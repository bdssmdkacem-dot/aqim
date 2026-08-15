from pathlib import Path

service = Path('lib/services/quran_service.dart')
text = service.read_text(encoding='utf-8')
if 'bool get isSajda =>' not in text:
    needle = "  }\n}\n\nclass QuranPage {"
    insert = """  }\n\n  bool get isSajda => const <String>{\n    '7:206',\n    '13:15',\n    '16:50',\n    '17:109',\n    '19:58',\n    '22:18',\n    '22:77',\n    '25:60',\n    '27:26',\n    '32:15',\n    '38:24',\n    '41:38',\n    '53:62',\n    '84:21',\n    '96:19',\n  }.contains('$surahNumber:$numberInSurah');\n}\n\nclass QuranPage {"""
    if needle not in text:
        raise SystemExit('QuranVerse insertion point not found')
    service.write_text(text.replace(needle, insert, 1), encoding='utf-8')

screen = Path('lib/screens/quran_screen.dart')
text = screen.read_text(encoding='utf-8')
if '_showSajdaGuide(QuranVerse verse)' not in text:
    needle = "  void _changePage(int delta) {"
    method = r'''  Future<void> _showSajdaGuide(QuranVerse verse) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(.12),
                      border: Border.all(color: AppColors.gold.withOpacity(.40)),
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'سجدة التلاوة',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            color: AppColors.ivory,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${verse.surahName} • الآية ${verse.numberInSurah}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withOpacity(.16)),
                ),
                child: Text(
                  verse.text,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(color: AppColors.ivory, fontSize: 22, height: 1.9),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'كيف تؤدي سجدة التلاوة؟',
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                'أكمل قراءة الآية التي عليها علامة السجدة.',
                'اسجد سجدة واحدة بنية سجود التلاوة، مع استقبال القبلة إن تيسّر.',
                'قل في السجود: «سبحان ربي الأعلى»، ثم ارفع رأسك.',
              ].asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: GoogleFonts.cairo(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: AppColors.ivory, fontSize: 14, height: 1.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ملاحظة: قد تختلف بعض التفاصيل الفقهية باختلاف المذهب، فاستعن بما تتبعه من أحكام.',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

'''
    if needle not in text:
        raise SystemExit('QuranScreen insertion point not found')
    text = text.replace(needle, method + needle, 1)

old = """                        const Spacer(),\n                        const Icon(Icons.menu_book_rounded, color: AppColors.textMuted, size: 17),\n"""
new = """                        const Spacer(),\n                        if (verse.isSajda)\n                          Padding(\n                            padding: const EdgeInsets.only(left: 4),\n                            child: IconButton(\n                              onPressed: () => _showSajdaGuide(verse),\n                              tooltip: 'موضع سجدة التلاوة',\n                              visualDensity: VisualDensity.compact,\n                              icon: const Icon(\n                                Icons.self_improvement_rounded,\n                                color: AppColors.gold,\n                                size: 20,\n                              ),\n                            ),\n                          ),\n                        const Icon(Icons.menu_book_rounded, color: AppColors.textMuted, size: 17),\n"""
if 'verse.isSajda' not in text:
    if old not in text:
        raise SystemExit('Quran verse header insertion point not found')
    text = text.replace(old, new, 1)
screen.write_text(text, encoding='utf-8')

Path('.github/quran-sajda-applied.txt').write_text(
    'Quran sajda patch applied: 15 standard sajda positions, visible marker, and tap-to-guide UI.\n',
    encoding='utf-8',
)
