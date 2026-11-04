class_name WorldCard
extends Button
## Cartão-postal do seletor de mundos em "madeira ilustrada": foto emoldurada (proporção da própria arte), plaquinha
## creme com o nome embaixo, discos de madeira nos cantos com os avisos do mundo (no máximo três) e os bloqueios reais.
## As imagens `map_*.png` vêm de `tools/world_map_art.gd`. Mundo atual = contorno dourado + selinho "Aqui".
## Nós preservados: `WorldPhoto`, `WorldName`, `WorldLock`, `CurrentWorld`, `WorldHint`, `WorldOpener`,
## `WorldStatusRows` e `WorldStatus_<tipo>` (rewards, missions, collections, finds, treasure, busy).

const KINDS := ["rewards", "missions", "collections", "finds", "treasure", "busy"]
const MAX_STATUS := 3
const PLATE_RATIO := 213.0 / 600.0      # altura / largura da plaquinha
const PLATE_OVERLAP := 0.30             # parte da plaquinha que sobe sobre a foto (a "corcunda" de madeira)
const DISC_RATIO := 137.0 / 132.0       # altura / largura do disco guardado
const CORNER := 6.0                     # folga do disco até o canto da foto

var world_id := ""
var wide := false
var plate_width := 100.0
var _photo_height := 0.0
var _picture: TextureRect
var _halo: Panel
var _plate: TextureRect
var _title: Label
var _here: Control
var _lock: TextureRect
var _status: Control
var _hint: Label
var _opener: TextureRect
var _kinds_shown: Array[Dictionary] = []


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "map_" + file + ".png") as Texture2D


func setup(id: String) -> void:
	world_id = id
	name = "WorldCard_" + id
	focus_mode = Control.FOCUS_NONE
	flat = true
	for kind: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(kind, StyleBoxEmpty.new())
	var world: Dictionary = Database.worlds[id]
	_picture = SellUi.soft(TextureRect.new())
	_picture.name = "WorldPhoto"
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_picture)
	_halo = Panel.new()
	_halo.name = "CurrentHalo"
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(0, 0, 0, 0)
	ring.border_color = Palette.WOOD_PICK
	ring.set_border_width_all(3)
	ring.set_corner_radius_all(14)
	_halo.add_theme_stylebox_override("panel", ring)
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_halo)
	_status = Control.new()
	_status.name = "WorldStatusRows"
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	_lock = SellUi.soft(TextureRect.new())
	_lock.name = "WorldLock"
	_lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
	_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_lock)
	_hint = MissionUi.text("", 12, Palette.WOOD_CREAM, 3)
	_hint.name = "WorldHint"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_hint)
	_plate = SellUi.soft(TextureRect.new())
	_plate.name = "WorldPlate"
	_plate.texture = tex("plate")
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_plate)
	_title = StationWood.text(str(world.get("map_name", world.name)), 15)
	_title.name = "WorldName"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_title)
	_here = _make_here()
	add_child(_here)
	_opener = UiKit.icon(null, 20)
	_opener.name = "WorldOpener"
	_opener.visible = false
	add_child(_opener)
	resized.connect(_layout)
	refresh("")


func _make_here() -> Control:
	var pill := PanelContainer.new()
	pill.name = "CurrentWorld"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_PICK
	style.set_corner_radius_all(9)
	style.set_border_width_all(2)
	style.border_color = Color("8a4b1f")
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 0
	style.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", style)
	var label := StationWood.text("Aqui", 12, Color("fff8e6"), 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	return pill


## Largura total do cartão -> define a altura (proporção da foto + plaquinha) e arruma tudo. Devolve a altura.
func fit(width: float) -> float:
	var photo: Texture2D = _picture.texture
	var ratio := float(photo.get_height()) / float(photo.get_width()) if photo != null else 0.967
	_photo_height = width * ratio
	var plate_h := plate_width * PLATE_RATIO
	size = Vector2(width, _photo_height + plate_h * (1.0 - PLATE_OVERLAP))
	_layout()
	return size.y


func plate_rect() -> Rect2:
	var plate_h := plate_width * PLATE_RATIO
	return Rect2((size.x - plate_width) / 2.0, _photo_height - plate_h * PLATE_OVERLAP, plate_width, plate_h)


func photo_rect() -> Rect2:
	return Rect2(0, 0, size.x, _photo_height)


func disc_width() -> float:
	return clampf(_photo_height * 0.30 if not wide else size.x * 0.17, 34.0, 44.0)


func refresh(current: String) -> void:
	disabled = Places.world_error(world_id) != ""
	_here.visible = not disabled and current == world_id
	_halo.visible = _here.visible
	_lock.visible = disabled
	var path := HomeUi.DIR + "map_%s%s.png" % [world_id, "_locked" if disabled else ""]
	if ResourceLoader.exists(path): _picture.texture = load(path)
	for child: Node in _status.get_children():
		_status.remove_child(child)
		child.queue_free()
	_kinds_shown.clear()
	if not disabled:
		var summary := Places.world_summary(world_id)
		var ready := int(summary.rewards) + int(summary.collections) + int(summary.finds)
		for kind: String in KINDS:
			if _kinds_shown.size() >= MAX_STATUS: break
			var amount := int(summary.get(kind, 0))
			if amount <= 0: continue
			if kind == "busy" and ready > 0: continue  # em andamento só aparece quando nada está pronto
			_kinds_shown.append({"kind": kind, "amount": amount})
	_hint.visible = disabled
	_hint.text = _locked_hint() if disabled else ""
	_opener.visible = false
	var requirements: Dictionary = Database.worlds[world_id].get("requirements", {})
	for quest: String in requirements.get("quests", []):
		var npc: String = Database.quests.get(quest, {}).get("npc", "")
		if npc != "":
			_opener.texture = ProgressionUi.npc_portrait(npc)
			break
	_build_status()
	_layout()
	_ignore_mouse(self)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Disco de madeira com o ícone da categoria; número numa pílula creme colada embaixo, "!" no selo vermelho.
func _build_status() -> void:
	for entry: Dictionary in _kinds_shown:
		var kind: String = entry.kind
		var amount: int = entry.amount
		var holder := Control.new()
		holder.name = "WorldStatus_" + kind
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var disc := SellUi.soft(TextureRect.new())
		disc.name = "Disc"
		disc.texture = tex("status_" + kind)
		disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		disc.stretch_mode = TextureRect.STRETCH_SCALE
		disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(disc)
		_status.add_child(holder)
		if kind == "missions":
			var mark := SellUi.soft(TextureRect.new())
			mark.name = "NewBadge"
			mark.texture = MissionUi.tex("tab_badge")
			mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mark.stretch_mode = TextureRect.STRETCH_SCALE
			holder.add_child(mark)
		elif kind in ["rewards", "collections", "busy"] or amount > 1:
			holder.add_child(_count_pill(amount))


func _count_pill(amount: int) -> Control:
	var pill := PanelContainer.new()
	pill.name = "Count"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff3dc")
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color("8a4b1f")
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 0
	style.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", style)
	var label := StationWood.text(str(amount), 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	return pill


func _locked_hint() -> String:
	var world: Dictionary = Database.worlds[world_id]
	if world.has("map_locked_hint"): return str(world.map_locked_hint)
	var requirements: Dictionary = world.get("requirements", {})
	for id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(id):
			return "Depois de: " + str(Database.quests.get(id, {}).get("name", id))
	if requirements.has("chapter"):
		return "Capítulo %d" % int(requirements.chapter)
	return Places.world_error(world_id)


func _layout() -> void:
	if not is_instance_valid(_hint) or _photo_height <= 0.0: return
	var photo := photo_rect()
	_picture.position = photo.position
	_picture.size = photo.size
	_halo.position = photo.position - Vector2(1, 1)
	_halo.size = photo.size + Vector2(2, 2)
	(_halo.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(int(roundf(size.x * 0.07)))
	var plate := plate_rect()
	_plate.position = plate.position
	_plate.size = plate.size
	# A parte creme da plaquinha fica entre 20% e 78% da altura e 9% das pontas; o texto cabe aí.
	_title.position = plate.position + Vector2(plate.size.x * 0.12, plate.size.y * 0.20)
	_title.size = Vector2(plate.size.x * 0.76, plate.size.y * 0.58)
	HomeUi.resize(_title, clampi(int(roundf(plate.size.y * 0.40)), 11, 16))
	_here.size = _here.get_combined_minimum_size()
	_here.position = Vector2(size.x - _here.size.x - 8, _photo_height - plate.size.y * PLATE_OVERLAP - _here.size.y - 6)
	var lock_px := clampf(_photo_height * 0.30, 28.0, 44.0)
	_lock.size = Vector2(lock_px, lock_px)
	_lock.position = Vector2((size.x - lock_px) / 2.0, maxf(6.0, _photo_height * 0.10))
	var hint_top := _lock.position.y + lock_px + 3.0
	var hint_width := maxf(40.0, size.x - 20.0)
	_hint.position = Vector2((size.x - hint_width) / 2.0, hint_top)
	_hint.size = Vector2(hint_width, 0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var room := _photo_height - plate.size.y * PLATE_OVERLAP - hint_top - 4.0
	var px := 12
	HomeUi.resize(_hint, px)
	while px > 9 and _hint.get_minimum_size().y > room:
		px -= 1
		HomeUi.resize(_hint, px)
	_hint.size.y = _hint.get_minimum_size().y
	_opener.position = Vector2(size.x - 32, hint_top)
	_opener.size = Vector2(20, 20)
	_layout_status()


func _layout_status() -> void:
	_status.position = Vector2.ZERO
	_status.size = size
	var width := disc_width()
	var height := width * DISC_RATIO
	var slots: Array[Vector2] = [
		Vector2(CORNER, CORNER),
		Vector2(size.x - CORNER - width, CORNER),
		Vector2(CORNER, CORNER + height + 15.0),
	]
	for i: int in _status.get_child_count():
		var holder := _status.get_child(i) as Control
		holder.position = slots[i]
		holder.size = Vector2(width, height)
		var pill := holder.get_node_or_null("Count") as Control
		if pill:
			pill.size = pill.get_combined_minimum_size()
			pill.position = Vector2((width - pill.size.x) / 2.0, height - 7.0)
		var mark := holder.get_node_or_null("NewBadge") as Control
		if mark:
			var badge := width * 0.42
			mark.size = Vector2(badge, badge)
			mark.position = Vector2(width - badge * 0.72, -badge * 0.2)


func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: _ignore_mouse(child)
