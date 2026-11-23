import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/activity_rotation.dart';

void main() {
  test('rejects empty catalogs and negative progress', () {
    expect(() => ActivityRotation.nextIndex(activityCount: 0, completedCount: 0), throwsArgumentError);
    expect(() => ActivityRotation.nextIndex(activityCount: 5, completedCount: -1), throwsArgumentError);
  });

  test('one available activity remains selectable', () {
    expect(ActivityRotation.nextIndex(activityCount: 1, completedCount: 7, previousIndex: 0), 0);
  });

  test('does not immediately repeat across 100 sessions', () {
    for (final count in [2, 3, 5, 7]) {
      int? previous;
      for (var step = 0; step < 100; step++) {
        final next = ActivityRotation.nextIndex(
          activityCount: count, completedCount: step, previousIndex: previous);
        expect(next, inInclusiveRange(0, count - 1));
        expect(next, isNot(previous));
        previous = next;
      }
    }
  });

  test('restored history continues without repeating last activity', () {
    const previous = 3;
    final next = ActivityRotation.nextIndex(
      activityCount: 5, completedCount: 12, previousIndex: previous);
    expect(next, isNot(previous));
    expect(next, ActivityRotation.nextIndex(
      activityCount: 5, completedCount: 12, previousIndex: previous));
  });
}
