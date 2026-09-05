from pathlib import Path

path = Path('lib/services/notification_service.dart')
text = path.read_text(encoding='utf-8')

# This script is intentionally idempotent: the notification service may already
# contain part or all of the pre-prayer preference changes.

prefs_block = """    final prefs = await SharedPreferences.getInstance();
    final prePrayerEnabled = prefs.getBool('pre_prayer_enabled') ?? true;
    final selectedPrePrayers = (prefs.getStringList('pre_prayer_prayers') ??
        Prayer.values.map((p) => p.name).toList()).toSet();
"""

if 'final prePrayerEnabled = prefs.getBool(\'pre_prayer_enabled\')' not in text:
    anchor = """    await _plugin.cancelAll();
    final now = DateTime.now();
"""
    if anchor not in text:
        raise SystemExit('scheduleAllForToday preferences anchor not found')
    text = text.replace(anchor, anchor + prefs_block, 1)
    print('Added pre-prayer preference loading.')
else:
    print('Pre-prayer preference loading already present.')

required_schedule = """      if (prePrayerEnabled && selectedPrePrayers.contains(prayer.name)) {
"""
if required_schedule not in text:
    old_schedule = """      if (prayer == Prayer.fajr) {
          await _scheduleFajrWakeAlarms(finalAlarmTime: alarmTime, beforeMinutes: beforeMinutes, now: now);
        } else if (alarmTime.isAfter(now)) {
          await _scheduleWakeAlarm(id: _idFor(prayer, 0), title: isJumuah ? 'استعد لصلاة الجمعة' : 'استعد لصلاة ${prayer.arabicName}', body: isJumuah ? 'تبقّى $beforeMinutes دقيقة على صلاة الجمعة.' : 'تبقّى $beforeMinutes دقيقة على ${prayer.arabicName}.', scheduledDate: alarmTime, soundName: _wakeAlarmSoundFor(prayer, prayerTime), payload: prayer.name);
        }
"""
    if old_schedule in text:
        text = text.replace(old_schedule, required_schedule + old_schedule, 1)
        print('Added pre-prayer prayer-selection guard.')
    else:
        raise SystemExit('pre-prayer scheduling block not found')
else:
    print('Pre-prayer prayer-selection guard already present.')

# The wake-alarm function should use the pre-prayer mode. Accept both the
# original multiline form and the compact form used by the current source.
required_alarm_mode = "final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';"
if required_alarm_mode not in text:
    raise SystemExit('pre-prayer alert-mode implementation not found')
print('Pre-prayer alert-mode implementation verified.')

path.write_text(text, encoding='utf-8')
print('Pre-prayer notification settings verified successfully.')
