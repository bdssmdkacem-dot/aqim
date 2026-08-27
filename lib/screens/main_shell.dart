import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../services/religious_events_service.dart';
import '../state/app_state.dart';
import '../widgets/aqim_bottom_nav.dart';
import '../widgets/religious_event_home_card.dart';
import 'adhkar_home_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'pre_prayer_screen.dart';
import 'quran_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  static const _tabs = [HomeScreen(), QuranScreen(), AdhkarHomeScreen(), MoreScreen()];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  void _navigate(int index) {
    if (index == 4) {
      final next = context.read<AppState>().nextPrayer;
      if (next != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)));
      }
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final todayEvent = ReligiousEventsService.eventOn(DateTime.now());
    return Scaffold(
      body: Column(
        children: [
          if (_index == 0 && todayEvent != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: ReligiousEventHomeCard(event: todayEvent),
            ),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
          if (_index == 0) const AppBannerAd(placement: 'home'),
        ],
      ),
      bottomNavigationBar: AqimBottomNav(currentIndex: _index, onTap: _navigate),
    );
  }
}
