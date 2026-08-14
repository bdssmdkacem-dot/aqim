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

  /// عدد مرات فوات كل صلاة (تراكمي، محفوظ محليًا) — أساس ملاحظة "الصلاة
  /// الأكثر فوتًا"، بدل الاعتماد على فوات اليوم فقط.
  final Map<Prayer, int> missTally = {for (final p in _allPrayers) p: 0};

  /// نسب إنجاز آخر سبعة أيام (٪) لعرضها في لوحة الحياة، الأقدم أولًا.
  /// تبدأ بالصفر لمستخدم جديد فعليًا (لا بيانات وهمية).
  List<int> weekHistory = [0, 0, 0, 0, 0, 0, 0];

  /// سجل يومي كامل: تاريخ ("yyyy-MM-dd") → نسبة الإنجاز (٪) — أساس
  /// شاشة "تتبع" (التقويم الشهري). يبدأ فارغًا ويتراكم يومًا بيوم.
  final Map<String, int> dailyHistory = {};


  /// سجل يومي مفصّل لكل صلاة: تاريخ ("yyyy-MM-dd") → حالة كل صلاة
  /// (تمّت/فائتة/إلخ) — أساس تفاصيل اليوم عند الضغط على تاريخ فـ تقويم
  /// شاشة "تتبع". يُسجَّل تلقائيًا عند انتقال اليوم (rollover)، قبل
  /// تصفير todayStatus لليوم الجديد.
  final Map<String, Map<Prayer, PrayerStatus>> dailyPrayerHistory = {};


  /// أطول سلسلة أيام متتالية مُتمَّة بالكامل، سُجِّلت يومًا ما (قد تكون
  /// أكبر من streak الحالي إن انقطعت السلسلة).
  int longestStreak = 0;

  late SharedPreferences _prefs;
  Timer? _clockTimer;
  bool ready = false;

  /// أوقات الصلاة الحقيقية لليوم (إن توفّر الموقع والإنترنت)، أو null
  /// لاستعمال الأوقات الاحتياطية الثابتة في Prayer.mockTime بدلاً منها.
  Map<Prayer, DateTime>? realTimes;
  bool timesLoading = false;

  /// توقيت التذكيرات القابل للتخصيص من شاشة الإعدادات.
  int beforeMinutes = 10;
  int afterMinutes = 20;
  bool adhanEnabled = true;
  bool adsRemoved = false;

  bool batteryPromptShown = false;

  /// اسم المدينة المكتشفة من الموقع (لعرضها للمستخدم وللتأكد أن التطبيق
  /// حدّد موقعه صح).
  String? cityName;

  /// سبب عدم عمل الإشعارات حاليًا (null = تعمل بشكل طبيعي). يُعرض فـ
  /// شاشة الإعدادات مع زر إعادة المحاولة، بدل فشل صامت لا يفهمه المستخدم.
  String? notificationIssue;

  bool get notificationsActive => realTimes != null && notificationIssue == null;

  double? get lastKnownLatitude => _prefs.getDouble('last_lat');
  double? get lastKnownLongitude => _prefs.getDouble('last_lng');

  /// الصلوات المُفعَّلة اليوم. مفعّلة كلها من اليوم الأول (بدل الفتح
  /// التدريجي أسبوعًا بأسبوع) — البنية التحتية للسلسلة/الأسبوع (streak،
  /// weekDaysCompleted) باقية شغّالة كعدّاد تحفيزي، لكنها لم تعد تتحكم
  /// فـ عدد الصلوات الظاهرة.
  List<Prayer> get activePrayers => _allPrayers;

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

  /// true إن كانت الأوقات الحالية محسوبة محليًا (بلا إنترنت) بدل
  /// المصدر الرسمي عبر الإنترنت — تُعرض ملاحظة صغيرة للمستخدم فـ هذه
  /// الحالة (راجع شاشة الإعدادات).
  bool usingOfflineTimes = false;

  /// يجلب أوقات الصلاة الحقيقية واسم المدينة بناءً على موقع الهاتف،
  /// ويُفعّل الإشعارات إن نجح. يُستدعى مرة عند إقلاع التطبيق (بلا حجب
  /// شاشة التحميل)، ويمكن استدعاؤه يدويًا (زر "إعادة المحاولة" فـ
  /// الإعدادات) إن فشل أول مرة. يسجّل السبب فـ notificationIssue بدل
  /// الفشل الصامت.
  ///
  /// **يعمل بلا إنترنت بالكامل** إن توفّر الموقع: يحاول أولًا المصدر
  /// الرسمي عبر الإنترنت (طريقة الأوقاف المغربية)، وإن تعذّر (بلا شبكة)
  /// يحسب الأوقات محليًا على الهاتف عبر معادلات فلكية قياسية بدل
  /// التعطّل — الفرق عادة دقائق قليلة فقط.
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

    if (lat == null || lng == null) {
      notificationIssue = 'تعذّر تحديد موقعك — تأكد من تفعيل خدمة الموقع ومنح صلاحية الوصول له.';
      timesLoading = false;
      notifyListeners();
      return;
    }

    // نجلب المدينة والأوقات معًا؛ فشل المدينة وحدها لا يوقف الإشعارات.
    final cityFuture = GeocodingService.cityFor(latitude: lat, longitude: lng);
    var times = await PrayerTimesService.fetchToday(latitude: lat, longitude: lng);
    usingOfflineTimes = false;

    if (times == null) {
      // بلا إنترنت أو الخادم غير متاح — نحسب محليًا بدل التعطّل.
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
    notificationIssue = null;

    _recomputeUpcoming();

    await NotificationService.instance.scheduleAllForToday(
      times,
      beforeMinutes: beforeMinutes,
      afterMinutes: afterMinutes,
      adhanEnabled: adhanEnabled,
    );
    await NotificationService.instance.scheduleWeeklySummary(_weeklySummaryText());
debugPrint("Prayer notifications scheduled");
    timesLoading = false;
    notifyListeners();
  }

  /// نص الملخص الأسبوعي: نافذة متحركة من آخر ٧ أيام (٦ أيام سابقة من
  /// السجل + اليوم الحالي)، من إجمالي ٣٥ صلاة (٧ أيام × ٥ صلوات).
  String _weeklySummaryText() {
    final recentSix = weekHistory.skip(1); // أحدث ٦ أيام من السجل (يُستثنى الأقدم)
    final pastDaysTotal = recentSix
        .map((pct) => (pct / 100 * _allPrayers.length).round())
        .fold<int>(0, (a, b) => a + b);
    final todayDone = activePrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;
    final total = pastDaysTotal + todayDone;
    const max = 7 * 5;
    return 'أتممت $total من $max صلاة هذا الأسبوع 🌙';
  }

  /// يحدّث توقيت التذكيرات (من شاشة الإعدادات) ويعيد جدولة الإشعارات
  /// فورًا إن كانت الأوقات الحقيقية متوفرة. إن لم تكن الإشعارات مفعّلة
  /// بعد (مثلاً أول محاولة فشلت)، يحاول التفعيل من جديد بدل تجاهل
  /// اختيار المستخدم بصمت.
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
    } else {
      await loadPrayerTimes();
    }
  }

  /// يفعّل/يعطّل إشعار الأذان عند وقت الصلاة (منبّه الاستعداد وتذكير
  /// "هل صليت؟" يبقيان فعّالين دائمًا — هذا الخيار خاص بصوت الأذان فقط).
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

    // لا ننتظر النتيجة هنا كي لا تتأخر شاشة الإقلاع؛ الواجهة تتحدّث
    // تلقائيًا (عبر notifyListeners داخل loadPrayerTimes) عند التوفّر.
    unawaited(loadPrayerTimes());
    unawaited(PurchaseService.instance.init(onAdsRemoved: _markAdsRemoved));
  }

  /// يُشغَّل مرة واحدة عند الإقلاع، ويعيد فحص الوقت كل دقيقة: يحدّث
  /// الصلاة "القادمة" فورًا، وينتقل لليوم الجديد تلقائيًا عند منتصف
  /// الليل بلا حاجة لإعادة فتح التطبيق.
  void _startClock() {
    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        final oldDate = lastOpenDate;

        _rolloverIfNewDay();

        if (oldDate != lastOpenDate) {
          await loadPrayerTimes();
        }

        _recomputeUpcoming();

        notifyListeners();
      },
    );
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

      // أغلق يوم الأمس: احسب نسبة الإنجاز وادفعها إلى السجل الأسبوعي واليومي.

      // أغلق يوم الأمس: احسب نسبة الإنجاز وادفعها إلى السجل الأسبوعي واليومي،
      // واحفظ حالة كل صلاة على حدة لعرضها لاحقًا فـ تفاصيل اليوم بالتقويم.

      final active = activePrayers;
      final doneCount = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      final pct = active.isEmpty ? 0 : ((doneCount / active.length) * 100).round();
      weekHistory = [...weekHistory.skip(1), pct];
      dailyHistory[lastOpenDate!] = pct;

      _persistDailyHistory();

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
  final times = realTimes;

  // إذا لم تكن أوقات الصلاة جاهزة نستعمل الترتيب القديم.
  if (times == null) {
    bool foundUpcoming = false;

    for (final p in activePrayers) {
      final s = todayStatus[p];

      if (s == PrayerStatus.done || s == PrayerStatus.missed) {
        continue;
      }

      if (!foundUpcoming) {
        todayStatus[p] = PrayerStatus.upcoming;
        foundUpcoming = true;
      } else {
        todayStatus[p] = PrayerStatus.pending;
      }
    }

    return;
  }

  final now = DateTime.now();

  Prayer? next;

  for (final prayer in activePrayers) {
    final status = todayStatus[prayer];
    if (status == PrayerStatus.done || status == PrayerStatus.missed) continue;

    final prayerTime = times[prayer];
    if (prayerTime == null) continue;

    if (prayerTime.isAfter(now)) {
      // أول صلاة لم يحن وقتها بعد ولم تُسجَّل — هي القادمة، ونتوقّف هنا
      // (كل ما بعدها فـ الترتيب لم يحن وقته بداهةً أيضًا).
      next ??= prayer;
      break;
    }

    // وقت هذه الصلاة مضى ولم تُسجَّل كمُصلّاة أو كفائتة — نُعلِمها
    // تلقائيًا كفائتة كي يظهر تنبيهها للمستخدم، مع بقاء إمكانية تسجيلها
    // "صليت" لاحقًا يدويًا إن كان قد صلاها فعلًا بدون تسجيل فوري.
    todayStatus[prayer] = PrayerStatus.missed;
  }

  // بعد العشاء نعتبر فجر الغد هو القادم
  next ??= Prayer.fajr;

  for (final prayer in activePrayers) {
    final status = todayStatus[prayer];

    if (status == PrayerStatus.done ||
        status == PrayerStatus.missed) {
      continue;
    }

    if (prayer == next) {
      todayStatus[prayer] = PrayerStatus.upcoming;
    } else {
      todayStatus[prayer] = PrayerStatus.pending;
    }
  }
  }

  /// وقت صلاة معيّنة لأغراض حساب "هل فات وقتها؟": الوقت الحقيقي إن
  /// توفّر، وإلا وقت Prayer.mockTime محسوبًا على تاريخ اليوم — حتى يعمل
  /// كشف الفوات التلقائي حتى بلا موقع/إنترنت.
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

  /// يحسب الصلاة "القادمة"، ويكشف تلقائيًا أي صلاة سابقة انتهى وقتها
  /// دون أن تُصلَّى فيُحوّلها لحالة "فائتة" (missed) — هذا هو أساس بطاقة
  /// "الصلوات غير المؤداة" فـ الشاشة الرئيسية، بدل الاعتماد فقط على
  /// تبليغ المستخدم اليدوي عبر شاشة السبب.
  void _recomputeUpcoming() {
    final now = DateTime.now();
    var missedChanged = false;

    // نحدّد الصلاة القادمة: أول صلاة لم يحن وقتها بعد (أو لم تُصلَّ ولا
    // نعرف وقتها). بعد العشاء نعتبر فجر الغد هو القادم.
    Prayer? next;
    for (final prayer in activePrayers) {
      final t = _timeFor(prayer);
      if (t == null) continue;
      if (t.isAfter(now)) {
        next = prayer;
        break;
      }
    }
    next ??= Prayer.fajr;

    for (final prayer in activePrayers) {
      final status = todayStatus[prayer];

      // مُصلاة أو فائتة مسبقًا (سواء تلقائيًا أو يدويًا عبر شاشة السبب):
      // لا نعيد تقييمها.
      if (status == PrayerStatus.done || status == PrayerStatus.missed) {
        continue;
      }

      if (prayer == next) {
        todayStatus[prayer] = PrayerStatus.upcoming;
        continue;
      }

      final t = _timeFor(prayer);
      final elapsed = t != null && now.isAfter(t);

      if (elapsed) {
        // فات وقتها ولم تُصلَّ ولم تُصنَّف فائتة بعد: نصنّفها تلقائيًا.
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

  /// الصلوات التي فات وقتها اليوم دون أداء، مرتبة حسب أولوية القضاء
  /// (الأقدم أولًا) — أساس بطاقة "الصلوات غير المؤداة".
  List<Prayer> get missedTodayPrayers =>
      activePrayers.where((p) => todayStatus[p] == PrayerStatus.missed).toList();

  int get missedTodayCount => missedTodayPrayers.length;

  /// عدد الصلوات المؤدّاة اليوم (لشريط تقدّم "قضاء اليوم").
  int get doneTodayCount =>
      activePrayers.where((p) => todayStatus[p] == PrayerStatus.done).length;

  /// true إن أُدِّيت كل صلوات اليوم النشطة (لا صلاة فائتة ولا متبقية).
  bool get allTodayDone =>
      activePrayers.isNotEmpty && doneTodayCount == activePrayers.length;

  /// يسجّل الصلاة كمقضيّة (أداء متأخر لصلاة كانت مصنّفة فائتة) — تُزال
  /// فورًا من قائمة "غير المؤداة" وتُحتسب ضمن صلوات اليوم المكتملة.
  Future<void> markQada(Prayer p) => markDone(p);


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
    missTally[p] = (missTally[p] ?? 0) + 1;

    // إن كانت مصنّفة فائتة تلقائيًا مسبقًا لا نزيد العدّاد مرة ثانية —
    // فقط نُسجّل السبب الذي اختاره المستخدم.
    final alreadyMissed = todayStatus[p] == PrayerStatus.missed;
    todayStatus[p] = PrayerStatus.missed;
    todayReasons[p] = reason;
    if (!alreadyMissed) {
      missTally[p] = (missTally[p] ?? 0) + 1;
    }

    _recomputeUpcoming();
    await _persist();
    await _persistMissTally();
    notifyListeners();
  }

  /// الصلاة الأكثر فوتًا تراكميًا (وليس اليوم فقط) — تُستعمل فـ ملاحظة
  /// لوحة الحياة. ترجع null إن لم تُفَت أي صلاة بعد.
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

  /// نسبة الالتزام العامة (متوسط كل الأيام المسجَّلة + اليوم الحالي).
  /// ترجع null إن لم يوجد أي سجل بعد (مستخدم جديد).
  int? get overallCommitmentPercent {
    final active = activePrayers;
    final todayDone = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
    final todayPct = active.isEmpty ? 0 : ((todayDone / active.length) * 100).round();
    final allValues = [...dailyHistory.values, todayPct];
    if (allValues.isEmpty) return null;
    return (allValues.reduce((a, b) => a + b) / allValues.length).round();
  }

  /// نسبة الإنجاز ليوم معيّن (لعرضه فـ التقويم الشهري)، أو null إن لم
  /// يُسجَّل أي شيء لذلك اليوم (يوم مستقبلي أو قبل تثبيت التطبيق).
  int? percentForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (key == _todayKey) {
      final active = activePrayers;
      final doneCount = active.where((p) => todayStatus[p] == PrayerStatus.done).length;
      return active.isEmpty ? 0 : ((doneCount / active.length) * 100).round();
    }
    return dailyHistory[key];
  }


  /// حالة كل صلاة فـ يوم معيّن (لبطاقة تفاصيل اليوم عند الضغط على تاريخ
  /// فـ التقويم): تُرجع todayStatus الحيّة لليوم الحالي، أو السجل
  /// المحفوظ لأي يوم سابق، أو null إن لم يُسجَّل شيء لذلك اليوم بعد
  /// (يوم مستقبلي أو قبل تثبيت التطبيق).
  Map<Prayer, PrayerStatus>? prayerStatusForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (key == _todayKey) return todayStatus;
    return dailyPrayerHistory[key];
  }

  Future<void> _persistMissTally() async {
    await _prefs.setStringList(
      'miss_tally',
      missTally.entries.map((e) => '${e.key.name}:${e.value}').toList(),
    );
  }

  Future<void> _persistDailyHistory() async {
    await _prefs.setStringList(
      'daily_history',
      dailyHistory.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }


  Future<void> _persistDailyPrayerHistory() async {
    await _prefs.setStringList(
      'daily_prayer_history',
      dailyPrayerHistory.entries.map((e) {
        final statusesText = e.value.entries.map((s) => '${s.key.name}=${s.value.name}').join(',');
        return '${e.key}|$statusesText';
      }).toList(),
    );
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

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
