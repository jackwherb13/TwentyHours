# Exterior evidence and current handoff

The existing baseline checker printed no FAIL lines. Its report says 30/31 L1 rooms reachable; that existing blueprint issue is outside this task. Initial review packet: baseline_plan.png.

Photo observations (reference sheets + selected 640 px thumbnails, no photo textures):
- IMG_0349–0351: brown brick service court; buff concrete fascia, projecting diagonal silver sunshade supports, black mesh fence, green dumpsters and ramp.
- IMG_0352–0353: brick south gym, grey metal volume with brick base, glazed stair entrance, mature pines, concrete paths.
- IMG_0354–0355: broad shallow grass depression with grey riprap channel; terrain must not be flat.
- IMG_0356–0360: two-lane road, double yellow center, white bicycle lanes, white zebra crosswalk, concrete curbs.
- IMG_0364–0368 and WEB_entrance_1/2: charcoal deep cantilever, tapering front fascia, pale tall columns, black curtain-wall mullions, white RAC letters; approximately 10 stair risers at 7 inches (5.83 ft total), three intermediate handrails. Front glass roughly 24 ft tall from door-height scaling. Not survey-grade heights.
- WEB_entrance_left_pole: grey metal end volume, horizontal panel joints, brick office wing, pale middle-floor spandrel, concrete retaining plinth.

Coordinate decision: use the interim pixel mapping exactly (685,470 origin; 100/140 ft/px). Geographic data uses 10.43 degrees grid bearing; align geographic RAC north-west competition-gym corner to interim pixel (406,184). Preserve existing top-level site keys, including the legacy trueNorthDeg=0; actual geographic rotation is recorded in the owned nested site section.

Studio blocked: MCP reports only Place1; awaiting confirmation that it is TwentyHours. No Studio modifications performed.

Additional official web references downloaded under reference/web, provenance in web_sources.json:
- gmu_facilities120: deeper wedge soffit and two storeys of glazing; white middle-floor spandrel, stair aligned with recessed glazed entrance; confirms broad landscaping plinth.
- gmu_rac_2019: contains people, used only for architectural observation; never a texture. Column faces appear rectangular in this view despite request for round columns; current design follows requested round supports. Ten risers still an estimate pending actual render matching.

Facade QA correction: legacy facade skin ends overlapped perpendicular backing-wall end faces. Skin endpoints now stop 0.75 ft before corners. The baseline and facade/roof-enabled building both report the same 11 existing wall gaps; facade additions report zero z-fighting, door obstruction, floating or intersection issues.

2026-09-29. The architect frame put the south RAC door at the origin. Lidar and county pavement were shifted onto that frame (terrain origin x0=-418.5249, z0=-580.0041). The entrance stair, ramp, planter, and wedge canopy are built there. Full-model geometry check: 0 issues. Lane paint and curbs are not instanced; they shared faces with the pavement slabs. Captures: verification/exterior/IMG_0364.png, IMG_0365.png, IMG_0368.png, IMG_0352.png, IMG_0358.png, WEB_entrance_2.png, WEB_entrance_left_pole.png.
