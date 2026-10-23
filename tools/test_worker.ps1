# Processo filho do circuito: cada teste recebe uma pasta de save própria.
param([string]$Test, [string]$Tag)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$env:TIRO_TEST_TAG = $Tag
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if ($Test -eq 'economy_quick') {
  $outRoot = "build/economy/cuidado07_$Tag"
  & powershell -NoProfile -ExecutionPolicy Bypass -File tools/economy_simulate.ps1 -Quick -OutRoot $outRoot
  $simCode = $LASTEXITCODE
  $summary = Get-ChildItem $outRoot -Recurse -Filter summary.json -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $summary) { Write-Error 'Quick sem summary.json'; exit 1 }
  if ($summary) {
    $data = Get-Content $summary.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($data.status -ne 'complete') { Write-Error ('Quick incompleto: ' + $data.status); exit 1 }
    Write-Host ('Dias por fase (SIMULADOS): ' + ($data.growth_days | ConvertTo-Json -Compress -Depth 8))
  }
  foreach ($engineLog in @(Get-ChildItem $outRoot -Recurse -File | Where-Object { $_.Name -in @('godot.log','godot.log.err') })) {
    $engineText = [IO.File]::ReadAllText($engineLog.FullName)
    if ($engineText -match 'SCRIPT ERROR:|(?m)^ERROR:|Parse Error') {
      Write-Error ("Quick emitiu erro no motor: " + $engineLog.FullName)
      Write-Host (($engineText -split "`n" | Select-Object -First 40) -join "`n")
      exit 1
    }
  }
  exit $simCode
} elseif ($Test -in @('economy_audit_selftest', 'economy_compare_selftest','test_circuit_selftest')) {
  & py -X utf8 -I "tools/$Test.py"
} elseif ($Test -eq 'scripts_check') {
  & $godot --headless --path game --quit-after 2
} elseif ($Test -eq 'import') {
  & $godot --headless --path game --import
} else {
  $file = $Test
  $extra = @()
  if ($Test -eq 'dev_tools_test_prod') { $file = 'dev_tools_test'; $extra = @('--', '--prod') }
  & $godot --headless --path game -s "res://tests/$file.gd" @extra
}
exit $LASTEXITCODE
