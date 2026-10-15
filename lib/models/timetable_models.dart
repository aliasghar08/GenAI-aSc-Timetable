class Teacher {
  final String id;
  final String name;
  final String shortName;

  Teacher({
    required this.id,
    required this.name,
    required this.shortName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
      };

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        shortName: map['shortName'] ?? '',
      );
}

class Subject {
  final String id;
  final String name;
  final String shortName;

  Subject({
    required this.id,
    required this.name,
    required this.shortName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        shortName: map['shortName'] ?? '',
      );
}

class SchoolClass {
  final String id;
  final String name;
  final String shortName;

  SchoolClass({
    required this.id,
    required this.name,
    required this.shortName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
      };

  factory SchoolClass.fromMap(Map<String, dynamic> map) => SchoolClass(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        shortName: map['shortName'] ?? '',
      );
}

class LessonPlacement {
  final String id;
  final String subjectId;
  final String teacherId;
  final String classId;
  final int dayOfWeek; // 1 = Mon, 2 = Tue, ..., 5 = Fri
  final int period; // 1 to 8

  LessonPlacement({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.classId,
    required this.dayOfWeek,
    required this.period,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'period': period,
      };

  factory LessonPlacement.fromMap(Map<String, dynamic> map) => LessonPlacement(
        id: map['id'] ?? '',
        subjectId: map['subjectId'] ?? '',
        teacherId: map['teacherId'] ?? '',
        classId: map['classId'] ?? '',
        dayOfWeek: map['dayOfWeek'] is int ? map['dayOfWeek'] : int.tryParse(map['dayOfWeek'].toString()) ?? 1,
        period: map['period'] is int ? map['period'] : int.tryParse(map['period'].toString()) ?? 1,
      );
}

class AiScheduleSuggestion {
  final String id;
  final String title;
  final String description;
  final String rationale;
  final String category; // 'core_focus', 'teacher_wellness', 'gap_reduction', 'friday_buffer', 'collision_fix', 'optimization'
  final String badgeText;
  final String impactText;
  final List<LessonPlacement> updatedPlacements;
  final String actionLabel;
  bool isApplied;

  AiScheduleSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.rationale,
    required this.category,
    required this.badgeText,
    required this.impactText,
    required this.updatedPlacements,
    this.actionLabel = 'Act Upon This Suggestion',
    this.isApplied = false,
  });
}

