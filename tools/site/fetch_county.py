"""Fetch bounded authoritative GIS features, ortho imagery and latest USGS LAZ."""
import concurrent.futures
import json
from pathlib import Path
import requests

OUT=Path('reference/web'); bbox=json.loads((OUT/'site_bbox.json').read_text())['bbox4326']
base='https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/'
services=json.loads((OUT/'county_agol.json').read_text())['services']
names=['Roadways_and_Bridges','Driveways_and_Parking_Lots','Sidewalks_Centerline','2023_Countywide_Impervious','Buildings','Buildings_Current','OpenData_S9']
jobs={s['name']:s['url'] for s in services if s['name'] in names}
jobs['county_contours']='https://tiles.arcgis.com/tiles/ioennV6PpG5Xodq0/arcgis/rest/services/Contours2022/VectorTileServer'
jobs['two_foot_contours']='https://services2.arcgis.com/DANcyjLcCCpGk8Ri/arcgis/rest/services/Two_Foot_Contours/FeatureServer'
def fetch(item):
 name,url=item
 try:
  meta=requests.get(url,params={'f':'json'},timeout=60).json();(OUT/(name+'_service.json')).write_text(json.dumps(meta,indent=2))
  results=[]
  for layer in meta.get('layers',[]):
   endpoint=url+'/'+str(layer['id'])
   detail=requests.get(endpoint,params={'f':'json'},timeout=60).json()
   (OUT/(name+'_'+str(layer['id'])+'_meta.json')).write_text(json.dumps(detail,indent=2))
   if detail.get('type')=='Group Layer':continue
   params={'f':'json','where':'1=1','geometry':','.join(map(str,bbox)),'geometryType':'esriGeometryEnvelope','inSR':4326,'outSR':4326,'spatialRel':'esriSpatialRelIntersects','outFields':'*','returnGeometry':'true','resultRecordCount':2000}
   d=requests.get(endpoint+'/query',params=params,timeout=60).json()
   (OUT/(name+'_'+str(layer['id'])+'_features.json')).write_text(json.dumps(d))
   results.append((layer['id'],layer['name'],len(d.get('features',[])),d.get('error'),d.get('exceededTransferLimit',False)))
  return name,results if results else {k:meta.get(k) for k in ['serviceItemId','tiles','minScale','maxScale','error']}
 except Exception as e:return name,str(e)
def lidar():
 item=next(i for i in json.loads((OUT/'lidar_catalog.json').read_text())['items'] if 'NorthernVA_B22' in i['title'])
 dest=OUT/'rac_lidar_2022.laz'
 if not dest.exists() or dest.stat().st_size<item['sizeInBytes']:
  r=requests.get(item['downloadURL'],stream=True,timeout=120);r.raise_for_status()
  with dest.open('wb') as f:
   for c in r.iter_content(1024*1024):f.write(c)
 (OUT/'lidar_selected.json').write_text(json.dumps(item,indent=2))
 return 'LAZ',dest.stat().st_size
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
 futures=[pool.submit(fetch,i) for i in jobs.items()]+[pool.submit(lidar)]
 for f in concurrent.futures.as_completed(futures):print(f.result(),flush=True)
