extends Control
## Casca do jogo: barra superior (nível/moedas, selo DEV), abas Tiro / Desejos / Mapa (mundos) /
## Missões / Mochila, painel inferior (Sheet) e mensagens rápidas (toast).
## Events.world_requested (botões "Ir") troca para o Mapa e entra no mundo pedido.

@onready var _screens := {
	&"pet": %PetScreen,
	&"wishes": %WishesScreen,
	&"map": %WorldsScreen,
	&"tasks": %TasksScreen,
	&"bag": %BagScreen,
}
@onready var _tabs := {
	&"pet": %PetTab,
	&"wishes": %WishesTab,
	&"map": %MapTab,
	&"tasks": %TasksTab,
	&"bag": %BagTab,
}
@onready var _level_label: Label = %LevelLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _toast: Label = %Toast

var _toast_tween: Tween
var _current_screen: StringName = &""
var _tasks_badge: Label
var _map_badge: Label
var _wishes_badge: Label
var _tasks_pulse: Tween
var _celebration: CanvasLayer
## Capítulo concluído nesta leva de missões (0 = nenhum); o anúncio sai uma vez, no fim do frame.
var _chapter_done: int = 0
var _announce_pending: bool = false
## Cartões modais esperando a vez (nível, bem-vindo de volta): um por vez, depois da introdução/comemorações.
var _modal_queue: Array[Callable] = []
var _welcome: CanvasLayer
var _walk_result: CanvasLayer
var _intro: Node
var _left_at: float = 0.0
var _pending_level: Dictionary = {}


func _ready() -> void:
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(_on_tab_pressed.bind(id))
		# Ícone em cima e texto embaixo: as cinco abas cabem na largura de 360 px.
		_tabs[id].expand_icon = true
		_tabs[id].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tabs[id].vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		_tabs[id].add_theme_constant_override("icon_max_width", 28)
		_tabs[id].add_theme_font_size_override("font_size", 18)
	Events.screen_requested.connect(show_screen)
	Events.world_requested.connect(_on_world_requested)
	_celebration = load("res://scenes/ui/celebration/celebration.tscn").instantiate()
	add_child(_celebration)
	add_child(CollectFx.new())
	_welcome = load("res://scenes/ui/welcome_back/welcome_back.tscn").instantiate()
	add_child(_welcome)
	_walk_result = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	add_child(_walk_result)
	Events.walk_collected.connect(func(result: Dictionary) -> void:
		_queue_modal(func() -> void: _walk_result.show_result(result))
		_queue_modal(func() -> void: _announce()))
	Events.trick_learned.connect(func(id: String) -> void:
		_queue_modal(func() -> void: _celebration.show_trick(id)))
	Events.treasure_opened.connect(func(rewards: Dictionary) -> void:
		_queue_modal(func() -> void: _celebration.show_treasure(rewards)))
	Events.cosmetic_received.connect(func(id: String) -> void:
		_queue_modal(func() -> void:
			_walk_result.show_result({"kind": "sewing", "name": "Roupa nova", "rare": id, "collections": [id]})))
	Events.level_up.connect(_on_level_up)
	Events.bond_up.connect(_on_bond_up)
	Events.find_discovered.connect(func(result: Dictionary) -> void:
		_queue_modal(func() -> void: _celebration.show_find(result)))
	var modal_timer := Timer.new()
	modal_timer.wait_time = 0.3
	modal_timer.autostart = true
	modal_timer.timeout.connect(_flush_modals)
	add_child(modal_timer)
	Events.quest_completed.connect(_on_quest_completed)
	Events.chapter_completed.connect(_on_chapter_completed)
	Events.state_changed.connect(_refresh_guide)
	_build_tasks_badge()
	_refresh_guide()
	Events.toast_requested.connect(_show_toast)
	Events.state_changed.connect(_refresh_top_bar)
	Events.update_available.connect(%UpdateBanner.show)
	%UpdateBanner.pressed.connect(PwaUpdater.apply_update)
	%UpdateBanner.visible = PwaUpdater.update_ready
	%VersionLabel.text = "v%s %s  " % [Database.version.get("version", "?"), Database.version.get("date", "")]
	# Atalho de emergência: tocar na versão força a atualização.
	%VersionLabel.gui_input.connect(func(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		if button and button.pressed:
			PwaUpdater.apply_update())
	# Versão dev: selo DEV abre as ferramentas de teste (BuildInfo / DevPanel).
	%DevButton.visible = BuildInfo.is_dev()
	_build_settings_button()
	%DevButton.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Ferramentas DEV", DevPanel.panel()))
	_toast.modulate.a = 0.0
	UiKit.tint_bar(%XpBar, Color(1, 0.82, 0.3))
	_refresh_top_bar()
	show_screen(&"pet")
	# Jogo novo: a Laís chega com o Tiro e apresenta a casa (uma vez só).
	if IntroScene.should_show():
		_intro = IntroScene.new()
		add_child(_intro)
	# Voltou depois de um tempo (ou abriu o jogo): presente do dia e o que ficou pronto.
	var saver := get_node_or_null("/root/SaveManager")
	var saved_at: float = float(saver.last_saved_at) if saver else 0.0
	_maybe_welcome(GameState.now() - saved_at if saved_at > 0.0 else 0.0)


## Ao ir para o segundo plano guarda a hora; ao voltar, mostra o cartão se passou tempo suficiente.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_left_at = GameState.now()
	elif (what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED) and _left_at > 0.0:
		var away := GameState.now() - _left_at
		_left_at = 0.0
		_maybe_welcome(away)


func _maybe_welcome(away_seconds: float) -> void:
	if away_seconds < float(Database.progression.settings.get("welcome_back_seconds", 300)):
		return
	_queue_modal(func() -> void:
		if WelcomeBack.has_content():
			_welcome.open())


func _on_level_up(level: int, rewards: Dictionary) -> void:
	# Níveis seguidos antes do cartão abrir viram um só (o último, com a soma).
	var first := _pending_level.is_empty()
	var sum: Dictionary = _pending_level.get("rewards", {"coins": 0, "affection": 0, "items": {}})
	sum["coins"] = int(sum.coins) + int(rewards.get("coins", 0))
	sum["affection"] = int(sum.affection) + int(rewards.get("affection", 0))
	for id: String in rewards.get("items", {}):
		sum.items[id] = int(sum.items.get(id, 0)) + int(rewards.items[id])
	_pending_level = {"level": level, "rewards": sum}
	if first:
		_queue_modal(func() -> void:
			_celebration.show_level(int(_pending_level.level), _pending_level.rewards)
			_pending_level = {})


## Vínculo novo: cartão com o presente (já entregue), na fila dos cartões.
func _on_bond_up(level: int, rewards: Dictionary) -> void:
	_queue_modal(func() -> void:
		_celebration.show_bond(level, rewards))


func _queue_modal(callback: Callable) -> void:
	_modal_queue.append(callback)


## Abre o próximo cartão quando nada está na tela (introdução, comemoração ou outro cartão).
func _flush_modals() -> void:
	if _modal_queue.is_empty() or _announce_pending or _chapter_done > 0:
		return
	if (is_instance_valid(_intro) and _intro.is_inside_tree()) or _celebration.visible or _welcome.visible or _walk_result.visible:
		return
	_modal_queue.pop_front().call()


func show_screen(id: StringName) -> void:
	_current_screen = id
	GameState.note_screen_opened(String(id))
	for screen_id: StringName in _screens:
		_screens[screen_id].visible = screen_id == id
		_tabs[screen_id].button_pressed = screen_id == id


## Tocar de novo na aba Mapa (já nela) volta para a lista de mundos.
func _on_tab_pressed(id: StringName) -> void:
	if id == &"map" and _current_screen == &"map":
		%WorldsScreen.show_map()
	show_screen(id)


func _on_world_requested(world_id: String, place: String) -> void:
	show_screen(&"map")
	%WorldsScreen.enter(world_id, place)


## Bolinha com o número de coisas prontas (missões e colheitas/produções) na aba Missões.
func _build_tasks_badge() -> void:
	_tasks_badge = Label.new()
	_tasks_badge.add_theme_font_size_override("font_size", 16)
	_tasks_badge.add_theme_color_override("font_color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.78, 0.22, 0.18)
	box.set_corner_radius_all(10)
	box.content_margin_left = 6
	box.content_margin_right = 6
	_tasks_badge.add_theme_stylebox_override("normal", box)
	_tasks_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%TasksTab.add_child(_tasks_badge)
	_map_badge = _tasks_badge.duplicate() as Label
	_map_badge.name = "NpcMapBadge"
	%MapTab.add_child(_map_badge)
	_wishes_badge = _tasks_badge.duplicate() as Label
	_wishes_badge.name = "WishesBadge"
	%WishesTab.add_child(_wishes_badge)
	# O selo fica no canto de cima, à direita do ícone (centrado na aba).
	for pair: Array in [[%TasksTab, _tasks_badge], [%MapTab, _map_badge], [%WishesTab, _wishes_badge]]:
		var tab: Button = pair[0]
		var badge: Label = pair[1]
		var place := func() -> void: badge.position = Vector2(tab.size.x / 2.0 + 6.0, 0.0)
		tab.resized.connect(place)
		place.call()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_tasks_badge)
	add_child(timer)
	_refresh_tasks_badge()


func _refresh_tasks_badge() -> void:
	var npc_status := ""
	for npc_id: String in Database.npcs:
		if not GameState.progress.npc_visible(npc_id):
			continue
		var world_id := Database.npc_world(npc_id)
		if GameState.requirement_error(Database.worlds.get(world_id, {}).get("requirements", {})) != "":
			continue
		var badge := Places.npc_badge(npc_id)
		if badge == "ready":
			npc_status = "ready"
			break
		if badge == "new":
			npc_status = "new"
	_map_badge.text = "✓" if npc_status == "ready" else "!"
	_map_badge.visible = npc_status != ""
	_map_badge.modulate = UiKit.GOOD if npc_status == "ready" else Color("ffd23f")
	var count := GameState.ready_quest_count() + GameState.ready_routine_count()
	for i in GameState.accessible_plots():
		if GameState.plot_status(i) == "ready":
			count += 1
	for station_id: String in GameState.stations:
		count += GameState.station(station_id).ready_count(GameState.now())
	if not GameState.progress.activity.is_empty() and GameState.activity_remaining() == 0:
		count += 1
	_tasks_badge.text = str(count)
	_tasks_badge.visible = count > 0
	_wishes_badge.text = str(GameState.fulfillable_wish_count())
	_wishes_badge.visible = GameState.fulfillable_wish_count() > 0


## Engrenagem ao lado das moedas: abre as configurações (vários saves).
func _build_settings_button() -> void:
	var gear := Button.new()
	gear.name = "SettingsButton"
	gear.flat = true
	gear.icon = UiKit.ui_icon("settings")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(48, 48)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear.add_theme_constant_override("icon_max_width", 48)
	# Sem margens internas do botão: o ícone ocupa todo o espaço.
	for style: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		gear.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	gear.pressed.connect(SettingsPanel.open)
	%CoinsLabel.get_parent().add_child(gear)


func _refresh_top_bar() -> void:
	_level_label.text = "Nível %d" % GameState.level
	%XpBar.max_value = GameState.xp_to_next_level()
	%XpBar.value = GameState.xp
	_coins_label.text = str(GameState.coins)


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _refresh_guide() -> void:
	_refresh_tasks_badge()
	# Mochila só aparece quando a história a apresenta.
	%BagTab.visible = GameState.progress.feature_unlocked("bag")
	%WishesTab.visible = GameState.progress.feature_unlocked("wishes")
	if GameState.progress.claimed_quests.has("welcome"):
		if _tasks_pulse:
			_tasks_pulse.kill()
			_tasks_pulse = null
		%TasksTab.modulate = Color.WHITE
		%TasksTab.tooltip_text = ""
	elif not _tasks_pulse:
		%TasksTab.tooltip_text = "Comece por aqui!"
		_tasks_pulse = create_tween().set_loops()
		_tasks_pulse.tween_property(%TasksTab, "modulate", Color(1.0, 0.72, 0.32), 0.7)
		_tasks_pulse.tween_property(%TasksTab, "modulate", Color.WHITE, 0.7)


func _on_quest_completed(id: String) -> void:
	var text := "Missão concluída!"
	if Database.quests[id].get("kind", "main") == "main":
		var next := GameState.progress.current_main_quest()
		text += " Próximo: " + str(Database.quests[next].name) if next != "" else " História completa!"
	_show_toast.call_deferred(text)
	_schedule_announce()


func _on_chapter_completed(index: int) -> void:
	_chapter_done = index
	_schedule_announce()


func _schedule_announce() -> void:
	if not _announce_pending:
		_announce_pending = true
		_announce.call_deferred()


## Fim de capítulo e/ou novidades ("Novo!") numa só tela; depois ficam marcadas como vistas.
func _announce() -> void:
	_announce_pending = false
	var unlocks := GameState.new_unlocks()
	if _chapter_done > 0:
		Events.sheet_close_requested.emit()
		_celebration.show_chapter(_chapter_done, unlocks)
	elif not unlocks.is_empty():
		Events.sheet_close_requested.emit()
		_celebration.show_unlocks(unlocks)
	_chapter_done = 0
	if not unlocks.is_empty():
		GameState.mark_seen(unlocks)
