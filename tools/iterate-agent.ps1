# Force an agent to iterate against the judges: judge its images -> if any score < MinScore, resume its Grok session with the
# judges' problems -> repeat. Grok tends to stop after one pass; this closes the loop externally.
# Usage: pwsh tools/iterate-agent.ps1 -Name site-markings -Session <grok id> -Images "verification/site_markings/overlay_*.jpg" `
#          -Task "<judge task text>" [-Mode plan|photo] [-MinScore 8] [-MaxIters 5]
param(
	[Parameter(Mandatory)] [string]$Name,
	[Parameter(Mandatory)] [string]$Session,
	[Parameter(Mandatory)] [string]$Images,
	[string]$Task,
	[ValidateSet('photo', 'plan')] [string]$Mode = 'plan',
	[int]$MinScore = 8,
	[int]$MaxIters = 5
)
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$agents = Join-Path $root '.grok-loop/agents'
$log = Join-Path $agents "$Name.iterate.md"

for ($i = 1; $i -le $MaxIters; $i++) {
	$files = @(Get-ChildItem $Images -ErrorAction SilentlyContinue | ForEach-Object FullName)
	if (-not $files.Count) { Add-Content $log "$(Get-Date -Format HH:mm) iter ${i}: no images matching $Images"; break }
	$out = Join-Path $agents "$Name.judge$i.json"
	$jargs = @('-NoProfile', '-File', 'tools/judge.ps1', '-Images', ($files -join ','), '-Out', $out, '-Mode', $Mode, '-MinScore', $MinScore)
	if ($Task) { $jargs += @('-Task', $Task) }
	$j = pwsh @jargs 2>&1 | Out-String
	$passed = $LASTEXITCODE -eq 0
	Add-Content $log "$(Get-Date -Format HH:mm) iter ${i}: $(if ($passed) { 'PASS' } else { 'FAIL' })`n$(($j -split "`n" | Where-Object { $_ -match '^(ok|FAIL)' }) -join "`n")"
	if ($passed) { break }
	$pf = Join-Path $agents "$Name.iter$i.txt"
	@"
Independent judges scored your output below $MinScore/10. You stopped too early last time: keep iterating (fit -> re-render -> compare) until
every problem below is fixed, then regenerate the SAME images ($Images) so they can be re-judged. Keep verify/geometry checks passing.

$($j.Substring([Math]::Max(0, $j.Length - 9000)))
"@ | Out-File $pf -Encoding utf8
	pwsh -NoProfile -File tools/run-agent.ps1 -Tool grok -Name $Name -PromptFile $pf -MaxTurns 400 -Resume $Session 2>&1 | Out-Null
}
Add-Content $log "$(Get-Date -Format HH:mm) done"
