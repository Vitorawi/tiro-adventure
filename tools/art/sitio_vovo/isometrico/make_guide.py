# Guia de composição (blockout) isométrico 2:1 do sítio da Bloblo.
# Tudo é desenhado em coordenadas de mundo (wx, wy) e projetado na mesma proporção 2:1 do apartamento.
# Uso: py -X utf8 -I tools/art/sitio_vovo/isometrico/make_guide.py
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1248, 4400
T = 40  # meia largura do losango de 1 tile (altura = T/2)
X0 = W / 2
img = Image.new("RGB", (W, H), (150, 196, 92))
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("arialbd.ttf", 30)
except OSError:
    font = ImageFont.load_default()


def P(wx, wy):
    return (X0 + (wx - wy) * T, (wx + wy) * T / 2)


def UV(u, v):
    """u = profundidade (desce na tela), v = lado (direita +)."""
    return ((u + v) / 2, (u - v) / 2)


def rect(wx, wy, a, b):
    return [P(wx - a / 2, wy - b / 2), P(wx + a / 2, wy - b / 2), P(wx + a / 2, wy + b / 2), P(wx - a / 2, wy + b / 2)]


def box(u, v, a, b, h, top, left, right):
    wx, wy = UV(u, v)
    base = rect(wx, wy, a, b)  # 0 fundo, 1 direita, 2 frente, 3 esquerda
    roof = [(x, y - h) for x, y in base]
    edge = (60, 40, 20)
    d.polygon([base[3], base[2], roof[2], roof[3]], fill=left, outline=edge)
    d.polygon([base[2], base[1], roof[1], roof[2]], fill=right, outline=edge)
    d.polygon(roof, fill=top, outline=edge)
    return roof[0]


def walk(u, v, steps):
    """Trechos SEMPRE alinhados aos eixos do mundo: ('x', n) desce para a direita, ('y', n) desce para a esquerda."""
    wx, wy = UV(u, v)
    pts = [(wx, wy)]
    for axis, n in steps:
        wx, wy = (wx + n, wy) if axis == "x" else (wx, wy + n)
        pts.append((wx, wy))
    return pts


def band(world_pts, width, col):
    pts = [P(*p) for p in world_pts]
    d.line(pts, fill=col, width=width, joint="curve")
    r = width // 2
    for x, y in pts:
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)


def fence(world_pts, col=(140, 90, 40)):
    d.line([P(*p) for p in world_pts], fill=col, width=9)


def label(xy, text):
    x, y = xy
    tw = d.textlength(text, font=font)
    d.rectangle([x - tw / 2 - 8, y - 20, x + tw / 2 + 8, y + 20], fill=(255, 255, 255), outline=(0, 0, 0))
    d.text((x - tw / 2, y - 17), text, fill=(20, 20, 20), font=font)


# grade 2:1 de referência
for k in range(-2 * H, W + 2 * H, T * 2):
    d.line([(k, 0), (k + 2 * H, H)], fill=(140, 186, 86), width=1)
    d.line([(k, 0), (k - 2 * H, H)], fill=(140, 186, 86), width=1)

WATER, PATH = (70, 170, 210), (226, 186, 120)
X, Y = "x", "y"

def zig(u, v, targets):
    """Vai de alvo em alvo de v; subir v = trecho em x, descer v = trecho em y (sempre nos eixos)."""
    steps = []
    for t in targets:
        steps.append((X, t - v) if t > v else (Y, v - t))
        v = t
    return walk(u, steps_v0(v, steps), steps)


def steps_v0(v_end, steps):
    for a, n in steps:
        v_end -= n if a == X else -n
    return v_end


# --- rio de cima: desce pela esquerda e sai pela borda perto da cerca ---
band(zig(-6, -10, [-14, -9, -13, -8, -13, -9, -14, -9, -13, -9, -14, -10, -14, -10, -18]), 100, WATER)
# --- rio de baixo: entra pela esquerda e desce até o fim ---
band(zig(136, -20, [-9, -13, -9, -13, -8, -12, -8, -13, -9, -13, -9, -13, -10, -14]), 100, WATER)

# --- caminho principal: da porta da casa até a base ---
band(zig(28, 4, [-1, 7, 3, 9, 5, 9, 5, 9, 5, 9, 4, 8, 3, 7, 2, 6, 1, 5, 0, 4, 0, 4, -1, 3, -2, 2, -3, 1, -3, 1, -2, 2, -2, 3, -3, 3, -3, 3, -3]), 110, PATH)
# trilha: ponte de cima -> Vender -> porta da casa
band(walk(12, -12, [(X, 16)]), 70, PATH)
# trilha: caminho -> ponte de baixo -> sai pela esquerda
band(zig(174, -2, [-17]), 70, PATH)

# --- topo: casa da vovó, placa Vender, ponte ---
t = box(24, 6, 7, 6, 160, (200, 90, 60), (232, 208, 165), (212, 186, 142))
label((t[0], t[1] - 30), "CASA DA VOVÓ")
t = box(21, -6, 2, 1, 70, (205, 165, 95), (170, 120, 60), (150, 100, 50))
label((t[0], t[1] - 30), "VENDER + CAIXOTE")
t = box(12, -12, 3, 2, 18, (190, 130, 70), (150, 100, 50), (130, 85, 45))
label((t[0], t[1] - 30), "PONTE")

# --- horta: 6 canteiros (3x3 tiles), 2 x 3, ao lado esquerdo do caminho ---
hu, hv = 62, -4
for j in range(3):       # linhas ao longo de wy
    for i in range(2):   # colunas ao longo de wx
        u = hu + (i * 4) + (j * 4)
        v = hv + (i * 4) - (j * 4)
        box(u, v, 3, 3, 14, (105, 66, 38), (168, 118, 68), (148, 98, 58))
label(P(*UV(hu - 6, hv)), "HORTA: 6 CANTEIROS")

# --- cerca que atravessa o sítio, com portão no caminho ---
gate_u, gate_v = 100, 4
gx, gy = UV(gate_u, gate_v)
fence([(gx - 30, gy), (gx - 1.8, gy)])
fence([(gx + 1.8, gy), (gx + 30, gy)])
t = box(gate_u, gate_v, 1, 0.6, 60, (170, 110, 50), (150, 95, 45), (130, 80, 40))
label((t[0], t[1] - 30), "PORTÃO (2 folhas)")

# --- celeiro + curral das vacas (esquerda) ---
t = box(117, -10, 6, 5, 140, (200, 90, 60), (205, 155, 95), (185, 135, 80))
label((t[0], t[1] - 30), "CELEIRO")
cx, cy = UV(131, -10)
fence([(cx - 3.5, cy - 3), (cx + 3.5, cy - 3), (cx + 3.5, cy + 3), (cx - 3.5, cy + 3), (cx - 3.5, cy - 3)])
label(P(*UV(140, -10)), "CURRAL (2 VACAS)")

# --- galinheiro + cercado (direita) ---
t = box(180, 10, 3, 3, 110, (200, 90, 60), (205, 155, 95), (185, 135, 80))
label((t[0], t[1] - 30), "GALINHEIRO")
cx, cy = UV(190, 10)
fence([(cx - 4, cy - 4), (cx + 4, cy - 4), (cx + 4, cy + 4), (cx - 4, cy + 4), (cx - 4, cy - 4)])
label(P(*UV(199, 10)), "CERCADO (GALINHAS)")

# --- ponte de baixo (na trilha da esquerda, sobre o rio de baixo) ---
t = box(183, -11, 2, 3, 18, (190, 130, 70), (150, 100, 50), (130, 85, 45))
label((t[0], t[1] - 30), "PONTE DE BAIXO")

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "guia_composicao.png")
img.save(out)
img.resize((W // 3, H // 3)).save(os.path.join(os.path.dirname(out), "..", "..", "..", "..", "build", "guide_prev.png"))
print(out, img.size)
