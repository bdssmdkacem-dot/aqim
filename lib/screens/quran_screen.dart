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
  bool _saving = false;
  String? _error;
  int _completedKhatmahCount = 0;
  int? _savedPage;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage ?? 1;
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('quran_resume_page') ??
        prefs.getInt('quran_next_page') ??
        1;
    final startPage = widget.initialPage ?? saved.clamp(1, 604);

    if (!mounted) return;
    setState(() {
      _page = startPage;
      _savedPage = saved.clamp(1, 604);
      _completedKhatmahCount = prefs.getInt('quran_khatmah_count') ?? 0;
    });
    await _loadPage();
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

  Future<void> _saveProgress() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_page >= 604) {
        final count = (prefs.getInt('quran_khatmah_count') ?? 0) + 1;
        await prefs.setInt('quran_khatmah_count', count);
        await prefs.setString(
          'quran_last_khatmah_at',
          DateTime.now().toIso8601String(),
        );
        await prefs.setInt('quran_resume_page', 1);
        await prefs.setInt('quran_next_page', 1);
        await NotificationService.instance.scheduleQuranDaily(1);

        if (!mounted) return;
        setState(() {
          _completedKhatmahCount = count;
          _savedPage = 1;
          _saving = false;
        });
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

      // Save the exact page where the reader stopped. The next session
      // resumes from this page instead of silently jumping ahead.
      await prefs.setInt('quran_resume_page', _page);
      await prefs.setInt('quran_next_page', _page);
      await NotificationService.instance.scheduleQuranDaily(_page);

      if (!mounted) return;
      setState(() {
        _savedPage = _page;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ تقدمك في الصفحة $_page. سنكمل من هنا لاحقًا بإذن الله.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ التقدم. حاول مرة أخرى.')),
      );
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
                      const Icon(Icons.menu_book_rounded, color: AppColors.gold),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withOpacity(.10),
                            border: Border.all(color: AppColors.gold.withOpacity(.30)),
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
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.gold),
                        onTap: () async {
                          final selectedNumber = s.number;
                          Navigator.of(context).pop();
                          try {
                            final startPage = await QuranService.instance.fetchSurahStartPage(selectedNumber);
                            if (!mounted) return;
                            setState(() => _page = startPage);
                            await _loadPage();
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تعذّر فتح بداية السورة.')),
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

  Future<void> _openSearch() async {
    final controller = TextEditingController();
    List<QuranSearchResult> results = const [];
    bool searching = false;
    String? searchError;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> runSearch() async {
            final query = controller.text.trim();
            if (query.isEmpty) return;
            setSheetState(() {
              searching = true;
              searchError = null;
              results = const [];
            });
            try {
              final found = await QuranService.instance.search(query);
              setSheetState(() {
                results = found;
                searching = false;
              });
            } catch (_) {
              setSheetState(() {
                searching = false;
                searchError = 'تعذّر البحث الآن. تحقق من الاتصال وحاول مرة أخرى.';
              });
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .78,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(
                          'البحث في القرآن الكريم',
                          style: GoogleFonts.amiri(
                            color: AppColors.ivory,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => runSearch(),
                      style: GoogleFonts.cairo(color: AppColors.ivory),
                      decoration: InputDecoration(
                        hintText: 'اكتب كلمة أو عبارة للبحث...',
                        hintStyle: GoogleFonts.cairo(color: AppColors.textMuted),
                        prefixIcon: IconButton(
                          onPressed: runSearch,
                          icon: const Icon(Icons.search_rounded),
                          color: AppColors.gold,
                        ),
                        filled: true,
                        fillColor: AppColors.ink.withOpacity(.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gold.withOpacity(.18)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gold.withOpacity(.18)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (searching)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    else if (searchError != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          searchError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(color: AppColors.textMuted),
                        ),
                      )
                    else if (controller.text.trim().isNotEmpty && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'لا توجد آيات مطابقة.',
                          style: GoogleFonts.cairo(color: AppColors.textMuted),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => Divider(
                            color: AppColors.paperLine.withOpacity(.35),
                            height: 1,
                          ),
                          itemBuilder: (_, i) {
                            final result = results[i];
                            final verse = result.verse;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                              title: Text(
                                verse.text,
                                textAlign: TextAlign.right,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(
                                  color: AppColors.ivory,
                                  fontSize: 19,
                                  height: 1.7,
                                ),
                              ),
                              subtitle: Text(
                                '${verse.surahName} • الآية ${verse.numberInSurah} • الصفحة ${verse.page}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.gold),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                if (!mounted) return;
                                setState(() => _page = verse.page);
                                await _loadPage();
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
        },
      ),
    );
    controller.dispose();
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
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: FutureBuilder<QuranTafsir>(
            future: cached != null ? Future.value(cached) : QuranService.instance.fetchTafsir(verse.number),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
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
                            border: Border.all(color: AppColors.gold.withOpacity(.35)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${verse.numberInSurah}',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
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
                                style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11),
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
                        border: Border.all(color: AppColors.gold.withOpacity(.14)),
                      ),
                      child: Text(
                        verse.text,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(color: AppColors.ivory, fontSize: 23, height: 1.9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 19),
                        const SizedBox(width: 7),
                        Text(
                          tafsir.source,
                          style: GoogleFonts.cairo(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tafsir.text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(color: AppColors.ivory, fontSize: 15, height: 1.9),
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

  Future<void> _showSajdaGuide(QuranVerse verse) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(.12),
                      border: Border.all(color: AppColors.gold.withOpacity(.40)),
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'سجدة التلاوة',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            color: AppColors.ivory,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${verse.surahName} • الآية ${verse.numberInSurah}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11),
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
                  border: Border.all(color: AppColors.gold.withOpacity(.16)),
                ),
                child: Text(
                  verse.text,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(color: AppColors.ivory, fontSize: 22, height: 1.9),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'كيف تؤدي سجدة التلاوة؟',
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                'أكمل قراءة الآية التي عليها علامة السجدة.',
                'اسجد سجدة واحدة بنية سجود التلاوة، مع استقبال القبلة إن تيسّر.',
                'قل في السجود: «سبحان ربي الأعلى»، ثم ارفع رأسك.',
              ].asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: GoogleFonts.cairo(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: AppColors.ivory, fontSize: 14, height: 1.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ملاحظة: قد تختلف بعض التفاصيل الفقهية باختلاف المذهب، فاستعن بما تتبعه من أحكام.',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePage(int delta) {
    final next = (_page + delta).clamp(1, 604);
    if (next == _page) return;
    setState(() => _page = next);
    _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final verses = _quranPage?.verses ?? const <QuranVerse>[];
    final page = _quranPage;
    final isLastPage = _page == 604;
    final progress = (_page / 604).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text('القرآن الكريم', style: GoogleFonts.amiri(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(Icons.search_rounded),
            tooltip: 'البحث في القرآن',
          ),
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
                            style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(isLastPage ? Icons.verified_rounded : Icons.menu_book_rounded, color: AppColors.gold),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          if (_savedPage != null && _savedPage == _page && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: AppColors.gold, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تقدمك محفوظ هنا — ستعود إلى الصفحة $_page عند فتح القرآن مرة أخرى.',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
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
                        'نهاية الختمة — احفظ الصفحة لإتمام الختمة وبدء ختمة جديدة.',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: AppColors.ivory, fontSize: 12, fontWeight: FontWeight.w700),
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
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.cairo(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _completedKhatmahCount > 0 ? 'ختمات مكتملة: $_completedKhatmahCount' : 'وردك اليومي',
                  style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProgress,
                      icon: Icon(isLastPage ? Icons.emoji_events_rounded : Icons.bookmark_add_rounded),
                      label: Text(_saving ? 'جارٍ الحفظ...' : (isLastPage ? 'أتممت الختمة' : 'حفظ التقدم')),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
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
              ElevatedButton(onPressed: _loadPage, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    if (verses.isEmpty) {
      return const Center(
        child: Text('لا توجد آيات في هذه الصفحة.', style: TextStyle(color: AppColors.textMuted)),
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
                  border: Border.all(color: AppColors.gold.withOpacity(.14)),
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
                            border: Border.all(color: AppColors.gold.withOpacity(.28)),
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
                        if (verse.isSajda)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: IconButton(
                              onPressed: () => _showSajdaGuide(verse),
                              tooltip: 'موضع سجدة التلاوة',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.self_improvement_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                          ),
                        const Icon(Icons.menu_book_rounded, color: AppColors.textMuted, size: 17),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verse.text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 25, height: 1.9, color: AppColors.ivory),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'اضغط على الآية لعرض التفسير',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.cairo(color: AppColors.textMuted.withOpacity(.8), fontSize: 9),
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
