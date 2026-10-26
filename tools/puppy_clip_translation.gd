extends SceneTree
## Reaplica a translação única de normalize_install.py aos PNGs já instalados.
## Sem Python/Pillow: usa o recibo antigo e preserva exatamente os pixels RGBA.
## Primeiro valida TODOS os limites; só escreve com -- --apply. --verify compara RGBA.
const BASE := "res://assets/sprites/characters/tiro_pet_puppy/"
const AUDIT := "res://../assets/pixellab_character/tiro_bebe/normalization_audit.json"

func _initialize() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string(AUDIT))
	var verify := "--verify" in OS.get_cmdline_user_args()
	var offsets: Dictionary = {}
	var output: Array[Dictionary] = []
	var report: Array[Dictionary] = []
	for record: Dictionary in records:
		var clip := str(record.clip)
		var old := Vector2i(int(record.offset[0]), int(record.offset[1]))
		if not offsets.has(clip): offsets[clip] = old
		var delta: Vector2i = offsets[clip] - old
		var path := BASE + clip + "/" + str(record.frame)
		var original := "res://../assets/pixellab_character/tiro_bebe/normalized/" + clip + "/" + str(record.frame) if verify else path
		if FileAccess.get_sha256(original) != str(record.sha256):
			push_error("PNG diferente do recibo antigo (já corrigido?): " + path)
			quit(1)
			return
		# Image.load lê o PNG original, sem bordas RGB introduzidas pelo importador.
		var image := Image.load_from_file(original)
		var box := image.get_used_rect()
		var moved := Rect2i(box.position + delta, box.size)
		if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(moved):
			push_error("Recorte proibido: " + path + " " + str(moved))
			quit(1)
			return
		var aligned := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
		aligned.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), delta)
		if verify and aligned.get_data() != Image.load_from_file(path).get_data():
			push_error("Pixels diferentes da translação esperada: " + path)
			quit(1)
			return
		output.append({"path": path, "image": aligned, "changed": delta != Vector2i.ZERO})
		report.append({"clip": clip, "frame": record.frame, "previous_offset": [old.x, old.y], "offset": [offsets[clip].x, offsets[clip].y], "delta": [delta.x, delta.y]})
	var apply := "--apply" in OS.get_cmdline_user_args()
	var count := 0
	for entry: Dictionary in output:
		if entry.changed:
			count += 1
			if apply and entry.image.save_png(entry.path) != OK:
				push_error("Falha ao salvar " + entry.path)
				quit(1)
				return
	var file := FileAccess.open("res://../build/screenshots/tiro_samba/translation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("PUPPY TRANSLATION: %d validados, %d alterados; apply=%s; verify=%s; nenhum recorte" % [output.size(), count, apply, verify])
	quit()
