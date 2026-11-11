# Abre o jogo com as duas animações da Animaref em ciclo e save isolado.
param([switch]$Verify, [switch]$Shots)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
$previousTag = $env:TIRO_TEST_TAG
try {
    $env:TIRO_TEST_TAG = 'animaref_preview'
    $arguments = @('--path', "$projectRoot/game", '--resolution', '360x780', '-s', 'res://tests/animaref_preview.gd')
    if ($Verify) { $arguments += '--headless' }
    $arguments += @('--', '--dev')
    if ($Verify) { $arguments += '--verify' }
    if ($Shots) { $arguments += '--shots' }
    & $godot @arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot encerrou com código $LASTEXITCODE" }
} finally {
    $env:TIRO_TEST_TAG = $previousTag
}
