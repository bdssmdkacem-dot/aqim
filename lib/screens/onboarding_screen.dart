import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/battery_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

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
  bool _locationReady = false;
  bool _notificationsReady = false;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _requestLocation(AppState state) async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _locationReady = position != null);
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فعّل الموقع واسمح لأقم بالوصول إليه لحساب أوقات الصلاة بدقة.')),
      );
      return;
    }
    await state.loadPrayerTimes();
  }

  Future<void> _requestNotifications() async {
    final granted = await NotificationService.instance.requestNotificationsPermission();
    if (mounted) setState(() => _notificationsReady = granted);
  }

  Future<void> _finish(AppState state) async {
    if (_finishing) return;
    setState(() => _finishing = true);

    if (!_notificationsReady) {
      await _requestNotifications();
    }
    if (!_locationReady) {
      await _requestLocation(state);
    }

    await state.completeOnboarding();
    await state.markBatteryPromptShown();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text('أقم', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Row(
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? AppColors.gold : AppColors.paperLine,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(onNext: _next),
                  _PermissionPage(
                    state: state,
                    locationReady: _locationReady,
                    notificationsReady: _notificationsReady,
                    onLocation: () => _requestLocation(state),
                    onNotifications: _requestNotifications,
                    onNext: _next,
                  ),
                  _PreferencesPage(
                    state: state,
                    finishing: _finishing,
                    onFinish: () => _finish(state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/arch_hero.jpg', fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.18),
                          AppColors.ink.withOpacity(.62),
                          AppColors.ink.withOpacity(.96),
                        ],
                        stops: const [0, .55, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ink.withOpacity(.72),
                            border: Border.all(color: AppColors.gold.withOpacity(.8)),
                            boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(.22), blurRadius: 24)],
                          ),
                          child: const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 38),
                        ),
                        const SizedBox(height: 18),
                        Text('مرحبًا بك في أقم', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('لأجل صلاة في وقتها', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text('نرافقك قبل الصلاة، عند وقتها، وبعدها — بهدوء ووضوح.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(.82)), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('ابدأ الإعداد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final AppState state;
  final bool locationReady;
  final bool notificationsReady;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;
  final VoidCallback onNext;

  const _PermissionPage({
    required this.state,
    required this.locationReady,
    required this.notificationsReady,
    required this.onLocation,
    required this.onNotifications,
    required this.onNext,
  });

  Widget _permissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool ready,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper.withOpacity(.035),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ready ? AppColors.sage.withOpacity(.65) : AppColors.gold.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ready ? AppColors.sage.withOpacity(.16) : AppColors.gold.withOpacity(.12),
              border: Border.all(color: ready ? AppColors.sage : AppColors.gold),
            ),
            child: Icon(ready ? Icons.check_rounded : icon, color: ready ? AppColors.sage : AppColors.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 5),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(.66), height: 1.45, fontSize: 12)),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: ready ? null : onPressed,
                  child: Text(ready ? 'تم الإعداد' : action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('إعداد أقم', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('خطوتان فقط لنحسب الصلاة ونضمن وصول التذكيرات.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(.65))),
          const SizedBox(height: 18),
          _permissionCard(
            context: context,
            icon: Icons.location_on_rounded,
            title: 'الموقع',
            description: state.cityName == null ? 'نستخدم موقعك لتحديد المدينة وحساب أوقات الصلاة المحلية بدقة.' : 'تم تحديد: ${state.cityName}',
            ready: locationReady,
            action: 'السماح بالموقع',
            onPressed: onLocation,
          ),
          const SizedBox(height: 12),
          _permissionCard(
            context: context,
            icon: Icons.notifications_active_rounded,
            title: 'الإشعارات',
            description: 'ليصلك تنبيه الاستعداد، الأذان، وتنبيه «هل صليت؟» للصلاة الفائتة.',
            ready: notificationsReady,
            action: 'السماح بالإشعارات',
            onPressed: onNotifications,
          ),
          const Spacer(),
          Text('يمكنك تغيير هذه الإعدادات لاحقًا من الإعدادات.', style: TextStyle(color: Colors.white.withOpacity(.48), fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('التالي: تخصيص التذكيرات'),
          ),
        ],
      ),
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  final AppState state;
  final bool finishing;
  final VoidCallback onFinish;
  const _PreferencesPage({required this.state, required this.finishing, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تخصيص أقم', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('اختر ما يناسبك الآن، ويمكن تغييره لاحقًا.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(.65))),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                _ChoiceCard(
                  title: 'منبّه الاستعداد قبل الصلاة',
                  icon: Icons.alarm_rounded,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _beforeOptions.map((m) {
                      final selected = state.beforeMinutes == m;
                      return ChoiceChip(
                        label: Text('$m د'),
                        selected: selected,
                        onSelected: (_) => state.updateReminderTiming(before: m),
                        selectedColor: AppColors.gold,
                        labelStyle: TextStyle(color: selected ? AppColors.ink : Colors.white.withOpacity(.72), fontWeight: FontWeight.w800),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                _ChoiceCard(
                  title: 'تذكير «هل صليت؟» بعد الصلاة',
                  icon: Icons.task_alt_rounded,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _afterOptions.map((m) {
                      final selected = state.afterMinutes == m;
                      return ChoiceChip(
                        label: Text('$m د'),
                        selected: selected,
                        onSelected: (_) => state.updateReminderTiming(after: m),
                        selectedColor: AppColors.gold,
                        labelStyle: TextStyle(color: selected ? AppColors.ink : Colors.white.withOpacity(.72), fontWeight: FontWeight.w800),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.paper.withOpacity(.035),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.gold.withOpacity(.24)),
                  ),
                  child: SwitchListTile(
                    activeColor: AppColors.gold,
                    title: const Text('صوت الأذان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    subtitle: Text('عند دخول وقت كل صلاة', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12)),
                    value: state.adhanEnabled,
                    onChanged: state.setAdhanEnabled,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.paper.withOpacity(.035),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.gold.withOpacity(.24)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.battery_saver_rounded, color: AppColors.gold),
                    title: const Text('تحسين البطارية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    subtitle: Text('مهم لوصول التذكيرات في الخلفية، خصوصًا على بعض الأجهزة.', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12)),
                    onTap: BatteryService.openSettings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: finishing ? null : onFinish,
              icon: finishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_back_rounded),
              label: Text(finishing ? 'جاري التجهيز...' : 'ابدأ مع أقم'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ChoiceCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper.withOpacity(.035),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withOpacity(.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
