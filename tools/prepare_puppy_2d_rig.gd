extends SceneTree
## Authoring command: bake the generated meshes/bones into an editable scene.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var rig: Node2D=load("res://scripts/ui/puppy_illustrated_rig.gd").new()
	rig.name="PuppyIllustratedRig"
	root.add_child(rig)
	rig.set_process(false)
	await process_frame
	var packed:=PackedScene.new()
	assert(packed.pack(rig)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/art/puppy_2d_rig/puppy_2d_rig.tscn")==OK)
	print("PUPPY 2D RIG: editable scene baked, three skin parts, two bones, original PNG references")
	quit()
