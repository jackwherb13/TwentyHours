"""Compile audited room/connection measurements in blueprint/architect_layout.json.

Never seeds geometry: source measurements and qualifications remain in blueprint/.
Output stays in blueprint/ and verification/M1/. No Studio, git, or src writes.
"""
import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / 'blueprint'
sys.path.insert(0, str(ROOT / 'tools'))
from build_blueprint import collect_segments, shared_edge


def write(name, data):
    (BP / name).write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')


def compile_level(source):
    rooms = source['rooms']
    byid = {r['id']: r for r in rooms}
    walls = []
    for a, b, owners in collect_segments(rooms):
        types = {byid[r]['type'] for r in owners}
        # Construction areas are reservations/fences, never opaque finished boxes.
        if types == {'construction'}:
            continue
        ext = len(owners) == 1
        # Partitions extend into the plenum above suspended ceilings.
        height = max(max(byid[r]['ceilingHeight'] for r in owners) + 0.5,
                     19.5 if source['level']==1 else 12.5)
        if types == {'stair'}:
            height = 28 if source['level'] == 1 else 12
        w = dict(id=f"l{source['level']}_w{len(walls)+1:03}", a=list(a), b=list(b),
                 thickness=1.0 if ext else (0.5 if 'office' in types else 0.67),
                 height=max(height, 9), material='brick' if ext else ('gypsum' if 'office' in types else 'painted_cmu'),
                 exterior=ext, openings=[], _owners=sorted(owners))
        walls.append(w)

    def aperture(w, center, width, kind='door', sill=0, head=7, **extra):
        length = math.dist(w['a'], w['b'])
        assert width <= length, (w['id'], width, length)
        start = round((center-width/2)*2)/2
        assert start >= 0 and start+width <= length, (w['id'], start, width, length)
        op = dict(type=kind, offset=start, width=width, sill=sill, head=head)
        if kind == 'door':
            op.update(leaves=2 if width >= 5 else 1, tag='RACDoor')
        if kind == 'curtainwall':
            op['mullionSpacing'] = 5
        op.update(extra)
        assert head <= w['height'], (w['id'],head,w['height'])
        w['openings'].append(op)

    for connection in source['connections']:
        r1,r2 = connection['rooms']
        choices=[w for w in walls if set(w['_owners']) == {r1,r2}]
        assert choices, f'No shared wall {r1}/{r2}'
        w=max(choices, key=lambda w: math.dist(w['a'],w['b']))
        length=math.dist(w['a'],w['b'])
        width=connection.get('width', 3.5)
        kind=connection.get('type','door')
        if width == 'full':
            width=length-2
        aperture(w, connection.get('center',length/2), width, kind,
                 head=connection.get('head',9 if kind=='opening' else 7))
        w['openings'][-1]['connection']=[r1,r2]
        if connection.get('label'):
            w['openings'][-1]['label']=connection['label']
        if connection.get('keypadCode'):
            w['openings'][-1]['keypadCode']=connection['keypadCode']

    for spec in source.get('apertures',[]):
        a,b=spec['a'],spec['b']
        w=next((w for w in walls if w['a']==a and w['b']==b),None)
        assert w is not None, f'Missing aperture wall {a} {b}'
        if 'height' in spec:w['height']=spec['height']
        if 'material' in spec:w['material']=spec['material']
        if spec.get('replace'):w['openings']=[]
        for op in spec['openings']:
            aperture(w,**op)

    for guard in source.get('guards',[]):
        # Split/replace every existing segment along this open balcony boundary.
        axis=0 if guard['a'][1]==guard['b'][1] else 1
        for w in walls:
            if w['a'][1-axis]!=guard['a'][1-axis] or w['b'][1-axis]!=guard['a'][1-axis]:continue
            if min(w['a'][axis],w['b'][axis])<min(guard['a'][axis],guard['b'][axis]):continue
            if max(w['a'][axis],w['b'][axis])>max(guard['a'][axis],guard['b'][axis]):continue
            w.update(height=3.5,thickness=.25,material='glass',exterior=False,openings=[])
    for w in walls:w.pop('_owners')
    # Emit one physical run when adjacent segments have identical construction.
    # Door offsets are rebased; graph identities remain attached to apertures.
    changed=True
    while changed:
        changed=False
        for i,a in enumerate(walls):
            for j in range(i+1,len(walls)):
                b=walls[j]
                if any(a[k]!=b[k] for k in ('height','thickness','material','exterior')):continue
                axis=0 if a['a'][1]==a['b'][1] else 1
                if b['a'][1-axis]!=b['b'][1-axis] or a['a'][1-axis]!=b['a'][1-axis]:continue
                first,last=(a,b) if a['a'][axis]<=b['a'][axis] else (b,a)
                if first['b']!=last['a']:continue
                length=math.dist(first['a'],first['b'])
                merged=dict(first,b=last['b'],openings=first['openings']+[dict(o,offset=o['offset']+length) for o in last['openings']])
                walls[i]=merged;walls.pop(j);changed=True;break
            if changed:break
    return dict(level=source['level'],elevation=source['elevation'],rooms=rooms,walls=walls,
                columns=source.get('columns',[]),stairs=source.get('stairs',[]),
                voids=source.get('voids',[]),props=source.get('props',[]))


def main():
    source=json.loads((BP/'architect_layout.json').read_text(encoding='utf-8'))
    for level in source['levels']:
        out=compile_level(level)
        write(f"level{level['level']}.json",out)
        print(f"Level {level['level']}: {len(out['rooms'])} spaces, {len(out['walls'])} walls, "
              f"{sum(len(w['openings']) for w in out['walls'])} apertures")
    write('site.json',source['site'])


if __name__=='__main__':main()
