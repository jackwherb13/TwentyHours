"""Direct VGIN image export plus numeric NAVD88 county contours."""
import sys,json,concurrent.futures
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'.vendor'))
import requests
from rasterio.warp import transform
from prepare_site import inverse
OUT=Path('reference/web'); bbox=json.loads((OUT/'site_bbox.json').read_text())['bbox4326']
def contours():
 endpoint='https://www.fairfaxcounty.gov/idrisi/rest/services/Jade/Contours/MapServer/0'
 meta=requests.get(endpoint,params={'f':'json'},timeout=45).json()
 (OUT/'county_contours_numeric_meta.json').write_text(json.dumps(meta,indent=2))
 print('CONTOUR FIELDS',[f['name'] for f in meta.get('fields',[])],flush=True)
 p={'f':'json','where':'1=1','geometry':','.join(map(str,bbox)),'geometryType':'esriGeometryEnvelope','inSR':4326,'outSR':4326,'outFields':'*','returnGeometry':'true','spatialRel':'esriSpatialRelIntersects','resultRecordCount':2000}
 d=requests.get(endpoint+'/query',params=p,timeout=90).json()
 (OUT/'county_contours_numeric.json').write_text(json.dumps(d))
 print('COUNTY CONTOURS',len(d.get('features',[])),d.get('error'),flush=True)
def ortho():
 url='https://vginmaps.vdem.virginia.gov/arcgis/rest/services/VBMP_Imagery/MostRecentImagery_WGS/MapServer'
 meta=requests.get(url,params={'f':'json'},timeout=45).json();(OUT/'vgin_service.json').write_text(json.dumps(meta,indent=2))
 corners=[tuple(v[0] for v in transform('EPSG:4326','EPSG:26918',[lon],[lat])) for lat,lon in [inverse(x,z) for x in [-592,208] for z in [-448,352]]]
 bounds=[min(p[0] for p in corners),min(p[1] for p in corners),max(p[0] for p in corners),max(p[1] for p in corners)]
 params={'f':'image','bbox':','.join(map(str,bounds)),'bboxSR':26918,'imageSR':26918,'size':'1024,1024','format':'png','transparent':'false','adjustAspectRatio':'false'}
 r=requests.get(url+'/export',params=params,timeout=90);r.raise_for_status()
 if not r.content.startswith(b'\x89PNG'):raise RuntimeError(r.text[:500])
 (OUT/'rac_ortho.png').write_bytes(r.content)
 (OUT/'vgin_export.json').write_text(json.dumps({'endpoint':url,'bounds26918':bounds,'request':params,'width':1024,'height':1024},indent=2))
 print('VGIN ORTHO',len(r.content),flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for f in concurrent.futures.as_completed([pool.submit(contours),pool.submit(ortho)]):
  try:f.result()
  except Exception as e:print('FAIL',repr(e),flush=True)
