# Exterior realism passes (run in order; each is built, reviewed, fixed before the next)

## Pass 1: Reference harvest (exterior)
Collect exterior references: Google Street View captures along Campus Dr / Patriot Cir / Mason Pond Dr / Global Ln around the RAC (screenshots
via the browser or Street View Static API if a key exists; otherwise user photos + web images), satellite/orthophotos (VGIN / NAIP), GMU news
photos, Perkins&Will renderings. Save to reference/web/exterior/ with INDEX.md (camera position + what it shows). Add stations.

## Pass 2: Bigger map
Extend the playable/visible area to include the surrounding campus out to the Angel Cabrera Global Center ("the Globe"), EagleBank Arena, the
Field House, RAC Field, West PE Module and the parking decks/lots between them. Beyond ~400 ft from the RAC, neighbour buildings are LOW-DETAIL
massing (correct footprint from Fairfax/OSM, height from lidar, simple facade color/material, window bands) - no interiors. Terrain for the whole
area from lidar at coarser resolution far away; fog/atmosphere at the edge. Budget: neighbours <= 4,000 parts total.

## Pass 3: Roads done right
Every road from the planimetrics with correct width and crown on the terrain; concrete curbs + gutters everywhere; lane lines (double yellow
centre, white edge, dashed lanes), bike lanes with symbols, crosswalks (ladder style where photos show), stop bars, the roundabout with its
island, curb and markings, turn arrows. Sits exactly on the ground surface (no floating, no burying).

## Pass 4: Parking and sidewalks
Every lot: asphalt, painted stalls (correct 9x18 ft), accessible stalls with symbols, islands with curbs + grass/trees, light poles, entrance/exit
curb cuts. Sidewalks: concrete with scored control joints (lines every ~5 ft), curb ramps with tactile pads at crossings, steps/ramps where
grade requires, the entrance plaza + wide stair + handrails + ramp.

## Pass 5: Landscape and street furniture
Trees placed from lidar (real positions/heights), believable species shapes (pines, oaks, maples), lawns, mulch beds, shrubs, the rock swale;
lamp posts, campus signs (building sign "Recreation and Athletic Complex"), bike racks, benches, trash cans, fire hydrants, bollards, dumpsters
in the service yard - only where photos/logic say.

## Pass 6: Clean-up and consistency
Remove stray/duplicated/floating parts, fix z-fighting, align everything to the terrain, check sight lines from every exterior photo station,
performance check (total parts within spec), final exterior photo-match on every station.
