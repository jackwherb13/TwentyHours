"""Check ordered walkthrough room routes using actual door apertures and stair pairs.
Does not count OUTSIDE as a shortcut and does not invent edges for touching rooms.
Writes concrete routes, inferred turns, and independent schema/height checks to M1.
"""
import collections
import json
import math
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
BP=ROOT/'blueprint';OUT=ROOT/'verification/M1'


def read(name):return json.loads((BP/name).read_text(encoding='utf-8'))
def inside(poly,p):
    x,z=p;yes=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if (a[1]>z)!=(b[1]>z) and x<(b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0]:yes=not yes
    return yes


def main():
    levels=[read('level1.json'),read('level2.json')];site=read('site.json');graph=collections.defaultdict(set);portals=[];fails=[]
    def add(a,b):graph[a].add(b);graph[b].add(a)
    for d in levels:
        n=d['level'];rooms=[r for r in d['rooms'] if r['type'] not in ('void','construction')]
        def at(p):return next((f"{n}:{r['id']}" for r in rooms if inside(r['polygon'],p)),None)
        for w in d['walls']:
            length=math.dist(w['a'],w['b']);ux=(w['b'][0]-w['a'][0])/length;uz=(w['b'][1]-w['a'][1])/length
            for o in w['openings']:
                if o['type'] not in ('door','opening'):continue
                if o['width']<3:fails.append(f"Narrow opening {w['id']} {o['width']}")
                t=o['offset']+o['width']/2;x=w['a'][0]+ux*t;z=w['a'][1]+uz*t;eps=w['thickness']/2+1
                a=at((x-uz*eps,z+ux*eps));b=at((x+uz*eps,z-ux*eps))
                if a and b:
                    if a==b:fails.append(f'Dead door {w["id"]}')
                    else:add(a,b)
                elif n==1 and (a=='1:lobby' or b=='1:lobby'):add('LOW_ENTRANCE',a or b)
                elif n==2 and (a=='2:basketball_approach' or b=='2:basketball_approach'):add('HIGH_EXIT',a or b)
                portals.append(dict(level=n,wall=w['id'],point=[x,z],rooms=[a,b],kind=o['type'],width=o['width']))
    for s in levels[0]['stairs']:
        a=f"1:{s['id']}";b=f"2:{s['id']}"
        if b not in graph:fails.append('Missing upper stair access '+b)
        add(a,b)
        if abs(s['rise']*s['risers']-20)>.001:fails.append('Incorrect stair rise '+s['id'])
    def path(a,b):
        q=collections.deque([[a]]);seen={a}
        while q:
            p=q.popleft()
            if p[-1]==b:return p
            for nxt in sorted(graph[p[-1]]):
                if nxt in ('LOW_ENTRANCE','HIGH_EXIT') and nxt!=b:continue
                if nxt not in seen:seen.add(nxt);q.append(p+[nxt])
        return None
    routes=read('walkthrough_routes.json')['routes'];results=[]
    for route in routes:
        stitched=[]
        for a,b in zip(route['rooms'],route['rooms'][1:]):
            p=path(a,b)
            if not p:fails.append(f"{route['id']}: no route {a} -> {b}")
            else:stitched.extend(p if not stitched else p[1:])
        results.append(dict(id=route['id'],orderedWaypoints=route['rooms'],resolvedRoute=stitched))
    for d in levels:
        for r in d['rooms']:
            if r['type'] in ('void','construction'):continue
            if path('LOW_ENTRANCE',f"{d['level']}:{r['id']}") is None:fails.append('Unreachable '+r['id'])
    if levels[1]['elevation']!=20 or site['levels'][1]['elevation']!=20:fails.append('User-confirmed L2 elevation is not 20')
    if any(r['type']=='racquetball' for r in levels[0]['rooms']):fails.append('Racquetball on L1')
    courts=[r for r in levels[1]['rooms'] if r['type']=='racquetball']
    if len(courts)!=2:fails.append('Expected exactly two upper courts')
    for r in courts:
        p=r['polygon'];dims=sorted([max(x[0] for x in p)-min(x[0] for x in p),max(x[1] for x in p)-min(x[1] for x in p)])
        if dims!=[20,40]:fails.append('Incorrect court dimensions '+r['id'])
    detail=read('stair_details.json')['stairs'][0];f1,f2=detail['flights'];u,v=f1['direction'],f2['direction']
    if len(detail['flights'])!=2 or u[0]*v[1]-u[1]*v[0]!=-1:fails.append('Main stair does not turn left')
    if [f['risers'] for f in detail['flights']]!=[17,17]:fails.append('Main riser split mismatch')
    # Every portal at the actual thin corridor boundaries must be doorless.
    for p in portals:
        if '1:thin_link' in p['rooms'] and any(r in p['rooms'] for r in ('1:athletic_corridor','1:corridor_entry_link')) and p['kind']!='opening':fails.append('Thin link has a door')
    warnings=[
        'Room graph is not a Roblox physics walk. Current production builder emits straight stair envelopes; see stair_details.json.',
        'Overlook-to-cross-concourse requires a return along the east gallery in this drawing fit; exact turn unresolved.',
        'West at-grade exit and southwest secondary stair are inferred to satisfy the upper court/exit order; diagram does not verify exact shaft location.',
        'Existing validator hard-codes 16 ft and must be updated by its owner. This check uses the user-confirmed 20 ft.'
    ]
    out=dict(status='PASS' if not fails else 'FAIL',fails=fails,warnings=warnings,routes=results,portals=portals)
    (OUT/'route_check.json').write_text(json.dumps(out,indent=2)+'\n')
    print(f"Ordered route check: {out['status']}; {len(results)} routes; {len(portals)} real apertures; {len(fails)} failures")
    for f in fails:print('FAIL',f)
    return 1 if fails else 0


if __name__=='__main__':raise SystemExit(main())
