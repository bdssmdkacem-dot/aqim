#!/usr/bin/env python3
"""Download the verbatim Tanzil Uthmani v1.1 Quran text for Aqim.

The file is fetched directly from Tanzil's official download endpoint.
It is intentionally NOT transformed: only the SURA|AYA| prefix is removed
when the app reads it. The Quran text itself is preserved verbatim.
"""

from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

URL = "https://tanzil.net/pub/download/download.php"
OUTPUT = Path("assets/quran/quran-uthmani.txt")
EXPECTED_AYAT = 6236

payload = urlencode(
    {
        "quranType": "uthmani",
        "outType": "txt",
        "marks": "false",
        "sajdah": "false",
        "rub": "false",
        "alef": "true",
        "me_quran": "false",
        "agree": "true",
    }
).encode("utf-8")

request = Request(URL, data=payload, method="POST", headers={"User-Agent": "Aqim/1.0"})
with urlopen(request, timeout=60) as response:
    data = response.read()

text = data.decode("utf-8-sig")
lines = [line for line in text.splitlines() if line.strip()]

if len(lines) != EXPECTED_AYAT:
    raise SystemExit(f"Tanzil integrity check failed: expected {EXPECTED_AYAT} ayat, got {len(lines)}")

seen = set()
for line in lines:
    parts = line.split("|", 2)
    if len(parts) != 3:
        raise SystemExit(f"Invalid Tanzil line format: {line[:80]!r}")
    surah, ayah, quran_text = parts
    key = (surah, ayah)
    if key in seen:
        raise SystemExit(f"Duplicate ayah key: {surah}:{ayah}")
    if not quran_text:
        raise SystemExit(f"Empty Quran text at {surah}:{ayah}")
    seen.add(key)

if lines[0].split("|", 2)[:2] != ["1", "1"]:
    raise SystemExit("Unexpected first ayah in Tanzil file")
if lines[-1].split("|", 2)[:2] != ["114", "6"]:
    raise SystemExit("Unexpected last ayah in Tanzil file")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(text, encoding="utf-8")
print(f"Downloaded Tanzil Uthmani v1.1: {len(lines)} ayat -> {OUTPUT}")
