#!/usr/bin/env python3
"""Resize/pad raw emulator screencaps to each store target size.

Reads PNGs from `store/raw/<name>.png` (produced by capture_screenshots.ps1)
and writes:

  Play Store (fastlane/metadata/android/en-US/images/ — the `supply` layout,
  uploaded by the promote lanes / `android update_listing`):
    phoneScreenshots/<i>_<name>.png       1080 x 1920
    sevenInchScreenshots/<i>_<name>.png   1200 x 1920
    tenInchScreenshots/<i>_<name>.png     1600 x 2560

  App Store (fastlane/screenshots/en-US/):
    iphone69_<i>_<name>.png     1320 x 2868
    ipadPro129_<i>_<name>.png   2048 x 2732
    ipadPro13_<i>_<name>.png    2064 x 2752

Each raw capture is contained-fit into the target dimension on a brand-green
background — preserves the actual app pixels rather than stretching/cropping.
"""

from PIL import Image
import os

ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR    = os.path.join(ROOT, 'store', 'raw')
PLAY_DIR   = os.path.join(ROOT, 'fastlane', 'metadata', 'android', 'en-US', 'images')
IOS_DIR    = os.path.join(ROOT, 'fastlane', 'screenshots', 'en-US')

# Match the brand bands in the existing PIL mockups so the padding looks
# intentional rather than letterboxed.
BG_COLOR   = (27, 94, 32)  # G900

# Captured in the order the patrol test produces them. Must stay in sync with the
# navigation order in lib/main_screenshots.dart and the $screens list in
# store/capture_screenshots.ps1 — the index here drives the NN_ store filename prefix.
SCREENS = [
    'team_landing',
    'teams',
    'formations',
    'live_game',
    'roster',
    'stats',
]

# (supply subdir, width, height) — subdir names are fastlane supply's convention.
PLAY_TARGETS = [
    ('phoneScreenshots',     1080, 1920),
    ('sevenInchScreenshots', 1200, 1920),
    ('tenInchScreenshots',   1600, 2560),
]

# Filename prefixes match fastlane deliver's device detection (iphone69,
# ipadPro129 = 12.9" 3rd gen APP_IPAD_PRO_3GEN_129, ipadPro13 = 13" M4).
IOS_TARGETS = [
    ('iphone69',   1320, 2868),
    ('ipadPro129', 2048, 2732),
    ('ipadPro13',  2064, 2752),
]


def fit_onto(src: Image.Image, w: int, h: int) -> Image.Image:
    """Aspect-fit `src` into a `w`x`h` canvas filled with BG_COLOR."""
    sw, sh = src.size
    scale = min(w / sw, h / sh)
    new_w, new_h = max(1, int(round(sw * scale))), max(1, int(round(sh * scale)))
    resized = src.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new('RGB', (w, h), BG_COLOR)
    canvas.paste(resized, ((w - new_w) // 2, (h - new_h) // 2))
    return canvas


def main() -> None:
    if not os.path.isdir(RAW_DIR):
        raise SystemExit(f'No raw captures found at {RAW_DIR}. '
                         f'Run capture_screenshots.ps1 first.')

    os.makedirs(PLAY_DIR, exist_ok=True)
    os.makedirs(IOS_DIR, exist_ok=True)

    found = []
    for i, name in enumerate(SCREENS, start=1):
        src_path = os.path.join(RAW_DIR, f'{name}.png')
        if not os.path.isfile(src_path):
            print(f'  ! missing {src_path} — skipping')
            continue
        found.append((i, name, src_path))

    if not found:
        raise SystemExit('No raw screenshots to process.')

    for i, name, src_path in found:
        src = Image.open(src_path).convert('RGB')
        for subdir, w, h in PLAY_TARGETS:
            out_dir = os.path.join(PLAY_DIR, subdir)
            os.makedirs(out_dir, exist_ok=True)
            out = os.path.join(out_dir, f'{i:02d}_{name}.png')
            fit_onto(src, w, h).save(out, 'PNG')
            print(f'  PLAY  {out}  ({w}x{h})')
        for prefix, w, h in IOS_TARGETS:
            out = os.path.join(IOS_DIR, f'{prefix}_{i:02d}_{name}.png')
            fit_onto(src, w, h).save(out, 'PNG')
            print(f'  IOS   {out}  ({w}x{h})')


if __name__ == '__main__':
    main()
