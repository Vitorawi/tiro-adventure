extends SceneTree
## Medida (não é teste): quantas telas por cima do jogo aparecem na primeira semana, passo a passo.
## Joga a rota da semana (`helpers/week_story_route.gd`) só pelo estado e imita as decisões do `main.gd`.
## Regra de 26/11/2026: tela grande só para marco (crescer, fim de capítulo, achados/truques/marcos); o resto é AVISO
## leve (Passo concluído ✓, Dia completo!, Nova foto!, nível de cozinheiro), "Novo!" é UMA folha por quadro, o capítulo
## que termina junto com um crescimento fica só com a cerimônia e o Boa noite só abre cartão no dia da chegada.
## Antes da regra: 65 telas grandes (build/journey_screens_antes.txt).
## Uso: godot --headless --path game -s res://tests/journey_screens.gd  → build/journey_screens.txt

var state: Node
var db: Node
var log: Array[String] = []
var counts := {}
var notices := {}
var pending_quests: Array[String] = []
var pending_chapter := 0
var pending_grew := ""
var last_action := ""
var current := "início"
var places: Script
var toasts := {}
var toast_total := 0
## Contagem por TIPO de aviso (regra dos quatro tipos): no lugar / balão do Tiro / aviso embaixo / conquista.
var types := {"no lugar (sem texto)": 0, "balão do Tiro": 0, "aviso embaixo (texto)": 0, "conquista (dourada)": 0}
const PLACE_LABELS := ["nova foto", "nova foto (repetida)", "passo concluído ✓", "dia completo", "boa noite (silenciosa)"]


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("JOURNEY · " + message)


func _add(kind: String, detail: String) -> void:
	counts[kind] = int(counts.get(kind, 0)) + 1
	log.append("[%s] TELA %s · %s" % [current, kind, detail])


func _type(name: String) -> void:
	types[name] = int(types[name]) + 1


func _notice(kind: String, detail: String) -> void:
	notices[kind] = int(notices.get(kind, 0)) + 1
	_type("conquista (dourada)" if kind == "cozinheiro" else "no lugar (sem texto)")
	log.append("[%s] aviso %s · %s" % [current, kind, detail])


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	places = load("res://scripts/ui/places.gd")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	var events := root.get_node("Events")
	events.quest_completed.connect(func(id: String) -> void: pending_quests.append(id))
	events.chapter_completed.connect(func(index: int) -> void: pending_chapter = index)
	events.grew.connect(func(phase: String) -> void: pending_grew = phase)
	events.photo_taken.connect(func(id: String) -> void:
		if (state.photo_alerts_enabled() or state.progress.claimed_quests.has("lais_photo")) and id != "h_arrival": _notice("nova foto", id))
	events.photo_sealed.connect(func(id: String) -> void:
		if state.photo_alerts_enabled(): _notice("nova foto (repetida)", id))
	events.paw_earned.connect(func(day: int) -> void: _notice("dia completo", "dia %d" % day))
	events.find_discovered.connect(func(result: Dictionary) -> void: _add("achado", str(result.get("id", result.get("item", "")))))
	events.trick_learned.connect(func(id: String) -> void:
		if not state.trick_is_lesson(id): _add("truque", id))
	events.chef_level_up.connect(func(level: int) -> void: _notice("cozinheiro", str(level)))
	events.album_milestone.connect(func(kind: String, key: String) -> void: _add("álbum marco", kind + ":" + key))
	events.recipe_piece_found.connect(func(id: String, count: int) -> void:
		if state.recipe_book_open() and count >= 3: _add("receita completa", id))
	events.cosmetic_received.connect(func(id: String) -> void: _add("roupa", id))
	# Avisos pedidos pelo jogo (toast, notice, momento), contados pelo texto com números trocados por N.
	events.toast_requested.connect(func(text: String) -> void: _toast("toast", text))
	events.notice_requested.connect(func(kind: String, text: String, _item: String) -> void: _toast(kind, text))
	events.moment_gained.connect(func(pillar: String, _source: String) -> void:
		_type("no lugar (sem texto)")
		_toast("momento (ícone voa ao avatar)", "Momento de " + pillar))
	events.tiro_said.connect(func(text: String) -> void:
		_type("balão do Tiro")
		_toast("balão do Tiro", text))
	var route: RefCounted = load("res://tests/helpers/week_story_route.gd").new(state, db, check)
	route.on_action = func(panel: String, _touches: int) -> void:
		_flush()
		last_action = panel
	for step: String in ["day_one", "day_two", "lake", "day_four", "day_five", "day_six", "day_seven"]:
		current = step
		if step == "lake":
			route.call(step, 3)
		else:
			route.call(step)
		_flush()
	_report()
	quit(0)


## Fim de um "quadro": decide as telas como o `main.gd._announce` faria.
func _flush() -> void:
	var unlocks: Array[String] = []
	unlocks.assign(state.new_unlocks())
	var views: Array[String] = []
	for key: String in unlocks:
		if not (places.call("unlock_view", key) as Dictionary).is_empty():
			views.append(key)
	var steps: Array[String] = []
	var growth_step := false
	for id: String in pending_quests:
		var quest: Dictionary = db.quests[id]
		if not quest.get("claim_sheet", true):
			continue
		var main_id := ""
		if quest.get("kind", "") == "main":
			main_id = id
		else:
			for candidate_id: String in db.quests:
				if db.quests[candidate_id].get("kind", "") == "main" and str(db.quests[candidate_id].get("shared_with", "")) == id:
					main_id = candidate_id
					break
		if main_id == "":
			continue
		steps.append(main_id)
		for goal: Dictionary in db.quests[main_id].get("goals", []):
			if goal.get("type", "") == "growth":
				growth_step = true
	var growth_waits := pending_grew != ""
	var modal := false
	if growth_waits:
		pass
	elif pending_chapter > 0 and not growth_step:
		modal = true
		_add("capítulo completo", "%d (%d novidades dentro)" % [pending_chapter, views.size()])
	elif not views.is_empty():
		modal = true
		_add("Novo! (uma folha)", "%d novidade(s): %s" % [views.size(), ", ".join(views)])
	if not growth_waits and not unlocks.is_empty():
		state.mark_seen(unlocks)
	if not modal and not growth_waits and not steps.is_empty():
		_notice("passo concluído ✓", ", ".join(steps))
	for id: String in pending_quests:
		for item: String in db.quests[id].get("rewards", {}).get("items", {}):
			if db.items.get(item, {}).get("category", "") == "keepsake":
				_add("presente", item)
	pending_quests.clear()
	pending_chapter = 0
	if pending_grew != "":
		_add("cerimônia de crescer", pending_grew)
		var after: Array[String] = []
		after.assign(state.new_unlocks())
		var after_views: Array[String] = []
		for key: String in after:
			if not (places.call("unlock_view", key) as Dictionary).is_empty():
				after_views.append(key)
		if not after_views.is_empty():
			_add("Novo! (uma folha)", "%d depois da cerimônia: %s" % [after_views.size(), ", ".join(after_views)])
		if not after.is_empty():
			state.mark_seen(after)
		pending_grew = ""
	for candidate: Dictionary in state.week_card_candidates():
		var report: Dictionary = state.take_week_card(candidate)
		if report.is_empty():
			continue
		if candidate.kind == "morning":
			_add("Bom dia", "dia %d" % int(candidate.day))
		elif state.is_arrival_day(int(candidate.day)):
			_add("Boa noite", "dia %d (chegada)" % int(candidate.day))
		else:
			_notice("boa noite (silenciosa)", "dia %d" % int(candidate.day))


func _toast(kind: String, text: String) -> void:
	var regex := RegEx.create_from_string("[0-9]+")
	var key := "%s · %s" % [kind, regex.sub(text, "N", true)]
	toasts[key] = int(toasts.get(key, 0)) + 1
	toast_total += 1
	if kind in ["toast", "info", "info_away", "error"]:
		_type("aviso embaixo (texto)")
	elif kind == "gold":
		_type("conquista (dourada)")


func _report() -> void:
	var lines: Array[String] = []
	lines.append("TELAS GRANDES NA PRIMEIRA SEMANA")
	var total := 0
	for kind: String in counts:
		total += int(counts[kind])
	lines.append("Total de telas grandes: %d (antes da regra: 65)" % total)
	var kinds := counts.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool: return int(counts[a]) > int(counts[b]))
	for kind: String in kinds:
		lines.append("  %3d  %s" % [int(counts[kind]), kind])
	var notice_total := 0
	for kind: String in notices:
		notice_total += int(notices[kind])
	lines.append("Avisos leves (Notice, não param o jogo): %d" % notice_total)
	for kind: String in notices:
		lines.append("  %3d  %s" % [int(notices[kind]), kind])
	var formats := {}
	for lesson: Dictionary in db.week_tutorials:
		formats[str(lesson.get("format", "?"))] = int(formats.get(str(lesson.get("format", "?")), 0)) + 1
	lines.append("Lições da semana por formato (fora da conta acima): " + str(formats))
	lines.append("")
	lines.append("AVISOS POR TIPO (antes da regra: ~87 pílulas de texto na semana)")
	var by_type_total := 0
	for name: String in types:
		by_type_total += int(types[name])
		lines.append("  %3d  %s" % [int(types[name]), name])
	lines.append("  Pílulas de texto embaixo agora: %d (info/erro) + %d douradas" % [int(types["aviso embaixo (texto)"]), int(types["conquista (dourada)"])])
	lines.append("")
	lines.append("AVISOS PEDIDOS PELO JOGO (toast/notice/momento): %d" % toast_total)
	var keys := toasts.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(toasts[a]) > int(toasts[b]))
	for key: String in keys:
		lines.append("  %3d  %s" % [int(toasts[key]), key])
	lines.append("")
	lines.append_array(log)
	var path := ProjectSettings.globalize_path("res://../build/journey_screens.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("
".join(lines))
	file.close()
	print("
".join(lines.slice(0, 30)))
