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

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool notificationsPermissionGranted = false;
  bool exactAlarmPermissionGranted = false;
  bool notificationPolicyAccessGranted = false;
  Future<void>? _initFuture;

  static const _jumuahAlarmSound = 'alarm_jomoaa';
  static const _missedPrefix = 'missed:';
  static const _quranPrefix = 'quran:';
  static const _channelVersion = 'v7';
  static const _weeklySummaryId = 9001;

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
      await refreshPermissionStatus();
    } catch (_) {
      _initialized = false;
      _initFuture = null;
      rethrow;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> refreshPermissionStatus() async {
    final android = _android;
    if (android == null) return;

    notificationsPermissionGranted =
        await android.areNotificationsEnabled() ?? false;

    try {
      exactAlarmPermissionGranted =
          await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      exactAlarmPermissionGranted = false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    await init();
    await refreshPermissionStatus();
    return notificationsPermissionGranted;
  }

  /// Returns the current exact-alarm permission state.
  ///
  /// This method intentionally does not open Android Settings. The request
  /// method below is responsible for opening the permission screen when the
  /// user explicitly taps the permission button.
  Future<bool> refreshExactAlarmPermission() async {
    await init();
    await refreshPermissionStatus();
    return exactAlarmPermissionGranted;
  }

  /// Android 13+ notification permission.
  Future<bool> requestNotificationsPermission() async {
    await init();
    final android = _android;
    if (android == null) return false;

    final granted = await android.requestNotificationsPermission() ?? false;
    notificationsPermissionGranted = granted;
    return granted;
  }

  /// Android 14+ exact alarm permission.
  Future<bool> requestExactAlarmPermission() async {
    await init();
    final android = _android;
    if (android == null) return false;

    try {
      final granted = await android.requestExactAlarmsPermission() ?? false;
      exactAlarmPermissionGranted = granted;
      return granted;
    } catch (_) {
      await refreshPermissionStatus();
      return exactAlarmPermissionGranted;
    }
  }

  /// Opens Android's notification-policy access screen.
  ///
  /// flutter_local_notifications does not expose a separate passive getter
  /// for this setting, so the cached value is updated from the request result.
  Future<bool> requestNotificationPolicyAccess() async {
    await init();
    final android = _android;
    if (android == null) return false;

    try {
      final granted = await android.requestNotificationPolicyAccess() ?? false;
      notificationPolicyAccessGranted = granted;
      return granted;
    } catch (_) {
      return notificationPolicyAccessGranted;
    }
  }

  /// Refresh the cached DND state without opening Settings.
  ///
  /// The notification plugin has no passive DND-policy getter, therefore we
  /// preserve the last known value here.
  Future<bool> refreshNotificationPolicyAccess() async {
    await init();
    return notificationPolicyAccessGranted;
  }

  /// Android full-screen notification permission.
  Future<bool> requestFullScreenIntentPermission() async {
    await init();
    final android = _android;
    if (android == null) return false;

    try {
      return await android.requestFullScreenIntentPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  AndroidScheduleMode get _scheduleMode =>
      exactAlarmPermissionGranted
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle;

  int _idFor(Prayer prayer, int kind) => prayer.index * 10 + kind;

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

  String _alarmChannel(String sound) =>
      'aqim_alarm_${_channelVersion}_$sound';

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

    if (!await areNotificationsEnabled()) {
      throw StateError('NOTIFICATIONS_PERMISSION_REQUIRED');
    }

    await refreshExactAlarmPermission();
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

  NotificationDetails _alarmDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? soundName,
    required AndroidNotificationCategory category,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        category: category,
        fullScreenIntent: true,
        playSound: soundName != null,
        sound: soundName == null
            ? null
            : RawResourceAndroidNotificationSound(soundName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        channelBypassDnd: notificationPolicyAccessGranted,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  Future<void> _scheduleWakeAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String soundName,
    required String payload,
  }) async {
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: _alarmDetails(
        channelId: _alarmChannel(soundName),
        channelName: soundName == _jumuahAlarmSound
            ? 'منبّه صلاة الجمعة'
            : 'منبّه الاستعداد للصلاة',
        channelDescription: 'تنبيه صوتي قبل الصلاة — يعمل كمنبّه',
        soundName: soundName,
        category: AndroidNotificationCategory.alarm,
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
      final scheduledDate =
          finalAlarmTime.subtract(Duration(minutes: stage.$1));
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
      details: _alarmDetails(
        channelId: 'aqim_adhan_${_channelVersion}',
        channelName: 'الأذان',
        channelDescription: 'الأذان عند دخول وقت الصلاة — صوت منبّه',
        soundName: 'adhan',
        category: AndroidNotificationCategory.alarm,
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
      details: _alarmDetails(
        channelId: 'aqim_missed_prayer_${_channelVersion}',
        channelName: 'تذكير الصلاة',
        channelDescription: 'تذكير بعد انتهاء وقت الصلاة',
        category: AndroidNotificationCategory.reminder,
      ),
    );
  }

  /// Schedules the weekly progress summary for the next Sunday at 20:00.
  ///
  /// The notification repeats weekly using the timezone-aware scheduler.
  Future<void> scheduleWeeklySummary(String text) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
    );

    while (scheduled.weekday != DateTime.sunday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.cancel(id: _weeklySummaryId);
    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: 'ملخص أسبوع أقم',
      body: text,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_weekly_summary_v1',
          'ملخص أسبوع أقم',
          channelDescription: 'ملخص أسبوعي لتقدم الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
        ),
      ),
      androidScheduleMode: _scheduleMode,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  Future<void> scheduleQuranDaily(int page) async {}

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload ?? '';
    final context = rootNavigatorKey.currentState?.context;
    if (context == null) return;

    if (payload.startsWith(_missedPrefix)) {
      final name = payload.substring(_missedPrefix.length);
      final prayer = Prayer.values.where((p) => p.name == name).firstOrNull;
      if (prayer != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissedPrayerResponseScreen(prayer: prayer),
          ),
        );
      }
    } else if (payload.startsWith(_quranPrefix)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuranScreen()),
      );
    } else if (payload.isNotEmpty) {
      final prayer = Prayer.values.where((p) => p.name == payload).firstOrNull;
      if (prayer != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: prayer)),
        );
      }
    }
  }
}
