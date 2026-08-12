/// تنسيق التاريخ الميلادي بأسماء عربية (بلا حاجة لتهيئة بيانات لغة intl).
class GregorianArabic {
  static const _dayNames = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليوز',
    'غشت',
    'شتنبر',
    'أكتوبر',
    'نونبر',
    'دجنبر',
  ];

  /// مثال: "الإثنين ٢٠ يوليوز ٢٠٢٦"
  static String format(DateTime date) {
    final dayName = _dayNames[date.weekday - 1];
    final monthName = _monthNames[date.month - 1];
    return '$dayName ${date.day} $monthName ${date.year}';
  }
}
