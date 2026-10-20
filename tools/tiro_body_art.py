"""Etapa 04: preparar folhas sem escala, instalar resultados e conferir arte.

Não liga a arte ao jogo. Entradas e saídas intermediárias ficam em build/.
Python com Pillow e numpy (runtime de arte do Codex).
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / 'game/assets/sprites'
CHAR = SPR / 'characters'
OUT = ROOT / 'build/art/tiro_fases'
WORK = OUT / 'producao04'
BASE_PAL = np.array(Image.open(OUT / 'paleta_strip.png').convert('RGB')).reshape(-1, 3)
# As 81 cores do quadro parado não incluem a tigela, bola e outros adereços
# já existentes nos clipes. Acrescentar somente cores opacas dos originais.
original_colors = {tuple(c) for c in BASE_PAL}
for source_dir in ['tiro_pet', 'tiro_world']:
    for source_png in (CHAR / source_dir).rglob('*.png'):
        if 'overlays' not in source_png.parts and 'sleep_belly' not in source_png.parts:
            pixels = np.array(Image.open(source_png).convert('RGBA'))
            original_colors.update(map(tuple, np.unique(pixels[:, :, :3][pixels[:, :, 3] > 127], axis=0)))
PAL = np.array(list(map(tuple, BASE_PAL)) + sorted(original_colors - {tuple(c) for c in BASE_PAL}))


def rgba(p):
    return Image.open(p).convert('RGBA')


def save_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def quantize(im, black_saddle=False):
    a = np.array(im)
    if black_saddle:
        # Mesmo critério de _blacken em growth_art_shots.gd / tiro_coat.
        rgb = a[:, :, :3].astype(float) / 255
        vmax, vmin = rgb.max(2), rgb.min(2)
        saturation = (vmax - vmin) / np.maximum(vmax, 1 / 255)
        saddle = (a[:, :, 3] > 127) & (saturation <= .22) & (vmax >= .22) & (vmax <= .66)
        darks = BASE_PAL[BASE_PAL.max(1) < 51]
        t = np.clip((vmax[saddle] - .22) / .44, 0, 1)
        a[:, :, :3][saddle] = darks[np.minimum((t * len(darks)).astype(int), len(darks) - 1)]
    mask = a[:, :, 3] > 127
    colors, inverse = np.unique(a[:, :, :3][mask], axis=0, return_inverse=True)
    dist = ((colors[:, None].astype(np.int32) - PAL[None].astype(np.int32)) ** 2).sum(2)
    a[:, :, :3][mask] = PAL[dist.argmin(1)][inverse]
    a[:, :, 3] = mask * 255
    a[~mask] = 0
    # Fragmentos isolados da geração (não suaviza nem muda o traço do corpo).
    seen = np.zeros(mask.shape, dtype=bool)
    for sy, sx in zip(*np.where(mask)):
        if seen[sy, sx]:
            continue
        component, queue = [], deque([(sy, sx)])
        seen[sy, sx] = True
        while queue:
            y, x = queue.popleft()
            component.append((y, x))
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
        if len(component) < (16 if max(mask.shape) > 80 else 3):
            for y, x in component:
                a[y, x] = 0
    return Image.fromarray(a)


def prepare():
    WORK.mkdir(parents=True, exist_ok=True)
    protected = {}
    for folder in ['tiro_pet', 'tiro_world']:
        for p in (CHAR / folder).rglob('*.png'):
            if 'sleep_belly' in p.parts:
                continue
            protected[str(p.relative_to(ROOT))] = hashlib.sha256(p.read_bytes()).hexdigest()
    for p in [SPR / 'ui/icons/hud_tiro.png']:
        protected[str(p.relative_to(ROOT))] = hashlib.sha256(p.read_bytes()).hexdigest()
    save_json(WORK / 'adult_hashes.json', protected)
    manifest = []
    for family in ['pet', 'world']:
        source = CHAR / ('tiro_' + family)
        groups = {}
        for p in sorted(source.rglob('*.png')):
            if family == 'pet' and not p.name.startswith('frame_'):
                continue
            if 'overlays' in p.parts or 'sleep_belly' in p.parts:
                continue
            groups.setdefault(str(p.parent.relative_to(source)), []).append(p)
        for clip, paths in groups.items():
            boxes = [rgba(p).getbbox() for p in paths]
            # Margem para o corpo aprovado; nunca reduz pixels de origem.
            left = max(0, min(b[0] for b in boxes) - 12)
            top = max(0, min(b[1] for b in boxes) - 12)
            right = min(rgba(paths[0]).width, max(b[2] for b in boxes) + 12)
            bottom = min(rgba(paths[0]).height, max(b[3] for b in boxes) + 5)
            crop = [left, top, right, bottom]
            tw, th = right - left, bottom - top
            cols = min(3 if family == 'pet' else 4, 512 // tw)
            rows = min(3 if family == 'pet' else 4, 512 // th)
            batch = cols * rows
            for start in range(0, len(paths), batch):
                selected = paths[start:start + batch]
                if family == 'world':
                    fitting = [c for c in range(1, cols + 1) if math.ceil(len(selected) / c) * th <= 512]
                    sheet_cols = min(fitting, key=lambda c: (c * math.ceil(len(selected) / c) - len(selected), -c))
                else:
                    sheet_cols = min(cols, len(selected))
                count_rows = math.ceil(len(selected) / sheet_cols)
                sheet = Image.new('RGBA', (tw * sheet_cols, th * count_rows))
                for i, p in enumerate(selected):
                    sheet.paste(rgba(p).crop(crop), ((i % sheet_cols) * tw, (i // sheet_cols) * th))
                key = f'{family}_{clip.replace(chr(92), "_").replace("/", "_")}_{start:02}'
                dest = WORK / 'inputs' / (key + '.png')
                dest.parent.mkdir(parents=True, exist_ok=True)
                sheet.save(dest)
                manifest.append(dict(key=key, family=family, clip=clip, crop=crop,
                                     cols=sheet_cols, tile=[tw, th], size=list(sheet.size),
                                     files=[str(p.relative_to(source)) for p in selected],
                                     input=str(dest.relative_to(ROOT))))
    save_json(WORK / 'manifest.json', manifest)
    print(f'{len(manifest)} folhas; {sum(len(x["files"]) for x in manifest)} quadros adultos')


def reprocess():
    entries = json.loads((WORK / 'manifest.json').read_text(encoding='utf-8'))
    for body in ['young', 'puppy']:
        for e in entries:
            raw = WORK / 'raw' / f'{body}_{e["key"]}.png'
            if raw.exists():
                if list(rgba(raw).size) == e['size']:
                    install(body, e['key'], raw)
                else:
                    print(f'Aguardando folha corrigida: {body}/{e["key"]}')
    strip = Image.fromarray(PAL.astype(np.uint8).reshape(1, -1, 3))
    strip.save(WORK / 'paleta_clipes.png')
    save_json(WORK / 'paleta_clipes.json', ['#%02x%02x%02x' % tuple(c) for c in PAL])
    print(f'Paleta dos originais: {len(PAL)} cores')
    native_install()


def native_install():
    for body in ['young', 'puppy']:
        source = WORK / 'native' / body
        if not source.exists():
            continue
        for p in sorted(source.rglob('frame_*.png')):
            rel = p.relative_to(source)
            original = rgba(CHAR / 'tiro_world' / rel)
            im = quantize(rgba(p), black_saddle=body == 'young')
            if im.size != original.size:
                raise ValueError(f'Canvas nativo: {body}/{rel}')
            aligned = Image.new('RGBA', im.size)
            aligned.paste(im, (0, original.getbbox()[3] - im.getbbox()[3]))
            dest = CHAR / f'tiro_world_{body}' / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            aligned.save(dest)
        print(f'Overrides nativos do mundo: {body}')


def install(body, key, raw):
    entries = json.loads((WORK / 'manifest.json').read_text(encoding='utf-8'))
    entry = next(e for e in entries if e['key'] == key)
    im = rgba(raw)
    if list(im.size) != entry['size']:
        raise ValueError(f'Dimensão da folha mudou: {im.size} != {entry["size"]}')
    tw, th = entry['tile']
    source = CHAR / ('tiro_' + entry['family'])
    target = CHAR / ('tiro_' + entry['family'] + '_' + body)
    for i, rel in enumerate(entry['files']):
        dest = target / rel
        # Quadro base/south aprovados na 01 são imutáveis.
        if rel.replace('\\', '/') in ['idle_breathe/frame_00.png', 'rotations/south.png']:
            continue
        x, y = (i % entry['cols']) * tw, (i // entry['cols']) * th
        tile = quantize(im.crop((x, y, x + tw, y + th)), black_saddle=body == 'young')
        adult = rgba(source / rel)
        frame = Image.new('RGBA', adult.size)
        frame.paste(tile, tuple(entry['crop'][:2]))
        # Mesma linha de apoio/quadro original; mantém saltos e rolagens do adulto.
        bounds = frame.getbbox()
        if not bounds:
            raise ValueError(f'Quadro vazio: {body}/{rel}')
        delta = adult.getbbox()[3] - bounds[3]
        aligned = Image.new('RGBA', frame.size)
        aligned.paste(frame, (0, delta))
        dest.parent.mkdir(parents=True, exist_ok=True)
        aligned.save(dest)
    print(f'Instalado {body}: {key} ({len(entry["files"])} quadros)')


def static(body, raw):
    im = quantize(rgba(raw), black_saddle=body == 'young')
    if im.size != (256, 216):
        raise ValueError('sleep_belly precisa de canvas 256x216')
    original = rgba(CHAR / 'tiro_pet/belly_rub/frame_00.png')
    aligned = Image.new('RGBA', im.size)
    aligned.paste(im, (0, original.getbbox()[3] - im.getbbox()[3]))
    folder = CHAR / ('tiro_pet' + ('' if body == 'adult' else '_' + body)) / 'sleep_belly'
    folder.mkdir(parents=True, exist_ok=True)
    aligned.save(folder / 'frame_00.png')
    print(f'sleep_belly: {body}')


def repair_tongues():
    """Edição exata da ilha da língua: PixelLab deixou-a castanha no latido.

    A borda preta separa a ilha interna da pele externa; não pinta focinho,
    dentes ou olhos. Só aceita ilha isolada no centro da boca frontal.
    """
    records = []
    paths = sorted((CHAR / 'tiro_pet_puppy/bark').glob('frame_*.png'))
    paths += sorted((CHAR / 'tiro_pet_young/pet_paw').glob('frame_*.png'))
    for p in paths:
        im = rgba(p)
        a = np.array(im)
        pink = (a[:, :, 0] > a[:, :, 1].astype(int) * 1.45) & (a[:, :, 2] > a[:, :, 1].astype(int) * .7) & (a[:, :, 0] > 140) & (a[:, :, 2] > 65) & (a[:, :, 3] > 0)
        if pink.any():
            continue
        roi = a[90:120, 108:140]
        r, g, b = [roi[:, :, i].astype(float) for i in range(3)]
        warm = (r > 45) & (r > g * 1.2) & (r > b * 1.3) & (roi[:, :, 3] > 0)
        seen = np.zeros(warm.shape, dtype=bool)
        candidates = []
        for sy, sx in zip(*np.where(warm)):
            if seen[sy, sx]:
                continue
            queue, comp = deque([(sy, sx)]), []
            seen[sy, sx] = True
            while queue:
                y, x = queue.popleft()
                comp.append((y, x))
                for dy, dx in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < 30 and 0 <= nx < 32 and warm[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            if 2 <= len(comp) <= 200 and not any(y in [0, 29] or x in [0, 31] for y, x in comp):
                cx, cy = np.mean([(x + 108, y + 90) for y, x in comp], axis=0)
                if 116 <= cx <= 132 and 97 <= cy <= 114:
                    candidates.append((abs(cx - 124) + abs(cy - 106), comp))
        if not candidates:
            if p.name == 'frame_06.png' and p.parent.name == 'bark':
                # Um pixel castanho liga a língua ao lábio neste quadro.
                # Polígono conferido na ampliação 10x, sem tocar no lábio.
                comp = [(y - 90, x - 108) for y in range(97, 109)
                        for x in range(116 if y <= 104 else 117 if y == 105 else 118 if y <= 107 else 119,
                                       130 if y <= 103 else 129 if y <= 105 else 128 if y <= 107 else 127)
                        if warm[y - 90, x - 108]]
            elif p.parent.name == 'pet_paw' and p.name in ['frame_03.png', 'frame_08.png']:
                records.append(dict(frame=str(p.relative_to(CHAR)), status='boca fechada conferida: sem língua exposta'))
                continue
            else:
                records.append(dict(frame=str(p.relative_to(CHAR)), status='revisar: ilha não encontrada'))
                continue
        else:
            comp = min(candidates, key=lambda c: c[0])[1]
        for y, x in comp:
            rgb = a[y + 90, x + 108, :3]
            a[y + 90, x + 108, :3] = (229, 99, 113) if int(rgb[0]) >= 140 else (172, 76, 93)
        Image.fromarray(a).save(p)
        records.append(dict(frame=str(p.relative_to(CHAR)), pixels=len(comp), status='língua rosa: ilha interna'))
    save_json(WORK / 'tongue_repair.json', records)
    print(json.dumps(records, ensure_ascii=False))


def audit():
    errors, rows = [], []
    entries = json.loads((WORK / 'manifest.json').read_text(encoding='utf-8'))
    crops = {(e['family'], rel.replace('\\', '/')): e['crop'] for e in entries for rel in e['files']}
    for body in ['young', 'puppy']:
        for family in ['pet', 'world']:
            source, target = CHAR / ('tiro_' + family), CHAR / ('tiro_' + family + '_' + body)
            groups = {}
            for p in sorted(source.rglob('*.png')):
                if family == 'pet' and not p.name.startswith('frame_'):
                    continue
                if 'overlays' in p.parts or 'sleep_belly' in p.parts:
                    continue
                rel = p.relative_to(source)
                if body == 'puppy' and rel.parts[0] == 'give_paw':
                    continue
                groups.setdefault(str(rel.parent), [0, 0])
                groups[str(rel.parent)][0] += 1
                q = target / rel
                if not q.exists():
                    errors.append(f'Falta {body}/{family}/{rel}')
                    continue
                groups[str(rel.parent)][1] += 1
                im = rgba(q)
                if im.size != rgba(p).size or not im.getbbox():
                    errors.append(f'Canvas/vazio {q.relative_to(ROOT)}')
                else:
                    pixels = np.array(im)
                    opaque = pixels[:, :, 3] > 127
                    colors = np.unique(pixels[:, :, :3][opaque], axis=0)
                    if not np.isin(pixels[:, :, 3], [0, 255]).all():
                        errors.append(f'Alpha intermediário: {q.relative_to(ROOT)}')
                    palette = {tuple(c) for c in PAL}
                    if any(tuple(c) not in palette for c in colors):
                        errors.append(f'Cor fora da paleta: {q.relative_to(ROOT)}')
                    if rel.as_posix() not in ['idle_breathe/frame_00.png', 'rotations/south.png']:
                        if im.getbbox()[3] != rgba(p).getbbox()[3]:
                            errors.append(f'Linha de apoio: {q.relative_to(ROOT)}')
                    if family == 'world':
                        native = WORK / 'native' / body / rel
                        bounds = im.getbbox()
                        crop = [0, 0, im.width, im.height] if native.exists() else crops[(family, rel.as_posix())]
                        if bounds[0] <= crop[0] or bounds[1] <= crop[1] or bounds[2] >= crop[2] or bounds[3] >= crop[3]:
                            errors.append(f'Revisar corte na borda: {q.relative_to(ROOT)}')
            for clip, counts in groups.items():
                pattern = 'frame_*.png' if family == 'pet' or clip != 'rotations' else '*.png'
                if len(list((target / clip).glob(pattern))) > counts[0]:
                    errors.append(f'Quadros extras: {body}/{family}/{clip}')
            rows.extend(dict(body=body, family=family, clip=k, expected=v[0], found=v[1]) for k, v in groups.items())
    for rel, digest in json.loads((WORK / 'adult_hashes.json').read_text()).items():
        if hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != digest:
            errors.append('Adulto alterado: ' + rel)
    for body in ['young', 'puppy', 'adult']:
        folder = 'tiro_pet' + ('' if body == 'adult' else '_' + body)
        path = CHAR / folder / 'sleep_belly/frame_00.png'
        if not path.exists():
            errors.append('Falta sleep_belly: ' + body)
        elif rgba(path).size != (256, 216) or len(list(path.parent.glob('frame_*.png'))) != 1:
            errors.append('sleep_belly inválido: ' + body)
    for body in ['young', 'puppy']:
        comparisons = [
            (OUT / 'final' / f'{body}_pet.png', CHAR / f'tiro_pet_{body}/idle_breathe/frame_00.png', (256, 216)),
            (OUT / 'final' / f'{body}_world.png', CHAR / f'tiro_world_{body}/rotations/south.png', (64, 64)),
            (OUT / 'final' / f'{body}_front.png', CHAR / f'tiro_pet_{body}/tiro_pet_{body}_idle_front.png', (160, 160)),
            (OUT / 'final' / f'{body}_hud.png', SPR / f'ui/icons/hud_tiro_{body}.png', (48, 48)),
        ]
        for approved, installed, size in comparisons:
            if not installed.exists() or rgba(installed).size != size or rgba(approved).tobytes() != rgba(installed).tobytes():
                errors.append(f'Base aprovada alterada: {installed.relative_to(ROOT)}')
    if (CHAR / 'tiro_pet_puppy/give_paw').exists():
        errors.append('puppy deve usar fallback de give_paw')
    save_json(WORK / 'audit.json', dict(clips=rows, errors=errors))
    for row in rows:
        print('{body}/{family}/{clip}: {found}/{expected}'.format(**row))
    print(f'ART AUDIT: {"PASS" if not errors else "INCOMPLETO"}; {len(errors)} problemas')
    return errors


def boards():
    folder = OUT / 'clipes'
    folder.mkdir(parents=True, exist_ok=True)
    summary = []
    for family in ['pet', 'world']:
        source = CHAR / ('tiro_' + family)
        groups = {}
        for p in sorted(source.rglob('*.png')):
            if family == 'pet' and not p.name.startswith('frame_'):
                continue
            if 'overlays' not in p.parts:
                groups.setdefault(str(p.parent.relative_to(source)), []).append(p)
        for clip, paths in groups.items():
            for body in ['young', 'puppy']:
                target = CHAR / ('tiro_' + family + '_' + body)
                pairs = [(p, target / p.relative_to(source)) for p in paths if (target / p.relative_to(source)).exists()]
                if not pairs:
                    continue
                cellw, cellh = (256, 238) if family == 'pet' else (128, 154)
                sheet = Image.new('RGB', (cellw * min(5, len(pairs)), cellh * 2 * math.ceil(len(pairs) / 5)), '#eee9dd')
                draw = ImageDraw.Draw(sheet)
                for i, pair in enumerate(pairs):
                    x, y = (i % 5) * cellw, (i // 5) * cellh * 2
                    for j, p in enumerate(pair):
                        im = rgba(p)
                        if family == 'world':
                            im = im.resize((128, 128), Image.Resampling.NEAREST)
                        sheet.paste(im, (x, y + j * cellh + 18), im)
                        draw.text((x + 4, y + j * cellh + 3), f'{"adult" if j == 0 else body} {p.name}', fill='#292521')
                name = f'{body}_{family}_{clip.replace(chr(92), "_").replace("/", "_")}.png'
                sheet.save(folder / name)
            representative = paths[len(paths) // 2].relative_to(source)
            available = [CHAR / ('tiro_' + family + suffix) / representative for suffix in ['', '_young', '_puppy']]
            summary.append((family + '/' + clip, available))
    width, rowh = 1080, 194
    sheet = Image.new('RGB', (width, 40 + math.ceil(len(summary) / 3) * rowh), '#eee9dd')
    draw = ImageDraw.Draw(sheet)
    summary_font = ImageFont.load_default(size=16)
    draw.text((10, 10), 'ETAPA 04 — em cada grupo: adulto atual | jovem | filhote', fill='#292521', font=summary_font)
    for i, (clip, paths) in enumerate(summary):
        x0, y = (i % 3) * 360, 40 + (i // 3) * rowh
        draw.text((x0 + 4, y), clip, fill='#292521', font=summary_font)
        for j, p in enumerate(paths):
            fallback = j == 2 and clip == 'pet/give_paw'
            if fallback:
                p = CHAR / 'tiro_pet_puppy/wag_excited/frame_04.png'
            if p.exists():
                im = rgba(p)
                im = im.crop(im.getbbox())
                if im.width == 64:
                    im = im.resize((128, 128), Image.Resampling.NEAREST)
                factor = min(1, 112 / im.width, 160 / im.height)
                if factor < 1:
                    im = im.resize((round(im.width * factor), round(im.height * factor)), Image.Resampling.NEAREST)
                sheet.paste(im, (x0 + j * 120 + (120 - im.width) // 2, y + 180 - im.height), im)
                if fallback:
                    draw.text((x0 + j * 120 + 8, y + 180), 'wag_excited', fill='#805a40')
            else:
                draw.text((x0 + j * 120 + 15, y + 80), 'PENDENTE', fill='#805a40')
    sheet.save(OUT / 'prancha_geral.png')
    print(f'Pranchas: {folder}; geral: {len(summary)} linhas')


def gifs():
    output = OUT / 'gifs'
    output.mkdir(parents=True, exist_ok=True)
    for clip, fps in [('idle_breathe', 6), ('eat', 8), ('sleep', 5), ('happy_jump', 9), ('walk/east', 8)]:
        world = clip.startswith('walk')
        base = 'tiro_world' if world else 'tiro_pet'
        sequences = []
        for suffix in ['', '_young', '_puppy']:
            paths = sorted((CHAR / (base + suffix) / clip).glob('frame_*.png'))
            sequences.append([rgba(p) for p in paths])
        if not sequences[0] or any(len(s) != len(sequences[0]) for s in sequences):
            continue
        width, height = (256, 216) if not world else (128, 128)
        frames = []
        for i in range(len(sequences[0])):
            frame = Image.new('RGB', (width * 3, height + 24), '#eee9dd')
            d = ImageDraw.Draw(frame)
            for j, seq in enumerate(sequences):
                im = seq[i]
                if world:
                    im = im.resize((128, 128), Image.Resampling.NEAREST)
                frame.paste(im, (j * width, 24), im)
                d.text((j * width + 8, 6), ['adulto', 'jovem', 'filhote'][j], fill='#292521')
            frames.append(frame)
        frames[0].save(output / (clip.replace('/', '_') + '.gif'), save_all=True,
                       append_images=frames[1:], duration=round(1000 / fps), loop=0, disposal=2)
    print(f'GIFs em {output}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['prepare', 'install', 'audit', 'boards', 'reprocess', 'static', 'gifs', 'repair_tongues', 'native_install'])
    parser.add_argument('--body')
    parser.add_argument('--key')
    parser.add_argument('--raw')
    args = parser.parse_args()
    if args.action == 'prepare':
        prepare()
    elif args.action == 'install':
        install(args.body, args.key, args.raw)
    elif args.action == 'boards':
        boards()
    elif args.action == 'reprocess':
        reprocess()
    elif args.action == 'static':
        static(args.body, args.raw)
    elif args.action == 'gifs':
        gifs()
    elif args.action == 'repair_tongues':
        repair_tongues()
    elif args.action == 'native_install':
        native_install()
    else:
        raise SystemExit(1 if audit() else 0)
