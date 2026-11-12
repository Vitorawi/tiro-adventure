"""Monta prancha (nearest, 4x): python board.py <saida.png> <pasta> [escala]. Colunas = pecas, linhas = opcoes a/b."""
import sys, os, re
from PIL import Image
out, folder = sys.argv[1], sys.argv[2]
sc = int(sys.argv[3]) if len(sys.argv) > 3 else 4
names = {}
for f in sorted(os.listdir(folder)):
    m = re.match(r"(.+)_([a-d])\.png$", f)
    if m: names.setdefault(m.group(1), {})[m.group(2)] = Image.open(os.path.join(folder, f)).convert("RGBA")
cols = list(names); rows = "abcd"
cw = max(i.width for d in names.values() for i in d.values()) * sc + 8
ch = max(i.height for d in names.values() for i in d.values()) * sc + 8
rows = [r for r in rows if any(r in d for d in names.values())]
sheet = Image.new("RGBA", (cw * len(cols), ch * len(rows)), (150, 190, 215, 255))
for ci, c in enumerate(cols):
    for ri, r in enumerate(rows):
        if r in names[c]:
            im = names[c][r].resize((names[c][r].width * sc, names[c][r].height * sc), Image.NEAREST)
            sheet.alpha_composite(im, (ci * cw + 4, ri * ch + 4))
sheet.save(out); print(out, sheet.size, cols)
