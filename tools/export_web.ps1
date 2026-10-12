# Exporta o jogo para Web (PWA) em build/web/.
# Uso: powershell -File tools/export_web.ps1
# O executável do Godot vem de $env:GODOT_BIN ou do caminho padrão abaixo.

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$GameDir = Join-Path $Root "game"
$OutDir = Join-Path $Root "build\web"

$Godot = $env:GODOT_BIN
if (-not $Godot) {
    $Godot = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
}
if (-not (Test-Path $Godot)) {
    throw "Godot nao encontrado em '$Godot'. Defina `$env:GODOT_BIN com o caminho do Godot_*_console.exe."
}

if (Test-Path $OutDir) { Remove-Item -Recurse -Force $OutDir }
New-Item -ItemType Directory -Force $OutDir | Out-Null

Write-Host "Importando assets..."
& $Godot --headless --path $GameDir --import
if ($LASTEXITCODE -ne 0) { throw "Falha no import (codigo $LASTEXITCODE)." }

Write-Host "Exportando preset Web..."
& $Godot --headless --path $GameDir --export-release "Web" (Join-Path $OutDir "index.html")
if ($LASTEXITCODE -ne 0) { throw "Falha no export (codigo $LASTEXITCODE)." }

Write-Host "Build pronto em $OutDir"
