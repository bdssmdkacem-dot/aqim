import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// بطاقة "الصلوات غير المؤداة": تُحاسب المستخدم على صلوات اليوم التي
/// فات وقتها دون أداء، مرتّبة حسب أولوية القضاء، مع زر سريع لتسجيل كل
/// صلاة كمقضيّة، وعدّاد/شريط تقدّم تحفيزي. إن لم تكن هناك صلاة فائتة
/// تُعرض بطاقة إيجابية بدلًا من ذلك.
class MissedPrayersCard extends StatelessWidget {
  const MissedPrayersCard({super.key});

  String _countLabel(int n) {
    if (n == 1) return 'بقيت عليك صلاة واحدة';
    if (n == 2) return 'بقيت عليك صلاتان';
    if (n >= 3 && n <= 10) return 'بقيت عليك $n صلوات';
    return 'بقيت عليك $n صلاة';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final missed = state.missedTodayPrayers;

    if (missed.isEmpty) {
      return _EmptyMissedCard(allDone: state.allTodayDone);
    }

    final total = state.activePrayers.length;
    final done = state.doneTodayCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.ember.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.ember, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الصلوات غير المؤداة',
                  style: GoogleFonts.amiri(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ember.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔴 ${missed.length}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ember,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'يُفضَّل قضاؤها بالترتيب — ابدأ بأول صلاة الآن',
            style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          ...List.generate(missed.length, (i) {
            final prayer = missed[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == missed.length - 1 ? 0 : 8),
              child: _MissedRow(order: i + 1, prayer: prayer),
            );
          }),
          const SizedBox(height: 14),
          _ProgressBar(progress: progress, done: done, total: total),
          const SizedBox(height: 4),
          Text(
            _countLabel(missed.length),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ember,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedRow extends StatelessWidget {
  final int order;
  final Prayer prayer;
  const _MissedRow({required this.order, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ember.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ember.withOpacity(0.7)),
            ),
            child: Text(
              '$order',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ember),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.close_rounded, size: 16, color: AppColors.ember),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              prayer.arabicName,
              style: GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.read<AppState>().markQada(prayer),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.sage.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sage.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: AppColors.sage),
                  const SizedBox(width: 4),
                  Text(
                    'قمت بقضائها',
                    style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.sage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final int done;
  final int total;
  const _ProgressBar({required this.progress, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'قضاء اليوم',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
            ),
            const Spacer(),
            Text(
              '$done / $total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldSoft),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      ],
    );
  }
}

/// تُعرض عندما لا توجد صلاة فائتة اليوم: رسالة إيجابية مختلفة إن كانت
/// كل الصلوات قد أُدِّيت فعلًا (يوم مكتمل) أو أن الوقت لم يحن بعد
/// لتفويت أي صلاة.
class _EmptyMissedCard extends StatelessWidget {
  final bool allDone;
  const _EmptyMissedCard({required this.allDone});

  @override
  Widget build(BuildContext context) {
    final emoji = allDone ? '🌿' : '✅';
    final title = allDone ? 'جميع الصلوات مؤداة' : 'بارك الله فيك';
    final subtitle = allDone ? 'تقبّل الله منك' : 'ليس عليك أي صلاة فائتة اليوم';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.sage.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.amiri(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}
