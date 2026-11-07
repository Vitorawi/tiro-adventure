extends SceneTree
## Reconstitui os 54 originais para o controle de arte, sem instalar ilustrações nem gravar progresso.
## Rodar com TIRO_TEST_TAG=album_art_originals, --resolution 528x528 -s res://tests/album_art_originals.gd.

func _initialize() -> void:
	_run.call_deferred()
	create_timer(180).timeout.connect(func() -> void: quit(1))


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	var database := root.get_node("Database")
	state.call("reset")
	var control: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/art/album_ilustrado/manifest.json"))
	var folder := ProjectSettings.globalize_path("res://../docs/art/album_ilustrado/originais/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.content_scale_size = Vector2i(528, 528)
	root.size = Vector2i(528, 528)
	var backdrop := ColorRect.new()
	backdrop.color = Color("fff6e3")
	backdrop.size = Vector2(528, 528)
	root.add_child(backdrop)
	var theme_holder := Control.new()
	theme_holder.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(theme_holder)
	for entry: Dictionary in control.photos:
		var photo_id := str(entry.id)
		state.get("growth").phase = str(entry.phase)
		state.call("dev_take_photo", photo_id)
		var definition: Dictionary = database.call("photo", photo_id)
		var illustration: Variant = definition.photo.get("illustration")
		definition.photo.erase("illustration")
		var info: Dictionary = state.call("photo_info", photo_id)
		var outfit := {"f_outfit": "red_scarf", "s_soap_explorer": "explorer_hat", "p_crown": "flower_crown", "p_sweater": "knit_sweater", "d_first_cold": "knit_sweater"}
		if outfit.has(photo_id):
			var collection: Dictionary = database.get("collections")[outfit[photo_id]]
			info.equipped = {str(collection.slot): str(outfit[photo_id])}
		var card: Control = load("res://scripts/ui/photo_card.gd").call("make", photo_id, 528.0, {"caption": true})
		theme_holder.add_child(card)
		await process_frame
		await RenderingServer.frame_post_draw
		var code := root.get_texture().get_image().save_png(folder + photo_id + ".png")
		if code != OK:
			push_error("Falha na captura original: " + photo_id)
			quit(1)
			return
		card.free()
		if illustration != null: definition.photo.illustration = illustration
		print("ORIGINAL ", photo_id)
	print("ALBUM ORIGINALS: 54/54")
	quit()
