import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';
import '../navigation/nav_key.dart';
import '../screens/pre_prayer_screen.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {}

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null) return;

    final prayer = _prayerFromId(payload);

    if (prayer == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PrePrayerScreen(prayer: prayer),
      ),
    );
  }

  Prayer? _prayerFromId(String id) {
    for (final prayer in Prayer.values) {
      if (prayer.name == id) {
        return prayer;
      }
    }
    return null;
  }

  int _idFor(Prayer prayer, {required bool isCheckIn}) {
    return Prayer.values.indexOf(prayer) * 10 + (isCheckIn ? 1 : 0);
  }

  Future<void> scheduleAllForToday(
      Map<Prayer, DateTime> realTimes) async {
    if (!_initialized) return;

    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      final beforeTime =
          prayerTime.subtract(const Duration(minutes: 10));

      final checkTime =
          prayerTime.add(const Duration(minutes: 20));

      if (beforeTime.isAfter(now)) {
        await _schedule(
          id: _idFor(prayer, isCheckIn: false),
          title: 'اقترب وقت ${prayer.arabicName}',
          body: 'تبقّى عشر دقائق — استعد لصلاة ${prayer.arabicName}.',
          scheduledDate: beforeTime,
          payload: prayer.name,
        );
      }

      if (checkTime.isAfter(now)) {
        await _schedule(
          id: _idFor(prayer, isCheckIn: true),
          title: 'هل صليت ${prayer.arabicName}؟',
          body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
          scheduledDate: checkTime,
          payload: prayer.name,
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_prayer_reminders',
          'تذكيرات الصلاة',
          channelDescription:
              'تذكير قبل كل صلاة وتنبيه بعدها لتسجيل الحالة',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
