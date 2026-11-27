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

## Os avisos moram na central: um por vez, erro > momento > foto > info, embaixo, acima da barra de abas (ou da folha).

var _notice: Notice
## IDs já agendados na fila modal; evita lembretes/revelações duplicados.
var _photo_queue: Array[String] = []
var _faces: Dictionary = {}  # id da aba → NavTab
var _current_screen: StringName = &""
var _tab_art: TextureRect
var _tasks_badge: Label
var _map_badge: Label
var _pet_dot: Label  # foto nova para ver, quando a tela do Tiro não está aberta
var _bag_dot: Label  # presente esperando espaço na Mochila
## Quem pede para esconder a linha 2 do HUD (além dos bloqueios automáticos: folha, bandeja, viagem, cartões).
var _row2_blockers: Dictionary = {}
var _row2_was_hidden := false
var _quest_reward: CanvasLayer
var _quest_rewards: Array[Dictionary] = []
const CARE_MAX_WAIT := 10000
var _care_since := -1
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
var _week_cards_queued: Dictionary = {}
var _intro: Node
var _left_at: float = 0.0


func _ready() -> void:
	# Rolagem por arrasto em qualquer lista (dedo sobre botões/cartões também rola).
	load("res://scripts/ui/drag_scroll.gd").call("install", self)
	_notice = Notice.new()
	add_child(_notice)
	_notice.setup(self, _hud, _toast, _toast_text, _toast_icon)
	_notice.blocked = notice_blocked
	_notice.bottom_y = notice_bottom
	_notice.on_pet_screen = func() -> bool: return _current_screen == &"pet"
	_build_tab_art()
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
		if not GameState.trick_is_lesson(id):
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
	# Fotos conhecidas entram na fila modal; fechadas antigas esperam no álbum.
	# Marco de coleção: a festa espera a revelação fechar (`_flush_modals` não abre com a carta na tela).
	Events.album_milestone.connect(func(kind: String, key: String) -> void:
		_queue_modal(func() -> void: _celebration.show_album_milestone(kind, key)))
	# Nível de cozinheiro: aviso leve, tocável para abrir o Livro de receitas (menos telas por cima do jogo).
	Events.chef_level_up.connect(_chef_notice)
	# Patinha ganha com o jogo aberto: o cartão "Dia completo!" (a aula da comida e as patinhas que se completaram com o
	# jogo fechado ficam de fora: `MealUi.live_paw` decide; o Bom dia conta as outras).
	Events.paw_earned.connect(func(day: int) -> void:
		var live: Dictionary = MealUi.live_paw(day)
		if not live.is_empty():
			_day_complete_notice())
	# O ✓ ao vivo com a outra metade pendente: um aviso curto (depois do registro do dia, que fecha a patinha).
	Events.meal_given.connect(func(period: String, on_time: bool) -> void:
		if on_time:
			_meal_counted.call_deferred(period))
	Events.photo_taken.connect(_queue_photo)
	Events.photo_sealed.connect(_queue_photo)
	Events.find_discovered.connect(func(result: Dictionary) -> void:
		_queue_modal(func() -> void: _celebration.show_find(result)))
	# Pedaço de receita: aviso curto; o cartão só aparece quando a receita fica completa.
	# Antes do Livro de receitas abrir, os pedaços entram em silêncio.
	Events.recipe_piece_found.connect(func(id: String, count: int) -> void:
		if not GameState.recipe_book_open():
			return
		if count < 3:
			Events.notice_requested.emit("info", "Pedaço de receita! %d de 3" % count, "map_piece_1")
			return
		_queue_modal(func() -> void: _celebration.show_recipe_piece(id, count)))
	var modal_timer := Timer.new()
	modal_timer.wait_time = 0.3
	modal_timer.autostart = true
	modal_timer.timeout.connect(func() -> void:
		_check_week_cards()
		_flush_modals())
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
	var tutorial_layer := CanvasLayer.new()
	tutorial_layer.layer = 28
	add_child(tutorial_layer)
	var tutorials := WeekTutorial.new()
	tutorials.name = "WeekTutorial"
	tutorials.main = self
	tutorial_layer.add_child(tutorials)
	var lessons := LessonGuide.new()
	lessons.main = self
	tutorial_layer.add_child(lessons)
	GameState.note_app_opened()
	_check_growth_ceremonies()
	_finish_web_loading.call_deferred()


func _finish_web_loading() -> void:
	if not OS.has_feature("web"): return
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("if (window.TiroLoading) window.TiroLoading.ready();", true)


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


## Depois da cerimônia de crescer: as novidades que ela segurou saem numa folha só.
func _growth_unlocks() -> void:
	if GameState.new_unlocks().is_empty(): return
	_queue_modal(func() -> void:
		var keys: Array[String] = []
		keys.assign(GameState.new_unlocks())
		if keys.is_empty(): return
		_celebration.show_unlocks(keys)
		GameState.mark_seen(keys))


## Há cerimônia de crescer ainda não vista (pronta para abrir ou esperando o Tiro acordar).
func _growth_pending() -> bool:
	for phase: String in GameState.growth.ceremonies:
		if not bool(GameState.growth.ceremonies[phase].get("seen", false)):
			return true
	return false


func _week_card_waits_for_growth() -> bool:
	for phase: String in _growth_queued:
		var ceremony: Dictionary = GameState.growth.ceremonies.get(phase, {})
		if not ceremony.get("seen", true):
			return true
	return false


func _check_week_cards() -> void:
	if _week_card_waits_for_growth():
		return
	for candidate: Dictionary in GameState.week_card_candidates():
		var key := "%s:%d:%d" % [candidate.kind, candidate.civil, GameState.growth.taste_seed]
		if _week_cards_queued.has(key):
			continue
		# Menos telas: o Boa noite só abre cartão no dia da chegada (o que ensina a tigela); nos outros dias a noite
		# é registrada em silêncio (o desafio "Boa noite" continua contando).
		if str(candidate.kind) == "night" and not GameState.is_arrival_day(int(candidate.day)):
			GameState.take_week_card(candidate)
			continue
		_week_cards_queued[key] = true
		_queue_modal(func() -> void:
			_week_cards_queued.erase(key)
			if _week_card_waits_for_growth():
				return
			var report := GameState.take_week_card(candidate)
			if not report.is_empty():
				Events.sheet_close_requested.emit()
				_celebration.show_week_card(report))


## Metade do dia ✓ ao vivo: sem texto; o potinho do HUD dá um pop (o disco já ganhou o ✓).
func _meal_counted(period: String) -> void:
	if MealUi.counted_notice(period) != "":
		_pop_pot()


func _pop_pot() -> void:
	var pot := find_child("MealDay", true, false) as Control
	if pot == null or not pot.is_visible_in_tree() or Motion.reduced: return
	pot.pivot_offset = pot.size / 2.0
	var pop := pot.create_tween()
	pop.tween_property(pot, "scale", Vector2(1.18, 1.18), 0.1)
	pop.tween_property(pot, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _queue_modal(callback: Callable) -> void:
	_modal_queue.append(callback)


## Abre o próximo cartão quando nada está na tela (introdução, comemoração ou outro cartão).
func _flush_modals() -> void:
	if _modal_queue.is_empty() or _announce_pending or _chapter_done > 0:
		return
	if Time.get_ticks_msec() < _reward_not_before: return
	if CardViewer.is_open() or _card_open():
		return
	if CookTogether.current() != null or TrickLesson.current() != null or is_instance_valid(YardPlay.current):
		return
	# O conteúdo da folha já fechou, mas sua moldura ainda pode estar saindo.
	if bool(get_node("Sheet").get("_closing")): return
	if _waiting_care(): return
	if not _modal_queue.is_empty():
		_modal_queue.pop_front().call()



## O cartão espera o Tiro terminar de comer/tomar banho/brincar (no máximo 10 s).
func _waiting_care() -> bool:
	var now := Time.get_ticks_msec()
	if PetAnimator.home_caring():
		if _care_since < 0: _care_since = now
		return now - _care_since < CARE_MAX_WAIT
	_care_since = -1
	return false


## Algum cartão grande (introdução, comemoração, boas-vindas, volta do passeio, cerimônia) está na tela.
func _card_open() -> bool:
	return (is_instance_valid(_intro) and _intro.is_inside_tree()) or _celebration.visible or _welcome.visible or _walk_result.visible or _growth_ceremony.visible or _quest_reward.visible


## Avisos esperam enquanto houver cartão aberto ou cartão na fila (mesma regra do `_flush_modals`).
## Há uma tela da história (prêmio do passo, capítulo, "Novo!") esperando para abrir ou aberta.
## As lições esperam por ela: primeiro a missão, depois o "Ir", e só então a explicação.
func story_card_pending() -> bool:
	return _card_open() or _announce_pending or _chapter_done > 0 or not _modal_queue.is_empty()


func notice_blocked() -> bool:
	return CookTogether.current() != null or TrickLesson.current() != null or is_instance_valid(YardPlay.current) or _card_open() or not _modal_queue.is_empty() or _announce_pending or _chapter_done > 0


## Onde o aviso TERMINA (y): logo acima da barra de abas de madeira; com folha ou bandeja de estação presa embaixo,
## logo acima do topo dela (o aviso segue a folha enquanto ela sobe). Se acima da folha não sobra espaço livre abaixo
## do HUD (folha alta), o aviso fica junto à barra de abas, por cima da folha: nunca cobre o HUD nem some.
func notice_bottom(height: float) -> float:
	var bottom := size.y + _tab_art.offset_top - 6.0
	# As almofadas redondas das abas sobem acima da tábua: o aviso fica acima delas.
	for tab: Control in _tabs.values():
		if tab != null and tab.is_visible_in_tree():
			bottom = minf(bottom, tab.get_global_rect().position.y - 6.0)
			var cushion := tab.find_child("Cushion", true, false) as Control
			if cushion != null:
				bottom = minf(bottom, cushion.get_global_rect().position.y - 6.0)
	var limit := bottom
	var sheet := get_node("Sheet") as Control
	if bool(sheet.call("is_open")):
		limit = minf(limit, (sheet.get_node("Panel") as Control).get_global_rect().position.y - 24.0)
	var tray := ActionTray.current
	if tray != null and is_instance_valid(tray) and tray.pick:
		limit = minf(limit, tray.screen_top() - 6.0)
	# A guia de comida (e a tigela) ficam à vista: o aviso sobe para não cobri-las.
	var food_menu := find_child("FoodMenu", true, false) as Control
	if food_menu != null and food_menu.is_visible_in_tree():
		limit = minf(limit, food_menu.get_global_rect().position.y - 6.0)
	var fishing := FishingPanel.current
	if fishing != null and is_instance_valid(fishing):
		limit = minf(limit, fishing.screen_top() - 6.0)
	if limit - height < Hud.HEIGHT + 4.0:
		limit = bottom
	return limit


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


## O rodapé é a tábua ilustrada (`TabBarArt`) com os quatro encaixes; o painel por baixo fica transparente e só
## reserva as margens para os botões caírem sobre os círculos da arte. `on` não muda mais o visual (nome mantido).
func set_tab_joined(_on: bool) -> void:
	_layout_tab_bar()


## Arte da barra de abas (360×104 por 1080×311 da imagem); a altura acompanha a largura para os círculos não ovalizarem.
func _build_tab_art() -> void:
	var bar := get_node("Layout/TabBar") as PanelContainer
	_tab_art = HomeUi.pic(bar.get_parent() as Control, "tabbar", Rect2(), "TabBarArt")
	_tab_art.z_index = 5
	bar.get_parent().move_child(_tab_art, bar.get_index())
	_tab_art.anchor_left = 0.0
	_tab_art.anchor_right = 1.0
	_tab_art.anchor_top = 1.0
	_tab_art.anchor_bottom = 1.0
	_tab_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tab_art.stretch_mode = TextureRect.STRETCH_SCALE
	_tab_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_layout_tab_bar)
	_layout_tab_bar()


func _layout_tab_bar() -> void:
	var bar := get_node_or_null("Layout/TabBar") as PanelContainer
	if bar == null or _tab_art == null:
		return
	var scale_x := maxf(size.x, 1.0) / 360.0
	var height := roundf(size.x * 311.0 / 1080.0)
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 11.0 * scale_x
	style.content_margin_right = 11.0 * scale_x
	bar.add_theme_stylebox_override("panel", style)
	bar.custom_minimum_size.y = height
	# Cada aba ocupa um encaixe da tábua (84,5 px em 360 com as quatro); com menos abas liberadas as que sobram
	# dividem a largura igualmente e ficam centradas no rodapé.
	for id: StringName in _tabs:
		(_tabs[id] as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(_tabs[id] as Control).custom_minimum_size.x = 84.5 * scale_x
	bar.offset_top = -height
	_tab_art.offset_top = -height
	_tab_art.offset_bottom = 0.0
	_tab_art.offset_left = 0.0
	_tab_art.offset_right = 0.0


func show_screen(id: StringName) -> void:
	# Aba que a história ainda não liberou: fica na tela do Tiro.
	if id != &"pet" and _tabs.has(id) and not (_tabs[id] as Control).visible:
		id = &"pet"
	_hud.set_row2_right(null)
	_current_screen = id
	_hud.next_step.shown_on_screen = id == &"pet"
	set_tab_joined(id == &"pet")
	GameState.note_screen_opened(String(id))
	for screen_id: StringName in _screens:
		_screens[screen_id].visible = screen_id == id
		_tabs[screen_id].button_pressed = screen_id == id
	%TasksScreen.sync_hud()
	%PetScreen.sync_hud()
	if _pet_dot != null: _refresh_tasks_badge()
	_check_row2()


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
	_pet_dot = UiKit.dot()
	_pet_dot.name = "PetNewDot"
	%PetTab.add_child(_pet_dot)
	_bag_dot = UiKit.dot()
	_bag_dot.name = "BagGiftDot"
	%BagTab.add_child(_bag_dot)
	for pair: Array in [[&"tasks", _tasks_badge], [&"map", _map_badge], [&"pet", _pet_dot], [&"bag", _bag_dot]]:
		var tab: Button = _tabs[pair[0]]
		var face: NavTab = _faces[pair[0]]
		var badge: Label = pair[1]
		var place := func() -> void: badge.position = face.icon_center() + Vector2(30.0, -24.0) - badge.size / 2.0
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
	_pet_dot.visible = _current_screen != &"pet" and GameState.photo_alerts_enabled() and AlbumScreen.has_new()
	_bag_dot.visible = not GameState.economy.pending.is_empty()


func _refresh_top_bar() -> void:
	_hud.refresh()


## Aviso comum ("info"): vai para a central. Mantido para chamadores antigos.
func _show_toast(text: String) -> void:
	_notice.notify("info", text)


## Foto nova: só um aviso tocável (a primeira, a da chegada, é aberta pelo tutorial do Álbum). O selo do botão do
## Álbum continua; tocar no aviso abre a carta daquela foto.
func _queue_photo(id: String) -> void:
	if not GameState.photo_alerts_enabled(): return
	if id == AlbumTutorial.PHOTO and not GameState.album_tutorial_done(): return  # quem abre é o tutorial do Álbum
	if id not in _photo_queue: _photo_queue.append(id)
	# Sem texto: o selo do botão do Álbum pulsa (PetScreen) e a aba Tiro ganha um pontinho até a foto ser vista.
	_refresh_tasks_badge()
	if _pet_dot != null and _pet_dot.visible and not Motion.reduced:
		Motion.bounce(_pet_dot)


## Toque no aviso "Nova foto!": abre a carta daquela foto (fechada = revelação; já aberta = o Álbum).
func _open_photo(id: String) -> void:
	_photo_queue.erase(id)
	ActionTray.close_current(true)
	CookPanel.close_current(true)
	var sheet := get_node_or_null("Sheet")
	if sheet != null and sheet.call("is_open"): sheet.call("close")
	if GameState.photo_sealed(id) > 0: CardReveal.open(id, {"host": self})
	else: AlbumScreen.open()


func _refresh_guide() -> void:
	_refresh_tasks_badge()
	# Cada aba só aparece quando a história a apresenta (Ato 1: só o Tiro; Mapa no passo 5; Missões e Mochila no fim).
	%MapTab.visible = GameState.progress.feature_unlocked("tab_map")
	%TasksTab.visible = GameState.progress.feature_unlocked("tab_tasks")
	%BagTab.visible = GameState.progress.feature_unlocked("bag")
	# O próximo passo (linha 2 do HUD) chama o olhar para a história; a aba Missões não pulsa mais.


func _on_quest_completed(id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	_reward_not_before = Time.get_ticks_msec() + (0 if Motion.reduced else int(Motion.FLY * 1000))
	if not quest.get("claim_sheet", true):
		pass  # passo de transição entregue sozinho e sem aviso: a história segue direto (ex.: a vovó já se apresenta)
	elif quest.get("kind", "") == "main":
		_quest_rewards.append({"id": id, "next": GameState.progress.current_main_quest()})
	else:
		# Marco de personagem que também é passo da história (`shared_with`): o aviso "Passo concluído" sai igual.
		for main_id: String in Database.quests:
			var main_quest: Dictionary = Database.quests[main_id]
			if main_quest.get("kind", "") == "main" and str(main_quest.get("shared_with", "")) == id and GameState.progress.claimed_quests.has(main_id):
				_quest_rewards.append({"id": main_id, "next": GameState.progress.current_main_quest()})
				break
		for item: String in quest.get("rewards", {}).get("items", {}):
			if Database.items.get(item, {}).get("category", "") == "keepsake":
				_queue_modal(_celebration.show_gift.bind(item, str(quest.get("npc", ""))))
	_schedule_announce()

## Tira o aviso "Passo concluído" de um passo (o painel de crescimento entrega e cresce no mesmo toque).
func drop_quest_reward(id: String) -> void:
	for index in range(_quest_rewards.size() - 1, -1, -1):
		if str(_quest_rewards[index].id) == id:
			_quest_rewards.remove_at(index)

func _on_chapter_completed(index: int) -> void:
	_chapter_done = index
	_schedule_announce()


func _schedule_announce() -> void:
	if not _announce_pending:
		_announce_pending = true
		_announce.call_deferred()


## Fim do quadro da história. Tela grande só para marco (crescer e fim de capítulo); o resto é aviso leve:
## - capítulo: cartão com as novidades, SALVO quando termina junto com um crescimento (só a cerimônia; as novidades
##   saem depois dela, numa folha só);
## - novidades sem capítulo: UMA folha "Novo!" com todas;
## - só passo concluído: aviso "Passo concluído ✓" (um por quadro) e um pulinho na pílula do próximo passo.
func _announce() -> void:
	_announce_pending = false
	var unlocks: Array[String] = []
	unlocks.assign(GameState.new_unlocks())
	var chapter := _chapter_done
	_chapter_done = 0
	var steps := _quest_rewards.duplicate()
	_quest_rewards.clear()
	var growth_waits := _growth_pending()
	var growth_step := false
	for entry: Dictionary in steps:
		for goal: Dictionary in Database.quests[str(entry.id)].get("goals", []):
			if goal.get("type", "") == "growth": growth_step = true
	if chapter > 0 or not steps.is_empty():
		# O cartão de origem não deve reaparecer depois de pegar o prêmio nem de "Ir".
		for catcher: Node in find_children("PopoverCatcher", "Control", true, false):
			(catcher as Control).hide()
			catcher.queue_free()
	var modal := false
	if growth_waits:
		pass  # a cerimônia vem primeiro; as novidades ficam para depois dela (`_growth_unlocks`)
	elif chapter > 0 and not growth_step:
		modal = true
		_close_for_card()
		_queue_modal(func() -> void:
			Events.sheet_close_requested.emit()
			_celebration.show_chapter(chapter, unlocks))
	elif not unlocks.is_empty():
		modal = true
		_close_for_card()
		_queue_modal(func() -> void:
			Events.sheet_close_requested.emit()
			_celebration.show_unlocks(unlocks))
	if not growth_waits and not unlocks.is_empty(): GameState.mark_seen(unlocks)
	if not modal and not growth_waits and not steps.is_empty():
		_hud.next_step.flash_done()
		_pulse_next_step()


func _close_for_card() -> void:
	ActionTray.close_current(true)
	CookPanel.close_current(true)
	Events.sheet_close_requested.emit()


## Pulinho na pílula do próximo passo (linha 2 do HUD): chama o olhar para o que vem agora.
func _pulse_next_step() -> void:
	var step := _hud.next_step
	if Motion.reduced or step == null or not step.is_visible_in_tree(): return
	step.pivot_offset = step.size / 2.0
	var tween := step.create_tween()
	tween.tween_property(step, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(step, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Dia completo: aviso com a patinha (toque abre a folha Hoje) e uma patinha voando até o potinho do HUD.
func _day_complete_notice() -> void:
	var paw := UiKit.ui_icon("find_paw")
	var pot := find_child("MealDay", true, false) as Control
	if pot == null or not pot.is_visible_in_tree() or Motion.reduced: return
	var fly := UiKit.icon(paw, 40)
	fly.name = "DayPawFly"
	fly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly.z_index = 15
	add_child(fly)
	var from := Vector2(size.x / 2.0 - 20.0, notice_bottom(44.0) - 40.0)
	var to := pot.get_global_rect().get_center() - Vector2(20, 20)
	Motion.fly_arc(fly, from, to, 0.9).tween_callback(func() -> void:
		fly.queue_free()
		_pop_pot())


## Nível de cozinheiro: aviso com o ícone da habilidade; tocar abre o Livro de receitas.
func _chef_notice(level: int) -> void:
	var rows: Array = GameState.chef_levels()
	var skill: Dictionary = rows[clampi(level, 0, rows.size() - 1)].skill
	_notice.notify("gold", "Cozinheiro nível %d: %s!" % [level, str(skill.name)], UiKit.ui_icon(str(skill.icon)), func() -> void:
		ActionTray.close_current(true)
		CookPanel.close_current(true)
		PetNotebook.open("recipes"))

func _on_moment_gained(pillar: String, _source: String) -> void:
	if not Database.growth.pillars.has(pillar): return
	var data: Dictionary = Database.growth.pillars[pillar]
	_notice.fly_to_avatar(UiKit.ui_icon(str(data.icon)))
