extends SceneTree
## Vitrine da etapa 02, não é teste. Duas páginas preservam toque e tipografia reais.
var host: Control
var box: VBoxContainer
var kit: Script
var tex: Texture2D
var folder := "res://../build/screenshots/i2_02_vitrine/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	kit = load("res://scripts/ui/ui_kit.gd")
	Motion.reduced = true
	host = Control.new()
	host.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper := ColorRect.new()
	paper.color = Palette.PAPER
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex = kit.call("ui_icon", "item_carrot")
	_page()
	box.add_child(kit.call("label", "Peças da casa", &"TitleLabel"))
	var row := _row()
	row.add_child(kit.call("primary", "Cozinhar", _noop))
	row.add_child(kit.call("small_go", "Pegar", _noop))
	row.add_child(kit.call("soft", "Depois", _noop, null, true))
	row = _row()
	var disabled: Button = kit.call("primary", "Cozinhar", _noop)
	disabled.disabled = true
	row.add_child(disabled)
	row.add_child(kit.call("ghost", "Ver tudo", _noop))
	row.add_child(kit.call("ctl_button", "gear", _noop))
	row.add_child(kit.call("ctl_button", "x", _noop, 32, "sunken"))
	var chips: HFlowContainer = kit.call("flow", 4)
	box.add_child(chips)
	for kind: String in ["neutral", "prize", "time", "have", "missing"]:
		chips.add_child(kit.call("chip", null if kind == "time" else tex, "1 min" if kind == "time" else "+2", null, kind))
	row = _row()
	for color: Color in [Palette.SKY, Palette.GO, Palette.ALERT, Palette.HONEY]:
		row.add_child(kit.call("ring", tex, 0.7, color))
	row.add_child(kit.call("badge", 4))
	row.add_child(kit.call("dot"))
	row.add_child(kit.call("spark"))
	row = _row()
	row.add_child(kit.call("steps", 6, 2))
	row.add_child(kit.call("toggle", true, _value))
	row.add_child(kit.call("toggle", false, _value))
	row = _row()
	for count: int in [1, 3]: row.add_child(kit.call("stepper", count, 1, 3, _value))
	var entries: Array[Dictionary] = [{"id": "a", "text": "Itens", "icon": tex, "count": 2}, {"id": "b", "text": "Fotos", "alert": true}]
	box.add_child(kit.call("segmented", entries, "a", _value))
	row = _row()
	for state: String in ["normal", "selected", "missing", "locked"]:
		row.add_child(kit.call("tile", tex, "1 min", state, kit.call("ui_icon", "item_milk")))
	row = _row()
	for state: String in ["busy", "ready", "empty", "queued", "buy", "level"]:
		row.add_child(kit.call("slot_dot", state, tex, 0.6, {"busy": "0:59", "ready": "Pronto", "buy": "80", "level": "Nível 2"}.get(state, "")))
	box.add_child(kit.call("lock_hint", "Depois do ateliê", _noop, tex))
	await _shot("vitrine")
	box.free()
	_page()
	box.add_child(kit.call("section", "Nesta lista", kit.call("chip", null, "3", null, "neutral")))
	var list: VBoxContainer = kit.call("list_card", box)
	for i in 3:
		var chips_in: Array[Control] = [kit.call("chip", tex, "2/6", null, "have" if i == 1 else "neutral")]
		list.add_child(kit.call("list_row", tex, "Colher cenouras", chips_in, kit.call("small_go", "Pegar", _noop) if i == 1 else null, Callable(), i == 1))
	box.add_child(load("res://scripts/ui/speech_bubble.gd").new("Bora plantar as primeiras cenouras?", "Laís"))
	var card: VBoxContainer = kit.call("card", box)
	card.add_child(load("res://scripts/ui/speech_bubble.gd").new("A horta está pronta!", "Vovó Bloblo", true))
	box.add_child(kit.call("lock_hint", "Depois da primeira colheita", _noop, tex))
	await _shot("vitrine_listas")
	quit(0)


func _noop() -> void: pass
func _value(_arg: Variant) -> void: pass


func _page() -> void:
	box = kit.call("vbox", 8)
	host.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 16
	box.offset_right = -16
	box.offset_top = 16
	box.offset_bottom = -16


func _row() -> HBoxContainer:
	var row: HBoxContainer = kit.call("hbox", 4)
	box.add_child(row)
	return row


func _shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + name + ".png")
