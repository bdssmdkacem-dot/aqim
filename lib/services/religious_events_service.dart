import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Religious dates used by Aqim for the Moroccan calendar.
///
/// Dates announced by Morocco's Ministry of Habous are used where available.
/// Future dates are marked as provisional because the Moroccan calendar is
/// confirmed by local crescent observation and can move by one day.
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
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  /// Morocco-confirmed 2026 dates plus the currently published 2027
  /// astronomical estimates. The app never presents a future estimate as
  /// an official confirmation.
  static List<ReligiousEvent> eventsForYear(int year) {
    switch (year) {
      case 2026:
        return const [
          ReligiousEvent(
            id: 'mawlid-1448',
            title: 'المولد النبوي الشريف',
            hijri: '12 ربيع الأول 1448 هـ',
            date: const DateTime(2026, 8, 25),
          ),
        ];
      case 2027:
        return const [
          ReligiousEvent(
            id: 'ramadan-1448',
            title: 'بداية شهر رمضان',
            hijri: '1 رمضان 1448 هـ',
            date: const DateTime(2027, 2, 8),
            provisional: true,
          ),
          ReligiousEvent(
            id: 'fitr-1448',
            title: 'عيد الفطر المبارك',
            hijri: '1 شوال 1448 هـ',
            date: const DateTime(2027, 3, 9),
            provisional: true,
          ),
          ReligiousEvent(
            id: 'adha-1448',
            title: 'عيد الأضحى المبارك',
            hijri: '10 ذو الحجة 1448 هـ',
            date: const DateTime(2027, 5, 16),
            provisional: true,
          ),
          ReligiousEvent(
            id: 'mawlid-1449',
            title: 'المولد النبوي الشريف',
            hijri: '12 ربيع الأول 1449 هـ',
            date: const DateTime(2027, 8, 14),
            provisional: true,
          ),
        ];
      default:
        return const [];
    }
  }

  static List<ReligiousEvent> upcoming({DateTime? from, int years = 2}) {
    final start = from ?? DateTime.now();
    final events = <ReligiousEvent>[];
    for (var year = start.year; year <= start.year + years; year++) {
      events.addAll(eventsForYear(year));
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events
        .where((e) => !e.date.add(const Duration(days: 1)).isBefore(start))
        .toList();
  }

  static ReligiousEvent? eventOn(DateTime date) {
    for (final event in eventsForYear(date.year)) {
      if (event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day) {
        return event;
      }
    }
    return null;
  }

  static String monthName(int month) => _monthNames[month - 1];

  static String labelForDate(DateTime date) {
    final event = eventOn(date);
    if (event == null) return '';
    return event.provisional ? '${event.title} (موعد متوقع)' : event.title;
  }

  static NotificationDetails notificationDetails() {
    return const NotificationDetails(
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
}
