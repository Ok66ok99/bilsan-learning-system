import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/drawing_lesson.dart';

void main() {
  test('original lesson contains five named drawing steps', () {
    expect(flowerLesson.steps.length, 5);
    expect(flowerLesson.steps.every((s) => s.label.isNotEmpty && s.points.length >= 2), isTrue);
    for (final step in flowerLesson.steps) {
      for (final p in step.points) {
        expect(p.dx, inInclusiveRange(0, 1));
        expect(p.dy, inInclusiveRange(0, 1));
      }
    }
  });
  test('drawing stays on one lesson and advances step by step', () {
    final session = DrawingSession(flowerLesson);
    expect(session.showReference, isTrue);
    session.showReference = false;
    for (var i = 0; i < flowerLesson.steps.length; i++) {
      expect(session.currentStep?.label, flowerLesson.steps[i].label);
      session.next();
    }
    expect(session.finished, isTrue);
    session.next();
    expect(session.stepIndex, flowerLesson.steps.length);
  });
  test('undo, tracing, coloring and restart preserve consistent state', () {
    final session = DrawingSession(flowerLesson);
    session.showReference = false;
    session.tracing = true;
    session.coloring = true;
    session.strokes.add([const Offset(.2,.2), const Offset(.3,.3)]);
    session.undo();
    expect(session.strokes, isEmpty);
    session.next();
    session.undo();
    expect(session.stepIndex, 0);
    session.next();
    session.reset();
    expect(session.stepIndex, 0);
    expect(session.showReference, isTrue);
    expect(session.tracing, isFalse);
    expect(session.coloring, isFalse);
  });
}
