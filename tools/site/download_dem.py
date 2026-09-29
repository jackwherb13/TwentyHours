from pathlib import Path
import json, requests, time
p=Path('reference/web'); item=json.loads((p/'dem_catalog.json').read_text())['items'][0]; dest=p/'rac_3dep_1m.tif'
if not dest.exists():
 r=requests.get(item['downloadURL'],stream=True,timeout=120);r.raise_for_status()
 with dest.open('wb') as f:
  for c in r.iter_content(1024*1024):f.write(c)
 print('Downloaded',dest.stat().st_size,flush=True)
from PIL import Image
Image.MAX_IMAGE_PIXELS=200000000
im=Image.open(dest); print(im.size,im.mode,dict(im.tag_v2),flush=True)
