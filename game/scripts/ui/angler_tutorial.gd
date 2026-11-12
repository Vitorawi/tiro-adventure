class_name AnglerTutorial
extends Control
## Tutorial "A vovó ensina a pescar" (Pesca, etapa 05). Mesmo molde do `AlbumTutorial`: véu de quatro retângulos com um
## buraco só no alvo do passo, balão de madeira com o retrato animado da vovó, nada de pular passo.
## As regras que garantem a primeira pesca (lambari, espera fixa, zona ≥ Meio, rede sem dreno/com piso, isca que não
## se gasta) são do motor (`GameState`, `FishingSim.tutorial`, `FishingPanel`); aqui só véu, balão e passos salvos.
##
## Nós: `TutorialVeil` (`Veil_T/B/L/R`), `TutorialHighlight`, `TutorialBalloon` (retrato + fala), `TutorialNote`
## (fala curta ao lado da pista), `TutorialNext` ("Continuar"), `TutorialArrow`/`TutorialArrowFish`.
##
## Fases e passos salvos (`fishing.tutorial.step`): lake 2, bait 3, force 4, wait 5, bite 6, see 7, hold 8,
## release 9, play 10, almost 11, result 12, outro 13. Fechar o app em qualquer ponto retoma na próxima visita ao
## Sítio: passos 6–11 recomeçam da mordida (a partida some ao fechar, e a espera é pulada); 12–13 vão ao "outro".

const STEPS := {"lake": 2, "bait": 3, "force": 4, "wait": 5, "bite": 6, "see": 7, "hold": 8, "release": 9, "play": 10, "almost": 11, "result": 12, "outro": 13}
const GAME_PHASES := ["see", "hold", "release", "play", "almost"]
const HOLD_NEEDED := 1.0   ## segundos segurando no passo 8
const ALMOST_AT := 0.6     ## rede que dispara o passo 11

static var current: AnglerTutorial

var room: RoomView
var phase := ""            ## "" = esperando começar
var _veil: Control
var _rects: Array[ColorRect] = []
var _highlight: Panel
var _layer: CanvasLayer
var _balloon: VBoxContainer
var _note: PanelContainer
var _note_label: Label
var _next_a: Button
var _next_b: Button
var _balloon_label: Label
var _arrow: Control
var _arrow_fish: Control
var _pulse: Tween
var _hold_time := 0.0
var _idle_time := 0.0
var _game: FishingGame


## Chamado pela sala do Sítio (ao ficar visível e a cada mudança de estado). Começa ou retoma se ainda ensina.
static func maybe_start(for_room: RoomView) -> void:
	if is_active() or GameState.fishing_tutorial_done() or GameState.current_rod() == "":
		return
	if for_room == null or not for_room.is_visible_in_tree():
		return
	var main := _main()
	if main == null:
		return
	var node := AnglerTutorial.new()
	node.name = "AnglerTutorial"
	node.room = for_room
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 13
	main.add_child(node)
	current = node


static func is_active() -> bool:
	return current != null and is_instance_valid(current) and not current.is_queued_for_deletion()


static func _main() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null("Main")
	return node if node != null else tree.current_scene


func _exit_tree() -> void:
	if current == self:
		current = null
	_unfreeze()


## Fecha sem concluir: o passo fica salvo e a próxima visita ao Sítio retoma.
func stop() -> void:
	_unfreeze()
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()


func _unfreeze() -> void:
	if is_instance_valid(_game):
		_game.frozen = false
		if _game.sim != null:
			_game.sim.tutorial.erase("cap")


func _flow() -> FishingFlow:
	return room.fishing_flow() if is_instance_valid(room) else null


func _flow_state() -> String:
	var flow := _flow()
	return flow.state if flow != null else "idle"


func _line(key: String) -> String:
	return str(Database.npcs.get("bloblo", {}).get("lines", {}).get("tutorial", {}).get(key, ""))


# --- Passos ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not is_instance_valid(room) or not room.is_visible_in_tree():
		stop()  # saiu do Sítio: o passo continua salvo
		return
	if _veil == null:
		_try_start()
		return
	_tick(delta)
	_layout()


## Espera a fila modal esvaziar e nenhuma folha aberta (o prêmio da vara fecha antes).
func _try_start() -> void:
	var main := _main()
	if main == null:
		stop()
		return
	var sheet := main.get_node_or_null("Sheet")
	if sheet != null and bool(sheet.call("is_open")):
		return
	if bool(main.call("notice_blocked")):
		return
	_build_layer()
	var initial := "lake"
	match _flow_state():
		"waiting": initial = "bite" if bool(GameState.fishing.cast.get("bitten", false)) else "wait"
		"fighting": initial = "see"
		"result": initial = "result"
	_go(initial)
	_layout()


func _go(next: String) -> void:
	phase = next
	_hold_time = 0.0
	_idle_time = 0.0
	GameState.advance_fishing_tutorial(int(STEPS.get(next, 0)))
	var text := _line(next)
	_balloon_label.text = text
	_note_label.text = text
	if next == "lake" and is_instance_valid(room):
		room.look_at_lake()
	var in_game := next in GAME_PHASES
	_balloon.visible = not in_game
	_note.visible = in_game
	_next_a.visible = next == "bait" or next == "outro"
	_next_b.visible = next == "see"
	_veil.visible = next != "result"
	_arrow.visible = false
	_arrow_fish.visible = false
	_grab_game()
	if is_instance_valid(_game):
		match next:
			"see":
				_game.frozen = true
				_game.sim.tutorial["cap"] = float(Database.fishing.get("tutorial", {}).get("cap", 0.4))
			"hold", "release":
				_game.frozen = false
				_game.sim.tutorial["cap"] = float(Database.fishing.get("tutorial", {}).get("cap", 0.4))
			"play", "almost":
				_game.frozen = false
				_game.sim.tutorial.erase("cap")


func _grab_game() -> void:
	var flow := _flow()
	if flow != null and is_instance_valid(flow.game):
		_game = flow.game


## Botão "Continuar" dos passos só de explicação.
func advance() -> void:
	match phase:
		"bait": _go("force")
		"see": _go("hold")
		"outro": _finish()


func _tick(delta: float) -> void:
	var state := _flow_state()
	_grab_game()
	if is_instance_valid(_game) and _game.is_paused():
		_game.resume()  # o app foi ao segundo plano: o véu esconderia o cartão de pausa
	match phase:
		"lake":
			if state == "panel":
				var step := GameState.fishing_tutorial_step()
				if step >= 12:
					_go("outro")
				elif step >= 6:
					_resume_bite()
				else:
					_go("bait")
		"bait":
			if state != "panel":
				_go("lake")
		"force":
			if state == "waiting":
				_go("wait")
			elif state != "panel":
				_go("lake")
		"wait":
			if state == "fighting":
				_go("see")
			elif bool(GameState.fishing.cast.get("bitten", false)):
				_go("bite")
			elif state != "waiting":
				_go("lake")
		"bite":
			if state == "fighting":
				_go("see")
			elif state != "waiting":
				_go("lake")
		"see":
			if state != "fighting":
				_go("result" if state == "result" else "lake")
		"hold":
			_hold_time = _hold_time + delta if is_instance_valid(_game) and _game.is_holding() else 0.0
			if _hold_time >= HOLD_NEEDED:
				_go("release")
			elif state != "fighting":
				_go("result" if state == "result" else "lake")
		"release":
			_idle_time = _idle_time + delta if is_instance_valid(_game) and not _game.is_holding() else 0.0
			if _idle_time >= 0.25:
				_go("play")
			elif state != "fighting":
				_go("result" if state == "result" else "lake")
		"play", "almost":
			if state == "result":
				_go("result")
			elif state != "fighting":
				_go("lake")
			elif phase == "play" and is_instance_valid(_game) and _game.sim.meter >= ALMOST_AT:
				_go("almost")
		"result":
			if state == "panel":
				_go("outro")
			elif state == "idle":
				stop()  # saiu do resultado: volta ao "outro" na próxima visita


## Fechou o app no meio da partida: lança de novo a minhoca (sem gastar) e a mordida vem na hora.
func _resume_bite() -> void:
	var flow := _flow()
	if flow == null:
		_go("bait")
		return
	flow._on_cast_requested("bait_worm", 2, 0.5)
	if _flow_state() != "waiting":
		_go("bait")  # sem minhoca ou outro bloqueio: recomeça pelo painel
		return
	GameState.fishing_tutorial_bite_now()
	_go("bite")


func _finish() -> void:
	GameState.finish_fishing_tutorial()
	Events.toast_requested.emit("Volte à vovó para pegar o prêmio")
	stop()


# --- Camada visual -------------------------------------------------------------------------

func _build_layer() -> void:
	_veil = Control.new()
	_veil.name = "TutorialVeil"
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["T", "B", "L", "R"]:
		var rect := ColorRect.new()
		rect.name = "Veil_" + side
		rect.color = Color(0.0, 0.0, 0.0, 0.5)
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_veil.add_child(rect)
		_rects.append(rect)
	_highlight = Panel.new()
	_highlight.name = "TutorialHighlight"
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Palette.HONEY
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	_highlight.add_theme_stylebox_override("panel", style)
	_veil.add_child(_highlight)
	if not Motion.reduced:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_highlight, "modulate:a", 0.45, 0.6)
		_pulse.tween_property(_highlight, "modulate:a", 1.0, 0.6)
	_arrow = _make_arrow("TutorialArrow")
	_arrow_fish = _make_arrow("TutorialArrowFish")
	# Balão e nota ficam acima de tudo (o cartão do resultado é uma camada própria, 24).
	_layer = CanvasLayer.new()
	_layer.layer = 25
	_layer.name = "TutorialLayer"
	add_child(_layer)
	_balloon = VBoxContainer.new()
	_balloon.name = "TutorialBalloon"
	_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balloon.add_theme_constant_override("separation", 6)
	_layer.add_child(_balloon)
	_balloon_label = ProgressionUi.npc_header(_balloon, "bloblo", "", true, true)
	_next_a = _next_button()
	_balloon.add_child(_next_a)
	_note = PanelContainer.new()
	_note.name = "TutorialNote"
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_note.add_child(StationWood.backing("tray", 36, 36))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	var column := UiKit.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_label = StationWood.text("", 15)
	_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_label.custom_minimum_size.x = 120.0
	column.add_child(_note_label)
	_next_b = _next_button()
	column.add_child(_next_b)
	margin.add_child(column)
	_note.add_child(margin)
	_layer.add_child(_note)


func _next_button() -> Button:
	var button := StepCardUi.go_button("Continuar", advance)
	button.name = "TutorialNext"
	button.set_meta("wood_primary", true)
	return button


func _make_arrow(node_name: String) -> Control:
	var arrow := UiKit.ctl("down", 34, Palette.HONEY)
	arrow.name = node_name
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.pivot_offset = Vector2(17, 17)
	_veil.add_child(arrow)
	return arrow


## Retângulo do alvo do passo, em coordenadas da tela (vazio = nenhum: tudo escurecido e bloqueado).
func target_rect() -> Rect2:
	match phase:
		"lake", "bite":
			return room.lake_screen_rect().grow(24.0) if is_instance_valid(room) else Rect2()
		"bait", "outro":
			return _panel_rect("BaitRow" if phase == "bait" else "BaitFish")
		"force":
			var button := _panel_rect("CastButton")
			var power := _panel_rect("CastPower")
			return button.merge(power) if power.size != Vector2.ZERO else button
		"see":
			return _game.track_global_rect() if is_instance_valid(_game) else Rect2()
		"hold", "release", "play", "almost":
			return _game.hold_button_rect() if is_instance_valid(_game) else Rect2()
	return Rect2()


func _panel_rect(node_name: String) -> Rect2:
	var panel := FishingPanel.current
	if not is_instance_valid(panel):
		return Rect2()
	var node := panel.find_child(node_name, true, false) as Control
	if node == null or not node.is_visible_in_tree():
		return Rect2()
	return node.get_global_rect()


var _relaid := false


func _layout() -> void:
	var parent := get_parent()
	if parent != null and get_index() != parent.get_child_count() - 1:
		parent.move_child(self, -1)  # por cima de tudo que abriu depois, inclusive no toque
	var screen := get_viewport_rect().size
	var hole := target_rect()
	var none := hole.size == Vector2.ZERO
	if none:
		hole = Rect2(screen * 0.5, Vector2.ZERO)
	else:
		hole = hole.grow(6.0)
	_rects[0].position = Vector2.ZERO
	_rects[0].size = Vector2(screen.x, maxf(hole.position.y, 0.0))
	_rects[1].position = Vector2(0, hole.end.y)
	_rects[1].size = Vector2(screen.x, maxf(screen.y - hole.end.y, 0.0))
	_rects[2].position = Vector2(0, hole.position.y)
	_rects[2].size = Vector2(maxf(hole.position.x, 0.0), hole.size.y)
	_rects[3].position = Vector2(hole.end.x, hole.position.y)
	_rects[3].size = Vector2(maxf(screen.x - hole.end.x, 0.0), hole.size.y)
	_highlight.visible = not none
	_highlight.position = hole.position
	_highlight.size = hole.size
	if phase in GAME_PHASES:
		_layout_note()
	else:
		_layout_balloon(hole, none, screen)


func _layout_balloon(hole: Rect2, none: bool, screen: Vector2) -> void:
	_balloon.size = Vector2(screen.x - 24.0, 0.0)
	var on_top := none or hole.get_center().y > screen.y * 0.5
	if phase == "result":
		on_top = true
	var height := _balloon.get_combined_minimum_size().y
	var top_y := Hud.HEIGHT + 6.0
	var bottom_y := screen.y - height - 110.0
	# Se o lado preferido encosta no alvo (com folga do contorno), usa o outro lado.
	var wanted := Rect2(12.0, top_y if on_top else bottom_y, screen.x - 24.0, height)
	var other := Rect2(12.0, bottom_y if on_top else top_y, screen.x - 24.0, height)
	if not none and phase != "result" and wanted.intersects(hole.grow(8.0)) and not other.intersects(hole.grow(8.0)):
		wanted = other
	_balloon.position = wanted.position
	_balloon.size = Vector2(screen.x - 24.0, height)
	# O texto quebrado ainda não mediu direito no primeiro quadro (altura enorme): mede de novo no seguinte, uma vez.
	if height > screen.y * 0.5 and not _relaid:
		_relaid = true
		_layout.call_deferred()
	elif height <= screen.y * 0.5:
		_relaid = false


## Passos do minigame: fala curta à esquerda da pista (o balão grande taparia o peixe e a barra).
func _layout_note() -> void:
	if not is_instance_valid(_game):
		return
	var track := _game.track_global_rect()
	var left := _game.global_position.x + 12.0
	var width := maxf(track.position.x - 14.0 - 8.0 - FishingGame.FRAME_PAD - 12.0 - left, 120.0)
	var top := _game.global_position.y + 6.0
	var info := _game.find_child("InfoCard", true, false) as Control
	if info != null and info.is_visible_in_tree():
		top = info.get_global_rect().end.y + 8.0
	_note.custom_minimum_size.x = width
	_note.position = Vector2(left, top)
	_note.size = Vector2(width, _note.get_combined_minimum_size().y)
	if phase == "see" and is_instance_valid(_game.sim):
		var sim := _game.sim
		var bar_center := track.end.y - (sim.bar_y + sim.bar_h * 0.5) * track.size.y
		var fish_center := track.end.y - sim.fish_y * track.size.y
		_place_arrow(_arrow, Vector2(track.position.x - 40.0, bar_center - 17.0))
		_place_arrow(_arrow_fish, Vector2(track.position.x - 40.0, fish_center - 17.0))
	else:
		_arrow.visible = false
		_arrow_fish.visible = false


func _place_arrow(arrow: Control, at: Vector2) -> void:
	arrow.visible = true
	arrow.rotation = -PI / 2.0  # aponta para a direita, para a pista
	arrow.position = at
