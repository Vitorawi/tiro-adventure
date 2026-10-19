extends SceneTree
## Capturas da Mochila com depósitos no limite, excesso legado e "Presentes para guardar" (Etapa 02 da economia).
## NÃO é teste. Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/storage_shots.gd -- --out=etapa02_antes/360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa02/"


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
	saver.set("_save_path", "user://storage_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	var owned: Dictionary = state.get("progress").owned
	for id: String in ["fridge", "silo", "warehouse", "chest"]:
		owned[id] = true
		owned.erase(id + "_2")
		owned.erase(id + "_3")
	state.get("economy").storage_floor.clear()  # a captura "desfaz" as compras para mostrar os limites base
	state.get("progress").seen["feature:bag"] = true
	state.call("_mark_all_seen")
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("carrot", 38)
	inventory.add("wheat", 14)  # silo: 52/40 (excesso do que já tinha)
	inventory.add("plank", 31)
	inventory.add("brick", 0)
	inventory.add("bolt", 9)  # armazém: 40/40
	inventory.add("egg", 9)
	inventory.add("milk", 4)
	inventory.add("carrot_snack", 17)
	inventory.add("dog_food", 6)
	for id: String in inventory.counts:
		state.get("progress").seen["ui:bag:" + id] = true
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"bag")
	await shot("01_mochila_limites")
	if state.has_method("pending_reward_count"):
		# Geladeira, armazém e baú cheios: presentes automáticos esperam num recibo, sem perda.
		inventory.add("plank", 9)  # armazém 40/40
		inventory.add("treat_box", 20)  # baú 20/20
		state.call("_grant_automatic", "customer:lais:1", {"coins": 20, "items": {"carrot_snack": 1}})
		state.call("_grant_automatic", "customer:lais:2", {"coins": 0, "items": {"treat_box": 2, "plank": 5}})
		state.call("_grant_automatic", "customer:bolota:1", {"coins": 25, "items": {"carrot_snack": 2}})
		state.call("_changed")
		await shot("02_mochila_presentes_recolhido", 3.6)
		var list: Node = main.find_child("InventoryList", true, false)
		list.call("toggle_gifts")
		await shot("03_mochila_presentes_aberto")
		# Abre espaço (consome 2 comidas e 1 tábua): guarda só o que cabe; o resto continua esperando.
		inventory.remove("carrot_snack", 2)
		inventory.remove("plank", 1)
		state.call("claim_pending_rewards")
		await shot("04_mochila_depois_de_guardar_parte")
		list.call("toggle_gifts")
		await shot("05_mochila_presentes_recolhido_resto")
	print("STORAGE SHOTS: pronto")
	quit()
