extends SceneTree
## Efeitos do cenário não atravessam janelas. Com renderização, compara pixels cobertos pelo painel.

var failures := 0
var main: Control
var sheet: Control

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Camadas dos efeitos: " + message)

func frames() -> void:
	for i in 8: await process_frame

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	state.call("reset")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	sheet = main.get_node("Sheet")
	var pet: Control = main.find_child("PetScreen", true, false)
	# O Zz real do sono, inclusive se emitido enquanto a janela já está aberta.
	state.call("set_sleeping", true)
	Motion.reduced = false
	pet.set("_sleep_age", 2.1)
	pet.call("_process", 0.0)
	Motion.reduced = true
	var found := false
	for child: Node in pet.get_children():
		if child is Label and child.text == "Zz":
			found = true
			check(child.z_index < sheet.z_index and not child.z_as_relative, "sono real fica abaixo da janela")
	check(found, "emitiu o Zz do sono")
	state.call("set_sleeping", false)
	# Os corações da comida favorita pertencem ao cenário, como os Zz.
	var before := pet.get_children()
	Motion.reduced = false
	pet.call("_on_taste", "carrot", "loved")
	Motion.reduced = true
	for child: Node in pet.get_children():
		if child not in before and child is CanvasItem:
			check(child.z_index < sheet.z_index, "corações e reações ficam abaixo da janela")
	for child: Node in main.get_children():
		if child.get_script() == load("res://scripts/ui/collect_fx.gd"):
			check(child.z_index < sheet.z_index, "ganhos do cenário ficam abaixo da janela")
	for place: String in ["pet", "house", "farm"]:
		var host: Control = pet
		if place == "pet": main.call("show_screen", &"pet")
		else:
			main.call("_on_world_requested", place, "")
			await frames()
			host = main.find_child("World_" + place, true, false)
		var content := VBoxContainer.new()
		content.custom_minimum_size = Vector2(200, 240)
		root.get_node("Events").sheet_requested.emit("Janela na frente", content)
		await frames()
		for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]: main.get(member).hide()
		main.get("_modal_queue").clear()
		var panel: Control = sheet.get_node("%Panel")
		var position := panel.global_position + Vector2(70, 110) - host.global_position
		Motion.reduced = false
		var tween := Motion.float_text(host, position, "Zz", Color.MAGENTA)
		tween.pause()
		Motion.reduced = true
		var label := host.get_child(host.get_child_count() - 1) as Label
		check(label.z_index < sheet.z_index, "painel cobre o texto em " + place)
		if DisplayServer.get_name() != "headless":
			label.hide()
			await RenderingServer.frame_post_draw
			var hidden := root.get_texture().get_image()
			label.show()
			await RenderingServer.frame_post_draw
			var shown := root.get_texture().get_image()
			var bounds := Rect2i(label.get_global_rect().grow(5)).intersection(Rect2i(Vector2i.ZERO, shown.get_size()))
			var changed := 0
			for y in range(bounds.position.y, bounds.end.y):
				for x in range(bounds.position.x, bounds.end.x):
					if hidden.get_pixel(x, y) != shown.get_pixel(x, y): changed += 1
			check(changed == 0, "nenhum pixel do Zz atravessa o painel em " + place)
			# Controle positivo: o mesmo texto na frente precisa aparecer na comparação.
			var original_z := label.z_index
			label.z_index = sheet.z_index + 1
			await RenderingServer.frame_post_draw
			var exposed := root.get_texture().get_image()
			var visible_pixels := 0
			for y in range(bounds.position.y, bounds.end.y):
				for x in range(bounds.position.x, bounds.end.x):
					if hidden.get_pixel(x, y) != exposed.get_pixel(x, y): visible_pixels += 1
			check(visible_pixels > 0, "comparação detecta o texto se ele estivesse na frente em " + place)
			label.z_index = original_z
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/effects_layers")
			DirAccess.make_dir_recursive_absolute(folder)
			shown.save_png(folder.path_join("%s_%d.png" % [place, root.size.x]))
		label.free()
	main.queue_free()
	await process_frame
	print("EFFECTS LAYER TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
