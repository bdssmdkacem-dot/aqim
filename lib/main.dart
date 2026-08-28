import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import 'ads/app_interstitial_ad.dart';
import 'navigation/bottom_nav_controller.dart';
import 'navigation/nav_key.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'state/app_state_actions.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  AppInterstitialAd.preload();

  runApp(const AqimApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.init();
  });
}

class AqimApp extends StatelessWidget {
  const AqimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'أقم',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final state = context.watch<AppState>();
          final content = child ?? const SizedBox.shrink();
          return Directionality(
            textDirection: TextDirection.rtl,
            child: state.ready && state.onboardingComplete
                ? AqimGlobalBottomNav(child: content)
                : content,
          );
        },
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                    border: Border.all(color: AppColors.gold.withOpacity(.65), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withOpacity(.12), blurRadius: 28, spreadRadius: 2),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 42),
                ),
                const SizedBox(height: 18),
                Text(
                  'أقم',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لأجل صلاة في وقتها',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.goldSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return state.onboardingComplete
        ? const MainShell()
        : const OnboardingScreen();
  }
}
