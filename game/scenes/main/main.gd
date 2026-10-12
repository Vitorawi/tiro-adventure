extends Control
## Casca do jogo: barra superior (nível/moedas, selo DEV), telas (Tiro, Casa,
## Sítio e Jornada), abas inferiores, painel inferior (Sheet) e mensagens rápidas (toast).

@onready var _screens := {
	&"pet": %PetScreen,
	&"house": %House,
	&"farm": %Farm,
	&"journey": %ProgressionScreen,
}
@onready var _tabs := {
	&"pet": %PetTab,
	&"house": %HouseTab,
	&"farm": %FarmTab,
	&"journey": %JourneyTab,
}
@onready var _level_label: Label = %LevelLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _toast: Label = %Toast

var _toast_tween: Tween


func _ready() -> void:
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(show_screen.bind(id))
		# Ícone em cima e texto embaixo: com 4 abas, "Jornada" ao lado do ícone não cabe.
		_tabs[id].expand_icon = true
		_tabs[id].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tabs[id].vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		_tabs[id].add_theme_constant_override("icon_max_width", 28)
		_tabs[id].add_theme_font_size_override("font_size", 18)
	Events.screen_requested.connect(show_screen)
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
	for screen_id: StringName in _screens:
		_screens[screen_id].visible = screen_id == id
		_tabs[screen_id].button_pressed = screen_id == id


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
