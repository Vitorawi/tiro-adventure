extends SceneTree
## Etapa 07: crescimento no HUD e nenhum prêmio/interface de nível do jogador.
var failures := 0
var state: Node
var db: Node
var main: Control

func _initialize() -> void:
	_run.call_deferred()
	create_timer(150).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HUD GROWTH: " + message)

func frames(n: int = 4) -> void:
	for i in n: await process_frame

func check_text(node: Node) -> void:
	for label: Label in node.find_children("*", "Label", true, false):
		check(not label.text.contains("XP") and not label.text.contains("Atributos") and not label.text.contains("Nível"), "sem texto antigo: " + label.text)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	Motion.reduced = true
	state.get("progress").seen.intro = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	var hud: Control = main.find_child("TopBar", true, false)
	check_text(main)
	var saves := VBoxContainer.new()
	load("res://scripts/ui/settings_panel.gd").call("_slot_card", saves, {"slot": 1, "active": false, "default": false, "finished": false, "chapter": 1, "chapters": 12, "coins": 10})
	check_text(saves)
	saves.free()
	var events := root.get_node("Events")
	var raised: Array = []
	events.level_up.connect(func(_level: int, _rewards: Dictionary) -> void: raised.append(true))
	var coins := int(state.get("coins"))
	state.call("_add_player_xp", 10000)
	check(state.get("level") == 1 and state.get("xp") == 10000 and raised.is_empty(), "XP soma sem subir nível ou emitir evento")
	check(state.get("coins") == coins and state.get("economy").granted.is_empty(), "nenhum presente ou recibo de nível")
	var persisted: Dictionary = state.call("to_dict")
	state.call("from_dict", persisted)
	check(state.get("level") == 1, "nível congelado ao recarregar")
	check(not db.get("progression").features.has("skills") and not state.get("progress").skills_visible(), "feature de atributos removida")
	for i in db.get("growth").phases.size():
		var phase: Dictionary = db.get("growth").phases[i]
		state.call("dev_set_phase", str(phase.id))
		if phase.id == "teething" and "--summary-shots" in OS.get_cmdline_user_args():
			state.get("growth").phase_moments = {"body": 34, "coat": 0, "smart": 19, "brave": 61}
		await frames()
		hud.refresh(false)
		check(hud.level_label.text == (str(i) if i > 0 else "•"), "número da fase " + phase.id)
		check(hud.avatar_button.icon.resource_path == str(state.call("dog_look").portrait), "retrato " + phase.id)
		check(is_equal_approx(float((hud.avatar_button.material as ShaderMaterial).get_shader_parameter("coat")), float(state.call("dog_look").coat)), "pelagem " + phase.id)
		var info: Dictionary = state.call("growth_info")
		var count: int = info.requirements.size()
		var fraction := 1.0 if count == 0 else float(count - int(load("res://scripts/ui/growth_ui.gd").call("missing", info))) / count
		check(is_equal_approx((hud.find_child("XpRing", true, false) as RingProgress).progress, fraction), "anel requisitos " + phase.id)
		hud.show_level_popover()
		await frames()
		var popover := main.get_node("PopoverCatcher")
		check_text(popover)
		check(popover.find_child("ViewGrowth", true, false).text == "Ver detalhes", "botão nomeia o destino")
		var surface := popover.get_node("Popover") as Control
		check(surface.get_global_rect().end.x <= main.get_global_rect().end.x + 1, "resumo cabe na largura")
		check(surface.get_global_rect().end.y <= main.get_global_rect().end.y + 1, "resumo cabe na altura")
		var grid := popover.find_child("GrowthQuickGrid", true, false)
		if not info.next.is_empty() and not info.ready:
			var pending: Array = info.requirements.filter(func(req: Dictionary) -> bool: return not req.done and req.type != "given")
			check(grid != null and grid.get_child_count() == pending.size(), "um ícone por requisito pendente")
			for req: Dictionary in info.requirements:
				check((popover.find_child("GrowthQuick_" + str(req.id), true, false) != null) == (not req.done and req.type != "given"), "não repete requisito pronto " + str(req.id))
		if "--summary-shots" in OS.get_cmdline_user_args():
			var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/growth_summary").simplify_path()
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("%s_%d.png" % [phase.id, root.size.x])) == OK, "captura do resumo " + str(phase.id))
		(popover.find_child("ViewGrowth", true, false) as Button).pressed.emit()
		await frames()
		check(main.find_child("GrowthPanel", true, false) != null, "Ver abre crescimento " + phase.id)
		events.sheet_close_requested.emit()
		await frames()
	# Pronto tem aviso vermelho explícito, sem movimento no avatar.
	state.call("dev_set_phase", "newborn")
	state.call("dev_complete_growth_reqs")
	Motion.reduced = false
	hud.refresh(false)
	var alert: Button = hud.find_child("GrowthReadyAlert", true, false)
	check(alert.visible and alert.text.contains("Crescer!"), "aviso explícito quando pode crescer")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		check(alert.get_global_rect().end.x < hud.find_child("CoinsColumn", true, false).global_position.x, "aviso cabe antes das moedas em %d" % viewport.x)
	check(hud.find_child("AvatarGroup", true, false).scale == Vector2.ONE, "avatar pronto permanece parado")
	Motion.reduced = true
	hud.refresh(false)
	check(alert.visible and hud.find_child("AvatarGroup", true, false).scale == Vector2.ONE, "aviso também aparece com menos animação")
	var ready_summary: Control = hud.show_level_popover()
	await frames()
	check(ready_summary.find_child("GrowthQuickGrid", true, false) == null, "pronto não lista pendências antigas")
	check(ready_summary.get("_tween") == null, "resumo permanece aberto para leitura")
	if "--summary-shots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/growth_summary").simplify_path()
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(folder.path_join("ready_%d.png" % root.size.x)) == OK, "captura do resumo pronto")
	ready_summary.call("close")
	await frames()
	# Todos os catálogos usam o mesmo construtor: XP e skill_xp nunca criam chips/textos.
	var ui := load("res://scripts/ui/progression_ui.gd")
	for id: String in db.get("recipes"):
		var recipe: Control = load("res://scripts/ui/station_tray.gd").call("recipe_detail", str(db.get("recipes")[id].station), id)
		root.add_child(recipe)
		check_text(recipe)
		recipe.free()
	for id: String in db.get("progression").orders:
		var detail := VBoxContainer.new()
		root.add_child(detail)
		load("res://scripts/ui/market_ui.gd").call("_order_detail", detail, id)
		check_text(detail)
		detail.free()
	for id: String in db.get("projects").projects:
		var project: Control = load("res://scripts/ui/project_ui.gd").call("panel", id)
		root.add_child(project)
		check_text(project)
		project.free()
	var obsolete := {"xp": 12, "player_xp": 13, "skill_xp": {"cooking": 100}}
	var empty: Control = ui.call("reward_chips", obsolete)
	check(empty.get_child_count() == 0 and ui.call("rewards_text", obsolete) == "", "nenhum chip/texto de XP ou atributo")
	empty.free()
	for table: Dictionary in [db.get("quests"), db.get("recipes"), db.get("progression").orders, db.get("projects").get("projects", {})]:
		for id: String in table:
			var chips: Control = ui.call("reward_chips", table[id].get("rewards", {}))
			check_text(chips)
			chips.free()
	for kind: String in ["daily", "weekly"]:
		for catalog: String in ["missions", "legacy"]:
			for routine_id: String in db.get("routines")[kind].get(catalog, {}):
				var chips: Control = ui.call("reward_chips", db.get("routines")[kind][catalog][routine_id].get("rewards", {}))
				check_text(chips)
				chips.free()
	check(db.get("recipes").treat_box.requirements.get("growth") == "explorer" and not db.get("recipes").treat_box.requirements.has("skills"), "caixa exige Aventureiro")
	state.call("dev_set_phase", "teething")
	check(state.call("requirement_error", {"growth": "explorer"}) != "", "Dentinhos não faz caixa")
	state.call("dev_set_phase", "explorer")
	check(state.call("requirement_error", {"growth": "explorer"}) == "", "Aventureiro faz caixa")
	# Rotina atual da fazenda não concede momentos avulsos ao recebê-la.
	state.call("reset")
	state.call("dev_set_phase", "puppy")
	state.get("dog").needs.hunger = 40
	state.call("dev_restart_routines")
	var routine := {"period": state.call("routine_period", "daily"), "catalog": 2, "base": {}, "targets": {"harvest": 1}}
	state.get("progress").routines["daily"] = routine
	routine["ids"] = ["harvest"]
	routine["claimed"] = {}
	state.get("progress").stats["harvest"] = 20
	var before: Dictionary = state.get("growth").moments.duplicate()
	check(state.call("claim_routine", "daily", "harvest") == "", "recebe rotina da fazenda")
	check(state.get("growth").moments == before, "rotinas não concedem pontos ou momentos avulsos")
	print("HUD GROWTH TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	main.queue_free()
	await frames()
	quit(1 if failures else 0)


