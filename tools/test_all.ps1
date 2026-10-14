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
foreach ($testTask in @("farm_test", "progression_test", "dev_tools_test", "tasks_test", "content_test", "navigation_test", "manual_test", "world_life_test", "animals_test", "nature_test", "worlds_test", "intro_test", "npc_lines_test", "saves_test", "storage_test", "loot_test", "welcome_test", "onboarding_test", "wishes_test")) {
  if (!(Test-Path "game/tests/$testTask.gd")) { continue }
  Invoke-Test $testTask @()
}
Invoke-Test "dev_tools_test" @("--", "--prod")
