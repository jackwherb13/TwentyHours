"""Generate room-by-room detail direction and migrate estimated camera stations."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
BP=ROOT/'blueprint';OUT=ROOT/'verification/M1'


def read(p):return json.loads(p.read_text(encoding='utf-8'))
def inside(poly,p):
    x,z=p;yes=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if (a[1]>z)!=(b[1]>z) and x<(b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0]:yes=not yes
    return yes


def center(r):
    poly=r['polygon'];xs=[p[0] for p in poly];zs=[p[1] for p in poly]
    for f in (.5,.25,.75,.1,.9):
        for g in (.5,.25,.75,.1,.9):
            p=[min(xs)+(max(xs)-min(xs))*f,min(zs)+(max(zs)-min(zs))*g]
            if inside(poly,p):return p
    return poly[0]


def main():
    levels=[read(BP/f'level{i}.json') for i in (1,2)]
    sx,sz=read(BP/'architect_constraints.json')['previousFrameShiftFt']
    briefs={
      'gym':('Maple hardwood, green perimeter and wall pads; white painted CMU and exposed pale steel joists. Use perimeter hoops, retractable green/gold bleachers, scoreboard, blank/generic team banners and US flag. Ceiling high-bays; do not put columns in playing rectangles. Court markings are separate detail geometry.', 'IMG_0332-0336; WEB_vb_gym_interior; WEB_vb_gym_overlook'),
      'corridor':('Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.', 'IMG_0314-0316,0331,0338-0343,0346,0372-0374'),
      'lobby':('Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle.', 'IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2'),
      'fitness':('Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.', 'IMG_0318,0328; WEB_entrance_from_level2'),
      'office':('Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.', 'IMG_0323-0327'),
      'locker':('Pale porcelain/ceramic floor, light walls, acoustic tile, wood lockers in volleyball suite; metal locker banks for public suites only after photo confirmation. Benches, generic volleyball/M branding, laundry bins. No real-player photos, jersey names or dedication text.', 'IMG_0316,0340,0375-0378'),
      'restroom':('Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.', 'IMG_0376,0379-0382'),
      'support':('Use room-specific brief below; pale washable walls, specified tile floor and acoustic ceiling. Keep circulation and service clearances. Fixtures must match the identified use; room names are provisional where noted.', 'IMG_0319,0340,0375-0378; WALKTHROUGH.md'),
      'storage':('Sealed concrete/vinyl, pale CMU, utility linear lights, simple secured shelving after use is confirmed. Do not populate anonymous rooms with arbitrary athletic equipment.', 'G-0201 service cells; no direct interior photo'),
      'mechanical':('Sealed concrete, painted CMU, exposed overhead service space and utility lights. Keep the service door and maintenance aisle clear; do not detail equipment without a source.', 'G-0201 service rooms; unphotographed'),
      'stair':('Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.', 'WALKTHROUGH.md 23:00 correction; IMG_0341,0371'),
      'racquetball':('40x20 ft court footprint, maple floor, smooth pale impact walls, 20ft clear ceiling, flush court markings. Glazed rear access and flush door with safe hardware. Bright diffuse ceiling lighting; no hoops, bleachers or squash markings.', 'WALKTHROUGH.md 23:00 correction; G-0201 small court bays. No direct court photograph'),
      'construction':('Unfinished reservation only: perimeter construction fence, generic work-zone signs and closed access. Do not construct or furnish proposed 2028 office suites as current occupied rooms.', 'G-0201 hatched work zone; site_plan_native.png north/west ADDITION'),
      'void':('No slab or ceiling at Level 2 within this polygon. Continue lower room volume; protect every walking edge with 42in horizontal rails or glazing as appropriate. Do not fill the volume with a generic floor.', 'IMG_0335-0336,0343-0345,0369-0370; WEB_entrance_from_level2')
    }
    special={
      'nutrition_vestibule':'Only the industrial glass-door fridge in this 10x10 vestibule. Sign: MATT CORSON NUTRITION STATION (fictional). Keypad entrance code 15234; entering from the west, turn LEFT/north into the volleyball locker room. No table or loose props here.',
      'training_room':'Green padded treatment/taping tables; ice machine, rehabilitation supplies/equipment, cabinetry and washable worktop. Use the user description; no training-room image was supplied.',
      'corridor_gym_east':'Northbound: volleyball double doors/glazing on LEFT/west; illuminated trophy case and generic unnamed jerseys on RIGHT/east. Preserve 12ft corridor width.',
      'thin_link':'Doorless 8ft passage. Both approach and perpendicular-hall ends must remain open. Public locker side doors do not change those open ends.',
      'basketball_approach':'Prominent BASKETBALL - OFF LIMITS sign at Cage door; separate west exterior exit meets continuous terrain at +20ft. Do not route public circulation through the restricted gym.',
      'cage_gym':'Upper-level restricted practice hall. Its southwest stair placement remains a flagged inference that conflicts with the drawn clear court. Do not finalize court striping until resolved.',
      'lobby':'20x20 entry stays double height. Desk anchor center 10ft from east glass; 16ft long axis east-west, perpendicular to that glass. Entry door aisle passes beside desk.',
      'corridor_wide':'Ping-pong/vending open recreation zone. Main stair opens off the south side. Read final route caution: local turns required by this fit are not all confirmed.',
      'corridor_l2_overlook':'Gym on LEFT for northbound travel. Full-height observation window band with low sill; no access door onto gym void. Return toward the cross-concourse is currently inferred.',
      'cardio_gallery':'Open cardio mezzanine; fitness floor and glass strip visible across the guarded edge. Do not recreate the old closed conference/office boxes.',
      'locker_volleyball':'Generic VOLLEYBALL LOCKER ROOM sign and NCAA ALL-AMERICANS board with fictional or blank names. Recreate graphics cleanly; never crop people or real dedications from photos.'
    }
    doc=ROOT/'docs/ARCHITECT_NOTES.md';s=doc.read_text(encoding='utf-8').split('## Final reconstruction decisions')[0]
    s+='''## Final reconstruction decisions and conflicts

- **Authority:** the 23:00 walkthrough correction supersedes all earlier stair/squash/16ft assumptions. L2 is +20ft, the main stair has two flights and a left quarter-turn, and both 40x20 courts are upstairs. The official RAC webpage still advertises squash; it does not override the user.
- **Origin:** the old frame placed its threshold at the northeast projection. All revised coordinates translate by (-15,-102) ft to the southeast entrance near site pixel (694,480). Source placement is approximate +/-3ft, not a surveyed threshold. Site/props owners must apply this translation before integrating old anchors.
- **Height:** 34 inferred risers at 20/34 ft (7.0588in), 17 per main flight. Tread/landing dimensions are a feasible design inference, not counted photo measurements. The existing validator's hard-coded 16ft assertion is obsolete and was not edited.
- **Exit inference:** choose the west-side Level 2 egress beside the Cage approach. terrain_relationship.json supplies a continuous 0-to-20ft grade relationship. The west exit side is not user-confirmed; terrain implementation belongs to the site agent.
- **Other-area inference:** the door beyond the east gym approach leads into fitness_north, then the northeast office/support suite. This is a drawing-based working assignment, not a known room name.
- **Route conflict remains:** the east-side overlook makes the volleyball gym left when northbound. The drawing-fit route then returns south to the westbound cross-concourse before the courts. That return is physically connected but not explicitly described by the user. The same fit requires returning from the gym-door approach to the thin link on L1. Do not describe these turns as surveyed facts.
- **Second stair conflict remains:** the westbound court -> right stair -> Cage/exit order places the secondary stair in the southwest part of the Cage envelope. This displaces drawn court area and is NOT resolved by the supplied walkthrough. Its exact location remains a structural gap, despite a connected graph.
- **Construction:** the proposed north/west addition is excluded from finished public interiors. Its L-shaped L1 reservation and the lower Cage reservation are disjoint. Proposed final-condition northwest offices are not current accessible rooms. The upper Cage floor is retained because the route reaches its door from L2 and the drawing shows its basketball floor at that level.
- **Precision:** footprint IoU and calibrated regulation courts are good checks of overall scale; they do not prove that each partition is within +/-1ft. NE offices, locker compartments, southwest offices and individual door swings remain approximate. No complete 1:1 fidelity claim is justified yet.
- **Builder contract:** level JSON retains the required schema and aggregate stair envelopes. The actual two-flight main stair is specified in stair_details.json. The current builder ignores that sidecar and still emits one straight run. This is a required implementation handoff, not a passed physical-walk test.
- **Protected voids:** entrance is fully open to above; east and south glass have a 15ft setback, increased locally to 20ft over the entrance. Guard locations are recorded. Horizontal metal rails still need the detail builder; the structural preview uses a 3.5ft glass barrier.
- **Photography:** reference people are evidence only. Never use their faces, names, likenesses, voices or photo textures. All signs in the generated game must use the user-approved fictional/generic wording.

## External research

- [Official RAC facility page](https://recreation.gmu.edu/facilities/rac/) corroborates the three-gym / two-story fitness program, but its public court list conflicts with the user's latest court identification. User wins.
- [GMU interactive RAC tour listing](https://oips.gmu.edu/managing-your-academic-workload/) provides a tour lead; no accessible calibrated floor-plan asset was recovered.
- [GMU BAPC project status](https://construction.gmu.edu/bapc-rac-addition) identifies the new addition at the existing Cage. Public source pages were readable through web search; direct local downloads were blocked (403/certificate errors), recorded in web_sources.json. No private access or bypass was used.
- Existing parallel-agent exterior references are in reference/web/web_sources.json. They were not overwritten. Sources containing people remain reference-only.

## DETAIL BRIEFS for Grok

Read the conflicts above before furnishing uncertain spaces. Dimensions below are footprint bounds; L-shaped rooms are not bounding-box rectangles. Keep all props out of doors, stair approaches and court play areas. Materials must use the established MaterialVariants. Room-specific fixture placements are instructions for later work, not claims of fixtures built in M1.

'''
    for d in levels:
        s+=f"### Level {d['level']} (FFL {d['elevation']:g} ft)\n\n"
        for r in d['rooms']:
            p=r['polygon'];w=max(q[0] for q in p)-min(q[0] for q in p);h=max(q[1] for q in p)-min(q[1] for q in p)
            text,photos=briefs[r['type']]
            s+=f"**{r['id']}** — {w:g} x {h:g} ft bounds; {r['ceilingHeight']:g} ft clear, {r['ceilingType']}. {text} {special.get(r['id'],'')} Reference: {photos}.\n\n"
    s+='''## Acceptance status

See verification/M1/REPORT.md and the saved gate logs for exact final results. Room connectivity and overall scale are verified separately from production-builder physics and visual fidelity. M1 remains unapproved while structural inferences, builder integration and sub-8 judge scores remain.
'''
    doc.write_text(s,encoding='utf-8')
    # Update cameras from immutable baseline, never cumulatively shift repeated runs.
    stations=read(OUT/'baseline/photo_stations.json');maps={'corridor_l2_east':'corridor_l2_return','corridor_l2_gym':'corridor_l2_overlook','corridor_l2_north':'corridor_ne','corridor_l2_ne':'corridor_ne','locker_general':'locker_general_m','stair_ne':'stair_main','corridor_link':'corridor_entry_link','corridor_west':'athletic_corridor','conference':'cardio_gallery','office_l2_east':'cardio_gallery'}
    for st in stations['stations']:
        pos=st['position'];upper=pos[1]>18;d=levels[1 if upper else 0]
        pos[0]-=sx;pos[2]-=sz
        if upper:pos[1]+=4
        room=maps.get(st.get('room'),st.get('room'))
        match=next((r for r in d['rooms'] if r['id']==room),None)
        if match and not inside(match['polygon'],[pos[0],pos[2]]):
            pos[0],pos[2]=center(match);pos[1]=d['elevation']+5.2
        if match:st['room']=room
        st['note']=st.get('note','')+' | Revised-frame estimate; not photographically solved. Recalibrate in Studio before comparison.'
        st['confidence']='estimated'
    # New web references need explicit stations too.
    existing={s['id'] for s in stations['stations']}
    for rid,room,n,look in [('WEB_entrance_1','exterior',1,[-1,0,0]),('WEB_entrance_2','exterior',1,[-1,0,0]),('WEB_entrance_left_pole','exterior',1,[-1,0,0]),('WEB_entrance_from_level2','balcony',2,[1,-.35,0]),('WEB_vb_gym_interior','competition_gym',1,[0,0,-1]),('WEB_vb_gym_overlook','corridor_l2_overlook',2,[-1,-.2,0])]:
        if rid in existing:continue
        r=next((r for r in levels[n-1]['rooms'] if r['id']==room),None);x,z=center(r) if r else (45,0)
        stations['stations'].append(dict(id=rid,file=f'reference/photos/{rid}.jpg',position=[x,levels[n-1]['elevation']+5.2,z],look=look,fovVertical=55,room=room,note='Estimated station; image dimensions/FOV and pose need Studio calibration.',confidence='estimated'))
    (BP/'photo_stations.json').write_text(json.dumps(stations,indent=2)+'\n')
    print('Room briefs written:',sum(len(d['rooms']) for d in levels),'Camera stations:',len(stations['stations']))


if __name__=='__main__':main()
