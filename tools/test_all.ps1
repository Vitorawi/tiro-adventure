# Atalho legado: portão de jogo e depois campanha. Para filtros, use tools/test.ps1.
param([switch]$KeepGoing)
& "$PSScriptRoot/test.ps1" -Level portao -KeepGoing:$KeepGoing
$gateCode = $LASTEXITCODE
if ($gateCode -and -not $KeepGoing) { exit $gateCode }
& "$PSScriptRoot/test.ps1" -Level campanha -KeepGoing:$KeepGoing
if ($gateCode -or $LASTEXITCODE) { exit 1 }
