import 'package:flutter/foundation.dart';
import '../models/timetable_models.dart';
import '../services/gemini_ai_service.dart';
import '../services/firestore_service.dart';

class TimetableProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  late final GeminiAiService _aiService;

  List<Teacher> teachers = [
    Teacher(id: 'T1', name: 'Dr. Alan Turing', shortName: 'AT'),
    Teacher(id: 'T2', name: 'Prof. Ada Lovelace', shortName: 'AL'),
    Teacher(id: 'T3', name: 'Dr. Marie Curie', shortName: 'MC'),
    Teacher(id: 'T4', name: 'Prof. Albert Einstein', shortName: 'AE'),
    Teacher(id: 'T5', name: 'Ms. Eleanor Vance', shortName: 'EV'),
  ];

  List<Subject> subjects = [
    Subject(id: 'S1', name: 'Computer Science & AI', shortName: 'CS'),
    Subject(id: 'S2', name: 'Mathematics', shortName: 'MATH'),
    Subject(id: 'S3', name: 'Physics', shortName: 'PHYS'),
    Subject(id: 'S4', name: 'Chemistry', shortName: 'CHEM'),
    Subject(id: 'S5', name: 'English Literature', shortName: 'ENG'),
  ];

  List<SchoolClass> classes = [
    SchoolClass(id: 'C1', name: 'Grade 10-A (Science)', shortName: '10A'),
    SchoolClass(id: 'C2', name: 'Grade 11-B (General)', shortName: '11B'),
    SchoolClass(id: 'C3', name: 'Grade 12-A (Advanced STEM)', shortName: '12A'),
  ];

  List<LessonPlacement> placements = [];
  bool isAiThinking = false;
  String? lastAiExplanation;

  TimetableProvider({required String geminiApiKey}) {
    _aiService = GeminiAiService(apiKey: geminiApiKey);
    _initializeDefaultPlacements();
    _listenToPlacements();
    _firestoreService.seedInitialAcademicData(teachers, subjects, classes);
  }

  void _initializeDefaultPlacements() {
    // Seed initial collision-free placements for immediate visual delight
    final initial = <LessonPlacement>[];
    for (final c in classes) {
      for (int day = 1; day <= 5; day++) {
        for (int period = 1; period <= 5; period++) {
          final sIdx = (day + period) % subjects.length;
          final tIdx = (period) % teachers.length;
          initial.add(
            LessonPlacement(
              id: 'lp_${c.id}_${day}_$period',
              subjectId: subjects[sIdx].id,
              teacherId: teachers[tIdx].id,
              classId: c.id,
              dayOfWeek: day,
              period: period,
            ),
          );
        }
      }
    }
    placements = initial;
  }

  void _listenToPlacements() {
    _firestoreService.streamPlacements().listen((updatedPlacements) {
      if (updatedPlacements.isNotEmpty) {
        placements = updatedPlacements;
        notifyListeners();
      }
    });
  }

  Future<void> instructAi(String naturalLanguagePrompt) async {
    isAiThinking = true;
    lastAiExplanation = null;
    notifyListeners();

    try {
      final result = await _aiService.processScheduleIntent(
        prompt: naturalLanguagePrompt,
        teachers: teachers,
        subjects: subjects,
        classes: classes,
        currentPlacements: placements,
      );

      lastAiExplanation = result['explanation'];

      if (result['status'] == 'SUCCESS') {
        final actions = result['actions'] as List<dynamic>;

        // Update local state immediately
        for (var act in actions) {
          final type = act['action'];
          final pMap = act['placement'] as Map<String, dynamic>;
          final placement = LessonPlacement.fromMap(pMap);

          if (type == 'UPSERT') {
            final idx = placements.indexWhere((p) => p.id == placement.id);
            if (idx >= 0) {
              placements[idx] = placement;
            } else {
              placements.add(placement);
            }
          } else if (type == 'DELETE') {
            placements.removeWhere((p) => p.id == placement.id);
          }
        }

        // Sync with Firestore
        await _firestoreService.batchApplyActions(actions);
      }
    } catch (e) {
      lastAiExplanation = 'Execution Error: ${e.toString()}';
    } finally {
      isAiThinking = false;
      notifyListeners();
    }
  }
}
