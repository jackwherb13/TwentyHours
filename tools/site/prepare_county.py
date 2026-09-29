"""800 ft exterior from county planimetrics, USGS LAZ and VGIN ortho classes.

Run process_lidar.py first. Only owned site sections and exterior artifacts change.
RGB aerial imagery is reference only, never a building/character texture.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'.vendor'))
sys.modules['pyproj']=None
import json,math
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import map_coordinates
from rasterio.warp import transform
from shapely.geometry import Polygon,LineString,Point,box
from shapely.ops import unary_union
from shapely import contains_xy,make_valid
from process_lidar import grid_coordinates,X0,Z0,N,STEP
from prepare_site import ROOT,inverse,distance

WEB=ROOT/'reference/web';OUT=ROOT/'verification/exterior';MODULE=ROOT/'src/ReplicatedStorage/RAC/Site'
BOUNDS=box(X0,Z0,X0+800,Z0+800)
xx,zz=np.meshgrid(X0+2+np.arange(N)*STEP,Z0+2+np.arange(N)*STEP)

def rings_shape(rings):
    result=Polygon()
    for ring in rings:
        x,z=grid_coordinates([p[1] for p in ring],[p[0] for p in ring])
        polygon=make_valid(Polygon(np.column_stack((x,z))))
        result=result.symmetric_difference(polygon)
    return result.intersection(BOUNDS)

def features(name):
    return json.loads((WEB/(name+'_0_features.json')).read_text())['features']

def parts(geometry):
    return [geometry] if geometry.geom_type in ('Polygon','LineString') else [g for g in geometry.geoms if not g.is_empty]

def add_lane_lines(shapes, markings):
    """Double-yellow center and white edges on straight two-lane county pavement.

    Paint is not in the planimetric layers. Layout is inferred from IMG_0356-0360
    and clipped so the segment midpoint stays on pavement.
    """
    for shape in shapes:
      for polygon in parts(shape):
        if polygon.geom_type != 'Polygon' or polygon.area < 1200 or len(markings) > 260:
            continue
        rect = np.array(polygon.minimum_rotated_rectangle.exterior.coords[:4])
        edges = [(rect[i], rect[(i + 1) % 4]) for i in range(4)]
        edges.sort(key=lambda e: -np.linalg.norm(e[1] - e[0]))
        long_a, long_b = edges[0]
        length = float(np.linalg.norm(long_b - long_a))
        short = float(np.linalg.norm(edges[2][1] - edges[2][0]))
        if short < 18 or short > 70 or length < 70:
            continue
        u = (long_b - long_a) / length
        v = np.array([-u[1], u[0]])
        center = rect.mean(axis=0)
        half = short / 2
        specs = [(0.4, 'yellow', 0.3), (-0.4, 'yellow', 0.3), (half - 1.3, 'white', 0.3), (-(half - 1.3), 'white', 0.3)]
        if short >= 34:
            specs += [(half - 6, 'white', 0.3), (-(half - 6), 'white', 0.3)]
        steps = max(1, math.ceil(length / 56))
        for along, color, width in specs:
            origin = center + v * along - u * (length / 2)
            for k in range(steps):
                if len(markings) > 260:
                    return
                p = origin + u * (length * k / steps)
                q = origin + u * (length * (k + 1) / steps)
                mid = (p + q) / 2
                if polygon.buffer(-0.5).covers(Point(mid)):
                    markings.append({'a': np.round(p, 2).tolist(), 'b': np.round(q, 2).tolist(), 'color': color, 'width': width,
                                     'source': 'Fairfax pavement polygon; lane paint inferred from IMG_0356-0360, not a surveyed stripe layer'})

def prepare():
    path=ROOT/'blueprint_interim/site.json';data=json.loads(path.read_text());scene=data['site']
    heightdata=np.load(WEB/'lidar_grids.npz');floor=float(heightdata['floorDatumFt']);h=heightdata['heights'].copy()
    surface=[];parking=[];road_shapes=[];building=[];sidewalk=[];sourcecounts={}
    for name in ('Roadways_and_Bridges','Driveways_and_Parking_Lots','Buildings','2023_Countywide_Impervious'):
        fs=features(name);sourcecounts[name]=len(fs)
        for f in fs:
            shape=rings_shape(f['geometry'].get('rings',[]))
            if shape.is_empty:continue
            attrs=f['attributes'];kind=attrs.get('TYPE',attrs.get('IMPERVIOUS_TYPE',''))
            if name=='Buildings': building.append(shape)
            elif name=='2023_Countywide_Impervious':
                if kind.lower()=='sidewalk':sidewalk.append(shape)
            elif kind not in ('MEDIAN','UNPAVED ROAD'):
                surface.append(shape)
                if 'PARKING' in kind:parking.append((shape,attrs['OBJECTID']))
                else:road_shapes.append(shape)
    roads=unary_union(surface).buffer(0)
    walks=unary_union(sidewalk).buffer(0)
    buildings=unary_union(building).buffer(0)
    pads=unary_union([Polygon(p) for p in scene['terrain']['padPolygons']])
    padmask=contains_xy(pads,xx,zz)
    # Keep L1 inside flat while preserving the natural +20 ft west-side grade.
    h[padmask]=-.65
    # Leave the lidar surface intact outside the building. The entrance stair is built
    # on top of that surface; carving a toe pit dropped the south road below the circle.
    e=scene['entrance']
    # Stair, apron, and the east 1:12 ramp. Pavement patches stop here so they do not bury the run.
    entrance=box(e['x']-e['width']/2-8,e['z']-1,e['x']+e['width']/2+16,e['z']+100)
    hard_exclusion=pads.union(entrance)
    roads=roads.difference(hard_exclusion);walks=walks.difference(hard_exclusion)
    roadmask=contains_xy(roads,xx,zz);walkmask=contains_xy(walks,xx,zz)
    # Sample public ortho in the exact same building-grid coordinates as the DEM.
    image=np.asarray(Image.open(WEB/'rac_ortho.png').convert('RGB'))
    meta=json.loads((WEB/'vgin_export.json').read_text());a,b,c,d=meta['bounds26918']
    lat,lon=inverse(xx.ravel(),zz.ravel());east,north=transform('EPSG:4326','EPSG:26918',lon.tolist(),lat.tolist())
    u=(np.asarray(east)-a)/(c-a)*(image.shape[1]-1);v=(d-np.asarray(north))/(d-b)*(image.shape[0]-1)
    rgb=np.stack([map_coordinates(image[:,:,k].astype(float),[v,u],order=1,mode='nearest').reshape(N,N) for k in range(3)],axis=2)
    Image.fromarray(np.uint8(rgb)).save(WEB/'ortho_blueprint.png')
    materials=np.ones((N,N),dtype=np.uint8)
    brightness=rgb.mean(axis=2);brown=(rgb[:,:,0]>rgb[:,:,1]*1.12)&(rgb[:,:,1]>rgb[:,:,2]*1.05)&(brightness<125)
    materials[brown & ~padmask]=5
    materials[roadmask]=2;materials[walkmask|padmask]=3
    # Entrance photos are a concrete forecourt, not lawn against the stair. Keep roads (already asphalt).
    forecourt=(np.abs(xx-(-21.5))<46)&(zz>54)&(zz<148)&(materials==1)
    materials[forecourt]=3
    # Rock channel is photo evidence, because ortho color alone cannot identify it reliably.
    sw=scene['swale']
    for p,q in zip(sw['points'],sw['points'][1:]):
        materials[(distance(xx,zz,p,q)<sw['width']/2)&~padmask&~roadmask&~walkmask]=4
    palette=np.array([[0,0,0],[88,109,54],[62,65,67],[191,186,171],[117,121,123],[96,72,48]],dtype=np.uint8)
    Image.fromarray(palette[materials]).save(OUT/'colormap.png')
    ymin=math.floor((float(h.min())-8)/4)*4;ymax=math.ceil((float(h.max())+8)/4)*4
    encoded=np.uint16(np.round(np.clip((h-ymin)/(ymax-ymin),0,1)*65535))
    Image.fromarray(encoded).save(OUT/'heightmap.png')
    h=np.round(h,2)
    # Compact non-overlapping 4-ft mask rectangles. Maximum patch 24 x 12 ft.
    # County rings define these masks; there is no inferred OSM road width.
    patches=[]
    for mask,kind in [(roadmask & ~walkmask,'asphalt'),(walkmask,'concrete')]:
        used=np.zeros((N,N),dtype=bool)
        for j in range(N):
            i=0
            while i<N:
                if not mask[j,i] or used[j,i]:i+=1;continue
                end=i+1
                while end<min(N,i+12) and mask[j,end] and not used[j,end]:end+=1
                bottom=j+1
                while bottom<min(N,j+6) and np.all(mask[bottom,i:end]&~used[bottom,i:end]):bottom+=1
                used[j:bottom,i:end]=True
                patches.append({'x':X0+i*4,'z':Z0+j*4,'w':(end-i)*4,'d':(bottom-j)*4,'material':kind})
                i=end
    # Road and parking boundaries are curb alignment evidence; curb presence/height inferred.
    curbs=[]
    for polygon in parts(roads.simplify(.8,preserve_topology=True)):
        if polygon.geom_type!='Polygon':continue
        for ring in [polygon.exterior,*polygon.interiors]:
            pts=list(ring.coords)
            for a,b in zip(pts,pts[1:]):
                if math.dist(a,b)<.5:continue
                mid=((a[0]+b[0])/2,(a[1]+b[1])/2)
                if min(mid[0]-X0,X0+800-mid[0],mid[1]-Z0,Z0+800-mid[1])<1:continue
                if hard_exclusion.distance(Point(mid))<1:continue
                count=math.ceil(math.dist(a,b)/72)
                for k in range(count):
                    curbs.append({'a':[round(a[c]+(b[c]-a[c])*k/count,2) for c in range(2)],'b':[round(a[c]+(b[c]-a[c])*(k+1)/count,2) for c in range(2)]})
    markings=[]
    for polygon,oid in parking:
        polygon=polygon.difference(hard_exclusion)
        if polygon.is_empty or polygon.area<500:continue
        rect=list(polygon.minimum_rotated_rectangle.exterior.coords)
        edges=[(np.array(rect[(i+1)%4])-np.array(rect[i])) for i in range(4)]
        edge=max(edges,key=lambda p:np.linalg.norm(p));u=edge/np.linalg.norm(edge);v=np.array([-u[1],u[0]])
        coords=np.array(rect); amin,amax=(coords@u).min(),(coords@u).max();bmin,bmax=(coords@v).min(),(coords@v).max()
        for side in np.arange(bmin+2,bmax-18,36):
            if len(markings)>180:break
            for offset in np.arange(amin+3,amax-3,9):
                if len(markings)>180:break
                p=u*offset+v*side;q=p+v*18
                if polygon.buffer(-1).covers(LineString([p,q])):
                    markings.append({'a':np.round(p,2).tolist(),'b':np.round(q,2).tolist(),'color':'white','width':.3,'source':f'County parking polygon {oid}; 9x18 ft stall layout inferred, individual markings not in GIS'})
    add_lane_lines(road_shapes, markings)
    # Retain the documented photo/aerial crosswalk location, clipped to actual pavement.
    for crossing in scene['crosswalks']:
        x,z=crossing['at']
        for offset in np.arange(-crossing['width']/2,crossing['width']/2,4):
            p=[x+offset,z-5];q=[x+offset,z+5]
            if roads.buffer(1).covers(LineString([p,q])):markings.append({'a':p,'b':q,'color':'white','width':2,'source':'Photo/site-plan crossing clipped to Fairfax pavement polygon'})
    trees=json.loads((OUT/'lidar_trees.json').read_text())['trees']
    trees=[t for t in trees if not pads.buffer(3).contains(Point(t['at'])) and not roads.buffer(1).contains(Point(t['at']))][:150]
    scene.update(roads=[],areas=[],trees=trees,planimetric={'source':'Fairfax County planimetrics, REST bounding-box query', 'patches':patches,'curbs':curbs,'markings':markings,'sourceCounts':sourcecounts,
                  'edgeAccuracyFt':2,'notes':'4-ft raster hardscape patches are within 2 ft of source boundaries. Curbs use simplified vector polygon edges. Curb height and stall layout are estimates, not surveyed.'})
    scene['terrain'].update(x0=X0,z0=Z0,step=STEP,count=N)
    scene['budget']={'maxParts':6000,'maxTrees':150,'areaFt':[800,800],'minimumDetailFt':.3,'stripeException':True}
    scene['terrain']['heightmap']='verification/exterior/heightmap.png';scene['terrain']['colormap']='verification/exterior/colormap.png'
    scene['terrain']['heightEncoding']={'bits':16,'minFt':ymin,'maxFt':ymax,'decode':'minFt + pixel/65535*(maxFt-minFt)','rowDirection':'+Z','origin':'upper-left pixel edge [x0,z0]','pixelSizeFt':4}
    data['site']=scene;path.write_text(json.dumps(data,indent=1)+'\n')
    provenance={'sourceResolutionM':'classified USGS 2022 LAZ ground returns','grid':{'x0':X0,'z0':Z0,'nx':N,'nz':N,'step':STEP,'cellCenters':True},'floorDatumFtNAVD88':floor,
                'floorDatumMethod':'classified ground 30 ft south of corrected south entrance + 10 assumed 7-inch risers; not surveyed threshold','heightMinFt':float(h.min()),'heightMaxFt':float(h.max()),'trueNorthDeg':10.43,
                'heightEncoding':scene['terrain']['heightEncoding'],'classification':'VGIN RGB brown/grass heuristic plus county road/sidewalk polygons; photo-derived rock swale overrides. Vegetation shadows and mulch/soil remain uncertain.',
                'highSideExit':'Measured high-side slope preserved. Exact exit coordinates not supplied; no doorway grade-match claim.', 'sourceCounts':sourcecounts}
    (OUT/'terrain_grid.json').write_text(json.dumps({'meta':provenance,'heights':h.tolist(),'materials':materials.tolist()},separators=(',',':')))
    (OUT/'dem_provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    lines=['--!strict','-- Generated by tools/site/prepare_county.py from USGS LAZ and county planimetrics.','return {',f' x0={X0}, z0={Z0}, step={STEP}, nx={N}, nz={N}, yMin={ymin}, yMax={ymax},',' rows={']
    lines+=[' "'+','.join(str(int(round(v*100))) for v in row)+'",' for row in h]
    lines+=[' }, materials={']+[' "'+''.join(map(str,row))+'",' for row in materials]+[' },','}']
    (MODULE/'TerrainData.luau').write_text('\n'.join(lines)+'\n')
    contour_check(h,floor,pads)
    # One review packet includes orthophoto, classification and elevation map.
    packet=Image.new('RGB',(1200,450),'white');draw=ImageDraw.Draw(packet)
    shade=np.uint8((h-h.min())/(h.max()-h.min())*255)
    for k,im in enumerate([Image.fromarray(np.uint8(rgb)),Image.fromarray(palette[materials]),Image.fromarray(shade).convert('RGB')]):packet.paste(im.resize((400,400)),(k*400,50))
    draw.text((12,8),'800 x 800 ft | 4 ft/pixel | USGS 2022 LAZ + Fairfax planimetrics + VGIN ortho | grid bearing 10.43 deg',fill='black')
    draw.text((12,29),'Public ortho (reference only)                         Terrain material classes                                  Relative elevation (dark = low)',fill='black')
    packet.save(OUT/'site_packet.png')
    print(f'County model: {len(patches)} surface patches, {len(curbs)} curb segments, {len(markings)} stripes, {len(trees)} trees',flush=True)

def contour_check(h,floor,pads):
    data=json.loads((WEB/'county_contours_numeric.json').read_text());points=[];lines=[]
    for f in data['features']:
        elevation=f['attributes']['CONTOUR']
        if abs(elevation/2-round(elevation/2))>.001:continue
        for path in f['geometry'].get('paths',[]):
            x,z=grid_coordinates([q[1] for q in path],[q[0] for q in path]);keep=(x>X0+4)&(x<X0+796)&(z>Z0+4)&(z<Z0+796)
            xy=np.column_stack((x[keep],z[keep]))
            if len(xy)<2:continue
            lines.append({'elevationFtNAVD88':elevation,'points':np.round(xy,2).tolist()})
            for q in xy[::10]:
                if not pads.buffer(8).contains(Point(q)):
                    ground=float(map_coordinates(h,[[(q[1]-Z0)/4-.5],[(q[0]-X0)/4-.5]],order=1)[0])+floor
                    points.append(ground-elevation)
    (WEB/'county_contours_2ft_grid.json').write_text(json.dumps({'source':'Fairfax County Jade/Contours/MapServer/0, 1-ft NAVD88 2022 source filtered to even 2-ft elevations','lines':lines}))
    stats={'sourceLines':len(lines),'samples':len(points),'medianDifferenceFt':float(np.median(points)) if points else None,'p95AbsoluteDifferenceFt':float(np.percentile(np.abs(points),95)) if points else None,'method':'Excluded building pad + 8 ft collar; compared LiDAR ground with official county even-elevation contours'}
    (OUT/'contour_comparison.json').write_text(json.dumps(stats,indent=2)+'\n');print('Contour cross-check',stats,flush=True)

if __name__=='__main__':prepare()
