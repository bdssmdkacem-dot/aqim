import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum QuranAudioTrust { catalog, officialArchive, thirdPartyArchive }

class QuranReciter {
  final int id, moshafId, surahTotal;
  final String name, nameEn, riwaya, style, server;
  final String? latestTitle, latestSourceUrl;
  final QuranAudioTrust latestTrust;
  const QuranReciter({required this.id,required this.moshafId,required this.name,required this.nameEn,required this.riwaya,required this.style,required this.surahTotal,required this.server,this.latestTitle,this.latestTrust=QuranAudioTrust.catalog,this.latestSourceUrl});
  String audioUrl(int surah)=>server+surah.toString().padLeft(3,'0')+'.mp3';
}

class QuranAyahTiming {
  final int ayah;
  final int startTime;
  final int endTime;
  const QuranAyahTiming({required this.ayah, required this.startTime, required this.endTime});
}

class QuranAudioService {
  QuranAudioService._();
  static final instance=QuranAudioService._();
  static const reciters=<QuranReciter>[
    QuranReciter(id:112,moshafId:112,name:'محمد صديق المنشاوي',nameEn:'Mohammed Siddiq Al-Minshawi',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server10.mp3quran.net/minsh/',latestTitle:'ختمة مرتلة نادرة مع فقرات جديدة — 2026',latestTrust:QuranAudioTrust.officialArchive,latestSourceUrl:'https://misrquran.gov.eg/'),
    QuranReciter(id:118,moshafId:118,name:'محمود خليل الحصري',nameEn:'Mahmoud Khalil Al-Hussary',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server13.mp3quran.net/husr/'),
    QuranReciter(id:51,moshafId:53,name:'عبد الباسط عبد الصمد',nameEn:'Abdulbasit Abdulsamad',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server7.mp3quran.net/basit/'),
    QuranReciter(id:125,moshafId:125,name:'مصطفى إسماعيل',nameEn:'Mustafa Ismail',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server8.mp3quran.net/mustafa/'),
    QuranReciter(id:106,moshafId:106,name:'محمد الطبلاوي',nameEn:'Mohammad Al-Tablaway',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server12.mp3quran.net/tblawi/'),
    QuranReciter(id:123,moshafId:123,name:'مشاري راشد العفاسي',nameEn:'Mishary Alafasi',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server8.mp3quran.net/afs/'),
    QuranReciter(id:102,moshafId:102,name:'ماهر المعيقلي',nameEn:'Maher Al-Meaqli',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server12.mp3quran.net/maher/'),
    QuranReciter(id:54,moshafId:54,name:'عبد الرحمن السديس',nameEn:'Abdulrahman Al-Sudais',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server11.mp3quran.net/sds/'),
    QuranReciter(id:31,moshafId:31,name:'سعود الشريم',nameEn:'Saud Al-Shuraim',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server7.mp3quran.net/shur/'),
    QuranReciter(id:30,moshafId:30,name:'سعد الغامدي',nameEn:'Saad Al-Ghamdi',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server7.mp3quran.net/s_gmd/'),
    QuranReciter(id:92,moshafId:92,name:'ياسر الدوسري',nameEn:'Yasser Al-Dosari',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server11.mp3quran.net/yasser/',latestTitle:'تلاوات رمضان 1447 هـ — 2026',latestTrust:QuranAudioTrust.officialArchive,latestSourceUrl:'https://www.yaldosry.com/taraweeh/c/273'),
    QuranReciter(id:20,moshafId:20,name:'خالد الجليل',nameEn:'Khalid Al-Jileel',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server10.mp3quran.net/jleel/',latestTitle:'تلاوات رمضان 1447 هـ — 2026',latestTrust:QuranAudioTrust.thirdPartyArchive,latestSourceUrl:'https://www.tvquran.com/ar/scholar/21/profile/%D8%AE%D8%A7%D9%84%D8%AF-%D8%A7%D9%84%D8%AC%D9%84%D9%8A%D9%84'),
    QuranReciter(id:81,moshafId:81,name:'فارس عباد',nameEn:'Fares Abbad',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server8.mp3quran.net/frs_a/'),
    QuranReciter(id:4,moshafId:4,name:'أبو بكر الشاطري',nameEn:'Abu Bakr Al-Shatri',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server11.mp3quran.net/shatri/'),
    QuranReciter(id:24,moshafId:24,name:'خليفة الطنيجي',nameEn:'Khalifa Al-Tunaiji',riwaya:'حفص عن عاصم',style:'مرتل',surahTotal:114,server:'https://server12.mp3quran.net/tnjy/'),
    QuranReciter(id:16,moshafId:16,name:'العيون الكوشي',nameEn:'Aloyoon Al-Koshi',riwaya:'ورش عن نافع',style:'مرتل',surahTotal:114,server:'https://server11.mp3quran.net/koshi/'),
    QuranReciter(id:80,moshafId:80,name:'عمر القزابري',nameEn:'Omar Al-Qazabri',riwaya:'ورش عن نافع',style:'مرتل',surahTotal:114,server:'https://server9.mp3quran.net/omar_warsh/'),
  ];
  final Map<String, List<QuranAyahTiming>> _timingCache = {};

  Future<List<QuranAyahTiming>> fetchAyahTimings({
    required QuranReciter reciter,
    required int surah,
  }) async {
    final key = '\${reciter.moshafId}:\$surah';
    final cached = _timingCache[key];
    if (cached != null) return cached;

    final uri = Uri.parse(
      'https://mp3quran.net/api/v3/ayat_timing?surah=\$surah&read=\${reciter.moshafId}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('تعذر تحميل توقيتات الآيات');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    final result = decoded.whereType<Map>().map((item) => QuranAyahTiming(
      ayah: (item['ayah'] as num?)?.toInt() ?? 0,
      startTime: (item['start_time'] as num?)?.toInt() ?? 0,
      endTime: (item['end_time'] as num?)?.toInt() ?? 0,
    )).where((item) => item.ayah > 0 && item.endTime > item.startTime).toList();
    _timingCache[key] = result;
    return result;
  }

  Future<bool> openLatestSource(QuranReciter r) async {
    final u=r.latestSourceUrl;
    if(u==null) return false;
    return launchUrl(Uri.parse(u),mode:LaunchMode.externalApplication);
  }
}
