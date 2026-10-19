# Roda o conjunto de perfis e sementes da 04_SIMULACAO_E_ACEITE.md (seção B) com a economia ATUAL do jogo.
#   Referência e Leve: sementes 1..10; Afetivo, Comercial, Recuperação e Ativo: 1..3; mais o pior caso de raro
#   (referência 1..3 com -Rare worst). Saída em build/economy/etapa_01/<perfil>_s<semente>_<Tag>/.
#   powershell -ExecutionPolicy Bypass -File tools\economy_baseline.ps1 [-Tag base] [-Parallel 3] [-Quick]
# O relatório sai de: py -X utf8 -I tools\economy_compare.py --in build\economy\etapa_01 --tag base
param(
  [string]$Tag = "base",
  [int]$Parallel = 3,
  [int]$Days = 150,
  [string]$OutRoot = "build/economy/etapa_01",
  [switch]$Quick
)
$script = Join-Path $PSScriptRoot "economy_simulate.ps1"
$plan = @(
  @{ Profile = "reference"; Seeds = $(if ($Quick) { "1..2" } else { "1..10" }); Rare = "normal" },
  @{ Profile = "light"; Seeds = $(if ($Quick) { "1..2" } else { "1..10" }); Rare = "normal" },
  @{ Profile = "active"; Seeds = $(if ($Quick) { "1" } else { "1..3" }); Rare = "normal" },
  @{ Profile = "affective"; Seeds = $(if ($Quick) { "1" } else { "1..3" }); Rare = "normal" },
  @{ Profile = "commercial"; Seeds = $(if ($Quick) { "1" } else { "1..3" }); Rare = "normal" },
  @{ Profile = "recovery"; Seeds = $(if ($Quick) { "1" } else { "1..3" }); Rare = "normal" }
)
if (-not $Quick) { $plan += @{ Profile = "reference"; Seeds = "1..3"; Rare = "worst"; Suffix = "_raro0" } }
$worst = 0
foreach ($entry in $plan) {
  $suffix = if ($entry.Suffix) { $entry.Suffix } else { "" }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $script -Profile $entry.Profile -Seed $entry.Seeds -Days $Days -Until campaign -Rare $entry.Rare -Ledger full -StallDays 10 -StallActiveMin 900 -Parallel $Parallel -Tag "$Tag$suffix" -OutRoot $OutRoot -TimeoutMin 60
  if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -gt $worst) { $worst = $LASTEXITCODE }
}
exit $worst
