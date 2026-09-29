# Lighting specialist log

## 2026-09-29

- Before: Lighting.luau `tune()` clamped every SurfaceLight to brightness 1.5–3 and range 16–40, so gym high-bays (authored 4/56) never reached the floor. Fixture grids were dense (gym every 20 ft, limit 40) and produced 24655 Lighting parts.
- Change: per-kind brightness (high-bay 12/60 + PointLight fill 5/48; 2x4 4.2/40; 2x2 3.6/32; lobby cans sparse). Spacing gym 32 ft limit 16; corridors 16 ft; offices 12 ft. Lights.build no-ops if `RAC.Lighting` already exists. Service: Future, Brightness 1.0, ExposureCompensation -0.15, Ambient 52, OutdoorAmbient 96, Atmosphere density 0.18, Bloom threshold 1.4.
- After build: Lighting 11836 parts, 922 Light instances, 88 zones, total map 30683 parts. Play: lobby glass readable (not blown). Gym through L2 glass still underlit relative to photos. Maple/green floor is Court/materials, not this module.
- Walkthrough check later blocked `tools/build_rac.ps1` (racquetball/stair/desk FAILs in other agents' files). Last successful full ps1: 30683 parts, 0 geometry issues.
