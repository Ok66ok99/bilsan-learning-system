import 'package:flutter/material.dart';

void main() => runApp(const BilsanParentApp());

class BilsanParentApp extends StatelessWidget {
  const BilsanParentApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'متابعة طفلتي',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8351A2)),
    home: const ParentDashboard(),
  );
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    const actions = [
      _ParentEntry('اختيار الدروس', Icons.menu_book_rounded, 'في المرحلة القادمة'),
      _ParentEntry('تقرير التقدم', Icons.query_stats_rounded, 'لا توجد نتائج حقيقية بعد'),
      _ParentEntry('إدارة الأجهزة', Icons.verified_user_rounded, 'التحكم السحابي لم يُفعّل'),
      _ParentEntry('الوقت والاستخدام', Icons.schedule_rounded, 'لا توجد جلسات بعد'),
      _ParentEntry('إرسال بطاقة', Icons.mark_email_unread_rounded, 'سيُربط بمكتبة البطاقات'),
      _ParentEntry('الإعدادات', Icons.settings_rounded, 'إعدادات أولية'),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFD6F0FF), Color(0xFFF3DFFC), Color(0xFFFFF9FD)],
          )),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Center(child: Text('👑 متابعة طفلتي',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF733C9A)))),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('لوحة ولي الأمر', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          const Text('الحالة: غير متصل بالمزامنة السحابية',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.deepOrange)),
                          const SizedBox(height: 4),
                          const Text('هذه نسخة تأسيسية فقط؛ لا يمكن التحقق من اتصال جهاز الطفلة بعد.'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFFFDF7FF),
                      child: Padding(padding: const EdgeInsets.all(18), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ملف الطفلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text('الصف الأول الابتدائي • المنهج السعودي'),
                          const Text('مؤشر الإتقان: لم يبدأ التقييم بعد',
                            style: TextStyle(color: Color(0xFF5E5371))),
                        ],
                      )),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 3 : 2,
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                        childAspectRatio: wide ? 1.65 : 1.25),
                      itemBuilder: (context, i) {
                        final action = actions[i];
                        return Card(
                          color: Colors.white, elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(23),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(action.title), content: Text(action.info),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(action.icon, size: 42, color: const Color(0xFF9257AC)),
                                const SizedBox(height: 6),
                                Text(action.title, style: const TextStyle(fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Center(child: Text('نسخة أولية للتحقق من البناء فقط — بيانات الأجهزة غير مفعلة',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentEntry {
  const _ParentEntry(this.title, this.icon, this.info);
  final String title;
  final IconData icon;
  final String info;
}
