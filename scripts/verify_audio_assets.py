#!/usr/bin/env python3
"""Verify every bundled prayer/adhkar MP3 exists, has a valid stream, and decodes."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    "android/app/src/main/res/raw": [
        "alarm_fajr_1.mp3", "alarm_fajr_2.mp3", "alarm_fajr_3.mp3",
        "alarm_dhuhr.mp3", "alarm_asr.mp3", "alarm_maghrib.mp3",
        "alarm_isha.mp3", "alarm_jomoaa.mp3",
    ],
    "assets/adhan": [
        "azan-fajr.mp3", "azan-Fajr-madina.mp3", "azan-fajr-maghribi.mp3",
        "azan_maroc_1.mp3", "azan_maroc_2.mp3", "azan_1.mp3",
        "azan_2.mp3", "azan_3.mp3", "azan_abdebast.mp3",
    ],
    "assets/audio/before": [
        "tarid_athan.mp3", "dua_athan.mp3", "dua_bayn_athan_iqama.mp3",
    ],
    "assets/audio/after": [
        "istighfar.mp3", "sayid_salam.mp3", "tahlil_mulk.mp3", "tasbih.mp3",
        "tahmid.mp3", "takbir.mp3", "tahlil_complete.mp3", "ayat_kursi.mp3",
        "al_ikhlas.mp3", "al_falaq.mp3", "an_nas.mp3",
    ],
}

def run(args):
    return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=False)

def main():
    missing_tools = [tool for tool in ("ffprobe", "ffmpeg")
                     if not run(["bash", "-lc", f"command -v {tool}"]).returncode == 0]
    if missing_tools:
        print("ERROR: missing audio validation tools: " + ", ".join(missing_tools))
        return 2

    failures = []
    checked = 0
    for folder, names in REQUIRED.items():
        for name in names:
            path = ROOT / folder / name
            label = f"{folder}/{name}"
            if not path.is_file() or path.stat().st_size == 0:
                failures.append(f"MISSING/EMPTY: {label}")
                continue
            probe = run(["ffprobe", "-v", "error", "-select_streams", "a:0",
                         "-show_entries", "stream=codec_name,duration",
                         "-of", "default=noprint_wrappers=1", str(path)])
            if probe.returncode != 0 or "codec_name=" not in probe.stdout:
                failures.append(f"NO VALID AUDIO STREAM: {label}: {probe.stderr.strip()}")
                continue
            decode = run(["ffmpeg", "-v", "error", "-i", str(path),
                          "-map", "0:a:0", "-f", "null", "-"])
            if decode.returncode != 0:
                failures.append(f"DECODE FAILED: {label}: {decode.stderr.strip()}")
                continue
            checked += 1
            print(f"PASS {label} ({path.stat().st_size} bytes)")
    print(f"Audio asset validation: {checked}/{sum(len(v) for v in REQUIRED.values())} files decoded.")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("All required notification and adhkar audio assets passed stream/decode checks.")
    print("Note: this validates bundled file integrity, not audible playback on a physical phone.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
