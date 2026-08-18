class AdhkarEvidence {
  final String virtue;
  final String source;
  const AdhkarEvidence({required this.virtue, required this.source});
}

/// Only evidence with a clear source is shown. Do not infer a special virtue
/// when the Sunnah does not establish one.
const Map<String, AdhkarEvidence> adhkarEvidence = {
  'morning_sayyidul_istighfar': AdhkarEvidence(
    virtue: 'من قاله موقنًا به في الصباح فمات من يومه دخل الجنة، وهو من أعظم صيغ الاستغفار.',
    source: 'صحيح البخاري 6306',
  ),
  'morning_subhanallah_bihamdih': AdhkarEvidence(
    virtue: 'من قال سبحان الله وبحمده مائة مرة حُطّت خطاياه وإن كانت مثل زبد البحر.',
    source: 'صحيح البخاري 6405',
  ),
  'morning_radi_billah': AdhkarEvidence(
    virtue: 'ورد في السنة أن من قاله ثلاث مرات حين يصبح وحين يمسي كان له وعد بالأمن من سخط الله.',
    source: 'سنن أبي داود 5072، الترمذي 3389',
  ),
  'al_ikhlas': AdhkarEvidence(
    virtue: 'سورة الإخلاص تعدل ثلث القرآن، وكان النبي ﷺ يقرؤها مع المعوذتين للتحصين.',
    source: 'صحيح البخاري 5013، صحيح مسلم 811',
  ),
  'al_falaq': AdhkarEvidence(
    virtue: 'كان النبي ﷺ يقرأها مع الإخلاص والناس ثلاث مرات صباحًا ومساءً وعند النوم للتحصين.',
    source: 'سنن أبي داود 5082، صحيح البخاري 5017',
  ),
  'an_nas': AdhkarEvidence(
    virtue: 'كان النبي ﷺ يقرأها مع الإخلاص والفلق للتحصين، ومنها رقية النفس عند النوم.',
    source: 'سنن أبي داود 5082، صحيح البخاري 5017',
  ),
  'morning_ikhlas': AdhkarEvidence(
    virtue: 'كان النبي ﷺ يقرأ الإخلاص والفلق والناس ثلاث مرات صباحًا ومساءً، وهي من أذكار التحصين.',
    source: 'سنن أبي داود 5082',
  ),
  'morning_falaq': AdhkarEvidence(
    virtue: 'من هدي النبي ﷺ قراءة المعوذات ثلاثًا صباحًا ومساءً للتحصين.',
    source: 'سنن أبي داود 5082',
  ),
  'morning_nas': AdhkarEvidence(
    virtue: 'من هدي النبي ﷺ قراءة المعوذات ثلاثًا صباحًا ومساءً للتحصين.',
    source: 'سنن أبي داود 5082',
  ),
  'istighfar': AdhkarEvidence(
    virtue: 'كان النبي ﷺ يستغفر الله بعد الصلاة ثلاث مرات.',
    source: 'صحيح مسلم 591',
  ),
  'tasbih': AdhkarEvidence(
    virtue: 'ثبت التسبيح ثلاثًا وثلاثين والتحميد ثلاثًا وثلاثين والتكبير ثلاثًا وثلاثين عقب الصلاة.',
    source: 'صحيح مسلم 597',
  ),
  'tahmid': AdhkarEvidence(
    virtue: 'ثبت التحميد ثلاثًا وثلاثين عقب الصلاة مع التسبيح والتكبير.',
    source: 'صحيح مسلم 597',
  ),
  'takbir': AdhkarEvidence(
    virtue: 'ثبت التكبير عقب الصلاة مع التسبيح والتحميد، وجاء تمام المائة بالتهليل.',
    source: 'صحيح مسلم 597',
  ),
  'dua_bayn_athan_iqama': AdhkarEvidence(
    virtue: 'الدعاء بين الأذان والإقامة لا يُرد، فاغتنم هذا الوقت بالدعاء.',
    source: 'سنن أبي داود 521، الترمذي 212',
  ),
  'dua_athan': AdhkarEvidence(
    virtue: 'من قال الدعاء المأثور بعد الأذان استحق شفاعة النبي ﷺ بإذن الله.',
    source: 'صحيح البخاري 614',
  ),
  'tarid_athan': AdhkarEvidence(
    virtue: 'من السنة متابعة المؤذن، ثم الصلاة على النبي ﷺ وسؤال الله له الوسيلة.',
    source: 'صحيح البخاري 614، صحيح مسلم 384',
  ),
  'waking_dua': AdhkarEvidence(
    virtue: 'كان النبي ﷺ إذا استيقظ من نومه حمد الله بهذا الذكر.',
    source: 'صحيح البخاري 6312',
  ),
};
