extends SceneTree
## Criações animal por animal: kit sem galinha, preços por quantidade, ampliação 2 -> 4, um lote por animal em paralelo,
## "alimentar todas" limitado pela ração e coleta única. Galinheiro e curral seguem a mesma regra.

var failures: int = 0
var state: Node
var database: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Criações por animal: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	state.call("reset")
	state.call("dev_jump_to_chapter", 13)
	state.call("dev_set_phase", "teething")
	state.call("dev_week_goto", 2)
	state.call("dev_complete_quest", "farm_deed")
	state.call("dev_grant_upgrade", "farm")
	state.call("dev_add_coins", 5000)
	state.set("unlimited_storage", true)
	_story()
	_coop()
	_parallel()
	_feed_all_with_limited_corn()
	_buy_during_batch()
	_remap()
	_barn()
	print("ANIMALS SLOTS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


## Missões novas e dados do kit.
func _story() -> void:
	var quests: Dictionary = database.get("quests")
	check(quests.has("week_hen") and quests.week_hen.goals[0].key == "buy_animal:chicken_coop", "missão week_hen compra a primeira galinha")
	check(int(quests.week_hen.chapter) == 4 and int(quests.week_hen.order) == 15, "week_hen entre o kit e o ovo")
	check(int(quests.week_eggs.goals[0].target) == 1, "o primeiro ovo pede 1 ovo")
	check(quests.has("bloblo_first_cow") and int(quests.bloblo_first_cow.order) == 105, "bloblo_first_cow antes do leite")
	var upgrades: Dictionary = database.get("progression").upgrades
	check(not upgrades.chicken_coop.has("gift_animal") and not upgrades.cow_barn.has("gift_animal"), "sem animal de presente")
	check(upgrades.has("chicken_coop_2") and upgrades.has("cow_barn_2"), "ampliações existem")


## Kit sem galinha; preços 30/50/80/120; capacidade 2 -> 4; contadores.
func _coop() -> void:
	check(state.call("buy_shop_item", "week_coop") == "", "kit do galinheiro")
	check(state.call("has_upgrade", "chicken_coop"), "kit constrói o galinheiro")
	check(state.call("animal_count", "chicken_coop") == 0, "o galinheiro chega vazio")
	check(state.call("station_slots", "chicken_coop") == 0, "sem animal, sem espaço de produção")
	state.get("inventory").add("corn", 20)
	check(state.call("cook_error", "eggs") != "", "sem galinha não alimenta")
	check(state.call("animal_price", "chicken_white") == 30, "primeira galinha custa 30")
	var coins: int = state.get("coins")
	check(state.call("buy_animal", "chicken_white") == "" and state.get("coins") == coins - 30, "compra a primeira por 30")
	check(state.call("animal_price", "chicken_white") == 50, "segunda custa 50")
	check(state.call("animal_price", "chicken_brown") == 70, "ruiva soma 20 ao preço da vez")
	check(state.call("buy_animal", "chicken_white") == "" and state.get("coins") == coins - 80, "compra a segunda por 50")
	check(state.call("animal_capacity", "chicken_coop") == 2, "o galinheiro começa com 2 lugares")
	check(state.call("buy_animal", "chicken_white") == "Abrigo cheio", "cheio recusa")
	check(state.get("coins") == coins - 80, "recusa não cobra")
	check(state.call("station_slots", "chicken_coop") == 2, "um espaço por animal")
	check(state.get("progress").stat("buy_animal:chicken_coop") == 2 and state.get("progress").stat("buy_animal") == 2, "contadores de compra")
	check((state.call("animal_pending_expansions", "chicken_coop") as Array) == ["chicken_coop_2"], "ampliação pendente")
	state.call("dev_grant_upgrade", "chicken_coop_2")
	check(state.call("animal_capacity", "chicken_coop") == 4, "ampliação leva a 4 lugares")
	check(state.call("animal_price", "chicken_white") == 80, "terceira custa 80")
	check(state.call("buy_animal", "chicken_white") == "", "compra a terceira")
	check(state.call("animal_price", "chicken_white") == 120, "quarta custa 120")
	check(state.call("buy_animal", "chicken_white") == "", "compra a quarta")
	check(state.call("buy_animal", "chicken_white") != "", "quatro é o limite")
	check(state.call("station_slots", "chicken_coop") == 4, "quatro espaços")
	check(int(state.call("animal_next_price", "chicken_coop")) == 120, "preço do próximo mostrado nos '+' (sem variedade extra)")


## Um lote por galinha, todos em paralelo; "alimentar uma de cada vez" tem tempos próprios.
func _parallel() -> void:
	var coop: RefCounted = state.call("station", "chicken_coop")
	coop.queue.clear()
	var corn_before: int = state.get("inventory").count("corn")
	check(state.call("cook_max", "eggs") == 4, "ração paga as quatro")
	check(state.call("cook_many", "eggs", 4) == "", "alimentar todas")
	check(coop.queue.size() == 4, "um lote por galinha")
	var slots: Array = []
	var finishes := {}
	for entry: Dictionary in coop.queue:
		slots.append(int(entry.slot))
		finishes[float(entry.ready_at)] = true
		check(int(entry.qty) == 2 and (entry.animals as Array).size() == 1, "cada lote é de uma galinha com 2 ovos")
	slots.sort()
	check(slots == [0, 1, 2, 3], "cada lote no seu animal")
	check(finishes.size() == 1, "todos terminam juntos")
	check(state.get("inventory").count("corn") == corn_before - 8, "2 milhos por galinha")
	check(state.call("cook_many", "eggs", 1) != "", "todas comendo: nada a alimentar")
	check(state.call("collect", "chicken_coop").is_empty(), "nada pronto antes do tempo")
	state.call("dev_advance_time", 900)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 8, "ovos certos, uma vez")
	check(state.call("collect", "chicken_coop").is_empty(), "sem duplicar")
	# Uma de cada vez: cada uma no seu tempo.
	check(state.call("cook_animal", "eggs", 0) == "", "alimenta só a galinha 0")
	check(state.call("cook_animal", "eggs", 0) == "Já está comendo", "a mesma não come duas vezes")
	check((state.call("animal_free_slots", "chicken_coop") as Array).size() == 3, "três livres")
	state.call("dev_advance_time", 450)
	check(state.call("cook_animal", "eggs", 1) == "", "alimenta a galinha 1 depois")
	var first: Dictionary = state.call("animal_batch", "chicken_coop", 0)
	var second: Dictionary = state.call("animal_batch", "chicken_coop", 1)
	check(absf(float(second.ready_at) - float(first.ready_at) - 450.0) < 5.0, "tempos próprios: a segunda termina 450 s depois")
	state.call("dev_advance_time", 450)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 2, "só a primeira ficou pronta")
	state.call("dev_advance_time", 450)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 2, "a segunda, no tempo dela")
	check(state.call("cook_animal", "eggs", 9) != "", "animal que não existe")


func _feed_all_with_limited_corn() -> void:
	var corn: int = state.get("inventory").count("corn")
	state.get("inventory").remove("corn", corn)
	state.get("inventory").add("corn", 2)
	check(state.call("cook_max", "eggs") == 1, "ração só para uma")
	check(state.call("cook_many", "eggs", 2) != "", "não alimenta duas sem ração")
	check(state.get("inventory").count("corn") == 2, "erro não consome")
	check(state.call("cook_many", "eggs", state.call("cook_max", "eggs")) == "", "alimentar todas com ração para 1")
	check(state.call("station", "chicken_coop").queue.size() == 1, "apenas um lote")
	check(state.get("inventory").count("corn") == 0, "gastou a ração paga")
	state.call("dev_advance_time", 900)
	state.call("collect", "chicken_coop")


## Galinha comprada durante um lote ganha espaço livre e pode ser alimentada.
func _buy_during_batch() -> void:
	state.call("reset")
	state.call("dev_jump_to_chapter", 13)
	state.call("dev_set_phase", "teething")
	state.call("dev_week_goto", 2)
	state.call("dev_grant_upgrade", "chicken_coop")
	state.call("dev_add_coins", 1000)
	state.get("inventory").add("corn", 20)
	check(state.call("buy_animal", "chicken_white") == "", "primeira galinha")
	check(state.call("cook_many", "eggs", 1) == "", "alimenta a única")
	var lot: Dictionary = state.call("animal_batch", "chicken_coop", 0)
	check(state.call("buy_animal", "chicken_white") == "", "compra a segunda durante o lote")
	check((state.call("animal_free_slots", "chicken_coop") as Array) == [1], "a nova está livre")
	check(state.call("animal_batch", "chicken_coop", 0) == lot, "o lote em andamento não muda")
	check(state.call("cook_many", "eggs", 1) == "", "alimenta a nova")
	var ready: Dictionary = state.call("animal_batch", "chicken_coop", 1)
	check(int(ready.slot) == 1 and (ready.animals as Array).size() == 1, "o lote novo é da galinha nova")
	state.call("dev_advance_time", 900)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 4, "dois lotes de 2 ovos")
	# O save guarda o animal de cada lote.
	state.call("cook_many", "eggs", 2)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	var restored: Array = state.call("station", "chicken_coop").queue
	check(restored.size() == 2 and int(restored[0].slot) == 0 and int(restored[1].slot) == 1, "lotes por animal sobrevivem ao save")


## O elenco é ordenado por variedade: comprar uma variedade "mais cedo" não troca o bicho do lote em andamento.
func _remap() -> void:
	state.call("reset")
	state.call("dev_jump_to_chapter", 13)
	state.call("dev_set_phase", "teething")
	state.call("dev_grant_upgrade", "chicken_coop")
	state.call("dev_grant_upgrade", "chicken_coop_2")
	state.call("dev_add_coins", 1000)
	state.get("inventory").add("corn", 20)
	state.set("animals", {"chicken_brown": 1})
	check(state.call("cook_many", "eggs", 1) == "", "alimenta a ruiva")
	check(int(state.call("animal_batch", "chicken_coop", 0).slot) == 0, "lote no espaço 0")
	check(state.call("buy_animal", "chicken_white") == "", "compra uma branca, que vem antes na ordem")
	var roster: Array = state.call("animal_roster", "chicken_coop")
	check(roster == ["chicken_white", "chicken_brown"], "a branca passa na frente no elenco")
	check(state.call("animal_batch", "chicken_coop", 1).animals == ["chicken_brown"], "o lote seguiu a ruiva para o espaço 1")
	check((state.call("animal_free_slots", "chicken_coop") as Array) == [0], "a branca nova está livre")


## Curral com a mesma regra: vazio, 80/120, ampliação 170/230, um lote por vaca.
func _barn() -> void:
	state.call("dev_grant_upgrade", "cow_barn")
	check(state.call("animal_count", "cow_barn") == 0, "o curral chega vazio")
	state.get("inventory").add("wheat", 20)
	check(state.call("animal_price", "cow_white") == 80, "primeira vaca custa 80")
	check(state.call("buy_animal", "cow_white") == "", "compra a primeira")
	check(state.call("animal_price", "cow_white") == 120, "segunda custa 120")
	check(state.call("buy_animal", "cow_white") == "", "compra a segunda")
	check(state.call("buy_animal", "cow_white") == "Abrigo cheio", "curral tem 2 lugares")
	state.call("dev_grant_upgrade", "cow_barn_2")
	check(state.call("animal_capacity", "cow_barn") == 4, "ampliação do curral leva a 4")
	check(state.call("animal_price", "cow_white") == 170, "terceira vaca custa 170")
	check(state.call("buy_animal", "cow_white") == "", "compra a terceira")
	check(state.call("animal_price", "cow_white") == 230, "quarta vaca custa 230")
	check(state.call("cook_many", "milk", 3) == "", "alimentar todas as vacas")
	var barn: RefCounted = state.call("station", "cow_barn")
	check(barn.queue.size() == 3, "um lote por vaca")
	state.call("dev_advance_time", 1800)
	check(state.call("collect", "cow_barn").get("milk", 0) == 6, "2 leites por vaca")
