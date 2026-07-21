/// تحويل التاريخ الميلادي إلى الهجري عبر الخوارزمية الجدولية المعروفة
/// (Tabular/Kuwaiti Islamic Calendar) — تقريب حسابي معتمد عالميًا (يُستعمل
/// فـ Microsoft وأنظمة كثيرة)، يختلف عادة يوم أو يومين عن التقويم المعتمد
/// على رؤية الهلال الفعلية (كالتقويم أم القرى الرسمي).
///
/// بلا أي حزمة خارجية أو اتصال إنترنت — حساب رياضي بحت.
class HijriDate {
  final int day;
  final int month; // 1..12
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

  static int _floorDiv(int a, int b) => (a / b).floor();

  factory HijriDate.fromGregorian(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;

    final a1 = _floorDiv(m - 14, 12);
    final jd = _floorDiv(1461 * (y + 4800 + a1), 4) +
        _floorDiv(367 * (m - 2 - 12 * a1), 12) -
        _floorDiv(3 * _floorDiv(y + 4900 + a1, 100), 4) +
        d -
        32075;

    var l = jd - 1948440 + 10632;
    final n = _floorDiv(l - 1, 10631);
    l = l - 10631 * n + 354;
    final j = _floorDiv(10985 - l, 5316) * _floorDiv(50 * l, 17719) +
        _floorDiv(l, 5670) * _floorDiv(43 * l, 15238);
    l = l -
        _floorDiv(30 - j, 15) * _floorDiv(17719 * j, 50) -
        _floorDiv(j, 16) * _floorDiv(15238 * j, 43) +
        29;
    final month = _floorDiv(24 * l, 709);
    final day = l - _floorDiv(709 * month, 24);
    final year = 30 * n + j - 30;

    return HijriDate(day, month, year);
  }

  String get formatted => '$day $monthName $year هـ';
}
