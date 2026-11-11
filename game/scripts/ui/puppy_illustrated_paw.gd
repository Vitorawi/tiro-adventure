@tool
extends Node2D
## One new articulated foreleg. Original head/body texture is shared with idle.
## Separate review component; not installed in PetAnimator.
const ENTRY:=0.38
const CORE:=9.0/8.0
const EXIT:=0.42
const DURATION:=ENTRY+CORE+EXIT
const SHOULDER:=Vector2(433,417)
const ELBOW:=Vector2(422,466)
const WRIST:=Vector2(423,514)
const CONTACT:=Vector2(440,350)
const OUTLINE: Array[Vector2]=[
	Vector2(418,430),Vector2(430,426),Vector2(441,431),Vector2(447,444),
	Vector2(448,459),Vector2(440,478),Vector2(445,500),Vector2(451,521),
	Vector2(453,537),Vector2(446,550),Vector2(433,557),Vector2(406,557),
	Vector2(391,550),Vector2(384,536),Vector2(388,520),Vector2(397,502),
	Vector2(397,480),Vector2(393,463),Vector2(402,446),Vector2(411,435)]
var base: Node2D
var repaired: Sprite2D
var paw: Polygon2D
var upper: Bone2D
var lower: Bone2D
var breathing_time:=0.0
var wrist_target:=WRIST
var is_paw_active:=false
var _action_time:=-1.0
var _cancel_time:=-1.0
var _cancel_from:=WRIST
var _cancel_seconds:=0.24

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if has_node("BaseRig"):
		base=get_node("BaseRig")
		repaired=get_node("HiddenBody")
		paw=get_node("ForelegArtwork")
		upper=get_node("PawSkeleton/Shoulder")
		lower=get_node("PawSkeleton/Shoulder/Elbow")
	else:
		_build()
	base.set_process(false)
	sample(0.0)

func _build() -> void:
	base=load("res://scenes/art/puppy_2d_rig/puppy_2d_rig.tscn").instantiate()
	base.name="BaseRig"
	add_child(base)
	base.owner=self
	repaired=Sprite2D.new()
	repaired.name="HiddenBody"
	repaired.centered=false
	var material:=ShaderMaterial.new()
	material.shader=load("res://assets/shaders/puppy_paw_body.gdshader")
	material.set_shader_parameter("repaired_skin",load("res://assets/sprites/characters/tiro_pet_puppy_illustrated/rig/hidden_body.png"))
	material.set_shader_parameter("outline",PackedVector2Array(OUTLINE))
	repaired.material=material
	add_child(repaired)
	repaired.owner=self
	var skeleton:=Skeleton2D.new()
	skeleton.name="PawSkeleton"
	add_child(skeleton)
	skeleton.owner=self
	upper=Bone2D.new()
	upper.name="Shoulder"
	upper.position=SHOULDER
	upper.set_autocalculate_length_and_angle(false)
	upper.set_length(SHOULDER.distance_to(ELBOW))
	upper.set_bone_angle((ELBOW-SHOULDER).angle())
	skeleton.add_child(upper)
	upper.owner=self
	upper.rest=upper.transform
	lower=Bone2D.new()
	lower.name="Elbow"
	lower.position=ELBOW-SHOULDER
	lower.set_autocalculate_length_and_angle(false)
	lower.set_length(ELBOW.distance_to(WRIST))
	lower.set_bone_angle((WRIST-ELBOW).angle())
	upper.add_child(lower)
	lower.owner=self
	lower.rest=lower.transform
	paw=Polygon2D.new()
	paw.name="ForelegArtwork"
	# Insert internal points around the elbow so it bends without scaling bones.
	var boundary:=PackedVector2Array(OUTLINE)
	var points:=boundary.duplicate()
	for x: float in [405.0,420.0,435.0]:
		for y: float in [446.0,462.0,478.0,496.0]:
			var point:=Vector2(x,y)
			if Geometry2D.is_point_in_polygon(point,boundary):points.append(point)
	var indices:=Geometry2D.triangulate_delaunay(points)
	var triangles: Array[PackedInt32Array]=[]
	for i: int in range(0,indices.size(),3):
		var a:=indices[i];var b:=indices[i+1];var c:=indices[i+2]
		if Geometry2D.is_point_in_polygon((points[a]+points[b]+points[c])/3.0,boundary):
			triangles.append(PackedInt32Array([a,b,c]))
	var upper_weights:=PackedFloat32Array()
	var lower_weights:=PackedFloat32Array()
	for point: Vector2 in points:
		var weight:=smoothstep(455.0,480.0,point.y)
		upper_weights.append(1.0-weight)
		lower_weights.append(weight)
	paw.polygon=points
	paw.uv=points
	paw.polygons=triangles
	var cutout:=ShaderMaterial.new()
	cutout.shader=load("res://assets/shaders/puppy_paw_cutout.gdshader")
	cutout.set_shader_parameter("outline",boundary)
	paw.material=cutout
	add_child(paw)
	paw.owner=self
	paw.skeleton=paw.get_path_to(skeleton)
	paw.add_bone(skeleton.get_path_to(upper),upper_weights)
	paw.add_bone(skeleton.get_path_to(lower),lower_weights)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():return
	advance(delta)

func start_paw() -> void:
	if _action_time>=0.0 or _cancel_time>=0.0:return
	_action_time=0.0

func cancel_paw(seconds: float=0.24) -> void:
	_action_time=-1.0
	_cancel_from=wrist_target
	_cancel_time=0.0
	_cancel_seconds=maxf(seconds,0.02)

func advance(delta: float) -> void:
	breathing_time+=delta
	if _cancel_time>=0.0:
		_cancel_time+=delta
		var weight:=smoothstep(0.0,1.0,minf(_cancel_time/_cancel_seconds,1.0))
		_set_pose(breathing_time,_cancel_from.lerp(WRIST,weight),weight<1.0)
		if weight>=1.0:_cancel_time=-1.0
	else:
		if _action_time>=0.0:
			_action_time+=delta
			if _action_time>=DURATION:_action_time=-1.0
		sample(breathing_time,_action_time)

func sample(time: float,elapsed: float=-1.0) -> void:
	var active:=elapsed>0.000001 and elapsed<DURATION-0.000001
	var target:=WRIST
	if active:
		if elapsed<ENTRY:
			var t:=smoothstep(0.0,1.0,elapsed/ENTRY)
			target=WRIST.bezier_interpolate(Vector2(501,488),Vector2(508,389),CONTACT,t)
		elif elapsed<ENTRY+CORE:
			var t:=(elapsed-ENTRY)/CORE
			var envelope:=pow(sin(PI*t),2.0)
			var wave:=sin(TAU*2.0*t)*envelope
			target=CONTACT+Vector2(wave*2.0,wave*7.0)
		else:
			var t:=smoothstep(0.0,1.0,(elapsed-ENTRY-CORE)/EXIT)
			target=CONTACT.bezier_interpolate(Vector2(508,389),Vector2(501,488),WRIST,t)
	_set_pose(time,target,active)

func _set_pose(time: float,target: Vector2,active: bool) -> void:
	breathing_time=time
	base.call("sample",time)
	var texture: Texture2D=base.get_node("NeutralArtwork").texture
	repaired.texture=texture
	paw.texture=texture
	base.visible=not active
	repaired.visible=active
	paw.visible=active
	is_paw_active=active
	wrist_target=target
	if not active:
		upper.rotation=0.0;lower.rotation=0.0
		return
	# Analytic two-bone IK. Lengths stay fixed; elbow bends outward to image right.
	var first:=ELBOW-SHOULDER
	var second:=WRIST-ELBOW
	var delta:=target-SHOULDER
	var distance:=clampf(delta.length(),absf(first.length()-second.length())+.01,first.length()+second.length()-.01)
	var cosine:=(first.length_squared()+distance*distance-second.length_squared())/(2.0*first.length()*distance)
	var upper_angle:=delta.angle()+acos(clampf(cosine,-1.0,1.0))
	var elbow:=SHOULDER+Vector2.from_angle(upper_angle)*first.length()
	var lower_angle:=(target-elbow).angle()
	upper.rotation=upper_angle-first.angle()
	lower.rotation=lower_angle-second.angle()-upper.rotation
