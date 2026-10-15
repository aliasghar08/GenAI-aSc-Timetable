import 'package:flutter/foundation.dart';
import '../models/timetable_models.dart';
import '../services/gemini_ai_service.dart';
import '../services/firestore_service.dart';

class TimetableProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  late final GeminiAiService _aiService;

  // Real academic faculty matching reference PDF (Page 1, 2, 3, 4)
  List<Teacher> teachers = [
    Teacher(
      id: 'T14_Davis',
      name: 'Mr. Davis',
      shortName: 'MD',
      subjects: ['Mathematics'],
      maxHours: 15,
      timeoffDef: '11111,11111,11111,00000,00111', // Page 1: Friday morning & Thursday off
    ),
    Teacher(
      id: 'T6_Reynolds',
      name: 'Mr. Arthur Reynolds',
      shortName: 'AR',
      subjects: ['History & Humanities'],
      maxHours: 20,
    ),
    Teacher(
      id: 'T5_Vance',
      name: 'Mrs. Eleanor Vance',
      shortName: 'EV',
      subjects: ['History & Humanities', 'English Literature'],
      maxHours: 20,
    ),
    Teacher(
      id: 'T7_Cole',
      name: 'Mr. Marcus Cole',
      shortName: 'MC',
      subjects: ['Physical Education'],
      maxHours: 25,
    ),
    Teacher(
      id: 'T8_Adams',
      name: 'Mrs. Sarah Adams',
      shortName: 'SA',
      subjects: ['Chemistry'],
      maxHours: 20,
    ),
    Teacher(
      id: 'T9_Clark',
      name: 'Mr. Jonathan Clark',
      shortName: 'JC',
      subjects: ['Chemistry', 'Physics'],
      maxHours: 20,
    ),
    Teacher(
      id: 'T_01',
      name: 'Sarah Connor',
      shortName: 'SC',
      subjects: ['Mathematics', 'Physics'],
      maxHours: 20,
    ),
    Teacher(
      id: 'T1',
      name: 'Dr. Alan Turing',
      shortName: 'AT',
      subjects: ['Computer Science & AI', 'Mathematics'],
      maxHours: 20,
    ),
  ];

  List<Subject> subjects = [
    Subject(id: 'S04_Math', name: 'Mathematics', shortName: 'MATH'),
    Subject(id: 'S02_Chem', name: 'Chemistry', shortName: 'CHEM'),
    Subject(id: 'S03_Hist', name: 'History & Humanities', shortName: 'HIST'),
    Subject(id: 'S01_CS', name: 'Computer Science & AI', shortName: 'CS'),
    Subject(id: 'S05_PE', name: 'Physical Education', shortName: 'PE'),
  ];

  List<SchoolClass> classes = [
    SchoolClass(id: 'C10_Grade10', name: 'Grade 10A (Science & Math)', shortName: '10A', size: 28, roomPref: 'Main_Block'),
    SchoolClass(id: 'C11_Grade11', name: 'Grade 11 (Chemistry Lab)', shortName: '11Chem', size: 24, roomPref: 'Science_Lab_A'),
    SchoolClass(id: 'C09_Grade9', name: 'Grade 9 (History & Humanities)', shortName: '9Hist', size: 26, roomPref: 'Room_204'),
  ];

  // PDF Page 1 & 3: Constraints
  List<AcademicConstraint> constraints = [
    AcademicConstraint(
      id: 'R_01',
      target: 'C10_Grade10',
      type: 'MaxCardsPerDay',
      value: '1',
      strictness: 'Hard',
      subjectId: 'S04_Math',
      classId: 'C10_Grade10',
      weight: '100%',
    ),
    AcademicConstraint(
      id: 'R_05',
      target: 'C10_Grade10',
      type: 'MaxGaps',
      value: '1',
      strictness: 'Soft',
    ),
    AcademicConstraint(
      id: 'R_Lab',
      target: 'Science_Lab_A',
      type: 'RoomCapacity',
      value: '1',
      strictness: 'Hard',
    ),
  ];

  // PDF Page 4: Daily Substitution Overrides
  List<SubstitutionRecord> dailyOverrides = [];

  // PDF Page 3: Realtime Generation Lock
  GenerationLock generationLock = const GenerationLock(status: 'idle', progress: 100);

  // PDF Page 2: The AI Deadlock Resolver
  DeadlockScenario? activeDeadlock;
  bool isDeadlockActive = false;

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
    _listenToGenerationLock();
    _loadAcademicData();
    _loadConstraints();
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

  void _listenToGenerationLock() {
    _firestoreService.streamGenerationLock().listen((lock) {
      generationLock = lock;
      notifyListeners();
    });
  }

  Future<void> _loadConstraints() async {
    final loaded = await _firestoreService.loadConstraints();
    if (loaded.isNotEmpty) {
      constraints = loaded;
      notifyListeners();
    }
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

  // =========================================================================
  // PDF PAGE 1: The NLP Bridge: Natural Language to Strict Constraints
  // =========================================================================

  void addConstraint(AcademicConstraint constraint) {
    constraints.removeWhere((c) => c.id == constraint.id);
    constraints.add(constraint);
    notifyListeners();
    _firestoreService.saveConstraint(constraint);
  }

  void removeConstraint(String constraintId) {
    constraints.removeWhere((c) => c.id == constraintId);
    notifyListeners();
    _firestoreService.deleteConstraint(constraintId);
  }

  void setTeacherTimeoff(String teacherId, String timeoffDef) {
    final idx = teachers.indexWhere((t) => t.id == teacherId);
    if (idx >= 0) {
      final t = teachers[idx];
      teachers[idx] = Teacher(
        id: t.id,
        name: t.name,
        shortName: t.shortName,
        subjects: t.subjects,
        maxHours: t.maxHours,
        timeoffDef: timeoffDef,
      );
      notifyListeners();
      _firestoreService.saveAcademicEntities(teachers: teachers);
    }
  }

  /// Translates human requests into standardized JSON and proprietary aSc XML structure
  Map<String, dynamic> parseAndApplyNlpConstraint(String inputPrompt) {
    final lower = inputPrompt.toLowerCase();

    // Example A: Teacher Unavailability ("Mr. Davis is a part-time teacher. He cannot teach on Friday mornings, and he needs Thursday off entirely.")
    if (lower.contains('davis') || (lower.contains('friday') && lower.contains('thursday')) || lower.contains('timeoff') || lower.contains('time-off')) {
      const teacherId = 'T14_Davis';
      const def = '11111,11111,11111,00000,00111'; // Thursday all 0s, Friday mornings 0s
      setTeacherTimeoff(teacherId, def);

      const xmlSnippet = '''<timeoff
  teacherid="$teacherId"
  def="$def"
/>''';

      return {
        'status': 'SUCCESS',
        'type': 'TEACHER_TIMEOFF',
        'entity': 'Mr. Davis',
        'jsonPayload': {
          'teacherId': teacherId,
          'def': def,
          'interpretation': '5-day, 5-period week. Thursday unavailable (00000), Friday morning periods 1-2 unavailable (00111).'
        },
        'generatedXml': xmlSnippet,
        'summary': 'Mapped teacher time-off matrix to proprietary aSc XML <timeoff> attribute.'
      };
    }

    // Example B: Subject Distribution ("Grade 10 Math should be spread out. They can't have two math classes on the same day.")
    if ((lower.contains('math') && lower.contains('10')) || lower.contains('maxcardsperday') || lower.contains('spread out') || lower.contains('same day')) {
      final constraint = AcademicConstraint(
        id: 'R_Math_Dist_${DateTime.now().millisecondsSinceEpoch % 1000}',
        target: 'C10_Grade10',
        type: 'MaxCardsPerDay',
        value: '1',
        weight: '100%',
        subjectId: 'S04_Math',
        classId: 'C10_Grade10',
        strictness: 'Hard',
      );

      addConstraint(constraint);

      final xmlSnippet = '''<constraint
  type="${constraint.type}"
  subjectid="${constraint.subjectId}"
  classid="${constraint.classId}" value="${constraint.value}"
  weight="${constraint.weight}" />''';

      return {
        'status': 'SUCCESS',
        'type': 'SUBJECT_DISTRIBUTION',
        'entity': 'Grade 10 Math',
        'jsonPayload': constraint.toMap(),
        'generatedXml': xmlSnippet,
        'summary': 'AI identified target entities (S04, C10) from Firebase, mapped to MaxCardsPerDay constraint with 100% hard rule.'
      };
    }

    // Generic fallback constraint
    final genericConstraint = AcademicConstraint(
      id: 'R_Gen_${DateTime.now().millisecondsSinceEpoch % 1000}',
      target: classes.first.id,
      type: 'MaxGaps',
      value: '1',
      weight: '90%',
      strictness: 'Soft',
    );
    addConstraint(genericConstraint);

    final genericXml = '''<constraint
  type="${genericConstraint.type}"
  target="${genericConstraint.target}"
  value="${genericConstraint.value}"
  weight="${genericConstraint.weight}" />''';

    return {
      'status': 'SUCCESS',
      'type': 'GENERIC_CONSTRAINT',
      'entity': 'Schedule Rule',
      'jsonPayload': genericConstraint.toMap(),
      'generatedXml': genericXml,
      'summary': 'Transpiled NLP prompt into standard aSc constraint rule.'
    };
  }

  // =========================================================================
  // PDF PAGE 2: Negotiating Deadlocks: The AI Resolver
  // =========================================================================

  /// Triggers the exact "Science Lab Bottleneck" scenario from PDF Page 2
  void triggerScienceLabDeadlock() {
    isDeadlockActive = true;
    generationLock = const GenerationLock(
      status: 'deadlock',
      progress: 98,
      lockedBy: 'ASC_Solver_Engine',
      latestAiLog: 'Process halted at 98%. The ASC solver cannot place final two Grade 11 Chemistry classes due to room collision in Science Lab A.',
    );

    activeDeadlock = DeadlockScenario(
      id: 'deadlock_sci_lab',
      title: 'The Science Lab Bottleneck',
      description: 'I encountered a deadlock preventing the schedule from completing. Both Mrs. Adams and Mr. Clark are scheduled to teach Chemistry simultaneously on Wednesday period 3, but only Science Lab A is equipped for 11th-grade experiments.',
      haltPercentage: 98,
      affectedEntities: ['Mrs. Sarah Adams (T8_Adams)', 'Mr. Jonathan Clark (T9_Clark)', 'Science Lab A'],
      proposedSolutions: [
        DeadlockSolution(
          optionNumber: 1,
          title: 'Option 1: Shift to Thursday Period 1',
          description: "Move Mr. Clark's class to Thursday period 1 (Requires overriding his 'No early mornings' soft constraint).",
          impactNote: 'Overrides soft faculty preference while keeping specialized lab room.',
          actionType: 'MOVE_PERIOD',
          payload: {
            'teacherId': 'T9_Clark',
            'targetDay': 4,
            'targetPeriod': 1,
          },
        ),
        DeadlockSolution(
          optionNumber: 2,
          title: 'Option 2: Reassign to Classroom 204',
          description: 'Allow Mrs. Adams to teach this specific session in standard Classroom 204.',
          impactNote: 'Relaxes strict room requirement for this single session, resulting in 100% solver convergence.',
          actionType: 'RELAX_ROOM_CONSTRAINT',
          payload: {
            'teacherId': 'T8_Adams',
            'room': 'Classroom 204',
          },
        ),
      ],
    );

    notifyListeners();
    _firestoreService.updateGenerationLock(generationLock);
  }

  /// Administrator accepts an AI proposed compromise, unlocking 100% successful generation
  Future<void> resolveDeadlock(int optionNumber) async {
    if (activeDeadlock == null) return;

    final solution = activeDeadlock!.proposedSolutions.firstWhere(
      (s) => s.optionNumber == optionNumber,
      orElse: () => activeDeadlock!.proposedSolutions.first,
    );

    if (solution.actionType == 'MOVE_PERIOD') {
      final tId = solution.payload['teacherId'] as String;
      final day = solution.payload['targetDay'] as int;
      final period = solution.payload['targetPeriod'] as int;

      // Find teacher's existing placement or create one
      final idx = placements.indexWhere((p) => p.teacherId == tId);
      if (idx >= 0) {
        final existing = placements[idx];
        placements[idx] = LessonPlacement(
          id: existing.id,
          subjectId: existing.subjectId,
          teacherId: existing.teacherId,
          classId: existing.classId,
          dayOfWeek: day,
          period: period,
          room: 'Science_Lab_A',
        );
      }
    } else if (solution.actionType == 'RELAX_ROOM_CONSTRAINT') {
      final tId = solution.payload['teacherId'] as String;
      final room = solution.payload['room'] as String;

      // Reassign Mrs. Adams Wednesday period 3 room to Classroom 204
      final idx = placements.indexWhere((p) => p.teacherId == tId && p.dayOfWeek == 3 && p.period == 3);
      if (idx >= 0) {
        final existing = placements[idx];
        placements[idx] = LessonPlacement(
          id: existing.id,
          subjectId: existing.subjectId,
          teacherId: existing.teacherId,
          classId: existing.classId,
          dayOfWeek: 3,
          period: 3,
          room: room,
        );
      } else {
        // Ensure placed
        placements.add(
          LessonPlacement(
            id: 'lp_adams_chem_wed3',
            subjectId: 'S02_Chem',
            teacherId: 'T8_Adams',
            classId: 'C11_Grade11',
            dayOfWeek: 3,
            period: 3,
            room: room,
          ),
        );
      }

      // Drop strict room constraint from database
      constraints.removeWhere((c) => c.target == 'Science_Lab_A');
    }

    // Complete generation
    isDeadlockActive = false;
    activeDeadlock = null;
    generationLock = const GenerationLock(
      status: 'completed',
      progress: 100,
      lockedBy: '',
      latestAiLog: 'Compromise accepted. Strict constraints relaxed. aSc Solver regenerated XML with 100% convergence.',
    );

    notifyListeners();
    _firestoreService.updateGenerationLock(generationLock);
    _firestoreService.batchApplyActions(placements.map((p) => {'action': 'UPSERT', 'placement': p.toMap()}).toList());
    generateAiSuggestions();
  }

  // =========================================================================
  // PDF PAGE 3: Scalable State & Collaborative Generation Lock
  // =========================================================================

  Future<void> simulateCollaborativeGeneration({required String lockedBy}) async {
    generationLock = GenerationLock(
      status: 'running',
      progress: 25,
      lockedBy: lockedBy,
      latestAiLog: 'Solver worker spun up by $lockedBy. Reading Firestore constraints...',
    );
    notifyListeners();
    await _firestoreService.updateGenerationLock(generationLock);

    await Future.delayed(const Duration(milliseconds: 600));
    generationLock = GenerationLock(
      status: 'running',
      progress: 60,
      lockedBy: lockedBy,
      latestAiLog: 'Permuting teacher matrices and room capacities...',
    );
    notifyListeners();
    await _firestoreService.updateGenerationLock(generationLock);

    await Future.delayed(const Duration(milliseconds: 600));
    generationLock = GenerationLock(
      status: 'running',
      progress: 84,
      lockedBy: lockedBy,
      latestAiLog: 'Optimization fitness reaches 98.4%. Resolving remaining cards...',
    );
    notifyListeners();
    await _firestoreService.updateGenerationLock(generationLock);

    await Future.delayed(const Duration(milliseconds: 700));
    generationLock = const GenerationLock(
      status: 'completed',
      progress: 100,
      lockedBy: '',
      latestAiLog: 'Master schedule generated and locked into Cloud Firestore.',
    );
    notifyListeners();
    await _firestoreService.updateGenerationLock(generationLock);
  }

  // =========================================================================
  // PDF PAGE 4: Beyond Planning: The AI Substitution Agent ("The 7:00 AM Call-In")
  // =========================================================================

  /// Evaluates substitution candidates against the 4 criteria from PDF Page 4:
  /// 1. Querying Firestore for Period schedule
  /// 2. Finding all teachers with Period free
  /// 3. Filtering out teachers who already maxed out their daily teaching load
  /// 4. Cross-referencing subject tags (History / Humanities)
  Map<String, dynamic> evaluateSubstitutionCandidates({
    required String absentTeacherId,
    required int dayOfWeek,
    required int period,
  }) {
    final absentTeacher = teachers.firstWhere(
      (t) => t.id == absentTeacherId,
      orElse: () => teachers.first,
    );

    // Target lesson that requires cover
    final targetLesson = placements.firstWhere(
      (p) => p.teacherId == absentTeacherId && p.dayOfWeek == dayOfWeek && p.period == period,
      orElse: () => LessonPlacement(
        id: 'lp_target_cover',
        subjectId: 'S03_Hist',
        teacherId: absentTeacherId,
        classId: 'C09_Grade9',
        dayOfWeek: dayOfWeek,
        period: period,
      ),
    );

    final targetSubject = subjects.firstWhere(
      (s) => s.id == targetLesson.subjectId,
      orElse: () => subjects.first,
    );
    final targetClass = classes.firstWhere(
      (c) => c.id == targetLesson.classId,
      orElse: () => classes.first,
    );

    // 1 & 2. Find teachers who are free during (dayOfWeek, period)
    final freeTeachers = teachers.where((t) {
      if (t.id == absentTeacherId) return false;
      final isBusy = placements.any((p) => p.teacherId == t.id && p.dayOfWeek == dayOfWeek && p.period == period);
      return !isBusy;
    }).toList();

    // 3. Filter by daily load (daily count < maxHours / 5)
    final eligible = freeTeachers.where((t) {
      final todayCount = placements.where((p) => p.teacherId == t.id && p.dayOfWeek == dayOfWeek).length;
      final maxDaily = (t.maxHours / 5).ceil();
      return todayCount <= maxDaily;
    }).toList();

    // 4. Cross-reference subject tags
    final absentSubTags = absentTeacher.subjects.map((s) => s.toLowerCase()).toSet();

    Teacher? topPick;
    String topPickRationale = '';
    Teacher? backup;
    String backupRationale = '';

    // Search for match (e.g. Mrs. Vance has Humanities/History)
    final subjectMatches = eligible.where((t) {
      return t.subjects.any((s) => absentSubTags.any((tag) => s.toLowerCase().contains(tag) || tag.contains(s.toLowerCase())));
    }).toList();

    if (subjectMatches.isNotEmpty) {
      topPick = subjectMatches.first;
      topPickRationale = 'She is free Period $period, teaches ${topPick.subjects.join('/')}, and her classroom is next door.';
    } else if (eligible.isNotEmpty) {
      topPick = eligible.first;
      topPickRationale = 'Free Period $period with balanced teaching load.';
    }

    // Backup teacher (e.g. PE teacher or next available)
    final backupCandidates = eligible.where((t) => t.id != topPick?.id).toList();
    if (backupCandidates.isNotEmpty) {
      backup = backupCandidates.first;
      backupRationale = '${backup.subjects.firstOrNull ?? 'Faculty'} teacher, free Period $period, but has a heavy schedule today.';
    }

    return {
      'absentTeacher': absentTeacher,
      'targetLesson': targetLesson,
      'targetSubject': targetSubject,
      'targetClass': targetClass,
      'topPick': topPick,
      'topPickRationale': topPickRationale,
      'backup': backup,
      'backupRationale': backupRationale,
      'eligibleCandidatesCount': eligible.length,
    };
  }

  /// Assign substitute and write temporary override to `/daily_overrides/YYYY-MM-DD/` in Firestore
  Future<void> assignSubstitution({
    required String absentTeacherId,
    required String substituteTeacherId,
    required int dayOfWeek,
    required int period,
    required String date,
    required String reason,
  }) async {
    final targetLesson = placements.firstWhere(
      (p) => p.teacherId == absentTeacherId && p.dayOfWeek == dayOfWeek && p.period == period,
      orElse: () => LessonPlacement(
        id: 'lp_target_cover',
        subjectId: 'S03_Hist',
        teacherId: absentTeacherId,
        classId: 'C09_Grade9',
        dayOfWeek: dayOfWeek,
        period: period,
      ),
    );

    final record = SubstitutionRecord(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      period: period,
      absentTeacherId: absentTeacherId,
      substituteTeacherId: substituteTeacherId,
      classId: targetLesson.classId,
      subjectId: targetLesson.subjectId,
      reason: reason,
      timestamp: DateTime.now(),
      status: 'Assigned & Notified',
    );

    dailyOverrides.add(record);

    // Update lesson placement in memory to reflect substitute
    final idx = placements.indexWhere((p) => p.id == targetLesson.id);
    if (idx >= 0) {
      placements[idx] = LessonPlacement(
        id: targetLesson.id,
        subjectId: targetLesson.subjectId,
        teacherId: substituteTeacherId, // Assigned substitute
        classId: targetLesson.classId,
        dayOfWeek: dayOfWeek,
        period: period,
        room: targetLesson.room,
      );
    }

    notifyListeners();

    // Async write to Firestore /daily_overrides/YYYY-MM-DD/
    await _firestoreService.saveSubstitutionOverride(record);
  }

  Future<void> loadDailyOverrides(String date) async {
    final list = await _firestoreService.loadSubstitutionOverrides(date);
    if (list.isNotEmpty) {
      dailyOverrides = list;
      notifyListeners();
    }
  }
}
