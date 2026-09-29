# Manager review of M1 draft (Claude, 2026-09-28 20:30)

Your registration and room inventory are good. The draft is NOT acceptable yet. Fix all of these before finishing:

1. **Axis-align the building.** The RAC's structural grid is currently rotated ~11° in blueprint space. Rotate ALL
   blueprint coordinates (rooms, walls, columns, stairs, voids, facade, roofs, props, photo stations) so the building's
   main walls run exactly along X and Z. Store the rotation from blueprint axes to true north in `site.json`
   (`trueNorthDeg`) and apply it only to OSM site context (roads, trees, neighbours) in M6. Snap coordinates to 0.5 ft.
2. **Rectilinear, clean geometry.** Rooms must be clean polygons with right angles (≤ 12 vertices each unless the real
   room is irregular — the lobby canopy/curtain wall is the only known angled element). No traced pixel blobs, no slivers.
   Racquetball courts are standard 40 × 20 ft boxes. Office wing = rectangular offices along a rectangular corridor loop.
3. **Walls:** merge collinear/overlapping segments; min length 2 ft; one wall per real wall. Target < 350 walls on L1.
   Every door/window/opening is an `openings` entry on its wall, not a gap between segments.
4. **No overlaps.** The RAC Addition (under construction) and its practice court must not overlap the existing Cage
   gym or each other. Model the addition as a single fenced construction zone (`type: construction`) matching the
   drawings' addition footprint. Room polygons may not overlap (except voids).
5. **No catch-all rooms.** Remove any room that spans the whole footprint. Circulation = named corridor rooms that
   follow the real corridors (the long E–W corridor south of the gyms, the lobby, the office loop).
6. **Scale proof.** Measure the basketball court lines drawn inside the Competition Gym and South Gym in the site plan
   at your chosen transform; report measured length × width vs the regulation 94 × 50 ft (and 84 × 50 for cross courts).
   Must be within ±4 %. If not, fix the scale. Put the numbers in verification/M1/REPORT.md.
7. Re-render `verification/M1/overlay_*.png` after the fixes, including a clean plan view of each level with room labels.
