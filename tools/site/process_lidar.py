"""Crop USGS LAZ, derive ground/canopy grids and roof observations.

Uses laspy/lazrs and GDAL (rasterio) for CRS conversion; pyproj is optional and
disabled here because the host's application-control policy rejects its DLL.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'.vendor'))
sys.modules['pyproj']=None
import json,math
import numpy as np
import laspy
from rasterio.warp import transform
from scipy.spatial import cKDTree
from scipy.ndimage import maximum_filter, gaussian_filter
from shapely.geometry import Polygon, Point
from shapely import contains_xy
from prepare_site import inverse, C, S, LAT0, LON0, FT, SHIFT, ROOT

WEB=ROOT/'reference/web';OUT=ROOT/'verification/exterior'
X0,Z0,N,STEP=-592,-448,200,4

def grid_coordinates(lat,lon):
    e=(np.asarray(lon)-LON0)*111320*math.cos(math.radians(LAT0))*FT
    n=(np.asarray(lat)-LAT0)*111320*FT
    return e*C-n*S+SHIFT[0], -e*S-n*C+SHIFT[1]

def crop_laz():
    path=WEB/'rac_lidar_2022.laz'
    selected=json.loads((WEB/'lidar_catalog.json').read_text())
    item=next(i for i in selected['items'] if 'NorthernVA_B22' in i['title'])
    assert path.stat().st_size==item['sizeInBytes'], 'LAZ download incomplete; wait for fetch_county.py'
    cache=WEB/'rac_lidar_crop.npz'
    if cache.exists():return dict(np.load(cache))
    arrays={k:[] for k in ('x','z','elevation','classification','returns')}
    with laspy.open(path) as reader:
        wkt=next(v.string for v in reader.header.vlrs if hasattr(v,'string'))
        corners=[inverse(x,z) for x in (X0-20,X0+820) for z in (Z0-20,Z0+820)]
        nx,ny=transform('EPSG:4326','EPSG:6593',[p[1] for p in corners],[p[0] for p in corners])
        bounds=[min(nx),min(ny),max(nx),max(ny)]
        provenance={'source':item,'pointCount':reader.header.point_count,'wkt':wkt,'nativeUnits':'US survey feet horizontal + vertical NAVD88 Geoid18','usedHorizontalCRS':'EPSG:6593','nativeBounds':bounds}
        for points in reader.chunk_iterator(1000000):
            x,y=np.asarray(points.x),np.asarray(points.y)
            keep=(x>bounds[0])&(x<bounds[2])&(y>bounds[1])&(y<bounds[3])
            if not keep.any():continue
            lon,lat=transform('EPSG:6593','EPSG:4326',x[keep].tolist(),y[keep].tolist())
            bx,bz=grid_coordinates(lat,lon)
            for key,value in [('x',bx),('z',bz),('elevation',np.asarray(points.z)[keep]*1.000002000004),('classification',np.asarray(points.classification)[keep]),('returns',np.asarray(points.number_of_returns)[keep])]:
                arrays[key].append(value)
    data={k:np.concatenate(v) for k,v in arrays.items()}
    np.savez_compressed(cache,**data)
    provenance['croppedPoints']=len(data['x']);provenance['classCounts']={str(k):int(v) for k,v in zip(*np.unique(data['classification'],return_counts=True))}
    (OUT/'lidar_provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    print('Cropped',len(data['x']),'points',provenance['classCounts'],flush=True)
    return data

def derive(data):
    x,z,elev,cls=(data[k] for k in ('x','z','elevation','classification'))
    ground=cls==2
    assert ground.sum()>10000,'Insufficient classified ground returns'
    tree=cKDTree(np.column_stack((x[ground],z[ground])))
    ge=elev[ground]
    def sample(q):
        d,i=tree.query(q,k=8,workers=2);w=1/np.maximum(d,.1)**2
        return (ge[i]*w).sum(axis=1)/w.sum(axis=1)
    xx,zz=np.meshgrid(X0+2+np.arange(N)*STEP,Z0+2+np.arange(N)*STEP)
    absolute=sample(np.column_stack((xx.ravel(),zz.ravel()))).reshape(N,N)
    floor=float(sample([[-21.5,88.5]])[0])+10*7/12
    heights=absolute-floor
    np.savez_compressed(WEB/'lidar_grids.npz',absolute=absolute,heights=heights,floorDatumFt=floor)
    site=json.loads((ROOT/'blueprint_interim/site.json').read_text())
    level=json.loads((ROOT/'blueprint_interim/level1.json').read_text())
    roofs=[]
    for room in level['rooms']:
        polygon=Polygon(room['polygon'])
        within=contains_xy(polygon,x,z)
        roof=within & ((cls==6) if np.count_nonzero(within&(cls==6))>50 else (cls==1)) & (elev-floor>8)
        values=elev[roof]-floor
        if len(values)<50:
            roofs.append({'id':room['id'],'count':int(len(values)),'status':'unresolved'});continue
        bins=np.round(values*2)/2;levels,counts=np.unique(bins,return_counts=True)
        mode=float(levels[np.argmax(counts)])
        main=values[abs(values-mode)<1.25]
        rooflevel=float(np.median(main))
        # Boundary returns must clear the roof but remain below plausible rooftop equipment.
        border=polygon.buffer(.5).difference(polygon.buffer(-2.5))
        edge=contains_xy(border,x,z)&roof
        high=elev[edge]-floor
        high=high[(high>rooflevel+.4)&(high<rooflevel+5)]
        parapet=float(np.percentile(high,75)) if len(high)>=30 else None
        roofs.append({'id':room['id'],'count':int(len(values)),'roofMedianFt':round(rooflevel,2),'roofP10Ft':round(float(np.percentile(main,10)),2),'roofP90Ft':round(float(np.percentile(main,90)),2),
                      'edgeReturnCandidateFt':round(parapet,2) if parapet is not None else None,'edgeCount':len(high),'status':'measured roof; parapet candidate only' if parapet is not None else 'measured roof; parapet unresolved'})
    (OUT/'roof_heights.json').write_text(json.dumps({'floorDatumFtNAVD88':floor,'source':'2022 USGS LAZ, classified roof returns / unclassified fallback, mapped to interim room polygons','roofs':roofs},indent=2)+'\n')
    lines=['# RAC roof observations from 2022 USGS LiDAR','',f'L1 reference = {floor:.3f} ft NAVD88 (inferred from ground 30 ft south of corrected south entrance + ten 7-inch risers). Relative heights inherit that datum uncertainty.','',
           'These are point-cloud observations, not verified construction dimensions. Interim room polygons include a future addition and differ from the actual roof footprint. Do not interpret an edge-return candidate as a confirmed parapet: roof equipment or registration error can contaminate it.','',
           '| Interim area | Roof ft above L1 | P10–P90 ft | Edge candidate ft | Roof returns | Status |','|---|---:|---:|---:|---:|---|']
    for r in roofs:
        lines.append(f"| {r['id']} | {r.get('roofMedianFt','—')} | {r.get('roofP10Ft','—')}–{r.get('roofP90Ft','—')} | {r.get('edgeReturnCandidateFt') or 'unresolved'} | {r['count']} | {r['status']} |")
    lines+=['','Source: '+json.loads((WEB/'lidar_catalog.json').read_text())['items'][-1]['downloadURL'],
            '','Architect handoff: confirm L1 surveyed elevation and high-side exit coordinates before changing floor-to-floor heights. WALKTHROUGH.md fixes the approximate L2 difference at 20 ft. No Level 1/2 interior source was edited.']
    (OUT/'ROOF_HEIGHTS.md').write_text('\n'.join(lines)+'\n')
    # Surface height and local maxima, excluding all county building polygons.
    building=np.zeros(len(x),dtype=bool)
    county=json.loads((WEB/'Buildings_0_features.json').read_text())
    for feature in county['features']:
        for ring in feature['geometry'].get('rings',[]):
            bx,bz=grid_coordinates([q[1] for q in ring],[q[0] for q in ring])
            building|=contains_xy(Polygon(np.column_stack((bx,bz))).buffer(3),x,z)
    point_ground=sample(np.column_stack((x,z)))
    above=elev-point_ground
    vegetation=np.isin(cls,[3,4,5])|((cls==1)&(data['returns']>1))
    vegetation &= ~building & (above>10)&(above<100)&(x>=X0)&(x<X0+800)&(z>=Z0)&(z<Z0+800)
    chm=np.zeros((N,N));ix=((x[vegetation]-X0)/STEP).astype(int);iz=((z[vegetation]-Z0)/STEP).astype(int)
    np.maximum.at(chm,(iz,ix),above[vegetation])
    smoothed=gaussian_filter(chm,.6)
    peaks=np.argwhere((smoothed==maximum_filter(smoothed,size=7))&(smoothed>12))
    peaks=sorted(peaks,key=lambda q:chm[tuple(q)],reverse=True)[:150]
    trees=[]
    if peaks:
        centres=np.array([[X0+(i+.5)*STEP,Z0+(j+.5)*STEP] for j,i in peaks]);near=cKDTree(centres)
        py,px=np.where(chm>8);_,labels=near.query(np.column_stack((X0+(px+.5)*STEP,Z0+(py+.5)*STEP)))
        for k,(j,i) in enumerate(peaks):
            cells=(labels==k);radius=max(5,min(22,math.sqrt(cells.sum()*STEP*STEP/math.pi)))
            height=float(chm[j,i]);trees.append({'at':[round(float(centres[k,0]),1),round(float(centres[k,1]),1)],'height':round(height,1),'radius':round(radius,1),
                'species':'pine' if height/radius>3.6 else 'deciduous','source':'USGS 2022 LiDAR canopy local maximum; crown radius Voronoi estimate; species template inferred, not surveyed'})
    (OUT/'lidar_trees.json').write_text(json.dumps({'treeCount':len(trees),'trees':trees},indent=2)+'\n')
    print('Ground',ground.sum(),'returns; floor',round(floor,3),'ft NAVD88; trees',len(trees),'; roof areas',len(roofs),flush=True)

if __name__=='__main__':derive(crop_laz())
