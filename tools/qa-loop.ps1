# Structure QA loop: independent reviewer finds problems -> builders fix -> repeat, so the user doesn't have to.
# Usage: pwsh tools/qa-loop.ps1 -ArchitectSession <grok id> -ExteriorSession <grok id> [-Rounds 4]
# Waits for the running architect-grok / exterior-grok jobs to finish first. Writes verification/qa/round<N>/.
param(
	[Parameter(Mandatory)] [string]$ArchitectSession,
	[Parameter(Mandatory)] [string]$ExteriorSession,
	[int]$Rounds = 4
)
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$agents = Join-Path $root '.grok-loop/agents'
$qa = Join-Path $root 'verification/qa'
New-Item -ItemType Directory -Force $qa | Out-Null
$log = Join-Path $qa 'PROGRESS.md'
function Log($m) { $l = "$(Get-Date -Format HH:mm) $m"; Add-Content $log $l; Write-Output $l }

function Wait-Agents([string[]]$names) {
	while ($true) {
		$running = @($names | Where-Object { (Get-Content (Join-Path $agents "$_.status") -ErrorAction SilentlyContinue) -match '^RUNNING' })
		if (-not $running.Count) { return }
		Start-Sleep 30
	}
}

$schema = '{"type":"object","properties":{"issues":{"type":"array","items":{"type":"object","properties":{"severity":{"type":"string","enum":["critical","major","minor"]},"owner":{"type":"string","enum":["architect","exterior"]},"area":{"type":"string"},"issue":{"type":"string"},"evidence":{"type":"string"},"fix":{"type":"string"}},"required":["severity","owner","area","issue","evidence","fix"]}},"summary":{"type":"string"}},"required":["issues","summary"]}'

$invalid = 0
Wait-Agents @('architect-grok', 'exterior-grok')
for ($round = 1; $round -le $Rounds; $round++) {
	$dir = "verification/qa/round$round"
	New-Item -ItemType Directory -Force $dir | Out-Null
	Log "round $round - build"
	pwsh -NoProfile -File tools/build_rac.ps1 2>&1 | Out-File "$dir/build.txt" -Encoding utf8
	python tools/verify_blueprint.py 2>&1 | Out-File "$dir/blueprint_check.txt" -Encoding utf8
	pwsh -NoProfile -File tools/verify.ps1 2>&1 | Out-File "$dir/verify.txt" -Encoding utf8
	$verifyFailed = $LASTEXITCODE -ne 0

	$userReviews = (Get-ChildItem docs/reviews -Filter 'USER-*.md' | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
	@"
You are an independent QA REVIEWER for a 1:1 Roblox recreation of GMU's RAC. You did NOT build it; your job is to find everything that is wrong
before the user sees it. Do NOT edit blueprint/, src/, or the RAC model. You may use the Roblox_Studio MCP in the place 'TwentyHours.rbxl' (never
'Jay test') to move the camera, playtest, use character_navigation and screen_capture. Save all evidence under $dir/. Use subagents for offline analysis.
Read first: AGENTS.md, docs/WALKTHROUGH.md (AUTHORITATIVE), docs/SPEC.md, docs/ARCHITECT_NOTES.md, verification/exterior/ROOF_HEIGHTS.md, and $dir/build.txt,
$dir/blueprint_check.txt (automated check output: every FAIL line there is at least a major issue).
Review three ways:
A. ROUTE WALK: follow docs/WALKTHROUGH.md step by step as a player (playtest + character_navigation, or camera at eye height 5.5 ft if navigation
   fails). At EVERY step screen_capture to $dir/route/stepNN.png and state what should be visible and whether it is (e.g. "L2 hallway: volleyball gym
   visible on the LEFT through glass"). Any step that is missing, in the wrong order, on the wrong side, or not physically walkable = critical.
B. EXTERIOR: capture from the camera positions of the exterior photos (IMG_0349-0368, WEB_entrance_1/2, WEB_entrance_left_pole; stations in
   blueprint/photo_stations.json), make pairs with python tools/side_by_side.py into $dir/pairs/, and compare: entrance stairs/ramp, canopy shape,
   glass wrap, facade materials, roads/roundabout sitting on the real ground (compare with verification/exterior/terrain_grid.json / lidar), trees.
C. BUILDING SENSE: does it function as a real building? Stairs connect floors with real risers (<= 7.75 in) and landings, every upper floor is
   supported, railings at every drop/void edge, every door leads somewhere, windows face outside or into gyms intentionally, no floating/stray/
   pointless elements, no rooms without access, lighting present, nothing clipping.
The user's own complaints (must each be explicitly re-checked; still broken = critical):
$userReviews
Report EVERY problem with severity (critical = wrong vs walkthrough/photos or non-functional; major = clearly unrealistic/illogical; minor =
cosmetic), owner (architect = anything in or of the building structure/interior; exterior = terrain, roads, parking, trees, facades, canopy,
entrance stairs), area, issue, evidence (screenshot path + what you measured), and a concrete fix. Be strict and specific.
Do the FULL review first (expect 60-200 tool calls). Only at the very end, write $dir/ISSUES_REVIEW.json exactly in this JSON format
{"issues":[{"severity":"critical|major|minor","owner":"architect|exterior","area":"...","issue":"...","evidence":"...","fix":"..."}],"summary":"..."}
and a readable $dir/REVIEW.md. A review with no screenshots under $dir/route/ and $dir/pairs/ is invalid.
"@ | Out-File "$dir/reviewer_prompt.txt" -Encoding utf8
	Log "round $round - reviewer"
	# Run the reviewer with a watchdog: if its session writes nothing for 20 minutes (a hung Studio call), kill it.
	$rp = Start-Process -FilePath "$env:USERPROFILE\.grok\bin\grok.exe" -ArgumentList @('--prompt-file', "$dir/reviewer_prompt.txt", '--cwd', $root, '--output-format', 'json', '--always-approve', '--reasoning-effort', 'xhigh', '--max-turns', '300') -RedirectStandardOutput "$dir/reviewer.json" -RedirectStandardError "$dir/reviewer.err" -NoNewWindow -PassThru
	$sessions = "$env:USERPROFILE\.grok\sessions"
	while (-not $rp.HasExited) {
		Start-Sleep 60
		$newest = Get-ChildItem $sessions -Recurse -Filter chat_history.jsonl -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $rp.StartTime } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
		$last = if ($newest) { $newest.LastWriteTime } else { $rp.StartTime }
		if (((Get-Date) - $last).TotalMinutes -gt 20) { Log "round $round - reviewer silent 20 min (hung Studio call?), killing"; Stop-Process -Id $rp.Id -Force; break }
	}
	$issues = @()
	$reviewOk = $true
	try { $issues = @((Get-Content "$dir/ISSUES_REVIEW.json" -Raw -ErrorAction Stop | ConvertFrom-Json).issues) } catch { Log "round $round - reviewer wrote no ISSUES_REVIEW.json"; $reviewOk = $false }
	$shots = @(Get-ChildItem "$dir/route", "$dir/pairs" -Recurse -File -ErrorAction SilentlyContinue).Count
	if ($shots -lt 5 -or -not $reviewOk) {
		Log "round $round - reviewer produced only $shots screenshots: review invalid, retrying the round"
		if (++$invalid -gt 2) { Log "round $round - reviewer failed 3 times; stopping QA loop"; break }
		$round--
		continue
	}

	$pairs = @(Get-ChildItem "$dir/pairs" -Filter *.jpg -ErrorAction SilentlyContinue | ForEach-Object FullName)
	if ($pairs.Count) {
		pwsh -NoProfile -File tools/judge.ps1 -Images ($pairs -join ',') -Out "$dir/judgement.json" 2>&1 | Out-File "$dir/judge.txt" -Encoding utf8
		Select-String "$dir/judge.txt" -Pattern '^FAIL' | ForEach-Object {
			$issues += [pscustomobject]@{ severity = 'major'; owner = 'exterior'; area = 'photo match'; issue = $_.Line; evidence = "$dir/judge.txt"; fix = 'see judge problems' }
		}
	}
	if ($verifyFailed) {
		$vf = (Select-String "$dir/verify.txt" -Pattern '^FAIL' | ForEach-Object Line) -join '; '
		$issues += [pscustomobject]@{ severity = 'critical'; owner = 'architect'; area = 'verify gate'; issue = "tools/verify.ps1 fails: $vf"; evidence = "$dir/verify.txt"; fix = 'make pwsh tools/verify.ps1 print VERIFY PASSED' }
	}
	$issues | ConvertTo-Json -Depth 6 | Out-File "$dir/ISSUES.json" -Encoding utf8
	$serious = @($issues | Where-Object { $_.severity -in 'critical', 'major' })
	Log "round $round - $($issues.Count) issues ($($serious.Count) critical/major)"
	if (-not $serious.Count -and $issues.Count -ge 0 -and (Test-Path "$dir/reviewer.json")) {
		Log "round $round - PASSED: structure accepted"
		"PASSED round $round" | Out-File "$qa/PASSED" -Encoding ascii
		break
	}

	foreach ($owner in 'architect', 'exterior') {
		$mine = @($issues | Where-Object { $_.owner -eq $owner })
		if (-not $mine.Count) { continue }
		$txt = ($mine | ForEach-Object { "- [$($_.severity)] $($_.area): $($_.issue)`n    evidence: $($_.evidence)`n    fix: $($_.fix)" }) -join "`n"
		"An independent QA reviewer walked the building (round $round, evidence in $dir/). Fix EVERY critical and major issue below (and minor ones if cheap), rebuild with pwsh tools/build_rac.ps1, keep 0 building geometry issues, and re-check each item yourself with a screenshot before finishing.`n`n$txt" |
			Out-File (Join-Path $agents "$owner-qa$round.txt") -Encoding utf8
	}
	$launched = @()
	if (Test-Path (Join-Path $agents "architect-qa$round.txt")) {
		Start-Process pwsh -ArgumentList '-NoProfile', '-File', 'tools/run-agent.ps1', '-Tool', 'grok', '-Name', 'architect-grok', '-PromptFile', ".grok-loop/agents/architect-qa$round.txt", '-MaxTurns', '400', '-Resume', $ArchitectSession -WindowStyle Hidden -WorkingDirectory $root
		$launched += 'architect-grok'
	}
	if (Test-Path (Join-Path $agents "exterior-qa$round.txt")) {
		Start-Process pwsh -ArgumentList '-NoProfile', '-File', 'tools/run-agent.ps1', '-Tool', 'grok', '-Name', 'exterior-grok', '-PromptFile', ".grok-loop/agents/exterior-qa$round.txt", '-MaxTurns', '400', '-Resume', $ExteriorSession -WindowStyle Hidden -WorkingDirectory $root
		$launched += 'exterior-grok'
	}
	Log "round $round - fixers: $($launched -join ', ')"
	Start-Sleep 20
	Wait-Agents $launched
}
Log 'qa loop finished'
