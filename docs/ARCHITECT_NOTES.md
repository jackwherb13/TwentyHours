# RAC structural audit — M1

Status: evidence and route reconstruction in progress. The previous JSON is a draft, not a measured survey. Walkthrough statements take precedence over the proposed addition drawings. No real people or photographed faces may be used as game assets.

## Walkthrough graph, established before geometry

1. Exterior low-side threshold → wrap-around glazed corner → approximately 20 × 20 ft double-height entry.
2. Front desk approximately 10 ft inside, long axis perpendicular to entrance glass. Behind desk → open selectorized fitness → partition → power-rack area.
3. Entry left branch → wide glazed recreation hall with ping-pong and vending → main stair on the left. Main stair has two flights, one square landing, then a LEFT 90-degree turn (latest correction).
4. Continue along narrowing hall → trophy/jersey display on right → competition-gym double doors on left.
5. Continue → doors to another area; immediately left of these, an un-doored narrow link → perpendicular athletic corridor.
6. Turn left → athletic training with green treatment tables. Nearby keypad door → square nutrition vestibule (fridge only) → left-hand door into volleyball locker room → washrooms/showers.
7. Continue along athletic corridor past locker approach → second stair up → basketball OFF LIMITS doorway on left → exterior Level 2 exit at grade.
8. Main stair upper landing → gym overlook corridor; volleyball gym on LEFT walking away from entrance → two 40 x 20 ft racquetball courts on LEFT → second stair descending backward on RIGHT → basketball OFF LIMITS doorway → same high-side exterior exit.
9. The entire wrap-around glass front has an approximately 15 ft double-height strip; no upper slab above entry. Grade rises continuously from entrance side to upper exit.

Adjacency list (undirected unless noted):
- low exterior: entry
- entry: glazed recreation hall, desk/selectorized floor
- selectorized floor: rack floor through partition opening
- glazed recreation hall: main stair lower, narrowed trophy hall
- trophy hall: competition gym, other-area doors, thin link
- thin link: athletic perpendicular corridor (no doors at either end)
- athletic corridor: training, nutrition vestibule (keypad 15234), second stair lower
- nutrition vestibule: volleyball locker (left turn)
- volleyball locker: washrooms, showers
- main stair upper: overlook corridor, cardio gallery
- overlook corridor: racquetball approach
- racquetball approach: racquetball 1, racquetball 2, second stair upper, basketball approach
- basketball approach: restricted Cage door, high-side exit
- main stair lower ↔ main stair upper; second stair lower ↔ second stair upper.

## Initial evidence audit

- The existing origin was assigned to site-plan pixel (672,336), a northeast projecting room, whereas the plan labels the main entrance near its southeast corner. Origin registration must be corrected together with all blueprint coordinates and camera stations.
- The previous generator labels four identical central rooms as racquetball; the supplied Level 2 drawing depicts locker/service partitions there. Do not preserve these invented court assignments.
- Current builder `Build/Stairs.luau` only emits a single straight flight per stair and assumes each flight spans the full floor-to-floor rise. The required two-flight quarter-turn main stair needs an explicit integration contract; a successful JSON graph alone cannot prove the generated stairs walkable.
- Photographic facts recorded once: IMG_0331 wide tile hall/trophy glazing; IMG_0335–0336 elevated gym viewing glass above court doors; IMG_0343 horizontal rails at upper balcony; IMG_0341 and IMG_0371 concrete stair/painted CMU with wall rails; IMG_0364–0370 dark canopy, wrapped glazing, pale tile and frosted desk; WEB_entrance_from_level2 shows cardio machines in a double-height glazed strip. IMG_0375–0382 shows a small fridge vestibule, wood lockers, pale ceramic washrooms and showers.

## Confirmed corrections, 23:00

- Two main flights, one square landing, LEFT quarter-turn. Earlier three-switchback interpretation is retired.
- L2 elevation = +20 ft, approximately; 34 risers give 7.0588 inches each, 17 per flight.
- Exactly two racquetball courts on Level 2, 40 x 20 ft; no Level 1 racquetball and no squash assignments.
- At-grade exit side and the other-area doorway will be assigned from the plans and identified as inferences.

## Questions for manager/user

No further answer is required to proceed. For later survey validation: confirm the marked exit position and room identity behind the other-area doorway, and measure an exact stair riser/tread.

## Final reconstruction decisions and conflicts

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

### Level 1 (FFL 0 ft)

**competition_gym** — 115 x 147 ft bounds; 32 ft clear, open_joist. Maple hardwood, green perimeter and wall pads; white painted CMU and exposed pale steel joists. Use perimeter hoops, retractable green/gold bleachers, scoreboard, blank/generic team banners and US flag. Ceiling high-bays; do not put columns in playing rectangles. Court markings are separate detail geometry.  Reference: IMG_0332-0336; WEB_vb_gym_interior; WEB_vb_gym_overlook.

**south_gym** — 139.5 x 109 ft bounds; 28 ft clear, open_joist. Maple hardwood, green perimeter and wall pads; white painted CMU and exposed pale steel joists. Use perimeter hoops, retractable green/gold bleachers, scoreboard, blank/generic team banners and US flag. Ceiling high-bays; do not put columns in playing rectangles. Court markings are separate detail geometry.  Reference: IMG_0332-0336; WEB_vb_gym_interior; WEB_vb_gym_overlook.

**office_ne_1** — 25.5 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_2** — 25 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_3** — 23.5 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_4** — 23.5 x 25 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_5** — 23.5 x 25 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_reception** — 38.5 x 38 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**restroom_ne_w** — 23.5 x 16.5 ft bounds; 9 ft clear, gypsum. Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.  Reference: IMG_0376,0379-0382.

**restroom_ne_m** — 42.5 x 16.5 ft bounds; 9 ft clear, gypsum. Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.  Reference: IMG_0376,0379-0382.

**fitness_north** — 88.5 x 41 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**lobby** — 20 x 20 ft bounds; 32 ft clear, gypsum. Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle. 20x20 entry stays double height. Desk anchor center 10ft from east glass; 16ft long axis east-west, perpendicular to that glass. Entry door aisle passes beside desk. Reference: IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2.

**lobby_north** — 15 x 74.5 ft bounds; 32 ft clear, gypsum. Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle.  Reference: IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2.

**fitness_center** — 61.5 x 34.5 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**weight_room** — 61.5 x 40 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**corridor_gym_east** — 12 x 22 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free. Northbound: volleyball double doors/glazing on LEFT/west; illuminated trophy case and generic unnamed jerseys on RIGHT/east. Preserve 12ft corridor width. Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**corridor_entry_link** — 12 x 52.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**glazed_recreation** — 15 x 60 ft bounds; 32 ft clear, gypsum. Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle.  Reference: IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2.

**stair_main** — 36 x 33 ft bounds; 32 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**fitness_annex** — 37.5 x 33 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**south_vestibule** — 92 x 15 ft bounds; 32 ft clear, gypsum. Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle.  Reference: IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2.

**corridor_south_link** — 18.5 x 47 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**thin_link** — 115 x 8 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free. Doorless 8ft passage. Both approach and perpendicular-hall ends must remain open. Public locker side doors do not change those open ends. Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**athletic_corridor** — 12 x 100 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**training_room** — 31 x 30.5 ft bounds; 10 ft clear, act_2x4. Use room-specific brief below; pale washable walls, specified tile floor and acoustic ceiling. Keep circulation and service clearances. Fixtures must match the identified use; room names are provisional where noted. Green padded treatment/taping tables; ice machine, rehabilitation supplies/equipment, cabinetry and washable worktop. Use the user description; no training-room image was supplied. Reference: IMG_0319,0340,0375-0378; WALKTHROUGH.md.

**nutrition_vestibule** — 10 x 10 ft bounds; 9 ft clear, act_2x4. Use room-specific brief below; pale washable walls, specified tile floor and acoustic ceiling. Keep circulation and service clearances. Fixtures must match the identified use; room names are provisional where noted. Only the industrial glass-door fridge in this 10x10 vestibule. Sign: MATT CORSON NUTRITION STATION (fictional). Keypad entrance code 15234; entering from the west, turn LEFT/north into the volleyball locker room. No table or loose props here. Reference: IMG_0319,0340,0375-0378; WALKTHROUGH.md.

**locker_volleyball** — 34 x 22 ft bounds; 9 ft clear, act_2x2. Pale porcelain/ceramic floor, light walls, acoustic tile, wood lockers in volleyball suite; metal locker banks for public suites only after photo confirmation. Benches, generic volleyball/M branding, laundry bins. No real-player photos, jersey names or dedication text. Generic VOLLEYBALL LOCKER ROOM sign and NCAA ALL-AMERICANS board with fictional or blank names. Recreate graphics cleanly; never crop people or real dedications from photos. Reference: IMG_0316,0340,0375-0378.

**volleyball_washroom** — 24 x 10 ft bounds; 9 ft clear, gypsum. Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.  Reference: IMG_0376,0379-0382.

**locker_general_w** — 28 x 32 ft bounds; 9 ft clear, act_2x2. Pale porcelain/ceramic floor, light walls, acoustic tile, wood lockers in volleyball suite; metal locker banks for public suites only after photo confirmation. Benches, generic volleyball/M branding, laundry bins. No real-player photos, jersey names or dedication text.  Reference: IMG_0316,0340,0375-0378.

**locker_general_m** — 28 x 32 ft bounds; 9 ft clear, act_2x2. Pale porcelain/ceramic floor, light walls, acoustic tile, wood lockers in volleyball suite; metal locker banks for public suites only after photo confirmation. Benches, generic volleyball/M branding, laundry bins. No real-player photos, jersey names or dedication text.  Reference: IMG_0316,0340,0375-0378.

**storage_athletic** — 25 x 32 ft bounds; 10 ft clear, none. Sealed concrete/vinyl, pale CMU, utility linear lights, simple secured shelving after use is confirmed. Do not populate anonymous rooms with arbitrary athletic equipment.  Reference: G-0201 service cells; no direct interior photo.

**corridor_main** — 115 x 12.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**team_support** — 96.5 x 18 ft bounds; 10 ft clear, act_2x4. Use room-specific brief below; pale washable walls, specified tile floor and acoustic ceiling. Keep circulation and service clearances. Fixtures must match the identified use; room names are provisional where noted.  Reference: IMG_0319,0340,0375-0378; WALKTHROUGH.md.

**stair_second** — 34.5 x 40 ft bounds; 32 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**training_store** — 19.5 x 87.5 ft bounds; 10 ft clear, none. Sealed concrete/vinyl, pale CMU, utility linear lights, simple secured shelving after use is confirmed. Do not populate anonymous rooms with arbitrary athletic equipment.  Reference: G-0201 service cells; no direct interior photo.

**west_link** — 110 x 12.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**corridor_office** — 75.5 x 10 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**stair_west** — 12.5 x 46 ft bounds; 32 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**office_w1** — 28 x 36 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_w2** — 24 x 36 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_w3** — 23.5 x 36 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**mechanical_sw** — 33 x 28 ft bounds; 12 ft clear, none. Sealed concrete, painted CMU, exposed overhead service space and utility lights. Keep the service door and maintenance aisle clear; do not detail equipment without a source.  Reference: G-0201 service rooms; unphotographed.

**corridor_service** — 33 x 18 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**corridor_ne** — 50.5 x 66.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**addition** — 154 x 208.5 ft bounds; 24 ft clear, none. Unfinished reservation only: perimeter construction fence, generic work-zone signs and closed access. Do not construct or furnish proposed 2028 office suites as current occupied rooms.  Reference: G-0201 hatched work zone; site_plan_native.png north/west ADDITION.

**cage_lower_reserved** — 126.5 x 127.5 ft bounds; 24 ft clear, none. Unfinished reservation only: perimeter construction fence, generic work-zone signs and closed access. Do not construct or furnish proposed 2028 office suites as current occupied rooms.  Reference: G-0201 hatched work zone; site_plan_native.png north/west ADDITION.

**corridor_wide** — 73.5 x 32 ft bounds; 32 ft clear, gypsum. Pale rectangular porcelain tile, wrapped dark-framed glazing, bronze/white frosted-panel reception counter, horizontal metal balcony rails. Use integrated linear ceiling lights and recessed downlights. Ping-pong and vending belong along the glazed recreation route, outside the entrance/desk aisle. Ping-pong/vending open recreation zone. Main stair opens off the south side. Read final route caution: local turns required by this fit are not all confirmed. Reference: IMG_0329-0330,0364-0370; WEB_entrance_1,WEB_entrance_2,WEB_entrance_from_level2.

### Level 2 (FFL 20 ft)

**office_ne_1** — 25.5 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_2** — 25 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_3** — 23.5 x 17.5 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_4** — 23.5 x 25 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_5** — 23.5 x 25 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_ne_reception** — 38.5 x 38 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**restroom_ne_w** — 23.5 x 16.5 ft bounds; 9 ft clear, gypsum. Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.  Reference: IMG_0376,0379-0382.

**restroom_ne_m** — 42.5 x 16.5 ft bounds; 9 ft clear, gypsum. Pale ceramic tiled wet walls/floors, white sanitary fixtures, neutral partitions and coved base. Fluorescent-style troffers/downlights, mirror/sink counter, toilet/urinal partitions and soap/paper dispensers. Split wet/dry and shower compartments after source confirmation.  Reference: IMG_0376,0379-0382.

**fitness_north** — 88.5 x 41 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**stair_main** — 36 x 33 ft bounds; 12 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**cardio_gallery** — 61.5 x 74.5 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people. Open cardio mezzanine; fitness floor and glass strip visible across the guarded edge. Do not recreate the old closed conference/office boxes. Reference: IMG_0318,0328; WEB_entrance_from_level2.

**cardio_south** — 37.5 x 33 ft bounds; 12 ft clear, act_2x2. Use rubber exercise surfacing and pale circulation tile, white square columns, light walls and suspended ceiling. Selectorized machines near desk, then partition and racks/platforms beyond; upper gallery is cardio. Group equipment in repeated instances with realistic clearances. No invented signs or people.  Reference: IMG_0318,0328; WEB_entrance_from_level2.

**corridor_l2_overlook** — 12 x 22 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free. Gym on LEFT for northbound travel. Full-height observation window band with low sill; no access door onto gym void. Return toward the cross-concourse is currently inferred. Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**corridor_l2_return** — 12 x 52.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**team_meeting** — 58.5 x 40 ft bounds; 10 ft clear, act_2x4. Use room-specific brief below; pale washable walls, specified tile floor and acoustic ceiling. Keep circulation and service clearances. Fixtures must match the identified use; room names are provisional where noted.  Reference: IMG_0319,0340,0375-0378; WALKTHROUGH.md.

**team_offices** — 56.5 x 40 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**corridor_l2** — 266.5 x 12.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**stair_second** — 34.5 x 40 ft bounds; 12 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**athletic_upper** — 12 x 87.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**upper_store** — 19.5 x 87.5 ft bounds; 10 ft clear, none. Sealed concrete/vinyl, pale CMU, utility linear lights, simple secured shelving after use is confirmed. Do not populate anonymous rooms with arbitrary athletic equipment.  Reference: G-0201 service cells; no direct interior photo.

**racquetball_1** — 20 x 40 ft bounds; 20 ft clear, gypsum. 40x20 ft court footprint, maple floor, smooth pale impact walls, 20ft clear ceiling, flush court markings. Glazed rear access and flush door with safe hardware. Bright diffuse ceiling lighting; no hoops, bleachers or squash markings.  Reference: WALKTHROUGH.md 23:00 correction; G-0201 small court bays. No direct court photograph.

**racquetball_2** — 20 x 40 ft bounds; 20 ft clear, gypsum. 40x20 ft court footprint, maple floor, smooth pale impact walls, 20ft clear ceiling, flush court markings. Glazed rear access and flush door with safe hardware. Bright diffuse ceiling lighting; no hoops, bleachers or squash markings.  Reference: WALKTHROUGH.md 23:00 correction; G-0201 small court bays. No direct court photograph.

**office_l2_w1** — 20 x 32 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**office_l2_w2** — 20 x 32 ft bounds; 9 ft clear, act_2x2. Carpet tile, pale gypsum, wood doors, 2x2 acoustic ceiling and 2x4 troffers. Reception/mail slots/clock only in reception; modest desks, chairs and storage in offices; cubicles only in identified shared-office zones. Do not invent occupant names.  Reference: IMG_0323-0327.

**court_gallery** — 20 x 32 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**stair_west** — 12.5 x 46 ft bounds; 12 ft clear, none. Concrete/terrazzo treads, pale CMU, metal handrails, top/bottom landing lights and exit signage. Build flights and landings from stair_details.json, not the aggregate legacy straight envelopes. Main stair: 17+17 risers, 8ft wide, square landing, LEFT quarter turn.  Reference: WALKTHROUGH.md 23:00 correction; IMG_0341,0371.

**mechanical_l2** — 48.5 x 6 ft bounds; 12 ft clear, none. Sealed concrete, painted CMU, exposed overhead service space and utility lights. Keep the service door and maintenance aisle clear; do not detail equipment without a source.  Reference: G-0201 service rooms; unphotographed.

**upper_service** — 60 x 14 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**basketball_approach** — 12 x 40 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free. Prominent BASKETBALL - OFF LIMITS sign at Cage door; separate west exterior exit meets continuous terrain at +20ft. Do not route public circulation through the restricted gym. Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**void_competition** — 115 x 147 ft bounds; 0 ft clear, none. No slab or ceiling at Level 2 within this polygon. Continue lower room volume; protect every walking edge with 42in horizontal rails or glazing as appropriate. Do not fill the volume with a generic floor.  Reference: IMG_0335-0336,0343-0345,0369-0370; WEB_entrance_from_level2.

**void_south** — 139.5 x 109 ft bounds; 0 ft clear, none. No slab or ceiling at Level 2 within this polygon. Continue lower room volume; protect every walking edge with 42in horizontal rails or glazing as appropriate. Do not fill the volume with a generic floor.  Reference: IMG_0335-0336,0343-0345,0369-0370; WEB_entrance_from_level2.

**corridor_ne** — 50.5 x 66.5 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

**cage_gym** — 126.5 x 127.5 ft bounds; 24 ft clear, open_joist. Maple hardwood, green perimeter and wall pads; white painted CMU and exposed pale steel joists. Use perimeter hoops, retractable green/gold bleachers, scoreboard, blank/generic team banners and US flag. Ceiling high-bays; do not put columns in playing rectangles. Court markings are separate detail geometry. Upper-level restricted practice hall. Its southwest stair placement remains a flagged inference that conflicts with the drawn clear court. Do not finalize court striping until resolved. Reference: IMG_0332-0336; WEB_vb_gym_interior; WEB_vb_gym_overlook.

**void_lobby** — 107 x 154.5 ft bounds; 0 ft clear, none. No slab or ceiling at Level 2 within this polygon. Continue lower room volume; protect every walking edge with 42in horizontal rails or glazing as appropriate. Do not fill the volume with a generic floor.  Reference: IMG_0335-0336,0343-0345,0369-0370; WEB_entrance_from_level2.

**balcony** — 73.5 x 32 ft bounds; 10 ft clear, act_2x4. Polished terrazzo or the room-specified porcelain tile; pale painted CMU, light base, 2x4 acoustic ceiling and troffers. Add exit signs, door hardware, bottle filler and fire cabinet only where references support them. Keep the entire door clear width free.  Reference: IMG_0314-0316,0331,0338-0343,0346,0372-0374.

## Acceptance status

See verification/M1/REPORT.md and the saved gate logs for exact final results. Room connectivity and overall scale are verified separately from production-builder physics and visual fidelity. M1 remains unapproved while structural inferences, builder integration and sub-8 judge scores remain.
