import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'reason_screen.dart';

/// شاشة مباشرة من إشعار الصلاة الفائتة: يجيب المستخدم فورًا هل صلاها أم لا.
class MissedPrayerResponseScreen extends StatelessWidget {
  final Prayer prayer;

  const MissedPrayerResponseScreen({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text('صلاة ${prayer.arabicName}', style: GoogleFonts.amiri(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.ember.withOpacity(.75), width: 1.2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.ember.withOpacity(.13),
                        border: Border.all(color: AppColors.ember.withOpacity(.75)),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.ember, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text('فاتتك صلاة ${prayer.arabicName}', textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: 25, fontWeight: FontWeight.w700, color: AppColors.ivory)),
                    const SizedBox(height: 8),
                    Text('هل أديت هذه الصلاة بالفعل؟', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text('نعم، صليتها', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                onPressed: () async {
                  await state.markQada(prayer);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded),
                label: Text('لا، لم أصلها بعد', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ember,
                  side: BorderSide(color: AppColors.ember.withOpacity(.75)),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReasonScreen(prayer: prayer)),
                  );
                },
              ),
              const Spacer(),
              Text(
                'اختيارك يُحدّث سجل الصلاة ويلغي تذكيرها الفائت.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
