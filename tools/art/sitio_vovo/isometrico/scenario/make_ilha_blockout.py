import sys, math
from PIL import Image, ImageDraw, ImageFont
S=sys.argv[1]; LAB=sys.argv[2]=="1"; OUT=sys.argv[3]   # uso: py -I make_ilha_blockout.py <pasta> <1=etiquetas|0=limpo> <saida.png>
N=30; T=40; W=2400; Y0=330; H=1700; X0=W/2
img=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(img)
try: font=ImageFont.truetype("arialbd.ttf",34)
except OSError: font=ImageFont.load_default()
def P(wx,wy): return (X0+(wx-wy)*T, Y0+(wx+wy)*T/2)
def poly(pts,fill,edge=None):
    d.polygon([P(*p) if len(p)==2 and isinstance(p,tuple) else p for p in pts],fill=fill,outline=edge)
EDGE=(60,40,20)
GRASS=(150,196,92); DIRT=(226,186,120); WATER=(70,170,210)
def flat(x0,x1,y0,y1,fill,edge=None):
    d.polygon([P(x0,y0),P(x1,y0),P(x1,y1),P(x0,y1)],fill=fill,outline=edge)
def label(wx,wy,text,lift=0):
    if not LAB: return
    x,y=P(wx,wy); y-=lift
    tw=d.textlength(text,font=font)
    d.rectangle([x-tw/2-8,y-22,x+tw/2+8,y+22],fill=(255,255,255),outline=(0,0,0)); d.text((x-tw/2,y-19),text,fill=(20,20,20),font=font)
# laje (espessura)
TH=70
l=[P(0,N),P(N,N),(P(N,N)[0],P(N,N)[1]+TH),(P(0,N)[0],P(0,N)[1]+TH)]; d.polygon(l,fill=(140,95,60),outline=EDGE)
r=[P(N,N),P(N,0),(P(N,0)[0],P(N,0)[1]+TH),(P(N,N)[0],P(N,N)[1]+TH)]; d.polygon(r,fill=(115,75,48),outline=EDGE)
flat(0,N,0,N,GRASS,EDGE)
# caminhos (retângulos alinhados aos eixos, largura ~2.4 tiles)
w=1.2
flat(16-w,16+w,7.5,9.5+w,DIRT)            # porta -> travessa
flat(8-w,22+w,9.5-w,9.5+w,DIRT)               # travessa
flat(22-w,22+w,9.5-w,28.5+w,DIRT)             # tronco direito
flat(22-w,28.5,28.5-w,28.5+w,DIRT)            # até o portão
flat(8-w,8+w,9.5-w,22,DIRT)                   # tronco esquerdo
objs=[]
def box(x0,x1,y0,y1,h,top,left,right,name=None,lab=None):
    objs.append((x0+x1+y0+y1,("box",x0,x1,y0,y1,h,top,left,right,name,lab)))
def draw_box(o):
    _,x0,x1,y0,y1,h,top,left,right,name,lab=o
    b=[P(x0,y0),P(x1,y0),P(x1,y1),P(x0,y1)]; t=[(x,y-h) for x,y in b]
    d.polygon([b[3],b[2],t[2],t[3]],fill=left,outline=EDGE)
    d.polygon([b[2],b[1],t[1],t[2]],fill=right,outline=EDGE)
    d.polygon(t,fill=top,outline=EDGE)
    if lab: label((x0+x1)/2,(y0+y1)/2,lab,lift=h+40)
RED=(200,90,60); CL=(232,208,165); CR=(212,186,142); WL=(205,155,95); WR=(185,135,80)
box(12.5,19.5,1.5,7.5,150,RED,CL,CR,lab="CASA DA VOVO")
box(2,5,1.5,4.5,110,(170,170,175),(190,190,195),(160,160,165),lab="SILO")
box(3,7,5.8,8.2,55,RED,WL,WR,lab="ARMAZEM")
box(20.7,23,3.5,5.8,30,(170,120,60),(150,100,50),(130,85,45),lab="BANCADA")
box(24.5,28,2,5.5,120,(205,165,95),(210,180,120),(190,160,100),lab="MOINHO")
box(24.5,28.5,7,10.5,60,RED,WL,WR,lab="QUEIJARIA")
# patios cercados (planos) + construcao pequena
def yard(x0,x1,y0,y1):
    flat(x0,x1,y0,y1,(190,160,110),(140,90,40))
yard(23.2,29.6,11.5,18.5); yard(23.2,29.6,19.5,27)
box(25.7,28.7,12,15,60,RED,WL,WR,lab="GALINHEIRO")
box(25,29,20,24,80,RED,WL,WR,lab="CURRAL (VACAS)")
box(9.5,16,24.5,29.5,50,(200,225,235),(170,200,215),(150,180,195),lab="ESTUFA (4 canteiros)")
box(17.5,20.5,25,28,55,(205,165,95),(170,120,60),(150,100,50),lab="BANCA DE VENDA")
box(27.5,29.5,28.2,30,70,(170,110,50),(150,95,45),(130,80,40),lab="PORTAO")
# pomar: faixa na borda esquerda-traseira
flat(1,7,10,20,(120,170,80),(80,120,50))
for ty in (11.5,14,16.5,19):
    for tx in (2.5,5.5):
        cx,cy=P(tx,ty); d.ellipse([cx-40,cy-110,cx+40,cy-20],fill=(70,140,60),outline=EDGE)
label(4,15,"POMAR",lift=130)
# lago opcional (decoração)
flat(1,7,22.5,29,(95,180,215),(40,110,150))
label(4,26,"LAGO (opcional)")
# horta central: 9 canteiros 3x3 (gap 1)
for j in range(3):
    for i in range(3):
        x0=9.5+i*3.75; y0=10.8+j*3.75
        box(x0,x0+3,y0,y0+3,14,(105,66,38),(168,118,68),(148,98,58))
label(14.5,22.6,"HORTA: 9 CANTEIROS")
# curral/galinheiro: cercado em volta
for (a,b,c,e) in ((23.2,29.8,11.2,18.8),(23.2,29.8,18.2,26)):
    pass
objs.sort(key=lambda t:t[0])
for k,o in objs: draw_box((k,)+o[1:])
img.save(OUT); print(OUT, img.size)
