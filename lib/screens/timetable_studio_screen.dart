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
/// 1. Drag & Drop Lecture Arrangement with real-time feedback & slot collision detection.
/// 2. "+ Create New Lecture" with custom subject, teacher, class, period, and room.
/// 3. Dedicated "⏰ Timings Schedule" view tab showing real-world clock hours and bell schedule.
/// 4. Real Data Management (CRUD for Real Teachers, Real Classes, and Real Subjects).
/// 5. Actionable AI Suggestions with one-click "Act Upon This Suggestion" execution.
/// 6. Native compliant aSc Timetables XML export.
class TimetableStudioScreen extends StatefulWidget {
  const TimetableStudioScreen({super.key});

  @override
  State<TimetableStudioScreen> createState() => _TimetableStudioScreenState();
}

class _TimetableStudioScreenState extends State<TimetableStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  late String selectedClassId;
  late String _selectedTeacherId;
  String _viewMode = 'class'; // 'class', 'teacher', or 'timing'

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
      constraints: provider.constraints,
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

    // Safety checks for active entity selection
    if (provider.classes.isNotEmpty && !provider.classes.any((c) => c.id == selectedClassId)) {
      selectedClassId = provider.classes.first.id;
    }
    if (provider.teachers.isNotEmpty && !provider.teachers.any((t) => t.id == _selectedTeacherId)) {
      _selectedTeacherId = provider.teachers.first.id;
    }

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
                              // Left: Graphical Class Arranger, Matrix & Timings View
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
                                  height: 640,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      'Drag & Drop Lectures • Real Bell Timings • Live Entity Customizer',
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Create New Lecture Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showCreateLectureModal(provider),
                    icon: const Icon(CupertinoIcons.plus_circle_fill, size: 15),
                    label: const Text('+ Create Lecture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),

                // PDF Page 1: The NLP Bridge: Natural Language to Strict Constraints
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFFC4B5FD),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
                    ),
                  ),
                  onPressed: () => _showNlpBridgeModal(provider),
                  icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 14),
                  label: const Text('NLP aSc Bridge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),

                // PDF Page 2: Negotiating Deadlocks: The AI Resolver
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isDeadlockActive
                        ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                    foregroundColor: provider.isDeadlockActive ? const Color(0xFFFCA5A5) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: provider.isDeadlockActive ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  onPressed: () => _showDeadlockResolverModal(provider),
                  icon: Icon(provider.isDeadlockActive ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.tuningfork, size: 14),
                  label: Text(provider.isDeadlockActive ? 'Deadlock (98%)!' : 'Deadlock Resolver', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),

                // PDF Page 4: Beyond Planning: The AI Substitution Agent
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFF6EE7B7),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                    ),
                  ),
                  onPressed: () => _showAiSubstitutionAgentModal(provider),
                  icon: const Icon(CupertinoIcons.person_2_alt, size: 14),
                  label: const Text('AI Substitutions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),

                // Manage Real School Data / Faculty & Classes
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  onPressed: () => _showManageEntitiesModal(provider),
                  icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 14),
                  label: const Text('Manage Real Data', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),

                // Export XML Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  onPressed: () => _exportAscXml(provider),
                  icon: const Icon(CupertinoIcons.arrow_down_doc, size: 14),
                  label: const Text('Export aSc XML', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),

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
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

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
              // PDF Page 2: Live Deadlock Negotiation Banner
              if (provider.isDeadlockActive) ...[
                _buildInlineDeadlockBanner(provider),
                const SizedBox(height: 10),
              ],

              // PDF Page 3: Realtime Collaborative Generation Lock
              if (provider.generationLock.status == 'running') ...[
                _buildCollaborativeLockBanner(provider),
                const SizedBox(height: 10),
              ],

              // View & Filter Bar (Class View vs Teacher View vs Timings Schedule)
              _buildArrangerToolbar(provider),
              const SizedBox(height: 10),

              if (_viewMode == 'timing')
                // Dedicated Timings View Tab
                Expanded(
                  child: _buildTimingsView(provider),
                )
              else ...[
                // Active Arranging Mode Indicator (if card selected for move/swap)
                if (_selectedPlacementForMove != null) _buildArrangingModeBanner(provider),

                // Quick Staging Palette Tray with Draggable Subject Chips
                _buildStagingPalette(provider),
                const SizedBox(height: 8),

                // Drag & Drop Hint Pill
                Row(
                  children: [
                    const Icon(CupertinoIcons.hand_draw_fill, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      'Drag and drop any lecture card to move or swap periods on the grid.',
                      style: AppTypography.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '8 Periods Active • 45m Clock Blocks',
                      style: AppTypography.inter(fontSize: 10, color: const Color(0xFF818CF8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // The Schedule Grid Matrix with Full Drag-and-Drop
                Expanded(
                  child: _buildInteractiveGrid(provider),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// View Mode Switcher: Class View, Teacher View, and Separate Timings Schedule
  Widget _buildArrangerToolbar(TimetableProvider provider) {
    final currentPlacementsCount = _viewMode == 'class'
        ? provider.placements.where((p) => p.classId == selectedClassId).length
        : _viewMode == 'teacher'
            ? provider.placements.where((p) => p.teacherId == _selectedTeacherId).length
            : provider.placements.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // View Mode 3-Segmented Pill
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
                _buildModeTab('timing', 'Timings Schedule', CupertinoIcons.clock_fill),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Dynamic Entity Dropdown (Class or Teacher)
          if (_viewMode != 'timing') ...[
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
          ] else ...[
            const Icon(CupertinoIcons.calendar_today, size: 14, color: Color(0xFF38BDF8)),
            const SizedBox(width: 6),
            Text(
              'Master Institutional Bell Timetable',
              style: AppTypography.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
            ),
          ],

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

  /// Dedicated "⏰ Timings Schedule" Separate View Tab
  Widget _buildTimingsView(TimetableProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with edit button
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.25),
                  const Color(0xFF06B6D4).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.clock_fill, color: Color(0xFF38BDF8), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Period & Bell Schedule',
                        style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Standard school bell timings mapped to real-world clock hours. Synchronized with aSc desktop exports.',
                        style: AppTypography.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showEditAllTimingsModal(provider),
                  icon: const Icon(CupertinoIcons.pencil, size: 13),
                  label: const Text('Edit Bell Timings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Period Timings Cards List
          Text(
            'Institutional Period Timeline (8 Academic Periods + Breaks):',
            style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.periodTimings.map((pt) {
              return Container(
                width: 210,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'P${pt.period}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFA5B4FC)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pt.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEditTimingDialog(provider, pt),
                          child: const Icon(CupertinoIcons.pencil_circle, size: 16, color: Color(0xFF38BDF8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.time, size: 12, color: Color(0xFF34D399)),
                        const SizedBox(width: 5),
                        Text(
                          '${pt.startTime} — ${pt.endTime}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Master Chronological Lecture Overview
          Text(
            'Master Real-Time Scheduled Lectures Overview:',
            style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.periodTimings.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 16),
              itemBuilder: (context, idx) {
                final pt = provider.periodTimings[idx];
                final periodPlacements = provider.placements.where((p) => p.period == pt.period).toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('P${pt.period} • ${pt.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                          Text('${pt.startTime} - ${pt.endTime}', style: const TextStyle(fontSize: 11, color: Color(0xFF34D399))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: periodPlacements.isEmpty
                          ? const Text('Free / Unassigned Period', style: TextStyle(fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: periodPlacements.map((p) {
                                final sub = provider.subjects.firstWhere((s) => s.id == p.subjectId, orElse: () => Subject(id: '', name: 'Subject', shortName: '??'));
                                final teacher = provider.teachers.firstWhere((t) => t.id == p.teacherId, orElse: () => Teacher(id: '', name: 'Teacher', shortName: '??'));
                                final cls = provider.classes.firstWhere((c) => c.id == p.classId, orElse: () => SchoolClass(id: '', name: 'Class', shortName: '??'));

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${weekDays[p.dayOfWeek - 1]}: ${sub.shortName} (${cls.shortName} • ${teacher.shortName})',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
              'Arranging Mode: Selected [${subject.shortName} • ${teacher.shortName}] (Day ${weekDays[placement.dayOfWeek - 1]} P${placement.period}). Drag it or Tap any slot to Move/Swap!',
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

  /// Quick Arrangement Palette Tray with draggable subject chips
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

  /// Weekly Timetable Interactive Grid with Drag and Drop
  Widget _buildInteractiveGrid(TimetableProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth > 640 ? constraints.maxWidth : 640),
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
                    0: FixedColumnWidth(95),
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
                            'Period / Time',
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
                          // Left column: Period + Clock Time
                          _buildPeriodTimingHeaderCell(provider, p),
                          // Monday - Friday cells with Drag & Drop
                          for (int d = 1; d <= 5; d++) _buildDragDropCell(provider, d, p),
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

  /// Period Header cell showing both Period number and real clock time
  Widget _buildPeriodTimingHeaderCell(TimetableProvider provider, int period) {
    final timing = provider.periodTimings.firstWhere(
      (pt) => pt.period == period,
      orElse: () => PeriodTiming(period: period, name: 'P$period', startTime: '08:00', endTime: '08:45'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'P$period',
            style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF818CF8)),
          ),
          const SizedBox(height: 2),
          Text(
            timing.startTime,
            style: const TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Interactive Cell supporting both Native Flutter Drag-and-Drop and Click-to-Move/Swap
  Widget _buildDragDropCell(TimetableProvider provider, int day, int period) {
    final isClassView = _viewMode == 'class';
    final activeEntityId = isClassView ? selectedClassId : _selectedTeacherId;

    final matches = isClassView
        ? provider.placements.where((pl) => pl.classId == selectedClassId && pl.dayOfWeek == day && pl.period == period).toList()
        : provider.placements.where((pl) => pl.teacherId == _selectedTeacherId && pl.dayOfWeek == day && pl.period == period).toList();

    return DragTarget<LessonPlacement>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final droppedPlacement = details.data;
        provider.handleDropPlacement(
          dropped: droppedPlacement,
          targetDay: day,
          targetPeriod: period,
          activeEntityId: activeEntityId,
          isClassView: isClassView,
        );
        _showToast('Arranged lesson to ${weekDays[day - 1]} Period $period via Drag & Drop!');
      },
      builder: (context, candidateData, rejectedData) {
        final isDropHovering = candidateData.isNotEmpty;

        // 1. EMPTY SLOT
        if (matches.isEmpty) {
          final isMoveTarget = _selectedPlacementForMove != null;
          final isStagingTarget = _stagedSubjectId != null;

          return InkWell(
            onTap: () {
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
                _showQuickScheduleDialog(provider, day, period);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDropHovering
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : isMoveTarget
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : isStagingTarget
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDropHovering
                      ? const Color(0xFF34D399)
                      : isMoveTarget
                          ? const Color(0xFF34D399)
                          : isStagingTarget
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                              : Colors.transparent,
                  width: isDropHovering ? 2.0 : 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: isDropHovering
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.arrow_down_circle_fill, size: 16, color: Color(0xFF34D399)),
                        Text('Drop Here', style: TextStyle(fontSize: 8, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                      ],
                    )
                  : isMoveTarget
                      ? const Icon(CupertinoIcons.arrow_down_circle, size: 16, color: Color(0xFF34D399))
                      : isStagingTarget
                          ? const Icon(CupertinoIcons.plus_circle, size: 14, color: Color(0xFF38BDF8))
                          : null,
            ),
          );
        }

        // 2. OCCUPIED SLOT (Draggable)
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

        final cardWidget = Container(
          height: 54,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDropHovering
                  ? [const Color(0xFF06B6D4).withValues(alpha: 0.4), const Color(0xFF6366F1).withValues(alpha: 0.35)]
                  : isSelectedForMove
                      ? [const Color(0xFF38BDF8).withValues(alpha: 0.4), const Color(0xFF6366F1).withValues(alpha: 0.35)]
                      : [const Color(0xFF6366F1).withValues(alpha: 0.22), const Color(0xFF8B5CF6).withValues(alpha: 0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDropHovering
                  ? const Color(0xFF06B6D4)
                  : isSelectedForMove
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF818CF8).withValues(alpha: 0.45),
              width: isDropHovering || isSelectedForMove ? 2.0 : 1.0,
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
        );

        return Draggable<LessonPlacement>(
          data: placement,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 120,
                height: 56,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject.shortName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      '${teacher.shortName} • ${schoolClass.shortName}',
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
          child: InkWell(
            onTap: () {
              if (_selectedPlacementForMove != null) {
                if (_selectedPlacementForMove!.id == placement.id) {
                  setState(() => _selectedPlacementForMove = null);
                } else {
                  provider.swapPlacements(_selectedPlacementForMove!.id, placement.id);
                  final swappedSub = subject.shortName;
                  setState(() => _selectedPlacementForMove = null);
                  _showToast('Swapped with $swappedSub!');
                }
              } else {
                setState(() {
                  _selectedPlacementForMove = placement;
                  _stagedSubjectId = null;
                });
              }
            },
            onLongPress: () => _showLessonEditorModal(provider, placement),
            child: cardWidget,
          ),
        );
      },
    );
  }

  /// "+ Create New Lecture" Modal
  void _showCreateLectureModal(TimetableProvider provider) {
    String selClass = provider.classes.isNotEmpty ? selectedClassId : 'C1';
    String selSub = provider.subjects.isNotEmpty ? provider.subjects.first.id : 'S1';
    String selTeacher = provider.teachers.isNotEmpty ? _selectedTeacherId : 'T1';
    int selDay = 1;
    int selPeriod = 1;
    final roomController = TextEditingController(text: 'Room 101');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => BackdropFilter(
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
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.plus_circle_fill, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Create New Lecture', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Class
                    const Text('Target Class:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selClass,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: provider.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setDlgState(() => selClass = val!),
                    ),
                    const SizedBox(height: 12),

                    // Subject & Teacher Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Subject:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selSub,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: provider.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                onChanged: (val) => setDlgState(() => selSub = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Faculty Teacher:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selTeacher,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: provider.teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                                onChanged: (val) => setDlgState(() => selTeacher = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Day & Period Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Day of Week:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: selDay,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: [
                                  for (int i = 0; i < weekDays.length; i++)
                                    DropdownMenuItem(value: i + 1, child: Text(weekDays[i])),
                                ],
                                onChanged: (val) => setDlgState(() => selDay = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Period Slot & Time:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: selPeriod,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: provider.periodTimings.map((pt) {
                                  return DropdownMenuItem(value: pt.period, child: Text('P${pt.period} (${pt.startTime})'));
                                }).toList(),
                                onChanged: (val) => setDlgState(() => selPeriod = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Room / Location
                    const Text('Room / Lab Location (Optional):', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: roomController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.createLecture(
                    classId: selClass,
                    subjectId: selSub,
                    teacherId: selTeacher,
                    dayOfWeek: selDay,
                    period: selPeriod,
                    room: roomController.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _showToast('Created new lecture successfully!');
                },
                child: const Text('Create Lecture'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Real Academic Data / Faculty & Classes Setup Modal
  void _showManageEntitiesModal(TimetableProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMngState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DefaultTabController(
            length: 3,
            child: AlertDialog(
              backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.96),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              title: Row(
                children: [
                  const Icon(CupertinoIcons.building_2_fill, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 10),
                  const Text('Manage Real School Data', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 480,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: Color(0xFF6366F1),
                      labelColor: Color(0xFF818CF8),
                      unselectedLabelColor: Colors.white60,
                      tabs: [
                        Tab(text: 'Teachers / Faculty'),
                        Tab(text: 'Classes / Grades'),
                        Tab(text: 'Subjects'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Teachers
                          _buildEntityCrudList<Teacher>(
                            items: provider.teachers,
                            title: 'Teacher',
                            getName: (t) => t.name,
                            getShort: (t) => t.shortName,
                            onAdd: (name, short) {
                              provider.addTeacher(name, short);
                              setMngState(() {});
                            },
                            onDelete: (id) {
                              provider.deleteTeacher(id);
                              setMngState(() {});
                            },
                          ),
                          // Tab 2: Classes
                          _buildEntityCrudList<SchoolClass>(
                            items: provider.classes,
                            title: 'Class',
                            getName: (c) => c.name,
                            getShort: (c) => c.shortName,
                            onAdd: (name, short) {
                              provider.addClass(name, short);
                              setMngState(() {});
                            },
                            onDelete: (id) {
                              provider.deleteClass(id);
                              setMngState(() {});
                            },
                          ),
                          // Tab 3: Subjects
                          _buildEntityCrudList<Subject>(
                            items: provider.subjects,
                            title: 'Subject',
                            getName: (s) => s.name,
                            getShort: (s) => s.shortName,
                            onAdd: (name, short) {
                              provider.addSubject(name, short);
                              setMngState(() {});
                            },
                            onDelete: (id) {
                              provider.deleteSubject(id);
                              setMngState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntityCrudList<T>({
    required List<T> items,
    required String title,
    required String Function(T) getName,
    required String Function(T) getShort,
    required void Function(String name, String short) onAdd,
    required void Function(String id) onDelete,
  }) {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();

    return Column(
      children: [
        // Quick add row
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'New $title Name (e.g. Mrs. Sarah Smith)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: shortCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Code (e.g. SS)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    final short = shortCtrl.text.trim().isNotEmpty ? shortCtrl.text.trim().toUpperCase() : nameCtrl.text.trim().substring(0, 2).toUpperCase();
                    onAdd(nameCtrl.text.trim(), short);
                    nameCtrl.clear();
                    shortCtrl.clear();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Items list
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (ctx, idx) {
              final it = items[idx];
              final name = getName(it);
              final short = getShort(it);
              final dynamic dyn = it;
              final id = dyn.id as String;

              return ListTile(
                dense: true,
                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Code: $short • ID: $id', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.trash, color: Color(0xFFF87171), size: 16),
                  onPressed: () => onDelete(id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Edit single period timing dialog
  void _showEditTimingDialog(TimetableProvider provider, PeriodTiming timing) {
    final startCtrl = TextEditingController(text: timing.startTime);
    final endCtrl = TextEditingController(text: timing.endTime);
    final nameCtrl = TextEditingController(text: timing.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Period ${timing.period} Timing', style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Period Label', labelStyle: TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Start (e.g. 08:00)', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'End (e.g. 08:45)', labelStyle: TextStyle(color: Colors.white60)),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              provider.updatePeriodTiming(
                timing.period,
                startCtrl.text.trim(),
                endCtrl.text.trim(),
                name: nameCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              _showToast('Updated Period ${timing.period} timing!');
            },
            child: const Text('Save Timing'),
          ),
        ],
      ),
    );
  }

  void _showEditAllTimingsModal(TimetableProvider provider) {
    _showEditTimingDialog(provider, provider.periodTimings.first);
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
                const Text('Select Subject:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
                const Text('Select Teacher:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
                subtitle: const Text('Drag this card or select it to swap with another period', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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
              ? const Center(
                  child: Text(
                    'All constraint suggestions have been satisfied!\nYour schedule is running at peak mathematical efficiency.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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

  // =========================================================================
  // PDF PAGE 2: Live Deadlock Negotiation Inline Banner & Modal
  // =========================================================================

  Widget _buildInlineDeadlockBanner(TimetableProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withValues(alpha: 0.25),
            const Color(0xFFDC2626).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFFCA5A5), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Resolver Deadlock: Process Halted at 98%',
                      style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFFCA5A5)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Science Lab Bottleneck', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Both Mrs. Adams & Mr. Clark scheduled simultaneously on Wednesday Period 3 in Science Lab A.',
                  style: AppTypography.inter(fontSize: 11, color: const Color(0xFFE2E8F0)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => provider.resolveDeadlock(1),
            child: const Text('Option 1: Thu P1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              provider.resolveDeadlock(2);
              _showToast('Accepted Option 2: Reassigned to Room 204. Schedule 100% complete!');
            },
            child: const Text('Accept Option 2 (Room 204)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeLockBanner(TimetableProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Realtime Generation Lock (${provider.generationLock.progress}%): Locked by ${provider.generationLock.lockedBy}. Streaming AI solver logs...',
              style: AppTypography.inter(fontSize: 11, color: const Color(0xFFBAE6FD), fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            provider.generationLock.latestAiLog ?? '',
            style: const TextStyle(fontSize: 10, color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PDF PAGE 1: The NLP Bridge Modal: Natural Language to Strict Constraints
  // =========================================================================

  void _showNlpBridgeModal(TimetableProvider provider) {
    final controller = TextEditingController(
      text: 'Mr. Davis is a part-time teacher. He cannot teach on Friday mornings, and he needs Thursday off entirely.',
    );
    Map<String, dynamic>? result = provider.parseAndApplyNlpConstraint(controller.text);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return BackdropFilter(
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
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. The NLP Bridge: Natural Language to Strict Constraints',
                        style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'LLM translates human requests into standardized JSON and proprietary aSc XML (.roz or .xml)',
                        style: AppTypography.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Real-World Architectural Examples from PDF:', style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFA5B4FC))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(CupertinoIcons.person_badge_minus_fill, size: 14, color: Color(0xFF8B5CF6)),
                          label: const Text('Example A: Teacher Unavailability (Mr. Davis)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          onPressed: () {
                            setModalState(() {
                              controller.text = 'Mr. Davis is a part-time teacher. He cannot teach on Friday mornings, and he needs Thursday off entirely.';
                              result = provider.parseAndApplyNlpConstraint(controller.text);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(CupertinoIcons.calendar_today, size: 14, color: Color(0xFF38BDF8)),
                          label: const Text('Example B: Subject Distribution (Grade 10 Math)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          onPressed: () {
                            setModalState(() {
                              controller.text = "Grade 10 Math should be spread out. They can't have two math classes on the same day.";
                              result = provider.parseAndApplyNlpConstraint(controller.text);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.35),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                        hintText: 'Type constraint rule in natural language...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          result = provider.parseAndApplyNlpConstraint(val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (result != null) ...[
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Input Prompt & JSON Structure
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Input Admin Prompt & JSON Payload', style: TextStyle(fontSize: 10, color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('"${controller.text}"', style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
                                    const Divider(color: Colors.white12, height: 16),
                                    const Text('Standardized Transpiler JSON:', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          result!['jsonPayload'].toString(),
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF38BDF8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right: Output Generated aSc XML
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Output Generated aSc XML', style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          result!['generatedXml'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: Color(0xFFFDE047),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      result!['summary'] ?? '',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    provider.parseAndApplyNlpConstraint(controller.text);
                    Navigator.pop(ctx);
                    _showToast('Transpiled & Saved Constraint to Firebase & aSc XML!');
                  },
                  icon: const Icon(CupertinoIcons.checkmark_alt, size: 14),
                  label: const Text('Commit Constraint to Firebase'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // PDF PAGE 2: Negotiating Deadlocks: The AI Resolver Modal
  // =========================================================================

  void _showDeadlockResolverModal(TimetableProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isHalted = provider.isDeadlockActive;

          return BackdropFilter(
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
                        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.tuningfork, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Negotiating Deadlocks: The AI Resolver',
                        style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'Analyzes aSc engine errors, cross-references Firebase constraints, and proposes human-readable compromises.',
                        style: AppTypography.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diagram row from PDF Page 2
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFlowStep('ASC Engine Fails', const Color(0xFFEF4444)),
                          const Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.white38),
                          _buildFlowStep('AI Reads XML Log & Firebase Constraints', const Color(0xFF8B5CF6)),
                          const Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.white38),
                          _buildFlowStep('AI Proposes Compromise\n(e.g., "Relax Room 101 constraint")', const Color(0xFF10B981)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Trigger / Status Bar
                    Row(
                      children: [
                        Text('Real-World Scenario: The Science Lab Bottleneck', style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        if (!isHalted)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
                              foregroundColor: const Color(0xFFFCA5A5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setModalState(() {
                                provider.triggerScienceLabDeadlock();
                              });
                            },
                            icon: const Icon(CupertinoIcons.play_circle_fill, size: 14),
                            label: const Text('Simulate 98% Deadlock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                            child: const Text('STATUS: HALTED AT 98%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Deadlock Scenario Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isHalted ? const Color(0xFFEF4444).withValues(alpha: 0.4) : Colors.white12),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Generation Agent Statement:',
                                style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF38BDF8)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '"I encountered a deadlock preventing the schedule from completing. Both Mrs. Adams and Mr. Clark are scheduled to teach Chemistry simultaneously on Wednesday period 3, but only Science Lab A is equipped for 11th-grade experiments."',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontStyle: FontStyle.italic, height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Proposed Solutions:',
                                style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFA5B4FC)),
                              ),
                              const SizedBox(height: 8),

                              // Option 1
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('1. Move Mr. Clark\'s class to Thursday period 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          const Text('(Requires overriding his "No early mornings" soft constraint).', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                                      onPressed: () {
                                        provider.resolveDeadlock(1);
                                        Navigator.pop(ctx);
                                        _showToast('Accepted Option 1: Moved Mr. Clark to Thursday Period 1.');
                                      },
                                      child: const Text('Accept Option 1', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Option 2 (The one from PDF)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('2. Allow Mrs. Adams to teach in standard Classroom 204', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6EE7B7))),
                                          const SizedBox(height: 2),
                                          const Text('Drops strict room requirement for this specific session, regenerates XML, and reaches 100% convergence.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                                      onPressed: () {
                                        provider.resolveDeadlock(2);
                                        Navigator.pop(ctx);
                                        _showToast('The administrator clicks "Accept Option 2." The system updates Firebase, drops strict room requirement, and triggers aSc solver (100% success)!');
                                      },
                                      child: const Text('Accept Option 2 (PDF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlowStep(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // =========================================================================
  // PDF PAGE 4: The AI Substitution Agent Modal ("The 7:00 AM Call-In")
  // =========================================================================

  void _showAiSubstitutionAgentModal(TimetableProvider provider) {
    String absentTeacherId = 'T6_Reynolds'; // Mr. Reynolds
    int dayOfWeek = 2; // Tuesday
    int period = 2; // Period 2

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final eval = provider.evaluateSubstitutionCandidates(
            absentTeacherId: absentTeacherId,
            dayOfWeek: dayOfWeek,
            period: period,
          );

          final Teacher? topPick = eval['topPick'] as Teacher?;
          final String topPickRationale = eval['topPickRationale'] as String? ?? '';
          final Teacher? backup = eval['backup'] as Teacher?;
          final String backupRationale = eval['backupRationale'] as String? ?? '';

          return BackdropFilter(
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
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.person_2_alt, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. Beyond Planning: The AI Substitution Agent',
                        style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'Real-World Scenario: "The 7:00 AM Call-In" (Optimized operational decisions via Firestore)',
                        style: AppTypography.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 740,
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scenario callout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.clock_fill, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'At 7:00 AM on a Tuesday, Mr. Reynolds (History) marks himself sick. The AI immediately analyzes the day\'s schedule and finds his Period 2 Grade 9 History class requires cover.',
                              style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Controls row
                    Row(
                      children: [
                        const Text('Absent Teacher:', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: absentTeacherId,
                          dropdownColor: const Color(0xFF1E293B),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          items: provider.teachers.map((t) {
                            return DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.subjects.firstOrNull ?? ''})'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => absentTeacherId = val);
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text('Day:', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        DropdownButton<int>(
                          value: dayOfWeek,
                          dropdownColor: const Color(0xFF1E293B),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monday')),
                            DropdownMenuItem(value: 2, child: Text('Tuesday (7:00 AM)')),
                            DropdownMenuItem(value: 3, child: Text('Wednesday')),
                            DropdownMenuItem(value: 4, child: Text('Thursday')),
                            DropdownMenuItem(value: 5, child: Text('Friday')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => dayOfWeek = val);
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text('Period:', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        DropdownButton<int>(
                          value: period,
                          dropdownColor: const Color(0xFF1E293B),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          items: List.generate(8, (i) => i + 1).map((p) {
                            return DropdownMenuItem(value: p, child: Text('Period $p'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => period = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Split Matrix & Recommendation View
                    Expanded(
                      child: Row(
                        children: [
                          // Left: AI Decision Matrix (from PDF Page 4)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('AI Decision Matrix (PDF)', style: TextStyle(fontSize: 10, color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildMatrixCheckItem('1. Querying Firestore for Period $period schedule.', true),
                                  _buildMatrixCheckItem('2. Finding all teachers with Period $period free.', true),
                                  _buildMatrixCheckItem('3. Filtering out teachers who already maxed out their daily teaching load.', true),
                                  _buildMatrixCheckItem('4. Cross-referencing subject tags (History/Humanities).', true),
                                  const Spacer(),
                                  Text(
                                    '${eval['eligibleCandidatesCount']} faculty eligible under active collective contract load.',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right: AI Recommendation to Principal
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('AI Recommendation to Principal', style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"Mr. Reynolds is absent. His Period $period Grade 9 History class requires cover."',
                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 10),

                                  // Top Pick Card
                                  if (topPick != null)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFFF59E0B)),
                                              const SizedBox(width: 5),
                                              Text('Top Pick: ${topPick.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6EE7B7))),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(topPickRationale, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  // Backup Card
                                  if (backup != null)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(CupertinoIcons.shield_fill, size: 12, color: Color(0xFF38BDF8)),
                                              const SizedBox(width: 5),
                                              Text('Backup: ${backup.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(backupRationale, style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                        ],
                                      ),
                                    ),

                                  const Spacer(),
                                  if (topPick != null)
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        onPressed: () async {
                                          await provider.assignSubstitution(
                                            absentTeacherId: absentTeacherId,
                                            substituteTeacherId: topPick.id,
                                            dayOfWeek: dayOfWeek,
                                            period: period,
                                            date: '2026-10-20',
                                            reason: 'Sick leave call-in at 7:00 AM',
                                          );
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            _showToast('Assigned ${topPick.name}! Written to /daily_overrides/2026-10-20/ in Firestore. Push notification dispatched.');
                                          }
                                        },
                                        icon: const Icon(CupertinoIcons.checkmark_shield_fill, size: 14),
                                        label: Text('Assign ${topPick.name} (Write to /daily_overrides/)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatrixCheckItem(String title, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: isChecked ? const Color(0xFF10B981) : Colors.white38,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isChecked ? Colors.white : Colors.white60,
                fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
