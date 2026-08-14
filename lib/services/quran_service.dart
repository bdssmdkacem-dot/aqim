import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranVerse {
  final int number;
  final String text;
  final int page;
  final int juz;

  const QuranVerse({required this.number, required this.text, required this.page, required this.juz});

  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
        number: json['number'] as int,
        text: json['text'] as String,
        page: (json['page'] as num?)?.toInt() ?? 1,
        juz: (json['juz'] as num?)?.toInt() ?? 1,
      );
}

class QuranPage {
  final int page;
  final List<QuranVerse> verses;
  const QuranPage({required this.page, required this.verses});
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  const QuranSurah({required this.number, required this.name, required this.englishName, required this.numberOfAyahs});

  factory QuranSurah.fromJson(Map<String, dynamic> json) => QuranSurah(
        number: json['number'] as int,
        name: json['name'] as String,
        englishName: json['englishName'] as String,
        numberOfAyahs: json['numberOfAyahs'] as int,
      );
}

class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();
  static const _base = 'https://api.alquran.cloud/v1';

  Future<QuranPage> fetchPage(int page) async {
    final response = await http.get(Uri.parse('$_base/page/$page/quran-uthmani')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Quran request failed');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();
    return QuranPage(page: page, verses: ayahs.map(QuranVerse.fromJson).toList());
  }

  Future<List<QuranSurah>> fetchSurahs() async {
    final response = await http.get(Uri.parse('$_base/surah')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Quran surahs request failed');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (root['data'] as List).cast<Map<String, dynamic>>();
    return data.map(QuranSurah.fromJson).toList();
  }
}
