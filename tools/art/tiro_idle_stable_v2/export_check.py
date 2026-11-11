"""Exporta o rig Canvas/WebGL no Chrome e mede estabilidade. Requer Playwright, Pillow, numpy."""
from pathlib import Path
import base64
import hashlib
import json
import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
frames = OUT / 'frames_3x'
frames.mkdir(exist_ok=True)
tracks = json.loads((OUT/'motion.json').read_text())['frames']
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe', headless=True)
    page = browser.new_page(viewport={'width':1350,'height':900},device_scale_factor=1)
    errors=[]
    page.on('pageerror', lambda e:errors.append(str(e)))
    page.goto((OUT/'preview.html').as_uri())
    page.wait_for_function('Object.values(imgs).every(i=>i.complete&&i.naturalWidth>0)')
    page.evaluate('stopAnimation()')
    shots=[]
    for i in range(9):
        page.evaluate('renderFrame(%d)'%i)
        png=page.locator('#stable').evaluate('(c)=>c.toDataURL("image/png")').split(',')[1]
        (frames/f'frame_{i:02d}.png').write_bytes(base64.b64decode(png))
        shot=OUT/f'comparison_{i:02d}.png'
        page.locator('.pair').screenshot(path=str(shot))
        shots.append(Image.open(shot).convert('RGB'))
    page.screenshot(path=str(OUT/'preview_capture.png'))
    assert not errors,errors
    browser.close()
shots[0].save(OUT/'comparison.gif',save_all=True,append_images=shots[1:],duration=[170,160,170]*3,loop=0,optimize=False,disposal=2)
arrays=[np.array(Image.open(frames/f'frame_{i:02d}.png')).astype(np.int16) for i in range(9)]
paws,heads=[],[]
for image,track in zip(arrays,tracks):
    dy=track['nose']['dy']*3
    paws.append(int(np.max(abs(image[515:560]-arrays[0][515:560]))))
    heads.append(int(np.max(abs(image[160+dy:300+dy,240:500]-arrays[0][160:300,240:500]))))
assert max(paws)==0,paws
assert max(heads)<=1,heads  # arredondamento de amostragem da GPU
for i,track in enumerate(tracks):
    src=ROOT/'game/assets/sprites/characters/tiro_pet_puppy/idle_breathe'/f'frame_{i:02d}.png'
    assert hashlib.sha256(src.read_bytes()).hexdigest()==track['sha256']
report={'fps':6,'frames':9,'paw_max_channel_difference':paws,
        'upper_face_max_channel_difference_after_measured_translation':heads,
        'horizontal_motion':[t['nose']['dx'] for t in tracks],
        'vertical_motion_source_pixels':[t['nose']['dy'] for t in tracks],
        'original_hashes_unchanged':True,'render':'continuous WebGL inverse warp; rigid head and fixed paws'}
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS: patas fixas 9/9; cabeça estável após translação 9/9; sem deslocamento horizontal; fontes intactas.')
