# Atualiza o relatório/galeria e valida arquivos do álbum ilustrado, sem alterar o jogo.
$ErrorActionPreference = 'Stop'
$albumPython = $env:TIRO_PYTHON_BIN
if (-not $albumPython) {
  $albumPython = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
}
if (-not (Test-Path -LiteralPath $albumPython)) {
  $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
  if (-not $pythonCommand) { throw 'Python não encontrado. Defina TIRO_PYTHON_BIN com o caminho do executável.' }
  $albumPython = $pythonCommand.Source
}
& $albumPython -X utf8 -I (Join-Path $PSScriptRoot 'album_art_control.py')
exit $LASTEXITCODE
