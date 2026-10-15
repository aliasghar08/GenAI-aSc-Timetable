class Teacher {
  final String id;
  final String name;
  final String shortName;
  final List<String> subjects;
  final int maxHours;
  final String? timeoffDef; // e.g. "11111,11111,11111,00000,00111"

  Teacher({
    required this.id,
    required this.name,
    required this.shortName,
    this.subjects = const [],
    this.maxHours = 20,
    this.timeoffDef,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'subjects': subjects,
        'max_hours': maxHours,
        'timeoffDef': timeoffDef,
      };

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        shortName: map['shortName'] ?? '',
        subjects: (map['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        maxHours: map['max_hours'] is int ? map['max_hours'] : 20,
        timeoffDef: map['timeoffDef'] as String?,
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
  final int size;
  final String roomPref;

  SchoolClass({
    required this.id,
    required this.name,
    required this.shortName,
    this.size = 28,
    this.roomPref = 'Main_Block',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'size': size,
        'room_pref': roomPref,
      };

  factory SchoolClass.fromMap(Map<String, dynamic> map) => SchoolClass(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        shortName: map['shortName'] ?? '',
        size: map['size'] is int ? map['size'] : 28,
        roomPref: map['room_pref'] ?? 'Main_Block',
      );
}

class LessonPlacement {
  final String id;
  final String subjectId;
  final String teacherId;
  final String classId;
  final int dayOfWeek; // 1 = Mon, 2 = Tue, ..., 5 = Fri
  final int period; // 1 to 8
  final String? room;

  LessonPlacement({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.classId,
    required this.dayOfWeek,
    required this.period,
    this.room,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'period': period,
        'room': room,
      };

  factory LessonPlacement.fromMap(Map<String, dynamic> map) => LessonPlacement(
        id: map['id'] ?? '',
        subjectId: map['subjectId'] ?? '',
        teacherId: map['teacherId'] ?? '',
        classId: map['classId'] ?? '',
        dayOfWeek: map['dayOfWeek'] is int ? map['dayOfWeek'] : int.tryParse(map['dayOfWeek'].toString()) ?? 1,
        period: map['period'] is int ? map['period'] : int.tryParse(map['period'].toString()) ?? 1,
        room: map['room'] as String?,
      );
}

class PeriodTiming {
  final int period;
  final String name;
  final String startTime;
  final String endTime;
  final bool isBreak;

  const PeriodTiming({
    required this.period,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() => {
        'period': period,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'isBreak': isBreak,
      };

  factory PeriodTiming.fromMap(Map<String, dynamic> map) => PeriodTiming(
        period: map['period'] is int ? map['period'] : int.tryParse(map['period'].toString()) ?? 1,
        name: map['name'] ?? '',
        startTime: map['startTime'] ?? '',
        endTime: map['endTime'] ?? '',
        isBreak: map['isBreak'] ?? false,
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

/// Models constraints stored in `/constraints/{id}` (e.g. MaxGaps, MaxCardsPerDay)
class AcademicConstraint {
  final String id;
  final String target; // e.g. "C_10A", "S04_Math", "T14_Davis"
  final String type; // e.g. "MaxCardsPerDay", "MaxGaps", "RoomPreference"
  final String value; // e.g. "1"
  final String strictness; // "Hard" or "Soft"
  final String? subjectId;
  final String? classId;
  final String weight; // "100%"

  AcademicConstraint({
    required this.id,
    required this.target,
    required this.type,
    required this.value,
    this.strictness = 'Hard',
    this.subjectId,
    this.classId,
    this.weight = '100%',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'target': target,
        'type': type,
        'value': value,
        'strictness': strictness,
        'subjectid': subjectId,
        'classid': classId,
        'weight': weight,
      };

  factory AcademicConstraint.fromMap(Map<String, dynamic> map) => AcademicConstraint(
        id: map['id'] ?? '',
        target: map['target'] ?? '',
        type: map['type'] ?? '',
        value: map['value']?.toString() ?? '1',
        strictness: map['strictness'] ?? 'Hard',
        subjectId: map['subjectid'] as String?,
        classId: map['classid'] as String?,
        weight: map['weight']?.toString() ?? '100%',
      );
}

/// Models daily substitution overrides stored in `/daily_overrides/{YYYY-MM-DD}/{id}`
class SubstitutionRecord {
  final String id;
  final String date; // YYYY-MM-DD
  final int period;
  final String absentTeacherId;
  final String substituteTeacherId;
  final String classId;
  final String subjectId;
  final String reason;
  final DateTime timestamp;
  final String status; // 'Assigned' | 'Notified' | 'Acknowledged'

  SubstitutionRecord({
    required this.id,
    required this.date,
    required this.period,
    required this.absentTeacherId,
    required this.substituteTeacherId,
    required this.classId,
    required this.subjectId,
    required this.reason,
    required this.timestamp,
    this.status = 'Assigned',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'period': period,
        'absentTeacherId': absentTeacherId,
        'substituteTeacherId': substituteTeacherId,
        'classId': classId,
        'subjectId': subjectId,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory SubstitutionRecord.fromMap(Map<String, dynamic> map) => SubstitutionRecord(
        id: map['id'] ?? '',
        date: map['date'] ?? '',
        period: map['period'] is int ? map['period'] : int.tryParse(map['period'].toString()) ?? 1,
        absentTeacherId: map['absentTeacherId'] ?? '',
        substituteTeacherId: map['substituteTeacherId'] ?? '',
        classId: map['classId'] ?? '',
        subjectId: map['subjectId'] ?? '',
        reason: map['reason'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        status: map['status'] ?? 'Assigned',
      );
}

/// Models Realtime generation lock stored in `/live/generation`
class GenerationLock {
  final String status; // 'idle' | 'running' | 'deadlock' | 'completed'
  final int progress; // 0..100
  final String lockedBy;
  final String? latestAiLog;

  const GenerationLock({
    this.status = 'idle',
    this.progress = 100,
    this.lockedBy = '',
    this.latestAiLog,
  });

  Map<String, dynamic> toMap() => {
        'status': status,
        'progress': progress,
        'locked_by': lockedBy,
        'latest_ai_log': latestAiLog,
      };

  factory GenerationLock.fromMap(Map<String, dynamic> map) => GenerationLock(
        status: map['status'] ?? 'idle',
        progress: map['progress'] is int ? map['progress'] : int.tryParse(map['progress'].toString()) ?? 0,
        lockedBy: map['locked_by'] ?? '',
        latestAiLog: map['latest_ai_log'] as String?,
      );
}

/// Proposed solution option for resolving solver deadlock (Page 2: The AI Resolver)
class DeadlockSolution {
  final int optionNumber;
  final String title;
  final String description;
  final String impactNote;
  final String actionType; // 'MOVE_PERIOD' | 'RELAX_ROOM_CONSTRAINT' | 'OVERRIDE_SOFT_RULE'
  final Map<String, dynamic> payload;

  DeadlockSolution({
    required this.optionNumber,
    required this.title,
    required this.description,
    required this.impactNote,
    required this.actionType,
    required this.payload,
  });
}

/// Active deadlock scenario encountered during generation
class DeadlockScenario {
  final String id;
  final String title;
  final String description;
  final int haltPercentage;
  final List<String> affectedEntities;
  final List<DeadlockSolution> proposedSolutions;

  DeadlockScenario({
    required this.id,
    required this.title,
    required this.description,
    this.haltPercentage = 98,
    required this.affectedEntities,
    required this.proposedSolutions,
  });
}

