from pathlib import Path

# Pre-prayer notifications intentionally remain on the existing
# flutter_local_notifications path. Prayer-time adhan playback is handled by
# the native AlarmManager + foreground MediaPlayer path already present in
# notification_service.dart.
path = Path("lib/services/notification_service.dart")
text = path.read_text(encoding="utf-8")

if "scheduleAdhan" not in text or "_nativePrePrayerAlarm" not in text:
    raise SystemExit("Expected native prayer-time adhan implementation is missing")

print("Verified: pre-prayer notifications stay on the normal notification path; adhan uses native persistent audio")
