# Site markings handoff

Exterior / manager: after `Site.Builder` builds pavement, add:

```luau
require(ReplicatedStorage.RAC.Site.Markings).build(grounded, rawSite.site)
```

`grounded` is the existing `GroundSlab` (or Context) folder. `Markings.build` creates `SiteMarkingsSlab` under that parent, drapes 4 in paint 0.02 ft above the heightfield, and stays under 2,500 parts.
