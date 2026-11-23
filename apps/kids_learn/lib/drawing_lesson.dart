import 'dart:ui';

/// One original, device-independent drawing lesson. Points are normalized
/// to a 0..1 canvas, so the same lesson works on phones and tablets.
class DrawingLesson {
  const DrawingLesson({required this.title, required this.steps});
  final String title;
  final List<DrawingStep> steps;
}

class DrawingStep {
  const DrawingStep(this.label, this.points);
  final String label;
  final List<Offset> points;
}

class DrawingSession {
  DrawingSession(this.lesson);
  final DrawingLesson lesson;
  int stepIndex = 0;
  final List<List<Offset>> strokes = [];
  bool showReference = true;
  bool tracing = false;
  bool coloring = false;

  bool get finished => stepIndex >= lesson.steps.length;
  DrawingStep? get currentStep => finished ? null : lesson.steps[stepIndex];

  void next() {
    if (!finished) stepIndex++;
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
    } else if (stepIndex > 0) {
      stepIndex--;
    }
  }

  void reset() {
    stepIndex = 0;
    strokes.clear();
    showReference = true;
    tracing = false;
    coloring = false;
  }
}

/// Original simple flower, not copied from any copyrighted character.
const flowerLesson = DrawingLesson(title: 'زهرة وردة', steps: [
  DrawingStep('وسط الزهرة', [Offset(.5,.38),Offset(.55,.35),Offset(.6,.38),Offset(.6,.44),Offset(.55,.47),Offset(.5,.44),Offset(.5,.38)]),
  DrawingStep('البتلة الأولى', [Offset(.53,.36),Offset(.46,.22),Offset(.4,.23),Offset(.42,.35),Offset(.5,.39)]),
  DrawingStep('البتلة الثانية', [Offset(.58,.36),Offset(.65,.24),Offset(.72,.27),Offset(.7,.38),Offset(.6,.42)]),
  DrawingStep('الساق', [Offset(.55,.47),Offset(.55,.62),Offset(.54,.78)]),
  DrawingStep('الورقة', [Offset(.55,.66),Offset(.4,.57),Offset(.37,.64),Offset(.55,.7)]),
]);
