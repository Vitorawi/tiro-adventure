extends Control
## Casca do jogo: barra superior (nível/moedas, selo DEV), abas Tiro / Mapa (mundos) /
## Tarefas / Mochila, painel inferior (Sheet) e mensagens rápidas (toast).
## Events.world_requested (botões "Ir") troca para o Mapa e entra no mundo pedido.

@onready var _screens := {
	&"pet": %PetScreen,
	&"map": %WorldsScreen,
	&"tasks": %TasksScreen,
	&"bag": %BagScreen,
}
@onready var _tabs := {
	&"pet": %PetTab,
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
var _tasks_pulse: Tween
var _celebration: CanvasLayer
var _worlds_open: Dictionary = {}
var _new_worlds: PackedStringArray = []


func _ready() -> void:
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(_on_tab_pressed.bind(id))
		# Ícone em cima e texto embaixo: com 4 abas, o texto ao lado do ícone não cabe.
		_tabs[id].expand_icon = true
		_tabs[id].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tabs[id].vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		_tabs[id].add_theme_constant_override("icon_max_width", 28)
		_tabs[id].add_theme_font_size_override("font_size", 18)
	Events.screen_requested.connect(show_screen)
	Events.world_requested.connect(_on_world_requested)
	_celebration = load("res://scenes/ui/celebration/celebration.tscn").instantiate()
	add_child(_celebration)
	for world: String in Database.worlds:
		_worlds_open[world] = Places.world_error(world) == ""
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
	%DevButton.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Ferramentas DEV", DevPanel.panel()))
	_toast.modulate.a = 0.0
	UiKit.tint_bar(%XpBar, Color(1, 0.82, 0.3))
	_refresh_top_bar()
	show_screen(&"pet")


func show_screen(id: StringName) -> void:
	_current_screen = id
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


## Bolinha com o número de coisas prontas (missões e colheitas/produções) na aba Tarefas.
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
	_tasks_badge.position = Vector2(54, 2)
	%TasksTab.add_child(_tasks_badge)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_tasks_badge)
	add_child(timer)
	_refresh_tasks_badge()


func _refresh_tasks_badge() -> void:
	var count := GameState.ready_quest_count()
	for i in GameState.accessible_plots():
		if GameState.plot_status(i) == "ready":
			count += 1
	for station_id: String in GameState.stations:
		count += GameState.station(station_id).ready_count(GameState.now())
	if not GameState.progress.activity.is_empty() and GameState.activity_remaining() == 0:
		count += 1
	_tasks_badge.text = str(count)
	_tasks_badge.visible = count > 0


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
	for world: String in Database.worlds:
		if not _worlds_open.get(world, false) and Places.world_error(world) == "":
			_worlds_open[world] = true
			_new_worlds.append(Database.worlds[world].name)
	var text := "Missão concluída!"
	if Database.quests[id].get("kind", "side") == "main":
		var next := GameState.progress.current_main_quest()
		text += " Próximo: " + str(Database.quests[next].name) if next != "" else " História completa!"
	_show_toast.call_deferred(text)


func _on_chapter_completed(index: int) -> void:
	Events.sheet_close_requested.emit()
	_celebration.call_deferred("show_chapter", index, _new_worlds.duplicate())
	_new_worlds.clear()
