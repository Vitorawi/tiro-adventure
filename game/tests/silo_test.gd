extends SceneTree
## Etapa 05 do plano de economia: espaço finito junto da primeira horta (Cesto da horta → Silo).
## Cobre: capacidades 16/32/56/88, colheita cheia sem pagar nada, "Tudo" parcial, silo grátis depois da
## primeira colheita, missão bloblo_silo (ordem 27), piso legado (40 não cai para 32) e estoque acima do teto.
## --headless --path game -s res://tests/silo_test.gd

var failures := 0
var state: Node
var database: Node
var toasts: Array[String] = []
var main: Control
var farm: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SILO: " + message)


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _progress() -> Object:
	return state.get("progress")


## Jogo novo logo depois de conhecer a vovó: sítio aberto, quatro canteiros emprestados, sem silo.
func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	_progress().owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")


func _materials(upgrade: Dictionary) -> String:
	var keys: Array = (upgrade.get("materials", {}) as Dictionary).keys()
	keys.sort()
	var text := ""
	for key: String in keys:
		text += "%s%d" % [key, int(upgrade.materials[key])]
	return text


func _ready_plot(index: int, crop: String = "carrot") -> void:
	check(state.call("plant", index, crop) == "", "planta %s no canteiro %d" % [crop, index])
	(state.get("plots") as Array)[index]["ready_at"] = 0.0


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	root.get_node("Events").toast_requested.connect(func(text: String) -> void: toasts.append(text))
	_capacities()
	_full_harvest()
	_free_silo()
	_quest_order()
	_legacy_saves()
	await _all_partial()
	print("SILO TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- capacidades ------------------------------------------------------------------------------

func _capacities() -> void:
	_fresh()
	check(bool(state.call("storage_active", "silo")), "jogo novo: o cesto já limita")
	check(int(state.call("storage_capacity", "silo")) == 16, "provisório = 16")
	check(state.call("storage_name", "silo") == "Cesto da horta", "nome antes do silo")
	check(int(state.call("storage_floor", "silo")) == 0, "jogo novo não tem piso legado")
	check(state.call("storage_of", "apple") == "silo" and state.call("storage_of", "carrot") == "silo", "maçã e cenoura moram no silo")
	check(state.call("storage_error", {"apple": 17}) != "" and state.call("storage_error", {"apple": 16}) == "", "a maçã conta no cesto")
	# Construído = 32 (não 40): o piso legado não vale para quem compra agora.
	_progress().owned["silo"] = true
	check(int(state.call("storage_capacity", "silo")) == 32, "silo construído = 32")
	check(state.call("storage_name", "silo") == "Silo", "depois do silo: Silo")
	_progress().owned["silo_2"] = true
	check(int(state.call("storage_capacity", "silo")) == 56, "silo_2 = 56")
	_progress().owned["silo_3"] = true
	check(int(state.call("storage_capacity", "silo")) == 88, "silo_3 = 88")
	state.call("_changed")
	check(int(state.call("storage_floor", "silo")) == 0, "comprar não cria piso legado")
	var upgrades: Dictionary = database.get("progression").upgrades
	check(int(upgrades.silo_2.storage_capacity) == 24 and int(upgrades.silo_3.storage_capacity) == 32, "ampliações somam só a diferença (24 e 32)")
	check(int(upgrades.silo_2.cost) == 100 and _materials(upgrades.silo_2) == "bolt1plank2", "silo_2: 100 moedas, tábua 2 e parafuso 1")
	check(int(upgrades.silo_3.cost) == 260 and _materials(upgrades.silo_3) == "bolt1brick2plank4", "silo_3: 260, tábua 4, tijolo 2, parafuso 1")
	check(upgrades.silo_2.requirements.quests == ["main_4_bench"] and upgrades.silo_3.requirements.quests == ["own_business"], "pré-requisitos de _2 e _3")
	check(database.get("progression").upgrades.has("silo_4"), "o _4 é da etapa 18")
	_progress().owned.erase("silo_2")
	_progress().owned.erase("silo_3")
	var preview: Dictionary = state.call("storage_upgrade_preview", "silo_2")
	check(int(preview.to) == 56, "prévia: silo_2 leva a 56 (%s)" % str(preview))


# --- colheita cheia ---------------------------------------------------------------------------

func _full_harvest() -> void:
	_fresh()
	state.get("inventory").add("carrot", 15)
	_ready_plot(0)
	toasts.clear()
	var coins := int(state.get("coins"))
	var harvests := int(_progress().stat("harvest"))
	var xp := int(state.get("player_xp")) if state.get("player_xp") != null else 0
	var error: String = state.call("harvest_error", 0)
	check(error == "Cesto da horta sem espaço: abra lugar para Cenoura ×1", "mensagem com a falta real (%s)" % error)
	check((state.call("harvest", 0) as Dictionary).is_empty(), "lote+1 não é colhido")
	check(state.call("plot_status", 0) == "ready", "planta madura continua pronta")
	check(_inv("carrot") == 15 and int(state.get("coins")) == coins and int(_progress().stat("harvest")) == harvests, "colheita rejeitada: sem item, moeda nem contador")
	check(toasts.size() == 1 and toasts[0] == error, "um aviso com o motivo")
	if state.get("player_xp") != null:
		check(int(state.get("player_xp")) == xp, "colheita rejeitada: sem XP")
	# Lote exato: 14 + 2 = 16 cabe.
	state.get("inventory").remove("carrot", 1)
	check(state.call("harvest_error", 0) == "", "lote exato cabe")
	check(not (state.call("harvest", 0) as Dictionary).is_empty() and _inv("carrot") == 16, "colhe o lote exato")
	check(int(_progress().stat("harvest")) == harvests + 1, "colheita aceita conta uma vez")
	# Vender libera espaço e a colheita volta a ser permitida.
	_ready_plot(1)
	check(state.call("harvest_error", 1) != "", "cheio de novo")
	check(state.call("sell", "carrot", 3) == "", "vender no cesto cheio funciona")
	check(state.call("harvest_error", 1) == "" and not (state.call("harvest", 1) as Dictionary).is_empty(), "depois de vender a colheita volta")
	# Comprar o silo CHEIO amplia mesmo com itens.
	_fresh()
	state.get("inventory").add("carrot", 16)
	state.call("dev_complete_quest", "first_harvest")
	check(state.call("upgrade_error", "silo") == "", "silo disponível depois da primeira colheita, sem material")
	var coins_before := int(state.get("coins"))
	check(state.call("buy_upgrade", "silo") == "" and int(state.get("coins")) == coins_before, "silo grátis")
	check(_inv("carrot") == 16 and int(state.call("storage_capacity", "silo")) == 32 and int(state.call("storage_space", "silo")) == 16, "comprar cheio amplia sem perder itens")


# --- silo grátis depois da primeira colheita ------------------------------------------------

func _free_silo() -> void:
	_fresh()
	check(state.call("upgrade_error", "silo") != "", "silo bloqueado antes da primeira colheita")
	var silo: Dictionary = database.get("progression").upgrades.silo
	check(int(silo.cost) == 0 and not silo.has("materials"), "silo não custa nada")
	check(silo.requirements.quests == ["first_harvest"], "silo só pede first_harvest (não mais a queijaria)")
	state.call("dev_complete_quest", "first_harvest")
	check(state.call("upgrade_error", "silo") == "", "first_harvest libera o silo")
	# Silo_2 pede a bancada (main_4_bench) e o estágio anterior.
	state.call("buy_upgrade", "silo")
	state.set("coins", 1000)
	state.get("inventory").add("plank", 2)
	state.get("inventory").add("bolt", 1)
	check(state.call("upgrade_error", "silo_2") != "", "silo_2 espera a bancada")
	state.call("dev_complete_quest", "main_4_bench")
	check(state.call("upgrade_error", "silo_2") == "", "silo_2 libera depois da bancada")
	var coins := int(state.get("coins"))
	check(state.call("buy_upgrade", "silo_2") == "" and int(state.get("coins")) == coins - 100 and int(state.call("storage_capacity", "silo")) == 56, "silo_2: 100 moedas e 56")


# --- missão ----------------------------------------------------------------------------------------

func _quest_order() -> void:
	var quest: Dictionary = database.get("quests").bloblo_silo
	check(int(quest.order) == 27 and quest.line == "bloblo" and quest.goals[0].key == "silo", "bloblo_silo: ordem 27, objetivo owned:silo")
	check(int(quest.rewards.coins) == 10 and not quest.rewards.has("items"), "bloblo_silo: 10 moedas, sem parafuso")
	var order := {}
	for id: String in ["bloblo_sell_surplus", "bloblo_dig", "bloblo_silo", "bloblo_more_crops"]:
		order[id] = int(database.get("quests")[id].order)
	check(order.bloblo_dig < order.bloblo_silo and order.bloblo_silo < order.bloblo_more_crops, "silo depois do faro e antes de mais colheitas")
	_fresh()
	state.call("dev_complete_quest", "bloblo_dig")
	check(_progress().current_line_quest("bloblo") == "bloblo_silo", "depois do faro vem o silo")
	# Quem já recebeu a missão não a perde nem repete.
	_progress().claimed_quests["bloblo_silo"] = true
	state.call("_changed")
	check(_progress().claimed_quests.has("bloblo_silo") and _progress().current_line_quest("bloblo") != "bloblo_silo", "recebida em save antigo continua recebida")


# --- saves antigos -------------------------------------------------------------------------------

func _v12(data: Dictionary) -> Dictionary:
	var copy: Dictionary = JSON.parse_string(JSON.stringify(data))
	copy.erase("economy")
	return copy


func _legacy_saves() -> void:
	# Silo antigo (capacidade 40): não cai para 32.
	_fresh()
	_progress().owned["silo"] = true
	state.get("inventory").add("carrot", 36)
	var old: Dictionary = _v12(state.call("to_dict"))
	state.call("from_dict", old)
	check(int(state.call("storage_floor", "silo")) == 40 and int(state.call("storage_capacity", "silo")) == 40, "silo antigo continua com 40")
	check(_inv("carrot") == 36 and state.call("storage_error", {"carrot": 4}) == "" and state.call("storage_error", {"carrot": 5}) != "", "40 vale até o fim")
	# Silo_2 antigo (80) é maior que o 56 novo.
	_fresh()
	_progress().owned["silo"] = true
	_progress().owned["silo_2"] = true
	state.call("from_dict", _v12(state.call("to_dict")))
	check(int(state.call("storage_capacity", "silo")) == 80, "silo_2 antigo mantém 80")
	# Sem silo e com 100 cenouras: o estoque é preservado, entradas bloqueiam, saídas funcionam.
	_fresh()
	state.get("inventory").add("carrot", 100)
	state.call("from_dict", _v12(state.call("to_dict")))
	check(_inv("carrot") == 100, "estoque de 100 preservado")
	check(int(state.call("storage_capacity", "silo")) == 16 and int(state.call("storage_excess", "silo")) == 84, "capacidade 16, excesso 84")
	check(state.call("storage_error", {"carrot": 1}) != "", "entradas bloqueadas")
	check(state.call("sell", "carrot", 10) == "" and _inv("carrot") == 90, "saída permitida (vender)")
	state.get("inventory").add("potato", 1)  # deixa claro que o excesso não some
	check(_inv("carrot") == 90, "nada some sozinho")
	_ready_plot(0)
	check(state.call("harvest_error", 0) != "", "acima do teto não colhe")


# --- "Tudo" parcial na bandeja da foice ---------------------------------------------------

func _all_partial() -> void:
	_fresh()
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("unlocked_plots", 9)
	state.get("inventory").counts.clear()
	_progress().owned.erase("silo")
	_progress().owned.erase("silo_2")
	_progress().owned.erase("silo_3")
	state.call("_changed")
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 4: await process_frame
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	for i in 4: await process_frame
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	farm = main.find_child("World_farm", true, false)
	farm.call("_animate_objects")
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	# Quatro cenouras prontas (2 cada = 8) com 14/16 no cesto: só um lote cabe, os outros três esperam.
	state.get("inventory").add("carrot", 14)
	for i in 4:
		_ready_plot(i)
	state.call("_changed")
	toasts.clear()
	var coins := int(state.get("coins"))
	var tray_script: Script = load("res://scripts/ui/plot_tray.gd")
	var sickle := tray_script.call("sickle", farm, 1) as Control
	await process_frame
	sickle.call("tap_item", "all")
	var ready := 0
	for i in 4:
		if state.call("plot_status", i) == "ready":
			ready += 1
	check(ready == 3, "Tudo: um lote coube, três continuam prontos (%d)" % ready)
	check(_inv("carrot") == 16, "Tudo: só o que cabe entrou (%d)" % _inv("carrot"))
	check(int(state.get("coins")) == coins + int(database.get("crops").carrot.get("coins", 0)), "Tudo: moedas só do lote colhido")
	var told := false
	for text in toasts:
		if text.begins_with("3 ficaram prontos"):
			told = true
	check(told, "Tudo comunica quantos ficaram prontos (%s)" % str(toasts))
	farm.call("close_tray")
	# Depois de vender, o resto volta a ser colhido.
	state.call("sell", "carrot", 8)
	sickle = tray_script.call("sickle", farm, 1) as Control
	await process_frame
	sickle.call("tap_item", "all")
	ready = 0
	for i in 4:
		if state.call("plot_status", i) == "ready":
			ready += 1
	check(ready == 0 or _inv("carrot") == 16, "vender abre espaço para colher mais")
	farm.call("close_tray")
