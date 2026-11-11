import sys, re
S = sys.argv[1]; LABELS = sys.argv[2] == "1"; OUT = sys.argv[3]
src = open("C:/Users/Vitor/Documents/ClaudeGame/tools/art/sitio_vovo/isometrico/make_guide.py", encoding="utf-8").read()
head = src.split("# grade 2:1 de refer")[0]
head = head.replace("W, H = 1248, 4400", "W, H = 1248, 1664")
if not LABELS:
    head = head.replace("def label(xy, text):\n", "def label(xy, text):\n    return\n")
exec(compile(head, "g", "exec"))
helpers = src.split("WATER, PATH =")[1].split("# --- rio de cima")[0]
exec(compile("WATER, PATH =" + helpers, "h", "exec"))

# rio de cima (igual ao original)
band(zig(-6, -10, [-14, -9, -13, -8, -13, -9, -14, -9, -13, -9, -14, -10, -14, -10, -18]), 100, WATER)
# caminho em L: porta -> 4 casas para a esquerda-baixo, 14 para a direita-baixo, longo para esquerda-baixo
band([(15, 12), (15, 16), (29, 16), (29, 40)], 110, PATH)
# trilha ponte -> Vender -> casa
band(walk(12, -12, [(X, 16)]), 70, PATH)
# casa, placa, ponte
t = box(24, 6, 7, 6, 160, (200, 90, 60), (232, 208, 165), (212, 186, 142)); label((t[0], t[1] - 30), "CASA DA VOVO")
t = box(21, -6, 2, 1, 70, (205, 165, 95), (170, 120, 60), (150, 100, 50)); label((t[0], t[1] - 30), "VENDER")
t = box(12, -12, 3, 2, 18, (190, 130, 70), (150, 100, 50), (130, 85, 45)); label((t[0], t[1] - 30), "PONTE")
# horta: 6 canteiros 2.5x2.5 tiles, folga 0.75, 3 ao longo de x e 2 ao longo de y
B, G = 2.5, 0.75
x0, y0 = 17 + B / 2, 19 + B / 2
for j in range(2):
    for i in range(3):
        wx, wy = x0 + i * (B + G), y0 + j * (B + G)
        base = rect(wx, wy, B, B); roof = [(x, y - 14) for x, y in base]
        edge = (60, 40, 20)
        d.polygon([base[3], base[2], roof[2], roof[3]], fill=(168, 118, 68), outline=edge)
        d.polygon([base[2], base[1], roof[1], roof[2]], fill=(148, 98, 58), outline=edge)
        d.polygon(roof, fill=(105, 66, 38), outline=edge)
label(P(x0 + 3, y0 - 3), "HORTA")
img.save(OUT)
print(OUT)
