import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'parent_pairing.dart';

class FirebaseBootstrap {
  static const apiKey = String.fromEnvironment('BILSAN_FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('BILSAN_FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('BILSAN_FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('BILSAN_FIREBASE_PROJECT_ID');
  static bool get configured => apiKey.isNotEmpty && appId.isNotEmpty &&
      senderId.isNotEmpty && projectId.isNotEmpty;

  static Future<bool> initialize() async {
    if (!configured) return false;
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: apiKey, appId: appId, messagingSenderId: senderId,
      projectId: projectId,
    ));
    return true;
  }
}

class ParentSignInPage extends StatefulWidget {
  const ParentSignInPage({super.key});
  @override
  State<ParentSignInPage> createState() => _ParentSignInPageState();
}

class _ParentSignInPageState extends State<ParentSignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text,
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = switch (e.code) {
        'invalid-email' => 'البريد الإلكتروني غير صحيح',
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'بيانات الدخول غير صحيحة',
        'too-many-requests' => 'محاولات كثيرة، حاول لاحقًا',
        'network-request-failed' => 'تعذر الاتصال بالإنترنت',
        _ => 'تعذر تسجيل الدخول',
      });
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر إكمال تسجيل الدخول');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('دخول ولي الأمر')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('سجّل الدخول بحساب ولي الأمر المعتمد في Firebase.'),
          const SizedBox(height: 20),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            autocorrect: false, decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور', border: OutlineInputBorder())),
          if (error != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 18),
          FilledButton(onPressed: busy ? null : signIn,
            child: Text(busy ? 'جارٍ التحقق...' : 'تسجيل الدخول')),
        ]),
      )),
    ),
  );
}

class ParentConnectionPage extends StatelessWidget {
  const ParentConnectionPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('الحساب والربط')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(padding: const EdgeInsets.all(24),
          child: FirebaseBootstrap.configured
            ? StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('تعذر التحقق من جلسة الحساب');
                  }
                  final user = snapshot.data;
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(user == null ? 'لم يتم تسجيل الدخول'
                        : 'تم تسجيل الدخول: ${user.email ?? "حساب ولي الأمر"}'),
                    const SizedBox(height: 16),
                    if (user == null)
                      FilledButton(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ParentSignInPage())),
                        child: const Text('تسجيل دخول ولي الأمر'))
                    else
                      OutlinedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('تسجيل الخروج')),
                    const SizedBox(height: 20),
                    if (user != null) FilledButton.icon(
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute<void>(builder: (_) => const ParentPairingPage())),
                      icon: const Icon(Icons.phonelink_lock),
                      label: const Text('ربط جهاز بيلسان')),
                    const Text('يتطلب الربط تفعيل Cloud Functions وApp Check على Firebase.'),
                  ]);
                })
            : const Text('إعداد Firebase غير مكتمل في نسخة البناء. '
                'لم يتم الاتصال بالخدمة، ولا يمكن تسجيل الدخول أو ربط جهاز.'),
        ),
      )),
    ),
  );
}
