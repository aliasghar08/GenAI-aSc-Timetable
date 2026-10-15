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
/// Features:
/// 1. Interactive Graphical Interface to manually & visually arrange classes (Move, Swap, Quick-Assign, Clear).
/// 2. Actionable AI Suggestions with one-click "Act Upon This Suggestion" execution.
/// 3. Resilient CSP Engine with timeout safeguards so it never hangs.
/// 4. View Switcher (Class Matrix vs Teacher Workload Matrix).
/// 5. Native compliant aSc Timetables XML export.
class TimetableStudioScreen extends StatefulWidget {
  const TimetableStudioScreen({super.key});

  @override
  State<TimetableStudioScreen> createState() => _TimetableStudioScreenState();
}

class _TimetableStudioScreenState extends State<TimetableStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  late String selectedClassId;
  late String _selectedTeacherId;
  String _viewMode = 'class'; // 'class' or 'teacher'

  // Interactive Class Arranging State
  LessonPlacement? _selectedPlacementForMove;
  String? _stagedSubjectId;

  // AI Panel Tab: 0 = Actionable Suggestions, 1 = Co-Pilot & Directives
  int _activeAiTab = 0;

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
    selectedClassId = provider.classes.isNotEmpty ? provider.classes.first.id : 'C1';
    _selectedTeacherId = provider.teachers.isNotEmpty ? provider.teachers.first.id : 'T1';
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
    final isDesktop = size.width >= 1000;

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
              color: const Color(0xFF6366F1).withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            right: -size.width * 0.05,
            child: _buildGlowOrb(
              size: size.width * 0.5,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.35,
            child: _buildGlowOrb(
              size: size.width * 0.3,
              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
            ),
          ),

          // Main Floating Workspace Layout
          SafeArea(
            child: Column(
              children: [
                // 1. Floating Top Dock
                _buildFloatingTopDock(provider),

                // 2. Main Studio Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: Graphical Class Arranger & Timetable Matrix
                              Expanded(
                                flex: 3,
                                child: _buildFloatingMatrixPanel(provider),
                              ),
                              const SizedBox(width: 16),
                              // Right: Actionable AI Suggestions & Co-Pilot
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
                                  height: 620,
                                  child: _buildFloatingMatrixPanel(provider),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 650,
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                  width: 36,
                  height: 36,
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
                      'aSc Timetables GenAI Studio',
                      style: AppTypography.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Interactive Class Arranger • Actionable AI Suggestions',
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Export XML Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  onPressed: () => _exportAscXml(provider),
                  icon: const Icon(CupertinoIcons.arrow_down_doc, size: 14),
                  label: const Text('Export aSc XML', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),

                // Administrator Identity Chip
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
                      const Icon(CupertinoIcons.person_crop_circle_fill, size: 14, color: Color(0xFFA5B4FC)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
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
                  icon: const Icon(CupertinoIcons.power, color: Color(0xFFF87171), size: 16),
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

  /// 2. Left Floating Glass Panel: Graphical Class Arranger & Timetable Matrix
  Widget _buildFloatingMatrixPanel(TimetableProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
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
              // View & Filter Bar (Class View vs Teacher View)
              _buildArrangerToolbar(provider),
              const SizedBox(height: 10),

              // Active Arranging Mode Indicator (if card selected for move/swap)
              if (_selectedPlacementForMove != null) _buildArrangingModeBanner(provider),

              // Quick Staging Palette Tray
              _buildStagingPalette(provider),
              const SizedBox(height: 10),

              // The Schedule Grid Matrix
              Expanded(
                child: _buildInteractiveGrid(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// View Mode Switcher and Entity Selector Toolbar
  Widget _buildArrangerToolbar(TimetableProvider provider) {
    final currentPlacementsCount = _viewMode == 'class'
        ? provider.placements.where((p) => p.classId == selectedClassId).length
        : provider.placements.where((p) => p.teacherId == _selectedTeacherId).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // View Mode Segmented Pill
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab('class', 'Class View', CupertinoIcons.building_2_fill),
                _buildModeTab('teacher', 'Teacher View', CupertinoIcons.person_2_fill),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Dynamic Entity Dropdown
          Text(
            _viewMode == 'class' ? 'Class:' : 'Teacher:',
            style: AppTypography.inter(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFFE2E8F0)),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF0F172A),
              value: _viewMode == 'class' ? selectedClassId : _selectedTeacherId,
              style: AppTypography.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              items: _viewMode == 'class'
                  ? provider.classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList()
                  : provider.teachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    if (_viewMode == 'class') {
                      selectedClassId = val;
                    } else {
                      _selectedTeacherId = val;
                    }
                    _selectedPlacementForMove = null;
                  });
                }
              },
            ),
          ),
          const Spacer(),

          // Placed Lessons Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill, size: 12, color: Color(0xFF34D399)),
                const SizedBox(width: 5),
                Text(
                  '$currentPlacementsCount Placed',
                  style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF34D399)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _viewMode = mode;
          _selectedPlacementForMove = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isSelected ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arranging Mode Banner shown when a card is selected
  Widget _buildArrangingModeBanner(TimetableProvider provider) {
    final placement = _selectedPlacementForMove!;
    final subject = provider.subjects.firstWhere((s) => s.id == placement.subjectId, orElse: () => Subject(id: '', name: 'Subject', shortName: '??'));
    final teacher = provider.teachers.firstWhere((t) => t.id == placement.teacherId, orElse: () => Teacher(id: '', name: 'Teacher', shortName: '??'));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.3),
            const Color(0xFF06B6D4).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.arrow_right_arrow_left, size: 15, color: Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Arranging Mode: Selected [${subject.shortName} • ${teacher.shortName}] (Day ${weekDays[placement.dayOfWeek - 1]} P${placement.period}). Tap any empty slot to Move, or another card to Swap!',
              style: AppTypography.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _selectedPlacementForMove = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: const Text('✕ Cancel Selection', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Arrangement Palette Tray
  Widget _buildStagingPalette(TimetableProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.square_grid_2x2_fill, size: 13, color: Color(0xFFA5B4FC)),
          const SizedBox(width: 8),
          Text(
            'Quick Place:',
            style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.subjects.map((sub) {
                  final isStaged = _stagedSubjectId == sub.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _stagedSubjectId = isStaged ? null : sub.id;
                          _selectedPlacementForMove = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isStaged
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isStaged ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sub.shortName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isStaged ? const Color(0xFF38BDF8) : Colors.white,
                              ),
                            ),
                            if (isStaged) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check, size: 10, color: Color(0xFF38BDF8)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_stagedSubjectId != null)
            InkWell(
              onTap: () => setState(() => _stagedSubjectId = null),
              child: const Text('✕ Clear', style: TextStyle(fontSize: 10, color: Color(0xFFF87171), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  /// Weekly Timetable Interactive Grid
  Widget _buildInteractiveGrid(TimetableProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth > 580 ? constraints.maxWidth : 580),
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
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            'Period',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFF94A3B8)),
                          ),
                        ),
                        ...weekDays.map(
                          (d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white),
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
                              style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF818CF8)),
                            ),
                          ),
                          for (int d = 1; d <= 5; d++) _buildInteractiveCell(provider, d, p),
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

  /// Interactive Placement Matrix Cell with Move, Swap, and Quick Scheduling
  Widget _buildInteractiveCell(TimetableProvider provider, int day, int period) {
    final matches = _viewMode == 'class'
        ? provider.placements.where((pl) => pl.classId == selectedClassId && pl.dayOfWeek == day && pl.period == period).toList()
        : provider.placements.where((pl) => pl.teacherId == _selectedTeacherId && pl.dayOfWeek == day && pl.period == period).toList();

    // 1. EMPTY SLOT
    if (matches.isEmpty) {
      final isMoveTarget = _selectedPlacementForMove != null;
      final isStagingTarget = _stagedSubjectId != null;

      return InkWell(
        onTap: () {
          // If a card is selected for move, execute the move!
          if (_selectedPlacementForMove != null) {
            final moving = _selectedPlacementForMove!;
            final check = provider.checkCollision(
              moving.teacherId,
              moving.classId,
              day,
              period,
              excludePlacementId: moving.id,
            );

            if (check['hasCollision'] == true) {
              _showCollisionWarning(provider, check['reason'] as String, () {
                provider.movePlacement(moving.id, day, period);
                setState(() => _selectedPlacementForMove = null);
                _showToast('Moved lesson with constraint override!');
              });
            } else {
              provider.movePlacement(moving.id, day, period);
              setState(() => _selectedPlacementForMove = null);
              _showToast('Moved lesson to ${weekDays[day - 1]} Period $period!');
            }
          } else if (_stagedSubjectId != null) {
            // Quick place from staged palette
            final subId = _stagedSubjectId!;
            final targetClass = _viewMode == 'class' ? selectedClassId : provider.classes.first.id;
            final targetTeacher = _viewMode == 'teacher' ? _selectedTeacherId : provider.teachers.first.id;

            provider.addPlacement(
              subjectId: subId,
              teacherId: targetTeacher,
              classId: targetClass,
              dayOfWeek: day,
              period: period,
            );
            _showToast('Placed new lesson in ${weekDays[day - 1]} Period $period!');
          } else {
            // Open quick schedule dialog
            _showQuickScheduleDialog(provider, day, period);
          }
        },
        child: Container(
          height: 52,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isMoveTarget
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : isStagingTarget
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMoveTarget
                  ? const Color(0xFF34D399)
                  : isStagingTarget
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                      : Colors.transparent,
              style: isMoveTarget ? BorderStyle.solid : BorderStyle.none,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: isMoveTarget
              ? const Icon(CupertinoIcons.arrow_down_circle, size: 16, color: Color(0xFF34D399))
              : isStagingTarget
                  ? const Icon(CupertinoIcons.plus_circle, size: 14, color: Color(0xFF38BDF8))
                  : null,
        ),
      );
    }

    // 2. OCCUPIED SLOT
    final placement = matches.first;
    final isSelectedForMove = _selectedPlacementForMove?.id == placement.id;

    final subject = provider.subjects.firstWhere(
      (s) => s.id == placement.subjectId,
      orElse: () => Subject(id: '', name: 'Unknown', shortName: '??'),
    );
    final teacher = provider.teachers.firstWhere(
      (t) => t.id == placement.teacherId,
      orElse: () => Teacher(id: '', name: 'Unknown', shortName: '??'),
    );
    final schoolClass = provider.classes.firstWhere(
      (c) => c.id == placement.classId,
      orElse: () => SchoolClass(id: '', name: 'Unknown', shortName: '??'),
    );

    return InkWell(
      onTap: () {
        if (_selectedPlacementForMove != null) {
          if (_selectedPlacementForMove!.id == placement.id) {
            // Deselect
            setState(() => _selectedPlacementForMove = null);
          } else {
            // Execute SWAP!
            provider.swapPlacements(_selectedPlacementForMove!.id, placement.id);
            final swappedSub = subject.shortName;
            setState(() => _selectedPlacementForMove = null);
            _showToast('Swapped with $swappedSub!');
          }
        } else {
          // Select this placement to move or swap
          setState(() {
            _selectedPlacementForMove = placement;
            _stagedSubjectId = null;
          });
        }
      },
      onLongPress: () => _showLessonEditorModal(provider, placement),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelectedForMove
                ? [
                    const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    const Color(0xFF6366F1).withValues(alpha: 0.35),
                  ]
                : [
                    const Color(0xFF6366F1).withValues(alpha: 0.22),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelectedForMove ? const Color(0xFF38BDF8) : const Color(0xFF818CF8).withValues(alpha: 0.45),
            width: isSelectedForMove ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelectedForMove
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : const Color(0xFF6366F1).withValues(alpha: 0.18),
              blurRadius: isSelectedForMove ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    subject.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: const Color(0xFFE0E7FF),
                    ),
                  ),
                ),
                if (isSelectedForMove) ...[
                  const SizedBox(width: 3),
                  const Icon(CupertinoIcons.arrow_right_arrow_left, size: 9, color: Color(0xFF38BDF8)),
                ],
              ],
            ),
            const SizedBox(height: 1),
            Text(
              _viewMode == 'class' ? teacher.shortName : schoolClass.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Schedule Dialog for an empty slot
  void _showQuickScheduleDialog(TimetableProvider provider, int day, int period) {
    String selSub = provider.subjects.first.id;
    String selTeacher = provider.teachers.first.id;
    final targetClass = _viewMode == 'class' ? selectedClassId : provider.classes.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            title: Text(
              'Schedule Lesson (${weekDays[day - 1]} Period $period)',
              style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Subject:', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selSub,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: provider.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setDlgState(() => selSub = val!),
                ),
                const SizedBox(height: 12),
                Text('Select Teacher:', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selTeacher,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: provider.teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (val) => setDlgState(() => selTeacher = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: () {
                  provider.addPlacement(
                    subjectId: selSub,
                    teacherId: selTeacher,
                    classId: targetClass,
                    dayOfWeek: day,
                    period: period,
                  );
                  Navigator.pop(ctx);
                  _showToast('Lesson placed successfully!');
                },
                child: const Text('Place Lesson'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lesson Editor Modal (Move, Reassign, Clear)
  void _showLessonEditorModal(TimetableProvider provider, LessonPlacement placement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Arranging Actions',
                style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(CupertinoIcons.arrow_right_arrow_left, color: Color(0xFF38BDF8)),
                title: const Text('Move / Swap this Lesson', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Select this card and tap another slot on the grid', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedPlacementForMove = placement);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Color(0xFFF87171)),
                title: const Text('Remove from Schedule', style: TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                subtitle: const Text('Clear this slot and make it available', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.removePlacement(placement.id);
                  _showToast('Lesson removed.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollisionWarning(TimetableProvider provider, String reason, VoidCallback onOverride) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Potential Collision', style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        content: Text(reason, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber[800]),
            onPressed: () {
              Navigator.pop(ctx);
              onOverride();
            },
            child: const Text('Override Anyway'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// 3. Right Floating Glass Panel: Actionable AI Suggestions & Strategic Co-Pilot
  Widget _buildFloatingAiPanel(TimetableProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
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
              // Tab Header
              _buildAiTabHeader(provider),
              const SizedBox(height: 12),

              // Tab 0: Actionable AI Suggestions
              // Tab 1: Strategic AI Co-Pilot & Directives
              Expanded(
                child: _activeAiTab == 0
                    ? _buildAiSuggestionsTab(provider)
                    : _buildAiCoPilotTab(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented Tab Header for Right Panel
  Widget _buildAiTabHeader(TimetableProvider provider) {
    final activeSuggestionsCount = provider.suggestions.where((s) => !s.isApplied).length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => setState(() => _activeAiTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: _activeAiTab == 0
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                      : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.lightbulb_fill, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      'AI Suggestions ($activeSuggestionsCount)',
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: _activeAiTab == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _activeAiTab == 0 ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => setState(() => _activeAiTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: _activeAiTab == 1
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF06B6D4)])
                      : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      'AI Directives',
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: _activeAiTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _activeAiTab == 1 ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 0: Actionable AI Suggestions with "Act Upon This Suggestion" execution
  Widget _buildAiSuggestionsTab(TimetableProvider provider) {
    final suggestions = provider.suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rationale & Action Pill
        Row(
          children: [
            const Icon(CupertinoIcons.check_mark_circled_solid, size: 14, color: Color(0xFF34D399)),
            const SizedBox(width: 6),
            Text(
              'Interactive Schedule Optimizations',
              style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                provider.generateAiSuggestions();
                _showToast('Re-analyzed constraints & refreshed suggestions!');
              },
              icon: const Icon(CupertinoIcons.refresh, size: 12, color: Color(0xFF38BDF8)),
              label: const Text('Refresh', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Expanded(
          child: suggestions.isEmpty
              ? Center(
                  child: Text(
                    'All constraint suggestions have been satisfied!\nYour schedule is running at peak mathematical efficiency.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = suggestions[idx];
                    return _buildSuggestionCard(provider, item);
                  },
                ),
        ),
      ],
    );
  }

  /// Actionable Suggestion Card with [Act Upon This Suggestion] Button
  Widget _buildSuggestionCard(TimetableProvider provider, AiScheduleSuggestion item) {
    Color categoryColor;
    IconData categoryIcon;

    switch (item.category) {
      case 'core_focus':
        categoryColor = const Color(0xFFF59E0B);
        categoryIcon = CupertinoIcons.sun_max_fill;
        break;
      case 'gap_reduction':
        categoryColor = const Color(0xFF8B5CF6);
        categoryIcon = CupertinoIcons.waveform_path_ecg;
        break;
      case 'friday_buffer':
        categoryColor = const Color(0xFF10B981);
        categoryIcon = CupertinoIcons.sparkles;
        break;
      default:
        categoryColor = const Color(0xFF6366F1);
        categoryIcon = CupertinoIcons.bolt_fill;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: item.isApplied ? 0.02 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isApplied ? Colors.white.withValues(alpha: 0.08) : categoryColor.withValues(alpha: 0.35),
          width: 1.1,
        ),
        boxShadow: [
          if (!item.isApplied)
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 10, color: categoryColor),
                    const SizedBox(width: 4),
                    Text(
                      item.badgeText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.impactText,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF34D399)),
                ),
              ),
              const Spacer(),
              if (item.isApplied)
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 13, color: Color(0xFF34D399)),
                    SizedBox(width: 4),
                    Text('Applied', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Title & Description
          Text(
            item.title,
            style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: AppTypography.inter(fontSize: 11, color: const Color(0xFFCBD5E1), height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            '💡 Rationale: ${item.rationale}',
            style: AppTypography.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),

          // Action Execution Button
          if (!item.isApplied)
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await provider.applySuggestion(item);
                  _showToast('Executed AI Directive: ${item.title}');
                },
                icon: const Icon(CupertinoIcons.sparkles, size: 13),
                label: Text(
                  'Act Upon This Suggestion',
                  style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tab 1: Strategic AI Co-Pilot & Natural Language Directives
  Widget _buildAiCoPilotTab(TimetableProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frosted Prompt Input Field
        TextField(
          controller: _promptController,
          maxLines: 2,
          style: AppTypography.inter(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'e.g. Prioritize morning CS for Grade 10-A, or free up Friday afternoon...',
            hintStyle: AppTypography.inter(color: const Color(0xFF64748B), fontSize: 11),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.35),
            contentPadding: const EdgeInsets.all(12),
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
        const SizedBox(height: 10),

        // Quick Directives
        Text(
          'Quick Algorithmic Directives:',
          style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickDirectives.map((qd) {
            final Color qdColor = qd['color'] as Color;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: provider.isAiThinking
                  ? null
                  : () {
                      provider.instructAi(qd['prompt'] as String);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: qdColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: qdColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(qd['icon'] as IconData, size: 10, color: qdColor),
                    const SizedBox(width: 4),
                    Text(
                      qd['label'] as String,
                      style: AppTypography.inter(
                        fontSize: 10,
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
        const SizedBox(height: 10),

        // Execute Solver or Unlock Emergency Button
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: provider.isAiThinking
                      ? null
                      : () {
                          if (_promptController.text.trim().isNotEmpty) {
                            provider.instructAi(_promptController.text.trim());
                            _promptController.clear();
                          } else {
                            provider.instructAi('Optimize timetable via CSP');
                          }
                        },
                  icon: provider.isAiThinking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.play_circle_fill, size: 15),
                  label: Text(
                    provider.isAiThinking ? 'Analyzing Constraints with CSP...' : 'Execute Constraint Solver',
                    style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (provider.isAiThinking) ...[
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                tooltip: 'Cancel / Emergency Unlock',
                onPressed: () => provider.resetAiThinkingState(),
                icon: const Icon(CupertinoIcons.clear_circled, color: Color(0xFFF87171), size: 18),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Terminal Diagnostic Output
        Row(
          children: [
            const Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF38BDF8)),
            const SizedBox(width: 6),
            Text(
              'Agent Diagnostic Output:',
              style: AppTypography.inter(fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFFE2E8F0)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              child: Text(
                provider.lastAiExplanation ??
                    '✨ Awaiting scheduling directive.\n\nType a natural language prompt or click one of the quick directives above to compute zero-collision permutations.',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
