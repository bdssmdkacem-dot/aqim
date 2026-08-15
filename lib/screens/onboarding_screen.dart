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

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  int _page = 0;
  bool _locationReady = false;
  bool _notificationsReady = false;
  bool _exactAlarmReady = false;
  bool _dndReady = false;
  bool _backgroundReady = false;
  bool _fullScreenRequested = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      final location = await LocationService.hasLocationPermission();
      final notifications =
          await NotificationService.instance.areNotificationsEnabled();
      final exact =
          await NotificationService.instance.refreshExactAlarmPermission();
      final dnd =
          await NotificationService.instance.refreshNotificationPolicyAccess();
      final background = await BatteryService.isFullyExempted();
      if (!mounted) return;
      setState(() {
        _locationReady = location;
        _notificationsReady = notifications;
        _exactAlarmReady = exact;
        _dndReady = dnd;
        _backgroundReady = background;
      });
    } catch (_) {}
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _requestLocation(AppState state) async {
    final granted = await LocationService.requestLocationPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فعّل الموقع واسمح لأقم بالوصول إليه لحساب أوقات الصلاة بدقة.'),
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => _locationReady = true);
    await state.loadPrayerTimes();
    await _refreshPermissions();
  }

  Future<void> _requestNotifications() async {
    final granted =
        await NotificationService.instance.requestNotificationsPermission();
    if (mounted) setState(() => _notificationsReady = granted);
  }

  Future<void> _requestExactAlarm() async {
    final granted =
        await NotificationService.instance.requestExactAlarmPermission();
    if (mounted) setState(() => _exactAlarmReady = granted);
  }

  Future<void> _requestDnd() async {
    await NotificationService.instance.requestNotificationPolicyAccess();
    await _refreshPermissions();
  }

  Future<void> _requestFullScreen() async {
    final ok =
        await NotificationService.instance.requestFullScreenIntentPermission();
    if (mounted && ok) setState(() => _fullScreenRequested = true);
  }

  Future<void> _requestBackground() async {
    await BatteryService.openSettings();
    // Android/OEM settings may take the user away from the app. The lifecycle
    // callback refreshes this value again when the user returns.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _refreshPermissions();
  }

  Future<void> _finish(AppState state) async {
    if (_finishing) return;
    setState(() => _finishing = true);

    // اطلب ما يمكن طلبه مباشرة، ثم اترك إعدادات الشركة المصنعة للمستخدم.
    if (!_notificationsReady) await _requestNotifications();
    if (!_locationReady) await _requestLocation(state);
    if (!_exactAlarmReady) await _requestExactAlarm();
    if (!_fullScreenRequested) await _requestFullScreen();

    await state.loadPrayerTimes();
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

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    'أقم',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
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
                    exactAlarmReady: _exactAlarmReady,
                    dndReady: _dndReady,
                    backgroundReady: _backgroundReady,
                    fullScreenRequested: _fullScreenRequested,
                    onLocation: () => _requestLocation(state),
                    onNotifications: _requestNotifications,
                    onExactAlarm: _requestExactAlarm,
                    onDnd: _requestDnd,
                    onFullScreen: _requestFullScreen,
                    onBackground: _requestBackground,
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(.22),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            color: AppColors.gold,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'مرحبًا بك في أقم',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لأجل صلاة في وقتها',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'فعّل الأذونات المهمة مرة واحدة ليحسب أقم مواقيت الصلاة بدقة، ويوقظك بالأذان والتذكيرات حتى والهاتف مقفل.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(.82),
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
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
  final bool exactAlarmReady;
  final bool dndReady;
  final bool backgroundReady;
  final bool fullScreenRequested;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;
  final VoidCallback onExactAlarm;
  final VoidCallback onDnd;
  final VoidCallback onFullScreen;
  final VoidCallback onBackground;
  final VoidCallback onNext;

  const _PermissionPage({
    required this.state,
    required this.locationReady,
    required this.notificationsReady,
    required this.exactAlarmReady,
    required this.dndReady,
    required this.backgroundReady,
    required this.fullScreenRequested,
    required this.onLocation,
    required this.onNotifications,
    required this.onExactAlarm,
    required this.onDnd,
    required this.onFullScreen,
    required this.onBackground,
    required this.onNext,
  });

  Widget _permissionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool ready,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
      decoration: BoxDecoration(
        color: AppColors.paper.withOpacity(.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ready
              ? AppColors.sage.withOpacity(.55)
              : AppColors.gold.withOpacity(.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ready
                  ? AppColors.sage.withOpacity(.13)
                  : AppColors.gold.withOpacity(.10),
            ),
            child: Icon(
              ready ? Icons.check_rounded : icon,
              color: ready ? AppColors.sage : AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.55),
                    height: 1.25,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          TextButton(
            onPressed: ready ? null : onPressed,
            child: Text(
              ready ? 'مفعّل' : action,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ready ? AppColors.sage : AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'فعّل أقم بالكامل',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(.22)),
            ),
            child: Text(
              'لأفضل تجربة: اسمح بكل الأذونات التالية. الموقع يحدد مدينتك، والإشعارات والأذان يصلان في وقتهما، والتشغيل في الخلفية يمنع تأخر التنبيهات. لا نطلب موقعًا مستمرًا في الخلفية.',
              style: TextStyle(
                color: Colors.white.withOpacity(.75),
                height: 1.4,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _permissionTile(
                  context: context,
                  icon: Icons.location_on_rounded,
                  title: 'الموقع',
                  description: state.cityName == null
                      ? 'لتحديد المدينة وحساب مواقيت الصلاة المحلية بدقة.'
                      : 'تم تحديد: ${state.cityName}',
                  ready: locationReady,
                  action: 'السماح',
                  onPressed: onLocation,
                ),
                _permissionTile(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  title: 'الإشعارات',
                  description: 'الأذان وتذكير قبل الصلاة وتذكير الصلاة الفائتة.',
                  ready: notificationsReady,
                  action: 'السماح',
                  onPressed: onNotifications,
                ),
                _permissionTile(
                  context: context,
                  icon: Icons.alarm_rounded,
                  title: 'المنبّهات الدقيقة',
                  description: 'لإطلاق الأذان في الموعد المحدد حتى أثناء توفير الطاقة.',
                  ready: exactAlarmReady,
                  action: 'تفعيل',
                  onPressed: onExactAlarm,
                ),
                _permissionTile(
                  context: context,
                  icon: Icons.fullscreen_rounded,
                  title: 'التنبيه على الشاشة المقفلة',
                  description: 'إظهار تنبيه الصلاة بوضوح عندما يكون الهاتف مقفلًا.',
                  ready: fullScreenRequested,
                  action: 'السماح',
                  onPressed: onFullScreen,
                ),
                _permissionTile(
                  context: context,
                  icon: Icons.do_not_disturb_off_rounded,
                  title: 'عدم الإزعاج للأذان',
                  description: 'يسمح لقناة الأذان بتجاوز وضع عدم الإزعاج إذا اخترت ذلك.',
                  ready: dndReady,
                  action: 'السماح',
                  onPressed: onDnd,
                ),
                _permissionTile(
                  context: context,
                  icon: Icons.battery_saver_rounded,
                  title: 'التشغيل في الخلفية',
                  description: 'عطّل تقييد البطارية لأقم حتى لا تتأخر التنبيهات على بعض الأجهزة.',
                  ready: backgroundReady,
                  action: 'إعداد',
                  onPressed: onBackground,
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'يمكن تغيير هذه الأذونات لاحقًا من إعدادات الهاتف أو إعدادات أقم.',
            style: TextStyle(color: Colors.white.withOpacity(.42), fontSize: 10.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
              icon: finishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_back_rounded),
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
