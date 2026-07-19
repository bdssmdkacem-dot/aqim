import 'package:flutter/material.dart';
import '../models/prayer.dart';
import 'package:provider/provider.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

const _beforeOptions = [5, 10, 15, 20, 30];
const _afterOptions = [10, 15, 20, 30, 45];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  Future<void> _finish(AppState state) async {
    await state.completeOnboarding();
    await state.markBatteryPromptShown();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : AppColors.paperLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _GoalPage(state: state, onNext: _next),
                  _PreferencesPage(state: state, onFinish: () => _finish(state)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final AppState state;
  final VoidCallback onNext;
  const _GoalPage({required this.state, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final goalPrayers = state.activePrayers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرحبًا بك في أقم', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text('هدفك بسيط وواضح', style: Theme.of(context).textTheme.headlineMedium),
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
                        'المحافظة على صلواتك الخمس',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'حافظ عليها سبعة أيام متتالية لتثبيت العادة — التطبيق يذكّرك قبل كل صلاة، ويرافقك بالأذكار بعدها.',
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
            onPressed: onNext,
            child: const Text('التالي: كيف تريد أن يعمل التطبيق؟'),
          ),
        ],
      ),
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  final AppState state;
  final VoidCallback onFinish;
  const _PreferencesPage({required this.state, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الخطوة الأخيرة', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text('كيف تريد أن يعمل التطبيق؟', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'اختر الآن، وتقدر تبدّلها لاحقًا من شاشة الإعدادات فـ أي وقت.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('منبّه الاستعداد قبل الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _beforeOptions.map((m) {
                            final selected = state.beforeMinutes == m;
                            return ChoiceChip(
                              label: Text('$m دقيقة'),
                              selected: selected,
                              onSelected: (_) => state.updateReminderTiming(before: m),
                              selectedColor: AppColors.gold.withOpacity(0.25),
                              labelStyle: TextStyle(
                                color: selected ? AppColors.ink : AppColors.inkSoft,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تذكير "هل صليت؟" بعد الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _afterOptions.map((m) {
                            final selected = state.afterMinutes == m;
                            return ChoiceChip(
                              label: Text('$m دقيقة'),
                              selected: selected,
                              onSelected: (_) => state.updateReminderTiming(after: m),
                              selectedColor: AppColors.gold.withOpacity(0.25),
                              labelStyle: TextStyle(
                                color: selected ? AppColors.ink : AppColors.inkSoft,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    title: const Text('صوت الأذان عند وقت كل صلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('إشعار بصوت الأذان لحظة دخول الوقت', style: TextStyle(fontSize: 12)),
                    value: state.adhanEnabled,
                    onChanged: state.setAdhanEnabled,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.battery_charging_full, color: AppColors.gold),
                    title: const Text('تحسين إعدادات البطارية'),
                    subtitle: const Text(
                      'مهم على هواتف Xiaomi وHuawei وOppo كي تصل التذكيرات فوقتها',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: BatteryService.openSettings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text('فهمت، لنبدأ اليوم'),
          ),
        ],
      ),
    );
  }
}
