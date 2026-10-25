extends SceneTree
## Tela do Tiro (Cuidar é crescer, etapa 03): balão do desejo, anéis que pedem, aviso de momento,
## painel em bolinhas e só quatro abas. Regras reais; sem acesso ao save pessoal.
## Com `-- --shots`, grava as capturas das telas mexidas nas três resoluções (precisa de janela).
var state: Node
var main: Control
var failures := 0
var out_dir := ""
var WISH: Script

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CARE_UI: " + message)

func frames(n: int = 6) -> void:
	for i in n:
		await process_frame

func need(id: String, value: float) -> void:
	state.dog.commit(state.now())
	state.dog.needs[id] = value

func all_needs(value: float) -> void:
	for id: String in ["hunger", "happiness", "hygiene", "energy"]:
		need(id, value)

func to_period(id: String) -> void:
	var guard := 0
	while not state.moment_period().ends_with(":" + id) and guard < 100:
		state.advance_clock(3600)
		guard += 1

func changed() -> void:
	state.update_wishes()
	state._changed()

func shot(id: String) -> void:
	if out_dir == "": return
	await frames(8)
	(main.get("_toast") as Control).hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("%s_%d.png" % [id, root.size.x]))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	WISH = load("res://scripts/ui/wish_ui.gd")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	var shots := "--shots" in OS.get_cmdline_user_args()
	if shots:
		out_dir = ProjectSettings.globalize_path("res://../build/screenshots/cuidado03")
		DirAccess.make_dir_recursive_absolute(out_dir)
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	state.progress.seen.intro = true
	state.growth.phase = "puppy"
	state.progress.claimed_quests["lais_bed"] = true
	to_period("morning")
	all_needs(100.0)
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	var pet: Control = main.find_child("PetScreen", true, false)
	var events := root.get_node("Events")
	# O humor dura três segundos, não reaparece a cada atualização e pode ser revisto por toque.
	var mood: Control = pet.find_child("MoodBubble", true, false)
	pet.call("_show_mood")
	pet.call("_process", 2.9)
	check(mood.visible, "humor permanece antes de três segundos")
	pet.call("_process", 0.11)
	check(not mood.visible, "humor some após três segundos com Menos animação")
	pet.call("_refresh")
	check(not mood.visible, "humor igual não reaparece no tique")
	var mood_touch := InputEventMouseButton.new()
	mood_touch.button_index = MOUSE_BUTTON_LEFT
	mood_touch.pressed = true
	pet.call("_on_dog_input", mood_touch)
	check(mood.visible, "toque no Tiro revela a pílula de humor")
	mood_touch.pressed = false
	pet.call("_on_dog_input", mood_touch)

	# --- Abas: só Tiro · Mapa · Missões · Mochila, sem tela nem nó de vínculo ---
	check(main.find_child("WishesTab", true, false) == null and main.find_child("WishesScreen", true, false) == null, "aba e tela Desejos saíram")
	var tabs := main.find_child("Tabs", true, false)
	var names: Array[String] = []
	for tab: Node in tabs.get_children():
		names.append(tab.name)
	check(names == ["PetTab", "MapTab", "TasksTab", "BagTab"], "quatro abas: " + str(names))
	check(not ResourceLoader.exists("res://scenes/ui/wishes_screen/wishes_screen.tscn"), "cena da aba apagada")
	check(main.find_children("*Bond*", "", true, false).is_empty() and pet.find_child("BondChip", true, false) == null, "nenhum nó de vínculo")

	# --- Balão do desejo: aparece com o desejo e some ao atender ---
	var bubble: Button = pet.find_child("WishBubble", true, false)
	changed()
	await frames()
	check(state.wish_id() == "pet" and bubble.visible, "primeiro desejo (carinho) aparece no balão")
	check((pet.find_child("WishSpark", true, false) as Control).visible and state.call("wish_pillar") == "brave", "balão marca com estrela o desejo que vale momento de Coragem")
	bubble.pressed.emit()
	await frames()
	var card := main.find_child("WishCard", true, false)
	check(card != null and card.find_child("WishPrize", true, false) != null, "tocar mostra o pedido e o prêmio")
	check(card.find_child("WishTake", true, false) == null and card.find_child("WishGo", true, false) == null, "carinho ainda por fazer: sem Pegar nem Ir")
	await shot("pet_wish_card")
	main.find_child("PopoverCatcher", true, false).free()

	# --- Passeio é fora da tela: o cartão traz Ir ---
	state.wishes.current = {"id": "walk", "item": "", "period": state.wishes.period, "progress": 0, "since": state.now()}
	state._changed()
	await frames()
	bubble.pressed.emit()
	await frames()
	check(main.find_child("WishGo", true, false) != null, "desejo de passeio mostra Ir")
	main.find_child("PopoverCatcher", true, false).free()
	state.wishes.current = {"id": "pet", "item": "", "period": state.wishes.period, "progress": 0, "since": state.now()}
	state._changed()

	# --- Anéis: o que pede pulsa e mostra o pilar; satisfeito fica normal ---
	await frames()
	for id: String in ["hunger", "happiness", "hygiene", "energy"]:
		check(not (main.find_child("NeedPillar_" + id, true, false) as Control).visible, "satisfeito sem ícone: " + id)
	need("hunger", 30)
	need("hygiene", 30)
	need("energy", 30)
	state._changed()
	await frames()
	var body_mark: Control = main.find_child("NeedPillar_hunger", true, false)
	check(body_mark.visible and (body_mark.get_parent() as RingProgress).color == Palette.ALERT, "fome pede: anel vermelho e pontinho")
	check((main.find_child("NeedPillar_hygiene", true, false) as Control).visible, "higiene pede: pontinho")
	check((main.find_child("NeedPillar_energy", true, false) as Control).visible, "energia pedindo também tem pontinho")
	check(pet.get("_pulses").is_empty(), "pedido sem contorno pulsante (desligado)")
	await shot("pet_rings")
	all_needs(100.0)
	state._changed()
	await frames()
	check(pet.get("_pulses").is_empty() and not body_mark.visible, "satisfeito de novo: anel normal")

	# --- Avatar do HUD: ícone do desejo, senão da necessidade que pede ---
	var ask: TextureRect = main.find_child("AvatarAsk", true, false)
	check(ask.visible and ask.texture == WISH.call("icon", "pet"), "avatar mostra o desejo ativo")
	state.wishes.current = {}
	need("hunger", 30)
	state._changed()
	await frames()
	check(ask.visible and ask.texture == root.get_node("Database").call("need_icon", "hunger"), "sem desejo, avatar mostra a necessidade pedindo")
	all_needs(100.0)
	state._changed()
	await frames()
	check(not ask.visible, "nada pedindo: avatar limpo")

	# --- Aviso de momento e anel do avatar ---
	Motion.reduced = false
	state.wishes.current = {"id": "pet", "item": "", "period": state.wishes.period, "progress": 0, "since": state.now()}
	state.growth.phase_moments = {"brave": 0, "smart": 0, "coat": 0}
	state._changed()
	await frames()
	var ring: RingProgress = main.find_child("XpRing", true, false)
	var before := ring.progress
	need("happiness", 40)
	state.pet()
	await frames(3)
	var notice: PanelContainer = main.find_child("MomentNotice", true, false)
	check(notice.visible and (main.find_child("MomentText", true, false) as Label).text == "Momento de Coragem!", "aviso Momento de Coragem!")
	await create_timer(0.7).timeout
	check(ring.progress > before, "anel do avatar avançou (%f → %f)" % [before, ring.progress])
	await shot("moment_notice")
	await create_timer(1.2).timeout
	check(not notice.visible, "aviso some sozinho")
	# Momento vindo de passeio, mundo ou desejo usa o mesmo aviso.
	events.moment_gained.emit("smart", "wish:play")
	await frames(3)
	check(notice.visible and (main.find_child("MomentText", true, false) as Label).text == "Momento de Esperteza!", "aviso também para momento do desejo")
	await create_timer(1.4).timeout
	Motion.reduced = true

	# --- Atender some com o balão ---
	state.wishes.current = {"id": "pet", "item": "", "period": state.wishes.period, "progress": int(state.progress.stat("pet")) - 1, "since": state.now()}
	state._changed()
	await frames()
	check(state.wish_error() == "" and bubble.visible, "desejo cumprido continua no balão")
	bubble.pressed.emit()
	await frames()
	var take: Button = main.find_child("WishTake", true, false)
	check(take != null, "pronto: Pegar")
	var moments_before := int(state.growth.moments.get("brave", 0))
	take.pressed.emit()
	await frames()
	check(state.wish_id() == "" and not bubble.visible, "atender tira o balão")
	check(int(state.growth.moments.get("brave", 0)) == moments_before + 1, "atender deu o momento")
	check(main.find_child("WishCard", true, false) == null, "cartão fechou")

	# --- Painel de crescimento e caderninho: bolinhas e de onde vêm ---
	state.growth.phase_moments = {"brave": 2, "smart": 0, "coat": 0}
	state._changed()
	var panel: Control = load("res://scripts/ui/growth_ui.gd").panel()
	events.sheet_requested.emit("Crescimento", panel)
	await frames(10)
	var dots := panel.find_child("GrowthDots_brave", true, false)
	check(dots != null and dots.get_child_count() == 3, "Coragem pede 3 bolinhas")
	var filled := 0
	for dot: Node in dots.get_children():
		if bool(dot.get_meta("filled", false)): filled += 1
	check(filled == 2, "2 bolinhas cheias (●●○)")
	check(panel.find_child("GrowthNextStep", true, false) != null, "próximo passo continua")
	await shot("growth_dots")
	events.sheet_close_requested.emit()
	await frames(10)
	var cares: Control = load("res://scripts/ui/pillar_ui.gd").panel()
	events.sheet_requested.emit("Cuidados do Tiro", cares)
	await frames(10)
	check(cares.find_child("MomentOrigins", true, false) != null and cares.find_child("Origin_pet", true, false) != null, "lista de onde vêm os momentos")
	check(cares.find_child("OriginGo_walk", true, false) != null, "fonte com lugar tem Ir")
	check(cares.find_child("PetGrowthHint", true, false) == null and cares.find_child("PlayGrowthHint", true, false) == null, "sem texto de recarga")
	var dots_brave := cares.find_child("PillarDots_brave", true, false)
	check(dots_brave != null and dots_brave.get_child_count() == 3, "caderninho: Coragem em bolinhas")
	await shot("cares")
	events.sheet_close_requested.emit()
	await frames(10)

	print("CARE UI TEST: ", "PASS" if failures == 0 else "FAIL")
	main.queue_free()
	await frames()
	quit(0 if failures == 0 else 1)
