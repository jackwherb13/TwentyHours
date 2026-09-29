"""Find and record official county GIS and USGS point-cloud endpoints."""
import concurrent.futures
import json
from pathlib import Path
import requests
from prepare_site import inverse

OUT=Path('reference/web'); OUT.mkdir(exist_ok=True)
corners=[inverse(x,z) for x in [-592,208] for z in [-448,352]]
bbox=[min(p[1] for p in corners),min(p[0] for p in corners),max(p[1] for p in corners),max(p[0] for p in corners)]
jobs={
 'county_catalog':('https://www.fairfaxcounty.gov/lambert/rest/services',{'f':'json'}),
 'county_open':('https://www.fairfaxcounty.gov/lambert/rest/services/OpenData',{'f':'json'}),
 'county_agol':('https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services',{'f':'json'}),
 'lidar_catalog':('https://tnmaccess.nationalmap.gov/api/v1/products',{'datasets':'Lidar Point Cloud (LPC)','bbox':','.join(map(str,bbox)),'max':100}),
 'imagery_service':('https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer',{'f':'json'}),
 'county_search':('https://www.arcgis.com/sharing/rest/search',{'f':'json','q':'"Fairfax" ("planimetric" OR "contours" OR "pavement")','num':100})}
def fetch(item):
 name,(url,params)=item
 try:
  r=requests.get(url,params=params,timeout=60);r.raise_for_status();d=r.json();(OUT/(name+'.json')).write_text(json.dumps(d,indent=2))
  if name=='lidar_catalog': result=[(i.get('title'),i.get('downloadURL'),i.get('boundingBox')) for i in d.get('items',[])]
  elif name=='county_search': result=[(i['id'],i['title'],i.get('url')) for i in d.get('results',[])]
  else: result=d.get('services',d.get('folders',str(d)[:1000]))
  return name,result
 except Exception as e:return name,str(e)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
 for name,result in pool.map(fetch,jobs.items()):print(name,json.dumps(result)[:26000],flush=True)
(OUT/'site_bbox.json').write_text(json.dumps({'bbox4326':bbox,'blueprintBounds':[-592,-448,208,352]},indent=2))
