extends SceneTree
## Etapa 10 do plano de economia: colheitas para visitas curtas e para a volta.
## Cobre: tabela de tempos/saídas/XP, custos dos canteiros, tempo efetivo (normal x estufa) em UM só lugar,
## rega 30% uma vez, plantas exclusivas, snapshot de planta antiga, linha `flavors` independente da escritura,
## requisitos de cada cultura, mirtilos x silo_2 e a fila de sementes.
## --headless --path game -s res://tests/garden_test.gd

var failures := 0
var state: Node
var db: Node

const TABLE := {
	"carrot": [60, 2, 6], "potato": [300, 3, 16], "strawberry": [900, 4, 24], "pumpkin": [3600, 4, 35],
	"sweet_potato": [7200, 6, 45], "wheat": [600, 4, 18], "corn": [1200, 6, 24], "herbs": [7200, 6, 50], "blueberry": [14400, 8, 65],
}


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HORTA: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", true)
	state.get("inventory").counts.clear()
	state.set("coins", 0)
	_p().owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	_table()
	_plot_costs()
	_effective_time_and_water()
	_exclusive_crops()
	_snapshot()
	_flavors_line()
	_blueberry_fits()
	_long_batches()
	_seed_list()
	print("GARDEN TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _table() -> void:
	var crops: Dictionary = db.get("crops")
	for id: String in TABLE:
		var crop: Dictionary = crops[id]
		var row: Array = TABLE[id]
		check(int(crop.seconds) == int(row[0]), "%s: %d s" % [id, int(row[0])])
		var item_count := 0
		for item: String in crop.yield:
			item_count += int(crop.yield[item])
		check(item_count == int(row[1]), "%s: %d por lote" % [id, int(row[1])])
		check(int(crop.skill_xp) == int(row[2]), "%s: XP %d" % [id, int(row[2])])
		check(int(crop.get("coins", 0)) == 0, "%s continua sem moeda (etapa 09)" % id)
	check(crops.size() == TABLE.size(), "nenhuma cultura fora da tabela")
	# Requisitos não trocados continuam como estavam.
	check(crops.carrot.get("requirements", {}).is_empty(), "cenoura sem requisito")
	check(crops.potato.requirements.quests == ["bloblo_more_crops"], "batata libera depois de colher três vezes")
	check(crops.strawberry.requirements.quests == ["bloblo_dig"], "morango: bloblo_dig")
	check(crops.pumpkin.requirements.quests == ["bloblo_potato"], "abóbora: bloblo_potato")
	check(crops.sweet_potato.requirements.quests == ["farm_deed"], "batata-doce: farm_deed")
	check(str(crops.herbs.greenhouse) == "only" and str(crops.blueberry.greenhouse) == "only" and str(crops.strawberry.greenhouse) == "any", "estufa: ervas/mirtilo exclusivos, morango nos dois")


func _plot_costs() -> void:
	var costs: Array = db.get("farm").unlock_costs
	var ints: Array[int] = []
	for cost in costs:
		ints.append(int(cost))
	check(ints == [0, 0, 0, 0, 80, 140, 220, 340, 500], "custos dos cinco canteiros 80/140/220/340/500 (%s)" % str(costs))
	check(int(db.get("farm").initial_plots) == 4 and int(db.get("farm").plots) == 9 and int(db.get("farm").greenhouse_plots) == 4, "índices e quantidades intactos")
	_fresh()
	state.set("coins", 2000)
	for expected: int in [80, 140, 220, 340, 500]:
		var before: int = int(state.get("coins"))
		check(state.call("buy_plot", int(state.get("unlocked_plots"))) == "", "compra o próximo terreno")
		check(before - int(state.get("coins")) == expected, "terreno custou %d" % expected)
	check(int(state.get("unlocked_plots")) == 9, "nove terrenos comuns")


func _effective_time_and_water() -> void:
	_fresh()
	_p().owned["greenhouse"] = true
	state.call("dev_unlock_everything")
	state.set("unlimited_storage", true)
	var speed := float(db.get("farm").greenhouse_speed)
	check(is_equal_approx(speed, 0.7), "fator estufa 0,7")
	check(is_equal_approx(float(state.call("crop_seconds", 0, "pumpkin")), 3600.0), "tempo efetivo no canteiro comum")
	check(is_equal_approx(float(state.call("crop_seconds", 9, "strawberry")), 900.0 * 0.7), "tempo efetivo na estufa")
	var before: float = float(state.call("now"))
	check(state.call("plant", 0, "pumpkin") == "", "planta abóbora")
	var plot: Dictionary = (state.get("plots") as Array)[0]
	check(absf(float(plot.ready_at) - float(plot.planted_at) - 3600.0) < 0.01, "pronto em 1 h")
	check(state.call("water", 0) == "", "rega")
	var left: float = float(plot.ready_at) - float(state.call("now"))
	check(left > 3600.0 * 0.7 - 5.0 and left < 3600.0 * 0.7 + 1.0, "rega tira 30%% do que falta (%.1f)" % left)
	check(state.call("water", 0) != "", "segunda rega recusada")
	var kept: float = float(plot.ready_at)
	# Salvar e carregar não compõe o bônus de novo.
	var data: Dictionary = state.call("to_dict")
	state.call("from_dict", data)
	check(absf(float(((state.get("plots") as Array)[0] as Dictionary).ready_at) - kept) < 0.01, "carregar não reaplica a rega")
	check(state.call("plant", 9, "strawberry") == "", "planta morango na estufa")
	var house: Dictionary = (state.get("plots") as Array)[9]
	check(absf(float(house.ready_at) - float(house.planted_at) - 630.0) < 0.01, "morango na estufa: 630 s")
	check(state.call("water", 9) == "", "rega na estufa")
	var house_left: float = float(house.ready_at) - float(state.call("now"))
	check(house_left < 630.0 * 0.7 + 1.0, "estufa + rega = 0,7 x 0,7 do tempo (%.1f)" % house_left)
	# O rendimento da colheita não muda com a rega.
	house.ready_at = 0.0
	var got: Dictionary = state.call("harvest", 9)
	check(int(got.get("strawberry", 0)) == 4, "regar não aumenta o rendimento")
	check(before > 0.0, "relógio disponível")


func _exclusive_crops() -> void:
	_fresh()
	_p().owned["greenhouse"] = true
	state.call("dev_unlock_everything")
	_p().stats["treasure"] = 1
	state.set("unlimited_storage", true)
	check(state.call("plant_error", 0, "herbs") == "Esta planta só cresce na estufa", "ervas não crescem no sítio")
	check(state.call("plant_error", 0, "blueberry") != "", "mirtilo não cresce no sítio")
	check(state.call("plant_error", 9, "carrot") == "A estufa é para plantas delicadas", "cenoura não vai para a estufa")
	check(state.call("plant_error", 9, "pumpkin") != "", "abóbora não vai para a estufa")
	for id: String in ["herbs", "blueberry", "strawberry"]:
		check(state.call("plant_error", 9, id) == "", "%s planta na estufa" % id)
	for id: String in ["carrot", "potato", "strawberry", "pumpkin", "sweet_potato", "wheat", "corn"]:
		check(state.call("plant_error", 1, id) == "", "%s planta no sítio" % id)
	# Todas colhem o que a tabela promete.
	for id: String in TABLE:
		var index := 9 if str(db.get("crops")[id].get("greenhouse", "")) == "only" else 1
		check(state.call("plant", index, id) == "", "%s plantada" % id)
		(state.get("plots") as Array)[index].ready_at = 0.0
		var got: Dictionary = state.call("harvest", index)
		var total := 0
		for item: String in got:
			total += int(got[item])
		check(total == int(TABLE[id][1]), "%s colhe %d" % [id, int(TABLE[id][1])])


func _snapshot() -> void:
	_fresh()
	check(state.call("plant", 0, "carrot") == "", "carrot plantada antes da troca")
	var crops: Dictionary = db.get("crops")
	var saved: Dictionary = (crops.carrot as Dictionary).duplicate(true)
	crops.carrot.yield = {"carrot": 9}
	crops.carrot.skill_xp = 99
	(state.get("plots") as Array)[0].ready_at = 0.0
	var got: Dictionary = state.call("harvest", 0)
	crops.carrot = saved
	check(int(got.get("carrot", 0)) == 2, "planta antiga entrega o que valia ao plantar (%s)" % str(got))


func _flavors_line() -> void:
	var quests: Dictionary = db.get("quests")
	var expected := {"bloblo_strawberry": 10, "bloblo_pumpkin": 20, "bloblo_sweet_potato": 30}
	for id: String in expected:
		check(str(quests[id].line) == "flavors" and str(quests[id].npc) == "bloblo" and int(quests[id].order) == int(expected[id]), "%s na linha flavors, ordem %d" % [id, int(expected[id])])
		var req: Array = quests[id].requirements.quests
		check("first_kitchen" in req, "%s entra depois de first_kitchen" % id)
	check("farm_deed" in quests.bloblo_sweet_potato.requirements.quests, "batata-doce também exige farm_deed")
	check(quests.bloblo_strawberry.rewards.coins == 15 and quests.bloblo_pumpkin.rewards.coins == 20 and quests.bloblo_sweet_potato.rewards.coins == 25, "recompensas preservadas")
	_fresh()
	var progress := _p()
	progress.claimed_quests["lais_welcome"] = true
	# A linha da Bloblo segue até a escritura sem passar por nenhum sabor.
	var path: Array[String] = []
	for id: String in progress.line_quests("bloblo"):
		path.append(id)
	check("bloblo_pumpkin" not in path and "bloblo_strawberry" not in path and "bloblo_sweet_potato" not in path, "nenhum sabor na linha principal da Bloblo")
	check(path.find("bloblo_stew") >= 0 and path.find("farm_deed") == path.find("bloblo_chew_ring") + 1 and path.find("bloblo_chew_ring") == path.find("bloblo_stew") + 1, "ensopado, argolinha (etapa 10) e escritura em sequência")
	var after_stew := path.slice(path.find("farm_deed") + 1)
	check(not after_stew.is_empty() and not ("bloblo_pumpkin" in after_stew), "animais seguem a escritura")
	# Com a escritura pronta e o sabor ainda aberto, a escritura é o passo ativo da linha principal.
	for id: String in path:
		if id == "farm_deed":
			break
		progress.claimed_quests[id] = true
	check(progress.current_line_quest("bloblo") == "farm_deed", "escritura é o passo ativo")
	check(progress.current_line_quest("flavors") == "", "sabores esperam first_kitchen")
	progress.claimed_quests["first_kitchen"] = true
	check(progress.current_line_quest("flavors") == "bloblo_strawberry", "primeiro sabor: morango")
	progress.claimed_quests["bloblo_strawberry"] = true
	check(progress.current_line_quest("flavors") == "bloblo_pumpkin", "depois, abóbora")
	progress.claimed_quests["bloblo_pumpkin"] = true
	check(progress.current_line_quest("flavors") == "", "batata-doce espera a escritura")
	progress.claimed_quests["farm_deed"] = true
	check(progress.current_line_quest("flavors") == "bloblo_sweet_potato", "com a escritura, batata-doce")
	# Plantar não depende de terminar a missão de colher a própria planta.
	_fresh()
	var plant_ok := true
	for id: String in ["strawberry", "pumpkin", "sweet_potato"]:
		var req: Dictionary = db.get("crops")[id].requirements
		for q: String in req.get("quests", []):
			if q in ["bloblo_strawberry", "bloblo_pumpkin", "bloblo_sweet_potato"]:
				plant_ok = false
	check(plant_ok, "nenhuma cultura exige a missão de colher ela mesma")
	# Missão já recebida continua recebida ao mudar de linha.
	progress.claimed_quests["bloblo_pumpkin"] = true
	check(progress.claimed_quests.has("bloblo_pumpkin") and str(quests.bloblo_pumpkin.line) == "flavors", "recebida segue recebida")


func _blueberry_fits() -> void:
	_fresh()
	_p().owned["silo"] = true
	_p().owned["silo_2"] = true
	check(int(state.call("storage_capacity", "silo")) == 56, "silo_2 = 56")
	var per_lot := 0
	for item: String in db.get("crops").blueberry.yield:
		per_lot += int(db.get("crops").blueberry.yield[item])
	check(per_lot * 4 == 32, "quatro mirtilos = 32 unidades")
	state.set("unlimited_storage", false)
	state.get("inventory").add("carrot", 24)
	check(state.call("storage_shortage", {"blueberry": 32}).is_empty(), "32 mirtilos cabem com reserva de 24")
	state.get("inventory").add("carrot", 1)
	check(not state.call("storage_shortage", {"blueberry": 32}).is_empty(), "25 reservados já não cabem")
	# Cenoura: duas rodadas de quatro canteiros cabem no cesto provisório (16).
	_fresh()
	state.set("unlimited_storage", false)
	check(int(state.call("storage_capacity", "silo")) == 16, "cesto provisório 16")
	check(state.call("storage_shortage", {"carrot": 16}).is_empty() and not state.call("storage_shortage", {"carrot": 17}).is_empty(), "duas rodadas de cenoura cabem; a terceira não")

## Quatro lotes longos com reserva de 24 no silo_2: colher, vender e replantar sem recusar nada.
func _long_batches() -> void:
	_fresh()
	_p().owned["greenhouse"] = true
	state.call("dev_unlock_everything")
	_p().stats["treasure"] = 1
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	state.get("inventory").add("carrot", 24)
	_p().owned.erase("silo_3")
	_p().owned.erase("silo_4")
	_p().owned.erase("silo_5")
	check(int(state.call("storage_capacity", "silo")) == 56, "silo_2 = 56 (sem a terceira ampliação)")
	for round in 2:
		for index in range(9, 13):
			check(state.call("plant", index, "blueberry") == "", "rodada %d: mirtilo no canteiro %d" % [round, index])
		for index in range(9, 13):
			(state.get("plots") as Array)[index].ready_at = 0.0
		for index in range(9, 13):
			check(state.call("harvest_error", index) == "", "rodada %d: colheita %d cabe" % [round, index])
			state.call("harvest", index)
		check(state.get("inventory").count("blueberry") == 32, "rodada %d: 32 mirtilos guardados" % round)
		check(state.get("inventory").count("carrot") == 24, "reserva de 24 intacta")
		check(state.call("sell", "blueberry", 32) == "" and state.get("inventory").count("blueberry") == 0, "vende o lote")
	# Culturas curtas comuns: quatro lotes de milho (24) cabem com reserva no silo_2.
	for index in range(0, 4):
		check(state.call("plant", index, "corn") == "", "milho %d" % index)
		(state.get("plots") as Array)[index].ready_at = 0.0
		state.call("harvest", index)
	check(state.get("inventory").count("corn") == 24, "quatro milhos = 24 unidades")

func _seed_list() -> void:
	_fresh()
	_p().owned["greenhouse"] = true
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	for pair: Array in [[0, "carrot", 60], [0, "pumpkin", 3600], [9, "strawberry", 630]]:
		var picker: Control = builder.call("seed_picker", int(pair[0]), str(pair[1]))
		root.add_child(picker)
		var texts: Array[String] = []
		_labels(picker, texts)
		var joined := " ".join(texts)
		var shown: String = load("res://scripts/util/time_text.gd").call("short", int(pair[2]))
		check(joined.contains(shown), "%s no canteiro %d mostra %s (%s)" % [pair[1], int(pair[0]), shown, joined])
		picker.queue_free()


func _labels(node: Node, result: Array[String]) -> void:
	if node is Label:
		result.append((node as Label).text)
	for child: Node in node.get_children():
		_labels(child, result)
