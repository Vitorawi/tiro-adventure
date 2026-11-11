extends SceneTree
## Motor da pesca (etapa 01): varas, isca, arremesso, fisgada, sorteio, tamanho, recorde, bolhas e save.
## Relógio injetado (friend_clock) e sem SaveManager: nada toca o disco.

var state: Node
var db: Node
var events: Node
var failures := 0
var t := 1791936000.0
var log: Array = []  # capturas: {fish, cm, cls, previous}


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Pesca: " + message)


func _tick(seconds: float) -> void:
	t += seconds
	state.set("test_time", t)


func _fishing() -> RefCounted:
	return state.get("fishing")


func _inv() -> RefCounted:
	return state.get("inventory")


func _fresh(with_rod: bool = true) -> void:
	state.call("reset")
	log.clear()
	if with_rod:
		state.call("dev_give_rod", "bamboo_rod")  # também encerra o tutorial


## Lança, espera a mordida e fisga. Devolve o erro (vazio = fisgou).
func _start(bait: String = "bait_worm", zone: int = 1, on_bubble: bool = false) -> String:
	if _inv().count(bait) < 3:
		_inv().add(bait, 5)
	var error: String = state.call("cast", bait, zone, on_bubble)
	if error != "":
		return error
	_tick(float(_fishing().cast.wait) + 0.1)
	return state.call("hook")


func _drain_fish() -> void:
	for id: String in db.get("fishing").fish:
		_inv().remove(id, _inv().count(id))


## Pesca completa e esvazia a geladeira; devolve a captura registrada ({} se falhou).
func _catch(score: float, perfect: bool = false, zone: int = 1) -> Dictionary:
	if _start("bait_worm", zone) != "":
		return {}
	var before := log.size()
	var error: String = state.call("finish_fishing", {"caught": true, "score": score, "perfect": perfect, "chest": false})
	_drain_fish()
	return log[before] if error == "" and log.size() > before else {}


func _on_caught(fish_id: String, cm: float, cls: String, previous: float) -> void:
	log.append({"fish": fish_id, "cm": cm, "cls": cls, "previous": previous})


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", t)
	events.connect("fish_caught", _on_caught)
	var config: Dictionary = db.get("fishing")
	# O catálogo real tem bar_base alto (ajuste do Vitor); o caso 15 mede a soma, então usa a base original.
	var original_base: float = config.physics.bar_base

	# 1. Sem vara.
	_fresh(false)
	check(state.call("fishing_error") != "", "1: sem vara explica")
	check(state.call("cast_error", "bait_worm", 1) != "", "1: cast sem vara explica")
	check(state.call("requirement_error", {"rod": "bamboo_rod"}) != "", "1: requisito rod explica")
	state.call("dev_give_rod", "bamboo_rod")
	check(state.call("requirement_error", {"rod": "bamboo_rod"}) == "", "1: requisito rod cumprido com a vara")

	# 2. Com vara e sem isca; cast não gasta.
	_fresh()
	check(state.call("cast_error", "bait_worm", 1) == "Sem minhoca", "2: sem isca diz 'Sem minhoca'")
	_inv().add("bait_worm", 3)
	check(state.call("cast", "bait_worm", 1) == "", "2: lança com isca")
	check(_inv().count("bait_worm") == 3 and _fishing().cast.state == "waiting", "2: cast não gasta a isca")
	check(state.call("cast_error", "bait_worm", 1) != "", "2: segunda partida enquanto há uma é recusada")
	check(not state.call("bite_due"), "2: ainda não mordeu")
	check(state.call("hook_error") == "Ainda não mordeu", "2: fisgar antes da hora é recusado")

	# 3. miss_bite não gasta, hook gasta 1, cancel devolve.
	state.call("miss_bite")
	check(_fishing().cast.is_empty() and _inv().count("bait_worm") == 3, "3: miss_bite limpa sem gastar")
	check(_start() == "" and _inv().count("bait_worm") == 2, "3: hook gasta 1 isca")
	check(_fishing().cast.state == "fighting" and str(_fishing().cast.fish) != "", "3: luta com peixe sorteado")
	state.call("cancel_fishing")
	check(_inv().count("bait_worm") == 3 and _fishing().cast.is_empty(), "3: cancel devolve a isca gasta")

	# 4. Mesma semente = mesmo peixe e tamanho; reabrir mantém o peixe.
	_fresh()
	check(_start() == "", "4: fisgou")
	var cast_copy: Dictionary = _fishing().cast.duplicate(true)
	var fish_id: String = cast_copy.fish
	check(state.call("_pick_fish", cast_copy) == state.call("_pick_fish", cast_copy), "4: sorteio do peixe é determinístico")
	var result := {"caught": true, "score": 0.5, "perfect": false}
	var size_a: Dictionary = state.call("_fishing_size", cast_copy, result)
	var size_b: Dictionary = state.call("_fishing_size", cast_copy, result)
	check(size_a.cm == size_b.cm and size_a.class == size_b.class, "4: mesma semente, mesmo tamanho")
	var bait_before: int = _inv().count("bait_worm")
	var saved: Dictionary = state.call("to_dict")
	check(saved.has("fishing"), "4: o save tem a chave fishing")
	state.call("from_dict", saved)
	check(_fishing().cast.fish == fish_id, "4: reabrir não troca o peixe")
	check(_fishing().cast.state == "interrupted" and _inv().count("bait_worm") == bait_before + 1, "4: luta interrompida devolve a isca")
	check(state.call("cast_error", "bait_worm", 1) == "", "4: partida interrompida não bloqueia a próxima")

	# 5. Iscas e varas.
	_fresh()
	_inv().add("bait_dough", 2)
	check(state.call("cast_error", "bait_dough", 1) != "", "5: vara 1 não usa massa")
	state.call("dev_give_rod", "angler_rod")
	_inv().add("bait_lure", 2)
	_inv().add("bait_worm", 2)
	for bait: String in ["bait_worm", "bait_dough", "bait_lure"]:
		check(state.call("cast_error", bait, 1) == "", "5: vara 3 aceita " + bait)
	check(state.call("choose_rod", "bamboo_rod") == "" and state.call("choose_bait", "bait_dough") != "", "5: escolher vara 1 recusa massa")
	check(state.call("choose_rod", "reel_rod") != "", "5: não escolhe vara que não tem")

	# 6. Tamanho, classes e quantidade. Nota 1 + perfeita: sempre Grande ou Gigante (Gigante depende da sorte).
	_fresh()
	var found_giant := false
	var all_large := true
	for i in 20:
		check(_start() == "", "6: fisgou " + str(i))
		var giant_id: String = _fishing().cast.fish
		check(state.call("finish_fishing", {"caught": true, "score": 1.0, "perfect": true, "chest": false}) == "", "6: entrega")
		var last: Dictionary = log.back()
		var def: Dictionary = config.fish[giant_id]
		all_large = all_large and last.cls in ["large", "giant"]
		check(last.cm >= float(def.cm[0]) and last.cm <= float(def.cm[1]) and is_equal_approx(fmod(last.cm * 2.0, 1.0), 0.0), "6: cm na faixa e múltiplo de 0,5")
		if last.cls == "giant":
			found_giant = true
			check(_inv().count(giant_id) == 2, "6: Gigante rende 2 peixes")
			break
		check(_inv().count(giant_id) == 1, "6: Grande rende 1 peixe")
		_drain_fish()
	check(all_large and found_giant, "6: perfeita dá Grande+ e o Gigante aparece")
	_drain_fish()
	var small := _catch(0.0)
	check(small.get("cls", "") in ["small", "medium"], "6: nota 0 dá Pequeno ou Médio")

	# 7. Garantia depois de 8 sem Grande+.
	_fresh()
	var all_small := true
	for i in 8:
		var got := _catch(0.0)
		all_small = all_small and got.get("cls", "large") in ["small", "medium"]
	check(all_small, "7: 8 capturas fracas seguidas")
	check(_fishing().since_large == 8, "7: contador chegou a 8")
	var ninth := _catch(0.0)
	check(ninth.get("cls", "small") in ["large", "giant"], "7: a 9ª é Grande+")
	check(_fishing().since_large == 0, "7: o contador zera")

	# 8. Geladeira cheia: nada muda, a partida continua; liberar e repetir entrega uma vez; soltar encerra.
	_fresh()
	check(_start() == "", "8: fisgou")
	var full_id: String = _fishing().cast.fish
	while state.call("storage_error", {full_id: 1}) == "":
		_inv().add("fish_lambari", 1)
	var held: int = _inv().count("fish_lambari") + _inv().count(full_id)
	var full_error: String = state.call("finish_fishing", {"caught": true, "score": 0.5, "perfect": false, "chest": false})
	check(full_error != "", "8: cheia devolve o erro (" + full_error + ")")
	check(_fishing().cast.state == "fighting" and _fishing().cast.has("pending_result"), "8: partida continua com o resultado guardado")
	check(_inv().count("fish_lambari") + _inv().count(full_id) == held and _fishing().xp == 0 and _fishing().records.is_empty(), "8: nada mudou")
	_inv().remove("fish_lambari", _inv().count("fish_lambari"))
	check(state.call("finish_fishing", {"caught": true, "score": 0.0, "perfect": false}) == "", "8: com espaço, entrega")
	check(_fishing().cast.is_empty() and state.get("progress").stat("fish") == 1, "8: entregou uma vez só")
	_drain_fish()
	check(_start() == "", "8: nova partida")
	var release_id: String = _fishing().cast.fish
	while state.call("storage_error", {release_id: 1}) == "":
		_inv().add("fish_lambari", 1)
	state.call("finish_fishing", {"caught": true, "score": 0.5, "perfect": false})
	var count_before: int = _inv().count(release_id)
	check(state.call("release_fish") == "" and _fishing().cast.is_empty(), "8: soltar encerra")
	check(_inv().count(release_id) == count_before and state.get("progress").stat("fish") == 1, "8: soltar não dá prêmio")
	check(state.call("release_fish") != "", "8: sem peixe para soltar")
	_drain_fish()

	# 9 e 10. Recorde só sobe; contagem por captura; contadores.
	_fresh()
	var first := {}
	for i in 30:
		first = _catch(1.0, true)
		if first.get("cls", "") == "giant":
			break
	check(first.get("cls", "") == "giant", "9: um Gigante apareceu")
	var species: String = first.fish
	var rec: Dictionary = _fishing().record(species)
	check(rec.gigantes == 1 and rec.perfects >= 1, "9: Gigante conta 1 captura (" + str(rec) + ")")
	var best: float = rec.best_cm
	var again := {}
	for i in 40:
		again = _catch(0.0)
		if not again.is_empty() and again.fish == species:
			break
	check(again.get("fish", "") == species, "9: pegou a mesma espécie de novo")
	rec = _fishing().record(species)
	check(rec.best_cm >= best and rec.count >= 2, "9: recorde só sobe, contagem por captura")
	check(again.get("previous", -1.0) == best, "9: o evento traz o recorde anterior")
	var progress: RefCounted = state.get("progress")
	var total_caught: int = log.size()
	check(progress.stat("fish") == total_caught and progress.stat("fish:" + species) == rec.count, "10: contadores fish e fish:<id>")
	check(progress.stat("fish_size:giant") == 1 and progress.stat("fish_size:large") >= 1, "10: Gigante também soma em fish_size:large")
	check(progress.stat("fish_perfect") >= 1 and progress.stat("fish_gigante") == 1, "10: fish_perfect e fish_gigante")

	# 11. Primeira espécie dá 1 momento de Coragem; a repetida não.
	_fresh()
	var moments_before: int = state.get("progress").stat("moment:brave")
	var one := _catch(0.5)
	check(state.get("progress").stat("moment:brave") == moments_before + 1, "11: a primeira espécie dá 1 momento de Coragem")
	var after_first: int = state.get("progress").stat("moment:brave")
	var repeat := {}
	for i in 40:
		repeat = _catch(0.5)
		if not repeat.is_empty() and repeat.fish == one.fish:
			break
	check(repeat.get("fish", "") == one.fish, "11: repetiu a espécie")
	# Espécies novas no meio do caminho também contam; a repetida em si não soma.
	var species_seen: int = _fishing().records.size()
	check(state.get("progress").stat("moment:brave") == after_first + (species_seen - 1), "11: só espécie nova dá momento")

	# 12. Tilápia garantida até a 3ª pesca; tutorial sempre lambari e espera fixa.
	_fresh()
	var picks: Array = []
	for i in 3:
		check(_start() == "", "12: fisgou " + str(i))
		picks.append(str(_fishing().cast.fish))
		state.call("cancel_fishing")
	check("fish_tilapia" in picks, "12: tilápia nas três primeiras pescas com minhoca")
	_fresh()
	_fishing().tutorial["done"] = false
	var lambari_only := true
	for i in 3:
		_inv().add("bait_worm", 2)
		check(state.call("cast", "bait_worm", 1) == "" and is_equal_approx(float(_fishing().cast.wait), float(config.cast.tutorial_wait)), "12: tutorial espera fixa")
		_tick(float(_fishing().cast.wait) + 0.1)
		check(state.call("hook") == "", "12: tutorial fisga")
		lambari_only = lambari_only and _fishing().cast.fish == "fish_lambari"
		state.call("cancel_fishing")
	check(lambari_only, "12: tutorial sempre lambari")

	# 13. Dormindo e passeando.
	_fresh()
	state.get("dog").sleeping = true
	check(state.call("fishing_error") == "Ele está dormindo", "13: dormindo")
	check(state.call("cast_error", "bait_worm", 1) != "", "13: cast dormindo")
	state.get("dog").sleeping = false
	state.get("walk_state").current = {"ready_at": t + 3600.0}
	check(state.call("fishing_error") == state.call("away_text"), "13: passeando")
	state.get("walk_state").current = {}
	check(state.call("fishing_error") == "", "13: livre de novo")

	# 14. Bolha pelo relógio: nasce, dá espera menor e +1 zona, some.
	_fresh()
	check(_fishing().bubble.is_empty() and _fishing().next_bubble_at > t, "14: sem bolha, próxima marcada")
	_tick(_fishing().next_bubble_at - t + 1.0)
	check(state.call("update_fishing") and not _fishing().bubble.is_empty(), "14: a bolha nasce pelo relógio")
	check(int(_fishing().bubble.spot) >= 0 and int(_fishing().bubble.spot) < int(config.bubbles.spots), "14: ponto da bolha válido")
	_inv().add("bait_worm", 3)
	check(state.call("cast", "bait_worm", 1, true) == "", "14: lança na bolha")
	check(_fishing().cast.zone == 2 and float(_fishing().cast.wait) <= float(config.cast.wait[1]) * float(config.bubbles.wait_mult) + 0.001, "14: espera menor e +1 zona")
	state.call("miss_bite")
	_tick(float(config.bubbles.lasts_min) * 60.0)
	state.call("update_fishing")
	check(_fishing().bubble.is_empty(), "14: a bolha some")
	_fresh()
	_tick(100000.0)
	state.call("from_dict", state.call("to_dict"))
	check(_fishing().bubble.is_empty() or _fishing().bubble.until > t, "14: bolha vencida com o app fechado não volta")

	# 15. XP e nível mudam a barra; Tiro animado aumenta; vara ajuda; teto respeitado.
	config.physics.bar_base = 0.169
	_fresh()
	state.call("dev_fill_needs")  # o relógio já andou: sem necessidade pedindo, o Tiro está animado
	state.get("dog").sleeping = true
	var base_bar: float = state.call("fishing_bar_height")
	state.get("dog").sleeping = false
	check(is_equal_approx(float(state.call("fishing_bar_height")), base_bar + float(config.physics.animated_bonus)), "15: Tiro animado aumenta a barra")
	state.get("dog").sleeping = true
	state.call("dev_fish_xp", 30)
	check(state.call("fishing_level") == 2 and is_equal_approx(float(state.call("fishing_bar_height")), base_bar + float(config.physics.bar_per_level)), "15: o nível aumenta a barra")
	state.call("dev_give_rod", "angler_rod")
	check(is_equal_approx(float(state.call("fishing_bar_height")), base_bar + float(config.physics.bar_per_level) + 0.05), "15: a vara soma o bônus")
	config.physics.bar_base = 0.5
	check(is_equal_approx(float(state.call("fishing_bar_height")), float(config.physics.bar_max)), "15: o teto bar_max vale")
	config.physics.bar_base = original_base
	state.get("dog").sleeping = false

	# 16. Catálogo.
	check((db.call("fishing_problems") as Array).is_empty(), "16: fishing_problems vazio: " + str(db.call("fishing_problems")))

	# Validação do resultado vindo da UI, baú e escape.
	_fresh()
	check(state.call("finish_fishing", {"caught": true, "score": 0.5}) != "", "extra: sem luta não termina")
	check(_start() == "", "extra: fisgou")
	for bad: Dictionary in [{"caught": true, "score": 1.5}, {"caught": true, "score": -0.1}, {"caught": "sim", "score": 0.5}, {"caught": false, "score": 0.5, "perfect": true}, {"caught": false, "score": 0.5, "chest": true}, {"score": 0.5}]:
		check(state.call("finish_fishing_error", bad) == "Resultado inválido", "extra: recusa " + str(bad))
	check(_fishing().cast.state == "fighting", "extra: resultado inválido não mexe na partida")
	var escaping: String = _fishing().cast.fish
	check(state.call("finish_fishing", {"caught": false, "score": 0.2}) == "", "extra: escapou")
	check(state.get("progress").stat("fish_escape") == 1 and state.get("progress").stat("fish_escape:" + escaping) == 1 and _fishing().cast.is_empty(), "extra: escape conta e limpa")
	check(_inv().count("bait_worm") == 4, "extra: a isca do peixe que escapou foi junto")
	# Baú: só com vara 2+.
	_fresh()
	check(_start() == "", "extra: fisgou na vara 1")
	var n1: int = int(_fishing().cast.n)
	state.call("finish_fishing", {"caught": true, "score": 0.5, "perfect": false, "chest": true})
	check(not state.get("economy").granted.has("fish_chest:%d" % n1), "extra: vara 1 não ganha baú")
	_drain_fish()
	state.call("dev_give_rod", "reel_rod")
	check(_start() == "", "extra: fisgou na vara 2")
	var n2: int = int(_fishing().cast.n)
	state.call("finish_fishing", {"caught": true, "score": 0.5, "perfect": false, "chest": true})
	check(state.get("economy").granted.has("fish_chest:%d" % n2), "extra: vara 2 recebe o baú uma vez")
	_drain_fish()
	# Iscas artificiais às vezes não gastam; a semente decide.
	_fresh()
	state.call("dev_give_rod", "angler_rod")
	var kept := 0
	for i in 20:
		_inv().add("bait_lure", 2)
		var before_lure: int = _inv().count("bait_lure")
		check(_start("bait_lure") == "", "extra: fisgou com isca artificial")
		if _inv().count("bait_lure") == before_lure:
			kept += 1
		state.call("cancel_fishing")
	check(kept > 0 and kept < 20, "extra: isca artificial poupa só parte das vezes (%d/20)" % kept)
	# Escolhas, requisito de nível e recompensa de vara.
	_fresh(false)
	state.call("_apply_rewards", {"rods": ["reel_rod"]})
	check(_fishing().has_rod("reel_rod") and state.get("progress").stat("rod:reel_rod") == 1, "extra: recompensa 'rods' dá a vara e conta")
	check(state.call("requirement_error", {"fishing_level": 3}) != "", "extra: requisito fishing_level")
	state.call("dev_fish_xp", 90)
	check(state.call("requirement_error", {"fishing_level": 3}) == "", "extra: nível 3 cumpre")
	var info: Dictionary = state.call("fishing_info")
	check(info.level == 3 and info.next_xp == 200 and info.rod == "reel_rod", "extra: fishing_info")

	print("FISHING TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
