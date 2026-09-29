# Run one parallel worker agent headless. Usage:
#   pwsh tools/run-agent.ps1 -Tool grok|codex|agy -Name props-fitness -PromptFile .grok-loop/agents/props-fitness.txt
# Output: .grok-loop/agents/<Name>.out (final answer) and <Name>.status (RUNNING / DONE <exit> <time>).
param(
	[Parameter(Mandatory)] [ValidateSet('grok', 'codex', 'agy')] [string]$Tool,
	[Parameter(Mandatory)] [string]$Name,
	[Parameter(Mandatory)] [string]$PromptFile,
	[int]$MaxTurns = 200,
	[string]$Model,
	[string]$Effort,
	[string]$Resume
)
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:Path = "$env:USERPROFILE\.rokit\bin;" + $env:Path
$dir = Join-Path $root '.grok-loop/agents'
New-Item -ItemType Directory -Force $dir | Out-Null
$out = Join-Path $dir "$Name.out"
$status = Join-Path $dir "$Name.status"
"RUNNING $(Get-Date -Format HH:mm)" | Out-File $status -Encoding ascii
$prompt = Get-Content $PromptFile -Raw

switch ($Tool) {
	'grok' {
		$ga = @('--prompt-file', $PromptFile, '--cwd', $root, '--output-format', 'json', '--always-approve', '--max-turns', $MaxTurns)
		if ($Resume) { $ga += @('--resume', $Resume) }
		& "$env:USERPROFILE\.grok\bin\grok.exe" @ga 2>"$out.err" |
			Out-File "$out.json" -Encoding utf8
		try { (Get-Content "$out.json" -Raw | ConvertFrom-Json).text | Out-File $out -Encoding utf8 } catch { Copy-Item "$out.json" $out }
	}
	'codex' {
		$cx = @()
		if ($Model) { $cx += @('-m', $Model) }
		if ($Effort) { $cx += @('-c', "model_reasoning_effort=`"$Effort`"") }
		if ($Resume) {
			$prompt | codex exec resume $Resume --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox @cx - 2>>"$out.err" | Out-File $out -Encoding utf8
		} else {
			$prompt | codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -C $root @cx - 2>"$out.err" |
				Out-File $out -Encoding utf8
		}
	}
	'agy' {
		agy -p $prompt --dangerously-skip-permissions --output-format text 2>"$out.err" | Out-File $out -Encoding utf8
	}
}
"DONE $LASTEXITCODE $(Get-Date -Format HH:mm)" | Out-File $status -Encoding ascii
