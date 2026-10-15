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
  ) async {
    try {
      final schoolRef = _db.collection('schools').doc(schoolId);
      await schoolRef.set({
        'teachers': teachers.map((e) => e.toMap()).toList(),
        'subjects': subjects.map((e) => e.toMap()).toList(),
        'classes': classes.map((e) => e.toMap()).toList(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Local fallback
    }
  }
}
