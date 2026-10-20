extends SceneTree
var state: Node
var db: Node
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error('Pillars: '+message)
func fresh(phase: String = 'adult') -> void:
	state.reset()
	state.growth.phase = phase
	needs(40)
func needs(value: float) -> void:
	for id: String in ['hunger','happiness','hygiene','energy']: state.dog.needs[id] = value
	state.dog.updated_at = state.now()
func count(id: String) -> int:
	return state.progress.stat('pillar:'+id)
func reload_state() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
func run() -> void:
	var saver: Node = root.get_node('SaveManager')
	root.remove_child(saver)
	saver.free()
	state = root.get_node('GameState')
	db = root.get_node('Database')
	state.set_script(load('res://tests/friend_clock.gd'))
	state.test_time = 1791936000.0
	fresh()
	for low: String in ['hunger','happiness','energy','hygiene']:
		needs(60)
		state.dog.needs[low] = 59
		var before := count('body')
		state._gain_pillar('body',3,'test')
		check(count('body')-before == 3,'Radiante exige '+low)
	needs(60)
	var n := count('body')
	state._gain_pillar('body',3,'test')
	check(count('body')-n == 5,'Radiante arredonda 4,5 para 5')
	# Todas as comidas pelo feed real, dentro e fora da fase.
	for item: String in db.items:
		if not db.items[item].has('feed'): continue
		var food: Dictionary = db.items[item].get('growth',{})
		for phase: String in ['newborn','puppy','teething','explorer','young','adult']:
			fresh(phase)
			for s in range(1, 50):
				state.growth.taste_seed = s
				if state.favorite_food() != item: break
			state.inventory.add(item,1)
			state.feed(item)
			for id: String in ['body','coat','smart','brave']:
				var expected := float(food.get('pillars',{}).get(id,0))
				if phase not in food.get('phases',[]): expected *= 0.0 if food.get('only_phases',false) else 0.5
				check(count(id)==ceili(expected),item+' '+phase+' '+id)
	fresh()
	state.bathe()
	check(count('coat')==3,'banho útil')
	needs(40)
	state.bathe()
	check(count('coat')==3,'banho recarga')
	reload_state()
	needs(40)
	state.bathe()
	check(count('coat')==3,'recarga banho salva')
	state.test_time += 7200
	needs(40)
	state.bathe()
	check(count('coat')==6,'banho após 2 h')
	fresh('puppy')
	state.play()
	check(count('brave')==2 and count('smart')==1,'brincar útil')
	needs(40)
	state.play()
	reload_state()
	needs(40)
	state.play()
	check(count('smart')==1,'brincar recarga salva')
	state.test_time += 1800
	needs(40)
	state.play()
	check(count('smart')==2,'brincar após 30 min')
	fresh('explorer')
	state.inventory.add('braided_toy')
	check(state.give_toy('braided_toy') == '', 'dar brinquedo para o cesto')
	state.play()
	check(count('smart')==2,'cesto da fase aventureiro')
	fresh()
	check(state.pet()==1 and count('brave')==1,'carinho com afeto')
	state.pet()
	reload_state()
	state.pet()
	check(count('brave')==1,'carinho recarga salva')
	state.test_time += 120
	needs(40)
	state.pet()
	check(count('brave')==2,'carinho após 120 s')
	fresh()
	state.talk_to('lais')
	state.talk_to('lais')
	reload_state()
	state.talk_to('lais')
	check(count('brave')==3,'primeira conversa persistida')
	state.note_world_visit('house')
	state.note_world_visit('house')
	reload_state()
	state.note_world_visit('house')
	check(count('brave')==5 and count('smart')==2,'primeiro mundo persistido')
	state.walk_state.current = {'id':'park_loop','ready_at':state.now()+100}
	state.note_world_visit('farm')
	check(not state.growth.firsts.has('world:farm'),'mundo sem Tiro não conta')
	fresh()
	state.dev_unlock_everything()
	needs(40)
	state.learn_trick('paw')
	check(count('smart')==12,'aprender truque')
	state.learn_trick('paw')
	reload_state()
	state.learn_trick('paw')
	check(count('smart')==12,'aprender uma vez')
	needs(40)
	state.perform_trick('paw')
	var smart := count('smart')
	state.perform_trick('paw')
	check(smart==13 and count('smart')==13,'mostrar truque com recarga')
	# Passeio soma pontos na volta; guardar bagagem não repete.
	for id: String in db.growth.sources.walk:
		fresh()
		state.walk_state.current = {'id':id,'ready_at':state.now()-1,'started_at':state.now()-1000,'seed':42}
		check(state.return_due_walk(false),'volta '+id)
		var actual := count('brave')
		var bright := true
		for need: String in ['hunger','happiness','energy','hygiene']:
			bright = bright and state.dog.get_need(need,state.now())>=60
		check(actual==ceili(float(db.growth.sources.walk[id].brave)*(1.5 if bright else 1.0)), 'pontos da rota '+id)
		state.return_due_walk(false)
		reload_state()
		state.return_due_walk(false)
		state.claim_walk_baggage()
		check(count('brave')==actual,'retorno não duplica '+id)
	fresh()
	state.dev_unlock_everything()
	needs(40)
	state.finds.worlds.farm = {'pending':1,'next_at':state.now()+100,'dug':0,'seed':42}
	state.dig('farm')
	check(count('smart')==3,'cavar faro')
	fresh()
	state.dev_unlock_everything()
	needs(40)
	var friend: String = db.friends.friends.keys()[0]
	state.inventory.add(str(state.friend_def(friend).likes),5)
	check(state.give_friend(friend)=='','dar petisco')
	check(count('brave')==2,'petisco dá coragem')
	state.give_friend(friend)
	check(count('brave')==2,'repetir amigo bloqueado')
	var entry: Dictionary = state.friend_state.entry(friend)
	entry.visit_pending = true
	entry.visit_gift = {'items':{}}
	state.friend_state.friends[friend] = entry
	state.collect_friend_visit(friend)
	state.collect_friend_visit(friend)
	check(count('brave')==6,'visita recebida uma vez')
	fresh('puppy')
	state.dev_unlock_everything()
	state.growth.phase = 'puppy'  # o atalho dev também faz o Tiro crescer junto da história (etapa 11)
	state.progress.owned.erase('named_bowl')  # isola a entrega única, sem o bônus opcional da Casa
	needs(40)
	for special: bool in [false,true]:
		state.wishes.slots[0] = {'id':'carrot_snack','base':0,'since':state.now(),'ready_at':0,'special':special,'last':''}
		state.inventory.add('carrot_snack',1)
		var courage := count('brave')
		var body := count('body')
		check(state.fulfill_wish(0)=='','Ele quer! entrega')
		check(count('body')-body==2,'Ele quer! alimenta exatamente uma vez')
		check(count('brave')-courage==(6 if special else 3),'desejo normal/especial')
		reload_state()
		state.fulfill_wish(0)
		check(count('brave')-courage==(6 if special else 3),'desejo não repete após reload')
	fresh()
	for project: String in ['park_bench','park_picnic','village_festival']:
		var project_entry: Dictionary = state.projects.entry(project)
		project_entry.completed = true
		state.projects.projects[project] = project_entry
		var courage := count('brave')
		check(state.use_project(project)=='','usar obra '+project)
		reload_state()
		state.use_project(project)
		check(count('brave')-courage==3,'uso de obra uma vez '+project)
	fresh()
	# O item só entra no catálogo na 09; a fonte e a recarga compartilhada já funcionam.
	state.inventory.add('herb_shampoo',1)
	state.bathe(true)
	check(count('coat')==12 and state.inventory.count('herb_shampoo')==0,'banho com xampu substitui 3 por 12')
	needs(40)
	state.bathe()
	check(count('coat')==12,'xampu e banho compartilham recarga')
	fresh()
	state._apply_rewards({'pillars':{'coat':4}})
	state._grant_automatic('test:pillar',{'pillars':{'coat':5}})
	reload_state()
	state._grant_automatic('test:pillar',{'pillars':{'coat':5}})
	check(count('coat')==9,'prêmios e recibo automático')
	fresh('newborn')
	state._gain_pillar('body',30,'test')
	check(state.growth.points.body==10 and state.growth.reserve.body==20 and state.growth.level('body')==1,'teto e reserva')
	state.dev_complete_growth_reqs()
	state.grow()
	check(state.growth.points.body==25 and state.growth.reserve.body==5,'grow aplica reserva')
	fresh()
	state.set_sleeping(true)
	state.test_time += 1800
	reload_state()
	state._finish_pillar_nap()
	check(count('body')==0,'soneca curta não paga')
	state.test_time += 3600
	state.dog.needs.energy = 100
	state.dog.updated_at = state.now()
	state._finish_pillar_nap()
	check(count('body')==2,'soneca de uma hora cheia')
	reload_state()
	state._finish_pillar_nap()
	check(count('body')==2,'soneca uma vez após reload')
	state.set_sleeping(false)
	needs(40)
	state.set_sleeping(true)
	state.test_time += 3600
	state.dog.needs.energy = 100
	state.dog.updated_at = state.now()
	state._finish_pillar_nap()
	check(count('body')==2,'recarga sono 12 h')
	state.test_time += 43200
	needs(40)
	state.set_sleeping(false)
	state.set_sleeping(true)
	state.test_time += 5400
	state.dog.needs.energy = 100
	state.dog.updated_at = state.now()
	state._finish_pillar_nap()
	check(count('body')==4,'nova soneca após 12 h')
	fresh()
	needs(90)
	state.set_sleeping(true)
	state.test_time += 900
	state._finish_pillar_nap()
	state.test_time += 3600
	state._finish_pillar_nap()
	check(count('body')==0,'cochilo cheio cedo não vira soneca longa')
	# Contratos da interface e atualização ao vivo.
	fresh('newborn')
	var notebook: Script = load('res://scripts/ui/pet_notebook.gd')
	check(not notebook.tabs().any(func(t: Dictionary) -> bool: return t.id=='growth'),'aba antes do primeiro crescimento escondida')
	state.growth.phase = 'puppy'
	check(notebook.tabs().any(func(t: Dictionary) -> bool: return t.id=='growth'),'aba liberada após puppy')
	var panel: Control = notebook.panel('growth')
	root.add_child(panel)
	state._gain_pillar('body',40,'test')
	state._changed()
	for id: String in ['body','coat','smart','brave']:
		check(panel.find_child('PillarRing_'+id,true,false)!=null,'anel '+id)
	check(panel.find_child('PillarValue_body',true,false).text=='2/2','nível/teto')
	check(panel.find_child('PillarReserve_body',true,false).text=='+15 guardado','reserva no painel')
	panel.queue_free()
	await process_frame
	print('PILLARS TEST: ', 'PASS' if failures==0 else 'FAIL')
	quit(1 if failures else 0)
