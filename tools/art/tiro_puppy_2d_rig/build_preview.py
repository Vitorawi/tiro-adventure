"""Audit original art and native rig renders; package a review GIF/HTML.

This is a render export, not generative editing or a new drawing of the dog.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
paths=sorted((ROOT/'build/screenshots/puppy_2d_rig').glob('frame_*.png'))
assert len(paths)==103
frames=[Image.open(path).convert('RGB') for path in paths]
neutral_errors=[];foot_errors=[];action_differences=[]
for i,frame in enumerate(frames):
    assert frame.size==(768,400)
    pixels=np.array(frame)
    reference=pixels[44:368,:384].astype(int)
    rig=pixels[44:368,384:].astype(int)
    difference=np.abs(reference-rig)
    if i<36 or i>=67:
        neutral_errors.append(int(difference.max()))
    else:
        action_differences.append(int(difference[:180].max()))
    # Native rasterization of polygons can round UVs slightly. The actual
    # planted paws below source y=460 are identical, not just unmoved controls.
    foot_errors.append(int(difference[230:].max()))
assert max(neutral_errors)==0
assert max(foot_errors)==0
assert max(action_differences)>30,'Head has not actually moved in the rendered image'
manifest=json.loads((HERE.parent/'puppy_idle_live/manifest.json').read_text())
for item in manifest['files']:
    assert hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest()==item['sha256']
palette_source=Image.new('RGB',(384*6,200))
for j,index in enumerate([0,36,44,50,60,68]):
    palette_source.paste(frames[index].resize((384,200)),(j*384,0))
palette=palette_source.quantize(colors=256)
gif=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
durations=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(gif))]
gif[0].save(HERE/'comparison.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0,disposal=2,optimize=False)
frames[50].save(HERE/'comparison_still.png')
embedded=[]
for frame in frames:
    buffer=io.BytesIO();frame.save(buffer,format='WEBP',lossless=True,method=4)
    embedded.append('data:image/webp;base64,'+base64.b64encode(buffer.getvalue()).decode())
template=(HERE/'template.html').read_text(encoding='utf8')
(HERE/'preview.html').write_text(template.replace('__FRAMES__',json.dumps(embedded)),encoding='utf8')
report={
 'source':'Nine approved idle PNGs; existing artwork; no generation or re-painting',
 'original_9_sha256_unchanged':True,'native_captures':len(frames),'capture_fps':24,
 'neutral_native_max_rgb_error':max(neutral_errors),
 'planted_paws_native_max_rgb_error':max(foot_errors),
 'head_motion_confirmed':True,'pose':'idle -> head tilt -> idle',
 'scene':'game/scenes/art/puppy_2d_rig/puppy_2d_rig.tscn',
 'checks':['3 connected skin meshes with normalized BodyAnchor/Head weights',
  'Shared original 9-frame breathing clock at 6 fps','Tilt duration 9/7 s',
  'Soft cancellation without a pose jump or restarting breathing'],
 'scope':'Initial front-pose rig only; not wired into PetAnimator and not published',
 'remaining':['Independent ear/eye/jaw/limb layers','Hidden surface artwork and other views',
  'Yawn/scratch/roll/stand and actual game transitions','User visual approval']}
(HERE/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('PASS: original 9 hashes intact; rest exact in native GPU image; planted paws exact in all 103 renders; head moves; GIF and lossless HTML prepared.')
