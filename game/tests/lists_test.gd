extends SceneTree
## Contratos das listas, filtros, prêmios e roupas. Perfil isolado; sem SaveManager.

var failures := 0
var state: Node
var main: Control
var db: Node
var events: Node
var gains := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(40.0).timeout.connect(func() -> void:
		push_error("LISTS: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("LISTS: " + message)


func frames() -> void:
	for i in 6: await process_frame


func primary_count(node: Node) -> int:
	var total := 0
	for button: Button in node.find_children("*", "Button", true, false):
		if button.theme_type_variation == &"PrimaryButton": total += 1
	return total


func has_text(node: Node, text: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if text in label.text: return true
	return false


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	state.call("reset")
	state.call("dev_unlock_everything")
	state.get("progress").seen.intro = true
	state.call("_mark_all_seen")
	state.call("dev_restart_routines")
	# Três descrições atuais: não depende da diária sorteada no dia.
	state.call("routine_ids", "daily")
	state.get("progress").routines.daily.ids = ["harvest", "cook", "order"]
	state.get("progress").routines.daily.claimed = {}
	state.get("progress").routines.daily.base = state.get("progress").stats.duplicate()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	Motion.reduced = true
	await frames()
	main.call("show_screen", &"tasks")
	await frames()
	var tasks: Control = main.find_child("TasksScreen", true, false)
	tasks.call("choose_group", "timed")
	await frames()
	var daily: Control = tasks.find_child("Routines_daily", true, false)
	check(daily != null, "seção diária existe")
	if daily:
		print("LISTS: altura diária = ", daily.size.y)
		check(daily.size.y < 300, "três diárias e título ocupam menos de 300 px")
		check(has_text(daily, "Colha os canteiros do sítio."), "instrução inteira preservada")
		check(daily.find_children("*", "RingProgress", true, false).size() == 3, "três anéis de progresso")
	for id: String in state.call("routine_ids", "daily"):
		var goal: Dictionary = state.call("routine_data", "daily", id).goal
		state.get("progress").stats[goal.key] = state.get("progress").stat(goal.key) + int(state.call("routine_target", "daily", id))
	state.call("_changed")
	await frames()
	check(tasks.find_child("ClaimAllRoutines", true, false) != null, "Pegar tudo com várias prontas")
	check(primary_count(tasks) == 1, "um único principal com Pegar tudo")
	state.set("xp", 0)
	var before: int = state.get("coins")
	var reward := 0
	for id: String in state.call("routine_ids", "daily"):
		reward += int(state.call("routine_data", "daily", id).rewards.coins)
	events.items_gained.connect(func(_items: Dictionary, coins: int, _origin: Vector2) -> void: gains += coins)
	var claim: Button = tasks.find_child("ClaimAllRoutines", true, false)
	if claim: claim.pressed.emit()
	await create_timer(0.1).timeout
	await frames()
	check(state.get("coins") == before + reward, "Pegar tudo paga exatamente as três diárias")
	check(gains == reward, "CollectFx recebe as moedas exatas")
	check(tasks.find_child("Routine_daily_harvest", true, false) == null, "linha recebida sai da lista")
	check(tasks.find_child("ClaimAllRoutines", true, false) == null, "ação some após receber")
	var after: int = state.get("coins")
	check(state.call("claim_routine", "daily", "harvest") != "" and state.get("coins") == after, "não duplica prêmio")
	# Mochila: quantidade zero, depósito, categorias, Novo e reabertura.
	state.get("inventory").call("from_dict", {"carrot": 4, "carrot_snack": 3, "dog_food": 3, "wood": 2, "wheat": 0})
	state.get("progress").seen.erase("ui:bag:carrot")
	main.call("show_screen", &"bag")
	await frames()
	var bag: Control = main.find_child("InventoryList", true, false)
	check(bag.find_child("Item_wheat", true, false) == null, "item zerado fora da grade")
	check(not has_text(bag, "×0") and not has_text(bag, "x0"), "mochila sem quantidade zero")
	check(bag.find_child("NewBadge", true, false) != null, "item novo ganha selo")
	check(state.get("progress").seen.has("ui:bag:carrot"), "marca visto pelo GameState")
	check(bag.find_child("Storage_fridge", true, false) != null and has_text(bag, "Geladeira"), "depósito com nome")
	bag.find_child("NotebookTab_crop", true, false).emit_signal("pressed")
	await frames()
	check(bag.find_child("Item_carrot", true, false) != null and bag.find_child("Item_dog_food", true, false) == null, "Colheitas esconde comidas")
	bag.call("choose_storage", "fridge")
	await frames()
	check(bag.find_child("Item_carrot_snack", true, false) != null and bag.find_child("Item_carrot", true, false) == null and bag.find_child("Item_dog_food", true, false) == null, "depósito filtra grade, inclusive a ração sem depósito")
	bag.call("choose_storage", "fridge")
	await frames()
	check(bag.find_child("Item_carrot", true, false) != null, "tocar depósito de novo remove filtro")
	main.call("show_screen", &"pet")
	main.call("show_screen", &"bag")
	await frames()
	check(bag.find_child("NewBadge", true, false) == null, "Novo some na próxima abertura")
	var sb: Script = load("res://scripts/ui/sheet_builder.gd")
	var detail: Control = sb.call("item_detail", "wheat")
	root.add_child(detail)
	await frames()
	check(has_text(detail, "Você não tem") and not has_text(detail, "×0"), "detalhe vazio é legível")
	check(not detail.has_meta("sheet_size"), "detalhe com altura automática")
	detail.queue_free()
	# Roupas: o mesmo nó responde ao toque para vestir e para tirar.
	state.get("progress").collection.red_scarf = true
	state.call("unequip", "neck")
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	var clothes: Control = ui.call("_clothes_panel")
	root.add_child(clothes)
	clothes.size = Vector2(320, 600)
	await frames()
	check(clothes.find_child("ClothesGrid", true, false).columns == 3, "roupas em três colunas")
	clothes.find_child("Equip_red_scarf", true, false).emit_signal("pressed")
	await frames()
	check(state.get("progress").equipped.neck == "red_scarf", "toque veste")
	check(clothes.find_child("Equip_red_scarf", true, false).find_child("EquippedCheck", true, false) != null, "check na vestida")
	clothes.find_child("Equip_red_scarf", true, false).emit_signal("pressed")
	await frames()
	check(state.get("progress").equipped.neck == "", "segundo toque tira")
	for button: Button in clothes.find_children("*", "Button", true, false):
		check(button.text != "Vestir" and button.text != "Tirar", "sem botões repetidos")
	clothes.queue_free()
	# Vários desejos cumpríveis continuam com somente um principal.
	state.call("dev_set_phase", "puppy")
	main.call("show_screen", &"pet")
	state.get("wishes").current = {"id": "meal", "item": "carrot_snack", "period": "x", "progress": 0, "since": 0.0}
	state.get("inventory").call("add", "carrot_snack", 2)
	state.call("_changed")
	await frames()
	var wish_card: Control = load("res://scripts/ui/wish_ui.gd").call("balloon_card")
	main.add_child(wish_card)
	check(primary_count(wish_card) == 1, "Desejo do balão respeita um principal")
	wish_card.queue_free()
	main.queue_free()
	await frames()
	print("LISTS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
