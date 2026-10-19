extends SceneTree
## Etapa 08: ações reais, persistência, filas únicas, bolsinha e garantia lendária independente.

var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Pet shop: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	check(state.call("equip_error", "red_scarf") != "", "não veste o que não tem")
	progress.collection["farm_ribbon"] = true
	check(state.call("equip_error", "farm_ribbon") == "Em breve no Tiro", "sem arte não veste invisível")
	check(state.call("buy_cosmetic_error", "red_scarf") != "", "loja fechada")
	progress.owned["petshop"] = true
	progress.owned["sewing_table"] = true
	state.set("coins", 1000)
	check(state.call("buy_cosmetic", "red_scarf") == "" and state.get("coins") == 940, "compra desconta uma vez")
	check(state.call("buy_cosmetic", "red_scarf") != "" and state.get("coins") == 940, "compra repetida bloqueada")
	var food: int = state.get("inventory").count("dog_food")
	check(state.call("buy_shop_item", "dog_food_pack") == "" and state.get("inventory").count("dog_food") == food + 5 and state.get("coins") == 925, "pacote dá cinco por quinze")
	check(state.call("equip", "red_scarf") == "", "veste lenço")
	var equips: int = progress.stat("equip")
	check(state.call("equip", "red_scarf") == "" and progress.stat("equip") == equips, "vestir igual não repete contador")
	for id: String in ["blue_collar", "yellow_bow", "sponge_uniform"]:
		progress.collection[id] = true
		check(state.call("equip", id) == "", "veste " + id)
	check(progress.equipped.neck == "blue_collar" and progress.equipped.head == "yellow_bow" and progress.equipped.body == "sponge_uniform", "um por slot e três juntos")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	progress = state.get("progress")
	check(progress.equipped.body == "sponge_uniform", "roupas persistem")
	check(state.call("unequip", "neck") == "" and progress.equipped.neck == "", "tira por lugar")
	check(state.call("unequip_error", "tail") != "", "slot inválido")
	for item: String in ["wildflower", "ribbon"]:
		state.get("inventory").add(item, 10)
	var flowers: int = state.get("inventory").count("wildflower")
	check(state.call("cook", "sew_flower_crown") == "", "costura começa")
	check(state.get("inventory").count("wildflower") == flowers - 3, "consome uma vez")
	check(state.call("cook_error", "sew_flower_crown") == "Já está sendo costurado", "não duplica roupa na fila")
	saved = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	progress = state.get("progress")
	var queue: RefCounted = state.call("station", "sewing")
	check(queue.queue.size() == 1 and state.call("cook_error", "sew_flower_crown") == "Já está sendo costurado", "fila salva mantém exclusividade")
	queue.queue[0].ready_at = 0.0
	state.call("collect", "sewing")
	check(progress.collection.has("flower_crown") and progress.stat("sew") == 1 and progress.stat("produce:flower_crown") == 1, "coleta dá coleção e contadores")
	check(state.get("inventory").count("flower_crown") == 0, "roupa não vira material de mochila")
	state.call("collect", "sewing")
	check(progress.stat("sew") == 1 and state.call("cook_error", "sew_flower_crown") == "Você já tem", "coleta única e receita concluída bloqueada")
	# Save anterior à Etapa 08 continua com progresso, sem roupa fantasma.
	saved.progression.erase("equipped")
	state.call("from_dict", saved)
	progress = state.get("progress")
	check(progress.equipped.head == "" and progress.collection.has("red_scarf"), "save antigo preservado")
	await _walks()
	await _ui()
	for id: String in db.get("collections"):
		var data: Dictionary = db.get("collections")[id]
		if str(data.get("overlay", "")) != "":
			check(ResourceLoader.exists(data.overlay), "overlay existe " + id)
	var anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/characters/tiro_pet/overlay_anchors.json"))
	check("sleep" in anchors.show_in and not "happy_jump" in anchors.show_in, "sono vestido e acrobacia oculta")
	check(db.call("place_with_panel", "station:sewing") == ["park", "sewing"], "Manual/ajuda encontram a costura separada da loja")
	var places: Script = load("res://scripts/ui/places.gd")
	check(places.call("quest_target", "nina_dress").get("collection", false), "Ir da Nina abre Coleção")
	print("PETSHOP TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _walks() -> void:
	var progress: RefCounted = state.get("progress")
	progress.collection.erase("sponge_uniform")
	check(state.call("_walk_legendary", 1) == "", "lendário bloqueado antes do marco")
	progress.claimed_quests["nina_meet"] = true
	progress.claimed_quests["main_2_order"] = true
	progress.owned["petshop"] = true
	progress.count("walk", 20)
	var walk: Dictionary = db.get("walks").walks.park_loop
	var before: Dictionary = walk.loot.duplicate(true)
	walk.loot = {"rolls": 1, "table": [{"weight": 1, "items": {"carrot": 1}}]}
	state.get("dog").needs.energy = 100.0
	state.get("dog").sleeping = false
	check(state.call("start_walk", "park_loop") == "", "passeio preparado")
	state.get("walk_state").current.seed = 12345
	var normal: Dictionary = state.call("walk_loot")
	progress.owned["walk_bag"] = true
	state.get("walk_state").pity.legendary = 29
	var bonus: Dictionary = state.call("walk_loot")
	check(normal.items.carrot == 1 and bonus.items.carrot == 2, "bolsinha acrescenta um sorteio")
	check(state.call("walk_loot") == bonus and bonus.legendary == "sponge_hat", "seed estável e lendário garantido")
	var silo: Dictionary = db.get("progression").storage.silo
	progress.owned[silo.building] = true
	state.get("inventory").add("carrot", int(state.call("storage_capacity", "silo")))
	state.get("walk_state").current.ready_at = 0.0
	var carrots: int = state.get("inventory").count("carrot")
	state.call("return_due_walk")
	check(not state.call("walking") and state.call("collect_walk_error") != "" and state.call("collect_walk").is_empty(), "bolsinha respeita depósito cheio")
	check(state.get("inventory").count("carrot") == carrots and state.get("walk_state").baggage_count() == 2, "bagagem espera inteira, nada perdido")
	check(progress.collection.has("sponge_hat") and progress.stat("walk_legendary") == 1, "a volta já deu o lendário, uma vez só")
	state.get("inventory").remove("carrot", state.get("inventory").count("carrot"))
	var result: Dictionary = state.call("collect_walk")
	check(state.get("inventory").count("carrot") == 2, "guarda exatamente o sorteio congelado")
	check(progress.collection.has("sponge_hat") and progress.stat("walk_legendary") == 1, "lendário vai à coleção uma vez")
	walk.loot = before
	# Duas garantias no mesmo passeio: o lendário soma, sem consumir o lugar do raro.
	state.get("dog").needs.energy = 100.0
	state.get("walk_state").pity.legendary = 29
	state.get("walk_state").pity.park_loop = 5
	state.call("start_walk", "park_loop")
	state.get("walk_state").current.ready_at = 0.0
	result = state.call("collect_walk")
	check(result.rare == "plaid_bow" and result.legendary == "sponge_uniform", "raro e segundo lendário juntos")
	check(progress.collection.has("sponge_uniform") and state.get("walk_state").pity.park_loop == 0, "garantias independentes e sem lendário repetido")
	var full_pity: Dictionary = state.get("walk_state").pity.duplicate()
	state.get("dog").needs.energy = 100.0
	state.call("start_walk", "park_loop")
	state.call("cancel_walk")
	check(state.get("walk_state").pity == full_pity, "cancelamento não gasta garantias")


func _ui() -> void:
	var result: Node = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	root.add_child(result)
	state.get("progress").collection.red_scarf = true
	result.call("show_result", {"name": "Teste", "rare": "red_scarf"})
	check(result.find_child("Equip_red_scarf", true, false) != null, "cartão com Vestir agora")
	result.find_child("Equip_red_scarf", true, false).emit_signal("pressed")
	check(state.get("progress").equipped.neck == "red_scarf", "botão veste")
	result.queue_free()
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	var panel: Control = ui.call("petshop_panel")
	root.add_child(panel)
	await process_frame
	check(panel.get_child_count() > 0, "painel de compras da loja")
	panel.queue_free()
