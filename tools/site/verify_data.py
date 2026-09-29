"""Validate the generated site source and DEM independently of Roblox rendering."""
import hashlib
import json
from pathlib import Path

import numpy as np

from prepare_site import geo, inverse, inside, X0, Z0, COUNT, STEP, ROOT

site = json.loads((ROOT/'blueprint_interim/site.json').read_text())
scene = site['site']
grid = json.loads((ROOT/'verification/exterior/terrain_grid.json').read_text())
h = np.array(grid['heights'])
m = np.array(grid['materials'])
assert h.shape == (COUNT, COUNT) and m.shape == h.shape
assert np.isfinite(h).all() and h.max()-h.min() > 10
assert set(np.unique(m)) <= {1, 2, 3, 4}
assert grid['meta']['sourceResolutionM'] == 1
assert geo(38.8310914,-77.312432) == [-199.5,-204.5]
for point in [(0,0),(-600,-500),(300,500)]:
    lat,lon=inverse(*point)
    assert np.allclose(geo(lat,lon),point,atol=.01), 'Geographic round-trip failure'
x,z=np.meshgrid(X0+2+np.arange(COUNT)*STEP,Z0+2+np.arange(COUNT)*STEP)
for polygon in scene['terrain']['padPolygons']:
    mask=inside(x,z,polygon)
    assert np.all(h[mask]==-.65), 'Building pad is not flat'
assert scene['trueNorthDeg']==10.43
assert len(site['facade'])>40 and len(scene['roads'])>100
assert all(s['height']>0 and s['base']>=0 for s in site['facade'])
assert all('source' in r for r in scene['roads'])
assert all(t['source'] for t in scene['trees'])
assert all('source' in r for r in site['roofs'])
record={'status':'PASS','checks':['1m DEM provenance','90000 finite 4ft cells','all building pads flat','geographic anchor and inverse transform','source citations on routes/trees/roofs','facade dimensions'],
        'terrainDataSha256':hashlib.sha256((ROOT/'src/ReplicatedStorage/RAC/Site/TerrainData.luau').read_bytes()).hexdigest(),
        'sourceDEMBytes':(ROOT/'reference/web/rac_3dep_1m.tif').stat().st_size,
        'boundsFt':[X0,Z0,X0+COUNT*STEP,Z0+COUNT*STEP]}
(ROOT/'verification/exterior/data_validation.json').write_text(json.dumps(record,indent=2)+'\n')
print('PASS site data: 90000 finite DEM cells, flat pad, transform round-trip, source provenance')
