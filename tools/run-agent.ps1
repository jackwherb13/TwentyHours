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
$errLog = Join-Path $dir "$Name.$(Get-Date -Format yyyyMMdd-HHmmss).err"  # unique per run: a stuck handle on an old log cannot block a relaunch
"RUNNING $(Get-Date -Format HH:mm)" | Out-File $status -Encoding ascii
$prompt = Get-Content $PromptFile -Raw

switch ($Tool) {
	'grok' {
		# A session whose context filled up is replaced by a fresh one; session-map.json redirects every later -Resume of the old id.
		$mapFile = Join-Path $dir 'session-map.json'
		$map = if (Test-Path $mapFile) { Get-Content $mapFile -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
		while ($Resume -and $map.ContainsKey($Resume)) { $Resume = $map[$Resume] }
		$ga = @('--cwd', $root, '--output-format', 'json', '--always-approve', '--max-turns', $MaxTurns, '--reasoning-effort', $(if ($Effort) { $Effort } else { 'xhigh' }))
		$ra = if ($Resume) { @('--resume', $Resume) } else { @() }
		& "$env:USERPROFILE\.grok\bin\grok.exe" --prompt-file $PromptFile @ga @ra 2>$errLog |
			Out-File "$out.json" -Encoding utf8
		if ($Resume -and (Select-String $errLog -Pattern 'input_too_large|context window' -Quiet)) {
			$handoff = Join-Path $dir "$Name.handoff.txt"
			@"
You are taking over from a previous agent ($Name) whose context window filled up. Rebuild context cheaply: read AGENTS.md, then the
PROGRESS.md / REPORT.md files for your area under verification/, git log -15 --stat, and the notes files your task names.
Do not redo finished work; continue from where the progress files end. Your task:

$prompt
"@ | Out-File $handoff -Encoding utf8
			& "$env:USERPROFILE\.grok\bin\grok.exe" --prompt-file $handoff @ga 2>>$errLog | Out-File "$out.json" -Encoding utf8
			try {
				$new = (Get-Content "$out.json" -Raw | ConvertFrom-Json).sessionId
				if ($new) { $map[$Resume] = $new; $map | ConvertTo-Json | Out-File $mapFile -Encoding utf8; "session $Resume full -> $new" | Add-Content $errLog }
			} catch { "handoff run produced no session id" | Add-Content $errLog }
		}
		try { (Get-Content "$out.json" -Raw | ConvertFrom-Json).text | Out-File $out -Encoding utf8 } catch { Copy-Item "$out.json" $out }
	}
	'codex' {
		$cx = @()
		if ($Model) { $cx += @('-m', $Model) }
		if ($Effort) { $cx += @('-c', "model_reasoning_effort=`"$Effort`"") }
		if ($Resume) {
			$prompt | codex exec resume $Resume --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox @cx - 2>$errLog | Out-File $out -Encoding utf8
		} else {
			$prompt | codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -C $root @cx - 2>$errLog |
				Out-File $out -Encoding utf8
		}
	}
	'agy' {
		agy -p $prompt --dangerously-skip-permissions --output-format text 2>$errLog | Out-File $out -Encoding utf8
	}
}
"DONE $LASTEXITCODE $(Get-Date -Format HH:mm)" | Out-File $status -Encoding ascii
