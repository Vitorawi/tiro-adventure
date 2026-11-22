extends RefCounted
## Testes de MECÂNICA (motor de pratos, cozinha, Livro, relógio) que andam pelos "dias" 1 a 7 do calendário antigo:
## devolvem, só em memória, os números que a F04 mudou (cada sistema agora abre no seu capítulo da história,
## 2 a 11). A ordem real dos capítulos é testada em `ato3_chapters_test`. Uso: `load(...).new().apply(db)`.


func apply(db: Node) -> void:
	var dishes: Dictionary = db.dishes
	for pair: Array in [["milho", 2], ["ovo", 2], ["abobrinha", 3], ["arroz", 3], ["peixe", 3], ["batata_doce", 4],
			["maca", 4], ["banana", 4], ["melancia", 5]]:
		dishes.ingredients[pair[0]]["opens"] = pair[1]
	for pair: Array in [["biscoito", 2], ["sopinha", 3], ["mingau", 4]]:
		dishes.types[pair[0]]["opens"] = pair[1]
	dishes.types.papinha["max_by_day"] = [[1, 2], [3, 3]]
	db.recipe_book["open_chapter"] = 1
	db.recipe_book.daily["from_chapter"] = 3
	db.recipe_book.novelty["from_chapter"] = 4
	db.recipes.week_oat_biscuit.requirements["story_day"] = 2
	var progression: Dictionary = db.progression
	progression.upgrades.chicken_coop.requirements["story_day"] = 2
	progression.upgrades.orchard.requirements["story_day"] = 4
	progression.shops.week_cart.requirements["story_day"] = 5
	for pair: Array in [["week_coop", 2], ["week_teether", 7], ["week_zucchini_seed", 3], ["week_rice", 3],
			["week_sweet_potato_seed", 4], ["week_watermelon_seed", 5], ["worm_pack", 3]]:
		progression.shop_items[pair[0]].requirements["story_day"] = pair[1]
	for pair: Array in [["sit", 2], ["paw", 4], ["lie_down", 5]]:
		progression.tricks[pair[0]].requirements["story_day"] = pair[1]
	progression.trick_settings.meal["day"] = 3
	progression.trick_settings.show["day"] = 6
	db.farm["fishing_chapter"] = 3
	db.farm["orchard_chapter"] = 4
	var days: Dictionary = db.growth.week_play.days
	for pair: Array in [["ball", 1], ["name", 1], ["fetch", 2], ["rope", 4], ["squeak", 5], ["lake", 6], ["hide", 6]]:
		days[pair[0]] = pair[1]
	var places: Dictionary = db.worlds.farm.places
	for pair: Array in [["week_cart", 5], ["week_show", 6], ["fishing", 3], ["orchard", 4], ["chicken_coop", 2]]:
		places[pair[0]].requirements["story_day"] = pair[1]
	db.wishes.wishes.train.requirements["story_day"] = 2
