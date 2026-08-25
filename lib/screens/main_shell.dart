import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../ads/app_interstitial_ad.dart';
import '../services/religious_events_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_bell.dart';
import '../widgets/religious_event_home_card.dart';
import 'adhkar_home_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'pre_prayer_screen.dart';
import 'quran_screen.dart';

/// القشرة الرئيسية: القرآن أصبح تبويبًا أساسيًا في الشريط السفلي.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    QuranScreen(),
    AdhkarHomeScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final next = state.nextPrayer;
    final todayEvent = ReligiousEventsService.eventOn(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          if (_index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(children: [
                const NotificationBell(),
                if (todayEvent != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: ReligiousEventHomeCard(event: todayEvent)),
                ] else
                  const Spacer(),
              ]),
            ),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
          if (_index == 0) const AppBannerAd(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == 2 && i != _index) {
            AppInterstitialAd.showIfEligible();
          }
          setState(() => _index = i);
        },
        onCenterTap: next == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)),
                ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;

  const _BottomBar({required this.currentIndex, required this.onTap, required this.onCenterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.paperLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'الرئيسية', selected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'القرآن', selected: currentIndex == 1, onTap: () => onTap(1)),
              _CenterButton(onTap: onCenterTap),
              _NavItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'أذكار', selected: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.more_horiz_rounded, selectedIcon: Icons.more_horiz_rounded, label: 'المزيد', selected: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.timer_outlined, color: AppColors.ink, size: 26),
              ),
            ),
            const SizedBox(height: 2),
            const Text('استعد للصلاة', style: TextStyle(fontSize: 9.5, color: AppColors.gold, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
