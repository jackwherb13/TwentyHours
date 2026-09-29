"""Prepare canonical schema objects from blueprint survey records, preserving evidence.
Only blueprint/ is written. Run before architect_build.py after editing survey records.
"""
import copy
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT/'blueprint'
BASE = ROOT/'verification/M1/baseline'


def read(path):return json.loads(path.read_text(encoding='utf-8'))
def write(name,d): (BP/name).write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')
def rect(x,z,X,Z):return [[x,z],[X,z],[X,Z],[x,Z]]


def main():
    c=read(BP/'architect_constraints.json')
    levels=[dict(level=n,elevation=0 if n==1 else c['level2Elevation'],rooms=[],connections=[],apertures=[],stairs=[],columns=[],voids=[],props=[]) for n in (1,2)]
    defaults={'gym':('maple',32,'open_joist'),'corridor':('terrazzo',10,'act_2x4'),
              'lobby':('porcelain_tile',32,'gypsum'),'fitness':('rubber',12,'act_2x2'),
              'stair':('sealed_concrete',32,'none'),'locker':('porcelain_tile',9,'act_2x2'),
              'restroom':('ceramic_tile',9,'gypsum'),'support':('porcelain_tile',10,'act_2x4'),
              'office':('carpet_tile',9,'act_2x2'),'storage':('sealed_concrete',10,'none'),
              'mechanical':('sealed_concrete',12,'none'),'racquetball':('maple',20,'gypsum'),
              'void':('sealed_concrete',0,'none'),'construction':('sealed_concrete',24,'none')}
    def add(l,rid,typ,poly):
        f,h,t=defaults[typ]
        if l['level']==2 and typ=='stair':h=12
        if rid=='south_gym':h=28
        if rid=='cage_gym':h=24
        if rid=='nutrition_vestibule':h=9
        l['rooms'].append(dict(id=rid,name=rid.replace('_',' ').title(),type=typ,polygon=poly,
                               floorMaterial=f,ceilingHeight=h,ceilingType=t,wallFinish='gypsum' if typ in ('office','fitness','lobby') else 'painted_cmu'))
    n=0
    for line in (BP/'architect_room_schedule.txt').read_text().splitlines():
        if line in ('# L1','# L2'):n=int(line[-1])-1
        if not line or line.startswith('#'):continue
        rid,typ,*bounds=line.split();add(levels[n],rid,typ,rect(*map(float,bounds)))
    for r in c['customRooms']:
        for n in r['levels']:add(levels[n-1],r['id'],r['type'],copy.deepcopy(r['polygon']))
    for key,value in c.get('ceilingOverrides',{}).items():
        n,rid=key.split(':')
        r=next(r for r in levels[int(n)-1]['rooms'] if r['id']==rid)
        r['ceilingHeight']=value['height'];r['ceilingType']=value['type']
    for l in levels:
        for row in c['commonConnections']+c[f"level{l['level']}Connections"]:
            a,b,w,*typ=row
            v=dict(rooms=[a,b],width=w,type=typ[0] if typ else 'door')
            if b=='nutrition_vestibule':v.update(keypadCode='15234',label='NUTRITION VESTIBULE')
            if b=='cage_gym':v['label']='BASKETBALL - OFF LIMITS'
            l['connections'].append(v)
        l['apertures']=[{k:copy.deepcopy(v) for k,v in a.items() if k!='level'} for a in c['apertures'] if a['level']==l['level']]
        l['guards']=[dict(id=f'gallery_guard_{i}',a=g['a'],b=g['b']) for i,g in enumerate(c.get('guards',[]),1) if g['level']==l['level']]
        for rid,stair in c['stairEnvelopes'].items():
            r=next(r for r in l['rooms'] if r['id']==rid)
            l['stairs'].append(dict(id=rid,polygon=copy.deepcopy(r['polygon']),fromLevel=1,toLevel=2,**stair))
        # Column lines inferred from the visible gallery bays, kept out of court areas.
        for x in (-53.5,-21.5):
            for z in (28,64,100):
                l['columns'].append(dict(id=f'gallery_{x}_{z}',at=[x,z],size=[1.5,1.5],height=19.75 if l['level']==1 else 12))
    l1,l2=levels
    for r in l2['rooms']:
        if r['type']=='void':l2['voids'].append(dict(id=r['id'],polygon=copy.deepcopy(r['polygon'])))
    # Explicit shaft holes; landing polygons are in stair_details.json.
    for rid in c['stairEnvelopes']:
        r=next(r for r in l2['rooms'] if r['id']==rid)
        xs=[p[0] for p in r['polygon']];zs=[p[1] for p in r['polygon']]
        l2['voids'].append(dict(id=rid+'_opening',polygon=rect(min(xs)+1,min(zs)+6,max(xs)-1,max(zs)-1)))
    sx,sz=c['previousFrameShiftFt']
    def point(p):return [round((p[0]-sx)*2)/2,round((p[1]-sz)*2)/2]
    for l in levels:
        for key in ('rooms','stairs','voids'):
            for r in l[key]:r['polygon']=[point(p) for p in r['polygon']]
        for r in l['columns']:r['at']=point(r['at'])
        for a in l['apertures']:a['a']=point(a['a']);a['b']=point(a['b'])
        for a in l['guards']:a['a']=point(a['a']);a['b']=point(a['b'])
    site=read(BASE/'site.json')
    site['footprint']=[point(p) for p in site['footprint']]
    site['levels']=[dict(level=1,elevation=0),dict(level=2,elevation=c['level2Elevation'])]
    site['facade']=[];site['roofs']=[]
    for a,b in zip(site['footprint'],site['footprint'][1:]+site['footprint'][:1]):
        if math.dist(a,b)<2:continue
        if (a[0]==b[0]==15-sx and min(a[1],b[1])>=17.5-sz) or (a[1]==b[1]==172-sz):continue
        site['facade'].append(dict(a=a,b=b,style='brick',height=36,base=0))
    for r in c['roofSchedule']:
        site['roofs'].append(dict(polygon=[point(p) for p in r['polygon']],height=r['height'],type='flat',overhang=0))
    site['roofs'].append(dict(polygon=[point(p) for p in c['canopy']['polygon']],height=c['canopy']['height'],type='canopy',overhang=0))
    site['origin']['desc']='Main entrance SOUTH-facing smaller glass frontage, near site-plan (680,579); 23:20 user correction; provisional +/-3 ft'
    site['origin']['previousBlueprintTranslationFt']=[-sx,-sz]
    theta=math.radians(-10.43);E=sx*math.cos(theta)+sz*math.sin(theta);N=sx*math.sin(theta)-sz*math.cos(theta)
    site['origin']['lat']+=N/(111320*3.280839895)
    site['origin']['lon']+=E/(111320*3.280839895*math.cos(math.radians(site['origin']['lat'])))
    site['calibration']='calibration.json'
    write('architect_layout.json',dict(status=c['status'],levels=levels,site=site))
    cal=read(BASE/'calibration.json');cal['shift']['x']+=sx;cal['shift']['z']+=sz
    cal['entrance']=dict(px=680,py=579,note='South smaller-glass threshold per 23:20 correction; full 107ft south glazing, 15ft longer than prior vestibule. Provisional +/-3ft.')
    cal['previousBlueprintTranslationFt']=[-sx,-sz];write('calibration.json',cal)
    print('Prepared source:',sum(len(l['rooms']) for l in levels),'spaces')


if __name__=='__main__':main()
