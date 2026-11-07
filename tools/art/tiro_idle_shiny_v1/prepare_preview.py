"""Recorta os quadros gerados e registra cada um no enquadramento do original.

A arte é produzida pelo image_gen; este preparo só extrai, dimensiona e alinha.
Requer Pillow. Não grava em game/.
"""
import base64
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
manifest = json.loads((HERE / 'source_manifest.json').read_text())
generated = Image.open(HERE / 'generated_sheet.png').convert('RGBA')
frames_dir = HERE / 'frames_3x'
frames_dir.mkdir(exist_ok=True)
sheet = Image.new('RGBA', (2304, 1944))
original_frames, new_frames, comparison = [], [], []
measurements = []
for i, source in enumerate(manifest['frames']):
    original_path = ROOT / source['file']
    assert hashlib.sha256(original_path.read_bytes()).hexdigest() == source['sha256'], 'Fonte mudou'
    original = Image.open(original_path).convert('RGBA')
    x, y = i % 3, i // 3
    cell = generated.crop((round(x * generated.width / 3), round(y * generated.height / 3),
                           round((x + 1) * generated.width / 3), round((y + 1) * generated.height / 3)))
    bounds = cell.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    assert bounds, 'Quadro vazio'
    art = cell.crop(bounds)
    left, top, right, bottom = source['bbox']
    art = art.resize(((right-left)*3, (bottom-top)*3), Image.Resampling.LANCZOS)
    frame = Image.new('RGBA', (768, 648))
    frame.paste(art, (left*3, top*3))
    frame.save(frames_dir / ('frame_%02d.png' % i))
    sheet.paste(frame, (x*768, y*648))
    actual = frame.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    target = [v*3 for v in source['bbox']]
    assert max(abs(a-b) for a,b in zip(actual,target)) <= 3, 'Registro divergente'
    measurements.append({'frame':i,'source_bbox':source['bbox'],'registered_bbox_3x':actual})
    old = original.resize((768,648),Image.Resampling.NEAREST)
    original_frames.append(old)
    new_frames.append(frame)
    board = Image.new('RGB',(1536,720),'#f1ddba')
    board.paste(old,(0,40),old)
    board.paste(frame,(768,40),frame)
    draw = ImageDraw.Draw(board)
    draw.text((40,20),'ORIGINAL',fill='#51371e')
    draw.text((808,20),'TESTE BRILHANTE',fill='#51371e')
    draw.text((40,690),'idle_breathe - 9 quadros - 6 fps - ciclo de 1,5 s',fill='#51371e')
    comparison.append(board)
sheet.save(HERE/'registered_sheet.png')
# GIF usa centésimos de segundo: 170/160/170 = 500 ms por três quadros.
comparison[0].save(HERE/'comparison.gif',save_all=True,append_images=comparison[1:],
                   duration=[170,160,170]*3,loop=0,optimize=False,disposal=2)
comparison[0].save(HERE/'comparison_still.png')
report={'frame_count':9,'fps':6,'cycle_seconds':1.5,'source_unchanged':True,
        'registration':'limites e linha de apoio do original, em 3x',
        'limitation':'Redesenho generativo: detalhes internos de rosto/pelo não são pixel a pixel iguais. Avaliar continuidade na prévia.',
        'measurements':measurements}
(HERE/'validation.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
def data(name):
    return 'data:image/png;base64,'+base64.b64encode((HERE/name).read_bytes()).decode()
html=(HERE/'preview_template.html').read_text(encoding='utf-8')
html=html.replace('__ORIGINAL__',data('source_sheet.png')).replace('__NEW__',data('registered_sheet.png'))
(HERE/'preview.html').write_text(html,encoding='utf-8')
print('PASS: 9 quadros, 6 fps, apoio alinhado; 9 hashes originais preservados; prévia e GIF preparados.')
