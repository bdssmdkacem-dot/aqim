import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer.dart';
import '../services/location_service.dart';
import '../services/prayer_times_service.dart';

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

  /// أوقات الصلاة الحقيقية لليوم (إن توفّر الموقع والإنترنت)، أو null
  /// لاستعمال الأوقات الاحتياطية الثابتة في Prayer.mockTime بدلاً منها.
  Map<Prayer, DateTime>? realTimes;
  bool timesLoading = false;

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

  /// الوقت المعروض لصلاة معيّنة: الوقت الحقيقي إن توفّر، وإلا الوقت
  /// الاحتياطي الثابت (Prayer.mockTime) كي لا تظهر الواجهة فارغة أبدًا.
  String displayTimeFor(Prayer p) {
    final real = realTimes?[p];
    if (real == null) return p.mockTime;
    final hh = real.hour.toString().padLeft(2, '0');
    final mm = real.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// يجلب أوقات الصلاة الحقيقية بناءً على موقع الهاتف. يُستدعى مرة عند
  /// إقلاع التطبيق (بلا حجب شاشة التحميل — يعمل فـ الخلفية وتتحدّث
  /// الواجهة تلقائيًا عند التوفّر). يفشل بهدوء ويُبقي الأوقات الاحتياطية
  /// إن تعذّر الوصول للموقع أو الإنترنت.
  Future<void> loadPrayerTimes() async {
    timesLoading = true;
    notifyListeners();

    final position = await LocationService.getCurrentPosition();
    final lat = position?.latitude ?? _prefs.getDouble('last_lat');
    final lng = position?.longitude ?? _prefs.getDouble('last_lng');

    if (position != null) {
      await _prefs.setDouble('last_lat', position.latitude);
      await _prefs.setDouble('last_lng', position.longitude);
    }

    if (lat != null && lng != null) {
      final times = await PrayerTimesService.fetchToday(latitude: lat, longitude: lng);
      if (times != null) {
        realTimes = times;
      }
    }

    timesLoading = false;
    notifyListeners();
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

    // لا ننتظر النتيجة هنا كي لا تتأخر شاشة الإقلاع؛ الواجهة تتحدّث
    // تلقائيًا (عبر notifyListeners داخل loadPrayerTimes) عند التوفّر.
    unawaited(loadPrayerTimes());
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
