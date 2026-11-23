import 'dart:math' as math;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_pairing.dart';
import 'child_progress_sync.dart';
import 'child_access_gate.dart';
import 'activity_rotation.dart';
import 'drawing_lesson.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await ChildFirebase.initialize(); } catch (_) {
    // Stay offline; do not falsely claim pairing or Firebase connectivity.
  }
  runApp(const BilsanKidsApp());
}
const rose = Color(0xFFB42D80), ink = Color(0xFF3F315A);
const navy = Color(0xFF44366E);

class BilsanKidsApp extends StatelessWidget {
  const BilsanKidsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'عالم بيلسان',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: rose,
      fontFamily: 'sans-serif'),
    home: const ChildAccessGate(child: KidsHome()),
  );
}

class KidsHome extends StatelessWidget {
  const KidsHome({super.key});
  void open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 620;
    return Directionality(textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Pastel(child: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 15, 16, 20), children: [
            Row(children: [
              IconButton(
                tooltip: 'ربط جهاز بيلسان',
                onPressed: () => open(context, const ChildPairingPage()),
                icon: const Icon(Icons.phonelink_lock, size: 30)),
              const Spacer(),
              Column(children: [
                Text('عالم بيلسان', style: TextStyle(fontSize: wide ? 36 : 29,
                  fontWeight: FontWeight.w900, color: rose)),
                const Text('رحلة التعلّم والمرح', style: TextStyle(
                  color: navy, fontWeight: FontWeight.w700)),
              ]),
              const Spacer(),
              IconButton.filledTonal(onPressed: () => open(context,
                const NoticePage('بريدي الجميل', 'لا توجد بطاقات مستلمة بعد')),
                icon: const Icon(Icons.mail_rounded)),
            ]),
            const SizedBox(height: 18),
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFF6FE), Color(0xFFFFCEE5), Color(0xFFC5EDFF)]),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x2686539A), blurRadius: 22, offset: Offset(0, 8))]),
              child: Stack(children: [
                const Positioned(right: 18, top: 20,
                  child: Text('⭐', style: TextStyle(fontSize: 32))),
                const Positioned(left: 20, top: 20,
                  child: Text('🦋', style: TextStyle(fontSize: 28))),
                const Positioned(left: 24, bottom: 16,
                  child: Text('🌷', style: TextStyle(fontSize: 35))),
                const Align(alignment: Alignment.topCenter,
                  child: Padding(padding: EdgeInsets.only(top: 8),
                    child: Text('أهلًا يا بطلة! ✨',
                      style: TextStyle(fontSize: 23, color: rose, fontWeight: FontWeight.w900)))),
                const Center(child: Mascot()),
                Align(alignment: Alignment.bottomCenter, child: Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: FilledButton.icon(
                    onPressed: () => open(context, const LettersPage()),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('هيا نتعلّم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    style: FilledButton.styleFrom(backgroundColor: rose, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 21),
            const Text('اختاري عالمك اليوم ✨', style: TextStyle(
              fontSize: 22, color: ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: wide ? 3 : 2,
              childAspectRatio: wide ? 1.35 : 1.0,
              mainAxisSpacing: 13, crossAxisSpacing: 13,
              children: [
                World('الحروف','أ ب ت',const Color(0xFFFFD16F),
                  () => open(context,const LettersPage())),
                World('اللغة العربية','📖',const Color(0xFFFFBED4),
                  () => open(context,const ArabicPage())),
                World('الرياضيات','١ ٢ ٣',const Color(0xFFAFE1FF),
                  () => open(context,const MathPage())),
                World('الرسم والإبداع','🎨',const Color(0xFFB8EBCD),
                  () => open(context,const DrawingPage())),
                World('حديقة الإنجازات','🌳',const Color(0xFFD6C4FF),
                  () => open(context,const NoticePage('حديقة الإنجازات','حديقتك ستكبر مع الدروس بعد تفعيل حفظ الإنجازات.'))),
                World('بريدي الجميل','💌',const Color(0xFFFFDBB0),
                  () => open(context,const NoticePage('بريدي الجميل','لا توجد بطاقات مستلمة بعد.'))),
              ],
            ),
            const SizedBox(height: 18),
            const Center(child: Text('كل محاولة جديدة تستحق نجمة 🌟',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
          ]),
        )))),
        bottomNavigationBar: SafeArea(top: false, child: Container(
          color: const Color(0xFFFFF7FE), padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children: [
            TextButton.icon(onPressed: () {}, icon: const Icon(Icons.home_rounded), label: const Text('الرئيسية')),
            TextButton.icon(onPressed: () => open(context,
              const NoticePage('مكافآتي','المكافآت ستظهر بعد اكتمال حفظ الإنجازات.')),
              icon: const Icon(Icons.star_rounded), label: const Text('مكافآتي')),
            TextButton.icon(onPressed: () => open(context,
              const NoticePage('بريدي','لم تصل بطاقات بعد.')),
              icon: const Icon(Icons.mail_rounded), label: const Text('بريدي')),
          ]),
        )),
      ),
    );
  }
}

class Pastel extends StatelessWidget {
  const Pastel({super.key,required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFC2EBFF),Color(0xFFFFE3F1),Color(0xFFFFF7D6)])),
    child: child,
  );
}

class Mascot extends StatefulWidget {
  const Mascot({super.key});
  @override
  State<Mascot> createState()=> _MascotState();
}
class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController anim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1350))..repeat(reverse:true);
  @override
  void dispose() {anim.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation: anim,
    builder:(context,child)=>Transform.translate(offset:Offset(0,-5*anim.value),
      child:Transform.scale(scale:1+0.04*anim.value,child:child)),
    child: Container(width:122,height:122,
      decoration: const BoxDecoration(shape:BoxShape.circle,color:Color(0xAAFFFFFF),
        boxShadow:[BoxShadow(color:Color(0x33894A86),blurRadius:20)]),
      child:ClipOval(child:Image.asset('assets/kidoza.webp',width:122,height:122,fit:BoxFit.cover))));
}

class World extends StatefulWidget {
  const World(this.title,this.symbol,this.color,this.onTap,{super.key});
  final String title,symbol;
  final Color color;
  final VoidCallback onTap;
  @override
  State<World> createState()=>_WorldState();
}
class _WorldState extends State<World>{
  bool pressed=false;
  @override
  Widget build(BuildContext context)=>AnimatedScale(
    scale:pressed?0.96:1,duration:const Duration(milliseconds:110),
    child:Material(color:Colors.transparent,
      child:InkWell(borderRadius:BorderRadius.circular(25),onTap:widget.onTap,
        onHighlightChanged:(v)=>setState(()=>pressed=v),
        child:Ink(
          decoration:BoxDecoration(
            gradient:LinearGradient(colors:[widget.color.withValues(alpha:0.70),widget.color]),
            borderRadius:BorderRadius.circular(25),
            border:Border.all(color:Colors.white,width:2),
            boxShadow:[BoxShadow(color:widget.color.withValues(alpha:.50),offset:const Offset(0,6),blurRadius:2),
              const BoxShadow(color:Color(0x24875777),blurRadius:12,offset:Offset(0,9))]),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Text(widget.symbol,style:const TextStyle(color:navy,fontSize:37,fontWeight:FontWeight.w900)),
            const SizedBox(height:8),
            Text(widget.title,textAlign:TextAlign.center,style:const TextStyle(
              fontSize:17,color:ink,fontWeight:FontWeight.w900)),
          ]),
        ),
      ),
    ),
  );
}

class LessonShell extends StatelessWidget {
  const LessonShell({super.key,required this.title,required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,
    child:Scaffold(appBar:AppBar(title:Text(title),backgroundColor:const Color(0xFFFFDCEC)),
      body:Pastel(child:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:720),child:child))))));
}

class LettersPage extends StatefulWidget {
  const LettersPage({super.key});
  @override
  State<LettersPage> createState()=>_LettersState();
}
class _LettersState extends State<LettersPage>{
  static const chars='أبتثجحخدذرزسشصضطظعغفقكلمنهوي';
  static const examples=['أسد','بطة','تفاح','ثعلب','جمل','حصان','خبز','دب','ذرة','رمان','زهرة','سمكة',
    'شمس','صقر','ضفدع','طائرة','ظرف','عصفور','غزال','فراشة','قمر','كتاب','ليمون','موز','نحلة','هلال','وردة','يد'];
  int selected=0;
  @override
  Widget build(BuildContext context)=>LessonShell(title:'الحروف الهجائية',
    child:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('اختاري حرفًا وتعلّمي كلمة تبدأ به',textAlign:TextAlign.center,
        style:TextStyle(color:ink,fontSize:20,fontWeight:FontWeight.w800)),
      const SizedBox(height:15),
      Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(18),
        child:Column(children:[
          Text(chars[selected],style:const TextStyle(color:rose,fontSize:95,fontWeight:FontWeight.w900)),
          Text(examples[selected],style:const TextStyle(color:navy,fontSize:26,fontWeight:FontWeight.w900)),
          const Text('رددي الحرف بصوتك يا بطلة 💗'),
          const Text('التسجيل والتقييم الصوتي غير مفعّل الآن',
            style:TextStyle(fontSize:11,color:Colors.grey)),
        ]))),
      const SizedBox(height:17),
      LayoutBuilder(builder:(context,c)=>GridView.builder(
        shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        itemCount:chars.length,
        gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:c.maxWidth>550?7:5,crossAxisSpacing:8,mainAxisSpacing:8),
        itemBuilder:(context,i)=>InkWell(onTap:()=>setState(()=>selected=i),
          child:Container(
            decoration:BoxDecoration(color:selected==i?const Color(0xFFFFC5E1):Colors.white,
              borderRadius:BorderRadius.circular(13)),
            child:Center(child:Text(chars[i],style:const TextStyle(
              fontSize:25,color:rose,fontWeight:FontWeight.w900))),
          )),
      )),
    ]));
}

class ArabicPage extends StatefulWidget {
  const ArabicPage({super.key});
  @override
  State<ArabicPage> createState()=>_ArabicState();
}
class _ArabicState extends State<ArabicPage>{
  int selected=0;
  static const words=['بَابٌ','قَلَمٌ','كِتَابٌ','وَرْدَةٌ'];
  @override
  Widget build(BuildContext context)=>LessonShell(title:'لغتي الجميلة',
    child:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('لنقرأ معًا 📖',style:TextStyle(fontSize:24,color:navy,fontWeight:FontWeight.w900)),
      const SizedBox(height:16),
      Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(28),
        child:Column(children:[
          Text(words[selected],style:const TextStyle(fontSize:48,color:rose,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          const Text('انظري إلى حروف الكلمة ثم اقرئيها'),
        ]))),
      const SizedBox(height:14),
      ...List.generate(words.length,(i)=>Card(child:ListTile(
        title:Text(words[i],style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
        selected:i==selected,onTap:()=>setState(()=>selected=i)))),
      const Text('تمارين قراءة تمهيدية، ولم تُعتمد بعد كوحدات المنهج السعودي.',
        textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
    ]));
}

class MathPage extends StatefulWidget{
  const MathPage({super.key});
  @override
  State<MathPage> createState()=>_MathState();
}
class _MathState extends State<MathPage>{
  int step=0,correct=0,attempts=0;
  int? lastTaskIndex;
  int? chosen;
  bool loaded=false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs=await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        step=prefs.getInt('math_step') ?? 0;
        lastTaskIndex=prefs.getInt('math_last_task_index');
        correct=prefs.getInt('math_correct') ?? 0;
        attempts=prefs.getInt('math_attempts') ?? 0;
        loaded=true;
      });
    } catch (_) {
      if (mounted) setState(() => loaded=true);
    }
  }

  Future<void> _recordAnswer(bool isCorrect) async {
    setState(() {
      attempts++;
      if (isCorrect) correct++;
    });
    final prefs=await SharedPreferences.getInstance();
    await prefs.setInt('math_correct',correct);
    await prefs.setInt('math_attempts',attempts);
  }

  Future<void> _nextQuestion() async {
    final completedTask = _taskIndex;
    setState(() {step++;lastTaskIndex=completedTask;chosen=null;});
    final prefs=await SharedPreferences.getInstance();
    await prefs.setInt('math_step',step);
    await prefs.setInt('math_last_task_index',completedTask);
    if (ChildFirebase.configured) {
      try {
        await ChildProgressSync.queueCompletedQuestion(step);
      } catch (_) {
        // Keep pending progress locally until the next retry.
      }
    }
  }
  static const tasks=[(2,1),(3,2),(1,4),(5,1),(2,5)];
  int get _taskIndex => ActivityRotation.nextIndex(
    activityCount: tasks.length, completedCount: step,
    previousIndex: lastTaskIndex);
  @override
  Widget build(BuildContext context){
    final a=tasks[_taskIndex].$1;
    final b=tasks[_taskIndex].$2;
    final result=a+b;
    final options=[result,result+1,math.max(result-1,0)]..shuffle(math.Random(step+19));
    return LessonShell(title:'صديق الأرقام',child:ListView(
      padding:const EdgeInsets.all(18),children:[
        const Text('هيا نجمع التفاحات! 🍎',textAlign:TextAlign.center,
          style:TextStyle(color:navy,fontSize:21,fontWeight:FontWeight.w900)),
        const SizedBox(height:17),
        Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(24),
          child:Column(children:[
            Text('$a + $b = ؟',style:const TextStyle(color:rose,fontSize:42,fontWeight:FontWeight.w900)),
            Text('${'🍎 ' * a} + ${'🍎 ' * b}',textAlign:TextAlign.center,
              style:const TextStyle(fontSize:20)),
            Text(loaded ? 'إجابات صحيحة محفوظة: $correct من $attempts' : 'جار تحميل التقدم...'),
          ]))),
        const SizedBox(height:16),
        ...options.map((n)=>Padding(
          padding:const EdgeInsets.only(bottom:10),
          child:FilledButton.tonal(
            onPressed:!loaded||chosen!=null?null:(){
              setState(()=>chosen=n);
              _recordAnswer(n==result);
            },
            child:Text('$n',style:const TextStyle(fontSize:24))),
        )),
        if(chosen!=null) ...[
          Text(chosen==result?'أحسنتِ يا بطلة! ⭐':'حاولي مرة أخرى في السؤال القادم 🌷',
            textAlign:TextAlign.center,style:const TextStyle(color:navy,fontSize:19)),
          FilledButton(onPressed:chosen==result ? _nextQuestion : ()=>setState(()=>chosen=null),
            child:Text(chosen==result?'السؤال التالي':'حاولي مرة أخرى')),
        ],
        const SizedBox(height:16),
        const Text('يُحفظ التقدم محليًا، وتُحاول المزامنة عند إكمال السؤال بعد اعتماد ربط الجهاز.',
          textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
      ]));
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});
  @override
  State<DrawingPage> createState()=>_DrawingState();
}
class _DrawingState extends State<DrawingPage>{
  final session=DrawingSession(flowerLesson);
  Color brushColor=rose;
  void change(VoidCallback action)=>setState(action);
  @override
  Widget build(BuildContext context)=>LessonShell(title:'الرسم مع وردة',
    child:ListView(padding:const EdgeInsets.all(16),children:[
      Text(session.showReference?'شاهدي الزهرة ثم اضغطي ابدئي الرسم':
        session.finished?'أحسنتِ! يمكنك تلوين رسمتك':
        'الخطوة ${session.stepIndex+1}: ${session.currentStep!.label}',
        textAlign:TextAlign.center,
        style:const TextStyle(fontSize:20,color:navy,fontWeight:FontWeight.w900)),
      const SizedBox(height:12),
      AspectRatio(aspectRatio:1,child:ClipRRect(
        borderRadius:BorderRadius.circular(26),
        child:Container(color:Colors.white,child:GestureDetector(
          onPanStart:session.showReference?null:(d)=>change(()=>
            session.strokes.add([d.localPosition])),
          onPanUpdate:session.showReference?null:(d)=>change((){
            if(session.strokes.isNotEmpty)session.strokes.last.add(d.localPosition);
          }),
          child:CustomPaint(
            painter:DrawPainter(session.strokes,
              guide:session.showReference?flowerLesson.steps:
                session.tracing?flowerLesson.steps:
                session.currentStep==null?const []:[session.currentStep!],
              brushColor:brushColor),
            child:const SizedBox.expand()),
        )),
      )),
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:8,alignment:WrapAlignment.center,children:[
        FilledButton(onPressed:()=>change(()=>session.showReference=!session.showReference),
          child:Text(session.showReference?'ابدئي الرسم':'إعادة عرض النموذج')),
        if(!session.showReference) ...[
          FilledButton.tonal(onPressed:()=>change(session.next),
            child:Text(session.finished?'اكتملت الخطوات':'الخطوة التالية')),
          OutlinedButton(onPressed:()=>change(session.undo),child:const Text('تراجع')),
          OutlinedButton(onPressed:()=>change(()=>session.tracing=!session.tracing),
            child:Text(session.tracing?'إخفاء التتبع':'تتبعي الرسم كاملًا')),
          OutlinedButton(onPressed:()=>change(()=>session.coloring=!session.coloring),
            child:Text(session.coloring?'إنهاء التلوين':'التلوين')),
        ],
        OutlinedButton(onPressed:()=>change(session.reset),child:const Text('إعادة من البداية')),
      ]),
      if(session.coloring) Wrap(alignment:WrapAlignment.center,children:[
        for(final color in [rose,Colors.blue,Colors.green,Colors.orange,Colors.purple])
          IconButton(onPressed:()=>change(()=>brushColor=color),
            icon:Icon(Icons.circle,color:color),tooltip:'اختيار لون'),
      ]),
      const SizedBox(height:10),
      const Text('الرسم واللوحة المرحلية يعملان محليًا. حفظ الرسومات ومزامنتها مع ولي الأمر لم يُنفّذا بعد.',
        textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
    ]));
}
class DrawPainter extends CustomPainter {
  const DrawPainter(this.strokes,{this.guide=const [],this.brushColor=rose});
  final List<List<Offset>> strokes;
  final List<DrawingStep> guide;
  final Color brushColor;
  @override
  void paint(Canvas canvas,Size size){
    final guidePaint=Paint()..color=const Color(0x99B42D80)
      ..style=PaintingStyle.stroke..strokeWidth=3..strokeCap=StrokeCap.round;
    for(final step in guide){
      if(step.points.isEmpty)continue;
      final path=Path()..moveTo(step.points.first.dx*size.width,step.points.first.dy*size.height);
      for(final p in step.points.skip(1)){path.lineTo(p.dx*size.width,p.dy*size.height);}
      canvas.drawPath(path,guidePaint);
    }
    final brush=Paint()..color=brushColor..strokeWidth=7..strokeCap=StrokeCap.round
      ..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke;
    for(final stroke in strokes){
      if(stroke.length==1){canvas.drawCircle(stroke.first,3.5,brush);}
      if(stroke.length>1){
        final path=Path()..moveTo(stroke.first.dx,stroke.first.dy);
        for(final p in stroke.skip(1)){path.lineTo(p.dx,p.dy);}
        canvas.drawPath(path,brush);
      }
    }
  }
  @override
  bool shouldRepaint(covariant DrawPainter old)=>true;
}

class NoticePage extends StatelessWidget {
  const NoticePage(this.title,this.body,{super.key});
  final String title,body;
  @override
  Widget build(BuildContext context)=>LessonShell(title:title,child:Center(
    child:Padding(padding:const EdgeInsets.all(22),child:Card(color:Colors.white,
      child:Padding(padding:const EdgeInsets.all(30),child:Column(
        mainAxisSize:MainAxisSize.min,children:[
          const Text('💌 🌸',style:TextStyle(fontSize:50)),
          const SizedBox(height:13),
          Text(body,textAlign:TextAlign.center,
            style:const TextStyle(fontSize:18,color:ink,fontWeight:FontWeight.w700)),
        ]))))));
}
