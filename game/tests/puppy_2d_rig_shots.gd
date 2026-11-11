extends SceneTree
## Native image fidelity, anchored paws and shared idle→tilt→idle sequence.
var failures:=0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error("PUPPY 2D RIG: "+message)
func _run() -> void:
	root.content_scale_size=Vector2i(768,400)
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	var bg:=ColorRect.new()
	bg.color=Color("ead4b0")
	bg.size=Vector2(768,400)
	root.add_child(bg)
	for j: int in 2:
		var title:=Label.new()
		title.text="ARTE APROVADA" if j==0 else "MESMA ARTE · RIG 2D"
		title.position=Vector2(j*384+12,12)
		title.add_theme_color_override("font_color",Color("4b321f"))
		title.add_theme_font_size_override("font_size",18)
		root.add_child(title)
	var reference:=Sprite2D.new()
	reference.centered=false
	reference.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reference.position=Vector2(0,44)
	reference.scale=Vector2.ONE*.5
	root.add_child(reference)
	var rig: Node2D=load("res://scenes/art/puppy_2d_rig/puppy_2d_rig.tscn").instantiate()
	rig.position=Vector2(384,44)
	rig.scale=Vector2.ONE*.5
	root.add_child(rig)
	rig.set_process(false)
	await process_frame
	var layers: Array=rig.get("_layers")
	check(layers.size()==3,"três partes ligadas usando o mesmo desenho")
	for mesh: Polygon2D in layers:
		check(mesh.get_bone_count()==2,"controle de apoio e cabeça")
		var body:=mesh.get_bone_weights(0)
		var head:=mesh.get_bone_weights(1)
		for i: int in mesh.polygon.size():
			check(is_equal_approx(body[i]+head[i],1.0),"pesos normalizados")
			if mesh.polygon[i].y>=406.0: check(head[i]==0.0,"patas fora da deformação")
	var folder:=ProjectSettings.globalize_path("res://../build/screenshots/puppy_2d_rig/")
	DirAccess.make_dir_recursive_absolute(folder)
	var status:=Label.new()
	status.position=Vector2(12,373)
	status.add_theme_color_override("font_color",Color("4b321f"))
	status.add_theme_font_size_override("font_size",16)
	root.add_child(status)
	for frame: int in 103:
		var time:=float(frame)/24.0
		var elapsed:=time-1.5
		var acting:=elapsed>=0.0 and elapsed<9.0/7.0
		rig.call("sample",time,elapsed if acting else -1.0)
		var phase: int=rig.get("source_frame")
		reference.texture=load("res://assets/sprites/characters/tiro_pet_puppy_illustrated/idle_breathe/frame_%02d.png" % phase)
		for mesh: Polygon2D in layers: check(mesh.texture==reference.texture,"mesmo recurso original, sem novo desenho")
		status.text="Respirar → inclinar → respirar   ·   %s   ·   %.2f s" % ["INCLINANDO" if acting else "RESPIRANDO",time]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"frame_%03d.png" % frame)
	# An interrupted tilt returns continuously; the shared breathing clock keeps
	# running and no initial neutral frame is forced over the current phase.
	rig.set("animate_breath",true)
	rig.call("start_tilt")
	rig.call("advance",0.6)
	var angle: float=rig.get("head_degrees")
	check(absf(angle)>10.0,"inclinação realmente move a cabeça")
	var time_before: float=rig.get("breathing_time")
	rig.call("cancel_tilt",0.2)
	check(is_equal_approx(rig.get("head_degrees"),angle),"cancelar não salta de pose")
	rig.call("advance",0.1)
	check(absf(rig.get("head_degrees"))<absf(angle),"retorno gradual")
	rig.call("advance",0.11)
	check(is_zero_approx(rig.get("head_degrees")),"retorno neutro")
	check(rig.get("breathing_time")>time_before+.2,"respiração não reiniciou")
	print("PUPPY 2D RIG: ","PASS" if failures==0 else "FAIL","; 103 native samples; exact source artwork; anchored feet; continuous cancellation")
	quit(0 if failures==0 else 1)
