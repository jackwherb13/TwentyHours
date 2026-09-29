# Blueprint geometry builder

Generate production data after the blueprint owner supplies it:

```powershell
python tools/json2luau.py blueprint src/ReplicatedStorage/RAC/Build/Data
```

Entry point in Studio (the Studio owner runs this in Edit mode):

```lua
local Build = require(game.ReplicatedStorage.RAC.Build.Build)
local stats = Build.build(workspace, nil) -- loads generated Data ModuleScripts
print(stats.parts, stats.byCategory)
```

For decoded JSON use `{site = siteTable, levels = {level1Table, level2Table}}`.
`{site=..., level1=..., level2=...}` is also accepted. All plan positions stay in
blueprint axes; `trueNorthDeg` is retained as metadata for later geographic site context.
No game services, publishing, or Studio automation are called by these modules.

Offline: `lune run tests/build.spec.luau`. This generates fixture modules under
`tests/fixtures/generated/` and writes the requested `places/build_preview.rbxm`.
The miniature building is synthetic test data, not a measurement of the RAC.

Implementation limits / integration notes:

- Slabs and ceiling outlines require rectilinear polygons, including concave L/U
  shapes and overlapping holes. Angled polygon edges fail explicitly; walls can
  run in any direction. No guessed approximation is made for angled slabs.
- Stairs are straight flights; the polygon anchors the bottom at its minimum
  projection along `direction`. Rounded rise totals within 0.05 ft are reconciled
  to the exact level elevations; larger discrepancies fail.
- Skins inherit matching wall openings. Curtain facade segments should describe
  glazing-only regions; entrance doors belong to wall openings, not facade skins.
- MaterialVariant names use the `RAC_` prefix (see Parts.luau). Texture-backed
  MaterialVariant assets and Future lighting are integration work for the Studio
  owner. Base materials/colors work without those assets.
- Door dimensions/tag options are passed to the prop library. DoorService hinge
  behavior and arbitrary-size door fitting depend on the supplied prop modules;
  these builders neither rewrite props nor add gameplay controllers.
- Unknown/missing prop modules warn and produce an orange 2 ft cube. Errors inside
  an existing prop module propagate so real implementation errors remain visible.
- Shell dimensions follow JSON. Grid/trim, slab thicknesses, and roof parapet
  defaults are construction details not specified by the schema.

Generated Data intentionally contains no fixture building. Run the converter on
real blueprint data before calling the default loader in Studio.
