import 'package:quran_data_dart/quran.dart' as verified_quran;
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

  const QuranVerse({required this.number, required this.numberInSurah, required this.text, required this.page, required this.juz, required this.hizbQuarter, required this.surahNumber, required this.surahName});

  bool get isSajda => const <String>{'7:206','13:15','16:50','17:109','19:58','22:18','22:77','25:60','27:26','32:15','38:24','41:38','53:62','84:21','96:19'}.contains('$surahNumber:$numberInSurah');
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
  const QuranSurah({required this.number, required this.name, required this.englishName, required this.numberOfAyahs});
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

/// Quran text is sourced from the complete Tanzil Uthmani text through
/// quran_data_dart. quran_with_tafsir is retained only for metadata and tafsir.
/// No regex cleanup, suffix removal, or manual rewriting is applied to ayahs.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  final offline_quran.QuranService _metadata = offline_quran.QuranService.instance;
  final Map<String, String> _verifiedText = <String, String>{};
  Future<void>? _textLoadFuture;

  Future<void> _ensureVerifiedText() => _textLoadFuture ??= _loadVerifiedText();

  Future<void> _loadVerifiedText() async {
    await verified_quran.QuranService.initialize();
    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      final surah = await verified_quran.QuranService.getSurah(surahNumber);
      for (final ayah in surah.ayat) {
        _verifiedText['$surahNumber:${ayah.id}'] = ayah.text.trim();
      }
    }
    if (_verifiedText.length != 6236) {
      throw StateError('Tanzil Quran integrity check failed: expected 6236 ayat, got ${_verifiedText.length}.');
    }
  }

  int _globalAyahNumber(int surahNumber, int ayahNumber) {
    var total = 0;
    for (var surah = 1; surah < surahNumber; surah++) {
      total += _metadata.getVerseCount(surah);
    }
    return total + ayahNumber;
  }

  QuranVerse _mapMetadataAyah(offline_quran.Ayah ayah) {
    final text = _verifiedText['${ayah.surahNumber}:${ayah.id}'];
    if (text == null || text.isEmpty) {
      throw StateError('Tanzil Quran text missing for ${ayah.surahNumber}:${ayah.id}.');
    }
    final rub = _metadata.getRubIndex(ayah.surahNumber, ayah.id) ?? 1;
    return QuranVerse(
      number: _globalAyahNumber(ayah.surahNumber, ayah.id),
      numberInSurah: ayah.id,
      text: text,
      page: ayah.page,
      juz: ayah.juz,
      hizbQuarter: rub,
      surahNumber: ayah.surahNumber,
      surahName: _metadata.getSurahNameArabic(ayah.surahNumber),
    );
  }

  Future<QuranPage> fetchPage(int page) async {
    if (page < 1 || page > 604) throw ArgumentError.value(page, 'page', 'must be between 1 and 604');
    await _ensureVerifiedText();
    final ayahs = _metadata.getPage(page);
    return QuranPage(page: page, verses: ayahs.map(_mapMetadataAyah).toList(growable: false));
  }

  Future<List<QuranSurah>> fetchSurahs() async {
    await _ensureVerifiedText();
    return _metadata.getAllSurahs().map((s) => QuranSurah(number: s.number, name: s.nameAr, englishName: s.nameEn, numberOfAyahs: s.ayahCount)).toList(growable: false);
  }

  Future<int> fetchSurahStartPage(int surahNumber) async {
    for (var page = 1; page <= 604; page++) {
      final ayahs = _metadata.getPage(page);
      if (ayahs.any((ayah) => ayah.surahNumber == surahNumber)) return page;
    }
    throw Exception('Surah not found');
  }

  Future<List<QuranSearchResult>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];
    await _ensureVerifiedText();
    final results = <QuranSearchResult>[];
    for (var surah = 1; surah <= 114 && results.length < 50; surah++) {
      for (final ayah in _metadata.getSurah(surah).verses) {
        final verse = _mapMetadataAyah(ayah);
        if (verse.text.contains(query)) {
          results.add(QuranSearchResult(verse: verse));
          if (results.length >= 50) break;
        }
      }
    }
    return results;
  }

  Future<QuranTafsir> fetchTafsir(int globalAyahNumber) async {
    var remaining = globalAyahNumber;
    for (var surah = 1; surah <= 114; surah++) {
      final count = _metadata.getVerseCount(surah);
      if (remaining <= count) {
        final tafsir = _metadata.getTafsir(surah)[remaining];
        if (tafsir != null && tafsir.trim().isNotEmpty) return QuranTafsir(text: tafsir.trim(), source: 'التفسير الميسر');
        break;
      }
      remaining -= count;
    }
    throw Exception('Tafsir not found');
  }
}
