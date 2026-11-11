@tool
extends Node2D
## Independent art rig. Reuses the exact approved PNGs; not wired into PetAnimator.
## First stage: body anchored, head tilt, shared breathing phase and a soft cancel.
const CANVAS := Vector2(768,648)
const SOURCE := "res://assets/sprites/characters/tiro_pet_puppy_illustrated/idle_breathe/frame_%02d.png"
const TILT_SECONDS := 9.0 / 7.0
const ANGLES := [0.0,0.0,0.0,-8.43,-19.09,-19.09,-16.50,0.0,0.0]
@export_range(0,8,1) var source_frame := 0:
	set(value):
		source_frame=clampi(value,0,8)
		_sync_texture()
@export_range(-25.0,25.0,0.1) var head_degrees := 0.0:
	set(value):
		head_degrees=value
		if is_instance_valid(_head): _head.rotation=deg_to_rad(value)
		_sync_pose_visibility()
@export var animate_breath := false
var breathing_time := 0.0
var _textures: Array[Texture2D] = []
var _layers: Array[Polygon2D] = []
var _head: Bone2D
var _body: Bone2D
var _neutral: Sprite2D
var _tilt_time := -1.0
var _return_time := -1.0
var _return_from := 0.0
var _return_seconds := 0.18

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for i: int in 9:
		_textures.append(load(SOURCE % i))
	if has_node("Skeleton2D"):
		_body=get_node("Skeleton2D/BodyAnchor")
		_head=get_node("Skeleton2D/BodyAnchor/Head")
		_neutral=get_node("NeutralArtwork")
		for layer_name: String in ["HeadFaceEars","NeckBridge","TorsoAndPaws"]:
			_layers.append(get_node(layer_name))
	else:
		_build()
	_sync_texture()
	head_degrees=head_degrees

func _build() -> void:
	var skeleton:=Skeleton2D.new()
	skeleton.name="Skeleton2D"
	add_child(skeleton)
	skeleton.owner=self
	_body=Bone2D.new()
	_body.name="BodyAnchor"
	_body.set_autocalculate_length_and_angle(false)
	_body.set_length(140)
	skeleton.add_child(_body)
	_body.owner=self
	_body.rest=_body.transform
	_head=Bone2D.new()
	_head.name="Head"
	_head.position=Vector2(369,365)
	_head.set_autocalculate_length_and_angle(false)
	_head.set_length(135)
	_head.set_bone_angle(-PI/2)
	_body.add_child(_head)
	_head.owner=self
	_head.rest=_head.transform
	# Three connected mesh strips partition the same texture. No duplicate
	# painted edges, image redrawing, colour tint or whole-image crossfade.
	for spec: Array in [["HeadFaceEars",0,14],["NeckBridge",14,18],["TorsoAndPaws",18,27]]:
		var mesh:=Polygon2D.new()
		mesh.name=spec[0]
		var points:=PackedVector2Array()
		var head_weights:=PackedFloat32Array()
		var body_weights:=PackedFloat32Array()
		var first_row: int=spec[1]
		var last_row: int=spec[2]
		for row: int in range(first_row,last_row+1):
			var y:=float(row*24)
			var weight:=1.0-smoothstep(338.0,406.0,y)
			for column: int in 25:
				points.append(Vector2(column*32,y))
				head_weights.append(weight)
				body_weights.append(1.0-weight)
		var triangles: Array[PackedInt32Array]=[]
		for row: int in last_row-first_row:
			for column: int in 24:
				var a:=row*25+column
				triangles.append(PackedInt32Array([a,a+1,a+26]))
				triangles.append(PackedInt32Array([a,a+26,a+25]))
		mesh.polygon=points
		mesh.uv=points
		mesh.polygons=triangles
		add_child(mesh)
		mesh.owner=self
		mesh.skeleton=mesh.get_path_to(skeleton)
		mesh.add_bone(skeleton.get_path_to(_body),body_weights)
		mesh.add_bone(skeleton.get_path_to(_head),head_weights)
		_layers.append(mesh)
	# Rest is the original unmodified sprite. This also avoids tiny rasterizer
	# rounding differences between textured triangles and a native sprite quad.
	_neutral=Sprite2D.new()
	_neutral.name="NeutralArtwork"
	_neutral.centered=false
	add_child(_neutral)
	_neutral.owner=self

func _sync_texture() -> void:
	if _textures.size()!=9: return
	for layer: Polygon2D in _layers: layer.texture=_textures[source_frame]
	if is_instance_valid(_neutral): _neutral.texture=_textures[source_frame]

func _sync_pose_visibility() -> void:
	if not is_instance_valid(_neutral): return
	var neutral:=is_zero_approx(head_degrees)
	_neutral.visible=neutral
	for layer: Polygon2D in _layers: layer.visible=not neutral

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	advance(delta)

func advance(delta: float) -> void:
	if animate_breath:
		breathing_time+=delta
		source_frame=posmod(int(floor(breathing_time*6.0+0.000001)),9)
	if _return_time>=0.0:
		_return_time+=delta
		head_degrees=lerpf(_return_from,0.0,smoothstep(0.0,1.0,minf(_return_time/_return_seconds,1.0)))
		if _return_time>=_return_seconds:
			_return_time=-1.0
			head_degrees=0.0
	elif _tilt_time>=0.0:
		_tilt_time+=delta
		if _tilt_time>=TILT_SECONDS:
			_tilt_time=-1.0
			head_degrees=0.0
		else:
			head_degrees=tilt_angle(_tilt_time)

func start_tilt() -> void:
	if _tilt_time>=0.0 or _return_time>=0.0: return
	_tilt_time=0.0
	head_degrees=0.0

func cancel_tilt(seconds: float=0.18) -> void:
	_tilt_time=-1.0
	_return_from=head_degrees
	_return_seconds=maxf(seconds,0.01)
	_return_time=0.0

func sample(time: float,tilt_elapsed: float=-1.0) -> void:
	breathing_time=time
	source_frame=posmod(int(floor(time*6.0+0.000001)),9)
	head_degrees=tilt_angle(tilt_elapsed) if tilt_elapsed>=0.0 and tilt_elapsed<TILT_SECONDS else 0.0

static func tilt_angle(seconds: float) -> float:
	var cursor:=clampf(seconds*7.0,0.0,8.0)
	var low:=int(cursor)
	var high:=mini(low+1,8)
	return lerpf(ANGLES[low],ANGLES[high],smoothstep(0.0,1.0,cursor-low))
