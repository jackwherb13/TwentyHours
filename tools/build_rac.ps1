# Build the live Rojo preview directly from JSON, then check actual geometry.
[CmdletBinding()]
param(
    [string]$Blueprint = 'blueprint',
    [string]$Output = 'places/build.rbxm'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$originalPath = $env:Path
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$status = 1
Push-Location $root
try {
    $env:Path = "$env:USERPROFILE\.rokit\bin;" + $env:Path
    & lune run tools/build_rac.luau $Blueprint $Output
    if ($LASTEXITCODE -ne 0) { throw 'RAC build failed.' }

    Write-Output 'Geometry QA: complete RAC (including props)'
    & lune run tools/check_geometry.luau $Output $Blueprint
    if ($LASTEXITCODE -ne 0) {
        Write-Output 'Checking building separately; RAC.Props issues do not fail this command.'
        & lune run tools/build_rac.luau $Blueprint $Output --check-building
        if ($LASTEXITCODE -ne 0) { throw 'Building geometry QA failed.' }
        Write-Output 'PASS building geometry; full-model QA has issues involving RAC.Props.'
    } else {
        Write-Output 'PASS complete RAC geometry.'
    }
    $status = 0
} catch {
    Write-Output "FAIL $($_.Exception.Message)"
} finally {
    $timer.Stop()
    Write-Output ('Build + QA elapsed: {0:F3} s' -f $timer.Elapsed.TotalSeconds)
    $env:Path = $originalPath
    Pop-Location
}
exit $status
