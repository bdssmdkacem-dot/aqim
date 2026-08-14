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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage ?? 1;
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() { _loading = true; _error = null; });
    try {
      final page = await QuranService.instance.fetchPage(_page);
      if (!mounted) return;
      setState(() { _quranPage = page; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذّر تحميل الصفحة. تحقق من اتصال الإنترنت وحاول مرة أخرى.'; });
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (_) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .78,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              itemCount: _surahs!.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.paperLine.withOpacity(.5)),
              itemBuilder: (_, i) {
                final s = _surahs![i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.gold.withOpacity(.12), child: Text('${s.number}', style: const TextStyle(color: AppColors.gold))),
                  title: Text(s.name, style: GoogleFonts.amiri(fontSize: 20, color: AppColors.ivory, fontWeight: FontWeight.w700)),
                  subtitle: Text('${s.englishName} • ${s.numberOfAyahs} آية', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  onTap: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر تحميل فهرس السور.')));
    }
  }

  Future<void> _markPageRead() async {
    final prefs = await SharedPreferences.getInstance();
    final next = _page >= 604 ? 1 : _page + 1;
    await prefs.setInt('quran_next_page', next);
    await NotificationService.instance.scheduleQuranDaily(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(TextSnackBar(message: _page >= 604 ? 'ما شاء الله! أتممت ختمة القرآن، وبدأت ختمة جديدة 🌙' : 'أحسنت! تم حفظ تقدمك. غدًا نكمل من الصفحة $next.'));
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
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text('القرآن الكريم', style: GoogleFonts.amiri(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _openSurahs, icon: const Icon(Icons.list_alt_rounded), tooltip: 'فهرس السور'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(children: [
              Text('الصفحة $_page من 604', style: GoogleFonts.cairo(color: AppColors.gold, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('وردك اليومي', style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11)),
            ]),
          ),
          LinearProgressIndicator(value: _page / 604, minHeight: 4, backgroundColor: AppColors.paperLine, color: AppColors.gold),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)), const SizedBox(height: 14), ElevatedButton(onPressed: _loadPage, child: const Text('إعادة المحاولة'))]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                        itemCount: verses.length,
                        itemBuilder: (_, i) {
                          final verse = verses[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.gold.withOpacity(.16))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Text(verse.text, textAlign: TextAlign.right, style: GoogleFonts.amiri(fontSize: 25, height: 1.9, color: AppColors.ivory)),
                              const SizedBox(height: 8),
                              Text('﴿${verse.number}﴾', textAlign: TextAlign.left, style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 15)),
                            ]),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _page > 1 ? () => _changePage(-1) : null, icon: const Icon(Icons.chevron_right_rounded), label: const Text('السابقة'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: _markPageRead, icon: const Icon(Icons.check_rounded), label: const Text('قرأت هذه الصفحة'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: _page < 604 ? () => _changePage(1) : null, icon: const Icon(Icons.chevron_left_rounded), label: const Text('التالية'))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class TextSnackBar extends SnackBar {
  TextSnackBar({required String message}) : super(content: Text(message));
}
