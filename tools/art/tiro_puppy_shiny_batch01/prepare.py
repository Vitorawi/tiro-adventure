"""Extrai e registra as três sequências geradas. Só grava nesta pasta de teste.

Requer Pillow; o redesenho é feito pelo image_gen, não por este preparo.
"""
import base64
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
TEMPLATE = (BASE.parent / 'tiro_idle_shiny_v1/preview_template.html').read_text(encoding='utf-8')
NAMES = {'head_tilt':'Inclinar a cabeça', 'scratch':'Coçar', 'yawn':'Bocejar'}
for clip, title in NAMES.items():
    here = BASE / clip
    source = json.loads((here/'source_manifest.json').read_text())
    fps = source['fps']
    cycle = 9 / fps
    generated = Image.open(here/'generated_sheet.png').convert('RGBA')
    target_dir = here / 'frames_3x'
    target_dir.mkdir(exist_ok=True)
    sheet = Image.new('RGBA',(2304,1944))
    comparisons, measurements = [], []
    for i, entry in enumerate(source['frames']):
        path = ROOT / entry['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256'], 'Original alterado'
        original = Image.open(path).convert('RGBA')
        x,y = i%3, i//3
        cell = generated.crop((round(x*generated.width/3), round(y*generated.height/3),
                               round((x+1)*generated.width/3), round((y+1)*generated.height/3)))
        bounds = cell.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        assert bounds, 'Quadro vazio'
        left,top,right,bottom = entry['bbox']
        art = cell.crop(bounds).resize(((right-left)*3,(bottom-top)*3),Image.Resampling.LANCZOS)
        frame = Image.new('RGBA',(768,648))
        frame.paste(art,(left*3,top*3))
        actual = frame.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        assert max(abs(a-b*3) for a,b in zip(actual,entry['bbox']))<=3, 'Registro divergente'
        frame.save(target_dir/('frame_%02d.png'%i))
        sheet.paste(frame,(x*768,y*648))
        measurements.append({'frame':i,'source_bbox':entry['bbox'],'registered_bbox_3x':actual})
        old = original.resize((768,648),Image.Resampling.NEAREST)
        board = Image.new('RGB',(1536,720),'#f1ddba')
        board.paste(old,(0,40),old)
        board.paste(frame,(768,40),frame)
        draw = ImageDraw.Draw(board)
        draw.text((40,20),'ORIGINAL',fill='#51371e')
        draw.text((808,20),'TESTE BRILHANTE',fill='#51371e')
        draw.text((40,690),'%s - 9 quadros - %d fps - %.3f s'%(clip,fps,cycle),fill='#51371e')
        comparisons.append(board)
    sheet.save(here/'registered_sheet.png')
    durations=[(round((i+1)*100/fps)-round(i*100/fps))*10 for i in range(9)]
    comparisons[0].save(here/'comparison.gif',save_all=True,append_images=comparisons[1:],
                        duration=durations,loop=0,optimize=False,disposal=2)
    comparisons[4].save(here/'comparison_still.png')
    html=TEMPLATE.replace('Tiro bebê · parado respirando','Tiro bebê · '+title)
    html=html.replace('9 quadros · ciclo de 1,5 s','9 quadros · ciclo de %.3f s'%cycle)
    html=html.replace('Normal · 6 fps','Normal · %d fps'%fps).replace('Metade · 3 fps','Metade · %g fps'%(fps/2))
    html=html.replace('1000/6','1000/%d'%fps)
    for marker,file in [('__ORIGINAL__','source_sheet.png'),('__NEW__','registered_sheet.png')]:
        html=html.replace(marker,'data:image/png;base64,'+base64.b64encode((here/file).read_bytes()).decode())
    (here/'preview.html').write_text(html,encoding='utf-8')
    report={'clip':clip,'frame_count':9,'fps':fps,'cycle_seconds':cycle,'gif_duration_ms':sum(durations),
            'source_unchanged':True,'measurements':measurements,
            'limitation':'Feições e pelagem foram redesenhadas; não afirmar deformação interna idêntica.'}
    (here/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('%s: PASS, 9 quadros, %d fps, apoio registrado, fontes intactas'%(clip,fps))
