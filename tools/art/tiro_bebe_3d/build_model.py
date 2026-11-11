"""First editable 3D study of the approved puppy. Run INSIDE Blender via MCP.

Seated proportions and colour placement follow the approved idle illustration.
This is an initial modelling study, not a finished rig or an identity approval.
Creates its own scene; never clears the user's original scene or preferences.
"""
import bpy
import math
import random
import hashlib
import json
from pathlib import Path
from mathutils import Vector

ROOT=Path('C:/Users/Vitor/Documents/ClaudeGame')
OUT=ROOT/'tools/art/tiro_bebe_3d/v001'
OUT.mkdir(parents=True,exist_ok=True)
REFERENCE=ROOT/'game/assets/sprites/characters/tiro_pet_puppy_illustrated/idle_breathe/frame_00.png'
OWNER='tiro_bebe_3d_v001'

existing=bpy.data.scenes.get('Tiro_Bebe_v001')
if existing and existing.get('generator')==OWNER:
    for obj in list(existing.objects):bpy.data.objects.remove(obj,do_unlink=True)
    scene=existing
else:
    scene=bpy.data.scenes.new('Tiro_Bebe_v001')
scene['generator']=OWNER
scene['stage']='BASE_SEM_RIG_PARA_REVISAO'
scene['reference_sha256']=hashlib.sha256(REFERENCE.read_bytes()).hexdigest()
bpy.context.window.scene=scene
groups={}
for title in ['01_Volumes','02_Rosto','03_Orelhas','04_Pelagem','05_Estudio','06_Referencias']:
    group=bpy.data.collections.new('Tiro_'+title)
    scene.collection.children.link(group)
    groups[title]=group

def move(obj,group):
    for collection in list(obj.users_collection):collection.objects.unlink(obj)
    groups[group].objects.link(obj)
    obj['generator']=OWNER
    return obj

def linear(value):return value/12.92 if value<=.04045 else ((value+.055)/1.055)**2.4

def material(name,hexcode,roughness=.68,noise=False):
    color=tuple(int(hexcode[i:i+2],16)/255 for i in (0,2,4))
    mat=bpy.data.materials.new('Tiro_'+name)
    mat.diffuse_color=(*color,1)
    mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links
    bsdf=nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=(*[linear(x) for x in color],1)
    bsdf.inputs['Roughness'].default_value=roughness
    if noise:
        tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=85
        bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.06;bump.inputs['Distance'].default_value=.003
        links.new(tex.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
    return mat

M={
 'coal':material('Preto_carvao','1C1B1E',noise=True),
 'coal_mid':material('Reflexo_cinza_quente','383236'),
 'coal_light':material('Fio_cinza','4A4548'),
 'gold':material('Dourado_base','B97B35',noise=True),
 'gold_dark':material('Dourado_sombra','965323'),
 'gold_mid':material('Dourado_fio','D3964B'),
 'cream':material('Dourado_luz','E3B673'),
 'nose':material('Nariz_preto','191719',.27),
 'mouth':material('Boca_interna','28191D',.64),
 'tongue':material('Lingua','DA7F89',.48),
 'iris':material('Iris_castanha','583214',.2),
 'pupil':material('Pupila','100D0D',.13),
 'highlight':material('Reflexo_olho','FFF5DC',.08),
 'ground':material('Fundo_neutro','D9CAB4',.9),
}

def ellipsoid(name,location,radii,mat,group='01_Volumes',rotation=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=32,location=location)
    obj=bpy.context.object;obj.name='Tiro_'+name;obj.scale=radii
    if rotation:obj.rotation_euler=rotation
    move(obj,group);obj.data.materials.append(mat)
    for polygon in obj.data.polygons:polygon.use_smooth=True
    return obj

def strand_curve(name,paths,mats,thickness=.0025,group='04_Pelagem'):
    data=bpy.data.curves.new('Tiro_'+name,'CURVE');data.dimensions='3D'
    data.resolution_u=2;data.bevel_depth=thickness;data.bevel_resolution=0
    for mat in mats:data.materials.append(mat)
    for points,mat_index in paths:
        spline=data.splines.new('POLY');spline.points.add(len(points)-1)
        spline.material_index=mat_index
        for j,(point,co) in enumerate(zip(spline.points,points)):
            point.co=(*co,1);point.radius=[.72,1,.6,.015][min(j,3)] if len(points)==4 else 1
    obj=bpy.data.objects.new('Tiro_'+name,data);move(obj,group)
    return obj

def coat(obj,count,length,mats,seed,kind='down',reject=None,thickness=.0015):
    rng=random.Random(seed);paths=[]
    centre=obj.location.copy();scale=obj.scale.copy();rotation=obj.rotation_euler.to_matrix()
    for i in range(count):
        zz=rng.uniform(-1,1);phi=rng.uniform(0,math.tau);rr=math.sqrt(1-zz*zz)
        unit=Vector((rr*math.cos(phi),rr*math.sin(phi),zz))
        point=centre+rotation@Vector((unit.x*scale.x,unit.y*scale.y,unit.z*scale.z))
        if reject and reject(point):continue
        normal=(rotation@Vector((unit.x/scale.x,unit.y/scale.y,unit.z/scale.z))).normalized()
        sign=1 if point.x>=0 else -1
        direction=Vector((sign*.3,-.08,-1))
        if kind=='brow':direction=Vector((sign*.9,-.15,.15))
        elif kind=='beard':direction=Vector((sign*.75,-.15,-.65))
        elif kind=='chest':direction=Vector((sign*.65,-.08,-.7))
        elif kind=='crown':direction=Vector((sign*.8,.15,.3 if abs(point.x)<.16 else -.7))
        tangent=direction-normal*direction.dot(normal)
        if tangent.length<.01:tangent=Vector((normal.z,0,-normal.x))
        tangent.normalize();size=length*rng.uniform(.6,1.45)
        points=[]
        for t in [0,.34,.70,1]:
            points.append(point+tangent*(size*t)+normal*(.007+size*(.15*math.sin(math.pi*t)+.10*t)))
        paths.append((points,rng.choices(range(len(mats)),weights=([16,3,1] if len(mats)==3 else [9,1]))[0]))
    return strand_curve(obj.name+'_Fios',paths,mats,thickness)

def line(name,points,mat,radius=.012,group='02_Rosto'):
    return strand_curve(name,[(list(map(Vector,points)),0)],[mat],radius,group)

def front_surface(objects,x,z):
    ys=[]
    for obj in objects:
        inside=1-((x-obj.location.x)/obj.scale.x)**2-((z-obj.location.z)/obj.scale.z)**2
        if inside>=0:ys.append(obj.location.y-obj.scale.y*math.sqrt(inside))
    return min(ys) if ys else -.3

def surface_patch(name,outline,supports,mat,hairs,seed,group='02_Rosto'):
    # Colour lies on the real skin instead of forming a separate raised blob.
    centre=Vector((sum(p[0] for p in outline)/len(outline),sum(p[1] for p in outline)/len(outline)))
    vertices=[(centre.x,front_surface(supports,centre.x,centre.y)-.009,centre.y)]
    n=len(outline);rings=8;faces=[]
    for ring in range(1,rings+1):
        t=ring/rings
        for x,z in outline:
            p=centre.lerp(Vector((x,z)),t)
            vertices.append((p.x,front_surface(supports,p.x,p.y)-.009,p.y))
    for i in range(n):faces.append((0,1+i,1+(i+1)%n))
    for ring in range(1,rings):
        for i in range(n):
            a=1+(ring-1)*n+i;b=1+(ring-1)*n+(i+1)%n
            c=1+ring*n+(i+1)%n;d=1+ring*n+i
            faces.extend([(a,b,c),(a,c,d)])
    mesh=bpy.data.meshes.new('Tiro_'+name+'_mesh');mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new('Tiro_'+name,mesh);move(obj,group);mesh.materials.append(mat)
    for polygon in mesh.polygons:polygon.use_smooth=True
    rng=random.Random(seed);paths=[]
    for i in range(hairs):
        boundary=Vector(outline[rng.randrange(n)]);p=centre.lerp(boundary,math.sqrt(rng.random())*.97)
        root=Vector((p.x,front_surface(supports,p.x,p.y)-.014,p.y))
        direction=Vector(((1 if p.x>=0 else -1)*.60,-.08,-.55)).normalized();ll=rng.uniform(.04,.10)
        points=[]
        for t in [0,.34,.70,1]:
            sample=root+direction*(ll*t)
            sample.y=min(sample.y,front_surface(supports,sample.x,sample.z)-.017)-.006*math.sin(math.pi*t)
            points.append(sample)
        paths.append((points,rng.choices([0,1,2],weights=[12,4,1])[0]))
    strand_curve(name+'_Fios',paths,[M['gold'],M['gold_mid'],M['cream']],.0016)
    return obj

# Body: seated quadruped. The rear feet remain separate and behind the front.
body=ellipsoid('Tronco',(0,.15,1.02),(.52,.44,.77),M['coal'])
shoulders=ellipsoid('Peito_estrutura',(0,-.01,1.43),(.49,.37,.39),M['coal'])
neck=ellipsoid('Pescoco',(0,-.055,1.68),(.37,.32,.40),M['coal'])
coat(body,1800,.12,[M['coal'],M['coal_mid'],M['coal_light']],11)
coat(shoulders,650,.11,[M['coal'],M['coal_mid']],12)
coat(neck,700,.095,[M['coal'],M['coal_mid']],13)

for side,sign in [('Direita',-1),('Esquerda',1)]:
    thigh=ellipsoid('Coxa_traseira_'+side,(sign*.43,.22,.45),(.29,.32,.41),M['coal'])
    hind=ellipsoid('Pata_traseira_'+side,(sign*.59,-.02,.13),(.20,.25,.14),M['gold'])
    upper=ellipsoid('Antebraco_'+side,(sign*.29,-.235,.68),(.17,.20,.49),M['coal'])
    leg=ellipsoid('Canela_dianteira_'+side,(sign*.29,-.30,.39),(.165,.19,.29),M['gold'])
    paw=ellipsoid('Pata_dianteira_'+side,(sign*.29,-.43,.135),(.215,.275,.145),M['gold'])
    for obj,n,ll in [(thigh,500,.105),(upper,500,.10),(leg,420,.07),(hind,180,.05),(paw,250,.04)]:
        coat(obj,n,ll,[M['coal'],M['coal_mid']] if obj in [thigh,upper] else [M['gold'],M['gold_mid'],M['cream']],20+len(bpy.data.objects))
    for toe in [-.075,0,.075]:
        line('Dobra_dedos_'+side+str(toe),[(sign*.29+toe,-.675,.15),(sign*.29+toe,-.69,.105)],M['gold_dark'],.004)

# Chest markings sit on the torso and follow its volume.
surface_patch('Marca_peito',[(-.40,1.32),(-.24,1.29),(-.10,1.21),(0,1.24),(.10,1.21),(.24,1.29),(.40,1.32),(.34,1.12),(.18,1.05),(0,.88),(-.18,1.05),(-.34,1.12)],[body,shoulders],M['gold'],1100,54,'01_Volumes')

# Skull and face: dark cap, golden brows/cheeks/muzzle, brown eyes, black nose.
head=ellipsoid('Cabeca',(0,-.04,2.13),(.75,.565,.65),M['coal'])
coat(head,3200,.115,[M['coal'],M['coal_mid'],M['coal_light']],71,kind='crown',reject=lambda p:p.y<-.28 and p.z<2.48 and abs(p.x)<.64)
for sign in [-1,1]:
    cheek=ellipsoid('Bochecha_'+str(sign),(sign*.42,-.43,1.94),(.255,.19,.29),M['gold'],'02_Rosto')
    muzzle=ellipsoid('Focinho_lado_'+str(sign),(sign*.21,-.60,1.91),(.315,.26,.24),M['gold'],'02_Rosto')
    brow_outline=[]
    for i in range(40):
        t=math.tau*i/40
        xx=.34+.19*math.cos(t);zz=2.32+.175*math.sin(t)+.12*(xx-.34)
        brow_outline.append((sign*xx,zz))
    surface_patch('Sobrancelha_'+str(sign),brow_outline,[head],M['gold'],500,70+sign)
    for obj,n,ll,kind in [(cheek,500,.115,'beard'),(muzzle,700,.09,'beard')]:
        coat(obj,n,ll,[M['gold'],M['gold_mid'],M['cream']],80+len(bpy.data.objects),kind=kind)
    eyeball=ellipsoid('Olho_'+str(sign),(sign*.285,-.46,2.235),(.15,.12,.17),M['pupil'],'02_Rosto')
    ellipsoid('Iris_'+str(sign),(sign*.285,-.574,2.235),(.113,.016,.135),M['iris'],'02_Rosto')
    ellipsoid('Pupila_'+str(sign),(sign*.285,-.589,2.24),(.085,.011,.108),M['pupil'],'02_Rosto')
    ellipsoid('Brilho_olho_'+str(sign),(sign*.285-.031,-.600,2.29),(.020,.008,.025),M['highlight'],'02_Rosto')
    ellipsoid('Brilho_pequeno_'+str(sign),(sign*.285+.024,-.601,2.21),(.008,.005,.010),M['highlight'],'02_Rosto')

jaw=ellipsoid('Queixo',(0,-.49,1.68),(.36,.23,.15),M['gold'],'02_Rosto')
coat(jaw,450,.085,[M['gold'],M['gold_mid'],M['cream']],103,kind='beard')
ellipsoid('Boca_sorriso',(0,-.705,1.735),(.245,.085,.115),M['mouth'],'02_Rosto')
ellipsoid('Lingua',(0,-.79,1.68),(.08,.025,.11),M['tongue'],'02_Rosto')
line('Lingua_sulco',[(0,-.817,1.74),(0,-.818,1.665)],M['gold_dark'],.0028)
nose=ellipsoid('Nariz',(0,-.861,1.995),(.155,.095,.105),M['nose'],'02_Rosto')
for vertex in nose.data.vertices:
    vertex.co.x*=.78+.22*(vertex.co.z+1)/2
for sign in [-1,1]:ellipsoid('Narina_'+str(sign),(sign*.071,-.946,1.99),(.035,.009,.023),M['pupil'],'02_Rosto')
line('Filtro_nariz',[(0,-.876,1.94),(0,-.88,1.81)],M['mouth'],.009)

# Rounded folded triangular ears. Tips hang at the sides, not upright cat ears.
for sign in [-1,1]:
    boundary=[(.49,-.015,2.57),(.70,-.025,2.67),(.98,-.08,2.43),(.94,-.23,2.17),(.85,-.34,2.02),(.69,-.30,2.19),(.61,-.11,2.42)]
    front=[(sign*x,y,z) for x,y,z in boundary]
    back=[(x,y+.065,z) for x,y,z in front]
    vertices=front+back+[(sign*.78,-.27,2.36),(sign*.78,-.08,2.36)]
    faces=[];n=len(front)
    for i in range(n):
        j=(i+1)%n;faces.extend([(2*n,i,j),(2*n+1,n+j,n+i),(i,n+i,n+j,j)])
    mesh=bpy.data.meshes.new('Tiro_Orelha_mesh');mesh.from_pydata(vertices,[],faces);mesh.update()
    ear=bpy.data.objects.new('Tiro_Orelha_'+str(sign),mesh);move(ear,'03_Orelhas');ear.data.materials.append(M['coal'])
    modifier=ear.modifiers.new('Dobras_arredondadas','SUBSURF');modifier.levels=2
    for polygon in mesh.polygons:polygon.use_smooth=True
    edgepoints=[(sign*.57,-.12,2.57),(sign*.70,-.15,2.54),(sign*.77,-.30,2.27),(sign*.85,-.35,2.09)]
    line('Dobra_dourada_orelha_'+str(sign),edgepoints,M['gold_mid'],.045,'03_Orelhas')
    rng=random.Random(110+sign);paths=[]
    for i in range(340):
        t=rng.random();a=Vector(edgepoints[0]).lerp(Vector(edgepoints[2]),t)
        a.x+=rng.uniform(-.045,.045);a.y-=rng.uniform(0,.025);a.z+=rng.uniform(-.05,.05)
        direction=Vector((sign*.35,-.12,-1)).normalized();ll=rng.uniform(.06,.13)
        paths.append(([a,a+direction*ll*.35,a+direction*ll*.75,a+direction*ll],rng.randrange(3)))
    strand_curve('Orelha_fios_'+str(sign),paths,[M['gold'],M['gold_mid'],M['cream']],.002)

# The reference hides most of the tail: keep it discreet behind the rump.
tail=line('Cauda_base',[(.26,.46,.38),(.52,.63,.42),(.75,.65,.58),(.85,.61,.77)],M['coal'],.075,'01_Volumes')
tail_tip=ellipsoid('Cauda_ponta',(.78,.63,.64),(.11,.12,.23),M['coal'],rotation=(0,.35,0))
coat(tail_tip,500,.13,[M['coal'],M['coal_mid'],M['coal_light']],127)

# Reference is packed and visible in the modelling scene, excluded from renders.
image=bpy.data.images.load(str(REFERENCE),check_existing=True);image.pack()
reference=bpy.data.objects.new('Tiro_REFERENCIA_APROVADA',None);reference.empty_display_type='IMAGE';reference.data=image
reference.empty_display_size=5.2;reference.location=(-3.0,0,1.40);reference.rotation_euler=(math.pi/2,0,0)
reference.hide_render=True;move(reference,'06_Referencias')

world=bpy.data.worlds.new('Tiro_Estudio_mundo');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.7,.66,.60,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35;scene.world=world

def aim(obj,point):obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()

def camera(name,location):
    data=bpy.data.cameras.new('Tiro_Camera_'+name);obj=bpy.data.objects.new('Tiro_Camera_'+name,data);move(obj,'05_Estudio')
    obj.location=location;aim(obj,(0,0,1.42));data.type='ORTHO';data.ortho_scale=3.35;return obj

cameras={'front':camera('Frente',(0,-8,1.42)),'three_quarter':camera('Tres_quartos',(4.4,-7,3.0)),
 'side':camera('Lado',(8,0,1.6)),'back':camera('Costas',(0,8,1.7))}
scene.camera=cameras['three_quarter']
for name,position,energy,size in [('Principal',(-3,-4,5),400,4),('Preenchimento',(3,-3,3),230,3),('Recorte',(1,3,4),400,3)]:
    data=bpy.data.lights.new('Tiro_Luz_'+name,'AREA');data.energy=energy;data.shape='DISK';data.size=size
    obj=bpy.data.objects.new('Tiro_Luz_'+name,data);move(obj,'05_Estudio');obj.location=position;aim(obj,(0,0,1.3))

scene.render.engine='CYCLES'
scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=640;scene.render.resolution_y=760;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'
scene.render.filepath=str(OUT/'three_quarter.png')
for obj in scene.objects:obj.select_set(False)
head.select_set(True);bpy.context.view_layer.objects.active=head
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_location=Vector((0,0,1.4));area.spaces.active.region_3d.view_distance=4.7
        area.spaces.active.region_3d.view_rotation=cameras['three_quarter'].rotation_euler.to_quaternion()
        area.spaces.active.shading.type='SOLID';area.spaces.active.shading.color_type='MATERIAL'
        area.spaces.active.overlay.show_extras=False

palette={name:tuple(round(x,4) for x in mat.diffuse_color[:3]) for name,mat in M.items()}
report={'stage':'initial_model_not_rigged_not_approved','reference':str(REFERENCE.relative_to(ROOT)).replace('\\','/'),
 'reference_sha256':scene['reference_sha256'],'scene':scene.name,'palette_srgb':palette,
 'objects':len(scene.objects),'hair_strands':sum(len(o.data.splines) for o in groups['04_Pelagem'].objects if o.type=='CURVE'),
 'anatomy':'seated quadruped, two forelegs and two hindlegs; separate jaws/ears/tail',
 'inferred':'hidden back/side coat distribution and most of tail; must be reviewed',
 'limitations':['Initial volumes and fur study; not identity-approved.','No rig, animation or game integration.','Not production skin topology.']}
(OUT/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'tiro_bebe_v001.blend'))
result={'scene':scene.name,'file':bpy.data.filepath,'objects':len(scene.objects),'hair_strands':report['hair_strands'],'stage':report['stage']}
