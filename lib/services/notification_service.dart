import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';
import '../navigation/nav_key.dart';
import '../screens/missed_prayer_response_screen.dart';
import '../screens/pre_prayer_screen.dart';
import '../screens/quran_screen.dart';

/// يدير تنبيهات الصلاة والورد اليومي من القرآن وملخص التقدم الأسبوعي.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool notificationsPermissionGranted = false;
  static const _snoozeActionId = 'snooze_15';
  static const _weeklySummaryId = 9000;
  static const _quranDailyId = 9100;
  static const _jumuahAlarmSound = 'alarm_jomoaa';
  static const _missedPrefix = 'missed:';
  static const _quranPrefix = 'quran:';

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
    _initialized = true;

    // Android 13+ لا يعرض أي إشعار قبل منح POST_NOTIFICATIONS.
    // نطلبها مبكرًا حتى لا يتم جدولة التنبيهات في صمت على الأجهزة الجديدة.
    notificationsPermissionGranted = await requestNotificationsPermission();

    // exactAllowWhileIdle يحتاج صلاحية المنبّه الدقيق على بعض إصدارات Android.
    // نستخدم dynamic هنا حتى يبقى التطبيق متوافقًا مع إصدارات plugin المختلفة.
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final dynamic impl = androidImpl;
      await impl?.requestExactAlarmsPermission();
    } catch (_) {
      // بعض الأجهزة/إصدارات plugin لا تعرض هذا الطلب؛ USE_EXACT_ALARM
      // في AndroidManifest يكفي في الحالات المدعومة.
    }

    final prefs = await SharedPreferences.getInstance();
    await scheduleQuranDaily(prefs.getInt('quran_next_page') ?? 1);
  }

  Future<bool> requestNotificationsPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.requestNotificationsPermission() ?? true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    if (response.actionId == _snoozeActionId) {
      _snoozeCheckIn(payload);
      return;
    }
    if (payload.startsWith(_quranPrefix)) {
      final page = int.tryParse(payload.substring(_quranPrefix.length)) ?? 1;
      rootNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => QuranScreen(initialPage: page)));
      return;
    }
    final isMissed = payload.startsWith(_missedPrefix);
    final prayerId = isMissed ? payload.substring(_missedPrefix.length) : payload;
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;
    final screen = isMissed ? MissedPrayerResponseScreen(prayer: prayer) : PrePrayerScreen(prayer: prayer);
    rootNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _snoozeCheckIn(String payload) async {
    final prayerId = payload.startsWith(_missedPrefix) ? payload.substring(_missedPrefix.length) : payload;
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;
    await _scheduleCheckIn(
      id: _idFor(prayer, 1),
      title: 'فاتتك صلاة ${prayer.arabicName}',
      body: 'هل صليتها؟ اضغط هنا لتسجيل الإجابة.',
      scheduledDate: DateTime.now().add(const Duration(minutes: 15)),
      payload: '$_missedPrefix$prayerId',
    );
  }

  Prayer? _prayerFromId(String id) {
    for (final p in Prayer.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  int _idFor(Prayer p, int typeOffset) => Prayer.values.indexOf(p) * 10 + typeOffset;

  Future<void> cancelMissedPrayer(Prayer prayer) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _idFor(prayer, 1));
  }

  String _wakeAlarmSoundFor(Prayer p, DateTime prayerTime) {
    if (p == Prayer.dhuhr && prayerTime.weekday == DateTime.friday) return _jumuahAlarmSound;
    switch (p) {
      case Prayer.fajr: return 'alarm_fajr_3';
      case Prayer.dhuhr: return 'alarm_dhuhr';
      case Prayer.asr: return 'alarm_asr';
      case Prayer.maghrib: return 'alarm_maghrib';
      case Prayer.isha: return 'alarm_isha';
    }
  }

  Future<void> scheduleAllForToday(
    Map<Prayer, DateTime> realTimes, {
    int beforeMinutes = 10,
    int afterMinutes = 20,
    bool adhanEnabled = true,
  }) async {
    if (!_initialized) await init();
    if (!notificationsPermissionGranted) {
      notificationsPermissionGranted = await requestNotificationsPermission();
    }

    await _plugin.cancelAll();
    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;
      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final missedTime = prayerTime.add(Duration(minutes: afterMinutes));
      final isJumuah = prayer == Prayer.dhuhr && prayerTime.weekday == DateTime.friday;

      // لا ننشئ تنبيهًا قديمًا؛ كل إشعار يملك وقتًا مستقبليًا فعليًا فقط.
      if (prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(finalAlarmTime: alarmTime, beforeMinutes: beforeMinutes, now: now);
      } else if (alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(
          id: _idFor(prayer, 0),
          title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}',
          body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.',
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

      // السؤال عن الصلاة لا يظهر قبل انتهاء وقتها.
      if (missedTime.isAfter(now)) {
        await _scheduleCheckIn(
          id: _idFor(prayer, 1),
          title: isJumuah ? 'فاتتك صلاة الجمعة' : 'فاتتك صلاة ${prayer.arabicName}',
          body: 'اضغط هنا لتجيب مباشرة: هل صليتها أم لا؟',
          scheduledDate: missedTime,
          payload: '$_missedPrefix${prayer.name}',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await scheduleQuranDaily(prefs.getInt('quran_next_page') ?? 1);
  }

  Future<void> scheduleQuranDaily(int page) async {
    if (!_initialized) return;
    final safePage = page.clamp(1, 604);
    await _plugin.cancel(id: _quranDailyId);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 30);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _quranDailyId,
      title: 'وردك اليومي من القرآن 🌙',
      body: 'صفحة $safePage — دقائق قليلة اليوم تقرّبك من ختم القرآن. اضغط للقراءة.',
      scheduledDate: first,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_quran_daily',
          'الورد اليومي من القرآن',
          channelDescription: 'تذكير يومي لطيف لقراءة جزء من القرآن الكريم',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$_quranPrefix$safePage',
    );
  }

  Future<void> scheduleWeeklySummary(String text) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _weeklySummaryId);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    while (first.weekday != DateTime.friday || !first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
      first = tz.TZDateTime(tz.local, first.year, first.month, first.day, 20);
    }
    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: 'ملخص أسبوعك في أقيم 🌙',
      body: text,
      scheduledDate: first,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_weekly_summary',
          'ملخص الأسبوع',
          channelDescription: 'ملخص أسبوعي لتقدمك في الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final channelId = 'aqim_wake_alarm_$soundName';
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          soundName == _jumuahAlarmSound ? 'منبّه صلاة الجمعة' : 'منبّه الاستعداد — $soundName',
          channelDescription: soundName == _jumuahAlarmSound ? 'منبّه صوتي خاص بصلاة الجمعة' : 'منبّه صوتي قبل الصلاة لمساعدتك على الاستعداد',
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

  Future<void> _scheduleFajrWakeAlarms({required DateTime finalAlarmTime, required int beforeMinutes, required DateTime now}) async {
    final stages = [
      (offsetMinutes: 10, soundName: 'alarm_fajr_1', title: 'اقترب وقت الفجر', typeOffset: 0),
      (offsetMinutes: 5, soundName: 'alarm_fajr_2', title: 'استعد لصلاة الفجر', typeOffset: 3),
      (offsetMinutes: 0, soundName: 'alarm_fajr_3', title: 'حان الاستعداد الأخير لصلاة الفجر', typeOffset: 4),
    ];
    for (final stage in stages) {
      final scheduledDate = finalAlarmTime.subtract(Duration(minutes: stage.offsetMinutes));
      if (!scheduledDate.isAfter(now)) continue;
      await _scheduleWakeAlarm(
        id: _idFor(Prayer.fajr, stage.typeOffset),
        title: stage.title,
        body: 'تبقّى $beforeMinutes دقيقة على صلاة الفجر.',
        scheduledDate: scheduledDate,
        soundName: stage.soundName,
        payload: Prayer.fajr.name,
      );
    }
  }

  Future<void> _scheduleAdhan({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
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

  Future<void> _scheduleCheckIn({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_missed_prayer',
          'الصلوات الفائتة',
          channelDescription: 'تنبيه عند عدم تسجيل الصلاة بعد انتهاء وقتها',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}
