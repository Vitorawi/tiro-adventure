import sys, json, collections, time
from PIL import Image, ImageFilter, ImageChops, ImageStat
S=sys.argv[1]; D=sys.argv[2]
BASE=r"C:/Users/Vitor/Documents/ClaudeGame/tools/art/sitio_vovo/isometrico/scenario/sitio_ilha_base.png"
p=Image.open(S+"/pecas_tudo_raw.png").convert("RGBA")
r,g,b,a=p.split(); a=a.point(lambda v:0 if v<14 else v); p=Image.merge("RGBA",(r,g,b,a))
base=Image.open(BASE).convert("RGB"); W,H=p.size; k=2
small=a.resize((W//k,H//k),Image.BILINEAR).point(lambda v:255 if v>40 else 0).filter(ImageFilter.MaxFilter(3))
sw,sh=small.size; px=small.load(); lab=[[0]*sw for _ in range(sh)]; comps=[]; n=0
for y in range(sh):
    for x in range(sw):
        if px[x,y] and not lab[y][x]:
            n+=1; q=collections.deque([(x,y)]); lab[y][x]=n; pts=[]
            while q:
                cx,cy=q.popleft(); pts.append((cx,cy))
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx,ny=cx+dx,cy+dy
                    if 0<=nx<sw and 0<=ny<sh and px[nx,ny] and not lab[ny][nx]:
                        lab[ny][nx]=n; q.append((nx,ny))
            comps.append(pts)
big=[]
for pts in comps:
    if len(pts)<800: continue
    xs=[q[0] for q in pts]; ys=[q[1] for q in pts]
    big.append(dict(pts=pts,cx=sum(xs)/len(xs)*k,cy=sum(ys)/len(ys)*k))
def name_of(c):
    cx,cy=c["cx"],c["cy"]
    if cx<1000 and cy<700: return "pomar"
    if 1100<cx<1450 and cy<400: return "bancada"
    if cx>2100 and cy<650: return "moinho"
    if 1500<cx<2000 and 600<cy<1000: return "galinheiro"
    if cx>1900 and 750<cy<1200: return "queijaria"
    if cx>1350 and cy>1000: return "curral"
    if cx<900 and cy>1100: return "estufa"
    if cx>1300 and cy<700: return "silo_armazem"
    return "canteiro"
items=[]
cnt=0
for c in big:
    nm=name_of(c)
    m=Image.new("L",(sw,sh),0); mp=m.load()
    for x,y in c["pts"]: mp[x,y]=255
    m=m.resize((W,H),Image.NEAREST).filter(ImageFilter.MaxFilter(5))
    pc=p.copy(); al=ImageChops.multiply(pc.split()[3],m); pc.putalpha(al)
    if nm=="silo_armazem":
        sa=pc.copy(); sb=pc.copy()
        left=Image.new("L",(W,H),0); left.paste(255,(0,0,1655,H))
        sa.putalpha(ImageChops.multiply(sa.split()[3],left)); sb.putalpha(ImageChops.multiply(sb.split()[3],Image.eval(left,lambda v:255-v)))
        items.append(("silo",sa)); items.append(("armazem",sb))
    elif nm=="canteiro":
        items.append(("canteiro_%d"%cnt,pc)); cnt+=1
    else: items.append((nm,pc))
SC=float(sys.argv[3]) if len(sys.argv)>3 else 0.8
CX,CY=W/2,H/2
def match(piece,name):
    bb=piece.getbbox(); pc_hr=piece.crop(bb)
    pc=pc_hr.resize((max(1,round(pc_hr.width*SC)),max(1,round(pc_hr.height*SC))),Image.LANCZOS)
    mask=pc.split()[3].point(lambda v:255 if v>200 else 0)
    ox=round(CX+SC*(bb[0]-CX)); oy=round(CY+SC*(bb[1]-CY)); best=None
    ps=pc.convert("RGB").resize((pc.width//4,pc.height//4),Image.BILINEAR).convert("L"); ms=mask.resize(ps.size,Image.NEAREST)
    bs=base.resize((W//4,H//4),Image.BILINEAR).convert("L"); cx0,cy0=ox//4,oy//4; R=60
    for dy in range(-R,R+1):
        for dx in range(-R,R+1):
            x0,y0=cx0+dx,cy0+dy
            if x0<0 or y0<0 or x0+ps.width>bs.width or y0+ps.height>bs.height: continue
            d=ImageChops.difference(bs.crop((x0,y0,x0+ps.width,y0+ps.height)),ps)
            e=ImageStat.Stat(d,mask=ms).mean[0]
            if best is None or e<best[0]: best=(e,x0*4,y0*4)
    bg=base.convert("L"); gp=pc.convert("RGB").convert("L"); bx,by=best[1],best[2]; best2=None
    for dy in range(-5,6):
        for dx in range(-5,6):
            x0,y0=bx+dx,by+dy
            if x0<0 or y0<0 or x0+gp.width>W or y0+gp.height>H: continue
            d=ImageChops.difference(bg.crop((x0,y0,x0+gp.width,y0+gp.height)),gp)
            e=ImageStat.Stat(d,mask=mask).mean[0]
            if best2 is None or e<best2[0]: best2=(e,x0,y0)
    return pc_hr,pc,best2
res={}
t0=time.time()
for nm,pc in items:
    hr,sm,(e,x,y)=match(pc,nm)
    hr.save("%s/%s_hr.png"%(D,nm)); sm.save("%s/%s.png"%(D,nm))
    res[nm]=dict(x=x,y=y,w=sm.width,h=sm.height,erro=round(e,1),escala=SC)
    print(nm,res[nm],"%.0fs"%(time.time()-t0),flush=True)
json.dump(res,open(D+"/posicoes.json","w"),indent=1)
