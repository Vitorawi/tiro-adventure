class_name WorldCard
extends Button
## Cartão do carrossel: a maquete aparece sobre o mesmo céu e chão do mundo.

const CARD_SIZE := Vector2(240, 330)
var world_id: String = ""
var _preview: Preview
var _footer: Control
var _badge: Label


func setup(id: String) -> void:
	world_id = id
	name = "WorldCard_" + id
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.border_color = Palette.CARD_LINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Palette.SHADE
	style.shadow_size = 3
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, style)
	var stripe := Panel.new()
	stripe.position = Vector2(2, 2)
	stripe.size = Vector2(236, 8)
	var stripe_style := StyleBoxFlat.new()
	stripe_style.bg_color = Palette.WORLD.get(id, Palette.ACCENT)
	stripe_style.corner_radius_top_left = 12
	stripe_style.corner_radius_top_right = 12
	stripe.add_theme_stylebox_override("panel", stripe_style)
	add_child(stripe)
	_preview = Preview.new()
	_preview.name = "WorldPreview"
	_preview.position = Vector2(12, 18)
	_preview.size = Vector2(216, 144)
	_preview.setup(id)
	add_child(_preview)
	var world: Dictionary = Database.worlds[id]
	var heading := UiKit.hbox(6)
	heading.position = Vector2(16, 170)
	heading.size = Vector2(208, 36)
	heading.add_child(UiKit.icon(UiKit.ui_icon(str(world.get("icon", "tab_map"))), 32))
	var title := UiKit.label(str(world.get("map_name", world.name)), &"TitleLabel")
	title.add_theme_font_size_override("font_size", 26)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(title)
	add_child(heading)
	var caption := UiKit.label(str(world.get("map_caption", "")), &"SmallLabel")
	caption.position = Vector2(16, 210)
	caption.size = Vector2(208, 24)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(caption)
	_footer = Control.new()
	_footer.position = Vector2(16, 244)
	_footer.size = Vector2(208, 76)
	add_child(_footer)
	_badge = UiKit.label("!", &"BadgeLabel")
	_badge.name = "MissionBadge"
	_badge.position = Vector2(204, 18)
	_badge.size = Vector2(24, 24)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_badge)
	_ignore_mouse(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh("")


func refresh(current: String) -> void:
	disabled = Places.world_error(world_id) != ""
	_preview.modulate.a = 0.55 if disabled else 1.0
	for child: Node in _preview.get_children():
		_preview.remove_child(child)
		child.queue_free()
	for child: Node in _footer.get_children():
		_footer.remove_child(child)
		child.queue_free()
	var status: Control
	if disabled:
		var hint := Places.unlock_hint(world_id)
		status = UiKit.lock_hint(str(hint.text))
		# O motivo usa a história/retrato; o cadeado grande continua sobre a miniatura.
		(status.get_child(0) as TextureRect).texture = hint.icon
		var lock := UiKit.lock_icon(48)
		lock.name = "PreviewLock"
		lock.position = Vector2(84, 48)
		_preview.add_child(lock)
	elif current == world_id:
		status = UiKit.chip(UiKit.ui_icon("ui_check"), "Você está aqui", Palette.GOOD)
		var pill_style := StyleBoxFlat.new()
		pill_style.bg_color = Palette.PRIMARY.lightened(0.75)
		pill_style.set_corner_radius_all(20)
		pill_style.content_margin_left = 8
		pill_style.content_margin_right = 8
		status.add_theme_stylebox_override("panel", pill_style)
	else:
		var count := Places.world_alerts(world_id).size()
		status = UiKit.chip(UiKit.ui_icon("ui_check"), "%d pronto%s" % [count, "s" if count != 1 else ""], Palette.GOOD) if count > 0 else UiKit.label("Tocar para viajar", &"SmallLabel")
	status.size = Vector2(_footer.size.x, 72 if disabled else 40)
	_footer.add_child(status)
	_badge.visible = false
	if not disabled:
		for npc_id: String in Places.visible_npcs(world_id):
			if Places.npc_badge(npc_id) != "":
				_badge.visible = true
	_ignore_mouse(self)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control:
			_ignore_mouse(child)


class Preview extends Control:
	var _sky: GradientTexture2D
	var _ground: Color = Palette.SUNKEN
	var _image: Texture2D
	var _far: Texture2D

	func setup(id: String) -> void:
		var world: Dictionary = Database.worlds[id]
		var room: Dictionary = Database.room(str(world.get("room", "")))
		var backdrop: Dictionary = room.get("backdrop", {})
		var colors: Array = backdrop.get("sky", [])
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(str(colors[0])), Color(str(colors[1]))]) if colors.size() >= 2 else PackedColorArray([Palette.INFO, Palette.PAPER])
		_sky = GradientTexture2D.new()
		_sky.gradient = gradient
		_sky.fill_to = Vector2(0, 1)
		_ground = Color(str(backdrop.get("ground", Palette.SUNKEN.to_html())))
		var path: String = world.get("banner", room.get("background", ""))
		_image = load(path) if ResourceLoader.exists(path) else null
		path = str(backdrop.get("texture", ""))
		_far = load(path) if path != "" and ResourceLoader.exists(path) else null
		clip_contents = true

	func _draw() -> void:
		draw_texture_rect(_sky, Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.6)), false)
		draw_rect(Rect2(0, size.y * 0.6, size.x, size.y * 0.4), _ground)
		if _far:
			draw_texture_rect(_far, Rect2(0, 0, size.x, size.y * 0.7), false)
		if _image:
			var factor := minf((size.x - 8) / _image.get_width(), (size.y - 8) / _image.get_height())
			var extent := _image.get_size() * factor
			draw_texture_rect(_image, Rect2((size - extent) / 2, extent), false)
