import '../models/timetable_models.dart';

/// Custom, zero-dependency aSc Timetables XML Engine
/// Hand-crafted pure Dart serializer and deserializer that eliminates `package:xml`.
class AscXmlService {
  /// Converts internal domain models to standard aSc Timetables XML specification
  static String exportToAscXml({
    required List<Teacher> teachers,
    required List<Subject> subjects,
    required List<SchoolClass> classes,
    required List<LessonPlacement> placements,
    List<AcademicConstraint> constraints = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="windows-1250"?>');
    buffer.writeln('<timetable importtype="database">');

    // 1. Days definitions
    buffer.writeln('  <daysdefs>');
    buffer.writeln('    <daysdef id="1" name="Week" short="W" days="10000,01000,00100,00010,00001"/>');
    buffer.writeln('  </daysdefs>');

    // 2. Periods (1 through 8)
    buffer.writeln('  <periods>');
    for (int p = 1; p <= 8; p++) {
      final start = '${7 + p}:00';
      final end = '${7 + p}:45';
      buffer.writeln('    <period name="$p" short="$p" period="$p" starttime="$start" endtime="$end"/>');
    }
    buffer.writeln('  </periods>');

    // 3. Teachers
    buffer.writeln('  <teachers>');
    for (final t in teachers) {
      final safeName = _escapeXml(t.name);
      final safeShort = _escapeXml(t.shortName);
      buffer.writeln('    <teacher id="${t.id}" name="$safeName" short="$safeShort"/>');
    }
    buffer.writeln('  </teachers>');

    // 4. Subjects
    buffer.writeln('  <subjects>');
    for (final s in subjects) {
      final safeName = _escapeXml(s.name);
      final safeShort = _escapeXml(s.shortName);
      buffer.writeln('    <subject id="${s.id}" name="$safeName" short="$safeShort"/>');
    }
    buffer.writeln('  </subjects>');

    // 5. Classes
    buffer.writeln('  <classes>');
    for (final c in classes) {
      final safeName = _escapeXml(c.name);
      final safeShort = _escapeXml(c.shortName);
      buffer.writeln('    <class id="${c.id}" name="$safeName" short="$safeShort"/>');
    }
    buffer.writeln('  </classes>');

    // 6. Teacher Timeoff Matrices (Page 1: The NLP Bridge)
    final teachersWithTimeoff = teachers.where((t) => t.timeoffDef != null && t.timeoffDef!.isNotEmpty).toList();
    if (teachersWithTimeoff.isNotEmpty) {
      buffer.writeln('  <timeoffs>');
      for (final t in teachersWithTimeoff) {
        buffer.writeln('    <timeoff teacherid="${t.id}" def="${t.timeoffDef}"/>');
      }
      buffer.writeln('  </timeoffs>');
    }

    // 7. Structural Constraints (Page 1: Subject Distribution & Rules)
    if (constraints.isNotEmpty) {
      buffer.writeln('  <constraints>');
      for (final c in constraints) {
        final subAttr = c.subjectId != null ? ' subjectid="${c.subjectId}"' : '';
        final classAttr = c.classId != null ? ' classid="${c.classId}"' : '';
        buffer.writeln('    <constraint type="${c.type}"$subAttr$classAttr value="${c.value}" weight="${c.weight}"/>');
      }
      buffer.writeln('  </constraints>');
    }

    // 8. Placed Lesson Cards
    buffer.writeln('  <cards>');
    for (final lp in placements) {
      final roomAttr = lp.room != null ? ' classroomids="${lp.room}"' : ' classroomids=""';
      buffer.writeln('    <card lessonid="${lp.id}" day="${lp.dayOfWeek}" period="${lp.period}"$roomAttr/>');
    }
    buffer.writeln('  </cards>');

    buffer.writeln('</timetable>');
    return buffer.toString();
  }

  /// Parses native aSc XML into memory using lightweight pattern matching
  static Map<String, dynamic> parseAscXml(String xmlString) {
    final List<Teacher> teachers = [];
    final List<Subject> subjects = [];
    final List<SchoolClass> classes = [];
    final List<LessonPlacement> placements = [];

    // Parse teachers
    final teacherMatches = RegExp(r'<teacher\s+([^>]+)/>').allMatches(xmlString);
    for (final m in teacherMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      teachers.add(Teacher(
        id: attrs['id'] ?? '',
        name: attrs['name'] ?? '',
        shortName: attrs['short'] ?? '',
      ));
    }

    // Parse subjects
    final subjectMatches = RegExp(r'<subject\s+([^>]+)/>').allMatches(xmlString);
    for (final m in subjectMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      subjects.add(Subject(
        id: attrs['id'] ?? '',
        name: attrs['name'] ?? '',
        shortName: attrs['short'] ?? '',
      ));
    }

    // Parse classes
    final classMatches = RegExp(r'<class\s+([^>]+)/>').allMatches(xmlString);
    for (final m in classMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      classes.add(SchoolClass(
        id: attrs['id'] ?? '',
        name: attrs['name'] ?? '',
        shortName: attrs['short'] ?? '',
      ));
    }

    // Parse placed cards
    final cardMatches = RegExp(r'<card\s+([^>]+)/>').allMatches(xmlString);
    for (final m in cardMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      final day = int.tryParse(attrs['day'] ?? '1') ?? 1;
      final period = int.tryParse(attrs['period'] ?? '1') ?? 1;
      placements.add(LessonPlacement(
        id: attrs['lessonid'] ?? '',
        classId: '',
        subjectId: '',
        teacherId: '',
        dayOfWeek: day,
        period: period,
        room: attrs['classroomids'],
      ));
    }

    // Parse timeoffs
    final timeoffMatches = RegExp(r'<timeoff\s+([^>]+)/>').allMatches(xmlString);
    for (final m in timeoffMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      final teacherId = attrs['teacherid'] ?? '';
      final def = attrs['def'] ?? '';
      final tIdx = teachers.indexWhere((t) => t.id == teacherId);
      if (tIdx >= 0) {
        teachers[tIdx] = Teacher(
          id: teachers[tIdx].id,
          name: teachers[tIdx].name,
          shortName: teachers[tIdx].shortName,
          subjects: teachers[tIdx].subjects,
          maxHours: teachers[tIdx].maxHours,
          timeoffDef: def,
        );
      }
    }

    // Parse constraints
    final List<AcademicConstraint> constraints = [];
    final constraintMatches = RegExp(r'<constraint\s+([^>]+)/>').allMatches(xmlString);
    for (final m in constraintMatches) {
      final attrs = _parseAttributes(m.group(1) ?? '');
      constraints.add(AcademicConstraint(
        id: 'c_${constraints.length + 1}',
        target: attrs['classid'] ?? attrs['subjectid'] ?? '',
        type: attrs['type'] ?? '',
        value: attrs['value'] ?? '1',
        weight: attrs['weight'] ?? '100%',
        subjectId: attrs['subjectid'],
        classId: attrs['classid'],
      ));
    }

    return {
      'teachers': teachers,
      'subjects': subjects,
      'classes': classes,
      'placements': placements,
      'constraints': constraints,
    };
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static Map<String, String> _parseAttributes(String attrString) {
    final Map<String, String> map = {};
    final regex = RegExp(r'(\w+)\s*=\s*"([^"]*)"');
    for (final match in regex.allMatches(attrString)) {
      final key = match.group(1);
      final val = match.group(2);
      if (key != null && val != null) {
        map[key] = val;
      }
    }
    return map;
  }
}
