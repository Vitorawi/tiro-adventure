# Exporta o jogo para Web (PWA), igual ao deploy:
#   versão publicada (prod) em build/web/  e  versão dev em build/web/dev/
# Uso: powershell -File tools/export_web.ps1 [-Channel both|prod|dev]
# O executável do Godot vem de $env:GODOT_BIN ou do caminho padrão abaixo.
# Ver docs/DEPLOY.md ("Versão dev").

param(
    [ValidateSet("both", "prod", "dev")]
    [string]$Channel = "both"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$GameDir = Join-Path $Root "game"
$OutDir = Join-Path $Root "build\web"
$VersionFile = Join-Path $GameDir "data\version.json"
$Utf8 = New-Object Text.UTF8Encoding $false

$Godot = $env:GODOT_BIN
if (-not $Godot) {
    $Godot = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
}
if (-not (Test-Path $Godot)) {
    throw "Godot nao encontrado em '$Godot'. Defina `$env:GODOT_BIN com o caminho do Godot_*_console.exe."
}

function Edit-Text([string]$Path, [string]$Old, [string]$New) {
    $text = [IO.File]::ReadAllText($Path)
    if (-not $text.Contains($Old)) { throw "Texto '$Old' nao encontrado em $Path" }
    [IO.File]::WriteAllText($Path, $text.Replace($Old, $New), $Utf8)
}

function Export-Channel([string]$Name, [string]$Dir) {
    Write-Host "Exportando canal '$Name' em $Dir..."
    [IO.File]::WriteAllText($VersionFile, "{ `"version`": `"local`", `"date`": `"$(Get-Date -Format 'dd/MM HH:mm')`", `"channel`": `"$Name`" }`n", $Utf8)
    New-Item -ItemType Directory -Force $Dir | Out-Null
    & $Godot --headless --path $GameDir --export-release "Web" (Join-Path $Dir "index.html")
    if ($LASTEXITCODE -ne 0) { throw "Falha no export (codigo $LASTEXITCODE)." }
    # Mesmo ajuste do deploy: o service worker instala a versao nova ignorando o cache HTTP.
    Edit-Text (Join-Path $Dir "index.service.worker.js") "cache.addAll(CACHED_FILES)" "cache.addAll(CACHED_FILES.map((f) => new Request(f, { cache: 'reload' })))"
    if ($Name -eq "dev") {
        # Mesmo ajuste do deploy: cache e nome proprios da versao dev.
        Edit-Text (Join-Path $Dir "index.service.worker.js") "const CACHE_PREFIX = 'Tiro Adventure-sw-cache-'" "const CACHE_PREFIX = 'Tiro Adventure DEV-sw-cache-'"
        Edit-Text (Join-Path $Dir "index.manifest.json") '"name":"Tiro Adventure"' '"name":"Tiro DEV"'
        Edit-Text (Join-Path $Dir "index.html") "<title>Tiro Adventure</title>" "<title>Tiro DEV</title>"
    }
}

$ResolvedOutput = [IO.Path]::GetFullPath($OutDir)
$ExpectedOutput = [IO.Path]::GetFullPath((Join-Path $Root "build\web"))
if ($ResolvedOutput -ne $ExpectedOutput) { throw "Saida fora de build/web" }
if (Test-Path $ResolvedOutput) { Remove-Item -LiteralPath $ResolvedOutput -Recurse -Force }
New-Item -ItemType Directory -Force $OutDir | Out-Null

Write-Host "Importando assets..."
& $Godot --headless --path $GameDir --import
if ($LASTEXITCODE -ne 0) { throw "Falha no import (codigo $LASTEXITCODE)." }

$OriginalVersion = [IO.File]::ReadAllText($VersionFile)
try {
    switch ($Channel) {
        "prod" { Export-Channel "prod" $OutDir }
        "dev" { Export-Channel "dev" $OutDir }
        default {
            Export-Channel "prod" $OutDir
            Export-Channel "dev" (Join-Path $OutDir "dev")
        }
    }
} finally {
    # version.json versionado continua como "local/dev" (o deploy grava o seu).
    [IO.File]::WriteAllText($VersionFile, $OriginalVersion, $Utf8)
}

Write-Host "Build pronto em $OutDir"
if ($Channel -eq "both") { Write-Host "Versao dev em $OutDir\dev (http://localhost:8000/dev/)" }
