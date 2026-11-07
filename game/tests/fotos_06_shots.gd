extends SceneTree
## Etapa 06: capturas nativas do álbum; dados descartáveis, auditoria de geometria e textos.
var state: Node
var main: Control
var sheet: Control
var folder := "fotos_06"
var failures := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.substr(6)
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: print("FAIL timeout"); quit(1))

func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)

func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: node.hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and intro.is_inside_tree(): intro.queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_photo_queue", [] as Array[String])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var node := main.find_child(hidden_name, true, false) as CanvasItem
		if node: node.hide()

func _grab(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_measure(label)
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + label + ".png")

func _measure(tag: String) -> void:
	var screen := root.get_visible_rect()
	var board := sheet.find_child("CodexBoard", true, false) as Control
	var scroll := sheet.find_child("CodexScroll", true, false) as Control
	if board != null:
		var r := board.get_global_rect()
		if r.position.y < 127.5 or r.end.y > screen.size.y - 103.5: _fail(tag + ": quadro sob HUD/abas")
	var detail := sheet.find_child("CodexDetail", true, false) as Control
	if detail != null:
		var r := detail.get_global_rect()
		if r.position.y < 127.5 or r.end.y > screen.size.y - 103.5: _fail(tag + ": pista sob HUD/abas")
	var greens := 0
	for child in sheet.find_children("*", "Control", true, false):
		var node := child as Control
		if not node.is_visible_in_tree(): continue
		var rect := node.get_global_rect()
		var in_scroll := scroll != null and scroll.is_ancestor_of(node)
		if in_scroll:
			if rect.size.x > 0 and (rect.position.x < scroll.get_global_rect().position.x - 1 or rect.end.x > scroll.get_global_rect().end.x + 1):
				_fail("%s: %s ultrapassa largura da rolagem" % [tag, node.name])
		elif node is Button and not screen.grow(1).encloses(rect):
			_fail("%s: %s fora da tela" % [tag, node.name])
		if node is Button:
			if rect.size.x < 43.5 or rect.size.y < 43.5: _fail("%s: alvo <44 %s" % [tag, node.name])
			if node.has_meta("wood_primary"): greens += 1
		if node is Label and not node.text.is_empty():
			if node.get_minimum_size().y > node.size.y + 1: _fail("%s: texto cortado %s" % [tag, node.name])
			if node.autowrap_mode == TextServer.AUTOWRAP_OFF and node.get_minimum_size().x > node.size.x + 1: _fail("%s: texto largo %s" % [tag, node.name])
		if node is NinePatchRect:
			var t := node.get_global_transform()
			if absf(t.x.length() / t.y.length() - 1) > 0.01: _fail(tag + ": NinePatch torto")
		if node is TextureRect and node.texture != null and node.stretch_mode == TextureRect.STRETCH_SCALE:
			var source: Vector2 = node.texture.get_size()
			if absf((rect.size.x / rect.size.y) / (source.x / source.y) - 1) > 0.01: _fail("%s: imagem torta %s" % [tag, node.name])
	if greens > 1: _fail(tag + ": mais de um botão verde")

func _open(section: String) -> void:
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.3).timeout
	load("res://scripts/ui/pet_notebook.gd").call("open", "album:" + section)
	await create_timer(0.6).timeout
	_hide_modals()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_unlock_everything()
	state._mark_all_seen()
	state.dev_reset_album()
	state.album.tutorial.done = true
	for entry: Dictionary in root.get_node("Database").album.photos:
		if str(entry.section) == "story": state.dev_take_photo(str(entry.id), 1 + (int(entry.get("order", 0)) % 4))
	# Níveis conhecidos para conferir brilho e seleção na grade.
	state.dev_take_photo("h_arrival", 4)
	state.set_photo_variant("h_arrival", 4)
	state.dev_take_photo("h_first_night", 3)
	state.set_photo_variant("h_first_night", 3)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.2).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	await _open("story")
	await _grab("01_historia_cheia")
	await create_timer(0.8).timeout
	await _grab("02_historia_brilho")
	var scroll := sheet.find_child("CodexScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 340
	await process_frame
	await _grab("03_historia_rolagem")
	await _open("firsts")
	await _grab("04_faltantes")
	await _open("story")
	await _grab("05_historia_rolagem_restaurada")
	state.dev_seal_photo("f_bath")
	_hide_modals()
	await _open("firsts")
	await _grab("06_para_abrir")
	await _open("tricks")
	await _grab("07_secretas")
	root.get_node("Events").sheet_requested.emit("Pista", load("res://scripts/ui/album_view.gd").call("secret_detail", "s_foam_ghost"))
	await create_timer(0.6).timeout
	await _grab("08_pista_madeira")
	# A etapa 07 preencherá pistas por contador; fixture visual local cobre a faixa sem editar o catálogo.
	var counter_photo: Dictionary = root.get_node("Database").photo("a_bloblo_helper")
	var saved := counter_photo.duplicate(true)
	counter_photo.hint = "Faça encomendas para o Bloblo."
	state.progress.stats["order:snacks"] = 18
	await _open("friends")
	await _grab("09_quase_la_fixture")
	counter_photo.clear()
	counter_photo.merge(saved)
	print("FOTOS 06 SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
