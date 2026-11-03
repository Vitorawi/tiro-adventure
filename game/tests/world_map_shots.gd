extends SceneTree
## Capturas e MEDIDAS do seletor de mundos "madeira ilustrada". NÃO é teste da suíte, mas imprime FAIL e sai com
## código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/world_map_shots.gd
## PNGs em build/screenshots/world_map/world_map_<largura>x<altura>_<caso>.png. Não grava o save pessoal.
## Casos: a_inicio (só a Casa liberada), b_meio (vários avisos), c_tudo (tudo liberado, atual = Sítio).

var state: Node
var main: Control
var worlds: Control
var selector: Control
var folder := "res://../build/screenshots/world_map/"
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(600).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


func _frames(count: int = 6) -> void:
	for i in count:
		await process_frame


func _fresh() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	await _frames()
	_hide_modals()


func _open(current: String) -> void:
	_hide_modals()
	worlds.call("enter", current, "") if worlds.get("current_world") != current else null
	await _frames(10)
	_hide_modals()
	worlds.call("show_map")
	await _frames(10)
	_hide_modals()


func _shot(case_name: String) -> void:
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "world_map_%dx%d_%s.png" % [image.get_width(), image.get_height(), case_name])
	_measure(case_name)


func _measure(tag: String) -> void:
	var screen := root.get_visible_rect().size
	var panel := selector.find_child("WorldListPanel", true, false) as Control
	var list := selector.find_child("WorldList", true, false) as Control
	var pr := panel.get_global_rect()
	var tab_top := screen.y
	for node_name: String in ["TabBar", "TabBarArt"]:
		var bar := main.find_child(node_name, true, false) as Control
		if bar:
			tab_top = minf(tab_top, bar.get_global_rect().position.y)
	_check(pr.position.x >= 0.0 and pr.end.x <= screen.x, "[%s] folha passa da tela em x %s" % [tag, pr])
	_check(pr.position.y >= 127.5, "[%s] folha sob o HUD (topo %.1f)" % [tag, pr.position.y])
	_check(pr.end.y <= tab_top + 0.5, "[%s] folha sob a barra de abas (%.1f > %.1f)" % [tag, pr.end.y, tab_top])
	_check(_near(pr.get_center().x, screen.x / 2.0, 1.0), "[%s] folha descentralizada" % tag)
	var creme_l := pr.position.x + 28.0
	var creme_r := pr.end.x - 26.0
	var cards: Array[Control] = []
	for child in list.get_children():
		cards.append(child as Control)
	_check(cards.size() == 5, "[%s] esperava cinco cartões" % tag)
	var first := cards[0]
	var fr := first.get_global_rect()
	for i in 4:
		var r := cards[i].get_global_rect()
		_check(_near(r.size.x, fr.size.x, 0.5) and _near(r.size.y, fr.size.y, 0.5), "[%s] cartão %s de tamanho diferente (%s x %s)" % [tag, cards[i].name, r.size, fr.size])
		_check(r.size.x >= 43.5 and r.size.y >= 43.5, "[%s] alvo de toque pequeno em %s" % [tag, cards[i].name])
	var r1 := cards[1].get_global_rect()
	var r2 := cards[2].get_global_rect()
	var r3 := cards[3].get_global_rect()
	_check(_near(fr.position.x, r2.position.x, 0.5) and _near(r1.position.x, r3.position.x, 0.5), "[%s] colunas desalinhadas" % tag)
	_check(_near(fr.position.y, r1.position.y, 0.5) and _near(r2.position.y, r3.position.y, 0.5), "[%s] linhas desalinhadas" % tag)
	_check(_near(fr.position.x - creme_l, creme_r - r1.end.x, 0.5), "[%s] colunas assimétricas no creme (%.2f x %.2f)" % [tag, fr.position.x - creme_l, creme_r - r1.end.x])
	_check(_near(r1.position.x - fr.end.x, r2.position.y - fr.end.y, 0.5), "[%s] vãos entre cartões diferentes (%.1f x %.1f)" % [tag, r1.position.x - fr.end.x, r2.position.y - fr.end.y])
	var wide := cards[4].get_global_rect()
	_check(_near(wide.size.x, fr.size.x * 2.0 + (r1.position.x - fr.end.x), 0.5), "[%s] cartão largo não cobre as duas colunas (%.1f)" % [tag, wide.size.x])
	_check(_near(wide.position.x, fr.position.x, 0.5), "[%s] cartão largo desalinhado" % tag)
	_check(_near(wide.position.y - r2.end.y, r1.position.x - fr.end.x, 0.5), "[%s] vão do cartão largo diferente" % tag)
	_check(pr.grow(0.5).encloses(wide), "[%s] cartão largo fora da folha" % tag)
	# Bordas do creme: a última linha respira o mesmo que as laterais (PAD).
	_check(creme_r - wide.end.x >= 6.0 - 0.6 and wide.position.x - creme_l >= 6.0 - 0.6, "[%s] cartão encosta na moldura" % tag)
	var plate_offset := Vector2.ZERO
	var plate_size := Vector2.ZERO
	for i in cards.size():
		var card := cards[i]
		var cr := card.get_global_rect()
		_check(pr.grow(0.5).encloses(cr), "[%s] %s fora da folha" % [tag, card.name])
		var photo := card.find_child("WorldPhoto", true, false) as TextureRect
		var photo_rect := photo.get_global_rect()
		var texture_ratio := float(photo.texture.get_height()) / float(photo.texture.get_width())
		_check(_near(photo_rect.size.y / photo_rect.size.x, texture_ratio, 0.003), "[%s] foto de %s distorcida (%.4f != %.4f)" % [tag, card.name, photo_rect.size.y / photo_rect.size.x, texture_ratio])
		_check(_near(photo_rect.size.x, cr.size.x, 0.5), "[%s] foto de %s não ocupa a largura do cartão" % [tag, card.name])
		# Razão desenhada x razão do PNG: nenhuma ilustração pode ser esticada (tolerância 1%).
		var source_ratio := (616.0 / 582.0) if i < 4 else (1191.0 / 445.0)  # moldura do Sítio / _1 da IUREF
		var photo_texture_ratio := float(photo.texture.get_width()) / float(photo.texture.get_height())
		_check(absf(photo_texture_ratio / source_ratio - 1.0) <= 0.01, "[%s] PNG de %s com razão %.4f longe da fonte %.4f" % [tag, card.name, photo_texture_ratio, source_ratio])
		_check(absf(photo_rect.size.x / photo_rect.size.y / photo_texture_ratio - 1.0) <= 0.01, "[%s] foto de %s desenhada com razão %.4f != do PNG %.4f" % [tag, card.name, photo_rect.size.x / photo_rect.size.y, photo_texture_ratio])
		var plate := card.find_child("WorldPlate", true, false) as Control
		var plate_rect := plate.get_global_rect()
		_check(_near(plate_rect.get_center().x, cr.get_center().x, 0.6), "[%s] plaquinha de %s descentralizada" % [tag, card.name])
		_check(cr.grow(0.5).encloses(plate_rect), "[%s] plaquinha de %s fora do cartão" % [tag, card.name])
		_check(_near(plate_rect.end.y, cr.end.y, 0.6), "[%s] plaquinha de %s não encosta no pé do cartão" % [tag, card.name])
		_check(absf(plate_rect.size.x / plate_rect.size.y / (600.0 / 213.0) - 1.0) <= 0.01, "[%s] plaquinha de %s distorcida" % [tag, card.name])
		if i == 0:
			plate_size = plate_rect.size
			plate_offset = plate_rect.position - cr.position
		else:
			_check(_near(plate_rect.size.x, plate_size.x, 0.5) and _near(plate_rect.size.y, plate_size.y, 0.5), "[%s] plaquinhas de tamanhos diferentes" % tag)
			if i < 4:
				_check(_near((plate_rect.position - cr.position).y, plate_offset.y, 0.5), "[%s] plaquinhas desalinhadas na vertical" % tag)
		var name_label := card.find_child("WorldName", true, false) as Label
		var name_rect := name_label.get_global_rect()
		_check(plate_rect.grow(0.5).encloses(name_rect), "[%s] nome de %s fora da plaquinha" % [tag, card.name])
		_check(_near(name_rect.get_center().x, plate_rect.get_center().x, 0.6), "[%s] nome de %s descentralizado" % [tag, card.name])
		var font := name_label.get_theme_font("font")
		var text_w := font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.get_theme_font_size("font_size")).x
		_check(text_w <= name_rect.size.x + 0.5, "[%s] nome de %s não cabe (%.1f > %.1f)" % [tag, card.name, text_w, name_rect.size.x])
		var lock := card.find_child("WorldLock", true, false) as Control
		if lock.visible:
			var hint := card.find_child("WorldHint", true, false) as Control
			_check(photo_rect.grow(0.5).encloses(lock.get_global_rect()), "[%s] cadeado de %s fora da foto" % [tag, card.name])
			_check(photo_rect.grow(0.5).encloses(hint.get_global_rect()), "[%s] dica de %s fora da foto (%s)" % [tag, card.name, hint.get_global_rect()])
			_check(lock.get_global_rect().end.y <= hint.get_global_rect().position.y, "[%s] cadeado sobre a dica em %s" % [tag, card.name])
		for status in card.find_child("WorldStatusRows", true, false).get_children():
			var holder := status as Control
			var hr := holder.get_global_rect()
			_check(photo_rect.grow(0.5).encloses(hr), "[%s] disco %s de %s fora da foto" % [tag, holder.name, card.name])
			_check(pr.grow(0.5).encloses(hr), "[%s] disco %s fora da moldura" % [tag, holder.name])
			_check(hr.size.x >= 33.5 and hr.size.x <= 44.5, "[%s] disco %s com %.1f px" % [tag, holder.name, hr.size.x])
			_check(_near(hr.size.y / hr.size.x, 137.0 / 132.0, 0.01), "[%s] disco %s distorcido" % [tag, holder.name])
			var disc_art := holder.get_node("Disc") as TextureRect
			_check(absf(hr.size.x / hr.size.y / (float(disc_art.texture.get_width()) / disc_art.texture.get_height()) - 1.0) <= 0.01, "[%s] disco %s com razão diferente do PNG" % [tag, holder.name])
			var count := holder.find_child("Count", true, false) as Control
			if count:
				_check(photo_rect.grow(0.5).encloses(count.get_global_rect()), "[%s] número de %s fora da foto" % [tag, holder.name])
				_check(_near(count.get_global_rect().get_center().x, hr.get_center().x, 0.6), "[%s] número de %s descentralizado" % [tag, holder.name])
				var label := count.find_child("*", true, false) as Label
				if label:
					var count_font := label.get_theme_font("font")
					_check(count_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.get_global_rect().size.x + 0.5, "[%s] número de %s não cabe" % [tag, holder.name])
			var badge := holder.find_child("NewBadge", true, false) as Control
			if badge:
				_check(photo_rect.grow(0.5).encloses(badge.get_global_rect()), "[%s] selo ! de %s fora da foto" % [tag, card.name])
		var here := card.find_child("CurrentWorld", true, false) as Control
		if here.visible:
			_check(photo_rect.grow(0.5).encloses(here.get_global_rect()), "[%s] Aqui de %s fora da foto" % [tag, card.name])
	# Placa do título e X de madeira: dentro da folha, centrada, alvo 44.
	var plate := selector.find_child("TitlePlate", true, false) as Control
	var title := selector.find_child("SelectorTitle", true, false) as Label
	var close := selector.find_child("CloseSelector", true, false) as Control
	_check(_near(plate.get_global_rect().get_center().x, pr.get_center().x, 0.6), "[%s] placa do título descentralizada" % tag)
	_check(absf(plate.get_global_rect().size.x / plate.get_global_rect().size.y / (float((plate as TextureRect).texture.get_width()) / (plate as TextureRect).texture.get_height()) - 1.0) <= 0.01, "[%s] placa do título com razão diferente do PNG" % tag)
	_check(pr.grow(0.5).encloses(plate.get_global_rect()), "[%s] placa do título fora da folha" % tag)
	_check(plate.get_global_rect().grow(0.5).encloses(title.get_global_rect()), "[%s] título fora da placa" % tag)
	var title_w := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	_check(title_w <= title.get_global_rect().size.x + 0.5, "[%s] título não cabe (%.1f > %.1f)" % [tag, title_w, title.get_global_rect().size.x])
	_check(close.size.x >= 43.5 and close.size.y >= 43.5, "[%s] X menor que 44" % tag)
	_check(pr.grow(0.5).encloses(close.get_global_rect()), "[%s] X fora da folha" % tag)
	_check(not close.get_global_rect().intersects(plate.get_global_rect()), "[%s] X sobre a placa do título" % tag)
	_check(first.get_global_rect().position.y >= plate.get_global_rect().end.y - 0.5, "[%s] cartões sob a placa do título" % tag)
	print("  [%s] folha %s, cartão %.1f x %.1f" % [tag, pr, fr.size.x, fr.size.y])


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			root.size = Vector2i(int(parts[0]), int(parts[1]))
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "mapa_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	worlds = main.find_child("WorldsScreen", true, false)
	selector = worlds.get_node("%MapView")
	main.call("_on_tab_pressed", &"map")
	await _frames()

	# a) começo do jogo: só a Casa liberada.
	worlds.call("show_map")
	await _frames(10)
	_hide_modals()
	await _shot("a_inicio")
	selector.call("dismiss")

	# b) meio do jogo: capítulo 4 (Natureza ainda fechada) com avisos de vários tipos.
	await _fresh()
	state.call("dev_jump_to_chapter", 4)
	state.call("_mark_all_seen")
	await _frames()
	_hide_modals()
	var now: float = state.call("now")
	# Sítio: dois canteiros prontos e missão pronta (vovó) — as colheitas viram "coletas".
	for i in 2:
		state.get("plots")[i] = {"crop": "carrot", "planted_at": now - 100, "ready_at": now - 1}
	state.get("progress").claimed_quests.erase("welcome")
	state.get("progress").stats["talk:lais"] = 1
	# Vila: achado do Tiro; Praça: passeio em andamento (sem nada pronto, o cronômetro aparece).
	state.get("finds").worlds["village"] = {"pending": 1, "next_at": now + 99999, "seed": 1, "spot": 0, "dug": 0}
	state.get("walk_state").current = {"id": "park_loop", "ready_at": now + 900}
	root.get_node("Events").emit_signal("state_changed")
	await _frames()
	var places: Script = load("res://scripts/ui/places.gd")
	for id: String in root.get_node("Database").get("worlds"):
		print("  resumo b ", id, " ", places.call("world_summary", id))
	worlds.call("show_map")
	await _frames(10)
	_hide_modals()
	await _shot("b_meio")
	selector.call("dismiss")

	# c) tudo liberado, atual = Sítio.
	await _fresh()
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	await _frames()
	_hide_modals()
	worlds.call("enter", "farm", "")
	await _frames(12)
	_hide_modals()
	worlds.call("show_map")
	await _frames(10)
	_hide_modals()
	await _shot("c_tudo")
	selector.call("dismiss")
	print("WORLD MAP SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
