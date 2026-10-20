extends SceneTree
## Etapa 13 do plano Tiro: álbum de recordações (motor, fotos garantidas, dentinho de leite e interface).
## Cada foto de História e Primeiras vezes sai pela ação real certa, uma vez só (inclusive recarregando);
## a foto guarda a fase e o corpo; seções inativas não aparecem; dado quebrado é rejeitado.

var state: Node
var db: Node
var failures := 0
var taken: Array[String] = []
var photo_card: Variant
var album_view: Variant
var notebook: Variant


func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void:
		print("ALBUM TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Álbum: " + message)


func _fresh(phase: String = "newborn") -> void:
	state.reset()
	state.progress.seen["intro"] = true
	state.growth.phase = phase
	state.dev_reset_album()
	taken.clear()


func _reload() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))


func _ids() -> Array:
	var ids: Array = state.album.photos.keys()
	ids.sort()
	return ids


func _unlock() -> void:
	state.dev_unlock_everything()
	state.dev_reset_album()
	state.growth.phase = "newborn"
	for need: String in state.dog.needs:
		state.dog.needs[need] = 50.0


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.test_time = 1791936000.0
	photo_card = load("res://scripts/ui/photo_card.gd")
	album_view = load("res://scripts/ui/album_view.gd")
	notebook = load("res://scripts/ui/pet_notebook.gd")
	root.get_node("Events").photo_taken.connect(func(id: String) -> void: taken.append(id))
	_data()
	var active: Array = db.album.active_sections.duplicate()
	# Os casos da etapa 13 isolam suas 22 fotos; a etapa 15 cobre as outras 32 pelas ações reais.
	db.album.active_sections = ["story", "firsts"]
	_story()
	_firsts()
	_campaign()
	_once_and_reload()
	_phase_snapshot()
	_milk_tooth()
	_inactive()
	db.album.active_sections = active
	_introduction()
	_interface()
	print("ALBUM TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _data() -> void:
	check(db.album_problems().is_empty(), "album.json válido: " + str(db.album_problems()))
	check(db.album.photos.size() == 54, "54 fotos no catálogo")
	var per := {}
	for entry: Dictionary in db.album.photos:
		per[entry.section] = int(per.get(entry.section, 0)) + 1
	check(per == {"story": 14, "firsts": 8, "tricks": 13, "sleep": 8, "friends": 6, "dates": 5}, "seções 14/8/13/8/6/5: " + str(per))
	for entry: Dictionary in db.album.photos:
		check(entry.when.size() <= 3, "no máximo 3 condições: " + str(entry.id))
	# Dado quebrado é rejeitado.
	var original: Dictionary = db.album
	for mutation: String in ["condition", "event", "prop", "scene", "many", "duplicate"]:
		var broken: Dictionary = original.duplicate(true)
		var entry: Dictionary = broken.photos[0]
		match mutation:
			"condition": entry.when = {"lua_de_queijo": 1}
			"event": entry.on = "voou"
			"prop": entry.photo.props = ["asa_delta"]
			"scene": entry.photo.scene = "marte"
			"many": entry.when = {"hour": [1, 2], "months": [1], "bond_min": 1, "phase_min": "puppy"}
			"duplicate": broken.photos[1].id = entry.id
		db.album = broken
		check(not db.album_problems().is_empty(), "rejeita: " + mutation)
	db.album = original
	check(db.album_problems().is_empty(), "restaura o catálogo")
	check(db.album_sections().size() == 6, "seis seções ativas na etapa 15")


## Executa `act`, confere que saíram exatamente as fotos esperadas e que repetir não tira de novo.
func _expect(label: String, act: Callable, expected: Array) -> void:
	taken.clear()
	var before: int = state.album.count()
	act.call()
	var got := taken.duplicate()
	got.sort()
	var want := expected.duplicate()
	want.sort()
	check(got == want, "%s tirou %s (esperado %s)" % [label, str(got), str(want)])
	check(state.album.count() == before + expected.size(), label + ": contagem")
	taken.clear()
	act.call()
	check(taken.is_empty(), label + ": repetir não tira de novo")


func _story() -> void:
	_fresh()
	state.progress.seen.erase("intro")
	_expect("intro", func() -> void:
		var keys: Array[String] = ["intro"]
		state.mark_seen(keys), ["h_arrival"])
	# Soneca antes da caminha não perde a foto: ela sai quando a missão é recebida.
	state.dog.needs["energy"] = 40.0
	_expect("soneca sem caminha", func() -> void: state.set_sleeping(true), [])
	state.set_sleeping(false)
	_expect("caminha da Laís", func() -> void: state._finish_quest("lais_bed"), ["h_first_night"])
	_fresh()
	state.progress.claimed_quests["lais_bed"] = true
	_expect("soneca com caminha", func() -> void: state.set_sleeping(true), ["h_first_night"])

	_fresh()
	_unlock()
	state.dev_complete_growth_reqs()
	_expect("cerimônia puppy", func() -> void: state.grow() if state.growth.phase == "newborn" else null, ["h_growth_puppy"])
	for phase in ["teething", "explorer", "young", "adult"]:
		state.dev_complete_growth_reqs()
		var id: String = "h_growth_" + phase
		_expect("cerimônia " + phase, func() -> void: state.grow() if state.growth.phase_index() < state.growth.phase_index(phase) else null, [id])
		check(state.album.photos[id].phase == phase, id + " guarda a fase nova")

	_fresh()
	_unlock()
	state.inventory.add("puppy_mash", 2)
	state.dog.needs["hunger"] = 20.0
	_expect("primeira papinha", func() -> void: state.feed("puppy_mash"), ["h_kitchen", "f_taste"])

	_fresh()
	_unlock()
	state.dev_walk_return()
	check(state.album.has_photo("h_first_walk"), "primeiro passeio tira h_first_walk")

	_fresh()
	_unlock()
	state.growth.phase = "teething"
	_expect("truque pata", func() -> void: state.learn_trick("paw"), ["h_first_trick"])
	_fresh()
	_unlock()
	_expect("banca", func() -> void: state._finish_quest("own_business"), ["h_banca"])
	_expect("banco", func() -> void: state._finish_quest("community_10_use"), ["h_bench"])
	_expect("medalhinha", func() -> void: state._finish_quest("community_12_memory"), ["h_courage"])
	_expect("guardião (último capítulo)", func() -> void: state._album_event("chapter_done", {"chapter_last": true}), ["h_guardian"])
	_fresh()
	state._album_event("chapter_done", {"chapter_last": false})
	check(taken.is_empty(), "capítulo que não é o último não tira foto")


func _firsts() -> void:
	_fresh()
	_unlock()
	_expect("primeiro banho", func() -> void: state.bathe(), ["f_bath"])
	state.dev_spawn_finds()
	_expect("primeiro achado", func() -> void: _dig_any(), ["f_dig"])
	_fresh()
	_unlock()
	state.inventory.add("carrot_snack", 4)
	var friend_error: String = state.give_friend_error("pipoca")
	check(friend_error == "", "fixture do petisco: " + friend_error)
	_expect("primeiro coração", func() -> void: state.give_friend("pipoca"), ["f_friend"])
	_fresh()
	_unlock()
	var outfit := ""
	for id: String in db.collections:
		if outfit == "" and state.equip_error(id) == "":
			outfit = id
	check(outfit != "", "fixture: roupa vestível")
	_expect("primeira roupa", func() -> void: state.equip(outfit), ["f_outfit"])
	_fresh()
	_unlock()
	state.inventory.add("basic_brush", 1)
	_expect("primeira escovada", func() -> void: state.brush(), ["f_brush"])
	_fresh()
	_expect("raro de passeio", func() -> void: state._album_event("walk_returned", {"route": "park_loop", "rare": true}), ["f_rare", "h_first_walk"])
	_fresh()
	state._album_event("walk_returned", {"route": "park_loop", "rare": false})
	check(not state.album.has_photo("f_rare"), "passeio comum não é achado raro")


## Save novo jogado pelas ações reais (com atalhos DEV só para cumprir requisitos) até o Aventureiro.
func _campaign() -> void:
	state.reset()
	state.dev_reset_album()
	var keys: Array[String] = ["intro"]
	state.mark_seen(keys)
	state._finish_quest("lais_bed")
	state.dog.needs["energy"] = 40.0
	state.set_sleeping(true)
	state.set_sleeping(false)
	state.bathe()
	state.dev_complete_growth_reqs()
	state.grow()
	state.inventory.add("puppy_mash", 1)
	state.feed("puppy_mash")
	state.dev_walk_return()
	state.dev_complete_growth_reqs()
	state.grow()
	state.dev_unlock_everything()
	state.dev_spawn_finds()
	_dig_any()
	state.growth.phase = "teething"
	state.learn_trick("paw")
	state.dev_complete_growth_reqs()
	state.grow()
	check(state.growth.phase in ["explorer", "teething"], "campanha chegou perto do Aventureiro")
	var expected := ["h_arrival", "h_first_night", "f_bath", "h_growth_puppy", "h_kitchen", "f_taste", "h_first_walk", "h_growth_teething", "f_dig", "h_first_trick"]
	for id: String in expected:
		check(state.album.has_photo(id), "campanha tirou " + id)
	for id: String in state.album.photos:
		check(db.photo(id).section in ["story", "firsts"], "só seções ativas: " + id)


func _dig_any() -> void:
	for world: String in state.finds.worlds:
		if int(state.finds.worlds[world].pending) > 0 and state.dig_error(world) == "":
			state.dig(world)
			return


func _once_and_reload() -> void:
	_fresh()
	_unlock()
	state.bathe()
	state.set_sleeping(true)
	var before := _ids()
	check(before.has("f_bath"), "fixture: foto do banho")
	_reload()
	check(_ids() == before, "recarregar mantém as fotos")
	taken.clear()
	state.set_sleeping(false)
	state.bathe()
	check(taken.is_empty() and _ids() == before, "recarregar não repete a foto")
	check(state.progress.stat("photos") == state.album.count(), "contador de fotos = fotos tiradas")
	state.mark_photo_seen("f_bath")
	_reload()
	check(state.album.photos.f_bath.seen and state.photos_unseen().size() == before.size() - 1, "visto sobrevive ao save")


func _phase_snapshot() -> void:
	_fresh("newborn")
	_unlock()
	state.bathe()
	var info: Dictionary = state.photo_info("f_bath")
	check(info.phase == "newborn", "foto guarda a fase")
	state.dev_complete_growth_reqs()
	state.grow()
	state.dev_set_phase("adult")
	check(state.photo_info("f_bath").phase == "newborn", "foto continua da fase antiga")
	var card: Control = photo_card.make("f_bath", 120.0)
	root.add_child(card)
	var dog := card.find_child("Tiro", true, false) as TextureRect
	check(dog != null and dog.texture.resource_path.contains("puppy"), "foto mostra o corpo de filhote depois de crescer: " + str(dog.texture.resource_path if dog else ""))
	var adult: Texture2D = photo_card.dog_frame("adult", "idle_breathe", 0)
	check(adult != null and not adult.resource_path.contains("puppy") and not adult.resource_path.contains("young"), "corpo adulto continua o original")
	card.free()


func _milk_tooth() -> void:
	_fresh("puppy")
	_unlock()
	state.growth.phase = "puppy"
	state.dev_spawn_finds()
	var world := ""
	for id: String in state.finds.worlds:
		if int(state.finds.worlds[id].pending) > 0 and state.dig_error(id) == "":
			world = id
	check(world != "", "fixture: montinho pendente")
	check(not state.find_reward(world).get("items", {}).has("milk_tooth"), "antes de Dentinhos não há dentinho")
	state.growth.phase = "teething"
	check(state.find_reward(world).items.has("milk_tooth"), "primeiro montinho de Dentinhos garante o dentinho")
	check(state.dig_error(world) == "", "dentinho cabe (sem depósito)")
	taken.clear()
	state.dig(world)
	check(state.progress.stat("find_item:milk_tooth") == 1, "dentinho entra na contagem de achados")
	check("f_tooth" in taken and state.album.has_photo("f_tooth"), "dentinho tira a foto f_tooth")
	state.dev_spawn_finds()
	for id: String in state.finds.worlds:
		check(not state.find_reward(id).get("items", {}).has("milk_tooth"), "depois de achado não repete")
	_fresh("explorer")
	_unlock()
	state.growth.phase = "explorer"
	state.dev_spawn_finds()
	var late := ""
	for id: String in state.finds.worlds:
		if int(state.finds.worlds[id].pending) > 0:
			late = id
	check(late != "" and state.find_reward(late).items.has("milk_tooth"), "quem pulou para Aventureiro ainda recebe o dentinho")


func _inactive() -> void:
	_fresh()
	_unlock()
	state.bathe()
	state.pet()
	check(not state.album.has_photo("s_foam_ghost"), "travessura (seção inativa) não é tirada")
	check(state.album.photos.keys().all(func(id: String) -> bool: return db.photo(id).section in ["story", "firsts"]), "só fotos das seções ativas")
	var panel: Control = album_view.panel()
	root.add_child(panel)
	check(panel.find_child("Photo_s_foam_ghost", true, false) == null, "seção inativa não aparece no álbum")
	check(panel.find_child("NotebookTab_tricks", true, false) == null, "aba de seção inativa não aparece")
	panel.free()


func _introduction() -> void:
	_fresh()
	state.dev_take_photo("h_arrival")
	var arrival: Dictionary = state.photo_info("h_arrival")
	check(not state.photo_alerts_enabled(), "chegada não ativa avisos de foto")
	check(not notebook.section_has_new("album"), "Álbum desconhecido não recebe sinal de novidade")
	check(state.welcome_ready_lines().all(func(line: Dictionary) -> bool: return line.kind != "photo"), "boas-vindas não anuncia fotos antes da primeira visita")
	check(not state.quest_unlocked("lais_album"), "apresentação espera as primeiras brincadeiras")
	state.progress.claimed_quests.lais_play = true
	check(state.quest_unlocked("lais_album"), "Laís apresenta o Álbum depois de brincar")
	check(db.quests.lais_album.kind == "line", "apresentação opcional não reabre a história antiga")
	var target: Dictionary = load("res://scripts/ui/progression_ui.gd").call("quest_go_target", "lais_album")
	check(target.get("notebook", "") == "album", "Ir tem como destino a aba Álbum")
	var view: Control = album_view.panel("story")
	root.add_child(view)
	check(state.photo_alerts_enabled() and state.progress.stat("open:album") == 1, "primeira visita habilita avisos e cumpre objetivo")
	check(state.quest_error("lais_album") == "", "visita cumpre a missão de apresentação")
	check(state.photo_info("h_arrival") == arrival, "primeira visita preserva a foto anterior e seu snapshot")
	view.free()
	_reload()
	check(state.photo_alerts_enabled(), "descoberta do Álbum persiste no save")
	# Save anterior, sem o contador novo: foto já vista prova que conhecia o Álbum.
	state.progress.stats.erase("open:album")
	state.mark_photo_seen("h_arrival")
	_reload()
	check(state.photo_alerts_enabled(), "compatibilidade com save que já tinha foto vista")


func _interface() -> void:
	_fresh()
	_unlock()
	state.bathe()
	state.set_sleeping(true)
	state.set_sleeping(false)
	for id: String in state.photos_unseen():
		if str(db.photo(id).section) != "firsts": state.mark_photo_seen(id)
	check(notebook.has_new(), "caderninho ganha o selo Novo com foto não vista")
	var ids: Array = notebook.tabs().map(func(t: Dictionary) -> String: return t.id)
	check("album" in ids, "aba Álbum aparece depois da primeira foto")
	var notebook_panel: Control = notebook.panel("manual")
	root.add_child(notebook_panel)
	check(notebook_panel.find_child("NotebookTab_album", true, false).find_child("NewBadge", true, false) != null, "Manual aponta novidade na aba Álbum")
	check(notebook_panel.find_child("NotebookTab_manual", true, false).find_child("NewBadge", true, false) == null, "Manual não recebe aviso de outra aba")
	notebook_panel.free()
	check(not state.photos_unseen().is_empty(), "abrir Manual não marca fotos como vistas")
	var panel: Control = album_view.panel("firsts")
	root.add_child(panel)
	var grid := panel.find_child("AlbumGrid", true, false) as GridContainer
	check(grid != null and grid.columns == 3 and grid.get_child_count() == 8, "grade de 3 colunas com as 8 primeiras vezes")
	check(panel.find_child("Photo_f_bath", true, false).find_child("NewBadge", true, false) != null, "foto nova tem selo Novo!")
	check(panel.find_child("Photo_f_bath", true, false).find_child("NewBadge", true, false).text == "!", "foto nova usa exclamação")
	check(panel.find_child("NotebookTab_firsts", true, false).find_child("NewBadge", true, false) != null, "seção Primeiras vezes aponta as fotos novas")
	check(panel.find_child("NotebookTab_story", true, false).find_child("NewBadge", true, false) == null, "seção sem foto nova fica sem aviso")
	check(panel.find_child("Photo_f_dig", true, false).find_child("NewBadge", true, false) == null, "foto que falta não tem selo")
	check(panel.find_child("PhotoCard", true, false) != null, "polaroides montadas")
	var counter := "%d/%d" % [album_view.taken_count(), album_view.total_count()]
	check(album_view.total_count() == 54, "contador usa as seis seções ativas (54)")
	check(counter != "", "contador " + counter)
	var secret: Control = photo_card.make("s_foam_ghost", 98.0, {"secret": true})
	root.add_child(secret)
	check(secret.find_child("SecretMark", true, false) != null, "secreta mostra ?")
	secret.free()
	panel.free()
	var lines: Array = state.welcome_ready_lines().filter(func(l: Dictionary) -> bool: return l.kind == "photo")
	check(lines.size() == 1 and int(lines[0].count) >= 1, "boas-vindas tem a linha de foto nova")
	var detail: Control = album_view.detail("f_bath")
	root.add_child(detail)
	check(detail.find_child("PhotoWhen", true, false) != null and detail.find_child("PhotoTitle", true, false) != null, "detalhe com título, data e fase")
	detail.free()
	for id: String in state.photos_unseen():
		state.mark_photo_seen(id)
	notebook_panel = notebook.panel("manual")
	root.add_child(notebook_panel)
	check(notebook_panel.find_child("NotebookTab_album", true, false).find_child("NewBadge", true, false) == null, "aba Álbum perde a exclamação após ver as fotos")
	notebook_panel.free()
	check(not notebook.has_new() or not state.new_unlocks().is_empty(), "selo some depois de ver as fotos")
	lines = state.welcome_ready_lines().filter(func(l: Dictionary) -> bool: return l.kind == "photo")
	check(lines.is_empty(), "linha de foto some depois de vista")
	# Antes e depois da cerimônia do adulto.
	state.dev_take_photo("h_arrival")
	state.dev_take_photo("h_growth_adult")
	var pair: Control = album_view.detail("h_growth_adult")
	root.add_child(pair)
	check(pair.find_child("BeforePhoto", true, false) != null, "foto do adulto mostra a chegada ao lado")
	pair.free()
