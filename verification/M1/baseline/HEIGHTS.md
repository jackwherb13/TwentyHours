# Heights

Feet. Level heights and roof heights are above the Level 1 finished floor, which is the origin.
A room's `ceilingHeight` is above that level's own floor. Level 2's floor is at 16 ft, so a 10 ft
Level 2 ceiling is 26 ft above the origin and the roof over it is a couple of feet above that.

Wall height is the taller ceiling of the rooms the wall bounds. An exterior wall is at least 18 ft,
so a one-story room still has a parapet above its ceiling. That rule produces the 9, 10, 12, 14, 16,
18, 20, 24, 28, and 32 ft wall heights in the JSON. They are not separate measurements.

## Floor to floor — 16 ft

`site.json` levels are 0 and 16. Both stairs use 28 risers at 0.571 ft (16/28) and a 0.917 ft (11 inch) tread.
28 × 0.571 = 15.99 ft.

Evidence: the entrance is a two-story curtain wall with a second floor of glass over the doors
(`reference/photos/IMG_0364.jpg`, and the same facade in IMG_0365–IMG_0368). Inside, IMG_0336 shows a
full upper floor of windows looking into the competition gym, with court-level doors below them and the
joists still well above the glass. A 16 ft floor-to-floor puts that glass band at roughly 19–24 ft
(Level 2 sill 3 ft, head 8 ft), which matches the photo: the upper windows sit about one story up and
the structure continues past them. The lobby balcony in IMG_0329 is that same second floor, seen from below.

## Doors — head 7 ft, sill 0

Corridor and office doors are a standard 7 ft head. In IMG_0314 the door head sits about 3 ft below the
2×4 acoustic grid, so the corridor ceiling is 10 ft, not 8. IMG_0320 is a pair of gym doors with the same
head, a sidelight, and a deep soffit above. Cased openings without a leaf use an 8 ft head (the lobby to
the fitness floor, IMG_0329).

## Corridors — ceiling 10 ft, 2×4 acoustic tile

IMG_0314 looks down the terrazzo concourse. Painted CMU is on one side, gypsum on the other, and the
ceiling is a 2×4 grid a few feet above the 7 ft doors. IMG_0376 shows the same grid continuing into the
locker-room vestibule. Level 2 corridors use the same 10 ft 2×4 ceiling (the upper floor in IMG_0336
has a visible tiled ceiling beyond the glass).

## Offices — ceiling 9 ft, 2×2 acoustic tile

IMG_0323 is an office suite: 2×2 tile, a low gypsum soffit, a 7 ft wood door, and no sign of a tall volume.
Level 2 offices match. The office-wing roof is 28 ft: 16 ft to Level 2, plus this 9 ft ceiling, plus structure.

## Lobby — 32 ft, gypsum, open through Level 2

IMG_0364 is two stories of glass at the entrance, so the lobby is the full height of the curtain wall,
not a 10 ft room. IMG_0329 shows the wood front desk, a lowered soffit at the balcony edge, and the
volume continuing up. The lobby roof is 36 ft (32 ft clear plus structure). The entrance canopy is 16 ft,
the Level 2 line, which is where the dark canopy sits in IMG_0364, over the exterior stairs. The canopy
polygon is outside the curtain wall, in front of the threshold.

The curtain-wall opening runs head 28 ft with mullions at 5 ft. The wall itself is 32 ft, so a band of
solid panel remains at the top, which is what the photo shows above the glass.

## Competition gym — ceiling 32 ft, open joist; roof 36 ft

IMG_0332 and IMG_0336. Maple floor, green border, exposed joists and bridging, high-bay lights hung in
the volume, and a clerestory / upper window zone. The mezzanine glass in IMG_0336 occupies roughly
19–24 ft. The joists and the high glass continue above that, so the clear height is 32 ft rather than
stopping at the second floor. The north-wall clerestory in the JSON is sill 22, head 30, on the 32 ft wall.
Roof 36 ft is that ceiling plus the joist depth.

Regulation rim height is 10 ft. The hoops in IMG_0332 and IMG_0336 sit well below the joists and below
the mezzanine glass, which is what a 10 ft rim looks like in a 32 ft room. The rims are props, not a
ceiling.

## South gym — ceiling 28 ft, open joist; roof 32 ft

Same maple gym, three courts on the site plan, no mezzanine glass as tall as the competition gym's.
The south exterior window band is sill 18, head 26, under a 28 ft ceiling. Roof 32 ft. Sunshade fins on
the south facade are the vertical shades on that wall (IMG_0361, the south lawn, and the south elevation
in the site photographs IMG_0349–IMG_0351 show the brick and the fin rhythm).

## Cage — ceiling 24 ft, open joist; roof 28 ft

The existing Cage is one double-height gym (two courts on the site plan and on the Level 1 life-safety
sheet). It does not have the competition gym's clerestory. 24 ft clear, roof at 28.

## Racquetball — 40 × 20 ft plan, ceiling 20 ft, roof 22 ft

Four courts, the standard 20 ft width and 40 ft length, 20 ft clear. Level 2 does not sit on them.
IMG_0336's upper windows are on the east side of the competition gym, over the single-story locker and
restroom core, which is `corridor_l2_gym` and the upper northeast corridor. Those Level 2 windows are
sill 3 ft, head 8 ft, on a 10 ft ceiling.

## Fitness and weight — ceiling 12 ft, 2×2 tile; roof 28 ft

East-wing rooms south of the lobby. Windows sill 3 ft, head 10 ft, in a 12 ft ceiling (the punched
windows on the metal-panel east wall, IMG_0358 and IMG_0364, are this lower band, distinct from the
two-story curtain wall). Level 2 sits on these rooms, so the roof is 28 ft, not 36.

## Lockers and restrooms — ceiling 9 ft

IMG_0376 is the volleyball locker vestibule: gypsum, a 7 ft door, tile floor, and an acoustic ceiling
close overhead, the same family as the offices. Restrooms match. The northeast core's Level 2 floor is
what you see through the gym's upper glass.

## Stairs — shaft ceiling 16 ft on Level 1, 10 ft on Level 2

The shaft is open between the two floors. 16 ft is the floor-to-floor. The Level 2 run then has the
same 10 ft gypsum ceiling as the upper corridor it lands in.

## Addition — ceiling 24 ft on Level 1, 12 ft on Level 2; roof 36 ft over the new box

The addition is one fenced construction zone, not a finished interior. The life-safety sheets show future
rooms and two courts inside it. Those stay inside the zone. The west strip is the site fence and has no
roof. The box roof at 36 ft is the new building's parapet, in the same range as the existing two-story
entrance (IMG_0364).

## West link — roof 14 ft

The 12 ft corridor between the Cage and the competition gym is one story (ceiling 10). Its roof is 14 ft.
Nothing on Level 2 sits on it.

## Mechanical — ceiling 12 ft

The southwest mechanical room is one story with an exposed structure (`ceilingType` `none`). Level 2
storage sits on part of it under the 28 ft office-wing roof.

## Facade bands

Brick runs are 32 ft to the parapet on the OSM outline. The east metal panel is 36 ft, the curtain wall
32 ft, the south sunshade fins 32 ft (the south gym). The precast band is 4 ft tall with its base at 12 ft:
the light horizontal course on the brick, visible between the ground-floor windows and the upper wall in
IMG_0349 and IMG_0364. CMU block in IMG_0314 is an 8 inch course, which is the 0.67 ft interior thickness.
Exterior walls are 1.33 ft. Office partitions on the corridor are 0.4 ft studs (the gypsum side of IMG_0314
and the office side of IMG_0323).

## Column heights

Competition-gym columns are 32 ft, south gym 28 ft, Cage 24 ft: the ceiling they stand under.
Grid spacing is about 28–32 ft, which is the bay you can see between the joist girders in IMG_0336.
