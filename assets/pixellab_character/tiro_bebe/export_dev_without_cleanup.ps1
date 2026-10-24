$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
Set-Location -LiteralPath $taskRoot
$sourcePath = Join-Path $taskRoot 'tools/export_web.ps1'
$source = [IO.File]::ReadAllText($sourcePath)
$cleanup = 'if (Test-Path $ResolvedOutput) { Remove-Item -LiteralPath $ResolvedOutput -Recurse -Force }'
if (-not $source.Contains($cleanup)) { throw 'Limpeza esperada nao encontrada; revisar antes de executar' }
$source = $source.Replace($cleanup, 'Write-Host "Saida existente preservada: limpeza desativada para esta tarefa."')
$source = $source.Replace('$Root = Split-Path -Parent $PSScriptRoot', ('$Root = ''' + $taskRoot.Replace("'", "''") + ''''))
$devBranch = '"dev" { Export-Channel "dev" $OutDir }'
if (-not $source.Contains($devBranch)) { throw 'Ramo dev esperado nao encontrado' }
$source = $source.Replace($devBranch, '"dev" { Export-Channel "dev" (Join-Path $OutDir "dev") }')
if ($source -match 'Remove-Item') { throw 'Operacao de remocao ainda presente' }
Write-Host 'Executando tools/export_web.ps1 em memoria: sem limpeza e canal dev em build/web/dev.'
& ([scriptblock]::Create($source)) -Channel dev
exit $LASTEXITCODE
