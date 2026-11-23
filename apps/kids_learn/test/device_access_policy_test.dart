import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/device_access_policy.dart';

void main() {
  test('unapproved, offline, and pending states cannot open lessons', () {
    for (final state in [
      DeviceVerification.rejected,
      DeviceVerification.offline,
      DeviceVerification.pending,
    ]) {
      expect(DeviceAccessPolicy.canOpenLessons(state), isFalse);
    }
    expect(DeviceAccessPolicy.canOpenLessons(DeviceVerification.approved), isTrue);
  });
  test('network failure retains queued progress but never grants access', () {
    expect(DeviceAccessPolicy.retainQueuedProgress(DeviceVerification.offline), isTrue);
    expect(DeviceAccessPolicy.clearLocalAuthorization(DeviceVerification.offline), isFalse);
    expect(DeviceAccessPolicy.canOpenLessons(DeviceVerification.offline), isFalse);
  });
  test('confirmed revocation clears authorization and queued progress', () {
    expect(DeviceAccessPolicy.clearLocalAuthorization(DeviceVerification.rejected), isTrue);
    expect(DeviceAccessPolicy.retainQueuedProgress(DeviceVerification.rejected), isFalse);
  });
  test('reconnect requires a fresh explicit server approval', () {
    var state = DeviceVerification.offline;
    expect(DeviceAccessPolicy.canOpenLessons(state), isFalse);
    state = DeviceAccessPolicy.fromServerResponse(false);
    expect(DeviceAccessPolicy.canOpenLessons(state), isFalse);
    state = DeviceAccessPolicy.fromServerResponse(true);
    expect(DeviceAccessPolicy.canOpenLessons(state), isTrue);
  });
  test('malformed server approval cannot grant access', () {
    for (final response in [null, 'true', 1, false, {}]) {
      expect(DeviceAccessPolicy.canOpenLessons(
        DeviceAccessPolicy.fromServerResponse(response)), isFalse);
    }
  });
}
