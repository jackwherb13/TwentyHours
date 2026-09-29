# Cross-model visual judge: ChatGPT (Codex) and Gemini (Antigravity) independently score side-by-side images.
# The builder (Grok) never grades its own work.
# Usage: pwsh tools/judge.ps1 -Images verification/M3/pairs/*.jpg -Out verification/M3/judgement.json [-Mode photo|plan]
# Exit 1 if any image scores < MinScore from either judge.
param(
	[Parameter(Mandatory)] [string[]]$Images,
	[Parameter(Mandatory)] [string]$Out,
	[ValidateSet('photo', 'plan')] [string]$Mode = 'photo',
	[int]$MinScore = 8
)
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$files = $Images | ForEach-Object { Get-ChildItem $_ } | ForEach-Object { $_.FullName }

$task = if ($Mode -eq 'photo') {
	@'
Each image is a side-by-side: LEFT = real photo of George Mason University's RAC, RIGHT = our Roblox recreation from (roughly) the
same camera position. Judge how faithfully the RIGHT reproduces the LEFT. Ignore people in the photo and ignore Roblox's
lower rendering fidelity; judge layout, proportions, materials/colors, fixtures/props, lighting and signage.
'@
} else {
	@'
Each image shows our floor plan (colored rooms, black walls) overlaid on / next to the real architect plan of George Mason
University's RAC. Judge whether every room is in the right place with the right size and shape, walls line up, doors are where
the drawing has them, and the layout is architecturally logical (circulation works, no impossible rooms).
'@
}
$prompt = @"
You are a strict architectural reviewer. $task
For EACH image return an entry. Scores are 1-10 (10 = indistinguishable in that aspect). Be specific and actionable in
"problems": name the element, what is wrong, and what it should be (e.g. "bleachers on north wall should be gold/green
telescopic, 12 rows, ~8 ft tall; build has 5 grey rows"). Output ONLY JSON:
{"results":[{"image":"<file name>","layout":n,"proportions":n,"materials":n,"props":n,"lighting":n,"overall":n,"problems":["..."]}]}
Images: $($files -join "`n")
"@

function Parse($text) {
	# Codex echoes the prompt (which contains a JSON template); keep only its final answer after the last "codex" marker.
	$parts = $text -split "(?m)^codex\s*$"
	$text = $parts[-1] -replace "(?m)^tokens used[\s\S]*$", ''
	$m = [regex]::Match($text, '\{[\s\S]*"results"[\s\S]*\}')
	if (-not $m.Success) { return $null }
	# Models sometimes drop trailing brackets; retry with common closers.
	foreach ($suffix in '', ']}', '}]}', ']}]}') {
		try { return (($m.Value + $suffix) | ConvertFrom-Json) } catch {}
	}
	return $null
}

$jobs = @{
	gpt = Start-Job -ScriptBlock {
		param($r, $p, $f)
		Set-Location $r
		$imgArgs = $f | ForEach-Object { '-i', $_ }
		$p | codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox @imgArgs - 2>$null | Out-String
	} -ArgumentList $root, $prompt, $files
	gemini = Start-Job -ScriptBlock {
		param($r, $p)
		Set-Location $r
		agy -p ($p + "`nOpen each image file listed above with your file/image viewing tool before judging.") --dangerously-skip-permissions --output-format text 2>$null | Out-String
	} -ArgumentList $root, $prompt
}
$result = @{}
foreach ($k in $jobs.Keys) {
	$raw = Receive-Job $jobs[$k] -Wait -AutoRemoveJob
	$raw | Out-File "$Out.$k.raw.txt" -Encoding utf8
	$result[$k] = Parse $raw
	if (-not $result[$k]) { Write-Output "WARN: $k judge returned no parsable JSON" }
}
$result | ConvertTo-Json -Depth 8 | Out-File $Out -Encoding utf8

$fail = $false
foreach ($k in $result.Keys) {
	foreach ($r in $result[$k].results) {
		$flag = if ($r.overall -lt $MinScore) { $fail = $true; 'FAIL' } else { 'ok  ' }
		Write-Output "$flag [$k] $($r.image): overall $($r.overall) (layout $($r.layout), materials $($r.materials), props $($r.props))"
		if ($r.overall -lt $MinScore) { $r.problems | ForEach-Object { Write-Output "       - $_" } }
	}
}
if ($fail) { exit 1 }
