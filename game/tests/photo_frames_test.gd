extends SceneTree
## Fotos do Tiro, etapa 03: moldura, selo e efeito por nível no PhotoCard.
## Níveis 1–2 sem efeito; 3 e 4 com o shader `photo_foil` (level certo); `still`/Menos animação param o efeito;
## molduras em escala uniforme; carta fechada (nível 0), bloqueada e segredo não ganham moldura de nível.

var failures := 0
var state: Node
var card: GDScript


func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void:
		print("PHOTO FRAMES TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Molduras: " + message)


func _foil(node: Control) -> Control:
	return node.find_child("CardFoil", true, false) as Control


func _param(node: Control, name: String) -> Variant:
	var foil := _foil(node)
	if foil == null or not (foil.material is ShaderMaterial):
		return null
	return (foil.material as ShaderMaterial).get_shader_parameter(name)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	card = load("res://scripts/ui/photo_card.gd")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	Motion.reduced = false
	state.dev_take_photo("h_arrival", 1)

	# 1. Níveis 1 e 2 sem efeito; 3 e 4 com o shader no nível certo
	for level in [1, 2, 3, 4]:
		var made: Control = card.make("h_arrival", 150.0, {"level": level})
		root.add_child(made)
		var frame := made.find_child("CardFrame", true, false) as TextureRect
		check(frame != null and int(frame.get_meta("level")) == level, "nível %d tem CardFrame do nível" % level)
		check(frame != null and frame.texture.resource_path.ends_with("frame_%d.png" % level), "nível %d usa frame_%d.png" % [level, level])
		check((made.find_child("CardSeal", true, false) != null) == (level == 2 or level == 3), "selo só nos níveis 2 e 3 (nível %d)" % level)
		if level <= 2:
			check(_foil(made) == null, "nível %d sem efeito" % level)
		else:
			var foil := _foil(made)
			check(foil != null and foil.material is ShaderMaterial, "nível %d tem material" % level)
			check(int(_param(made, "level")) == level, "nível %d: shader com level certo" % level)
			check((foil.material as ShaderMaterial).shader.resource_path.ends_with("photo_foil.gdshader"), "shader photo_foil")
			check(bool(_param(made, "still")) == false, "nível %d anima por padrão" % level)
		var art := made.find_child("Illustration", true, false) as TextureRect
		check(art != null and art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "arte continua suave (nível %d)" % level)
		check(not (art.material is ShaderMaterial), "a arte não recebe shader (nível %d)" % level)
		made.free()
	var off: Control = card.make("h_arrival", 150.0, {"level": 4, "effects": false})
	root.add_child(off)
	check(_foil(off) == null and off.find_child("CardFrame", true, false) != null, "effects=false: moldura sem efeito")
	off.free()
	var tilted: Control = card.make("h_arrival", 150.0, {"level": 4, "tilt": Vector2(-1, 0)})
	root.add_child(tilted)
	check(Vector2(_param(tilted, "tilt")) == Vector2(-1, 0), "tilt repassado ao shader")
	tilted.free()

	# 2. Parado: options.still ou Motion.reduced
	var still: Control = card.make("h_arrival", 150.0, {"level": 3, "still": true})
	root.add_child(still)
	check(bool(_param(still, "still")), "options.still deixa parado")
	still.free()
	Motion.reduced = true
	var calm: Control = card.make("h_arrival", 150.0, {"level": 4})
	root.add_child(calm)
	check(bool(_param(calm, "still")), "Menos animação deixa parado")
	calm.free()
	Motion.reduced = false

	# 3. Moldura em escala uniforme em 90, 150 e 300 px
	for width in [90.0, 150.0, 300.0]:
		var made: Control = card.make("h_arrival", width, {"level": 3})
		root.add_child(made)
		var canvas := made.get_node("Canvas") as Control
		var frame := made.find_child("CardFrame", true, false) as TextureRect
		check(absf(canvas.scale.x - canvas.scale.y) < 0.0001, "canvas uniforme em %d" % int(width))
		check(frame.stretch_mode == TextureRect.STRETCH_SCALE and absf(frame.size.x / frame.size.y - 1.0) < 0.0001, "frame quadrado em %d" % int(width))
		var tex_ratio := float(frame.texture.get_width()) / float(frame.texture.get_height())
		check(absf(tex_ratio - frame.size.x / frame.size.y) < 0.001, "textura e frame com a mesma proporção em %d" % int(width))
		check(absf(made.custom_minimum_size.x - width) < 0.01, "carta com %d de largura" % int(width))
		made.free()

	# 4. Fechada (nível 0), bloqueada e segredo: sem moldura de nível nem efeito
	state.dev_seal_photo("h_arrival")
	state.album.photos["h_arrival"]["rarity"] = 0
	state.album.photos["h_arrival"]["variants"] = []
	state.album.photos["h_arrival"].erase("opened_at")
	check(state.photo_shown_rarity("h_arrival") == 0, "foto fechada tem nível 0")
	var sealed: Control = card.make("h_arrival", 150.0)
	root.add_child(sealed)
	check(sealed.find_child("CardFrame", true, false) == null and _foil(sealed) == null and sealed.find_child("CardSeal", true, false) == null, "fechada: sem moldura de nível, selo nem efeito")
	check((sealed.get_node("Canvas/Frame") as CanvasItem).visible, "fechada mantém a polaroide simples")
	sealed.free()
	var locked: Control = card.make("h_arrival", 150.0, {"locked": true, "level": 4})
	root.add_child(locked)
	check(locked.find_child("CardFrame", true, false) == null and _foil(locked) == null, "bloqueada: sem moldura nem efeito")
	locked.free()
	var secret: Control = card.make("p_pipoca", 150.0, {"secret": true, "level": 4})
	root.add_child(secret)
	check(secret.find_child("CardFrame", true, false) == null and _foil(secret) == null, "segredo ainda não tirado: sem moldura nem efeito")
	secret.free()

	# 5. Selo com nome
	for level in [1, 2, 3, 4]:
		var badge: Control = card.call("rarity_badge", level, 24)
		root.add_child(badge)
		var label := badge.find_child("BadgeName", true, false) as Label
		check(label != null and label.text == ["Comum", "Brilhante", "Rara", "Holográfica"][level - 1], "selo nível %d com o nome" % level)
		check((badge.find_child("BadgeSeal", true, false) != null) == (level >= 2), "selo %d com ícone só de 2 em diante" % level)
		badge.free()

	print("PHOTO FRAMES TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
