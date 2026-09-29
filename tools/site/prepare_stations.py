"""Create exterior-only capture manifest; never drives Studio or claims captures."""
import json
from pathlib import Path
from prepare_site import ROOT

grid=json.loads((ROOT/'verification/exterior/terrain_grid.json').read_text())
g=grid['meta']['grid']; heights=grid['heights']
def ground(x,z):
    i=max(0,min(g['nx']-1,int((x-g['x0'])/g['step'])))
    j=max(0,min(g['nz']-1,int((z-g['z0'])/g['step'])))
    return heights[j][i]
# Existing canonical photo stations use a different entrance origin. These local
# exterior stations are estimated anew against the interim visible floor plan.
views=[('IMG_0364',[64,31],[0,12,-10]),('IMG_0365',[40,-16],[2,15,-10]),
       ('IMG_0368',[62,2],[0,14,0]),('IMG_0352',[-301,123],[-229,15,49]),
       ('IMG_0358',[-94,-348],[-106,15,-187]),('WEB_entrance_2',[56,58],[0,13,-10]),
       ('WEB_entrance_left_pole',[60,-148],[0,13,-44])]
stations=[]
for ident,p,target in views:
    stations.append({'id':ident,'camera_position':[p[0],round(ground(*p)+5.2,2),p[1]],
                     'look_at_position':target,'reference':f'reference/photos/{ident}.jpg',
                     'output':f'verification/exterior/{ident}.png','fovVertical':55,
                     'status':'NOT_CAPTURED','notes':'Estimated interim-grid exterior station. MCP screen_capture cannot set FOV; visual calibration required.'})
(ROOT/'verification/exterior/capture_stations.json').write_text(json.dumps({'stations':stations},indent=2)+'\n')
print('Prepared 7 exterior stations; all NOT_CAPTURED')
