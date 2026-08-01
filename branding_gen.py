import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import arabic_reshaper
from bidi.algorithm import get_display

# ---------- palette ----------
INK = (16, 26, 46, 255)
INK_SOFT = (30, 42, 68, 255)
GOLD = (201, 162, 75, 255)
GOLD_SOFT = (222, 193, 122, 255)
PAPER = (244, 239, 227, 255)
EMBER = (181, 101, 74, 255)
SAGE = (91, 122, 99, 255)

FONT_AMIRI_BOLD = "/home/claude/fonts/Amiri-Bold.ttf"
FONT_AMIRI_REG = "/home/claude/fonts/Amiri-Regular.ttf"
FONT_CAIRO_BOLD = "/home/claude/fonts/Cairo-Bold.ttf"

def shape(text):
    return get_display(arabic_reshaper.reshape(text))

def day_arc_points(cx, cy, rx, ry, n=5):
    pts = []
    for i in range(n):
        t = i / (n - 1)
        x = cx - rx + 2 * rx * t
        y = cy - math.sin(t * math.pi) * ry
        pts.append((x, y, t))
    return pts

def draw_arc_glow(draw, pts, scale=1.0):
    # connecting path, soft gold gradient feel via repeated faint strokes
    for i in range(len(pts) - 1):
        x1, y1, _ = pts[i]
        x2, y2, _ = pts[i + 1]
        draw.line([(x1, y1), (x2, y2)], fill=(201, 162, 75, 70), width=max(1, int(2 * scale)))

def draw_nodes(draw, pts, scale=1.0, active_upto=2):
    for i, (x, y, t) in enumerate(pts):
        if i < active_upto:
            color = SAGE
            r = 6 * scale
        elif i == active_upto:
            color = GOLD
            r = 8 * scale
            # glow
            glow_r = r + 10 * scale
            draw.ellipse([x - glow_r, y - glow_r, x + glow_r, y + glow_r], fill=(201, 162, 75, 60))
        else:
            color = (228, 220, 200, 160)
            r = 5.5 * scale
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def make_square_icon(size, rounded=True, bg=INK, with_padding=True):
    """Primary square app icon: navy field, gold day-arc, minimal crescent."""
    scale = size / 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    pad = int(size * (0.0 if not with_padding else 0.0))
    if rounded:
        radius = int(size * 0.225)
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=bg)
    else:
        d.rectangle([0, 0, size - 1, size - 1], fill=bg)

    # subtle vertical vignette for depth
    grad = Image.new("L", (1, size), 0)
    for y in range(size):
        t = y / size
        v = int(18 * (1 - abs(t - 0.5) * 2))
        grad.putpixel((0, y), v)
    grad = grad.resize((size, size))
    glow_layer = Image.new("RGBA", (size, size), GOLD)
    glow_layer.putalpha(grad)
    img = Image.alpha_composite(img, glow_layer)
    d = ImageDraw.Draw(img)
    if rounded:
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
        img.putalpha(mask)
        d = ImageDraw.Draw(img)

    cx, cy = size * 0.5, size * 0.60
    rx, ry = size * 0.29, size * 0.30
    pts = day_arc_points(cx, cy, rx, ry, 5)
    draw_arc_glow(d, pts, scale)
    draw_nodes(d, pts, scale, active_upto=2)

    # small crescent above, referencing fajr / night-to-light motif
    moon_r = size * 0.075
    mcx, mcy = size * 0.5, size * 0.245
    crescent_mask = Image.new("L", (size, size), 0)
    cmd = ImageDraw.Draw(crescent_mask)
    cmd.ellipse([mcx - moon_r, mcy - moon_r, mcx + moon_r, mcy + moon_r], fill=255)
    cmd.ellipse([mcx - moon_r * 0.35, mcy - moon_r * 1.05, mcx + moon_r * 1.5, mcy + moon_r * 0.65], fill=0)
    moon_layer = Image.new("RGBA", (size, size), GOLD_SOFT)
    img.paste(moon_layer, (0, 0), crescent_mask)

    return img


def add_wordmark(icon_img, size):
    """Overlay the Arabic word 'اقم' isn't used on the icon itself (icons should
    stay symbolic/simple); this helper is for the wordmark lockup, not the icon."""
    return icon_img


def make_wordmark(width=1600, height=900):
    img = Image.new("RGBA", (width, height), PAPER)
    d = ImageDraw.Draw(img)

    # icon on the left third
    icon_size = int(height * 0.62)
    icon = make_square_icon(icon_size)
    icon_x = int(width * 0.10)
    icon_y = (height - icon_size) // 2
    img.paste(icon, (icon_x, icon_y), icon)

    # wordmark text
    text = shape("أقم")
    font_size = int(height * 0.34)
    font = ImageFont.truetype(FONT_AMIRI_BOLD, font_size)
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    text_x = icon_x + icon_size + int(width * 0.055)
    text_y = int(height * 0.5 - th / 2 - bbox[1])
    d.text((text_x, text_y), text, font=font, fill=INK)

    # tagline beneath
    tagline = shape("لا نذكّرك بالصلاة فقط… بل نساعدك على المحافظة عليها")
    tag_font = ImageFont.truetype(FONT_CAIRO_BOLD, int(height * 0.052))
    tbbox = d.textbbox((0, 0), tagline, font=tag_font)
    tag_w = tbbox[2] - tbbox[0]
    tag_x = text_x
    tag_y = text_y + th + int(height * 0.055)
    d.text((tag_x, tag_y), tagline, font=tag_font, fill=(90, 98, 118, 255))

    return img


def make_feature_graphic(width=1600, height=780):
    """Play Store style feature banner: dark, arc motif large, wordmark right-aligned (RTL)."""
    img = Image.new("RGBA", (width, height), INK)
    d = ImageDraw.Draw(img)

    # large soft arc across the whole banner
    cx, cy = width * 0.5, height * 0.72
    rx, ry = width * 0.42, height * 0.5
    pts = day_arc_points(cx, cy, rx, ry, 5)
    draw_arc_glow(d, pts, scale=2.2)
    draw_nodes(d, pts, scale=2.0, active_upto=3)

    # crescent
    moon_r = height * 0.09
    mcx, mcy = width * 0.5, height * 0.22
    crescent_mask = Image.new("L", (width, height), 0)
    cmd = ImageDraw.Draw(crescent_mask)
    cmd.ellipse([mcx - moon_r, mcy - moon_r, mcx + moon_r, mcy + moon_r], fill=255)
    cmd.ellipse([mcx - moon_r * 0.3, mcy - moon_r * 1.05, mcx + moon_r * 1.6, mcy + moon_r * 0.7], fill=0)
    moon_layer = Image.new("RGBA", (width, height), GOLD_SOFT)
    img.paste(moon_layer, (0, 0), crescent_mask)
    d = ImageDraw.Draw(img)

    text = shape("أقم")
    font = ImageFont.truetype(FONT_AMIRI_BOLD, int(height * 0.30))
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((width / 2 - tw / 2 - bbox[0], height * 0.06 - bbox[1] + height*0.0), text, font=font, fill=GOLD)

    return img


if __name__ == "__main__":
    out = "/home/claude/aqim_app/branding"
    import os
    os.makedirs(out, exist_ok=True)

    icon_1024 = make_square_icon(1024)
    icon_1024.save(f"{out}/icon_1024.png")

    icon_512 = make_square_icon(512)
    icon_512.save(f"{out}/icon_512.png")

    wordmark = make_wordmark(1600, 900)
    wordmark.save(f"{out}/wordmark.png")

    feature = make_feature_graphic(1600, 780)
    feature.save(f"{out}/feature_graphic.png")

    print("done")
