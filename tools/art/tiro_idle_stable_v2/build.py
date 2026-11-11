"""Mede o movimento no pixel e monta a demonstração de rig WebGL sem redesenhar quadros.

Requer numpy, OpenCV e Pillow. Os sprites de game/ só são lidos.
"""
import base64
import hashlib
import json
from pathlib import Path
import cv2
import numpy as np
from PIL import Image

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
source=ROOT/'game/assets/sprites/characters/tiro_pet_puppy/idle_breathe'
base=np.array(Image.open(source/'frame_00.png').convert('RGBA'))
tracks=[]
for path in sorted(source.glob('*.png')):
    image=np.array(Image.open(path).convert('RGBA'))
    record={'frame':int(path.stem[-2:]),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    for name,region in [('nose',(114,87,131,100)),('chest',(99,135,143,157))]:
        x,y,r,b=region
        _,score,_,pos=cv2.minMaxLoc(cv2.matchTemplate(image[y-12:b+12,x-8:r+8,:3],base[y:b,x:r,:3],cv2.TM_CCOEFF_NORMED))
        record[name]={'dx':pos[0]-8,'dy':pos[1]-12,'confidence':score}
    tracks.append(record)
assert all(t['nose']['dx']==0 for t in tracks)
motion={'fps':6,'frames':tracks,'source':'idle_breathe','closed_expression_offset':[1,1]}
(OUT/'motion.json').write_text(json.dumps(motion,indent=2),encoding='utf-8')
old=ROOT/'tools/art/tiro_idle_shiny_v1'
paths={'__SOURCE__':old/'source_sheet.png','__PREVIOUS__':old/'registered_sheet.png',
       '__BASE__':old/'frames_3x/frame_00.png','__CLOSED__':old/'frames_3x/frame_08.png'}
assets={key:'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode() for key,path in paths.items()}
(OUT/'assets.json').write_text(json.dumps(assets),encoding='utf-8')
html=(OUT/'template.html').read_text(encoding='utf-8').replace('__ASSETS__',json.dumps(assets)).replace('__TRACKS__',json.dumps(tracks))
(OUT/'preview.html').write_text(html,encoding='utf-8')
