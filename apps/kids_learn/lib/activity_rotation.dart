/// Deterministic, persisted activity selection that avoids immediate repeats.
/// The selection is scoped by the caller's progress key (one child/device).
class ActivityRotation {
  const ActivityRotation._();

  static int nextIndex({
    required int activityCount,
    required int completedCount,
    int? previousIndex,
  }) {
    if (activityCount <= 0) {
      throw ArgumentError.value(activityCount, 'activityCount', 'Must be positive');
    }
    if (completedCount < 0) {
      throw ArgumentError.value(completedCount, 'completedCount', 'Must be nonnegative');
    }
    if (activityCount == 1) return 0;
    // A full permutation per cycle, with a different starting position
    // each cycle. No immediate repetition, including cycle boundaries.
    final cycle = completedCount ~/ activityCount;
    final position = completedCount % activityCount;
    var index = (position * (activityCount - 1) + cycle) % activityCount;
    if (index == previousIndex) index = (index + 1) % activityCount;
    return index;
  }
}
