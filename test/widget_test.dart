import 'package:flutter_test/flutter_test.dart';
import 'package:genai_asc_timetable/models/timetable_models.dart';
import 'package:genai_asc_timetable/services/algorithmic_csp_solver.dart';
import 'package:genai_asc_timetable/services/asc_xml_service.dart';

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
}
