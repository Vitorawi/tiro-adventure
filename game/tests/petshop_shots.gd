extends SceneTree
## Capturas da Etapa 08; rodar sem headless, 360x780 e timeout externo.

const FOLDER := "res://../build/screenshots/etapa08/"
var state: Node
var main: Node
var animator: Node
var ui: Script


func _initialize() -> void:
	_run.call_deferred()


func shot(id: String) -> void:
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")


func pose(clip: String, frame := 0) -> void:
	animator.call("_play", StringName(clip), 1)
	animator.set("_frame", frame)
	animator.call("_show")


func sheet(title: String, content: Control) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.3).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 30)
	state.call("dev_add_coins", 5000)
	state.get("progress").collection.clear()
	state.get("progress").seen["intro"] = true
	state.get("progress").count("walk", 20)
	state.call("_mark_all_seen")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	ui = load("res://scripts/ui/progression_ui.gd")
	await create_timer(0.8).timeout
	main.get_node("Celebration").hide()
	main.get("_modal_queue").clear()
	main.call("show_screen", &"pet")
	animator = main.get_node("%PetScreen").get("_animator")
	animator.set_process(false)
	for id: String in ["red_scarf", "feather_hat", "knit_sweater", "sponge_uniform", "sponge_hat", "glow_collar", "plaid_bow", "flower_clip"]:
		state.get("progress").collection[id] = true
	state.call("equip", "red_scarf")
	pose("idle_breathe")
	await shot("tiro_lenco")
	# Todas as animações com a lógica real de camadas, incluindo as que ocultam a roupa.
	for clip: StringName in animator.get("_frames"):
		var frames: Array = animator.get("_frames")[clip]
		pose(str(clip), frames.size() / 2)
		await shot("anim_" + str(clip))
	pose("idle_breathe")
	await shot("roupa_voltou")
	state.call("equip", "feather_hat")
	state.call("equip", "knit_sweater")
	pose("idle_breathe")
	await shot("tres_roupas")
	state.call("equip", "sponge_hat")
	state.call("equip", "sponge_uniform")
	state.call("equip", "glow_collar")
	pose("idle_breathe")
	await shot("lendarios_juntos")
	pose("sleep", 16)
	await shot("lendarios_dormindo")
	main.call("show_screen", &"pet")
	await shot("desejos_vestido")
	await sheet("Coleção", ui.call("collection_panel"))
	await shot("colecao_topo")
	var scroll := main.get_node("Sheet/%ContentHolder").get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 10000
	await shot("colecao_roupas")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.get("progress").owned.erase("petshop")
	state.get("progress").owned.erase("sewing_table")
	main.call("_on_world_requested", "park", "")
	await create_timer(1.0).timeout
	await shot("praca_antes")
	state.call("buy_upgrade", "petshop")
	state.call("buy_upgrade", "sewing_table")
	await shot("praca_depois")
	await sheet("Pet shop", ui.call("petshop_panel"))
	await shot("petshop_costura")
	state.call("cook", "sew_flower_crown")
	await shot("costurando")
	scroll = main.get_node("Sheet/%ContentHolder").get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 10000
	await shot("petshop_comprar")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.call("dev_finish_timers")
	state.call("collect", "sewing")
	await create_timer(0.8).timeout
	await shot("roupa_costurada")
	main.get_node("WalkResult").hide()
	main.get("_modal_queue").clear()
	var result: Node = main.get_node("WalkResult")
	result.call("show_result", {"id":"park_loop", "name":"Volta na praça", "postcard":state.call("walk_postcard","park_loop"),"rare":"plaid_bow", "items":{"stick":2},"coins":10})
	await shot("raro_vestir")
	(result.find_child("WalkResultScroll", true, false) as ScrollContainer).scroll_vertical = 10000
	await shot("raro_vestir_botao")
	result.call("show_result", {"name":"Volta na praça", "legendary":"sponge_hat", "collections":["sponge_hat"],"items":{"ribbon":2}})
	await shot("lendario_cartao")
	result.hide()
	await sheet("Diário", ui.call("walk_diary"))
	await shot("diario_lendarios")
	print("PETSHOP SHOTS: PASS")
	quit()
