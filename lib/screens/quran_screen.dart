import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/quran_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class QuranScreen extends StatefulWidget {
  final int? initialPage;

  const QuranScreen({super.key, this.initialPage});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late int _page;
  QuranPage? _quranPage;
  List<QuranSurah>? _surahs;
  final Map<int, QuranTafsir> _tafsirCache = {};
  bool _loading = true;
  String? _error;
  int _completedKhatmahCount = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage ?? 1;
    _loadProgress();
    _loadPage();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _completedKhatmahCount = prefs.getInt('quran_khatmah_count') ?? 0;
    });
  }

  Future<void> _loadPage() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final page = await QuranService.instance.fetchPage(_page);
      if (!mounted) return;
      setState(() {
        _quranPage = page;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل الصفحة. تحقق من اتصال الإنترنت وحاول مرة أخرى.';
      });
    }
  }

  Future<void> _openSurahs() async {
    try {
      _surahs ??= await QuranService.instance.fetchSurahs();
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surfaceDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .86,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppColors.gold),
                      const SizedBox(width: 10),
                      Text(
                        'فهرس القرآن الكريم',
                        style: GoogleFonts.amiri(
                          color: AppColors.ivory,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'اختر السورة للانتقال مباشرة إلى أول صفحة منها',
                    style: GoogleFonts.cairo(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: _surahs!.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.paperLine.withOpacity(.45),
                      height: 1,
                    ),
                    itemBuilder: (_, i) {
                      final s = _surahs![i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withOpacity(.10),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(.30),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${s.number}',
                            style: GoogleFonts.cairo(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            fontSize: 21,
                            color: AppColors.ivory,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${s.englishName}  •  ${s.numberOfAyahs} آية',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.gold,
                        ),
                        onTap: () async {
                          final selectedNumber = s.number;
                          Navigator.of(context).pop();
                          try {
                            final startPage = await QuranService.instance
                                .fetchSurahStartPage(selectedNumber);
                            if (!mounted) return;
                            setState(() => _page = startPage);
                            await _loadPage();
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذّر فتح بداية السورة.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تحميل فهرس السور.')),
        );
      }
    }
  }

  Future<void> _markPageRead() async {
    final prefs = await SharedPreferences.getInstance();

    if (_page >= 604) {
      final count = (prefs.getInt('quran_khatmah_count') ?? 0) + 1;
      await prefs.setInt('quran_khatmah_count', count);
      await prefs.setString(
        'quran_last_khatmah_at',
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt('quran_next_page', 1);
      await NotificationService.instance.scheduleQuranDaily(1);

      if (!mounted) return;
      setState(() => _completedKhatmahCount = count);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ما شاء الله! أتممت الختمة رقم $count. تقبّل الله منك 🌙',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final next = _page + 1;
    await prefs.setInt('quran_next_page', next);
    await NotificationService.instance.scheduleQuranDaily(next);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أحسنت! تم حفظ تقدمك. غدًا نكمل من الصفحة $next.')),
    );
  }

  void _changePage(int delta) {
    final next = (_page + delta).clamp(1, 604);
    if (next == _page) return;
    setState(() => _page = next);
    _loadPage();
  }

  Future<void> _showTafsir(QuranVerse verse) async {
    final cached = _tafsirCache[verse.number];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FutureBuilder<QuranTafsir>(
            future: cached != null
                ? Future.value(cached)
                : QuranService.instance.fetchTafsir(verse.number),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'تعذّر تحميل التفسير الآن. حاول مرة أخرى.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              final tafsir = snapshot.data!;
              _tafsirCache[verse.number] = tafsir;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withOpacity(.12),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(.35),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${verse.numberInSurah}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'تفسير الآية',
                                style: GoogleFonts.amiri(
                                  color: AppColors.ivory,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${verse.surahName} • الآية ${verse.numberInSurah}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(.55),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(.14),
                        ),
                      ),
                      child: Text(
                        verse.text,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          color: AppColors.ivory,
                          fontSize: 23,
                          height: 1.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold,
                          size: 19,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tafsir.source,
                          style: GoogleFonts.cairo(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tafsir.text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        color: AppColors.ivory,
                        fontSize: 15,
                        height: 1.9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verses = _quranPage?.verses ?? const <QuranVerse>[];
    final page = _quranPage;
    final isLastPage = _page == 604;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text(
          'القرآن الكريم',
          style: GoogleFonts.amiri(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openSurahs,
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'فهرس السور',
          ),
        ],
      ),
      body: Column(
        children: [
          if (page != null && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            page.surahName.isEmpty ? 'القرآن الكريم' : page.surahName,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.amiri(
                              color: AppColors.ivory,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'الجزء ${page.juz}  •  الحزب ${page.hizb}  •  الصفحة $_page من 604',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isLastPage ? Icons.verified_rounded : Icons.menu_book_rounded,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          if (isLastPage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.gold.withOpacity(.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: AppColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'نهاية الختمة — أكمل هذه الصفحة ثم سجّل إتمام الختمة.',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          color: AppColors.ivory,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 5),
            child: Row(
              children: [
                Text(
                  '${((_page / 604) * 100).round()}%',
                  style: GoogleFonts.cairo(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _completedKhatmahCount > 0
                      ? 'ختمات مكتملة: $_completedKhatmahCount'
                      : 'وردك اليومي',
                  style: GoogleFonts.cairo(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _page / 604,
            minHeight: 4,
            backgroundColor: AppColors.paperLine,
            color: AppColors.gold,
          ),
          Expanded(child: _buildPageBody(verses)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _page > 1 ? () => _changePage(-1) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('السابقة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markPageRead,
                      icon: Icon(
                        isLastPage
                            ? Icons.emoji_events_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(isLastPage ? 'أتممت الختمة' : 'قرأت الصفحة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _page < 604 ? () => _changePage(1) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('التالية'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBody(List<QuranVerse> verses) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadPage,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (verses.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات في هذه الصفحة.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: verses.length,
      itemBuilder: (_, i) {
        final verse = verses[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showTafsir(verse),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withOpacity(.10),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(.28),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${verse.numberInSurah}',
                            style: GoogleFonts.cairo(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.textMuted,
                          size: 17,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verse.text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 25,
                        height: 1.9,
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'اضغط على الآية لعرض التفسير',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.cairo(
                        color: AppColors.textMuted.withOpacity(.8),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
