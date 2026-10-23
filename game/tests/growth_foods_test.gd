extends SceneTree
var state: Node
var db: Node
var failures := 0
const FOODS = ['frozen_carrot','puppy_mash','corn_crunch','growth_kibble','egg_scramble','cheese_bites','milk_porridge','herb_shampoo']
const PRICES = [8,12,7,14,20,8,15,18]
func _initialize() -> void:
 run.call_deferred()
 create_timer(150).timeout.connect(func() -> void: quit(1))
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error('Growth foods: '+message)
func fresh(phase: String = 'adult') -> void:
 state.reset()
 state.growth.phase = phase
 needs()
func avoid_favorite(item: String) -> void:
 # A favorita ganha +50%; estes testes medem o ganho comum.
 for s in range(1, 50):
  state.growth.taste_seed = s
  if state.favorite_food() != item: return
func needs() -> void:
 for id in ['hunger','happiness','energy','hygiene']: state.dog.needs[id] = 20.0
 state.dog.updated_at = state.now()
func row(id: String) -> Dictionary:
 for r: Dictionary in state.growth_info().requirements:
  if r.id == id: return r
 return {}
func reload_state() -> void:
 state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
func run() -> void:
 var saver = root.get_node('SaveManager')
 root.remove_child(saver)
 saver.free()
 state = root.get_node('GameState')
 db = root.get_node('Database')
 state.set_script(load('res://tests/friend_clock.gd'))
 state.test_time = 1791936000.0
 # Ajuda de comida: receita visível mesmo bloqueada, ícone real e ação conforme preparo/estoque.
 var help: Script = load('res://scripts/ui/task_help.gd')
 fresh('teething')
 state.progress.owned['stove'] = true
 var guide: Dictionary = help.call('describe','growth_req','meals')
 check(guide.title=='Ração de crescimento' and guide.food_guide.place=='Casa → Fogão','nome da comida e local explícitos')
 check('Galinheiro' in str(guide.food_guide.status),'explica o bloqueio direto antes da missão distante')
 check(guide.food_guide.inputs.size()==3 and guide.food_guide.inputs[0].label!='','ingredientes têm nomes')
 check(guide.target.get('place')=='recipe:growth_kibble','mesmo bloqueada a ajuda mantém destino na receita')
 check(help.call('icon_for','growth_req','meals')==db.item_icon('growth_kibble'),'ícone da comida, não osso genérico')
 fresh('teething')
 state.dev_unlock_everything()
 state.growth.phase = 'teething'
 state.inventory.from_dict({'corn':1,'carrot':1,'egg':1})
 guide = help.call('describe','growth_req','meals')
 check(guide.action=='Preparar no Fogão','com tudo disponível leva à receita')
 # Fila cheia com todos os ingredientes: não pode culpar materiais nem perder o foco.
 state.inventory.add('carrot',20)
 for i in state.station_slots('stove'):
  check(state.cook('carrot_snack')=='','preenche a fila com outra receita')
 guide = help.call('describe','growth_req','meals')
 check('fila' in str(guide.food_guide.status) and not 'Falta conseguir' in str(guide.food_guide.status),'fila cheia tem explicação própria')
 check(guide.action=='Ver fila no Fogão' and guide.target.get('place')=='recipe:growth_kibble','fila cheia ainda abre a receita pedida')
 state.station('stove').queue.clear()
 state.inventory.from_dict({})
 guide = help.call('describe','growth_req','meals')
 check('Falta conseguir' in str(guide.food_guide.status) and guide.target.get('place')=='recipe:growth_kibble','ingredientes faltantes não desviam o botão de preparar')
 state.inventory.from_dict({'corn':1,'carrot':1,'egg':1})
 check(state.cook('growth_kibble')=='','prepara a comida da ajuda')
 guide = help.call('describe','growth_req','meals')
 check(guide.action=='Ver preparo','não manda preparar de novo durante a produção')
 state.test_time += 601
 guide = help.call('describe','growth_req','meals')
 check(guide.action=='Pegar no Fogão','comida pronta orienta pegar')
 state.collect('stove')
 guide = help.call('describe','growth_req','meals')
 check(guide.action=='Dar ao Tiro' and 'Você tem 2' in str(guide.progress_text),'com estoque orienta alimentar')
 state.feed('growth_kibble')
 guide = help.call('describe','growth_req','meals')
 check('Já comeu 1 de 3' in str(guide.progress_text),'progresso das refeições separado do estoque')
 for i in FOODS.size():
  var id: String = FOODS[i]
  fresh()
  state.dev_unlock_everything()
  state.inventory.from_dict({})
  var recipe: Dictionary = db.recipes[id]
  for input: String in recipe.inputs: state.inventory.add(input,int(recipe.inputs[input]))
  check(state.cook(id)=='','cozinha '+id)
  state.test_time += float(recipe.seconds)+1
  state.collect(str(recipe.station))
  check(state.inventory.count(id)==int(recipe.qty),'rendimento '+id)
  check(state.storage_of(id)=='fridge','geladeira '+id)
  check(int(recipe.player_xp)==0,'sem XP '+id)
  check(db.item_sources(id).size()>0 and db.sources_of(id).size()>0,'Manual/Como fazer '+id)
  state.dev_complete_quest('bloblo_meet')
  state.dev_complete_quest('merchant_meet')
  var coins: int = state.coins
  check(state.sell(id,1)=='','venda '+id)
  check(state.coins-coins==PRICES[i],'preço '+id)
  if id == 'herb_shampoo': continue
  var growth: Dictionary = db.items[id].growth
  for phase: String in ['newborn','puppy','teething','explorer','young','adult']:
   fresh(phase)
   avoid_favorite(id)
   state.inventory.add(id,1)
   check(state.feed(id),'come '+id)
   check(state.progress.stat('feed:'+id)==1,'comida conta refeição sem pontos '+id)
 # Os bloqueios dizem exatamente a construção/missão que falta.
 for pair in [['growth_kibble','chicken_coop'],['egg_scramble','chicken_coop'],['cheese_bites','dairy'],['milk_porridge','cow_barn'],['herb_shampoo','greenhouse']]:
  fresh()
  state.dev_grant_upgrade('stove')
  state.dev_grant_upgrade('blender')
  check(state.cook_error(pair[0])==state.requirement_error(db.recipes[pair[0]].requirements),'motivo de '+pair[0])
  check(state.cook_error(pair[0]).contains(str(db.progression.upgrades[pair[1]].name)),'nome de '+pair[1])
 fresh()
 state.dev_grant_upgrade('cow_barn')
 check(state.requirement_error(db.recipes.milk_porridge.requirements).contains(str(db.progression.upgrades.mill.name)),'mingau exige também moinho')
 for pair in [['frozen_carrot','lais_blender'],['puppy_mash','first_kitchen']]:
  fresh()
  check(state.requirement_error(db.recipes[pair[0]].requirements)!='','missão bloqueia '+pair[0])
  state.dev_complete_quest(pair[1])
  check(state.requirement_error(db.recipes[pair[0]].requirements)=='','missão libera '+pair[0])
 fresh()
 check(state.requirement_error(db.recipes.corn_crunch.requirements)!='','crocante exige capítulo 5')
 state.dev_unlock_everything()
 check(state.requirement_error(db.recipes.corn_crunch.requirements)=='','capítulo libera crocante')
 for pair in [['puppy','frozen_carrot'],['teething','growth_kibble'],['explorer','milk_porridge']]:
  fresh()
  state.progress.stats['feed:'+pair[1]] = 8
  state.growth.phase = pair[0]
  state.growth.phase_stats = state.progress.stats.duplicate()
  check(row('meals').have==0,'antes da fase não conta '+pair[1])
  state.inventory.add(pair[1],3)
  for i in 3: state.feed(pair[1])
  check(row('meals').done,'refeição durante a fase '+pair[1])
  reload_state()
  check(row('meals').done,'refeição salva '+pair[1])
 fresh('explorer')
 state.inventory.add('herb_shampoo',4)
 state.bathe(true)
 check(state.inventory.count('herb_shampoo')==3 and state.progress.stat('moment:coat')==2,'xampu útil vale dois')
 needs()
 state.bathe(true)
 check(state.progress.stat('moment:coat')==2,'teto compartilhado de banhos')
 reload_state()
 needs()
 state.bathe()
 check(state.progress.stat('moment:coat')==2,'reload não libera teto')
 state.test_time += 6 * 3600
 needs()
 state.bathe()
 check(state.progress.stat('moment:coat')==3,'novo período libera banho comum')
 fresh()
 state.bathe(true)
 check(state.progress.stat('bathe')==0,'sem xampu não consome nem conta')
 print('GROWTH FOODS TEST: '+('PASS' if failures==0 else 'FAIL (%d)'%failures))
 quit(0 if failures==0 else 1)
