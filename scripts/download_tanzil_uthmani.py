#!/usr/bin/env python3
"""Fetch and verify Tanzil Uthmani-all v1.1 for Aqim.

The Quran payload is copied verbatim from the Tanzil-derived corpus. This
script must never normalize, strip, replace, or otherwise rewrite Quran text.
"""
import json
from pathlib import Path
from urllib.request import Request, urlopen

# Uthmani-all is the full Uthmani variant in the Tanzil-derived corpus.
# It is pinned to the repository's main source rather than a changing Tanzil
# download endpoint, which previously caused CI 404 failures.
SOURCE_URL = "https://raw.githubusercontent.com/dotquran/corpus/main/processed/uthmani-all/quran-uthmani-all.json"
OUTPUT = Path("assets/quran/quran-uthmani.txt")
EXPECTED_AYAT = 6236

request = Request(SOURCE_URL, headers={"User-Agent": "Aqim/1.0"})
with urlopen(request, timeout=60) as response:
    data = json.loads(response.read().decode("utf-8"))

metadata = data.get("metadata", {})
if metadata.get("source") != "Tanzil Project":
    raise SystemExit(f"Unexpected Quran source: {metadata.get('source')!r}")
if metadata.get("version") != "Uthmani, Version 1.1":
    raise SystemExit(f"Unexpected Quran version: {metadata.get('version')!r}")

lines = []
seen = set()
for surah in data.get("surahs", []):
    surah_number = int(surah["number"])
    for ayah in surah.get("ayahs", []):
        ayah_number = int(ayah["number"])
        if ayah_number == 0:
            continue
        quran_text = ayah["text"]
        if not isinstance(quran_text, str) or not quran_text:
            raise SystemExit(f"Empty Quran text at {surah_number}:{ayah_number}")
        key = (surah_number, ayah_number)
        if key in seen:
            raise SystemExit(f"Duplicate ayah key: {surah_number}:{ayah_number}")
        seen.add(key)
        # Preserve the Quran payload exactly. Marks are metadata and are not
        # injected into the source text; the app renders sajda separately.
        lines.append(f"{surah_number}|{ayah_number}|{quran_text}")

if len(lines) != EXPECTED_AYAT:
    raise SystemExit(f"Tanzil integrity check failed: expected {EXPECTED_AYAT} ayat, got {len(lines)}")
if lines[0].split("|", 2)[:2] != ["1", "1"]:
    raise SystemExit("Unexpected first ayah in Tanzil file")
if lines[-1].split("|", 2)[:2] != ["114", "6"]:
    raise SystemExit("Unexpected last ayah in Tanzil file")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Verified Tanzil Uthmani-all v1.1: {len(lines)} ayat -> {OUTPUT}")
