import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class IdentityScreen extends StatelessWidget {
  final Prayer prayer;
  const IdentityScreen({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final message = state.streak >= 7
        ? 'أنت شخص يحافظ على ${prayer.arabicName}'
        : 'خطوة أخرى نحو المحافظة على ${prayer.arabicName}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🕌', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(fontSize: 19, color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${state.streak} يومًا متتاليًا. استمر بنفس الوتيرة.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                ),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
