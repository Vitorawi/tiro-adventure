# Servidor HTTP local para testar o build Web (build/web/).
# Uso: powershell -File tools/serve_local.ps1 [-Port 8000]
# Abra http://localhost:8000 no navegador. Ctrl+C para parar.
# Para testar no celular na mesma rede, use o "Remote Debug" do editor Godot
# ou publique no GitHub Pages (localhost nao e acessivel pelo celular).

param([int]$Port = 8000)

$ErrorActionPreference = "Stop"

$Root = Join-Path (Split-Path -Parent $PSScriptRoot) "build\web"
if (-not (Test-Path (Join-Path $Root "index.html"))) {
    throw "Build nao encontrado. Rode tools/export_web.ps1 antes."
}

$Mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".json" = "application/json"
    ".webmanifest" = "application/manifest+json"
}

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
$Listener.Start()
Write-Host "Servindo $Root em http://localhost:$Port/ (Ctrl+C para parar)"

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Path = [Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath.TrimStart("/"))
        if ($Path -eq "") { $Path = "index.html" }
        $File = Join-Path $Root $Path
        $Response = $Context.Response
        if ((Test-Path $File -PathType Leaf) -and ((Resolve-Path $File).Path.StartsWith($Root))) {
            $Bytes = [System.IO.File]::ReadAllBytes($File)
            $Ext = [System.IO.Path]::GetExtension($File).ToLower()
            $Response.ContentType = if ($Mime.ContainsKey($Ext)) { $Mime[$Ext] } else { "application/octet-stream" }
            $Response.ContentLength64 = $Bytes.Length
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        } else {
            $Response.StatusCode = 404
        }
        $Response.Close()
    }
} finally {
    $Listener.Stop()
}
