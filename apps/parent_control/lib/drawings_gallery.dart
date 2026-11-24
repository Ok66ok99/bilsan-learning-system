import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_authentication.dart';

class DrawingsGallery extends StatefulWidget {
  const DrawingsGallery({super.key});
  @override
  State<DrawingsGallery> createState()=>_DrawingsGalleryState();
}
class _DrawingsGalleryState extends State<DrawingsGallery> {
  String? familyId;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    if(!FirebaseBootstrap.initialized || FirebaseAuth.instance.currentUser==null){
      setState(()=>error='سجّل دخول ولي الأمر أولًا من إعدادات الربط.');
      return;
    }
    try {
      final response=await FirebaseFunctions.instanceFor(region:'us-central1')
        .httpsCallable('createFamily').call();
      if(mounted)setState(()=>familyId=(response.data as Map)['familyId'] as String);
    } catch (_) {if(mounted)setState(()=>error='تعذر التحقق من الأسرة. حاول مجددًا.');}
  }
  @override
  Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,
    child:Scaffold(appBar:AppBar(title:const Text('رسومات طفلتي')),
      body:error!=null?Center(child:Text(error!)):
        familyId==null?const Center(child:CircularProgressIndicator()):
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream:FirebaseFirestore.instance.collection('families').doc(familyId)
            .collection('drawings').snapshots(),
          builder:(context,snapshot){
            if(snapshot.hasError)return const Center(child:Text('تعذر تحميل الرسومات'));
            if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
            final entries=<Map<String,dynamic>>[];
            for(final doc in snapshot.data!.docs){
              final items=doc.data()['items'];
              if(items is List){
                for(final item in items){
                  if(item is Map)entries.add(Map<String,dynamic>.from(item));
                }
              }
            }
            entries.sort((a,b)=>(b['createdAt']??'').toString()
              .compareTo((a['createdAt']??'').toString()));
            if(entries.isEmpty)return const Center(child:Text('لم تصل رسومات محفوظة بعد.'));
            return ListView.builder(padding:const EdgeInsets.all(16),
              itemCount:entries.length,itemBuilder:(context,i){
                final drawing=entries[i];
                return Card(child:Padding(padding:const EdgeInsets.all(12),
                  child:Column(children:[
                    Text((drawing['createdAt']??'رسمة بيلسان').toString()),
                    const SizedBox(height:8),
                    AspectRatio(aspectRatio:1,child:CustomPaint(
                      painter:ArchivePainter(drawing['strokes']),
                      child:const SizedBox.expand())),
                  ])));
              });
          }),
    ));
}
class ArchivePainter extends CustomPainter {
  const ArchivePainter(this.raw);
  final Object? raw;
  @override
  void paint(Canvas canvas,Size size){
    canvas.drawColor(Colors.white,BlendMode.src);
    if(raw is! List)return;
    final brush=Paint()..color=const Color(0xFFB42D80)
      ..strokeWidth=5..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    for(final line in raw as List){
      if(line is! Map || line['points'] is! List)continue;
      final path=Path();
      var first=true;
      for(final item in line['points'] as List){
        if(item is! Map || item['x'] is! num || item['y'] is! num)continue;
        final x=(item['x'] as num).toDouble()*size.width;
        final y=(item['y'] as num).toDouble()*size.height;
        if(first){path.moveTo(x,y);first=false;}else{path.lineTo(x,y);}
      }
      canvas.drawPath(path,brush);
    }
  }
  @override
  bool shouldRepaint(covariant ArchivePainter old)=>raw!=old.raw;
}
