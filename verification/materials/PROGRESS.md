# Materials template progress

10:00 inventory - photo colors from data/inventory.json + contact sheets - docs/MATERIALS_TEMPLATE.md
10:05 PBR - ambientCG CC0 1K maps tinted to RAC samples - art/materials/pbr/
10:08 builder - Parts/Court/Walls look up only template keys - src/ReplicatedStorage/RAC/Materials.luau
10:12 check - lune tools/check_materials.luau PASS 4707 building parts
10:12 rebuild - tools/build_rac.ps1 PASS building geometry
14:20 PBR upload - color/normal/roughness maps uploaded via Studio MCP; IDs in Materials.luau + RAC_*.model.json
14:35 refine - porcelain 12x24 running bond, ACT pinholes, brushed stainless, CMU, recropped people-free swatches
14:50 rebuild - PASS 24960 parts; check_materials PASS; verify.ps1 PASS
15:10 judge - pairs regenerated; gemini porcelain 8; most others 2-7 (geometry complaints on material-only crops; gym lighting dark)
16:40 iterate - stacked CMU, vertical metal, 1in mosaic, strip maple, white painted steel, pale door wood, greige door paint; recropped swatches to material-only; pairs regenerated; verify.ps1 PASS
