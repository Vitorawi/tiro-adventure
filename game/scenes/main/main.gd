extends Control
## Casca do jogo: HUD de duas linhas (crescimento/moedas, próximo passo), rodapé preso com as abas Tiro / Mapa
## (mundos) / Missões / Mochila, painel inferior (Sheet) e a central de avisos (`Notice`).
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
@onready var _hud: Hud = %TopBar
@onready var _toast: PanelContainer = %Toast
@onready var _toast_text: Label = %ToastText
@onready var _toast_icon: TextureRect = %ToastIcon

## Os avisos moram na central: um por vez, erro > momento > foto > info, abaixo da linha 2 do HUD.
const NOTICE_Y := 136.0
const NOTICE_BELOW_BANNER_Y := 188.0

var _notice: Notice
## Fotos novas esperando a vez do aviso (depois de qualquer cartão, sem entrar na fila de cartões).
var _photo_queue: Array[String] = []
var _faces: Dictionary = {}  # id da aba → NavTab
var _current_screen: StringName = &""
var _tasks_badge: Label
var _map_badge: Label
## Quem pede para esconder a linha 2 do HUD (além dos bloqueios automáticos: folha, bandeja, viagem, cartões).
var _row2_blockers: Dictionary = {}
var _row2_was_hidden := false
var _quest_reward: CanvasLayer
var _quest_rewards: Array[Dictionary] = []
var _reward_not_before := 0
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
	_notice = Notice.new()
	add_child(_notice)
	_notice.setup(self, _hud, _toast, _toast_text, _toast_icon)
	_notice.blocked = notice_blocked
	_notice.top_y = notice_top
	for id: StringName in _tabs:
		_tabs[id].pressed.connect(_on_tab_pressed.bind(id))
		# Almofada com o ícone e o nome embaixo; a aba ativa ganha a almofada mel (as quatro cabem em 360 px).
		_faces[id] = NavTab.attach(_tabs[id])
		_tabs[id].pressed.connect(func() -> void: _faces[id].bounce_icon())
	Events.screen_requested.connect(show_screen)
	Events.world_requested.connect(_on_world_requested)
	_celebration = load("res://scenes/ui/celebration/celebration.tscn").instantiate()
	add_child(_celebration)
	_quest_reward = load("res://scenes/ui/quest_reward/quest_reward.tscn").instantiate()
	add_child(_quest_reward)
	add_child(CollectFx.new())
	_welcome = load("res://scenes/ui/welcome_back/welcome_back.tscn").instantiate()
	add_child(_welcome)
	_walk_result = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	add_child(_walk_result)
	_warm_glyphs.call_deferred()
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
	# Foto nova do álbum: aviso tocável que abre a foto, depois de qualquer cartão (fila própria).
	Events.photo_taken.connect(func(id: String) -> void:
		if GameState.photo_alerts_enabled(): _photo_queue.append(id))
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
	Events.moment_gained.connect(_on_moment_gained)
	var row2_timer := Timer.new()
	row2_timer.wait_time = 0.2
	row2_timer.autostart = true
	row2_timer.timeout.connect(_check_row2)
	add_child(row2_timer)
	Events.sheet_requested.connect(func(_title: String, _content: Control) -> void: _check_row2.call_deferred())
	Events.sheet_close_requested.connect(func() -> void: _check_row2.call_deferred())
	Events.state_changed.connect(_refresh_top_bar)
	Events.update_available.connect(%UpdateBanner.show)
	%UpdateBanner.pressed.connect(PwaUpdater.apply_update)
	%UpdateBanner.visible = PwaUpdater.update_ready
	# Versão dev: selo DEV abre as ferramentas de teste (BuildInfo / DevPanel).
	# (A versão e o atalho de atualização moraram no HUD; agora ficam no rodapé das Configurações.)
	_hud.dev_button.visible = BuildInfo.is_dev()
	_hud.dev_button.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Ferramentas DEV", DevPanel.panel()))
	UiKit.tint_bar(_hud.xp_bar, Palette.HONEY)
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


func _queue_modal(callback: Callable) -> void:
	_modal_queue.append(callback)


## Abre o próximo cartão quando nada está na tela (introdução, comemoração ou outro cartão).
func _flush_modals() -> void:
	if (_modal_queue.is_empty() and _photo_queue.is_empty()) or _announce_pending or _chapter_done > 0:
		return
	if Time.get_ticks_msec() < _reward_not_before: return
	if _card_open():
		return
	if not _modal_queue.is_empty():
		_modal_queue.pop_front().call()
	else:
		_show_photo_toast(_photo_queue.pop_front())


## Algum cartão grande (introdução, comemoração, boas-vindas, volta do passeio, cerimônia) está na tela.
func _card_open() -> bool:
	return (is_instance_valid(_intro) and _intro.is_inside_tree()) or _celebration.visible or _welcome.visible or _walk_result.visible or _growth_ceremony.visible or _quest_reward.visible


## Avisos esperam enquanto houver cartão aberto ou cartão na fila (mesma regra do `_flush_modals`).
func notice_blocked() -> bool:
	return _card_open() or not _modal_queue.is_empty() or _announce_pending or _chapter_done > 0


## Onde o aviso nasce: logo abaixo da linha 2 do HUD (ou da pílula do mundo e dos rostos, no Mapa).
func notice_top() -> float:
	var y := NOTICE_BELOW_BANNER_Y if %UpdateBanner.visible else NOTICE_Y
	# Com folha, seletor ou bandeja abertos a linha 2 recolhe: o aviso nasce nessa faixa livre, acima do topo
	# da folha (que nunca sobe de `Hud.HEIGHT`), e não cobre o título dela.
	if _row2_hidden():
		y = Hud.ROW2_TOP + 4.0
	if _current_screen == &"map" and not %WorldsScreen.is_map_open():
		y = maxf(y, %WorldsScreen.toast_top())
	return y


## Linha 2 do HUD: esconde por uma chave (a roleta, a barra da horta... pedem por aqui) ou pelos bloqueios
## automáticos de `_check_row2`.
func set_row2_blocker(key: String, on: bool) -> void:
	if on:
		_row2_blockers[key] = true
	else:
		_row2_blockers.erase(key)
	_check_row2()


## Sem pílula do próximo passo nem peça da tela, a linha 2 de Missões e Mochila fica vazia: recolhe e o conteúdo sobe.
func _row2_empty() -> bool:
	return _current_screen in [&"tasks", &"bag"] and not _hud.next_step.visible and not _hud.row2_right_used()


## A linha 2 está recolhida (folha, seletor, bandeja, viagem, cartão, bloqueio por chave ou vazia).
func _row2_hidden() -> bool:
	return _row2_empty() or not _row2_blockers.is_empty() or _card_open() or (get_node("Sheet") as Control).call("is_open") \
		or ActionTray.current != null or FarmDock.current() != null or %WorldsScreen.is_traveling() \
		or (%WorldsScreen.is_visible_in_tree() and %WorldsScreen.is_map_open())


func _check_row2() -> void:
	var hidden := _row2_hidden()
	_hud.set_row2_shown(not hidden)
	if hidden != _row2_was_hidden:
		_row2_was_hidden = hidden
		_notice.retarget()
	var top := Hud.ROW2_TOP + 8.0 if _row2_empty() else Hud.HEIGHT + 8.0
	for screen_id: StringName in [&"tasks", &"bag"]:
		_screens[screen_id].call("set_content_top", top)


## Com `true`, o rodapé se junta à tela de cima (sem cantos nem sombra, divisória de 1 px): a etapa 04 apoia o
## botão Cuidar nele. Padrão `false`.
func set_tab_joined(on: bool) -> void:
	var bar := get_node("Layout/TabBar") as PanelContainer
	if not on:
		bar.remove_theme_stylebox_override("panel")
		return
	var style := UiKit.surface(Palette.BASE_GLASS, 0)
	style.border_color = Palette.BASE_LINE
	style.border_width_top = 1
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 14.0
	bar.add_theme_stylebox_override("panel", style)


func show_screen(id: StringName) -> void:
	_hud.set_row2_right(null)
	_current_screen = id
	set_tab_joined(id == &"pet")
	GameState.note_screen_opened(String(id))
	for screen_id: StringName in _screens:
		_screens[screen_id].visible = screen_id == id
		_tabs[screen_id].button_pressed = screen_id == id
	%TasksScreen.sync_hud()
	%PetScreen.sync_hud()


## A aba Mapa retoma o mundo; tocar de novo abre o carrossel.
## Aquece o cache de glifos: a primeira vez que a Fredoka/Nunito (variáveis) aparece num tamanho novo
## custa ~150 ms (roleta, folha). Um rótulo quase invisível, preso a 1×1 px, desenha o alfabeto em cada
## par fonte/tamanho do tema (inclusive Texto maior) por alguns quadros e some.
func _warm_glyphs() -> void:
	var theme := load("res://assets/theme/main_theme.tres") as Theme
	var pairs: Dictionary = {}
	if theme != null:
		pairs["%d/%d" % [theme.default_font.get_instance_id(), theme.default_font_size]] = [theme.default_font, theme.default_font_size]
		for type_name: String in theme.get_font_size_type_list():
			for item: String in theme.get_font_size_list(type_name):
				var font: Font = theme.get_font(item, type_name) if theme.has_font(item, type_name) else theme.default_font
				var size := theme.get_font_size(item, type_name)
				pairs["%d/%d" % [font.get_instance_id(), size]] = [font, size]
	for path: String in ["font_display", "font_body", "font_caption"]:
		var extra := load("res://assets/fonts/%s.tres" % path) as Font
		if extra == null: continue
		for size: int in [12, 15, 18, 24, 26]:
			pairs["%d/%d" % [extra.get_instance_id(), size]] = [extra, size]
	var holder := Control.new()
	holder.name = "GlyphWarmup"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	holder.size = Vector2.ONE
	holder.modulate.a = 0.01
	add_child(holder)
	for entry: Array in pairs.values():
		var label := Label.new()
		label.text = "AÁÀÂÃBCÇDEÉÊFGHIÍJKLMNOÓÔÕPQRSTUÚVWXYZ aáàâãbcçdeéêfghiíjklmnoóôõpqrstuúvwxyz 0123456789 .,!?:;+-×%/()"
		label.add_theme_font_override("font", entry[0])
		label.add_theme_font_size_override("font_size", entry[1])
		holder.add_child(label)
	for i: int in 3:
		await get_tree().process_frame
	holder.queue_free()


func _on_tab_pressed(id: StringName) -> void:
	if id == &"map" and _current_screen == &"map":
		%WorldsScreen.show_map()
	elif id == &"map":
		%WorldsScreen.close_map()
	show_screen(id)


func _on_world_requested(world_id: String, place: String) -> void:
	%WorldsScreen.enter(world_id, place)
	show_screen(&"map")


## Selo com o número de coisas prontas (missões e colheitas/produções) nas abas Missões e Mapa.
## Fica no canto de cima, à direita da almofada: centro do ícone + (22, −16).
func _build_tasks_badge() -> void:
	_tasks_badge = UiKit.badge(1, Palette.BASE)
	%TasksTab.add_child(_tasks_badge)
	_map_badge = UiKit.badge(1, Palette.BASE)
	_map_badge.name = "NpcMapBadge"
	%MapTab.add_child(_map_badge)
	for pair: Array in [[&"tasks", _tasks_badge], [&"map", _map_badge]]:
		var tab: Button = _tabs[pair[0]]
		var face: NavTab = _faces[pair[0]]
		var badge: Label = pair[1]
		var place := func() -> void: badge.position = face.icon_center() + Vector2(22.0, -16.0) - badge.size / 2.0
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


func _refresh_top_bar() -> void:
	_hud.refresh()


## Aviso comum ("info"): vai para a central. Mantido para chamadores antigos.
func _show_toast(text: String) -> void:
	_notice.notify("info", text)


func _show_photo_toast(id: String) -> void:
	_notice.notify("photo", "Nova foto!", null, AlbumView.open_photo.bind(id))


func _refresh_guide() -> void:
	_refresh_tasks_badge()
	# Mochila só aparece quando a história a apresenta.
	%BagTab.visible = GameState.progress.feature_unlocked("bag")
	# O próximo passo (linha 2 do HUD) chama o olhar para a história; a aba Missões não pulsa mais.


func _on_quest_completed(id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	_reward_not_before = Time.get_ticks_msec() + (0 if Motion.reduced else int(Motion.FLY * 1000))
	if quest.get("kind", "") == "main":
		_quest_rewards.append({"id": id, "next": GameState.progress.current_main_quest()})
	else:
		for item: String in quest.get("rewards", {}).get("items", {}):
			if Database.items.get(item, {}).get("category", "") == "keepsake":
				_notice.notify("info", "%s te deu: %s" % [str(Database.npcs.get(str(quest.get("npc", "")), {}).get("name", "")), Database.item_name(item)])
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
	var chapter := _chapter_done
	_chapter_done = 0
	if chapter > 0:
		_quest_rewards.clear()
		_queue_modal(func() -> void:
			Events.sheet_close_requested.emit()
			_celebration.show_chapter(chapter, unlocks))
	else:
		for entry: Dictionary in _quest_rewards:
			_queue_modal(func() -> void:
				Events.sheet_close_requested.emit()
				_quest_reward.call("open", str(entry.id), str(entry.next)))
		_quest_rewards.clear()
		if not unlocks.is_empty():
			_queue_modal(func() -> void:
				Events.sheet_close_requested.emit()
				_celebration.show_unlocks(unlocks))
	if not unlocks.is_empty(): GameState.mark_seen(unlocks)

func _on_moment_gained(pillar: String, _source: String) -> void:
	if not Database.growth.pillars.has(pillar): return
	var data: Dictionary = Database.growth.pillars[pillar]
	_notice.notify("moment", "Momento de %s!" % data.name, UiKit.ui_icon(str(data.icon)))
