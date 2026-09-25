#!/usr/bin/env python3
"""Prepare the lightweight offline Warsh Quran dataset for AQIM.

The release build downloads the official versioned Quranpedia mushaf-4 dump,
keeps only the fields needed by the reader, and writes a compact JSON asset.
No page PNGs are bundled or downloaded anymore.
"""

from __future__ import annotations

import gzip
import json
import urllib.request
from pathlib import Path

SOURCE_URL = "https://api.quranpedia.net/dumps/mushafs-4.json.gz"
SOURCE_PAGE = "https://quranpedia.net/dumps"
EXPECTED_VERSION = "2026-09-25"
OUT = Path("assets/quran/warsh.json")
PAGE_COUNT = 604
SURAH_COUNT = 114


def download() -> bytes:
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "AQIM-build/2.0", "Accept": "application/gzip"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def main() -> None:
    print(f"Downloading Warsh Quran dataset from {SOURCE_URL}")
    payload = gzip.decompress(download())
    root = json.loads(payload.decode("utf-8"))

    if not isinstance(root, dict):
        raise SystemExit("Warsh dump is not a JSON object")

    license_info = root.get("license") or {}
    version = license_info.get("version") if isinstance(license_info, dict) else None
    if version and version != EXPECTED_VERSION:
        raise SystemExit(
            f"Unexpected Quranpedia dump version: {version}; expected {EXPECTED_VERSION}"
        )

    surahs = root.get("surahs")
    if not isinstance(surahs, list) or len(surahs) != SURAH_COUNT:
        raise SystemExit("Warsh dump does not contain exactly 114 surahs")

    compact_surahs = []
    seen_pages = set()
    total_ayahs = 0

    for raw_surah in surahs:
        number = int(raw_surah["id"])
        name = str(raw_surah["name"])
        ayahs = raw_surah.get("ayahs")
        if not isinstance(ayahs, list) or not ayahs:
            raise SystemExit(f"Warsh surah {number} has no ayahs")

        compact_ayahs = []
        for raw_ayah in ayahs:
            page = int(raw_ayah["page_number"])
            text = str(raw_ayah["text"]).strip()
            mapped = raw_ayah.get("number_in_hafs") or []
            mapped = [int(value) for value in mapped]
            if not 1 <= page <= PAGE_COUNT or not text or not mapped:
                raise SystemExit(
                    f"Invalid Warsh ayah in surah {number}: {raw_ayah.get('number')}"
                )
            seen_pages.add(page)
            compact_ayahs.append(
                {
                    "number": int(raw_ayah["number"]),
                    "page": page,
                    "text": text,
                    "number_in_hafs": mapped,
                }
            )
            total_ayahs += 1

        compact_surahs.append(
            {"number": number, "name": name, "ayahs": compact_ayahs}
        )

    if seen_pages != set(range(1, PAGE_COUNT + 1)):
        missing = sorted(set(range(1, PAGE_COUNT + 1)) - seen_pages)
        raise SystemExit(f"Warsh page map is incomplete; missing pages: {missing[:20]}")

    output = {
        "source": "Quranpedia.net",
        "sourceUrl": SOURCE_PAGE,
        "version": version or EXPECTED_VERSION,
        "mushafId": 4,
        "pageCount": PAGE_COUNT,
        "ayahCount": total_ayahs,
        "surahs": compact_surahs,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps(output, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(
        f"Warsh dataset ready: {total_ayahs} ayahs / "
        f"{PAGE_COUNT} pages / {SURAH_COUNT} surahs"
    )
    print(f"Source version: {output['version']}")


if __name__ == "__main__":
    main()
