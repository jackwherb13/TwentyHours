"""Apply the south-entrance walkthrough correction and bounded detail policy."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
MODULE=ROOT/'src/ReplicatedStorage/RAC/Site'

def main():
    path=ROOT/'blueprint_interim/site.json';data=json.loads(path.read_text());s=data['site']
    s['entrance'].update(x=-21.5,z=58.5,width=36,rotationDeg=-90,canopyWidth=51,canopyDepth=28,
        source='WALKTHROUGH 23:20: entrance on smaller south glass. Current 43-ft interim south facade retained; enlargement needs architect coordinates. Ten 7-inch risers photo estimate.',
        returnCanopyDepth=20)
    s['walkthrough']['source']='docs/WALKTHROUGH.md including 23:20 south entrance correction'
    # Only owned override data changes. Preserve existing exterior endpoints.
    for w in s['exteriorWallOverrides']:
        if w['id'] not in ('w063','w034'):continue
        length=((w['b'][0]-w['a'][0])**2+(w['b'][1]-w['a'][1])**2)**.5
        if w['id']=='w063':
            w['openings']=[dict(type='curtainwall',offset=0,width=length,sill=0,head=24,mullionSpacing=5)]
        else:
            start=length/2-3
            w['openings']=[dict(type='curtainwall',offset=0,width=start,sill=0,head=24,mullionSpacing=5),
                dict(type='door',offset=start,width=6,sill=0,head=8,leaves=2,tag='RACDoor'),
                dict(type='curtainwall',offset=start,width=6,sill=8,head=24,mullionSpacing=5),
                dict(type='curtainwall',offset=start+6,width=length-start-6,sill=0,head=24,mullionSpacing=5)]
    path.write_text(json.dumps(data,indent=1)+'\n')

if __name__=='__main__':main()
