import sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'python_libs'))
from PIL import Image, ImageDraw
import json, hashlib, shutil
ROOT=HERE.parents[2]
ANIM=HERE/'animations'
BACKUP=ROOT/'assets/backup_tiro_pet_puppy_20261024'
TARGET=ROOT/'game/assets/sprites/characters/tiro_pet_puppy'
STAGE=HERE/'normalized'

def normalize():
    choices=json.loads((HERE/'final_choices.json').read_text())
    assert BACKUP.is_dir()
    records=[]
    for clip,source in choices.items():
        old=sorted((BACKUP/clip).glob('frame_*.png'))
        new=sorted((ANIM/source).glob('frame_*.png'))
        if clip=='sleep_belly':new=[new[4]]
        assert len(old)==len(new),(clip,len(old),len(new))
        (STAGE/clip).mkdir(parents=True,exist_ok=True)
        for i,(op,np) in enumerate(zip(old,new)):
            reference=Image.open(op).convert('RGBA');im=Image.open(np).convert('RGBA')
            rb=reference.getbbox();nb=im.getbbox()
            # Shared scale = 1 for every clip; only translation. Match each original support line/centre.
            dx=round((rb[0]+rb[2]-nb[0]-nb[2])/2);dy=rb[3]-nb[3]
            if clip=='eat' and i==0:
                # Bowl extracted exactly from frame 01, including kibble, masked along its outline.
                bowl=Image.open(ANIM/source/'frame_01.png').convert('RGBA')
                mask=Image.new('L',bowl.size)
                ImageDraw.Draw(mask).polygon([(104,152),(124,152),(133,154),(145,158),(150,162),(152,179),(153,184),(149,189),(140,192),(125,194),(100,193),(92,191),(86,188),(84,182),(86,169),(87,161),(94,156)],fill=255)
                bowl.putalpha(Image.composite(bowl.getchannel('A'),Image.new('L',bowl.size),mask))
                # bowl is a little in front of feet; same coordinates as its following frame.
                im.alpha_composite(bowl)
                nb=im.getbbox();dy=Image.open(old[1]).getbbox()[3]-nb[3]
            bbox=(nb[0]+dx,nb[1]+dy,nb[2]+dx,nb[3]+dy)
            assert bbox[0]>=0 and bbox[1]>=0 and bbox[2]<=reference.width and bbox[3]<=reference.height,(clip,i,bbox)
            canvas=Image.new('RGBA',reference.size)
            canvas.alpha_composite(im,(dx,dy))
            out=STAGE/clip/f'frame_{i:02d}.png';canvas.save(out)
            records.append({'clip':clip,'source':source,'source_frame':np.name,'frame':out.name,'canvas':canvas.size,'scale':1,'offset':[dx,dy],'bbox':canvas.getbbox(),'reference_bbox':rb,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()})
    (HERE/'normalization_audit.json').write_text(json.dumps(records,indent=2)+'\n')
    print('Prepared',len(records),'frames; 22 clips; scale=1; no cropping')

def install():
    records=json.loads((HERE/'normalization_audit.json').read_text())
    for r in records:
        source=STAGE/r['clip']/r['frame'];target=TARGET/r['clip']/r['frame']
        assert hashlib.sha256(source.read_bytes()).hexdigest()==r['sha256']
        assert (BACKUP/r['clip']/r['frame']).exists() and target.exists()
        shutil.copy2(source,target)
    # Existing .import files and the separate idle_front are deliberately preserved.
    print('Installed',len(records),'PNGs by copy after complete backup')

if __name__=='__main__':{'normalize':normalize,'install':install}[sys.argv[1]]()
