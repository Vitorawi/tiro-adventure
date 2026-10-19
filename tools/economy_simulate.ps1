# Invocador da simulação de economia (etapa 01 do plano docs/plans/economia).
#
#   powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Profile reference -Seed 1 -Days 30
#   powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Profile reference -Seed 1..10 -Until campaign -Days 120
#
# Cada execução usa o GameState REAL com relógio injetado (game/tests/economy_simulation.gd), sem tocar
# no save pessoal. Saída em build/economy/etapa_01/<perfil>_s<semente>/ (summary.json + ledger.jsonl).
# Um processo por semente; -Parallel roda vários ao mesmo tempo. O tempo máximo por execução mata o Godot.
param(
  [string]$Profile = "reference",
  [string]$Seed = "1",
  [int]$Days = 30,
  [ValidateSet("days", "campaign", "projects")][string]$Until = "days",
  [ValidateSet("normal", "worst")][string]$Rare = "normal",
  [ValidateSet("full", "compact", "off")][string]$Ledger = "compact",
  [ValidateSet("none", "session")][string]$Reload = "none",
  [string]$OutRoot = "build/economy/etapa_01",
  [int]$StallDays = 21,
  [int]$StallActiveMin = 600,
  [int]$TimeoutMin = 40,
  [int]$Parallel = 1,
  [string]$Tag = ""
)
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $godot)) { throw "Godot não encontrado: $godot (defina GODOT_BIN)" }

# "1..10", "1,2,3" ou "4"
$seeds = @()
foreach ($part in $Seed -split ",") {
  if ($part -match "^(\d+)\.\.(\d+)$") { $seeds += [int]$Matches[1]..[int]$Matches[2] } else { $seeds += [int]$part }
}

function Start-Sim([int]$s) {
  $name = if ($Tag) { "${Profile}_s${s}_$Tag" } else { "${Profile}_s${s}" }
  $out = "$OutRoot/$name"
  New-Item -ItemType Directory -Force "$root/$out" | Out-Null
  $log = "$root/$out/godot.log"
  $arguments = @("--headless", "--path", "game", "-s", "res://tests/economy_simulation.gd", "--", "--profile=$Profile", "--seed=$s", "--days=$Days", "--until=$Until", "--rare=$Rare", "--ledger=$Ledger", "--reload=$Reload", "--stall-days=$StallDays", "--stall-active-min=$StallActiveMin", "--out=$out")
  $p = Start-Process -FilePath $godot -ArgumentList $arguments -WorkingDirectory $root -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru -WindowStyle Hidden
  return [pscustomobject]@{ Seed = $s; Name = $name; Process = $p; Log = $log; Started = Get-Date }
}

function Finish-Sim($job) {
  if (-not $job.Process.WaitForExit($TimeoutMin * 60 * 1000)) {
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $job.Process.Id } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Stop-Process -Id $job.Process.Id -Force -ErrorAction SilentlyContinue
    Write-Host "TEMPO ESGOTADO ($TimeoutMin min): $($job.Name)"
    return 124
  }
  $line = (Get-Content $job.Log -Encoding UTF8 -ErrorAction SilentlyContinue | Where-Object { $_ -like "ECONOMY SIM:*" }) -join "`n"
  Write-Host $(if ($line) { $line } else { "SEM RESULTADO: $($job.Name) (veja $($job.Log))" })
  return $job.Process.ExitCode
}

$worst = 0
$queue = [System.Collections.Generic.Queue[int]]::new()
$seeds | ForEach-Object { $queue.Enqueue($_) }
$running = @()
while ($queue.Count -gt 0 -or $running.Count -gt 0) {
  while ($queue.Count -gt 0 -and $running.Count -lt [Math]::Max(1, $Parallel)) { $running += Start-Sim $queue.Dequeue() }
  $job = $running[0]
  $code = Finish-Sim $job
  if ($code -ne 0 -and $code -gt $worst) { $worst = $code }
  $running = @($running | Select-Object -Skip 1)
}
exit $worst
