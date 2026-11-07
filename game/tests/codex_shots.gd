extends SceneTree
## Capturas e MEDIDAS do Caderninho "madeira ilustrada". NÃO é teste da suíte, mas imprime FAIL e sai com código 1 se a
## geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/codex_shots.gd -- --out=codex
## PNGs em build/screenshots/<out>/codex_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/codex/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(900).timeout.connect(func() -> void: quit(1))


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


func _unlock() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	var inventory: Object = state.get("inventory")
	for id: String in ["carrot", "egg", "plank", "wheat", "carrot_snack", "milk", "stone", "apple"]:
		inventory.call("add", id, 12)
	for photo: String in ["h_arrival", "f_bath", "f_dig"]:
		state.call("dev_take_photo", photo)
	state.get("progress").stats["find_item:stick"] = 1
	var tastes: Dictionary = state.get("growth").tastes  # as reações do Paladar: feliz, médio, triste e a favorita
	tastes["dog_food"] = "liked"
	tastes["carrot_snack"] = "odd"
	tastes["carrot"] = "grimace"
	tastes[str(state.call("favorite_food"))] = "loved"
	await create_timer(1.0).timeout
	_hide_modals()


func _close() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	for i in 20:
		await process_frame


func _all(node: Node, kind: String) -> Array[Node]:
	return node.find_children("*", kind, true, false)


func _text_fits(label: Label, tag: String) -> void:
	if not label.is_visible_in_tree() or label.text == "":
		return
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var rect := label.get_global_rect()
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_check(width <= rect.size.x + 0.5, "[%s] %s passa da sua caixa (%.1f > %.1f): %s" % [tag, label.name, width, rect.size.x, label.text])
	else:
		var lines := label.get_line_count()
		var allowed := label.max_lines_visible if label.max_lines_visible > 0 else 99
		_check(lines <= allowed, "[%s] %s cortado: %d linhas (máx %d): %s" % [tag, label.name, lines, allowed, label.text])


func _open(target: String, shot_name: String) -> void:
	root.get_node("Events").sheet_requested.emit("Caderninho", (load("res://scripts/ui/pet_notebook.gd") as Script).call("panel", target))
	await create_timer(1.0).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "codex_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name)


func _measure(tag: String) -> void:
	var screen := root.get_visible_rect().size
	var board := sheet.find_child("CodexBoard", true, false) as Control
	if board == null:
		_check(false, "[%s] sem CodexBoard" % tag)
		return
	var br := board.get_global_rect()
	_check(br.position.x >= -0.5 and br.end.x <= screen.x + 0.5, "[%s] quadro fora da tela %s" % [tag, br])
	_check(br.position.y >= 127.5, "[%s] folha passa do HUD (topo %.1f)" % [tag, br.position.y])
	_check(br.end.y <= screen.y + 0.5, "[%s] folha passa da base da tela (%.1f > %.1f)" % [tag, br.end.y, screen.y])
	_check(br.end.y <= screen.y - 104.0 + 0.5, "[%s] moldura cobre a barra de abas do jogo (fim %.1f, barra em %.1f)" % [tag, br.end.y, screen.y - 104.0])
	var wood: Rect2 = board.get_meta("wood")
	var wood_global := Rect2(br.position + wood.position, wood.size)
	_check(wood_global.position.x >= 0.0 and wood_global.end.x <= screen.x, "[%s] madeira fora da tela" % tag)
	var art := board.find_child("Art", false, false) as Control
	_check(art.get_global_rect().position.x + 6.0 >= 0.0, "[%s] folhas da moldura saem da tela" % tag)
	# Placa centrada na madeira; título centrado na placa.
	var plate := board.find_child("CodexPlate", false, false) as Control
	_check(_near(plate.get_global_rect().get_center().x, wood_global.get_center().x, 1.0), "[%s] placa fora do centro da madeira" % tag)
	var title := board.find_child("CodexTitle", false, false) as Label
	_check(_near(title.get_global_rect().get_center().x, plate.get_global_rect().get_center().x, 1.0), "[%s] título fora do centro da placa" % tag)
	_text_fits(title, tag)
	_check(_near(plate.size.x / plate.size.y, plate.texture.get_width() / float(plate.texture.get_height()), 0.02 * 2.9), "[%s] placa distorcida" % tag)
	var close := board.find_child("CloseButton", false, false) as Control
	_check(not plate.get_global_rect().intersects(close.get_global_rect()), "[%s] placa cobre o X" % tag)
	_check(close.size.x >= 44.0 and close.size.y >= 44.0, "[%s] X menor que 44" % tag)
	_check(br.grow(0.5).encloses(close.get_global_rect()), "[%s] X fora do quadro" % tag)
	_check(_near(close.get_global_rect().end.x, wood_global.end.x + 2.0, 1.0), "[%s] X fora do canto da madeira" % tag)
	# Abas laterais: iguais, alinhadas, espaçadas por igual, na tela e com a escolhida mais saliente.
	var tabs: Array[Control] = []
	for child in board.get_children():
		if child.name.begins_with("NotebookTab_") and child is Button and child.has_meta("picked") and (child as Control).position.x > wood.position.x + wood.size.x - 40.0:
			tabs.append(child as Control)
	tabs.sort_custom(func(a: Control, b: Control) -> bool: return a.position.y < b.position.y)
	_check(tabs.size() >= 2, "[%s] abas laterais faltando (%d)" % [tag, tabs.size()])
	var picked_count := 0
	for index in tabs.size():
		var tab := tabs[index]
		var rect := tab.get_global_rect()
		_check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "[%s] aba %s menor que 44 (%s)" % [tag, tab.name, rect.size])
		_check(rect.size.is_equal_approx(tabs[0].get_global_rect().size), "[%s] aba %s de tamanho diferente" % [tag, tab.name])
		_check(rect.end.x <= screen.x - 4.0 + 0.5 and rect.position.x >= 0.0, "[%s] aba %s a menos de 4 px da borda (%.1f)" % [tag, tab.name, rect.end.x])
		if index > 0:
			_check(_near(tab.position.y - tabs[index - 1].position.y, tabs[1].position.y - tabs[0].position.y, 0.5), "[%s] abas com espaçamento desigual" % tag)
		var picked: bool = tab.get_meta("picked")
		picked_count += 1 if picked else 0
		_check(tab.position.x < wood.position.x + wood.size.x - 0.0, "[%s] aba dentro da madeira?" % tag)
		for other in tabs:
			if other != tab and not bool(other.get_meta("picked")) and picked:
				_check(rect.end.x > other.get_global_rect().end.x - 0.5 or _near(rect.end.x, other.get_global_rect().end.x + 10.0, 0.6), "[%s] aba escolhida não sobressai" % tag)
		for label: Node in tab.find_children("Title", "Label", true, false):
			_text_fits(label as Label, tag)
			var lab := label as Label
			var visible_from := wood_global.end.x + 1.0
			var tw: float = lab.get_theme_font("font").get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lab.get_theme_font_size("font_size")).x
			_check(lab.get_global_rect().get_center().x - tw / 2.0 >= visible_from - 0.5 and lab.get_global_rect().get_center().x + tw / 2.0 <= rect.end.x - 6.0, "[%s] nome da aba %s cortado/fora da parte visível" % [tag, lab.text])
		var icon := tab.find_child("Icon", true, false) as TextureRect
		_check(_near(icon.size.x / icon.size.y, 1.0, 0.01), "[%s] ícone da aba distorcido" % tag)
	_check(picked_count == 1, "[%s] deveria haver uma aba escolhida (%d)" % [tag, picked_count])
	# Filtros: abinhas com nome, todas visíveis sem rolar, mesma altura, dentro do miolo, cada linha centralizada.
	var filters := board.find_child("CodexFilters", true, false) as Control
	if filters != null:
		var area := filters.get_global_rect()
		var first: Rect2 = Rect2()
		var rows := {}
		for index in filters.get_child_count():
			var option := filters.get_child(index) as Control
			var r := option.get_global_rect()
			if index == 0:
				first = r
			_check(_near(r.size.y, first.size.y, 0.5) and r.size.y >= 44.0, "[%s] filtro %s com altura diferente ou < 44 (%.0f)" % [tag, option.name, r.size.y])
			var caption := option.find_child("Caption", true, false) as Label
			_check(caption != null and caption.get_line_count() == 1 and caption.get_theme_font("font").get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption.get_theme_font_size("font_size")).x <= r.size.x - 8.0, "[%s] nome do filtro %s cortado" % [tag, option.name])
			_check(area.grow(0.5).encloses(r) and wood_global.encloses(r), "[%s] filtro %s fora do miolo" % [tag, option.name])
			var key := int(roundf(r.position.y))
			if not rows.has(key):
				rows[key] = Vector2(r.position.x, r.end.x)
			rows[key] = Vector2(minf(rows[key].x, r.position.x), maxf(rows[key].y, r.end.x))
		_check(rows.size() <= 3, "[%s] filtros em mais de três linhas" % tag)
		for key: int in rows:
			var span: Vector2 = rows[key]
			_check(_near(span.x - area.position.x, area.end.x - span.y, 2.0), "[%s] filtros descentralizados (%.1f x %.1f)" % [tag, span.x - area.position.x, area.end.x - span.y])
	# Grades: quadradinhos iguais, dentro da área, simétricos.
	var scroll := board.find_child("CodexScroll", true, false) as Control
	var scroll_rect := scroll.get_global_rect()
	_check(scroll_rect.position.y >= br.position.y and scroll_rect.end.y <= br.end.y, "[%s] área da grade fora do quadro" % tag)
	_check(wood_global.encloses(scroll_rect), "[%s] grade passa da madeira" % tag)
	var grids := board.find_children("CodexTiles", "GridContainer", true, false)
	for grid_node: Node in grids:
		var grid := grid_node as GridContainer
		var reference := (grid.get_child(0) as Control).size
		var cols := grid.columns
		var min_x := 99999.0
		var max_x := -99999.0
		for tile_node: Node in grid.get_children():
			var tile := tile_node as Control
			_check(tile.size.is_equal_approx(reference), "[%s] quadradinho %s de tamanho diferente (%s x %s)" % [tag, tile.name, tile.size, reference])
			_check(tile.size.x >= 44.0, "[%s] quadradinho %s menor que 44" % [tag, tile.name])
			var picture := tile.find_child("Picture", false, false) as TextureRect
			if picture != null and picture.texture.get_width() <= 32:
				_check(_near(picture.size.x / picture.texture.get_width(), roundf(picture.size.x / picture.texture.get_width()), 0.01), "[%s] ícone pixel de %s em escala não inteira" % [tag, tile.name])
			if picture != null:
				_check(_near(picture.size.x / picture.size.y, picture.texture.get_width() / float(picture.texture.get_height()), 0.05) or picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "[%s] ícone distorcido em %s" % [tag, tile.name])
			for label: Node in tile.find_children("*", "Label", true, false):
				_text_fits(label as Label, tag)
			var global := tile.get_global_rect()
			min_x = minf(min_x, global.position.x)
			max_x = maxf(max_x, global.end.x)
		if grid.get_child_count() >= cols:
			var left_gap := min_x - (wood_global.position.x + 14.3)
			var right_gap := (wood_global.end.x - 14.0) - max_x
			_check(_near(left_gap, right_gap, 1.5), "[%s] grade descentralizada (%.1f x %.1f)" % [tag, left_gap, right_gap])
		var rows: Array = []
		for tile_node: Node in grid.get_children():
			var y: float = (tile_node as Control).position.y
			if not y in rows:
				rows.append(y)
		print("[%s] grade %d colunas, %d quadradinhos %s" % [tag, cols, grid.get_child_count(), reference])
	for label: Node in _all(board, "Label"):
		if label.name in ["BlockTitle", "BlockCount", "CodexLine", "CodexEmpty", "Quantity", "Caption"]:
			_text_fits(label as Label, tag)
	var foot := board.find_child("CodexFoot", true, false) as Control
	if foot != null:
		_check(foot.size.y >= 44.0, "[%s] botão do rodapé menor que 44" % tag)
		_check(_near(foot.get_global_rect().get_center().x, wood_global.get_center().x - 0.0, 1.5), "[%s] rodapé descentralizado" % tag)
		_check(wood_global.encloses(foot.get_global_rect()), "[%s] rodapé fora da madeira" % tag)
	print("[%s] %dx%d quadro %s" % [tag, screen.x, screen.y, br])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "caderninho_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	await _unlock()
	var cases := [
		["resources", "a_recursos"], ["resources:crop", "b_colheitas"], ["resources:material", "c_materiais"], ["resources:keepsake", "d_tiro"],
		["stations", "e_estacoes"], ["stations:crops", "f_plantas"], ["stations:nature", "g_natureza"],
		["growth", "h_pilares"], ["growth:tastes", "i_paladar"], ["growth:diary", "j_diario"],
		["album", "k_album"], ["album:firsts", "l_primeiras"],
		["collection", "m_roupas"], ["collection:finds", "n_achados"], ["collection:friends", "o_amigos"],
		["tricks", "p_truques"],
	]
	for entry: Array in cases:
		await _open(str(entry[0]), str(entry[1]))
		await _close()
	state.call("dev_set_phase", "explorer")
	await create_timer(0.5).timeout
	await _open("growth:pillars", "h2_pilares_fase")
	await _close()
	# Detalhes enxutos em madeira.
	var sections: Script = load("res://scripts/ui/codex_sections.gd")
	for detail: Array in [["station_detail", "stove", "q_detalhe_estacao"], ["crop_detail", "carrot", "r_detalhe_planta"], ["route_detail", "woodcutting", "s_detalhe_rota"], ["pillar_detail", "brave", "t_detalhe_pilar"]]:
		root.get_node("Events").sheet_requested.emit(str(detail[1]), sections.call(detail[0], detail[1]))
		await create_timer(1.0).timeout
		_hide_modals()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		image.save_png(ProjectSettings.globalize_path(folder) + "codex_%dx%d_%s.png" % [image.get_width(), image.get_height(), detail[2]])
		var screen := root.get_visible_rect().size
		for node in sheet.find_children("*", "Button", true, false):
			var button := node as Button
			if button.is_visible_in_tree() and button.name != "CloseButton":
				_check(Rect2(Vector2.ZERO, screen).encloses(button.get_global_rect()), "[%s] botão %s fora da tela %s" % [detail[2], button.name, button.get_global_rect()])
				_check(button.size.y >= 44.0 or button.name.begins_with("Made_"), "[%s] botão %s menor que 44" % [detail[2], button.name])
		await _close()
	print("CODEX SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
