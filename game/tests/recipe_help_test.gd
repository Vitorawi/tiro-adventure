extends SceneTree
## Ingredientes diretos separados dos bloqueios; navegação até a origem sem save pessoal.
var failures: int = 0
var help: Script
var shots: bool = "--screenshots" in OS.get_cmdline_user_args()
const GREENHOUSE := "res://assets/sprites/areas/farm/greenhouse.png"

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("RECIPE HELP: " + message)

func settle() -> void:
	for i: int in 12: await process_frame

func chips(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button and node.theme_type_variation == &"ChipButton": result.append(node)
	for child: Node in node.get_children(): result.append_array(chips(child))
	return result

func shot(id: String) -> void:
	if not shots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/recipe_help")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(id + ".png")) == OK, "captura " + id)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	var db: Node = root.get_node("Database")
	help = load("res://scripts/ui/task_help.gd")
	state.reset()
	# Catálogo inteiro, com mundos/receitas bloqueados e estações presentes (inclui Costura).
	for station: String in db.stations: state.progress.owned[db.station_upgrade(station)] = true
	for id: String in db.recipes:
		var data: Dictionary = help.describe("recipe", id, 5)
		var expected: Dictionary = state.recipe_inputs(id)
		check(data.ingredients.size() == expected.size(), id + ": só ingredientes diretos")
		for ingredient: Dictionary in data.ingredients:
			check(ingredient.kind == "item" and expected.has(ingredient.id), id + ": nenhum bloqueio nos ingredientes")
			check(ingredient.amount == int(expected[ingredient.id]) * int(data.batches), id + ": quantidade por lote")
	state.reset()
	state.progress.owned.blender = true
	state.progress.owned.farm = true
	state.progress.claimed_quests["growth_1_puppy"] = true
	state.progress.seen.intro = true
	state._mark_all_seen()
	var shampoo: Dictionary = help.describe("item", "herb_shampoo")
	check(shampoo.ingredients.size() == 2 and shampoo.ingredients[0].id == "herbs" and shampoo.ingredients[0].amount == 2 and shampoo.ingredients[1].id == "milk" and shampoo.ingredients[1].amount == 1, "Xampu: ervas 2 e leite 1")
	var herbs: Dictionary = help.describe("item", "herbs", 2)
	var greenhouse_found := false
	for need: Dictionary in herbs.needs:
		if need.kind == "upgrade" and need.id == "greenhouse":
			greenhouse_found = true
			check(help.need_icon(need).resource_path == GREENHOUSE, "Estufa usa o asset existente")
	check(greenhouse_found, "Ervas explicam o requisito da Estufa")
	Motion.reduced = true
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		help.open("item", "herb_shampoo")
		await settle()
		var holder: Node = main.find_child("ContentHolder", true, false)
		var ingredients := chips(holder)
		check(ingredients.size() == 2, "painel renderizado só tem dois chips")
		check(ingredients[0].icon == db.item_icon("herbs") and ingredients[1].icon == db.item_icon("milk"), "ícones dos ingredientes renderizados")
		await shot("shampoo_%d" % viewport.x)
		ingredients[0].pressed.emit()
		await settle()
		var required := chips(holder)
		check(required.size() == 1 and required[0].icon.resource_path == GREENHOUSE, "tocar nas Ervas abre a Estufa com ícone correto")
		await shot("herbs_%d" % viewport.x)
		var back: Button = holder.find_children("*", "Button", true, false)[0]
		back.pressed.emit()
		await settle()
		check(chips(holder).size() == 2, "voltar restaura os dois ingredientes")
	main.queue_free()
	await process_frame
	print("RECIPE HELP TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
