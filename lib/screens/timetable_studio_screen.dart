import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/timetable_provider.dart';
import '../models/timetable_models.dart';
import '../services/asc_xml_service.dart';

class TimetableStudioScreen extends StatefulWidget {
  const TimetableStudioScreen({super.key});

  @override
  State<TimetableStudioScreen> createState() => _TimetableStudioScreenState();
}

class _TimetableStudioScreenState extends State<TimetableStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  late String selectedClassId;

  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<String> quickDirectives = [
    '⚡ Deterministic CSP Backtracking (0 Collisions)',
    '🧬 Genetic Soft-Constraint Optimization (Minimize Gaps)',
    '🌅 Prioritize Morning Math & Physics',
    '🏖️ Free up Friday Afternoons',
    '🧘 Teacher Burnout Protection: Max 4 periods/day',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<TimetableProvider>();
    selectedClassId = provider.classes.first.id;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _exportAscXml(TimetableProvider provider) {
    final xml = AscXmlService.exportToAscXml(
      teachers: provider.teachers,
      subjects: provider.subjects,
      classes: provider.classes,
      placements: provider.placements,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Generated aSc Timetables XML'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Compatible with aSc TimeTables database schema and import wizard:'),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      xml,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: xml));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied aSc XML to clipboard!')),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy to Clipboard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'aSc Timetables GenAI Autonomous Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4F46E5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 14, color: Color(0xFF4F46E5)),
                SizedBox(width: 4),
                Text(
                  'Hybrid CSP Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'Firebase Connected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Native aSc XML',
            onPressed: () => _exportAscXml(provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left: Timetable Matrix
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildClassSelector(provider),
                        const SizedBox(height: 12),
                        Expanded(child: _buildGrid(provider)),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right: AI Co-pilot & Log Terminal
                Expanded(
                  flex: 2,
                  child: _buildAiPanel(provider),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildClassSelector(provider),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 480,
                    child: _buildGrid(provider),
                  ),
                  const SizedBox(height: 20),
                  _buildAiPanel(provider),
                ],
              ),
            ),
    );
  }

  Widget _buildClassSelector(TimetableProvider provider) {
    return Row(
      children: [
        const Icon(Icons.school_outlined, size: 20),
        const SizedBox(width: 8),
        const Text('Class Schedule: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedClassId,
          items: provider.classes
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => selectedClassId = val);
          },
        ),
        const Spacer(),
        Chip(
          avatar: const Icon(Icons.calendar_month_outlined, size: 16),
          label: Text(
            '${provider.placements.where((p) => p.classId == selectedClassId).length} Lessons',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAiPanel(TimetableProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text('AI Scheduling Agent', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Instruct with human speech; Gemini enforces aSc constraint rules and syncs to Firestore.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Schedule CS for Grade 10-A on Monday Period 1 with Turing. If conflict, move Turing to Tuesday.',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickDirectives.map((qd) {
              return ActionChip(
                label: Text(qd, style: const TextStyle(fontSize: 11)),
                onPressed: provider.isAiThinking
                    ? null
                    : () {
                        provider.instructAi(qd);
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: provider.isAiThinking
                  ? null
                  : () {
                      if (_promptController.text.trim().isNotEmpty) {
                        provider.instructAi(_promptController.text.trim());
                        _promptController.clear();
                      }
                    },
              icon: provider.isAiThinking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.bolt),
              label: Text(provider.isAiThinking ? 'Analyzing Constraints...' : 'Execute Constraint Solver'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Agent Diagnostic Output:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  provider.lastAiExplanation ?? '✨ Awaiting scheduling directive. Type a prompt or pick a quick directive above.',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(TimetableProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 550),
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3)),
            columnWidths: const {
              0: FixedColumnWidth(70),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15)),
                children: [
                  const Padding(padding: EdgeInsets.all(8.0), child: Text('Period', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ...weekDays.map((d) => Padding(padding: const EdgeInsets.all(8.0), child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                ],
              ),
              for (int p = 1; p <= 8; p++)
                TableRow(
                  children: [
                    Container(padding: const EdgeInsets.all(8), alignment: Alignment.center, child: Text('P$p', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    for (int d = 1; d <= 5; d++) _buildCell(provider, d, p),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(TimetableProvider provider, int day, int period) {
    final matches = provider.placements.where((pl) =>
        pl.classId == selectedClassId && pl.dayOfWeek == day && pl.period == period);

    if (matches.isEmpty) {
      return Container(height: 52, color: Colors.transparent);
    }

    final placement = matches.first;
    final subject = provider.subjects.firstWhere(
      (s) => s.id == placement.subjectId,
      orElse: () => Subject(id: '', name: 'Unknown', shortName: '??'),
    );
    final teacher = provider.teachers.firstWhere(
      (t) => t.id == placement.teacherId,
      orElse: () => Teacher(id: '', name: 'Unknown', shortName: '??'),
    );

    return Container(
      height: 52,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            subject.shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 1),
          Text(
            teacher.shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
