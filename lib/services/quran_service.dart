import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_with_tafsir/quran_with_tafsir.dart' as offline_quran;

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

  bool get isSajda => const <String>{
    '7:206',
    '13:15',
    '16:50',
    '17:109',
    '19:58',
    '22:18',
    '22:77',
    '25:60',
    '27:26',
    '32:15',
    '38:24',
    '41:38',
    '53:62',
    '84:21',
    '96:19',
  }.contains('$surahNumber:$numberInSurah');
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

/// Quran loading is online-first so the displayed Arabic text comes from the
/// canonical quran-uthmani edition instead of a malformed/generated suffix.
/// The bundled dataset remains as a fallback so the Quran still works offline.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  final offline_quran.QuranService _offline =
      offline_quran.QuranService.instance;

  static const _api = 'https://api.alquran.cloud/v1';

  String _arabicDigits(int number) {
    const digits = <String>['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  /// Keep the Quran wording untouched, but remove only end markers supplied
  /// by an API/dataset before rendering our single consistent ayah marker.
  String _cleanAyahText(String text) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r'\s*(?:۝\s*[٠-٩0-9]*|۞|﴿\s*[٠-٩0-9]+\s*﴾|ئج|غج)\s*$'),
      '',
    );
    return cleaned.trim();
  }

  bool _isSajdaAyah(int surahNumber, int ayahNumber) => const <String>{
    '7:206',
    '13:15',
    '16:50',
    '17:109',
    '19:58',
    '22:18',
    '22:77',
    '25:60',
    '27:26',
    '32:15',
    '38:24',
    '41:38',
    '53:62',
    '84:21',
    '96:19',
  }.contains('$surahNumber:$ayahNumber');

  String _marker(int surahNumber, int ayahNumber) {
    final number = _arabicDigits(ayahNumber);
    return _isSajdaAyah(surahNumber, ayahNumber)
        ? '۩ $number'
        : '۝$number';
  }

  int _globalAyahNumber(int surahNumber, int ayahNumber) {
    var total = 0;
    for (var surah = 1; surah < surahNumber; surah++) {
      total += _offline.getVerseCount(surah);
    }
    return total + ayahNumber;
  }

  QuranVerse _mapOfflineAyah(offline_quran.Ayah ayah) {
    final rub = _offline.getRubIndex(ayah.surahNumber, ayah.id) ?? 1;
    final cleanText = _cleanAyahText(ayah.text);
    return QuranVerse(
      number: _globalAyahNumber(ayah.surahNumber, ayah.id),
      numberInSurah: ayah.id,
      text: '$cleanText ${_marker(ayah.surahNumber, ayah.id)}',
      page: ayah.page,
      juz: ayah.juz,
      hizbQuarter: rub,
      surahNumber: ayah.surahNumber,
      surahName: _offline.getSurahNameArabic(ayah.surahNumber),
    );
  }

  QuranVerse? _mapOnlineAyah(Map<String, dynamic> raw) {
    final surah = raw['surah'];
    if (surah is! Map<String, dynamic>) return null;
    final surahNumber = (surah['number'] as num?)?.toInt();
    final ayahNumber = (raw['numberInSurah'] as num?)?.toInt();
    final globalNumber = (raw['number'] as num?)?.toInt();
    final page = (raw['page'] as num?)?.toInt();
    final juz = (raw['juz'] as num?)?.toInt();
    final hizbQuarter = (raw['hizbQuarter'] as num?)?.toInt();
    final text = raw['text'] as String?;
    if (surahNumber == null ||
        ayahNumber == null ||
        globalNumber == null ||
        page == null ||
        juz == null ||
        hizbQuarter == null ||
        text == null) {
      return null;
    }

    final surahName = (surah['name'] as String?)?.trim() ??
        _offline.getSurahNameArabic(surahNumber);
    final cleanText = _cleanAyahText(text);
    return QuranVerse(
      number: globalNumber,
      numberInSurah: ayahNumber,
      text: '$cleanText ${_marker(surahNumber, ayahNumber)}',
      page: page,
      juz: juz,
      hizbQuarter: hizbQuarter,
      surahNumber: surahNumber,
      surahName: surahName,
    );
  }

  Future<List<QuranVerse>?> _fetchOnlinePage(int page) async {
    try {
      final uri = Uri.parse('$_api/page/$page/quran-uthmani');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final data = root['data'] as Map<String, dynamic>?;
      final ayahs = data?['ayahs'] as List<dynamic>?;
      if (ayahs == null || ayahs.isEmpty) return null;
      final verses = ayahs
          .whereType<Map<String, dynamic>>()
          .map(_mapOnlineAyah)
          .whereType<QuranVerse>()
          .toList(growable: false);
      return verses.isEmpty ? null : verses;
    } catch (_) {
      return null;
    }
  }

  Future<QuranPage> fetchPage(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError.value(page, 'page', 'must be between 1 and 604');
    }
    final online = await _fetchOnlinePage(page);
    if (online != null) {
      return QuranPage(page: page, verses: online);
    }

    final ayahs = _offline.getPage(page);
    return QuranPage(
      page: page,
      verses: ayahs.map(_mapOfflineAyah).toList(growable: false),
    );
  }

  Future<List<QuranSurah>> fetchSurahs() async {
    try {
      final response = await http
          .get(Uri.parse('$_api/surah'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final data = root['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          return data.whereType<Map<String, dynamic>>().map((s) {
            return QuranSurah(
              number: (s['number'] as num).toInt(),
              name: (s['name'] as String?) ?? '',
              englishName: (s['englishName'] as String?) ?? '',
              numberOfAyahs: (s['numberOfAyahs'] as num).toInt(),
            );
          }).toList(growable: false);
        }
      }
    } catch (_) {}

    return _offline.getAllSurahs().map((s) => QuranSurah(
      number: s.number,
      name: s.nameAr,
      englishName: s.nameEn,
      numberOfAyahs: s.ayahCount,
    )).toList(growable: false);
  }

  Future<int> fetchSurahStartPage(int surahNumber) async {
    for (var page = 1; page <= 604; page++) {
      final online = await _fetchOnlinePage(page);
      if (online != null && online.any((ayah) => ayah.surahNumber == surahNumber)) {
        return page;
      }
      final ayahs = _offline.getPage(page);
      if (ayahs.any((ayah) => ayah.surahNumber == surahNumber)) return page;
    }
    throw Exception('Surah not found');
  }

  Future<List<QuranSearchResult>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse('$_api/search/$encoded/all/quran-uthmani');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final data = root['data'] as Map<String, dynamic>?;
        final matches = data?['matches'] as List<dynamic>?;
        if (matches != null) {
          final results = matches
              .whereType<Map<String, dynamic>>()
              .map(_mapOnlineAyah)
              .whereType<QuranVerse>()
              .take(50)
              .map((verse) => QuranSearchResult(verse: verse))
              .toList(growable: false);
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {}

    return _offline
        .search(query, limit: 50)
        .map((ayah) => QuranSearchResult(verse: _mapOfflineAyah(ayah)))
        .toList(growable: false);
  }

  Future<QuranTafsir> fetchTafsir(int globalAyahNumber) async {
    var remaining = globalAyahNumber;
    for (var surah = 1; surah <= 114; surah++) {
      final count = _offline.getVerseCount(surah);
      if (remaining <= count) {
        final tafsir = _offline.getTafsir(surah)[remaining];
        if (tafsir != null && tafsir.trim().isNotEmpty) {
          return QuranTafsir(text: tafsir.trim(), source: 'التفسير الميسر');
        }
        break;
      }
      remaining -= count;
    }
    throw Exception('Tafsir not found');
  }
}
