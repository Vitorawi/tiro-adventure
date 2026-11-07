extends SceneTree
## Etapa 07: cinco grupos do contrato, consultas puras e ligação das ações da folha.
var failures := 0
var state: Node
var db: Node
var view: GDScript
var destinations: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: print("PHOTO HINTS TEST: TIMEOUT"); quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Pistas: " + message)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	view = load("res://scripts/ui/album_view.gd")
	var places := load("res://scripts/ui/places.gd")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_unlock_everything()
	state.dev_reset_album()
	state.album.tutorial.done = true
	var events := root.get_node("Events")
	events.sheet_requested.connect(func(_title: String, content: Control) -> void: content.queue_free())
	events.world_requested.connect(func(world: String, place: String) -> void: destinations.append({"world": world, "place": place}))
	events.screen_requested.connect(func(screen: StringName) -> void: destinations.append({"screen": str(screen)}))
	# 1. Catálogo inteiro com texto concreto e ícone existente; consulta não altera estado.
	check(db.album.photos.size() == 54, "54 fotos")
	var before: String = JSON.stringify(state.to_dict())
	for entry: Dictionary in db.album.photos:
		var goal: Dictionary = entry.get("goal_hint", {})
		check(not str(goal.get("text", "")).strip_edges().is_empty(), str(entry.id) + " tem texto")
		check(ResourceLoader.exists("res://assets/sprites/ui/icons/" + str(goal.get("icon", "")) + ".png"), str(entry.id) + " tem ícone válido")
		state.photo_hint(str(entry.id))
	state.near_photos()
	check(JSON.stringify(state.to_dict()) == before, "consultar não consome lupa, carta, moedas nem sorteio")
	check(state.photo_hint("inexistente").is_empty(), "id inválido")
	# 2. Destinos explícitos: catálogo/lugares especiais reconhecidos e Places.go emite o alvo.
	for entry: Dictionary in db.album.photos:
		var go: Dictionary = entry.goal_hint.get("go", {})
		if go.is_empty(): continue
		if go.has("world"):
			check(db.worlds.has(str(go.world)), str(entry.id) + " mundo existe")
			var place := str(go.get("place", ""))
			check(place in ["", "find"] or db.worlds[go.world].places.has(place), str(entry.id) + " lugar resolve")
		elif go.has("screen"):
			check(str(go.screen) in ["pet", "tasks", "bag", "worlds"], str(entry.id) + " aba existe")
		else:
			check(go.get("notebook", "") == "album", str(entry.id) + " caderninho resolve")
		var count := destinations.size()
		places.call("go", go)
		check(destinations.size() > count, str(entry.id) + " Ir emite destino")
	# 3. Contador real do Bloblo usa a mesma consulta de AlbumRules, com teto da meta.
	state.progress.stats["order:snacks"] = 3
	check(state.photo_hint("a_bloblo_helper").have == 3, "contador começa em 3/20")
	state.progress.stats["order:snacks"] = 18
	var hint: Dictionary = state.photo_hint("a_bloblo_helper")
	check(hint.have == 18 and hint.need == 20, "progresso sobe para 18/20")
	state.progress.stats["order:snacks"] = 24
	check(state.photo_hint("a_bloblo_helper").have == 20, "progresso limitado à meta")
	state.progress.stats["order:snacks"] = 18
	check(state.photo_hint("d_month").need == 0 and state.photo_hint("d_full_moon").need == 0, "data e hora sem progresso artificial")
	# 4. Poesia e verso até a lupa; após, texto concreto, destino, ícone e arte escura.
	var id := "s_foam_ghost"
	hint = state.photo_hint(id)
	check(not hint.revealed and hint.text == db.photo(id).hint and hint.go.is_empty() and hint.icon == "", "segredo não vaza instrução/destino/ícone")
	var panel: Control = view.call("photo_hint", id)
	check(panel.name == "PhotoHint" and panel.get_meta("sheet_bare", false), "folha PhotoHint em madeira")
	check(panel.find_child("CardBack", true, false) != null and panel.find_child("PhotoHintGo", true, false) == null, "verso e sem Ir antes da lupa")
	check(panel.find_child("PhotoHintTalk", true, false) != null, "Conversar com hint_npc")
	(panel.find_child("PhotoHintTalk", true, false) as Button).pressed.emit()
	check(destinations.back() == {"world": db.npc_world("lais"), "place": "npc:lais"}, "Conversar leva à Laís pelo fluxo existente")
	var lupas: int = state.album_lupas_left()
	(panel.find_child("HintButton", true, false) as Button).pressed.emit()
	panel.free()
	check(state.album_lupas_left() == lupas - 1, "lupa consome uma vez")
	check(state.reveal_photo_hint(id) == "" and state.album_lupas_left() == lupas - 1, "reabrir não consome outra lupa")
	hint = state.photo_hint(id)
	check(hint.revealed and hint.text == db.photo(id).goal_hint.text and not hint.go.is_empty(), "lupa revela objetivo concreto")
	panel = view.call("photo_hint", id)
	check(panel.find_child("MissingIllustration", true, false) != null and panel.find_child("PhotoHintGo", true, false) != null, "prévia e Ir após lupa")
	(panel.find_child("PhotoHintGo", true, false) as Button).pressed.emit()
	check(destinations.back() == {"screen":"pet"}, "Ir usa o destino dos dados")
	panel.free()
	# Campo secret também participa sem inventar regras diferentes para a lupa.
	var entry: Dictionary = db.photo("f_bath")
	entry.secret = true
	check(not state.photo_hint("f_bath").revealed, "secret explícito fica oculto")
	entry.erase("secret")
	# 5. Fração decrescente, só faltantes ativas e reveladas, limite inclusive zero.
	state.progress.stats["project_gather:village_festival"] = 2
	var near: Array = state.near_photos(54)
	check(near[0].id == "a_bloblo_helper" and near[1].id == "a_gathering", "18/20 antes de 2/3")
	for item: Dictionary in near:
		check(item.id != "s_begging" and item.id != "p_crown", "segredo sem lupa fora de Quase lá")
	check(state.near_photos(1).size() == 1 and state.near_photos(0).is_empty(), "limite respeitado")
	check(near.back().need == 0, "sem contador tem fração zero")
	state.dev_seal_photo("a_bloblo_helper")
	check(state.near_photos(1)[0].id == "a_gathering", "foto obtida fechada não é faltante")
	panel = view.call("photo_hint", "a_gathering")
	check(panel.find_child("PhotoHintProgress", true, false) != null, "barra de progresso no detalhe")
	panel.free()
	print("PHOTO HINTS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
