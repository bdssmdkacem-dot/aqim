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
  static const _channelVersion = 'v14';
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
      const androidInit = AndroidInitializationSettings('@drawable/ic_aqim_notification');
      await _plugin.initialize(settings: const InitializationSettings(android: androidInit), onDidReceiveNotificationResponse: _onNotificationTap);
      _initialized = true;
      await refreshPermissionStatus();
    } catch (_) {
      _initialized = false;
      _initFuture = null;
      rethrow;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> refreshPermissionStatus() async {
    final android = _android;
    if (android == null) return;
    notificationsPermissionGranted = await android.areNotificationsEnabled() ?? false;
    try { exactAlarmPermissionGranted = await android.canScheduleExactNotifications() ?? false; } catch (_) { exactAlarmPermissionGranted = false; }
  }

  Future<bool> areNotificationsEnabled() async { await init(); await refreshPermissionStatus(); return notificationsPermissionGranted; }
  Future<bool> refreshExactAlarmPermission() async { await init(); await refreshPermissionStatus(); return exactAlarmPermissionGranted; }

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
    } catch (_) { await refreshPermissionStatus(); return exactAlarmPermissionGranted; }
  }

  Future<bool> requestNotificationPolicyAccess() async {
    await init();
    final android = _android;
    if (android == null) return false;
    try {
      final granted = await android.requestNotificationPolicyAccess() ?? false;
      notificationPolicyAccessGranted = granted;
      return granted;
    } catch (_) { return notificationPolicyAccessGranted; }
  }

  Future<bool> refreshNotificationPolicyAccess() async { await init(); return notificationPolicyAccessGranted; }

  Future<bool> requestFullScreenIntentPermission() async {
    await init();
    final android = _android;
    if (android == null) return false;
    try { return await android.requestFullScreenIntentPermission() ?? false; } catch (_) { return false; }
  }

  AndroidScheduleMode get _scheduleMode => exactAlarmPermissionGranted ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.inexactAllowWhileIdle;
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

  DateTime _safeFallbackDate(DateTime scheduledDate) => exactAlarmPermissionGranted ? scheduledDate : scheduledDate.add(const Duration(minutes: 2));

  Future<void> _scheduleExact({required int id, required String title, required String body, required DateTime scheduledDate, required NotificationDetails details, required String payload}) async {
    final safeDate = _safeFallbackDate(scheduledDate);
    if (!safeDate.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(id: id, title: title, body: body, scheduledDate: tz.TZDateTime.from(safeDate, tz.local), notificationDetails: details, androidScheduleMode: _scheduleMode, payload: payload);
  }

  Future<void> scheduleAllForToday(Map<Prayer, DateTime> realTimes, {int beforeMinutes = 10, int afterMinutes = 20, bool adhanEnabled = true}) async {
    await init();
    if (!await areNotificationsEnabled()) throw StateError('NOTIFICATIONS_PERMISSION_REQUIRED');
    await refreshExactAlarmPermission();
    if (!exactAlarmPermissionGranted) { await requestExactAlarmPermission(); await refreshExactAlarmPermission(); }
    await _plugin.cancelAll();
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final prePrayerEnabled = prefs.getBool('pre_prayer_enabled') ?? true;
    final selectedPrePrayers = (prefs.getStringList('pre_prayer_prayers') ?? Prayer.values.map((p) => p.name).toList()).toSet();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;
      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final missedTime = prayerTime.add(Duration(minutes: afterMinutes));
      final isJumuah = prayer == Prayer.dhuhr && prayerTime.weekday == DateTime.friday;

      if (prePrayerEnabled && selectedPrePrayers.contains(prayer.name)) {
        if (prayer == Prayer.fajr) {
          await _scheduleFajrWakeAlarms(prayerTime: prayerTime, beforeMinutes: beforeMinutes, now: now);
        } else if (alarmTime.isAfter(now)) {
          await _scheduleWakeAlarm(id: _idFor(prayer, 0), title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}', body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.', scheduledDate: alarmTime, soundName: _wakeAlarmSoundFor(prayer, prayerTime), payload: prayer.name);
        }
      }

      if (adhanEnabled && prayerTime.isAfter(now)) {
        await _scheduleAdhan(prayer: prayer, id: _idFor(prayer, 2), title: isJumuah ? 'حان وقت صلاة الجمعة' : 'حان وقت ${prayer.arabicName}', body: 'حيّ على الصلاة، حيّ على الفلاح.', scheduledDate: prayerTime, payload: prayer.name);
      }
      if (missedTime.isAfter(now)) {
        await _scheduleCheckIn(id: _idFor(prayer, 1), title: isJumuah ? 'فاتتك صلاة الجمعة' : 'فاتتك صلاة ${prayer.arabicName}', body: 'اضغط هنا لتجيب مباشرة: هل صليتها أم لا؟', scheduledDate: missedTime, payload: '$_missedPrefix${prayer.name}');
      }
    }
    final riwaya = prefs.getString('quran_last_riwaya') == 'warsh' ? 'warsh' : 'hafs';
    final savedPage = prefs.getInt('quran_resume_page_$riwaya') ?? prefs.getInt('quran_next_page_$riwaya') ?? prefs.getInt('quran_${riwaya}_page') ?? 1;
    await _scheduleQuranReminders(realTimes, savedPage);
    await _scheduleShafWitrReminder(realTimes[Prayer.isha]);
    await _scheduleReligiousEvents();
  }

  Future<void> _scheduleReligiousEvents() async {
    final events = ReligiousEventsService.upcoming(from: DateTime.now(), years: 2);
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final baseId = _religiousBaseId + i * 2;
      await _plugin.cancel(id: baseId); await _plugin.cancel(id: baseId + 1);
      final nightBefore = DateTime(event.date.year, event.date.month, event.date.day).subtract(const Duration(days: 1)).add(const Duration(hours: 20));
      final morning = DateTime(event.date.year, event.date.month, event.date.day, 8);
      final qualifier = event.provisional ? ' (موعد متوقع)' : '';
      if (nightBefore.isAfter(DateTime.now())) await _scheduleExact(id: baseId, title: 'غدًا: ${event.title}$qualifier', body: 'غدًا ${event.hijri}. استعد لهذه المناسبة المباركة.', scheduledDate: nightBefore, payload: '$_religiousPrefix${event.id}:night', details: ReligiousEventsService.notificationDetails());
      if (morning.isAfter(DateTime.now())) await _scheduleExact(id: baseId + 1, title: 'اليوم: ${event.title}$qualifier', body: '${event.hijri}. تقبل الله طاعتكم وكل عام وأنتم بخير.', scheduledDate: morning, payload: '$_religiousPrefix${event.id}:morning', details: ReligiousEventsService.notificationDetails());
    }
  }

  NotificationDetails _alarmDetails({required String channelId, required String channelName, required String channelDescription, String? soundName, required AndroidNotificationCategory category}) => NotificationDetails(android: AndroidNotificationDetails(channelId, channelName, channelDescription: channelDescription, importance: Importance.max, priority: Priority.max, category: category, fullScreenIntent: true, playSound: soundName != null, sound: soundName == null ? null : RawResourceAndroidNotificationSound(soundName), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));
  NotificationDetails _reminderDetails({required String channelId, required String channelName, required String description}) => NotificationDetails(android: AndroidNotificationDetails(channelId, channelName, channelDescription: description, importance: Importance.high, priority: Priority.high, category: AndroidNotificationCategory.reminder, playSound: true, enableVibration: true, visibility: NotificationVisibility.public));

  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';
    final selectedSound = mode == 'alarm' ? soundName : null;
    final channelSuffix = mode == 'alarm' ? 'alarm_$soundName' : mode;
    final details = NotificationDetails(android: AndroidNotificationDetails('aqim_pre_prayer_${_channelVersion}_$channelSuffix', 'التنبيه قبل الصلاة', channelDescription: mode == 'alarm' ? 'منبه صوتي قبل الصلاة — ليس أذانًا' : mode == 'ringtone' ? 'تنبيه قبل الصلاة برنة الهاتف' : 'تنبيه قبل الصلاة بالاهتزاز فقط', importance: Importance.max, priority: Priority.max, category: AndroidNotificationCategory.alarm, fullScreenIntent: true, playSound: mode != 'vibrate', sound: selectedSound == null ? null : RawResourceAndroidNotificationSound(selectedSound), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));
    await _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: details);
  }

  Future<void> _scheduleFajrWakeAlarms({required DateTime prayerTime, required int beforeMinutes, required DateTime now}) async {
    if (beforeMinutes <= 0) return;

    // The selected X-minute window belongs entirely before Fajr. Spread the
    // three dedicated Fajr alarm sounds across that window, with the final
    // alarm immediately before the prayer time. The Fajr adhan itself remains
    // a separate notification scheduled exactly at prayerTime.
    final windowStart = prayerTime.subtract(Duration(minutes: beforeMinutes));
    final window = beforeMinutes;
    final offsets = <int>[0, window ~/ 2, window > 1 ? window - 1 : 0];
    final stages = <(int, String, String, int)>[
      (offsets[0], 'alarm_fajr_1', 'اقترب وقت الفجر', 0),
      (offsets[1], 'alarm_fajr_2', 'استعد لصلاة الفجر', 3),
      (offsets[2], 'alarm_fajr_3', 'حان الاستعداد الأخير لصلاة الفجر', 4),
    ];

    for (final stage in stages) {
      final scheduledDate = windowStart.add(Duration(minutes: stage.$1));
      if (!scheduledDate.isAfter(now) || !scheduledDate.isBefore(prayerTime)) continue;
      final remaining = prayerTime.difference(scheduledDate).inMinutes;
      await _scheduleWakeAlarm(
        id: _idFor(Prayer.fajr, stage.$4),
        title: stage.$3,
        body: 'تبقّى ${remaining.clamp(1, beforeMinutes)} دقيقة على صلاة الفجر.',
        scheduledDate: scheduledDate,
        soundName: stage.$2,
        payload: Prayer.fajr.name,
      );
    }
  }

  Future<void> _scheduleAdhan({required Prayer prayer, required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('adhan_alert_mode') ?? 'adhan';
    final selectedSound = prayer == Prayer.fajr ? ((prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') == 'azanfajrmadina' ? 'azan-Fajr-madina ' : (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr')) : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');
    final notificationSound = mode == 'adhan' ? selectedSound : null;
    final channelSuffix = mode == 'adhan' ? 'adhan_${prayer.name}_$selectedSound' : mode;
    await _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: NotificationDetails(android: AndroidNotificationDetails('aqim_adhan_${_channelVersion}_$channelSuffix', 'الأذان', channelDescription: mode == 'adhan' ? (prayer == Prayer.fajr ? 'أذان الفجر — المؤذن المختار للفجر' : 'أذان الصلوات الأخرى — المؤذن المختار') : mode == 'ringtone' ? 'تنبيه وقت الصلاة برنة الهاتف' : 'تنبيه وقت الصلاة بالاهتزاز فقط', importance: Importance.max, priority: Priority.max, category: AndroidNotificationCategory.alarm, fullScreenIntent: true, playSound: mode != 'vibrate', sound: notificationSound == null ? null : RawResourceAndroidNotificationSound(notificationSound), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public)));
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
    await _plugin.zonedSchedule(id: _weeklySummaryId, title: 'ملخص أسبوع أقم', body: text, scheduledDate: scheduled, notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('aqim_weekly_summary_v1', 'ملخص أسبوع أقم', channelDescription: 'ملخص أسبوعي لتقدم الصلاة', importance: Importance.defaultImportance, priority: Priority.defaultPriority, category: AndroidNotificationCategory.reminder, playSound: true)), androidScheduleMode: _scheduleMode, matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, payload: 'weekly_summary');
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
