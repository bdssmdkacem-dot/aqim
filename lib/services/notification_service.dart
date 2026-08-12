import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';
import '../navigation/nav_key.dart';
import '../screens/pre_prayer_screen.dart';

/// يدير ثلاثة تنبيهات لكل صلاة:
/// 1) "منبّه الاستعداد" — قبل الوقت الحقيقي (توقيت قابل للتخصيص)، بصوت
///    منبّه خاص بكل صلاة (راجع [_wakeAlarmSoundFor]) وسلوك منبّه حقيقي
///    (يعمل حتى والهاتف مقفل). الفجر تحديدًا له ثلاثة تنبيهات متتالية
///    تصاعدية (أهدأ فأقوى) بدل تنبيه واحد — راجع [_scheduleFajrWakeAlarms].
/// 2) "الأذان" — عند الوقت الحقيقي بالضبط، بصوت الأذان (adhan) إن وُجد
///    الملف، وإلا نغمة الإشعار الافتراضية.
/// 3) "هل صليت؟" — بعد الوقت الحقيقي (توقيت قابل للتخصيص)، بزر تأجيل.
///
/// يُجدوَل الكل بناءً على أوقات حقيقية فقط (AppState.realTimes)، ولا
/// يُستعمل أبدًا مع الأوقات الاحتياطية الوهمية.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // نبقى على UTC كخيار احتياطي إن تعذّر تحديد المنطقة الزمنية —
      // أفضل من تعطّل الجدولة بالكامل.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  static const _snoozeActionId = 'snooze_15';

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (response.actionId == _snoozeActionId) {
      _snoozeCheckIn(payload);
      return;
    }

    final prayer = _prayerFromId(payload);
    if (prayer == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: prayer)),
    );
  }

  /// يؤجّل إشعار "هل صليت؟" خمس عشرة دقيقة بدل فتح التطبيق مباشرة.
  /// يعمل عندما يكون التطبيق مفتوحًا فـ الخلفية (وليس مغلقًا بالكامل من
  /// قِبل النظام) — قيد معروف موثّق فـ README.
  Future<void> _snoozeCheckIn(String prayerId) async {
    final prayer = _prayerFromId(prayerId);
    if (prayer == null) return;

    await _scheduleCheckIn(
      id: _idFor(prayer, 1),
      title: 'هل صليت ${prayer.arabicName}؟',
      body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
      scheduledDate: DateTime.now().add(const Duration(minutes: 15)),
      payload: prayerId,
    );
  }

  Prayer? _prayerFromId(String id) {
    for (final p in Prayer.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  /// معرّف فريد لكل إشعار: فهرس الصلاة × 10 + نوع الإشعار
  /// (0=منبّه الاستعداد [أو الأول من ثلاثة للفجر]، 1=هل صليت، 2=الأذان،
  /// 3=منبّه الفجر الثاني، 4=منبّه الفجر الثالث/الأخير).
  int _idFor(Prayer p, int typeOffset) => Prayer.values.indexOf(p) * 10 + typeOffset;

  /// اسم ملف الصوت (فـ android/app/src/main/res/raw) لمنبّه الاستعداد
  /// الخاص بكل صلاة. الفجر لا يُستعمل هنا لأنه يُعامَل بشكل خاص فـ
  /// [_scheduleFajrWakeAlarms] بثلاثة أصوات متتالية.
  String _wakeAlarmSoundFor(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return 'alarm_fajr_3'; // احتياطي، غير مُستعمل عمليًا
      case Prayer.dhuhr:
        return 'alarm_dhuhr';
      case Prayer.asr:
        return 'alarm_asr';
      case Prayer.maghrib:
        return 'alarm_maghrib';
      case Prayer.isha:
        return 'alarm_isha';
    }
  }

  /// يلغي كل التذكيرات السابقة ويعيد جدولتها بناءً على أوقات اليوم
  /// الحقيقية. يُستدعى فـ كل مرة تُجلَب فيها أوقات جديدة بنجاح، أو عند
  /// تغيير المستخدم لتوقيت التذكير من الإعدادات.
  Future<void> scheduleAllForToday(
    Map<Prayer, DateTime> realTimes, {
    int beforeMinutes = 10,
    int afterMinutes = 20,
    bool adhanEnabled = true,
  }) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final entry in realTimes.entries) {
      final prayer = entry.key;
      final prayerTime = entry.value;

      final alarmTime = prayerTime.subtract(Duration(minutes: beforeMinutes));
      final checkInTime = prayerTime.add(Duration(minutes: afterMinutes));

      if (prayer == Prayer.fajr) {
        await _scheduleFajrWakeAlarms(
          finalAlarmTime: alarmTime,
          beforeMinutes: beforeMinutes,
          now: now,
        );
      } else if (alarmTime.isAfter(now)) {
        await _scheduleWakeAlarm(
          id: _idFor(prayer, 0),
          title: 'استعد لصلاة ${prayer.arabicName}',
          body: 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} على ${prayer.arabicName}.',
          scheduledDate: alarmTime,
          soundName: _wakeAlarmSoundFor(prayer),
          payload: prayer.name,
        );
      }

      if (adhanEnabled && prayerTime.isAfter(now)) {
        await _scheduleAdhan(
          id: _idFor(prayer, 2),
          title: 'حان وقت ${prayer.arabicName}',
          body: 'حيّ على الصلاة، حيّ على الفلاح.',
          scheduledDate: prayerTime,
          payload: prayer.name,
        );
      }

      if (checkInTime.isAfter(now)) {
        await _scheduleCheckIn(
          id: _idFor(prayer, 1),
          title: 'هل صليت ${prayer.arabicName}؟',
          body: 'اضغط هنا لتسجيل صلاتك أو معرفة السبب إن فاتتك.',
          scheduledDate: checkInTime,
          payload: prayer.name,
        );
      }
    }
  }

  /// منبّه الاستعداد قبل الصلاة — سلوك منبّه حقيقي (شاشة كاملة + صوت
  /// منبّه) حتى لو كان الهاتف مقفلاً أو صامتًا، لمساعدة المستخدم على
  /// النهوض والاستعداد. يحتاج ملف الصوت المقابل فـ
  /// android/app/src/main/res/raw/ (راجع README) — يستعمل نغمة الإشعار
  /// الافتراضية إن لم يُضَف الملف بعد.
  Future<void> _scheduleWakeAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String soundName,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_wake_alarm',
          'منبّه الاستعداد للصلاة',
          channelDescription: 'منبّه صوتي قبل كل صلاة لمساعدتك على الاستعداد',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// ثلاثة منبّهات متتالية وتصاعدية قبل الفجر بدل منبّه واحد: الأول
  /// (alarm_fajr_1) قبل عشر دقائق إضافية من الموعد المعتاد، الثاني
  /// (alarm_fajr_2) قبل خمس دقائق إضافية، والثالث (alarm_fajr_3) فـ
  /// نفس موعد منبّه الاستعداد المعتاد [finalAlarmTime] — الأقوى صوتًا
  /// باعتباره التنبيه الحاسم قبل دخول الوقت. كل واحد يُجدوَل فقط إن كان
  /// موعده لا يزال فـ المستقبل.
  Future<void> _scheduleFajrWakeAlarms({
    required DateTime finalAlarmTime,
    required int beforeMinutes,
    required DateTime now,
  }) async {
    final stages = [
      (
        offsetMinutes: 10,
        soundName: 'alarm_fajr_1',
        title: 'اقترب وقت الفجر',
        typeOffset: 0,
      ),
      (
        offsetMinutes: 5,
        soundName: 'alarm_fajr_2',
        title: 'استعد لصلاة الفجر',
        typeOffset: 3,
      ),
      (
        offsetMinutes: 0,
        soundName: 'alarm_fajr_3',
        title: 'حان الاستعداد الأخير لصلاة الفجر',
        typeOffset: 4,
      ),
    ];

    for (final stage in stages) {
      final scheduledDate =
          finalAlarmTime.subtract(Duration(minutes: stage.offsetMinutes));
      if (!scheduledDate.isAfter(now)) continue;

      await _scheduleWakeAlarm(
        id: _idFor(Prayer.fajr, stage.typeOffset),
        title: stage.title,
        body: 'تبقّى $beforeMinutes ${beforeMinutes == 1 ? "دقيقة" : "دقائق"} على صلاة الفجر.',
        scheduledDate: scheduledDate,
        soundName: stage.soundName,
        payload: Prayer.fajr.name,
      );
    }
  }

  /// إشعار الأذان عند دخول وقت الصلاة بالضبط، بصوت الأذان. يحتاج ملف
  /// android/app/src/main/res/raw/adhan.mp3 (راجع README) — يُفضَّل
  /// مقطع قصير (٢٠-٤٠ ثانية) بدل الأذان الكامل لضمان تشغيله بشكل موثوق
  /// كصوت إشعار على مختلف الأجهزة.
  Future<void> _scheduleAdhan({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_adhan',
          'الأذان',
          channelDescription: 'صوت الأذان عند دخول وقت كل صلاة',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan'),
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _scheduleCheckIn({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_prayer_checkin',
          'تسجيل الصلاة',
          channelDescription: 'تنبيه بعد كل صلاة لتسجيل الحالة',
          importance: Importance.high,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(
              _snoozeActionId,
              'أجّل 15 دقيقة',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// يجدول (أو يُحدِّث) إشعار الملخص الأسبوعي — يظهر كل جمعة الساعة ٨
  /// مساءً بنص محسوب من آخر مرة فُتح فيها التطبيق. ليس تكراريًا حقيقيًا
  /// (المحتوى يتغيّر يوميًا)، لذا يُعاد جدولته يوميًا بنص محدَّث بدل
  /// الاعتماد على تكرار ثابت النص.
  static const _weeklySummaryId = 999;

  Future<void> scheduleWeeklySummary(String body) async {
    if (!_initialized) return;
    final target = _nextFridayEightPm();
    final tzTime = tz.TZDateTime.from(target, tz.local);
    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: 'ملخّص أسبوعك مع أقم 🌙',
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_weekly_summary',
          'الملخص الأسبوعي',
          channelDescription: 'تذكير أسبوعي بعدد الصلوات المُتمّة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  DateTime _nextFridayEightPm() {
    final now = DateTime.now();
    var daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    var target = DateTime(now.year, now.month, now.day, 20).add(Duration(days: daysUntilFriday));
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 7));
    }
    return target;
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
