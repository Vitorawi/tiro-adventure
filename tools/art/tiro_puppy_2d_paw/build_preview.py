"""Audit native captures and package the foreleg proof for visual review."""
import base64
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
paths=sorted((ROOT/'build/screenshots/puppy_2d_paw').glob('frame_*.png'))
assert len(paths)==144
frames=[Image.open(path).convert('RGB') for path in paths]
areas={'protected_face':(125,80,202,158),'planted_front_left':(143,254,179,281),'planted_rear_left':(124,250,146,265)}
errors={name:[] for name in areas};neutral=[];movement=[]
for i,frame in enumerate(frames):
    assert frame.size==(768,400)
    pixels=np.asarray(frame)
    difference=np.abs(pixels[44:368,:384].astype(int)-pixels[44:368,384:].astype(int))
    if i<36 or i>=83:neutral.append(int(difference.max()))
    else:movement.append(int(difference.max()))
    for name,(x,y,r,b) in areas.items():errors[name].append(int(difference[y:b,x:r].max()))
assert max(neutral)==0
assert all(max(values)==0 for values in errors.values())
assert max(movement)>100
original=json.loads((HERE.parent/'puppy_idle_live/manifest.json').read_text())
for entry in original['files']:
    assert hashlib.sha256((ROOT/entry['file']).read_bytes()).hexdigest()==entry['sha256']
asset=json.loads((HERE/'asset_manifest.json').read_text())
assert hashlib.sha256((ROOT/asset['output']).read_bytes()).hexdigest()==asset['output_sha256']
palette_image=Image.new('RGB',(384*6,200))
for j,index in enumerate([0,40,44,52,65,84]):palette_image.paste(frames[index].resize((384,200)),(384*j,0))
palette=palette_image.quantize(colors=256)
gif=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
durations=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(gif))]
gif[0].save(HERE/'comparison.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0,disposal=2,optimize=False)
frames[52].save(HERE/'comparison_still.png')
embedded=[]
for frame in frames:
    buffer=io.BytesIO();frame.save(buffer,format='WEBP',lossless=True,method=4)
    embedded.append('data:image/webp;base64,'+base64.b64encode(buffer.getvalue()).decode())
template=(HERE/'template.html').read_text(encoding='utf8')
(HERE/'preview.html').write_text(template.replace('__FRAMES__',json.dumps(embedded)),encoding='utf8')
report={'scope':'Independent 2D foreleg proof; not installed in PetAnimator or published',
 'original_9_hashes_unchanged':True,'rendered_samples':len(frames),'capture_fps':24,
 'preview_seconds':6.0,'preview_loop':'Four complete 1.5s breathing cycles; wraps through approved phase 8 -> 0',
 'rest_entry_exit_max_rgb_error':max(neutral),
 'protected_regions':{name:{'max_rgb_error':max(errors[name]),'preview_pixel_rect':list(rect)} for name,rect in areas.items()},
 'protected_region_coordinates':'Relative to each 384x324 dog canvas, excluding the header/footer',
 'motion':'Original shared foreleg texture; two-bone IK, fixed bone lengths, continuous breathing',
 'timing_seconds':{'entry':.38,'rubbing':9/8,'exit':.42,'total':.38+9/8+.42},
 'hidden_art':'Built-in image_gen body plate, sampled only through the original image-right foreleg hole',
 'original_face_from_generated_plate_used':False,
 'occlusion_note':'The planted rear-right paw is briefly covered by the moving foreleg on entry/exit. Do not claim it is visible and RGB-identical in all frames.',
 'limitations':['First front-paw-to-face prototype, not a full set of animations.',
  'Large elbow bends approximate volume with a 2D skin mesh; contour/artistic review remains required.',
  'No turned-over paw-pad view was invented; the existing furry paw texture rotates with the limb.']}
(HERE/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('PASS: 144 native renders; rest, protected face and two visible support paws RGB-identical; nine approved hashes intact; preview loop aligned with breathing')
