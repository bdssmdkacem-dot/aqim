from pathlib import Path

path = Path('lib/services/notification_service.dart')
text = path.read_text(encoding='utf-8')

old = """    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final entry in realTimes.entries) {"""
new = """    await _plugin.cancelAll();
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final prePrayerEnabled = prefs.getBool('pre_prayer_enabled') ?? true;
    final selectedPrePrayerPrayers = prefs.getStringList('pre_prayer_prayers') ??
        Prayer.values.map((p) => p.name).toList();
    for (final entry in realTimes.entries) {"""
if old not in text:
    raise SystemExit('scheduleAllForToday anchor not found')
text = text.replace(old, new, 1)

old = """      if (prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(finalAlarmTime: alarmTime, beforeMinutes: beforeMinutes, now: now);
      } else if (alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(id: _idFor(prayer, 0), title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}', body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.', scheduledDate: alarmTime, soundName: _wakeAlarmSoundFor(prayer, prayerTime), payload: prayer.name);
      }"""
new = """      final shouldSchedulePrePrayer =
          prePrayerEnabled && selectedPrePrayerPrayers.contains(prayer.name);
      if (shouldSchedulePrePrayer && prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(finalAlarmTime: alarmTime, beforeMinutes: beforeMinutes, now: now);
      } else if (shouldSchedulePrePrayer && alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(id: _idFor(prayer, 0), title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}', body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.', scheduledDate: alarmTime, soundName: _wakeAlarmSoundFor(prayer, prayerTime), payload: prayer.name);
      }"""
if old not in text:
    raise SystemExit('pre-prayer scheduling block not found')
text = text.replace(old, new, 1)

old = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async => _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: _alarmDetails(channelId: _alarmChannel(soundName), channelName: soundName == _jumuahAlarmSound ? 'منبّه صلاة الجمعة' : 'منبّه الاستعداد للصلاة', channelDescription: 'تنبيه صوتي قبل الصلاة — يعمل كمنبّه', soundName: soundName, category: AndroidNotificationCategory.alarm));"""
new = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('pre_prayer_alert_mode') ?? 'adhan';
    final selectedAdhan = prefs.getString('adhan_sound') ?? 'azan_maroc_1';
    final String? notificationSound;
    final bool playSound;
    final bool vibration;
    final String channelSuffix;
    switch (mode) {
      case 'ringtone':
        notificationSound = null;
        playSound = true;
        vibration = true;
        channelSuffix = 'ringtone';
        break;
      case 'vibrate':
        notificationSound = null;
        playSound = false;
        vibration = true;
        channelSuffix = 'vibrate';
        break;
      case 'adhan':
      default:
        notificationSound = selectedAdhan;
        playSound = true;
        vibration = true;
        channelSuffix = 'adhan_$selectedAdhan';
        break;
    }
    final channelId = 'aqim_pre_prayer_${_channelVersion}_$channelSuffix';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'التنبيه قبل الصلاة',
        channelDescription: mode == 'vibrate'
            ? 'تنبيه قبل الصلاة بالاهتزاز فقط'
            : mode == 'ringtone'
                ? 'تنبيه قبل الصلاة برنة الهاتف'
                : 'تنبيه قبل الصلاة بالأذان المختار',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: playSound,
        sound: notificationSound == null
            ? null
            : RawResourceAndroidNotificationSound(notificationSound),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        channelBypassDnd: notificationPolicyAccessGranted,
        enableVibration: vibration,
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
  }"""
if old not in text:
    raise SystemExit('wake alarm function not found')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('Applied Aqim pre-prayer notification preferences.')
