# Start a command detached from the calling session (via WMI Win32_Process.Create), so it keeps running when the Claude Code
# session that launched it exits. Output goes to .grok-loop/detached/<Name>.log.
# Usage: pwsh tools/detach.ps1 -Name qa-loop -Command "pwsh -NoProfile -File tools/qa-loop.ps1 ..."
param(
	[Parameter(Mandatory)] [string]$Name,
	[Parameter(Mandatory)] [string]$Command
)
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root '.grok-loop/detached'
New-Item -ItemType Directory -Force $dir | Out-Null
$log = Join-Path $dir "$Name.log"
$wrapped = "Set-Location '$root'; `$env:Path = `"`$env:USERPROFILE\.rokit\bin;`" + `$env:Path; & { $Command } *>> '$log'"
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapped))
$pwsh = (Get-Command pwsh).Source
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
	CommandLine = "`"$pwsh`" -NoProfile -WindowStyle Hidden -EncodedCommand $encoded"
	CurrentDirectory = $root
}
if ($r.ReturnValue -ne 0) { throw "Win32_Process.Create failed: $($r.ReturnValue)" }
"$(Get-Date -Format s) started $Name pid=$($r.ProcessId): $Command" | Add-Content (Join-Path $dir 'launched.log')
Write-Output "$Name pid=$($r.ProcessId)"
