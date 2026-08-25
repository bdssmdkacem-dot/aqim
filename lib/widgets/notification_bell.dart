import 'package:flutter/material.dart';
import '../screens/notification_inbox_screen.dart';
import '../services/notification_inbox_service.dart';
import '../services/religious_events_service.dart';
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
    _sync();
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
