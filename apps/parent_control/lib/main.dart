// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_authentication.dart';
import 'drawings_gallery.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseBootstrap.initialize();
  } catch (_) {
    // Remain offline and never claim successful Firebase connection.
  }
  runApp(const BilsanParentApp());
}

const navy = Color(0xFF20385F);
const purple = Color(0xFF7456B4);
const lilac = Color(0xFFF0E9FF);
const pale = Color(0xFFF4F8FF);

class BilsanParentApp extends StatelessWidget {
  const BilsanParentApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'متابعة طفلتي',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: purple),
      scaffoldBackgroundColor: pale),
    home: const ParentDashboard(),
  );
}

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}
class _ParentDashboardState extends State<ParentDashboard> {
  int semester = 1;
  final selected = <String>{};
  bool preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        semester = prefs.getInt('bilsan_semester') ?? 1;
        selected
          ..clear()
          ..addAll(prefs.getStringList('bilsan_lessons') ?? <String>[]);
        preferencesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => preferencesLoaded = true);
    }
  }

  Future<void> _savePreferences(int newSemester, Set<String> lessons) async {
    setState(() {
      semester = newSemester;
      selected
        ..clear()
        ..addAll(lessons);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bilsan_semester', newSemester);
    await prefs.setStringList('bilsan_lessons', lessons.toList()..sort());
  }

  void open(Widget page) => Navigator.push(context,
    MaterialPageRoute<void>(builder: (_) => page));
  void editCurriculum() => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, showDragHandle: true,
    builder: (_) => CurriculumSheet(
      semester: semester, selection: selected,
      onSaved: (s, lessons) => _savePreferences(s, lessons),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 670;
    return Directionality(textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F3FF), Color(0xFFF5E9FF), Color(0xFFFFFAFF)])),
          child: SafeArea(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 13, 16, 30), children: [
              Row(children: [
                Container(width: 46,height:46,decoration:BoxDecoration(
                  color:Colors.white,borderRadius:BorderRadius.circular(16)),
                  child:ClipOval(child:Image.asset('assets/kidoza.webp',width:46,height:46,fit:BoxFit.cover))),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                  Text('متابعة طفلتي',style:TextStyle(
                    color:navy,fontSize:27,fontWeight:FontWeight.w900)),
                  Text('لوحة ولي الأمر',style:TextStyle(color:purple,fontSize:13)),
                ])),
                IconButton.filledTonal(onPressed: ()=>open(
                  const ParentConnectionPage()),
                  icon: const Icon(Icons.settings_rounded)),
              ]),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(colors:[
                    Color(0xFF263A6B),Color(0xFF6550A2)]),
                  boxShadow: const [BoxShadow(color: Color(0x33445688),
                    blurRadius:18,offset:Offset(0,7))]),
                child: Padding(padding:const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment:CrossAxisAlignment.start,children: [
                    const Row(children: [
                      CircleAvatar(radius:24,backgroundColor:Color(0x66FFFFFF),
                        child:Icon(Icons.school_rounded,color:Colors.white,size:28)),
                      SizedBox(width:12),
                      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                        children: [
                          Text('بيلسان',style:TextStyle(fontSize:24,
                            color:Colors.white,fontWeight:FontWeight.w900)),
                          Text('الصف الأول الابتدائي • المنهج السعودي',
                            style:TextStyle(color:Color(0xFFE7DBFF),fontSize:12)),
                        ])),
                    ]),
                    const SizedBox(height: 18),
                    Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
                      decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.13),
                        borderRadius:BorderRadius.circular(16)),
                      child: const Row(children: [
                        Icon(Icons.wifi_off_rounded,color:Color(0xFFFFC587),size:24),
                        SizedBox(width:9),
                        Expanded(child:Text('الجهاز غير مربوط — لا يمكن التحقق من الاتصال',
                          style:TextStyle(color:Colors.white,
                            fontWeight:FontWeight.w800,fontSize:14))),
                      ]),
                    ),
                    const SizedBox(height:6),
                    const Text('آخر مزامنة: لا توجد بيانات',
                      style:TextStyle(color:Color(0xFFE7DFFF),fontSize:12)),
                  ]),
                ),
              ),
              const SizedBox(height: 17),
              Row(children: [
                Expanded(child:StatusTile(icon:Icons.menu_book_rounded,
                  label:'المناهج',value:preferencesLoaded ? 'الفصل $semester' : 'جار التحميل',tone:const Color(0xFFDDF0FF))),
                const SizedBox(width:10),
                const Expanded(child:StatusTile(icon:Icons.query_stats_rounded,
                  label:'تقدم المهارات',value:'لم يُقيّم',tone:Color(0xFFFBE6F4))),
                const SizedBox(width:10),
                const Expanded(child:StatusTile(icon:Icons.access_time_rounded,
                  label:'الوقت اليوم',value:'لا بيانات',tone:Color(0xFFE6F7EB))),
              ]),
              const SizedBox(height: 21),
              const Text('إدارة تعلم بيلسان',style:TextStyle(
                fontSize:21,fontWeight:FontWeight.w900,color:navy)),
              const SizedBox(height: 13),
              GridView.count(
                crossAxisCount:wide?3:2,
                shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
                mainAxisSpacing:12,crossAxisSpacing:12,
                childAspectRatio:wide?1.75:1.23,
                children: [
                  DashboardAction(Icons.menu_book_rounded,'الفصول والدروس',
                    const Color(0xFFDEEAFB),editCurriculum),
                  DashboardAction(Icons.auto_graph_rounded,'تقرير التقدم',
                    const Color(0xFFE4F4ED),()=>open(const InformationScreen(
                      'تقرير التقدم','لا توجد نتائج فعلية بعد. بعد ربط التطبيقين ستظهر نقاط القوة والمهارات التي تحتاج مراجعة.'))),
                  DashboardAction(Icons.devices_other_rounded,'إدارة الأجهزة',
                    const Color(0xFFE5DEFA),()=>open(const InformationScreen(
                      'الأجهزة','لا توجد أجهزة مربوطة. ستُتاح الموافقة والرفض وإلغاء الصلاحية بعد إعداد قواعد الأمان.'))),
                  DashboardAction(Icons.schedule_rounded,'الوقت والاستخدام',
                    const Color(0xFFFFF0D7),()=>open(const InformationScreen(
                      'الوقت والاستخدام','لم تصل جلسات استخدام من تطبيق الطفلة بعد.'))),
                  DashboardAction(Icons.mail_rounded,'بطاقة تشجيع',
                    const Color(0xFFFFDAE9),()=>open(const GreetingCardEditor())),
                  DashboardAction(Icons.palette_rounded,'رسومات طفلتي',
                    const Color(0xFFF0E6FA),()=>open(const DrawingsGallery())),
                ],
              ),
              const SizedBox(height: 19),
              Container(padding:const EdgeInsets.all(15),
                decoration:BoxDecoration(color:Colors.white.withValues(alpha:.82),
                  borderRadius:BorderRadius.circular(18)),
                child:const Row(children:[
                  Icon(Icons.shield_outlined,color:purple),
                  SizedBox(width:10),
                  Expanded(child:Text('جميع البيانات المعروضة حقيقية: لا نعرض نتائج أو اتصالًا افتراضيًا.',
                    style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:navy))),
                ])),
            ]),
          ))),
        ),
      ),
    );
  }
}

class StatusTile extends StatelessWidget {
  const StatusTile({super.key,required this.icon,required this.label,
    required this.value,required this.tone});
  final IconData icon;
  final String label,value;
  final Color tone;
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(vertical:12,horizontal:6),
    decoration:BoxDecoration(color:tone,borderRadius:BorderRadius.circular(18),
      border:Border.all(color:Colors.white,width:2)),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:purple,size:24),
      const SizedBox(height:5),
      FittedBox(fit:BoxFit.scaleDown,child:Text(value,
        style:const TextStyle(fontWeight:FontWeight.w900,color:navy,fontSize:15))),
      FittedBox(fit:BoxFit.scaleDown,child:Text(label,
        style:const TextStyle(fontSize:11,color:navy))),
    ]),
  );
}

class DashboardAction extends StatefulWidget {
  const DashboardAction(this.icon,this.title,this.color,this.onTap,{super.key});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  @override
  State<DashboardAction> createState()=>_ActionState();
}
class _ActionState extends State<DashboardAction> {
  bool pressed=false;
  @override
  Widget build(BuildContext context)=>AnimatedScale(
    scale:pressed ? 0.97 : 1,duration:const Duration(milliseconds:120),
    child:Material(color:Colors.transparent,child:InkWell(
      onTap:widget.onTap,onHighlightChanged:(v)=>setState(()=>pressed=v),
      borderRadius:BorderRadius.circular(22),
      child:Ink(decoration:BoxDecoration(
        gradient:LinearGradient(colors:[Colors.white,widget.color]),
        borderRadius:BorderRadius.circular(22),
        boxShadow:const [BoxShadow(color:Color(0x19806A95),
          blurRadius:12,offset:Offset(0,6))],
        border:Border.all(color:Colors.white,width:1.7)),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          CircleAvatar(radius:26,backgroundColor:Colors.white,
            child:Icon(widget.icon,color:purple,size:28)),
          const SizedBox(height:10),
          Text(widget.title,textAlign:TextAlign.center,
            style:const TextStyle(fontWeight:FontWeight.w900,color:navy,fontSize:15)),
        ]),
      ),
    )),
  );
}

class CurriculumSheet extends StatefulWidget {
  const CurriculumSheet({super.key,required this.semester,required this.selection,required this.onSaved});
  final int semester;
  final Set<String> selection;
  final void Function(int,Set<String>) onSaved;
  @override
  State<CurriculumSheet> createState()=>_CurriculumState();
}
class _CurriculumState extends State<CurriculumSheet> {
  late int semester=widget.semester;
  late final selected=Set<String>.of(widget.selection);
  static const lessons=['الحروف الهجائية','الحركات القصيرة','قراءة الكلمات',
    'الأعداد حتى 10','المقارنة','الجمع والطرح'];
  @override
  Widget build(BuildContext context)=>Directionality(
    textDirection:TextDirection.rtl,
    child:Padding(padding:EdgeInsets.fromLTRB(20,10,20,
      MediaQuery.viewInsetsOf(context).bottom+25),
      child:SingleChildScrollView(child:Column(
        mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          const Text('اختيار الفصل والدروس',style:TextStyle(fontWeight:FontWeight.w900,
            fontSize:22,color:navy)),
          const SizedBox(height:10),
          DropdownButtonFormField<int>(
            initialValue:semester,
            decoration:const InputDecoration(labelText:'الفصل الدراسي',
              border:OutlineInputBorder()),
            items:[1,2,3].map((s)=>DropdownMenuItem(value:s,
              child:Text('الفصل $s'))).toList(),
            onChanged:(s){if(s!=null)setState(()=>semester=s);},
          ),
          const SizedBox(height:12),
          const Text('اختاري أنشطة النسخة التمهيدية:',
            style:TextStyle(fontWeight:FontWeight.w800)),
          ...lessons.map((name)=>CheckboxListTile(
            title:Text(name),value:selected.contains(name),
            onChanged:(v)=>setState((){
              if(v==true){selected.add(name);}else{selected.remove(name);}
            }),
          )),
          const SizedBox(height:10),
          FilledButton.icon(onPressed:(){
            widget.onSaved(semester,selected);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:Text('حُفظ الاختيار على جهاز الأب فقط؛ المزامنة غير مفعّلة.')));
          }, icon:const Icon(Icons.check_circle_rounded),
          label:const Text('حفظ اختيار الدروس')),
        ],
      )),
    ),
  );
}

class GreetingCardEditor extends StatefulWidget {
  const GreetingCardEditor({super.key});
  @override
  State<GreetingCardEditor> createState()=>_GreetingCardState();
}
class _GreetingCardState extends State<GreetingCardEditor> {
  final message=TextEditingController(text:'أنا فخور بك يا بيلسان، أحبك يا أميرتي ❤️');
  String style='وردي';
  double size=20;
  Color get color=>switch(style){
    'أزرق'=>const Color(0xFF2358A6),
    'أخضر'=>const Color(0xFF247858),
    _=>const Color(0xFF922478)};
  @override
  void dispose(){message.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Directionality(
    textDirection:TextDirection.rtl,
    child:Scaffold(
      appBar:AppBar(title:const Text('بطاقة لابنتي'),
        backgroundColor:const Color(0xFFFFDBEE)),
      body:Container(decoration:const BoxDecoration(
        gradient:LinearGradient(colors:[Color(0xFFFFE7F6),Color(0xFFE8F0FF)])),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          const Text('بطاقة محبة من والدك 💌',textAlign:TextAlign.center,
            style:TextStyle(color:navy,fontSize:22,fontWeight:FontWeight.w900)),
          const SizedBox(height:13),
          TextField(controller:message,maxLines:3,maxLength:160,
            onChanged:(_)=>setState((){}),
            decoration:const InputDecoration(labelText:'اكتب رسالتك لبيلسان',
              filled:true,fillColor:Colors.white,border:OutlineInputBorder())),
          const SizedBox(height:7),
          Wrap(spacing:10,children:['وردي','أزرق','أخضر'].map((n)=>ChoiceChip(
            label:Text(n),selected:style==n,
            onSelected:(_)=>setState(()=>style=n))).toList()),
          Row(children:[
            const Text('حجم النص'),
            Expanded(child:Slider(value:size,min:15,max:30,
              divisions:15,onChanged:(n)=>setState(()=>size=n))),
            Text(size.round().toString()),
          ]),
          const SizedBox(height:8),
          Container(
            height:320,
            decoration:BoxDecoration(
              gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
                colors:[Color(0xFFFFDBE9),Color(0xFFFFF8D7),Color(0xFFF4C5F3)]),
              borderRadius:BorderRadius.circular(32),
              border:Border.all(color:Colors.white,width:3),
              boxShadow:const [BoxShadow(color:Color(0x448C507F),blurRadius:18,offset:Offset(0,8))]),
            child:Stack(children:[
              const Positioned(top:16,left:22,child:Text('🌸',style:TextStyle(fontSize:30))),
              const Positioned(top:12,right:18,child:Text('✨',style:TextStyle(fontSize:30))),
              Align(alignment:Alignment.topCenter,
                child:Padding(padding:const EdgeInsets.only(top:8),
                  child:Row(mainAxisSize:MainAxisSize.min,children:[ClipOval(child:Image.asset('assets/kidoza.webp',width:63,height:63,fit:BoxFit.cover)),const Text(' 💝',style:TextStyle(fontSize:34))]))),
              Align(alignment:Alignment.center,child:Padding(
                padding:const EdgeInsets.fromLTRB(26,45,26,12),
                child:Container(width:double.infinity,padding:const EdgeInsets.all(18),
                  decoration:BoxDecoration(color:Colors.white.withValues(alpha:.87),
                    borderRadius:BorderRadius.circular(26),
                    border:Border.all(color:const Color(0xFFFFBEDA),width:2)),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    const Text('إلى أميرتي بيلسان',style:TextStyle(
                      color:navy,fontSize:17,fontWeight:FontWeight.w900)),
                    const SizedBox(height:9),
                    Text(message.text,textAlign:TextAlign.center,
                      style:TextStyle(fontSize:size,color:color,fontWeight:FontWeight.w900)),
                    const SizedBox(height:10),
                    const Text('من والدك ❤️',style:TextStyle(
                      color:navy,fontWeight:FontWeight.w900)),
                  ]),
                ),
              )),
            ]),
          ),
          const SizedBox(height:13),
          FilledButton.icon(onPressed:null,
            icon:const Icon(Icons.send_rounded),
            label:const Text('الإرسال يتطلب تفعيل الربط السحابي')),
          const SizedBox(height:7),
          const Text('المعاينة تعمل محليًا؛ لا يُرسل شيء إلى جهاز الطفلة الآن.',
            textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
        ]),
      ),
    ),
  );
}

class InformationScreen extends StatelessWidget {
  const InformationScreen(this.title,this.body,{super.key});
  final String title,body;
  @override
  Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,
    child:Scaffold(appBar:AppBar(title:Text(title)),
      body:Container(color:pale,child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:550),
        child:Card(margin:const EdgeInsets.all(24),child:Padding(
          padding:const EdgeInsets.all(29),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            const Icon(Icons.info_outline_rounded,color:purple,size:49),
            const SizedBox(height:16),
            Text(body,textAlign:TextAlign.center,style:const TextStyle(
              color:navy,fontSize:18,fontWeight:FontWeight.w700)),
          ]),
        )),
      ))),
    ),
  );
}
