# Offline verification gate. Exit 0 = pass. Studio checks are done separately via MCP (see AGENTS.md).
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:Path = "$env:USERPROFILE\.rokit\bin;" + $env:Path
$fail = @()

function Step($name, [scriptblock]$cmd) {
	$out = & $cmd 2>&1 | Out-String
	if ($LASTEXITCODE -ne 0) {
		$script:fail += $name
		Write-Output "FAIL  $name`n$($out.Trim())`n"
	} else {
		Write-Output "PASS  $name"
	}
}

Step 'stylua --check' { stylua --check src }
Step 'selene' { selene src }
Step 'rojo build' { rojo build default.project.json -o "$env:TEMP\twentyhours-verify.rbxl" }

if (Test-Path blueprint/level1.json) {
	Step 'blueprint geometry' { python tools/verify_blueprint.py }
}
if (Test-Path tools/validate_blueprint.luau) {
	Step 'blueprint schema' { lune run tools/validate_blueprint.luau }
}
if (Test-Path tests) {
	Get-ChildItem tests -Filter *.spec.luau | ForEach-Object {
		$f = $_.FullName
		Step "test $($_.Name)" { lune run $f }
	}
}

if (Test-Path places/props_preview.rbxm) {
	Step 'prop geometry (z-fight, slivers, floating)' { lune run tools/check_geometry.luau places/props_preview.rbxm none }
}
if ((Test-Path places/build.rbxm) -and (Test-Path blueprint/level1.json) -and ((Get-Item places/build.rbxm).LastWriteTime -gt (Get-Item blueprint/level1.json).LastWriteTime)) {
	Step 'building geometry (intersections, gaps, blocked doors)' { lune run tools/check_geometry.luau places/build.rbxm blueprint }
}
if (Test-Path art/materials/materials.spec.luau) {
	Step 'material spec' { lune run art/materials/materials.spec.luau }
}
if (Test-Path tools/check_materials.luau) {
	Step 'material template' { lune run tools/check_materials.luau }
}
if (Test-Path art/materials/assets.json) {
	Step 'PBR maps uploaded (disk == Roblox asset)' { python tools/check_uploads.py }
}
if ((Test-Path tools/check_perf.luau) -and (Test-Path places/build.rbxm)) {
	Step 'perf budgets and walkable surfaces' { lune run tools/check_perf.luau places/build.rbxm blueprint }
}
if (Test-Path tools/globalTypes.d.luau) {
	rojo sourcemap default.project.json -o sourcemap.json 2>&1 | Out-Null
	Step 'luau-lsp analyze' {
		luau-lsp analyze --definitions=tools/globalTypes.d.luau --sourcemap=sourcemap.json --no-strict-dm-types src
	}
}

if ($fail.Count) {
	Write-Output "`nVERIFY FAILED: $($fail -join ', ')"
	exit 1
}
Write-Output "`nVERIFY PASSED"
exit 0
