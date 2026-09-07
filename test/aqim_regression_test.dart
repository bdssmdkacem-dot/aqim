import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aqim/models/prayer.dart';
import 'package:aqim/services/offline_prayer_times_service.dart';
import 'package:aqim/state/app_state.dart';
import 'package:aqim/state/app_state_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aqim prayer regression', () {
    test('keeps the five daily prayers in canonical order', () {
      final state = AppState();

      expect(state.activePrayers, const [
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]);
      expect(state.todayStatus.length, 5);
      expect(state.todayStatus.values, everyElement(PrayerStatus.pending));
    });

    test('offline prayer times return five ordered local times', () {
      final times = OfflinePrayerTimesService.calculateForDate(
        date: DateTime(2026, 9, 7),
        latitude: 30.4278,
        longitude: -9.5981,
      );

      expect(times, isNotNull);
      expect(times!.length, 5);
      final values = Prayer.values.map((prayer) => times[prayer]!).toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i].isAfter(values[i - 1]), isTrue,
            reason: 'Prayer times must remain chronological');
      }
    });

    test('completed prayer survives AppState persistence and reload', () async {
      SharedPreferences.setMockInitialValues({});
      final first = AppState();
      await first.init();

      expect(first.todayStatus[Prayer.fajr], PrayerStatus.pending);
      await first.markDone(Prayer.fajr);
      expect(first.todayStatus[Prayer.fajr], PrayerStatus.done);

      final second = AppState();
      await second.init();
      expect(second.todayStatus[Prayer.fajr], PrayerStatus.done);
    });
  });
}
