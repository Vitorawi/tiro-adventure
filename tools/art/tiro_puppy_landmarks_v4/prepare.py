"""Register three existing image_gen sequences against the original animation.

Manual face correspondences handle rotation, blinking and an opening mouth;
template tracking handles the chest and planted paws. All positions are in the
original 256x216 canvas. Registration uses independent drawings, not one photo.
Requires Pillow, numpy and OpenCV. Writes only to this review directory.
"""
import base64
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
INPUT = OUT.parent / 'tiro_puppy_shiny_batch01'
NAMES = {'head_tilt': 'Inclinar a cabeça', 'scratch': 'Coçar', 'yawn': 'Bocejar'}
# Left eye, right eye, nose. Closed lids retain the centre of the eye socket.
FACE = {
 'head_tilt': {
  'pixel': [
   [[110,81],[138,81],[123,94]], [[109,78],[138,78],[123,90]],
   [[111,72],[139,72],[124,85]], [[111,73],[138,69],[125,83]],
   [[110,78],[136,69],[126,85]], [[110,78],[136,69],[126,85]],
   [[107,78],[134,70],[125,85]], [[109,77],[137,77],[123,88]],
   [[111,81],[138,81],[123,92]]],
  'art': [
   [[111,86],[139,86],[125,100]], [[113,81],[139,81],[126,94]],
   [[114,74],[140,74],[125,88]], [[111,73],[138,72],[124,85]],
   [[112,84],[138,72],[126,89]], [[112,84],[139,74],[127,92]],
   [[108,82],[134,76],[124,92]], [[107,83],[137,83],[124,92]],
   [[110,85],[138,85],[125,98]]],
  'body_pixel': [[123,140],[105,177],[141,177]],
  'body_art': [[125,143],[111,178],[142,178]],
 },
 'scratch': {
  'pixel': [
   [[94,92],[121,92],[106,105]], [[94,92],[121,92],[106,105]],
   [[94,90],[121,90],[106,103]], [[95,89],[122,89],[108,103]],
   [[94,91],[122,91],[107,104]], [[93,93],[121,93],[105,107]],
   [[94,91],[122,91],[107,104]], [[95,88],[123,88],[109,101]],
   [[96,86],[123,86],[110,99]]],
  'art': [
   [[96,92],[123,92],[109,104]], [[97,92],[123,92],[110,103]],
   [[98,90],[124,90],[111,102]], [[98,87],[125,87],[111,101]],
   [[95,90],[123,90],[107,104]], [[95,92],[122,92],[107,106]],
   [[95,89],[123,89],[109,103]], [[97,87],[124,87],[110,101]],
   [[98,86],[125,86],[111,100]]],
  'body_pixel': [[111,145],[100,177],[147,167]],
  'body_art': [[110,145],[106,177],[148,168]],
  # Raised paw is tracked by hand: its turn exposes pads in the detailed art.
  'paw_pixel': [[126,121],[136,119],[141,112],[134,124],[126,124],[136,124],[140,124],[136,124],[126,124]],
  'paw_art': [[132,123],[138,120],[145,110],[140,126],[128,127],[139,128],[143,127],[140,126],[130,125]],
 },
 'yawn': {
  'pixel': [
   [[111,81],[139,81],[124,94]], [[112,79],[140,79],[125,92]],
   [[112,77],[140,77],[125,90]], [[112,70],[140,70],[125,83]],
   [[112,70],[140,70],[125,83]], [[111,70],[139,70],[124,83]],
   [[111,72],[138,72],[123,85]], [[111,77],[139,77],[125,90]],
   [[112,81],[140,81],[125,94]]],
  'art': [
   [[112,85],[140,85],[126,98]], [[112,83],[140,83],[125,95]],
   [[113,80],[141,80],[126,93]], [[113,70],[141,70],[126,86]],
   [[113,71],[141,71],[126,87]], [[112,71],[140,71],[125,87]],
   [[111,74],[139,74],[125,89]], [[112,80],[140,80],[126,94]],
   [[112,85],[140,85],[126,98]]],
  'mouth_pixel': [[124,109],[125,113],[125,114],[125,113],[125,113],[124,111],[123,101],[125,104],[125,108]],
  'mouth_art': [[126,113],[125,114],[126,115],[126,112],[126,113],[125,112],[125,105],[126,107],[126,111]],
  'body_pixel': [[124,140],[107,177],[143,177]],
  'body_art': [[126,143],[112,178],[144,178]],
 }
}
IDLE_PIXEL = np.array([[109,82],[137,82],[122.5,93.5],[121,146],[104,176.5],[140,176.5]],float)
IDLE_ART = np.array([[109.5,85],[137.67,84.83],[122.83,96.5],[124.17,140.33],[109.67,177.67],[141.17,177.67]],float)

def track(base, frame, point, radius=6, search=7):
    x,y = np.round(point).astype(int)
    patch = base[y-radius:y+radius+1,x-radius:x+radius+1,:3]
    region = frame[y-radius-search:y+radius+search+1,x-radius-search:x+radius+search+1,:3]
    _,score,_,pos = cv2.minMaxLoc(cv2.matchTemplate(region,patch,cv2.TM_CCOEFF_NORMED))
    assert score > .65, (point,score)
    return np.array(point)+np.array(pos)-search,score

def kernel(d): return d*np.log(d+1e-12)

def remap(art, current, target):
    t=target/768.; c=current/768.; n=len(t)
    k=kernel(((t[:,None]-t[None,:])**2).sum(2))
    p=np.column_stack([np.ones(n),t])
    coef=np.linalg.solve(np.block([[k+np.eye(n)*1e-8,p],[p.T,np.zeros((3,3))]]),np.vstack([c,np.zeros((3,2))]))
    yy,xx=np.mgrid[:648,:768]
    g=np.column_stack([xx.ravel(),yy.ravel()])/768.
    uv=(kernel(((g[:,None]-t[None,:])**2).sum(2))@coef[:n]+np.column_stack([np.ones(len(g)),g])@coef[n:])*768
    uv=uv.reshape(648,768,2).astype('float32')
    rgba=art.astype('float32')/255.;rgba[:,:,:3]*=rgba[:,:,3:4]
    moved=np.clip(cv2.remap(rgba,uv[:,:,0],uv[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT),0,1)
    moved[:,:,:3]/=np.maximum(moved[:,:,3:4],1e-5)
    fit=kernel(((t[:,None]-t[None,:])**2).sum(2))@coef[:n]+p@coef[n:]
    return Image.fromarray(np.round(np.clip(moved,0,1)*255).astype('uint8')),float(np.max(np.linalg.norm((fit-c)*768,axis=1)))

for clip,title in NAMES.items():
    config=FACE[clip]; here=OUT/clip; (here/'frames_3x').mkdir(parents=True,exist_ok=True)
    manifest=json.loads((INPUT/clip/'source_manifest.json').read_text())
    original=[];art=[]
    for i,entry in enumerate(manifest['frames']):
        path=ROOT/entry['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
        original.append(np.array(Image.open(path).convert('RGBA')))
        art.append(np.array(Image.open(INPUT/clip/f'frames_3x/frame_{i:02d}.png').convert('RGBA')))
    records=[]; boards=[]; sheet=Image.new('RGBA',(2304,1944))
    for i in range(9):
        old=list(np.array(config['pixel'][i],float));new=list(np.array(config['art'][i],float));scores=[]
        for old_base,new_base in zip(config['body_pixel'],config['body_art']):
            op,os=track(original[0],original[i],old_base)
            np_,ns=track(art[0],art[i],np.array(new_base)*3,radius=16,search=24)
            old.append(op);new.append(np_/3);scores.append([os,ns])
        old=np.array(old);new=np.array(new)
        target=IDLE_ART+(old-IDLE_PIXEL)
        # Body marks use matching patches inside each clip, whose exact patch
        # centres differ from idle. Calibrate their rest positions explicitly,
        # then transfer only the measured motion, avoiding cross-clip offsets.
        body_rest = IDLE_ART[3:].copy()
        if clip == 'scratch':
            body_rest=np.array([[114.17,140.33],[105.67,177.67],[148.17,168.17]])
        target[3:]=body_rest+(old[3:]-np.array(config['body_pixel']))
        current=list(new*3);dest=list(target*3)
        if 'paw_pixel' in config:
            current.append(np.array(config['paw_art'][i])*3)
            dest.append((IDLE_ART[2]+np.array(config['paw_pixel'][i])-IDLE_PIXEL[2])*3)
        if 'mouth_pixel' in config:
            current.append(np.array(config['mouth_art'][i])*3)
            dest.append((np.array([122.83,109.5])+np.array(config['mouth_pixel'][i])-[122.5,108.5])*3)
        # Crown follows source height, but retains the approved idle's head height.
        old_top=np.where(original[i][:,:,3]>24)[0].min()
        new_top=np.where(art[i][:,:,3]>24)[0].min()
        current.append([new[2,0]*3,new_top]);dest.append([target[2,0]*3,146+(old_top-48)*3])
        for point in [[0,0],[767,0],[0,647],[767,647],[369,620]]:
            current.append(point);dest.append(point)
        result,fit=remap(art[i],np.array(current,float),np.array(dest,float))
        result.save(here/f'frames_3x/frame_{i:02d}.png')
        sheet.paste(result,((i%3)*768,(i//3)*648))
        board=Image.new('RGB',(1536,690),'#efd9b6')
        for j,im in enumerate([Image.fromarray(original[i]).resize((768,648),Image.Resampling.NEAREST),result]):board.paste(im,(j*768,25),im)
        d=ImageDraw.Draw(board);d.text((15,8),f'{clip} {i+1}/9 - PIXEL',fill='#50351d');d.text((783,8),'DESENHOS COM MARCOS REGISTRADOS',fill='#50351d')
        boards.append(board)
        records.append({'frame':i,'pixel_landmarks':old.tolist(),'art_landmarks':new.tolist(),'target_3x':(target*3).tolist(),'fit_max_px_3x':fit,'body_tracking_scores':scores})
    sheet.save(here/'registered_sheet.png')
    fps=manifest['fps'];durations=[(round((i+1)*100/fps)-round(i*100/fps))*10 for i in range(9)]
    boards[0].save(here/'comparison.gif',save_all=True,append_images=boards[1:],duration=durations,loop=0,disposal=2)
    boards[4].save(here/'comparison_still.png')
    template=(OUT.parent/'tiro_idle_landmarks_v3/template.html').read_text(encoding='utf8')
    assets={'original':INPUT/clip/'source_sheet.png','previous':INPUT/clip/'registered_sheet.png','new':here/'registered_sheet.png'}
    assets={k:'data:image/png;base64,'+base64.b64encode(v.read_bytes()).decode() for k,v in assets.items()}
    template=template.replace('__ASSETS__',json.dumps(assets)).replace('Respiração ·',title+' ·').replace('1000/6',f'1000/{fps}').replace('6 fps · normal',f'{fps} fps · normal').replace('3 fps · metade',f'{fps/2:g} fps · metade')
    (here/'preview.html').write_text(template,encoding='utf8')
    report={'clip':clip,'fps':fps,'count':9,'source_hashes_unchanged':True,'records':records,'limitation':'Landmark fit measures registration, not perceptual coherence of every fur strand.'}
    (here/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print(clip,'PASS',max(r['fit_max_px_3x'] for r in records))
