import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/pending_math_progress.dart';

void main() {
  test('offline queue preserves only same family and device', () {
    const old = PendingMathProgress(familyId:'family-a',deviceUid:'child-a',total:3);
    expect(old.belongsTo('family-a','child-a'),isTrue);
    expect(old.belongsTo('family-b','child-a'),isFalse);
    expect(old.belongsTo('family-a','child-b'),isFalse);
    expect(old.withTotal(2).total,3);
    expect(old.withTotal(5).total,5);
  });
  test('roundtrip scoped pending record survives offline persistence', () {
    const pending = PendingMathProgress(familyId:'family-a',deviceUid:'child-a',total:7);
    final restored = PendingMathProgress.fromJson(pending.toJson());
    expect(restored, isNotNull);
    expect(restored!.belongsTo('family-a','child-a'),isTrue);
    expect(restored.total,7);
  });
  test('legacy unscoped and corrupt records are rejected', () {
    expect(PendingMathProgress.fromJson({'total': 10}),isNull);
    expect(PendingMathProgress.fromJson({'familyId':'family-a','deviceUid':'child-a','total':-1}),isNull);
    expect(PendingMathProgress.fromJson({'familyId':'family-a','deviceUid':'child-a','total':'3'}),isNull);
  });
}
