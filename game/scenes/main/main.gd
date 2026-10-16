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
@onready var _hud: Hud = %TopBar
@onready var _toast: Control = %Toast
@onready var _toast_text: Label = %ToastText
@onready var _toast_icon: TextureRect = %ToastIcon

## Aviso (toast) desce de y = TOAST_FROM_Y até TOAST_Y, logo abaixo do HUD; com o banner de atualização aberto, desce mais.
const TOAST_FROM_Y := -40.0
const TOAST_Y := 68.0
const TOAST_BELOW_BANNER_Y := 116.0
const TOAST_MAX_WIDTH := 320.0
const TOAST_HOLD := 1.6
const TOAST_FADE := 0.3

var _toast_tween: Tween
var _faces: Dictionary = {}  # id da aba → NavTab
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
		# Ícone em cima e nome embaixo; a aba ativa ganha o círculo e sobe (as cinco cabem em 360 px).
		_faces[id] = NavTab.attach(_tabs[id])
		_tabs[id].pressed.connect(func() -> void: Motion.bounce(_faces[id].icon_node()))
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
	# Versão dev: selo DEV abre as ferramentas de teste (BuildInfo / DevPanel).
	# (A versão e o atalho de atualização moraram no HUD; agora ficam no rodapé das Configurações.)
	_hud.dev_button.visible = BuildInfo.is_dev()
	_hud.dev_button.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Ferramentas DEV", DevPanel.panel()))
	UiKit.tint_bar(_hud.xp_bar, Palette.GOLD)
	_hud.refresh(false)
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


## A aba Mapa retoma o mundo; tocar de novo abre o carrossel.
func _on_tab_pressed(id: StringName) -> void:
	if id == &"map" and _current_screen == &"map":
		%WorldsScreen.show_map()
	elif id == &"map":
		%WorldsScreen.close_map()
	show_screen(id)


func _on_world_requested(world_id: String, place: String) -> void:
	%WorldsScreen.enter(world_id, place)
	show_screen(&"map")


## Bolinha com o número de coisas prontas (missões e colheitas/produções) na aba Missões.
func _build_tasks_badge() -> void:
	_tasks_badge = Label.new()
	_tasks_badge.theme_type_variation = &"BadgeLabel"
	_tasks_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%TasksTab.add_child(_tasks_badge)
	_map_badge = _tasks_badge.duplicate() as Label
	_map_badge.name = "NpcMapBadge"
	%MapTab.add_child(_map_badge)
	_wishes_badge = _tasks_badge.duplicate() as Label
	_wishes_badge.name = "WishesBadge"
	%WishesTab.add_child(_wishes_badge)
	# O selo fica no canto de cima, à direita do ÍCONE (não da aba): centro do ícone + (14, −20).
	for pair: Array in [[&"tasks", _tasks_badge], [&"map", _map_badge], [&"wishes", _wishes_badge]]:
		var tab: Button = _tabs[pair[0]]
		var face: NavTab = _faces[pair[0]]
		var badge: Label = pair[1]
		var place := func() -> void: badge.position = face.icon_center() + Vector2(14.0, -20.0) - badge.size / 2.0
		tab.resized.connect(place)
		badge.resized.connect(place)
		tab.toggled.connect(func(_pressed: bool) -> void: place.call())
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
	_map_badge.modulate = UiKit.GOOD if npc_status == "ready" else Palette.GOLD
	var count := GameState.ready_quest_count() + GameState.ready_routine_count()
	for i in GameState.usable_plot_indices():
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


func _refresh_top_bar() -> void:
	_hud.refresh()


## Aviso: pílula que desce de cima até logo abaixo do HUD, fica 1,6 s e some em 0,3 s.
## Aviso novo com outro ainda na tela: troca o texto, dá um pulinho e reinicia o tempo.
func _show_toast(text: String) -> void:
	var on_screen := _toast.visible and _toast.modulate.a > 0.0
	_toast_text.text = text
	_toast_icon.visible = text.begins_with("Missão concluída")
	if _toast_icon.visible:
		_toast_icon.texture = UiKit.ui_icon("ui_check")
	# Largura do texto (até 320 com o ícone e as margens); só então a pílula assume o tamanho certo.
	var font := _toast_text.get_theme_font("font")
	var font_size := _toast_text.get_theme_font_size("font_size")
	var limit := TOAST_MAX_WIDTH - 20.0 - (38.0 if _toast_icon.visible else 0.0)
	_toast_text.custom_minimum_size.x = minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2.0, limit)
	_toast_text.custom_minimum_size.y = 0.0
	_toast.reset_size()
	_toast.pivot_offset = _toast.size / 2.0
	var target_y := TOAST_BELOW_BANNER_Y if %UpdateBanner.visible else TOAST_Y
	if _current_screen == &"map":
		target_y = maxf(target_y, %WorldsScreen.toast_top())
	_toast.position.x = (size.x - _toast.size.x) / 2.0
	if _toast_tween:
		_toast_tween.kill()
	_toast.show()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	if on_screen:
		_toast.position.y = target_y
		Motion.bounce(_toast)
	elif Motion.reduced:
		_toast.position.y = target_y
	else:
		_toast.position.y = TOAST_FROM_Y
		_toast_tween.tween_property(_toast, "position:y", target_y, Motion.SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(TOAST_HOLD)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE)
	_toast_tween.tween_callback(_toast.hide)


func _refresh_guide() -> void:
	_refresh_tasks_badge()
	# Mochila só aparece quando a história a apresenta.
	%BagTab.visible = GameState.progress.feature_unlocked("bag")
	%WishesTab.visible = GameState.progress.feature_unlocked("wishes")
	if GameState.progress.claimed_quests.has("welcome"):
		if _tasks_pulse:
			_tasks_pulse.kill()
			_tasks_pulse = null
			_faces[&"tasks"].lift_node().scale = Vector2.ONE
	elif not _tasks_pulse:
		# Chama o olhar para a aba Missões pulsando o ícone (sem frase na tela do Tiro).
		_tasks_pulse = Motion.pulse(_faces[&"tasks"].lift_node())


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
