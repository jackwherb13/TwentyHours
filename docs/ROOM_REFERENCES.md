# RAC Room Visual References & Architectural Specification

This document provides room-by-room visual references, photo citations, and concrete architectural specifications for every distinct space on the player route within George Mason University's Recreation and Athletic Complex (RAC) recreation.

Top priority: **The RAC must be dimensionally and visually faithful to the real building.**
All specifications are cross-tagged with their source of truth:
- `(photo)` — Directly verified from photographic evidence (`reference/photos/` or `reference/web/rooms/`).
- `(walkthrough)` — Authoritatively specified by the user's on-site walkthrough (`docs/WALKTHROUGH.md`).
- `(inferred)` — Structurally or logically inferred from architectural standards, building codes, or campus context.

---

## 1. Exterior Entrance, Plaza & Canopy (`exterior-entrance`)

### Visual References
- **Images:**
  - `reference/web/rooms/exterior-entrance/ewingcole_ext_daylight.jpg` (EwingCole architectural elevation)
  - `reference/web/rooms/exterior-entrance/ewingcole_ext_canopy.jpg` (EwingCole canopy perspective)
  - `reference/web/rooms/exterior-entrance/ewingcole_ext_twilight.jpg` (EwingCole twilight view)
  - `reference/web/rooms/exterior-entrance/ewingcole_ext_wide.jpg` (EwingCole campus elevation)
  - `reference/web/rooms/exterior-entrance/sj_exterior_plaza_stairs.jpg` ([Stadium Journey](https://static.wixstatic.com/media/1c8368_dade5646f5824b04b515491845238d0f~mv2.jpg))
  - `reference/web/rooms/exterior-entrance/tour_entry_canopy.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/exterior-entrance/tour_entry_doors.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/photos/IMG_0362.jpg` to `IMG_0368.jpg`, `WEB_entrance_1.jpg`, `WEB_entrance_2.jpg`, `WEB_entrance_left_pole.jpg`

### Concrete Builder Specification
- **Floor / Paving:**
  - Material: Cast-in-place concrete broom-finish paving slabs with tooled score lines (photo).
  - Color: Medium light-gray (`Color3.fromRGB(185, 185, 180)`), low reflectance (inferred).
  - Geometry: Broad terraced exterior plaza steps rising ~4 ft from campus sidewalk to main entrance threshold at `(0, 0, 0)` (photo, walkthrough).
- **Walls & Facade:**
  - Glazing: 2-story clear glass curtain wall with dark bronze/black anodized aluminum mullions wrapping the south and east corners (photo, walkthrough).
  - Cladding: Horizontal silver-gray composite metal panels (`Color3.fromRGB(150, 155, 160)`) above glazing and on adjoining gym volume (photo).
  - Masonry: Red-brown GMU campus blend modular brick (`Color3.fromRGB(140, 70, 55)`) on the adjoining physical education wing (photo).
- **Canopy:**
  - Structure: Deep black modern cantilevered overhang projecting ~25 ft over the entry plaza (photo, walkthrough).
  - Underside: Matte black soffit panels (`Color3.fromRGB(25, 25, 25)`) with flush recessed circular LED downlights (photo).
  - Columns: Two square concrete piers clad in brushed aluminum/gray precast supporting canopy edge (photo).
- **Doors & Glazing:**
  - Center: 3-wing automatic revolving glass door with dark bronze frame (photo).
  - Flanking: Paired glazed aluminum swing doors with continuous vertical push/pull bars (photo).
- **FF&E / Site Amenities:**
  - Guardrails: 1.5" diameter gray painted steel pipe handrails on stairs and retaining walls (photo).
  - Bike Racks: Forest-green serpentine tubular steel bike racks (approx. 5 loops) on plaza west flank (photo).
  - Lighting: 12-ft cylindrical black exterior area lighting poles with disc luminaires (photo).
- **Signage:**
  - Canopy Edge: White sans-serif illuminated dimensional lettering: "RECREATION AND ATHLETIC COMPLEX" (photo).
  - Glazing: Vinyl operational decals: "Mason Recreation", operating hours, NIRSA member decal (photo).

---

## 2. Main Entrance Lobby (`lobby-main`)

### Visual References
- **Images:**
  - `reference/web/rooms/lobby-main/ewingcole_lobby_overview.jpg` (EwingCole interior perspective)
  - `reference/web/rooms/lobby-main/ewingcole_lobby_high_angle.jpg` (EwingCole overhead view)
  - `reference/web/rooms/lobby-main/promo_lobby_atrium.jpg` ([Mason Rec Promo](https://www.youtube.com/watch?v=BT6k7rc-3bA))
  - `reference/web/rooms/lobby-main/tour_lobby_banner.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/photos/IMG_0369.jpg`, `IMG_0370.jpg`, `IMG_0328.jpg`, `IMG_0330.jpg`

### Concrete Builder Specification
- **Floor:**
  - Material: Porcelain floor tile (`Material.Porcelain` or `MaterialVariant`) (photo).
  - Pattern: Large format 18"x18" or 24"x24" tiles in light warm beige/sand (`Color3.fromRGB(215, 210, 198)`) with 1/8" light gray grout (photo).
  - Entry Mat: Dark charcoal recessed walk-off carpet matting grid immediately inside doors (inferred).
- **Walls:**
  - Material: Smooth painted drywall/gypsum (`Color3.fromRGB(240, 238, 232)` warm off-white). **NO interior red brick in the entrance lobby** (photo, walkthrough).
  - Glass: Full-height two-story exterior curtain wall along south/east perimeter (photo, walkthrough).
  - Structural Piers: Two rectangular structural columns clad in light-tan horizontally stacked split-face stone/masonry veneer (`Color3.fromRGB(195, 185, 170)`) located directly behind front desk (photo).
- **Ceiling & Height:**
  - Double-Height Atrium: ~20 × 20 ft clear open volume rising 22.0 ft to ceiling deck (walkthrough, photo).
  - Mezzanine Setback: Level 2 cardio floor is set back **15.0 ft** from the exterior glass curtain wall, forming a continuous double-height light slot (walkthrough, photo).
  - Mezzanine Soffit: Smooth painted drywall underside of Level 2 at 10.5 ft AFF with recessed circular pot lights (photo).
- **Lighting:**
  - Atrium: High-output circular recessed downlights and pendant-hung architectural cylinders (photo).
  - Daylighting: Flooded with natural south light through the full curtain wall (photo).
- **Doors & Glazing:**
  - Revolving door and flanking aluminum entrance doors on south wall; open flow to concourse and fitness floor (photo, walkthrough).
- **FF&E:**
  - Welcome Banner: Free-standing rollup banner stand: "Welcome to Mason Recreation" with gold star logo (photo).
  - Turnstiles / Gates: Automated optical barrier turnstiles with swing arms at card-tap entry point (photo).
- **Signage:**
  - Overhead directional wayfinding signage suspended from mezzanine fascia: "FITNESS / GYMNASIUMS / RACQUETBALL" (inferred).

---

## 3. Main Reception Desk (`reception-desk`)

### Visual References
- **Images:**
  - `reference/web/rooms/reception-desk/ewingcole_desk_front.jpg` (EwingCole architectural desk view)
  - `reference/web/rooms/reception-desk/ewingcole_desk_overhead.jpg` (EwingCole staff desk layout)
  - `reference/web/rooms/reception-desk/ewingcole_lounge_toward_desk.jpg` (EwingCole lounge view)
  - `reference/photos/IMG_0369.jpg`, `IMG_0370.jpg`, `IMG_0329.jpg`

### Concrete Builder Specification
- **Orientation & Dimensions:**
  - Placement: Located ~10 ft inside the main entrance, with its long axis running **perpendicular to the south window wall** (walkthrough, photo).
  - Overall Size: ~22 ft long × 10 ft wide U-shaped curved counter enclosure; staff area inside (walkthrough, photo).
  - Counter Height: Transaction top at 42" (3.5 studs) AFF; inner staff work desktop at 30" (2.5 studs) AFF (photo, IBC standard).
- **Materials & Colors:**
  - Body / Facing: Horizontal natural blonde birch/maple wood slats (`Color3.fromRGB(222, 195, 155)`) with fine dark reveals (photo).
  - Countertop: 2" thick white solid-surface (Corian-style) countertop (`Color3.fromRGB(245, 245, 245)`) (walkthrough, photo).
  - Accent Panels: Semi-translucent emerald green acrylic/glass panels mounted to front face with brushed silver standoffs (photo).
  - Base: 4" black recessed toe-kick (photo).
- **Front Face Logo:**
  - Center of transaction desk features the prominent official George Mason "GM" athletics star logo (walkthrough).
- **Staff Back-of-House Equipment:**
  - Staffing: Sized for 3–4 student employees (walkthrough).
  - Equipment: 3 flat-panel desktop computers, barcode card scanners, receipt printer, telephone (photo, inferred).
  - Storage: Ball rental bins (basketballs, volleyballs, racquetball racquets) and lost-and-found wire baskets behind desk (walkthrough).
  - Key Drop: Heavy-duty metal key-return dropbox (inferred).

---

## 4. Lobby Lounge / Ping-Pong & Vending Zone (`lobby-lounge`)

### Visual References
- **Images:**
  - `reference/web/rooms/lobby-lounge/ewingcole_lounge_seating.jpg` (EwingCole lounge layout)
  - `reference/web/rooms/lobby-lounge/tour_lounge_mezzanine.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/lobby-lounge/promo_lounge_balls.jpg` ([Mason Rec Promo](https://www.youtube.com/watch?v=BT6k7rc-3bA))

### Concrete Builder Specification
- **Context:**
  - Historically the "Freshens" juice bar; **the juice bar has been completely removed** (walkthrough). Now an open student lounge, ping-pong, and vending zone (walkthrough).
- **Floor:**
  - Beige porcelain tile continuous with main lobby (`Color3.fromRGB(215, 210, 198)`) (photo, walkthrough).
- **Walls & Glazing:**
  - Outer Wall: Continuous wrap-around exterior glass curtain wall on the left (walkthrough).
  - Inner Wall: Smooth painted drywall (`Color3.fromRGB(240, 238, 232)`); NO brick (walkthrough).
- **Ceiling & Height:**
  - Outer bay: Double height 22.0 ft along glass (walkthrough, photo).
  - Inner bay: Drywall soffit at 10.5 ft AFF under L2 mezzanine (photo).
- **FF&E:**
  - Ping-Pong: 2 competition-grade blue-top ping-pong tables with white court markings and center mesh nets (walkthrough).
  - Vending Machines: Bank of 3 commercial vending machines (1 Coca-Cola glass-front bottle machine, 1 Monster/energy drink machine, 1 snack machine with "Geak Bar" energy bars) (walkthrough, Rule 5).
  - Seating: 4 round white laminate cafe tables (36" diameter) with molded dark brown polypropylene chairs; 4 large cylindrical cushioned ottomans in green, gold, and charcoal (photo).
  - Planter: Long low rectangular laminate planter box with artificial foliage (photo).
  - Trash / Recycling: Stainless steel twin-stream recycling station (photo).

---

## 5. Main Stairs L1 to L2 (`stair-main`)

### Visual References
- **Images:**
  - `reference/web/rooms/stair-main/ewingcole_stair_base.jpg` (EwingCole stair base detail)
  - `reference/photos/IMG_0370.jpg` (background behind desk)
  - `docs/WALKTHROUGH.md` (Sections 11, 39, 64, 80)

### Concrete Builder Specification
- **Configuration & Geometry:**
  - Flight Count: **Exactly two straight flights with one intermediate landing** (walkthrough Section 64; overrides older three-switchback notes).
  - Direction: First flight rises from lobby floor parallel to fitness partition; lands on a square intermediate landing at +10.0 ft; turns **90° LEFT**; second flight ascends straight to Level 2 finished floor at **+20.0 ft** (walkthrough Sections 64, 80).
  - Width: Wide monumental stair, 6.0 ft (6 studs) clear width between stringers (photo, walkthrough).
  - Steps: Total ~34 risers (~7" rise, 11" tread); 17 risers per flight (walkthrough Section 66).
- **Materials:**
  - Structure: Welded structural steel carriage stringers painted dark charcoal/black (`Color3.fromRGB(35, 35, 40)`) (photo).
  - Treads / Risers: Light beige terrazzo/precast concrete treads with non-slip black abrasive nosing strips (photo).
  - Guardrail: Open horizontal brushed aluminum intermediate rails (4 rails) topped with a continuous natural blonde birch/maple round wood cap rail (photo, walkthrough).
  - Lighting: Recessed step lights in stringers; overhead recessed LED downlights in soffit (inferred).

---

## 6. L1 Open Selectorized Fitness Floor (`fitness-selectorized`)

### Visual References
- **Images:**
  - `reference/web/rooms/fitness-selectorized/ewingcole_strength_gallery.jpg` (EwingCole fitness photo)
  - `reference/web/rooms/fitness-selectorized/tour_strength_machines.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/fitness-selectorized/strength_machines_row.jpg` ([Strength Training](https://www.youtube.com/watch?v=W2PKTQ2eg-o))
  - `reference/web/rooms/fitness-selectorized/strength_cable_freemotion.jpg` ([Strength Training](https://www.youtube.com/watch?v=W2PKTQ2eg-o))
  - `reference/photos/IMG_0318.jpg`, `WEB_entrance_from_level2.jpg`

### Concrete Builder Specification
- **Floor:**
  - Heavy-duty commercial interlocking rubber athletic tile (`Material.Rubber`), 24"x24" square tiles, charcoal gray with light green and beige EPDM flecks (`Color3.fromRGB(50, 52, 53)`) (photo).
- **Walls & Partitions:**
  - Lobby Separation: Full-height glass storefront partition wall with dark anodized aluminum framing allowing clear views from lobby into fitness floor (photo, walkthrough).
  - Back / Side Walls: Smooth painted drywall in warm beige (`Color3.fromRGB(235, 230, 220)`) with 1/4" polished plate glass perimeter mirrors (photo).
  - Power Rack Separation: Half-height/full drywall partition dividing selectorized machines from heavy squat racks (walkthrough Section 53).
- **Ceiling & Height:**
  - Standard 2x4 acoustic ceiling tile (ACT) grid at 11.0 ft AFF (photo).
  - Lighting: 2x4 recessed fluorescent/LED troffer fixtures in continuous parallel rows, 4000K neutral white (photo).
- **Equipment (Counts & Types):**
  - Selectorized Circuit: ~25 commercial pin-select machines (Precor / FreeMotion / Matrix): chest press, lat pulldown, seated cable row, shoulder press, leg extension, leg curl, ab crunch, seated dip, bicep curl (photo). Silver powder-coat steel frames, black vinyl padded seats and backrests.
  - Cable Stations: 2 dual-adjustable cable column stations (FreeMotion style) with multi-grip pull-up bars (photo).
  - Sanitation: 4 wall-mounted disinfectant wipe dispensers and trash receptacles (photo).

---

## 7. L1 Squat Racks / Free Weight Area (`fitness-power-racks`)

### Visual References
- **Images:**
  - `reference/web/rooms/fitness-power-racks/legday_power_racks_platforms.jpg` ([Leg Day](https://www.youtube.com/watch?v=TRbxoaC2Wn0))
  - `reference/web/rooms/fitness-power-racks/legday_hammer_strength.jpg` ([Leg Day](https://www.youtube.com/watch?v=TRbxoaC2Wn0))
  - `reference/web/rooms/fitness-power-racks/legday_dumbbells_benches.jpg` ([Leg Day](https://www.youtube.com/watch?v=TRbxoaC2Wn0))
  - `reference/photos/IMG_0318.jpg`, `IMG_0328.jpg`

### Concrete Builder Specification
- **Floor:**
  - High-impact dual-layer black vulcanized rubber flooring, 3/4" thick (photo).
  - Olympic Platforms: 6 integrated flush wooden lifting platforms (blonde hardwood center section with black rubber drop zones on sides) (photo).
- **Walls:**
  - Full-height wall mirrors spanning the entire free weight perimeter above a 6" black rubber baseboard (photo).
  - Upper wall: Painted drywall/CMU in off-white (photo).
- **Ceiling & Height:**
  - Acoustic ceiling tile grid at 11.0 ft AFF with recessed 2x4 troffers (photo).
- **Equipment (Counts & Types):**
  - Power Racks: 6 heavy-duty Hammer Strength HD Elite half/power racks, matte black steel uprights, chrome spotter arms, plate storage horns loaded with black Olympic bumper plates (photo).
  - Dumbbell Racks: 3 multi-tier angled commercial dumbbell racks holding urethane dumbbells from 5 lbs up to 120 lbs in pairs (photo).
  - Benches: 6 adjustable flat-to-incline benches (silver frames, black vinyl pads) and 2 dedicated Olympic flat bench press stations (photo).
  - Accessories: 3 vertical barbell storage tubes holding 7-ft Olympic bars, chalk bowls on stands (photo).

---

## 8. Main Elevator (`elevator`)

### Visual References
- `docs/WALKTHROUGH.md` (Section 99: "Elevator: between the squat area and the coaches' offices").

### Concrete Builder Specification
- **Location:**
  - Positioned in the interior vestibule corridor between the L1 free weight area and the coaches' suite entrance, providing ADA access between Level 1 and Level 2 (walkthrough).
- **Doors & Frame:**
  - Single 2-speed side-sliding commercial elevator door in brushed stainless steel (`Material.Metal`, `Color3.fromRGB(200, 202, 205)`) (inferred).
  - Frame: Stainless steel wrap frame flush with painted drywall wall (inferred).
- **Call Station:**
  - Brushed stainless steel vertical faceplate with illuminated up/down call buttons and digital floor indicator lantern above door (inferred).
- **Cab Interior:**
  - Dimensions: 6.5 ft wide × 5.5 ft deep × 8.0 ft ceiling cab (inferred standard 3,500 lb hydraulic/traction passenger elevator).
  - Walls: Brushed stainless steel lower half, plastic laminate upper panels, tubular stainless handrail (inferred).
  - Floor: Charcoal resilient sheet flooring (inferred).

---

## 9. Coaches' Suite & Staff Offices (`coaches-suite`)

### Visual References
- **Images:**
  - `reference/web/rooms/coaches-suite/user_coaches_reception_mail.jpg` (`reference/photos/IMG_0323.jpg`)
  - `reference/web/rooms/coaches-suite/user_coaches_corridor.jpg` (`reference/photos/IMG_0324.jpg`)
  - `reference/web/rooms/coaches-suite/user_coaches_ceiling_lighting.jpg` (`reference/photos/IMG_0325.jpg`)
  - `reference/web/rooms/coaches-suite/user_coaches_cubicle_bullpen.jpg` (`reference/photos/IMG_0326.jpg`)
  - `reference/web/rooms/coaches-suite/user_coaches_workstations.jpg` (`reference/photos/IMG_0327.jpg`)
  - `docs/WALKTHROUGH.md` (Sections 83-85, 95)

### Concrete Builder Specification
- **Floor:**
  - Commercial tufted loop carpet tile, 24"x24", dark charcoal/slate pattern with subtle linear flecks (`Color3.fromRGB(60, 62, 65)`) (photo).
- **Walls:**
  - Smooth painted drywall in off-white/cream (`Color3.fromRGB(242, 240, 235)`). **NO brick in the coaches' office suite** (photo, walkthrough).
  - Baseboard: 4" black rubber cove base (photo).
- **Ceiling & Height:**
  - 2x2 acoustic ceiling tile grid at 9.0 ft AFF (photo).
  - Recessed 2x2 and 2x4 fluorescent/LED prismatic troffers (photo).
- **Suite Layout & Rooms:**
  - Entrance: Interior storefront glass wall with glazed door opening from right concourse (walkthrough).
  - Reception / Workroom: Compact reception desk with horizontal blonde wood slats and white transaction top matching main desk; 40-slot grey metal mail sorter unit; round analog wall clock with brushed metal rim (photo).
  - Bullpen: Central open cubicle area with 5-ft freestanding fabric partitions (taupe/beige fabric, dark brown PVC edge trim) containing ~8 workstation cubicles with L-desks and black task chairs (photo).
  - Perimeter Offices: Private offices with solid-core blonde wood doors and commercial metal frames (photo).
- **Signage:**
  - Head Coach Office: Prominent acrylic door plate: **"HEAD COACH"** (walkthrough, Rule 5).
  - Room Signs: Green and silver GM acrylic plaques ("Work Room / 1110", "Athletics Staff") (photo).

---

## 10. Main Concourse / Left Hallway (`concourse-main`)

### Visual References
- **Images:**
  - `reference/web/rooms/concourse-main/tour_brick_corridor.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/concourse-main/intomason_corridor_doors.jpg` ([Into Mason 2015](https://www.youtube.com/watch?v=m6o9t8uaUsE))
  - `reference/web/rooms/concourse-main/user_concourse_brick_vending.jpg` (`reference/photos/IMG_0331.jpg`)
  - `reference/web/rooms/concourse-main/user_concourse_brick_pier.jpg` (`reference/photos/IMG_0339.jpg`)
  - `reference/web/rooms/concourse-main/user_concourse_northeast.jpg` (`reference/photos/IMG_0371.jpg`)
  - `reference/photos/IMG_0314`–`IMG_0316`, `IMG_0319`, `IMG_0341`–`IMG_0343`, `IMG_0346`, `IMG_0372`, `IMG_0374`

### Concrete Builder Specification
- **Dimensions:**
  - Broad circulation spine: 14.0 ft to 16.0 ft wide at east entrance, narrowing to ~10.0 ft past gym doors (walkthrough, photo).
- **Floor:**
  - Large-format porcelain floor tile (12"x24" or 16"x16") laid in a 1/3-offset running bond pattern; light beige/sand matte finish (`Color3.fromRGB(215, 212, 202)`) with thin gray grout (photo).
- **Wall Materials (CRITICAL DISTINCTION):**
  - **North Wall:** Red modular brick in running bond with off-white mortar joints (`Color3.fromRGB(145, 68, 52)`). This is the original exterior facade of the 1972 PE module enveloped during the 2009 expansion (photo, walkthrough).
  - **South Wall:** Smooth painted gypsum drywall in bright off-white (`Color3.fromRGB(242, 240, 235)`). **NO brick on the south wall** (photo, walkthrough).
  - Portals: Deep cased openings through the brick wall with painted light-taupe steel wraparound frames leading to locker rooms and stairs (photo).
- **Ceiling & Height:**
  - 2x2 acoustic ceiling tile grid at 9.5 ft AFF (photo).
  - Lighting: Staggered double-row recessed 2x4 fluorescent/LED troffers aligned longitudinally down hallway (photo).
- **Doors Along Concourse:**
  - Pairs of painted light-taupe hollow metal doors with tall glass vision panels leading into RAC Competition Gym on left and Linn Gym further down (photo).
- **Amenities:**
  - Vending: 1 tall commercial refrigerated beverage vending machine wrapped in green Mason Recreation vinyl wrap (photo).
  - Waste: 3 large blue wheeled recycling/waste carts lined against brick wall (photo).
  - Wall Graphics: Green vinyl dimensional lettering on south drywall: **"GEORGE MASON ATHLETICS HALL OF FAME"** flanked by framed certificates (photo).

---

## 11. Concourse Trophy Cases (`trophy-concourse`)

### Visual References
- **Images:**
  - `reference/web/rooms/trophy-concourse/sj_trophy_case_recessed.jpg` ([Stadium Journey](https://static.wixstatic.com/media/1c8368_c3bd774db16d4945ab314cea03d883f8~mv2.jpg))
  - `reference/photos/IMG_0331.jpg` (right-side recessed cases)
  - `docs/WALKTHROUGH.md` (Section 40)

### Concrete Builder Specification
- **Placement & Enclosure:**
  - Built directly into recesses along the North brick wall of the concourse (photo, walkthrough).
  - Frame / Surround: 4" wide natural blonde maple/birch wood face trim (`Color3.fromRGB(222, 195, 155)`) flush with wall plane (photo).
  - Base: 18" high blonde wood plinth cabinet base projecting 4" from wall (photo).
- **Display Case Construction:**
  - Glazing: 1/4" tempered sliding glass panels in an aluminum track with push-button cylinder plunger lock (photo).
  - Backing: Forest green felt/fabric display backing (`Color3.fromRGB(25, 75, 45)`) in main bays, neutral tan linen backing in side bays (photo).
  - Shelving: 3 tiers of adjustable 3/8" tempered glass shelves supported on recessed vertical slotted chrome standards (photo).
  - Lighting: Concealed high-CRI warm-white linear LED strip lighting tucked behind upper header fascia (photo).
- **Artifacts & Contents:**
  - Centerpiece: Framed white George Mason #8 varsity jersey in black shadowbox frame (photo).
  - Balls: Official white championship game volleyball on angled blonde wood display stand (photo).
  - Awards: 8 wood and brass commemorative championship plaques, 4 etched silver/acrylic conference trophies, 2 bronze cups, framed team championship photographs (photo).

---

## 12. Athletic Training Room (`training-room`)

### Visual References
- `docs/WALKTHROUGH.md` (Section 44-45, 55-56)
- GMU Directory: RAC Room #1006 ("Recreation Athletic Training Room")

### Concrete Builder Specification
- **Location:**
  - Accessed via a doorless perpendicular connector hallway off the main concourse (walkthrough).
- **Floor:**
  - Seamless medical-grade heat-welded resilient sheet vinyl with integral 6" sanitary cove base; light mottled gray (`Color3.fromRGB(190, 192, 195)`) (inferred).
- **Walls:**
  - Smooth painted gypsum drywall in scrubbable semi-gloss warm white (`Color3.fromRGB(245, 245, 242)`) (inferred).
- **Ceiling & Height:**
  - 2x2 moisture-resistant acoustic ceiling tile grid at 9.0 ft AFF; recessed 2x4 clean-room troffers (inferred).
- **FF&E:**
  - Treatment Tables: 4 athletic training taping/treatment tables with forest-green heavy-duty vinyl padded tops (`Color3.fromRGB(30, 85, 50)`), blonde wood frame bases with double-door lower storage cabinets (walkthrough, inferred). Dimensions: 78" L × 30" W × 32" H.
  - Taping Station: 2 raised 36" high blonde wood taping benches with vinyl padded back wedges (inferred).
  - Ice Machine: Commercial stainless steel Scotsman/Manitowoc ice maker with storage bin (walkthrough, inferred).
  - Hydrotherapy / Rehab: Whirlpool bath tubs, resistance bands wall racks, foam rollers, rehabilitation mats (walkthrough, inferred).
  - Cabinetry: Full wall of laminate upper and lower medical supply cabinets with stainless sink (inferred).

---

## 13. Nutrition Station Vestibule (`nutrition-station`)

### Visual References
- **Images:**
  - `reference/web/rooms/nutrition-station/user_nutrition_fridge_vestibule.jpg` (`reference/photos/IMG_0375.jpg`)
  - `docs/WALKTHROUGH.md` (Section 45-47)

### Concrete Builder Specification
- **Spatial Dimensions:**
  - Compact square transition vestibule (~8.0 ft wide × 8.0 ft deep × 9.0 ft ceiling) immediately outside the volleyball team locker room (photo, walkthrough).
- **Floor:**
  - 6"x6" unglazed ceramic quarry tile in warm tan/sand (`Color3.fromRGB(195, 175, 155)`) with 3/8" gray grout (photo).
- **Walls:**
  - Left / Entry Walls: Smooth painted off-white drywall (photo).
  - Right Wall: Full-height custom vinyl graphic mural featuring collegiate volleyball action photography in monochrome gray tones (photo).
- **Ceiling:**
  - 2x2 acoustic ceiling tiles at 9.0 ft AFF with recessed circular pot light and exhaust grille (photo).
- **Refrigeration Equipment (THE NUTRITION STATION):**
  - Brand / Model: Avantco 2-door commercial reach-in glass display refrigerator on heavy-duty caster wheels (photo).
  - Dimensions: 54" W × 32" D × 80" H (photo).
  - Finish: White powder-coated steel exterior, black aluminum glass door frames, bottom-mounted compressor louver grille (photo).
  - Lightbox Header: Top illuminated translucent sign reading: **"THE MATT CORSON NUTRITION STATION"** (fictionalized per Rule 5; real header reads "THE MATT CROSON NUTRITION STATION") with yellow athletic font and volleyball crowd artwork (photo, walkthrough).
  - Stocking: Clear glass shelves loaded with bottled sports drinks (Gatorade green and yellow), bottled water, and cartons of **"Geak Bar"** energy bars (walkthrough, Rule 5).

---

## 14. Men's Varsity Volleyball Team Locker Room (`locker-volleyball`)

### Visual References
- **Images:**
  - `reference/web/rooms/locker-volleyball/user_mosaic_vb_entrance.jpg` (`reference/photos/IMG_0340.jpg`)
  - `reference/web/rooms/locker-volleyball/user_keypad_door_15234.jpg` (`reference/photos/IMG_0376.jpg`)
  - `reference/web/rooms/locker-volleyball/user_wood_lockers_honours.jpg` (`reference/photos/IMG_0377.jpg`)
  - `reference/web/rooms/locker-volleyball/user_gm_logo_locker_door.jpg` (`reference/photos/IMG_0378.jpg`)
  - `docs/WALKTHROUGH.md` (Section 45-47)

### Concrete Builder Specification
- **Entrance Sequence:**
  - Concourse Portal: Cased portal through North brick wall opens into mosaic alcove (photo).
  - Mosaic Wall: Full-height 1"x1" glass mosaic tile feature wall in green/white blend with pixelated interlocking "GM" logo and green text: **"HOME OF GMU VOLLEYBALL"** (photo).
  - Door: Painted warm-taupe hollow metal flush door with stainless steel mop kick plate, vertical D-pull handle, and **digital push-button PIN keypad lock above handle** (photo).
  - Keypad Code: **15234** (in-game interactable code) (walkthrough Section 45).
  - Header Signage: Green sans-serif letters above door: **"THE HEAD COACH LOCKER ROOM"** (fictionalized per Rule 5: the real sign names a real person; never reproduce it) (photo, walkthrough).
- **Floor:**
  - Changing Zone: Heavy-duty commercial carpet tile in dark charcoal/forest green heather (`Color3.fromRGB(45, 52, 48)`) (photo, walkthrough).
  - Wet Circulation: 6"x6" warm tan quarry tile leading to showers (photo).
- **Walls:**
  - Painted drywall in crisp off-white with dark green painted accent reveals (photo).
  - Honours Wall 1: Green painted wall lettering: **"NCAA ALL-AMERICANS"** with a two-column roster (photo). RULE 5: roster text must be illegible placeholder strokes or clearly fictional names - never real athletes' names.
  - Honours Wall 2: Green wall lettering: **"NAIA ALL-AMERICANS"** and **"EIVA HALL OF FAME"** (photo); rosters under them follow the same no-real-names rule.
  - End Wall: Ceramic tile wall with large green "GM VOLLEYBALL" graphic (photo).
- **Lockers (FF&E):**
  - Construction: Custom open-faced natural blonde birch/maple team lockers (photo).
  - Upper: Enclosed overhead storage cabinet with blonde wood door, screened George Mason athletics star logo, and padlock hasp (photo).
  - Center: Open clothing bay with coat hooks, equipment shelf, nameplate holder (photo).
  - Lower: Open shoe/cleat cubby bench shelf (photo).
  - Count: ~24 locker bays arranged along perimeter (photo, inferred).
- **Room Accessories:**
  - Molten Volleyball Cart: Black folding fabric cart filled with 12 official red/white/blue Molten volleyballs (photo).
  - Stools: Traditional 3-legged round wooden locker room stools (photo).
  - Hampers: Commercial rolling Brute laundry barrels in green and red on swivel caster dollies (photo).

---

## 15. Volleyball Team Showers & Restroom (`volleyball-showers`)

### Visual References
- **Images:**
  - `reference/web/rooms/volleyball-showers/user_vb_showers_curtains.jpg` (`reference/photos/IMG_0380.jpg`)
  - `reference/web/rooms/volleyball-showers/user_vb_restroom_vanity.jpg` (`reference/photos/IMG_0382.jpg`)
  - `reference/photos/IMG_0379.jpg`, `docs/WALKTHROUGH.md` (Section 47)

### Concrete Builder Specification
- **Floor:**
  - 6"x6" slip-resistant unglazed ceramic quarry tile in warm tan/sand (`Color3.fromRGB(195, 175, 155)`) sloping to stainless trench/floor drains (photo).
- **Walls:**
  - Shower Area: 2"x2" glazed ceramic mosaic tiles on dividing curbs; full-height molded white acrylic stall surrounds with molded 3D pyramid/diamond relief pattern on back wall and smooth sides (photo).
  - Restroom Area: 4"x4" beige/almond ceramic wall tile up to 5.0 ft AFF with sanitary cove base; smooth painted semi-gloss drywall above (photo).
- **Ceiling & Height:**
  - Water-resistant smooth drywall ceiling at 8.5 ft AFF with flush circular vapor-tight LED fixtures (photo).
- **Shower Fixtures:**
  - Individual Stalls: 4 private shower compartments with curved brushed stainless steel curtain rods (photo).
  - Shower Curtains: Heavy white vinyl curtains featuring vertical George Mason athletics wordmark in dark green and gold (photo).
  - Hardware: Chrome institutional pressure-balanced shower heads and single-lever mixer valves (photo).
- **Restroom Vanity & Stalls:**
  - Countertop: Beige composite solid-surface vanity with 3 undermount white vitreous china lavatory bowls and chrome push-metering faucets (photo).
  - Mirrors: Frameless polished plate glass mirror running entire length of vanity counter (photo).
  - Partitions: Floor-mounted, overhead-braced commercial toilet stall compartments in matte light gray with chrome hardware (photo).
  - Accessories: Black commercial wall-mounted paper towel dispensers and soap dispensers (photo).

---

## 16. Public Locker Rooms (`locker-general`)

### Visual References
- **Images:**
  - `reference/web/rooms/locker-general/user_women_locker_brick_portal.jpg` (`reference/photos/IMG_0373.jpg`)
  - `reference/web/rooms/locker-general/user_general_locker_banks.jpg` (`reference/photos/IMG_0381.jpg`)
  - `docs/WALKTHROUGH.md` (Section 101)

### Concrete Builder Specification
- **Entrance:**
  - Deep cased portals cut through the concourse North brick wall with gray steel wrap frames (photo).
  - Signs: Silver/green acrylic signage: "Men's General Locker Room / 1206" and "Women's General Locker Room / 1208" (photo).
- **Floor:**
  - 12"x12" non-slip ceramic floor tile in light gray/beige with dark grout (photo).
- **Walls:**
  - Painted concrete masonry unit (CMU) block in running bond, painted off-white/warm gray semi-gloss (`Color3.fromRGB(225, 225, 220)`) (photo).
- **Ceiling & Height:**
  - 2x4 vinyl-faced moisture-resistant acoustic ceiling tiles at 9.0 ft AFF with recessed fluorescent troffers (photo).
- **Locker Banks:**
  - Lockers: Multi-tier heavy-gauge steel lockers painted medium gray (`Color3.fromRGB(130, 132, 135)`); louvered ventilation slots, padlock hasps, numbered aluminum plates (photo).
  - Benches: Clear-finished hardwood laminated locker benches (12" wide) mounted on heavy black cast-iron pedestals bolted to floor (photo).
- **Restroom & Showers (Walkthrough Layout):**
  - "Lockers on the right, restroom with ~5 stalls on the left with sinks across from them, and public showers straight ahead" (walkthrough Section 101).
  - Restroom: 5 gray metal toilet stalls on left, bank of 4 porcelain sinks on right vanity (walkthrough Section 101).
  - Showers: Gang/semi-private shower drying area leading straight ahead to tiled stall bank (walkthrough Section 101).

---

## 17. RAC Competition Gymnasium (`gym-competition`)

### Visual References
- **Images:**
  - `reference/web/rooms/gym-competition/ewingcole_gym_bleachers_folded.jpg` (EwingCole primary gym photo)
  - `reference/web/rooms/gym-competition/sj_gym_match_court_view.jpg` ([Stadium Journey](https://static.wixstatic.com/media/1c8368_d2e6dd3a03ec4bb6842d2d6ccfc47343~mv2.jpg))
  - `reference/web/rooms/gym-competition/sj_gym_wall_pads_cmu.jpg` ([Stadium Journey](https://static.wixstatic.com/media/1c8368_415394055418435d96c94118246c9b0d~mv2.jpg))
  - `reference/web/rooms/gym-competition/sj_gym_banners_rafters.jpg` ([Stadium Journey](https://static.wixstatic.com/media/1c8368_2b9f050e2f9a4a98ae1cc18bbe05d0bd~mv2.jpg))
  - `reference/web/rooms/gym-competition/clubvb_gym_wide.jpg` ([Club Volleyball](https://www.youtube.com/watch?v=MiXtCa4L7kY))
  - `reference/web/rooms/gym-competition/tour_gym_sideline.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/gym-competition/wrestling_bleachers_crowd.jpg` ([Wrestling Match](https://www.youtube.com/watch?v=caHHTBaVymI))
  - `reference/web/rooms/gym-competition/basketball_end_wall_hoop.jpg` ([Basketball Practice](https://www.youtube.com/watch?v=tPAlCiYRebo))
  - `reference/photos/IMG_0332`–`IMG_0336`, `IMG_0344`, `IMG_0345`, `WEB_vb_gym_interior.jpg`
  - `docs/WALKTHROUGH.md` (Sections 16, 23, 34, 110)

### Concrete Builder Specification
- **Capacity & Program:**
  - 1,550-seat varsity competition arena for George Mason Men's & Women's Volleyball and Division I Wrestling (dossier, photo).
- **Floor:**
  - Material: High-gloss first-grade Northern Hard Maple strip flooring (`Material.WoodPlanks`, `Color3.fromRGB(228, 198, 155)`) (photo).
  - Painted Markings:
    - Center Court: Large interlocking "GM" athletics logo in forest green with gold outline (photo).
    - Keys / Paint: Solid painted forest green (`Color3.fromRGB(24, 72, 42)`) key/free-throw lane areas (photo).
    - Baselines: Solid forest green borders with collegiate block lettering: **"GEORGE MASON"** on one baseline, **"MASON"** on the other in yellow/gold (photo).
    - Linework: Yellow volleyball court lines (NCAA standard 9m × 18m) and black/white basketball court boundaries (photo).
- **Bleachers (CRITICAL CORRECTION):**
  - Location: **Telescoping retractable bleachers along BOTH long sidelines** (walkthrough Section 110, photo).
  - State: **RETRACTED / FOLDED against the walls during regular days** (walkthrough Section 110).
  - Colors: Molded dark forest-green plastic bench seats with bright gold/yellow vertical aisle stairs and black steel safety end-railings (photo).
- **Walls & Wainscot:**
  - Lower Wainscot: 8.0 to 10.0 ft high forest-green padded protective wall mats (`Color3.fromRGB(24, 72, 42)`) wrapping all perimeter walls (photo, walkthrough).
  - Mid Wall: White painted CMU concrete block in running bond with horizontal concrete belt course ledges (photo).
  - Upper Wall: Smooth painted drywall/plaster in bright off-white (`Color3.fromRGB(245, 245, 240)`) with exposed diagonal white structural steel wind-bracing struts (photo).
  - Clerestory Windows: Multi-pane rectangular clerestory daylight windows high along the upper sideline wall (photo).
- **Roof & Ceiling:**
  - Height: ~32.0 ft clear height to roof deck (photo, inferred).
  - Structure: Exposed white open-web steel roof trusses and joists, white corrugated metal acoustic roof decking (photo).
  - Lighting: High-bay linear fluorescent/LED sports luminaires arranged in continuous parallel bands (photo).
- **Rafter Banners & Electronics:**
  - Championship Banners: Suspended vertical fabric championship banners hung from steel trusses:
    - "CAA WOMEN'S VOLLEYBALL CHAMPIONS" (1992, 1993, 1994, 1995, 1996, 2002, 2003, 2009) (photo).
    - "NCAA WOMEN'S VOLLEYBALL" (1993, 1994, 1995, 1996, 2002, 2003) (photo).
    - "CAA WRESTLING CHAMPIONS" (1992, 1995, 1996, 1997, 2001) (photo).
    - "EIVA MEN'S VOLLEYBALL CHAMPIONS" (1984, 1985, 1988, 2016) (photo).
  - Scoreboards: Wall-mounted electronic digital scoreboards ("HOME / GUEST / PERIOD / PLAYER FOULS") in forest green casing with amber LED numerals (photo).
  - Hoops: Ceiling-suspended retractable basketball backboards with glass target faces, hoisted into rafters for volleyball (photo).
  - Flag: Large American flag suspended from center roof truss on end wall (photo).

---

## 18. Linn Gym (`gym-linn`)

### Visual References
- **Images:**
  - `reference/web/rooms/gym-linn/user_linn_gym_doors_sidelight.jpg` (`reference/photos/IMG_0320.jpg`)
  - `reference/web/rooms/gym-linn/user_linn_gym_link_doors.jpg` (`reference/photos/IMG_0321.jpg`)
  - `reference/web/rooms/gym-linn/user_linn_gym_sidelight_glazing.jpg` (`reference/photos/IMG_0322.jpg`)
  - `reference/photos/IMG_0338.jpg`, `docs/WALKTHROUGH.md` (Section 91)

### Concrete Builder Specification
- **Role & Program:**
  - Multi-court student recreation gymnasium located down the right hallway past the L1 workout area; accommodates open basketball, volleyball, badminton, and pickleball (walkthrough Section 91, photo).
- **Floor:**
  - Clear-finished maple strip hardwood sports floor with multi-color painted game linework (black basketball, yellow volleyball, green badminton lines) (photo).
- **Walls:**
  - Lower: 6.0 ft forest-green protective wall padding around court boundaries (photo).
  - Upper: Painted concrete masonry unit (CMU) block in warm off-white (`Color3.fromRGB(235, 235, 230)`) (photo).
- **Ceiling & Height:**
  - ~24.0 ft clear height with exposed white steel joists and white roof deck; suspended rectangular high-bay luminaires (photo).
- **Doors & Glazing:**
  - Entrance: Double painted hollow metal doors with large rectangular glass vision panels (2 lites per door leaf) and an adjoining **6-lite glass sidelight wall** providing full visibility from the concourse (photo).
- **Equipment:**
  - Multiple ceiling-hung and wall-mounted basketball hoops with glass/acrylic backboards and heavy protective padding (photo).

---

## 19. Corridor Thin Link (`corridor-thin-link`)

### Visual References
- **Images:**
  - `reference/web/rooms/corridor-thin-link/user_thin_link_overlook_glass.jpg` (`reference/photos/IMG_0344.jpg`)
  - `reference/web/rooms/corridor-thin-link/user_link_toward_concourse.jpg` (`reference/photos/IMG_0374.jpg`)
  - `docs/WALKTHROUGH.md` (Section 42-44)

### Concrete Builder Specification
- **Role:**
  - Connector corridor: "Immediately left of those doors is a thinner hallway with no doors that leads to a perpendicular hallway" (walkthrough Section 43-44).
- **Dimensions:**
  - Narrower width: ~7.0 ft clear width, 9.0 ft ceiling height (walkthrough, photo).
- **Floor:**
  - Beige speckled vinyl composition tile (VCT) / resilient sheet tile with dark gray cove base (photo).
- **Walls:**
  - Smooth painted gypsum drywall in off-white; stainless steel corner guards on external drywall corners (photo).
- **Ceiling:**
  - 2x2 acoustic ceiling tiles with flush circular LED pot lights (photo).

---

## 20. Emergency Egress Stair (`stair-emergency`)

### Visual References
- `docs/WALKTHROUGH.md` (Section 92: "Third stair: exists, rarely used, enclosed like an emergency exit stair... enclosed with a door and exit signage").

### Concrete Builder Specification
- **Enclosure:**
  - 2-hour fire-rated shaft enclosure constructed of painted CMU block or shaftliner drywall (inferred, IBC standard).
- **Doors:**
  - Single 3-ft wide hollow metal fire-rated door with heavy-duty rim panic exit hardware (crash bar), automatic door closer, and illuminated red/green emergency "EXIT" sign overhead (walkthrough, inferred).
- **Stair Construction:**
  - Cast-in-place concrete or pan-filled concrete treads on welded steel stringers; painted gray industrial finish (inferred).
  - 1.5" diameter continuous steel pipe handrail on both sides (inferred).
- **Lighting:**
  - Vandal-resistant surface-mounted linear fluorescent/LED utility fixtures on emergency circuit (inferred).

---

## 21. North Concourse Stair to L2 (`stair-north`)

### Visual References
- `docs/WALKTHROUGH.md` (Section 48: "Past the locker room, straight down the hall: stairs up to Level 2. At the top of those stairs, on the left: the basketball (OFF LIMITS) door, then the Level 2 exit").

### Concrete Builder Specification
- **Configuration:**
  - Straight single-run or landing-switchback stair connecting L1 north locker room concourse up to Level 2 corridor (walkthrough Section 48).
- **Width & Steps:**
  - 5.0 ft clear width; concrete treads with metal nosing; black metal pipe railings (inferred, IBC standard).
- **Walls:**
  - Painted CMU block transitioning to painted drywall at Level 2 landing (inferred).
- **Connection:**
  - Arrives directly at Level 2 corridor immediately adjacent to the "BASKETBALL — OFF LIMITS" entrance and the exterior Level 2 grade exit (walkthrough Section 48).

---

## 22. Level 2 Overlook Corridor (`corridor-l2-overlook`)

### Visual References
- **Images:**
  - `reference/web/rooms/corridor-l2-overlook/user_l2_overlook_gym_window.jpg` (`reference/photos/IMG_0344.jpg`)
  - `reference/web/rooms/corridor-l2-overlook/web_vb_gym_overlook.jpg` (`reference/photos/WEB_vb_gym_overlook.jpg`)
  - `docs/WALKTHROUGH.md` (Sections 16, 34)

### Concrete Builder Specification
- **Circulation & Orientation:**
  - At the top of the main stair, walking away from the entrance glass, **the competition gym is on your LEFT** (walkthrough Section 16, 34).
- **Floor:**
  - High-gloss neutral gray resilient sheet vinyl flooring (`Color3.fromRGB(180, 182, 185)`) with black rubber baseboard (photo).
- **Overlook Glazing (LEFT SIDE):**
  - Full-height interior storefront observation glazing: black anodized aluminum framing with large tempered glass lights looking directly down into the RAC Competition Gym court, center GM logo, and bleachers (photo, walkthrough).
- **Right Wall:**
  - Smooth painted drywall in off-white (`Color3.fromRGB(240, 238, 232)`); leading to racquetball courts and stairs down (photo, walkthrough).
- **Ceiling & Height:**
  - 2x2 acoustic ceiling tile grid at 9.5 ft AFF with rectangular recessed troffers (photo).

---

## 23. Level 2 Cardio Gallery & Balcony (`l2-cardio-gallery`)

### Visual References
- **Images:**
  - `reference/web/rooms/l2-cardio-gallery/ewingcole_cardio_gallery.jpg` (EwingCole primary photo)
  - `reference/web/rooms/l2-cardio-gallery/promo_woodway_treadmills.jpg` ([Mason Rec Promo](https://www.youtube.com/watch?v=BT6k7rc-3bA))
  - `reference/web/rooms/l2-cardio-gallery/promo_cardio_atrium_edge.jpg` ([Mason Rec Promo](https://www.youtube.com/watch?v=BT6k7rc-3bA))
  - `reference/web/rooms/l2-cardio-gallery/cardio_ellipticals_controls.jpg` ([Cardio Training](https://www.youtube.com/watch?v=jbrxSPXeiGM))
  - `reference/web/rooms/l2-cardio-gallery/cardio_wall_tvs_dumbbells.jpg` ([Cardio Training](https://www.youtube.com/watch?v=jbrxSPXeiGM))
  - `reference/web/rooms/l2-cardio-gallery/tour_cardio_gallery.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/photos/WEB_entrance_from_level2.jpg`, `docs/WALKTHROUGH.md` (Sections 13, 82, 87, 105, 106)

### Concrete Builder Specification
- **Spatial Relationship (CRITICAL):**
  - Open mezzanine gallery completely overlooking the Level 1 lobby atrium; **NO brick partition wall** (walkthrough Section 87).
  - Overlook edge sits **15.0 ft back from the south curtain wall** (walkthrough Section 13, photo).
- **Balcony Guardrail:**
  - Open 42" high horizontal brushed aluminum guardrail (4 horizontal intermediate rails) topped with a continuous natural blonde birch/maple smooth wood cap rail (photo, walkthrough).
- **Floor:**
  - High-performance athletic rubber/resilient flooring: warm beige/tan field with contrasting dark charcoal runner strips beneath cardio equipment rows (photo).
- **Walls:**
  - South/East: Open air to double-height atrium and curtain wall glass (photo, walkthrough).
  - Interior Walls: Smooth painted drywall in off-white (photo).
  - Back Wall (Perpendicular to Windows): Full-height wall mirrors behind free weight dumbbell zone (photo, walkthrough).
- **Ceiling & Height:**
  - 12.0 ft AFF to painted acoustic deck and structural steel beams; pendant and recessed fixtures (photo).
- **Cardio Equipment (FF&E):**
  - Treadmills: Row of 10 Woodway commercial slat-belt treadmills lined along balcony edge facing the lobby glass (photo, walkthrough).
  - Ellipticals: Row of 12 Precor EFX commercial cross-trainers with silver frames and orange accent handgrips (photo).
  - Stationary Bikes: 8 upright and recumbent exercise bikes (photo).
  - Free Weights: Multi-tier dumbbell rack (5 to 50 lbs) and 2 adjustable workout benches along wall perpendicular to windows (walkthrough Section 105, photo).
  - Boxing: 1 heavy leather punching bag suspended from ceiling swivel mount (walkthrough Section 87).
  - Entertainment: 6 flat-screen commercial televisions mounted on articulating wall brackets (walkthrough Section 105, photo).
- **Doors / Utility Signage:**
  - Utility doors along inner wall with green/silver signs: "STORAGE 2008", "CONTROLS 2012" (photo).

---

## 24. Level 2 Racquetball Courts (`racquetball-courts`)

### Visual References
- **Images:**
  - `reference/web/rooms/racquetball-courts/tour_squash_corridor.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `reference/web/rooms/racquetball-courts/tour_squash_interior.jpg` ([Mason Rec Tour](https://www.youtube.com/watch?v=9zIL-QVJBZg))
  - `docs/WALKTHROUGH.md` (Sections 18, 29, 68, 97)

### Concrete Builder Specification
- **Count & Location:**
  - **Two regulation courts on Level 2**, located off the overlook hallway on the **LEFT** when walking away from the entrance (walkthrough Sections 18, 68). There are no courts on Level 1 (walkthrough Section 67).
- **Dimensions:**
  - Regulation racquetball dimensions: 40.0 ft long × 20.0 ft wide × 20.0 ft high clear play volume (dossier, walkthrough).
- **Floor:**
  - High-grade unfinished Northern Hard Maple sports floor with red 2" wide regulation court service lines (photo, walkthrough).
- **Walls:**
  - Front & Side Walls: Impact-resistant high-density plaster/panel wall system painted brilliant pure matte white (`Color3.fromRGB(250, 250, 250)`) (photo, walkthrough).
  - Rear Back Wall: **Full-height 1/2" tempered glass back wall** and flush frameless tempered glass door with recessed push/pull handle allowing spectators to watch from corridor (photo, walkthrough).
- **Ceiling & Netting:**
  - Smooth impact-resistant white ceiling with recessed, flush, shatterproof fluorescent/LED sports luminaires behind polycarbonate lenses (photo).
  - Heavy black safety netting suspended above glass back wall to prevent errant balls entering hallway (photo).
- **Accessories:**
  - Analog round quartz wall clock on front wall (photo).
  - Automated AED station mounted on structural column outside courts in corridor (photo).

---

## 25. Cage Gym / Basketball Practice Facility (`gym-cage-basketball`)

### Visual References
- `docs/WALKTHROUGH.md` (Sections 20, 21, 48, 100)

### Concrete Builder Specification
- **Status & Warning Signage (CRITICAL GAMEPLAY FEATURE):**
  - **OFF LIMITS AREA:** The varsity basketball practice facility / Cage Gym is under active construction/addition work (walkthrough Section 20).
  - Must feature prominent high-visibility warning signage on doors: **"BASKETBALL — OFF LIMITS"** (walkthrough Section 20).
- **Access / Entrance:**
  - Entrance located on **Level 2** off the north hallway (walkthrough Sections 20, 48, 100).
  - Double commercial steel flush doors painted institutional gray with heavy-duty push bars, keyed deadbolts, and yellow hazard tape across frame (inferred, walkthrough).
- **Interior Court (Through Vision Panels):**
  - Floor: Maple basketball practice court with green perimeter lines (walkthrough, inferred).
  - Walls: Dark green protective wall padding around baseline, exposed joist ceiling, suspended practice hoops (inferred).

---

## 26. Level 2 Grade Exit (`l2-grade-exit`)

### Visual References
- `docs/WALKTHROUGH.md` (Sections 22, 23, 48)

### Concrete Builder Specification
- **Topographic Context (CRITICAL):**
  - The RAC is built into a sloping hillside. While the main entrance is at grade on Level 1, the outdoor terrain on the northwest side rises ~20 ft so that **Level 2 exits directly at grade to the exterior** (walkthrough Sections 22-23).
  - The exterior terrain must rise smoothly up to meet this Level 2 threshold without artificial sheer cliffs (walkthrough Section 30).
- **Door & Hardware:**
  - Heavy-duty exterior hollow metal door (or pair) with insulated glazing vision panel, weatherstripping, exterior lever handle, interior panic crash bar, and overhead illuminated "EXIT" sign (walkthrough, inferred).
- **Exterior Landing:**
  - Exterior broom-finish concrete landing pad and sloped sidewalk connecting into campus walkway network (inferred).

---

## 27. Public Restrooms (`restrooms-public`)

### Visual References
- **Images:**
  - `reference/web/rooms/restrooms-public/user_restroom_stalls_vanity.jpg` (`reference/photos/IMG_0382.jpg`)
  - `docs/WALKTHROUGH.md` (Section 101)

### Concrete Builder Specification
- **Floor:**
  - 6"x6" unglazed ceramic quarry tile in warm tan/sand (`Color3.fromRGB(195, 175, 155)`) with floor drain (photo).
- **Walls:**
  - 4"x4" beige/almond glazed ceramic tile up to 5.0 ft AFF; smooth painted off-white drywall above (photo).
- **Ceiling:**
  - 2x2 moisture-resistant acoustic ceiling tile grid at 9.0 ft AFF with recessed fluorescent troffers and exhaust grilles (photo).
- **Fixtures & Stalls:**
  - Toilet Stalls: Commercial floor-mounted, overhead-braced steel privacy partitions in neutral light gray (`Color3.fromRGB(175, 178, 180)`) with chrome latch hardware (photo).
  - Toilets / Urinals: White vitreous china commercial wall-hung fixtures with Sloan Royal chrome flushometer valves (inferred).
  - Vanity: Solid surface continuous countertop with undermount white china lavatories, automatic sensor faucets, wall-width plate glass mirror, and black paper towel dispenser (photo).

---

# GAPS: Spaces Needing Future Reference Photos

While the player route is now comprehensively documented with over 70 photographic and video frame references, the following minor gaps exist where direct interior photographs are currently unavailable:

| Space / Feature | Current State | What the User Could Photograph to Close Gap |
|---|---|---|
| **Athletic Training Room (#1006)** | Fully specified via walkthrough & directory facts, but no direct interior photo. | An eye-level shot looking into Room #1006 showing treatment tables, taping stations, and hydrotherapy tubs. |
| **Elevator Interior & Call Station** | Positioned and dimensioned per walkthrough Section 99, but no direct photo of the door or cab. | A photo of the elevator door and call button station between the free weight area and coaches' office suite. |
| **Emergency Egress Stair (Stair 3)** | Specified as enclosed fire stair per walkthrough Section 92. | A photo of the fire door and landing of the enclosed emergency stairwell. |
| **North Concourse Stair (Stair 2)** | Specified per walkthrough Section 48. | A photo of the stair flight looking up from the L1 concourse past the locker rooms. |
| **Cage Gym / Basketball Addition Door** | Specified with "BASKETBALL — OFF LIMITS" signage per walkthrough Section 20-21. | A photo of the Level 2 double doors leading into the Cage Gym / practice facility showing warning signage. |
| **Level 2 Grade Exit Threshold** | Topographically specified per walkthrough Sections 22-23. | A photo of the Level 2 exterior exit door showing where it meets the uphill sidewalk grade. |
| **L2 Racquetball Court Interior Close-up** | Documented via tour video frames; full regulation court geometry known. | A high-res photo through the glass back wall of Court 1 or 2 showing boundary lines and wall finish. |
