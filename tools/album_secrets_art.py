"""Prepara os adereços PixelLab da etapa 15, sem rede e sem alterar os corpos do Tiro."""
from pathlib import Path
import json, hashlib
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'tools/art/album_secrets_pixellab'
OUT = ROOT / 'game/assets/sprites/ui/album'

def prepare(source, size=(48,48)):
    image=Image.open(source).convert('RGBA')
    box=image.getbbox()
    if box: image=image.crop(box)
    scale=min((size[0]-2)/image.width,(size[1]-2)/image.height)
    image=image.resize((max(1,round(image.width*scale)),max(1,round(image.height*scale))),Image.Resampling.NEAREST)
    result=Image.new('RGBA',size)
    result.alpha_composite(image,((size[0]-image.width)//2,(size[1]-image.height)//2))
    return result

manifest=json.loads((SOURCES/'manifest.json').read_text(encoding='utf-8'))
for entry in manifest:
    if entry.get('rejected'): continue
    source=SOURCES/(entry['id']+'.png')
    if entry['id']=='pipoca_curled':
        image=Image.open(source).convert('RGBA')
        old=Image.open(ROOT/'game/assets/sprites/characters/dog_pipoca/rotations/east.png').convert('RGBA')
        box=image.getbbox(); crop=image.crop(box)
        canvas=Image.new('RGBA',old.size)
        canvas.alpha_composite(crop,((old.width-crop.width)//2,old.getbbox()[3]-crop.height))
        canvas.save(OUT/'pipoca_sleep.png')
    else:
        prepare(source).save(OUT/f'prop_{entry["id"]}.png')
    entry['sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
(SOURCES/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

shadow=Image.new('RGBA',(96,48)); ImageDraw.Draw(shadow).ellipse((8,28,90,42),fill=(46,30,52,110)); shadow.save(OUT/'prop_long_shadow.png')
speed=Image.new('RGBA',(96,48)); draw=ImageDraw.Draw(speed)
for y,x in [(12,5),(20,0),(30,8),(38,2)]: draw.line((x,y,x+30,y),fill=(255,235,158,235),width=2)
speed.save(OUT/'prop_speed_lines.png')

hat=prepare(SOURCES/'explorer_hat.png',(84,48))
overlay=Image.new('RGBA',(256,216)); overlay.alpha_composite(hat,(86,22))
overlay.save(OUT/'explorer_hat_overlay.png')
prepare(SOURCES/'explorer_hat.png',(32,32)).save(ROOT/'game/assets/sprites/ui/icons/outfit_explorer_hat.png')
board=Image.new('RGB',(480,330),'#e4d9bd'); draw=ImageDraw.Draw(board)
for i,path in enumerate(sorted(OUT.glob('prop_*.png'))):
    im=Image.open(path).convert('RGBA').resize((72,72),Image.Resampling.NEAREST)
    board.paste(im,((i%6)*80,(i//6)*110),im)
    draw.text(((i%6)*80,(i//6)*110+74),path.stem.replace('prop_',''),fill='black')
folder=ROOT/'build/test_logs/tiro15'; folder.mkdir(parents=True,exist_ok=True)
board.save(folder/'props_board.png')
print('Adereços preparados; corpos do Tiro preservados.')
