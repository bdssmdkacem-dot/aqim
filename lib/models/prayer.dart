/// الصلوات الخمس بترتيبها اليومي.
enum Prayer { fajr, dhuhr, asr, maghrib, isha }

extension PrayerLabel on Prayer {
  String get arabicName {
    switch (this) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }

  /// وقت افتراضي للعرض فقط. النسخة الإنتاجية يجب أن تُحسب من موقع
  /// المستخدم عبر واجهة برمجية لمواقيت الصلاة (مثل Aladhan API).
  String get mockTime {
    switch (this) {
      case Prayer.fajr:
        return '05:12';
      case Prayer.dhuhr:
        return '13:05';
      case Prayer.asr:
        return '16:40';
      case Prayer.maghrib:
        return '19:55';
      case Prayer.isha:
        return '21:20';
    }
  }
}

enum PrayerStatus { pending, upcoming, done, missed }

/// آية وحديث وفائدة قصيرة تُعرض قبل كل صلاة بعشر دقائق.
class PreReminder {
  final String ayah;
  final String hadith;
  final String benefit;

  const PreReminder({
    required this.ayah,
    required this.hadith,
    required this.benefit,
  });
}

const Map<Prayer, PreReminder> preReminders = {
  Prayer.fajr: PreReminder(
    ayah: '﴿أَقِمِ الصَّلَاةَ لِدُلُوكِ الشَّمْسِ إِلَىٰ غَسَقِ اللَّيْلِ وَقُرْآنَ الْفَجْرِ﴾',
    hadith: 'من صلى الصبح فهو في ذمة الله.',
    benefit: 'ركعتا الفجر خير من الدنيا وما فيها — ابدأ يومك بها.',
  ),
  Prayer.dhuhr: PreReminder(
    ayah: '﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ﴾',
    hadith: 'أول ما يُحاسَب به العبد يوم القيامة صلاته.',
    benefit: 'توقف خمس دقائق عن العمل الآن يمنحك تركيزًا أفضل لبقية اليوم.',
  ),
  Prayer.asr: PreReminder(
    ayah: '﴿وَالْعَصْرِ إِنَّ الْإِنْسَانَ لَفِي خُسْرٍ﴾',
    hadith: 'من ترك صلاة العصر فقد حبط عمله.',
    benefit: 'العصر أكثر صلاة يُفرَّط فيها بسبب انشغال آخر اليوم — انتبه لها.',
  ),
  Prayer.maghrib: PreReminder(
    ayah: '﴿فَسُبْحَانَ اللَّهِ حِينَ تُمْسُونَ وَحِينَ تُصْبِحُونَ﴾',
    hadith: 'بادروا بالأعمال الصالحة قبل أن تُغلَق أبوابها.',
    benefit: 'المغرب لحظة انتقال هادئة بين عمل النهار وراحة الليل.',
  ),
  Prayer.isha: PreReminder(
    ayah: '﴿وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَّكَ﴾',
    hadith: 'من صلى العشاء في جماعة فكأنما قام نصف الليل.',
    benefit: 'اختم يومك بها قبل النوم لتُقفل صفحة اليوم بطمأنينة.',
  ),
};

/// أسباب فوات الصلاة التي يعرضها التطبيق للمستخدم عند التبليغ.
const List<String> missedReasons = [
  'كنت نائمًا',
  'كنت في العمل',
  'نسيت',
  'كنت خارج المنزل',
  'لا أعرف',
];

String suggestionForReason(String reason) {
  const map = {
    'كنت نائمًا': 'جرّب ضبط تنبيه قيلولة قصيرة قبل الصلاة بعشرين دقيقة.',
    'كنت في العمل': 'نقترح إشعارًا أهدأ عبر الساعة الذكية بدل صوت الهاتف.',
    'نسيت': 'سنرسل لك تذكيرًا ثانيًا بعد عشر دقائق من الأول تحسبًا للنسيان.',
    'كنت خارج المنزل': 'يمكنك حفظ أقرب مسجد على طريقك ضمن التطبيق.',
    'لا أعرف': 'لا بأس، سنتابع معك هذا الأسبوع لنفهم النمط بدقة أكبر.',
  };
  return map[reason] ?? 'سنحاول مساعدتك أكثر في المرة القادمة.';
}
