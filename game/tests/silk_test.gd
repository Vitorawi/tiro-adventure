extends SceneTree
## Pelagem de seda (etapa 17): só no adulto, requisitos, brilho por nível, presente único e recarga.
var failures := 0
var state: Node
var db: Node

func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SILK: " + message)

func _prepare(days: int, baths: int, coat_moments: int = 10) -> void:
	state.growth.phase = "adult"
	state.growth.moments["coat"] = coat_moments
	state.growth.brush_days.clear()
	for day in days:
		state.growth.brush_days["2026-11-%02d" % (day + 1)] = true
	state.progress.stats["shampoo_bath"] = baths

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.reset()
	check(db.growth.silk.levels.size() == 3, "três níveis nos dados")
	# Só no adulto
	for phase: Dictionary in db.growth.phases:
		state.growth.phase = phase.id
		state.growth.moments["coat"] = 10
		check((state.silk_error() == "Só depois de adulto") == (phase.id != "adult"), "seda só no adulto: " + str(phase.id))
		check(is_equal_approx(state.dog_look().sheen, 0.0), "sem brilho antes da seda")
	check(state.silk_info().adult == false or state.growth.phase == "adult", "consulta fora do adulto")
	state.growth.phase = "explorer"
	check(state.brighten() == "Só depois de adulto", "recusa fora do adulto")
	# Requisitos
	_prepare(5, 3, 0)
	check(state.silk_error() != "", "Pelagem baixa bloqueia")
	_prepare(4, 3)
	check(state.silk_error().contains("dias diferentes"), "faltam dias: " + state.silk_error())
	_prepare(5, 2)
	check(state.silk_error().contains("xampu"), "faltam banhos com xampu: " + state.silk_error())
	_prepare(5, 3)
	check(state.silk_error() == "" and state.silk_info().ready, "nível I pronto")
	# Mesma escovação no mesmo dia não conta duas vezes: o conjunto de dias é por data
	state.growth.brush_days.clear()
	for i in 6: state.growth.brush_days["2026-11-01"] = true
	check(state.silk_info().requirements[1].have == 1, "dias iguais contam uma vez")
	_prepare(5, 3)
	# Nível I
	var coins: int = state.coins
	var seen: Array[int] = []
	var hook := func(level: int) -> void: seen.append(level)
	root.get_node("Events").silk_up.connect(hook)
	check(state.brighten() == "", "sobe ao nível I")
	check(state.growth.silk == 1 and is_equal_approx(state.dog_look().sheen, 0.33), "sheen 0,33")
	check(state.coins == coins + 50, "presente 50 moedas")
	check(state.brighten() != "", "II ainda não")
	check(seen == [1], "evento uma vez")
	# Nível II e III
	_prepare(10, 6)
	check(state.brighten() == "" and is_equal_approx(state.dog_look().sheen, 0.66) and state.coins == coins + 130, "nível II: 0,66 e +80")
	_prepare(20, 10)
	check(state.brighten() == "" and is_equal_approx(state.dog_look().sheen, 1.0) and state.coins == coins + 250, "nível III: 1,0 e +120")
	check(state.brighten() == "A pelagem já está de seda", "nada além do III")
	# Presente só uma vez e recarga mantém o nível
	state.growth.silk = 2
	var again: int = state.coins
	state.growth.silk = 1
	_prepare(10, 6)
	state.brighten()
	check(state.coins == again, "presente não se repete")
	var data: Dictionary = state.to_dict()
	state.from_dict(data)
	check(state.growth.silk == 2 and is_equal_approx(state.dog_look().sheen, 0.66), "recarregar mantém o nível")
	# Painel do adulto
	state.growth.phase = "adult"
	state.growth.silk = 0
	_prepare(5, 3)
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	var panel: Control = growth_ui.panel()
	root.add_child(panel)
	await process_frame
	check(panel.find_child("SilkButton", true, false) != null and panel.find_child("GrowButton", true, false) == null, "botão Mais brilho!")
	check(panel.find_child("SilkSilhouette", true, false) != null and panel.find_child("SilkReq_shampoo", true, false) != null, "silhueta e requisitos")
	check(panel.find_child("SilkRequirements", true, false).columns == 3, "seda na mesma grade de três colunas")
	var preview: Control = panel.find_child("SilkSilhouette", true, false)
	var preview_material: ShaderMaterial = preview.get_child(0).material
	check(preview_material.shader.resource_path.ends_with("tiro_coat.gdshader") and is_equal_approx(float(preview_material.get_shader_parameter("sheen")), float(state.silk_info().next.sheen)), "prévia usa o brilho do próximo nível")
	check(is_equal_approx(state.silk_sheen(), 0.0), "prévia não aplica seda no estado")
	for req: Dictionary in state.silk_info().requirements:
		var tile: Control = panel.find_child("SilkReq_" + str(req.id), true, false)
		var rings: Array[Node] = tile.find_children("*", "RingProgress", true, false)
		check(rings.size() == 1 and rings[0].get_child_count() == 1 and rings[0].get_child(0).texture != null, "requisito com anel e ícone: " + str(req.id))
	panel.queue_free()
	await process_frame
	_prepare(1, 0)
	panel = growth_ui.panel()
	root.add_child(panel)
	await process_frame
	check(panel.find_child("SilkLock", true, false) != null and panel.find_child("SilkButton", true, false) == null, "cadeado com o que falta")
	check(panel.find_child("SilkLock", true, false).find_children("*", "TextureRect", true, false).size() >= 2, "bloqueio com cadeado e ícone do requisito")
	panel.queue_free()
	await process_frame
	# Shader: brilho passa para o material e respeita Menos animação
	var look: Script = load("res://scripts/ui/dog_look.gd")
	state.growth.silk = 3
	var material: ShaderMaterial = look.material()
	check(is_equal_approx(float(material.get_shader_parameter("sheen")), 1.0), "material recebe sheen")
	print("SILK TEST: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
