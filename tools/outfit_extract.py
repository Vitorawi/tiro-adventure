"""Limpeza reproduzível das diferenças PixelLab; máscaras revisadas em coordenadas do quadro.

Os PNGs de entrada são gerados pelo PixelLab; este utilitário só recorta camadas e prepara
variações de pose. Não desenha roupa nova. Use após New-OverlayFromDiff (pixel_tools.ps1).
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SOURCE=Path('build/art_sources/etapa08')
PET=Path('game/assets/sprites/characters/tiro_pet')
OUT=PET/'overlays'
OUT.mkdir(exist_ok=True)
def box(x0,y0,x1,y1): return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]
polygons={
 'blue_collar':[[(99,118),(113,122),(131,121),(145,116),(144,130),(126,145),(115,135),(101,129)]],
 'yellow_bow':[box(106,46,140,62)],
 'rain_coat':[[(91,108),(105,111),(112,120),(135,120),(147,110),(158,106),(159,129),(166,154),(150,154),(148,144),(102,144),(98,153),(82,153),(87,127)]],
 'plaid_bow':[box(103,43,144,65)],
 'flower_clip':[box(89,72,157,92)],
 'bow_tie':[box(98,113,145,131)],
 'sailor_scarf':[[(94,110),(104,113),(116,122),(129,123),(143,112),(152,109),(152,122),(138,134),(137,149),(110,151),(108,134),(95,122)]],
 'explorer_backpack':[box(79,116,94,140),box(149,114,168,145),[(94,116),(101,119),(100,144),(94,150),(91,143)],[(143,116),(150,113),(155,145),(148,151),(144,143)]],
 'star_glasses':[box(89,64,157,96)],
 'glow_collar':[box(99,118,147,133)],
 'flower_crown':[[(79,73),(85,61),(103,52),(125,48),(143,53),(159,62),(164,76),(156,80),(148,68),(125,62),(103,65),(90,77)]],
 'shell_collar':[box(98,113,146,132)],
 'knit_sweater':[[(95,112),(109,118),(135,118),(150,111),(157,151),(151,164),(97,163),(87,153)]],
 'feather_hat':[box(101,15,166,62)],
 'golden_cape':[[(92,112),(105,117),(121,123),(139,116),(152,109),(170,161),(156,162),(142,137),(106,137),(89,160),(74,162)]],
 'sponge_hat':[box(108,26,146,59)],
 'sponge_uniform':[[(95,113),(107,118),(138,118),(151,112),(157,148),(150,154),(150,176),(132,176),(133,162),(112,162),(113,176),(95,176),(93,154),(88,147)]],
}
base=Image.open(PET/'idle_breathe/frame_00.png').convert('RGBA')
for id,regions in polygons.items():
    src=SOURCE/('sponge_set_candidate_01.png' if id.startswith('sponge_') else id+'_candidate_01.png')
    dressed=Image.open(src).convert('RGBA')
    # O diff é preservado para auditoria; a máscara recorta só a roupa revisada.
    diff=SOURCE/(id+'_diff.png')
    raw=Image.open(diff).convert('RGBA') if diff.exists() else dressed
    mask=Image.new('L',base.size)
    draw=ImageDraw.Draw(mask)
    for polygon in regions: draw.polygon(polygon,fill=255)
    layer=Image.new('RGBA',base.size)
    # Dentro do pano, mantém também cores iguais à base para não criar furinhos.
    layer.paste(dressed,(0,0),mask)
    layer.save(OUT/(id+'.png'))
    Image.alpha_composite(base,layer).save(SOURCE/(id+'_composite.png'))

# Pranchas em páginas; pixel mais próximo, 4 por página, sem mudar os originais.
ids=list(polygons)+['red_scarf']
for page in range((len(ids)+3)//4):
    sheet=Image.new('RGBA',(1024,252),(245,227,194,255));draw=ImageDraw.Draw(sheet)
    for col,id in enumerate(ids[page*4:page*4+4]):
        img=Image.alpha_composite(base,Image.open(OUT/(id+'.png')).convert('RGBA'))
        sheet.alpha_composite(img,(col*256,24));draw.text((col*256+8,4),id,fill=(64,44,36))
    sheet.save(SOURCE/f'overlays_review_{page:02}.png')

# Âncoras das poses difíceis, conferidas contra os três quadros transfer_outfit.
# Reamostra apenas o tecido já gerado, mantendo cada quadro ORIGINAL do cachorro.
collections=json.loads(Path('game/data/collections.json').read_text(encoding='utf-8'))
transferred={}
for clip,frame,regions in [
    ('eat',4,[box(105,121,133,162)]),
    ('sleep',16,[box(103,116,150,130),box(72,150,94,168)]),
    ('lick_paw',4,[box(101,125,136,165),box(80,98,102,122)]),
]:
    im=Image.open(SOURCE/f'transfer_{clip}_{frame:02}.png').convert('RGBA')
    region=Image.new('L',im.size);draw=ImageDraw.Draw(region)
    for polygon in regions:draw.polygon(polygon,fill=255)
    red=Image.new('L',im.size)
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=im.getpixel((x,y))
            if region.getpixel((x,y)) and a>0 and r>g*1.5 and r>b*1.5 and abs(g-b)<35:red.putpixel((x,y),255)
    red=ImageChops.multiply(red.filter(ImageFilter.MaxFilter(3)),region)
    layer=Image.new('RGBA',im.size);layer.paste(im,(0,0),red)
    transferred[clip]=layer
for id in ids:
    layer=Image.open(OUT/(id+'.png')).convert('RGBA')
    slot=collections[id]['slot']
    for clip in ['sad','eat','lick_paw','sleep','head_tilt']:
        frames=sorted((PET/clip).glob('frame_*.png'))
        for index,path in enumerate(frames):
            import math
            t=min(1,index/max(1,len(frames)//2))
            if clip=='head_tilt': t=math.sin(math.pi*index/max(1,len(frames)-1))
            dx=dy=angle=0; sx=sy=1
            px,py={'head':(124,60),'neck':(124,126),'body':(124,146)}[slot]
            if clip=='sad':
                if slot in ['head','neck']: dy=22*t
            elif clip=='eat':
                if slot=='head': dx=20*t;dy=34*t;angle=8*t
                elif slot=='neck': dx=-2*t;dy=19*t;sx=1-.25*t;sy=1-.1*t;angle=-15*t
                else: dx=-10*t;sy=1-.10*t
            elif clip=='lick_paw':
                if slot=='head': dx=10*t;dy=18*t;angle=14*t
                elif slot=='neck': dx=-8*t;dy=17*t;angle=20*t;sx=1-.15*t
            elif clip=='sleep':
                if slot=='head':dy=69*t;sx=sy=1-.15*t
                elif slot=='neck':dx=-10*t;dy=-2*t;sx=1-.15*t;sy=1-.3*t
                else:dy=-20*t;sx=1-.1*t;sy=1-.55*t
            elif clip=='head_tilt' and slot=='head':angle=20*t
            # Transformação inversa em torno da âncora, nearest-neighbor.
            a=math.radians(angle);c=math.cos(a);s=math.sin(a)
            tx,ty=px+dx,py+dy
            affine=(c/sx,s/sx,px-(c*tx+s*ty)/sx,-s/sy,c/sy,py-(-s*tx+c*ty)/sy)
            posed=layer.transform(layer.size,Image.Transform.AFFINE,affine,Image.Resampling.NEAREST)
            if slot in ['neck','body'] and clip in ['eat','lick_paw','sleep'] and t>.1:
                # Face e pata da pose original ocluem a roupa; nunca são redesenhadas.
                masks={'eat':[(127,111),(160,109),(181,140),(170,161),(143,160),(126,142)],
                       'lick_paw':[(122,99),(153,105),(166,134),(158,161),(135,156),(120,133)],
                       'sleep':[(78,132),(91,126),(156,126),(175,142),(169,190),(77,190)]}
                rest=[(124+(x-124)*.78, y-20) for x,y in masks[clip]]
                polygon=[(int(rx+(x-rx)*t),int(ry+(y-ry)*t)) for (rx,ry),(x,y) in zip(rest,masks[clip])]
                ImageDraw.Draw(posed).polygon(polygon,fill=(0,0,0,0))
            # Lenço das três poses transferidas: usa apenas seu tecido, nunca o cachorro redesenhado.
            if id=='red_scarf' and clip in transferred and t>=.8:
                posed=transferred[clip]
            folder=OUT/id/clip;folder.mkdir(parents=True,exist_ok=True)
            posed.save(folder/path.name)

anchors={'show_in':['idle_breathe','wag_excited','head_tilt','look_around','yawn','sad','pet_head','pet_paw','eat','sniff','lick_paw','scratch','bark','give_paw','shake_off','sleep'],'offsets':{},'frame_variants':['sad','eat','lick_paw','sleep','head_tilt']}
(PET/'overlay_anchors.json').write_text(json.dumps(anchors,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
