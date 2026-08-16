from pathlib import Path

path = Path('lib/screens/home_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import '../widgets/day_arc.dart';\n"
new_import = "import '../widgets/day_arc.dart';\nimport '../widgets/aqim_logo.dart';\n"
if "../widgets/aqim_logo.dart" not in text:
    if old_import not in text:
        raise SystemExit('home_screen.dart: day_arc import not found')
    text = text.replace(old_import, new_import, 1)

old_top = """      Text('أَقِم', style: GoogleFonts.amiri(fontSize: 25, height: 1, fontWeight: FontWeight.w700, color: AppColors.goldSoft)),"""
new_top = """      const AqimLogo(size: 38),"""
if old_top in text:
    text = text.replace(old_top, new_top, 1)

old_title = """        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('أقم', style: GoogleFonts.amiri(fontSize: 39, height: .9, fontWeight: FontWeight.w700, color: AppColors.goldSoft)), const SizedBox(height: 6), Text('لأجل صلاة في وقتها', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600))]),"""
new_title = """        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [\n          const AqimLogo(size: 56),\n          const SizedBox(height: 5),\n          Text('لأجل صلاة في وقتها', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),\n        ]),"""
if old_title in text:
    text = text.replace(old_title, new_title, 1)

path.write_text(text, encoding='utf-8')
print('Aqim branding applied successfully.')
