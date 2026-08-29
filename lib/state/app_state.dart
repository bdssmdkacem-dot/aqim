import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/notification_inbox_service.dart';
import '../services/offline_prayer_times_service.dart';
import '../services/prayer_times_service.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';

const List<Prayer> _allPrayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

class AppState extends ChangeNotifier {
  bool onboardingComplete = false;
  int currentWeek = 1;
  int weekDaysCompleted = 0;
  int streak = 0;
  String? lastOpenDate;
  final Map<Prayer, PrayerStatus> todayStatus = {for (final p in _allPrayers) p: PrayerStatus.pending};
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
  bool get notificationsActive => realTimes != null && notificationIssue == null && NotificationService.instance.notificationsPermissionGranted;
  double? get lastKnownLatitude => _prefs.getDouble('last_lat');
  double? get lastKnownLongitude => _prefs.getDouble('last_lng');
  List<Prayer> get activePrayers => _allPrayers;

  Prayer? get nextPrayer {
    final times = realTimes;
    if (times != null) {
      final now = DateTime.now();
      for (final p in activePrayers) {
        final status = todayStatus[p];
        final time = times[p];
        if (time == null || status == PrayerStatus.done || status == PrayerStatus.missed) continue;
        if (time.isAfter(now)) return p;
      }
      return Prayer.fajr;
    }
    for (final p in activePrayers) {
      if (todayStatus[p] == PrayerStatus.upcoming) return p;
    }
    return Prayer.fajr;
  }

  DateTime? get nextPrayerTime {
    final prayer = nextPrayer;
    if (prayer == null) return null;
    final time = _timeFor(prayer);
    if (time == null) return null;
    final now = DateTime.now();
    if (prayer == Prayer.fajr && !time.isAfter(now)) return time.add(const Duration(days: 1));
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
      final savedLat = _prefs.getDouble('last_lat');
      final savedLng = _prefs.getDouble('last_lng');

      // Always prefer a fresh GPS fix. The saved coordinates are only a
      // fallback for cases where location services/permission are unavailable.
      final position = await LocationService.getCurrentPosition();
      final lat = position?.latitude ?? savedLat;
      final lng = position?.longitude ?? savedLng;
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
      if (cityName != null && cityName!.trim().isNotEmpty) await _prefs.setString('city_name', cityName!);
      if (times == null) {
        notificationIssue = 'تعذّر جلب أو حساب أوقات الصلاة. أعد المحاولة.';
        timesLoading = false;
        notifyListeners();
        return;
      }
      realTimes = times;
      _recomputeUpcoming();
      try {
        await NotificationService.instance.init();
        await NotificationService.instance.refreshPermissionStatus();
        if (!NotificationService.instance.notificationsPermissionGranted) {
          final granted = await NotificationService.instance.requestNotificationsPermission();
          await NotificationService.instance.refreshPermissionStatus();
          if (granted && NotificationService.instance.notificationsPermissionGranted) {
            await NotificationService.instance.scheduleAllForToday(times, beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, adhanEnabled: adhanEnabled);
            await NotificationService.instance.scheduleWeeklySummary(_weeklySummaryText());
            notificationIssue = null;
            debugPrint('Notification permission granted and prayer notifications scheduled.');
          } else {
            notificationIssue = 'إشعارات أقم محظورة من إعدادات الهاتف. اسمح للتطبيق بإرسال الإشعارات ثم اضغط «إعادة المحاولة»."';
          }
        } else {
          await NotificationService.instance.scheduleAllForToday(times, beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, adhanEnabled: adhanEnabled);
          await NotificationService.instance.scheduleWeeklySummary(_weeklySummaryText());
          await NotificationService.instance.refreshPermissionStatus();
          notificationIssue = NotificationService.instance.notificationsPermissionGranted ? null : 'إشعارات أقم محظورة من إعدادات الهاتف. اسمح للتطبيق بإرسال الإشعارات ثم اضغط «إعادة المحاولة»."';
          debugPrint('Prayer notifications scheduled: ${NotificationService.instance.notificationsPermissionGranted}');
        }
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
      notificationIssue = enabled ? (realTimes == null ? 'جارٍ تحميل أوقات الصلاة.' : null) : 'إشعارات أقم محظورة من إعدادات الهاتف. اسمح للتطبيق بإرسال الإشعارات ثم اضغط «إعادة المحاولة»."';
    } catch (_) {
      notificationIssue = 'تعذّر التحقق من حالة الإشعارات. اضغط «إعادة المحاولة»."';
    }
    notifyListeners();
  }

  String _weeklySummaryText() {
    final recentSix = weekHistory.skip(1);
    final pastDaysTotal = recentSix.map((pct) => (pct / 100 * _allPrayers.length).round()).fold<int>(0, (a, b) => a + b);
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
      await NotificationService.instance.scheduleAllForToday(times, beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, adhanEnabled: adhanEnabled);
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
      await NotificationService.instance.scheduleAllForToday(times, beforeMinutes: beforeMinutes, afterMinutes: afterMinutes, adhanEnabled: adhanEnabled);
      await refreshNotificationStatus();
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
    cityName = _prefs.getString('city_name');
    final savedStatus = _prefs.getStringList('today_status');
    if (savedStatus != null && savedStatus.length == _allPrayers.length) {
      for (var i = 0; i < _allPrayers.length; i++) {
        todayStatus[_allPrayers[i]] = PrayerStatus.values.firstWhere((e) => e.name == savedStatus[i], orElse: () => PrayerStatus.pending);
      }
    }
    final savedHistory = _prefs.getStringList('history');
    if (savedHistory != null && savedHistory.length == 7) weekHistory = savedHistory.map(int.parse).toList();
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
          for (final p in _allPrayers) { if (p.name == kv[0]) { prayer = p; break; } }
          PrayerStatus? status;
          for (final s in PrayerStatus.values) { if (s.name == kv[1]) { status = s; break; } }
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
        for (final p in _allPrayers) { if (p.name == parts[0]) { missTally[p] = count; break; } }
      }
    }
    _rolloverIfNewDay();
    if (realTimes != null) _recomputeUpcoming();
    ready = true;
    _startClock();
    notifyListeners();
    unawaited(loadPrayerTimes());
    unawaited(PurchaseService.instance.init(onAdsRemoved: _markAdsRemoved));
    if (onboardingComplete) unawaited(ReviewService.instance.maybeRequestReview(currentWeek: currentWeek));
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final oldDate = lastOpenDate;
      final oldWeek = currentWeek;
      _rolloverIfNewDay();
      if (oldDate != lastOpenDate) await loadPrayerTimes();
      _recomputeUpcoming();
      if (currentWeek != oldWeek) unawaited(ReviewService.instance.maybeRequestReview(currentWeek: currentWeek));
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
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _rolloverIfNewDay() {
    final today = _todayKey;
    if (lastOpenDate == null) { lastOpenDate = today; return; }
    if (lastOpenDate != today) {
      final doneCount = _allPrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;
      final active = activePrayers;
      if (active.isNotEmpty) {
        final pct = (doneCount / active.length * 100).round();
        dailyHistory[lastOpenDate!] = pct;
        weekHistory = [...weekHistory.skip(1), pct];
      }
      for (final p in _allPrayers) {
        if (todayStatus[p] == PrayerStatus.missed) missTally[p] = (missTally[p] ?? 0) + 1;
      }
      dailyPrayerHistory[lastOpenDate!] = Map<Prayer, PrayerStatus>.from(todayStatus);
      _persistDailyHistory();
      _persistDailyPrayerHistory();
      final allDone = doneCount == active.length && active.isNotEmpty;
      if (allDone) {
        streak += 1;
        weekDaysCompleted += 1;
        if (streak > longestStreak) { longestStreak = streak; _prefs.setInt('longest_streak', longestStreak); }
        if (weekDaysCompleted >= 7 && currentWeek < 5) { currentWeek += 1; weekDaysCompleted = 0; }
      } else { streak = 0; }
      for (final p in _allPrayers) todayStatus[p] = PrayerStatus.pending;
      todayReasons.clear();
      lastOpenDate = today;
      _persist();
    }
  }

  DateTime? _timeFor(Prayer p) {
    final t = realTimes?[p];
    if (t != null) return t;
    final parts = p.mockTime.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  void _recomputeUpcoming() {
    final now = DateTime.now();
    var missedChanged = false;
    Prayer? next;
    for (final prayer in activePrayers) {
      final t = _timeFor(prayer);
      if (t == null) continue;
      if (t.isAfter(now)) { next = prayer; break; }
    }
    next ??= Prayer.fajr;
    for (final prayer in activePrayers) {
      final status = todayStatus[prayer];
      if (status == PrayerStatus.done || status == PrayerStatus.missed) continue;
      if (prayer == next) {
        todayStatus[prayer] = PrayerStatus.upcoming;
        continue;
      }
      final t = _timeFor(prayer);
      if (t != null && now.isAfter(t)) {
        todayStatus[prayer] = PrayerStatus.missed;
        missTally[prayer] = (missTally[prayer] ?? 0) + 1;
        missedChanged = true;
        final dateKey = _todayKey;
        unawaited(NotificationInboxService.instance.add(
          id: 'missed-prayer-$dateKey-${prayer.name}',
          title: 'صلاة فائتة: ${prayer.arabicName}',
          body: 'فات وقت ${prayer.arabicName}. اضغط هنا للانتقال مباشرة إلى تسجيل القضاء.',
          createdAt: now,
        ));
      } else {
        todayStatus[prayer] = PrayerStatus.pending;
      }
    }
    if (missedChanged) {
      _persist();
      unawaited(_persistMissTally());
    }
  }

  List<Prayer> get missedTodayPrayers => activePrayers.where((p) => todayStatus[p] == PrayerStatus.missed).toList();
  int get missedTodayCount => missedTodayPrayers.length;
  int get doneTodayCount => activePrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;
  bool get allTodayDone => activePrayers.isNotEmpty && doneTodayCount == activePrayers.length;

  void _persist() {
    _prefs.setBool('ob_complete', onboardingComplete);
    _prefs.setInt('week', currentWeek);
    _prefs.setInt('week_days_completed', weekDaysCompleted);
    _prefs.setInt('streak', streak);
    _prefs.setString('last_date', lastOpenDate ?? '');
    _prefs.setStringList('today_status', todayStatus.values.map((s) => s.name).toList());
    _prefs.setStringList('today_reasons', todayReasons.entries.map((e) => '${e.key.name}:${e.value}').toList());
    _prefs.setStringList('history', weekHistory.map((e) => e.toString()).toList());
    _prefs.setStringList('miss_tally', missTally.entries.map((e) => '${e.key.name}:${e.value}').toList());
  }

  Future<void> completeOnboarding() async { onboardingComplete = true; await _prefs.setBool('ob_complete', true); notifyListeners(); }
  void _persistDailyHistory() { _prefs.setStringList('daily_history', dailyHistory.entries.map((e) => '${e.key}:${e.value}').toList()); }
  void _persistDailyPrayerHistory() { _prefs.setStringList('daily_prayer_history', dailyPrayerHistory.entries.map((entry) => '${entry.key}|${entry.value.entries.map((e) => '${e.key.name}=${e.value.name}').join(',')}').toList()); }
  Future<void> _persistMissTally() async { await _prefs.setStringList('miss_tally', missTally.entries.map((e) => '${e.key.name}:${e.value}').toList()); }

  @override
  void dispose() { _clockTimer?.cancel(); super.dispose(); }
}