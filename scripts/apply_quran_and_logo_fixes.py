from pathlib import Path
import shutil

# 1) Quran: every page change gets a fresh PageStorage key, so page 2 starts
# at the top instead of restoring page 1's previous scroll offset.
quran = Path('lib/screens/quran_screen.dart')
text = quran.read_text(encoding='utf-8')
old = """return ListView.builder(\n      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),"""
new = """return ListView.builder(\n      key: PageStorageKey<int>(_page),\n      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),"""
if old in text and 'PageStorageKey<int>(_page)' not in text:
    text = text.replace(old, new, 1)
quran.write_text(text, encoding='utf-8')

# 2) Adhkar: use the exact transparent PNG requested by the user.
adhkar = Path('lib/screens/adhkar_flow_screen.dart')
text = adhkar.read_text(encoding='utf-8')
text = text.replace("import '../widgets/aqim_logo.dart';\n", '')
text = text.replace("const AqimLogo(size: 62),", "Image.asset('assets/images/aqim_logo_transparent_512.png', width: 62, height: 62, fit: BoxFit.contain),")
adhkar.write_text(text, encoding='utf-8')

# 3) Android launcher icon: copy the exact same PNG into Android resources.
source = Path('assets/images/aqim_logo_transparent_512.png')
target = Path('android/app/src/main/res/drawable/aqim_logo_transparent_512.png')
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source, target)

manifest = Path('android/app/src/main/AndroidManifest.xml')
manifest_text = manifest.read_text(encoding='utf-8')
manifest_text = manifest_text.replace('android:icon="@drawable/ic_aqim_logo"', 'android:icon="@drawable/aqim_logo_transparent_512"')
manifest.write_text(manifest_text, encoding='utf-8')

print('Applied Quran page reset and exact Aqim PNG branding.')
