extends Control
## Aba Mapa: a lista de mundos (MapView) e o mundo atual (WorldView).
##
## Os mundos vêm de data/worlds.json. Mundo com "room" vira uma sala (RoomView:
## casa, sítio); sem "room" vira uma tela com a imagem "banner" + cartões dos
## personagens e lugares. O cabeçalho do mundo mostra o botão "Mapa", o botão
## "Lugares" ("O que tem aqui?") e os personagens dali (com "!" quando há missão
## pronta), para nunca ser preciso adivinhar onde tocar.

const ROOM_SCENE := preload("res://scenes/levels/room/room.tscn")
## Segundos com a seta à vista antes de abrir o painel do destino.
const POINT_DELAY := 0.8

var current_world := "house"
var _views: Dictionary = {}  # world_id -> Control (criado na primeira visita e mantido)
var _thumbs: Dictionary = {}  # world_id -> Texture2D (miniatura do cartão do mapa)
var _header_key := ""


func _ready() -> void:
	%MapButton.pressed.connect(show_map)
	%MapButton.icon = UiKit.ui_icon("tab_map")
	%PlacesButton.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Locais" if current_world == "nature" else "O que tem aqui?", Places.world_list(current_world)))
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
	if not _views.has(world_id):
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
	# "Ir": a seta mostra ONDE fica a coisa e o painel abre logo depois.
	var room := _views[world_id] as RoomView
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


## Cabeçalho: nome do mundo e, embaixo, os personagens dali (com nome). Só refaz se algo mudou
## (refazer com o dedo na tela "engoliria" o toque).
func _refresh_header() -> void:
	var world: Dictionary = Database.worlds.get(current_world, {})
	var key := current_world
	for npc_id: String in Places.visible_npcs(current_world):
		key += "|%s:%s" % [npc_id, Places.npc_alert(npc_id) != ""]
	if key == _header_key:
		return
	_header_key = key
	%WorldTitle.text = world.get("name", "")
	%PlacesButton.text = "Locais" if current_world == "nature" else "Lugares"
	for child in %NpcRow.get_children():
		child.queue_free()
	%NpcRow.visible = not Places.visible_npcs(current_world).is_empty()
	for npc_id: String in Places.visible_npcs(current_world):
		# Personagem com nome escrito; verde e com "!" quando tem missão pronta.
		var ready := Places.npc_alert(npc_id) != ""
		var npc_name: String = Database.npcs.get(npc_id, {}).get("name", npc_id)
		var chip := UiKit.button(("! " if ready else "") + npc_name, Places.open_npc.bind(npc_id), &"PrimaryButton" if ready else &"", ProgressionUi.npc_portrait(npc_id))
		chip.custom_minimum_size = Vector2(0, 40)
		chip.add_theme_constant_override("icon_max_width", 28)
		chip.add_theme_font_size_override("font_size", 16)
		%NpcRow.add_child(chip)


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
		normal.bg_color = Color("f7e9c9") if locked == "" else Color("e7ddc7")
		normal.border_color = Color("689847") if not alerts.is_empty() or world_id == current_world else Color("a87d52")
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(12)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("disabled", normal)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("e5d0a4")
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
