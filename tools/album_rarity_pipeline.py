"""Durable, local-only art queue. Never calls paid generation or edits game data."""
import argparse
import hashlib
import html
import json
import shutil
import struct
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tools/art/album_rarities'
CAT = OUT / 'catalog.json'
TIERS = ['common', 'shiny', 'rare', 'holographic']
LABELS = dict(zip(TIERS, ['Comum', 'Brilhante', 'Rara', 'Holográfica']))
STYLE = 'tools/art/album_rarity_tests/h_arrival/render_v4'
SEEDS = {'h_arrival': 'render_v4', 's_moon_friend': 'render_v2',
         'f_dig': 'render_v1', 'p_ball_hug': 'render_v1',
         'a_lais_lap': 'render_v1', 'a_pipoca': 'render_v1'}

def now():
    return datetime.now(timezone.utc).isoformat()

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def write(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temp.replace(path)

def rel(path):
    return path.relative_to(ROOT).as_posix()

def photo(c, ident):
    return next(p for p in c['photos'] if p['id'] == ident)

def png_info(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Not PNG: ' + str(path))
    w, h = struct.unpack('>II', data[16:24])
    if w != h or w < 1024:
        raise ValueError(f'Expected square >=1024, got {w}x{h}: {path}')
    return dict(width=w, height=h, sha256=hashlib.sha256(data).hexdigest())

def save(c):
    c['updated_at'] = now()
    counts = {s: sum(v['status'] == s for p in c['photos'] for v in p['variants'].values())
              for s in ['pending', 'generating', 'generated', 'reviewed']}
    c['summary'] = {'photos': len(c['photos']), 'images': len(c['photos'])*4,
                    'complete_photos': sum(all(v['status'] in ['generated', 'reviewed']
                                              for v in p['variants'].values()) for p in c['photos']),
                    **counts}
    # Each photo and each job also have a standalone recovery file.
    for p in c['photos']:
        write(ROOT / p['manifest_path'], p)
    write(CAT, c)
    gallery(c)

def gallery(c):
    parts = ['<!doctype html><meta charset="utf-8"><title>Raridades do álbum</title>',
             '<style>body{font:16px system-ui;background:#fff8eb;color:#493723;margin:24px}section{margin:32px 0}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}img{width:100%;border-radius:12px}a{color:inherit}small{display:block} @media(max-width:700px){.grid{grid-template-columns:repeat(2,1fr)}}</style>',
             '<h1>Raridades do álbum — produção</h1>',
             '<p>Comum + três variações. Experimentos locais, sem instalação no jogo.</p>',
             '<pre>' + html.escape(json.dumps(c['summary'], ensure_ascii=False, indent=2)) + '</pre>']
    for p in c['photos']:
        parts += [f'<section id="{p["id"]}"><h2>{html.escape(p["title"])} — {p["id"]}</h2>',
                  f'<p>{html.escape(p["section_name"])} · fase: {p["phase"]} · cenário: {p["game_scene"]} · lote: {p.get("batch_id") or "pendente"}</p><div class="grid">']
        for tier, v in p['variants'].items():
            path = ROOT / v['path']
            src = path.relative_to(OUT).as_posix()
            parts.append(f'<div><b>{LABELS[tier]}</b><small>{v["status"]}</small>')
            if path.exists():
                parts.append(f'<a href="{src}"><img loading="lazy" src="{src}"></a>')
            parts.append('</div>')
        parts.append('</div></section>')
    (OUT / 'gallery.html').write_text('\n'.join(parts), encoding='utf-8')

def init():
    if CAT.exists():
        return read(CAT)
    album = read(ROOT / 'game/data/album.json')
    originals = {p['id']: p for p in read(ROOT / 'docs/art/album_ilustrado/manifest.json')['photos']}
    tier_specs = {v['id']: v['detail'] for v in read(ROOT / 'tools/art/album_rarity_tests/p_ball_hug/render_v1/manifest.json')['variants']}
    sections = {s['id']: s['name'] for s in album['sections']}
    c = {'schema': 1, 'direction_version': 'render_progression_v1', 'created_at': now(),
         'policy': '54 fotos x 4 raridades: Comum + três variações. Reutilizar seis séries atuais; não usar testes antigos de brilho. Só produção de arte; não instalar nem publicar.',
         'source_catalog': 'game/data/album.json', 'source_catalog_sha256': hashlib.sha256((ROOT/'game/data/album.json').read_bytes()).hexdigest(),
         'tool': 'built-in image_gen', 'batch_size_photos': 5,
         'style_reference_directory': STYLE, 'batches': [], 'photos': []}
    for item in album['photos']:
        ident = item['id']; original = originals[ident]
        folder = OUT / 'photos' / item['section'] / ident
        folder.mkdir(parents=True, exist_ok=True)
        p = {'id': ident, 'title': item['title'], 'section': item['section'],
             'section_name': sections[item['section']], 'phase': original['phase'],
             'game_scene': item['photo']['scene'],
             'source_definition': f'game/data/album.json#photos/{ident}',
             'trigger': {'on': item['on'], 'when': item.get('when', {})},
             'original_photo_definition': item['photo'],
             'scene_description': original['scene_prompt'],
             'base_image': f'game/assets/sprites/ui/album/illustrated/{ident}.png',
             'original_capture': original['original_capture'],
             'manifest_path': rel(folder / 'photo.json'), 'batch_id': None, 'variants': {}}
        for tier in TIERS:
            prompt = ("Use case: style-transfer. Generate ONE square full-bleed Tiro Adventure memory illustration. "
                      "IMAGE 1 is EXACT content, character identity, proportions, age, body size, coat, pose, camera and event reference. "
                      "IMAGE 2 is ONLY the approved rendering sophistication of THIS rarity; never copy its baby, box, room or lighting. "
                      "Keep same dog size relative to environment/characters. Preserve character features, ear shape and growth stage. "
                      "Keep action and indispensable story props. No new characters or objects. Simplify optional scenery in lower tiers. "
                      "Tiro remains highest-contrast focus. Apply tier drawing quality to all characters. No text, UI, border, rainbow/foil/glitter. "
                      "For Pipoca preserve SHORT smooth caramel coat, not Yorkshire fur. Other friends keep their exact breeds. "
                      f"Photo: {item['title']}; stage {p['phase']}; scene description: {p['scene_description']}. "
                      "The exact visual reference overrides generic scene descriptions. " + tier_specs[tier])
            prompt_path = folder / 'prompts' / (tier + '.txt')
            prompt_path.parent.mkdir(exist_ok=True)
            prompt_path.write_text(prompt, encoding='utf-8')
            p['variants'][tier] = {'rarity': tier, 'label': LABELS[tier], 'status': 'pending',
                'path': rel(folder / (tier + '.png')), 'prompt_path': rel(prompt_path),
                'style_reference': f'{STYLE}/{tier}.png', 'attempts': [],
                'integration_target': f'res://assets/sprites/ui/album/rarities/{ident}/{tier}.png'}
        c['photos'].append(p)
    # Import only the six latest, user-liked render-progression samples.
    for ident, version in SEEDS.items():
        p = photo(c, ident)
        prior = read(ROOT / f'tools/art/album_rarity_tests/{ident}/{version}/manifest.json')
        for old in prior['variants']:
            v = p['variants'][old['id']]
            src = ROOT / old['path']
            shutil.copy2(src, ROOT / v['path'])
            (ROOT / v['prompt_path']).write_text(old['prompt'], encoding='utf-8')
            v.update(status='reviewed', **png_info(ROOT/v['path']), imported_from=old['path'],
                     generated_source=old['source'], review_note='Conferida visualmente e mostrada na conversa; usuário autorizou continuar nesse padrão.')
    save(c)
    return c

def reserve(c):
    # Resume unfinished batch first; no duplicated requests on a new session.
    active = next((b for b in c['batches'] if b['status'] == 'in_progress'), None)
    if active:
        return active
    candidates = [p for p in c['photos'] if any(v['status'] == 'pending' for v in p['variants'].values()) and not p['batch_id']][:5]
    if not candidates:
        return None
    b = {'id': f'batch_{len(c["batches"])+1:03}', 'created_at': now(), 'status': 'in_progress',
         'photo_ids': [p['id'] for p in candidates], 'shown_to_user': False}
    for p in candidates:
        p['batch_id'] = b['id']
    c['batches'].append(b); save(c)
    return b

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('command', choices=['init','next','prepare','start','accept','review','shown','complete','check','status'])
    ap.add_argument('--photo'); ap.add_argument('--tier', choices=TIERS); ap.add_argument('--source'); ap.add_argument('--batch')
    args = ap.parse_args(); c = init()
    if args.command in ['next','prepare']:
        b = reserve(c)
        jobs = []
        if b:
            for ident in b['photo_ids']:
                p = photo(c, ident)
                for tier, v in p['variants'].items():
                    if v['status'] in ['pending','generating']:
                        ready_to_submit = args.command == 'prepare' and v['status'] == 'pending'
                        if args.command == 'prepare' and v['status'] == 'pending':
                            v['status'] = 'generating'; v['attempts'].append({'started_at':now()})
                        jobs.append({'photo_id':ident,'title':p['title'],'tier':tier, **v, 'ready_to_submit':ready_to_submit,
                                     'base_image':p['base_image'],'prompt':(ROOT/v['prompt_path']).read_text(encoding='utf-8')})
        if args.command == 'prepare': save(c)
        print(json.dumps({'batch':b,'jobs':jobs}, ensure_ascii=False)); return
    if args.command in ['start','accept','review']:
        p = photo(c,args.photo); v = p['variants'][args.tier]
        if args.command == 'start':
            if v['status'] != 'pending':
                raise ValueError('Job already started/completed; inspect recovery before retry: '+v['status'])
            v['status'] = 'generating'; v['attempts'].append({'started_at':now()})
        elif args.command == 'accept':
            if v['status'] != 'generating': raise ValueError('Expected generating job')
            source = Path(args.source); info = png_info(source)
            shutil.copy2(source,ROOT/v['path'])
            v.update(status='generated',generated_source=str(source),completed_at=now(),**info)
            v['attempts'][-1].update(source=str(source),completed_at=now())
        else:
            if v['status'] not in ['generated','reviewed']: raise ValueError('Not generated')
            v.update(status='reviewed',reviewed_at=now())
        save(c)
    elif args.command in ['shown', 'complete']:
        b = next(b for b in c['batches'] if b['id']==args.batch)
        if not all(v['status']=='reviewed' for ident in b['photo_ids'] for v in photo(c,ident)['variants'].values()):
            raise ValueError('Batch not fully reviewed')
        b.update(status='complete',shown_to_user=args.command == 'shown',completed_at=now()); save(c)
    elif args.command == 'check':
        album = read(ROOT/'game/data/album.json')
        assert {p['id'] for p in album['photos']}=={p['id'] for p in c['photos']}
        hashes = set()
        for p in c['photos']:
            assert set(p['variants'])==set(TIERS)
            assert (ROOT/p['base_image']).exists()
            for v in p['variants'].values():
                assert (ROOT/v['prompt_path']).exists()
                if v['status'] in ['generated','reviewed']:
                    info=png_info(ROOT/v['path']); assert info['sha256']==v['sha256']
                    assert info['sha256'] not in hashes; hashes.add(info['sha256'])
        print('CHECK PASS: IDs, bases, prompts, dimensions, hashes and unique outputs')
    print(json.dumps(c['summary'],ensure_ascii=False))

if __name__ == '__main__':
    main()
