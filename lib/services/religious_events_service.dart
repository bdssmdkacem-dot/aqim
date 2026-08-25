import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Religious dates used by Aqim for the Moroccan calendar.
///
/// Dates confirmed by Morocco's Ministry of Habous are used for 2026 where
/// available. Future dates are explicitly provisional because the Moroccan
/// calendar is confirmed by local crescent observation and can move by one day.
class ReligiousEvent {
  final String id;
  final String title;
  final String hijri;
  final DateTime date;
  final bool provisional;

  const ReligiousEvent({
    required this.id,
    required this.title,
    required this.hijri,
    required this.date,
    this.provisional = false,
  });
}

class ReligiousEventsService {
  ReligiousEventsService._();

  static const List<String> _monthNames = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  /// Main Islamic occasions used by Aqim. Confirmed Moroccan dates are kept
  /// fixed for 2026; future dates remain provisional until Morocco confirms
  /// the crescent.
  static List<ReligiousEvent> eventsForYear(int year) {
    switch (year) {
      case 2026:
        return [
          ReligiousEvent(id: 'ramadan-1447', title: 'بداية شهر رمضان المبارك', hijri: '1 رمضان 1447 هـ', date: DateTime(2026, 2, 19)),
          ReligiousEvent(id: 'fitr-1447', title: 'عيد الفطر المبارك', hijri: '1 شوال 1447 هـ', date: DateTime(2026, 3, 20)),
          ReligiousEvent(id: 'arafah-1447', title: 'يوم عرفة', hijri: '9 ذو الحجة 1447 هـ', date: DateTime(2026, 5, 26)),
          ReligiousEvent(id: 'adha-1447', title: 'عيد الأضحى المبارك', hijri: '10 ذو الحجة 1447 هـ', date: DateTime(2026, 5, 27)),
          ReligiousEvent(id: 'hijri-new-year-1448', title: 'رأس السنة الهجرية', hijri: '1 محرم 1448 هـ', date: DateTime(2026, 6, 17)),
          ReligiousEvent(id: 'ashura-1448', title: 'عاشوراء', hijri: '10 محرم 1448 هـ', date: DateTime(2026, 6, 26)),
          ReligiousEvent(id: 'mawlid-1448', title: 'المولد النبوي الشريف', hijri: '12 ربيع الأول 1448 هـ', date: DateTime(2026, 8, 25)),
        ];
      case 2027:
        return [
          ReligiousEvent(id: 'ramadan-1448', title: 'بداية شهر رمضان المبارك', hijri: '1 رمضان 1448 هـ', date: DateTime(2027, 2, 8), provisional: true),
          ReligiousEvent(id: 'laylat-al-qadr-1448', title: 'ليلة القدر', hijri: '27 رمضان 1448 هـ', date: DateTime(2027, 3, 6), provisional: true),
          ReligiousEvent(id: 'fitr-1448', title: 'عيد الفطر المبارك', hijri: '1 شوال 1448 هـ', date: DateTime(2027, 3, 9), provisional: true),
          ReligiousEvent(id: 'arafah-1448', title: 'يوم عرفة', hijri: '9 ذو الحجة 1448 هـ', date: DateTime(2027, 5, 15), provisional: true),
          ReligiousEvent(id: 'adha-1448', title: 'عيد الأضحى المبارك', hijri: '10 ذو الحجة 1448 هـ', date: DateTime(2027, 5, 16), provisional: true),
          ReligiousEvent(id: 'hijri-new-year-1449', title: 'رأس السنة الهجرية', hijri: '1 محرم 1449 هـ', date: DateTime(2027, 6, 7), provisional: true),
          ReligiousEvent(id: 'ashura-1449', title: 'عاشوراء', hijri: '10 محرم 1449 هـ', date: DateTime(2027, 6, 16), provisional: true),
          ReligiousEvent(id: 'mawlid-1449', title: 'المولد النبوي الشريف', hijri: '12 ربيع الأول 1449 هـ', date: DateTime(2027, 8, 14), provisional: true),
        ];
      default:
        return [];
    }
  }

  static List<ReligiousEvent> upcoming({DateTime? from, int years = 2}) {
    final start = from ?? DateTime.now();
    final events = <ReligiousEvent>[];
    for (var year = start.year; year <= start.year + years; year++) {
      events.addAll(eventsForYear(year));
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events.where((e) => !e.date.add(const Duration(days: 1)).isBefore(start)).toList();
  }

  static ReligiousEvent? eventOn(DateTime date) {
    for (final event in eventsForYear(date.year)) {
      if (event.date.year == date.year && event.date.month == date.month && event.date.day == date.day) return event;
    }
    return null;
  }

  static String monthName(int month) => _monthNames[month - 1];

  static String labelForDate(DateTime date) {
    final event = eventOn(date);
    if (event == null) return '';
    return event.provisional ? '${event.title} (موعد متوقع)' : event.title;
  }

  static NotificationDetails notificationDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'aqim_religious_events_v1',
          'المناسبات الدينية',
          channelDescription: 'تنبيهات المناسبات الدينية في التقويم المغربي',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      );
}
