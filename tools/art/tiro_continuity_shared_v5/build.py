"""Package native Godot renders; check full transitions against the shared skin.

No image generation or creative asset editing: input is the native renderer's
103 screenshots. The GIF/HTML are only review exports of that motion proof.
"""
import base64
import hashlib
import io
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
CAPTURES=ROOT/'build/screenshots/puppy_shared_pose'
paths=sorted(CAPTURES.glob('frame_*.png'))
assert len(paths)==103
frames=[Image.open(p).convert('RGB') for p in paths]
assert all(im.size==(960,330) for im in frames)
arrays=[np.asarray(im) for im in frames]

# Each phase of approved idle has a neutral render before the action starts.
# The new column must retain exactly the same lower torso and paws at that
# breathing phase, including DURING the action. This checks actual GPU output.
body_errors=[]
for i,frame in enumerate(arrays):
    phase=(i//4)%9
    reference=arrays[phase*4]
    delta=np.abs(frame[206:300,640:960].astype(int)-reference[206:300,640:960].astype(int))
    body_errors.append(int(delta.max()))
assert max(body_errors)==0,body_errors

entry=36
exit_=math.ceil((1.5+9/7)*24)
entry_error=int(np.abs(arrays[entry][32:300,640:960].astype(int)-arrays[0][32:300,640:960].astype(int)).max())
exit_reference=((exit_//4)%9)*4
exit_error=int(np.abs(arrays[exit_][32:300,640:960].astype(int)-arrays[exit_reference][32:300,640:960].astype(int)).max())
assert entry_error==exit_error==0,(entry_error,exit_error)

manifest=json.loads((HERE.parent/'puppy_idle_live/manifest.json').read_text())
for entry_ in manifest['files']:
    assert hashlib.sha256((ROOT/entry_['file']).read_bytes()).hexdigest()==entry_['sha256']

# One shared palette avoids changes of colour caused by per-frame GIF palettes.
palette_source=Image.new('RGB',(480*6,165))
for j,index in enumerate([0,36,44,50,60,68]):
    palette_source.paste(frames[index].resize((480,165)),(j*480,0))
palette=palette_source.quantize(colors=256)
gif=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
durations=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(gif))]
gif[0].save(HERE/'comparison.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0,disposal=2,optimize=False)
frames[50].save(HERE/'comparison_still.png')
embedded=[]
for frame in frames:
    buffer=io.BytesIO();frame.save(buffer,format='WEBP',quality=90,method=5)
    embedded.append('data:image/webp;base64,'+base64.b64encode(buffer.getvalue()).decode())
template=(HERE/'template.html').read_text(encoding='utf8')
(HERE/'preview.html').write_text(template.replace('__FRAMES__',json.dumps(embedded)),encoding='utf8')
report={
 'scope':'Head tilt only. Isolated shared-skin rig proof; not installed in PetAnimator.',
 'native_rendered_frames':len(frames),'rate':24,'duration_seconds':len(frames)/24,
 'shared_source':'Nine approved idle drawings; body/face breathing clock continues through action.',
 'approved_idle_9_hashes_unchanged':True,
 'entry_same_phase_neutral_max_channel_error':entry_error,
 'exit_same_phase_neutral_max_channel_error':exit_error,
 'lower_body_vs_same_phase_neutral_max_channel_error':max(body_errors),
 'entry_frame':entry,'exit_frame':exit_,
 'motion':'Original tilt angle keyframes, interpolated; original 9/7 s duration; eyelid patch for blink.',
 'limitations':[
  'Rigid head rotation plus neck skinning approximates source movement; source head translations are not copied.',
  'Yawn/scratch and remaining pixel actions are not converted by this proof.',
  'GPU comparisons validate shared artwork and continuity at boundaries, not final artistic approval.'
 ]}
(HERE/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('PASS: 103 native renders; exact shared lower body in every frame; entry/exit exact neutral by phase; approved source intact.')
