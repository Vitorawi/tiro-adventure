# Testa o jogo como um celular com tela de toque (Chrome headless + DevTools Protocol).
# Pre-requisitos: build em build/web (tools/export_web.ps1) e servidor rodando
# (tools/serve_local.ps1 em outro terminal). Saida: PNGs em build/touch_test/ e o
# console do navegador (prints do Godot) em build/touch_test/console.txt.
#
# Uso:  powershell -File tools/touch_test.ps1 [-Url http://localhost:8000/] [-Steps steps.json]
# Sem -Steps, roda o roteiro padrao (abre Casa, arrasta, toca na geladeira).
# Coordenadas sao em pixels CSS de um celular 390x844.

param(
    [string]$Url = "http://localhost:8000/",
    [string]$Steps = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Out = Join-Path $Root "build\touch_test"
New-Item -ItemType Directory -Force $Out | Out-Null
Get-ChildItem $Out -Filter *.png | Remove-Item

$Chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $Chrome)) { $Chrome = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" }
$Profile = Join-Path $env:TEMP ("touch_test_" + [guid]::NewGuid().ToString("N").Substring(0, 6))
$Port = 9333
$Proc = Start-Process $Chrome -WindowStyle Hidden -ArgumentList "--headless=new", "--remote-debugging-port=$Port", "--user-data-dir=$Profile", "--no-first-run", "--window-size=390,844", "about:blank" -PassThru

try {
    $Target = $null
    for ($i = 0; $i -lt 40 -and -not $Target; $i++) {
        Start-Sleep -Milliseconds 250
        try { $Target = (Invoke-RestMethod "http://127.0.0.1:$Port/json/list") | Where-Object { $_.type -eq "page" } | Select-Object -First 1 } catch {}
    }
    if (-not $Target) { throw "Chrome nao respondeu na porta $Port" }

    $Ws = New-Object System.Net.WebSockets.ClientWebSocket
    $Ws.ConnectAsync([Uri]$Target.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
    $script:Id = 0
    $script:Console = New-Object System.Collections.Generic.List[string]

    function Receive-Cdp {
        $buffer = New-Object byte[] 65536
        $ms = New-Object System.IO.MemoryStream
        do {
            $seg = New-Object ArraySegment[byte] -ArgumentList (, $buffer)
            $r = $Ws.ReceiveAsync($seg, [Threading.CancellationToken]::None).Result
            $ms.Write($buffer, 0, $r.Count)
        } while (-not $r.EndOfMessage)
        $msg = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
        if ($msg.method -eq "Runtime.consoleAPICalled") {
            $script:Console.Add((($msg.params.args | ForEach-Object { $_.value }) -join " "))
        }
        return $msg
    }

    function Send-Cdp([string]$Method, $Params = @{}) {
        $script:Id++
        $json = @{ id = $script:Id; method = $Method; params = $Params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $Ws.SendAsync((New-Object ArraySegment[byte] -ArgumentList (, $bytes)), "Text", $true, [Threading.CancellationToken]::None).Wait()
        do { $resp = Receive-Cdp } until ($resp.id -eq $script:Id)
        if ($resp.error) { throw "$Method falhou: $($resp.error.message)" }
        return $resp.result
    }

    function Touch([string]$Type, $Points) {
        $tp = @($Points | ForEach-Object { @{ x = $_[0]; y = $_[1]; id = $_[2] } })
        Send-Cdp "Input.dispatchTouchEvent" @{ type = $Type; touchPoints = $tp } | Out-Null
    }

    function Invoke-Step($s) {
        switch ($s.do) {
            "wait" { Start-Sleep -Milliseconds $s.ms }
            "tap" {
                Touch "touchStart" @(, @($s.x, $s.y, 0)); Start-Sleep -Milliseconds 60
                Touch "touchEnd" @()
            }
            "drag" {
                $n = 12
                Touch "touchStart" @(, @($s.x1, $s.y1, 0))
                for ($k = 1; $k -le $n; $k++) {
                    $x = $s.x1 + ($s.x2 - $s.x1) * $k / $n; $y = $s.y1 + ($s.y2 - $s.y1) * $k / $n
                    Touch "touchMove" @(, @($x, $y, 0)); Start-Sleep -Milliseconds 16
                }
                Touch "touchEnd" @()
            }
            "ghost_drag" {
                # Simula navegador que avisa o mesmo dedo duas vezes (ids 0 e 7 no mesmo lugar).
                $n = 12
                Touch "touchStart" @(@($s.x1, $s.y1, 0), @($s.x1, $s.y1, 7))
                for ($k = 1; $k -le $n; $k++) {
                    $x = $s.x1 + ($s.x2 - $s.x1) * $k / $n; $y = $s.y1 + ($s.y2 - $s.y1) * $k / $n
                    Touch "touchMove" @(@($x, $y, 0), @($x, $y, 7)); Start-Sleep -Milliseconds 16
                }
                Touch "touchEnd" @()
            }
            "pinch" {
                # Dois dedos se afastando (zoom in) ou aproximando (factor < 1) em volta de (x, y).
                $n = 12; $d0 = 40; $d1 = 40 * $s.factor
                Touch "touchStart" @(@(($s.x - $d0), $s.y, 0), @(($s.x + $d0), $s.y, 1))
                for ($k = 1; $k -le $n; $k++) {
                    $d = $d0 + ($d1 - $d0) * $k / $n
                    Touch "touchMove" @(@(($s.x - $d), $s.y, 0), @(($s.x + $d), $s.y, 1)); Start-Sleep -Milliseconds 16
                }
                Touch "touchEnd" @()
            }
            "shot" {
                $png = (Send-Cdp "Page.captureScreenshot" @{ format = "png" }).data
                [IO.File]::WriteAllBytes((Join-Path $Out "$($s.name).png"), [Convert]::FromBase64String($png))
            }
        }
    }

    Send-Cdp "Runtime.enable" | Out-Null
    Send-Cdp "Page.enable" | Out-Null
    Send-Cdp "Emulation.setDeviceMetricsOverride" @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
    Send-Cdp "Emulation.setTouchEmulationEnabled" @{ enabled = $true; maxTouchPoints = 5 } | Out-Null
    Send-Cdp "Page.navigate" @{ url = $Url } | Out-Null
    Start-Sleep -Seconds 12

    if ($Steps) {
        $plan = Get-Content $Steps -Raw | ConvertFrom-Json
    } else {
        $plan = @(
            @{ do = "shot"; name = "01_pet" },
            @{ do = "tap"; x = 292; y = 809 }, @{ do = "wait"; ms = 800 },
            @{ do = "shot"; name = "02_casa" },
            @{ do = "drag"; x1 = 250; y1 = 450; x2 = 120; y2 = 450 }, @{ do = "wait"; ms = 500 },
            @{ do = "shot"; name = "03_depois_arrastar" }
        ) | ForEach-Object { [pscustomobject]$_ }
    }
    foreach ($s in $plan) { Invoke-Step $s }

    # Coleta mensagens de console pendentes.
    Send-Cdp "Runtime.evaluate" @{ expression = "1" } | Out-Null
    $script:Console | Set-Content (Join-Path $Out "console.txt") -Encoding UTF8
    Write-Host "Prints em $Out"
} finally {
    if ($Proc -and -not $Proc.HasExited) { Stop-Process -Id $Proc.Id -Force }
    $ResolvedProfile = [IO.Path]::GetFullPath($Profile)
    $TempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if (!$ResolvedProfile.StartsWith($TempRoot, [StringComparison]::OrdinalIgnoreCase) -or !(Split-Path $ResolvedProfile -Leaf).StartsWith("touch_test_")) { throw "Perfil fora da pasta temporaria" }
    Remove-Item -LiteralPath $ResolvedProfile -Recurse -Force -ErrorAction SilentlyContinue
}
