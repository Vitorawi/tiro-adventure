"""Prepara cópias WebP das fontes aprovadas, sem alterar os PNGs (requer Pillow)."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
assets = {
    'puppy': 'tiro_puppy_box_v1_shiny.png',
    'farm': 'tiro_carrot_chase_v2_shiny.png',
    'logo': 'logo_as_aventuras_de_tiro_tiro_v1.png',
    'track': 'loading_track_v1.png',
    'fill': 'loading_fill_v1.png',
}
target = root / 'game/web/loading'
target.mkdir(parents=True, exist_ok=True)
for name, source in assets.items():
    image = Image.open(root / 'tools/art/loading' / source)
    if name in ('logo', 'track', 'fill'):
        image = image.crop(image.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox())
    image.thumbnail((1080, 1920) if name in ('puppy', 'farm') else (1200, 520))
    image.save(target / (name + '.webp'), quality=90, method=6)
