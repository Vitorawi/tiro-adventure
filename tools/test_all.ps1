$ErrorActionPreference = "Stop"
$godotTask = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
foreach ($testTask in @("farm_test", "progression_test", "dev_tools_test", "tasks_test", "content_test", "navigation_test", "manual_test", "world_life_test", "animals_test", "nature_test", "worlds_test", "intro_test", "npc_lines_test", "saves_test")) {
  if (!(Test-Path "game/tests/$testTask.gd")) { continue }
  $testOutput = & $godotTask --headless --path game -s "res://tests/$testTask.gd" 2>&1
  $testOutput | ForEach-Object { Write-Host $_ }
  if ($testOutput -match "SCRIPT ERROR:|^ERROR:") { throw "$testTask emitiu erros" }
  if ($LASTEXITCODE -ne 0) { throw "$testTask falhou" }
}
& $godotTask --headless --path game -s res://tests/dev_tools_test.gd -- --prod
if ($LASTEXITCODE -ne 0) { throw "DEV prod falhou" }
