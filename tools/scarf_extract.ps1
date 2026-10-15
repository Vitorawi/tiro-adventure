param([string]$Candidate = 'build/art_sources/etapa08/red_scarf_candidate_02.png')
# Limpeza reproduzível do lenço: diferença RGBA seguida de máscara de tecido vermelho
# e contorno adjacente. Não transporta as alterações de pelo feitas pelo gerador.
. "$PSScriptRoot/pixel_tools.ps1"
$taskFolder = Join-Path $PSScriptRoot '../build/art_sources/etapa08'
$rawPath = Join-Path $taskFolder 'red_scarf_diff_raw.png'
$outPath = Join-Path $taskFolder 'red_scarf_overlay.png'
New-OverlayFromDiff "$PSScriptRoot/../game/assets/sprites/characters/tiro_pet/idle_breathe/frame_00.png" $Candidate $rawPath
$raw = [System.Drawing.Bitmap]::new((Resolve-Path $rawPath).Path)
$out = [System.Drawing.Bitmap]::new($raw.Width, $raw.Height)
$mask = New-Object 'bool[,]' $raw.Width, $raw.Height
for ($y = 100; $y -lt 149; $y++) {
    for ($x = 98; $x -lt 169; $x++) {
        # Exclui a boca/língua; inclui o pano sob o queixo e o nó à direita.
        if ($y -lt 110 -and $x -lt 149) { continue }
        $c = $raw.GetPixel($x, $y)
        if ($c.A -gt 0 -and $c.R -gt $c.G * 1.4 -and $c.B -gt $c.G * 0.8) {
            $mask[$x,$y] = $true
        }
    }
}
# Descarta pequenos resíduos de pelo que também têm tom avermelhado.
$seen = New-Object 'bool[,]' $raw.Width, $raw.Height
for ($y = 100; $y -lt 149; $y++) {
    for ($x = 98; $x -lt 169; $x++) {
        if (-not $mask[$x,$y] -or $seen[$x,$y]) { continue }
        $queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()
        $component = [System.Collections.Generic.List[System.Drawing.Point]]::new()
        $queue.Enqueue([System.Drawing.Point]::new($x,$y))
        while ($queue.Count -gt 0) {
            $p = $queue.Dequeue()
            if ($p.X -lt 1 -or $p.X -ge $raw.Width-1 -or $p.Y -lt 1 -or $p.Y -ge $raw.Height-1) { continue }
            if ($seen[$p.X,$p.Y] -or -not $mask[$p.X,$p.Y]) { continue }
            $seen[$p.X,$p.Y] = $true
            $component.Add($p)
            for ($dy = -1; $dy -le 1; $dy++) {
                for ($dx = -1; $dx -le 1; $dx++) { $queue.Enqueue([System.Drawing.Point]::new($p.X+$dx,$p.Y+$dy)) }
            }
        }
        foreach ($p in $component) {
            if ($component.Count -lt 8) { $mask[$p.X,$p.Y] = $false }
            else { $out.SetPixel($p.X,$p.Y,$raw.GetPixel($p.X,$p.Y)) }
        }
    }
}
for ($y = 100; $y -lt 149; $y++) {
    for ($x = 98; $x -lt 169; $x++) {
        $c = $raw.GetPixel($x, $y)
        if ($c.A -eq 0 -or $c.R -gt 75 -or $c.G -gt 65 -or $c.B -gt 65) { continue }
        $near = $false
        for ($dy = -1; $dy -le 1; $dy++) {
            for ($dx = -1; $dx -le 1; $dx++) {
                if ($mask[($x+$dx),($y+$dy)]) { $near = $true }
            }
        }
        if ($near) { $out.SetPixel($x,$y,$c) }
    }
}
$out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
$raw.Dispose()
New-ContactSheet (Join-Path $taskFolder 'red_scarf_review.png') 2 @(
    "$PSScriptRoot/../game/assets/sprites/characters/tiro_pet/idle_breathe/frame_00.png",
    $Candidate,
    $outPath
)
