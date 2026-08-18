#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成「虹月 AI Chat」应用图标。

沿用手绘稿的构成，几何化重绘：
  · 圆环 = 月轮，左侧大半段用青色渐变，右侧一段用暖黄渐变（月牙受光面）
  · 环内一个向上的 ∧ 峰（对话/上升的意象），青色，左腿略长保留手稿的不对称
  · 深色圆角底 + 左上青色柔光

输出：
  android/app/src/main/res/mipmap-*/ic_launcher.png            legacy 图标
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png 自适应前景（透明底）
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml    自适应图标定义
  assets/icon.png        1024 主图（宣传 / 商店）
  assets/icon_mark.png   512 透明底纯图形（网页用）

用法：python3 tools/gen_icon.py [--preview]
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SS = 4  # 超采样倍数

# ---------------------------------------------------------------- 配色
CYAN_1 = (46, 250, 226)   # 青色（亮）
CYAN_2 = (8, 168, 156)    # 青色（暗）
GOLD_1 = (255, 230, 150)  # 暖黄（亮）
GOLD_2 = (244, 186, 84)   # 暖黄（暗）
BG_1 = (14, 30, 46)       # 底色（浅）
BG_2 = (5, 12, 22)        # 底色（深）

# ------------------------------------------------- 几何（以 1.0 = 半个画布计）
R_OUT = 0.780   # 环外半径
R_IN = 0.590    # 环内半径
GOLD_HALF = 52  # 暖黄段的半角（度），以 3 点钟方向为中心

PEAK_W = 0.185        # ∧ 笔宽
PEAK_APEX = (0.00, -0.345)   # 顶点
PEAK_LEFT = (-0.300, 0.302)  # 左腿末端（长）
PEAK_RIGHT = (0.262, 0.212)  # 右腿末端（短，保留手稿的不对称）


def _lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient(size, c1, c2, angle):
    """线性渐变（小图逐像素后放大，快且视觉无差）。"""
    n = 128
    img = Image.new('RGB', (n, n))
    px = img.load()
    rad = math.radians(angle)
    dx, dy = math.cos(rad), math.sin(rad)
    span = abs(dx) * n + abs(dy) * n
    ox = 0 if dx >= 0 else n
    oy = 0 if dy >= 0 else n
    for y in range(n):
        for x in range(n):
            t = ((x - ox) * dx + (y - oy) * dy) / span
            t = 0.0 if t < 0 else (1.0 if t > 1 else t)
            px[x, y] = (_lerp(c1[0], c2[0], t),
                        _lerp(c1[1], c2[1], t),
                        _lerp(c1[2], c2[2], t))
    return img.resize((size, size), Image.LANCZOS)


def ring_mask(size, scale, arc, feather=0):
    """圆环的一段。arc=(start,end)，角度以 3 点钟为 0、顺时针增加。
    feather > 0 时对扇区边界做羽化，让两段颜色自然过渡。"""
    half = size / 2.0
    r_out = R_OUT * scale * half
    r_in = R_IN * scale * half
    m = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(m)
    d.ellipse([half - r_out, half - r_out, half + r_out, half + r_out], fill=255)
    d.ellipse([half - r_in, half - r_in, half + r_in, half + r_in], fill=0)

    sector = Image.new('L', (size, size), 0)
    pad = r_out + size * 0.05
    ImageDraw.Draw(sector).pieslice(
        [half - pad, half - pad, half + pad, half + pad],
        start=arc[0], end=arc[1], fill=255)
    if feather:
        sector = sector.filter(ImageFilter.GaussianBlur(feather))
    return ImageChops.multiply(m, sector)


def peak_mask(size, scale):
    """环内向上的 ∧ 峰，圆头笔画。"""
    half = size / 2.0
    m = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(m)

    def P(pt):
        return (half + pt[0] * scale * half, half + pt[1] * scale * half)

    w = max(2, int(PEAK_W * scale * half))
    apex, left, right = P(PEAK_APEX), P(PEAK_LEFT), P(PEAK_RIGHT)
    d.line([left, apex], fill=255, width=w)
    d.line([apex, right], fill=255, width=w)
    for pt in (apex, left, right):  # 圆头
        d.ellipse([pt[0] - w / 2, pt[1] - w / 2,
                   pt[0] + w / 2, pt[1] + w / 2], fill=255)
    return m


def build_symbol(size, scale):
    """图形本体（透明底）。"""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cyan = gradient(size, CYAN_1, CYAN_2, 125)
    gold = gradient(size, GOLD_1, GOLD_2, 100)

    feather = max(1, int(size * 0.012))
    # 青色主环（先铺满整圈，保证接缝处不透底）
    layer.paste(cyan, (0, 0), ring_mask(size, scale, (0, 360)))
    # 右侧暖黄段，边界羽化后叠上去
    layer.paste(gold, (0, 0),
                ring_mask(size, scale, (-GOLD_HALF, GOLD_HALF), feather))
    # 环内 ∧ 峰
    layer.paste(cyan, (0, 0), peak_mask(size, scale))
    return layer


def rounded_bg(size, radius_ratio=0.235):
    """深色圆角底 + 左上柔光。"""
    bg = gradient(size, BG_1, BG_2, 120).convert('RGBA')

    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    gr = int(size * 0.46)
    ImageDraw.Draw(glow).ellipse([-gr // 3, -gr // 3, gr, gr],
                                 fill=(20, 226, 206, 66))
    glow = glow.filter(ImageFilter.GaussianBlur(size // 9))
    bg = Image.alpha_composite(bg, glow)

    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * radius_ratio), fill=255)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out


def make_legacy(px):
    s = px * SS
    icon = Image.alpha_composite(rounded_bg(s), build_symbol(s, 0.80))
    return icon.resize((px, px), Image.LANCZOS)


def make_foreground(px):
    """自适应前景：图形只占 108dp 画布约 55%，落在安全区内。"""
    s = px * SS
    fg = Image.alpha_composite(Image.new('RGBA', (s, s), (0, 0, 0, 0)),
                               build_symbol(s, 0.55))
    return fg.resize((px, px), Image.LANCZOS)


def make_mark(px):
    """透明底纯图形。"""
    s = px * SS
    fg = Image.alpha_composite(Image.new('RGBA', (s, s), (0, 0, 0, 0)),
                               build_symbol(s, 0.94))
    return fg.resize((px, px), Image.LANCZOS)


ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
FOREGROUND = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216,
              'xxhdpi': 324, 'xxxhdpi': 432}

ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''

COLORS_XML = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0A1826</color>
</resources>
'''


def preview(px=44):
    """终端 ASCII 预览，用于确认造型。"""
    im = make_legacy(px).convert('RGB')
    ramp = ' .:-=+*#%@'
    for y in range(px):
        row = ''
        for x in range(px):
            r, g, b = im.getpixel((x, y))
            lum = (r * 0.3 + g * 0.6 + b * 0.1) / 255
            row += ramp[min(len(ramp) - 1, int(lum * len(ramp)))]
        print(row)


def main():
    if '--preview' in sys.argv:
        preview()
        return

    for dpi, px in LEGACY.items():
        d = os.path.join(RES, 'mipmap-' + dpi)
        os.makedirs(d, exist_ok=True)
        make_legacy(px).save(os.path.join(d, 'ic_launcher.png'))

    for dpi, px in FOREGROUND.items():
        d = os.path.join(RES, 'mipmap-' + dpi)
        make_foreground(px).save(os.path.join(d, 'ic_launcher_foreground.png'))

    any26 = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(any26, exist_ok=True)
    with open(os.path.join(any26, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(ADAPTIVE_XML)
    with open(os.path.join(RES, 'values', 'ic_launcher_background.xml'),
              'w', encoding='utf-8') as f:
        f.write(COLORS_XML)

    assets = os.path.join(ROOT, 'assets')
    os.makedirs(assets, exist_ok=True)
    make_legacy(1024).save(os.path.join(assets, 'icon.png'))
    make_mark(512).save(os.path.join(assets, 'icon_mark.png'))
    print('icons generated')


if __name__ == '__main__':
    main()