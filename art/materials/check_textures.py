"""Normalize generated assets, repair wrapping, and test 2x2 repeats (Pillow/numpy).

Run from any directory: python art/materials/check_textures.py --prepare
Omit --prepare for read-only asset validation (QA outputs are refreshed).
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
NAMES = ['maple_court', 'terrazzo_corridor', 'porcelain_tile_12x24',
         'carpet_tile_office', 'painted_cmu', 'brick_red', 'acoustic_ceiling_2x2',
         'rubber_gym_floor', 'sealed_concrete', 'metal_panel_grey',
         'ceramic_wall_tile', 'mosaic_green']


def seam_metrics(a):
    a = a.astype(np.float32)
    dx, dy = np.abs(np.diff(a, axis=1)), np.abs(np.diff(a, axis=0))
    sx, sy = np.abs(a[:, 0] - a[:, -1]), np.abs(a[0] - a[-1])
    return {'horizontal_mae': float(sx.mean()), 'vertical_mae': float(sy.mean()),
            'horizontal_p95': float(np.percentile(sx, 95)),
            'vertical_p95': float(np.percentile(sy, 95)),
            'interior_x_mae': float(dx.mean()), 'interior_y_mae': float(dy.mean())}


def repair(a, band=32):
    # Blend opposite borders towards a shared edge with a cosine falloff.
    # Interior layout stays intact; unlike mirror tiling, no new symmetry is added.
    a = a.astype(np.float32)
    for axis in (1, 0):
        b = np.swapaxes(a, 0, axis)
        target = (b[0].copy() + b[-1].copy()) * 0.5
        left, right = target - b[0], target - b[-1]
        for i in range(band):
            w = (1 + np.cos(np.pi * i / band)) * 0.5
            b[i] += left * w
            b[-1-i] += right * w
    return np.clip(np.rint(a), 0, 255).astype(np.uint8)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--prepare', action='store_true')
    args = parser.parse_args()
    sources = {e['name']: e['source'] for e in json.loads(
        (ROOT / 'generation.json').read_text(encoding='utf-8-sig'))}
    qa = ROOT / 'qa'
    qa.mkdir(exist_ok=True)
    results = []
    packet = Image.new('RGB', (1024, 3 * 294), '#eeeeee')
    draw = ImageDraw.Draw(packet)
    for index, name in enumerate(NAMES):
        path = ROOT / (name + '.png')
        if not path.exists():
            results.append({'name': name, 'pass': False, 'error': 'missing'})
            continue
        im = Image.open(sources[name] if args.prepare else path)
        if args.prepare and name == 'brick_red':
            # Remove generated partial ninth course; preserve eight whole courses.
            im = im.crop((0, 0, im.width, round(im.height * 0.93)))
        before = seam_metrics(np.asarray(im.convert('RGB')))
        if args.prepare:
            im = im.convert('RGB').resize((1024, 1024), Image.Resampling.LANCZOS)
            im = Image.fromarray(repair(np.asarray(im)))
            im.save(path)
        a = np.asarray(im.convert('RGB'))
        metrics = seam_metrics(a)
        ok = im.size == (1024, 1024) and im.mode == 'RGB'
        ok = ok and max(metrics['horizontal_mae'], metrics['vertical_mae']) <= 2
        ok = ok and max(metrics['horizontal_p95'], metrics['vertical_p95']) <= 6
        # Also flag steep blending edges inside the repair band.
        band_diffs = [np.abs(np.diff(a.astype(float), axis=axis)) for axis in (0, 1)]
        band_mae = []
        interior_peaks = []
        for axis, diffs in enumerate(band_diffs):
            lines = diffs.mean(axis=tuple(i for i in range(3) if i != axis))
            band_mae.append(float(max(lines[:32].max(), lines[-32:].max())))
            interior_peaks.append(float(lines[32:-32].max()))
        metrics['repair_band_max_line_mae'] = band_mae
        metrics['interior_max_line_mae'] = interior_peaks
        # Mortar/grid lines have legitimate high contrast. Compare with those
        # interior features rather than treating every grout joint as a defect.
        ok = ok and all(edge <= max(35, inside * 1.5 + 5)
                        for edge, inside in zip(band_mae, interior_peaks))
        repeat = Image.fromarray(np.tile(a, (2, 2, 1)))
        repeat.save(qa / (name + '_2x2.png'))
        x, y = (index % 4) * 256, (index // 4) * 294
        packet.paste(repeat.resize((256, 256), Image.Resampling.LANCZOS), (x, y))
        draw.text((x+5, y+259), name, fill='black')
        draw.text((x+5, y+276), 'PASS' if ok else 'FAIL', fill='green' if ok else 'red')
        results.append({'name': name, 'pass': bool(ok), 'before': before, 'after': metrics})
        print(('PASS' if ok else 'FAIL'), name, metrics)
    packet.save(qa / 'PACKET.png')
    (qa / 'seams.json').write_text(json.dumps(results, indent=2) + '\n')
    raise SystemExit(0 if all(r['pass'] for r in results) else 1)


if __name__ == '__main__':
    main()
