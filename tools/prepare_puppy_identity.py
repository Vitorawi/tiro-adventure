"""Derive static puppy portraits from Vitor's exact reference, without repainting."""
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools/art/puppy_identity/reference.png'
TARGET = ROOT / 'game/assets/sprites/characters/tiro_pet_puppy_animaref'
TARGET.mkdir(parents=True, exist_ok=True)
shutil.copyfile(SOURCE, TARGET / 'reference.png')
with Image.open(SOURCE) as image:
    assert image.size == (768, 648)
    bounds = image.getbbox()
    image.crop((bounds[0]-8, bounds[1]-8, bounds[2]+8, bounds[3]+8)).save(TARGET / 'reference_front.png')
    image.crop((214, 136, 524, 372)).save(TARGET / 'reference_head.png')
print('Reference copied unchanged; head and front are exact crops. Approved idle untouched.')
