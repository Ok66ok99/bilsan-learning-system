import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentPairingPage extends StatefulWidget {
  const ParentPairingPage({super.key});
  @override
  State<ParentPairingPage> createState() => _ParentPairingPageState();
}

class _ParentPairingPageState extends State<ParentPairingPage> {
  final code = TextEditingController();
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  String? familyId;
  String? message;
  bool busy = false;
  List<String> devices = [];

  @override
  void initState() { super.initState(); loadFamily(); }
  @override
  void dispose() { code.dispose(); super.dispose(); }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() { busy = true; message = null; });
    try { await action(); }
    on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => message = 'تعذر تنفيذ العملية: ${e.code}');
    } catch (_) {
      if (mounted) setState(() => message = 'تعذر الاتصال بالخادم. لم تتغير صلاحيات الجهاز.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadFamily() => run(() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final result = await functions.httpsCallable('createFamily').call();
    final id = (result.data as Map)['familyId'] as String;
    if (mounted) setState(() => familyId = id);
    await refreshDevices(id);
  });

  Future<void> refreshDevices(String id) async {
    // Server-owned device approval; parent may read its own device list.
    // Device list is intentionally omitted until Firestore query integration.
    if (mounted) setState(() => devices = []);
  }

  Future<void> approve() => run(() async {
    final id = familyId;
    if (id == null || !RegExp(r'^\d{8}$').hasMatch(code.text.trim())) {
      throw const FormatException('Invalid pairing code');
    }
    await functions.httpsCallable('approvePairing').call({
      'familyId': id, 'code': code.text.trim(),
    });
    if (mounted) setState(() => message = 'تم إرسال الموافقة للخادم بنجاح');
  });

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('ربط جهاز بيلسان')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(familyId == null ? 'جارٍ التحقق من العائلة...' : 'العائلة جاهزة للربط'),
          const SizedBox(height: 16),
          const Text('افتح رمز الربط في جهاز بيلسان، ثم أدخل الرمز المكون من 8 أرقام هنا.'),
          const SizedBox(height: 12),
          TextField(controller: code, keyboardType: TextInputType.number,
            maxLength: 8, decoration: const InputDecoration(
              labelText: 'رمز الربط', border: OutlineInputBorder())),
          FilledButton(onPressed: busy || familyId == null ? null : approve,
            child: Text(busy ? 'جارٍ التحقق...' : 'الموافقة على ربط الجهاز')),
          if (message != null) Padding(
            padding: const EdgeInsets.only(top: 16), child: Text(message!)),
          const SizedBox(height: 16),
          const Text('إدارة الأجهزة وإلغاء الربط ستظهر بعد اكتمال قراءة قائمة الأجهزة من Firebase.'),
        ]),
      )),
    ),
  );
}
