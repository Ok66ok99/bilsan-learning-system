import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pending_math_progress.dart';

/// A queue is always scoped to the exact approved family and Firebase UID.
/// Network failures preserve pending data; a confirmed revocation removes it.
class ChildProgressSync {
  static const pendingKey = 'math_progress_pending_v2';
  static const legacyKey = 'math_progress_pending';

  static PendingMathProgress? readPending(SharedPreferences prefs) {
    final raw = prefs.getString(pendingKey);
    if (raw == null) return null;
    try { return PendingMathProgress.fromJson(jsonDecode(raw)); }
    catch (_) { return null; }
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pendingKey);
    await prefs.remove(legacyKey);
  }

  static Future<void> queueCompletedQuestion(int total) async {
    if (total < 0 || total > 100000) throw ArgumentError.value(total, 'total');
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('approved_family_id');
    final user = FirebaseAuth.instance.currentUser;
    // Do not create a transferable queue without a verified identity.
    if (familyId == null || user == null) return;
    final old = readPending(prefs);
    final record = old != null && old.belongsTo(familyId, user.uid)
        ? old.withTotal(total)
        : PendingMathProgress(familyId: familyId, deviceUid: user.uid, total: total);
    await prefs.setString(pendingKey, jsonEncode(record.toJson()));
    await prefs.remove(legacyKey);
    try {
      await flushPending().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Preserve scoped progress for the next verified session.
    } on FirebaseException {
      // Permission errors are handled in flushPending.
    }
  }

  static Future<void> flushPending() async {
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('approved_family_id');
    final user = FirebaseAuth.instance.currentUser;
    final record = readPending(prefs);
    if (familyId == null || user == null || record == null) return;
    if (!record.belongsTo(familyId, user.uid)) {
      // Old family/identity progress must never be sent to the new family.
      await clearPending();
      return;
    }
    final ref = FirebaseFirestore.instance.collection('families')
        .doc(familyId).collection('progress').doc(user.uid);
    try {
      await ref.set({
        'deviceUid': user.uid,
        'completedCount': record.total,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // A newer completion may arrive during the upload; keep it queued.
      final current = readPending(prefs);
      if (current != null && current.belongsTo(familyId, user.uid) &&
          current.total == record.total) await clearPending();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // An old in-flight request must not revoke a newly paired family.
        if (prefs.getString('approved_family_id') == familyId &&
            FirebaseAuth.instance.currentUser?.uid == user.uid) {
          await prefs.remove('approved_family_id');
          final current = readPending(prefs);
          if (current != null && current.belongsTo(familyId, user.uid)) {
            await clearPending();
          }
        }
      }
      rethrow;
    }
  }
}
