extends SceneTree
## Rolagem por arrasto em todas as listas: o dedo (toque OU mouse) cai sobre um botão/cartão, arrasta
## ~150 px e a lista rola SEM disparar o item; um toque curto continua disparando.
## --headless --path game -s res://tests/drag_scroll_test.gd [-- --before]   (--before: sem o DragScroll, só mede)

var failures := 0
var state: Node
var main: Control
var before := false
var mode := "touch"
var fired := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(240.0).timeout.connect(func() -> void:
		push_error("DRAG SCROLL: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		if not before:
			failures += 1
			push_error("DRAG SCROLL: " + message)
		else:
			print("ANTES (quebrado): ", message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


# --- Eventos ------------------------------------------------------------------------------------------------

func win(point: Vector2) -> Vector2:
	return root.get_final_transform() * point


func send(kind: String, point: Vector2, relative := Vector2.ZERO) -> void:
	var at := win(point)
	if mode == "touch":
		if kind == "move":
			var drag := InputEventScreenDrag.new()
			drag.position = at
			drag.relative = relative
			Input.parse_input_event(drag)
		else:
			var touch := InputEventScreenTouch.new()
			touch.position = at
			touch.pressed = kind == "down"
			Input.parse_input_event(touch)
	else:
		if kind == "move":
			var motion := InputEventMouseMotion.new()
			motion.position = at
			motion.global_position = at
			motion.relative = relative
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(motion)
		else:
			var button := InputEventMouseButton.new()
			button.position = at
			button.global_position = at
			button.button_index = MOUSE_BUTTON_LEFT
			button.pressed = kind == "down"
			button.button_mask = MOUSE_BUTTON_MASK_LEFT if kind == "down" else 0
			Input.parse_input_event(button)
	Input.flush_buffered_events()
	await frames(2)


func swipe(from: Vector2, delta: Vector2) -> void:
	await send("down", from)
	var steps := 6
	for i in range(1, steps + 1):
		await send("move", from + delta * (float(i) / steps), delta / steps)
	await send("up", from + delta)
	await frames(2)


func tap_at(point: Vector2) -> void:
	await send("down", point)
	await send("up", point)
	await frames(3)


func settle() -> void:
	await create_timer(0.9).timeout
	await frames(2)


# --- Sondas -------------------------------------------------------------------------------------------------

func overflow(scroll: ScrollContainer) -> Vector2:
	var v := scroll.get_v_scroll_bar()
	var h := scroll.get_h_scroll_bar()
	var vy := v.max_value - v.page if scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED else 0.0
	var hx := h.max_value - h.page if scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED else 0.0
	return Vector2(hx, vy)


func position_of(scroll: ScrollContainer) -> Vector2:
	return Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)


## Primeiro botão/probe inteiramente visível dentro da rolagem (preferindo o do meio).
func find_probe(scroll: ScrollContainer, extra: Array) -> Control:
	var area := scroll.get_global_rect().grow(-6.0)
	if overflow(scroll).x > overflow(scroll).y:
		area = Rect2(area.position - Vector2(0, 2000), Vector2(area.size.x, area.size.y + 4000))
	else:
		area = Rect2(area.position - Vector2(2000, 0), Vector2(area.size.x + 4000, area.size.y))
	var best: Control = null
	var best_score := INF
	var candidates: Array = extra.duplicate()
	for node in scroll.find_children("*", "Button", true, false):
		candidates.append(node)
	for node: Control in candidates:
		if not is_instance_valid(node) or not node.is_visible_in_tree() or node.size.x < 12 or node.size.y < 12:
			continue
		if node is Button and (node as Button).disabled:
			continue
		var rect := node.get_global_rect()
		if not area.encloses(rect):
			continue
		var score := absf(rect.get_center().y - area.get_center().y) + absf(rect.get_center().x - area.get_center().x) * 0.2
		if score < best_score:
			best_score = score
			best = node
	return best


func watch(probe: Control) -> void:
	if probe.has_meta("watched"):
		return
	probe.set_meta("watched", true)
	if probe is Button:
		(probe as Button).pressed.connect(func() -> void:
			fired += 1
			if "--debug" in OS.get_cmdline_user_args(): print("  pressed ", probe.name, " t=", Time.get_ticks_msec()))


## Executa o contrato numa rolagem: arrasto rola sem agir; toque age.
func exercise(label: String, scroll: ScrollContainer, extra: Array = []) -> void:
	var room := overflow(scroll)
	if room.x < 20.0 and room.y < 20.0:
		print("DRAG SCROLL %s [%s]: sem sobra de conteúdo (ignorado)" % [label, mode])
		return
	var horizontal := room.x > room.y
	var probe := find_probe(scroll, extra)
	check(probe != null, "%s [%s]: há item visível para tocar" % [label, mode])
	if probe == null:
		return
	watch(probe)
	var start := position_of(scroll)
	var forward := (start.x if horizontal else start.y) < (room.x if horizontal else room.y) / 2.0
	var sign := -1.0 if forward else 1.0  # dedo para cima/esquerda = conteúdo avança
	var delta := Vector2(150.0 * sign, 0.0) if horizontal else Vector2(0.0, 150.0 * sign)
	fired = 0
	await swipe(probe.get_global_rect().get_center(), delta)
	var moved := position_of(scroll) - start
	var did := (absf(moved.x) if horizontal else absf(moved.y)) > 20.0
	check(did, "%s [%s]: arrastar sobre o item rola (%s -> %s)" % [label, mode, start, position_of(scroll)])
	check(fired == 0, "%s [%s]: arrastar NÃO dispara o item (%d)" % [label, mode, fired])
	await settle()
	# Toque curto: o item (agora possivelmente em outro lugar) ainda age.
	probe = find_probe(scroll, extra)
	check(probe != null, "%s [%s]: item visível depois de rolar" % [label, mode])
	if probe == null:
		return
	watch(probe)
	fired = 0
	await tap_at(probe.get_global_rect().get_center() + Vector2(1, 1))
	check(fired == 1, "%s [%s]: toque curto dispara o item uma vez (%d)" % [label, mode, fired])
	print("DRAG SCROLL %s [%s]: ok (rolou %s)" % [label, mode, moved])


# --- Cenários -----------------------------------------------------------------------------------------------

func fresh() -> void:
	if main:
		main.queue_free()
		await frames(3)
	state.call("reset")
	state.call("dev_unlock_everything")
	state.get("progress").seen.intro = true
	state.call("_mark_all_seen")
	state.call("dev_add_items", 3)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	Motion.reduced = true
	await frames(8)
	if before and main.has_node("DragScroll"):
		main.get_node("DragScroll").free()
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])


func long_list(count: int, tap_rows: bool) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in count:
		var button := Button.new()
		button.text = "Botão %d" % i
		button.custom_minimum_size = Vector2(0, 56)
		box.add_child(button)
		if tap_rows and i % 3 == 0:
			var row: Control = load("res://scripts/ui/ui_kit.gd").call("list_row", null, "Linha %d" % i, [] as Array[Control], null, func() -> void: fired += 1)
			row.name = "Row%d" % i
			box.add_child(row)
	return box


func scenario_synthetic() -> void:
	await fresh()
	var holder := Control.new()
	holder.size = Vector2(360, 780)
	main.add_child(holder)
	# Vertical: botões e uma linha de lista (UiKit.on_tap).
	var vertical := ScrollContainer.new()
	vertical.position = Vector2(30, 160)
	vertical.size = Vector2(300, 420)
	vertical.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical.add_child(long_list(30, true))
	holder.add_child(vertical)
	# O holder fica no CanvasLayer 0 da casca: precisa estar por cima do que a casca desenha.
	holder.z_index = 50
	await frames(4)
	await exercise("sintético vertical (botões)", vertical)
	vertical.scroll_vertical = 0
	await frames(2)
	var row := vertical.find_child("Row0", true, false) as Control
	if row:
		await exercise("sintético vertical (linha on_tap)", vertical, [row])
	# Linha de lista como alvo exclusivo: o toque age no soltar dentro.
	vertical.scroll_vertical = 0
	await frames(2)
	row = vertical.find_child("Row3", true, false) as Control
	if row and vertical.get_global_rect().grow(-6).encloses(row.get_global_rect()):
		fired = 0
		await swipe(row.get_global_rect().get_center(), Vector2(0, -150))
		check(fired == 0, "linha on_tap [%s]: arrastar não dispara" % mode)
		await settle()
		vertical.scroll_vertical = 0
		await frames(2)
		fired = 0
		await tap_at(row.get_global_rect().get_center())
		check(fired == 1, "linha on_tap [%s]: toque dispara (%d)" % [mode, fired])
	# Horizontal.
	var horizontal := ScrollContainer.new()
	horizontal.position = Vector2(20, 620)
	horizontal.size = Vector2(320, 70)
	horizontal.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	horizontal.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var strip := HBoxContainer.new()
	for i in 20:
		var button := Button.new()
		button.text = "Aba %d" % i
		button.custom_minimum_size = Vector2(90, 50)
		strip.add_child(button)
	horizontal.add_child(strip)
	holder.add_child(horizontal)
	await frames(4)
	await exercise("sintético horizontal", horizontal)


func scenario_sheet() -> void:
	await fresh()
	var content := long_list(40, true)
	state.get_node("/root/Events").sheet_requested.emit("Teste", content)
	await frames(10)
	await create_timer(0.4).timeout
	var sheet := main.find_child("Sheet", true, false)
	var scroll := sheet.find_child("Scroll", true, false) as ScrollContainer
	check(scroll != null, "Sheet tem rolagem")
	if scroll:
		await exercise("Sheet (conteúdo genérico)", scroll)
	state.get_node("/root/Events").sheet_close_requested.emit()
	await frames(4)


func scenario_sheet_view(label: String, factory: Callable, title := "Teste") -> void:
	await fresh()
	state.get_node("/root/Events").sheet_requested.emit(title, factory.call())
	await frames(10)
	await create_timer(0.5).timeout
	var sheet := main.find_child("Sheet", true, false)
	var scrolls := sheet.find_children("*", "ScrollContainer", true, false)
	var any := false
	for node in scrolls:
		if not is_instance_valid(node): continue
		var scroll := node as ScrollContainer
		if scroll.is_visible_in_tree() and (overflow(scroll).x > 20.0 or overflow(scroll).y > 20.0):
			any = true
			await exercise("%s (%s)" % [label, scroll.name], scroll)
	if not any:
		print("DRAG SCROLL %s: nenhuma rolagem com sobra (ignorado)" % label)
	state.get_node("/root/Events").sheet_close_requested.emit()
	await frames(4)


func scenario_screen(label: String, screen: StringName) -> void:
	await fresh()
	main.call("show_screen", screen)
	await frames(10)
	var found := false
	for node in main.find_children("*", "ScrollContainer", true, false):
		if not is_instance_valid(node): continue
		var scroll := node as ScrollContainer
		if scroll.is_visible_in_tree() and (overflow(scroll).x > 20.0 or overflow(scroll).y > 20.0):
			found = true
			await exercise("%s (%s)" % [label, scroll.name], scroll)
	if not found:
		print("DRAG SCROLL %s: nenhuma rolagem com sobra (ignorado)" % label)


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	before = "--before" in OS.get_cmdline_user_args()
	Input.emulate_mouse_from_touch = true
	for input_mode: String in ["touch", "mouse"]:
		mode = input_mode
		var only := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--only="): only = a.substr(7)
		if only in ["", "synthetic"]: await scenario_synthetic()
		if only in ["", "sheet"]: await scenario_sheet()
		if only in ["", "bag"]: await scenario_screen("Mochila", &"bag")
		if only in ["", "tasks"]: await scenario_screen("Missões", &"tasks")
		if only in ["", "codex"]: await scenario_sheet_view("Caderninho", func() -> Control: return load("res://scripts/ui/pet_notebook.gd").call("panel", "resources"), "Caderninho")
		if only in ["", "sell"]: await scenario_sheet_view("Feira", func() -> Control: return load("res://scripts/ui/market_ui.gd").call("sell", "farm"), "Feira")
		if only in ["", "item"]: await scenario_sheet_view("Item", func() -> Control: return load("res://scripts/ui/sheet_builder.gd").call("item_detail", "carrot"), "Cenoura")
		if only in ["", "station"]: await scenario_sheet_view("Estações", func() -> Control: return load("res://scripts/ui/sheet_builder.gd").call("station_view", "stove"), "Fogão")
		if only in ["", "story"]: await scenario_sheet_view("História", func() -> Control: return load("res://scripts/ui/mission_ui.gd").call("story_book"), "História")
	print("DRAG SCROLL TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
