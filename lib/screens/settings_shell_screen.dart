import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/aqim_bottom_nav.dart';
import 'main_shell.dart';
import 'pre_prayer_screen.dart';
import 'settings_screen.dart';

/// Settings displayed inside the same navigation shell used by the app.
/// The settings screen remains the existing implementation; this wrapper only
/// guarantees that the shared bottom navigation is always visible.
class SettingsShellScreen extends StatelessWidget {
  const SettingsShellScreen({super.key});

  void _navigate(BuildContext context, int index) {
    if (index == 4) {
      final next = context.read<AppState>().nextPrayer;
      if (next != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)),
        );
      }
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const SettingsScreen(),
      bottomNavigationBar: AqimBottomNav(
        currentIndex: 5,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }
}
