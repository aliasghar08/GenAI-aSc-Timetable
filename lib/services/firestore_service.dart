import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String schoolId = 'demo_school';

  Stream<List<LessonPlacement>> streamPlacements() {
    try {
      return _db
          .collection('schools')
          .doc(schoolId)
          .collection('placements')
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => LessonPlacement.fromMap(doc.data()))
              .toList())
          .handleError((error) {
        // Return empty list on network or permission restrictions
        return <LessonPlacement>[];
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> batchApplyActions(List<dynamic> actions) async {
    try {
      final batch = _db.batch();
      final col = _db.collection('schools').doc(schoolId).collection('placements');

      for (var act in actions) {
        final type = act['action'];
        final pMap = act['placement'] as Map<String, dynamic>;
        final docRef = col.doc(pMap['id']);

        if (type == 'UPSERT') {
          batch.set(docRef, pMap, SetOptions(merge: true));
        } else if (type == 'DELETE') {
          batch.delete(docRef);
        }
      }
      await batch.commit().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Allow seamless local operation without blocking UI
    }
  }

  Future<void> seedInitialAcademicData(
    List<Teacher> teachers,
    List<Subject> subjects,
    List<SchoolClass> classes,
    List<PeriodTiming> timings,
  ) async {
    try {
      final schoolRef = _db.collection('schools').doc(schoolId);
      final doc = await schoolRef.get().timeout(const Duration(seconds: 3));
      // Only seed if doc does not already exist
      if (!doc.exists) {
        await schoolRef.set({
          'teachers': teachers.map((e) => e.toMap()).toList(),
          'subjects': subjects.map((e) => e.toMap()).toList(),
          'classes': classes.map((e) => e.toMap()).toList(),
          'timings': timings.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Local fallback
    }
  }

  Future<Map<String, dynamic>?> loadAcademicData() async {
    try {
      final schoolRef = _db.collection('schools').doc(schoolId);
      final doc = await schoolRef.get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveAcademicEntities({
    List<Teacher>? teachers,
    List<Subject>? subjects,
    List<SchoolClass>? classes,
    List<PeriodTiming>? timings,
  }) async {
    try {
      final schoolRef = _db.collection('schools').doc(schoolId);
      final data = <String, dynamic>{};
      if (teachers != null) data['teachers'] = teachers.map((e) => e.toMap()).toList();
      if (subjects != null) data['subjects'] = subjects.map((e) => e.toMap()).toList();
      if (classes != null) data['classes'] = classes.map((e) => e.toMap()).toList();
      if (timings != null) data['timings'] = timings.map((e) => e.toMap()).toList();

      await schoolRef.set(data, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
