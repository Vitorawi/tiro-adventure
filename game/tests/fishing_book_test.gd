extends SceneTree
## Pesca, etapa 09: caderno de peixes (filtro Peixes na Coleção), detalhe da espécie, rotinas de pesca, encomendas e o
## petisco de lambari. Relógio injetado e sem SaveManager.
## --headless --path game -s res://tests/fishing_book_test.gd

const T0 := 1900000000.0

var failures := 0
var state: Node
var db: Node
var sections: GDScript


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CADERNO: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _f() -> RefCounted:
	return state.get("fishing")


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	state.set("coins", 500)


func _view(filter: String) -> Dictionary:
	return sections.call("view", "collection", filter, {})


func _has_filter(view: Dictionary, id: String) -> bool:
	for entry: Dictionary in view.filters:
		if str(entry.id) == id:
			return true
	return false


func _tiles(view: Dictionary) -> Array:
	var result: Array = []
	for block: Dictionary in view.blocks:
		result.append_array(block.get("tiles", []))
	return result


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	Motion.reduced = true
	sections = load("res://scripts/ui/codex_sections.gd")
	_filter()
	_tiles_and_detail()
	_routines()
	_orders_and_treat()
	_sources_and_help()
	print("FISHING BOOK TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 1. O filtro só existe com a vara; o "Novo!" aparece uma vez.
func _filter() -> void:
	_fresh()
	check(not _has_filter(_view("clothes"), "fish"), "1: sem vara não há filtro Peixes")
	check(not ("feature:fish_book" in state.call("new_unlocks")), "1: sem vara não há Novo!")
	state.call("give_rod", "bamboo_rod")
	check(_has_filter(_view("clothes"), "fish"), "1: com a vara o filtro aparece")
	check("feature:fish_book" in state.call("new_unlocks"), "1: Novo! do caderno")
	state.call("mark_seen", ["feature:fish_book"] as Array[String])
	check(not ("feature:fish_book" in state.call("new_unlocks")), "1: Novo! só uma vez")


# 2/3. Nove tiles, recorde, sombra, vara não obtida apagada; detalhe.
func _tiles_and_detail() -> void:
	_fresh()
	state.call("give_rod", "bamboo_rod")
	var view := _view("fish")
	check(str(view.filter) == "fish" and view.blocks.size() == 3, "2: três blocos de vara")
	var tiles := _tiles(view)
	check(tiles.size() == 9, "2: nove espécies: %d" % tiles.size())
	for tile: Dictionary in tiles:
		check(bool(tile.dim) and str(tile.caption) == "?", "2: ninguém pego é sombra com ?: " + str(tile.name))
	check(bool(view.blocks[1].get("dim", false)) and str(view.blocks[1].lines[0]).begins_with("Ganhe"), "2: molinete apagado com dica")
	check(not bool(view.blocks[0].get("dim", false)), "2: bambu não apagado")
	_f().records["fish_lambari"] = {"best_cm": 12.5, "best_class": "large", "count": 3, "gigantes": 1, "perfects": 2, "first_at": 1.0}
	_f().records["fish_cara"] = {"best_cm": 9.0, "best_class": "small", "count": 1, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	tiles = _tiles(_view("fish"))
	var lambari: Dictionary = tiles[0]
	check(str(lambari.name) == "Fish_fish_lambari" and not bool(lambari.dim) and str(lambari.record) == "12,5 cm", "2: lambari pego com recorde")
	check(str(lambari.get("mark", "")) == "star", "2: Gigante tem a estrela")
	check(str(tiles[1].get("mark", "")) == "" and str(tiles[1].record) == "9,0 cm", "2: cará sem estrela")
	check(bool(tiles[2].dim), "2: tilápia ainda sombra")
	# Detalhe.
	state.call("dev_complete_quest", "growth_1_puppy")
	var detail: Control = sections.call("fish_detail", "fish_lambari")
	root.add_child(detail)
	check(detail.find_child("FishRuler", true, false) != null, "3: régua")
	check(detail.find_child("FishRecord", true, false) != null and detail.find_child("FishGiants", true, false) != null, "3: recorde e Gigantes")
	var count := detail.find_child("FishCount", true, false)
	check(count != null and "3" in _all_text(count), "3: pegou 3")
	check(detail.find_child("FishBait", true, false) != null and detail.find_child("FishRod", true, false) != null, "3: isca e vara")
	var go: Button = detail.find_child("FishGo", true, false) as Button
	check(go != null, "3: botão Ir pescar")
	detail.queue_free()
	var unknown: Control = sections.call("fish_detail", "fish_tilapia")
	root.add_child(unknown)
	check(unknown.find_child("FishNever", true, false) != null and unknown.find_child("FishRecord", true, false) == null, "3: não pego mostra só 'Ainda não pegou'")
	check(unknown.find_child("FishRuler", true, false) != null, "3: não pego ainda mostra a faixa")
	unknown.queue_free()
	var target: Dictionary = {"world": "farm", "place": "fishing"}
	check(db.get("worlds").farm.places.has("fishing") and str(target.place) == "fishing", "3: Ir leva à lagoa")


func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text += (node as Label).text + " "
	for child in node.get_children():
		text += _all_text(child)
	return text


# 4. Rotinas.
func _routines() -> void:
	var routines: Dictionary = db.get("routines")
	check(routines.daily.missions.has("fish") and routines.weekly.missions.has("big_fish") and routines.weekly.missions.has("many_fish"), "4: três rotinas de pesca")
	for kind: String in ["daily", "weekly"]:
		for id: String in routines[kind].missions:
			var mission: Dictionary = routines[kind].missions[id]
			if str(mission.goal.key).begins_with("fish"):
				check(str(mission.requirements.rod) == "bamboo_rod", "4: %s exige a vara" % id)
				check(str(state.call("requirement_error", {})) == "", "4: base")
	_fresh()
	check(str(state.call("requirement_error", routines.daily.missions.fish.requirements)) != "", "4: sem vara a diária está fechada")
	check(str(state.call("requirement_error", routines.weekly.missions.many_fish.requirements)) != "", "4: sem vara a semanal está fechada")
	state.call("give_rod", "bamboo_rod")
	check(str(state.call("requirement_error", routines.daily.missions.fish.requirements)) == "", "4: com a vara a diária abre")
	# Contadores reais.
	var base: int = int(_p().stat("fish"))
	state.call("_count", "fish")
	state.call("_count", "fish")
	check(_p().stat("fish") - base == 2, "4: dois peixes cumprem a diária (alvo 2)")
	state.call("_count", "fish_size:large")
	check(_p().stat("fish_size:large") >= 1, "4: peixe grande cumpre a semanal")


# 5. Encomendas e petisco.
func _orders_and_treat() -> void:
	_fresh()
	var orders: Dictionary = db.get("progression").orders
	check(str(orders.bloblo_lambaris.customer) == "bloblo" and int(orders.bloblo_lambaris.rewards.coins) == 30 and int(orders.bloblo_lambaris.inputs.fish_lambari) == 4, "5: bloblo_lambaris")
	check(str(orders.nina_lambari_treats.customer) == "nina" and int(orders.nina_lambari_treats.rewards.coins) == 45 and int(orders.nina_lambari_treats.inputs.lambari_crunch) == 2, "5: nina_lambari_treats")
	check(str(state.call("order_error", "bloblo_lambaris")) != "", "5: sem vara a encomenda está fechada")
	state.call("give_rod", "bamboo_rod")
	state.call("dev_complete_quest", "first_harvest")
	state.call("_count", "noop")
	state.get("inventory").add("fish_lambari", 4)
	var before: int = int(state.get("coins"))
	check(str(state.call("fulfill_order", "bloblo_lambaris")) == "", "5: entrega dos lambaris: " + str(state.call("order_error", "bloblo_lambaris")))
	check(int(state.get("coins")) - before >= 30, "5: 30 moedas")
	# Petisco.
	var item: Dictionary = db.get("items").lambari_crunch
	check(bool(item.treat) and int(item.sell_price) == 14 and str(item.category) == "food", "5: petisco de lambari")
	check(item.growth.phases == ["teething", "explorer", "young", "adult"], "5: comida de crescimento nas quatro fases")
	check(int(item.feed.hunger) == 15 and int(item.feed.happiness) == 15, "5: fome 15 e felicidade 15")
	var recipe: Dictionary = db.get("recipes").lambari_crunch
	check(str(recipe.station) == "stove" and int(recipe.inputs.fish_lambari) == 3 and int(recipe.qty) == 2 and int(recipe.seconds) == 240, "5: receita 3 → 2 em 240 s no fogão")
	check(str(item.icon) != "" and ResourceLoader.exists(str(item.icon)), "5: ícone existe")
	check(str(orders.nina_lambari_treats.requirements.rod) == "bamboo_rod", "5: Nina pede com a vara")


# 6/7. Origem e Como fazer.
func _sources_and_help() -> void:
	var sources: Array = db.call("item_sources", "fish_tilapia")
	var lake := false
	for source: Dictionary in sources:
		if str(source.get("key", "")) == "fish:fish_tilapia":
			lake = true
	check(lake, "6: item_sources aponta a lagoa")
	var help = load("res://scripts/ui/task_help.gd")
	var info: Dictionary = help.describe("stat", "fish_size:large")
	check("barra" in str(info.get("detail", "")) and not info.target.is_empty(), "7: Como fazer do peixe grande com Ir")
