#!/usr/bin/env python3
"""Forge the Synthwave84 Knight spritesheet.

Atlas: 8 cols x 9 rows of 192x208 frames (1536x1872).
Rows: idle, running-right, running-left, waving, jumping, failed,
waiting, running, review. Six frames per state; cols 6-7 duplicate
0 and 1 because renderers ignore them.

Art is drawn on a 96x104 logical grid and scaled 2x nearest, so the
knight reads as a sprite instead of an 8px blob. Sword sits on the
viewer's left (the knight's right hand). Shield sits on the viewer's
right. The shield bears an iron cross: a cross pattee, blood on black,
steel-edged, concave ends. Not a plus.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

HERMES_PET = Path.home() / ".hermes" / "pets" / "synthwave84-knight"
REPO = Path(__file__).resolve().parent
LW, LH = 96, 104
SCALE = 2
FW, FH = LW * SCALE, LH * SCALE  # 192 x 208
COLS, ROWS = 8, 9

# Synthwave84 livery. Grimdark templar: near-black, steel, ember, blood.
INK = (8, 8, 12, 255)
ARMOR = (22, 24, 30, 255)
ARMOR_HI = (48, 52, 60, 255)
STEEL = (143, 149, 156, 255)
BONE = (216, 211, 200, 255)
BLOOD = (193, 18, 31, 255)
BLOOD_DK = (106, 12, 20, 255)
EMBER = (193, 18, 31, 255)       # plume — same blood as the cross
EMBER_DK = (106, 12, 20, 255)
FIELD = (16, 16, 20, 255)
VISOR = (220, 36, 48, 255)       # lit blood, not ember
VISOR_DIM = (122, 14, 22, 255)


def new():
    return Image.new("RGBA", (LW, LH), (0, 0, 0, 0))


def rect(d, x0, y0, x1, y1, color):
    if x1 < x0:
        x0, x1 = x1, x0
    if y1 < y0:
        y0, y1 = y1, y0
    d.rectangle([x0, y0, x1, y1], fill=color)


def shift(im, dx, dy):
    """Translate without the negative-paste sliver bug."""
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sx0 = max(0, -dx)
    sy0 = max(0, -dy)
    sx1 = im.width - max(0, dx)
    sy1 = im.height - max(0, dy)
    if sx1 <= sx0 or sy1 <= sy0:
        return out
    out.paste(im.crop((sx0, sy0, sx1, sy1)), (max(0, dx), max(0, dy)))
    return out


def squash(im, yscale, foot_y):
    """Squash/stretch around the foot line. yscale < 1 crouches."""
    nh = max(1, int(round(im.height * yscale)))
    scaled = im.resize((im.width, nh), Image.Resampling.NEAREST)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    top = foot_y - nh
    # crop if the head leaves the canvas
    src_top = max(0, -top)
    dst_top = max(0, top)
    src_bot = min(nh, im.height - top)
    if src_bot > src_top:
        out.paste(scaled.crop((0, src_top, im.width, src_bot)), (0, dst_top))
    return out


# Filled cross pattee. Ends bow in. Neck is narrower than the flare.
# This is the shape that reads as an iron cross, not a plus and not a diamond.
IRON = [
    "......o.o......",
    ".....oxxxo.....",
    "....oxxxxxo....",
    "...oxx.x.xxo...",
    "..oxx..x..xxo..",
    ".oxx...x...xxo.",
    "oxx....x....xxo",
    "xxxxxxx.xxxxxxx",
    "oxx....x....xxo",
    ".oxx...x...xxo.",
    "..oxx..x..xxo..",
    "...oxx.x.xxo...",
    "....oxxxxxo....",
    ".....oxxxo.....",
    "......o.o......",
]


def iron_cross(draw, cx, cy, color, edge, r=7):
    """Stamp a cross pattee. `r` is unused; the bitmap is the shape."""
    del r
    h = len(IRON)
    w = len(IRON[0])
    x0 = cx - w // 2
    y0 = cy - h // 2
    for row, line in enumerate(IRON):
        for col, ch in enumerate(line):
            if ch == "o":
                rect(draw, x0 + col, y0 + row, x0 + col, y0 + row, edge)
            elif ch == "x":
                rect(draw, x0 + col, y0 + row, x0 + col, y0 + row, color)


def draw_shield(d, ox, oy, gleam=None):
    """Heater. Black field, steel rim, blood iron cross."""
    cx = 70 + ox
    top = 34 + oy
    bot = 62 + oy
    left = 58 + ox
    right = 82 + ox
    # rim, then field inset by 1
    rim = [
        (left - 1, top), (right + 1, top),
        (right + 2, top + 6),
        (cx + 2, bot + 3),
        (cx - 2, bot + 3),
        (left - 2, top + 6),
    ]
    field = [
        (left + 2, top + 2), (right - 2, top + 2),
        (right - 1, top + 7),
        (cx, bot - 1),
        (left + 1, top + 7),
    ]
    d.polygon(rim, fill=STEEL)
    d.polygon(field, fill=FIELD)
    iron_cross(d, cx, top + 13, BLOOD, STEEL)
    if gleam is not None:
        gx = left + 2 + gleam
        rect(d, gx, top + 2, gx + 1, top + 3, BONE)


def draw_sword(angle):
    """Raised blade on the viewer's left. Rotated about the shoulder."""
    im = new()
    d = ImageDraw.Draw(im)
    # shoulder / grip anchor
    sx, sy = 30, 36
    # grip
    rect(d, sx - 1, sy - 2, sx + 1, sy + 3, BLOOD_DK)
    # crossguard
    rect(d, sx - 5, sy - 4, sx + 5, sy - 2, STEEL)
    rect(d, sx - 5, sy - 4, sx - 4, sy - 2, BONE)
    # blade, straight up
    rect(d, sx - 1, 8, sx + 1, sy - 5, BONE)
    rect(d, sx, 6, sx, 9, BONE)  # tip
    rect(d, sx - 1, 14, sx - 1, 20, STEEL)  # fuller edge
    if angle:
        im = im.rotate(angle, resample=Image.Resampling.NEAREST, center=(sx, sy))
    return im


def draw_body(plume_dx=0, visor="on", legs="stand", lean=0, stars=None):
    im = new()
    d = ImageDraw.Draw(im)
    # plume — blood, same red as the cross
    px = 46 + plume_dx
    rect(d, px, 4, px + 4, 8, EMBER)
    rect(d, px - 1, 7, px + 5, 11, EMBER)
    rect(d, px, 10, px + 3, 14, EMBER_DK)
    rect(d, px + 1, 3, px + 2, 5, EMBER)

    # great helm
    rect(d, 39, 13, 57, 28, INK)
    rect(d, 40, 14, 56, 27, ARMOR)
    rect(d, 40, 14, 56, 15, STEEL)          # brow rim
    rect(d, 41, 16, 42, 18, ARMOR_HI)       # highlight
    if visor == "x":
        rect(d, 43, 19, 45, 21, BONE)
        rect(d, 51, 19, 53, 21, BONE)
        rect(d, 44, 20, 44, 20, INK)
        rect(d, 52, 20, 52, 20, INK)
    else:
        color = VISOR if visor == "on" else VISOR_DIM
        rect(d, 42, 19, 54, 21, color)
        rect(d, 43, 20, 53, 20, EMBER)
    rect(d, 44, 23, 45, 24, STEEL)          # breath
    rect(d, 51, 23, 52, 24, STEEL)
    rect(d, 40, 26, 56, 27, STEEL)          # bevor

    # pauldrons
    rect(d, 30, 28, 40, 34, INK)
    rect(d, 31, 29, 39, 33, ARMOR)
    rect(d, 31, 29, 38, 30, STEEL)
    rect(d, 56, 28, 66, 34, INK)
    rect(d, 57, 29, 65, 33, ARMOR)
    rect(d, 57, 29, 64, 30, STEEL)

    # torso
    rect(d, 36, 32, 60, 52, INK)
    rect(d, 37, 33, 59, 51, ARMOR)
    rect(d, 38, 34, 40, 48, ARMOR_HI)       # plate highlight
    rect(d, 46, 36, 50, 49, BLOOD_DK)       # tabard
    rect(d, 47, 37, 49, 40, BLOOD)
    # belt
    rect(d, 36, 50, 60, 53, STEEL)
    rect(d, 46, 50, 50, 52, BLOOD)

    # sword-arm (viewer's left) — the blade itself is a separate layer
    rect(d, 28, 34, 36, 40, INK)
    rect(d, 29, 35, 35, 39, ARMOR)
    rect(d, 27, 38, 30, 42, ARMOR)          # gauntlet
    rect(d, 27, 38, 29, 39, STEEL)

    # shield-arm
    rect(d, 58, 36, 64, 44, ARMOR)
    rect(d, 62, 40, 66, 46, ARMOR)
    rect(d, 64, 44, 68, 48, STEEL)

    # legs — greaves, not sticks
    if legs == "stand":
        rect(d, 37, 53, 48, 90, INK)
        rect(d, 38, 54, 47, 89, ARMOR)
        rect(d, 48, 53, 59, 90, INK)
        rect(d, 49, 54, 58, 89, ARMOR)
        rect(d, 36, 84, 46, 94, STEEL)
        rect(d, 50, 84, 60, 94, STEEL)
        rect(d, 36, 91, 46, 94, ARMOR_HI)
        rect(d, 50, 91, 60, 94, ARMOR_HI)
    elif legs == "left":
        rect(d, 32, 54, 44, 94, INK)
        rect(d, 33, 55, 43, 93, ARMOR)
        rect(d, 52, 52, 62, 84, INK)
        rect(d, 53, 53, 61, 83, ARMOR)
        rect(d, 31, 88, 45, 96, STEEL)
        rect(d, 51, 78, 63, 85, STEEL)
    elif legs == "right":
        rect(d, 52, 54, 64, 94, INK)
        rect(d, 53, 55, 63, 93, ARMOR)
        rect(d, 34, 52, 44, 84, INK)
        rect(d, 35, 53, 43, 83, ARMOR)
        rect(d, 51, 88, 65, 96, STEEL)
        rect(d, 33, 78, 45, 85, STEEL)
    elif legs == "pass":
        rect(d, 38, 53, 48, 86, INK)
        rect(d, 39, 54, 47, 85, ARMOR)
        rect(d, 48, 53, 58, 86, INK)
        rect(d, 49, 54, 57, 85, ARMOR)
        rect(d, 37, 80, 49, 87, STEEL)
        rect(d, 47, 80, 59, 87, STEEL)
    elif legs == "tuck":
        rect(d, 36, 52, 48, 74, INK)
        rect(d, 37, 53, 47, 73, ARMOR)
        rect(d, 48, 52, 60, 74, INK)
        rect(d, 49, 53, 59, 73, ARMOR)
        rect(d, 34, 68, 46, 76, STEEL)
        rect(d, 50, 68, 62, 76, STEEL)

    if lean:
        im = shift(im, lean, 0)
    if stars:
        sd = ImageDraw.Draw(im)
        for (x, y, col) in stars:
            rect(sd, x, y, x + 1, y + 1, col)
    return im


def compose(body, sword, shield_ox=0, shield_oy=0, gleam=None, dy=0, yscale=1.0):
    im = body.copy()
    d = ImageDraw.Draw(im)
    draw_shield(d, shield_ox, shield_oy, gleam=gleam)
    im = Image.alpha_composite(im, sword)
    if yscale != 1.0:
        im = squash(im, yscale, foot_y=100)
    # headroom so a jump can rise without clipping the plume
    im = shift(im, 0, dy + 6)
    return im.resize((FW, FH), Image.Resampling.NEAREST)


def f_idle(i):
    plume = (0, 2, 2, 0, -2, 0)[i]
    visor = "dim" if i == 2 else "on"
    body = draw_body(plume_dx=plume, visor=visor)
    sword = draw_sword(0)
    if i == 4:
        sd = ImageDraw.Draw(sword)
        rect(sd, 29, 10, 30, 12, (255, 255, 255, 255))
    gleam = 2 if i == 5 else None
    dy = -1 if i == 3 else 0
    return compose(body, sword, gleam=gleam, dy=dy)


def f_run(i):
    legs = ("left", "pass", "right", "pass", "left", "pass")[i]
    bob = (0, -2, 0, -2, 0, -3)[i]
    arm = (8, 0, -10, 0, 8, 0)[i]
    body = draw_body(plume_dx=(1, 0, -1, 0, 1, 0)[i], legs=legs)
    sword = draw_sword(arm)
    shield_oy = -bob // 2
    return compose(body, sword, shield_oy=shield_oy, dy=bob)


def f_wave(i):
    # positive = counter-clockwise = the blade sweeps out to the viewer's left
    angle = (0, 18, 38, 56, 38, 18)[i]
    body = draw_body(plume_dx=(0, 1, 2, 1, 0, -1)[i])
    sword = draw_sword(angle)
    return compose(body, sword)


def f_jump(i):
    # crouch, load, launch, peak, fall, land
    specs = (
        ("stand", 2, 0.86, 1),
        ("tuck", 3, 0.78, 2),
        ("stand", -6, 1.08, -6),
        ("tuck", -8, 1.0, -10),
        ("stand", -4, 1.04, -5),
        ("stand", 2, 0.84, 2),
    )
    legs, plume, yscale, dy = specs[i]
    body = draw_body(plume_dx=plume, legs=legs, visor="on")
    sword = draw_sword(-8 if i in (2, 3) else 0)
    return compose(body, sword, yscale=yscale, dy=dy)


def f_failed(i):
    stars_a = [(18, 8, BONE), (70, 6, EMBER), (22, 4, BLOOD)]
    stars_b = [(16, 6, EMBER), (74, 8, BONE), (20, 10, BONE)]
    body = draw_body(
        plume_dx=3, visor="x", legs="stand", lean=3,
        stars=stars_a if i % 2 == 0 else stars_b,
    )
    sword = draw_sword(28)
    return compose(body, sword, shield_ox=1, shield_oy=6, dy=1)


def f_waiting(i):
    look = ("dim", "dim", "on", "on", "dim", "on")[i]
    bob = (0, 0, 1, 0, 0, 0)[i]
    body = draw_body(plume_dx=(-2, -2, 0, 2, 2, 0)[i], visor=look)
    sword = draw_sword(6)
    return compose(body, sword, shield_ox=2, shield_oy=4, dy=bob)


def f_review(i):
    gleam = (0, 2, 4, 6, 4, 2)[i]
    body = draw_body(plume_dx=0, visor="on")
    sword = draw_sword(0)
    return compose(body, sword, shield_oy=-4, gleam=gleam)


def mirror(im):
    return im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


ROW_BUILDERS = [
    f_idle,
    f_run,
    lambda i: mirror(f_run(i)),
    f_wave,
    f_jump,
    f_failed,
    f_waiting,
    f_run,
    f_review,
]


def build_atlas():
    atlas = Image.new("RGBA", (COLS * FW, ROWS * FH), (0, 0, 0, 0))
    frames = []
    for row_i, builder in enumerate(ROW_BUILDERS):
        row = [builder(i) for i in range(6)]
        frames.append(row)
        padded = row + [row[0], row[1]]
        for col_i, frame in enumerate(padded):
            atlas.paste(frame, (col_i * FW, row_i * FH))
    return atlas, frames


def knight_card(idle_frames):
    """Heraldic card. Matte black, steel ring, knight large enough to read."""
    card_w, card_h = 880, 980
    scale = 4
    out_frames = []
    for frame in idle_frames:
        card = Image.new("RGBA", (card_w, card_h), (16, 16, 20, 255))
        d = ImageDraw.Draw(card)
        # steel ring
        d.ellipse([36, 36, card_w - 37, card_h - 37], outline=STEEL, width=6)
        d.ellipse([48, 48, card_w - 49, card_h - 49], outline=BLOOD, width=2)
        knight = frame.resize((FW * scale, FH * scale), Image.Resampling.NEAREST)
        x = (card_w - knight.width) // 2
        y = (card_h - knight.height) // 2 - 10
        card.alpha_composite(knight, (x, y))
        out_frames.append(card.convert("P", palette=Image.Palette.ADAPTIVE, colors=32))
    return out_frames


def write_pet(atlas):
    HERMES_PET.mkdir(parents=True, exist_ok=True)
    atlas.save(
        HERMES_PET / "spritesheet.webp",
        format="WEBP", lossless=True, quality=100, method=6, exact=True,
    )
    (HERMES_PET / "pet.json").write_text(json.dumps({
        "id": "synthwave84-knight",
        "displayName": "Synthwave84 Knight",
        "description": "Sworn knight of the obsidian watch. Black heater, iron cross, blood plume. Zero retreat.",
        "spritesheetPath": "spritesheet.webp",
        "createdBy": "generator",
    }, indent=2) + "\n", encoding="utf-8")
    thumb = Path.home() / ".hermes" / "pets" / ".thumbs" / "synthwave84-knight.png"
    thumb.unlink(missing_ok=True)


def verify(frames):
    """Pixel asserts. Vision lies about small sprites; the samples do not."""
    import numpy as np

    idle = np.array(frames[0][0])
    # Shield-right box. A plus keeps a constant arm width. This cross
    # flares: the widest blood row beats the narrowest by a clear margin,
    # and the tip is narrower than the row below it.
    cross = idle[88:124, 118:160]
    blood = (cross[:, :, 0] > 160) & (cross[:, :, 1] < 80) & (cross[:, :, 3] > 200)
    assert int(blood.sum()) > 40, f"iron cross missing, blood pixels={int(blood.sum())}"
    widths = [int(blood[i].sum()) for i in range(blood.shape[0])]
    nonzero = [w for w in widths if w]
    assert max(nonzero) >= min(nonzero) + 4, f"cross does not flare: {nonzero}"
    top = next(i for i, n in enumerate(widths) if n)
    assert widths[min(top + 4, len(widths) - 1)] > widths[top], "cross tip does not widen"

    def bbox(im):
        a = np.array(im)
        ys, xs = np.where(a[:, :, 3] > 10)
        return int(ys.min()), int(ys.max()), int(xs.min()), int(xs.max())

    # wave: the bone blade in the upper-left must travel. The plume is
    # ember, so it does not count.
    tips = []
    for fr in frames[3]:
        a = np.array(fr)
        bone = (
            (a[:110, :100, 0] > 190)
            & (a[:110, :100, 1] > 180)
            & (a[:110, :100, 2] > 160)
            & (a[:110, :100, 3] > 200)
        )
        ys, xs = np.where(bone)
        assert len(xs), "wave frame has no blade"
        # tip is the highest bone pixel
        tip_i = int(ys.argmin())
        tips.append((int(xs[tip_i]), int(ys[tip_i])))
    xs_only = [t[0] for t in tips]
    assert max(xs_only) - min(xs_only) >= 10, f"wave does not move the blade: {tips}"

    # jump: peak frame's top is clearly above idle's top, feet leave the line
    idle_top, idle_bot, _, _ = bbox(frames[0][0])
    peak_top, peak_bot, _, _ = bbox(frames[4][3])
    assert idle_top - peak_top >= 10, f"jump peak did not rise: idle {idle_top} peak {peak_top}"
    assert idle_bot - peak_bot >= 8, f"feet did not leave the ground: idle {idle_bot} peak {peak_bot}"

    # run: lead-foot x changes across the cycle
    foot_x = []
    for fr in frames[1]:
        a = np.array(fr)
        band = a[160:200]
        ys, xs = np.where(band[:, :, 3] > 10)
        foot_x.append(int(xs.min()))
    assert max(foot_x) - min(foot_x) >= 6, f"run does not stride: {foot_x}"
    print("verify ok", {"blood": int(blood.sum()), "wave_tips": tips,
                        "jump": (idle_top, peak_top, idle_bot, peak_bot),
                        "stride": foot_x})


def main():
    atlas, frames = build_atlas()
    verify(frames)
    write_pet(atlas)

    atlas.save(REPO / "spritesheet.webp", format="WEBP", lossless=True,
               quality=100, method=6, exact=True)
    atlas.save(REPO / "spritesheet.png")

    preview = Image.new("RGBA", (6 * FW, 9 * FH), (16, 16, 20, 255))
    for row_i, row in enumerate(frames):
        for col_i, frame in enumerate(row):
            preview.paste(frame, (col_i * FW, row_i * FH))
    preview.save(REPO / "preview.png")

    # 4x close-up of idle, wave extreme, jump peak — for the eye, not the assert
    close = Image.new("RGBA", (FW * 4 * 3 + 24, FH * 4 + 16), (16, 16, 20, 255))
    for i, fr in enumerate((frames[0][0], frames[3][3], frames[4][3])):
        big = fr.resize((FW * 4, FH * 4), Image.Resampling.NEAREST)
        close.paste(big, (8 + i * (FW * 4 + 8), 8))
    close.save(REPO / "closeup.png")

    # idle row, three across, profile banner
    banner = Image.new("RGBA", (FW * 3, FH), (16, 16, 20, 255))
    for i, fr in enumerate(frames[0][:3]):
        banner.paste(fr, (i * FW, 0))
    banner.save(REPO / "banner.png")

    card = knight_card(frames[0])
    card[0].save(
        REPO / "knight-card.gif",
        save_all=True,
        append_images=card[1:],
        duration=140,
        loop=0,
        disposal=2,
        optimize=False,
    )
    print("wrote", HERMES_PET / "spritesheet.webp")
    print("card", REPO / "knight-card.gif")


if __name__ == "__main__":
    main()
