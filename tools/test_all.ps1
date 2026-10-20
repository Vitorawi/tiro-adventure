# Roda a suíte de testes headless (sem parâmetros: todos, na ordem abaixo, parando na primeira falha).
#   powershell -ExecutionPolicy Bypass -File tools\test_all.ps1
#   powershell -ExecutionPolicy Bypass -File tools\test_all.ps1 -Only "hud_test,texts_test"   # só esses, nesta ordem
#   powershell -ExecutionPolicy Bypass -File tools\test_all.ps1 -Skip "progression_test"      # pula esses
#   powershell -ExecutionPolicy Bypass -File tools\test_all.ps1 -Fast                         # sem progression_test, economy_sim_test e Python
#   powershell -ExecutionPolicy Bypass -File tools\test_all.ps1 -KeepGoing                    # não para na falha (linha de base)
# Cada teste imprime a duração; no fim, o total e build/test_logs/last_run.csv (teste, segundos, resultado).
# Nomes: o arquivo sem .gd; "dev_tools_test_prod" = dev_tools_test -- --prod; os autotestes Python
# são "economy_audit_selftest" e "economy_compare_selftest". Teste novo entra UMA vez, no fim de $Suite.
param(
  [string]$Only = "",
  [string]$Skip = "",
  [switch]$Fast,
  [switch]$KeepGoing
)
$godotTask = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
# No PowerShell 5.1, redirecionar o stderr de um .exe vira ErrorRecord (e "Stop" abortaria por avisos
# inofensivos como "RIDs leaked"). Por isso o modo é "Continue" e só falhas reais derrubam a suíte.
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Ordem da suíte. "?" no começo = pula em silêncio se o arquivo não existir (como antes).
$Suite = @(
  "?farm_test", "?progression_test", "?dev_tools_test", "?tasks_test", "?content_test", "?navigation_test",
  "?manual_test", "?world_life_test", "?animals_test", "?nature_test", "?worlds_test", "?intro_test",
  "?npc_lines_test", "?saves_test", "?storage_test", "?loot_test", "?welcome_test", "?onboarding_test",
  "?wishes_test", "?flavors_test", "?finds_test", "?park_test",
  "walks_test", "petshop_test", "friends_test", "tricks_test", "treasure_test", "ui_base_test",
  "ui_style_test", "sheet_test", "hud_test", "world_view_test", "world_selector_test", "balloon_test",
  "tray_test", "station_tray_test", "pet_care_test", "lists_test", "market_test", "ready_badges_test",
  "texts_test", "festa_test", "economy_sim_test", "economy_transactions_test", "silo_test", "fridge_test",
  "warehouse_test", "chest_test", "coins_test", "garden_test", "nature_routes_test", "queue_test",
  "expansion_test", "projects_test", "bench_test", "garden_picnic_test", "journey_test",
  "animals_chain_test", "customers_test", "bond_test", "products_test", "pending_gifts_test",
  "absence_test", "walk_return_test", "walk_return_ui_test", "dev_tools_test_prod",
  "economy_audit_selftest", "economy_compare_selftest", "growth_test", "pillars_test", "growth_visual_test", "growth_ui_test", "hud_growth_test", "ceremony_test", "growth_foods_test", "keys_test", "growth_story_test", "album_test", "house_test", "album_secrets_test", "brush_taste_test", "personality_test", "silk_test"
)
$python = @("economy_audit_selftest", "economy_compare_selftest")
$slow = @("progression_test", "economy_sim_test") + $python

function Split-Names([string]$text) { return @($text -split "," | ForEach-Object { $_.Trim() -replace "\.gd$", "" } | Where-Object { $_ }) }
$all = @($Suite | ForEach-Object { $_.TrimStart("?") })
$optional = @($Suite | Where-Object { $_.StartsWith("?") } | ForEach-Object { $_.TrimStart("?") })

if ($Only) {
  $plan = Split-Names $Only
  $unknown = @($plan | Where-Object { $all -notcontains $_ -and !(Test-Path "game/tests/$_.gd") })
  if ($unknown.Count -gt 0) { throw "Teste desconhecido: $($unknown -join ', ')" }
} else {
  $plan = $all
}
$skipped = @()
if ($Skip) { $skipped += Split-Names $Skip }
if ($Fast) { $skipped += $slow }
if ($skipped.Count -gt 0) {
  $cut = @($plan | Where-Object { $skipped -contains $_ })
  Write-Host "Pulando ($($cut.Count)): $(if ($cut.Count) { $cut -join ', ' } else { '(nenhum da lista)' })"
  $plan = @($plan | Where-Object { $skipped -notcontains $_ })
}
Write-Host "Rodando $($plan.Count) teste(s)."

function Invoke-Test([string]$name) {
  if ($python -contains $name) {
    if (!(Get-Command py -ErrorAction SilentlyContinue)) { return "SEM_PYTHON" }
    py -X utf8 -I "tools/$name.py" 2>&1 | ForEach-Object { Write-Host "$_" }
    if ($LASTEXITCODE -ne 0) { throw "$name falhou" }
    return "PASS"
  }
  $file = $name
  $extra = @()
  if ($name -eq "dev_tools_test_prod") { $file = "dev_tools_test"; $extra = @("--", "--prod") }
  if (($optional -contains $name) -and !(Test-Path "game/tests/$file.gd")) { return "AUSENTE" }
  $output = & $godotTask --headless --path game -s "res://tests/$file.gd" @extra 2>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
  $output | ForEach-Object { Write-Host $_ }
  if ($output -match "SCRIPT ERROR:|^ERROR:(?!.*RID)|Parse Error") { throw "$name emitiu erros" }
  if ($code -ne 0) { throw "$name falhou" }
  return "PASS"
}

New-Item -ItemType Directory -Force "build/test_logs" | Out-Null
$csv = "build/test_logs/last_run.csv"
$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add("teste,segundos,resultado")
$total = [System.Diagnostics.Stopwatch]::StartNew()
$failed = @()
$stop = $null
foreach ($name in $plan) {
  $watch = [System.Diagnostics.Stopwatch]::StartNew()
  $result = "PASS"
  try { $result = Invoke-Test $name } catch { $result = "FAIL"; $failed += $name; if (-not $KeepGoing) { $stop = $_ } }
  $seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 1)
  $rows.Add(("{0},{1},{2}" -f $name, $seconds.ToString([System.Globalization.CultureInfo]::InvariantCulture), $result))
  [System.IO.File]::WriteAllLines("$root/$csv", $rows, [System.Text.UTF8Encoding]::new($false))
  Write-Host ("== {0}: {1} ({2} s)" -f $name, $result, $seconds)
  if ($stop) { break }
}
Write-Host ("== Total: {0} min; {1} falha(s){2}. Tempos em {3}" -f [Math]::Round($total.Elapsed.TotalMinutes, 1), $failed.Count, $(if ($failed.Count) { ": " + ($failed -join ", ") } else { "" }), $csv)
if ($stop) { throw $stop }
if ($failed.Count -gt 0) { exit 1 }
