import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkar.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'prayer_guide_screen.dart';

class AdhkarFlowScreen extends StatefulWidget {
  final String title;
  final List<AdhkarItem> items;
  final String audioCategory;
  final Widget Function()? nextScreenBuilder;

  const AdhkarFlowScreen({
    super.key,
    required this.title,
    required this.items,
    required this.audioCategory,
    this.nextScreenBuilder,
  });

  @override
  State<AdhkarFlowScreen> createState() => _AdhkarFlowScreenState();
}

class _AdhkarFlowScreenState extends State<AdhkarFlowScreen> {
  int index = 0;
  int count = 0;

  AdhkarItem get current => widget.items[index];
  bool get isLast => index == widget.items.length - 1;
  double get itemProgress => current.repeat <= 0 ? 0 : (count / current.repeat).clamp(0.0, 1.0);
  double get totalProgress => ((index + itemProgress) / widget.items.length).clamp(0.0, 1.0);

  /// Converts the Quran surahs already included in the adhkar lists from the
  /// old '*' separators to proper Quran-style ayah numbers. The Quran source
  /// itself is never modified; this is display-only metadata.
  String _quranAwareText(AdhkarItem item) {
    final id = item.id;
    final isIkhlas = id == 'al_ikhlas' || id == 'morning_ikhlas' || id.contains('evening_ikhlas');
    final isFalaq = id == 'al_falaq' || id == 'morning_falaq' || id.contains('evening_falaq');
    final isNas = id == 'an_nas' || id == 'morning_nas' || id.contains('evening_nas');

    if (id == 'ayat_kursi' || id == 'morning_ayat_kursi' || id.contains('evening_ayat_kursi')) {
      return '${item.text.trim()} ﴿٢٥٥﴾';
    }

    if (!isIkhlas && !isFalaq && !isNas) return item.text;

    final parts = item.text.split('*').map((part) => part.trim()).where((part) => part.isNotEmpty).toList(growable: false);
    final count = isIkhlas ? 4 : (isFalaq ? 5 : 6);
    if (parts.length != count) return item.text;

    return List<String>.generate(
      parts.length,
      (i) => '${parts[i]} ﴿${_arabicNumber(i + 1)}﴾',
    ).join(' ');
  }

  String _arabicNumber(int value) {
    const digits = <String>['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return value.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  void _next() {
    if (isLast) {
      if (widget.nextScreenBuilder != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreenBuilder!()),
        );
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() {
      index++;
      count = 0;
    });
  }

  void _tap() {
    if (count >= current.repeat) return;
    setState(() => count++);
    if (count >= current.repeat) {
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted) _next();
      });
    }
  }

  void _openPrayerGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrayerGuideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = current;
    final displayText = _quranAwareText(item);

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: Text(widget.title, style: GoogleFonts.amiri(fontWeight: FontWeight.w800)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalProgress,
                backgroundColor: AppColors.paperLine,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                minHeight: 4,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withOpacity(.22)),
                    ),
                    child: Text('${index + 1} / ${widget.items.length}', style: GoogleFonts.tajawal(color: AppColors.gold, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: item.repeat > 1 && count < item.repeat ? _tap : _next,
                              splashColor: AppColors.gold.withOpacity(.10),
                              highlightColor: AppColors.gold.withOpacity(.05),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [AppColors.surfaceDark, AppColors.ink.withOpacity(.96)],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: AppColors.gold.withOpacity(.32)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold.withOpacity(.09),
                                        border: Border.all(color: AppColors.gold.withOpacity(.5)),
                                      ),
                                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 28),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      displayText,
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,
                                      style: GoogleFonts.amiri(fontSize: 22, height: 2.0, color: AppColors.ivory, fontWeight: FontWeight.w600),
                                    ),
                                    if (item.note != null) ...[
                                      const SizedBox(height: 18),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.paper.withOpacity(.035),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: AppColors.paperLine),
                                        ),
                                        child: Text(item.note!, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11, height: 1.6, color: AppColors.inkSoft)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Material(
                              color: AppColors.ink.withOpacity(.62),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'استماع',
                                icon: const Icon(Icons.volume_up_rounded, color: AppColors.gold, size: 22),
                                onPressed: () => AudioService.instance.playAsset(context, item.audioAsset(widget.audioCategory)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (item.repeat > 1) ...[
                        Text('$count / ${item.repeat}', style: GoogleFonts.tajawal(fontSize: 30, color: AppColors.gold, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text('اضغط على البطاقة لكل تكرار', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: itemProgress,
                            minHeight: 7,
                            backgroundColor: AppColors.paperLine,
                            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ] else
                        Text('اضغط على البطاقة للمتابعة', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openPrayerGuide,
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('كيف أقيم صلاتي؟ من الوضوء إلى التسليم'),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'إنهاء' : 'تخطي'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: item.repeat > 1 && count < item.repeat ? _tap : _next,
                      child: Text(item.repeat > 1 && count < item.repeat ? 'تسبيح' : (isLast ? 'إنهاء' : 'التالي')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
