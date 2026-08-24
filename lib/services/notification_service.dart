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
import 'religious_events_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool notificationsPermissionGranted = false;
  bool exactAlarmPermissionGranted = false;
  bool notificationPolicyAccessGranted = false;
  Future<void>? _initFuture;

  static const _jumuahAlarmSound = 'alarm_jomoaa';
  static const _missedPrefix = 'missed:';
  static const _quranPrefix = 'quran:';
  static const _witrPrefix = 'witr:';
  static const _religiousPrefix = 'religious:';
  static const _channelVersion = 'v13';
  static const _weeklySummaryId = 9001;
  static const _quranFajrId = 9002;
  static const _quranDhuhrId = 9003;
  static const _quranAsrId = 9004;
  static const _quranMaghribId = 9005;
  static const _witrId = 9010;
  static const _religiousBaseId = 9200;

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
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> refreshPermissionStatus() async {
    final android = _android;
    if (android == null) return;
    notificationsPermissionGranted = await android.areNotificationsEnabled() ?? false;
    try {
      exactAlarmPermissionGranted = await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      exactAlarmPermissionGranted = false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    await init();
    await refreshPermissionStatus();
    return notificationsPermissionGranted;
  }

  Future<bool> refreshExactAlarmPermission() async {
    await init();
    await refreshPermissionStatus();
    return exactAlarmPermissionGranted;
  }

  Future<bool> requestNotificationsPermission() async {
    await init();
    final android = _android;
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission() ?? false;
    notificationsPermissionGranted = granted;
    return granted;
  }

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

  Future<bool> refreshNotificationPolicyAccess() async {
    await init();
    return notificationPolicyAccessGranted;
  }

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

  AndroidScheduleMode get _scheduleMode => exactAlarmPermissionGranted
      ? AndroidScheduleMode.alarmClock
      : AndroidScheduleMode.inexactAllowWhileIdle;

  int _idFor(Prayer prayer, int kind) => prayer.index * 10 + kind;

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

  String _alarmChannel(String sound) => 'aqim_alarm_${_channelVersion}_$sound';

  DateTime _safeFallbackDate(DateTime scheduledDate) {
    if (exactAlarmPermissionGranted) return scheduledDate;
    return scheduledDate.add(const Duration(minutes: 2));
  }

  Future<void> _scheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    required String payload,
  }) async {
    final safeDate = _safeFallbackDate(scheduledDate);
    if (!safeDate.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(safeDate, tz.local),
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
    if (!exactAlarmPermissionGranted) {
      await requestExactAlarmPermission();
      await refreshExactAlarmPermission();
    }
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;
      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final missedTime = prayerTime.add(Duration(minutes: afterMinutes));
      final isJumuah = prayer == Prayer.dhuhr && prayerTime.weekday == DateTime.friday;
      if (prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(finalAlarmTime: alarmTime, beforeMinutes: beforeMinutes, now: now);
      } else if (alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(id: _idFor(prayer, 0), title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}', body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.', scheduledDate: alarmTime, soundName: _wakeAlarmSoundFor(prayer, prayerTime), payload: prayer.name);
      }
      if (adhanEnabled && prayerTime.isAfter(now)) {
        await _scheduleAdhan(id: _idFor(prayer, 2), title: isJumuah ? 'حان وقت صلاة الجمعة' : 'حان وقت ${prayer.arabicName}', body: 'حيّ على الصلاة، حيّ على الفلاح.', scheduledDate: prayerTime, payload: prayer.name);
      }
      if (missedTime.isAfter(now)) {
        await _scheduleCheckIn(id: _idFor(prayer, 1), title: isJumuah ? 'فاتتك صلاة الجمعة' : 'فاتتك صلاة ${prayer.arabicName}', body: 'اضغط هنا لتجيب مباشرة: هل صليتها أم لا؟', scheduledDate: missedTime, payload: '$_missedPrefix${prayer.name}');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('quran_resume_page') ?? prefs.getInt('quran_next_page') ?? 1;
    await _scheduleQuranReminders(realTimes, savedPage);
    await _scheduleShafWitrReminder(realTimes[Prayer.isha]);
    await _scheduleReligiousEvents();
  }

  Future<void> _scheduleReligiousEvents() async {
    final events = ReligiousEventsService.upcoming(from: DateTime.now(), years: 2);
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final baseId = _religiousBaseId + i * 2;
      await _plugin.cancel(id: baseId);
      await _plugin.cancel(id: baseId + 1);
      final nightBefore = DateTime(event.date.year, event.date.month, event.date.day).subtract(const Duration(days: 1)).add(const Duration(hours: 20));
      final morning = DateTime(event.date.year, event.date.month, event.date.day, 8);
      final qualifier = event.provisional ? ' (موعد متوقع)' : '';
      if (nightBefore.isAfter(DateTime.now())) {
        await _scheduleExact(id: baseId, title: 'غدًا: ${event.title}$qualifier', body: 'غدًا ${event.hijri}. استعد لهذه المناسبة المباركة.', scheduledDate: nightBefore, payload: '$_religiousPrefix${event.id}:night', details: ReligiousEventsService.notificationDetails());
      }
      if (morning.isAfter(DateTime.now())) {
        await _scheduleExact(id: baseId + 1, title: 'اليوم: ${event.title}$qualifier', body: '${event.hijri}. تقبل الله طاعتكم وكل عام وأنتم بخير.', scheduledDate: morning, payload: '$_religiousPrefix${event.id}:morning', details: ReligiousEventsService.notificationDetails());
      }
    }
  }

  NotificationDetails _alarmDetails({required String channelId, required String channelName, required String channelDescription, String? soundName, required AndroidNotificationCategory category}) => NotificationDetails(android: AndroidNotificationDetails(channelId, channelName, channelDescription: channelDescription, importance: Importance.max, priority: Priority.max, category: category, fullScreenIntent: true, playSound: soundName != null, sound: soundName == null ? null : RawResourceAndroidNotificationSound(soundName), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));

  NotificationDetails _reminderDetails({required String channelId, required String channelName, required String description}) => NotificationDetails(android: AndroidNotificationDetails(channelId, channelName, channelDescription: description, importance: Importance.high, priority: Priority.high, category: AndroidNotificationCategory.reminder, playSound: true, enableVibration: true, visibility: NotificationVisibility.public));

  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aqim_pre_prayer_${_channelVersion}',
        'التنبيه قبل الصلاة',
        channelDescription: 'تنبيه صوتي قبل الصلاة — ليس أذانًا',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        channelBypassDnd: notificationPolicyAccessGranted,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: details,
    );
  }

  Future<void> _scheduleFajrWakeAlarms({required DateTime finalAlarmTime, required int beforeMinutes, required DateTime now}) async {
    final stages = [(10, 'alarm_fajr_1', 'اقترب وقت الفجر', 0), (5, 'alarm_fajr_2', 'استعد لصلاة الفجر', 3), (0, 'alarm_fajr_3', 'حان الاستعداد الأخير لصلاة الفجر', 4)];
    for (final stage in stages) {
      final scheduledDate = finalAlarmTime.subtract(Duration(minutes: stage.$1));
      if (!scheduledDate.isAfter(now)) continue;
      await _scheduleWakeAlarm(id: _idFor(Prayer.fajr, stage.$4), title: stage.$3, body: 'تبقّى $beforeMinutes دقيقة على صلاة الفجر.', scheduledDate: scheduledDate, soundName: stage.$2, payload: Prayer.fajr.name);
    }
  }

  Future<void> _scheduleAdhan({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSound = prefs.getString('adhan_sound') ?? 'azan_maroc_1';
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_adhan_${_channelVersion}_$selectedSound',
          'الأذان',
          channelDescription: 'الأذان عند دخول وقت الصلاة — الصوت المختار من الإعدادات',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(selectedSound),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          channelBypassDnd: notificationPolicyAccessGranted,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> _scheduleCheckIn({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async => _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: _alarmDetails(channelId: 'aqim_missed_prayer_${_channelVersion}', channelName: 'تذكير الصلاة', channelDescription: 'تذكير بعد انتهاء وقت الصلاة', category: AndroidNotificationCategory.reminder));

  Future<void> _scheduleQuranReminders(Map<Prayer, DateTime> times, int page) async {
    final slots = <int, (DateTime?, String, String)>{
      _quranFajrId: (times[Prayer.fajr]?.add(const Duration(minutes: 15)), 'قرآن الفجر — أقم', 'اجعل بعد الفجر وردًا ثابتًا من كتاب الله.'),
      _quranDhuhrId: (times[Prayer.dhuhr]?.add(const Duration(minutes: 30)), 'ورد القرآن — وقت الظهر', 'خذ دقائق هادئة لقراءة القرآن وأكمل من الصفحة $page.'),
      _quranAsrId: (times[Prayer.asr]?.add(const Duration(minutes: 30)), 'ورد القرآن — وقت العصر', 'تذكير لطيف لقراءة ما تيسر من القرآن اليوم.'),
      _quranMaghribId: (times[Prayer.maghrib]?.add(const Duration(minutes: 30)), 'ورد القرآن — بعد المغرب', 'قبل أن ينتهي اليوم، افتح القرآن وأكمل وردك.'),
    };
    for (final entry in slots.entries) {
      await _plugin.cancel(id: entry.key);
      final scheduled = entry.value.$1;
      if (scheduled == null || !scheduled.isAfter(DateTime.now())) continue;
      await _scheduleExact(id: entry.key, title: entry.value.$2, body: entry.value.$3, scheduledDate: scheduled, payload: '$_quranPrefix$page', details: _reminderDetails(channelId: 'aqim_quran_reading_${_channelVersion}', channelName: 'قراءة القرآن', description: 'تذكيرات يومية متفرقة لقراءة القرآن الكريم'));
    }
  }

  Future<void> _scheduleShafWitrReminder(DateTime? isha) async {
    await _plugin.cancel(id: _witrId);
    if (isha == null) return;
    final scheduled = isha.add(const Duration(minutes: 5));
    if (!scheduled.isAfter(DateTime.now())) return;
    await _scheduleExact(id: _witrId, title: 'الشفع والوتر', body: 'بعد صلاة العشاء، حان وقت صلاة الشفع والوتر بإذن الله.', scheduledDate: scheduled, payload: '$_witrPrefix${isha.toIso8601String()}', details: _reminderDetails(channelId: 'aqim_witr_${_channelVersion}', channelName: 'الشفع والوتر', description: 'تذكير بعد صلاة العشاء بخمس دقائق بصلاة الشفع والوتر'));
  }

  Future<void> scheduleWeeklySummary(String text) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    while (scheduled.weekday != DateTime.sunday || !scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    await _plugin.cancel(id: _weeklySummaryId);
    await _plugin.zonedSchedule(id: _weeklySummaryId, title: 'ملخص أسبوع أقم', body: text, scheduledDate: scheduled, notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('aqim_weekly_summary_v1', 'ملخص أسبوع أقم', channelDescription: 'ملخص أسبوعي لتقدم الصلاة', importance: Importance.defaultImportance, priority: Priority.defaultPriority, category: AndroidNotificationCategory.reminder, playSound: true),), androidScheduleMode: _scheduleMode, matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, payload: 'weekly_summary');
  }

  Future<void> scheduleQuranDaily(int page, {DateTime? afterFajr}) async {
    await init();
    final safePage = page.clamp(1, 604);
    await _plugin.cancel(id: _quranFajrId);
    final scheduled = afterFajr?.add(const Duration(minutes: 15));
    if (scheduled == null || !scheduled.isAfter(DateTime.now())) return;
    await _scheduleExact(id: _quranFajrId, title: 'قرآن الفجر — أقم', body: 'أكمل وردك من الصفحة $safePage — دقائق قليلة مع القرآن.', scheduledDate: scheduled, payload: '$_quranPrefix$safePage', details: _reminderDetails(channelId: 'aqim_quran_reading_${_channelVersion}', channelName: 'قراءة القرآن', description: 'تذكير يومي بقراءة القرآن الكريم'));
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload ?? '';
    final context = rootNavigatorKey.currentState?.context;
    if (context == null) return;
    if (payload.startsWith(_missedPrefix)) {
      final name = payload.substring(_missedPrefix.length);
      final prayer = Prayer.values.where((p) => p.name == name).firstOrNull;
      if (prayer != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissedPrayerResponseScreen(prayer: prayer)));
    } else if (payload.startsWith(_quranPrefix)) {
      final page = int.tryParse(payload.substring(_quranPrefix.length));
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuranScreen(initialPage: page)));
    } else if (payload.startsWith(_witrPrefix)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrePrayerScreen(prayer: Prayer.isha)));
    } else if (payload.isNotEmpty && !payload.startsWith(_religiousPrefix)) {
      final prayer = Prayer.values.where((p) => p.name == payload).firstOrNull;
      if (prayer != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: prayer)));
    }
  }
}