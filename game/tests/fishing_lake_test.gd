extends SceneTree
## Pesca, etapa 02: a lagoa do Sítio de ponta a ponta (toque, painel, arremesso, espera, mordida, minigame, resultado).
## Usa o Sítio de verdade (main.tscn), sem SaveManager. O relógio é o real: a mordida vem recuando `cast.at`.
## --headless --path game -s res://tests/fishing_lake_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var farm: Control
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PESCA_LAGOA: " + message)


func _fishing() -> RefCounted:
	return state.get("fishing")


func _inv() -> RefCounted:
	return state.get("inventory")


func _flow() -> Node:
	return farm.call("fishing_flow")


## Painel de arremesso aberto (sem referenciar o tipo: ele usa autoloads, que não existem ao compilar um teste `-s`).
func _panel() -> Control:
	var node := farm.find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _frames(count: int = 3) -> void:
	for i in count:
		await process_frame


## Estado limpo com vara e isca; o fluxo da sala volta ao parado.
func _reset(with_rod: bool = true, baits: int = 5) -> void:
	if _flow() != null:
		_flow().call("end")
	state.call("cancel_fishing")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	_inv().call("from_dict", {})
	if with_rod:
		state.call("dev_give_rod", "bamboo_rod")
		_inv().add("bait_worm", baits)
	toasts.clear()


func _open() -> void:
	farm.call("open_fishing")
	await _frames()


## Faz a mordida chegar já: recua o início da espera.
func _make_bite_due() -> void:
	var cast: Dictionary = _fishing().cast
	cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
	state.call("update_fishing")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(4)
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await _frames(4)
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	farm = main.find_child("World_farm", true, false)
	farm.call("recenter")
	await _frames()

	await _test_locked()
	await _test_panel_and_dog()
	await _test_no_bait()
	await _test_zones()
	await _test_early_tap()
	await _test_bite_and_game()
	await _test_tab_switch()
	await _test_reload()
	await _test_bubble()
	await _test_rects()
	await _test_extras()

	print("FISHING LAKE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 1 — sem vara: só o aviso curto da vovó e nenhum painel.
func _test_locked() -> void:
	_reset(false)
	await _open()
	check(_panel() == null, "1: sem vara não abre o painel")
	var notice: Object = main.get("_notice")
	var texts: Array[String] = [str((notice.get("_current") as Dictionary).get("text", ""))]
	for waiting: Dictionary in notice.get("_queue"):
		texts.append(str(waiting.text))
	check(texts.any(func(text: String) -> bool: return "pescar" in text), "1: aviso da vovó (%s)" % str(texts))
	check(farm.call("fishing_flow") == null, "1: sem vara o fluxo nem nasce")
	check(root.get_node("Database").get("npcs").bloblo.lines.lake_locked != "", "1: fala lake_locked nos dados")


# 2 — com vara e isca: o painel abre, o botão está ativo e o Tiro vai sentar na beirinha.
func _test_panel_and_dog() -> void:
	_reset()
	await _open()
	check((_panel() != null), "2: o painel abre")
	var panel := _panel()
	check(panel != null and panel.find_child("CastButton", true, false) is Button, "2: CastButton existe")
	check(not (panel.find_child("CastButton", true, false) as Button).disabled, "2: CastButton ativo")
	check(panel.find_child("RodRow", true, false) == null, "2: com 1 vara não há fileira de varas")
	check(panel.find_child("Bait_bait_worm", true, false) != null, "2: isca da minhoca no painel")
	check(panel.find_child("BaitFish", true, false) != null, "2: faixa com os peixes da isca")
	var dog: Node = farm.call("dog_node")
	check(dog != null and dog.fishing_session, "2: o Tiro está em sessão de pesca")
	check(str(dog.get_meta("last_reaction", "")) == "fishing", "2: o Tiro recebeu a reação fishing")
	check(panel.find_child("FishingLevel", true, false) != null, "2: nível de pesca no cabeçalho")
	var tabs := main.find_child("TabBar", true, false) as Control
	var box := panel.find_child("Panel", true, false) as Control
	check(box.get_global_rect().end.y <= tabs.global_position.y + 0.5, "2: painel acima das abas (%s × %s)" % [box.get_global_rect(), tabs.global_position])
	check(box.get_global_rect().position.y >= 168.0 - 0.5, "2: painel abaixo do HUD")
	# duas varas: aparece a fileira
	state.call("dev_give_rod", "reel_rod")
	await _frames()
	check(_panel() != null and _panel().find_child("RodRow", true, false) != null, "2: com 2 varas aparece RodRow")
	check(_panel().find_child("Rod_reel_rod", true, false) != null, "2: quadradinho da vara nova")


# 3 — sem isca: botão bloqueado com o motivo; tocar abre o Como fazer.
func _test_no_bait() -> void:
	_reset(true, 0)
	await _open()
	var panel := _panel()
	check(panel != null, "3: o painel abre sem isca")
	var locked := panel.find_child("Locked_CastButton", true, false) as Button
	check(locked != null, "3: Locked_CastButton")
	check(panel.find_child("CastButton", true, false) == null, "3: sem CastButton verde")
	check(locked != null and str(locked.get_meta("reason", "")) == "Sem minhoca", "3: motivo 'Sem minhoca'")
	if locked:
		locked.emit_signal("pressed")
		await _frames()
		check(root.get_node("Database").call("item_name", "bait_worm") != "", "3: ajuda da isca consultável")


# 4 — a força do ponteiro vira a zona certa.
func _test_zones() -> void:
	for pair: Array in [[0.1, 1], [0.5, 2], [0.95, 3]]:
		_reset()
		await _open()
		var panel := _panel()
		panel.set("power_override", float(pair[0]))
		panel.call("press_cast")
		panel.call("release_cast")
		check(int(panel.get("last_zone")) == int(pair[1]), "4: força %s → zona %d" % [pair[0], pair[1]])
		var cast: Dictionary = _fishing().cast
		check(not cast.is_empty() and int(cast.zone) == int(pair[1]), "4: a partida nasce na zona %d" % int(pair[1]))
		check(str(_flow().get("state")) == "waiting", "4: o fluxo espera a mordida")
		check(not (_panel() != null), "4: o painel fecha ao arremessar")
		check(_inv().count("bait_worm") == 5, "4: arremessar não gasta a isca")
		await _frames()


# 5 — tocar antes da mordida recolhe a linha sem gastar nada.
func _test_early_tap() -> void:
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	check(_flow().call("handle_tap"), "5: o toque na espera é consumido")
	check(_fishing().cast.is_empty(), "5: miss_bite limpou a partida")
	check(_inv().count("bait_worm") == 5, "5: nada gasto no toque cedo")
	check(int(state.get("progress").stat("fish_miss")) == 1, "5: conta fish_miss")
	check("Ainda não mordeu!" in toasts, "5: aviso 'Ainda não mordeu!'")
	check(str(_flow().get("state")) == "panel", "5: volta ao painel")


# 6 — mordida, fisgar, minigame até pegar, resultado, "Pescar de novo".
func _test_bite_and_game() -> void:
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	var bobber: Node2D = _flow().get("bobber")
	_make_bite_due()
	await _frames()
	check(str(bobber.get("state")) == "bite", "6: a boia afunda na mordida")
	check(_flow().call("handle_tap"), "6: o toque na mordida é consumido")
	check(str(_flow().get("state")) == "fighting", "6: fisgou: o minigame abre")
	var game := main.find_child("FishingGame", true, false)
	check(game != null, "6: FishingGame existe")
	check(_inv().count("bait_worm") == 4, "6: a fisgada gastou 1 minhoca")
	if game == null:
		return
	# Joga: pausa a cena para o teste conduzir o motor até pegar.
	game.set("_paused", true)
	var sim: FishingSim = game.get("sim")
	sim.meter = 0.995
	var guard := 0
	while not sim.finished and guard < 3000:
		sim.step(sim.fish_y > sim.bar_y + sim.bar_h / 2.0, 1.0 / 60.0)
		guard += 1
	check(sim.finished and sim.caught, "6: o motor terminou com o peixe pego")
	game.call("_finish")
	game.set("_result_ready_at", 0.0)
	await _frames(4)
	var result: Node = _flow().get("result")
	check(result.visible, "6: o cartão de resultado abre")
	check(result.find_child("FishSize", true, false) != null, "6: FishSize (cm)")
	check(result.find_child("FishClass", true, false) != null, "6: FishClass")
	check(int(state.get("progress").stat("fish")) == 1, "6: contou 1 peixe")
	var again := result.find_child("FishAgain", true, false) as Button
	check(again != null, "6: botão Pescar de novo")
	if again:
		again.emit_signal("pressed")
		await _frames(3)
		check((_panel() != null), "6: 'Pescar de novo' volta ao painel de arremesso")
		check(_panel() != null and _panel().find_child("CastButton", true, false) != null, "6: CastButton de volta")


# 7 — trocar de aba com o minigame aberto devolve a isca.
func _test_tab_switch() -> void:
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	_make_bite_due()
	_flow().call("handle_tap")
	await _frames()
	check(_inv().count("bait_worm") == 4, "7: a isca foi gasta na luta")
	main.call("show_screen", &"tasks")
	await _frames(4)
	check(_inv().count("bait_worm") == 5, "7: trocar de aba devolveu a isca")
	check(_fishing().cast.is_empty(), "7: a partida acabou")
	check(main.find_child("FishingGame", true, false) == null, "7: o minigame fechou")
	check(str(_flow().get("state")) == "idle", "7: o fluxo está parado")
	main.call("show_screen", &"map")
	await _frames(3)


# 8 — recarregar o save com a partida em luta devolve a isca.
func _test_reload() -> void:
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	_make_bite_due()
	_flow().call("handle_tap")
	await _frames()
	check(_inv().count("bait_worm") == 4 and str(_fishing().cast.state) == "fighting", "8: luta em andamento")
	var saved: Dictionary = state.call("to_dict")
	_flow().call("end")
	state.call("from_dict", saved)
	check(_inv().count("bait_worm") == 5, "8: recarregar devolve a isca")
	check(str(_fishing().cast.get("state", "")) in ["interrupted", ""], "8: a partida não segue em luta")
	state.call("cancel_fishing")


# 9 — bolha: arremessar em cima dela usa a espera menor e sobe a zona.
func _test_bubble() -> void:
	_reset()
	state.call("dev_bubble_now")
	await _open()
	var flow := _flow()
	var index := int(_fishing().bubble.spot)
	var points: Array = flow.get("bubble_points")
	check(points.size() >= 4, "9: a sala tem as 4 posições de bolha")
	check(farm.call("fishing_bubbles").call("active_spot") == index, "9: as bolhas aparecem no ponto sorteado")
	points[index] = flow.call("landing_for", 1)
	flow.set("bubble_points", points)
	_panel().set("power_override", 0.1)
	_panel().call("press_cast")
	_panel().call("release_cast")
	var cast: Dictionary = _fishing().cast
	check(bool(cast.get("bubble", false)), "9: o arremesso na bolha vale")
	check(int(cast.zone) == 2, "9: a bolha sobe a zona (1 → 2)")
	var max_wait: float = float(root.get_node("Database").get("fishing").cast.wait[1]) * float(root.get_node("Database").get("fishing").bubbles.wait_mult)
	check(float(cast.wait) <= max_wait + 0.01, "9: espera encurtada (%.2f <= %.2f)" % [float(cast.wait), max_wait])
	state.call("cancel_fishing")
	_flow().call("end")


# 10 — o minigame nunca cobre o HUD nem as abas.
func _test_rects() -> void:
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	_make_bite_due()
	_flow().call("handle_tap")
	await _frames(3)
	var game := main.find_child("FishingGame", true, false) as Control
	check(game != null, "10: minigame aberto")
	if game:
		var rect := game.get_global_rect()
		var tabs := main.find_child("TabBarArt", true, false) as Control
		check(rect.position.y >= 168.0 - 0.5, "10: não cobre o HUD (topo %.0f)" % rect.position.y)
		check(rect.end.y <= tabs.global_position.y + 0.5, "10: não cobre as abas")
		var track: Rect2 = game.call("track_rect")
		check(track.size.y > 100.0 and track.end.x <= game.size.x and track.position.x >= 0.0, "10: a pista cabe na área")
		check(game.get("z_index") == 7, "10: z 7 (abaixo do HUD)")
		# pausa e continuar
		game.call("pause")
		check(game.call("is_paused") and game.find_child("PauseCard", true, false).visible, "10: pausa mostra o cartão")
		game.call("resume")
		check(not game.call("is_paused"), "10: continuar retoma")
	state.call("cancel_fishing")
	_flow().call("end")
	await _frames(2)
	check(main.find_child("FishingGame", true, false) == null, "10: ao terminar o minigame some")


# Extras: geladeira cheia, escapou, lugar na lista e destino do Ir.
func _test_extras() -> void:
	_reset()
	# lugar escondido, mas na lista depois da vara
	var places: Script = load("res://scripts/ui/places.gd")
	var world: Control = places.call("world_list", "farm")
	main.add_child(world)
	await _frames(2)
	check(world.find_child("Place_fishing", true, false) != null, "11: a lagoa aparece em Lugares depois da vara")
	world.queue_free()
	check(places.call("goal_target", {"type": "stat", "key": "fish:fish_lambari"}).get("place", "") == "fishing", "11: goal_target de peixe leva à lagoa")
	check(places.call("world_summary", "farm").fishing == 0, "11: sem bolha, fishing 0")
	state.call("dev_bubble_now")
	check(places.call("world_summary", "farm").fishing == 1, "11: com bolha, fishing 1")
	# escapou: aviso e painel
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	_make_bite_due()
	_flow().call("handle_tap")
	await _frames()
	_flow().call("_finish", {"caught": false, "score": 0.1, "perfect": false, "chest": false})
	await _frames(3)
	check((_panel() != null), "12: escapou: o painel volta")
	check(int(state.get("progress").stat("fish_escape")) == 1, "12: contou escape")
	# geladeira cheia
	_reset()
	await _open()
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	_make_bite_due()
	_flow().call("handle_tap")
	await _frames()
	var fish := str(_fishing().cast.fish)
	var capacity := int(state.call("storage_capacity", "fridge")) if state.has_method("storage_capacity") else 12
	_inv().add(fish, 999)
	_flow().call("_finish", {"caught": true, "score": 0.6, "perfect": false, "chest": false})
	await _frames(3)
	var result: Node = _flow().get("result")
	check(result.find_child("Locked_Fridge", true, false) != null, "13: geladeira cheia mostra o bloqueio")
	check(result.find_child("FishFreeSpace", true, false) != null and result.find_child("FishRelease", true, false) != null, "13: liberar espaço e soltar")
	check(not _fishing().cast.is_empty() and _fishing().cast.has("pending_result"), "13: o peixe espera na linha")
	var release := result.find_child("FishRelease", true, false) as Button
	if release:
		release.emit_signal("pressed")
		await _frames()
		check(_fishing().cast.is_empty(), "13: soltar o peixe encerra a partida")
