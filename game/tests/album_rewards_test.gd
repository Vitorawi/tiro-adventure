extends SceneTree
## Fotos do Tiro, etapa 10: recompensas de coleção (seção completa, 4 versões, 5/15/30 Raras+, primeira
## Holográfica) pagas uma vez, recibos quando não cabem e o cartão de festa na fila depois da revelação.
##   godot --headless --path game -s res://tests/album_rewards_test.gd

var state: Node
var db: Node
var main: Control
var failures := 0
var milestones: Array = []
var all_photos: Array = []


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void:
		print("ALBUM REWARDS TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Recompensas do álbum: " + message)


func _fresh() -> void:
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	state.coins = 0
	milestones.clear()


func _reload() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))


func _kinds(kind: String) -> Array:
	return milestones.filter(func(m: Array) -> bool: return m[0] == kind).map(func(m: Array) -> String: return str(m[1]))


func _story(count: int) -> Array:
	var result: Array = []
	for entry: Dictionary in all_photos:
		if str(entry.section) == "story" and str(entry.id) != "h_arrival":
			result.append(entry)
			if result.size() == count: break
	return result


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	root.get_node("Events").album_milestone.connect(func(kind: String, key: String) -> void: milestones.append([kind, key]))
	all_photos = db.album.photos.duplicate()
	_fresh()

	# Dados
	var rewards: Dictionary = db.album.cards.rewards
	check(int(rewards.section.coins) == 60 and int(rewards.styles.coins) == 25 and int(rewards.holo_first.coins) == 100, "tabela do desenho")
	check(int(rewards.rare["5"].coins) == 40 and int(rewards.rare["15"].coins) == 80 and int(rewards.rare["30"].coins) == 150, "marcos de Raras")

	# 1. Seção completa paga uma vez (só com todas as cartas da seção abertas)
	var pair := _story(2)
	db.album.photos = pair
	var a := str(pair[0].id)
	var b := str(pair[1].id)
	state.dev_take_photo(a, 1)
	check(milestones.is_empty() and state.coins == 0, "uma foto aberta não completa a seção")
	state._take_photo(b)
	state._check_album_rewards()
	check(milestones.is_empty(), "carta fechada não conta")
	state.dev_take_photo(b, 1)
	check(_kinds("section") == ["story"] and state.coins == 60, "a última carta paga a seção (60 moedas)")
	check(state.album_milestone_paid("section", "story") and state.album_milestones("story").section.complete, "marco consultável")
	state.dev_take_photo(a, 2)
	state.upgrade_photo(b)
	state._check_album_rewards()
	_reload()
	state._check_album_rewards()
	check(_kinds("section") == ["story"] and state.coins >= 60 and not state.economy.granted.is_empty(), "repetir e recarregar não paga de novo")
	check(int(state.economy.granted.keys().filter(func(k: String) -> bool: return k.begins_with("album:section:")).size()) == 1, "um único recibo de seção")

	# 2. Quatro versões de uma foto + primeira Holográfica
	_fresh()
	state.dev_take_photo(a, 1)
	state.dev_take_photo(a, 2)
	state.dev_take_photo(a, 3)
	check(_kinds("styles").is_empty() and _kinds("holo").is_empty(), "três versões não pagam")
	state.dev_take_photo(a, 4)
	check(_kinds("styles") == [a] and _kinds("holo") == ["first"], "quatro versões e a primeira Holográfica pagam")
	check(state.coins == 25 + 100, "25 + 100 moedas (sem seção: a outra carta está fechada)")
	state.dev_take_photo(a, 4)
	state.dev_take_photo(b, 4)
	state.dev_take_photo(b, 1)
	check(_kinds("holo") == ["first"] and _kinds("styles") == [a, b], "outra Holográfica não paga a primeira de novo; a Holográfica completa as versões de baixo")
	var before: int = state.coins
	_reload()
	state._check_album_rewards()
	check(_kinds("styles") == [a, b] and state.coins == before, "recarregar não repaga")

	# 3. Marcos de 5/15/30 fotos Raras+
	db.album.photos = all_photos
	_fresh()
	var opened := 0
	for entry: Dictionary in all_photos:
		state.dev_take_photo(str(entry.id), 3)
		opened += 1
		if opened == 4: check(_kinds("rare").is_empty(), "4 Raras ainda não pagam")
		if opened == 5: check(_kinds("rare") == ["5"], "5 Raras pagam o primeiro marco")
		if opened == 14: check(_kinds("rare") == ["5"], "14 Raras não pagam o segundo")
		if opened == 15: check(_kinds("rare") == ["5", "15"], "15 Raras pagam o segundo")
		if opened == 30: break
	check(_kinds("rare") == ["5", "15", "30"], "30 Raras pagam o terceiro")
	var next: Dictionary = state.album_milestones("story")
	check(next.rare.is_empty(), "sem próximo marco depois do último")
	state.dev_take_photo(str(all_photos[0].id), 4)
	state.dev_take_photo(str(all_photos[1].id), 4)
	check(_kinds("holo") == ["first"] and _kinds("rare") == ["5", "15", "30"], "Holográfica paga uma vez; Raras não repetem")
	_reload()
	state._check_album_rewards()
	check(_kinds("holo") == ["first"] and _kinds("rare").size() == 3, "recarregar não repaga os marcos")
	_fresh()
	for i in 3: state.dev_take_photo(str(all_photos[i].id), 3)
	var step: Dictionary = state.album_milestones()
	check(int(step.rare.next) == 5 and int(step.rare.left) == 2 and int(step.rare.have) == 3, "próximo marco: mais 2 Raras")

	# 4. Itens que não cabem viram recibo
	db.album.photos = pair
	_fresh()
	state.unlimited_storage = false
	state.progress.owned["fridge"] = true
	for upgrade: String in ["fridge_2", "fridge_3", "fridge_4", "fridge_5"]: state.progress.owned.erase(upgrade)
	state.economy.storage_floor.clear()
	state.inventory.counts.clear()
	state.inventory.add("egg", 24)
	var saved_reward: Dictionary = (db.album.cards.rewards.holo_first as Dictionary).duplicate(true)
	db.album.cards.rewards.holo_first = {"coins": 10, "items": {"carrot_snack": 2}}
	state.dev_take_photo(a, 4)
	check(_kinds("holo") == ["first"] and state.coins == 10 + 25, "moedas entram mesmo sem espaço (prêmio + as 4 versões)")
	check(state.economy.pending.has("album:holo:first") and int(state.pending_reward_total()) == 2, "itens esperam em 'Presentes para guardar'")
	check(str(state.economy.pending["album:holo:first"].label) == "Álbum de fotos", "recibo diz de onde veio")
	db.album.cards.rewards.holo_first = saved_reward
	state.dev_take_photo(b, 4)
	check(_kinds("holo") == ["first"], "o recibo não é repetido")

	# 5. A festa entra na fila e só abre depois da revelação
	db.album.photos = pair
	_fresh()
	state.note_screen_opened("album")
	state.dev_take_photo(a, 1)
	state.dev_seal_photo(b)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for timer in main.find_children("*", "Timer", true, false): timer.stop()
	main.get("_modal_queue").clear()
	main.get("_photo_queue").clear()
	main.set("_announce_pending", false)
	main.set("_chapter_done", 0)
	main.set("_reward_not_before", 0)
	for key in ["_welcome", "_celebration", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(key) as CanvasLayer).hide()
	var reveal_script: GDScript = load("res://scripts/ui/card_reveal.gd")
	var viewer_script: GDScript = load("res://scripts/ui/card_viewer.gd")
	var card: Control = reveal_script.call("open", b, {"host": main})
	await process_frame
	check(card != null and viewer_script.call("is_open"), "revelação aberta")
	card.get_node("CardReveal").call("_open_card")
	check(state.photo_rarity(b) > 0 and _kinds("section") == ["story"], "abrir a última carta completa a seção")
	check(main.get("_modal_queue").size() == 1, "a festa entrou na fila")
	main.call("_flush_modals")
	check(not (main.get("_celebration") as CanvasLayer).visible, "a festa espera a carta na tela")
	await create_timer(1.5).timeout
	(viewer_script.get("current") as Control).call("close")
	await process_frame
	main.call("_flush_modals")
	var celebration := main.get("_celebration") as CanvasLayer
	check(celebration.visible and celebration.find_child("CelebrationScroll", true, false) != null, "depois de fechar a carta a festa abre")
	check(main.get("_modal_queue").is_empty(), "fila vazia depois da festa")

	db.album.photos = all_photos
	print("ALBUM REWARDS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)
