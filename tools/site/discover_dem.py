import requests,json
from pathlib import Path
p=Path('reference/web')
u='https://tnmaccess.nationalmap.gov/api/v1/products'
r=requests.get(u,params={'datasets':'Digital Elevation Model (DEM) 1 meter','bbox':'-77.3155,38.8295,-77.3090,38.8345','max':20},timeout=60); r.raise_for_status(); d=r.json(); (p/'dem_catalog.json').write_text(json.dumps(d,indent=2)); print([(i.get('title'),i.get('downloadURL'),i.get('boundingBox')) for i in d.get('items',[])])
u='https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer'
d=requests.get(u+'/query',params={'f':'json','geometry':'-77.3124,38.8322','geometryType':'esriGeometryPoint','inSR':4326,'outFields':'*','returnGeometry':'false'},timeout=60).json();(p/'dem_service_catalog.json').write_text(json.dumps(d,indent=2)); print(str(d)[:12000])
