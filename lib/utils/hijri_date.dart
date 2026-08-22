/// تحويل التاريخ الميلادي إلى الهجري.
///
/// بالنسبة لسنة 1448هـ نستخدم بدايات الأشهر الخاصة بالتقويم المغربي
/// المنشور والمتوافق مع المعطيات الرسمية حيث تتوفر، بدل الاعتماد على الحساب
/// الجدولي وحده. خارج هذه الفترة نستخدم الحساب الجدولي كحل احتياطي.
/// بداية الشهر الهجري في المغرب قد تختلف عن الحساب الفلكي بيوم.
class HijriDate {
  final int day;
  final int month;
  final int year;

  const HijriDate(this.day, this.month, this.year);

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

  String get monthName => _monthNames[month - 1];

  static final List<_MoroccoMonthStart> _morocco1448 = [
    _MoroccoMonthStart(DateTime(2026, 6, 17), 1, 1448),
    _MoroccoMonthStart(DateTime(2026, 7, 16), 2, 1448),
    _MoroccoMonthStart(DateTime(2026, 8, 14), 3, 1448),
    _MoroccoMonthStart(DateTime(2026, 9, 12), 4, 1448),
    _MoroccoMonthStart(DateTime(2026, 10, 12), 5, 1448),
    _MoroccoMonthStart(DateTime(2026, 11, 11), 6, 1448),
    _MoroccoMonthStart(DateTime(2026, 12, 10), 7, 1448),
    _MoroccoMonthStart(DateTime(2027, 1, 9), 8, 1448),
    _MoroccoMonthStart(DateTime(2027, 2, 8), 9, 1448),
    _MoroccoMonthStart(DateTime(2027, 3, 9), 10, 1448),
    _MoroccoMonthStart(DateTime(2027, 4, 8), 11, 1448),
    _MoroccoMonthStart(DateTime(2027, 5, 7), 12, 1448),
    _MoroccoMonthStart(DateTime(2027, 6, 6), 1, 1449),
  ];

  factory HijriDate.fromGregorian(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final lastVerifiedStart = _morocco1448.last.gregorian;
    final lastVerifiedEnd = lastVerifiedStart.add(const Duration(days: 30));

    if (!localDate.isBefore(_morocco1448.first.gregorian) && localDate.isBefore(lastVerifiedEnd)) {
      for (var i = _morocco1448.length - 1; i >= 0; i--) {
        final start = _morocco1448[i];
        if (!localDate.isBefore(start.gregorian)) {
          final day = localDate.difference(start.gregorian).inDays + 1;
          return HijriDate(day, start.month, start.year);
        }
      }
    }

    return _fromTabular(localDate);
  }

  static HijriDate _fromTabular(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    int floorDiv(int a, int b) => (a / b).floor();

    final a1 = floorDiv(m - 14, 12);
    final jd = floorDiv(1461 * (y + 4800 + a1), 4) +
        floorDiv(367 * (m - 2 - 12 * a1), 12) -
        floorDiv(3 * floorDiv(y + 4900 + a1, 100), 4) +
        d -
        32075;

    var l = jd - 1948440 + 10632;
    final n = floorDiv(l - 1, 10631);
    l = l - 10631 * n + 354;
    final j = floorDiv(10985 - l, 5316) * floorDiv(50 * l, 17719) +
        floorDiv(l, 5670) * floorDiv(43 * l, 15238);
    l = l -
        floorDiv(30 - j, 15) * floorDiv(17719 * j, 50) -
        floorDiv(j, 16) * floorDiv(15238 * j, 43) +
        29;
    final month = floorDiv(24 * l, 709);
    final day = l - floorDiv(709 * month, 24);
    final year = 30 * n + j - 30;

    return HijriDate(day, month, year);
  }

  String get formatted => '$day $monthName $year هـ';
}

class _MoroccoMonthStart {
  final DateTime gregorian;
  final int month;
  final int year;

  const _MoroccoMonthStart(this.gregorian, this.month, this.year);
}
