class_name DevPanel
extends RefCounted
## Painel "Ferramentas DEV" (só na versão dev; aberto pelo selo DEV da barra superior).
## Cada botão chama um GameState.dev_*() ou o SaveManager. Ver docs/DEPLOY.md ("Versão dev").

const PAGES := {"resources": "Recursos", "progress": "Progresso", "time": "Tempo", "save": "Save"}

static var _page: String = "resources"
## Toque duplo para recomeçar do zero: guarda até quando o segundo toque vale.
static var _reset_armed_until: float = 0.0


static func panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		_tabs(box)
		match _page:
			"progress":
				_progress(box)
			"time":
				_time(box)
			"save":
				_save(box)
			_:
				_resources(box)
	)


static func _tabs(box: VBoxContainer) -> void:
	var row := _grid(box, 4)
	for id: String in PAGES:
		var tab := UiKit.button(PAGES[id], func() -> void:
			_page = id
			(box as SheetBuilder.LiveBox).refresh())
		tab.custom_minimum_size = Vector2(0, 40)
		tab.add_theme_font_size_override("font_size", 16)
		tab.disabled = id == _page
		row.add_child(tab)


static func _grid(box: VBoxContainer, columns: int = 2) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	return grid


## Botão compacto que executa a ação e mostra um aviso.
static func _tool(grid: Container, text: String, action: Callable, done: String = "Feito!") -> void:
	var button := UiKit.button(text, func() -> void:
		var result: Variant = action.call()
		Events.toast_requested.emit(result if result is String and result != "" else done))
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # textos longos não alargam o painel
	button.add_theme_font_size_override("font_size", 16)
	grid.add_child(button)


static func _section(box: VBoxContainer, title: String, hint: String = "") -> void:
	box.add_child(UiKit.label(title, &"SectionLabel"))
	if hint != "":
		box.add_child(UiKit.label(hint, &"SmallLabel"))


static func _resources(box: VBoxContainer) -> void:
	_section(box, "Moedas", "Você tem %d." % GameState.coins)
	var coins := _grid(box, 3)
	for amount: int in [100, 1000, 10000]:
		_tool(coins, "+%d" % amount, GameState.dev_add_coins.bind(amount))

	_section(box, "Mochila", "Soma em todos os itens do tipo.")
	var items := _grid(box)
	_tool(items, "+10 de tudo", GameState.dev_add_items.bind(10, ""))
	_tool(items, "+10 materiais", GameState.dev_add_items.bind(10, "material"))
	_tool(items, "+10 colheitas", GameState.dev_add_items.bind(10, "crop"))
	_tool(items, "+10 comidas", GameState.dev_add_items.bind(10, "food"))

	_section(box, "Tiro")
	var dog := _grid(box)
	_tool(dog, "Necessidades 100%", GameState.dev_fill_needs)
	_tool(dog, "Abrir mochila", func() -> void:
		Events.sheet_requested.emit("Mochila", SheetBuilder.inventory_view()), "")


static func _progress(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	_section(box, "Capítulo atual", chapter.get("name", ""))
	_tool(box, "Concluir passo atual da história", GameState.dev_complete_main_step)
	_tool(box, "Rever introdução (Laís chega com o Tiro)", func() -> void:
		Events.sheet_close_requested.emit()
		(Engine.get_main_loop() as SceneTree).current_scene.add_child(IntroScene.new()), "")

	_section(box, "Atributos", "Sobe todos para pelo menos o nível escolhido.")
	var skills := _grid(box, 4)
	var top := int(Database.progression.settings.max_skill_level)
	for target: int in [3, 5, 10, top]:
		_tool(skills, "Máx." if target == top else "Nív. %d" % target, GameState.dev_set_skills.bind(target))

	_section(box, "Pular para o capítulo", "Libera de graça tudo o que vem antes (melhorias, missões e atributos exigidos).")
	var chapters: Array = Database.progression.chapters
	var jumps := _grid(box)
	for i in chapters.size():
		_tool(jumps, "%d. %s" % [i + 1, chapters[i].name], GameState.dev_jump_to_chapter.bind(i))
	_tool(jumps, "%d. %s" % [chapters.size() + 1, Database.progression.final_chapter.name], GameState.dev_jump_to_chapter.bind(chapters.size()))
	var all := _grid(box, 1)
	_tool(all, "Liberar TUDO (melhorias, terrenos, missões, coleção, atributos máx.)", GameState.dev_unlock_everything)

	_section(box, "Melhorias", "Libera uma melhoria e o que ela exige, sem custo.")
	var upgrades := _grid(box)
	for id: String in Database.progression.upgrades:
		if not GameState.has_upgrade(id):
			_tool(upgrades, Database.progression.upgrades[id].name, GameState.dev_grant_upgrade.bind(id))

	_section(box, "Missões", "Conclui (com recompensa) a missão e as anteriores.")
	var quests := _grid(box, 1)
	for id: String in Database.quests:
		if not GameState.progress.claimed_quests.has(id):
			var quest: Dictionary = Database.quests[id]
			var where := "%d." % int(quest.chapter) if quest.has("chapter") else str(Database.npcs.get(quest.npc, {}).get("name", "")) + " ·"
			_tool(quests, "%s %s" % [where, quest.name], GameState.dev_complete_quest.bind(id))
	_section(box, "Diárias e semanais", "Zera o progresso e as recompensas do dia e da semana.")
	_tool(_grid(box, 1), "Recomeçar diárias e semanais", GameState.dev_restart_routines)


static func _time(box: VBoxContainer) -> void:
	_section(box, "Terminar agora", "Plantações, estações, rota e recargas ficam prontas.")
	var finish := _grid(box, 1)
	_tool(finish, "Terminar todos os timers", GameState.dev_finish_timers)

	_section(box, "Avançar o tempo", "Como se o jogo ficasse fechado: necessidades caem, plantas crescem, filas andam.")
	var shift := _grid(box, 4)
	for seconds: int in [600, 3600, 4 * 3600, 12 * 3600]:
		_tool(shift, "+" + TimeText.short(seconds).replace(" 00", ""), GameState.dev_advance_time.bind(float(seconds)))


static func _save(box: VBoxContainer) -> void:
	_section(box, "Versão dev", "Canal: %s · versão %s\nSave separado: %s" % [BuildInfo.channel(), Database.version.get("version", "?"), BuildInfo.save_path()])
	box.add_child(UiKit.label("O progresso da versão publicada nunca é alterado por aqui.", &"SmallLabel"))
	var tools := _grid(box, 1)
	_tool(tools, "Copiar o save da versão publicada", SaveManager.load_production_copy, "Save publicado copiado para a versão dev")
	_tool(tools, "Salvar agora", SaveManager.save_game, "Salvo")
	var armed := Time.get_ticks_msec() / 1000.0 < _reset_armed_until
	_tool(tools, "Toque de novo para APAGAR o save dev" if armed else "Recomeçar do zero (save dev)", func() -> String:
		if Time.get_ticks_msec() / 1000.0 < _reset_armed_until:
			_reset_armed_until = 0.0
			SaveManager.delete_save()
			return "Save dev apagado: jogo novo"
		_reset_armed_until = Time.get_ticks_msec() / 1000.0 + 4.0
		(box as SheetBuilder.LiveBox).refresh()
		return "Toque de novo em 4 s para confirmar")
