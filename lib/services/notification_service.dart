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

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;


  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(
        tz.getLocation(localTz),
      );
    } catch (_) {
      tz.setLocalLocation(
        tz.getLocation('Africa/Casablanca'),
      );
    }


    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');


    const settings = InitializationSettings(
      android: androidSettings,
    );


   await _plugin.initialize(
  settings: settings,
  onDidReceiveNotificationResponse: _onNotificationTap,
);


    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();


    await android?.requestNotificationsPermission();


    _initialized = true;
  }


  static const _snoozeActionId = 'snooze_15';
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (response.actionId == _snoozeActionId) {
      _snoozeCheckIn(payload);
      return;
    }

    final prayer = _prayerFromId(payload);
    if (prayer == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: prayer)),
    );
  }

  /// يؤجّل إشعار "هل صليت؟" خمس عشرة دقيقة بدل فتح التطبيق مباشرة.
  /// يعمل عندما يكون التطبيق مفتوحًا فـ الخلفية (وليس مغلقًا بالكامل من
  /// قِبل النظام) — قيد معروف موثّق فـ README.
  Future<void> _snoozeCheckIn(String prayerId) async {
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;

    await _scheduleCheckIn(
      id: _idFor(prayer, isCheckIn: true),
      title: 'هل صليت ${prayer.arabicName}؟',
      body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
      scheduledDate: DateTime.now().add(const Duration(minutes: 15)),
      payload: prayerId,
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
  /// الحقيقية. يُستدعى فـ كل مرة تُجلَب فيها أوقات جديدة بنجاح، أو عند
  /// تغيير المستخدم لتوقيت التذكير من الإعدادات.
  Future<void> scheduleAllForToday(
    Map<Prayer, DateTime> realTimes, {
    int beforeMinutes = 10,
    int afterMinutes = 20,
  }) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      final beforeTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final checkInTime = prayerTime.add(Duration(minutes: afterMinutes));

      if (beforeTime.isAfter(now)) {
        await _schedule(
          id: _idFor(prayer, isCheckIn: false),
          title: 'اقترب وقت ${prayer.arabicName}',
          body: 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} — استعد لصلاة ${prayer.arabicName}.',
          scheduledDate: beforeTime,
          payload: prayer.name,
        );
      }

      if (checkInTime.isAfter(now)) {
        await _scheduleCheckIn(
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

  Future<void> _scheduleCheckIn({
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_prayer_reminders',
          'تذكيرات الصلاة',
          channelDescription: 'تذكير قبل كل صلاة وتنبيه بعدها لتسجيل الحالة',
          importance: Importance.high,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(
              _snoozeActionId,
              'أجّل 15 دقيقة',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// يجدول (أو يُحدِّث) إشعار الملخص الأسبوعي — يظهر كل جمعة الساعة ٨
  /// مساءً بنص محسوب من آخر مرة فُتح فيها التطبيق. ليس تكراريًا حقيقيًا
  /// (المحتوى يتغيّر يوميًا)، لذا يُعاد جدولته يوميًا بنص محدَّث بدل
  /// الاعتماد على تكرار ثابت النص.
  static const _weeklySummaryId = 999;

  Future<void> scheduleWeeklySummary(String body) async {
    if (!_initialized) return;
    final target = _nextFridayEightPm();
    final tzTime = tz.TZDateTime.from(target, tz.local);
    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: 'ملخّص أسبوعك مع أقم 🌙',
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_weekly_summary',
          'الملخص الأسبوعي',
          channelDescription: 'تذكير أسبوعي بعدد الصلوات المُتمّة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  DateTime _nextFridayEightPm() {
    final now = DateTime.now();
    var daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    var target = DateTime(now.year, now.month, now.day, 20).add(Duration(days: daysUntilFriday));
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 7));
    }
    return target;
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
