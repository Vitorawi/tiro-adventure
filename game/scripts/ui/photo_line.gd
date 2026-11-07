class_name PhotoLine
extends Control
## Varal da home do Tiro (Fotos, etapa 08): até 3 polaroides em destaque presas por pregadores.
## Tocar numa abre a carta 3D; espaço vazio ("+") leva ao Álbum. Só aparece depois da primeira foto aberta,
## some no passeio e (dormindo) se cobrir a cabeça/Zz. Sem `_process`: o balanço é um tween lento.

const SLOTS := 3
const CARD_MAX := 84
const CARD_MIN := 72
const GAP := 6.0
const MARGIN := 8.0
const CORD_H := 16.0               # altura da cordinha + pregadores acima das polaroides
const ANGLES: Array[float] = [-4.0, 2.0, -2.0]
const CORD := Color("8a5a2b")
const PIN := Color("c98b4a")
const PIN_EDGE := Color("7a4a20")

var pet: Control                    # a PetScreen (dona do varal)
var card_px := CARD_MAX
var _signature: Array = []
var _items: Array[Control] = []
var _tweens: Array[Tween] = []


func _init() -> void:
	name = "PhotoLine"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


## Fotos que têm carta aberta (a primeira abre o varal).
static func has_opened() -> bool:
	for id: Variant in GameState.album.photos:
		if GameState.photo_rarity(str(id)) > 0:
			return true
	return false


## Ids mostrados, na ordem do motor (`featured_photos`).
static func shown_ids() -> Array[String]:
	return GameState.featured_photos()


## Quanto cabe: largura da polaroide para o espaço entre a margem e o balão do desejo.
static func fit_px(available: float) -> int:
	return clampi(floori((available - GAP * (SLOTS - 1)) / SLOTS), CARD_MIN, CARD_MAX)


func sync() -> void:
	if pet == null or not is_instance_valid(pet): return
	var show := has_opened() and not GameState.walking() and pet.is_inside_tree()
	if not show:
		hide()
		return
	var area := _area()
	card_px = fit_px(area.size.x)
	var ids := shown_ids()
	var signature: Array = [card_px, Motion.reduced]
	for id in ids:
		signature.append([id, GameState.photo_shown_rarity(id)])
	if signature != _signature:
		_signature = signature
		_rebuild(ids)
	_place(area)
	# Dormindo, o varal só fica se não cobrir a cabeça (onde sobe o Zz).
	var covers: bool = GameState.dog.sleeping and get_global_rect().grow(4.0).intersects(pet.call("head_rect"))
	visible = not covers


## Faixa livre: abaixo do HUD, à esquerda do balão do desejo, acima da cabeça do Tiro.
func _area() -> Rect2:
	var top := Hud.HEIGHT - pet.global_position.y + 6.0
	var right: float = pet.call("photo_line_right")
	return Rect2(MARGIN, top, maxf(right - MARGIN, 0.0), 0.0)


func _place(area: Rect2) -> void:
	var total := card_px * SLOTS + GAP * (SLOTS - 1)
	position = Vector2(area.position.x + (area.size.x - total) * 0.5, area.position.y)
	size = Vector2(total, CORD_H + card_px)
	queue_redraw()


func _rebuild(ids: Array[String]) -> void:
	for tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()
	for node in _items:
		remove_child(node)  # sai já, para o nome do novo não virar "@Button@N"
		node.queue_free()
	_items.clear()
	for index in SLOTS:
		var holder := Button.new()
		holder.flat = true
		holder.focus_mode = Control.FOCUS_NONE
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.position = Vector2(index * (card_px + GAP), CORD_H)
		holder.size = Vector2(card_px, card_px)
		holder.custom_minimum_size = holder.size
		holder.pivot_offset = Vector2(card_px * 0.5, 0.0)
		holder.rotation_degrees = ANGLES[index]
		for style: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			holder.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		if index < ids.size():
			var id := ids[index]
			holder.name = "PhotoLine_" + id
			holder.set_meta("photo", id)
			var card := PhotoCard.make(id, card_px, {"effects": true, "still": Motion.reduced})
			card.set_anchors_preset(Control.PRESET_FULL_RECT)
			holder.add_child(card)
			holder.pressed.connect(_open_photo.bind(id))
			Motion.press(holder)
		else:
			holder.name = "PhotoSlot_%d" % index
			var box := Panel.new()
			var style := UiKit.surface(Color(Palette.WOOD_CREAM, 0.6), 8)
			style.border_color = Color(Palette.WOOD_INK, 0.6)
			style.set_border_width_all(2)
			box.add_theme_stylebox_override("panel", style)
			box.set_anchors_preset(Control.PRESET_FULL_RECT)
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(box)
			var plus := UiKit.ctl("plus", 28, Palette.WOOD_INK)
			plus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plus.size = Vector2(28, 28)
			plus.position = (holder.size - plus.size) * 0.5
			plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(plus)
			holder.pressed.connect(_open_album)
		add_child(holder)
		_items.append(holder)
		if not Motion.reduced:
			_swing(holder, index)


## Balanço sutil e lento, cada polaroide com seu ritmo (parado em Menos animação).
func _swing(holder: Control, index: int) -> void:
	var base: float = ANGLES[index]
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var time := 2.6 + 0.5 * index
	tween.tween_property(holder, "rotation_degrees", base + 1.2, time)
	tween.tween_property(holder, "rotation_degrees", base - 1.2, time)
	_tweens.append(tween)


func _open_photo(id: String) -> void:
	CardViewer.open(id)


func _open_album() -> void:
	AlbumScreen.open()


func _draw() -> void:
	if size.x <= 0.0: return
	# Cordinha com uma leve barriga entre as pontas e um pregador por polaroide.
	var left := Vector2(-4.0, 3.0)
	var right := Vector2(size.x + 4.0, 3.0)
	var points := PackedVector2Array()
	for step in 17:
		var t := step / 16.0
		points.append(left.lerp(right, t) + Vector2(0.0, sin(t * PI) * 4.0))
	draw_polyline(points, Color(Palette.WOOD_SHADOW, 0.5), 3.0, true)
	draw_polyline(points, CORD, 2.0, true)
	for index in SLOTS:
		var cx := index * (card_px + GAP) + card_px * 0.5
		var t := (cx + 4.0) / (size.x + 8.0)
		var y := 3.0 + sin(t * PI) * 4.0
		var pin := Rect2(cx - 4.0, y - 2.0, 8.0, 14.0)
		draw_rect(pin, PIN, true)
		draw_rect(pin, PIN_EDGE, false, 1.0)
		draw_line(Vector2(cx, y + 2.0), Vector2(cx, y + 12.0), PIN_EDGE, 1.0)
