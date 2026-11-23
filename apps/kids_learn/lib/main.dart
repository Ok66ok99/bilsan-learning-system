import 'package:flutter/material.dart';

void main() => runApp(const BilsanKidsApp());

class BilsanKidsApp extends StatelessWidget {
  const BilsanKidsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'عالم بيلسان',
    theme: ThemeData(useMaterial3: true, fontFamily: 'sans-serif'),
    home: const BilsanKidsHome(),
  );
}

class BilsanKidsHome extends StatelessWidget {
  const BilsanKidsHome({super.key});
  static const berry = Color(0xFFBA388B);
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 660;
    final items = [
      _KidsEntry('الحروف', Icons.abc_rounded, const Color(0xFFFFCE83)),
      _KidsEntry('اللغة العربية', Icons.menu_book_rounded, const Color(0xFFFFBDCE)),
      _KidsEntry('الرياضيات', Icons.calculate_rounded, const Color(0xFFB5DFFF)),
      _KidsEntry('الرسم', Icons.palette_rounded, const Color(0xFFB6E9CE)),
      _KidsEntry('حديقة الإنجازات', Icons.park_rounded, const Color(0xFFD9C6FA)),
      _KidsEntry('بريدي الجميل', Icons.mark_email_unread_rounded, const Color(0xFFFFD8AF)),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB5E5FF), Color(0xFFFFDAF0), Color(0xFFFFF7CA)],
          )),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 930),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  children: [
                    const Center(child: Text('👑  عالم بيلسان  🌸',
                      style: TextStyle(fontSize: 31, color: berry, fontWeight: FontWeight.w900))),
                    const SizedBox(height: 8),
                    const Center(child: Text('هيا نتعلم ونلعب معًا!',
                      style: TextStyle(color: Color(0xFF45356C), fontSize: 18, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(28)),
                      child: Column(children: [
                        const Icon(Icons.auto_awesome_rounded, color: berry, size: 65),
                        const Text('مرحبًا بك في عالمك الجميل',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: berry)),
                        const SizedBox(height: 7),
                        const Text('هذه النسخة التأسيسية لتجربة الواجهة فقط. الدروس والشخصيات المتحركة لم تكتمل بعد.',
                          textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF504568))),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 3 : 2, crossAxisSpacing: 12,
                        mainAxisSpacing: 12, childAspectRatio: wide ? 1.55 : 1.18),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 2, color: item.color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(item.title),
                                content: const Text('هذا القسم قيد التطوير، ولن نعرض دروسًا أو نتائج وهمية.'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
                              ),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(item.icon, size: wide ? 57 : 49, color: const Color(0xFF543274)),
                              const SizedBox(height: 7),
                              Text(item.title, textAlign: TextAlign.center, style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF452D5A))),
                            ]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Center(child: Text('نسخة البناء الأولى • بدون مزامنة أو بيانات حقيقية',
                      style: TextStyle(fontSize: 12, color: Color(0xFF604E6C)))),
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

class _KidsEntry {
  const _KidsEntry(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}
