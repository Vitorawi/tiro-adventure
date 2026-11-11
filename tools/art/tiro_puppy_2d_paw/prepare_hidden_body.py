"""Technical canvas registration of the image_gen hidden-body plate.

The plate is only sampled through the foreleg mask in the rig. Original visible
art is never replaced or re-painted by this preparation.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
raw=HERE/'hidden_body_generated.png'
target=ROOT/'game/assets/sprites/characters/tiro_pet_puppy_illustrated/rig/hidden_body.png'
target.parent.mkdir(parents=True,exist_ok=True)
source=Image.open(raw).convert('RGBA').resize((768,648),Image.Resampling.LANCZOS)
registered=Image.new('RGBA',(768,648))
# Body/chest/rear-foot matching measured after resizing: generated y=-1px.
registered.paste(source,(0,1))
registered.save(target)
report={'source':str(raw.relative_to(ROOT)).replace('\\','/'),'source_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),
 'tool':'built-in image_gen','prompt':'hidden_body_prompt.txt','registration':{'canvas':[768,648],'translation':[0,1]},
 'usage':'Hidden body only inside image-right foreleg mask. Never sample the generated face.',
 'output':str(target.relative_to(ROOT)).replace('\\','/'),'output_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
 'scope':'New hidden surface, not a new dog design or replacement of approved PNGs'}
(HERE/'asset_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('Prepared registered hidden body; original artwork untouched')
