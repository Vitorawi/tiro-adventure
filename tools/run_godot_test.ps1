# Roda um teste headless do Godot com tempo máximo (mata o processo se travar) e guarda o log.
#   powershell -ExecutionPolicy Bypass -File tools\run_godot_test.ps1 economy_sim_test [-TimeoutMin 10] [-Log build\economy\etapa_01\x.log]
# Útil quando o script pode travar (o Godot não encerra sozinho se o script não chamar quit()).
param(
  [Parameter(Mandatory = $true)][string]$Test,
  [int]$TimeoutMin = 10,
  [string]$Log = ""
)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
if (-not $Log) { $Log = "build/economy/etapa_01/$Test.log" }
New-Item -ItemType Directory -Force (Split-Path -Parent "$root/$Log") | Out-Null
$p = Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", "game", "-s", "res://tests/$Test.gd") -RedirectStandardOutput "$root/$Log" -RedirectStandardError "$root/$Log.err" -PassThru -WindowStyle Hidden
if (-not $p.WaitForExit($TimeoutMin * 60 * 1000)) {
  Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $p.Id } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Write-Host "TEMPO ESGOTADO ($TimeoutMin min): $Test"
  exit 124
}
$text = [System.IO.File]::ReadAllText("$root/$Log", [System.Text.Encoding]::UTF8)
$errors = [System.IO.File]::ReadAllText("$root/$Log.err", [System.Text.Encoding]::UTF8)
Write-Host $text
if ($errors -match "SCRIPT ERROR|Parse Error") { Write-Host $errors }
exit $p.ExitCode
