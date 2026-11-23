import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_pairing.dart';
import 'child_progress_sync.dart';
import 'device_access_policy.dart';

/// Fail-closed access gate: a saved family ID is never authorization.
class ChildAccessGate extends StatefulWidget {
  const ChildAccessGate({super.key, required this.child});
  final Widget child;
  @override
  State<ChildAccessGate> createState() => _ChildAccessGateState();
}
class _ChildAccessGateState extends State<ChildAccessGate>
    with WidgetsBindingObserver {
  Timer? approvalTimer;
  bool verificationRunning = false;
  bool approved = false;
  bool checking = true;
  String message = 'جارٍ التحقق من موافقة ولي الأمر...';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    verify();
    approvalTimer = Timer.periodic(const Duration(seconds: 60), (_) => verify());
  }
  @override
  void dispose() {
    approvalTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) verify();
  }
  Future<void> verify() async {
    if (!mounted || verificationRunning) return;
    verificationRunning = true;
    setState(() { approved = false; checking = true; });
    try {
      if (!ChildFirebase.configured) {
        throw StateError('Firebase is not configured');
      }
      final prefs = await SharedPreferences.getInstance();
      final familyId = prefs.getString('approved_family_id');
      final user = FirebaseAuth.instance.currentUser;
      if (familyId == null || user == null) {
        if (mounted) setState(() => message = 'هذا الجهاز غير مربوط. اطلب موافقة ولي الأمر.');
        return;
      }
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('verifyDeviceAccess').call({'familyId': familyId})
          .timeout(const Duration(seconds: 10));
      final verification = DeviceAccessPolicy.fromServerResponse(
          (result.data as Map)['approved']);
      final allowed = DeviceAccessPolicy.canOpenLessons(verification);
      if (DeviceAccessPolicy.clearLocalAuthorization(verification)) {
        await prefs.remove('approved_family_id');
        await ChildProgressSync.clearPending();
      }
      if (allowed) {
        try {
          await ChildProgressSync.flushPending().timeout(const Duration(seconds: 3));
        } catch (_) {
          // Approval is already verified; pending progress remains for retry.
        }
      }
      if (mounted) setState(() {
        approved = allowed;
        message = allowed ? '' : 'تم إلغاء صلاحية الجهاز. اطلب موافقة ولي الأمر.';
      });
    } catch (_) {
      if (mounted) setState(() => message =
          'تعذر التحقق من صلاحية الجهاز. اتصل بالإنترنت وأعد المحاولة.');
    } finally {
      verificationRunning = false;
      if (mounted) setState(() => checking = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (approved && !checking) return widget.child;
    return Directionality(textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حماية جهاز بيلسان')),
        body: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.phonelink_lock, size: 52),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (checking) const CircularProgressIndicator(),
              if (!checking) ...[
                FilledButton(onPressed: verify, child: const Text('إعادة التحقق')),
                OutlinedButton(onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute<void>(
                    builder: (_) => const ChildPairingPage()));
                  if (mounted) verify();
                }, child: const Text('ربط الجهاز بموافقة ولي الأمر')),
              ],
            ])),
        )),
      ),
    );
  }
}
