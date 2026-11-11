extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var rig: Node2D=load("res://scripts/ui/puppy_illustrated_paw.gd").new()
	rig.name="PuppyIllustratedPaw"
	root.add_child(rig)
	rig.set_process(false)
	await process_frame
	var scene:=PackedScene.new()
	assert(scene.pack(rig)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/art/puppy_2d_rig/puppy_2d_paw.tscn")==OK)
	print("PUPPY 2D PAW: editable foreleg scene saved")
	quit()
