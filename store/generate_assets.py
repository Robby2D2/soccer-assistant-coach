#!/usr/bin/env python3
"""Generate Play Store listing assets for Soccer Assistant Coach."""

from PIL import Image, ImageDraw, ImageFont
import os

ICON_PATH = r'c:\Users\rdane\Documents\Projects\soccer-assistant-coach\soccer-assistant-coach.png'
OUT_DIR   = r'c:\Users\rdane\Documents\Projects\soccer-assistant-coach\store\assets'
os.makedirs(OUT_DIR, exist_ok=True)

# Brand colors
G900 = (27,  94,  32)
G800 = (46, 125,  50)
G700 = (56, 142,  60)
G500 = (76, 175,  80)
G200 = (165, 214, 167)
G100 = (200, 230, 201)
W    = (255, 255, 255)
S50  = (250, 250, 250)
S100 = (245, 245, 245)
S200 = (238, 238, 238)
S300 = (224, 224, 224)
S400 = (189, 189, 189)
S500 = (158, 158, 158)
S600 = (117, 117, 117)
S800 = ( 66,  66,  66)
S900 = ( 33,  33,  33)
FIELD_BG   = (39, 125, 44)
FIELD_DARK = (30, 100, 35)
FIELD_LINE = (255, 255, 255)
ACCENTS = [
    (25, 118, 210),
    (198,  40,  40),
    (230,  81,   0),
    (  0, 121, 107),
]


def fnt(size, bold=False):
    size = max(8, int(size))
    for p in [
        r'C:\Windows\Fonts\segoeuib.ttf' if bold else r'C:\Windows\Fonts\segoeui.ttf',
        r'C:\Windows\Fonts\arialbd.ttf'  if bold else r'C:\Windows\Fonts\arial.ttf',
    ]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            pass
    return ImageFont.load_default()


def tw(draw, text, font):
    bb = draw.textbbox((0, 0), text, font=font)
    return bb[2] - bb[0]


def th(draw, text, font):
    bb = draw.textbbox((0, 0), text, font=font)
    return bb[3] - bb[1]


def ct(draw, cx, cy, text, font, fill):
    draw.text((cx - tw(draw, text, font) // 2, cy - th(draw, text, font) // 2),
              text, fill=fill, font=font)


def rr(draw, bbox, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=int(radius), fill=fill, outline=outline, width=width)


def h_gradient(draw, y1, y2, img_w, c_top, c_bot):
    for y in range(y1, y2):
        t = (y - y1) / max(1, y2 - y1 - 1)
        c = tuple(int(c_top[i] * (1 - t) + c_bot[i] * t) for i in range(3))
        draw.line([(0, y), (img_w, y)], fill=c)


def v_gradient(draw, x1, x2, img_h, c_left, c_right):
    for x in range(x1, x2):
        t = (x - x1) / max(1, x2 - x1 - 1)
        c = tuple(int(c_left[i] * (1 - t) + c_right[i] * t) for i in range(3))
        draw.line([(x, 0), (x, img_h)], fill=c)


# ─── Feature Graphic 1024×500 ────────────────────────────────────────────────

def make_feature_graphic():
    FW, FH = 1024, 500
    img = Image.new('RGB', (FW, FH), G900)
    draw = ImageDraw.Draw(img)

    v_gradient(draw, 0, FW, FH, G900, G700)

    # decorative field circles (faint)
    for r in [200, 340, 480]:
        ox, oy = int(FW * 0.72), FH // 2
        draw.ellipse([ox - r, oy - r, ox + r, oy + r], outline=(255, 255, 255), width=1)
    draw.line([(FW // 2, FH // 2), (FW, FH // 2)], fill=(255, 255, 255), width=1)

    # app icon
    icon = Image.open(ICON_PATH).convert('RGBA')
    iw = 280
    icon = icon.resize((iw, iw), Image.LANCZOS)
    img.paste(icon, (56, FH // 2 - iw // 2), icon)

    draw.text((378, 56),  "Soccer",           fill=W,    font=fnt(82, bold=True))
    draw.text((378, 144), "Assistant Coach",  fill=G100, font=fnt(62, bold=True))
    draw.line([(378, 234), (838, 234)], fill=G500, width=3)
    draw.text((378, 248), "Manage your team like a pro", fill=G200, font=fnt(28))

    bullets = ["Build lineups & formations", "Track live game metrics", "Manage rosters & seasons"]
    for i, b in enumerate(bullets):
        by = 302 + i * 48
        draw.ellipse([378, by + 10, 396, by + 28], fill=G500)
        draw.text((406, by + 4), b, fill=W, font=fnt(24))

    img.save(os.path.join(OUT_DIR, 'feature_graphic.png'), 'PNG')
    print("✓ feature_graphic.png  (1024×500)")


# ─── Teams Screen ────────────────────────────────────────────────────────────

def make_teams_screen(IW, IH, fname, out_dir=None):
    img = Image.new('RGB', (IW, IH), S50)
    draw = ImageDraw.Draw(img)
    s = IW / 1080

    # marketing banner
    hdr_h = int(140 * s)
    h_gradient(draw, 0, hdr_h, IW, G900, G800)
    ct(draw, IW // 2, int(hdr_h * 0.38), "Your Teams at a Glance",
       fnt(int(44 * s), bold=True), W)
    ct(draw, IW // 2, int(hdr_h * 0.72), "Create and manage multiple teams & seasons",
       fnt(int(24 * s)), G100)
    y = hdr_h

    # status bar
    sb = int(36 * s)
    draw.rectangle([0, y, IW, y + sb], fill=G800)
    draw.text((int(16 * s), y + int(8 * s)), "9:41", fill=W, font=fnt(int(18 * s), bold=True))
    y += sb

    # app bar
    ab = int(64 * s)
    draw.rectangle([0, y, IW, y + ab], fill=G800)
    draw.text((int(24 * s), y + int(ab * 0.28)), "My Teams",
              fill=W, font=fnt(int(ab * 0.44), bold=True))
    for di in range(3):
        dx = IW - int(40 * s)
        dy = y + int(ab * 0.22) + di * int(ab * 0.26)
        draw.ellipse([dx - 4, dy - 4, dx + 4, dy + 4], fill=W)
    y += ab

    # search bar
    sch = int(52 * s)
    draw.rectangle([0, y, IW, y + sch], fill=W)
    m16 = int(16 * s)
    rr(draw, [m16, y + int(8 * s), IW - m16, y + sch - int(8 * s)],
       int(20 * s), fill=S100, outline=S200, width=1)
    draw.text((m16 + int(44 * s), y + int(15 * s)), "Search teams...",
              fill=S500, font=fnt(int(18 * s)))
    sx, sy, sr = m16 + int(22 * s), y + sch // 2, int(9 * s)
    draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], outline=S500, width=max(1, int(2 * s)))
    draw.line([sx + sr - 2, sy + sr - 2, sx + sr + 5, sy + sr + 5], fill=S500, width=max(1, int(2 * s)))
    y += sch

    draw.line([0, y, IW, y], fill=S200, width=1)
    y += int(6 * s)

    sec_h = int(40 * s)
    draw.text((int(24 * s), y + int(10 * s)), "ACTIVE TEAMS",
              fill=S500, font=fnt(int(14 * s), bold=True))
    y += sec_h

    # team cards
    teams = [
        (ACCENTS[0], "Lightning FC",     "Season 2024-25",      14),
        (ACCENTS[1], "Thunder United",   "Season 2024-25",      11),
        (ACCENTS[2], "Rec League Stars", "Season Spring 2025",   9),
        (ACCENTS[3], "Junior Squad",     "Season 2024-25",      16),
    ]
    card_h = int(88 * s)
    gap    = int(10 * s)
    m = int(16 * s)
    for accent, name, season, players in teams:
        rr(draw, [m, y, IW - m, y + card_h], int(12 * s), fill=W, outline=S200, width=1)
        rr(draw, [m + int(12 * s), y + int(20 * s), m + int(52 * s), y + card_h - int(20 * s)],
           int(10 * s), fill=accent)
        draw.text((m + int(64 * s), y + int(12 * s)), name,
                  fill=S900, font=fnt(int(22 * s), bold=True))
        draw.text((m + int(64 * s), y + int(40 * s)), season,
                  fill=S600, font=fnt(int(17 * s)))
        draw.text((m + int(64 * s), y + int(60 * s)), f"{players} players",
                  fill=S500, font=fnt(int(16 * s)))
        cx2 = IW - m - int(24 * s)
        cy2 = y + card_h // 2
        draw.polygon([(cx2 - int(6 * s), cy2 - int(10 * s)),
                      (cx2 + int(2 * s), cy2),
                      (cx2 - int(6 * s), cy2 + int(10 * s))], fill=S300)
        y += card_h + gap

    # archived section
    y += int(8 * s)
    draw.text((int(24 * s), y + int(10 * s)), "ARCHIVED",
              fill=S500, font=fnt(int(14 * s), bold=True))
    y += sec_h
    rr(draw, [m, y, IW - m, y + card_h], int(12 * s), fill=S100, outline=S200, width=1)
    rr(draw, [m + int(12 * s), y + int(20 * s), m + int(52 * s), y + card_h - int(20 * s)],
       int(10 * s), fill=S300)
    draw.text((m + int(64 * s), y + int(12 * s)), "Old Club FC",
              fill=S500, font=fnt(int(22 * s), bold=True))
    draw.text((m + int(64 * s), y + int(40 * s)), "Season 2023-24  |  Archived",
              fill=S500, font=fnt(int(17 * s)))

    nav_h = int(56 * s)

    # quick-stats card
    y += int(20 * s)
    card2_h = int(120 * s)
    G50_c = (232, 245, 233)
    G200_c = (165, 214, 167)
    rr(draw, [m, y, IW - m, y + card2_h], int(14 * s), fill=G50_c, outline=G200_c, width=1)
    stats = [("4", "Teams"), ("50", "Players"), ("12", "Seasons")]
    col_w = (IW - 2 * m) // len(stats)
    for i, (val, lbl) in enumerate(stats):
        sx = m + i * col_w + col_w // 2
        ct(draw, sx, y + int(40 * s), val, fnt(int(32 * s), bold=True), G800)
        ct(draw, sx, y + int(80 * s), lbl, fnt(int(18 * s)), S600)
        if i < len(stats) - 1:
            draw.line([m + (i + 1) * col_w, y + int(20 * s),
                       m + (i + 1) * col_w, y + card2_h - int(20 * s)], fill=S200, width=1)

    # FAB
    fcx, fcy, fr = IW - int(80 * s), IH - nav_h - int(80 * s), int(28 * s)
    draw.ellipse([fcx - fr, fcy - fr, fcx + fr, fcy + fr], fill=G500)
    lw = max(2, int(3 * s))
    draw.rectangle([fcx - int(14 * s), fcy - lw // 2, fcx + int(14 * s), fcy + lw // 2], fill=W)
    draw.rectangle([fcx - lw // 2, fcy - int(14 * s), fcx + lw // 2, fcy + int(14 * s)], fill=W)

    # nav bar
    ny = IH - nav_h
    draw.rectangle([0, ny, IW, IH], fill=W)
    draw.line([0, ny, IW, ny], fill=S200, width=1)
    nav_labels = [("Teams", True), ("Games", False), ("Settings", False)]
    for i, (label, active) in enumerate(nav_labels):
        nx = IW * (i + 1) // (len(nav_labels) + 1)
        lf = fnt(int(13 * s), bold=active)
        lc = G800 if active else S500
        if active:
            lw2 = tw(draw, label, lf) + int(28 * s)
            rr(draw, [nx - lw2 // 2, ny + int(5 * s), nx + lw2 // 2, ny + int(30 * s)],
               int(12 * s), fill=G100)
        ct(draw, nx, ny + nav_h // 2, label, lf, lc)

    img.save(os.path.join(out_dir or OUT_DIR, fname), 'PNG')
    print(f"✓ {fname}  ({IW}×{IH})")


# ─── Lineup Screen ───────────────────────────────────────────────────────────

def draw_field(draw, fx, fy, fw, fh, s):
    draw.rectangle([fx, fy, fx + fw, fy + fh], fill=FIELD_BG)
    sw = fw // 10
    for i in range(10):
        if i % 2 == 0:
            draw.rectangle([fx + i * sw, fy, fx + (i + 1) * sw, fy + fh], fill=FIELD_DARK)

    lw  = max(2, int(s * 3))
    pad = int(fw * 0.05)
    mx, my = fx + fw // 2, fy + fh // 2

    draw.rectangle([fx + pad, fy + pad, fx + fw - pad, fy + fh - pad], outline=FIELD_LINE, width=lw)
    draw.line([fx + pad, my, fx + fw - pad, my], fill=FIELD_LINE, width=lw)

    cr = int(fw * 0.11)
    draw.ellipse([mx - cr, my - cr, mx + cr, my + cr], outline=FIELD_LINE, width=lw)
    cd = max(3, int(s * 4))
    draw.ellipse([mx - cd, my - cd, mx + cd, my + cd], fill=FIELD_LINE)

    gaw = int(fw * 0.32)
    gah = int(fh * 0.09)
    gax = mx - gaw // 2
    draw.rectangle([gax, fy + pad, gax + gaw, fy + pad + gah], outline=FIELD_LINE, width=lw)
    draw.rectangle([gax, fy + fh - pad - gah, gax + gaw, fy + fh - pad], outline=FIELD_LINE, width=lw)

    ar = int(fw * 0.03)
    for (cx2, cy2, a1, a2) in [
        (fx + pad,      fy + pad,      0,   90),
        (fx + fw - pad, fy + pad,      90,  180),
        (fx + fw - pad, fy + fh - pad, 180, 270),
        (fx + pad,      fy + fh - pad, 270, 360),
    ]:
        draw.arc([cx2 - ar, cy2 - ar, cx2 + ar, cy2 + ar], a1, a2, fill=FIELD_LINE, width=lw)


def make_lineup_screen(IW, IH, fname, out_dir=None):
    img = Image.new('RGB', (IW, IH), (24, 24, 24))
    draw = ImageDraw.Draw(img)
    s = IW / 1080

    hdr_h = int(140 * s)
    h_gradient(draw, 0, hdr_h, IW, G900, G800)
    ct(draw, IW // 2, int(hdr_h * 0.38), "Build Lineups Instantly",
       fnt(int(44 * s), bold=True), W)
    ct(draw, IW // 2, int(hdr_h * 0.72), "Drag & assign players to any formation",
       fnt(int(24 * s)), G100)
    y = hdr_h

    sb = int(36 * s)
    draw.rectangle([0, y, IW, y + sb], fill=G900)
    draw.text((int(16 * s), y + int(8 * s)), "9:41", fill=W, font=fnt(int(18 * s), bold=True))
    y += sb

    ab = int(64 * s)
    draw.rectangle([0, y, IW, y + ab], fill=G900)
    draw.text((int(24 * s), y + int(ab * 0.28)), "Lineup Builder",
              fill=W, font=fnt(int(ab * 0.44), bold=True))
    lbl_f = fnt(int(ab * 0.38), bold=True)
    draw.text((IW - int(24 * s) - tw(draw, "4-3-3", lbl_f), y + int(ab * 0.3)),
              "4-3-3", fill=G100, font=lbl_f)
    y += ab

    # formation chips
    ch_h = int(52 * s)
    draw.rectangle([0, y, IW, y + ch_h], fill=(24, 24, 24))
    chip_x = int(IW * 0.04)
    for chip in ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1"]:
        cf = fnt(int(18 * s), bold=(chip == "4-3-3"))
        cw = tw(draw, chip, cf) + int(32 * s)
        if chip == "4-3-3":
            rr(draw, [chip_x, y + int(8 * s), chip_x + cw, y + ch_h - int(8 * s)],
               int(16 * s), fill=G800)
            ct(draw, chip_x + cw // 2, y + ch_h // 2, chip, cf, W)
        else:
            rr(draw, [chip_x, y + int(8 * s), chip_x + cw, y + ch_h - int(8 * s)],
               int(16 * s), outline=S800, width=1)
            ct(draw, chip_x + cw // 2, y + ch_h // 2, chip, cf, S500)
        chip_x += cw + int(10 * s)
    y += ch_h

    nav_h = int(56 * s)
    fm = int(20 * s)
    fw = IW - 2 * fm
    fh = IH - y - int(8 * s) - nav_h - int(16 * s)

    draw_field(draw, fm, y + int(8 * s), fw, fh, s)

    # players (4-3-3)
    pr  = max(18, int(s * 28))
    pf  = fnt(max(10, int(pr * 0.65)), bold=True)
    pad = int(fw * 0.05)
    ix  = fm + pad
    iy  = y + int(8 * s) + pad
    ifw = fw - 2 * pad
    ifh = fh - 2 * pad

    def fp(col, row):
        return (int(ix + ifw * col), int(iy + ifh * row))

    positions = [
        (fp(0.50, 0.88), (230, 170,  0), "GK"),
        (fp(0.15, 0.70), ACCENTS[0], "LB"),
        (fp(0.38, 0.72), ACCENTS[0], "CB"),
        (fp(0.62, 0.72), ACCENTS[0], "CB"),
        (fp(0.85, 0.70), ACCENTS[0], "RB"),
        (fp(0.20, 0.50), ACCENTS[2], "LM"),
        (fp(0.50, 0.48), ACCENTS[2], "CM"),
        (fp(0.80, 0.50), ACCENTS[2], "RM"),
        (fp(0.20, 0.26), ACCENTS[1], "LW"),
        (fp(0.50, 0.22), ACCENTS[1], "CF"),
        (fp(0.80, 0.26), ACCENTS[1], "RW"),
    ]
    for (px, py), color, label in positions:
        draw.ellipse([px - pr + 1, py - pr + 2, px + pr + 1, py + pr + 2], fill=(0, 40, 0))
        draw.ellipse([px - pr, py - pr, px + pr, py + pr],
                     fill=color, outline=W, width=max(2, int(s * 2)))
        ct(draw, px, py - 1, label, pf, W)

    # nav bar
    ny = IH - nav_h
    draw.rectangle([0, ny, IW, IH], fill=(24, 24, 24))
    draw.line([0, ny, IW, ny], fill=S800, width=1)
    nav_labels = [("Teams", False), ("Games", True), ("Settings", False)]
    for i, (label, active) in enumerate(nav_labels):
        nx = IW * (i + 1) // (len(nav_labels) + 1)
        lf = fnt(int(13 * s), bold=active)
        lc = G500 if active else S600
        if active:
            lw2 = tw(draw, label, lf) + int(28 * s)
            rr(draw, [nx - lw2 // 2, ny + int(5 * s), nx + lw2 // 2, ny + int(30 * s)],
               int(12 * s), fill=(40, 68, 40))
        ct(draw, nx, ny + nav_h // 2, label, lf, lc)

    img.save(os.path.join(out_dir or OUT_DIR, fname), 'PNG')
    print(f"✓ {fname}  ({IW}×{IH})")


# ─── Run ─────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    make_feature_graphic()

    make_teams_screen(1080, 1920, 'phone_01_teams.png')
    make_lineup_screen(1080, 1920, 'phone_02_lineup.png')

    make_teams_screen(1200, 1920, 'tablet7_01_teams.png')
    make_lineup_screen(1200, 1920, 'tablet7_02_lineup.png')

    make_teams_screen(1600, 2560, 'tablet10_01_teams.png')
    make_lineup_screen(1600, 2560, 'tablet10_02_lineup.png')

    print(f"\nAll assets saved to:\n{OUT_DIR}")

    # iOS App Store screenshots
    IOS_DIR = r'c:\Users\rdane\Documents\Projects\soccer-assistant-coach\fastlane\screenshots\en-US'
    os.makedirs(IOS_DIR, exist_ok=True)

    # iPhone 6.9" (required — iPhone 16 Pro Max): 1320×2868
    make_teams_screen(1320, 2868, 'iphone69_01_teams.png', out_dir=IOS_DIR)
    make_lineup_screen(1320, 2868, 'iphone69_02_lineup.png', out_dir=IOS_DIR)

    # iPhone 6.7" (iPhone 14 Plus / 15 Plus / 16 Plus): 1290×2796
    make_teams_screen(1290, 2796, 'iphone67_01_teams.png', out_dir=IOS_DIR)
    make_lineup_screen(1290, 2796, 'iphone67_02_lineup.png', out_dir=IOS_DIR)

    print(f"\nAll iOS screenshots saved to:\n{IOS_DIR}")
