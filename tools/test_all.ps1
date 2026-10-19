$godotTask = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
# No PowerShell 5.1, redirecionar o stderr de um .exe vira ErrorRecord (e "Stop" abortaria por avisos
# inofensivos como "RIDs leaked"). Por isso o modo é "Continue" e só falhas reais derrubam a suíte.
$ErrorActionPreference = "Continue"
function Invoke-Test([string]$name, [string[]]$extra) {
  $output = & $godotTask --headless --path game -s "res://tests/$name.gd" @extra 2>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
  $output | ForEach-Object { Write-Host $_ }
  if ($output -match "SCRIPT ERROR:|^ERROR:(?!.*RID)|Parse Error") { throw "$name emitiu erros" }
  if ($code -ne 0) { throw "$name falhou" }
}
foreach ($testTask in @("farm_test", "progression_test", "dev_tools_test", "tasks_test", "content_test", "navigation_test", "manual_test", "world_life_test", "animals_test", "nature_test", "worlds_test", "intro_test", "npc_lines_test", "saves_test", "storage_test", "loot_test", "welcome_test", "onboarding_test", "wishes_test", "flavors_test", "finds_test", "park_test")) {
  if (!(Test-Path "game/tests/$testTask.gd")) { continue }
  Invoke-Test $testTask @()
}
Invoke-Test "walks_test" @()
Invoke-Test "petshop_test" @()
Invoke-Test "friends_test" @()
Invoke-Test "tricks_test" @()
Invoke-Test "treasure_test" @()
Invoke-Test "ui_base_test" @()
Invoke-Test "ui_style_test" @()
Invoke-Test "sheet_test" @()
Invoke-Test "hud_test" @()
Invoke-Test "world_view_test" @()
Invoke-Test "world_selector_test" @()
Invoke-Test "balloon_test" @()
Invoke-Test "tray_test" @()
Invoke-Test "station_tray_test" @()
Invoke-Test "pet_care_test" @()
Invoke-Test "lists_test" @()
Invoke-Test "market_test" @()
Invoke-Test "ready_badges_test" @()
Invoke-Test "texts_test" @()
Invoke-Test "festa_test" @()
Invoke-Test "economy_sim_test" @()
Invoke-Test "economy_transactions_test" @()
Invoke-Test "silo_test" @()
Invoke-Test "fridge_test" @()
Invoke-Test "warehouse_test" @()
Invoke-Test "chest_test" @()
Invoke-Test "coins_test" @()
Invoke-Test "garden_test" @()
Invoke-Test "nature_routes_test" @()
Invoke-Test "queue_test" @()
Invoke-Test "expansion_test" @()
Invoke-Test "projects_test" @()
Invoke-Test "bench_test" @()
Invoke-Test "garden_picnic_test" @()
Invoke-Test "journey_test" @()
Invoke-Test "animals_chain_test" @()
Invoke-Test "customers_test" @()
Invoke-Test "bond_test" @()
Invoke-Test "products_test" @()
Invoke-Test "pending_gifts_test" @()
Invoke-Test "absence_test" @()
Invoke-Test "walk_return_test" @()
Invoke-Test "walk_return_ui_test" @()
Invoke-Test "dev_tools_test" @("--", "--prod")
# Auditor de economia (Python): dados reais passam, cópia quebrada falha
if (Get-Command py -ErrorAction SilentlyContinue) {
  py -X utf8 -I tools/economy_audit_selftest.py
  if ($LASTEXITCODE -ne 0) { throw "economy_audit_selftest falhou" }
  py -X utf8 -I tools/economy_compare_selftest.py
  if ($LASTEXITCODE -ne 0) { throw "economy_compare_selftest falhou" }
}
