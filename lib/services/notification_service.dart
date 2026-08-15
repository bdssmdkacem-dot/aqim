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

/// إشعارات الصلاة والقرآن.
///
/// نستخدم Exact Alarm عندما يسمح Android بذلك. إذا لم يمنح النظام صلاحية
/// المنبّه الدقيق، لا نوقف الإشعارات كلها؛ نستخدم inexactAllowWhileIdle
/// كحل احتياطي حتى لا تتوقف التنبيهات تمامًا على الأجهزة المقيدة.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool notificationsPermissionGranted = false;
  bool exactAlarmPermissionGranted = false;
  Future<void>? _initFuture;

  static const _weeklySummaryId = 9000;
  static const _quranDailyId = 9100;
  static const _jumuahAlarmSound = 'alarm_jomoaa';
  static const _missedPrefix = 'missed:';
  static const _quranPrefix = 'quran:';

  // إصدار جديد للقنوات حتى لا ترث القنوات القديمة إعدادات الصوت/الأهمية.
  static const _channelVersion = 'v4';

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final localTz = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTz));
      } catch (_) {}

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialized = true;

      final android = _android;
      if (android != null) {
        notificationsPermissionGranted =
            await android.areNotificationsEnabled() ?? false;
        if (!notificationsPermissionGranted) {
          notificationsPermissionGranted =
              await android.requestNotificationsPermission() ?? false;
        }

        try {
          exactAlarmPermissionGranted =
              await android.canScheduleExactNotifications() ?? false;
          if (!exactAlarmPermissionGranted) {
            exactAlarmPermissionGranted =
                await android.requestExactAlarmsPermission() ?? false;
          }
        } catch (_) {
          exactAlarmPermissionGranted = false;
        }

        try {
          await android.requestFullScreenIntentPermission();
        } catch (_) {}
      }
    } catch (_) {
      _initialized = false;
      _initFuture = null;
      rethrow;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> areNotificationsEnabled() async {
    await init();
    final enabled = await _android?.areNotificationsEnabled();
    notificationsPermissionGranted = enabled ?? notificationsPermissionGranted;
    return notificationsPermissionGranted;
  }

  Future<bool> requestNotificationsPermission() async {
    await init();
    final granted = await _android?.requestNotificationsPermission() ?? false;
    notificationsPermissionGranted = granted;
    return granted;
  }

  Future<bool> refreshExactAlarmPermission() async {
    await init();
    try {
      exactAlarmPermissionGranted =
          await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      exactAlarmPermissionGranted = false;
    }
    return exactAlarmPermissionGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    await init();
    try {
      exactAlarmPermissionGranted =
          await _android?.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      exactAlarmPermissionGranted = false;
    }
    return exactAlarmPermissionGranted;
  }

  Future<bool> _ensureExactAlarmPermission() async {
    await refreshExactAlarmPermission();
    if (exactAlarmPermissionGranted) return true;
    return requestExactAlarmPermission();
  }

  AndroidScheduleMode get _scheduleMode =>
      exactAlarmPermissionGranted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    if (payload.startsWith(_quranPrefix)) {
      final page = int.tryParse(payload.substring(_quranPrefix.length)) ?? 1;
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => QuranScreen(initialPage: page)),
      );
      return;
    }

    final missed = payload.startsWith(_missedPrefix);
    final prayerId = missed
        ? payload.substring(_missedPrefix.length)
        : payload;
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => missed
            ? MissedPrayerResponseScreen(prayer: prayer)
            : PrePrayerScreen(prayer: prayer),
      ),
    );
  }

  Prayer? _prayerFromId(String id) {
    for (final p in Prayer.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  int _idFor(Prayer p, int offset) => Prayer.values.indexOf(p) * 10 + offset;

  Future<void> cancelMissedPrayer(Prayer prayer) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _idFor(prayer, 1));
  }

  String _wakeAlarmSoundFor(Prayer p, DateTime prayerTime) {
    if (p == Prayer.dhuhr && prayerTime.weekday == DateTime.friday) {
      return _jumuahAlarmSound;
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

  String _alarmChannel(String sound) => 'aqim_alarm_${_channelVersion}_$sound';

  Future<void> _scheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
  }) async {
    if (!scheduledDate.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: _scheduleMode,
      payload: payload,
    );
  }

  Future<void> scheduleAllForToday(
    Map<Prayer, DateTime> realTimes, {
    int beforeMinutes = 10,
    int afterMinutes = 20,
    bool adhanEnabled = true,
  }) async {
    await init();

    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      throw StateError('NOTIFICATIONS_PERMISSION_REQUIRED');
    }

    // نطلب exact عندما يمكن، لكن لا نجعل غيابه سببًا لتعطيل التنبيهات.
    await _ensureExactAlarmPermission();

    await _plugin.cancelAll();
    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;
      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final missedTime = prayerTime.add(Duration(minutes: afterMinutes));
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
          title: isJumuah
              ? 'استعد لصلاة الجمعة'
              : 'استعد لصلاة ${prayer.arabicName}',
          body: isJumuah
              ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.'
              : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.',
          scheduledDate: alarmTime,
          soundName: _wakeAlarmSoundFor(prayer, prayerTime),
          payload: prayer.name,
        );
      }

      if (adhanEnabled && prayerTime.isAfter(now)) {
        await _scheduleAdhan(
          id: _idFor(prayer, 2),
          title: isJumuah
              ? 'حان وقت صلاة الجمعة'
              : 'حان وقت ${prayer.arabicName}',
          body: 'حيّ على الصلاة، حيّ على الفلاح.',
          scheduledDate: prayerTime,
          payload: prayer.name,
        );
      }

      if (missedTime.isAfter(now)) {
        await _scheduleCheckIn(
          id: _idFor(prayer, 1),
          title: isJumuah
              ? 'فاتتك صلاة الجمعة'
              : 'فاتتك صلاة ${prayer.arabicName}',
          body: 'اضغط هنا لتجيب مباشرة: هل صليتها أم لا؟',
          scheduledDate: missedTime,
          payload: '$_missedPrefix${prayer.name}',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await scheduleQuranDaily(prefs.getInt('quran_next_page') ?? 1);
  }

  Future<void> _scheduleWakeAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String soundName,
    required String payload,
  }) async {
    final channel = _alarmChannel(soundName);
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          soundName == _jumuahAlarmSound
              ? 'منبّه صلاة الجمعة'
              : 'منبّه الاستعداد للصلاة',
          channelDescription: 'تنبيه صوتي قبل الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> _scheduleFajrWakeAlarms({
    required DateTime finalAlarmTime,
    required int beforeMinutes,
    required DateTime now,
  }) async {
    final stages = [
      (10, 'alarm_fajr_1', 'اقترب وقت الفجر', 0),
      (5, 'alarm_fajr_2', 'استعد لصلاة الفجر', 3),
      (0, 'alarm_fajr_3', 'حان الاستعداد الأخير لصلاة الفجر', 4),
    ];
    for (final stage in stages) {
      final scheduledDate = finalAlarmTime.subtract(
        Duration(minutes: stage.$1),
      );
      if (!scheduledDate.isAfter(now)) continue;
      await _scheduleWakeAlarm(
        id: _idFor(Prayer.fajr, stage.$4),
        title: stage.$3,
        body: 'تبقّى $beforeMinutes دقيقة على صلاة الفجر.',
        scheduledDate: scheduledDate,
        soundName: stage.$2,
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
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_adhan_v4',
          'الأذان',
          channelDescription: 'الأذان عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> _scheduleCheckIn({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_missed_prayer_v4',
          'تذكير الصلاة',
          channelDescription: 'تذكير بعد انتهاء وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> scheduleQuranDaily(int page) async {
    await init();
    await refreshExactAlarmPermission();
    final safePage = page.clamp(1, 604);
    await _plugin.cancel(id: _quranDailyId);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      30,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _quranDailyId,
      title: 'وردك اليومي من القرآن 🌙',
      body: 'صفحة $safePage — دقائق قليلة اليوم تقرّبك من ختم القرآن. اضغط للقراءة.',
      scheduledDate: first,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_quran_daily_v4',
          'الورد اليومي من القرآن',
          channelDescription: 'تذكير يومي لقراءة القرآن الكريم',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
      ),
      androidScheduleMode: _scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$_quranPrefix$safePage',
    );
  }

  Future<void> scheduleWeeklySummary(String text) async {
    await init();
    await refreshExactAlarmPermission();
    await _plugin.cancel(id: _weeklySummaryId);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    while (first.weekday != DateTime.friday || !first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
      first = tz.TZDateTime(
        tz.local,
        first.year,
        first.month,
        first.day,
        20,
      );
    }
    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: 'ملخص أسبوعك في أقيم 🌙',
      body: text,
      scheduledDate: first,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_weekly_summary_v4',
          'ملخص الأسبوع',
          channelDescription: 'ملخص أسبوعي لتقدمك في الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
      ),
      androidScheduleMode: _scheduleMode,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }
}
