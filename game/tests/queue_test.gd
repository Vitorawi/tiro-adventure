extends SceneTree
## Etapa 12 do plano de economia: filas e "Preparar N".
## Cobre: tempos da tabela 02 D, ampliações (stove_queue 80, stove_queue_2 220+tábua 3, blender_queue 100+tábua 1),
## N = 1 / máximo / máximo+1, ingredientes que faltam no último lote (nada consumido), jobs encadeados com snapshot,
## recarregar no meio, colher primeiro e enfileirar outro, receitas diferentes, costura (output_collection) e animais
## comprados durante o lote, XP uma vez por recebimento, comparação de visitas e a interface de quantidade.
## --headless --path game -s res://tests/queue_test.gd

const T0 := 1791936000.0
const TABLE := {
	"carrot_snack": 60, "mashed_potato": 120, "vegetable_soup": 180, "pumpkin_mash": 300, "strawberry_juice": 120,
	"strawberry_pop": 180, "sweet_potato_chips": 600, "mint_snack": 240, "apple_biscuit": 480, "treat_box": 900,
	"plank": 120, "brick": 180, "hardwood_planks": 480, "fabric": 900, "accessory_set": 1800, "flour": 300,
	"eggs": 900, "milk": 1800, "cheese": 1200,
}

var failures := 0
var state: Node
var db: Node
var _visit_note := ""


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("QUEUE: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _station(id: String) -> RefCounted:
	return state.call("station", id)


func _advance(seconds: float) -> void:
	state.set("test_time", float(state.get("test_time")) + seconds)


## Dicionários de quantidades iguais, ignorando int × float (JSON).
func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in a:
		if not b.has(key) or int(a[key]) != int(b[key]):
			return false
	return true


func _roundtrip() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", true)
	state.call("reset")
	state.get("inventory").counts.clear()
	state.set("coins", 0)
	for id in ["stove", "stove_queue", "stove_queue_2", "workbench", "mill", "sewing_table", "blender", "blender_queue", "chicken_coop"]:
		_p().owned[id] = true
	for quest_id: String in db.get("quests"):
		if str(db.get("quests")[quest_id].get("kind", "")) == "main":
			_p().claimed_quests[quest_id] = true
	_p().claimed_quests["bloblo_potato"] = true


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	_data()
	_counts()
	_chain_and_reload()
	_collect_then_enqueue()
	_mixed_and_collection()
	_animals()
	_visits()
	_interface()
	_report()
	print("QUEUE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- dados ------------------------------------------------------------------------------------------

func _data() -> void:
	for id: String in TABLE:
		check(int(db.get("recipes")[id].seconds) == int(TABLE[id]), "%s: %d s" % [id, int(TABLE[id])])
	var r: Dictionary = db.get("recipes")
	check(int(r.apple_biscuit.qty) == 2 and int(r.flour.qty) == 2 and int(r.eggs.qty) == 2 and int(r.milk.qty) == 2, "biscoito, farinha, ovos e leite mantêm o rendimento 2")
	check(_same(r.apple_biscuit.inputs, {"apple": 2, "carrot_snack": 1}) and _same(r.flour.inputs, {"wheat": 3}), "ingredientes de biscoito e farinha intactos")
	check(int(r.sew_golden_cape.seconds) == 1200 and int(r.sew_flower_crown.seconds) == 300, "costura de coleção fica igual")
	var u: Dictionary = db.get("progression").upgrades
	check(int(u.stove_queue.cost) == 80 and not u.stove_queue.has("materials"), "stove_queue: 80 moedas, sem tábuas")
	check(u.stove_queue.requirements.quests == ["first_kitchen"], "stove_queue exige first_kitchen")
	check(int(u.stove_queue_2.cost) == 220 and _same(u.stove_queue_2.materials, {"plank": 3}), "stove_queue_2: 220 + tábua 3")
	check("workbench" in u.stove_queue_2.requirements.owned and "stove_queue" in u.stove_queue_2.requirements.owned, "stove_queue_2 exige bancada e a fila anterior")
	check(int(u.blender_queue.cost) == 100 and _same(u.blender_queue.materials, {"plank": 1}), "blender_queue: 100 + tábua 1")
	check("workbench" in u.blender_queue.requirements.owned and "blender" in u.blender_queue.requirements.owned, "blender_queue exige bancada")
	_fresh()
	check(int(state.call("station_slots", "stove")) == 3 and int(state.call("station_slots", "blender")) == 2, "fogão 3 e liquidificador 2 vagas com as ampliações")
	_p().owned.erase("blender_queue")
	check(int(state.call("station_slots", "blender")) == 1, "liquidificador começa com 1")
	check(int(state.call("station_slots", "chicken_coop")) == 1 and int(state.call("station_slots", "mill")) == 2, "criações e moinho não mudaram")


# --- N = 1, máximo, máximo+1, falta de ingrediente --------------------------------------------------

func _counts() -> void:
	_fresh()
	state.get("inventory").add("carrot", 20)
	check(int(state.call("cook_max", "carrot_snack")) == 3, "máximo = vagas livres (3)")
	check(state.call("cook_many", "carrot_snack", 1) == "", "N = 1")
	check(_inv("carrot") == 18 and _station("stove").queue.size() == 1, "N = 1 consome 2 cenouras e põe 1 trabalho")
	check(int(state.call("cook_max", "carrot_snack")) == 2, "depois de 1, máximo = 2")
	var before_q: int = _station("stove").queue.size()
	var before_c := _inv("carrot")
	check(state.call("cook_many", "carrot_snack", 3) != "", "N = máximo + 1 é recusado")
	check(_inv("carrot") == before_c and _station("stove").queue.size() == before_q, "recusa não consome nem enfileira nada")
	check(state.call("cook_many", "carrot_snack", 2) == "", "N = máximo")
	check(_inv("carrot") == 14 and _station("stove").queue.size() == 3, "N = máximo consome tudo e lota a fila")
	check(state.call("cook_many_error", "carrot_snack", 1) == "Fila cheia", "fila cheia")
	check(int(state.call("cook_max", "carrot_snack")) == 0, "máximo 0 com a fila cheia")
	check(state.call("cook_many", "carrot_snack", 0) != "", "N = 0 é recusado")
	# ingredientes insuficientes no último lote: 5 cenouras pagam 2 lotes, não 3
	_fresh()
	state.get("inventory").add("carrot", 5)
	check(int(state.call("cook_max", "carrot_snack")) == 2, "5 cenouras pagam 2 lotes")
	var error: String = state.call("cook_many", "carrot_snack", 3)
	check(error == "Falta Cenoura ×1", "falta no último lote: " + error)
	check(_inv("carrot") == 5 and _station("stove").queue.is_empty(), "sem meio lote: nada consumido, nada enfileirado")
	check(state.call("cook_many", "carrot_snack", 2) == "" and _inv("carrot") == 1, "2 lotes pagos exatamente")
	# receita de rendimento 2 (farinha) em duas vagas do moinho
	_fresh()
	state.get("inventory").add("wheat", 6)
	check(int(state.call("cook_max", "flour")) == 2 and state.call("cook_many", "flour", 2) == "" and _inv("wheat") == 0, "farinha: 2 lotes de 3 trigos")
	var queue: Array = _station("mill").queue
	check(queue.size() == 2 and int(queue[0].qty) == 2 and int(queue[1].qty) == 2, "cada lote de farinha rende 2")
	# biscoito: rendimento 2 e dois ingredientes diferentes
	_fresh()
	_p().owned["fridge"] = true
	state.get("inventory").add("apple", 6)
	state.get("inventory").add("carrot_snack", 2)
	check(int(state.call("cook_max", "apple_biscuit")) == 2, "biscoito: 2 lanches limitam em 2 lotes")
	check(state.call("cook_many", "apple_biscuit", 3) != "" and _inv("apple") == 6 and _inv("carrot_snack") == 2, "biscoito ×3 recusado sem consumir")
	check(state.call("cook_many", "apple_biscuit", 2) == "" and _inv("apple") == 2 and _inv("carrot_snack") == 0, "biscoito ×2: 4 maçãs e 2 lanches")
	_advance(2000.0)
	var got: Dictionary = state.call("collect", "stove")
	check(int(got.get("apple_biscuit", 0)) == 4, "biscoito rende 2 por lote (4)")


# --- tempos encadeados, snapshot e recarga ----------------------------------------------------------

func _chain_and_reload() -> void:
	_fresh()
	state.get("inventory").add("carrot", 6)
	check(state.call("cook_many", "carrot_snack", 3) == "", "3 lotes")
	var queue: Array = _station("stove").queue
	for i in 3:
		check(is_equal_approx(float(queue[i].ready_at), T0 + 60.0 * (i + 1)), "lote %d pronto em %d s" % [i + 1, 60 * (i + 1)])
		check(queue[i].has("job") and _same(queue[i].job.inputs, {"carrot": 2}) and int(queue[i].job.qty) == 1, "lote %d com snapshot próprio" % (i + 1))
	_roundtrip()
	queue = _station("stove").queue
	check(queue.size() == 3 and is_equal_approx(float(queue[2].ready_at), T0 + 180.0) and _same(queue[2].job.inputs, {"carrot": 2}), "recarregar no meio preserva horários e snapshots")
	_advance(130.0)
	check(int(_station("stove").ready_count(state.call("now"))) == 2, "aos 130 s, 2 lotes prontos")
	_roundtrip()
	var got: Dictionary = state.call("collect", "stove")
	check(int(got.get("carrot_snack", 0)) == 2 and _inv("carrot_snack") == 2, "colhe só os 2 prontos")
	check(_station("stove").queue.size() == 1 and is_equal_approx(float(_station("stove").queue[0].ready_at), T0 + 180.0), "o terceiro segue no horário (tempo acumulado correto)")
	_advance(60.0)
	got = state.call("collect", "stove")
	check(int(got.get("carrot_snack", 0)) == 1 and _inv("carrot_snack") == 3, "o terceiro sai depois")
	check(state.call("collect", "stove").is_empty(), "colher de novo não duplica")
	check(_inv("carrot") == 0, "ingredientes usados uma vez")
	# snapshot: mudar a receita depois não muda o que já está na fila
	_fresh()
	state.get("inventory").add("carrot", 4)
	state.call("cook_many", "carrot_snack", 2)
	db.get("recipes").carrot_snack.qty = 5
	_advance(200.0)
	got = state.call("collect", "stove")
	db.get("recipes").carrot_snack.qty = 1
	check(int(got.get("carrot_snack", 0)) == 2, "alterar a receita depois não muda lotes na fila")
	# XP por recebimento
	_fresh()
	state.get("inventory").add("carrot", 6)
	var total_before := _xp_total()
	state.call("cook_many", "carrot_snack", 3)
	check(_xp_total() == total_before, "preparar não dá XP")
	_advance(500.0)
	state.call("collect", "stove")
	var per_batch := int(db.get("xp").get("cook", 0))
	check(_xp_total() - total_before == 3 * per_batch, "XP do jogador entra por lote recebido (3 × %d)" % per_batch)
	check(int(_p().stat("produce:carrot_snack")) == 3, "contador de produção = 3")


## XP total comparável (o nível pesa muito mais que o XP dentro dele; os testes ficam longe de subir de nível).
func _xp_total() -> int:
	return int(state.get("level")) * 1000000 + int(state.get("xp"))


# --- colher primeiro e enfileirar outro --------------------------------------------------------------

func _collect_then_enqueue() -> void:
	_fresh()
	state.get("inventory").add("carrot", 10)
	state.call("cook_many", "carrot_snack", 3)
	check(state.call("cook_many", "carrot_snack", 1) == "Fila cheia", "fila cheia recusa mais um")
	_advance(70.0)
	check(state.call("cook_many", "carrot_snack", 1) == "Fila cheia", "um lote pronto e não pego continua ocupando a vaga")
	state.call("collect", "stove")
	check(int(state.call("station_free_slots", "stove")) == 1, "colher libera 1 vaga")
	check(state.call("cook_many", "carrot_snack", 1) == "", "enfileira outro depois de colher")
	var tail: Dictionary = _station("stove").queue.back()
	check(is_equal_approx(float(tail.ready_at), T0 + 180.0 + 60.0), "o novo começa quando o último termina (240 s)")
	_advance(1000.0)
	check(int(_station("stove").ready_count(state.call("now"))) == 3, "tudo pronto no fim")
	state.call("collect", "stove")
	check(_inv("carrot_snack") == 4, "4 lanches no total")


# --- receitas diferentes e costura ---------------------------------------------------------------------

func _mixed_and_collection() -> void:
	_fresh()
	state.get("inventory").add("carrot", 4)
	state.get("inventory").add("potato", 4)
	check(state.call("cook_many", "carrot_snack", 1) == "", "lanche na fila")
	check(state.call("cook_many", "mashed_potato", 2) == "", "purê ×2 depois (receitas diferentes na mesma fila)")
	var queue: Array = _station("stove").queue
	check(queue.size() == 3 and is_equal_approx(float(queue[1].ready_at), T0 + 60.0 + 120.0) and is_equal_approx(float(queue[2].ready_at), T0 + 60.0 + 240.0), "tempos encadeados com receitas diferentes")
	_advance(1000.0)
	state.call("collect", "stove")
	check(_inv("carrot_snack") == 1 and _inv("mashed_potato") == 2, "cada receita entrega a sua saída")
	# costura: coleção, sempre um
	_fresh()
	for id in ["wildflower", "ribbon"]:
		state.get("inventory").add(id, 10)
	check(int(state.call("cook_max", "sew_flower_crown")) == 1, "costura de coleção: máximo 1")
	check(state.call("cook_many", "sew_flower_crown", 2) != "", "costura ×2 é recusada")
	check(_inv("wildflower") == 10 and _station("sewing").queue.is_empty(), "recusa sem consumir")
	check(state.call("cook_many", "sew_flower_crown", 1) == "", "costura ×1 funciona")
	check(state.call("cook_many_error", "sew_flower_crown", 1) != "", "a mesma roupa não entra duas vezes")
	_advance(400.0)
	state.call("collect", "sewing")
	check(_p().collection.has("flower_crown") and _inv("flower_crown") == 0, "a roupa vai para a coleção, não para o inventário")


# --- animais comprados durante o lote ------------------------------------------------------------------

func _animals() -> void:
	_fresh()
	state.set("animals", {"chicken_white": 1})
	state.get("inventory").add("corn", 20)
	check(int(state.call("cook_max", "eggs")) == 1, "criação: um lote por vez")
	check(state.call("cook_many", "eggs", 2) != "", "criação ×2 recusada")
	check(state.call("cook_many", "eggs", 1) == "" and _inv("corn") == 18, "1 galinha: 2 milhos")
	var entry: Dictionary = _station("chicken_coop").queue[0]
	check(int(entry.qty) == 2 and int(entry.job.qty) == 2 and is_equal_approx(float(entry.ready_at), T0 + 900.0), "lote: 2 ovos em 900 s (duração do lote)")
	state.get("animals")["chicken_brown"] = 1
	_roundtrip()
	_advance(1000.0)
	var got: Dictionary = state.call("collect", "chicken_coop")
	check(int(got.get("egg", 0)) == 2, "galinha comprada durante o lote não entra nele")
	check(int(state.call("recipe_quantity", "eggs")) == 4, "o próximo lote já conta 2 galinhas")
	state.get("animals").erase("chicken_brown")


# --- comparação de visitas -----------------------------------------------------------------------------

func _visits() -> void:
	# 10 lanches (600 s de fogão). Com 1 vaga o jogador precisa de 10 visitas; com 3 vagas e "Preparar N", 4.
	# O tempo total de fogão é o mesmo: a fila poupa visitas, não acelera nada.
	_fresh()
	_p().owned.erase("stove_queue")
	_p().owned.erase("stove_queue_2")
	state.get("inventory").add("carrot", 20)
	var visits_one := 0
	var made := 0
	while made < 10:
		visits_one += 1
		state.call("cook_many", "carrot_snack", 1)
		_advance(60.0)
		made += int(state.call("collect", "stove").get("carrot_snack", 0))
	var elapsed_one := float(state.get("test_time")) - T0
	_fresh()
	state.get("inventory").add("carrot", 20)
	var visits_three := 0
	made = 0
	var queued := 0
	while made < 10:
		visits_three += 1
		var n := mini(int(state.call("cook_max", "carrot_snack")), 10 - queued)
		if n > 0:
			state.call("cook_many", "carrot_snack", n)
			queued += n
		_advance(180.0)
		made += int(state.call("collect", "stove").get("carrot_snack", 0))
	var elapsed_three := float(state.get("test_time")) - T0
	check(visits_one == 10 and visits_three == 4, "10 lanches: %d visitas com 1 vaga × %d com 3 vagas" % [visits_one, visits_three])
	check(elapsed_three >= 599.9 and elapsed_one >= 599.9, "o fogão continua levando 600 s: a fila não acelera (1 vaga %d s, 3 vagas %d s)" % [int(elapsed_one), int(elapsed_three)])
	_visit_note = "10 lanches de cenoura: 1 vaga = %d visitas (%d s); 3 vagas com Preparar N = %d visitas (%d s)." % [visits_one, int(elapsed_one), visits_three, int(elapsed_three)]


# --- interface (bandeja) -------------------------------------------------------------------------------

func _interface() -> void:
	_fresh()
	state.get("inventory").add("carrot", 10)
	var tray: Script = load("res://scripts/ui/station_tray.gd")
	tray.get("quantity").clear()
	var detail: Control = tray.call("recipe_detail", "stove", "carrot_snack")
	root.add_child(detail)
	check(detail.find_child("QuantityValue", true, false) != null and detail.find_child("FinishAt", true, false) != null, "seletor de quantidade e horário aparecem")
	check(str((detail.find_child("QuantityValue", true, false) as Label).text) == "×1", "começa em ×1")
	check((detail.find_child("Minus", true, false) as Button).disabled, "− desligado em ×1")
	var max_pill := detail.find_child("QuantityMax", true, false) as Button
	check(max_pill != null and max_pill.text == "Tudo", "Tudo (QuantityMax) ao lado do seletor com 2+ vagas livres")
	if max_pill:
		max_pill.pressed.emit()
		check(int(tray.call("chosen_count", "carrot_snack")) == int(state.call("cook_max", "carrot_snack")) and int(state.call("cook_max", "carrot_snack")) > 1, "Tudo leva ao máximo (×%d)" % int(state.call("cook_max", "carrot_snack")))
		tray.get("quantity").clear()
	check(_station("stove").queue.is_empty(), "só selecionar não começa a produção")
	detail.queue_free()
	tray.call("_set_count", "carrot_snack", 3)
	check(int(tray.call("chosen_count", "carrot_snack")) == 3, "escolhe ×3")
	tray.call("_set_count", "carrot_snack", 9)
	check(int(tray.call("chosen_count", "carrot_snack")) == 3, "limitado ao máximo (3)")
	detail = tray.call("recipe_detail", "stove", "carrot_snack")
	root.add_child(detail)
	var ing: Node = detail.find_child("Ingredients", true, false)
	check(ing != null and ing.get_children().filter(func(n: Node) -> bool: return n is Button).size() == 1, "ingredientes totais numa chip só")
	check(str((detail.find_child("Cook", true, false) as Button).text) == "Cozinhar ×3", "botão mostra ×3")
	detail.queue_free()
	# ingredientes que sobraram depois de gastar
	state.get("inventory").counts.clear()
	state.get("inventory").add("carrot", 2)
	check(int(tray.call("chosen_count", "carrot_snack")) == 1, "sem ingredientes para 3, a escolha volta a 1")
	# fila cheia: sem seletor, botão desligado
	state.get("inventory").add("carrot", 10)
	state.call("cook_many", "carrot_snack", 3)
	detail = tray.call("recipe_detail", "stove", "carrot_snack")
	root.add_child(detail)
	check(detail.find_child("Quantity", true, false) == null, "sem vaga livre não há seletor")
	check(detail.find_child("Cook", true, false) == null and detail.find_child("LockHint", true, false) != null, "sem botão verde com a fila cheia (aviso de fila cheia)")
	detail.queue_free()
	tray.get("quantity").clear()


# --- relatório de autonomia ------------------------------------------------------------------------------

func _short(seconds: int) -> String:
	return str(load("res://scripts/util/time_text.gd").call("short", seconds))


func _report() -> void:
	var lines: Array[String] = []
	lines.append("# Autonomia por estação (etapa 12)")
	lines.append("")
	lines.append("Fila cheia com a receita de MAIOR tempo de cada estação, com todas as ampliações da etapa 12 (a 18 acrescenta moinho/queijaria/ateliê).")
	lines.append("")
	lines.append("| Estação | Vagas | Receita (maior) | Fila ocupada | Produtos na volta | Toques para encher | Toques para pegar | Ingredientes reservados (valor de venda) |")
	lines.append("|---|---:|---|---:|---:|---:|---:|---:|")
	_fresh()
	state.set("animals", {"chicken_white": 1, "cow_white": 1})
	for station_id: String in ["stove", "blender", "workbench", "mill", "dairy", "atelier", "chicken_coop", "cow_barn"]:
		var slots := int(state.call("station_slots", station_id))
		var best := ""
		var best_seconds := 0
		for id in db.call("recipes_for", station_id):
			var seconds := int(db.get("recipes")[id].seconds)
			if seconds > best_seconds:
				best_seconds = seconds
				best = id
		if best == "":
			continue
		var recipe: Dictionary = db.get("recipes")[best]
		var value := 0
		for item: String in recipe.get("inputs", {}):
			value += int(recipe.inputs[item]) * int(db.get("items").get(item, {}).get("sell_price", 0))
		lines.append("| %s | %d | %s (%s) | %s | %d | 1 | 1 | %d moedas |" % [
			db.get("stations")[station_id].name, slots, db.call("item_name", db.call("recipe_output", recipe)), _short(best_seconds),
			_short(best_seconds * slots), int(recipe.get("qty", 1)) * slots, value * slots])
	lines.append("")
	lines.append("Toques para encher = 1 (Preparar N); para pegar = 1 (Pegar tudo). Criações e costura de coleção continuam um lote por vez (um lote cobre até 3 animais). Moinho, queijaria e ateliê ficam com 2 vagas até a etapa 18; a fila do fogão chega a 3 e a do liquidificador a 2.")
	lines.append("")
	lines.append("## Visitas")
	lines.append("")
	lines.append(_visit_note + " O tempo de fogão é o mesmo nos dois casos: a fila poupa visitas, não acelera nada.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_12"))
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_12/autonomia.md"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
		file.close()
	print("\n".join(lines))
