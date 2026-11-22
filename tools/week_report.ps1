# Resume as execucoes do modo "-Until week" (F05): capitulos, Dentinhos, sessao, esperas.
#   powershell -ExecutionPolicy Bypass -File tools\week_report.ps1 -Dir build/economy/f05_antes
param([string]$Dir = "build/economy/f05_depois")
$root = Split-Path -Parent $PSScriptRoot
foreach ($p in "muito", "regular", "perde_dia") {
  foreach ($f in Get-ChildItem "$root/$Dir/${p}_s*/week.json" -ErrorAction SilentlyContinue | Sort-Object FullName) {
    $d = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $c = $d.chapters
    $days = (2..10 | ForEach-Object { $c."$_".day }) -join ","
    $teeth = if ($d.phases.teething) { $d.phases.teething.day } else { "-" }
    $c10 = $c."10".day; $c11 = $c."11".day
    $sess = (2..10 | ForEach-Object { $c."$_".session_min } | Measure-Object -Sum).Sum
    "{0,-9} {1,-12} cap2-10 fecha no dia {2} (dias: {3}) | Dentinhos dia {4} | 1a sessao {5} min | sessao cap2-10 {6:N0} min | maior espera {7} min | caixa min {8} | patinhas {9} | erros {10}" -f $d.profile, (Split-Path -Leaf (Split-Path $f.FullName)), $c10, $days, $teeth, $d.first_session_min, $sess, $d.max_wait_min, $d.min_coins, $d.paws, $d.errors.Count
  }
}
