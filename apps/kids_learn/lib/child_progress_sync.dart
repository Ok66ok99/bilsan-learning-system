import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Only server-approved children can write their own progress document.
/// Firestore rules enforce ownership, monotonic count, and server timestamp.
class ChildProgressSync {
  static Future<void> recordCompletedLesson(String familyId, int total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Child must sign in');
    if (total < 0 || total > 100000) throw ArgumentError.value(total, 'total');
    await FirebaseFirestore.instance
        .collection('families').doc(familyId)
        .collection('progress').doc(user.uid)
        .set({
          'deviceUid': user.uid,
          'completedCount': total,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
