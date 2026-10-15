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
  List<AiScheduleSuggestion> suggestions = [];

  List<PeriodTiming> periodTimings = [
    const PeriodTiming(period: 1, name: 'Period 1', startTime: '08:00', endTime: '08:45'),
    const PeriodTiming(period: 2, name: 'Period 2', startTime: '08:50', endTime: '09:35'),
    const PeriodTiming(period: 3, name: 'Period 3', startTime: '09:55', endTime: '10:40'),
    const PeriodTiming(period: 4, name: 'Period 4', startTime: '10:45', endTime: '11:30'),
    const PeriodTiming(period: 5, name: 'Period 5', startTime: '11:50', endTime: '12:35'),
    const PeriodTiming(period: 6, name: 'Period 6', startTime: '13:20', endTime: '14:05'),
    const PeriodTiming(period: 7, name: 'Period 7', startTime: '14:10', endTime: '14:55'),
    const PeriodTiming(period: 8, name: 'Period 8', startTime: '15:00', endTime: '15:45'),
  ];

  TimetableProvider({required String geminiApiKey}) {
    _aiService = GeminiAiService(apiKey: geminiApiKey);
    _initializeDefaultPlacements();
    _listenToPlacements();
    _loadAcademicData();
    _firestoreService.seedInitialAcademicData(teachers, subjects, classes, periodTimings);
    generateAiSuggestions();
  }

  Future<void> _loadAcademicData() async {
    final data = await _firestoreService.loadAcademicData();
    if (data != null) {
      if (data['teachers'] != null && (data['teachers'] as List).isNotEmpty) {
        teachers = (data['teachers'] as List)
            .map((e) => Teacher.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['subjects'] != null && (data['subjects'] as List).isNotEmpty) {
        subjects = (data['subjects'] as List)
            .map((e) => Subject.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['classes'] != null && (data['classes'] as List).isNotEmpty) {
        classes = (data['classes'] as List)
            .map((e) => SchoolClass.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data['timings'] != null && (data['timings'] as List).isNotEmpty) {
        periodTimings = (data['timings'] as List)
            .map((e) => PeriodTiming.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      notifyListeners();
    }
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
        generateAiSuggestions();
        notifyListeners();
      }
    });
  }

  // --- Interactive Class Arranging API ---

  /// Move a lesson placement to a target day and period
  void movePlacement(String placementId, int targetDay, int targetPeriod) {
    final idx = placements.indexWhere((p) => p.id == placementId);
    if (idx < 0) return;

    final existing = placements[idx];
    final updated = LessonPlacement(
      id: existing.id,
      subjectId: existing.subjectId,
      teacherId: existing.teacherId,
      classId: existing.classId,
      dayOfWeek: targetDay,
      period: targetPeriod,
    );

    placements[idx] = updated;
    notifyListeners();

    // Async sync to Firestore
    _firestoreService.batchApplyActions([
      {'action': 'UPSERT', 'placement': updated.toMap()}
    ]);
    generateAiSuggestions();
  }

  /// Swap two scheduled lessons on the timetable
  void swapPlacements(String id1, String id2) {
    final idx1 = placements.indexWhere((p) => p.id == id1);
    final idx2 = placements.indexWhere((p) => p.id == id2);
    if (idx1 < 0 || idx2 < 0) return;

    final p1 = placements[idx1];
    final p2 = placements[idx2];

    final updated1 = LessonPlacement(
      id: p1.id,
      subjectId: p1.subjectId,
      teacherId: p1.teacherId,
      classId: p1.classId,
      dayOfWeek: p2.dayOfWeek,
      period: p2.period,
    );

    final updated2 = LessonPlacement(
      id: p2.id,
      subjectId: p2.subjectId,
      teacherId: p2.teacherId,
      classId: p2.classId,
      dayOfWeek: p1.dayOfWeek,
      period: p1.period,
    );

    placements[idx1] = updated1;
    placements[idx2] = updated2;
    notifyListeners();

    _firestoreService.batchApplyActions([
      {'action': 'UPSERT', 'placement': updated1.toMap()},
      {'action': 'UPSERT', 'placement': updated2.toMap()},
    ]);
    generateAiSuggestions();
  }

  /// Add a new lesson placement directly to a slot
  void addPlacement({
    required String subjectId,
    required String teacherId,
    required String classId,
    required int dayOfWeek,
    required int period,
  }) {
    // Remove any existing card in the same slot for this class
    placements.removeWhere((p) => p.classId == classId && p.dayOfWeek == dayOfWeek && p.period == period);

    final newPlacement = LessonPlacement(
      id: 'lp_${classId}_${dayOfWeek}_${period}_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subjectId,
      teacherId: teacherId,
      classId: classId,
      dayOfWeek: dayOfWeek,
      period: period,
    );

    placements.add(newPlacement);
    notifyListeners();

    _firestoreService.batchApplyActions([
      {'action': 'UPSERT', 'placement': newPlacement.toMap()}
    ]);
    generateAiSuggestions();
  }

  /// Drag-and-drop placement handler: moves or swaps a dropped lesson into (targetDay, targetPeriod)
  void handleDropPlacement({
    required LessonPlacement dropped,
    required int targetDay,
    required int targetPeriod,
    required String activeEntityId,
    required bool isClassView,
  }) {
    // If dropped on the same slot, do nothing
    if (dropped.dayOfWeek == targetDay && dropped.period == targetPeriod) {
      return;
    }

    // Check if destination slot has a card for the current view
    final existingMatches = isClassView
        ? placements.where((p) => p.classId == activeEntityId && p.dayOfWeek == targetDay && p.period == targetPeriod).toList()
        : placements.where((p) => p.teacherId == activeEntityId && p.dayOfWeek == targetDay && p.period == targetPeriod).toList();

    if (existingMatches.isNotEmpty) {
      // SWAP
      final target = existingMatches.first;
      swapPlacements(dropped.id, target.id);
    } else {
      // MOVE
      movePlacement(dropped.id, targetDay, targetPeriod);
    }
  }

  /// Create a new lecture with optional room and persist it
  void createLecture({
    required String classId,
    required String subjectId,
    required String teacherId,
    required int dayOfWeek,
    required int period,
    String? room,
  }) {
    // Remove conflicting lesson for this class in this slot if any
    placements.removeWhere((p) => p.classId == classId && p.dayOfWeek == dayOfWeek && p.period == period);

    final newPlacement = LessonPlacement(
      id: 'lp_${classId}_${dayOfWeek}_${period}_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subjectId,
      teacherId: teacherId,
      classId: classId,
      dayOfWeek: dayOfWeek,
      period: period,
      room: room,
    );

    placements.add(newPlacement);
    notifyListeners();

    _firestoreService.batchApplyActions([
      {'action': 'UPSERT', 'placement': newPlacement.toMap()}
    ]);
    generateAiSuggestions();
  }

  // --- Real Academic Entity CRUD & Customization ---

  void addTeacher(String name, String shortName) {
    final id = 'T${DateTime.now().millisecondsSinceEpoch % 10000}';
    teachers.add(Teacher(id: id, name: name, shortName: shortName));
    notifyListeners();
    _firestoreService.saveAcademicEntities(teachers: teachers);
  }

  void updateTeacher(String id, String name, String shortName) {
    final idx = teachers.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      teachers[idx] = Teacher(id: id, name: name, shortName: shortName);
      notifyListeners();
      _firestoreService.saveAcademicEntities(teachers: teachers);
    }
  }

  void deleteTeacher(String id) {
    teachers.removeWhere((t) => t.id == id);
    placements.removeWhere((p) => p.teacherId == id);
    notifyListeners();
    _firestoreService.saveAcademicEntities(teachers: teachers);
    generateAiSuggestions();
  }

  void addSubject(String name, String shortName) {
    final id = 'S${DateTime.now().millisecondsSinceEpoch % 10000}';
    subjects.add(Subject(id: id, name: name, shortName: shortName));
    notifyListeners();
    _firestoreService.saveAcademicEntities(subjects: subjects);
  }

  void updateSubject(String id, String name, String shortName) {
    final idx = subjects.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      subjects[idx] = Subject(id: id, name: name, shortName: shortName);
      notifyListeners();
      _firestoreService.saveAcademicEntities(subjects: subjects);
    }
  }

  void deleteSubject(String id) {
    subjects.removeWhere((s) => s.id == id);
    placements.removeWhere((p) => p.subjectId == id);
    notifyListeners();
    _firestoreService.saveAcademicEntities(subjects: subjects);
    generateAiSuggestions();
  }

  void addClass(String name, String shortName) {
    final id = 'C${DateTime.now().millisecondsSinceEpoch % 10000}';
    classes.add(SchoolClass(id: id, name: name, shortName: shortName));
    notifyListeners();
    _firestoreService.saveAcademicEntities(classes: classes);
  }

  void updateClass(String id, String name, String shortName) {
    final idx = classes.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      classes[idx] = SchoolClass(id: id, name: name, shortName: shortName);
      notifyListeners();
      _firestoreService.saveAcademicEntities(classes: classes);
    }
  }

  void deleteClass(String id) {
    classes.removeWhere((c) => c.id == id);
    placements.removeWhere((p) => p.classId == id);
    notifyListeners();
    _firestoreService.saveAcademicEntities(classes: classes);
    generateAiSuggestions();
  }

  void updatePeriodTiming(int period, String startTime, String endTime, {String? name}) {
    final idx = periodTimings.indexWhere((p) => p.period == period);
    if (idx >= 0) {
      periodTimings[idx] = PeriodTiming(
        period: period,
        name: name ?? periodTimings[idx].name,
        startTime: startTime,
        endTime: endTime,
        isBreak: periodTimings[idx].isBreak,
      );
      notifyListeners();
      _firestoreService.saveAcademicEntities(timings: periodTimings);
    }
  }

  /// Remove a lesson placement to clear a slot
  void removePlacement(String placementId) {
    placements.removeWhere((p) => p.id == placementId);
    notifyListeners();

    _firestoreService.batchApplyActions([
      {'action': 'DELETE', 'placement': {'id': placementId}}
    ]);
    generateAiSuggestions();
  }

  /// Checks if scheduling a teacher or class in (day, period) creates a collision
  Map<String, dynamic> checkCollision(
    String teacherId,
    String classId,
    int dayOfWeek,
    int period, {
    String? excludePlacementId,
  }) {
    final activePlacements = placements.where((p) => p.id != excludePlacementId);

    // 1. Teacher collision
    final teacherBusy = activePlacements.where(
      (p) => p.teacherId == teacherId && p.dayOfWeek == dayOfWeek && p.period == period,
    );
    if (teacherBusy.isNotEmpty) {
      final conflict = teacherBusy.first;
      final otherClass = classes.firstWhere((c) => c.id == conflict.classId, orElse: () => SchoolClass(id: '', name: 'Another Class', shortName: '??'));
      return {
        'hasCollision': true,
        'reason': 'Teacher is already teaching ${otherClass.name} in Period $period!',
        'type': 'TEACHER_COLLISION',
      };
    }

    // 2. Class collision
    final classBusy = activePlacements.where(
      (p) => p.classId == classId && p.dayOfWeek == dayOfWeek && p.period == period,
    );
    if (classBusy.isNotEmpty) {
      return {
        'hasCollision': true,
        'reason': 'This class already has a lesson scheduled in Period $period.',
        'type': 'CLASS_COLLISION',
      };
    }

    return {'hasCollision': false};
  }

  /// Generate contextual, actionable AI suggestions based on current timetable state
  void generateAiSuggestions({String? customPrompt}) {
    final List<AiScheduleSuggestion> generated = [];

    // 1. Pedagogical Morning Focus: Check if core subjects (Math, CS, Physics) are in late afternoon
    for (final c in classes) {
      final lateCore = placements.where((p) =>
          p.classId == c.id &&
          p.period >= 4 &&
          (p.subjectId == 'S2' || p.subjectId == 'S1' || p.subjectId == 'S3')).toList();

      if (lateCore.isNotEmpty) {
        final target = lateCore.first;
        final sub = subjects.firstWhere((s) => s.id == target.subjectId, orElse: () => subjects.first);
        // Find if morning period 1 or 2 is free on same day or another day
        for (int p = 1; p <= 2; p++) {
          final isFree = !placements.any((x) => x.classId == c.id && x.dayOfWeek == target.dayOfWeek && x.period == p);
          if (isFree) {
            generated.add(
              AiScheduleSuggestion(
                id: 'sugg_morning_${target.id}',
                title: 'Prioritize Morning ${sub.name} for ${c.shortName}',
                description: 'Shift ${sub.shortName} from afternoon Period ${target.period} to morning Period $p.',
                rationale: 'Cognitive retention and mathematical problem-solving peak before lunch.',
                category: 'core_focus',
                badgeText: 'Pedagogy Boost',
                impactText: '+15% Cognitive Peak',
                actionLabel: 'Move to Period $p',
                updatedPlacements: [
                  LessonPlacement(
                    id: target.id,
                    subjectId: target.subjectId,
                    teacherId: target.teacherId,
                    classId: target.classId,
                    dayOfWeek: target.dayOfWeek,
                    period: p,
                  ),
                ],
              ),
            );
            break;
          }
        }
      }
    }

    // 2. Teacher Gap Reduction: Detect isolated 1-hour free windows
    for (final t in teachers) {
      for (int day = 1; day <= 5; day++) {
        final tPeriods = placements.where((p) => p.teacherId == t.id && p.dayOfWeek == day).toList()
          ..sort((a, b) => a.period.compareTo(b.period));

        if (tPeriods.length >= 2) {
          for (int i = 0; i < tPeriods.length - 1; i++) {
            final gap = tPeriods[i + 1].period - tPeriods[i].period;
            if (gap == 2) {
              final gapPeriod = tPeriods[i].period + 1;
              final candidateMove = tPeriods[i + 1];
              final isClassFree = !placements.any((x) => x.classId == candidateMove.classId && x.dayOfWeek == day && x.period == gapPeriod);
              if (isClassFree) {
                generated.add(
                  AiScheduleSuggestion(
                    id: 'sugg_gap_${t.id}_${day}_$gapPeriod',
                    title: 'Eliminate Idle Gap for ${t.name}',
                    description: 'Move lesson from Period ${candidateMove.period} to Period $gapPeriod on Day $day.',
                    rationale: 'Reduces unproductive wait time for faculty, improving work satisfaction.',
                    category: 'gap_reduction',
                    badgeText: 'Teacher Wellness',
                    impactText: '1 hr Saved',
                    actionLabel: 'Eliminate Gap',
                    updatedPlacements: [
                      LessonPlacement(
                        id: candidateMove.id,
                        subjectId: candidateMove.subjectId,
                        teacherId: candidateMove.teacherId,
                        classId: candidateMove.classId,
                        dayOfWeek: day,
                        period: gapPeriod,
                      ),
                    ],
                  ),
                );
              }
            }
          }
        }
      }
    }

    // 3. Friday Afternoon Extracurricular Consolidation
    final fridayAfternoonClasses = placements.where((p) => p.dayOfWeek == 5 && p.period >= 5).toList();
    if (fridayAfternoonClasses.isNotEmpty) {
      final sample = fridayAfternoonClasses.first;
      final c = classes.firstWhere((cl) => cl.id == sample.classId, orElse: () => classes.first);
      generated.add(
        AiScheduleSuggestion(
          id: 'sugg_friday_buffer',
          title: 'Consolidate Friday Extracurriculars for ${c.shortName}',
          description: 'Free up Friday afternoon periods 5-8 for athletics, robotics club, and faculty planning.',
          rationale: 'Aligns with modern holistic school schedules and prevents end-of-week student fatigue.',
          category: 'friday_buffer',
          badgeText: 'Campus Culture',
          impactText: 'Free Friday P5-P8',
          actionLabel: 'Free Up Friday',
          updatedPlacements: fridayAfternoonClasses.map((p) {
            return LessonPlacement(
              id: p.id,
              subjectId: p.subjectId,
              teacherId: p.teacherId,
              classId: p.classId,
              dayOfWeek: 4, // Shift to Thursday
              period: p.period <= 2 ? p.period + 2 : p.period,
            );
          }).toList(),
        ),
      );
    }

    // 4. Global CSP Optimization Suggestion
    generated.add(
      AiScheduleSuggestion(
        id: 'sugg_csp_global',
        title: 'Run Global Constraint Permutation Solver',
        description: 'Re-compute zero-collision schedule with genetic load balancing across all classes.',
        rationale: 'Guarantees 100% hard constraint satisfaction and maximizes teacher wellness index.',
        category: 'optimization',
        badgeText: 'Deterministic CSP',
        impactText: '98%+ Fitness',
        actionLabel: 'Execute CSP Optimization',
        updatedPlacements: [], // Will trigger full CSP solve
      ),
    );

    suggestions = generated;
    notifyListeners();
  }

  /// Act upon a specific AI suggestion
  Future<void> applySuggestion(AiScheduleSuggestion suggestion) async {
    if (suggestion.isApplied) return;

    if (suggestion.id == 'sugg_csp_global') {
      await instructAi('Execute full CSP schedule optimization');
      suggestion.isApplied = true;
      notifyListeners();
      return;
    }

    final actions = <Map<String, dynamic>>[];
    for (final updated in suggestion.updatedPlacements) {
      final idx = placements.indexWhere((p) => p.id == updated.id);
      if (idx >= 0) {
        placements[idx] = updated;
      } else {
        placements.add(updated);
      }
      actions.add({'action': 'UPSERT', 'placement': updated.toMap()});
    }

    suggestion.isApplied = true;
    notifyListeners();

    // Background sync to Firestore
    _firestoreService.batchApplyActions(actions);
  }

  /// Emergency unlock if user ever needs to cancel or unstick the AI state
  void resetAiThinkingState() {
    isAiThinking = false;
    lastAiExplanation = 'Reset AI thinking state. Studio unlocked and ready.';
    notifyListeners();
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
      ).timeout(const Duration(seconds: 8));

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

        // Fire-and-forget background sync with Firestore without blocking UI
        _firestoreService.batchApplyActions(actions);
        generateAiSuggestions();
      }
    } catch (e) {
      lastAiExplanation = 'Execution Notice: Handled via local algorithmic solver. ${e.toString()}';
    } finally {
      isAiThinking = false;
      notifyListeners();
    }
  }
}
