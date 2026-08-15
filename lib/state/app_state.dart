import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/offline_prayer_times_service.dart';
import '../services/prayer_times_service.dart';
import '../services/purchase_service.dart';

const List<Prayer> _allPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

class AppState extends ChangeNotifier {
  bool onboardingComplete = false;
  int currentWeek = 1;
  int weekDaysCompleted = 0;
  int streak = 0;
  String? lastOpenDate;

  final Map<Prayer, PrayerStatus> todayStatus = {
    for (final p in _allPrayers) p: PrayerStatus.pending,
  };
  final Map<Prayer, String> todayReasons = {};
  final Map<Prayer, int> missTally = {for (final p in _allPrayers) p: 0};
  List<int> weekHistory = [0, 0, 0, 0, 0, 0, 0];
  final Map<String, int> dailyHistory = {};
  final Map<String, Map<Prayer, PrayerStatus>> dailyPrayerHistory = {};
  int longestStreak = 0;

  late SharedPreferences _prefs;
  Timer? _clockTimer;
  bool ready = false;
  Map<Prayer, DateTime>? realTimes;
  bool timesLoading = false;
  int beforeMinutes = 10;
  int afterMinutes = 20;
  bool adhanEnabled = true;
  bool adsRemoved = false;
  bool batteryPromptShown = false;
  String? cityName;
  String? notificationIssue;
  bool get notificationsActive =>
      realTimes != null &&
      notificationIssue == null &&
      NotificationService.instance.notificationsPermissionGranted;
  double? get lastKnownLatitude => _prefs.getDouble('last_lat');
  double? get lastKnownLongitude => _prefs.getDouble('last_lng');
  List<Prayer> get activePrayers => _allPrayers;

  Prayer? get nextPrayer {
    for (final p in activePrayers) {
      final s = todayStatus[p];
      if (s == PrayerStatus.pending || s == PrayerStatus.upcoming) return p;
    }
    // After Isha, today's Fajr is not a future prayer. The next prayer is
    // Fajr tomorrow; nextPrayerTime below supplies tomorrow's DateTime.
    return Prayer.fajr;
  }

  DateTime? get nextPrayerTime {
    final prayer = nextPrayer;
    if (prayer == null) return null;
    final time = _timeFor(prayer);
    if (time == null) return null;
    final now = DateTime.now();
    if (prayer == Prayer.fajr && !time.isAfter(now)) {
      return time.add(const Duration(days: 1));
    }
    return time;
  }

  bool get nextPrayerIsTomorrow {
    final prayer = nextPrayer;
    final time = prayer == null ? null : _timeFor(prayer);
    return prayer == Prayer.fajr && time != null && !time.isAfter(DateTime.now());
  }

  String displayTimeFor(Prayer p) {
    final real = realTimes?[p];
    if (real == null) return p.mockTime;
    final hh = real.hour.toString().padLeft(2, '0');
    final mm = real.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool usingOfflineTimes = false;

  Future<void> loadPrayerTimes() async {
    timesLoading = true;
    notifyListeners();
    try {
      final position = await LocationService.getCurrentPosition();
      final lat = position?.latitude ?? _prefs.getDouble('last_lat');
      final lng = position?.longitude ?? _prefs.getDouble('last_lng');
      if (position != null) {
        await _prefs.setDouble('last_lat', position.latitude);
        await _prefs.setDouble('last_lng', position.longitude);
      }
      if (lat == null || lng == null) {
        notificationIssue = 'تعذّر تحديد موقعك — تأكد من تفعيل خدمة الموقع ومنح صلاحية الوصول له.';
        timesLoading = false;
        notifyListeners();
        return;
      }
      final cityFuture = GeocodingService.cityFor(latitude: lat, longitude: lng);
      var times = await PrayerTimesService.fetchToday(latitude: lat, longitude: lng);
      usingOfflineTimes = false;
      if (times == null) {
        times = OfflinePrayerTimesService.calculateToday(latitude: lat, longitude: lng);
        usingOfflineTimes = times != null;
      }
      cityName = await cityFuture;
      if (times == null) {
        notificationIssue = 'تعذّر جلب أو حساب أوقات الصلاة. أعد المحاولة.';
        timesLoading = false;
        notifyListeners();
        return;
      }

      realTimes = times;
      _recomputeUpcoming();

      // جدولة الإشعارات أصبحت مستقلة عن صلاحية المنبّه الدقيق؛ الخدمة
      // تستخدم exact عند توفره وتعود تلقائيًا إلى inexact عند عدم توفره.
      try {
        await NotificationService.instance.scheduleAllForToday(
          times,
          beforeMinutes: beforeMinutes,
          afterMinutes: afterMinutes,
          adhanEnabled: adhanEnabled,
        );
        await NotificationService.instance.scheduleWeeklySummary(_weeklySummaryText());
        final enabled = await NotificationService.instance.areNotificationsEnabled();
        notificationIssue = enabled
            ? null
            : 'إشعارات أقم محظورة من إعدادات الهاتف. اسمح للتطبيق بإرسال الإشعارات ثم اضغط «إعادة المحاولة»."';
        debugPrint('Prayer notifications scheduled: $enabled');
      } catch (error) {
        notificationIssue = 'تعذّر جدولة الإشعارات. تحقق من صلاحية الإشعارات وإعدادات البطارية ثم أعد المحاولة.';
        debugPrint('Notification scheduling failed: $error');
      }
    } catch (error) {
      notificationIssue = 'تعذّر تحديث أوقات الصلاة والإشعارات. أعد المحاولة.';
      debugPrint('Prayer times load failed: $error');
    } finally {
      timesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotificationStatus() async {
    try {
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      if (enabled) {
        notificationIssue = realTimes == null ? 'جارٍ تحميل أوقات الصلاة.' : null;
      } else {
        notificationIssue = 'إشعارات أقم محظورة من إعدادات الهاتف. اسمح للتطبيق بإرسال الإشعارات ثم أعد المحاولة.';
      }
    } catch (_) {
      notificationIssue = 'تعذّر التحقق من حالة الإشعارات. اضغط «إعادة المحاولة»."';
    }
    notifyListeners();
  }

  String _weeklySummaryText() {
    final recentSix = weekHistory.skip(1);
    final pastDaysTotal = recentSix
        .map((pct) => (pct / 100 * _allPrayers.length).round())
        .fold<int>(0, (a, b) => a + b);
    final todayDone = activePrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;
    final total = pastDaysTotal + todayDone;
    const max = 7 * 5;
    return 'أتممت $total من $max صلاة هذا الأسبوع 🌙';
  }

  Future<void> updateReminderTiming({int? before, int? after}) async {
    if (before != null) beforeMinutes = before;
    if (after != null) afterMinutes = after;
    await _prefs.setInt('before_minutes', beforeMinutes);
    await _prefs.setInt('after_minutes', afterMinutes);
    notifyListeners();
    final times = realTimes;
    if (times != null) {
      await NotificationService.instance.scheduleAllForToday(
        times,
        beforeMinutes: beforeMinutes,
        afterMinutes: afterMinutes,
        adhanEnabled: adhanEnabled,
      );
      await NotificationService.instance.scheduleWeeklySummary(_weeklySummaryText());
      await refreshNotificationStatus();
    } else {
      await loadPrayerTimes();
    }
  }

  Future<void> setAdhanEnabled(bool value) async {
    adhanEnabled = value;
    await _prefs.setBool('adhan_enabled', value);
    notifyListeners();
    final times = realTimes;
    if (times != null) {
      await NotificationService.instance.scheduleAllForToday(
        times,
        beforeMinutes: beforeMinutes,
        afterMinutes: afterMinutes,
        adhanEnabled: adhanEnabled,
      );
      await refreshNotificationStatus();
    } else {
      await loadPrayerTimes();
    }
  }

  Future<void> markBatteryPromptShown() async {
    batteryPromptShown = true;
    await _prefs.setBool('battery_prompt_shown', true);
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
    final savedDaily = _prefs.getStringList('daily_history');
    if (savedDaily != null) {
      for (final entry in savedDaily) {
        final idx = entry.lastIndexOf(':');
        if (idx == -1) continue;
        final date = entry.substring(0, idx);
        final pct = int.tryParse(entry.substring(idx + 1));
        if (pct != null) dailyHistory[date] = pct;
      }
    }
    final savedDailyPrayers = _prefs.getStringList('daily_prayer_history');
    if (savedDailyPrayers != null) {
      for (final entry in savedDailyPrayers) {
        final sepIdx = entry.indexOf('|');
        if (sepIdx == -1) continue;
        final date = entry.substring(0, sepIdx);
        final statuses = <Prayer, PrayerStatus>{};
        for (final pair in entry.substring(sepIdx + 1).split(',')) {
          final kv = pair.split('=');
          if (kv.length != 2) continue;
          Prayer? prayer;
          for (final p in _allPrayers) {
            if (p.name == kv[0]) {
              prayer = p;
              break;
            }
          }
          PrayerStatus? status;
          for (final s in PrayerStatus.values) {
            if (s.name == kv[1]) {
              status = s;
              break;
            }
          }
          if (prayer != null && status != null) statuses[prayer] = status;
        }
        if (statuses.isNotEmpty) dailyPrayerHistory[date] = statuses;
      }
    }
    longestStreak = _prefs.getInt('longest_streak') ?? 0;
    beforeMinutes = _prefs.getInt('before_minutes') ?? 10;
    afterMinutes = _prefs.getInt('after_minutes') ?? 20;
    adhanEnabled = _prefs.getBool('adhan_enabled') ?? true;
    adsRemoved = _prefs.getBool('ads_removed') ?? false;
    batteryPromptShown = _prefs.getBool('battery_prompt_shown') ?? false;
    final savedTally = _prefs.getStringList('miss_tally');
    if (savedTally != null) {
      for (final entry in savedTally) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        final count = int.tryParse(parts[1]);
        if (count == null) continue;
        for (final p in _allPrayers) {
          if (p.name == parts[0]) {
            missTally[p] = count;
            break;
          }
        }
      }
    }
    _rolloverIfNewDay();
    _recomputeUpcoming();
    ready = true;
    _startClock();
    notifyListeners();
    unawaited(loadPrayerTimes());
    unawaited(PurchaseService.instance.init(onAdsRemoved: _markAdsRemoved));
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final oldDate = lastOpenDate;
      _rolloverIfNewDay();
      if (oldDate != lastOpenDate) await loadPrayerTimes();
      _recomputeUpcoming();
      notifyListeners();
    });
  }

  void _markAdsRemoved() {
    adsRemoved = true;
    _prefs.setBool('ads_removed', true);
    notifyListeners();
  }

  Future<void> buyRemoveAds() => PurchaseService.instance.buyRemoveAds();
  Future<void> restorePurchases() => PurchaseService.instance.restorePurchases();
  String get removeAdsPriceLabel => PurchaseService.instance.removeAdsProduct?.price ?? '\$19';

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
      final active = activePrayers;
      final doneCount = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      final pct = active.isEmpty ? 0 : ((doneCount / active.length) * 100).round();
      weekHistory = [...weekHistory.skip(1), pct];
      dailyHistory[lastOpenDate!] = pct;
      dailyPrayerHistory[lastOpenDate!] = Map.of(todayStatus);
      _persistDailyHistory();
      _persistDailyPrayerHistory();
      final allDone = doneCount == active.length && active.isNotEmpty;
      if (allDone) {
        streak += 1;
        weekDaysCompleted += 1;
        if (streak > longestStreak) {
          longestStreak = streak;
          _prefs.setInt('longest_streak', longestStreak);
        }
        if (weekDaysCompleted >= 7 && currentWeek < 5) {
          currentWeek += 1;
          weekDaysCompleted = 0;
        }
      } else {
        streak = 0;
      }
      for (final p in _allPrayers) todayStatus[p] = PrayerStatus.pending;
      todayReasons.clear();
      lastOpenDate = today;
      _persist();
    }
  }

  DateTime? _timeFor(Prayer p) {
    final real = realTimes?[p];
    if (real != null) return real;
    final parts = p.mockTime.split(':');
    if (parts.length != 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hh, mm);
  }

  void _recomputeUpcoming() {
    final now = DateTime.now();
    var missedChanged = false;
    Prayer? nextToday;

    // A prayer is today's upcoming prayer only while its time is still in the future.
    for (final prayer in activePrayers) {
      final t = _timeFor(prayer);
      if (t == null) continue;
      if (t.isAfter(now)) {
        nextToday = prayer;
        break;
      }
    }

    for (final prayer in activePrayers) {
      final status = todayStatus[prayer];
      if (status == PrayerStatus.done || status == PrayerStatus.missed) continue;

      final t = _timeFor(prayer);
      final elapsed = t != null && !t.isAfter(now);

      if (prayer == nextToday) {
        todayStatus[prayer] = PrayerStatus.upcoming;
        continue;
      }

      if (elapsed) {
        todayStatus[prayer] = PrayerStatus.missed;
        missTally[prayer] = (missTally[prayer] ?? 0) + 1;
        missedChanged = true;
      } else {
        todayStatus[prayer] = PrayerStatus.pending;
      }
    }

    if (missedChanged) {
      unawaited(_persist());
      unawaited(_persistMissTally());
    }
  }

  List<Prayer> get missedTodayPrayers => activePrayers.where((p) => todayStatus[p] == PrayerStatus.missed).toList();
  int get missedTodayCount => missedTodayPrayers.length;
  int get doneTodayCount => activePrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;
  bool get allTodayDone => activePrayers.isNotEmpty && doneTodayCount == activePrayers.length;
  Future<void> markQada(Prayer p) => markDone(p);

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await _prefs.setBool('ob_complete', true);
    notifyListeners();
  }

  Future<void> markDone(Prayer p) async {
    todayStatus[p] = PrayerStatus.done;
    await NotificationService.instance.cancelMissedPrayer(p);
    _recomputeUpcoming();
    await _persist();
    notifyListeners();
  }

  Future<void> markMissed(Prayer p, String reason) async {
    final alreadyMissed = todayStatus[p] == PrayerStatus.missed;
    todayStatus[p] = PrayerStatus.missed;
    todayReasons[p] = reason;
    if (!alreadyMissed) missTally[p] = (missTally[p] ?? 0) + 1;
    _recomputeUpcoming();
    await _persist();
    await _persistMissTally();
    notifyListeners();
  }

  Prayer? get weakestPrayer {
    Prayer? worst;
    var worstCount = 0;
    for (final entry in missTally.entries) {
      if (entry.value > worstCount) {
        worst = entry.key;
        worstCount = entry.value;
      }
    }
    return worst;
  }

  int? get overallCommitmentPercent {
    final active = activePrayers;
    final todayDone = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
    final todayPct = active.isEmpty ? 0 : ((todayDone / active.length) * 100).round();
    final allValues = [...dailyHistory.values, todayPct];
    if (allValues.isEmpty) return null;
    return (allValues.reduce((a, b) => a + b) / allValues.length).round();
  }

  int? percentForDate(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (key == _todayKey) {
      final active = activePrayers;
      final doneCount = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      return active.isEmpty ? 0 : ((doneCount / active.length) * 100).round();
    }
    return dailyHistory[key];
  }

  Map<Prayer, PrayerStatus>? prayerStatusForDate(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (key == _todayKey) return todayStatus;
    return dailyPrayerHistory[key];
  }

  Future<void> _persistMissTally() async {
    await _prefs.setStringList('miss_tally', missTally.entries.map((e) => '${e.key.name}:${e.value}').toList());
  }

  Future<void> _persistDailyHistory() async {
    await _prefs.setStringList('daily_history', dailyHistory.entries.map((e) => '${e.key}:${e.value}').toList());
  }

  Future<void> _persistDailyPrayerHistory() async {
    await _prefs.setStringList('daily_prayer_history', dailyPrayerHistory.entries.map((e) {
      final statusesText = e.value.entries.map((s) => '${s.key.name}=${s.value.name}').join(',');
      return '${e.key}|$statusesText';
    }).toList());
  }

  Future<void> _persist() async {
    await _prefs.setInt('week', currentWeek);
    await _prefs.setInt('week_days_completed', weekDaysCompleted);
    await _prefs.setInt('streak', streak);
    await _prefs.setString('last_date', lastOpenDate ?? _todayKey);
    await _prefs.setStringList('today_status', _allPrayers.map((p) => todayStatus[p]!.name).toList());
    await _prefs.setStringList('history', weekHistory.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
