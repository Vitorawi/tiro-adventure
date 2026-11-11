extends Node2D
## Three reference clips share a fixed support frame and an uninterrupted idle clock.
## Tracks are hand-registered to the nine PixelLab frames relative to the planted foot.
const PAW := preload("res://scenes/art/puppy_2d_rig/puppy_2d_paw.tscn")
const MOTION := preload("res://assets/shaders/puppy_motion.gdshader")
const REST := Vector2(423,514)
const CONTACT := Vector2(425,369)
const LICK := [0., .12, .42, .97, 1., .98, .92, .35, .06]
const DIP := [0., .05, .64, .98, 1., .89, .94, 1., .98]
const CLIPS := [&"idle_breathe", &"lick_paw", &"eat"]
var clip := &"idle_breathe"
var elapsed := 0.
var clock := 0.
# Channels: paw reach, head dip, lick, bowl opacity.
var pose := Vector4.ZERO
var velocity := Vector4.ZERO
var rig
var skin := ShaderMaterial.new()
var frames: Array[Texture2D] = []
var bowl := Sprite2D.new()

func _ready() -> void:
	rig = PAW.instantiate()
	add_child(rig)
	rig.set_process(false)
	rig.base.hide()
	skin.shader = MOTION
	skin.set_shader_parameter("repaired_skin", rig.repaired.material.get_shader_parameter("repaired_skin"))
	skin.set_shader_parameter("outline", PackedVector2Array(rig.OUTLINE))
	rig.repaired.material = skin
	for i in 9:
		frames.append(load(rig.base.SOURCE % i))
	skin.set_shader_parameter("rest_skin",frames[0])
	bowl.texture = preload("res://assets/sprites/areas/house/named_bowl.png")
	bowl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bowl.position = Vector2(409,515)
	bowl.scale = Vector2.ONE * 5.
	add_child(bowl)
	_render()

func play(action: StringName) -> void:
	if action in CLIPS and action != clip:
		clip = action
		elapsed = 0.

func _process(delta: float) -> void:
	advance(delta)

func _track(keys: Array, cursor: float) -> float:
	var i := mini(floori(cursor), keys.size()-1)
	return lerpf(keys[i], keys[mini(i+1,keys.size()-1)], smoothstep(0.,1.,cursor-i))

func _goal() -> Vector4:
	if clip == &"eat":
		var cursor := elapsed * 6.
		if cursor >= 8.:
			cursor = 6. + (1.+cos((cursor-8.)*PI*.5))
		return Vector4(0., _track(DIP,cursor), 0., 1.)
	if clip == &"lick_paw":
		var cursor := minf(elapsed*5.,8.)
		var lift := _track(LICK,cursor)
		var lick := smoothstep(2.7,3.3,cursor)*(1.-smoothstep(5.8,6.7,cursor))
		if elapsed >= 1.85:
			play(&"idle_breathe")
		return Vector4(lift,0.,lick*(.5-.5*cos((cursor-3.)*TAU)),0.)
	return Vector4.ZERO

func advance(delta: float) -> void:
	# Critically damped channels preserve velocity even when a gesture is interrupted.
	var left := maxf(delta,0.)
	while left > .000001:
		var step := minf(left,1./120.)
		left -= step
		elapsed += step
		clock += step
		var goal := _goal()
		var error := pose-goal
		var rate := 22.
		var jump := velocity + rate*error
		var decay := exp(-rate*step)
		pose = goal + (error+jump*step)*decay
		velocity = (velocity-rate*jump*step)*decay
	_render()

func _render() -> void:
	var reach := clampf(pose.x,0.,1.)
	var target := REST.bezier_interpolate(Vector2(495,494),Vector2(500,398),CONTACT,reach)
	rig._set_pose(clock,target,reach>.0001)
	rig.base.hide()
	rig.repaired.show()
	var cursor := fmod(clock*6.,9.)
	skin.set_shader_parameter("next_skin",frames[(floori(cursor)+1)%9])
	skin.set_shader_parameter("phase_mix",smoothstep(0.,1.,fmod(cursor,1.)))
	skin.set_shader_parameter("paw_lift",reach)
	skin.set_shader_parameter("head_offset",Vector2(31.*reach + 17.*pose.y, 38.*reach+153.*pose.y))
	skin.set_shader_parameter("pitch",pose.y)
	skin.set_shader_parameter("mouth",5.*pose.z - 4.*pose.y)
	bowl.modulate.a = clampf(pose.w,0.,1.)


