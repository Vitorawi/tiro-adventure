extends SceneTree
## Base da interface nova (Etapa 00): RingProgress, Motion, Palette e ícones próprios das estações.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("UI base: " + message)


func _run() -> void:
	_ring()
	_motion()
	_palette()
	_icons()
	print("UI_BASE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _ring() -> void:
	var ring := RingProgress.new()
	ring.progress = 1.7
	check(is_equal_approx(ring.progress, 1.0), "Anel: 1,7 vira 1,0")
	ring.progress = -1.0
	check(is_equal_approx(ring.progress, 0.0), "Anel: -1 vira 0")
	ring.progress = 0.5
	check(is_equal_approx(ring.progress, 0.5), "Anel: 0,5 continua 0,5")
	check(ring.custom_minimum_size == Vector2(56, 56), "Anel: 56x56 por padrão")
	check(ring.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Anel não recebe toque")
	ring.free()


func _motion() -> void:
	Motion.reduced = true
	var box := Control.new()
	box.size = Vector2(100, 40)
	root.add_child(box)
	box.scale = Vector2(0.3, 0.3)
	box.modulate.a = 0.0
	Motion.pop_in(box)
	check(box.scale == Vector2.ONE, "pop_in reduzido: escala 1 na hora")
	check(is_equal_approx(box.modulate.a, 1.0), "pop_in reduzido: alfa 1 na hora")
	var label := Label.new()
	root.add_child(label)
	Motion.count_up(label, 0, 120, "+%d")
	check(label.text == "+120", "count_up reduzido escreve o valor final")
	var start := box.position
	Motion.shake(box)
	Motion.bounce(box)
	check(box.position == start, "shake/bounce reduzidos não mexem no nó")
	Motion.reduced = false
	# Sem reduzir: o número começa no valor inicial e o tween existe.
	var tween := Motion.count_up(label, 5, 50, "%d")
	check(label.text == "5" and tween != null, "count_up começa no valor inicial")
	tween.kill()
	var pulse := Motion.pulse(box)
	check(pulse != null and pulse.is_valid(), "pulse devolve o Tween ativo")
	pulse.kill()
	box.free()
	label.free()


func _palette() -> void:
	check(Palette.PRIMARY != Palette.ACCENT and Palette.INK != Palette.PAPER, "Paleta: cores distintas")
	for id: String in ["house", "farm", "park", "village", "nature"]:
		check(Palette.WORLD.has(id), "Paleta: cor do mundo " + id)
	var ui_kit: Script = load("res://scripts/ui/ui_kit.gd")
	check(ui_kit.get_script_constant_map().get("GOOD") == Palette.GOOD, "UiKit.GOOD aponta para Palette.GOOD")
	check(ui_kit.get_script_constant_map().get("BAD") == Palette.BAD, "UiKit.BAD aponta para Palette.BAD")


func _icon_exists(icon: String) -> bool:
	return ResourceLoader.exists("res://assets/sprites/ui/icons/%s.png" % icon)


func _icons() -> void:
	var upgrades: Dictionary = _json("res://data/progression.json").upgrades
	for id: String in upgrades:
		var icon: String = str(upgrades[id].get("icon", ""))
		check(_icon_exists(icon), "Upgrade %s: ícone '%s' não existe" % [id, icon])
	var worlds: Dictionary = _json("res://data/worlds.json")
	for world_id: String in worlds:
		for place_id: String in worlds[world_id].get("places", {}):
			var icon: String = str(worlds[world_id].places[place_id].get("icon", ""))
			check(_icon_exists(icon), "Lugar %s.%s: ícone '%s' não existe" % [world_id, place_id, icon])
	# Estações de produção têm ícone próprio, nunca emprestado de item ou aba.
	var stations := ["stove", "stove_queue", "stove_queue_2", "fridge", "fridge_2", "fridge_3", "blender", "chest", "chest_2", "chest_3",
		"workbench", "silo", "silo_2", "silo_3", "warehouse", "warehouse_2", "warehouse_3", "mill", "dairy", "chicken_coop",
		"cow_barn", "sewing_table", "stall"]
	for id: String in stations:
		var icon: String = str(upgrades[id].icon)
		check(icon.begins_with("station_"), "Estação %s usa ícone próprio (tem '%s')" % [id, icon])
		check(not icon.begins_with("tab_") and icon != "item_carrot_snack", "Estação %s não usa ícone emprestado" % id)
	check(_icon_exists("ui_lock"), "ui_lock existe")


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
