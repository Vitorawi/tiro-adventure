"""Install the supplied sheets unchanged; keep their frame timing and registration."""
import json
import shutil
import hashlib
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Animaref/animation-pack'
TARGET = ROOT / 'game/assets/sprites/characters/tiro_pet_puppy_animaref'
TARGET.mkdir(parents=True, exist_ok=True)
clips = {'idle_breathe': (SOURCE, 'Animate-the-baby-pup-2'),
         'head_tilt': (SOURCE, 'Animate-the-baby-pup-1'),
         'close_eyes': (SOURCE, 'Animate-the-baby-pup'),
         'eat_enter': (ROOT / 'Animaref/baby_eat', 'Animate-the-baby-pup-1'),
         'eat_loop': (ROOT / 'Animaref/baby_eat', 'Animate-the-baby-pup-2'),
         'eat_exit': (ROOT / 'Animaref/baby_eat', 'Animate-the-baby-pup-3'),
         'bath': (ROOT / 'Animaref/baby_bath', 'sprite-max-px-frames-36-rows-6-cols-6'),
         'play_ball': (ROOT / 'Animaref/baby_ball', 'sprite-max-px-frames-36-rows-6-cols-6'),
         'sleep_enter': (ROOT / 'Animaref/baby_sleep', 'Animate-the-baby-pup-2'),
         'sleep_loop': (ROOT / 'Animaref/baby_sleep', 'Animate-the-baby-pup-1'),
         'sleep_exit': (ROOT / 'Animaref/baby_sleep', 'Animate-the-baby-pup'),
         'pet_head': (ROOT / 'Animaref/baby_reactions', 'Animate-the-baby-pup-1'),
         'sad': (ROOT / 'Animaref/baby_reactions', 'Animate-the-baby-pup'),
         'lick_paw': (ROOT / 'Animaref/baby_reactions', 'It-is-a-dog-Remain-'),
         'belly_enter': (ROOT / 'Animaref/baby_belly', 'Animate-the-baby-pup'),
         'belly_loop': (ROOT / 'Animaref/baby_belly', 'Animate-the-baby-pup-1'),
         'belly_exit': (ROOT / 'Animaref/baby_belly', 'Animate-the-baby-pup-2')}
layouts = []
exit_margins = []
bath_margins = []
ball_margins = []
sleep_margins = []
reaction_margins = []
belly_margins = []
IDLE_SHA256 = 'fb010a541283d6ff575032edf172642b569b0d22eae062a11f1e4f0d9d4ca0b5'

def match(source_box, target_box):
    x, y, right, bottom = source_box
    tx, ty, tr, tb = target_box
    sw, sh, tw, th = right-x, bottom-y, tr-tx, tb-ty
    factor = (sw*tw + sh*th) / (sw*sw + sh*sh)
    return factor, (tx+tr)/2 - factor*(x+right)/2, (ty+tb)/2 - factor*(y+bottom)/2

def compose(outer, inner):
    scale, x, y = outer
    inner_scale, ix, iy = inner
    return scale*inner_scale, x+scale*ix, y+scale*iy

def endpoints(clip):
    source, name = clips[clip]
    data = json.loads((source / (name+'.json')).read_text())
    entries = list(data['frames'].values())
    with Image.open(source / data['meta']['image']) as image:
        boxes = []
        for entry in (entries[0], entries[-1]):
            r = entry['frame']
            boxes.append(image.crop((r['x'], r['y'], r['x']+r['w'], r['y']+r['h'])).getbbox())
    return boxes

belly_bounds = {clip: endpoints(clip) for clip in ('belly_enter', 'belly_loop', 'belly_exit')}
belly_start = match(belly_bounds['belly_enter'][0], (18, 14, 397, 544))
# Keep the lying puppy centered and grounded in the same fixed idle canvas.
# Only translate the entrance as it rolls; preserve its scale and anatomy.
bx, by, br, bb = belly_bounds['belly_enter'][1]
bs = belly_start[0]
belly_end = (bs, 207.5-bs*(bx+br)/2, 544-bs*bb)
belly_loop = compose(belly_end, match(belly_bounds['belly_loop'][0], belly_bounds['belly_enter'][1]))
belly_exit_start = compose(belly_loop, match(belly_bounds['belly_exit'][0], belly_bounds['belly_loop'][1]))
belly_exit_end = match(belly_bounds['belly_exit'][1], (18, 14, 397, 544))

sleep_bounds = {}
for clip in ('sleep_enter', 'sleep_loop', 'sleep_exit'):
    source, name = clips[clip]
    data = json.loads((source / (name+'.json')).read_text())
    frames = list(data['frames'].values())
    with Image.open(source / data['meta']['image']) as image:
        boxes = []
        for entry in (frames[0], frames[-1]):
            r = entry['frame']
            boxes.append(image.crop((r['x'], r['y'], r['x']+r['w'], r['y']+r['h'])).getbbox())
        sleep_bounds[clip] = boxes
# The entrance is the fixed reference. Fit lying to its final pose, and
# wake to the loop endpoint at first and to the exact idle registration last.
sleep_base = match(sleep_bounds['sleep_enter'][0], (18, 14, 397, 544))
sleep_loop = compose(sleep_base, match(sleep_bounds['sleep_loop'][0], sleep_bounds['sleep_enter'][1]))
wake_start = compose(sleep_loop, match(sleep_bounds['sleep_exit'][0], sleep_bounds['sleep_loop'][1]))
wake_end = match(sleep_bounds['sleep_exit'][1], (18, 14, 397, 544))
lines = ['extends RefCounted', '## Imported from Animaref; original pixels, frame rectangles and durations.', '## Crop/scale of the phone-sized sheets (tools/optimize_animaref.py); idle is not in it.', 'const PACK := preload("res://scripts/ui/animaref_pack.gd").PACK', 'const CLIPS := {']
for clip, (source, name) in clips.items():
    data = json.loads((source / (name + '.json')).read_text())
    if clip == 'idle_breathe':
        # Vitor's locked reference: never rewrite the approved idle.
        assert hashlib.sha256((source / data['meta']['image']).read_bytes()).hexdigest() == IDLE_SHA256
        idle_target = TARGET / 'idle_breathe.png'
        if idle_target.exists():
            assert hashlib.sha256(idle_target.read_bytes()).hexdigest() == IDLE_SHA256
        else:
            shutil.copyfile(source / data['meta']['image'], idle_target)
    elif clip not in ('bath', 'play_ball'):
        shutil.copyfile(source / data['meta']['image'], TARGET / (clip + '.png'))
    entries = list(data['frames'].values())
    assert len(entries) == 36 and all(not e['rotated'] and not e['trimmed'] for e in entries)
    w, h = entries[0]['frame']['w'], entries[0]['frame']['h']
    assert all(e['frame']['w'] == w and e['frame']['h'] == h for e in entries)
    assert all(e['frame']['x'] == (i % 6) * w and e['frame']['y'] == (i // 6) * h for i, e in enumerate(entries))
    if clip == 'idle_breathe':
        assert (w, h) == (415, 544) and all(e['duration'] == 105 for e in entries)
    if clip in ('bath', 'play_ball'):
        # Lossless atlas packaging only: keep pages below 4096 px on mobile.
        with Image.open(source / data['meta']['image']) as image:
            columns = 3 if clip == 'play_ball' else 6
            rows = 18 // columns
            for page in range(2):
                packed = Image.new('RGBA', (columns*w, rows*h))
                for local in range(18):
                    r = entries[page*18+local]['frame']
                    packed.paste(image.crop((r['x'], r['y'], r['x']+w, r['y']+h)), ((local%columns)*w, (local//columns)*h))
                packed.save(TARGET / f'{clip}_{page}.png')
            bounds = []
            for entry in (entries[0], entries[-1]):
                r = entry['frame']
                bounds.append(image.crop((r['x'], r['y'], r['x']+w, r['y']+h)).getbbox())
        # Register endpoint dog poses only, never the foam or moving ball.
        start, end = (match(box, (18, 14, 397, 544)) for box in bounds)
        for i in range(len(entries)):
            t = i / (len(entries)-1)
            t = t*t*(3-2*t)
            factor, ox, oy = (a+(b-a)*t for a, b in zip(start, end))
            adjusted = ((300+ox)/factor, (190+oy)/factor,
                        1016/factor-w, 857/factor-h)
            margins = ball_margins if clip == 'play_ball' else bath_margins
            margins.append('\tRect2(' + ', '.join(f'{v:.8f}' for v in adjusted) + '),')
    if clip.startswith('eat_'):
        # ONE similarity transform for the complete feeding group, based on
        # idle bbox (18,14,397,544) and entry bbox (4,55,256,407).
        scale = 530 / 352
        dx, dy = 18 - 4 * scale, 14 - 55 * scale
        margin = ((300 + dx) / scale, (190 + dy) / scale,
                  1016 / scale - w, 857 / scale - h)
    else:
        margin = (300, 190, 601, 313)
    layouts.append(f'\t&"{clip}": [Vector2({w}, {h}), Rect2({", ".join(str(v) for v in margin)})],')
    if clip.startswith('belly_'):
        belly_margins.append(f'\t&"{clip}": [')
        for i in range(len(entries)):
            t = i / (len(entries)-1)
            t = t*t*(3-2*t)
            if clip == 'belly_enter': start, end = belly_start, belly_end
            elif clip == 'belly_loop': start = end = belly_loop
            else: start, end = belly_exit_start, belly_exit_end
            factor, ox, oy = (a+(b-a)*t for a, b in zip(start, end))
            adjusted = ((300+ox)/factor, (190+oy)/factor, 1016/factor-w, 857/factor-h)
            belly_margins.append('\t\tRect2(' + ', '.join(f'{v:.8f}' for v in adjusted) + '),')
        belly_margins.append('\t],')
    if clip in ('pet_head', 'sad', 'lick_paw'):
        with Image.open(source / data['meta']['image']) as image:
            bounds = []
            for entry in (entries[0], entries[-1]):
                r = entry['frame']
                bounds.append(image.crop((r['x'], r['y'], r['x']+w, r['y']+h)).getbbox())
        start, end = (match(box, (18, 14, 397, 544)) for box in bounds)
        reaction_margins.append(f'\t&"{clip}": [')
        for i in range(len(entries)):
            t = i / (len(entries)-1)
            t = t*t*(3-2*t)
            factor, ox, oy = (a+(b-a)*t for a, b in zip(start, end))
            adjusted = ((300+ox)/factor, (190+oy)/factor, 1016/factor-w, 857/factor-h)
            reaction_margins.append('\t\tRect2(' + ', '.join(f'{v:.8f}' for v in adjusted) + '),')
        reaction_margins.append('\t],')
    if clip.startswith('sleep_'):
        sleep_margins.append(f'\t&"{clip}": [')
        for i in range(len(entries)):
            t = i / (len(entries)-1)
            t = t*t*(3-2*t)
            if clip == 'sleep_enter': factor, ox, oy = sleep_base
            elif clip == 'sleep_loop': factor, ox, oy = sleep_loop
            else: factor, ox, oy = (a+(b-a)*t for a, b in zip(wake_start, wake_end))
            adjusted = ((300+ox)/factor, (190+oy)/factor, 1016/factor-w, 857/factor-h)
            sleep_margins.append('\t\tRect2(' + ', '.join(f'{v:.8f}' for v in adjusted) + '),')
        sleep_margins.append('\t],')
    if clip == 'eat_exit':
        # The exit was generated smaller than chewing. Match its first pose to
        # the chewing endpoint and its final pose to the entry/idle endpoint.
        # Smoothly interpolate ONE uniform scale + translation (never warp).
        start = match((15, 158, 254, 407), (4, 150, 264, 419))
        end = match((12, 60, 259, 406), (4, 55, 256, 407))
        for i in range(len(entries)):
            t = i / (len(entries)-1)
            t = t*t*(3-2*t)
            factor, ox, oy = (a+(b-a)*t for a, b in zip(start, end))
            adjusted = ((300+dx+scale*ox)/(scale*factor),
                        (190+dy+scale*oy)/(scale*factor),
                        1016/(scale*factor)-w, 857/(scale*factor)-h)
            exit_margins.append('\tRect2(' + ', '.join(f'{v:.8f}' for v in adjusted) + '),')
    times = ', '.join(str(e['duration'] / 1000) for e in entries)
    lines.append(f'\t&"{clip}": [{times}],')
lines.extend(['}', 'const LAYOUTS := {', *layouts, '}',
              '## Exit scale/placement correction: chew endpoint → original idle endpoint.',
              'const EXIT_MARGINS := [', *exit_margins, ']',
              '## Dry endpoints aligned to idle; foam is excluded from registration.',
              'const BATH_MARGINS := [', *bath_margins, ']',
              '## Ball-free endpoint poses registered to idle; keep the original paw action.',
              'const BALL_MARGINS := [', *ball_margins, ']',
              '## Fixed entrance/loop; wake compensation bridges lying back to original idle.',
              'const SLEEP_MARGINS := {', *sleep_margins, '}',
              '## Idle-to-idle registration; preserve the original head/paw movement.',
              'const REACTION_MARGINS := {', *reaction_margins, '}',
              '## Belly registration is applied only to new clips. Idle is immutable.',
              'const BELLY_MARGINS := {', *belly_margins, '}', '', 'static func exists(clip: StringName) -> bool:',
              '	if not CLIPS.has(clip): return false',
              '	var base := "res://assets/sprites/characters/tiro_pet_puppy_animaref/%s" % clip',
              '	if clip in [&"bath", &"play_ball"]:',
              '		return ResourceLoader.exists(base + "_0.png") and ResourceLoader.exists(base + "_1.png")',
              '	return ResourceLoader.exists(base + ".png")', '',
              'static func frames(clip: StringName) -> Array[Texture2D]:',
              '\tvar result: Array[Texture2D] = []',
              '\tif not CLIPS.has(clip): return result',
              '\tvar path := "res://assets/sprites/characters/tiro_pet_puppy_animaref/%s.png" % clip',
              '\tvar paged := clip in [&"bath", &"play_ball"]',
              '\tif paged: path = path.replace("%s.png" % clip, "%s_0.png" % clip)',
              '\tif not ResourceLoader.exists(path): return result',
              '\tvar sheet: Texture2D = load(path)',
              '\tvar second: Texture2D',
              '\tif paged:',
              '\t\tvar other := path.replace("%s_0.png" % clip, "%s_1.png" % clip)',
              '\t\tif not ResourceLoader.exists(other): return result',
              '\t\tsecond = load(other)',
              '\tvar size: Vector2 = LAYOUTS[clip][0]',
              '\tfor i: int in CLIPS[clip].size():',
              '\t\tvar frame := AtlasTexture.new()',
              '\t\tframe.atlas = second if paged and i >= 18 else sheet',
              '\t\tvar local_index: int = i % 18 if paged else i',
              '\t\tvar columns: int = 3 if clip == &"play_ball" else 6',
              '\t\tframe.region = Rect2(Vector2(local_index % columns, local_index / columns) * cell, cell)',
              '\t\t# Shared canvas preserves the existing home scale and foot baseline.',
              '\t\tframe.margin = EXIT_MARGINS[i] if clip == &"eat_exit" else LAYOUTS[clip][1]',
              '\t\tif clip == &"bath": frame.margin = BATH_MARGINS[i]',
              '\t\tif clip == &"play_ball": frame.margin = BALL_MARGINS[i]',
              '\t\tif SLEEP_MARGINS.has(clip): frame.margin = SLEEP_MARGINS[clip][i]',
              '\t\tif REACTION_MARGINS.has(clip): frame.margin = REACTION_MARGINS[clip][i]',
              '\t\tif BELLY_MARGINS.has(clip): frame.margin = BELLY_MARGINS[clip][i]',
              '\t\tframe.filter_clip = true',
              '\t\tresult.append(frame)',
              '\treturn result', ''])
(ROOT / 'game/scripts/ui/animaref_clips.gd').write_text('\n'.join(lines), encoding='utf-8')
print('Installed 612 frames; belly balanced to locked idle; approved idle hash/timing verified, not rewritten.')
