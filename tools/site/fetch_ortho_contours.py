"""Bounded USGS public orthophoto export and Fairfax 2-ft contour vector tiles."""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'.vendor'))
import json, math, concurrent.futures
import requests
from rasterio.warp import transform
from prepare_site import inverse

OUT=Path('reference/web')
bbox=json.loads((OUT/'site_bbox.json').read_text())['bbox4326']
def ortho():
 url='https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer'
 corners=[tuple(v[0] for v in transform('EPSG:4326','EPSG:26918',[lon],[lat])) for lat,lon in [inverse(x,z) for x in [-592,208] for z in [-448,352]]]
 bounds=[min(p[0] for p in corners),min(p[1] for p in corners),max(p[0] for p in corners),max(p[1] for p in corners)]
 params={'f':'json','bbox':','.join(map(str,bounds)),'bboxSR':26918,'imageSR':26918,'size':'1024,1024','format':'tiff','pixelType':'U8','interpolation':'RSP_BilinearInterpolation','adjustAspectRatio':'false'}
 r=requests.get(url+'/exportImage',params=params,timeout=90);r.raise_for_status();meta=r.json()
 (OUT/'ortho_export.json').write_text(json.dumps({'endpoint':url,'request':params,'response':meta},indent=2))
 if 'href' not in meta:raise RuntimeError(meta)
 image=requests.get(meta['href'],timeout=90);image.raise_for_status();(OUT/'rac_ortho.tif').write_bytes(image.content)
 q=requests.get(url+'/identify',params={'f':'json','geometry':json.dumps({'x':sum(bbox[::2])/2,'y':sum(bbox[1::2])/2,'spatialReference':{'wkid':4326}}),'geometryType':'esriGeometryPoint','returnGeometry':'false','returnCatalogItems':'true'},timeout=60).json()
 (OUT/'ortho_catalog.json').write_text(json.dumps(q,indent=2))
 print('ORTHO',image.content[:4],len(image.content),flush=True)
def contours():
 import mapbox_vector_tile
 url='https://tiles.arcgis.com/tiles/ioennV6PpG5Xodq0/arcgis/rest/services/Contours2022/VectorTileServer'
 p0=tuple(v[0] for v in transform('EPSG:4326','EPSG:3857',[bbox[0]],[bbox[1]]));p1=tuple(v[0] for v in transform('EPSG:4326','EPSG:3857',[bbox[2]],[bbox[3]]))
 zoom=16;span=40075016.68557849/(2**zoom);origin=20037508.342789244
 features=[];tiles=[]
 for x in range(math.floor((p0[0]+origin)/span),math.floor((p1[0]+origin)/span)+1):
  for y in range(math.floor((origin-p1[1])/span),math.floor((origin-p0[1])/span)+1):
   path=f'/tile/{zoom}/{y}/{x}.pbf';r=requests.get(url+path,timeout=60);r.raise_for_status();(OUT/f'contour_{zoom}_{y}_{x}.pbf').write_bytes(r.content)
   d=mapbox_vector_tile.decode(r.content,default_options={'y_coord_down':True})
   tiles.append({'url':url+path,'layers':list(d)})
   for layer,value in d.items():
    extent=value['extent']
    for f in value['features']:
     f['layer']=layer;f['tile']=[zoom,x,y];f['tileExtent']=extent
     features.append(f)
 (OUT/'county_contours_decoded.json').write_text(json.dumps({'source':url,'tiles':tiles,'features':features}))
 print('CONTOURS',len(features),'properties',[f['properties'] for f in features[:4]],flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for f in concurrent.futures.as_completed([pool.submit(ortho),pool.submit(contours)]):
  try:f.result()
  except Exception as e:print('FAIL',repr(e),flush=True)
