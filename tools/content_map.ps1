param([int]$Port = 8765, [switch]$NoOpen)
$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "content_map.py"
if ($NoOpen) { py -X utf8 $scriptPath --port $Port }
else { py -X utf8 $scriptPath --port $Port --open }
