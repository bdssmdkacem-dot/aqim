import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/notification_inbox_screen.dart';
import '../services/notification_inbox_service.dart';
import '../services/religious_events_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final event = ReligiousEventsService.eventOn(DateTime.now());
    if (event != null) {
      await NotificationInboxService.instance.add(
        id: 'religious-${event.id}-${event.date.toIso8601String().substring(0, 10)}',
        title: 'اليوم: ${event.title}',
        body: '${event.hijri}. نسأل الله أن يتقبل منكم صالح الأعمال.',
      );
    }

    // The missed-prayer inbox is derived from AppState. Do not use the generic
    // unread inbox count for the bell badge: the badge must mean only
    // "unpaid missed prayers".
    final state = context.read<AppState>();
    final today = DateTime.now();
    final dateKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final prayer in state.missedTodayPrayers) {
      await NotificationInboxService.instance.add(
        id: 'missed-prayer-$dateKey-${prayer.name}',
        title: 'صلاة فائتة: ${prayer.arabicName}',
        body: 'فات وقت ${prayer.arabicName}. اضغط هنا للانتقال مباشرة إلى تسجيل القضاء.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This value comes directly from the same source used by MissedPrayersCard.
    // Therefore the red indicator changes immediately after qada/markDone.
    final missedCount = context.watch<AppState>().missedTodayCount;

    return Material(
      color: AppColors.surfaceDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await _sync();
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
          );
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.ivory),
            if (missedCount > 0)
              Positioned(
                top: 1,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(color: AppColors.ember, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    missedCount > 99 ? '99+' : '$missedCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
