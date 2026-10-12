# Utilitarios de imagem para preparar arte do PixelLab antes de entrar no jogo.
# Uso:
#   . .\tools\pixel_tools.ps1              (carrega as funcoes na sessao)
#   Invoke-TrimSprite in.png out.png       (corta bordas transparentes; retorna "LxA")
#   Invoke-ClearOutside in.png out.png 12  (torna transparente o fundo claro que toca as bordas)
#   New-ContactSheet out.png 3 a.png b.png (pranchas ampliadas para revisao)

Add-Type -AssemblyName System.Drawing
if (-not ("PixelTools" -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Collections.Generic;
public static class PixelTools {
    static Bitmap Load(string path) {
        var src = new Bitmap(path);
        var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
        src.Dispose();
        return bmp;
    }
    public static string Trim(string inPath, string outPath) {
        var b = Load(inPath); int minX = b.Width, minY = b.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++)
            if (b.GetPixel(x, y).A > 10) { minX = Math.Min(minX, x); minY = Math.Min(minY, y); maxX = Math.Max(maxX, x); maxY = Math.Max(maxY, y); }
        var r = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
        var o = b.Clone(r, b.PixelFormat); b.Dispose(); o.Save(outPath, ImageFormat.Png); o.Dispose();
        return r.Width + "x" + r.Height;
    }
    public static int ClearOutside(string inPath, string outPath, int tol) {
        var bmp = Load(inPath); int w = bmp.Width, h = bmp.Height, n = 0;
        var seen = new bool[w, h]; var q = new Queue<Point>();
        for (int x = 0; x < w; x++) { q.Enqueue(new Point(x, 0)); q.Enqueue(new Point(x, h - 1)); }
        for (int y = 0; y < h; y++) { q.Enqueue(new Point(0, y)); q.Enqueue(new Point(w - 1, y)); }
        while (q.Count > 0) {
            var p = q.Dequeue();
            if (p.X < 0 || p.Y < 0 || p.X >= w || p.Y >= h || seen[p.X, p.Y]) continue;
            var c = bmp.GetPixel(p.X, p.Y);
            if (c.R < 255 - tol || c.G < 255 - tol || c.B < 255 - tol) continue;
            seen[p.X, p.Y] = true; bmp.SetPixel(p.X, p.Y, Color.Transparent); n++;
            q.Enqueue(new Point(p.X + 1, p.Y)); q.Enqueue(new Point(p.X - 1, p.Y));
            q.Enqueue(new Point(p.X, p.Y + 1)); q.Enqueue(new Point(p.X, p.Y - 1));
        }
        bmp.Save(outPath, ImageFormat.Png); bmp.Dispose();
        return n;
    }
}
"@
}

function Invoke-TrimSprite([string]$In, [string]$Out) { [PixelTools]::Trim((Resolve-Path $In).Path, $Out) }
function Invoke-ClearOutside([string]$In, [string]$Out, [int]$Tolerance = 12) { [PixelTools]::ClearOutside((Resolve-Path $In).Path, $Out, $Tolerance) }

function New-ContactSheet([string]$Out, [int]$Scale, [string[]]$Files) {
    $images = $Files | ForEach-Object { [System.Drawing.Image]::FromFile((Resolve-Path $_).Path) }
    $cellW = ($images | Measure-Object Width -Maximum).Maximum * $Scale
    $cellH = ($images | Measure-Object Height -Maximum).Maximum * $Scale
    $sheet = New-Object System.Drawing.Bitmap ($cellW * $images.Count), $cellH
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(150, 110, 80))
    $g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
    for ($i = 0; $i -lt $images.Count; $i++) {
        $img = $images[$i]
        $g.DrawImage($img, $i * $cellW, $cellH - $img.Height * $Scale, $img.Width * $Scale, $img.Height * $Scale)
        $img.Dispose()
    }
    $g.Dispose(); $sheet.Save($Out); $sheet.Dispose()
}
