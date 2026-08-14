import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';
import '../navigation/nav_key.dart';
import '../screens/pre_prayer_screen.dart';

/// يدير ثلاثة تنبيهات لكل صلاة:
/// 1) منبّه الاستعداد قبل الوقت الحقيقي، بصوت خاص بكل صلاة.
///    يوم الجمعة، صلاة الظهر المعروضة باسم «الجمعة» تستعمل صوت
///    alarm_jomoaa بدل صوت الظهر العادي.
/// 2) الأذان عند الوقت الحقيقي بالضبط.
/// 3) هل صليت؟ بعد الوقت الحقيقي.
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
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

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

  Future<void> _snoozeCheckIn(String prayerId) async {
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;

    await _scheduleCheckIn(
      id: _idFor(prayer, 1),
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

  int _idFor(Prayer p, int typeOffset) =>
      Prayer.values.indexOf(p) * 10 + typeOffset;

  /// اسم صوت منبّه الاستعداد.
  ///
  /// الجمعة حالة خاصة: Dhuhr يبقى Prayer.dhuhr داخليًا، لكن إذا كان
  /// موعده يوم الجمعة نستعمل alarm_jomoaa.
  String _wakeAlarmSoundFor(Prayer p, DateTime prayerTime) {
    if (p == Prayer.dhuhr && prayerTime.weekday == DateTime.friday) {
      return 'alarm_jomoaa';
    }

    switch (p) {
      case Prayer.fajr:
        return 'alarm_fajr_3';
      case Prayer.dhuhr:
        return 'alarm_dhuhr';
      case Prayer.asr:
        return 'alarm_asr';
      case Prayer.maghrib:
        return 'alarm_maghrib';
      case Prayer.isha:
        return 'alarm_isha';
    }
  }

  Future<void> scheduleAllForToday(
    Map<Prayer, DateTime> realTimes, {
    int beforeMinutes = 10,
    int afterMinutes = 20,
    bool adhanEnabled = true,
  }) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final checkInTime = prayerTime.add(Duration(minutes: afterMinutes));

      final isJumuah =
          prayer == Prayer.dhuhr && prayerTime.weekday == DateTime.friday;

      if (prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(
          finalAlarmTime: alarmTime,
          beforeMinutes: beforeMinutes,
          now: now,
        );
      } else if (alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(
          id: _idFor(prayer, 0),
          title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}',
          body: isJumuah
              ? 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} على صلاة الجمعة.'
              : 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} على ${prayer.arabicName}.',
          scheduledDate: alarmTime,
          soundName: _wakeAlarmSoundFor(prayer, prayerTime),
          payload: prayer.name,
        );
      }

      if (adhanEnabled && prayerTime.isAfter(now)) {
        await _scheduleAdhan(
          id: _idFor(prayer, 2),
          title: isJumuah ? 'حان وقت صلاة الجمعة' : 'حان وقت ${prayer.arabicName}',
          body: 'حيّ على الصلاة، حيّ على الفلاح.',
          scheduledDate: prayerTime,
          payload: prayer.name,
        );
      }

      if (checkInTime.isAfter(now)) {
        await _scheduleCheckIn(
          id: _idFor(prayer, 1),
          title: isJumuah ? 'هل صليت الجمعة؟' : 'هل صليت ${prayer.arabicName}؟',
          body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
          scheduledDate: checkInTime,
          payload: prayer.name,
        );
      }
    }
  }

  /// منبّه الاستعداد قبل الصلاة — شاشة كاملة + صوت منبّه.
  /// الصوت يجب أن يكون داخل android/app/src/main/res/raw/.
  Future<void> _scheduleWakeAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String soundName,
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
          'aqim_wake_alarm_$soundName',
          'منبّه الاستعداد — $soundName',
          channelDescription: 'منبّه صوتي قبل الصلاة لمساعدتك على الاستعداد',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _scheduleFajrWakeAlarms({
    required DateTime finalAlarmTime,
    required int beforeMinutes,
    required DateTime now,
  }) async {
    final stages = [
      (
        offsetMinutes: 10,
        soundName: 'alarm_fajr_1',
        title: 'اقترب وقت الفجر',
        typeOffset: 0,
      ),
      (
        offsetMinutes: 5,
        soundName: 'alarm_fajr_2',
        title: 'استعد لصلاة الفجر',
        typeOffset: 3,
      ),
      (
        offsetMinutes: 0,
        soundName: 'alarm_fajr_3',
        title: 'حان الاستعداد الأخير لصلاة الفجر',
        typeOffset: 4,
      ),
    ];

    for (final stage in stages) {
      final scheduledDate =
          finalAlarmTime.subtract(Duration(minutes: stage.offsetMinutes));
      if (!scheduledDate.isAfter(now)) continue;

      await _scheduleWakeAlarm(
        id: _idFor(Prayer.fajr, stage.typeOffset),
        title: stage.title,
        body: 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} على صلاة الفجر.',
        scheduledDate: scheduledDate,
        soundName: stage.soundName,
        payload: Prayer.fajr.name,
      );
    }
  }

  Future<void> _scheduleAdhan({
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
          'aqim_adhan',
          'الأذان',
          channelDescription: 'تنبيه عند دخول وقت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_check_in',
          'متابعة الصلاة',
          channelDescription: 'تذكير لتسجيل الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}
