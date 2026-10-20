extends SceneTree
## Capturas e toque (eventos de mouse reais no viewport) da etapa 10: Mochila "Para o Tiro" e "Dar" no painel.
## Uso: godot --path game --resolution 360x780 -s res://tests/keys_shots.gd   → build/screenshots/tiro10_depois/
var state: Node
var main: Control
var failures := 0
func _initialize() -> void:
 run.call_deferred()
 create_timer(90).timeout.connect(func() -> void: quit(1))
func frames(count: int = 10) -> void:
 for i in count: await process_frame
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error('Keys UI: '+message)
func click(node: Control) -> void:
 for pressed: bool in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  event.position = root.get_final_transform()*(node.get_global_transform_with_canvas()*(node.size*0.5))
  root.push_input(event)
 await frames()
func shot(id: String) -> void:
 var folder := ProjectSettings.globalize_path('res://').path_join('../build/screenshots/tiro10_depois').simplify_path()
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
 state.growth.phase = 'puppy'
 state.progress.stats['feed:frozen_carrot'] = 3
 for id in ['body','brave']: state.growth.points[id] = 25
 state.inventory.from_dict({'chew_ring':1,'stick_chew':1,'soft_brush':1,'courage_medal':1,'carrot':3})
 root.size=Vector2i(360,780)
 main=load('res://scenes/main/main.tscn').instantiate()
 root.add_child(main)
 await frames()
 for member in ['_celebration','_welcome','_walk_result']: main.get(member).hide()
 main.set('_modal_queue',[] as Array[Callable])
 # Mochila: filtro Para o Tiro e detalhe com Dar/Ir.
 var events := root.get_node('Events')
 var list = load('res://scripts/ui/inventory_list.gd').new()
 events.sheet_requested.emit('Mochila', load('res://scripts/ui/sheet_builder.gd').tall(list))
 await frames(20)
 list.choose_category('keepsake')
 await frames()
 check(list.find_child('Item_chew_ring',true,false)!=null and list.find_child('Item_courage_medal',true,false)!=null,'filtro mostra os itens-chave')
 check(list.find_child('Item_carrot',true,false)==null,'filtro esconde o resto')
 await shot('mochila_para_o_tiro')
 await click(list.find_child('Item_chew_ring',true,false))
 var give: Control = main.find_child('GiveGrowth_chew_ring',true,false)
 check(give!=null and main.find_child('KeepsakeGo',true,false)!=null,'detalhe tem Dar e Ir')
 await shot('detalhe_argolinha')
 # Painel de crescimento: Dar pelo cartão do requisito, com o ícone voando.
 events.sheet_close_requested.emit()
 await frames(20)
 load('res://scripts/ui/growth_ui.gd').call('open')
 await frames(20)
 await shot('painel_antes')
 var panel_give: Control = main.find_child('GiveGrowth_chew_ring',true,false)
 check(panel_give!=null and panel_give.size.y>=44,'Dar no painel com alvo 44')
 Motion.reduced = false
 await click(panel_give)
 check(state.inventory.count('chew_ring')==0 and state.growth.delivered.teething.chew_ring==1,'entregou pelo toque')
 check(root.find_child('FlyingKeepsake',true,false)!=null,'ícone voando até o Tiro')
 await shot('painel_voando')
 await create_timer(0.8).timeout
 await frames()
 check(root.find_child('FlyingKeepsake',true,false)==null,'ícone chegou')
 check(main.find_child('GiveGrowth_chew_ring',true,false)==null,'cartão sem botão depois')
 check(state.grow_error()=='','pronto para crescer')
 await shot('painel_depois')
 print('KEYS UI: '+('PASS' if failures==0 else 'FAIL'))
 quit(0 if failures==0 else 1)
