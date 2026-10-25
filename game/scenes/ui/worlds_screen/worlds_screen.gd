extends Control
## Aba Mapa: mundo atual (WorldView) e lista de cinco destinos por cima (MapView).
##
## Os mundos vêm de data/worlds.json. Mundo com "room" vira uma sala (RoomView:
## casa, sítio); sem "room" vira uma tela com a imagem "banner" + cartões dos
## personagens e lugares. O mundo ocupa a tela toda (o HUD flutua por cima); a barra do mundo
## mostra a pílula do mundo (abre a lista de mundos), o botão "Lugares" e os rostos dos
## personagens dali (com selo quando há missão), para nunca ser preciso adivinhar onde tocar.

const ROOM_SCENE := preload("res://scenes/levels/room/room.tscn")
const TRANSITION_SCENE := preload("res://scenes/ui/world_transition/world_transition.tscn")
## Segundos com a seta à vista antes de abrir o painel do destino.
const POINT_DELAY := 0.8
## Barra do mundo: margem lateral e altura (na linha 2 do HUD, que começa em 76).
const BAR_MARGIN := 10.0
const BAR_TOP := 76.0
## Folga entre a pílula do mundo e o próximo passo, e entre o próximo passo e os rostos.
const ROW2_GAP := 8.0

var current_world := "house"
var _views: Dictionary = {}  # world_id -> Control (criado na primeira visita e mantido)
var _thumbs: Dictionary = {}  # world_id -> Texture2D (miniatura do cartão do mapa)
var _header_key := ""
var _idle := 0.0
var _hinted: Dictionary = {}  # passos que já ganharam a seta da dica parada
var _transition: WorldTransition
var _visit: int = 0  # invalida setas/painéis de uma viagem substituída por outra


func _ready() -> void:
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree(): GameState.note_world_visit(current_world)
		sync_row2.call_deferred())
	resized.connect(sync_row2)
	_build_world_bar()
	%MapButton.pressed.connect(show_map)
	%MapView.chosen.connect(enter)
	%MapView.closed.connect(_resume_room_input)
	# A pílula do mundo e os rostos não aparecem atrás do seletor.
	%MapView.visibility_changed.connect(func() -> void:
		var bar := find_child("WorldBar", true, false)
		if bar: bar.visible = not %MapView.visible)
	_transition = TRANSITION_SCENE.instantiate()
	add_child(_transition)
	Events.state_changed.connect(_refresh_header)
	Events.state_changed.connect(func() -> void:
		if is_map_open(): %MapView.refresh(current_world))
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_header)
	timer.timeout.connect(func() -> void:
		if is_map_open(): %MapView.refresh(current_world))
	add_child(timer)
	enter(current_world)


func show_map() -> void:
	if _transition.busy: return
	Events.sheet_close_requested.emit()
	_suspend_room_input()
	%MapView.open(current_world)


func close_map() -> void:
	%MapView.dismiss()


func _suspend_room_input() -> void:
	for view: Control in _views.values():
		view.set_process_input(false)
		if view is RoomView: view.call("_stop_camera")


func _resume_room_input() -> void:
	if _transition.busy: return
	for view: Control in _views.values():
		view.set_process_input(true)


## A viagem entre mundos (nuvens) está acontecendo: a linha 2 do HUD espera.
func is_traveling() -> bool:
	return _transition != null and _transition.busy


func is_map_open() -> bool:
	return %MapView.visible


## Reserva espaço para o aviso abaixo da pílula e dos rostos, sem cobrir os botões do mapa.
func toast_top() -> float:
	# Com o seletor aberto os controles medidos ficam atrás dele.
	if not is_visible_in_tree() or not %WorldView.visible or is_map_open():
		return 0.0
	var bottom: float = maxf(%MapButton.get_global_rect().end.y, Hud.HEIGHT)
	if %NpcRow.visible:
		bottom = maxf(bottom, %NpcRow.get_global_rect().end.y)
	return bottom + 8.0


## Entra no mundo; `place` opcional abre um lugar ("stove"), personagem ("npc:bloblo")
## ou compra ("buy:oven") assim que chegar.
func enter(world_id: String, place: String = "") -> void:
	if not Database.worlds.has(world_id):
		return
	var reason := Places.world_error(world_id)
	if reason != "":
		Events.toast_requested.emit("Ainda não: " + reason)
		show_map()
		return
	_visit += 1
	var visit := _visit
	# Durante a nuvem, o pedido mais recente espera a troca atual e então segue.
	while _transition.busy:
		await get_tree().process_frame
		if visit != _visit: return
	var animate := world_id != current_world and is_visible_in_tree() and not Motion.reduced
	%MapView.dismiss()
	if animate:
		Events.sheet_close_requested.emit()
		_suspend_room_input()
		await _transition.travel(_switch_world.bind(world_id))
		_resume_room_input()
	else:
		_switch_world(world_id)
	if visit != _visit: return
	await _point_destination(world_id, place, visit)


func _switch_world(world_id: String) -> void:
	var entering := current_world != world_id or not _views.has(world_id) or not is_visible_in_tree()
	current_world = world_id
	GameState.note_screen_opened(world_id)
	if is_visible_in_tree(): GameState.note_world_visit(world_id)
	var fresh_view := not _views.has(world_id)
	if fresh_view:
		_views[world_id] = _build_world(world_id)
		%WorldHolder.add_child(_views[world_id])
		if _transition.busy: _views[world_id].set_process_input(false)
	for id: String in _views:
		_views[id].visible = id == world_id
	%MapView.hide()
	%WorldView.show()
	if entering: _views[world_id].present_labels()
	_header_key = ""
	_refresh_header()


func _point_destination(world_id: String, place: String, visit: int) -> void:
	if place == "":
		return
	await get_tree().process_frame  # a sala nova recentraliza a câmera no próximo quadro
	if visit != _visit or not is_visible_in_tree(): return
	var room := _views[world_id] as RoomView
	if place == "find":
		if room: room.point_at("find")
		return
	# "look:<ação>": só a seta, sem abrir o painel (o jogador toca por conta própria).
	if place.begins_with("look:"):
		if room:
			room.point_at(Places.highlight_action(place.trim_prefix("look:")))
		return
	# "Ir": a seta mostra ONDE fica a coisa e o painel abre logo depois.
	if room and room.point_at(Places.highlight_action(place)):
		get_tree().create_timer(POINT_DELAY).timeout.connect(func() -> void:
			if visit == _visit and current_world == world_id and is_visible_in_tree() and not is_map_open():
				Places.run(world_id, place))
	else:
		Places.run.call_deferred(world_id, place)


func _build_world(world_id: String) -> Control:
	var world: Dictionary = Database.worlds[world_id]
	var view: Control
	if world.get("room", "") != "":
		var room: RoomView = ROOM_SCENE.instantiate()
		room.room_id = world.room
		room.world_id = world_id
		view = room
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for side: String in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 10)
		var box := UiKit.vbox(8)
		var banner := _thumbnail(world_id, 200)
		if banner:
			box.add_child(banner)
		box.add_child(UiKit.label(world.get("description", ""), &"SmallLabel"))
		box.add_child(Places.world_list(world_id))
		margin.add_child(box)
		scroll.add_child(margin)
		view = scroll
	view.name = "World_" + world_id
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return view


func _open_places() -> void:
	Events.sheet_requested.emit("Lugares", Places.world_list(current_world))


## Barra flutuante do mundo, abaixo do HUD: pílula do mundo + lista de lugares (esquerda) e os
## rostos dos personagens dali (direita, em coluna). O contêiner ignora o mouse: arrastar o mundo
## continua funcionando fora das peças.
func _build_world_bar() -> void:
	var bar := Control.new()
	bar.name = "WorldBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 2
	%WorldView.add_child(bar)
	var left := HBoxContainer.new()
	left.name = "BarLeft"
	left.add_theme_constant_override("separation", 6)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.position = Vector2(Hud.SIDE, BAR_TOP + (Hud.ROW2_HEIGHT - WorldPill.HEIGHT) / 2.0)
	bar.add_child(left)
	var pill := WorldPill.new()
	pill.name = "MapButton"
	left.add_child(pill)
	pill.owner = self
	pill.unique_name_in_owner = true
	var places := UiKit.ctl_button("list", _open_places, 40)
	places.name = "PlacesButton"
	places.anchor_left = 1.0
	places.anchor_right = 1.0
	places.offset_left = -(BAR_MARGIN + 44.0)
	places.offset_right = -BAR_MARGIN
	places.offset_top = BAR_TOP
	places.offset_bottom = BAR_TOP + 44.0
	bar.add_child(places)  # fica embaixo dos rostos, na coluna da direita
	places.owner = self
	places.unique_name_in_owner = true
	var title := Label.new()  # só guarda o nome do mundo (testes e leitores de tela); não aparece
	title.name = "WorldTitle"
	title.visible = false
	bar.add_child(title)
	title.owner = self
	title.unique_name_in_owner = true
	var faces := VBoxContainer.new()
	faces.name = "NpcRow"
	faces.add_theme_constant_override("separation", 8)
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faces.anchor_left = 1.0
	faces.anchor_right = 1.0
	faces.offset_left = -(BAR_MARGIN + NpcFace.SIZE + 8.0)  # 8 a mais: o selo passa um pouco do círculo
	faces.offset_right = -BAR_MARGIN
	faces.offset_top = BAR_TOP
	faces.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.add_child(faces)
	faces.owner = self
	faces.unique_name_in_owner = true


## Nome do mundo na pílula e os rostos dos personagens (selo "!" = missão nova, check = pronta).
## Só refaz se algo mudou (refazer com o dedo na tela "engoliria" o toque).
func _refresh_header() -> void:
	var world: Dictionary = Database.worlds.get(current_world, {})
	var key := current_world
	for npc_id: String in Places.visible_npcs(current_world):
		key += "|%s:%s" % [npc_id, Places.npc_badge(npc_id)]
	if key == _header_key:
		return
	_header_key = key
	%WorldTitle.text = world.get("name", "")
	(%MapButton as WorldPill).set_world(current_world)
	for child in %NpcRow.get_children():
		child.queue_free()
	%NpcRow.visible = not Places.visible_npcs(current_world).is_empty()
	for npc_id: String in Places.visible_npcs(current_world):
		var face := NpcFace.new()
		face.pressed.connect(Places.open_npc.bind(npc_id))
		%NpcRow.add_child(face)
		face.setup(npc_id, Places.npc_badge(npc_id))
		Motion.pop_in(face)
	# O botão Lugares desce para baixo dos rostos (nunca sobrepõe).
	var faces_count := Places.visible_npcs(current_world).size()
	var places_top := BAR_TOP + faces_count * (NpcFace.SIZE + 8.0)
	%PlacesButton.offset_top = places_top
	%PlacesButton.offset_bottom = places_top + 44.0
	sync_row2.call_deferred()


## Linha 2 do HUD no Mapa: o próximo passo vai à direita da pílula do mundo, em modo compacto, e só mostra
## retrato + número se não couber antes dos rostos. Fora do Mapa tudo volta ao normal.
func sync_row2() -> void:
	var hud := get_tree().root.find_child("TopBar", true, false) as Hud
	if hud == null:
		return
	var on_map: bool = is_visible_in_tree() and %WorldView.visible and not is_map_open()
	if not on_map:
		hud.set_row2_inset(0.0)
		hud.next_step.compact = false
		hud.next_step.mini = false
		return
	hud.next_step.compact = true
	hud.set_row2_inset((%MapButton as Control).size.x + ROW2_GAP)
	# Limite: antes da coluna dos rostos (360 px: x ≤ 360 − 12 − 48 − 8 = 292).
	var limit := size.x - Hud.SIDE - NpcFace.SIZE - ROW2_GAP
	if not %NpcRow.visible:
		limit = size.x - Hud.SIDE
	var start := Hud.SIDE + (%MapButton as Control).size.x + ROW2_GAP
	hud.next_step.mini = false
	if start + hud.next_step.wanted_width() > limit:
		hud.next_step.mini = true


# --- Mapa ----------------------------------------------------------------------

## Miniatura do mundo: "banner" ou o fundo da sala, cortada para caber na largura.
func _thumbnail(world_id: String, height: int) -> TextureRect:
	if not _thumbs.has(world_id):
		var world: Dictionary = Database.worlds[world_id]
		var path: String = world.get("banner", "")
		if path == "" and world.get("room", "") != "":
			path = Database.room(world.room).get("background", "")
		_thumbs[world_id] = load(path) if path != "" and ResourceLoader.exists(path) else null
	if _thumbs[world_id] == null:
		return null
	var rect := TextureRect.new()
	rect.texture = _thumbs[world_id]
	rect.custom_minimum_size = Vector2(0, height)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.clip_contents = true
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# --- Dica parada --------------------------------------------------------------------
# Sem toque por `idle_hint_seconds` nos primeiros capítulos: seta sozinha no alvo do passo ativo
# (só a seta, sem abrir painel), uma vez por passo (memória, não vai para o save).

func _process(delta: float) -> void:
	if is_visible_in_tree() and %WorldView.visible and not is_map_open() and not _transition.busy:
		advance_idle(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		_idle = 0.0


## Soma tempo parado e mostra a seta quando passa do limite. Público para os testes.
func advance_idle(seconds: float) -> void:
	_idle += seconds
	var settings: Dictionary = Database.progression.settings
	if _idle < float(settings.get("idle_hint_seconds", 15)) or GameState.progress.chapter_index() > int(settings.get("idle_hint_max_chapter", 4)):
		return
	var room := _views.get(current_world) as RoomView
	if room == null:
		return
	var steps := GameState.progress.active_steps()
	var order: Array = []
	if steps.has("main"):
		order.append(steps["main"])
	for line: String in steps:
		if line != "main":
			order.append(steps[line])
	for quest_id: String in order:
		if _hinted.has(quest_id):
			continue
		var target := Places.quest_target(quest_id)
		if str(target.get("world", "")) != current_world or str(target.get("place", "")) == "":
			continue
		_hinted[quest_id] = true
		_idle = 0.0
		room.point_at(Places.highlight_action(str(target.place)))
		return
