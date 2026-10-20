extends Control
## Casca do jogo: barra superior (crescimento/moedas, selo DEV), abas Tiro / Desejos / Mapa (mundos) /
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
## Foto que o aviso "Nova foto!" abre ao ser tocado ("" = aviso comum, que ignora o toque).
var _toast_photo: String = ""
## Fotos novas esperando a vez do aviso (depois de qualquer cartão, sem entrar na fila de cartões).
var _photo_queue: Array[String] = []
const PHOTO_TOAST := "Nova foto!"
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
## Cartões modais esperando a vez (crescimento, bem-vindo de volta): um por vez, depois da introdução/comemorações.
var _modal_queue: Array[Callable] = []
var _welcome: CanvasLayer
var _walk_result: CanvasLayer
var _growth_ceremony: GrowthCeremony
var _growth_queued: Dictionary = {}
var _intro: Node
var _left_at: float = 0.0


func _ready() -> void:
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(_on_tab_pressed.bind(id))
		# Ícone em cima e nome embaixo; a aba ativa ganha o círculo e sobe (as cinco cabem em 360 px).
		_faces[id] = NavTab.attach(_tabs[id])
		_tabs[id].pressed.connect(func() -> void: _faces[id].bounce_icon())
	Events.screen_requested.connect(show_screen)
	Events.world_requested.connect(_on_world_requested)
	_celebration = load("res://scenes/ui/celebration/celebration.tscn").instantiate()
	add_child(_celebration)
	add_child(CollectFx.new())
	_welcome = load("res://scenes/ui/welcome_back/welcome_back.tscn").instantiate()
	add_child(_welcome)
	_walk_result = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	add_child(_walk_result)
	_growth_ceremony = load("res://scenes/ui/growth_ceremony/growth_ceremony.tscn").instantiate()
	add_child(_growth_ceremony)
	Events.grew.connect(func(_phase: String) -> void: _check_growth_ceremonies())
	Events.state_changed.connect(_check_growth_ceremonies)
	_growth_ceremony.closed.connect(_growth_unlocks)
	Events.walk_collected.connect(func(result: Dictionary) -> void:
		_queue_modal(func() -> void: _walk_result.show_result(result))
		_queue_modal(func() -> void: _announce()))
	# Voltou com o jogo fechado: o resultado já foi aplicado ao carregar; o cartão sai uma vez só da marca salva.
	if GameState.walk_result_unseen():
		var unseen := GameState.walk_result_view()
		_queue_modal(func() -> void: _walk_result.show_result(unseen))
		_queue_modal(func() -> void: _announce())
	Events.trick_learned.connect(func(id: String) -> void:
		_queue_modal(func() -> void: _celebration.show_trick(id)))
	Events.silk_up.connect(func(level: int) -> void:
		_queue_modal(func() -> void: _celebration.show_silk(level)))
	Events.treasure_opened.connect(func(rewards: Dictionary) -> void:
		_queue_modal(func() -> void: _celebration.show_treasure(rewards)))
	Events.project_completed.connect(func(id: String, _result: Dictionary) -> void:
		_queue_modal(func() -> void: _celebration.show_project(id)))
	Events.project_phase_completed.connect(func(id: String, phase_id: String, index: int) -> void:
		# A última fase vira o cartão da obra pronta; as outras ganham só um aviso.
		if index < Database.project(id).get("phases", []).size() - 1:
			_show_toast("%s: %s pronta!" % [Database.project(id).get("name", "Obra"), Database.project(id).phases[index].get("name", phase_id)]))
	Events.cosmetic_received.connect(func(id: String) -> void:
		_queue_modal(func() -> void:
			_walk_result.show_result({"kind": "sewing", "name": "Roupa nova", "rare": id, "collections": [id]})))
	Events.bond_up.connect(_on_bond_up)
	# Foto nova do álbum: aviso tocável que abre a foto, depois de qualquer cartão (fila própria).
	Events.photo_taken.connect(func(id: String) -> void: _photo_queue.append(id))
	_toast.gui_input.connect(_on_toast_input)
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
	if saver:
		var reset_notice: String = saver.take_reset_notice()
		if reset_notice != "":
			if is_instance_valid(_intro):
				_intro.tree_exited.connect(func() -> void: _show_toast.call_deferred(reset_notice))
			else:
				_show_toast.call_deferred(reset_notice)
	var saved_at: float = float(saver.last_saved_at) if saver else 0.0
	_maybe_welcome(GameState.now() - saved_at if saved_at > 0.0 else 0.0)
	GameState.note_app_opened()
	_check_growth_ceremonies()


## Ao ir para o segundo plano guarda a hora; ao voltar, mostra o cartão se passou tempo suficiente.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_left_at = GameState.now()
	elif (what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED) and _left_at > 0.0:
		var away := GameState.now() - _left_at
		_left_at = 0.0
		GameState.note_app_opened()
		_maybe_welcome(away)


func _maybe_welcome(away_seconds: float) -> void:
	if GameState.growth.pending_reveal == "" and away_seconds < float(Database.progression.settings.get("welcome_back_seconds", 300)):
		return
	_queue_modal(func() -> void:
		if WelcomeBack.has_content():
			_welcome.open())


func _check_growth_ceremonies() -> void:
	for phase: String in GameState.growth.ceremonies:
		var at := float(GameState.growth.ceremonies[phase].get("at", 0.0))
		if bool(GameState.growth.ceremonies[phase].get("seen", false)) or _growth_queued.get(phase, -1.0) == at: continue
		if GameState.growth.pending_reveal == phase and GameState.dog.sleeping: continue
		_growth_queued[phase] = at
		_queue_modal(func() -> void:
			if bool(GameState.growth.ceremonies.get(phase, {}).get("seen", true)): return
			if float(GameState.growth.ceremonies[phase].get("at", 0.0)) != at: return
			Events.sheet_close_requested.emit()
			_growth_ceremony.open(phase))


func _growth_unlocks() -> void:
	for key: String in GameState.new_unlocks():
		_queue_modal(func() -> void:
			if key not in GameState.new_unlocks(): return
			var keys: Array[String] = [key]
			_celebration.show_unlocks(keys)
			GameState.mark_seen(keys))


## Vínculo novo: cartão com o presente (já entregue), na fila dos cartões.
func _on_bond_up(level: int, rewards: Dictionary) -> void:
	_queue_modal(func() -> void:
		_celebration.show_bond(level, rewards))


func _queue_modal(callback: Callable) -> void:
	_modal_queue.append(callback)


## Abre o próximo cartão quando nada está na tela (introdução, comemoração ou outro cartão).
func _flush_modals() -> void:
	if (_modal_queue.is_empty() and _photo_queue.is_empty()) or _announce_pending or _chapter_done > 0:
		return
	if (is_instance_valid(_intro) and _intro.is_inside_tree()) or _celebration.visible or _welcome.visible or _walk_result.visible or _growth_ceremony.visible:
		return
	if not _modal_queue.is_empty():
		_modal_queue.pop_front().call()
	else:
		_show_photo_toast(_photo_queue.pop_front())


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
	var collections := 0
	for count: int in GameState.world_ready_counts().values():
		collections += count
	_map_badge.text = str(collections)
	_map_badge.visible = collections > 0
	var count := GameState.ready_quest_count() + GameState.ready_routine_count()
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
	if text != PHOTO_TOAST:
		_toast_photo = ""
		_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_text.text = text
	_toast_icon.visible = text.begins_with("Missão concluída") or text == PHOTO_TOAST
	if _toast_icon.visible:
		_toast_icon.texture = UiKit.ui_icon("album_story" if text == PHOTO_TOAST else "ui_check")
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


func _show_photo_toast(id: String) -> void:
	_show_toast(PHOTO_TOAST)
	_toast_photo = id
	_toast.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_toast_input(event: InputEvent) -> void:
	if _toast_photo == "" or not (event is InputEventMouseButton and event.pressed):
		return
	var id := _toast_photo
	_toast_photo = ""
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.hide()
	AlbumView.open_photo(id)


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
