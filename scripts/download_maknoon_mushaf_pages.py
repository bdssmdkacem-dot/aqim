#!/usr/bin/env python3
"""Download and validate the pinned Maknoon Quran page images.

Build-only asset preparation. This script intentionally does not modify the
Quran UI or any Quran navigation behavior.

The pinned upstream set contains legitimate pages with more than one native
PNG dimension, so validation must not assume one global width/height per
reading. It still rejects malformed/non-PNG files and implausible dimensions.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.request import Request, urlopen
import struct

ROOT = Path("assets/quran")
SOURCE_REPO = "https://raw.githubusercontent.com/maknon/Quran/44115bae36fef56dd904a78e0c4eed8932c0b1c7"
PAGE_COUNT = 604

# Bounds cover the actual pinned Maknoon pages (including pages such as
# 771x1040, 941x1552 and 941x1555) while rejecting obviously bad responses.
MIN_WIDTH, MAX_WIDTH = 700, 1200
MIN_HEIGHT, MAX_HEIGHT = 1000, 1800


def png_size(data: bytes):
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def validate_page(kind: str, page: int, data: bytes):
    width, height = png_size(data)
    if not (MIN_WIDTH <= width <= MAX_WIDTH and MIN_HEIGHT <= height <= MAX_HEIGHT):
        raise ValueError(f"{kind} page {page}: invalid dimensions ({width}, {height})")
    if len(data) < 1000:
        raise ValueError(f"{kind} page {page}: file is unexpectedly small")
    return width, height


def download_one(kind: str, page: int):
    directory = ROOT / kind / "pages"
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / f"{page:03d}.png"

    if target.exists() and target.stat().st_size > 1000:
        validate_page(kind, page, target.read_bytes())
        return page, "cached"

    url = f"{SOURCE_REPO}/pages-{kind}/{page}.png"
    request = Request(url, headers={"User-Agent": "AQIM-build/1.1"})
    with urlopen(request, timeout=60) as response:
        data = response.read()

    validate_page(kind, page, data)
    target.write_bytes(data)
    return page, "downloaded"


def main():
    commit = SOURCE_REPO.rsplit("/", 1)[-1]
    print(f"Downloading Maknoon/KFQPC mushaf pages from pinned commit {commit}")

    for kind in ("hafs", "warsh"):
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
            raise SystemExit(
                "\n".join([f"{kind}: {len(failures)} download/validation failures"] + failures[:20])
            )

        files = sorted((ROOT / kind / "pages").glob("*.png"))
        expected = [f"{p:03d}.png" for p in range(1, PAGE_COUNT + 1)]
        actual = [p.name for p in files]
        if actual != expected:
            missing = sorted(set(expected) - set(actual))
            extra = sorted(set(actual) - set(expected))
            raise SystemExit(
                f"{kind}: page set mismatch; missing={missing[:20]} extra={extra[:20]}"
            )
        print(f"{kind}: verified {len(files)} pages ({downloaded} downloaded, {cached} cached)")

    (ROOT / "SOURCE.md").write_text(
        "# AQIM Quran page source\n\n"
        "Pages used by AQIM are the PNG page rendering published by Maknoon in:\n"
        "https://www.maknoon.com/community/threads/172/\n\n"
        "Pinned source repository commit: `44115bae36fef56dd904a78e0c4eed8932c0b1c7`.\n\n"
        "Hafs: 604 pages.\n"
        "Warsh: 604 pages.\n\n"
        "The page images are downloaded during the release build so the Git repository does not need to store the binary page set.\n"
    )


if __name__ == "__main__":
    main()
