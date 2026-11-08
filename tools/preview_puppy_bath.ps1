param([switch]$Shots, [switch]$Verify)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
$previousTag = $env:TIRO_TEST_TAG
try {
    $env:TIRO_TEST_TAG = 'puppy_bath_preview'
    $arguments = @('--path', "$projectRoot/game", '--resolution', '360x780', '-s', 'res://tests/puppy_bath_test.gd')
    if ($Verify) { $arguments += '--headless' }
    $arguments += @('--', '--dev')
    if ($Shots) { $arguments += '--shots' }
    if (-not $Verify -and -not $Shots) { $arguments += '--preview' }
    & $godot @arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot exit code $LASTEXITCODE" }
} finally { $env:TIRO_TEST_TAG = $previousTag }
