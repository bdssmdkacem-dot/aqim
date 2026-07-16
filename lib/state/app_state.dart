import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer.dart';

const List<Prayer> _allPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// حالة التطبيق: يدير الأسبوع الحالي، صلوات اليوم، السلسلة المتتالية،
/// وسجل الأسبوع. البيانات تُحفظ محليًا عبر SharedPreferences فقط
/// (لا يوجد اتصال بخادم في هذه النسخة التجريبية).
class AppState extends ChangeNotifier {
  bool onboardingComplete = false;
  int currentWeek = 1; // 1..5
  int weekDaysCompleted = 0; // أيام كاملة في الأسبوع الحالي (هدف 7)
  int streak = 0;
  String? lastOpenDate;

  final Map<Prayer, PrayerStatus> todayStatus = {
    for (final p in _allPrayers) p: PrayerStatus.pending,
  };
  final Map<Prayer, String> todayReasons = {};

  /// نسب إنجاز آخر سبعة أيام (٪) لعرضها في لوحة الحياة، الأقدم أولًا.
  List<int> weekHistory = [70, 100, 60, 100, 80, 40, 0];

  late SharedPreferences _prefs;
  bool ready = false;

  /// الصلوات المُفعَّلة هذا الأسبوع بحسب مبدأ البناء التدريجي للعادة.
  List<Prayer> get activePrayers => _allPrayers.take(_activeCountForWeek(currentWeek)).toList();

  int _activeCountForWeek(int week) => week.clamp(1, 5);

  Prayer? get nextPrayer {
    for (final p in activePrayers) {
      final s = todayStatus[p];
      if (s == PrayerStatus.pending || s == PrayerStatus.upcoming) return p;
    }
    return null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    onboardingComplete = _prefs.getBool('ob_complete') ?? false;
    currentWeek = _prefs.getInt('week') ?? 1;
    weekDaysCompleted = _prefs.getInt('week_days_completed') ?? 0;
    streak = _prefs.getInt('streak') ?? 0;
    lastOpenDate = _prefs.getString('last_date');

    final savedStatus = _prefs.getStringList('today_status');
    if (savedStatus != null && savedStatus.length == _allPrayers.length) {
      for (var i = 0; i < _allPrayers.length; i++) {
        todayStatus[_allPrayers[i]] = PrayerStatus.values.firstWhere(
          (e) => e.name == savedStatus[i],
          orElse: () => PrayerStatus.pending,
        );
      }
    }
    final savedHistory = _prefs.getStringList('history');
    if (savedHistory != null && savedHistory.length == 7) {
      weekHistory = savedHistory.map(int.parse).toList();
    }

    _rolloverIfNewDay();
    _recomputeUpcoming();
    ready = true;
    notifyListeners();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _rolloverIfNewDay() {
    final today = _todayKey;
    if (lastOpenDate == null) {
      lastOpenDate = today;
      _persist();
      return;
    }
    if (lastOpenDate != today) {
      // أغلق يوم الأمس: احسب نسبة الإنجاز وادفعها إلى السجل الأسبوعي.
      final active = activePrayers;
      final doneCount = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      final pct = active.isEmpty ? 0 : ((doneCount / active.length) * 100).round();
      weekHistory = [...weekHistory.skip(1), pct];

      final allDone = doneCount == active.length && active.isNotEmpty;
      if (allDone) {
        streak += 1;
        weekDaysCompleted += 1;
        if (weekDaysCompleted >= 7 && currentWeek < 5) {
          currentWeek += 1;
          weekDaysCompleted = 0;
        }
      } else {
        streak = 0;
        // لا نُصفّر تقدم الأسبوع لتفويت يوم واحد، لكن لا نحتسبه ضمن الأيام المكتملة.
      }

      for (final p in _allPrayers) {
        todayStatus[p] = PrayerStatus.pending;
      }
      todayReasons.clear();
      lastOpenDate = today;
      _persist();
    }
  }

  void _recomputeUpcoming() {
    var foundUpcoming = false;
    for (final p in activePrayers) {
      final s = todayStatus[p];
      if (s == PrayerStatus.done || s == PrayerStatus.missed) continue;
      if (!foundUpcoming) {
        todayStatus[p] = PrayerStatus.upcoming;
        foundUpcoming = true;
      } else {
        todayStatus[p] = PrayerStatus.pending;
      }
    }
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await _prefs.setBool('ob_complete', true);
    notifyListeners();
  }

  Future<void> markDone(Prayer p) async {
    todayStatus[p] = PrayerStatus.done;
    _recomputeUpcoming();
    await _persist();
    notifyListeners();
  }

  Future<void> markMissed(Prayer p, String reason) async {
    todayStatus[p] = PrayerStatus.missed;
    todayReasons[p] = reason;
    _recomputeUpcoming();
    await _persist();
    notifyListeners();
  }

  /// أضعف صلاة هذا الأسبوع (الأكثر فوتًا) لعرضها في الملاحظة الذكية.
  Prayer? get weakestPrayer {
    final missed = todayReasons.keys.toList();
    if (missed.isEmpty) return null;
    return missed.first;
  }

  Future<void> _persist() async {
    await _prefs.setInt('week', currentWeek);
    await _prefs.setInt('week_days_completed', weekDaysCompleted);
    await _prefs.setInt('streak', streak);
    await _prefs.setString('last_date', lastOpenDate ?? _todayKey);
    await _prefs.setStringList(
      'today_status',
      _allPrayers.map((p) => todayStatus[p]!.name).toList(),
    );
    await _prefs.setStringList('history', weekHistory.map((e) => e.toString()).toList());
  }
}
