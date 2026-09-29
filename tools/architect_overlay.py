"""Registered source/model overlays for the corrected RAC blueprint. No source image writes."""
import json
import math
import sys
from pathlib import Path
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parent.parent
BP=ROOT/'blueprint';OUT=ROOT/'verification/M1'
sys.path.insert(0,str(ROOT/'tools'))
import build_blueprint as baseline


def read(p):return json.loads(p.read_text(encoding='utf-8'))
def font(n,b=False):return ImageFont.truetype('arialbd.ttf' if b else 'arial.ttf',n)
COL={'gym':'#dbb470','corridor':'#d1d7df','lobby':'#badcec','office':'#c3dcbb','fitness':'#f2cead','locker':'#d9c1e4','restroom':'#bde4df','stair':'#b9b5de','racquetball':'#e4ca94','construction':'#f4d5d5','void':'#ededee'}


def draw(g,d,t,source=False):
    for r in d['rooms']:
        if source:
            color=COL.get(r['type'],'#e1ddca');rgb=tuple(int(color[i:i+2],16) for i in (1,3,5))
            g.polygon([t(p) for p in r['polygon']],fill=rgb+(32,),outline=rgb+(150,))
        else:g.polygon([t(p) for p in r['polygon']],fill=COL.get(r['type'],'#e1ddca'),outline='#888888')
    for w in d['walls']:
        g.line([t(w['a']),t(w['b'])],fill=(0,105,145,200) if source else '#2b343b',width=2)
        length=math.dist(w['a'],w['b']);u=[(b-a)/length for a,b in zip(w['a'],w['b'])]
        for o in w['openings']:
            a=[w['a'][j]+u[j]*o['offset'] for j in (0,1)];b=[a[j]+u[j]*o['width'] for j in (0,1)]
            g.line([t(a),t(b)],fill='#277bcc' if o['type'] in ('window','curtainwall') else '#c14037',width=3)
    for c in d['columns']:
        x,z=c['at'];g.rectangle([t([x-.75,z-.75]),t([x+.75,z+.75])],fill='#303948')
    if not source:
        for i,r in enumerate(d['rooms'],1):
            p=r['polygon'];x=sum(q[0] for q in p)/len(p);z=sum(q[1] for q in p)/len(p)
            g.text(t([x,z]),str(i),font=font(13,True),fill='#202020',anchor='mm')
        for s in d['stairs']:
            p=s['polygon'];x=sum(q[0] for q in p)/len(p);z=sum(q[1] for q in p)/len(p)
            a=t([x,z]);b=t([x+s['direction'][0]*10,z+s['direction'][1]*10]);g.line([a,b],fill='#613998',width=4)


def overlay(n):
    d=read(BP/f'level{n}.json');src=Image.open(ROOT/'reference/photos/Screenshot_2026-09-28_174529.jpg').convert('RGB')
    crop=(650,605,1330,1120) if n==1 else (20,55,615,520)
    # Registered by the four competition-gym corners on each separately scaled diagram.
    origin=(959,655) if n==1 else (328,74)
    scale=(151/115,189/147)
    sx=1150/(crop[2]-crop[0]);sy=880/(crop[3]-crop[1])
    panel=src.crop(crop).resize((1150,880)).convert('RGBA')
    layer=Image.new('RGBA',panel.size,(0,0,0,0));g=ImageDraw.Draw(layer)
    shift=read(BP/'architect_constraints.json')['previousFrameShiftFt']
    def t(p):return ((origin[0]+(p[0]+shift[0]+188.5)*scale[0]-crop[0])*sx,(origin[1]+(p[1]+shift[1]+107.5)*scale[1]-crop[1])*sy)
    draw(g,d,t,True);panel=Image.alpha_composite(panel,layer)
    sheet=Image.new('RGB',(2400,1510),'white');sheet.paste(panel,(20,100));g=ImageDraw.Draw(sheet)
    g.text((24,18),f'RAC M1 / LEVEL {n} / '+('FFL 0 ft' if n==1 else 'FFL +20 ft'),font=font(28,True),fill='#163b46')
    g.text((24,57),'LEFT: registered Perkins&Will G-0201 + blue model walls. RIGHT: numbered blueprint. Red = door/open opening.',font=font(19),fill='#39494f')
    def clean(p):return (1210+(p[0]+shift[0]+380)*2.8,120+(p[1]+shift[1]+140)*2.4)
    draw(g,d,clean)
    g.text((1220,965),'Main entrance = (0,0). Building north up. 1 stud = 1 ft.',font=font(17),fill='black')
    for i,r in enumerate(d['rooms'],1):
        col=(i-1)//17;row=(i-1)%17
        p=r['polygon'];w=max(q[0] for q in p)-min(q[0] for q in p);h=max(q[1] for q in p)-min(q[1] for q in p)
        g.text((25+col*580,1010+row*26),f'{i:02} {r["id"]} ({w:g} x {h:g})',font=font(16),fill='#252f37')
    g.text((25,1470),'Walkthrough overrides: +20 ft L2; two upper 40x20 racquetball courts; main stair turns LEFT. Inferred partitions remain provisional.',font=font(19,True),fill='#8d3823')
    sheet.save(OUT/f'overlay_level{n}.png')


def metrics():
    site=read(BP/'site.json');cal=read(BP/'calibration.json');l1=read(BP/'level1.json')
    raw,*_=baseline.footprint_from_osm();raw=raw-np.array(read(BP/'architect_constraints.json')['previousFrameShiftFt'])
    iou=baseline.raster_iou(raw,np.array(site['footprint']))
    bounds=np.vstack([raw,np.array(site['footprint'])]);origin=bounds.min(axis=0)-2;extent=bounds.max(axis=0)+2
    shape=tuple(np.ceil((extent-origin)[::-1]*2).astype(int)+1)
    def mask(polys):
        m=np.zeros(shape,np.uint8)
        for p in polys:cv2.fillPoly(m,[np.round((np.array(p)-origin)*2).astype(np.int32)],1)
        return m
    occupied=mask([r['polygon'] for r in l1['rooms'] if r['id']!='addition']);foot=mask([site['footprint']])
    rooms_iou=float(np.logical_and(occupied,foot).sum()/np.logical_or(occupied,foot).sum())
    d=dict(footprint_iou_vs_osm=iou,l1_room_union_iou_vs_footprint=rooms_iou,court_scale_checks=cal['courts'],registration='Corner fit on compressed screenshots; NOT a +/-1 ft survey certification.')
    (OUT/'metrics.json').write_text(json.dumps(d,indent=2)+'\n')
    im=Image.open(ROOT/'reference/site_plan_native.png').convert('RGBA');layer=Image.new('RGBA',im.size,(0,0,0,0));g=ImageDraw.Draw(layer)
    a=cal['pixelAnchor'];s=cal['scaleFtPerPx'];shift=cal['shift']
    def t(p):return (a['px']+(p[0]-a['rawX']+shift['x'])/s,a['py']+(p[1]-a['rawZ']+shift['z'])/s)
    draw(g,l1,t,True);Image.alpha_composite(im,layer).convert('RGB').save(OUT/'overlay_site.png')
    print(json.dumps(d,indent=2))


if __name__=='__main__':
    overlay(1);overlay(2);metrics()
