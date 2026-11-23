/// Pure queue policy. A pending record is bound to the exact family and
/// Firebase anonymous UID that created it; no cross-family replay.
class PendingMathProgress {
  const PendingMathProgress({
    required this.familyId, required this.deviceUid, required this.total,
  });
  final String familyId;
  final String deviceUid;
  final int total;

  Map<String, Object> toJson() => {
    'familyId': familyId, 'deviceUid': deviceUid, 'total': total,
  };

  static PendingMathProgress? fromJson(Object? value) {
    if (value is! Map) return null;
    final familyId = value['familyId'];
    final uid = value['deviceUid'];
    final total = value['total'];
    if (familyId is! String || familyId.isEmpty ||
        uid is! String || uid.isEmpty ||
        total is! int || total < 0 || total > 100000) return null;
    return PendingMathProgress(familyId: familyId, deviceUid: uid, total: total);
  }

  bool belongsTo(String family, String uid) =>
      familyId == family && deviceUid == uid;

  PendingMathProgress withTotal(int next) => PendingMathProgress(
    familyId: familyId, deviceUid: deviceUid,
    total: next > total ? next : total,
  );
}
