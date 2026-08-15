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

class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  final offline_quran.QuranService _offline =
      offline_quran.QuranService.instance;

  /// Converts a number to Arabic-Indic digits for the traditional ayah marker.
  String _arabicDigits(int number) {
    const digits = <String>['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  /// Removes any source-provided end marker or malformed suffix before rendering.
  /// The app owns the presentation of the ayah marker so it stays consistent
  /// on every device and font.
  String _cleanAyahText(String text) {
    var cleaned = text.trim();

    // Remove common source marker formats, including U+06DD and ﴿١﴾.
    cleaned = cleaned.replaceFirst(
      RegExp(r'\s*(?:۝\s*[٠-٩0-9]*|﴿\s*[٠-٩0-9]+\s*﴾)\s*$'),
      '',
    );

    // Remove the malformed suffix visible in some font/rendering combinations.
    cleaned = cleaned.replaceFirst(RegExp(r'\s*(?:ئج|غج)\s*$'), '');

    return cleaned.trim();
  }

  /// Returns the global ayah number used by the old online API shape.
  /// The value is calculated entirely from the bundled Quran metadata.
  int _globalAyahNumber(int surahNumber, int ayahNumber) {
    var total = 0;
    for (var surah = 1; surah < surahNumber; surah++) {
      total += _offline.getVerseCount(surah);
    }
    return total + ayahNumber;
  }

  QuranVerse _mapAyah(offline_quran.Ayah ayah) {
    final rub = _offline.getRubIndex(ayah.surahNumber, ayah.id) ?? 1;
    final cleanText = _cleanAyahText(ayah.text);
    final marker = '﴿${_arabicDigits(ayah.id)}﴾';

    return QuranVerse(
      number: _globalAyahNumber(ayah.surahNumber, ayah.id),
      numberInSurah: ayah.id,
      text: '$cleanText $marker',
      page: ayah.page,
      juz: ayah.juz,
      hizbQuarter: rub,
      surahNumber: ayah.surahNumber,
      surahName: _offline.getSurahNameArabic(ayah.surahNumber),
    );
  }

  /// Fully offline: Quran text and page metadata are embedded in the app.
  Future<QuranPage> fetchPage(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError.value(page, 'page', 'must be between 1 and 604');
    }
    final ayahs = _offline.getPage(page);
    return QuranPage(
      page: page,
      verses: ayahs.map(_mapAyah).toList(growable: false),
    );
  }

  /// Fully offline: all 114 surahs come from bundled metadata.
  Future<List<QuranSurah>> fetchSurahs() async {
    return _offline
        .getAllSurahs()
        .map(
          (s) => QuranSurah(
            number: s.number,
            name: s.nameAr,
            englishName: s.nameEn,
            numberOfAyahs: s.ayahCount,
          ),
        )
        .toList(growable: false);
  }

  /// Fully offline: returns the first page containing the requested surah.
  Future<int> fetchSurahStartPage(int surahNumber) async {
    final pages = <int>[];
    for (var page = 1; page <= 604; page++) {
      final ayahs = _offline.getPage(page);
      if (ayahs.any((ayah) => ayah.surahNumber == surahNumber)) {
        pages.add(page);
        break;
      }
    }
    if (pages.isEmpty) throw Exception('Surah not found');
    return pages.first;
  }

  /// Fully offline Arabic search. The package normalizes Arabic text for us.
  Future<List<QuranSearchResult>> search(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    final matches = _offline.search(query, limit: 50);
    return matches
        .map((ayah) => QuranSearchResult(verse: _mapAyah(ayah)))
        .toList(growable: false);
  }

  /// Fully offline Tafsir Al-Muyassar for every ayah.
  Future<QuranTafsir> fetchTafsir(int globalAyahNumber) async {
    var remaining = globalAyahNumber;
    for (var surah = 1; surah <= 114; surah++) {
      final count = _offline.getVerseCount(surah);
      if (remaining <= count) {
        final tafsir = _offline.getTafsir(surah)[remaining];
        if (tafsir != null && tafsir.trim().isNotEmpty) {
          return QuranTafsir(
            text: tafsir.trim(),
            source: 'التفسير الميسر',
          );
        }
        break;
      }
      remaining -= count;
    }
    throw Exception('Tafsir not found');
  }
}
