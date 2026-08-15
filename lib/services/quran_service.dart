import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranVerse {
  final int number;
  final int numberInSurah;
  final String text;
  final int page;
  final int juz;
  final int hizbQuarter;
  final int surahNumber;
  final String surahName;

  const QuranVerse({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.page,
    required this.juz,
    required this.hizbQuarter,
    required this.surahNumber,
    required this.surahName,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    final surah = json['surah'] is Map
        ? Map<String, dynamic>.from(json['surah'] as Map)
        : const <String, dynamic>{};
    return QuranVerse(
      number: (json['number'] as num?)?.toInt() ?? 0,
      numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      page: (json['page'] as num?)?.toInt() ?? 1,
      juz: (json['juz'] as num?)?.toInt() ?? 1,
      hizbQuarter: (json['hizbQuarter'] as num?)?.toInt() ?? 1,
      surahNumber: (surah['number'] as num?)?.toInt() ?? 0,
      surahName: surah['name'] as String? ?? '',
    );
  }
}

class QuranPage {
  final int page;
  final List<QuranVerse> verses;
  const QuranPage({required this.page, required this.verses});

  String get surahName => verses.isEmpty ? '' : verses.first.surahName;
  int get surahNumber => verses.isEmpty ? 0 : verses.first.surahNumber;
  int get juz => verses.isEmpty ? 1 : verses.first.juz;
  int get hizb => verses.isEmpty ? 1 : ((verses.first.hizbQuarter + 3) ~/ 4);
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) => QuranSurah(
        number: (json['number'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        englishName: json['englishName'] as String? ?? '',
        numberOfAyahs: (json['numberOfAyahs'] as num?)?.toInt() ?? 0,
      );
}

class QuranSearchResult {
  final QuranVerse verse;
  const QuranSearchResult({required this.verse});
}

class QuranTafsir {
  final String text;
  final String source;
  const QuranTafsir({required this.text, required this.source});
}

class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();
  static const _base = 'https://api.alquran.cloud/v1';

  Future<QuranPage> fetchPage(int page) async {
    final response = await http
        .get(Uri.parse('$_base/page/$page/quran-uthmani'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Quran request failed');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    final ayahs = (data['ayahs'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return QuranPage(
      page: page,
      verses: ayahs.map(QuranVerse.fromJson).toList(),
    );
  }

  Future<List<QuranSurah>> fetchSurahs() async {
    final response = await http
        .get(Uri.parse('$_base/surah'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Quran surahs request failed');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (root['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return data.map(QuranSurah.fromJson).toList();
  }

  Future<int> fetchSurahStartPage(int surahNumber) async {
    final response = await http
        .get(Uri.parse('$_base/surah/$surahNumber/quran-uthmani'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Surah request failed');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List;
    if (ayahs.isEmpty) throw Exception('Surah has no ayahs');
    final first = Map<String, dynamic>.from(ayahs.first as Map);
    return (first['page'] as num?)?.toInt() ?? 1;
  }

  Future<List<QuranSearchResult>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    final encoded = Uri.encodeComponent(query);
    final response = await http
        .get(Uri.parse('$_base/search/$encoded/all/quran-uthmani'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Quran search failed');

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;
    final matches = (data?['matches'] as List?) ?? const [];
    return matches
        .whereType<Map>()
        .map((e) => QuranSearchResult(
              verse: QuranVerse.fromJson(
                Map<String, dynamic>.from(e),
              ),
            ))
        .toList();
  }

  Future<QuranTafsir> fetchTafsir(int globalAyahNumber) async {
    final editions = <String, String>{
      'ar.muyassar': 'التفسير الميسر',
      'ar.jalalayn': 'تفسير الجلالين',
    };

    for (final entry in editions.entries) {
      try {
        final response = await http
            .get(Uri.parse('$_base/ayah/$globalAyahNumber/${entry.key}'))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final data = root['data'] as Map<String, dynamic>;
        final text = data['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return QuranTafsir(text: text.trim(), source: entry.value);
        }
      } catch (_) {
        // Try the next available Arabic tafsir edition.
      }
    }

    throw Exception('Tafsir request failed');
  }
}
