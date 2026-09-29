# Interior realism passes (run in order; each is built, reviewed, fixed before the next)

## Pass 1: Reference harvest (interior)
Search the web for as many real photos of the GMU RAC interior as possible: Mason Recreation site, gomason.com facility pages, GMU news,
Perkins&Will, Instagram/Facebook posts, Google Maps user photos, YouTube walkthrough frames (download frames with yt-dlp + ffmpeg if available),
virtual tours. Save to reference/web/interior/ (git-ignored) with a short INDEX.md entry per image: what room, camera position/direction, what it
proves (floor colors, bleacher layout, signage text, ceiling, lighting, desk shape...). Add the useful ones to blueprint/photo_stations.json.
Then list every contradiction between these photos and the current build in verification/passes/interior-1/FINDINGS.md.

## Pass 2: Finishes everywhere
Every room's floor, wall, base, ceiling and trim finishes match the photos (maple vs terrazzo vs porcelain vs carpet vs rubber vs ceramic;
painted CMU vs brick accent walls vs gypsum; ACT grid vs open joist vs gypsum). Door frames/hardware, wall base, corner guards. Colors sampled
from photos (data/inventory.json). Use art/materials textures.

## Pass 3: Volleyball / competition gym + overlook
Exact court graphics (bright maple, large Mason-green apron, gold lines, GEORGE/MASON lettering, center logo), extended bleachers both sides
matching photos, wall pads, banners/flag/scoreboards, clerestory windows, joists + ducts + lights, the Level 2 overlook glass. Other gyms too
(south gym, basketball gym with OFF LIMITS signage).

## Pass 4: Entry, desk, fitness and recreation
The front entry room (20x20 double height), the big perpendicular desk with the inner counter, ping-pong tables, vending, the two-flight stair
with glass/metal railings, the weight machines -> partition -> squat racks area, cardio rows by the glass, mirrors, TVs.

## Pass 5: Team areas
Trophy cabinet + jersey wall (lit), training room (green tables, taping stations, ice machine, cabinets), keypad vestibule with the nutrition
fridge, volleyball locker room (wood lockers, GM branding, All-American boards), restrooms/showers, racquetball courts, offices.

## Pass 6: Lighting, signage, wayfinding, small fixtures
Real light sources everywhere at realistic brightness (evening + after-hours horror mood variant), exit signs, room signs, directional signs,
fire extinguisher cabinets, thermostats, outlets, bulletin boards, clocks, trash/recycling, water fountains - only where photos or logic say.

## Pass 7: Fill the gaps with logic
Walk every space that no photo shows and make it plausible for a university rec/athletics building (storage, mechanical, janitor, corridors),
consistent with neighbouring spaces. No empty boxes, no impossible rooms. Final interior photo-match on every station.
