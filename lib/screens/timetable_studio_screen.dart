import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_provider.dart';
import '../models/timetable_models.dart';
import '../providers/auth_provider.dart';
import '../providers/timetable_provider.dart';
import '../services/asc_xml_service.dart';
import '../theme/app_typography.dart';

/// Next-Gen Autonomous Timetable Studio Screen
/// Features floating glass widgets, frosted blur layers, ambient lighting orbs,
/// and rich multi-layer drop shadows across both matrix and AI co-pilot panels.
class TimetableStudioScreen extends StatefulWidget {
  const TimetableStudioScreen({super.key});

  @override
  State<TimetableStudioScreen> createState() => _TimetableStudioScreenState();
}

class _TimetableStudioScreenState extends State<TimetableStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  late String selectedClassId;

  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<Map<String, dynamic>> quickDirectives = [
    {
      'label': '⚡ Deterministic CSP Backtracking (0 Collisions)',
      'prompt': 'Execute deterministic forward-checking CSP backtracking search to guarantee 0 teacher and room collisions.',
      'icon': CupertinoIcons.bolt_fill,
      'color': Color(0xFF6366F1),
    },
    {
      'label': '🧬 Genetic Soft-Constraint Optimization (Minimize Gaps)',
      'prompt': 'Run genetic algorithm permutation search to minimize teacher idle gap hours and balance load.',
      'icon': CupertinoIcons.waveform_path_ecg,
      'color': Color(0xFF8B5CF6),
    },
    {
      'label': '🌅 Prioritize Morning Math & Physics',
      'prompt': 'Schedule high-cognitive subjects (Mathematics, Physics) in morning periods 1-3.',
      'icon': CupertinoIcons.sun_max_fill,
      'color': Color(0xFFF59E0B),
    },
    {
      'label': '🏖️ Free up Friday Afternoons',
      'prompt': 'Consolidate Friday afternoon periods 6-8 for extracurriculars and planning.',
      'icon': CupertinoIcons.sparkles,
      'color': Color(0xFF10B981),
    },
    {
      'label': '🧘 Teacher Burnout Protection: Max 4 periods/day',
      'prompt': 'Enforce soft constraint: No teacher should teach more than 4 periods in a single calendar day.',
      'icon': CupertinoIcons.heart_fill,
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<TimetableProvider>();
    selectedClassId = provider.classes.isNotEmpty ? provider.classes.first.id : 'c1';
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.arrow_down_doc_fill, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Generated aSc Timetables XML',
                style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliant with official aSc Timetables database XML schema for desktop import:',
                  style: AppTypography.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        xml,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          height: 1.4,
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
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Copied compliant aSc XML to clipboard!'),
                      ],
                    ),
                  ),
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
              label: const Text('Copy to Clipboard'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // Background Ambient Lighting Orbs
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.05,
            child: _buildGlowOrb(
              size: size.width * 0.45,
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            right: -size.width * 0.05,
            child: _buildGlowOrb(
              size: size.width * 0.5,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.35,
            child: _buildGlowOrb(
              size: size.width * 0.3,
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
            ),
          ),

          // Main Floating Workspace Layout
          SafeArea(
            child: Column(
              children: [
                // 1. Floating Island Top Dock / Navigation Bar
                _buildFloatingTopDock(provider),

                // 2. Main Studio Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: Floating Glass Timetable Matrix
                              Expanded(
                                flex: 3,
                                child: _buildFloatingMatrixPanel(provider),
                              ),
                              const SizedBox(width: 16),
                              // Right: Floating Glass AI Co-Pilot & Diagnostic Console
                              Expanded(
                                flex: 2,
                                child: _buildFloatingAiPanel(provider),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 520,
                                  child: _buildFloatingMatrixPanel(provider),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 600,
                                  child: _buildFloatingAiPanel(provider),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  /// 1. Floating Island Top Dock / AppBar
  Widget _buildFloatingTopDock(TimetableProvider provider) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUser?.email ?? 'admin@institution.edu';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Row(
              children: [
                // Studio Official App Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'aSc Timetables GenAI Autonomous Studio',
                      style: AppTypography.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Deterministic CSP Engine • Gemini Reasoning Co-Pilot',
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Status Badges
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.bolt_fill, size: 12, color: Color(0xFFA5B4FC)),
                      SizedBox(width: 5),
                      Text(
                        'Hybrid CSP Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5B4FC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Native aSc XML Export Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  onPressed: () => _exportAscXml(provider),
                  icon: const Icon(CupertinoIcons.arrow_down_doc, size: 15),
                  label: const Text('Export aSc XML', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),

                // Active Administrator Identity Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.person_crop_circle_fill, size: 16, color: Color(0xFFA5B4FC)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Sign Out Button
                IconButton(
                  icon: const Icon(CupertinoIcons.power, color: Color(0xFFF87171), size: 18),
                  tooltip: 'Sign Out Session',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: AlertDialog(
                          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          title: const Text('Sign Out Session', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Are you sure you want to end your scheduling session and return to the login screen?',
                            style: TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (confirm == true) {
                      await auth.signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Left Floating Glass Panel: Timetable Matrix
  Widget _buildFloatingMatrixPanel(TimetableProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Selector & Stats Pill
              _buildClassSelector(provider),
              const SizedBox(height: 16),

              // The Schedule Grid Matrix
              Expanded(
                child: _buildGrid(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Class Selector Pill Bar
  Widget _buildClassSelector(TimetableProvider provider) {
    final currentPlacementsCount = provider.placements.where((p) => p.classId == selectedClassId).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.building_2_fill, color: Color(0xFFA5B4FC), size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Target Class:',
            style: AppTypography.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFFE2E8F0)),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF0F172A),
              value: selectedClassId,
              style: AppTypography.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              items: provider.classes
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedClassId = val);
              },
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.clock_fill, size: 13, color: Color(0xFF34D399)),
                const SizedBox(width: 6),
                Text(
                  '$currentPlacementsCount Placed Lessons',
                  style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF34D399)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly Timetable Grid
  Widget _buildGrid(TimetableProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth > 600 ? constraints.maxWidth : 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(64),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Period',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                        ),
                        ...weekDays.map(
                          (d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (int p = 1; p <= 8; p++)
                      TableRow(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              'P$p',
                              style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF818CF8)),
                            ),
                          ),
                          for (int d = 1; d <= 5; d++) _buildCell(provider, d, p),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Interactive Placement Matrix Cell
  Widget _buildCell(TimetableProvider provider, int day, int period) {
    final matches = provider.placements.where((pl) =>
        pl.classId == selectedClassId && pl.dayOfWeek == day && pl.period == period);

    if (matches.isEmpty) {
      return Container(
        height: 54,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(8),
        ),
      );
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
      height: 54,
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.22),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            subject.shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: const Color(0xFFE0E7FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            teacher.shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Right Floating Glass Panel: AI Co-Pilot & Diagnostic Console
  Widget _buildFloatingAiPanel(TimetableProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Scheduling Agent',
                    style: AppTypography.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Instruct with human speech; Gemini translates rules into deterministic CSP constraints with 0 collisions.',
                style: AppTypography.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),

              // Frosted Prompt Input Field
              TextField(
                controller: _promptController,
                maxLines: 2,
                style: AppTypography.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Schedule CS for Grade 10-A on Monday Period 1 with Turing. If conflict, move Turing to Tuesday.',
                  hintStyle: AppTypography.inter(color: const Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.35),
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Floating Quick Directives
              Text(
                'Quick Algorithmic Directives:',
                style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickDirectives.map((qd) {
                  final Color qdColor = qd['color'] as Color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: provider.isAiThinking
                        ? null
                        : () {
                            provider.instructAi(qd['prompt'] as String);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: qdColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: qdColor.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: qdColor.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(qd['icon'] as IconData, size: 12, color: qdColor),
                          const SizedBox(width: 6),
                          Text(
                            qd['label'] as String,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Primary Action Execution Button
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.play_circle_fill, size: 18),
                  label: Text(
                    provider.isAiThinking ? 'Analyzing Constraints with CSP...' : 'Execute Constraint Solver',
                    style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Agent Diagnostic Output Terminal
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text(
                    'Agent Diagnostic Output:',
                    style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFE2E8F0)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      provider.lastAiExplanation ??
                          '✨ Awaiting scheduling directive.\n\nType a natural language prompt or click one of the floating quick directives above to compute collision-free permutations.',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
