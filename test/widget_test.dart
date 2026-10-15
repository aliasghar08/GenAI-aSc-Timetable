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
}
