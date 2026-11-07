"""Check the rendered planted-paw patches, not just the fitted TPS controls."""
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
reports=[]
for clip,fps in [('head_tilt',7),('scratch',8),('yawn',6)]:
    directory=HERE/clip
    report=json.loads((directory/'validation.json').read_text())
    source=json.loads((HERE.parent/'tiro_puppy_shiny_batch01'/clip/'source_manifest.json').read_text())
    assert report['fps']==fps and report['count']==len(source['frames'])==9
    files=[];frames=[]
    for i,entry in enumerate(source['frames']):
        assert hashlib.sha256((ROOT/entry['file']).read_bytes()).hexdigest()==entry['sha256']
        path=directory/f'frames_3x/frame_{i:02d}.png'
        array=np.array(Image.open(path).convert('RGBA'))
        assert array.shape==(648,768,4) and array[:,:,3].max()==255
        installed=ROOT/f'game/assets/sprites/characters/tiro_pet_puppy_illustrated/{clip}/frame_{i:02d}.png'
        assert installed.read_bytes()==path.read_bytes(), 'Installed frame differs from audited artwork'
        assert 'mipmaps/generate=true' in Path(str(installed)+'.import').read_text()
        frames.append(array)
        files.append({'file':str(path.relative_to(ROOT)).replace('\\','/'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    patches=[]
    for mark in [4,5]:
        x,y=np.round(report['records'][0]['target_3x'][mark]).astype(int)
        patch=frames[0][y-12:y+13,x-12:x+13,:3]
        for i,frame in enumerate(frames):
            _,score,_,pos=cv2.minMaxLoc(cv2.matchTemplate(frame[y-24:y+25,x-24:x+25,:3],patch,cv2.TM_CCOEFF_NORMED))
            displacement=np.array(pos)-12
            expected=np.array(report['records'][i]['target_3x'][mark])-report['records'][0]['target_3x'][mark]
            residual=displacement-expected
            assert score>.9 and np.linalg.norm(residual)<=1.5,(clip,mark,i,score,residual)
            patches.append({'frame':i,'paw':mark-4,'match':score,'residual_px_3x':residual.tolist()})
    reports.append({'clip':clip,'fps':fps,'frames':files,'planted_paw_patches':patches,
        'max_residual_px_3x':max(float(np.linalg.norm(p['residual_px_3x'])) for p in patches)})
summary={'original_27_hashes_unchanged':True,'canvas':[768,648],'clips':reports,
 'installed_27_frames_match':True,
 'scope':'Template check of planted paws only; not a guarantee of all-fur temporal coherence.',
 'art_source':'Existing image_gen drawings from tiro_puppy_shiny_batch01; no new generation in this revision.'}
(HERE/'audit.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
for clip in reports:print(clip['clip'],'PASS; planted paws max residual',round(clip['max_residual_px_3x'],3),'px at 3x')
