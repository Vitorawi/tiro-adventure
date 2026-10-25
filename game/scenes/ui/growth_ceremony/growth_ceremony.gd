class_name GrowthCeremony
extends CanvasLayer
## Uma revelação por fase, serializada pela casca. O recibo só é visto ao tocar em Que lindo!.
signal closed

const DELIVERY_SECONDS := 0.45
const CONCENTRATION_SECONDS := 1.0
const TRANSFORMATION_SECONDS := 2.5
const MAX_SWITCHES_PER_SECOND := 3.0
const SWITCH_INTERVALS := [0.54, 0.48, 0.42, 0.38, 0.34, 0.34]
const REDUCED_SECONDS := 0.4

var phase: String = ""
var switching := false
var _before: Dictionary
var _after: Dictionary
var _record: Dictionary
var _scene: Control
var _mark_progress := 1.0


func _init() -> void:
	name = "GrowthCeremony"
	layer = 32
	visible = false


func open(id: String) -> void:
	if visible: return
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	phase = id
	_record = GameState.growth.ceremonies.get(id, {}).duplicate(true)
	if bool(_record.get("seen", true)): return
	var index := GameState.growth.phase_index(id)
	_after = Database.growth.phases[index].duplicate(true)
	_before = Database.growth.phases[maxi(0, index - 1)].duplicate(true)
	_before["coat"] = float(_record.get("before_coat", _before.coat))
	_after["coat"] = float(_record.get("after_coat", _after.coat))
	show()
	await _play()


static func pose(def: Dictionary, px: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(px, px + 20)
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target := UiKit.icon(load(str(Database.growth.bodies[def.body].dir.pet) + "idle_breathe/frame_00.png"), px * 2)
	target.custom_minimum_size = Vector2.ZERO
	target.size = Vector2(px * 2, px * 2.0 * 216.0 / 256.0)
	target.position = Vector2(-px * 0.5, -px * 9.0 / 64.0)
	target.material = DogLook.material()
	(target.material as ShaderMaterial).set_shader_parameter("coat", float(def.coat))
	holder.add_child(target)
	return holder


func _play() -> void:
	_scene = Control.new()
	_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scene)
	var dim := ColorRect.new()
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene.add_child(center)
	var stage := pose(_before, 200)
	stage.name = "Concentration"
	var glow := UiKit.icon(load(ModalCard.RAYS_PATH), 256)
	glow.modulate.a = 0.0
	center.add_child(glow)
	center.add_child(stage)
	# Entregas já consumidas: só a memória visual voa; não há segunda transação.
	for item: String in _record.get("delivered", {}) if not Motion.reduced else {}:
		Haptics.tap()
		var icon := UiKit.icon(Database.item_icon(item), 40)
		_scene.add_child(icon)
		var screen := get_viewport().get_visible_rect().size
		icon.position = screen * Vector2(0.2, 0.7)
		var fly := create_tween().set_parallel()
		fly.tween_property(icon, "position", screen * 0.5 - Vector2(20, 20), DELIVERY_SECONDS)
		fly.tween_property(icon, "modulate:a", 0.0, DELIVERY_SECONDS)
		await fly.finished
		icon.queue_free()
	if not Motion.reduced:
		create_tween().tween_property(glow, "modulate:a", 0.6, CONCENTRATION_SECONDS)
		stage.pivot_offset = Vector2(100, 110)
		var breathe := create_tween()
		breathe.tween_property(stage, "scale", Vector2(1.04, 1.04), CONCENTRATION_SECONDS * 0.5)
		breathe.tween_property(stage, "scale", Vector2.ONE, CONCENTRATION_SECONDS * 0.5)
		stage.modulate = Color(1.0, 1.0, 1.0, 0.65)
		create_tween().tween_property(stage, "modulate:a", 1.0, CONCENTRATION_SECONDS)
		await breathe.finished
	var next_pose := pose(_after, 200)
	center.add_child(next_pose)
	if Motion.reduced:
		next_pose.modulate.a = 0.0
		var fade := create_tween().set_parallel()
		fade.tween_property(stage, "modulate:a", 0.0, REDUCED_SECONDS)
		fade.tween_property(next_pose, "modulate:a", 1.0, REDUCED_SECONDS)
		await fade.finished
	else:
		var white := Shader.new()
		white.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); COLOR=vec4(vec3(1.0),c.a);}"
		for dog: Control in [stage, next_pose]:
			var mat := ShaderMaterial.new()
			mat.shader = white
			(dog.get_child(0) as TextureRect).material = mat
		next_pose.hide()
		switching = true
		for interval: float in SWITCH_INTERVALS:
			await get_tree().create_timer(interval).timeout
			stage.visible = not stage.visible
			next_pose.visible = not stage.visible
		switching = false
	show_card()


func show_card() -> void:
	var card := ModalCard.open(self, {"title": "O Tiro cresceu!", "ribbon": Palette.HONEY, "icon": load(str(Database.growth.bodies[_after.body].portrait)),
		"icon_px": 64, "confetti": not Motion.reduced, "haptic": "big"})
	card.icon_node.material = DogLook.material()
	(card.icon_node.material as ShaderMaterial).set_shader_parameter("coat", float(_after.coat))
	var pair := UiKit.hbox(8)
	pair.name = "BeforeAfter"
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	for def: Dictionary in [_before, _after]:
		var column := UiKit.vbox(2)
		column.add_child(pose(def, 124))
		var label := UiKit.label(str(def.name), &"SmallLabel")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		pair.add_child(column)
	card.add(pair)
	card.add_text(str(_after.age) + " · " + str(_after.weight), &"SectionLabel")
	card.add_text(str(_after.facts[0]), &"SmallLabel")
	var ruler := Control.new()
	ruler.name = "HeightMark"
	ruler.custom_minimum_size = Vector2(280, 32)
	card.add(ruler)
	var index := GameState.growth.phase_index(phase)
	_mark_progress = 1.0 if Motion.reduced else 0.0
	ruler.draw.connect(func() -> void:
		ruler.draw_line(Vector2(12, 25), Vector2(268, 25), Palette.LINE, 2)
		for i in 6:
			var x := 18.0 + i * 48.0
			var tip := lerpf(25.0, 19.0 - i * 3.0, _mark_progress) if i == index else 19.0 - i * 3.0
			ruler.draw_line(Vector2(x, 25), Vector2(x, tip), Palette.GO if i == index else Palette.LINE, 3 if i == index else 1))
	if not Motion.reduced:
		create_tween().tween_method(func(value: float) -> void:
			_mark_progress = value
			ruler.queue_redraw(), 0.0, 1.0, Motion.SLIDE)
	card.add_primary("Que lindo!", _close).name = "CloseCeremony"


func _close() -> void:
	GameState.acknowledge_growth(phase)
	hide()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	closed.emit()
