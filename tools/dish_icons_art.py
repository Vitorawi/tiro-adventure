"""Ícones PROVISÓRIOS dos ingredientes novos da primeira semana (E02), tingidos a partir dos ícones existentes.
Lista em docs/plans/primeira_semana/PROVISORIOS.md; a E16 troca por arte final.
Uso: py -X utf8 -I tools/dish_icons_art.py"""
import colorsys
from pathlib import Path
from PIL import Image

ICONS = Path(__file__).resolve().parent.parent / "game" / "assets" / "sprites" / "ui" / "icons"


def tint(source: str, target: str, hue_shift: float, sat: float = 1.0, val: float = 1.0) -> None:
    img = Image.open(ICONS / f"item_{source}.png").convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + hue_shift) % 1.0
            s = min(1.0, s * sat)
            v = min(1.0, v * val)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    img.save(ICONS / f"item_{target}.png")
    print("ok", target, img.size)


tint("carrot", "zucchini", 0.22)          # abobrinha: cenoura virada para o verde
tint("wheat", "oat", 0.0, 0.55, 1.05)     # aveia: trigo mais pálido
tint("wheat", "rice", 0.0, 0.12, 1.25)    # arroz: trigo quase branco
tint("corn", "banana", 0.01, 0.85, 1.12)       # banana: milho amarelo-claro
tint("apple", "watermelon", 0.94, 0.85, 1.05)   # melancia: maçã virada para o rosa
tint("puppy_mash", "gororoba", 0.0, 0.35, 0.65)  # gororoba: papinha acinzentada
