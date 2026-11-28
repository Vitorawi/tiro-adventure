extends SceneTree
## F04 Parte A do plano "Novo fluxo": os capítulos 2 a 11 apresentam um sistema cada, abrem só no seu capítulo
## (conteúdo por `content_day()` = capítulo), fecham com uma carta fechada e a Vila só abre com o Dentinhos.

var failures := 0
var state: Node
var db: Node

## capítulo -> [último passo, foto de marco que ele entrega ("" = nenhuma: fotos só de marcos)]
const CLOSING := {
	2: ["week_soup", ""], 3: ["lais_first_wish", ""], 4: ["week_egg_dish", ""],
	5: ["week_sit", "h_first_trick"], 6: ["week_fish_dish", ""], 7: ["week_fruit_dish", ""],
	8: ["week_book", ""], 9: ["week_bath", ""], 10: ["week_show", ""],
}


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("F04A · " + message)


## O requisito `story_day` abre no capítulo `chapter` (e não antes).
func _story_day_opens(requirements: Dictionary, chapter: int, what: String) -> void:
	check(int(requirements.get("story_day", 0)) == chapter, what + ": story_day = capítulo %d" % chapter)
	state.dev_content_day(chapter - 1)
	check(state.requirement_error({"story_day": chapter}) != "", what + ": fechado no capítulo %d" % (chapter - 1))
	state.dev_content_day(chapter)
	check(state.requirement_error({"story_day": chapter}) == "", what + ": aberto no capítulo %d" % chapter)


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.reset()
	state.set_clock(1792411200.0)
	state.reset()
	state.call("_count", "arrival_box")
	var prog: Dictionary = db.progression

	# Estrutura: capítulos 2 a 11 na ordem do plano e pós-semana a partir do 12.
	check(prog.chapters.size() == 20, "20 capítulos (11 da semana + 9 depois)")
	check(state.week_last_chapter() == 11, "a semana termina no capítulo 11")
	var expected := {
		2: ["week_market", "week_plots", "lais_photo", "week_fridge", "week_soup"], 3: ["lais_first_wish"], 4: ["week_coop", "week_hen", "week_eggs", "week_egg_dish"],
		5: ["week_biscuits", "week_sit"], 6: ["week_bridge", "week_fish", "week_fish_dish"], 7: ["week_orchard", "week_fruit_dish"],
		8: ["week_invent", "week_book"], 9: ["week_cart_order", "week_bath"],
		10: ["week_fetch", "week_rope", "week_paw", "week_down", "week_hide", "week_show"], 11: ["teeth_3_ring", "growth_3_teething"],
		12: ["lais_village", "first_sale", "main_2_order", "main_4_nina_chest"],
	}
	for chapter: int in expected:
		check(state.progress.main_quests(chapter) == Array(expected[chapter], TYPE_STRING, "", null), "passos do capítulo %d" % chapter)

	# Cada sistema abre no capítulo que o apresenta.
	state.dev_content_day(1)
	check(not state.dish_type_open("sopinha"), "sopinha fechada no capítulo 1")
	state.dev_content_day(2)
	check(state.dish_type_open("sopinha"), "sopinha abre no capítulo 2 (banca)")
	check(db.recipes.vegetable_soup.get("requirements", {}).get("owned", []) == ["fridge"], "a sopinha do fogão pede a geladeira (passo week_fridge antes)")
	state.growth.phase = "puppy"  # o desejo também pede Filhotinho
	state.dev_content_day(2)
	check(not state.wishes_open(), "sem desejo no capítulo 2")
	state.dev_content_day(3)
	check(state.wishes_open(), "desejo abre no capítulo 3")
	_story_day_opens(prog.upgrades.chicken_coop.requirements, 4, "galinheiro")
	_story_day_opens(prog.tricks.sit.requirements, 5, "Senta")
	state.dev_content_day(5)
	check(not state.farm_lake_open(), "lagoa fechada no capítulo 5")
	state.dev_content_day(6)
	check(state.farm_lake_open(), "lagoa abre no capítulo 6")
	_story_day_opens(prog.upgrades.orchard.requirements, 7, "pomar")
	state.dev_grant_upgrade("stove")
	state.dev_content_day(7)
	check(not state.invent_open() and not state.recipe_book_open(), "Inventar e Livro fechados no capítulo 7")
	check(state.cook_invented_error({"pumpkin": 1, "potato": 1}, "papinha") == "Continue a História", "Inventar não cozinha antes do capítulo 8")
	state.dev_content_day(8)
	check(state.invent_open() and state.recipe_book_open(), "Inventar e Livro abrem no capítulo 8")
	_story_day_opens(prog.shops.week_cart.requirements, 9, "carroça")
	_story_day_opens(prog.tricks.paw.requirements, 10, "Dá a pata")
	state.dev_content_day(9)
	check(not state.yard_open("ball") and not state.yard_open("rope") and not state.yard_open("hide"), "quintal fechado no capítulo 9")
	state.dev_content_day(10)
	check(state.yard_open("ball") and state.yard_open("rope") and state.yard_open("hide"), "quintal abre no capítulo 10")
	check(int(prog.trick_settings.show.day) == 10, "show no capítulo 10")
	_story_day_opens(prog.shop_items.week_teether.requirements, 11, "mordedor")

	# O último passo de cada capítulo entrega a carta fechada, e só ele.
	for chapter: int in CLOSING:
		var last: String = CLOSING[chapter][0]
		var photo: String = CLOSING[chapter][1]
		var ids: Array = state.progress.main_quests(chapter)
		var closing: String = ids.back() if chapter != 10 else "week_show"
		check(closing == last, "o último passo do capítulo %d é %s" % [chapter, last])
		check(photo == "" or not db.photo(photo).is_empty(), "foto de fechamento existe: " + photo)
		state.reset()
		state.call("_count", "arrival_box")
		state.dev_content_day(chapter)
		for id: String in ids:
			if id == last:
				break
			state.dev_complete_quest(id)
		if photo != "":
			check(not state.album.has_photo(photo), "foto %s ainda não chegou antes do último passo" % photo)
		state.dev_complete_quest(last)
		if photo != "":
			check(state.album.has_photo(photo), "o passo %s entrega a foto %s" % [last, photo])
		if photo != "":
			check(state.photo_sealed(photo) >= 1, "a foto %s chega fechada" % photo)

	# A foto do almoço de despedida fecha o capítulo 11, e a Vila só abre com o Dentinhos.
	check(str(db.week_story.farewell.photo) == "h_week_group" and not db.photo("h_week_group").is_empty(), "foto de grupo do almoço")
	state.reset()
	state.call("_count", "arrival_box")
	state.dev_content_day(12)
	state.growth.phase = "puppy"
	check(state.requirement_error(db.worlds.village.requirements) != "", "Vila fechada antes dos Dentinhos")
	state.growth.phase = "teething"
	check(state.requirement_error(db.worlds.village.requirements) == "", "Vila abre com os Dentinhos")

	print("ATO3 CHAPTERS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
