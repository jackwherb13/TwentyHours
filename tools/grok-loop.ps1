# Drives Grok Build through docs/MILESTONES.md until each milestone passes verify + an independent audit.
# Usage: pwsh tools/grok-loop.ps1 [-Only M1] [-MaxAttempts 5] [-NoPush]
param(
	[string]$Only,
	[int]$MaxAttempts = 5,
	[int]$MaxTurns = 400,
	[switch]$NoPush
)
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$grok = "$env:USERPROFILE\.grok\bin\grok.exe"
$state = Join-Path $root '.grok-loop'
New-Item -ItemType Directory -Force $state | Out-Null
$log = Join-Path $state 'loop.log'

function Log($msg) {
	$line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
	Add-Content $log $line
	Write-Output $line
}

function Get-NextMilestone {
	$lines = Get-Content docs/MILESTONES.md
	for ($i = 0; $i -lt $lines.Count; $i++) {
		if ($lines[$i] -match '^- \[ \] (M\d+)\b') {
			$id = $Matches[1]
			if ($Only -and $id -ne $Only) { continue }
			$block = @($lines[$i])
			for ($j = $i + 1; $j -lt $lines.Count -and $lines[$j] -notmatch '^- \['; $j++) { $block += $lines[$j] }
			return @{ Id = $id; Text = ($block -join "`n") }
		}
	}
	return $null
}

function Invoke-Grok([string]$prompt, [string]$sessionFile, [string]$tag, [string]$schema) {
	$pf = Join-Path $state "$tag.prompt.txt"
	$prompt | Out-File $pf -Encoding utf8
	$gargs = @('--prompt-file', $pf, '--cwd', $root, '--output-format', 'json', '--always-approve', '--max-turns', $MaxTurns)
	if ($schema) { $gargs += @('--json-schema', $schema) }
	if ($sessionFile -and (Test-Path $sessionFile)) { $gargs += @('--resume', (Get-Content $sessionFile -Raw).Trim()) }
	$out = Join-Path $state "$tag.out.json"
	& $grok @gargs 2>(Join-Path $state "$tag.err.txt") | Out-File $out -Encoding utf8
	try { $j = Get-Content $out -Raw | ConvertFrom-Json } catch { Log "grok output unparsable ($tag)"; return $null }
	if ($sessionFile -and $j.sessionId) { $j.sessionId | Out-File $sessionFile -Encoding ascii }
	Log "grok $tag stop=$($j.stopReason) turns=$($j.num_turns)"
	return $j
}

while ($true) {
	$m = Get-NextMilestone
	if (-not $m) { Log 'No unchecked milestones left (or -Only milestone done).'; break }
	$id = $m.Id
	$sess = Join-Path $state "$id.session"
	Log "=== $id start ==="
	$prompt = @"
You are the builder for milestone $id of this repo. Read AGENTS.md, docs/SPEC.md and the milestone below first.
Work autonomously until every "Done when" item is satisfied. Use the Roblox_Studio MCP for anything in Studio.
Keep going through failures; do not stop to ask questions. Commit nothing (the driver commits).
When finished: run ``pwsh tools/verify.ps1``, do the Studio checks from AGENTS.md, and write verification/$id/REPORT.md
listing each Done-when item with evidence (file paths, numbers, screenshot paths). The last line of REPORT.md must be
exactly ``STATUS: DONE`` or ``STATUS: BLOCKED: <reason>``.

MILESTONE:
$($m.Text)
"@
	$attempt = 0
	$passed = $false
	while ($attempt -lt $MaxAttempts -and -not $passed) {
		$attempt++
		$null = Invoke-Grok $prompt $sess "$id.build$attempt" $null

		$v = pwsh -NoProfile -File tools/verify.ps1 2>&1 | Out-String
		$v | Out-File (Join-Path $state "$id.verify$attempt.txt") -Encoding utf8
		if ($LASTEXITCODE -ne 0) {
			Log "$id attempt ${attempt}: verify FAILED"
			$prompt = "tools/verify.ps1 failed. Fix every failure, re-run it until it passes, then re-do the Studio checks and update verification/$id/REPORT.md.`n`n$($v.Substring([Math]::Max(0, $v.Length - 6000)))"
			continue
		}
		Log "$id attempt ${attempt}: verify passed"

		$auditSchema = '{"type":"object","properties":{"verdict":{"type":"string","enum":["PASS","FAIL"]},"problems":{"type":"array","items":{"type":"string"}}},"required":["verdict","problems"]}'
		$audit = Invoke-Grok @"
You are an independent AUDITOR (not the builder). Do not modify any files or the Studio place except to take screenshots
into verification/$id/audit/. Judge milestone $id strictly against its Done-when list below and AGENTS.md.
Inspect: git diff HEAD --stat and the changed files, verification/$id/REPORT.md, the screenshots it cites (open them and
compare with the reference photos), and the live Studio place via read-only MCP calls (get_console_output, search_game_tree,
inspect_instance, screen_capture). Be skeptical: a claim without evidence is a FAIL. Return PASS only if every item is met.

MILESTONE:
$($m.Text)
"@ $null "$id.audit$attempt" $auditSchema
		$verdict = $null
		try { $verdict = ($audit.text | ConvertFrom-Json) } catch {}
		if ($verdict -and $verdict.verdict -eq 'PASS') {
			$passed = $true
		} else {
			$problems = if ($verdict) { ($verdict.problems | ForEach-Object { "- $_" }) -join "`n" } else { '- audit produced no verdict' }
			Log "$id attempt ${attempt}: audit FAILED`n$problems"
			$prompt = "An independent audit rejected milestone $id. Fix every problem below, re-verify, and update verification/$id/REPORT.md.`n$problems"
		}
	}

	if (-not $passed) {
		"Milestone $id blocked after $MaxAttempts attempts. See .grok-loop/$id.* files." | Out-File (Join-Path $state 'BLOCKED.md') -Encoding utf8
		Log "=== $id BLOCKED ==="
		break
	}

	(Get-Content docs/MILESTONES.md -Raw) -replace "- \[ \] $id\b", "- [x] $id" | Set-Content docs/MILESTONES.md -NoNewline -Encoding utf8
	git add -A
	git commit -q -m "$id complete (Grok build loop, verify + audit passed)`n`nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
	if (-not $NoPush) { git push -q 2>&1 | Out-Null }
	Log "=== $id DONE (committed) ==="
	if ($Only) { break }
}
