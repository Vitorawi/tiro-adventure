import sys
from pathlib import Path
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'python_libs'))
import json, re, urllib.request, concurrent.futures, math, hashlib, subprocess
from PIL import Image, ImageDraw
import numpy as np
ROOT = HERE.parents[2]
ANIM = HERE / 'animations'

def download():
    text = (HERE / 'character_progress.txt').read_text(encoding='utf-8')
    jobs = {x['name']: x for x in json.loads((HERE/'jobs_all_20261024.json').read_text(encoding='utf-8'))}
    manifest = json.loads((ANIM/'manifest_animacoes.json').read_text(encoding='utf-8-sig'))
    entries = {e['nome']:e for e in manifest['animations']}
    tasks=[]
    for match in re.finditer(r'^  ([\w_]+) — .*?\[group: ([\w-]+)\]\n    south: (\S+) \(i=0\.\.(\d+)\)',text,re.M):
        name,group,url,last=match.groups()
        if name not in jobs: continue
        args=jobs[name]['args']; receipt=jobs[name]['result']['content'][0]['text']
        jid=re.search(r'job_ids: south=([\w-]+)',receipt).group(1)
        entry=entries.get(name)
        if entry is None:
            entry={'nome':name}; manifest['animations'].append(entry)
        entry.update(animation_id=re.search(r'/animations/([^/]+)/',url).group(1), animation_group_id=group,
                     job_id=jid, tipo='custom', modo=args['mode'], action_description=args['action_description'],
                     descricao=args['action_description'], frames=int(last)+1, numero_frames=int(last)+1,
                     frame_url_template=url, status='completed', download_status='pending', versao_final=name)
        if 'custom_start_frame_url' in args: entry['custom_start_frame_url']=args['custom_start_frame_url']
        folder=ANIM/name; folder.mkdir(exist_ok=True)
        for i in range(int(last)+1):
            target=folder/f'frame_{i:02d}.png'
            if not target.exists(): tasks.append((url.replace('{i}',str(i)),target))
    def fetch(task):
        url,target=task
        for attempt in range(3):
            try:
                result=subprocess.run(['curl.exe','--fail','--silent','--show-error','--location','--max-time','45',url],capture_output=True,check=True)
                data=result.stdout
                assert data[:8]==b'\x89PNG\r\n\x1a\n'
                target.write_bytes(data); return str(target.relative_to(HERE))
            except Exception:
                if attempt==2: raise
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for result in pool.map(fetch,tasks): print(result,flush=True)
    for e in manifest['animations']:
        fs=sorted((ANIM/e['nome']).glob('frame_*.png'))
        if fs:
            e['canvas']=list(Image.open(fs[0]).size);e['download_status']='downloaded'
    (ANIM/'manifest_animacoes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def review():
    audit=HERE/'review'/'pixel_audit.json'
    report=json.loads(audit.read_text()) if audit.exists() else {}
    for folder in sorted(ANIM.iterdir()):
        if not folder.is_dir():continue
        if len(sys.argv)>2 and folder.name not in sys.argv[2:]:continue
        files=sorted(folder.glob('frame_*.png'))
        if not files:continue
        cols=3;cellw=max(Image.open(p).width for p in files)*2+12; cellh=max(Image.open(p).height for p in files)*2+30
        sheet=Image.new('RGB',(cols*cellw,math.ceil(len(files)/cols)*cellh),'#747c82');draw=ImageDraw.Draw(sheet)
        results=[]
        for i,p in enumerate(files):
            im=Image.open(p).convert('RGBA');a=np.array(im); mask=a[:,:,3]>0
            # Main opaque connected component is the body. Detached near-white pixels are counted exactly.
            seen=np.zeros(mask.shape,dtype=bool); comps=[]
            for y,x in zip(*np.where(mask)):
                if seen[y,x]:continue
                stack=[(int(y),int(x))];seen[y,x]=True;component=[]
                while stack:
                    yy,xx=stack.pop();component.append((yy,xx))
                    for dy,dx in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
                        ny,nx=yy+dy,xx+dx
                        if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:
                            seen[ny,nx]=True;stack.append((ny,nx))
                comps.append(component)
            body=max(comps,key=len);bodymask=np.zeros(mask.shape,dtype=bool)
            for y,x in body:bodymask[y,x]=True
            white=(a[:,:,:3]>220).all(axis=2)&mask
            outside=white & ~bodymask
            # Remove near-white from the silhouette, flood background; enclosed teeth/eye highlights stay inside.
            from collections import deque
            solid=mask & ~white
            flood=np.zeros(mask.shape,dtype=bool)
            queue=deque()
            for yy in range(mask.shape[0]):
                for xx in (0,mask.shape[1]-1):
                    if not solid[yy,xx]:flood[yy,xx]=True;queue.append((yy,xx))
            for xx in range(mask.shape[1]):
                for yy in (0,mask.shape[0]-1):
                    if not solid[yy,xx] and not flood[yy,xx]:flood[yy,xx]=True;queue.append((yy,xx))
            while queue:
                yy,xx=queue.popleft()
                for dy,dx in [(-1,0),(1,0),(0,-1),(0,1)]:
                    ny,nx=yy+dy,xx+dx
                    if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and not solid[ny,nx] and not flood[ny,nx]:
                        flood[ny,nx]=True;queue.append((ny,nx))
            outside_outline=white & flood
            results.append({'frame':p.name,'canvas':im.size,'bbox':im.getbbox(),'quase_brancos_total':int(white.sum()),'quase_brancos_fora_componente_corpo':int(outside.sum()),'quase_brancos_expostos_ao_fundo':int(outside_outline.sum()),'coordenadas':np.argwhere(outside_outline).tolist()})
            x=(i%cols)*cellw;y=(i//cols)*cellh
            draw.text((x+4,y+4),f'{folder.name} {i:02d}',fill='white')
            sheet.paste(im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST),(x,y+24),im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST))
        out=HERE/'review'/f'{folder.name}_all.png';out.parent.mkdir(exist_ok=True);sheet.save(out)
        report[folder.name]=results
        print(folder.name,len(files),Image.open(files[0]).size,'white outside',sum(r['quase_brancos_fora_componente_corpo'] for r in results))
    (HERE/'review'/'pixel_audit.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':
    {'download':download,'review':review}[sys.argv[1]]()
