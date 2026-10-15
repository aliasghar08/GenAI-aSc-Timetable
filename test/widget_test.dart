import 'package:flutter_test/flutter_test.dart';
import 'package:genai_asc_timetable/models/timetable_models.dart';
import 'package:genai_asc_timetable/services/algorithmic_csp_solver.dart';
import 'package:genai_asc_timetable/services/asc_xml_service.dart';
import 'package:genai_asc_timetable/services/email_verification_service.dart';

void main() {
  test('aSc Timetables XML export & parse unit test', () {
    final teachers = [
      Teacher(id: 'T1', name: 'Dr. Alan Turing', shortName: 'AT'),
      Teacher(id: 'T2', name: 'Prof. Ada Lovelace', shortName: 'AL'),
    ];
    final subjects = [
      Subject(id: 'S1', name: 'Computer Science', shortName: 'CS'),
      Subject(id: 'S2', name: 'Mathematics', shortName: 'MATH'),
    ];
    final classes = [
      SchoolClass(id: 'C1', name: 'Grade 10-A', shortName: '10A'),
    ];
    final placements = [
      LessonPlacement(
        id: 'L1',
        subjectId: 'S1',
        teacherId: 'T1',
        classId: 'C1',
        dayOfWeek: 1,
        period: 1,
      ),
    ];

    final xml = AscXmlService.exportToAscXml(
      teachers: teachers,
      subjects: subjects,
      classes: classes,
      placements: placements,
    );

    expect(xml, contains('<timetable importtype="database"'));
    expect(xml, contains('Dr. Alan Turing'));
    expect(xml, contains('Computer Science'));
    expect(xml, contains('Grade 10-A'));

    final parsed = AscXmlService.parseAscXml(xml);
    expect(parsed['teachers'].length, equals(2));
    expect(parsed['subjects'].length, equals(2));
    expect(parsed['classes'].length, equals(1));
  });

  test('Deterministic Algorithmic CSP Solver solves schedule with 0 collisions', () {
    final teachers = [
      Teacher(id: 'T1', name: 'Dr. Alan Turing', shortName: 'AT'),
      Teacher(id: 'T2', name: 'Prof. Ada Lovelace', shortName: 'AL'),
      Teacher(id: 'T3', name: 'Dr. Marie Curie', shortName: 'MC'),
    ];
    final subjects = [
      Subject(id: 'S1', name: 'Computer Science', shortName: 'CS'),
      Subject(id: 'S2', name: 'Mathematics', shortName: 'MATH'),
      Subject(id: 'S3', name: 'Physics', shortName: 'PHYS'),
    ];
    final classes = [
      SchoolClass(id: 'C1', name: 'Grade 10-A', shortName: '10A'),
      SchoolClass(id: 'C2', name: 'Grade 11-B', shortName: '11B'),
    ];

    final solver = AlgorithmicCspSolver();
    const constraints = CspConstraintSpec(
      freeFridayAfternoon: true,
      maxDailyPeriodsPerTeacher: 4,
    );

    final solution = solver.solve(
      classes: classes,
      subjects: subjects,
      teachers: teachers,
      currentPlacements: const [],
      constraints: constraints,
    );

    expect(solution.hardConflicts, equals(0), reason: 'CSP must produce 0 hard collisions');
    expect(solution.placements.isNotEmpty, isTrue);
    expect(solution.fitnessScore, greaterThanOrEqualTo(70.0));
    expect(solution.executionTimeMs, lessThan(1000), reason: 'CSP must execute in sub-second time');
  });

  test('EmailVerificationService rejects invalid syntax and disposable domains', () async {
    // 1. Invalid syntax
    final invalidSyntax = await EmailVerificationService.verifyEmail('invalid-email-address');
    expect(invalidSyntax.isValid, isFalse);

    // 2. Disposable domain
    final disposable = await EmailVerificationService.verifyEmail('test@mailinator.com');
    expect(disposable.isValid, isFalse);

    // 3. Real domain with active MX
    final realEmail = await EmailVerificationService.verifyEmail('admin@gmail.com');
    expect(realEmail.isValid, isTrue);
    expect(realEmail.domain, equals('gmail.com'));

    // 4. Fake non-existent domain
    final fakeDomain = await EmailVerificationService.verifyEmail('user@fakedomain99999xyznotreal.com');
    expect(fakeDomain.isValid, isFalse);
  });

  test('Interactive Class Arranging and Actionable AI Suggestions test', () {
    final teachers = [
      Teacher(id: 'T1', name: 'Dr. Alan Turing', shortName: 'AT'),
      Teacher(id: 'T2', name: 'Prof. Ada Lovelace', shortName: 'AL'),
    ];
    final subjects = [
      Subject(id: 'S1', name: 'Computer Science', shortName: 'CS'),
      Subject(id: 'S2', name: 'Mathematics', shortName: 'MATH'),
    ];
    final classes = [
      SchoolClass(id: 'C1', name: 'Grade 10-A', shortName: '10A'),
    ];

    final placements = [
      LessonPlacement(id: 'P1', subjectId: 'S1', teacherId: 'T1', classId: 'C1', dayOfWeek: 1, period: 1),
      LessonPlacement(id: 'P2', subjectId: 'S2', teacherId: 'T2', classId: 'C1', dayOfWeek: 1, period: 2),
    ];

    // Test moving placement
    final moved = LessonPlacement(
      id: placements[0].id,
      subjectId: placements[0].subjectId,
      teacherId: placements[0].teacherId,
      classId: placements[0].classId,
      dayOfWeek: 2,
      period: 4,
    );
    expect(moved.dayOfWeek, equals(2));
    expect(moved.period, equals(4));

    expect(teachers.length, equals(2));
    expect(subjects.length, equals(2));
    expect(classes.length, equals(1));

    // Test PeriodTiming model
    const timing = PeriodTiming(period: 1, name: 'Period 1', startTime: '08:00', endTime: '08:45');
    expect(timing.period, equals(1));
    expect(timing.startTime, equals('08:00'));
    expect(timing.endTime, equals('08:45'));
    expect(timing.toMap()['name'], equals('Period 1'));

    // Test actionable AI suggestion model
    final suggestion = AiScheduleSuggestion(
      id: 'sugg_test_1',
      title: 'Prioritize Morning Mathematics',
      description: 'Move Math from afternoon to morning',
      rationale: 'Peak cognitive attention',
      category: 'core_focus',
      badgeText: 'Pedagogy Boost',
      impactText: '+15% Attention',
      updatedPlacements: [moved],
      actionLabel: 'Act Upon This Suggestion',
    );

    expect(suggestion.isApplied, isFalse);
    expect(suggestion.actionLabel, equals('Act Upon This Suggestion'));
    expect(suggestion.updatedPlacements.length, equals(1));
    suggestion.isApplied = true;
    expect(suggestion.isApplied, isTrue);
  });

  test('PDF Page 1 Conformance: The NLP Bridge & XML Schema Specification', () {
    // 1. Test teacher timeoff bitmask XML export
    final teachers = [
      Teacher(
        id: 'T14_Davis',
        name: 'Mr. Davis',
        shortName: 'MD',
        subjects: ['Mathematics'],
        maxHours: 15,
        timeoffDef: '11111,11111,11111,00000,00111', // Thursday all 0s, Friday morning 0s
      ),
    ];

    // 2. Test MaxCardsPerDay constraint XML export
    final constraints = [
      AcademicConstraint(
        id: 'R_Math_Dist',
        target: 'C10_Grade10',
        type: 'MaxCardsPerDay',
        value: '1',
        weight: '100%',
        subjectId: 'S04_Math',
        classId: 'C10_Grade10',
        strictness: 'Hard',
      ),
    ];

    final xml = AscXmlService.exportToAscXml(
      teachers: teachers,
      subjects: [Subject(id: 'S04_Math', name: 'Mathematics', shortName: 'MATH')],
      classes: [SchoolClass(id: 'C10_Grade10', name: 'Grade 10', shortName: '10')],
      placements: [],
      constraints: constraints,
    );

    // Verify exact aSc XML tag signatures from PDF Page 1
    expect(xml, contains('<timeoff teacherid="T14_Davis" def="11111,11111,11111,00000,00111"/>'));
    expect(xml, contains('<constraint type="MaxCardsPerDay" subjectid="S04_Math" classid="C10_Grade10" value="1" weight="100%"/>'));

    // Verify round-trip parsing
    final parsed = AscXmlService.parseAscXml(xml);
    final parsedTeachers = parsed['teachers'] as List<Teacher>;
    final parsedConstraints = parsed['constraints'] as List<AcademicConstraint>;

    expect(parsedTeachers.length, equals(1));
    expect(parsedTeachers.first.timeoffDef, equals('11111,11111,11111,00000,00111'));
    expect(parsedConstraints.length, equals(1));
    expect(parsedConstraints.first.type, equals('MaxCardsPerDay'));
    expect(parsedConstraints.first.subjectId, equals('S04_Math'));
    expect(parsedConstraints.first.classId, equals('C10_Grade10'));
    expect(parsedConstraints.first.weight, equals('100%'));
  });

  test('PDF Page 2 Conformance: Negotiating Deadlocks (The Science Lab Bottleneck)', () {
    final deadlock = DeadlockScenario(
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
          payload: {'teacherId': 'T9_Clark', 'targetDay': 4, 'targetPeriod': 1},
        ),
        DeadlockSolution(
          optionNumber: 2,
          title: 'Option 2: Reassign to Classroom 204',
          description: 'Allow Mrs. Adams to teach this specific session in standard Classroom 204.',
          impactNote: 'Relaxes strict room requirement for this single session, resulting in 100% solver convergence.',
          actionType: 'RELAX_ROOM_CONSTRAINT',
          payload: {'teacherId': 'T8_Adams', 'room': 'Classroom 204'},
        ),
      ],
    );

    expect(deadlock.haltPercentage, equals(98));
    expect(deadlock.proposedSolutions.length, equals(2));
    expect(deadlock.proposedSolutions[1].actionType, equals('RELAX_ROOM_CONSTRAINT'));
    expect(deadlock.proposedSolutions[1].payload['room'], equals('Classroom 204'));
  });

  test('PDF Page 3 Conformance: Scalable State & Realtime Database Generation Lock', () {
    // 1. /teachers/T_01 { name: "Sarah Connor", subjects: ["Math", "Physics"], max_hours: 20 }
    final teacher = Teacher(
      id: 'T_01',
      name: 'Sarah Connor',
      shortName: 'SC',
      subjects: ['Math', 'Physics'],
      maxHours: 20,
    );
    final tMap = teacher.toMap();
    expect(tMap['name'], equals('Sarah Connor'));
    expect(tMap['subjects'], equals(['Math', 'Physics']));
    expect(tMap['max_hours'], equals(20));

    // 2. /classes/C_10A { name: "Grade 10A", size: 28, room_pref: "Main_Block" }
    final schoolClass = SchoolClass(
      id: 'C_10A',
      name: 'Grade 10A',
      shortName: '10A',
      size: 28,
      roomPref: 'Main_Block',
    );
    final cMap = schoolClass.toMap();
    expect(cMap['name'], equals('Grade 10A'));
    expect(cMap['size'], equals(28));
    expect(cMap['room_pref'], equals('Main_Block'));

    // 3. /constraints/R_05 { target: "C_10A", type: "MaxGaps", value: 1, strictness: "Soft" }
    final constraint = AcademicConstraint(
      id: 'R_05',
      target: 'C_10A',
      type: 'MaxGaps',
      value: '1',
      strictness: 'Soft',
    );
    final rMap = constraint.toMap();
    expect(rMap['target'], equals('C_10A'));
    expect(rMap['type'], equals('MaxGaps'));
    expect(rMap['strictness'], equals('Soft'));

    // 4. /live/generation { status: "running", progress: 84, locked_by: "Admin_Steve" }
    final lock = GenerationLock(
      status: 'running',
      progress: 84,
      lockedBy: 'Admin_Steve',
      latestAiLog: 'Permuting teacher matrices...',
    );
    final lMap = lock.toMap();
    expect(lMap['status'], equals('running'));
    expect(lMap['progress'], equals(84));
    expect(lMap['locked_by'], equals('Admin_Steve'));
  });

  test('PDF Page 4 Conformance: The AI Substitution Agent & /daily_overrides/ Collection', () {
    // Models The 7:00 AM Call-In workflow
    final override = SubstitutionRecord(
      id: 'sub_test_1',
      date: '2026-10-20',
      period: 2,
      absentTeacherId: 'T6_Reynolds',
      substituteTeacherId: 'T5_Vance',
      classId: 'C09_Grade9',
      subjectId: 'S03_Hist',
      reason: 'Mr. Reynolds marked sick at 7:00 AM. Mrs. Vance assigned cover (Humanities specialist).',
      timestamp: DateTime.now(),
      status: 'Assigned & Notified',
    );

    final map = override.toMap();
    expect(map['date'], equals('2026-10-20'));
    expect(map['period'], equals(2));
    expect(map['absentTeacherId'], equals('T6_Reynolds'));
    expect(map['substituteTeacherId'], equals('T5_Vance'));
    expect(map['status'], equals('Assigned & Notified'));

    final restored = SubstitutionRecord.fromMap(map);
    expect(restored.substituteTeacherId, equals('T5_Vance'));
    expect(restored.reason, contains('Mrs. Vance assigned cover'));
  });
}
