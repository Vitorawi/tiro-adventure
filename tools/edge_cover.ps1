# Gera o poligono "edge_cover" de uma maquete: a faixa de terra (lateral do bloco flutuante) entre a
# borda da grama e o fundo do bloco. Uso:
#   powershell -ExecutionPolicy Bypass -File tools/edge_cover.ps1 game\assets\sprites\areas\farm\farm_animals.png
# Imprime a lista [[x, y], ...] pronta para colar em data/rooms/<id>.json ("edge_cover").
# A imagem precisa ter o fundo transparente (veja Invoke-ClearCorner em tools/pixel_tools.ps1).
param([Parameter(Mandatory = $true)][string]$Image, [int]$Step = 4, [double]$Tolerance = 1.5)

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Collections.Generic; using System.Text;
public static class EdgeCover {
    static bool Grass(Color c) { return c.A > 128 && c.G >= c.R && c.G > c.B + 8; }
    // distancia do ponto p ate o segmento a-b
    static double Dist(PointF p, PointF a, PointF b) {
        double dx = b.X - a.X, dy = b.Y - a.Y, len = dx * dx + dy * dy;
        if (len == 0) return Math.Sqrt((p.X - a.X) * (p.X - a.X) + (p.Y - a.Y) * (p.Y - a.Y));
        double t = Math.Max(0, Math.Min(1, ((p.X - a.X) * dx + (p.Y - a.Y) * dy) / len));
        double px = a.X + t * dx, py = a.Y + t * dy;
        return Math.Sqrt((p.X - px) * (p.X - px) + (p.Y - py) * (p.Y - py));
    }
    static void Rdp(List<PointF> pts, int s, int e, double tol, bool[] keep) {
        double best = 0; int idx = -1;
        for (int i = s + 1; i < e; i++) { double d = Dist(pts[i], pts[s], pts[e]); if (d > best) { best = d; idx = i; } }
        if (best > tol && idx >= 0) { keep[idx] = true; Rdp(pts, s, idx, tol, keep); Rdp(pts, idx, e, tol, keep); }
    }
    static List<PointF> Simplify(List<PointF> pts, double tol) {
        if (pts.Count < 3) return pts;
        var keep = new bool[pts.Count]; keep[0] = true; keep[pts.Count - 1] = true;
        Rdp(pts, 0, pts.Count - 1, tol, keep);
        var r = new List<PointF>(); for (int i = 0; i < pts.Count; i++) if (keep[i]) r.Add(pts[i]); return r;
    }
    public static string Build(string path, int step, double tol) {
        using (var bmp = new Bitmap(path)) {
            var top = new List<PointF>(); var bottom = new List<PointF>();
            for (int x = 0; x < bmp.Width; x += step) {
                int bot = -1;
                for (int y = bmp.Height - 1; y >= 0; y--) if (bmp.GetPixel(x, y).A > 128) { bot = y; break; }
                if (bot < 0) continue;
                int edge = -1;
                for (int y = bot; y >= 0; y--) if (Grass(bmp.GetPixel(x, y))) { edge = y; break; }
                if (edge < 0) continue;
                top.Add(new PointF(x, edge + 1)); bottom.Add(new PointF(x, bot + 1));
            }
            top = Simplify(top, tol); bottom = Simplify(bottom, tol);
            bottom.Reverse();
            var all = new List<PointF>(top); all.AddRange(bottom);
            var sb = new StringBuilder("[");
            for (int i = 0; i < all.Count; i++) { if (i > 0) sb.Append(", "); sb.Append("[" + (int)all[i].X + ", " + (int)all[i].Y + "]"); }
            return sb.Append("]").ToString();
        }
    }
}
"@

[EdgeCover]::Build((Resolve-Path $Image).Path, $Step, $Tolerance)
