extends SceneTree
var failures:=0
func _initialize() -> void:_run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error("PUPPY 2D PAW: "+message)
func _run() -> void:
	root.content_scale_size=Vector2i(768,400)
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	var background:=ColorRect.new()
	background.color=Color("ead4b0")
	background.size=Vector2(768,400)
	root.add_child(background)
	for j: int in 2:
		var label:=Label.new()
		label.text="ARTE APROVADA" if j==0 else "MESMA ARTE · PATINHA"
		label.position=Vector2(j*384+12,12)
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",Color("4b321f"))
		root.add_child(label)
	var reference:=Sprite2D.new()
	reference.centered=false
	reference.position=Vector2(0,44)
	reference.scale=Vector2.ONE*.5
	reference.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(reference)
	var rig: Node2D=load("res://scenes/art/puppy_2d_rig/puppy_2d_paw.tscn").instantiate()
	rig.position=Vector2(384,44)
	rig.scale=Vector2.ONE*.5
	root.add_child(rig)
	rig.set_process(false)
	await process_frame
	var folder:=ProjectSettings.globalize_path("res://../build/screenshots/puppy_2d_paw/")
	DirAccess.make_dir_recursive_absolute(folder)
	var status:=Label.new()
	status.position=Vector2(12,373)
	status.add_theme_font_size_override("font_size",16)
	status.add_theme_color_override("font_color",Color("4b321f"))
	root.add_child(status)
	var duration: float=rig.get("DURATION")
	# Close the preview on a whole breathing cycle so looping the GIF/HTML does
	# not jump from an arbitrary idle phase back to frame zero.
	var total:=ceilf((3.0+duration)/1.5)*1.5
	var count:=int(round(total*24.0))
	var reach_error:=0.0
	for frame: int in count:
		var time:=float(frame)/24.0
		var elapsed:=time-1.5
		var active:=elapsed>=0.0 and elapsed<duration
		rig.call("sample",time,elapsed if active else -1.0)
		var body: Node2D=rig.get("base")
		var original:=body.get_node("NeutralArtwork") as Sprite2D
		reference.texture=original.texture
		var plate: Sprite2D=rig.get("repaired")
		var paw: Polygon2D=rig.get("paw")
		check(plate.texture==original.texture and paw.texture==original.texture,"corpo e pata usam o arquivo aprovado na mesma fase")
		var upper: Bone2D=rig.get("upper")
		var lower: Bone2D=rig.get("lower")
		check(upper.scale==Vector2.ONE and lower.scale==Vector2.ONE,"ossos não são esticados")
		if rig.get("is_paw_active"):
			var actual:=rig.to_local(lower.to_global(Vector2(1,48)))
			var target: Vector2=rig.get("wrist_target")
			reach_error=maxf(reach_error,actual.distance_to(target))
			check(actual.distance_to(target)<.05,"cotovelo e punho alcançam a trajetória")
		else:
			check(body.visible and not paw.visible and not plate.visible,"repouso volta diretamente à arte original")
		status.text="Respirar → patinha no rosto → respirar · %s · %.2f s" % ["PATINHA" if active else "RESPIRANDO",time]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"frame_%03d.png" % frame)
	# Cancellation preserves the initial target and returns without restarting idle.
	rig.call("start_paw")
	rig.call("advance",0.7)
	var before: Vector2=rig.get("wrist_target")
	var time_before: float=rig.get("breathing_time")
	rig.call("cancel_paw",.24)
	check(rig.get("wrist_target")==before,"cancelar não troca a pose de uma vez")
	rig.call("advance",.12)
	check((rig.get("wrist_target") as Vector2).distance_to(Vector2(423,514))<before.distance_to(Vector2(423,514)),"retorno gradual ao apoio")
	rig.call("advance",.13)
	check(not rig.get("is_paw_active"),"retorno à imagem original")
	check(rig.get("breathing_time")>time_before+.24,"respiração continua")
	print("PUPPY 2D PAW: ","PASS" if failures==0 else "FAIL","; ",count," native captures; max wrist reach error=",reach_error)
	quit(0 if failures==0 else 1)
