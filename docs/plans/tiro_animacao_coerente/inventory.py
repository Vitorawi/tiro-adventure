"""Read-only inventory of the actual puppy resources and original timings."""
import hashlib
import json
import re
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
sprite_root=ROOT/'game/assets/sprites/characters/tiro_pet_puppy'
script=(ROOT/'game/scripts/ui/pet_animator.gd').read_text(encoding='utf8')
fps={k:float(v) for k,v in re.findall(r'&"([a-z_]+)": ([0-9.]+)',script[script.index('const FPS'):script.index('const REACTIONS')])}
rows=[]
for directory in sorted(sprite_root.iterdir()):
    if not directory.is_dir(): continue
    files=sorted(directory.glob('frame_*.png'))
    rate=fps.get(directory.name)
    rows.append({'clip':directory.name,'frames':len(files),'fps':rate,
      'duration_seconds':len(files)/rate if rate else None,
      'files':[{'file':str(path.relative_to(ROOT)).replace('\\','/'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()} for path in files]})
summary={'scope':'PetScreen puppy body; original resources only',
 'animated_sequences':sum(x['fps'] is not None for x in rows),'static_poses':sum(x['fps'] is None for x in rows),
 'total_frames':sum(x['frames'] for x in rows),'fallback':{'give_paw':'wag_excited'},'clips':rows}
(HERE/'inventory.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
print(summary['animated_sequences'],'animated sequences +',summary['static_poses'],'static pose;',summary['total_frames'],'frames hashed')
