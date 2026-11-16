"""Monta os PNGs da tela de pesca a partir das camadas do Figma (página "Pesca").

Entrada: IUREF/pesca/ (raw_*.png e nodes/*.png baixados do Figma; ver README do plano). Saída:
game/assets/sprites/ui/fishing_ui/fp_*.png, em 1,5x das medidas do Figma (o jogo desenha em ~0,5x, então dá ~3x de nitidez).
Rode: py -X utf8 -I tools/fishing_layout_art.py   (depois godot --headless --path game --import e mipmaps/generate=true nos .import)
"""
from PIL import Image
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "IUREF" / "pesca"
OUT = ROOT / "game" / "assets" / "sprites" / "ui" / "fishing_ui"
K = 1.5


def load(name: str) -> Image.Image:
    return Image.open(SRC / name).convert("RGBA")


def fill(im: Image.Image, w: float, h: float) -> Image.Image:
    """Modo FILL do Figma: cobre o retângulo, centralizado e cortando o que passa."""
    tw, th = round(w * K), round(h * K)
    s = max(tw / im.width, th / im.height)
    r = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    left, top = (r.width - tw) // 2, (r.height - th) // 2
    return r.crop((left, top, left + tw, top + th))


def crop_sheet(sheet: Image.Image, tr, w: float, h: float) -> Image.Image:
    """Modo CROP do Figma: imageTransform [[sx,0,tx],[0,sy,ty]] em coordenadas normalizadas da imagem."""
    sx, tx, sy, ty = tr[0][0], tr[0][2], tr[1][1], tr[1][2]
    box = (round(tx * sheet.width), round(ty * sheet.height), round((tx + sx) * sheet.width), round((ty + sy) * sheet.height))
    return sheet.crop(box).resize((round(w * K), round(h * K)), Image.LANCZOS)


def save(im: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / name, optimize=True)
    print(name, im.size)


sheet = load("raw_1.png")
# Painel: as listras cinza das linhas saem com os "quadrados da mesma cor" do Figma (image 6/9/10 do grupo containerinformacao):
# cada um é uma faixa fina e lisa do próprio painel esticada por cima da linha. Posições relativas ao painel (141, -122).
panel_src = load("raw_13.png")
panel = fill(panel_src, 420, 524)
covers = [
    ((58, 135, 298, 163), [[0.3214285969734192, 0, 0.36666667461395264], [0, 0.0228652935475111, 0.23704910278320312]]),
    ((53, 328, 303, 49), [[0.7309523820877075, 0, 0.12380953133106232], [0, 0.020959852263331413, 0.7229366302490234]]),
    ((53, 388, 303, 49), [[0.7309523820877075, 0, 0.12380953133106232], [0, 0.020959852263331413, 0.7229366302490234]]),
]
for (x, y, w, h), tr in covers:
    panel.alpha_composite(crop_sheet(panel_src, tr, w, h), (round(x * K), round(y * K)))
save(panel, "fp_panel.png")
save(crop_sheet(sheet, [[0.20027625560760498, 0, 0.11006300151348114], [0, 0.26703497767448425, 0.38962775468826294]], 50, 50), "fp_ico_ruler.png")
save(crop_sheet(sheet, [[0.21961325407028198, 0, 0.39013269543647766], [0, 0.29189687967300415, 0.3729281723499298]], 50, 50), "fp_ico_record.png")
save(fill(load("raw_18.png"), 300, 100), "fp_tip1.png")
save(fill(load("raw_5.png"), 255, 85), "fp_tip2.png")
save(fill(load("raw_7.png"), 290, 94), "fp_tip3.png")
save(fill(load("raw_12.png"), 123, 123), "fp_pause.png")
save(fill(load("nodes/n72_a.png"), 550, 183), "fp_hold.png")
save(fill(load("nodes/n96_a.png"), 550, 183), "fp_hold_down.png")
save(fill(load("raw_11.png"), 330, 660), "fp_water.png")      # camada "containerdapesca" = faixa de água
save(fill(load("nodes/n75_a.png"), 266, 726), "fp_frame.png")  # camada "fundoagua" = moldura de madeira
bar = load("raw_15.png").crop((104, 344, 780, 1364))          # corpo do retângulo que pesca (sem a folga transparente)
save(bar.resize((round(106 * K), round(106 * K * bar.height / bar.width)), Image.LANCZOS), "fp_bar.png")

# Fundo do minigame (camada "fundominigame", 775x1033): imagem enviada pelo Vitor, com cantos transparentes.
bg_path = Path(__file__).resolve().parent.parent / "IUREF" / "pesca" / "fundominigame.webp"
if bg_path.exists():
    bg = Image.open(bg_path).convert("RGBA").resize((round(775 * K), round(1033 * K)), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    bg.save(OUT / "fp_bg.webp", quality=92, method=6)
    print("fp_bg.webp", bg.size)


# ---------------------------------------------------------------------------------------------------------------------
# Tela "Pescaria concluída" (página PremioPesca do Figma). Fontes baixadas em IUREF/pesca/premio/ (raw_1 = container vazio,
# raw_3 = folha com os botões, raw_4 = folha de ícones, raw_6 = triângulo vermelho). Medidas em unidades do Figma, K = 1,5.
PREMIO = SRC / "premio"


def pload(name: str) -> Image.Image:
    return Image.open(PREMIO / name).convert("RGBA")


def crop_to(sheet: Image.Image, tr, w: float, h: float) -> Image.Image:
    return crop_sheet(sheet, tr, w, h)


def union_pair(normal: Image.Image, pressed: Image.Image, nw: float, nh: float, pw: float, ph: float, name: str) -> None:
    """Normal e clicado no MESMO canvas (o maior dos dois), cada um centralizado: o botão não pula ao apertar."""
    cw, ch = max(nw, pw), max(nh, ph)
    cw_px, ch_px = round(cw * K), round(ch * K)
    for image, label in ((normal, ""), (pressed, "_down")):
        canvas = Image.new("RGBA", (cw_px, ch_px), (0, 0, 0, 0))
        canvas.alpha_composite(image, ((cw_px - image.width) // 2, (ch_px - image.height) // 2))
        save(canvas, f"{name}{label}.png")


buttons = pload("raw_3.png")
sheet4 = pload("raw_4.png")
save(fill(pload("raw_1.png"), 659, 818), "fp_res_card.png")
union_pair(
    crop_to(buttons, [[0.19626998901367188, 0, 0.4484902322292328], [0, 0.05654974654316902, 0.7909806370735168]], 243, 87),
    crop_to(buttons, [[0.1714031994342804, 0, 0.8152753114700317], [0, 0.05654974654316902, 0.7909806370735168]], 226, 93),
    243, 87, 226, 93, "fp_res_again")
union_pair(
    crop_to(buttons, [[0.14476022124290466, 0, 0.008880995213985443], [0, 0.05654974654316902, 0.7909806370735168]], 180, 87),
    crop_to(buttons, [[0.1420959085226059, 0, 0.29307281970977783], [0, 0.05654974654316902, 0.7909806370735168]], 177, 87),
    180, 87, 177, 87, "fp_res_leave")
save(fill(pload("raw_6.png"), 73, 73), "fp_res_marker.png")
save(crop_to(sheet4, [[0.21961326897144318, 0, 0.10582790523767471], [0, 0.2900552749633789, 0.3792570233345032]], 30, 30), "fp_res_ruler.png")
save(crop_to(sheet4, [[0.21754145622253418, 0, 0.391133576631546], [0, 0.285451203584671, 0.3756907284259796]], 30, 30), "fp_res_trophy.png")
