import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goalPrayers = state.activePrayers;
    final newestGoal = goalPrayers.last;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الأسبوع ${state.currentWeek} من ٥', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Text('هدف هذا الأسبوع بسيط', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 34)),
                          const SizedBox(height: 12),
                          Text(
                            state.currentWeek == 1
                                ? 'المحافظة على الفجر فقط'
                                : 'أضف ${newestGoal.arabicName} إلى صلواتك',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا تُطالَب بخمس صلوات دفعة واحدة. حافظ على صلوات هذا الأسبوع سبعة أيام متتالية، وننتقل معك للصلاة التالية.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 6,
                            children: goalPrayers
                                .map((p) => Chip(
                                      label: Text(p.arabicName),
                                      backgroundColor: AppColors.gold.withOpacity(0.15),
                                      labelStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                                      side: BorderSide.none,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(7, (i) {
                  final filled = i < state.weekDaysCompleted;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.sage : AppColors.paperLine,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.weekDaysCompleted} من ٧ أيام — استمر',
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  await state.completeOnboarding();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
                child: const Text('فهمت، لنبدأ اليوم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
