import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../screens/main_shell.dart';
import '../screens/pre_prayer_screen.dart';
import '../state/app_state.dart';
import '../widgets/aqim_bottom_nav.dart';
import 'nav_key.dart';

final ValueNotifier<int> aqimBottomNavIndex = ValueNotifier<int>(0);
final ValueNotifier<bool> aqimBottomNavVisible = ValueNotifier<bool>(true);

void setAqimBottomNavIndex(int index) {
  if (index >= 0 && index <= 3) aqimBottomNavIndex.value = index;
}

void handleAqimBottomNavTap(BuildContext context, int index, {Prayer? nextPrayer}) {
  if (index == 4) {
    if (nextPrayer != null) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: nextPrayer)),
      );
    }
    return;
  }

  setAqimBottomNavIndex(index);
  rootNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
    (route) => false,
  );
}

class AqimGlobalBottomNav extends StatelessWidget {
  const AqimGlobalBottomNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: aqimBottomNavVisible,
      builder: (_, visible, __) {
        if (!visible) return child;
        return ValueListenableBuilder<int>(
          valueListenable: aqimBottomNavIndex,
          builder: (_, index, __) {
            final nextPrayer = context.select<AppState, Prayer?>(
              (state) => state.nextPrayer,
            );
            return Column(
              children: [
                Expanded(child: child),
                AqimBottomNav(
                  currentIndex: index,
                  onTap: (value) => handleAqimBottomNavTap(
                    context,
                    value,
                    nextPrayer: nextPrayer,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
