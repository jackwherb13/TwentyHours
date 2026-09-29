import requests,json
from pathlib import Path
from PIL import Image
sources={'gmu_rac_2019':'https://recreation.gmu.edu/wp-content/uploads/2019/12/RAC.jpg','gmu_facilities120':'https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/georgemason.sidearmsports.com/images/2016/11/1/Facilities120.jpg'}
for name,url in sources.items():
 r=requests.get(url,timeout=40);r.raise_for_status(); p=Path('reference/web')/(name+'.jpg');p.write_bytes(r.content)
 im=Image.open(p);im.thumbnail((640,640));im.save(p.with_name(name+'_thumb.jpg'))
Path('reference/web/web_sources.json').write_text(json.dumps({'images':sources,'usage':'Architectural reference only. Never use photos containing people as textures.'},indent=2))
