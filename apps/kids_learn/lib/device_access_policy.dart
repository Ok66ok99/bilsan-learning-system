/// Security decision shared by launch gate and deterministic tests.
/// No network result, including timeout/offline, can authorize lesson access.
enum DeviceVerification { approved, rejected, offline, pending }

class DeviceAccessPolicy {
  static bool canOpenLessons(DeviceVerification state) =>
      state == DeviceVerification.approved;

  static bool clearLocalAuthorization(DeviceVerification state) =>
      state == DeviceVerification.rejected;

  static bool retainQueuedProgress(DeviceVerification state) =>
      state == DeviceVerification.offline ||
      state == DeviceVerification.pending ||
      state == DeviceVerification.approved;

  static DeviceVerification fromServerResponse(Object? approved) =>
      approved == true ? DeviceVerification.approved : DeviceVerification.rejected;
}
