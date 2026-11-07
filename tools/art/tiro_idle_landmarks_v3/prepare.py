"""Estabiliza nove desenhos distintos por marcos anatômicos dirigidos pelo pixel.

Experimento de registro de animação, sem geração de nova arte ou gravação em game/.
Requer numpy, OpenCV e Pillow.
"""
import base64
import hashlib
import json
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ImageDraw

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[2]
PREVIOUS=ROOT/'tools/art/tiro_idle_shiny_v1'
SRC=ROOT/'game/assets/sprites/characters/tiro_pet_puppy/idle_breathe'
original=[np.array(Image.open(SRC/f'frame_{i:02d}.png').convert('RGBA')) for i in range(9)]
art=[np.array(Image.open(PREVIOUS/f'frames_3x/frame_{i:02d}.png').convert('RGBA')) for i in range(9)]
manifest=json.loads((PREVIOUS/'source_manifest.json').read_text())
for i,entry in enumerate(manifest['frames']):
    assert hashlib.sha256((ROOT/entry['file']).read_bytes()).hexdigest()==entry['sha256']

# Um ponto de controle por olho/nariz, peito e pata, não só retângulo externo.
REGIONS={
 'eye_left':((310,241,347,269),(100,77,114,89)),
 'eye_right':((394,240,432,269),(130,77,144,89)),
 'nose':((352,275,385,304),(114,87,131,100)),
 'chest':((335,399,410,443),(99,135,143,157)),
 'paw_left':((308,520,350,546),(94,169,114,184)),
 'paw_right':((400,520,447,546),(130,169,150,184)),
}
def track(base,image,roi,dx,dy):
    x,y,r,b=roi
    response=cv2.matchTemplate(image[y-dy:b+dy,x-dx:r+dx,:3],base[y:b,x:r,:3],cv2.TM_CCOEFF_NORMED)
    _,score,_,pos=cv2.minMaxLoc(response)
    return np.array([pos[0]-dx,pos[1]-dy],dtype=float),float(score)

def kernel(d2):
    return d2*np.log(d2+1e-12)

def tps_map(target,current):
    # Registro inverso: cada pixel de saída consulta sua posição na arte daquele quadro.
    t=target/768.0;c=current/768.0;n=len(t)
    k=kernel(((t[:,None]-t[None,:])**2).sum(2))
    p=np.column_stack([np.ones(n),t])
    system=np.block([[k+np.eye(n)*1e-8,p],[p.T,np.zeros((3,3))]])
    coefficients=np.linalg.solve(system,np.vstack([c,np.zeros((3,2))]))
    yy,xx=np.mgrid[0:648,0:768]
    grid=np.column_stack([xx.ravel(),yy.ravel()])/768.0
    distances=((grid[:,None,:]-t[None,:,:])**2).sum(2)
    result=kernel(distances)@coefficients[:n]+np.column_stack([np.ones(len(grid)),grid])@coefficients[n:]
    result=(result*768).reshape(648,768,2).astype('float32')
    predicted=kernel(((t[:,None]-t[None,:])**2).sum(2))@coefficients[:n]+p@coefficients[n:]
    fit=float(np.max(np.linalg.norm((predicted-c)*768,axis=1)))
    return result,fit

sheet=Image.new('RGBA',(2304,1944));comparisons=[];records=[]
frame_dir=OUT/'frames_3x';frame_dir.mkdir(exist_ok=True)
for i in range(9):
    target=[];current=[];anchors={}
    for name,(new_roi,old_roi) in REGIONS.items():
        new_motion,new_score=track(art[0],art[i],new_roi,28,40)
        old_motion,old_score=track(original[0],original[i],old_roi,8,12)
        assert new_score>.8 and old_score>.8,(i,name,new_score,old_score)
        x,y,r,b=new_roi;point=np.array([(x+r)/2,(y+b)/2])
        current.append(point+new_motion)
        target.append(point+old_motion*3)
        anchors[name]={'generated_displacement':new_motion.tolist(),'target_displacement':(old_motion*3).tolist(),'generated_score':new_score,'source_score':old_score}
    # A coroa da cabeça também acompanha a altura da silhueta original.
    base_top=manifest['frames'][0]['bbox'][1]*3
    new_top=manifest['frames'][i]['bbox'][1]*3
    current.append([369,new_top]);target.append([369,base_top+(new_top-base_top)])
    for point in [[0,0],[767,0],[0,647],[767,647],[369,600]]:
        current.append(point);target.append(point)
    maps,fit=tps_map(np.array(target,float),np.array(current,float))
    # Premultiplicação evita franjas de cor da transparência ao reamostrar.
    rgba=art[i].astype('float32')/255
    rgba[:,:,:3]*=rgba[:,:,3:4]
    moved=cv2.remap(rgba,maps[:,:,0],maps[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT)
    moved=np.clip(moved,0,1)
    moved[:,:,:3]=np.where(moved[:,:,3:4]>1e-5,moved[:,:,:3]/np.maximum(moved[:,:,3:4],1e-5),0)
    image=Image.fromarray(np.round(np.clip(moved,0,1)*255).astype('uint8'))
    image.save(frame_dir/f'frame_{i:02d}.png')
    sheet.paste(image,((i%3)*768,(i//3)*648))
    board=Image.new('RGB',(2304,720),'#f1ddba')
    for j,frame in enumerate([Image.fromarray(original[i]).resize((768,648),Image.Resampling.NEAREST),Image.fromarray(art[i]),image]):
        board.paste(frame,(j*768,40),frame)
    draw=ImageDraw.Draw(board)
    for j,label in enumerate(['ORIGINAL PIXEL','ANTERIOR: 9 DESENHOS SEM CORRECAO INTERNA','NOVO: 9 DESENHOS COM MARCOS ALINHADOS']):
        draw.text((j*768+22,14),label,fill='#51371e')
    draw.text((22,690),f'Quadro {i+1}/9 - 6 fps - sem foto-base unica',fill='#51371e')
    comparisons.append(board)
    records.append({'frame':i,'fit_error_pixels':fit,'anchors':anchors})
sheet.save(OUT/'registered_sheet.png')
comparisons[0].save(OUT/'comparison.gif',save_all=True,append_images=comparisons[1:],duration=[170,160,170]*3,loop=0,optimize=False,disposal=2)
comparisons[4].save(OUT/'comparison_still.png')
def data(path):return 'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()
assets={'original':data(PREVIOUS/'source_sheet.png'),'previous':data(PREVIOUS/'registered_sheet.png'),'new':data(OUT/'registered_sheet.png')}
html=(OUT/'template.html').read_text(encoding='utf-8').replace('__ASSETS__',json.dumps(assets))
(OUT/'preview.html').write_text(html,encoding='utf-8')
report={'fps':6,'frame_count':9,'method':'separate detailed drawings, per-frame multi-landmark registration; no single-photo rig',
        'source_hashes_unchanged':True,'records':records,'limitation':'Geometria dos marcos corrigida; diferenças de anatomia/pelagem entre desenhos não são eliminadas por registro.'}
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS: nove desenhos distintos; marcos medidos e ajuste inverso preparado; fontes intactas.')
