# User review 2026-09-29 19:05 - the lobby is one open space (critical)

User, looking at the live build: "the lobby is much more open, look at the reference images, it's a completely open space and the desk is a
lot further back and nothing is making sense."

Authoritative details: docs/WALKTHROUGH.md, section "Lobby is one open space (user, 2026-09-29 19:05)".

What is wrong in the build (manager, from `python tools/render_plan.py` at 19:00):
- The entrance zone on Level 1 is cut into walled sub-rooms: `Lobby` (22x45), `South Vestibule` (87x16), `Fitness Annex` (30x32),
  `Stair Main` (enclosed 25x22), `Corridor Wide` (62x39), `Corridor Entry South` (12x64), plus `Corridor South Link`. In the real
  building this is ONE open hall.
- The desk sits ~10 ft inside the door. In the photos it is behind the lounge and a planter, under the Level 2 balcony edge (~25-30 ft in).
- Standing just inside the doors you face a white wall/pier and a low ceiling; in IMG_0370 you see a two-storey open hall, the desk on the
  right, the stair rising behind it, and a long straight hallway ahead.

Must be true before QA can pass (each is critical):
1. Plan: no interior walls between the entrance glass, the lounge, the desk, the main stair and the start of the long hallway. Only columns.
2. Double-height strip along the entrance glass with the lounge furniture (cafe tables + chairs, round poufs along the glass).
3. Knee-high wood planter/bench between lounge and desk.
4. Desk under the Level 2 balcony edge, near end ~25-30 ft from the glass, long axis perpendicular to the glass, on the right as you enter.
5. Main stair open in the hall behind the desk (not boxed in), core clad in tan stacked tile.
6. Side-by-sides from the IMG_0370, IMG_0369 and EwingCole viewpoints look like the same room (judge overall >= 7).
