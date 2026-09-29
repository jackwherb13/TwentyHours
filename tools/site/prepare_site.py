"""Rebuild owned exterior blueprint sections and a 4-ft grid from USGS 1 m DEM.

Only numpy, Pillow and requests are required. Run from repository root.
Existing non-owned site.json keys are retained. Every estimated detail is labelled.
"""
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / 'reference/web'
OUT = ROOT / 'verification/exterior'
MODULE = ROOT / 'src/ReplicatedStorage/RAC/Site'
LAT0, LON0 = 38.8322, -77.3124
ANGLE = math.radians(10.43)
C, S = math.cos(ANGLE), math.sin(ANGLE)
FT = 1 / .3048
X0, Z0, STEP, COUNT = -792, -648, 4, 300


def raw_geo(lat, lon):
    e = (lon - LON0) * 111320 * math.cos(math.radians(LAT0)) * FT
    n = (lat - LAT0) * 111320 * FT
    return e * C - n * S, -e * S - n * C


ANCHOR = raw_geo(38.8310914, -77.312432)
SHIFT = [-199.5 - ANCHOR[0], -204.5 - ANCHOR[1]]


def geo(lat, lon):
    x, z = raw_geo(lat, lon)
    return [round(x + SHIFT[0], 2), round(z + SHIFT[1], 2)]


def inverse(x, z):
    x, z = x - SHIFT[0], z - SHIFT[1]
    e, n = x * C - z * S, -x * S - z * C
    return LAT0 + n / (111320 * FT), LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)


def utm18(lat, lon):
    # Transverse Mercator on GRS80 (NAD83 / UTM18N, GeoTIFF EPSG:26918).
    a, f, k = 6378137.0, 1 / 298.257222101, .9996
    e2 = f * (2-f); ep = e2 / (1-e2)
    p, l = np.radians(lat), np.radians(lon + 75)
    n = a / np.sqrt(1-e2*np.sin(p)**2)
    t, cc, aa = np.tan(p)**2, ep*np.cos(p)**2, np.cos(p)*l
    m = a*((1-e2/4-3*e2**2/64-5*e2**3/256)*p-(3*e2/8+3*e2**2/32+45*e2**3/1024)*np.sin(2*p)+(15*e2**2/256+45*e2**3/1024)*np.sin(4*p)-35*e2**3/3072*np.sin(6*p))
    east = 500000+k*n*(aa+(1-t+cc)*aa**3/6+(5-18*t+t*t+72*cc-58*ep)*aa**5/120)
    north = k*(m+n*np.tan(p)*(aa*aa/2+(5-t+9*cc+4*cc*cc)*aa**4/24+(61-58*t+t*t+600*cc-330*ep)*aa**6/720))
    return east, north


def inside(x, z, poly):
    result = np.zeros(np.broadcast(x, z).shape, dtype=bool)
    for a, b in zip(poly, poly[1:]+poly[:1]):
        if a[1] != b[1]:
            result ^= ((a[1] > z) != (b[1] > z)) & (x < (b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0])
    return result


def distance(x, z, a, b):
    dx, dz = b[0]-a[0], b[1]-a[1]
    q = np.clip(((x-a[0])*dx+(z-a[1])*dz)/max(dx*dx+dz*dz, .0001), 0, 1)
    return np.hypot(x-a[0]-q*dx, z-a[1]-q*dz)


def pixel(px, py):
    return [round((px-685)*100/140*2)/2, round((py-470)*100/140*2)/2]


def main():
    site_path = ROOT/'blueprint_interim/site.json'
    original = json.loads(site_path.read_text())
    level = json.loads((ROOT/'blueprint_interim/level1.json').read_text())
    rooms = level['rooms']
    # Exterior-only build overrides live in the owned site section. The interior
    # source files remain untouched; Site.prepare applies these to a private copy.
    wall_overrides=[]
    for w in level['walls']:
        if w['id'] not in ('w063','w064','w034'): continue
        changed=json.loads(json.dumps(w))
        length=math.dist(w['a'],w['b'])
        doors=[o for o in w['openings'] if o['type']=='door']
        if w['id']=='w063':
            doors=[{'type':'door','offset':75,'width':6,'sill':0,'head':8,'leaves':2,'tag':'RACDoor'}]
        changed.update(material='glass',height=30,openings=[])
        last=0
        for door in sorted(doors,key=lambda o:o['offset']):
            if door['offset']>last:
                changed['openings'].append({'type':'curtainwall','offset':last,'width':door['offset']-last,'sill':0,'head':24,'mullionSpacing':5})
            changed['openings'].append(door)
            changed['openings'].append({'type':'curtainwall','offset':door['offset'],'width':door['width'],'sill':door['head'],'head':24,'mullionSpacing':5})
            last=door['offset']+door['width']
        if last<length:
            changed['openings'].append({'type':'curtainwall','offset':last,'width':length-last,'sill':0,'head':24,'mullionSpacing':5})
        wall_overrides.append(changed)
    for i,w in enumerate(level['walls']):
        level['walls'][i]=next((o for o in wall_overrides if o['id']==w['id']),w)
    osm = json.loads((ROOT/'reference/osm_rac_area.json').read_text())['elements']
    scene = {'schemaVersion': 1, 'trueNorthDeg': 10.43, 'lat0': LAT0, 'lon0': LON0,
             'geographicShiftFt': SHIFT, 'anchor': {'osm': [38.8310914,-77.312432], 'interim': [-199.5,-204.5]},
             'accuracyNote': 'OSM footprints and survey DEM are measured sources; untagged widths, vegetation sizes and photo-derived details are estimates. Interim plan differs from OSM; no scale warp applied.',
             'roads': [], 'areas': [], 'trees': [], 'fences': [], 'details': [],
             'exteriorWallOverrides':wall_overrides,
             'walkthrough':{'source':'docs/WALKTHROUGH.md, user 2026-09-28 23:00', 'level2ElevationFt':20,
                            'highSide':'west, near Cage gym', 'exitPositionStatus':'UNCONFIRMED; no doorway position invented',
                            'glassCorner':[0,58.5], 'glassReturnEnd':[-43,58.5]},
             'terrain': {'x0': X0, 'z0': Z0, 'step': STEP, 'count': COUNT, 'padPolygons': [r['polygon'] for r in rooms]}}
    widths = {'secondary':38,'tertiary':34,'residential':28,'unclassified':28,'service':20,'footway':6,'path':5,'cycleway':8,'steps':8,'pedestrian':12}
    for w in osm:
        tags = w.get('tags', {})
        if 'geometry' not in w:
            if tags.get('natural') == 'tree' and 'lat' in w:
                p = geo(w['lat'], w['lon'])
                if X0 < p[0] < X0+1200 and Z0 < p[1] < Z0+1200:
                    scene['trees'].append({'at':p,'height':30,'radius':10,'species':'deciduous','source':f"OSM node {w['id']}"})
            continue
        pts = [geo(p['lat'],p['lon']) for p in w['geometry']]
        if not any(X0-50<p[0]<X0+1250 and Z0-50<p[1]<Z0+1250 for p in pts): continue
        highway = tags.get('highway')
        if highway in widths:
            width = widths[highway]
            if 'width' in tags:
                try: width = float(tags['width'])*FT
                except ValueError: pass
            scene['roads'].append({'id':f"osm_{w['id']}",'points':pts,'width':round(width,2),'kind':highway,
                                   'name':tags.get('name',''),'source':'OSM geometry; width '+('tag metres' if 'width' in tags else 'photo estimate'),
                                   'bikeLane':highway in ('secondary','tertiary'),'markings':highway in ('secondary','tertiary','residential')})
        kind = 'parking' if tags.get('amenity') == 'parking' and tags.get('parking') != 'multi-storey' else 'pitch' if tags.get('leisure') == 'pitch' else 'building' if tags.get('building') and w['id'] != 112472416 else None
        if kind and len(pts)>3:
            height=float(tags.get('height','24').split()[0]) * FT if tags.get('height','').replace('.','',1).isdigit() else 24
            scene['areas'].append({'id':f"osm_{w['id']}",'polygon':pts,'kind':kind,'height':round(height,1),'source':'OSM; untagged building height estimated'})
    # Measured aerial pixel traces for features missing in the OSM extract.
    for ident, pts, width, kind in [
        ('east_front_walk',[(701,178),(701,565),(645,593)],8,'footway'),
        ('south_walk',[(326,674),(590,674),(668,592)],7,'footway'),
        ('west_walk',[(94,337),(137,485),(142,622),(319,661)],7,'footway'),
        ('service_drive',[(300,720),(300,580),(310,470)],20,'service'),
        ('entry_approach',[(712,612),(675,587),(655,557)],14,'footway')]:
        scene['roads'].append({'id':ident,'points':[pixel(*p) for p in pts],'width':width,'kind':kind,'markings':False,'bikeLane':False,'source':'site_plan_native.png pixel trace; width estimated'})
    scene['areas'] += [{'id':'rac_south_parking','polygon':[pixel(*p) for p in [(169,543),(286,543),(286,595),(169,595)]],'kind':'parking','source':'aerial trace'},
                       {'id':'rac_north_parking','polygon':[pixel(*p) for p in [(390,139),(670,139),(670,178),(390,178)]],'kind':'parking','source':'aerial trace'},
                       {'id':'service_yard','polygon':[pixel(*p) for p in [(300,544),(336,544),(336,600),(300,600)]],'kind':'parking','source':'IMG_0349-0351 + aerial'}]
    scene['swale'] = {'points':[pixel(*p) for p in [(390,93),(440,72),(530,66),(605,79)]], 'width':14, 'source':'IMG_0354/0355; approximate aerial trace'}
    # Individually recorded aerial canopy centres, not random scatter.
    tree_pixels=[(103,194),(98,240),(89,305),(98,369),(119,424),(81,463),(94,515),(121,579),(154,605),(193,607),(229,615),(262,630),(345,682),(397,689),(447,698),(494,697),(567,662),(620,650),(644,618),(705,593),(702,113),(660,101),(615,105),(552,91),(488,108),(406,96),(337,90),(285,82),(224,78),(181,91),(128,104),(91,139)]
    for i,p in enumerate(tree_pixels):
        scene['trees'].append({'at':pixel(*p),'height':28+(i%4)*3,'radius':10+(i%3)*2,'species':'pine' if i<12 or i>24 else 'deciduous','source':'site_plan_native.png canopy centre; photo species/estimated size'})
    scene['fences']=[{'id':'construction','points':[pixel(*p) for p in [(140,151),(352,151),(352,281),(141,281),(141,452)]],'height':8,'source':'site plan RAC addition boundary'},
                     {'id':'service_ramp','points':[pixel(*p) for p in [(299,542),(299,587),(331,587)]],'height':5,'source':'IMG_0349/0350 estimated fence line'}]
    # Facade uses existing wall/opening splitting. Preserve every door/window.
    faces=[]
    for w in level['walls']:
        if not w['exterior']: continue
        a,b=w['a'][:],w['b'][:]
        # Keep the skin clear of the perpendicular 1.33 ft backing wall ends;
        # against perpendicular backing walls while keeping wall apertures projected.
        dx0,dz0=b[0]-a[0],b[1]-a[1]; ln0=math.hypot(dx0,dz0)
        a=[a[0]+dx0/ln0*.75,a[1]+dz0/ln0*.75]
        b=[b[0]-dx0/ln0*.75,b[1]-dz0/ln0*.75]
        if w['material']=='glass':
            faces.append({'a':a,'b':b,'style':'metal_panel','base':24,'height':max(1,w['height']-24),'source':w['id']+' upper curtain-wall fascia; glazing already generated by Walls'})
            continue
        # Interior recesses: orient local -Z outward; the legacy builder tests rectangular site footprint.
        dx,dz=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dz)
        mx,mz=(a[0]+b[0])/2,(a[1]+b[1])/2
        plus_inside=any(bool(inside(mx-dz/length*2,mz+dx/length*2,r['polygon'])) for r in rooms)
        if not plus_inside: a,b=b,a
        metal = (w['a'][1]<-78 and min(w['a'][0],w['b'][0])>=-82) or (w['a'][1]<=-203)
        h=w['height']
        faces.append({'a':a,'b':b,'style':'brick','base':0,'height':8 if metal else h-3,'source':w['id']+'; IMG_0349-0363'})
        faces.append({'a':a,'b':b,'style':'metal_panel' if metal else 'precast_band','base':8 if metal else h-3,'height':h-8 if metal else 3,'source':w['id']+'; photo estimate'})
        if not metal and h>=28:
            # Custom fins are outside the skin, so do not duplicate an underlying wall.
            scene['details'].append({'kind':'sunshade','a':a,'b':b,'height':h-4,'spacing':4,'projection':2.5})
        if metal: scene['details'].append({'kind':'panel_joints','a':a,'b':b,'base':8,'height':h,'spacing':2})
    roofs=[]
    for r in rooms:
        poly=r['polygon']
        if len(poly)!=4: continue
        h=max([w['height'] for w in level['walls'] if any(p in poly for p in (w['a'],w['b']))] or [r['ceilingHeight']+2])
        if r['type']=='construction': continue
        xs,zs=[p[0] for p in poly],[p[1] for p in poly]
        lo,hi,top,bot=min(xs)+.9,max(xs)-.9,min(zs)+.9,max(zs)-.9
        roofs.append({'polygon':[[lo,top],[hi,top],[hi,bot],[lo,bot]],'height':h+.06,'type':'flat','overhang':0,'source':r['id']+' existing wall heights; inset avoids shared parapet overlap'})
        if hi-lo>45 and bot-top>40: scene['details'].append({'kind':'hvac','at':[(lo+hi)/2,(top+bot)/2],'y':h+.56,'size':[10,4,7]})
    scene['entrance']={'x':0,'z':0,'width':58,'landingDepth':13,'risers':10,'rise':7/12,'run':1.1,'canopyHeight':27,'canopyDepth':28,'canopyWidth':151,'columnRadius':.7,
                       'glassCorner':[0,58.5], 'glassReturnEnd':[-43,58.5], 'returnCanopyDepth':20,
                       'source':'IMG_0365: ten visible risers; 7 inch rise assumed. WEB_entrance_1/2: ~24 ft glazing, deep tapered canopy. Interim east lobby anchors.'}
    scene['crosswalks']=[{'road':'Campus Drive','at':pixel(660,15),'width':34,'rotation':0,'source':'aerial crosswalk and IMG_0357'}]
    # Keep pre-existing non-exterior props; own stable prefix allows repeatable updates.
    props=[p for p in original.get('props',[]) if not p.get('id','').startswith('site_')]
    for i,p in enumerate([(310,562),(325,566)]): props.append({'id':f'site_dumpster_{i}','kind':'site_dumpster','at':pixel(*p),'rotation':0,'room':'exterior','source':'IMG_0349 approximate service-yard position'})
    for i,p in enumerate([(184,549),(278,546),(414,156),(582,156),(699,188),(701,347),(699,539),(624,589),(359,684),(114,380)]): props.append({'id':f'site_lamp_{i}','kind':'site_lamp','at':pixel(*p),'rotation':0,'room':'exterior','source':'aerial/photo positions estimated'})
    for i,p in enumerate([(648,566),(610,577),(609,627)]): props.append({'id':f'site_shrub_{i}','kind':'site_shrub_bed','at':pixel(*p),'rotation':0,'room':'exterior','source':'IMG_0364/0368 planting beds; estimated'})
    original.update(facade=faces,roofs=roofs,props=props,site=scene)
    site_path.write_text(json.dumps(original,indent=1)+'\n')
    build_dem(scene, rooms)
    print(f'Site: {len(faces)} facade segments, {len(roofs)} roofs, {len(scene["roads"])} routes, {len(scene["areas"])} areas, {len(scene["trees"])} trees')


def build_dem(scene, rooms):
    Image.MAX_IMAGE_PIXELS=200000000
    im=Image.open(WEB/'rac_3dep_1m.tif')
    assert im.tag_v2[33550][:2]==(1.,1.), 'Source is not a 1 m DEM'
    assert 26918 in im.tag_v2[34735], 'Unexpected DEM CRS'
    tie=im.tag_v2[33922]
    x,z=np.meshgrid(X0+2+np.arange(COUNT)*STEP,Z0+2+np.arange(COUNT)*STEP)
    lat,lon=inverse(x,z); east,north=utm18(lat,lon)
    cols,rows=east-tie[3]-.5,tie[4]-north-.5
    box=(int(cols.min())-2,int(rows.min())-2,int(cols.max())+3,int(rows.max())+3)
    arr=np.array(im.crop(box)); assert np.all(arr>-1000),'DEM contains nodata'
    Image.fromarray(arr).save(WEB/'rac_dem_crop.tif')
    def sample(cx,cz):
        la,lo=inverse(cx,cz);e,n=utm18(la,lo)
        u,v=e-tie[3]-.5-box[0],tie[4]-n-.5-box[1]
        i,j=np.floor(u).astype(int),np.floor(v).astype(int);du,dv=u-i,v-j
        return arr[j,i]*(1-du)*(1-dv)+arr[j,i+1]*du*(1-dv)+arr[j+1,i]*(1-du)*dv+arr[j+1,i+1]*du*dv
    datum=float(sample(30,-10))+10*7/12*.3048
    h=(sample(x,z)-datum)*FT
    mask=np.zeros(h.shape,dtype=bool)
    distance_pad=np.full(h.shape,10000.)
    for r in rooms:
        p=r['polygon'];mask|=inside(x,z,p)
        for a,b in zip(p,p[1:]+p[:1]):distance_pad=np.minimum(distance_pad,distance(x,z,a,b))
    # The measured DEM already rises ~20 ft west of the Cage. Do NOT pull its
    # whole perimeter down to L1: that creates a false trench at the upper exit.
    # Flatten only the enclosed footprint; preserve surveyed grade outside it.
    # The low entrance apron alone blends to the L1 threshold.
    blend=np.clip(distance_pad/12,0,1);blend=blend*blend*(3-2*blend)
    low_side=np.clip((x+100)/100,0,1)
    collar=(1-blend)*low_side
    h=np.where(mask,-.65,-.65*collar+h*(1-collar))
    materials=np.ones(h.shape,dtype=np.uint8)
    materials[mask]=3
    # Asphalt/concrete terrain base follows exactly the OSM/site-plan surfaces.
    for route in scene['roads']:
        for a,b in zip(route['points'],route['points'][1:]):
            hit=distance(x,z,a,b)<route['width']/2
            materials[hit & ~mask]=3 if route['kind'] in ('footway','path','pedestrian','steps') else 2
    for area in scene['areas']:
        if area['kind']=='parking': materials[inside(x,z,area['polygon']) & ~mask]=2
    sw=scene['swale']
    for a,b in zip(sw['points'],sw['points'][1:]):
        dd=distance(x,z,a,b);hit=dd<sw['width']/2
        h-=np.maximum(0,1-dd/(sw['width']/2))*1.0
        materials[hit]=4
    # Flat entrance landing and stair toe reference, with a modest terrain clearance.
    ent=scene['entrance']; toe=(x>12)&(x<35)&(abs(z-ent['z'])<ent['width']/2+2)
    h[toe]=np.minimum(h[toe],-ent['risers']*ent['rise']-.15)
    h=np.round(h,2)
    meta={'source':json.loads((WEB/'dem_catalog.json').read_text())['items'][0]['downloadURL'],
          'sourceResolutionM':1,'crs':'EPSG:26918 NAD83 / UTM18N','verticalDatum':'NAVD88 metres','floorDatumM':datum,
          'floorDatumMethod':'DEM sample 30 ft east of facade plus photo-derived 10 x 7 inch entry stair rise; not a surveyed threshold elevation',
          'grid':{'x0':X0,'z0':Z0,'step':STEP,'nx':COUNT,'nz':COUNT,'cellCenters':True},
          'heightMinFt':float(h.min()),'heightMaxFt':float(h.max()),'geographicShiftFt':SHIFT,'trueNorthDeg':10.43,
          'padElevationFt':-.65,'padBlendFt':12,'padBlendPolicy':'Low/east side only. Natural DEM grade retained along west/high side; no exterior retaining cliff or perimeter trench.',
          'walkthroughLevel2Ft':20,'highSideSampleFt':float((sample(-410,-100)-datum)*FT),
          'exitDoorPositionStatus':'UNCONFIRMED; exact threshold pin must come from the interior blueprint owner',
          'cropPixelBox':box,'sourceGeoTiffOrigin':list(tie)}
    (OUT/'dem_provenance.json').write_text(json.dumps(meta,indent=2)+'\n')
    (OUT/'terrain_grid.json').write_text(json.dumps({'meta':meta,'heights':h.tolist(),'materials':materials.tolist()},separators=(',',':')))
    lines=['--!strict','-- Generated by tools/site/prepare_site.py from USGS 1 m DEM; see dem_provenance.json.', 'return {',f' x0 = {X0}, z0 = {Z0}, step = {STEP}, nx = {COUNT}, nz = {COUNT},',f' yMin = {math.floor((h.min()-12)/4)*4}, yMax = {math.ceil((h.max()+8)/4)*4},',' rows = {']
    lines.extend(' "'+','.join(str(int(round(v*100))) for v in row)+'",' for row in h)
    lines+=[' },',' materials = {']
    lines.extend(' "'+''.join(str(v) for v in row)+'",' for row in materials)
    lines+=[' },','}']
    (MODULE/'TerrainData.luau').write_text('\n'.join(lines)+'\n')
    # Review packet: measurable elevations, context lines and interim walls.
    shade=(h-h.min())/(h.max()-h.min()); rgb=np.zeros((COUNT,COUNT,3),dtype=np.uint8)
    rgb[:,:,0]=70+shade*135;rgb[:,:,1]=95+shade*105;rgb[:,:,2]=55+shade*95
    rgb[materials==2]=[62,65,66];rgb[materials==3]=[175,174,160];rgb[materials==4]=[109,117,126]
    packet=Image.fromarray(rgb).resize((900,900));draw=ImageDraw.Draw(packet)
    def p(q): return ((q[0]-X0)*.75,(q[1]-Z0)*.75)
    for room in rooms: draw.polygon([p(q) for q in room['polygon']],outline='white',width=2)
    for t in scene['trees']:
        px,pz=p(t['at']);draw.ellipse((px-4,pz-4,px+4,pz+4),outline='#14351b',width=2)
    draw.rectangle((5,5,890,62),fill='white');draw.text((15,14),f'USGS 1 m DEM -> 4 ft grid | 1200 x 1200 ft | north-grid bearing 10.43 deg\nRelative elevations {h.min():.1f} to {h.max():.1f} ft; white = interim building pad | Photo datum estimated',fill='black')
    packet.save(OUT/'site_packet.png')
    print(f'DEM {h.shape}, relative range {h.min():.2f}..{h.max():.2f} ft; threshold datum {datum:.3f} m NAVD88')


if __name__ == '__main__': main()
