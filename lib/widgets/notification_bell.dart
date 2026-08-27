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
  int _unread = 0;

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

    // Keep the notification inbox synchronized with the same missed-prayer
    // state shown on the home screen. An item is created only after a prayer
    // is actually considered missed, and its id is date+prayer so repeated
    // refreshes do not create duplicates.
    final state = context.read<AppState>();
    final today = DateTime.now();
    final dateKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0)}';
    for (final prayer in state.missedTodayPrayers) {
      await NotificationInboxService.instance.add(
        id: 'missed-prayer-$dateKey-${prayer.name}',
        title: 'صلاة فائتة: ${prayer.arabicName}',
        body: 'فات وقت ${prayer.arabicName}. يمكنك تسجيلها كمقضيّة من الصفحة الرئيسية.',
      );
    }

    final count = await NotificationInboxService.instance.unreadCount();
    if (mounted) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await _sync();
          if (!mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationInboxScreen()));
          await _sync();
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.ivory),
            if (_unread > 0)
              Positioned(
                top: 1,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(color: AppColors.ember, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(_unread > 99 ? '99+' : '$_unread', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
