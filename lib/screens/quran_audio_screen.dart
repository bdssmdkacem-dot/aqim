import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/quran_audio_service.dart';
import '../theme/app_theme.dart';

class QuranAudioScreen extends StatefulWidget { const QuranAudioScreen({super.key}); @override State<QuranAudioScreen> createState()=>_QuranAudioScreenState(); }
class _QuranAudioScreenState extends State<QuranAudioScreen>{
 final player=AudioPlayer(); final service=QuranAudioService.instance; QuranReciter reciter=QuranAudioService.reciters.first; int surah=1; bool loading=false;
 static const names=['الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس'];
 @override void dispose(){player.dispose();super.dispose();}
 Future<void> play()async{setState(()=>loading=true);try{await player.stop();await player.play(UrlSource(reciter.audioUrl(surah)));}finally{if(mounted)setState(()=>loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.ink,appBar:AppBar(title:const Text('الاستماع إلى القرآن')),body:Directionality(textDirection:TextDirection.rtl,child:ListView(padding:const EdgeInsets.all(18),children:[
 DropdownButtonFormField<QuranReciter>(value:reciter,dropdownColor:AppColors.surfaceDark,items:QuranAudioService.reciters.map((r)=>DropdownMenuItem(value:r,child:Text(r.name+' — '+r.riwaya))).toList(),onChanged:(r){if(r!=null)setState(() { reciter = r; surah = 1; });}),
 const SizedBox(height:16), Text(reciter.name,style:const TextStyle(color:AppColors.ivory,fontSize:24,fontWeight:FontWeight.w800)),Text(reciter.riwaya+' • '+reciter.surahTotal.toString()+' سورة',style:const TextStyle(color:AppColors.textMuted)),const SizedBox(height:12),
 DropdownButtonFormField<int>(value:surah,dropdownColor:AppColors.surfaceDark,items:List.generate(reciter.surahTotal,(i)=>DropdownMenuItem(value:i+1,child:Text((i+1).toString()+'. '+names[i]))),onChanged:(v){if(v!=null)setState(()=>surah=v);}),const SizedBox(height:14),
 FilledButton.icon(onPressed:loading?null:play,icon:const Icon(Icons.play_arrow_rounded),label:Text(loading?'جاري التشغيل…':'تشغيل السورة')),
 if(reciter.latestTitle!=null) Padding(padding:const EdgeInsets.only(top:12),child:OutlinedButton.icon(onPressed:()=>service.openLatestSource(reciter),icon:const Icon(Icons.new_releases_outlined),label:Text(reciter.latestTitle!))),
 const SizedBox(height:16),const Text('ورش: العيون الكوشي وعمر القزابري. حفص: 15 قارئًا آخرون.',style:TextStyle(color:AppColors.textMuted,fontSize:11)),const SizedBox(height:8),const Text('الصوت يُشغّل من خوادم MP3Quran ولا يُنسخ داخل APK.',style:TextStyle(color:AppColors.textMuted,fontSize:10),textAlign:TextAlign.center)
]))); }
