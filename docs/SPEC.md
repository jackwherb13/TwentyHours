# 20 Hour Weeks — Spec

## Goal (phase 1)
A **1:1, photoreal-as-Roblox-allows recreation of the GMU RAC** (Recreation and Athletic Complex, 4400 University Dr,
Fairfax VA) plus its immediate campus surroundings, explorable on foot, with a simple horror loop layered on top.

"1:1" means:
- Building footprint matches the OpenStreetMap outline (way 112472416, ~392 × 341 ft) and the GMU site plan within ±2 ft.
- Room layout matches the architect drawings / site plan: every gym, corridor, stair, lobby, office suite and locker room
  in the right place with the right size (±1 ft on major walls).
- Heights come from counted evidence: CMU courses (8"), doors (7'), rims (10'), stair risers (~7"), ceiling grid (2'×2'/2'×4').
- Materials, colors and fixtures match the photos (green/gold Mason palette, maple floors, green wall pads,
  gold/green telescopic bleachers, brick accent walls, terrazzo corridors, porcelain tile lobby, carpet-tile offices).

## Known facts (from reference/)
- Built 1972 as the P.E. Building, renovated 2009; NW "Cage" gym being expanded by the Perkins&Will
  "Basketball & Academic Performance Center (RAC Addition)" — under construction 2025-26 → model it as an active
  construction zone behind fencing.
- Main entrance: south-east, 2-story glass curtain wall under a large dark cantilevered canopy with a vertical "RAC"
  sign, wide concrete stairs + ramp (IMG_0364–0368).
- Lobby: front desk, 2nd-floor balcony with horizontal-rail guardrail, fitness center behind glass (IMG_0318, 0328–0330, 0369–0370).
- Volleyball/competition gym: maple floor with green borders and GM center logo, gold/green telescopic bleachers,
  retractable ceiling hoops, NCAA banners + US flag, clerestory windows, exposed steel joists + LED high-bays, 2nd-floor
  viewing windows (IMG_0332–0337, video frames, 0344–0345).
- Corridors: terrazzo (shiny) and 12×24 porcelain tile, white painted CMU, 2×4 troffers, brick accent walls (0314–0316, 0331, 0339–0343).
- Offices: carpet tile, cubicles, reception with mail slots and clock (0323–0327).
- Volleyball locker room (real sign is a dedication to a person — use a generic "VOLLEYBALL LOCKER ROOM" sign), wood lockers,
  showers with tile, restrooms (0375–0382).
- Exterior: brown brick with precast band + sunshade fins (south/west), grey metal-panel additions (east), service
  yard with dumpsters + fenced ramp (0349–0351), lawns, pines, stormwater rock swale (0354–0355), roads with bike lanes
  and crosswalks (0356–0360).

## Gameplay (phase 2, simple)
Survive a late-night "20 hour week" practice in the RAC. **Coach** (fictional) patrols and hunts by sight and sound.
- **Geak Bar** (energy bar): throw to lure Coach to a spot; eat to refill stamina.
- **Volleyballs**: spike to stun Coach briefly.
- **Golf**: a golf club + balls — drive a ball across a gym to make noise far away; putting objectives on a mini green.
- Tasks ("hours") around the RAC; finish them before dawn. Sprint/stamina exists already.

## Out of scope for now
Monetization, data saving, lobbies/matchmaking, public publishing.

## Realism standard (applies to every build milestone)
- Every room is furnished like the real one: nothing empty or placeholder. Doors have frames, hardware and signage;
  walls have base trim, fire extinguisher cabinets, exit signs, thermostats, outlets and bulletin boards where the photos show them.
- Real-world scale for every object (1 stud = 1 ft). Prefer fewer, better props over many low-effort ones.
- Materials: MaterialVariants with correct color + roughness; no default grey plastic anywhere visible.
- Lighting: fixtures are actual light sources (SurfaceLight/SpotLight) placed where the ceiling fixtures are.
- NOT OVERBOARD (user, 2026-09-28): accurate layout and recognizable detail, not micro-detail. Budgets: whole map <= 40,000 parts
  (building shell <= 12k, props <= 20k, exterior <= 6k), repeated items instanced from templates, no parts < 0.3 ft except stripes/trim/labels,
  textures only from art/materials. When a detail costs lots of parts but is barely visible at eye level, skip it.
