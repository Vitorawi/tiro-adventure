extends SceneTree
## Etapa 06: cinco grupos do contrato e rolagem independente por seção.
var failures := 0
var state: Node
var db: Node
var view: GDScript
var codex: GDScript
var viewer_script: GDScript
var host: Control

func _initialize() -> void:
	_run.call_deferred()
	create_timer(100).timeout.connect(func() -> void: print("ALBUM BOOK TEST: TIMEOUT"); quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Livro: " + message)

func frames() -> void:
	for i in 5: await process_frame

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	view = load("res://scripts/ui/album_view.gd")
	codex = load("res://scripts/ui/codex_ui.gd")
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_unlock_everything()
	state.dev_reset_album()
	state.album.tutorial.done = true
	state.dev_take_photo("h_arrival", 3)
	state.dev_take_photo("h_arrival", 1)
	state.set_photo_variant("h_arrival", 1)
	state.dev_seal_photo("h_first_night")
	host = Control.new()
	host.name = "Main"
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: Control = view.call("panel", "story")
	host.add_child(panel)
	await frames()
	# 1. Duas colunas; nível escolhido, não o melhor; seção inteira, sem SubViewports.
	var grid := panel.find_child("AlbumGrid", true, false) as GridContainer
	check(grid != null and grid.columns == 2 and grid.get_child_count() == 14, "duas colunas com 14 fotos da História")
	var arrival := panel.find_child("AlbumCard_h_arrival", true, false) as Button
	check(arrival.get_meta("level") == 1 and arrival.find_child("CardFrame", true, false).get_meta("level") == 1, "moldura da versão mostrada")
	check(panel.find_child("CardStage", true, false) == null, "grade não cria SubViewport")
	check(arrival.find_child("NewBadge", true, false) != null, "Novo permanece até ver a foto")
	check(arrival.size.x > 100 and arrival.size.y > arrival.size.x, "carta ocupa meia largura útil, sem quadradinho externo")
	# 2. Fotos/versões/níveis contados pelo estado, incluindo fechadas sem nível.
	var stats: Dictionary = panel.find_child("AlbumSummary", true, false).get_meta("counts")
	check(stats.taken == 2 and stats.total == 14 and stats.versions == 2 and stats.possible == 56, "resumo fotos e versões")
	check(stats.levels[1] == 1 and stats.levels[3] == 1 and stats.levels[2] == 0 and stats.levels[4] == 0, "contagens das quatro versões")
	# 3. Construir a faixa não consome; tocar abre o verso no visualizador.
	check(panel.find_child("AlbumSealed", true, false) != null, "faixa Para abrir")
	check(state.photo_sealed("h_first_night") == 1, "montar o livro não abre cartas")
	(panel.find_child("AlbumOpenSealed", true, false) as Button).pressed.emit()
	await frames()
	var viewer: Control = viewer_script.get("current")
	check(viewer != null and viewer.get("photo_id") == "h_first_night" and viewer.get("showing_back"), "faixa abre revelação da primeira fechada")
	check(state.photo_sealed("h_first_night") == 1, "só Abrir pode consumir")
	viewer.call("close")
	await frames()
	# 4. Prévia cinza de baixa resolução + pista; segredo sem pista só verso.
	var missing := panel.find_child("AlbumCard_h_kitchen", true, false)
	var picture := missing.find_child("MissingIllustration", true, false) as TextureRect
	check(picture != null and missing.find_child("MissingLock", true, false) != null, "faltante com base apagada e cadeado")
	if picture != null:
		var image := picture.texture.get_image()
		var pixel := image.get_pixel(12, 12)
		check(image.get_width() == 24 and absf(pixel.r - pixel.g) < 0.005 and absf(pixel.b - pixel.g) < 0.005 and pixel.r <= 0.49, "prévia desfocada, cinza e escura")
	var secret: Control = view.call("book_card", "s_foam_ghost", 120)
	check(secret.find_child("CardBack", true, false) != null and secret.find_child("MissingIllustration", true, false) == null, "segredo sem pista não carrega ilustração")
	check((secret.find_child("AlbumCaption", true, false) as Label).text.begins_with("???"), "segredo mantém título oculto e pista poética")
	secret.free()
	state.album.hints["s_foam_ghost"] = 1
	secret = view.call("book_card", "s_foam_ghost", 120)
	check(secret.find_child("MissingIllustration", true, false) != null, "pista revelada permite prévia escura")
	secret.free()
	# 5. Toque na carta aberta encaminha o id certo e marca vista.
	arrival.pressed.emit()
	await frames()
	viewer = viewer_script.get("current")
	check(viewer != null and viewer.get("photo_id") == "h_arrival" and not viewer.get("showing_back"), "toque abre CardViewer da foto")
	check(state.photo_info("h_arrival").seen, "abrir confirma Novo")
	viewer.call("close")
	await frames()
	# Rolagem: trocar filtro e reconstruir preserva cada seção separadamente.
	var scroll := panel.find_child("CodexScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 180
	await frames()
	var old := scroll.scroll_vertical
	check(old > 0, "seção rola")
	panel.free()
	panel = view.call("panel", "firsts")
	host.add_child(panel)
	await frames()
	check((panel.find_child("CodexScroll", true, false) as ScrollContainer).scroll_vertical == 0, "outra seção começa no topo")
	panel.free()
	panel = view.call("panel", "story")
	host.add_child(panel)
	await frames()
	check((panel.find_child("CodexScroll", true, false) as ScrollContainer).scroll_vertical == old, "voltar restaura seção anterior")
	# Quase lá: fixture privada; não acrescenta goal_hint nem altera regras reais.
	var entry: Dictionary = db.photo("d_bloblo_20")
	if entry.is_empty():
		for candidate: Dictionary in db.album.photos:
			if candidate.get("when", {}).get("stat_min", {}).has("customer_orders:bloblo"):
				entry = candidate
	check(not entry.is_empty(), "fixture por contador existente")
	if not entry.is_empty():
		var saved := entry.duplicate(true)
		entry.hint = "Faça encomendas para o Bloblo."
		state.progress.stats["customer_orders:bloblo"] = 18
		# O contador real das encomendas é uma consulta do canal contracts.
		state.progress.stats["order:snacks"] = 18
		var near: Array = view.call("near_entries", str(entry.section))
		check(near.size() > 0 and near.size() <= 3 and near[0].id == entry.id and near[0].have == 18 and near[0].need == 20, "Quase lá usa contador real e limita a três")
		var near_book: Control = view.call("book", str(entry.section), 240)
		check(near_book.find_child("AlbumNear", true, false) != null and near_book.find_child("AlbumNearGo_" + str(entry.id), true, false) != null, "Quase lá oferece Ir")
		near_book.free()
		entry.clear()
		entry.merge(saved)
	panel.free()
	print("ALBUM BOOK TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
