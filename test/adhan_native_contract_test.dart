import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Adhan native service resolves Flutter assets and has robust cleanup',
    () {
      final source = File(
        'android/app/src/main/kotlin/com/aqim/app/AdhanAlarmService.kt',
      ).readAsStringSync();

      expect(source, contains('flutter_assets/assets/adhan/'));
      expect(source, contains('assets/adhan/'));
      expect(source, contains('setAudioAttributes'));
      expect(source, contains('USAGE_ALARM'));
      expect(source, contains('releasePlayer()'));
    },
  );

  test('Adhan native scheduler uses exact alarms when available', () {
    final source = File(
      'android/app/src/main/kotlin/com/aqim/app/AdhanAlarmScheduler.kt',
    ).readAsStringSync();

    expect(source, contains('canScheduleExactAlarms()'));
    expect(source, contains('setAlarmClock('));
    expect(source, contains('setAndAllowWhileIdle('));
  });

  test('system time refresh does not pre-delete stored Adhan alarms', () {
    final source = File(
      'android/app/src/main/kotlin/com/aqim/app/AdhanAlarmScheduler.kt',
    ).readAsStringSync();
    final methodStart = source.indexOf('fun requestSystemTimeReschedule');
    final methodEnd = source.indexOf('fun scheduleMaintenance', methodStart);

    expect(methodStart, greaterThanOrEqualTo(0));
    expect(methodEnd, greaterThan(methodStart));
    final method = source.substring(methodStart, methodEnd);
    expect(method, isNot(contains('cancelAllStoredAlarms(context)')));
    expect(method, contains('refreshCurrentDayAsync(context)'));
  });

  test('Android manifest declares media playback foreground services', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('FOREGROUND_SERVICE'));
    expect(manifest, contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK'));
    expect(
      manifest,
      contains('android:foregroundServiceType="mediaPlayback"'),
    );
    expect(manifest, contains('.AdhanAlarmService'));
    expect(manifest, contains('.PrePrayerAlarmService'));
  });
}
