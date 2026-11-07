extends SceneTree
## Fotos do Tiro, etapa 08: o varal da home (PhotoLine). Sem foto aberta não existe; 1 foto = 1 polaroide + 2 "+";
## 3 em destaque na ordem do motor; toque abre a carta certa sem virar carinho; não cobre nada nas 3 resoluções.

var failures := 0
var state: Node
var main: Control
var pet: Control
var viewer_script: GDScript


func _initialize() -> void:
	_run.call_deferred()
	create_timer(60.0).timeout.connect(func() -> void:
		print("PHOTO LINE TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Varal: " + message)


func frames(count: int = 4) -> void:
	for i in count: await process_frame


func line() -> Control:
	return pet.find_child("PhotoLine", true, false)


func polaroids() -> Array[Control]:
	var result: Array[Control] = []
	for child in line().get_children():
		if str(child.name).begins_with("PhotoLine_"): result.append(child)
	return result


func slots() -> Array[Control]:
	var result: Array[Control] = []
	for child in line().get_children():
		if str(child.name).begins_with("PhotoSlot_"): result.append(child)
	return result


func click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
		await frames(2)


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	# Os cartões de festa de coleção (etapa 10) saem pela fila modal: este teste só mede o varal e toques.
	for timer in main.find_children("*", "Timer", false, false):
		if is_equal_approx((timer as Timer).wait_time, 0.3): (timer as Timer).stop()
	pet = main.find_child("PetScreen", true, false)
	main.call("show_screen", &"pet")
	await frames()

	check(line() != null and not line().visible, "1: sem foto aberta não há varal")
	state.call("dev_seal_photo", "h_arrival")
	await frames()
	check(not line().visible, "1: carta fechada não abre o varal")

	state.call("dev_take_photo", "h_arrival", 1)
	await frames()
	check(line().visible and polaroids().is_empty() and slots().size() == 3, "1: com foto aberta e nada em destaque, três espaços")
	check(state.call("feature_photo", "h_arrival") == "", "1: destaca a primeira")
	await frames()
	check(polaroids().size() == 1 and slots().size() == 2, "1: uma polaroide e dois espaços")

	for id in ["f_bath", "f_taste"]:
		state.call("dev_take_photo", id, 4 if id == "f_bath" else 2)
		state.call("feature_photo", id)
	await frames()
	var names: Array[String] = []
	for holder in polaroids(): names.append(str(holder.get_meta("photo")))
	check(names == ["h_arrival", "f_bath", "f_taste"] and slots().is_empty(), "2: três polaroides na ordem do motor: " + str(names))

	# Posições: nada do que a home mostra pode ser coberto (e o toque do varal não vira carinho).
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		var others: Dictionary = {
			"NeedsPanel": main.find_child("NeedsPanel", true, false),
			"WishBubble": pet.find_child("WishBubble", true, false),
			"ManualButton": pet.find_child("ManualButton", true, false),
			"CareButton": pet.find_child("CareButton", true, false),
		}
		var head: Rect2 = pet.call("head_rect")
		for holder in polaroids():
			var rect := holder.get_global_rect()
			check(rect.size.x >= 72.0 and rect.size.x <= 84.0, "3: tamanho 72–84 em %s: %s" % [viewport, rect.size.x])
			check(rect.position.y >= 168.0 and root.get_visible_rect().encloses(rect), "3: abaixo do HUD e dentro da tela em " + str(viewport))
			check(not rect.intersects(head), "3: não cobre a cabeça em " + str(viewport))
			for key: String in others:
				var node: Control = others[key]
				if node != null and node.is_visible_in_tree():
					check(not rect.intersects(node.get_global_rect()), "3: não cobre %s em %s" % [key, viewport])
		var wish: Control = others["WishBubble"]
		if wish != null:
			var all := polaroids()
			check(all.back().get_global_rect().end.x <= wish.get_global_rect().position.x, "3: à esquerda do balão do desejo em " + str(viewport))
	root.size = Vector2i(360, 780)
	await frames()

	# Toque: abre a carta certa, sem iniciar o carinho no Tiro.
	var pets_before := int(state.get("progress").stat("pet"))
	var second := polaroids()[1]
	await click(second.get_global_rect().get_center())
	check(bool(viewer_script.call("is_open")), "2: tocar abre o CardViewer")
	check(viewer_script.get("current").get("photo_id") == "f_bath", "2: abre a carta certa")
	check(not bool(pet.get("_holding")), "5: o toque não inicia carinho")
	check(int(state.get("progress").stat("pet")) == pets_before, "5: o toque não conta carinho")
	viewer_script.get("current").call("close")
	await frames()

	# Trocar a versão mostrada atualiza a polaroide, sem mexer na ordem.
	state.call("dev_take_photo", "f_bath", 1)
	check(state.call("set_photo_variant", "f_bath", 1) == "", "4: troca para a versão 1")
	await frames()
	check(polaroids()[1].find_child("PhotoCard", true, false) != null, "4: polaroide continua montada")
	check(int(state.call("photo_shown_rarity", "f_bath")) == 1, "4: versão 1 é a mostrada")
	var art: Node = polaroids()[1].find_child("Illustration", true, false)
	if art != null: check(int(art.get_meta("level", -1)) == 1, "4: a polaroide mostra a versão escolhida")
	check(str(polaroids()[1].get_meta("photo")) == "f_bath", "4: ordem preservada")

	# Espaço vazio leva ao Álbum.
	state.call("unfeature_photo", "f_taste")
	await frames()
	check(slots().size() == 1, "2: tirar do varal abre um espaço")
	await click(slots()[0].get_global_rect().get_center())
	check(main.find_child("NotebookTab_album", true, false) != null, "2: espaço vazio abre o Álbum")
	await frames()
	main.find_child("PetNotebook", true, false).queue_free()

	# Passeio: o varal some.
	state.call("dev_take_photo", "f_dig", 1)
	state.get("walk_state").current = {"id": "meadow", "ready_at": state.call("now") + 600.0, "seed": 1}
	state.call("_changed")
	await frames()
	check(state.call("walking") == false or not line().visible, "6: some durante o passeio")
	state.get("walk_state").current = {}
	state.call("_changed")
	await frames()

	# Sono: o varal nunca cobre a cabeça (onde sobe o Zz).
	state.get("dog").sleeping = true
	state.call("_changed")
	await frames()
	check(not line().visible or not line().get_global_rect().intersects(pet.call("head_rect")), "6: dormindo não cobre o Zz")

	if failures == 0:
		print("PHOTO LINE TEST: PASS")
	quit(failures)
