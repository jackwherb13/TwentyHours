import json,math
from pathlib import Path
els=json.load(open('reference/osm_rac_area.json'))['elements']
w=next(x for x in els if x['id']==112472416)
a=math.radians(10.43);c=math.cos(a);s=math.sin(a)
def xz(p):
 e=(p['lon']+77.3124)*111320*math.cos(math.radians(38.8322))/.3048;n=(p['lat']-38.8322)*111132/.3048
 return (e*c-n*s,-e*s-n*c)
print('RAC',[(tuple(round(v,2) for v in xz(p)),p) for p in w['geometry']]);print('tag groups',[(x['id'],x.get('tags',{})) for x in els if x.get('tags',{}).get('amenity')=='parking'])
