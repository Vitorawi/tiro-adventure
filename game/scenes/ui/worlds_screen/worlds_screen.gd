extends Control
## Aba Mapa: a lista de mundos (MapView) e o mundo atual (WorldView).
##
## Os mundos vêm de data/worlds.json. Mundo com "room" vira uma sala (RoomView:
## casa, sítio); sem "room" vira uma tela com a imagem "banner" + cartões dos
## personagens e lugares. O mundo ocupa a tela toda (o HUD flutua por cima); a barra do mundo
## mostra a pílula do mundo (abre a lista de mundos), o botão "Lugares" e os rostos dos
## personagens dali (com selo quando há missão), para nunca ser preciso adivinhar onde tocar.

const ROOM_SCENE := preload("res://scenes/levels/room/room.tscn")
## Segundos com a seta à vista antes de abrir o painel do destino.
const POINT_DELAY := 0.8
## Barra do mundo: margem lateral e altura (logo abaixo do HUD, que tem 60).
const BAR_MARGIN := 10.0
const BAR_TOP := 64.0

var current_world := "house"
var _views: Dictionary = {}  # world_id -> Control (criado na primeira visita e mantido)
var _thumbs: Dictionary = {}  # world_id -> Texture2D (miniatura do cartão do mapa)
var _header_key := ""
var _idle := 0.0
var _hinted: Dictionary = {}  # passos que já ganharam a seta da dica parada


func _ready() -> void:
	_build_world_bar()
	%MapButton.pressed.connect(show_map)
	%Cards.add_child(SheetBuilder.LiveBox.new(_build_cards))
	Events.state_changed.connect(_refresh_header)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_header)
	add_child(timer)
	enter(current_world)


func show_map() -> void:
	%MapView.show()
	%WorldView.hide()


func is_map_open() -> bool:
	return %MapView.visible


## Reserva espaço para o aviso abaixo da pílula e dos rostos, sem cobrir os botões do mapa.
func toast_top() -> float:
	if not is_visible_in_tree() or not %WorldView.visible:
		return 0.0
	var bottom: float = %MapButton.get_global_rect().end.y
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
		Events.toast_requested.emit("Ainda fechado: " + reason)
		show_map()
		return
	current_world = world_id
	GameState.note_screen_opened(world_id)
	var fresh_view := not _views.has(world_id)
	if fresh_view:
		_views[world_id] = _build_world(world_id)
		%WorldHolder.add_child(_views[world_id])
	for id: String in _views:
		_views[id].visible = id == world_id
	%MapView.hide()
	%WorldView.show()
	_header_key = ""
	_refresh_header()
	if place == "":
		return
	if fresh_view:
		await get_tree().process_frame  # a sala nova recentraliza a câmera no próximo quadro
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
			if current_world == world_id and %WorldView.visible:
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
	left.position = Vector2(BAR_MARGIN, BAR_TOP)
	bar.add_child(left)
	var pill := WorldPill.new()
	pill.name = "MapButton"
	left.add_child(pill)
	pill.owner = self
	pill.unique_name_in_owner = true
	var places := UiKit.icon_button(UiKit.ui_icon("tab_tasks"), _open_places, 44)
	places.name = "PlacesButton"
	left.add_child(places)
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


# --- Mapa ----------------------------------------------------------------------

func _build_cards(box: VBoxContainer) -> void:
	box.add_theme_constant_override("separation", 10)
	for world_id: String in Database.worlds:
		var world: Dictionary = Database.worlds[world_id]
		var locked := Places.world_error(world_id)
		var alerts := Places.world_alerts(world_id)
		var button := UiKit.button("", enter.bind(world_id, ""))
		button.name = "WorldCard_" + world_id
		button.custom_minimum_size = Vector2(0, 138 if locked != "" else 118)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = locked != ""
		var normal := StyleBoxFlat.new()
		normal.bg_color = Palette.CARD if locked == "" else Palette.SUNKEN
		var highlighted := not alerts.is_empty() or world_id == current_world
		normal.border_color = Palette.PRIMARY if highlighted else Palette.CARD_LINE
		normal.set_border_width_all(3 if highlighted else 2)
		normal.set_corner_radius_all(14)
		normal.shadow_color = Palette.SHADE
		normal.shadow_size = 3
		normal.shadow_offset = Vector2(0, 2)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("disabled", normal)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Palette.SUNKEN
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover", normal)
		var row := UiKit.hbox(12)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.offset_top = 10
		row.offset_bottom = -10
		var picture := _thumbnail(world_id, 88)
		if picture:
			picture.custom_minimum_size.x = 88
			picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			picture.modulate.a = 0.55 if locked != "" else 1.0
			row.add_child(picture)
		var info := UiKit.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.add_child(UiKit.label(world.get("map_name", world.name), &"SectionLabel"))
		info.add_child(UiKit.label(world.get("map_caption", world.get("description", "")), &"SmallLabel"))
		if locked != "":
			var hint := "Fechado · " + locked
			if world.get("requirements", {}).has("chapter"):
				hint = "Abre no capítulo %d" % int(world.requirements.chapter)
			info.add_child(UiKit.label(hint, &"SmallLabel", UiKit.BAD))
		elif not alerts.is_empty():
			info.add_child(UiKit.label("Algo pronto para recolher!", &"SmallLabel", UiKit.GOOD))
		elif world_id == current_world:
			info.add_child(UiKit.label("Você está aqui", &"SmallLabel", UiKit.GOOD))
		row.add_child(info)
		row.add_child(UiKit.short_label("›" if locked == "" else "—", &"TitleLabel"))
		button.add_child(row)
		_ignore_card_mouse(row)
		box.add_child(button)


func _ignore_card_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control:
			_ignore_card_mouse(child)


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
	if is_visible_in_tree() and %WorldView.visible:
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
