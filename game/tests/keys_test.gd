extends SceneTree
var state: Node
var db: Node
var failures := 0
const KEYS = ['chew_ring','stick_chew','soft_brush','courage_medal']
func _initialize() -> void:
 run.call_deferred()
 create_timer(170).timeout.connect(func() -> void: quit(1))
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error('Keys: '+message)
func fresh(phase: String = 'newborn') -> void:
 state.reset()
 state.growth.phase = phase
func row(id: String) -> Dictionary:
 for r: Dictionary in state.growth_info().requirements:
  if r.id == id: return r
 return {}
func reload_state() -> void:
 state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
func make(recipe_id: String) -> void:
 var recipe: Dictionary = db.recipes[recipe_id]
 for input: String in recipe.inputs: state.inventory.add(input,int(recipe.inputs[input]))
 var why: String = state.cook(recipe_id)
 check(why=='','fabrica '+recipe_id+' '+why)
 state.test_time += float(recipe.seconds)+1
 state.collect(str(recipe.station))
func run() -> void:
 var saver = root.get_node('SaveManager')
 root.remove_child(saver)
 saver.free()
 state = root.get_node('GameState')
 db = root.get_node('Database')
 state.set_script(load('res://tests/friend_clock.gd'))
 state.test_time = 1791936000.0
 # Itens: categoria, sem depósito, sem venda, com ícone próprio.
 for id: String in KEYS:
  var item: Dictionary = db.items[id]
  check(item.category=='keepsake' and item.storage=='none','categoria '+id)
  check(state.storage_of(id)=='' and not item.has('sell_price'),'sem depósito nem preço '+id)
  check(ResourceLoader.exists(str(item.icon)),'ícone '+id)
  fresh()
  state.inventory.add(id,1)
  check(state.sell(id,1)!='' and state.inventory.count(id)==1,'não vende '+id)
 # Receitas da bancada.
 fresh()
 state.dev_unlock_everything()
 state.inventory.from_dict({})
 make('stick_chew')
 check(state.inventory.count('stick_chew')==1,'mordedor de graveto')
 make('soft_brush')
 check(state.inventory.count('soft_brush')==1,'escova macia')
 check(db.recipes.soft_brush.requirements.quests[0]=='main_8_fiber','escova pela missão')
 # Alcançável pelo jogo: todo insumo dos itens-chave tem origem (colheita, rota, passeio ou receita).
 for recipe_id in ['stick_chew','soft_brush','sew_topknot_bow']:
  for input: String in db.recipes[recipe_id].inputs:
   check(db.item_sources(input).size()>0,'origem de '+input+' ('+recipe_id+')')
 # Missão da vovó: entrega uma vez, consome os ingredientes, dá argolinha + 10 moedas.
 fresh('puppy')
 var help: Script = load('res://scripts/ui/task_help.gd')
 var origin: Dictionary = help.call('describe','growth_req','key')
 check('Vovó Bloblo' in str(origin.detail) and 'Sítio' in str(origin.detail) and 'Argolinha da vovó' in str(origin.detail),'origem visível antes de liberar a missão')
 check('3' in str(origin.detail) and '1' in str(origin.detail),'origem informa as quantidades da troca')
 check(origin.target.get('screen','')!='bag','sem argolinha não manda procurar na mochila')
 var source_panel: Control = load('res://scripts/ui/growth_ui.gd').panel()
 root.add_child(source_panel)
 await process_frame
 check(source_panel.find_child('GrowthSource_chew_ring',true,false)!=null,'origem aparece diretamente no crescimento')
 source_panel.queue_free()
 fresh()
 state.dev_complete_quest('bloblo_stew')
 check(state.quest_unlocked('bloblo_chew_ring'),'missão da vovó aparece depois do ensopado')
 check(state.claim_quest('bloblo_chew_ring')!='','sem ingredientes não entrega')
 state.inventory.add('carrot',3)
 state.inventory.add('potato',1)
 var coins: int = state.coins
 check(state.claim_quest('bloblo_chew_ring')=='','entrega a argolinha')
 check(state.inventory.count('chew_ring')==1 and state.inventory.count('carrot')==0 and state.inventory.count('potato')==0,'argolinha e ingredientes')
 check(state.coins-coins==10,'dez moedas')
 state.growth.phase = 'puppy'
 origin = help.call('describe','growth_req','key')
 check('Você já tem' in str(origin.detail) and origin.target.has('growth'),'depois de receber orienta Dar no crescimento')
 var rewards: Control = load('res://scripts/ui/progression_ui.gd').reward_chips(db.quests.bloblo_chew_ring.rewards)
 root.add_child(rewards)
 var named_reward := false
 for label: Label in rewards.find_children('*','Label',true,false):
  if 'Argolinha de morder' in label.text: named_reward = true
 check(named_reward,'recompensa mostra o nome, além do ícone')
 rewards.queue_free()
 check(state.claim_quest('bloblo_chew_ring')!='' and state.inventory.count('chew_ring')==1,'uma vez só')
 # Dar: erro sem item, definitivo, some depois de entregar, exigido para crescer.
 fresh('puppy')
 check(state.deliver_growth_error('chew_ring')=='Falta Argolinha de morder','erro sem item')
 check(state.deliver_growth_error('courage_medal').contains('não precisa'),'item de outra fase')
 check(row('key').type=='deliver' and not row('key').done,'dentinhos pede a argolinha')
 state.inventory.add('chew_ring',1)
 check(state.inventory.count('chew_ring')==1,'argolinha fica na mochila até entregar')
 check(state.deliver_growth('chew_ring')=='','dar')
 check(state.inventory.count('chew_ring')==0 and row('key').done,'entregue some e cumpre')
 check(state.deliver_growth('chew_ring')=='Já entregue','definitivo')
 check(int(state.growth.delivered.teething.chew_ring)==1,'lembrança gravada')
 reload_state()
 check(row('key').done and int(state.growth.delivered.teething.chew_ring)==1,'lembrança salva')
 # Crescer exige o item-chave.
 fresh('puppy')
 state.progress.stats['feed:frozen_carrot'] = 3
 state.growth.phase_moments['brave'] = 3
 check(state.grow_error().contains('Argolinha'),'não cresce sem argolinha')
 state.inventory.add('chew_ring',1)
 state.deliver_growth('chew_ring')
 check(state.grow_error()=='' and state.grow()=='' and state.growth.phase=='teething','cresce com argolinha')
 # Requisitos finais: todas as fases têm item-chave; adulto = medalha + lacinho + refeição.
 for pair in [['teething','chew_ring'],['explorer','stick_chew'],['young','soft_brush'],['adult','courage_medal']]:
  var found := false
  for p: Dictionary in db.growth.phases:
   if p.id==pair[0]:
    for req: Dictionary in p.requirements:
     if req.type=='deliver' and req.item==pair[1]: found = true
  check(found,'deliver '+pair[1]+' em '+pair[0])
 var kinds := []
 for req: Dictionary in db.growth.phases[5].requirements: kinds.append(req.type)
 check('collection' in kinds and 'feed' in kinds,'adulto: lacinho e refeição')
 # Medalhinha pela missão da festa, uma vez.
 fresh()
 state.dev_complete_quest('community_12_festival')
 state.progress.stats['project_use:village_festival'] = 1
 check(state.claim_quest('community_12_memory')=='','missão da lembrança')
 check(state.inventory.count('courage_medal')==1,'medalhinha')
 check(state.claim_quest('community_12_memory')!='' and state.inventory.count('courage_medal')==1,'medalhinha uma vez')
 # Lacinho: só no Mocinho; costurado vira roupa; overlay nos corpos adulto e jovem.
 fresh('explorer')
 state.dev_unlock_everything()
 state.growth.phase = 'explorer'
 check(state.cook_error('sew_topknot_bow')!='','costura espera o Mocinho')
 state.growth.phase = 'young'
 state.inventory.from_dict({})
 state.progress.collection.erase('topknot_bow')
 make('sew_topknot_bow')
 check(state.progress.collection.has('topknot_bow'),'lacinho costurado entra na coleção')
 check(state.inventory.count('topknot_bow')==0,'não vira item')
 check(state.equip('topknot_bow')=='' and state.progress.equipped.head=='topknot_bow','veste na cabeça')
 var anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/sprites/characters/tiro_pet/overlay_anchors.json'))
 check(ResourceLoader.exists(str(db.collections.topknot_bow.overlay)),'overlay base')
 for clip: String in anchors.show_in:
  check(anchors.bodies.young.has(clip) and anchors.bodies.young[clip].has('head'),'âncora do jovem '+clip)
 for clip: String in anchors.frame_variants:
  check(ResourceLoader.exists('res://assets/sprites/characters/tiro_pet/overlays/topknot_bow/%s/frame_00.png' % clip),'variantes '+clip)
 # Mochila: filtro "Para o Tiro" e botão Ir.
 state.inventory.add('chew_ring',1)
 var list = load('res://scripts/ui/inventory_list.gd').new()
 root.add_child(list)
 await process_frame
 check(list.find_child('Item_chew_ring',true,false)!=null,'argolinha na grade')
 list.choose_category('keepsake')
 await process_frame
 check(list.find_child('Item_chew_ring',true,false)!=null,'filtro Para o Tiro')
 var detail: Control = load('res://scripts/ui/sheet_builder.gd').item_detail('chew_ring')
 root.add_child(detail)
 await process_frame
 check(detail.find_child('KeepsakeGo',true,false)!=null,'botão Ir no detalhe')
 print('KEYS TEST: '+('PASS' if failures==0 else 'FAIL'))
 quit(0 if failures==0 else 1)


