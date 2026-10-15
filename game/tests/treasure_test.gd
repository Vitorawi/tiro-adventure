extends SceneTree
## Missão "O mapa completo", baú da Clareira (uma vez só), mirtilo e persistência da Etapa 11.
var state: Node
var db: Node
var failures: int = 0
var celebrations: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Tesouro: " + message)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	var p: RefCounted = state.get("progress")
	var inv: RefCounted = state.get("inventory")
	root.get_node("Events").connect("treasure_opened", func(_r: Dictionary) -> void: celebrations += 1)
	# Missão só aparece depois de guide_fibers.
	check(not state.call("quest_unlocked", "guide_treasure"), "missão escondida antes de guide_fibers")
	check(state.call("open_treasure_error") != "" and state.call("open_treasure") != "", "baú fechado sem missão")
	for id: String in db.get("quests"):
		var quest: Dictionary = db.get("quests")[id]
		if quest.get("line", "") == "guide" and int(quest.order) < 50:
			p.claimed_quests[id] = true
	check(state.call("quest_unlocked", "guide_treasure"), "missão abre depois de guide_fibers")
	for n in range(1, 5):
		check(state.call("quest_error", "guide_treasure") != "", "faltam pedaços (%d)" % (n - 1))
		inv.add("map_piece_%d" % n, 1)
	check(state.call("quest_error", "guide_treasure") == "", "pronta com os quatro pedaços")
	var coins: int = state.get("coins")
	check(state.call("claim_quest", "guide_treasure") == "", "recebe a missão")
	check(state.get("coins") == coins + 30, "30 moedas")
	for n in range(1, 5):
		check(inv.count("map_piece_%d" % n) == 1, "pedaço %d não é consumido" % n)
	check(state.call("claim_quest", "guide_treasure") != "" and state.get("coins") == coins + 30, "missão não repete")
	# Mirtilo ainda fechado até abrir o baú.
	check(state.call("content_error", "crop", "blueberry", db.get("crops").blueberry) != "", "mirtilo bloqueado antes do baú")
	# Baú: abre uma vez, entrega tudo.
	check(state.call("open_treasure_error") == "", "baú disponível")
	var bolts: int = inv.count("bolt")
	coins = state.get("coins")
	check(state.call("open_treasure") == "", "abre o baú")
	check(celebrations == 1, "uma festa")
	check(state.get("coins") == coins + 150 and inv.count("bolt") == bolts + 2, "150 moedas e 2 parafusos")
	check(p.collection.has("explorer_hat"), "Chapéu de explorador")
	check(p.unlocks.has("crop:blueberry") and state.call("content_error", "crop", "blueberry", db.get("crops").blueberry) == "", "mirtilo liberado")
	check(p.stat("treasure") == 1 and state.call("treasure_opened"), "contador e marca")
	check(state.call("open_treasure") == "Já aberto" and state.get("coins") == coins + 150 and celebrations == 1, "toque repetido não paga")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	p = state.get("progress")
	inv = state.get("inventory")
	check(state.call("open_treasure") == "Já aberto" and state.get("coins") == coins + 150, "salvar/reabrir não repete")
	check(p.collection.has("explorer_hat") and p.unlocks.has("crop:blueberry"), "prêmios persistem")
	# Conjunto da natureza também entrega o chapéu sem duplicar.
	var hats := 0
	for id: String in p.collection:
		hats += 1 if id == "explorer_hat" else 0
	check(hats == 1, "um chapéu só")
	# Mirtilo planta e colhe.
	state.set("unlocked_plots", 3)
	p.owned["farm"] = true
	check(state.call("plant", 0, "blueberry") == "", "planta mirtilo")
	state.call("dev_advance_time", 901.0)
	check(state.call("plot_status", 0) == "ready", "mirtilo cresce em 15 min")
	var before: int = inv.count("blueberry")
	state.call("harvest", 0)
	check(inv.count("blueberry") == before + 3, "colhe 3 mirtilos")
	check(db.get("items").blueberry.feed.happiness == 8 and db.get("crops").blueberry.coins == 20, "dados do mirtilo")
	# Desejo especial do mirtilo.
	var wish: Dictionary = db.get("wishes").wishes.blueberry
	check(wish.special and state.call("requirement_error", wish.requirements) == "", "desejo de mirtilo abre depois do baú")
	# Ir: pedaços levam ao mundo onde se cava.
	var places: Script = load("res://scripts/ui/places.gd")
	var worlds := {"map_piece_1": "farm", "map_piece_2": "park", "map_piece_3": "village", "map_piece_4": "nature"}
	for key: String in worlds:
		var target: Dictionary = places.call("goal_target", {"type": "have", "key": key, "target": 1})
		check(target.get("world") == worlds[key] and target.get("place") == "find", "Ir de %s leva a %s" % [key, worlds[key]])
	# Sala da Natureza: baú só existe depois da missão; abre e troca o desenho.
	var fresh_state: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
	room.set("room_id", "nature")
	room.set("world_id", "nature")
	root.add_child(room)
	await process_frame
	var chest: Sprite2D = _find_chest(room)
	check(chest != null and not chest.visible, "baú escondido antes da missão")
	state.call("from_dict", fresh_state)
	state.get("progress").seen.erase("treasure_opened")
	state.get("progress").collection.erase("explorer_hat")
	state.call("_changed")
	await process_frame
	check(chest.visible, "baú aparece com a missão")
	room.call("_open_treasure", chest)
	await process_frame
	check(not chest.visible, "baú some depois de aberto")
	check(state.call("treasure_opened"), "aberto na sala")
	room.queue_free()
	await process_frame
	print("TREASURE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _find_chest(node: Node) -> Sprite2D:
	for child in node.find_children("treasure_chest", "Sprite2D", true, false):
		return child as Sprite2D
	return null
