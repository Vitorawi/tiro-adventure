extends SceneTree
## Fotos do Tiro, etapa 02: arte por raridade instalada em res://assets/sprites/ui/album/rarities/ e escolhida
## por `PhotoCard.art_for` (nível 1 Comum, 2 Brilhante, 3 Rara, 4 Holográfica; sem arte revisada, a ilustração
## atual da PRÓPRIA foto). Instalador idempotente, 768×768 com mipmaps.

const ROOT := "res://assets/sprites/ui/album/rarities/"
const KEYS := {1: "common", 2: "shiny", 3: "rare", 4: "holographic"}

var failures := 0
var state: Node
var db: Node
var photo_card: GDScript


func _initialize() -> void:
	_run.call_deferred()
	create_timer(240).timeout.connect(func() -> void:
		print("PHOTO ART TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Arte: " + message)


func _path(tex: Texture2D) -> String:
	return tex.resource_path if tex != null else ""


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	photo_card = load("res://scripts/ui/photo_card.gd")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()

	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	var items: Dictionary = manifest.items
	var complete: Array[String] = []
	var pending: Array[String] = []
	for entry: Dictionary in db.album.photos:
		var id := str(entry.id)
		var have := 0
		for key: String in KEYS.values():
			if items.has(id + "/" + key): have += 1
		if have == 4: complete.append(id)
		elif have == 0: pending.append(id)
	check(not complete.is_empty(), "há fotos completas (%d completas, %d pendentes)" % [complete.size(), pending.size()])

	# 1. Foto completa: 4 texturas diferentes, cada uma do seu caminho
	var base_id: String = complete[0]
	var seen := {}
	for level in [1, 2, 3, 4]:
		var expected := "%s%s/%s.png" % [ROOT, base_id, KEYS[level]]
		var tex: Texture2D = photo_card.art_for(base_id, level)
		check(_path(tex) == expected, "%s nível %d usa %s (veio %s)" % [base_id, level, expected, _path(tex)])
		seen[_path(tex)] = true
	check(seen.size() == 4, "quatro texturas diferentes")

	# 2. Foto pendente: os 4 níveis (e o fechado) caem na ilustração da própria foto
	var plain_id: String = pending[0] if not pending.is_empty() else ""
	var own := str(db.photo(plain_id).photo.get("illustration", "")) if plain_id != "" else ""
	for level in ([0, 1, 2, 3, 4] if plain_id != "" else []):
		var tex: Texture2D = photo_card.art_for(plain_id, level)
		check(own == "" or _path(tex) == own, "%s nível %d usa a ilustração própria" % [plain_id, level])
	check(photo_card.art_for(base_id, 0) != null and _path(photo_card.art_for(base_id, 0)).contains("/illustrated/"), "carta fechada usa a ilustração base")
	check(_path(photo_card.art_for(base_id, 9)).contains("/illustrated/"), "nível inexistente cai na ilustração base")

	# 3. Nunca o caminho de outra foto (54 × 4)
	for entry: Dictionary in db.album.photos:
		var id := str(entry.id)
		for level in [1, 2, 3, 4]:
			var path := _path(photo_card.art_for(id, level))
			if path == "": continue
			check(path.contains("/" + id + "/") or path.ends_with("/" + id + ".png"), "%s nível %d aponta para outra foto: %s" % [id, level, path])

	# 4. Trocar a versão mostrada muda a textura do PhotoCard (e `options.level` manda)
	state._take_photo(base_id)
	state.album.photos[base_id]["sealed"] = 0
	state.album.photos[base_id]["rarity"] = 3
	state.album.photos[base_id]["variants"] = [1, 3]
	state.album.photos[base_id]["shown"] = 0
	state.album.photos[base_id]["opened_at"] = 1.0
	var best: Control = photo_card.make(base_id, 120.0)
	root.add_child(best)
	var pic := best.find_child("Illustration", true, false) as TextureRect
	check(pic != null and _path(pic.texture) == ROOT + base_id + "/rare.png", "mostra a melhor (Rara) por padrão")
	check(pic != null and pic.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "ilustração suave")
	best.free()
	check(state.set_photo_variant(base_id, 1) == "", "escolhe a Comum")
	var common: Control = photo_card.make(base_id, 120.0)
	root.add_child(common)
	pic = common.find_child("Illustration", true, false) as TextureRect
	check(pic != null and _path(pic.texture) == ROOT + base_id + "/common.png", "PhotoCard muda para a Comum")
	common.free()
	var forced: Control = photo_card.make(base_id, 120.0, {"level": 4})
	root.add_child(forced)
	pic = forced.find_child("Illustration", true, false) as TextureRect
	check(pic != null and _path(pic.texture) == ROOT + base_id + "/holographic.png", "options.level manda")
	forced.free()
	var locked: Control = photo_card.make(base_id, 120.0, {"locked": true, "level": 4})
	check(locked.find_child("Illustration", true, false) == null, "bloqueada não revela arte")
	locked.free()
	var other: Control = photo_card.make(plain_id if plain_id != "" else base_id, 120.0, {"locked": false, "level": 4})
	root.add_child(other)
	if own != "":
		pic = other.find_child("Illustration", true, false) as TextureRect
		check(pic != null and _path(pic.texture) == own, "pendente mostra a própria ilustração")
	other.free()

	# 5. Duas execuções num catálogo congelado e destino isolado: nunca instalar lotes em produção pelo teste.
	var exe := OS.get_executable_path()
	var fixture := ProjectSettings.globalize_path("res://../build/photo_art_fixture/%s/" % str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(fixture)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../tools/art/album_rarities/catalog.json"))
	var photos: Array = []
	for photo: Dictionary in catalog.photos:
		if str(photo.id) == base_id:
			photos.append(photo.duplicate(true))
	var frozen := FileAccess.open(fixture + "catalog.json", FileAccess.WRITE)
	frozen.store_string(JSON.stringify({"photos": photos}))
	frozen.close()
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "../tools/album_rarity_install.gd", "--", "--catalog=" + fixture + "catalog.json", "--target=" + fixture + "installed/"])
	var out: Array = []
	var code := OS.execute(exe, args, out, true)
	var first_text := "\n".join(out.map(func(v: Variant) -> String: return str(v)))
	check(code == 0 and first_text.contains("instalados 4,"), "instalador copia as quatro variantes na primeira execução")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture + "installed/manifest.json"))
	for tag: String in saved.items:
		var image := Image.load_from_file(fixture + "installed/" + tag + ".png")
		check(image != null and image.get_size() == Vector2i(768, 768), "fixture instalada em 768×768: " + tag)
	out.clear()
	code = OS.execute(exe, args, out, true)
	var text := "\n".join(out.map(func(v: Variant) -> String: return str(v)))
	check(code == 0 and text.contains("instalados 0,") and text.contains("removidos 0"), "instalador idempotente: " + text.right(200))

	# 6. 768×768 com mipmaps; manifesto coerente
	var total := 0
	for tag: String in items:
		total += 1
		var target := "%s%s.png" % [ROOT, tag]
		var tex := load(target) as Texture2D
		check(tex != null and tex.get_width() == LOADED and tex.get_height() == LOADED, "%s %d×%d na memória (limite de importação)" % [tag, LOADED, LOADED])
		var import_text := FileAccess.get_file_as_string(target + ".import")
		check(import_text.contains("mipmaps/generate=true"), "%s com mipmaps" % tag)
		check(import_text.contains("process/size_limit=%d" % LOADED), "%s limite de importação %d" % [tag, LOADED])
		check(int(items[tag].size) == SIZE and str(items[tag].sha256).length() == 64, "%s manifesto" % tag)
	check(total >= 4 * complete.size(), "manifesto cobre as fotos completas (%d)" % total)

	print("PHOTO ART TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


const SIZE := 768
## Tamanho carregado: o importador limita a 512 para poupar memória no celular.
const LOADED := 512
