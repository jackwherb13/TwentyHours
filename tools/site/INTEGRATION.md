# Separate site-builder integration (owner of tools/build_rac.luau)

`tools/build_rac.luau` applies `Site/Prepare` before `Build.build` (south glass overrides, level files untouched) and calls `Site/Builder` after the model exists. The inserted block is:

```luau
data = loader.load("src/ReplicatedStorage/RAC/Site/Prepare").apply(data)
-- Build.build ...
local siteParts = loader.load("src/ReplicatedStorage/RAC/Site/Builder").build(model, data.site)
```

Historical note, superseded by that call: insert after `assert(model, "Build.build did not produce RAC")` and before serializeModel:

```luau
-- Exterior site: raw JSON retains nested site/props extension data.
local SiteBuilder = Loader.new().load("src/ReplicatedStorage/RAC/Site/Builder")
local siteParts = SiteBuilder.build(model, data.site)
stats.parts += siteParts
stats.byCategory.SiteContext = siteParts
```

`SiteBuilder.build` replaces only `RAC.Site.Context` and reads generated TerrainData (4 ft DEM samples). Facade/roof sections already flow through existing Build modules. Do not rebuild the terrain during offline builds. In authorized TwentyHours Edit mode run `require(game.ReplicatedStorage.RAC.Site.Terrain).build(workspace.Terrain)` once after Rojo sync, and again when DEM changes. Terrain clear is restricted to the generated 1200 ft region.

Offline independent preview / integration QA: `lune run tools/site/build_preview.luau` (output entirely in verification/exterior).
