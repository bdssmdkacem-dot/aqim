import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkar.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'adhkar_flow_screen.dart';
import 'identity_screen.dart';

class _Phrase {
  final String arabic;
  final int target;
  const _Phrase(this.arabic, this.target);
}

const _phrases = [
  _Phrase('سبحان الله', 33),
  _Phrase('الحمد لله', 33),
  _Phrase('الله أكبر', 34),
];

class DhikrScreen extends StatefulWidget {
  final Prayer prayer;
  const DhikrScreen({super.key, required this.prayer});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  int phraseIndex = 0;
  int count = 0;

  void _tap() {
    setState(() {
      count++;
      if (count >= _phrases[phraseIndex].target) {
        if (phraseIndex < _phrases.length - 1) {
          phraseIndex++;
          count = 0;
        }
      }
    });
  }

  bool get _allDone =>
      phraseIndex == _phrases.length - 1 && count >= _phrases[phraseIndex].target;

  @override
  Widget build(BuildContext context) {
    final phrase = _phrases[phraseIndex];
    final pct = (count / phrase.target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('اذكر الله')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              Text('هل صليت؟', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Text('اذكر الله دقيقة واحدة', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              GestureDetector(
                onTap: _allDone ? null : _tap,
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 10,
                          backgroundColor: AppColors.paperLine,
                          valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$count',
                                  style: GoogleFonts.tajawal(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                                TextSpan(
                                  text: '/${phrase.target}',
                                  style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(phrase.arabic, style: GoogleFonts.amiri(fontSize: 18, color: AppColors.inkSoft)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _allDone ? 'أحسنت، أتممت الذكر' : 'اضغط الدائرة لكل تسبيحة',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: !_allDone
                    ? null
                    : () async {
                        await context.read<AppState>().markDone(widget.prayer);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => IdentityScreen(prayer: widget.prayer)),
                          );
                        }
                      },
                child: const Text('أحسنت ✔'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: !_allDone
                    ? null
                    : () async {
                        await context.read<AppState>().markDone(widget.prayer);
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AdhkarFlowScreen(
                              title: 'أذكار ما بعد الصلاة',
                              items: afterPrayerAdhkar,
                              audioCategory: 'after',
                              nextScreenBuilder: () => IdentityScreen(prayer: widget.prayer),
                            ),
                          ),
                        );
                      },
                child: const Text('عرض جميع الأذكار الكاملة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
