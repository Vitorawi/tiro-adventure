$ErrorActionPreference = "Stop"
$godotTask = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
foreach ($testTask in @("farm_test", "progression_test", "dev_tools_test", "tasks_test", "content_test")) {
  if (!(Test-Path "game/tests/$testTask.gd")) { continue }
  & $godotTask --headless --path game -s "res://tests/$testTask.gd"
  if ($LASTEXITCODE -ne 0) { throw "$testTask falhou" }
}
& $godotTask --headless --path game -s res://tests/dev_tools_test.gd -- --prod
if ($LASTEXITCODE -ne 0) { throw "DEV prod falhou" }
