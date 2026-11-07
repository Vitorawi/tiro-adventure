"""Install the supplied sheets unchanged; keep their frame timing and registration."""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Animaref/animation-pack'
TARGET = ROOT / 'game/assets/sprites/characters/tiro_pet_puppy_animaref'
TARGET.mkdir(parents=True, exist_ok=True)
clips = {'idle_breathe': 'Animate-the-baby-pup-2',
         'head_tilt': 'Animate-the-baby-pup-1',
         'close_eyes': 'Animate-the-baby-pup'}
lines = ['extends RefCounted', '## Imported from Animaref; original pixels, frame rectangles and durations.', 'const CLIPS := {']
for clip, name in clips.items():
    data = json.loads((SOURCE / (name + '.json')).read_text())
    shutil.copyfile(SOURCE / data['meta']['image'], TARGET / (clip + '.png'))
    entries = list(data['frames'].values())
    assert len(entries) == 36 and all(not e['rotated'] and not e['trimmed'] for e in entries)
    assert all(e['frame']['w'] == 415 and e['frame']['h'] == 544 for e in entries)
    times = ', '.join(str(e['duration'] / 1000) for e in entries)
    lines.append(f'\t&"{clip}": [{times}],')
lines.extend(['}', '', 'static func frames(clip: StringName) -> Array[Texture2D]:',
              '\tvar result: Array[Texture2D] = []',
              '\tif not CLIPS.has(clip): return result',
              '\tvar path := "res://assets/sprites/characters/tiro_pet_puppy_animaref/%s.png" % clip',
              '\tif not ResourceLoader.exists(path): return result',
              '\tvar sheet: Texture2D = load(path)',
              '\tfor i: int in CLIPS[clip].size():',
              '\t\tvar frame := AtlasTexture.new()',
              '\t\tframe.atlas = sheet',
              '\t\tframe.region = Rect2((i % 6) * 415, (i / 6) * 544, 415, 544)',
              '\t\t# Shared canvas preserves the existing home scale and foot baseline.',
              '\t\tframe.margin = Rect2(300, 190, 601, 313)',
              '\t\tframe.filter_clip = true',
              '\t\tresult.append(frame)',
              '\treturn result', ''])
(ROOT / 'game/scripts/ui/animaref_clips.gd').write_text('\n'.join(lines), encoding='utf-8')
print('Installed 3 unchanged sheets, 108 frames; generated timing metadata.')
