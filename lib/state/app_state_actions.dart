import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer.dart';
import '../services/notification_inbox_service.dart';
import '../services/notification_service.dart';
import 'app_state.dart';

/// UI-facing actions kept separate from the core state implementation.
/// This avoids changing prayer scheduling/persistence logic while restoring
/// the public actions used by the existing screens.
extension AppStateActions on AppState {
  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ob_complete', true);
    notifyListeners();
  }

  Future<void> markDone(Prayer prayer) async {
    todayStatus[prayer] = PrayerStatus.done;
    todayReasons.remove(prayer);
    await _persistActions();
    notifyListeners();
  }

  /// Marks a prayer that was already missed as performed/qada exactly once.
  /// It is deliberately idempotent: a prayer that is no longer missed cannot
  /// increment any tally or create another completion.
  Future<void> markQada(Prayer prayer) async {
    if (todayStatus[prayer] != PrayerStatus.missed) return;

    todayStatus[prayer] = PrayerStatus.done;
    todayReasons.remove(prayer);
    await _persistActions();

    final now = DateTime.now();
    final dateKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await NotificationInboxService.instance.removeMissedPrayer(dateKey, prayer.name);
    await NotificationService.instance.cancelMissedPrayer(prayer);
    notifyListeners();
  }

  Future<void> markMissed(Prayer prayer, String reason) async {
    todayStatus[prayer] = PrayerStatus.missed;
    todayReasons[prayer] = reason;
    missTally[prayer] = (missTally[prayer] ?? 0) + 1;
    await _persistActions();
    notifyListeners();
  }

  int? percentForDate(DateTime date) {
    final key = _dateKey(date);
    if (key == _dateKey(DateTime.now())) {
      final active = activePrayers;
      if (active.isEmpty) return 0;
      final done = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      return ((done / active.length) * 100).round();
    }
    return dailyHistory[key];
  }

  Prayer? get weakestPrayer {
    Prayer? weakest;
    var lowest = double.infinity;
    for (final prayer in activePrayers) {
      var total = 0;
      var done = 0;
      for (final statuses in dailyPrayerHistory.values) {
        final status = statuses[prayer];
        if (status == null) continue;
        total++;
        if (status == PrayerStatus.done) done++;
      }
      final todayStatusValue = todayStatus[prayer];
      if (todayStatusValue != null) {
        total++;
        if (todayStatusValue == PrayerStatus.done) done++;
      }
      final score = total == 0 ? 1.0 : done / total;
      if (score < lowest) {
        lowest = score;
        weakest = prayer;
      }
    }
    return weakest;
  }

  int get missedTodayCount =>
      todayStatus.values.where((status) => status == PrayerStatus.missed).length;

  List<Prayer> get missedTodayPrayers =>
      activePrayers.where((p) => todayStatus[p] == PrayerStatus.missed).toList();

  Future<void> _persistActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'today_status',
      activePrayers.map((p) => (todayStatus[p] ?? PrayerStatus.pending).name).toList(),
    );
    await prefs.setStringList(
      'today_reasons',
      todayReasons.entries.map((e) => '${e.key.name}:${e.value}').toList(),
    );
    await prefs.setStringList(
      'miss_tally',
      missTally.entries.map((e) => '${e.key.name}:${e.value}').toList(),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
