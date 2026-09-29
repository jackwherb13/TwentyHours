# Realism passes after structure QA: for each pass in docs/passes/<Chain>.md -> builder (resumed Grok session) -> build ->
# independent reviewer + judges -> up to $FixRounds fixes -> next pass.
# Usage: pwsh tools/realism-loop.ps1 -Chain interior -Session <grok id> [-FixRounds 2] [-WaitFor verification/qa/PASSED]
param(
	[Parameter(Mandatory)] [ValidateSet('interior', 'exterior', 'life')] [string]$Chain,
	[Parameter(Mandatory)] [string]$Session,
	[int]$FixRounds = 2,
	[string[]]$WaitFor = @('verification/qa/PASSED'),
	[int]$StartPass = 1,
	[int]$MinScore = 7
)
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$grok = "$env:USERPROFILE\.grok\bin\grok.exe"
$agents = Join-Path $root '.grok-loop/agents'
$out = Join-Path $root "verification/passes"
New-Item -ItemType Directory -Force $out | Out-Null
$log = Join-Path $out "PROGRESS-$Chain.md"
function Log($m) { $l = "$(Get-Date -Format HH:mm) [$Chain] $m"; Add-Content $log $l; Write-Output $l }

$lockRule = @'
STUDIO LOCK: two chains share Roblox Studio. Before ANY Roblox_Studio MCP call that moves the camera, plays, or edits: wait until the file
.grok-loop/studio.lock does not exist (or is older than 20 minutes), then create it containing your chain name; delete it as soon as that
batch of Studio work is done. Keep each locked batch short (< 10 min). Never edit the RAC model by hand; rebuild with tools/build_rac.ps1.
'@

while (@($WaitFor | Where-Object { $_ -and -not (Test-Path $_) }).Count) {
	if ((Test-Path 'verification/qa/PROGRESS.md') -and (Select-String 'verification/qa/PROGRESS.md' -Pattern 'qa loop finished' -Quiet)) { break }
	Start-Sleep 60
}

$text = Get-Content "docs/passes/$Chain.md" -Raw
$passes = [regex]::Matches($text, '(?ms)^## Pass (\d+): ([^\r\n]+)\r?\n(.*?)(?=^## Pass |\z)')
$schema = '{"type":"object","properties":{"issues":{"type":"array","items":{"type":"object","properties":{"severity":{"type":"string","enum":["critical","major","minor"]},"area":{"type":"string"},"issue":{"type":"string"},"evidence":{"type":"string"},"fix":{"type":"string"}},"required":["severity","area","issue","evidence","fix"]}},"summary":{"type":"string"}},"required":["issues","summary"]}'

function Run-Builder([string]$prompt, [string]$tag) {
	$pf = Join-Path $agents "$Chain-$tag.txt"
	$prompt | Out-File $pf -Encoding utf8
	"RUNNING $(Get-Date -Format HH:mm)" | Out-File (Join-Path $agents "$Chain-realism.status") -Encoding ascii
	& $grok --prompt-file $pf --cwd $root --output-format json --always-approve --max-turns 500 --resume $Session 2>(Join-Path $agents "$Chain-$tag.err") |
		Out-File (Join-Path $agents "$Chain-$tag.json") -Encoding utf8
	"DONE 0 $(Get-Date -Format HH:mm)" | Out-File (Join-Path $agents "$Chain-realism.status") -Encoding ascii
}

foreach ($p in $passes) {
	$n = [int]$p.Groups[1].Value
	if ($n -lt $StartPass) { continue }
	$title = $p.Groups[2].Value.Trim()
	$body = $p.Groups[3].Value.Trim()
	$dir = "verification/passes/$Chain-$n"
	New-Item -ItemType Directory -Force $dir | Out-Null
	Log "pass $n start: $title"
	Run-Builder @"
REALISM PASS $n ($Chain): $title
$body

Rules: AGENTS.md (budgets in docs/SPEC.md - accurate, NOT overboard), docs/WALKTHROUGH.md is authoritative, keep structure QA fixes intact.
Rebuild with pwsh tools/build_rac.ps1 after changes (0 building geometry issues). Take before/after screenshots into $dir/ and write
$dir/NOTES.md: what you changed, evidence, what you could not verify.
$lockRule
"@ "pass$n"

	for ($r = 1; $r -le ($FixRounds + 1); $r++) {
		pwsh -NoProfile -File tools/build_rac.ps1 2>&1 | Out-File "$dir/build$r.txt" -Encoding utf8
		@"
You are an independent REVIEWER (you did not build this). Review ONLY realism pass $n ($Chain): "$title" - its goal:
$body
Check the live place 'TwentyHours.rbxl' via the Roblox_Studio MCP (read-only: camera, screen_capture, playtest/character_navigation) and the
files: $dir/NOTES.md, $dir/build$r.txt, reference photos (reference/sheets, thumbs, photos, reference/web/). Compare against the real RAC:
docs/WALKTHROUGH.md (authoritative), photos, lidar/planimetric data. Make side-by-side pairs with python tools/side_by_side.py into $dir/pairs$r/.
Also flag anything that makes no sense as a real building/site, anything floating/clipping/stray, and budget overruns.
Severity: critical = wrong vs walkthrough/photos or broken; major = clearly unrealistic or illogical; minor = polish.
Do the FULL review first. Only at the very end write $dir/ISSUES_REVIEW$r.json in this JSON format
{"issues":[{"severity":"critical|major|minor","area":"...","issue":"...","evidence":"...","fix":"..."}],"summary":"..."} and $dir/REVIEW$r.md.
A review without screenshots in $dir/pairs$r/ is invalid.
$lockRule
"@ | Out-File "$dir/review$r.prompt.txt" -Encoding utf8
		& $grok --prompt-file "$dir/review$r.prompt.txt" --cwd $root --output-format json --always-approve --max-turns 300 2>"$dir/review$r.err" |
			Out-File "$dir/review$r.json" -Encoding utf8
		$issues = @()
		try { $issues = @((Get-Content "$dir/ISSUES_REVIEW$r.json" -Raw | ConvertFrom-Json).issues) } catch { Log "pass $n review $r wrote no ISSUES_REVIEW json"; $issues = @([pscustomobject]@{ severity = 'major'; area = 'review'; issue = 'reviewer produced no issue file - rerun review'; evidence = ''; fix = 'n/a' }) }
		$pairs = @(Get-ChildItem "$dir/pairs$r" -Filter *.jpg -ErrorAction SilentlyContinue | ForEach-Object FullName)
		if ($pairs.Count) {
			pwsh -NoProfile -File tools/judge.ps1 -Images ($pairs -join ',') -Out "$dir/judgement$r.json" -MinScore $MinScore 2>&1 | Out-File "$dir/judge$r.txt" -Encoding utf8
			Select-String "$dir/judge$r.txt" -Pattern '^FAIL' | ForEach-Object { $issues += [pscustomobject]@{ severity = 'major'; area = 'photo match'; issue = $_.Line; evidence = "$dir/judge$r.txt"; fix = 'see judge problems' } }
		}
		$issues | ConvertTo-Json -Depth 6 | Out-File "$dir/ISSUES$r.json" -Encoding utf8
		$serious = @($issues | Where-Object { $_.severity -in 'critical', 'major' })
		Log "pass $n review ${r}: $($issues.Count) issues ($($serious.Count) critical/major)"
		if (-not $serious.Count -or $r -gt $FixRounds) { break }
		$txt = ($serious + @($issues | Where-Object severity -eq 'minor') | ForEach-Object { "- [$($_.severity)] $($_.area): $($_.issue)`n    evidence: $($_.evidence)`n    fix: $($_.fix)" }) -join "`n"
		Run-Builder "An independent reviewer checked realism pass $n ($title). Fix every critical/major issue (minor if cheap), rebuild, verify each with a screenshot, update $dir/NOTES.md.`n$lockRule`n`n$txt" "pass$n-fix$r"
	}
	Log "pass $n done"
}
Log 'chain finished'
"done $(Get-Date -Format s)" | Out-File "verification/passes/DONE-$Chain" -Encoding ascii
