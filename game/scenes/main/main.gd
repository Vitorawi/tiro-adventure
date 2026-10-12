extends Control
## Casca do jogo: barra superior (nível/moedas), telas (Pet e Casa),
## abas inferiores, painel inferior (Sheet) e mensagens rápidas (toast).

@onready var _screens := {
	&"pet": %PetScreen,
	&"house": %House,
}
@onready var _tabs := {
	&"pet": %PetTab,
	&"house": %HouseTab,
}
@onready var _level_label: Label = %LevelLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _toast: Label = %Toast

var _toast_tween: Tween


func _ready() -> void:
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(show_screen.bind(id))
	Events.screen_requested.connect(show_screen)
	Events.toast_requested.connect(_show_toast)
	Events.state_changed.connect(_refresh_top_bar)
	Events.update_available.connect(%UpdateBanner.show)
	%UpdateBanner.pressed.connect(PwaUpdater.apply_update)
	%UpdateBanner.visible = PwaUpdater.update_ready
	%VersionLabel.text = "v%s %s  " % [Database.version.get("version", "?"), Database.version.get("date", "")]
	_toast.modulate.a = 0.0
	_refresh_top_bar()
	show_screen(&"pet")


func show_screen(id: StringName) -> void:
	for screen_id: StringName in _screens:
		_screens[screen_id].visible = screen_id == id
		_tabs[screen_id].button_pressed = screen_id == id


func _refresh_top_bar() -> void:
	_level_label.text = "Nível %d  (%d/%d XP)" % [GameState.level, GameState.xp, GameState.xp_to_next_level()]
	_coins_label.text = "%d moedas" % GameState.coins


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
