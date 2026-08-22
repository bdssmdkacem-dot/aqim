import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notifications for major Islamic occasions using Morocco dates.
///
/// The 1448 AH Mawlid date is confirmed by Morocco's Ministry of Habous:
/// 12 Rabi I 1448 = 25 August 2026.
/// 1448 AH Ramadan/Eid dates and 1449 dates below are calendar estimates and
/// must be updated when Morocco officially announces the moon-sighting dates.
class IslamicOccasionsService {
  IslamicOccasionsService._();
  static final IslamicOccasionsService instance = IslamicOccasionsService._();

  static const int _nightBaseId = 9200;
  static const int _morningBaseId = 9300;

  static const _occasions = <_IslamicOccasion>[
    _IslamicOccasion(
      id: 1,
      name: 'المولد النبوي الشريف',
      date: _DateOnly(2026, 8, 25),
      hijri: '12 ربيع الأول 1448 هـ',
      official: true,
    ),
    _IslamicOccasion(
      id: 2,
      name: 'حلول شهر رمضان المبارك',
      date: _DateOnly(2027, 2, 8),
      hijri: '1 رمضان 1448 هـ',
      official: false,
    ),
    _IslamicOccasion(
      id: 3,
      name: 'عيد الفطر المبارك',
      date: _DateOnly(2027, 3, 9),
      hijri: '1 شوال 1448 هـ',
      official: false,
    ),
    _IslamicOccasion(
      id: 4,
      name: 'عيد الأضحى المبارك',
      date: _DateOnly(2027, 5, 16),
      hijri: '10 ذو الحجة 1448 هـ',
      official: false,
    ),
    _IslamicOccasion(
      id: 5,
      name: 'المولد النبوي الشريف',
      date: _DateOnly(2027, 8, 14),
      hijri: '12 ربيع الأول 1449 هـ',
      official: false,
    ),
  ];

  Future<void> scheduleUpcoming(FlutterLocalNotificationsPlugin plugin) async {
    final now = tz.TZDateTime.now(tz.local);

    for (final occasion in _occasions) {
      final day = tz.TZDateTime(
        tz.local,
        occasion.date.year,
        occasion.date.month,
        occasion.date.day,
      );
      final night = tz.TZDateTime(
        tz.local,
        occasion.date.year,
        occasion.date.month,
        occasion.date.day,
      ).subtract(const Duration(days: 1)).add(const Duration(hours: 20));
      final morning = tz.TZDateTime(
        tz.local,
        occasion.date.year,
        occasion.date.month,
        occasion.date.day,
        8,
      );

      final nightId = _nightBaseId + occasion.id;
      final morningId = _morningBaseId + occasion.id;
      await plugin.cancel(id: nightId);
      await plugin.cancel(id: morningId);

      if (night.isAfter(now)) {
        await _schedule(
          plugin,
          id: nightId,
          title: 'غدًا ${occasion.name} 🌙',
          body: 'غدًا ${occasion.name} — ${occasion.hijri}. نسأل الله أن يبارك لكم في هذه المناسبة.',
          scheduled: night,
          payload: 'islamic_occasion:${occasion.id}:night',
        );
      }

      if (morning.isAfter(now)) {
        await _schedule(
          plugin,
          id: morningId,
          title: occasion.name,
          body: 'اليوم ${occasion.name} — ${occasion.hijri}. تقبل الله منا ومنكم صالح الأعمال.',
          scheduled: morning,
          payload: 'islamic_occasion:${occasion.id}:morning',
        );
      }

      // Keep analyzer aware that the date itself is intentional metadata.
      if (day.isBefore(now) && occasion.official) {
        // Confirmed past occasion: nothing to schedule.
      }
    }
  }

  Future<void> _schedule(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required String payload,
  }) async {
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_islamic_occasions_v1',
          'المناسبات الإسلامية',
          channelDescription: 'تذكيرات ليلة وصباح المناسبات الإسلامية',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}

class _IslamicOccasion {
  final int id;
  final String name;
  final _DateOnly date;
  final String hijri;
  final bool official;

  const _IslamicOccasion({
    required this.id,
    required this.name,
    required this.date,
    required this.hijri,
    required this.official,
  });
}

class _DateOnly {
  final int year;
  final int month;
  final int day;

  const _DateOnly(this.year, this.month, this.day);
}
