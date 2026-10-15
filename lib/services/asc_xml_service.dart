import 'package:xml/xml.dart';
import '../models/timetable_models.dart';

class AscXmlService {
  /// Converts internal models to standard aSc Timetable XML
  static String exportToAscXml({
    required List<Teacher> teachers,
    required List<Subject> subjects,
    required List<SchoolClass> classes,
    required List<LessonPlacement> placements,
  }) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="windows-1250"');
    builder.element('timetable', nest: () {
      builder.attribute('importtype', 'database');

      // Days and Periods specification
      builder.element('daysdefs', nest: () {
        builder.element('daysdef', nest: () {
          builder.attribute('id', '1');
          builder.attribute('name', 'Week');
          builder.attribute('short', 'W');
          builder.attribute('days', '10000,01000,00100,00010,00001');
        });
      });

      builder.element('periods', nest: () {
        for (int p = 1; p <= 8; p++) {
          builder.element('period', nest: () {
            builder.attribute('name', '$p');
            builder.attribute('short', '$p');
            builder.attribute('period', '$p');
            builder.attribute('starttime', '${7 + p}:00');
            builder.attribute('endtime', '${7 + p}:45');
          });
        }
      });

      // Teachers
      builder.element('teachers', nest: () {
        for (var t in teachers) {
          builder.element('teacher', nest: () {
            builder.attribute('id', t.id);
            builder.attribute('name', t.name);
            builder.attribute('short', t.shortName);
          });
        }
      });

      // Subjects
      builder.element('subjects', nest: () {
        for (var s in subjects) {
          builder.element('subject', nest: () {
            builder.attribute('id', s.id);
            builder.attribute('name', s.name);
            builder.attribute('short', s.shortName);
          });
        }
      });

      // Classes
      builder.element('classes', nest: () {
        for (var c in classes) {
          builder.element('class', nest: () {
            builder.attribute('id', c.id);
            builder.attribute('name', c.name);
            builder.attribute('short', c.shortName);
          });
        }
      });

      // Placed Cards (Lessons)
      builder.element('cards', nest: () {
        for (var lp in placements) {
          builder.element('card', nest: () {
            builder.attribute('lessonid', lp.id);
            builder.attribute('day', '${lp.dayOfWeek}');
            builder.attribute('period', '${lp.period}');
            builder.attribute('classroomids', '');
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Parses native aSc XML into memory
  static Map<String, dynamic> parseAscXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final List<Teacher> teachers = [];
    final List<Subject> subjects = [];
    final List<SchoolClass> classes = [];
    final List<LessonPlacement> placements = [];

    for (var node in document.findAllElements('teacher')) {
      teachers.add(Teacher(
        id: node.getAttribute('id') ?? '',
        name: node.getAttribute('name') ?? '',
        shortName: node.getAttribute('short') ?? '',
      ));
    }

    for (var node in document.findAllElements('subject')) {
      subjects.add(Subject(
        id: node.getAttribute('id') ?? '',
        name: node.getAttribute('name') ?? '',
        shortName: node.getAttribute('short') ?? '',
      ));
    }

    for (var node in document.findAllElements('class')) {
      classes.add(SchoolClass(
        id: node.getAttribute('id') ?? '',
        name: node.getAttribute('name') ?? '',
        shortName: node.getAttribute('short') ?? '',
      ));
    }

    return {
      'teachers': teachers,
      'subjects': subjects,
      'classes': classes,
      'placements': placements,
    };
  }
}
