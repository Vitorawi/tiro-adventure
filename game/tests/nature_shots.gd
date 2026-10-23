extends SceneTree
## Capturas da etapa 11 da economia (rotas da Natureza com escolha de duração e patamares 24/120/360). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/nature_shots.gd -- --out=etapa11_depois/360x780
## `--antes` volta em memória às rotas e aos patamares anteriores (a interface é a nova; só os dados voltam).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa11/"
var before := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
		if arg == "--antes":
			before = true
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _level(xp: int, label: String, material: String, slots: int) -> Dictionary:
	return {"xp": xp, "label": label, "materials": [material], "slots": slots}


## Dados da etapa 10: rotas sem XP próprio, 3 patamares (0/30/90, 0/40/120, 0/30/90) e madeira cortada só no nível 2.
func _revert_data() -> void:
	var database: Node = root.get_node("Database")
	var activities: Dictionary = database.get("progression").activities
	var old := {
		"lane": [60, {"wood": 1}], "pebbles": [75, {"stone": 1}], "trail": [180, {"wood": 3, "stone": 2}], "quarry": [180, {"stone": 5}],
		"woodcutting": [150, {"wood": 4}], "timber": [240, {"wood": 5, "hardwood": 2}], "copper_vein": [360, {"stone": 3, "copper": 3}],
		"deep_quarry": [300, {"stone": 8, "copper": 4}], "crystal_cave": [600, {"crystal": 2, "copper": 2}], "crystal_deep": [480, {"crystal": 4, "copper": 3}],
		"meadow": [420, {"fiber": 5, "wood": 3}], "reeds": [300, {"fiber": 8, "wood": 3}],
	}
	for id: String in old:
		activities[id]["seconds"] = old[id][0]
		activities[id]["rewards"]["items"] = old[id][1]
		activities[id].erase("nature_xp")
	activities["woodcutting"]["requirements"]["owned"] = ["forest_level_2"]
	var sites: Dictionary = database.get("progression").nature_sites
	sites["trees"]["levels"] = [_level(0, "Madeira", "wood", 1), _level(30, "Mais madeira + 2 espaços", "wood", 2), _level(90, "Madeira dura + 3 espaços", "hardwood", 3)]
	sites["rocks"]["levels"] = [_level(0, "Pedra", "stone", 1), _level(40, "Cobre + 2 espaços", "copper", 2), _level(120, "Cristais + 3 espaços", "crystal", 3)]
	sites["fibers"]["levels"] = [_level(0, "Fibras", "fiber", 1), _level(30, "Mais fibras + 2 espaços", "fiber", 2), _level(90, "3 espaços de busca", "fiber", 3)]
	for site: String in sites:
		sites[site]["slot_levels"] = [2, 3]


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "nature_shots_descartavel.json"))
	state = root.get_node("GameState")
	if before:
		_revert_data()
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 5)
	progress.owned["forest_open"] = true
	progress.owned["cave_open"] = true
	progress.owned["meadow_open"] = true
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	state.set("coins", 300)
	progress.nature_xp = {"trees": 2, "rocks": 26, "fibers": 0}
	for site: String in ["trees", "rocks", "fibers"]:
		progress.call("sync_nature_tokens", site)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var events: Node = root.get_node("Events")
	var ui: Script = load("res://scripts/ui/nature_ui.gd")
	events.sheet_requested.emit("Bosque", ui.call("panel", "trees"))
	await shot("01_bosque_painel")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Evolução · Bosque", ui.call("levels_panel", "trees"))
	await shot("02_bosque_patamares")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Caverna", ui.call("panel", "rocks"))
	await shot("03_caverna_painel")
	events.sheet_close_requested.emit()
	main.call("_on_world_requested", "nature", "")
	await create_timer(1.2).timeout
	var room: Node = main.find_child("World_nature", true, false)
	if room != null:
		room.call("open_nature_tray", "trees")
		await shot("04_bosque_bandeja", 1.2)
	print("NATURE SHOTS: pronto")
	quit()
