import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';

class ChildFirebase {
  static const apiKey = String.fromEnvironment('BILSAN_FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('BILSAN_FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('BILSAN_FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('BILSAN_FIREBASE_PROJECT_ID');
  static bool get configured => apiKey.isNotEmpty && appId.isNotEmpty &&
      senderId.isNotEmpty && projectId.isNotEmpty;
  static Future<void> initialize() async {
    if (!configured) return;
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: apiKey, appId: appId, messagingSenderId: senderId,
      projectId: projectId,
    ));
    await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity);
  }
}

class ChildPairingPage extends StatefulWidget {
  const ChildPairingPage({super.key});
  @override
  State<ChildPairingPage> createState() => _ChildPairingPageState();
}

class _ChildPairingPageState extends State<ChildPairingPage> {
  String? code;
  String? status;
  String? error;
  bool busy = false;
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> requestCode() async {
    if (busy || !ChildFirebase.configured) return;
    setState(() { busy = true; error = null; });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final result = await functions.httpsCallable('requestPairing').call();
      if (mounted) setState(() {
        code = (result.data as Map)['code'] as String;
        status = 'pending';
      });
    } on FirebaseException catch (e) {
      if (mounted) setState(() => error = 'تعذر إنشاء رمز الربط: ${e.code}');
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر إنشاء رمز الربط');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkStatus() async {
    final currentCode = code;
    if (busy || currentCode == null) return;
    setState(() { busy = true; error = null; });
    try {
      final result = await functions.httpsCallable('getPairingStatus')
          .call({'code': currentCode});
      if (mounted) setState(() => status = (result.data as Map)['status'] as String);
    } on FirebaseException catch (e) {
      if (mounted) setState(() => error = 'تعذر التحقق: ${e.code}');
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر التحقق من الموافقة');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('ربط الجهاز بولي الأمر')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('يجب أن يوافق ولي الأمر على ربط هذا الجهاز.'),
          if (!ChildFirebase.configured)
            const Text('إعداد Firebase غير متوفر في نسخة البناء. الربط غير متاح.'),
          if (code != null) ...[
            const SizedBox(height: 20),
            const Text('أعطِ هذا الرمز لولي الأمر:'),
            SelectableText(code!, style: const TextStyle(
              fontSize: 34, fontWeight: FontWeight.bold)),
            const Text('الرمز صالح لمدة 10 دقائق فقط.'),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: busy || !ChildFirebase.configured ? null : requestCode,
            child: const Text('إنشاء رمز ربط')),
          if (code != null) OutlinedButton(
            onPressed: busy ? null : checkStatus,
            child: const Text('التحقق من موافقة ولي الأمر')),
          if (status != null) Text(status == 'approved'
            ? 'تمت الموافقة من الخادم'
            : status == 'pending' ? 'بانتظار الموافقة'
            : status == 'revoked' ? 'تم إلغاء صلاحية الجهاز'
            : 'حالة الطلب: $status'),
          if (error != null) Text(error!,
            style: const TextStyle(color: Colors.red)),
        ]),
      )),
    ),
  );
}
