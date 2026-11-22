#!/usr/bin/env python3
# Finds the main colour of every wallpaper in a folder and keeps them in a JSON
# cache: { "/full/path.png": {color, palette, mtime}, ... }. Pictures already in the cache
# (and unchanged since) are skipped, so only new ones cost time.
#
#   wallpaper-colors.py <folder> <cache.json>
#
# Needs ImageMagick (`magick`). The "main colour" is the most common of 5
# colours the picture is reduced to, ignoring near-black/near-white when a
# real colour is also present.
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

EXTS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tga", ".tiff", ".tif",
        ".pnm", ".pbm", ".pgm", ".ppm", ".pam", ".ff", ".farbfeld", ".webp"}

def main_colour(path):
    try:
        out = subprocess.run(
            ["magick", path + "[0]", "-resize", "64x64", "-colors", "5",
             "-format", "%c", "histogram:info:-"],
            capture_output=True, text=True, timeout=30).stdout
    except Exception:
        return None
    best, best_score = None, -1
    palette, total = [], 0
    for line in out.splitlines():
        # "   1234: (r,g,b) #RRGGBB srgb(...)"
        try:
            count = int(line.split(":")[0])
            hexc = line.split("#")[1][:6]
        except (ValueError, IndexError):
            continue
        r, g, b = (int(hexc[i:i+2], 16) for i in (0, 2, 4))
        palette.append(["#" + hexc.lower(), count]); total += count
        mx, mn = max(r, g, b), min(r, g, b)

        # favour real colours over near-black / near-white / grey
        colourful = (mx - mn) / 255
        score = count * (0.35 + colourful)
        if score > best_score:
            best, best_score = "#" + hexc.lower(), score
    if not best:
        return None

    # the 5 colours with how much of the picture each covers (0..1), biggest first
    palette = sorted(([c, round(n / total, 3)] for c, n in palette), key=lambda p: -p[1])
    return best, palette

def main():
    folder, cache_path = sys.argv[1], sys.argv[2]
    try:
        cache = json.load(open(cache_path))
    except Exception:
        cache = {}
    files = []
    for name in os.listdir(folder):
        p = os.path.join(folder, name)
        if os.path.isfile(p) and os.path.splitext(name)[1].lower() in EXTS:
            files.append(p)
    todo = [p for p in files
            if not (p in cache and cache[p].get("mtime") == os.path.getmtime(p)
                    and "palette" in cache[p])]          # older caches had no palette
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        for p, c in zip(todo, pool.map(main_colour, todo)):
            if c:
                cache[p] = {"color": c[0], "palette": c[1], "mtime": os.path.getmtime(p)}

    # forget pictures that were deleted
    cache = {p: v for p, v in cache.items() if os.path.exists(p)}
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    tmp = cache_path + ".tmp"
    json.dump(cache, open(tmp, "w"))
    os.replace(tmp, cache_path)   # replace in one go, so readers never see half a file
    print(f"{len(todo)} new, {len(cache)} total")

main()
