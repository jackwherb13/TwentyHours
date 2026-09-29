"""Normalize generated PNG sizes, preserve alpha, and validate the branding assets."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--prepare', action='store_true')
args = parser.parse_args()
records = json.loads((ROOT / 'generation.json').read_text(encoding='utf-8-sig'))
packet = Image.new('RGB', (1024, 380), '#dddddd')
draw = ImageDraw.Draw(packet)
results = []
for index, entry in enumerate(records):
    path = ROOT / (entry['name'] + '.png')
    if args.prepare:
        source = Image.open(entry['source'])
        source.resize((1024, 1024), Image.Resampling.LANCZOS).save(path)
    im = Image.open(path)
    alpha = im.convert('RGBA').getchannel('A')
    extrema = alpha.getextrema()
    transparent = entry['name'] != 'locker_room_sign'
    ok = im.size == (1024, 1024)
    ok = ok and (extrema == (0, 255) if transparent else extrema == (255, 255))
    if transparent:
        ok = ok and all(alpha.getpixel(p) == 0 for p in [(0,0),(0,1023),(1023,0),(1023,1023)])
    thumb = im.convert('RGBA').resize((332, 332), Image.Resampling.LANCZOS)
    packet.paste(thumb, (index * 342, 0), thumb)
    draw.text((index * 342 + 4, 340), entry['name'], fill='black')
    draw.text((index * 342 + 4, 357), 'PASS' if ok else 'FAIL', fill='green' if ok else 'red')
    results.append({'name': entry['name'], 'size': im.size, 'mode': im.mode,
                    'alpha_extrema': extrema, 'pass': bool(ok)})
    print('PASS' if ok else 'FAIL', entry['name'], im.size, im.mode, extrema)
packet.save(ROOT / 'PACKET.png')
(ROOT / 'checks.json').write_text(json.dumps(results, indent=2) + '\n')
raise SystemExit(0 if all(e['pass'] for e in results) else 1)
