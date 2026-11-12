# Tour de capturas da pesca (etapa 10 do plano docs/plans/pesca): junta os roteiros de captura que cada etapa
# já tem (lagoa/painel/força/mordida/minigame/resultado, tutorial, banca Comprar, caderno de peixes, varas 2 e 3)
# e roda cada um nas três resoluções, SEM --headless (precisa de janela). Cada roteiro mede e imprime FAIL.
#   powershell -ExecutionPolicy Bypass -File tools\pesca_tour.ps1
# PNGs em build/screenshots/pesca_tour/<roteiro>_<largura>/ . Sai com código 1 se algum roteiro falhar.
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
$scripts = @("fishing_shots", "fishing_tutorial_shots", "shop_shots", "fishing_book_shots", "fishing_rod2_shots", "fishing_rod3_shots")
$sizes = @("360x780", "390x844", "412x915")
$failed = 0
foreach ($name in $scripts) {
  foreach ($size in $sizes) {
    $out = "pesca_tour/${name}_$($size.Split('x')[0])"
    Write-Host "== $name $size"
    $log = & $godot --path game --resolution $size -s "res://tests/$name.gd" -- "--out=$out" 2>&1 | Out-String
    $bad = ($log -match "FAIL") -or ($LASTEXITCODE -ne 0)
    if ($bad) { $failed++; Write-Host "   FALHOU: $name $size"; ($log -split "`n" | Select-String "FAIL") | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" } }
  }
}
Write-Host "PESCA TOUR: $(if ($failed -eq 0) { 'OK' } else { "$failed execução(ões) com FAIL" })"
exit $(if ($failed -eq 0) { 0 } else { 1 })
