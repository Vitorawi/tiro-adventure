"""Ícones provisórios do Ensopado Dourado (F04b): derivados dos ícones existentes com tom dourado.

Uso: py -X utf8 -I tools/secret_stew_icons.py   (depois: godot --headless --path game --import)
Sem PixelLab. Registrados em docs/plans/primeira_semana/PROVISORIOS.md.
"""
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent / "game" / "assets" / "sprites" / "ui"

# (origem, destino)
JOBS = [
    ("icons/item_bait_worm.png", "icons/item_golden_worm.png"),
    ("icons/item_fish_tilapia.png", "icons/item_fish_golden.png"),
    ("icons/item_fish_stew.png", "icons/item_golden_stew.png"),
    ("fishing/fish_tilapia.png", "fishing/fish_golden.png"),
]


def gold(source: Path, target: Path) -> None:
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A")
    shade = ImageOps.autocontrast(image.convert("L"), cutoff=2)
    tinted = ImageOps.colorize(shade, black=(92, 52, 4), mid=(240, 176, 28), white=(255, 246, 170)).convert("RGBA")
    tinted.putalpha(alpha)
    tinted.save(target)
    print("ok", target.relative_to(ROOT))


for origin, destination in JOBS:
    gold(ROOT / origin, ROOT / destination)
