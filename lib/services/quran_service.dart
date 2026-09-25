import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran_with_tafsir/quran_with_tafsir.dart' as offline_quran;

enum QuranRiwaya { hafs, warsh }

class QuranVerse {
  final int number;
  final int numberInSurah;
  final String text;
  final int page;
  final int juz;
  final int hizbQuarter;
  final int surahNumber;
  final String surahName;
  final List<int> hafsVerseNumbers;
  final QuranRiwaya riwaya;

  const QuranVerse({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.page,
    required this.juz,
    required this.hizbQuarter,
    required this.surahNumber,
    required this.surahName,
    required this.hafsVerseNumbers,
    required this.riwaya,
  });

  bool get isSajda => hafsVerseNumbers.any((ayah) =>
      const <String>{
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
      }.contains('\${surahNumber}:\$ayah'));

  int get hizb => ((hizbQuarter + 3) ~/ 4).clamp(1, 60);
}

class QuranPage {
  final int page;
  final List<QuranVerse> verses;
  const QuranPage({required this.page, required this.verses});

  String get surahName => verses.isEmpty ? '' : verses.first.surahName;
  int get surahNumber => verses.isEmpty ? 0 : verses.first.surahNumber;
  int get juz => verses.isEmpty ? 1 : verses.first.juz;
  int get hizb => verses.isEmpty ? 1 : verses.first.hizb;
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final int startPage;
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.startPage,
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

/// Offline Quran text and metadata.
///
/// Hafs text is Tanzil Uthmani. Warsh is generated during CI from the
/// versioned Quranpedia mushaf-4 dump, keeping the APK text-only and
/// avoiding the 1208 PNG pages previously downloaded into the release build.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  final offline_quran.QuranService _metadata =
      offline_quran.QuranService.instance;
  final Map<String, String> _textByAyah = <String, String>{};
  final Map<int, List<QuranVerse>> _warshByPage = <int, List<QuranVerse>>{};
  final List<QuranSurah> _warshSurahs = <QuranSurah>[];
  Future<void>? _loadHafsFuture;
  Future<void>? _loadWarshFuture;

  Future<void> _ensureHafsLoaded() => _loadHafsFuture ??= _loadHafsText();
  Future<void> _ensureWarshLoaded() => _loadWarshFuture ??= _loadWarshText();

  Future<void> _loadHafsText() async {
    final raw = await rootBundle.loadString('assets/quran/quran-uthmani.txt');
    final lines = const LineSplitter()
        .convert(raw)
        .where((line) => line.trim().isNotEmpty);

    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length < 3) {
        throw StateError('Invalid Tanzil Quran line.');
      }
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      if (surah == null ||
          ayah == null ||
          surah < 1 ||
          surah > 114 ||
          ayah < 1) {
        throw StateError('Invalid Tanzil Quran reference.');
      }
      final text = parts.sublist(2).join('|');
      if (text.isEmpty) throw StateError('Empty Quran text at \$surah:\$ayah');
      _textByAyah['\$surah:\$ayah'] = text;
    }

    if (_textByAyah.length != 6236 ||
        !_textByAyah.containsKey('1:1') ||
        !_textByAyah.containsKey('114:6')) {
      throw StateError('Tanzil Quran integrity check failed.');
    }
  }

  Future<void> _loadWarshText() async {
    final raw = await rootBundle.loadString('assets/quran/warsh.json');
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final pageCount = root['pageCount'] as int?;
    if (pageCount != 604) {
      throw StateError('Warsh Quran integrity check failed: expected 604 pages.');
    }

    final surahs = root['surahs'];
    if (surahs is! List || surahs.length != 114) {
      throw StateError('Warsh Quran integrity check failed: expected 114 surahs.');
    }

    for (final rawSurah in surahs) {
      final surah = rawSurah as Map<String, dynamic>;
      final number = surah['number'] as int;
      final name = surah['name'] as String;
      final rawAyahs = surah['ayahs'] as List<dynamic>;
      if (rawAyahs.isEmpty) {
        throw StateError('Warsh surah \$number has no ayahs.');
      }
      final firstPage = rawAyahs.first['page'] as int;
      _warshSurahs.add(QuranSurah(
        number: number,
        name: name,
        englishName: name,
        numberOfAyahs: rawAyahs.length,
        startPage: firstPage,
      ));

      for (final rawAyah in rawAyahs) {
        final ayah = rawAyah as Map<String, dynamic>;
        final ayahNumber = ayah['number'] as int;
        final page = ayah['page'] as int;
        final hafsNumbers = (ayah['number_in_hafs'] as List<dynamic>?)
                ?.map((value) => value as int)
                .toList(growable: false) ??
            const <int>[];
        final verse = QuranVerse(
          number: ayahNumber,
          numberInSurah: ayahNumber,
          text: ayah['text'] as String,
          page: page,
          juz: _hafsJuz(number, hafsNumbers),
          hizbQuarter: _hafsRub(number, hafsNumbers),
          surahNumber: number,
          surahName: name,
          hafsVerseNumbers: hafsNumbers,
          riwaya: QuranRiwaya.warsh,
        );
        (_warshByPage[page] ??= <QuranVerse>[]).add(verse);
      }
    }

    if (_warshByPage.length != 604 ||
        _warshByPage.keys.any((p) => p < 1 || p > 604)) {
      throw StateError('Warsh Quran integrity check failed: page map is incomplete.');
    }
  }

  int _hafsRub(int surahNumber, List<int> numbers) {
    final verses = _metadata.getSurah(surahNumber).verses;
    for (final number in numbers) {
      final rub = _metadata.getRubIndex(surahNumber, number);
      if (rub != null) return rub;
    }
    return verses.isEmpty ? 1 : (_metadata.getRubIndex(surahNumber, verses.first.id) ?? 1);
  }

  int _hafsJuz(int surahNumber, List<int> numbers) {
    final verses = _metadata.getSurah(surahNumber).verses;
    for (final number in numbers) {
      for (final verse in verses) {
        if (verse.id == number) return verse.juz;
      }
    }
    return verses.isEmpty ? 1 : verses.first.juz;
  }

  int _globalAyahNumber(int surahNumber, int ayahNumber) {
    var total = 0;
    for (var surah = 1; surah < surahNumber; surah++) {
      total += _metadata.getVerseCount(surah);
    }
    return total + ayahNumber;
  }

  QuranVerse _mapHafsAyah(offline_quran.Ayah ayah) {
    final text = _textByAyah['\${ayah.surahNumber}:\${ayah.id}'];
    if (text == null || text.isEmpty) {
      throw StateError('Tanzil Quran text missing for \${ayah.surahNumber}:\${ayah.id}.');
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
      hafsVerseNumbers: <int>[ayah.id],
      riwaya: QuranRiwaya.hafs,
    );
  }

  Future<QuranPage> fetchPage(
    int page, {
    QuranRiwaya riwaya = QuranRiwaya.hafs,
  }) async {
    if (page < 1 || page > 604) throw ArgumentError.value(page, 'page');
    if (riwaya == QuranRiwaya.warsh) {
      await _ensureWarshLoaded();
      return QuranPage(
        page: page,
        verses: List.unmodifiable(_warshByPage[page] ?? const []),
      );
    }
    await _ensureHafsLoaded();
    final ayahs = _metadata.getPage(page);
    return QuranPage(
      page: page,
      verses: ayahs.map(_mapHafsAyah).toList(growable: false),
    );
  }

  Future<List<QuranSurah>> fetchSurahs({
    QuranRiwaya riwaya = QuranRiwaya.hafs,
  }) async {
    if (riwaya == QuranRiwaya.warsh) {
      await _ensureWarshLoaded();
      return List.unmodifiable(_warshSurahs);
    }
    await _ensureHafsLoaded();
    return _metadata.getAllSurahs().map((s) => QuranSurah(
      number: s.number,
      name: s.nameAr,
      englishName: s.nameEn,
      numberOfAyahs: s.ayahCount,
      startPage: _metadata.getSurah(s.number).verses.first.page,
    )).toList(growable: false);
  }

  Future<int> fetchSurahStartPage(
    int surahNumber, {
    QuranRiwaya riwaya = QuranRiwaya.hafs,
  }) async {
    final surahs = await fetchSurahs(riwaya: riwaya);
    return surahs.firstWhere((surah) => surah.number == surahNumber).startPage;
  }

  Future<List<QuranSearchResult>> search(
    String keyword, {
    QuranRiwaya riwaya = QuranRiwaya.hafs,
  }) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];
    final results = <QuranSearchResult>[];
    if (riwaya == QuranRiwaya.warsh) {
      await _ensureWarshLoaded();
      for (final page in _warshByPage.values) {
        for (final verse in page) {
          if (verse.text.contains(query)) {
            results.add(QuranSearchResult(verse: verse));
            if (results.length >= 50) return results;
          }
        }
      }
      return results;
    }
    await _ensureHafsLoaded();
    for (var surah = 1; surah <= 114 && results.length < 50; surah++) {
      for (final ayah in _metadata.getSurah(surah).verses) {
        final verse = _mapHafsAyah(ayah);
        if (verse.text.contains(query)) {
          results.add(QuranSearchResult(verse: verse));
          if (results.length >= 50) break;
        }
      }
    }
    return results;
  }

  Future<QuranTafsir> fetchTafsir(QuranVerse verse) async {
    await _ensureHafsLoaded();
    final texts = <String>[];
    for (final ayah in verse.hafsVerseNumbers) {
      var remaining = _globalAyahNumber(verse.surahNumber, ayah);
      for (var surah = 1; surah <= 114; surah++) {
        final count = _metadata.getVerseCount(surah);
        if (remaining <= count) {
          final tafsir = _metadata.getTafsir(surah)[remaining];
          if (tafsir != null && tafsir.trim().isNotEmpty) {
            texts.add(tafsir.trim());
          }
          break;
        }
        remaining -= count;
      }
    }
    if (texts.isEmpty) throw Exception('Tafsir not found');
    return QuranTafsir(
      text: texts.join('\\n\\n'),
      source: 'التفسير الميسر',
    );
  }
}
