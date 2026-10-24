# Circuito: rapido, etapa (áreas dos arquivos mudados), portao e campanha.
# -Exact limita etapa ao rápido + -Tests, sem descobrir áreas pelos arquivos mudados.
param(
  [ValidateSet('rapido','etapa','portao','campanha')][string]$Level = 'etapa',
  [string]$Tests = '', [string]$Areas = '', [string]$Since = '',
  [string]$ChangeList = '',
  [ValidateRange(1,16)][int]$Jobs = 1,
  [switch]$KeepGoing, [switch]$DryRun, [switch]$Exact
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $PSBoundParameters.ContainsKey('Jobs')) { $Jobs = if ($Level -eq 'portao') { 3 } else { 1 } }
function Names([string]$value) { @($value -split ',' | ForEach-Object { $_.Trim() -replace '\.gd$','' } | Where-Object { $_ }) }
$map = Get-Content tools/test_areas.json -Raw | ConvertFrom-Json
# A suíte canônica é conferida contra o mapa, inclusive quando um teste novo só entrou no atalho.
$suite = @($map.suite)
$mapped = @($map.campaign)
foreach ($area in $map.areas.PSObject.Properties) { $mapped += @($area.Value.tests) }
$orphans = @($suite | Where-Object { $_ -notin $mapped })
if ($orphans.Count) { throw "Teste órfão: $($orphans -join ', ')" }
foreach ($name in $suite) {
  $file = if ($name -eq 'dev_tools_test_prod') { 'dev_tools_test' } else { $name }
  if ($name -notmatch 'selftest$' -and -not (Test-Path "game/tests/$file.gd")) { throw "Teste ausente: $name" }
}
$selectedAreas = @(Names $Areas)
$plan = @()
if ($Level -in @('rapido','etapa')) {
  $cache = if (Test-Path game/.godot/global_script_class_cache.cfg) { Get-Content game/.godot/global_script_class_cache.cfg -Raw } else { '' }
  $missing = @(Get-ChildItem game -Filter *.gd -Recurse | Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' } | ForEach-Object {
    $match = [regex]::Match([IO.File]::ReadAllText($_.FullName), '(?m)^class_name\s+(\w+)')
    if ($match.Success -and $cache -notmatch ('"class":\s*&?"' + [regex]::Escape($match.Groups[1].Value) + '"')) { $_.Name }
  })
  if ($missing.Count) { $plan += 'import' }
  $plan += 'scripts_check'
  $plan += @($map.always)
}
if ($Level -eq 'etapa') {
  # -Exact: só rapido + -Tests, sem descoberta automática de áreas.
  if (-not $Exact) {
  if ($ChangeList) {
    if ($Since) { throw 'Use -ChangeList ou -Since, não ambos.' }
    $changed = @(Get-Content -LiteralPath $ChangeList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
    foreach ($path in $changed) {
      if ([IO.Path]::IsPathRooted($path) -or $path -match '(^|[/\\])\.\.([/\\]|$)') { throw "Caminho inválido no ChangeList: $path" }
    }
    Write-Host "Escopo da tarefa: $ChangeList ($($changed.Count) arquivos); alterações anteriores ficam fora da seleção automática."
  } elseif ($Since) {
    $changed = @(& git diff --name-only $Since --)
    if ($LASTEXITCODE) { throw "Referência Git inválida: $Since" }
  } else {
    # Inclui arquivos ainda não rastreados e renomeados no status.
    $changed = @(& git -c core.quotepath=false status --porcelain --untracked-files=all | ForEach-Object {
      $path = $_.Substring(3)
      if ($path.Contains(' -> ')) { $path = ($path -split ' -> ')[-1] }
      $path.Trim('"')
    })
  }
  foreach ($path in $changed) {
    if (@($map.broad | Where-Object { $path -like $_ }).Count) {
      Write-Warning "$path mudou: passe -Areas para as áreas afetadas."
      continue
    }
    foreach ($area in $map.areas.PSObject.Properties) {
      if (@($area.Value.paths | Where-Object { $path -like $_ }).Count) { $selectedAreas += $area.Name }
    }
  }
  }
  $plan += @(Names $Tests)
}
if ($Level -eq 'portao') { $selectedAreas = @($map.areas.PSObject.Properties.Name) }
foreach ($id in @($selectedAreas | Select-Object -Unique)) {
  if ($id -notin $map.areas.PSObject.Properties.Name) { throw "Área desconhecida: $id" }
  $plan += @($map.areas.$id.tests)
}
if ($Level -eq 'campanha') { $plan = @($map.campaign) }
$plan = @($plan | Select-Object -Unique)
foreach ($name in $plan) {
  if ($name -notin ($suite + @('import','scripts_check','economy_quick'))) { throw "Teste desconhecido: $name" }
  if ($Level -ne 'campanha' -and $name -in $map.campaign) { throw "$name pertence à campanha; use -Level campanha" }
}
$logRoot = Join-Path $root 'build/test_logs'
$times = @{}
if (Test-Path "$logRoot/times.csv") { Import-Csv "$logRoot/times.csv" | ForEach-Object { $times[$_.teste] = [double]::Parse($_.segundos, [Globalization.CultureInfo]::InvariantCulture) } }
elseif (Test-Path "$logRoot/last_run.csv") { Import-Csv "$logRoot/last_run.csv" | ForEach-Object { $times[$_.teste] = [double]::Parse($_.segundos, [Globalization.CultureInfo]::InvariantCulture) } }
$estimate = 0.0
# Referências históricas só quando ainda não há tempo medido neste circuito.
$initialSeconds = @{ progression_test = 1470; economy_sim_test = 55; economy_quick = 360; import = 30; scripts_check = 10 }
$unmeasured = @()
foreach ($name in $plan) {
  if ($times.ContainsKey($name)) { $estimate += $times[$name] } else { $estimate += $(if ($initialSeconds.ContainsKey($name)) { $initialSeconds[$name] } else { 15 }); $unmeasured += $name }
}
$estimate /= $Jobs
$budget = @{ rapido = 60; etapa = 300; portao = 480; campanha = 0 }[$Level]
Write-Host "Nível $Level; $($plan.Count) testes; Jobs=$Jobs; estimativa $([Math]::Round($estimate)) s."
Write-Host ($plan -join ', ')
if ($unmeasured.Count) { Write-Host "Sem medida (estimativas iniciais, não medições): $($unmeasured -join ', ')" }
if ($budget -and $estimate -gt $budget) { Write-Warning "Estimativa acima do orçamento de $budget s; refine as áreas se necessário." }
if ($DryRun) { exit 0 }
New-Item -ItemType Directory -Force $logRoot | Out-Null
$runTag = 'r' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$runDir = Join-Path $logRoot $runTag
New-Item -ItemType Directory -Force $runDir | Out-Null
$rows = [Collections.Generic.List[object]]::new()
$active = [Collections.Generic.List[object]]::new()
$queue = [Collections.Generic.Queue[string]]::new()
$plan | ForEach-Object { $queue.Enqueue($_) }
$clock = [Diagnostics.Stopwatch]::StartNew()
$failed = $false
try {
  while ($queue.Count -or $active.Count) {
    while ($queue.Count -and $active.Count -lt $Jobs -and (-not $failed -or $KeepGoing)) {
      # Importação escreve no cache compartilhado: nunca roda junto dos testes.
      if ($active.Count -and $queue.Peek() -eq 'import') { break }
      if (@($active | Where-Object { $_.name -eq 'import' }).Count) { break }
      $name = $queue.Dequeue()
      $log = Join-Path $runDir "$name.log"
      $worker = Join-Path $PSScriptRoot 'test_worker.ps1'
      $tag = "${runTag}_$name"
      $process = Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$worker`"",'-Test',$name,'-Tag',$tag) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
      $null = $process.Handle
      $active.Add([pscustomobject]@{ name=$name; process=$process; log=$log; watch=[Diagnostics.Stopwatch]::StartNew() })
      if ($name -eq 'import') { break }
    }
    foreach ($job in @($active.ToArray())) {
      $limit = if ($job.name -in @('progression_test','economy_quick')) { 2400 } else { 300 }
      $timeout = $job.watch.Elapsed.TotalSeconds -gt $limit
      if (-not $job.process.HasExited -and -not $timeout) { continue }
      if ($timeout) { & taskkill /PID $job.process.Id /T /F | Out-Null }
      $job.process.WaitForExit()
      $output = [IO.File]::ReadAllText($job.log) + [IO.File]::ReadAllText("$($job.log).err")
      $result = if ($timeout) { 'TIMEOUT' } elseif ($job.process.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR:|(?m)^ERROR:|Parse Error|TEST: FAIL') { 'FAIL' } else { 'PASS' }
      $seconds = [Math]::Round($job.watch.Elapsed.TotalSeconds,1)
      $times[$job.name] = $seconds
      $rows.Add([pscustomobject]@{ teste=$job.name; segundos=$seconds.ToString([Globalization.CultureInfo]::InvariantCulture); resultado=$result; nivel=$Level })
      $rows | Export-Csv "$logRoot/last_run.csv" -NoTypeInformation -Encoding UTF8
      $timeRows = foreach ($key in @($times.Keys | Sort-Object)) { [pscustomobject]@{ teste=$key; segundos=$times[$key].ToString([Globalization.CultureInfo]::InvariantCulture) } }
      $timeRows | Export-Csv "$logRoot/times.csv" -NoTypeInformation -Encoding UTF8
      Write-Host "$($job.name): $result ($seconds s) — $($job.log)"
      if ($result -ne 'PASS') { $failed = $true; Write-Host $output }
      $active.Remove($job) | Out-Null
    }
    if ($failed -and -not $KeepGoing -and -not $active.Count) { break }
    Start-Sleep -Milliseconds 100
  }
} finally {
  foreach ($job in $active) { if (-not $job.process.HasExited) { & taskkill /PID $job.process.Id /T /F | Out-Null } }
}
$rows | Export-Csv "$runDir/results.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Total: $([Math]::Round($clock.Elapsed.TotalSeconds,1)) s; resultados: $runDir/results.csv"
if ($failed) { exit 1 }
exit 0
