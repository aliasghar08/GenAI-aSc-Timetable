import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/timetable_models.dart';
import 'algorithmic_csp_solver.dart';

class GeminiAiService {
  final String apiKey;
  GenerativeModel? _model;
  final AlgorithmicCspSolver _cspSolver = AlgorithmicCspSolver();

  GeminiAiService({required this.apiKey}) {
    if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_FALLBACK') {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2, // Low temperature for deterministic constraint logic
            responseMimeType: 'application/json',
          ),
        );
      } catch (_) {
        _model = null;
      }
    }
  }

  Future<Map<String, dynamic>> processScheduleIntent({
    required String prompt,
    required List<Teacher> teachers,
    required List<Subject> subjects,
    required List<SchoolClass> classes,
    required List<LessonPlacement> currentPlacements,
  }) async {
    // 1. Synthesize formal CSP constraints from natural language prompt
    final constraintSpec = CspConstraintSpec.fromPrompt(prompt, subjects, teachers);

    // 2. Execute deterministic Algorithmic CSP Solver (Backtracking + Genetic Optimization)
    final cspSolution = _cspSolver.solve(
      classes: classes,
      subjects: subjects,
      teachers: teachers,
      currentPlacements: currentPlacements,
      constraints: constraintSpec,
    );

    // Build operational diff actions from the CSP solution
    final actions = cspSolution.placements.map((p) {
      return {
        'action': 'UPSERT',
        'placement': p.toMap(),
      };
    }).toList();

    // If Gemini model is available, enrich with deep natural language reasoning
    if (_model != null) {
      try {
        final contextSnapshot = {
          'prompt': prompt,
          'cspTelemetry': cspSolution.telemetry,
          'fitnessScore': '${cspSolution.fitnessScore.toStringAsFixed(1)}%',
          'verifiedCardCount': cspSolution.placements.length,
          'teachers': teachers.map((t) => t.toMap()).toList(),
          'subjects': subjects.map((s) => s.toMap()).toList(),
        };

        final systemPrompt = '''
You are the Strategic Orchestrator of a Hybrid LLM + Algorithmic CSP Timetable Solver.
The deterministic CSP engine has already calculated and verified a zero-collision solution.
Your job is to provide an executive summary explaining:
1. How the administrator's request was translated into constraints.
2. The trade-offs and optimizations executed (teacher workloads, morning subject biases, and gap reductions).
3. The mathematical validity of the resulting schedule.

Data:
${jsonEncode(contextSnapshot)}

Return strictly valid JSON:
{
  "explanation": "Executive summary report for school leadership",
  "status": "SUCCESS"
}
''';

        final response = await _model!.generateContent([
          Content.text(systemPrompt),
        ]);

        if (response.text != null && response.text!.isNotEmpty) {
          final decoded = jsonDecode(response.text!);
          final llmExplanation = decoded['explanation'] ?? 'Optimized via Hybrid CSP solver.';
          return {
            'explanation': '$llmExplanation\n\n${cspSolution.telemetry}',
            'status': 'SUCCESS',
            'actions': actions,
            'fitness': cspSolution.fitnessScore,
          };
        }
      } catch (_) {
        // Fall back to algorithmic explanation if Gemini API is unresponsive
      }
    }

    // Default Hybrid Fallback: Algorithmic CSP solver output
    final explanation = '''
[Hybrid LLM + Algorithmic CSP Solver]
Directive: "$prompt"

Constraint Synthesis:
• Morning Core Subject Prioritization: ${constraintSpec.morningSubjectIds.isNotEmpty ? "Enabled (${constraintSpec.morningSubjectIds.length} subjects)" : "Standard distribution"}
• Teacher Wellness Cap: Max ${constraintSpec.maxDailyPeriodsPerTeacher} periods/day
• Friday Afternoon Buffer: ${constraintSpec.freeFridayAfternoon ? "Reserved / Free" : "Standard"}

${cspSolution.telemetry}
''';

    return {
      'explanation': explanation,
      'status': 'SUCCESS',
      'actions': actions,
      'fitness': cspSolution.fitnessScore,
    };
  }
}
