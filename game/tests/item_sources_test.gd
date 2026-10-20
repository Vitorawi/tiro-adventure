extends SceneTree
var failures := 0
func _initialize() -> void:
 run.call_deferred()
 create_timer(45).timeout.connect(func() -> void: quit(1))
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error("ITEM SOURCES: " + message)
func run() -> void:
 var saver = root.get_node("SaveManager")
 root.remove_child(saver)
 saver.free()
 var state = root.get_node("GameState")
 var db = root.get_node("Database")
 var help = load("res://scripts/ui/task_help.gd")
 state.reset()
 state.inventory.from_dict({})
 var early: Dictionary = help.describe("item", "bolt")
 check("Missão" in str(early.detail) and early.target.get("screen", "") != "bag", "parafuso inicial explica missão")
 # Todos os prêmios únicos esgotados: ainda existe a fonte repetível.
 for id: String in db.quests: state.progress.claimed_quests[id] = true
 for item in ["bolt", "iron_band"]:
  var info: Dictionary = help.describe("item", item)
  check("Vila" in str(info.get("source_text", "")) and "receber" in str(info.get("source_text", "")), "contrato real para " + item)
  check(info.target.get("screen", "") != "bag", "origem sem mochila " + item)
  var panel: Control = help.panel("item", item)
  root.add_child(panel)
  await process_frame
  check(panel.find_child("ItemSource", true, false) != null, "origem no painel " + item)
  panel.queue_free()
 var brush: Dictionary = help.describe("item", "basic_brush")
 check("Dentinhos" in str(brush.get("source_text", "")) and brush.target.has("growth"), "escova é presente da fase")
 var tooth: Dictionary = help.describe("item", "milk_tooth")
 check("montinho" in str(tooth.get("source_text", "")) and tooth.target.has("growth"), "dentinho explica fase e achado")
 for item: String in db.items:
  var info: Dictionary = help.describe("item", item)
  check("Veja na Mochila" not in str(info) and "fonte disponível no catálogo" not in str(info), "item tem origem concreta: " + item)
 # O Ir do produto abre a receita, mesmo com insumos só para parte da meta (ou nenhum).
 state.dev_unlock_everything()
 var destinations: Array[Dictionary] = []
 root.get_node("Events").world_requested.connect(func(world: String, place: String) -> void: destinations.append({"world": world, "place": place}))
 for wood: int in [8, 0]:
  state.inventory.from_dict({"wood": wood})
  for entry: Array in [["item", "plank"], ["recipe", "plank"], ["produced", "plank"], ["item", "carrot_snack"]]:
   var panel: Control = help.panel(entry[0], entry[1], 4)
   root.add_child(panel)
   await process_frame
   var button: Button = panel.find_child("HelpGo", true, false)
   destinations.clear()
   button.pressed.emit()
   check(not destinations.is_empty() and str(destinations.back().place).begins_with("recipe:"), "Ir mantém receita de %s com %d madeiras" % [entry[1], wood])
   check(destinations.back().world == ("house" if entry[1] == "carrot_snack" else "farm"), "Ir leva ao mundo da estação")
   check(state.inventory.count("wood") == wood, "consulta não consome ingredientes")
   panel.queue_free()
   await process_frame
 if "--shots" in OS.get_cmdline_user_args():
  state.reset()
  state.progress.seen.intro = true
  var main = load("res://scenes/main/main.tscn").instantiate()
  root.add_child(main)
  for i in 8: await process_frame
  for mode in ["mission", "contract", "plank"]:
   if mode == "contract":
    main.queue_free()
    await process_frame
    state.dev_unlock_everything()
    for id: String in db.quests: state.progress.claimed_quests[id] = true
    main = load("res://scenes/main/main.tscn").instantiate()
    root.add_child(main)
    for i in 8: await process_frame
   state.inventory.from_dict({"wood": 8} if mode == "plank" else {})
   help.open("item", "plank" if mode == "plank" else "bolt", 4 if mode == "plank" else 1)
   for i in 20: await process_frame
   await create_timer(0.4).timeout
   var folder := "res://../build/screenshots/item_sources"
   DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
   root.get_texture().get_image().save_png(folder + "/" + mode + "_" + str(root.size.x) + ".png")
 print("ITEM SOURCES: " + ("PASS" if failures == 0 else "FAIL %d" % failures))
 quit(0 if failures == 0 else 1)
