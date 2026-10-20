extends SceneTree
var state: Node
var main: Control
var failures := 0
func _initialize() -> void:
 run.call_deferred()
 create_timer(60).timeout.connect(func() -> void: quit(1))
func frames() -> void:
 for i in 10: await process_frame
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error('Foods UI: '+message)
func click(node: Control) -> void:
 for pressed: bool in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  event.position = root.get_final_transform()*(node.get_global_transform_with_canvas()*(node.size*0.5))
  root.push_input(event)
 await frames()
func shot(id: String) -> void:
 var folder := ProjectSettings.globalize_path('res://').path_join('../../screenshots/tiro09_depois').simplify_path()
 DirAccess.make_dir_recursive_absolute(folder)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(id+'.png'))
func run() -> void:
 var saver = root.get_node('SaveManager')
 root.remove_child(saver)
 saver.free()
 state = root.get_node('GameState')
 state.reset()
 state.progress.seen.intro = true
 state.growth.phase = 'explorer'
 state.inventory.from_dict({'egg_scramble':4,'cheese_bites':4,'corn_crunch':4,'milk_porridge':4,'herb_shampoo':3})
 for id in ['hunger','happiness','energy','hygiene']: state.dog.needs[id]=40.0
 state.dog.updated_at=state.now()
 root.size=Vector2i(360,780)
 Motion.reduced=true
 main=load('res://scenes/main/main.tscn').instantiate()
 root.add_child(main)
 await frames()
 for member in ['_celebration','_welcome','_walk_result']: main.get(member).hide()
 main.set('_modal_queue',[] as Array[Callable])
 var tray: Control=main.find_child('CareTray',true,false)
 var manual: Control=load('res://scripts/ui/game_manual.gd').call('panel')
 check(manual.find_child('Resource_herb_shampoo',true,false)!=null,'xampu aparece no Manual')
 manual.free()
 var help: Dictionary=load('res://scripts/ui/task_help.gd').call('describe','growth_req','shampoo')
 # Aventureiro: próximo crescimento é Mocinho e inclui os banhos.
 check(help.target.get('screen','')=='pet' and help.needs.is_empty(),'Como fazer leva ao banho quando já tem xampu')
 await click(tray.find_child('FoodButton',true,false))
 var menu: Control=main.find_child('FoodMenu',true,false)
 check(menu.visible,'toque abre guia')
 check(tray.item_node('egg_scramble').get_node_or_null('GrowthSeal')!=null,'adequada ganha selo')
 check(tray.item_node('milk_porridge').get_node_or_null('GrowthSeal')==null,'outra fase sem selo')
 check(menu.get_global_rect().position.x>=0 and menu.get_global_rect().end.x<=360,'guia dentro da tela')
 await shot('guia_selos')
 var hints: Array[String]=[]
 root.get_node('Events').toast_requested.connect(func(value: String) -> void: hints.append(value))
 var item: Control=tray.item_node('milk_porridge')
 var point: Vector2=tray.item_center('milk_porridge')
 var down:=InputEventMouseButton.new()
 down.button_index=MOUSE_BUTTON_LEFT
 down.pressed=true
 down.global_position=point
 item.gui_input.emit(down)
 await create_timer(0.75).timeout
 check('Ele prefere outra coisa agora' in hints,'segurar mostra dica')
 var up:=InputEventMouseButton.new()
 up.button_index=MOUSE_BUTTON_LEFT
 up.global_position=point
 item.gui_input.emit(up)
 check(state.inventory.count('milk_porridge')==3,'dica não bloqueia comida')
 tray.close_food_menu()
 await create_timer(3.5).timeout
 await frames()
 var toggle: Button=main.find_child('ShampooToggle',true,false)
 check(toggle.visible and toggle.size.y>=44,'chip disponível com alvo 44')
 await click(toggle)
 check(toggle.button_pressed and tray.use_shampoo,'toque seleciona xampu')
 await shot('banho_xampu')
 var sponge: Control=tray.item_node('sponge')
 point=tray.item_center('sponge')
 for pressed: bool in [true,false]:
  var event:=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  event.global_position=point
  sponge.gui_input.emit(event)
 await frames()
 check(state.inventory.count('herb_shampoo')==2 and state.progress.stat('shampoo_bath')==1,'toque no banho usa uma unidade')
 state.growth.phase='young'
 root.get_node('Events').state_changed.emit()
 tray.open_food_menu()
 await frames()
 check(tray.item_node('milk_porridge').get_node_or_null('GrowthSeal')!=null,'selo atualiza ao mudar fase')
 tray.close_food_menu()
 state.inventory.remove('herb_shampoo',2)
 root.get_node('Events').state_changed.emit()
 check(not toggle.visible,'sem xampu esconde chip')
 print('GROWTH FOODS UI: '+('PASS' if failures==0 else 'FAIL'))
 main.queue_free()
 await frames()
 quit(0 if failures==0 else 1)
