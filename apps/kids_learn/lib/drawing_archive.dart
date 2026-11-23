import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedDrawing {
  const SavedDrawing({required this.id, required this.createdAt, required this.strokes});
  final String id;
  final String createdAt;
  final List<List<Offset>> strokes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'strokes': strokes.map((line) => line.map((p) => [
      double.parse(p.dx.toStringAsFixed(4)),
      double.parse(p.dy.toStringAsFixed(4)),
    ]).toList()).toList(),
  };

  static SavedDrawing fromJson(Object? input) {
    final data = Map<String, dynamic>.from(input as Map);
    final lines = (data['strokes'] as List).map((raw) =>
      (raw as List).map((point) {
        final coords = point as List;
        return Offset((coords[0] as num).toDouble(), (coords[1] as num).toDouble());
      }).toList()).toList();
    return SavedDrawing(id: data['id'] as String,
      createdAt: data['createdAt'] as String, strokes: lines);
  }
}

class DrawingArchive {
  static const localKey = 'bilsan_drawings_v1';
  static const maxDrawings = 20;
  static Future<List<SavedDrawing>> readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(localKey) ?? '[]') as List;
      return raw.map(SavedDrawing.fromJson).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveLocal(SavedDrawing drawing) async {
    final existing = await readLocal();
    final next = [drawing, ...existing.where((d) => d.id != drawing.id)]
      .take(maxDrawings).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localKey, jsonEncode(next.map((d) => d.toJson()).toList()));
  }

  static Future<bool> syncToParent() async {
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('approved_family_id');
    final user = FirebaseAuth.instance.currentUser;
    if (familyId == null || user == null) return false;
    final drawings = await readLocal();
    if (drawings.isEmpty) return true;
    try {
      await FirebaseFirestore.instance.collection('families').doc(familyId)
        .collection('drawings').doc(user.uid).set({
          'deviceUid': user.uid,
          'items': drawings.map((d) => d.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      return true;
    } on FirebaseException { return false; }
  }
}
