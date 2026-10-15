extends SceneTree
## Etapa 02 da interface nova: alturas do painel (automática, meia, alta), fechar na hora e arrastando,
## título único nas estações e as peças novas (bolinhas e linhas de lista).
## As classes de interface usam o autoload Database: por isso são carregadas só em tempo de execução.

var failures: int = 0
var state: Node
var sheet: Control
var sheet_builder: GDScript
var ui_kit: GDScript
var usable: float = 0.0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Sheet: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	sheet_builder = load("res://scripts/ui/sheet_builder.gd")
	ui_kit = load("res://scripts/ui/ui_kit.gd")
	sheet = (load("res://scenes/ui/sheet/sheet.tscn") as PackedScene).instantiate()
	root.add_child(sheet)
	await process_frame
	usable = sheet.size.y
	check(usable > 0.0, "o painel tem altura útil")
	await _heights()
	await _closing()
	await _dragging()
	await _stations_title()
	await _stove_rows()
	await _pieces()
	print("SHEET TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _open(title: String, content: Control) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	for i in 4:
		await process_frame
	await create_timer(0.35).timeout  # deixa terminar o tween de altura (0,18 s) e a animação de abrir


func _panel_height() -> float:
	return (sheet.get_node("%Panel") as Control).size.y


func _lines(count: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	for i in count:
		var line := Label.new()
		line.text = "Linha %d" % i
		line.custom_minimum_size = Vector2(0, 30)
		box.add_child(line)
	return box


func _heights() -> void:
	await _open("Pequeno", _lines(1))
	var small := _panel_height()
	check(small <= usable * 0.55 + 1.0, "conteúdo pequeno cabe em até 55%% da tela (%d de %d)" % [small, usable])
	check(small >= usable * 0.30 - 1.0, "altura mínima de 30%")
	check(sheet.call("is_open"), "painel aberto")
	await _open("Longo", _lines(30))
	check(absf(_panel_height() - usable * 0.88) <= 1.0, "30 linhas: altura alta de 88%% (%d)" % _panel_height())
	var tall_small := _lines(1)
	tall_small.set_meta("sheet_size", "tall")
	await _open("Alto", tall_small)
	check(absf(_panel_height() - usable * 0.88) <= 1.0, "meta tall: 88%")
	var half := _lines(30)
	half.set_meta("sheet_size", "half")
	await _open("Meio", half)
	check(absf(_panel_height() - usable * 0.55) <= 1.0, "meta half: 55%")
	# Trocar o conteúdo com o painel aberto: a altura acompanha (com tween de 0,18 s).
	await _open("Pequeno de novo", _lines(1))
	await create_timer(0.4).timeout
	check(_panel_height() <= usable * 0.55 + 1.0, "ao trocar por conteúdo pequeno o painel encolhe (%d)" % _panel_height())


func _closing() -> void:
	await _open("Fechar", _lines(2))
	root.get_node("Events").emit_signal("sheet_close_requested")
	check(not sheet.call("is_open"), "sheet_close_requested fecha no mesmo quadro")
	check((sheet.get_node("%ContentHolder") as Control).get_child_count() == 0, "conteúdo some na hora")
	await create_timer(0.5).timeout
	check(not sheet.visible, "depois de deslizar o painel fica escondido")
	# Reabrir logo depois de fechar funciona.
	await _open("Reaberto", _lines(2))
	check(sheet.visible and sheet.call("is_open"), "reabre")


func _mouse_button(y: float, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = Vector2(180, y)
	event.global_position = Vector2(180, y)
	return event


func _mouse_move(y: float) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(180, y)
	event.global_position = Vector2(180, y)
	return event


func _dragging() -> void:
	# Arrasto curto: volta ao lugar e o painel continua aberto.
	await _open("Arrastar", _lines(2))
	var start := usable - _panel_height() + 10.0
	sheet.call("_drag_input", _mouse_button(start, true))
	sheet.call("_drag_input", _mouse_move(start + 10.0))
	sheet.call("_drag_input", _mouse_button(start + 10.0, false))
	await create_timer(0.5).timeout
	check(sheet.call("is_open") and sheet.visible, "arrasto curto não fecha")
	check(absf(_panel_height() - float(sheet.call("panel_height"))) <= 1.0, "arrasto curto volta ao lugar")
	# Arrasto longo (mais de 25% da altura): fecha.
	var panel_h: float = sheet.call("panel_height")
	sheet.call("_drag_input", _mouse_button(start, true))
	sheet.call("_drag_input", _mouse_move(start + panel_h * 0.2))
	sheet.call("_drag_input", _mouse_move(start + panel_h * 0.4))
	sheet.call("_drag_input", _mouse_button(start + panel_h * 0.4, false))
	check(not sheet.call("is_open"), "arrastar mais de 25% da altura fecha")
	await create_timer(0.5).timeout
	check(not sheet.visible, "painel arrastado some depois de deslizar")
	# Arrastar para cima num painel automático: vira alto.
	await _open("Subir", _lines(2))
	check(_panel_height() < usable * 0.88 - 5.0, "painel pequeno começa baixo")
	start = usable - _panel_height() + 10.0
	sheet.call("_drag_input", _mouse_button(start, true))
	sheet.call("_drag_input", _mouse_move(start - 120.0))
	sheet.call("_drag_input", _mouse_button(start - 120.0, false))
	await create_timer(0.5).timeout
	check(absf(_panel_height() - usable * 0.88) <= 1.5, "arrastar para cima vira alto (%d)" % _panel_height())
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _stations_title() -> void:
	# Num jogo novo o moinho (capítulo 5) ainda não existe: só a bancada aparece e o título do painel basta.
	var panel: Control = sheet_builder.call("stations_view", PackedStringArray(["workbench", "mill"]))
	root.add_child(panel)
	await process_frame
	await process_frame
	var titles := 0
	for node: Node in panel.find_children("*", "Label", true, false):
		if (node as Label).theme_type_variation == &"TitleLabel":
			titles += 1
	check(titles == 0, "uma só estação visível: sem título repetido")
	panel.queue_free()
	state.call("dev_unlock_everything")
	var both: Control = sheet_builder.call("stations_view", PackedStringArray(["workbench", "mill"]))
	root.add_child(both)
	await process_frame
	await process_frame
	titles = 0
	for node: Node in both.find_children("*", "Label", true, false):
		if (node as Label).theme_type_variation == &"TitleLabel":
			titles += 1
	check(titles == 2, "duas estações visíveis: um título para cada (%d)" % titles)
	both.queue_free()
	await process_frame


## O fogão sozinho (começo do jogo) mostra 4 receitas inteiras sem rolar, em 360×780.
func _stove_rows() -> void:
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 20)
	await _open("Cozinha", sheet_builder.call("stations_view", PackedStringArray(["stove"])))
	var rows: Array[Control] = []
	for node: Node in sheet.get_node("%ContentHolder").find_children("*", "PanelContainer", true, false):
		if (node as PanelContainer).theme_type_variation == &"RowPanel":
			rows.append(node as Control)
	check(rows.size() >= 4, "o fogão tem pelo menos 4 receitas (%d)" % rows.size())
	if rows.size() >= 4:
		var scroll_bottom := (sheet.get_node("%ContentHolder").get_parent() as Control).get_global_rect().end.y
		check(rows[3].get_global_rect().end.y <= scroll_bottom + 1.0, "4ª receita inteira sem rolar (%d de %d)" % [rows[3].get_global_rect().end.y, scroll_bottom])
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _pieces() -> void:
	var texture: Texture2D = ui_kit.call("ui_icon", "coin")
	for entry: Array in [["empty", 0.0], ["queued", 0.0], ["busy", 0.4], ["ready", 1.0], ["buy", 1.0], ["level", 0.0]]:
		var dot: Control = ui_kit.call("slot_dot", entry[0], texture, entry[1], "x")
		root.add_child(dot)
		await process_frame
		check(dot.size.y >= 56.0 and dot.size.y <= 90.0, "bolinha %s tem ~76 px de altura (%d)" % [entry[0], dot.size.y])
		dot.queue_free()
	var chips: Array[Control] = [ui_kit.call("chip", texture, "3")]
	var row: Control = ui_kit.call("list_row", texture, "Receita", chips, null)
	row.custom_minimum_size.x = 304.0  # largura útil de um painel em 360 px
	root.add_child(row)
	await process_frame
	check(row.size.y >= 64.0 and row.size.y <= 100.0, "linha de lista baixa (%d)" % row.size.y)
	row.queue_free()
	await process_frame
