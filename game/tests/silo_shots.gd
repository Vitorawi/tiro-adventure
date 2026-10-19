extends SceneTree
## Capturas do Cesto da horta → Silo (Etapa 05 da economia). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/silo_shots.gd -- --out=etapa05_depois/360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa05/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
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


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://silo_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	# Logo depois da primeira colheita: sítio aberto, quatro canteiros emprestados, cesto quase cheio.
	for id: String in ["lais_bed", "lais_meet_bloblo", "lais_first_crops", "bloblo_meet", "first_harvest", "bloblo_sell_surplus", "bloblo_dig"]:
		state.call("dev_complete_quest", id)
	progress.owned["farm"] = true
	progress.owned.erase("silo")
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")
	state.call("_mark_all_seen")
	progress.seen["feature:bag"] = true
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("carrot", 14)
	inventory.add("dog_food", 3)
	for id: String in inventory.counts:
		progress.seen["ui:bag:" + id] = true
	state.set("coins", 40)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(1.2).timeout
	_hide_modals()
	await shot("01_horta_balao_gratis")
	# Mochila: Cesto da horta 14/16.
	main.call("show_screen", &"bag")
	await shot("02_mochila_cesto")
	# Painel de construção do silo (grátis, 16 → 32).
	root.get_node("Events").sheet_requested.emit("Silo", load("res://scripts/ui/progression_ui.gd").call("purchase", "silo"))
	await shot("03_painel_silo")
	root.get_node("Events").sheet_close_requested.emit()
	# Colheita que não cabe: quatro prontos, um só lote cabe.
	main.call("show_screen", &"map")
	await create_timer(0.8).timeout
	var farm: Control = main.find_child("World_farm", true, false)
	var plots: Array = state.get("plots")
	for i in 4:
		plots[i] = {"crop": "carrot", "ready_at": 0.0}
	state.call("_changed")
	farm.call("_animate_objects")
	var tray: Control = (load("res://scripts/ui/plot_tray.gd") as Script).call("sickle", farm, 1) as Control
	await shot("04_foice_tudo", 0.5)
	tray.call("tap_item", "all")
	await shot("05_tudo_parcial", 0.5)
	# Depois de arrumar o silo: Silo 16/32 e o balão some.
	farm.call("close_tray")
	state.call("buy_upgrade", "silo")
	main.call("show_screen", &"bag")
	await shot("06_mochila_silo", 3.6)
	print("SILO SHOTS: pronto")
	quit()
