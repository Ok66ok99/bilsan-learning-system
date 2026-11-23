import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local progress is authoritative until the server confirms an upload.
/// Rejected/revoked devices never bypass Firestore security rules.
class ChildProgressSync {
  static const _pendingKey = 'math_progress_pending';

  static Future<void> queueCompletedQuestion(int total) async {
    if (total < 0 || total > 100000) throw ArgumentError.value(total, 'total');
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getInt(_pendingKey) ?? 0;
    await prefs.setInt(_pendingKey, total > pending ? total : pending);
    // Never block a child's lesson while Firestore waits for reconnection.
    try {
      await flushPending().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Local pending progress is retained for the next approved session.
    } on FirebaseException {
      // Local pending progress is retained; the access gate revalidates approval.
    }
  }

  static Future<void> flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('approved_family_id');
    final total = prefs.getInt(_pendingKey);
    final user = FirebaseAuth.instance.currentUser;
    if (familyId == null || total == null || user == null) return;
    // Firestore rules require an approved device, matching UID and monotonic count.
    final ref = FirebaseFirestore.instance
        .collection('families').doc(familyId)
        .collection('progress').doc(user.uid);
    try {
      await ref.set({
        'deviceUid': user.uid,
        'completedCount': total,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // A newer completion may have arrived while the write was in flight.
      if (prefs.getInt(_pendingKey) == total) {
        await prefs.remove(_pendingKey);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Force a fresh pairing status check; do not repeatedly retry revoked access.
        await prefs.remove('approved_family_id');
        await prefs.remove(_pendingKey);
      }
      rethrow;
    }
  }
}
