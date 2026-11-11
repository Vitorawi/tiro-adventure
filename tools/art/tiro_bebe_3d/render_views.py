"""Background review renders. Does not change the master .blend file."""
import bpy
from pathlib import Path

OUT=Path('C:/Users/Vitor/Documents/ClaudeGame/tools/art/tiro_bebe_3d/v001')
scene=bpy.data.scenes['Tiro_Bebe_v001']
bpy.context.window.scene=scene
scene.render.engine='CYCLES'
scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED';scene.render.threads=6
scene.render.resolution_percentage=100
for view,name in [('front','Frente'),('three_quarter','Tres_quartos'),('side','Lado'),('back','Costas')]:
    scene.camera=bpy.data.objects['Tiro_Camera_'+name]
    scene.render.filepath=str(OUT/(view+'.png'))
    bpy.ops.render.render(write_still=True)
print('TIRO MODEL: four camera views rendered')
