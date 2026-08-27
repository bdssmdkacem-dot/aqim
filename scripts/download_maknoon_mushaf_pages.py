#!/usr/bin/env python3
"""Download the exact Maknoon Quran page images used by the selected source.

Source: https://www.maknoon.com/community/threads/172/
The Maknoon project states that these PNG pages were converted from the
recent digital Adobe Illustrator edition of the King Fahd Complex and are
intended for direct use in computer/phone applications.

The source repository is pinned to a commit so a future upstream change
cannot silently change the pages shipped in AQIM.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.request import Request, urlopen
import struct

ROOT = Path("assets/quran")
SOURCE_REPO = "https://raw.githubusercontent.com/maknon/Quran/44115bae36fef56dd904a78e0c4eed8932c0b1c7"
PAGE_COUNT = 604
CONFIG = {
    "hafs": (944, 1555),
    "warsh": (976, 1555),
}


def png_size(data: bytes):
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    width, height = struct.unpack(">II", data[16:24])
    return width, height


def download_one(kind: str, page: int):
    directory = ROOT / kind / "pages"
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / f"{page:03d}.png"
    if target.exists() and target.stat().st_size > 1000:
        data = target.read_bytes()
        if png_size(data) == CONFIG[kind]:
            return page, "cached"
        target.unlink()

    url = f"{SOURCE_REPO}/pages-{kind}/{page}.png"
    request = Request(url, headers={"User-Agent": "AQIM-build/1.0"})
    with urlopen(request, timeout=60) as response:
        data = response.read()

    if png_size(data) != CONFIG[kind]:
        raise ValueError(f"{kind} page {page}: unexpected dimensions {png_size(data)}")
    if len(data) < 1000:
        raise ValueError(f"{kind} page {page}: file is unexpectedly small")
    target.write_bytes(data)
    return page, "downloaded"


def main():
    print(f"Downloading Maknoon/KFQPC mushaf pages from pinned commit {SOURCE_REPO.rsplit('/', 1)[-1]}")
    for kind in CONFIG:
        print(f"Preparing {kind}: {PAGE_COUNT} pages")
        failures = []
        downloaded = cached = 0
        with ThreadPoolExecutor(max_workers=12) as pool:
            futures = [pool.submit(download_one, kind, p) for p in range(1, PAGE_COUNT + 1)]
            for future in as_completed(futures):
                try:
                    _, status = future.result()
                    if status == "cached":
                        cached += 1
                    else:
                        downloaded += 1
                except Exception as exc:
                    failures.append(str(exc))
        if failures:
            raise SystemExit("\n".join([f"{kind}: {len(failures)} download/validation failures"] + failures[:20]))

        files = sorted((ROOT / kind / "pages").glob("*.png"))
        expected = [f"{p:03d}.png" for p in range(1, PAGE_COUNT + 1)]
        actual = [p.name for p in files]
        if actual != expected:
            missing = sorted(set(expected) - set(actual))
            extra = sorted(set(actual) - set(expected))
            raise SystemExit(f"{kind}: page set mismatch; missing={missing[:20]} extra={extra[:20]}")
        print(f"{kind}: verified {len(files)} pages ({downloaded} downloaded, {cached} cached)")

    (ROOT / "SOURCE.md").write_text(
        "# AQIM Quran page source\n\n"
        "Pages used by AQIM are the PNG page rendering published by Maknoon in:\n"
        "https://www.maknoon.com/community/threads/172/\n\n"
        "Maknoon states that the pages were converted from the recent digital Adobe Illustrator edition of the King Fahd Glorious Quran Printing Complex.\n"
        "Pinned source repository commit: `44115bae36fef56dd904a78e0c4eed8932c0b1c7`.\n\n"
        "Hafs: 604 pages, 944x1555 PNG.\n"
        "Warsh: 604 pages, 976x1555 PNG.\n\n"
        "The page images are downloaded during the release build so the Git repository does not need to store the binary page set.\n"
    )


if __name__ == "__main__":
    main()
