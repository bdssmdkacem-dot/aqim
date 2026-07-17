import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';
import '../navigation/nav_key.dart';
import '../screens/pre_prayer_screen.dart';

/// يدير تذكيرين لكل صلاة:
/// 1) "قبل الصلاة" — عشر دقائق قبل الوقت الحقيقي.
/// 2) "هل صليت؟" — عشرين دقيقة بعد الوقت الحقيقي.
///
/// يُجدوَل فقط بناءً على أوقات حقيقية (AppState.realTimes)، ولا يُستعمل
/// أبدًا مع الأوقات الاحتياطية الوهمية، تجنّبًا لتنبيه المستخدم فـ وقت
/// خاطئ. يستعمل جدولة "غير دقيقة" (inexact) عمدًا كي لا يحتاج التطبيق
/// صلاحية "المنبّهات الدقيقة" الحساسة على أندرويد 12+.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // نبقى على UTC كخيار احتياطي إن تعذّر تحديد المنطقة الزمنية —
      // أفضل من تعطّل الجدولة بالكامل.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final prayer = _prayerFromId(payload);
    if (prayer == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: prayer)),
    );
  }

  Prayer? _prayerFromId(String id) {
    for (final p in Prayer.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  int _idFor(Prayer p, {required bool isCheckIn}) {
    final base = Prayer.values.indexOf(p) * 10;
    return base + (isCheckIn ? 1 : 0);
  }

  /// يلغي كل التذكيرات السابقة ويعيد جدولتها بناءً على أوقات اليوم
  /// الحقيقية. يُستدعى في كل مرة تُجلَب فيها أوقات جديدة بنجاح.
  Future<void> scheduleAllForToday(Map<Prayer, DateTime> realTimes) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      final beforeTime = prayerTime.subtract(const Duration(minutes: 10));
      final checkInTime = prayerTime.add(const Duration(minutes: 20));

      if (beforeTime.isAfter(now)) {
        await _schedule(
          id: _idFor(prayer, isCheckIn: false),
          title: 'اقترب وقت ${prayer.arabicName}',
          body: 'تبقّى عشر دقائق — استعد لصلاة ${prayer.arabicName}.',
          scheduledDate: beforeTime,
          payload: prayer.name,
        );
      }

      if (checkInTime.isAfter(now)) {
        await _schedule(
          id: _idFor(prayer, isCheckIn: true),
          title: 'هل صليت ${prayer.arabicName}؟',
          body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
          scheduledDate: checkInTime,
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
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_prayer_reminders',
          'تذكيرات الصلاة',
          channelDescription: 'تذكير قبل كل صلاة وتنبيه بعدها لتسجيل الحالة',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
