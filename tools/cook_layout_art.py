"""Monta os PNGs da tela da cozinha (fogão) a partir das camadas do Figma (página "FogaoAutDetalhe", nó 3895:13).

Entrada: IUREF/cozinha/nodes/*.png (exports de cada camada em 1,5x, baixados do Figma). Saída:
game/assets/sprites/ui/cook_ui/ck_*.png, em 1,5x das medidas do Figma (o jogo desenha em ~0,5x).
As camadas vêm sobre o cinza 229 da página do Figma: o cinza ligado à borda vira transparente ("cor para alfa",
então a sombra suave continua como sombra). Rode:
  py -X utf8 -I tools/cook_layout_art.py
depois  godot --headless --path game --import  e  mipmaps/generate=true  nos .import.
"""
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "IUREF" / "cozinha" / "nodes"
OUT = ROOT / "game" / "assets" / "sprites" / "ui" / "cook_ui"
K = 1.5
GRAY = 229
TOL = 26  # quão longe do cinza ainda conta como "fundo" na inundação a partir da borda


def load(name: str) -> Image.Image:
    return Image.open(SRC / f"{name}.png").convert("RGBA")


def key_gray(im: Image.Image) -> Image.Image:
    """Tira o cinza da página: inunda a partir da borda os pixels perto do cinza e aplica "cor para alfa" neles."""
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    queue: deque = deque()

    def near(c) -> bool:
        return max(abs(c[0] - GRAY), abs(c[1] - GRAY), abs(c[2] - GRAY)) <= TOL

    for x in range(w):
        for y in (0, h - 1):
            if near(px[x, y]) and not seen[y * w + x]:
                seen[y * w + x] = 1
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if near(px[x, y]) and not seen[y * w + x]:
                seen[y * w + x] = 1
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and near(px[nx, ny]):
                seen[ny * w + nx] = 1
                queue.append((nx, ny))
    # Cor para alfa só na região inundada (+ uma faixa de 2 px em volta, a borda antisserrilhada).
    grow = bytearray(seen)
    for _ in range(2):
        nxt = bytearray(grow)
        for y in range(h):
            row = y * w
            for x in range(w):
                if grow[row + x]:
                    continue
                if (x > 0 and grow[row + x - 1]) or (x < w - 1 and grow[row + x + 1]) or \
                        (y > 0 and grow[row - w + x]) or (y < h - 1 and grow[row + w + x]):
                    nxt[row + x] = 1
        grow = nxt
    for y in range(h):
        for x in range(w):
            if not grow[y * w + x]:
                continue
            r, g, b, a = px[x, y]
            alpha = 0.0
            for c in (r, g, b):
                d = (c - GRAY) / (255 - GRAY) if c > GRAY else (GRAY - c) / GRAY
                alpha = max(alpha, d)
            if not seen[y * w + x]:
                alpha = max(alpha, 0.0)
            alpha = min(1.0, alpha * 1.6) if seen[y * w + x] else min(1.0, alpha * 3.0)
            if alpha <= 0.004:
                px[x, y] = (0, 0, 0, 0)
                continue
            out = []
            for c in (r, g, b):
                out.append(max(0, min(255, round((c - GRAY) / alpha + GRAY))))
            px[x, y] = (out[0], out[1], out[2], round(a * alpha))
    return im


def solid_box(im: Image.Image) -> tuple[int, int, int, int]:
    """Caixa do que é visível de verdade (ignora resto quase transparente do cinza)."""
    return im.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()


def trim(im: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    box = solid_box(im)
    clean = im.copy()
    a = clean.getchannel("A").point(lambda v: 0 if v <= 24 else v)
    clean.putalpha(a)
    return clean, box  # sem cortar: a imagem continua do tamanho do retângulo da camada no Figma


def save(im: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / name, optimize=True)
    print(name, im.size)


def at(x: float) -> int:
    return round(x * K)


# --- Painel: "image 2" + as três tampas (image 26, image 8, image 7) que escondem o que vinha desenhado embaixo ---
# Posições em unidades do Figma relativas ao quadro "containercozinha-deixarjunto" (-345, -538).
panel = load("panel")
for name, x, y in (("image26", 217, 184), ("shelf", 32, 389), ("image7", 26, 478)):
    panel.alpha_composite(load(name), (at(x), at(y)))
panel = key_gray(panel)
panel, pbox = trim(panel)
panel = panel.crop((0, pbox[1], panel.width, pbox[3]))  # largura inteira do quadro; só corta em cima/embaixo
print("panel bbox (unidades do Figma):", [round(v / K, 1) for v in pbox])
# Três fatias: em cima, faixa do meio (estica na vertical) e embaixo. A faixa fica entre a primeira e a última linha
# de pratos, onde o desenho só tem as linhas verticais das caixas.
band_top = at(790) - pbox[1]
band_bot = band_top + 22  # um período do tracejado da caixa do detalhe: a faixa do meio é LADRILHADA (não esticada)
save(panel.crop((0, 0, panel.width, band_top)), "ck_panel_top.png")
save(panel.crop((0, band_top, panel.width, band_bot)), "ck_panel_mid.png")
save(panel.crop((0, band_bot, panel.width, panel.height)), "ck_panel_bottom.png")

# --- Fila (quatro espaços) ---
busy = key_gray(load("slot_busy"))
# Apaga o anel de progresso desenhado (o jogo desenha um anel de verdade): cada pixel do anel recebe a cor da
# mesma linha fora do anel (o cartão é um degradê vertical).
bpx = busy.load()
cx, cy, r_out, r_in = 99, 59, 54, 28
for y in range(cy - r_out, cy + r_out + 1):
    src_x = cx - r_out - 4
    for x in range(cx - r_out, cx + r_out + 1):
        d2 = (x - cx) ** 2 + (y - cy) ** 2
        if r_in ** 2 <= d2 <= r_out ** 2 and 0 <= y < 105:  # 105 = topo da pílula do tempo
            bpx[x, y] = bpx[src_x, y]
for name in ("slot_ready", "slot_free", "slot_locked"):
    save(trim(key_gray(load(name)))[0], f"ck_{name}.png")
save(trim(busy)[0], "ck_slot_busy.png")
save(trim(key_gray(load("ready_btn")))[0], "ck_ready_btn.png")

# --- Alternador Pratos / Inventar ---
save(trim(key_gray(load("toggle_dishes")))[0], "ck_toggle_dishes.png")
save(trim(key_gray(load("toggle_invent")))[0], "ck_toggle_invent.png")

# --- Categorias ---
for name in ("cat_on", "cat_off", "cat_arrow", "ico_all"):
    save(trim(key_gray(load(name)))[0], f"ck_{name}.png")

# --- Filtros "Dá para fazer" / "Faltam" / "Do Tiro" ---
for i, name in ((1, "can"), (2, "missing"), (3, "tiro")):
    save(trim(key_gray(load(f"filter{i}")))[0], f"ck_filter_{name}.png")

# --- Pratos da lista ---
for name in ("dish_on", "dish_off", "clock", "clock_detail"):
    save(trim(key_gray(load(name)))[0], f"ck_{name}.png")

# --- Barra de rolagem: trilho (sem o pegador) e pegador separados ---
bar, bbox = trim(key_gray(load("scrollbar")))
bar = bar.crop(bbox)
print("scrollbar (unidades do Figma, relativo à camada):", [round(v / K, 1) for v in bbox])
bpx2 = bar.load()
yellow = [y for y in range(bar.height) if any(bpx2[x, y][3] > 200 and bpx2[x, y][0] > 220 and bpx2[x, y][1] > 170 and bpx2[x, y][2] < 90 for x in range(bar.width))]
t0, t1 = min(yellow) - 3, max(yellow) + 4
print("pegador linhas", t0, t1)
thumb = bar.crop((0, t0, bar.width, t1))
track = bar.copy()
# trilho sem o pegador: copia uma fatia lisa do trilho (logo abaixo do pegador) por cima dele
slab = bar.crop((0, t1 + 6, bar.width, t1 + 7))
for y in range(t0, t1 + 1):
    track.paste(slab, (0, y))
save(track, "ck_scroll_track.png")
save(thumb, "ck_scroll_thumb.png")

# --- Detalhe ---
save(trim(key_gray(load("ingr_1")))[0], "ck_ingredient.png")
for name in ("qty_ok", "qty_missing", "mark_ok", "mark_missing", "btn_queue", "btn_together"):
    save(trim(key_gray(load(name)))[0], f"ck_{name}.png")
save(load("empty_detail"), "ck_empty_detail.png")

# --- Estrelas (por enquanto o jogo mostra sempre 0; 1–3 ficam prontas para quando houver a regra) ---
save(trim(key_gray(load("stars0")))[0], "ck_stars_0.png")          # cartão do prato, 50×18
save(trim(key_gray(load("stars0_detail")))[0], "ck_stars_0_detail.png")  # detalhe, 75×27
for n in (1, 2, 3):
    save(trim(key_gray(load(f"stars{n}")))[0], f"ck_stars_{n}.png")


# ============================================================================================================
# Aba "Inventar" (Figma FogaoInventar 3907:16 / FogaoIngredientes 3909:213). Entrada: IUREF/cozinha/inventar/nodes/.
# Saída: ck_inv_*.png + ck_inv_slots.json (medidas do corpo de cada espaço, em unidades do Figma).
# ============================================================================================================
import json

SRC_INV = ROOT / "IUREF" / "cozinha" / "inventar" / "nodes"


def load_inv(name: str) -> Image.Image:
    return Image.open(SRC_INV / f"{name}.png").convert("RGBA")


# Fundo da Inventar: painel + tampa image 26 + inv_cover (no lugar da prateleira e da image 7 da aba Pratos).
inv_panel = load("panel")
inv_panel.alpha_composite(load("image26"), (at(217), at(184)))
inv_panel.alpha_composite(load_inv("inv_cover"), (at(32), at(389)))
inv_panel = key_gray(inv_panel)
inv_panel, ibox = trim(inv_panel)
inv_panel = inv_panel.crop((0, ibox[1], inv_panel.width, ibox[3]))
print("inv panel bbox (unidades do Figma):", [round(v / K, 1) for v in ibox], "(Pratos:", [round(v / K, 1) for v in pbox], ")")
assert ibox[1] == pbox[1] and ibox[3] == pbox[3], "o fundo da Inventar tem que ter a mesma faixa vertical do fundo Pratos"
# faixa do meio: confere que é lisa (linhas iguais) para ladrilhar sem emenda visível
band = inv_panel.crop((0, band_top, inv_panel.width, band_bot)).convert("RGBA")
bp = band.load()
worst = 0
for y in range(band.height):
    for x in range(0, band.width, 3):
        a, b = bp[x, y], bp[x, (y + 1) % band.height]
        worst = max(worst, max(abs(a[i] - b[i]) for i in range(3)))
print("faixa do meio da Inventar: pior diferença entre linhas vizinhas =", worst)
save(inv_panel.crop((0, 0, inv_panel.width, band_top)), "ck_inv_panel_top.png")
save(inv_panel.crop((0, band_top, inv_panel.width, band_bot)), "ck_inv_panel_mid.png")
save(inv_panel.crop((0, band_bot, inv_panel.width, inv_panel.height)), "ck_inv_panel_bottom.png")

# Tipos de prato, espaços e cartão grande.
for name in ("type_on", "type_off", "slot_filled", "card_unknown", "bowl_unknown", "box_hint", "btn_together",
             "card_known", "box_known", "plate_known", "card_empty", "ring_empty", "box_info"):
    save(trim(key_gray(load_inv(name)))[0], f"ck_inv_{name}.png")

slots_info: dict = {}
for kind in ("legume", "protein", "fruit", "dairy", "grain", "free"):
    art, box = trim(key_gray(load_inv(f"slot_{kind}")))
    save(art, f"ck_inv_slot_{kind}.png")
    slots_info[kind] = {
        "size": [round(art.width / K, 2), round(art.height / K, 2)],
        # corpo = parte visível do desenho (sem a sombra): centro x e topo, em unidades, relativos ao canto do desenho
        "body": [round(box[0] / K, 2), round(box[1] / K, 2), round((box[2] - box[0]) / K, 2), round((box[3] - box[1]) / K, 2)],
        "center_x": round((box[0] + box[2]) / 2 / K, 2),
        "top": round(box[1] / K, 2),
    }
filled, fbox = trim(key_gray(load_inv("slot_filled")))
slots_info["filled"] = {"size": [round(filled.width / K, 2), round(filled.height / K, 2)],
                        "body": [round(fbox[0] / K, 2), round(fbox[1] / K, 2), round((fbox[2] - fbox[0]) / K, 2), round((fbox[3] - fbox[1]) / K, 2)]}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "ck_inv_slots.json").write_text(json.dumps(slots_info, indent=2), encoding="utf-8")
print("slots:", json.dumps(slots_info))

# Janelinha de ingredientes: um NinePatch vertical (pontas com folhas/seta e o miolo liso que estica).
pick, pkbox = trim(key_gray(load_inv("pick_panel")))
PICK_M = 150  # linhas (1,5x) de cima e de baixo que não esticam
mid_rows = [pick.crop((0, y, pick.width, y + 1)).convert("RGBA") for y in (PICK_M, pick.height // 2, pick.height - PICK_M - 1)]
d = 0
for x in range(0, pick.width, 3):
    ps = [r.getpixel((x, 0)) for r in mid_rows]
    d = max(d, max(abs(ps[0][i] - ps[2][i]) for i in range(4)))
print("pick: pior diferença entre a primeira e a última linha do miolo:", d, " tamanho", pick.size)
save(pick, "ck_inv_pick.png")
for name in ("pick_head_match", "pick_head_other", "pick_close", "pick_select", "pick_remove", "cell_plain", "cell_rec",
             "cell_on", "cell_out", "tag_pot", "qty_pill", "out_pill"):
    save(trim(key_gray(load_inv(name)))[0], f"ck_inv_{name}.png")

# Barra da janelinha: trilho e pegador, como a barra da lista de pratos.
ibar, ibbox = trim(key_gray(load_inv("pick_scrollbar")))
ibar = ibar.crop(ibbox)
print("pick_scrollbar bbox (unidades, relativo à camada):", [round(v / K, 1) for v in ibbox])
ipx = ibar.load()
yel = [y for y in range(ibar.height) if any(ipx[x, y][3] > 200 and ipx[x, y][0] > 220 and ipx[x, y][1] > 170 and ipx[x, y][2] < 90 for x in range(ibar.width))]
u0, u1 = min(yel) - 3, max(yel) + 4
ithumb = ibar.crop((0, u0, ibar.width, u1))
itrack = ibar.copy()
slab2 = ibar.crop((0, u1 + 6, ibar.width, u1 + 7))
for y in range(u0, u1 + 1):
    itrack.paste(slab2, (0, y))
save(itrack, "ck_inv_pick_track.png")
save(ithumb, "ck_inv_pick_thumb.png")
slots_info["pick_bar"] = {"rect": [round(ibbox[0] / K, 2), round(ibbox[1] / K, 2), round((ibbox[2] - ibbox[0]) / K, 2), round((ibbox[3] - ibbox[1]) / K, 2)]}
(OUT / "ck_inv_slots.json").write_text(json.dumps(slots_info, indent=2), encoding="utf-8")
