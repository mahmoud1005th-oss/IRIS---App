#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد أيقونات وسبلاش عالية الجودة لآيرس من assets/logo.png (الماستر 1024px).

المخرجات:
  assets/icon/icon_2048.png   ماستر 2048 لأيقونة اللانشر (داون سامبل نظيف)
  assets/icon/adaptive_fg.png مقدمة الأيقونة التكيفية: اللوجو شفاف الخلفية داخل منطقة الأمان
  assets/icon/splash.png      سبلاش نيتيف: اللوجو متمركز على خلفية سوداء
  assets/icon/splash_fg.png   سبلاش أندرويد 12+: لوجو شفاف متمركز
"""
import os
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets', 'logo.png')
OUT = os.path.join(ROOT, 'assets', 'icon')
BLACK = (0, 0, 0)


def load_logo_art():
    """يرجع اللوجو RGBA: خطوط بيضاء وألفا من الإضاءة، مقصوص على المحتوى ومربع."""
    im = Image.open(SRC).convert('L')
    bbox = im.point(lambda v: 255 if v > 24 else 0).getbbox()
    if bbox:
        im = im.crop(bbox)
    # خليها مربعة بالتوسيع من المركز عشان الريسايز ما يبوظش النسبة
    w, h = im.size
    side = max(w, h)
    sq = Image.new('L', (side, side), 0)
    sq.paste(im, ((side - w) // 2, (side - h) // 2))
    art = Image.new('RGBA', (side, side), (255, 255, 255, 0))
    art.putalpha(sq)
    return art


def upscale(art, size):
    a = art.resize((size, size), Image.LANCZOS)
    return a.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))


def place(art, size, fill_ratio, bg):
    canvas = Image.new('RGBA', (size, size), bg)
    target = int(size * fill_ratio)
    a = upscale(art, target)
    off = (size - target) // 2
    canvas.paste(a, (off, off), a)
    return canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    art = load_logo_art()
    print('logo art square size:', art.size)
    place(art, 2048, 0.98, BLACK + (255,)).convert('RGB').save(
        os.path.join(OUT, 'icon_2048.png'))
    place(art, 1024, 0.62, (0, 0, 0, 0)).save(
        os.path.join(OUT, 'adaptive_fg.png'))
    place(art, 1152, 0.62, BLACK + (255,)).convert('RGB').save(
        os.path.join(OUT, 'splash.png'))
    place(art, 1024, 0.62, (0, 0, 0, 0)).save(
        os.path.join(OUT, 'splash_fg.png'))
    print('icons written to', OUT)


if __name__ == '__main__':
    main()
