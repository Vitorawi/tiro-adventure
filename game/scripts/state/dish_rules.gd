class_name DishRules
extends RefCounted
## Motor dos pratos (Primeira semana, E02): funções puras sobre `data/dishes.json` (`Database.dishes`).
##
## Um prato é descrito por TIPO + INGREDIENTES + ESTRELAS e vira o item dinâmico
## `dish_<tipo>_<ing+ing+ing>_<estrelas>` (só `[a-z0-9_+]`, para servir de nome de nó e de chave de contador).
## O `Database.ensure_dish` registra esse item em `Database.items` quando ele entra no jogo; daí em diante
## inventário, depósito, venda, Mochila e alimentação tratam o prato como qualquer item.
##
## Cálculo (confere linha a linha com a planilha "Catálogo de pratos do filhote"): soma dos ingredientes →
## bônus fixos do tipo → duplas (+1 cada) → UM multiplicador (maciça da papinha × preparo das estrelas),
## arredondado uma só vez. A ordem das vagas não muda o prato.

const PREFIX := "dish_"


static func data() -> Dictionary:
	return Database.dishes


# --- Identificador -----------------------------------------------------------------------------------

static func is_dish_id(id: String) -> bool:
	return id.begins_with(PREFIX) and not parse(id).is_empty()


## Id do prato com os ingredientes na ordem canônica. "" se o tipo ou algum ingrediente não existe.
static func make_id(type: String, ingredients: Array, stars: int = 1) -> String:
	if not data().get("types", {}).has(type) or ingredients.is_empty():
		return ""
	for ing: Variant in ingredients:
		if not data().get("ingredients", {}).has(str(ing)):
			return ""
	var parts: PackedStringArray = []
	for ing: String in canon(ingredients):
		parts.append(ing)
	return "%s%s_%s_%d" % [PREFIX, type, "+".join(parts), clampi(stars, 1, 3)]


## {type, ingredients (canônicos), stars} ou {} se o id não descreve um prato conhecido.
static func parse(id: String) -> Dictionary:
	if not id.begins_with(PREFIX):
		return {}
	var body := id.substr(PREFIX.length())
	var first := body.find("_")
	var last := body.rfind("_")
	if first <= 0 or last <= first:
		return {}
	var type := body.substr(0, first)
	var stars_text := body.substr(last + 1)
	if not stars_text.is_valid_int() or int(stars_text) < 1 or int(stars_text) > 3:
		return {}
	if not data().get("types", {}).has(type):
		return {}
	var ingredients: Array[String] = []
	for part: String in body.substr(first + 1, last - first - 1).split("+"):
		if not data().get("ingredients", {}).has(part):
			return {}
		ingredients.append(part)
	if ingredients.is_empty() or canon(ingredients) != ingredients:
		return {}
	return {"type": type, "ingredients": ingredients, "stars": int(stars_text)}


# --- Ingredientes -------------------------------------------------------------------------------------

## Ordem canônica (a da tabela de ingredientes): é a ordem dos nomes ("cenoura, ovo e peixe").
static func order() -> Array:
	return data().get("ingredients", {}).keys()


static func canon(ingredients: Array) -> Array[String]:
	var list := order()
	var result: Array[String] = []
	for ing: Variant in ingredients:
		result.append(str(ing))
	result.sort_custom(func(a: String, b: String) -> bool:
		var ia := list.find(a)
		var ib := list.find(b)
		return ia < ib if ia != ib else a < b)
	return result


static func ingredient(id: String) -> Dictionary:
	return data().get("ingredients", {}).get(id, {})


## Ingrediente que um item do inventário representa ("" se não é ingrediente). Os três peixes são "peixe".
static func ingredient_of_item(item_id: String) -> String:
	for id: String in data().get("ingredients", {}):
		if item_id in data().ingredients[id].get("items", []):
			return id
	return ""


## Item "canônico" do ingrediente (o primeiro da lista).
static func main_item(ingredient_id: String) -> String:
	var items: Array = ingredient(ingredient_id).get("items", [])
	return str(items[0]) if not items.is_empty() else ""


# --- Tipos e regra de combinação -------------------------------------------------------------------------

static func type_def(type: String) -> Dictionary:
	return data().get("types", {}).get(type, {})


static func types() -> Array:
	return data().get("types", {}).keys()


static func opens(type: String) -> int:
	return int(type_def(type).get("opens", 1))


static func is_meal(type: String) -> bool:
	return bool(type_def(type).get("meal", false))


## Máximo de ingredientes do tipo no dia (a 3ª vaga da papinha abre no dia 3).
static func max_count(type: String, day: int = 99) -> int:
	var def := type_def(type)
	var result := int(def.get("max", 1))
	for entry: Variant in def.get("max_by_day", []):
		if day >= int(entry[0]):
			result = int(entry[1])
	return result


static func _matches(rule: Dictionary, ingredient_id: String) -> bool:
	if bool(rule.get("any", false)):
		return true
	if rule.has("ingredient"):
		return str(rule.ingredient) == ingredient_id
	return str(rule.get("category", "")) == str(ingredient(ingredient_id).get("category", ""))


## {"state": "dish" | "gororoba" | "incomplete" | "invalid", "culprit": ingrediente que quebrou a regra, "reason": texto}.
## `incomplete` = poucos ingredientes (nada acontece ainda); `gororoba` = não forma o prato do tipo; `invalid` = id ruim.
static func evaluate(type: String, ingredients: Array) -> Dictionary:
	var def := type_def(type)
	if def.is_empty():
		return {"state": "invalid", "reason": "Tipo de prato desconhecido"}
	for ingredient_id: Variant in ingredients:
		if ingredient(str(ingredient_id)).is_empty():
			return {"state": "invalid", "reason": "Ingrediente inválido"}
	if ingredients.size() > int(def.get("max", 1)):
		return {"state": "invalid", "reason": "Ingredientes demais"}
	if ingredients.size() < int(def.get("min", 1)):
		return {"state": "incomplete", "reason": "Faltam ingredientes"}
	# Todo ingrediente precisa caber numa das famílias aceitas; o primeiro que não cabe é o que volta (Gororoba).
	for ingredient_id: String in canon(ingredients):
		var fits := false
		for rule: Dictionary in def.get("allow", []):
			if _matches(rule, ingredient_id):
				fits = true
				break
		if not fits:
			return {"state": "gororoba", "culprit": ingredient_id, "reason": "Não forma um %s" % str(def.name).to_lower()}
	for need: Dictionary in def.get("need", []):
		var have := 0
		for ingredient_id: String in ingredients:
			if _matches(need, ingredient_id):
				have += 1
		if have < int(need.get("min", 1)):
			# O que sobra sem cumprir: devolve o último na ordem canônica.
			return {"state": "gororoba", "culprit": canon(ingredients).back(), "reason": "Não forma um %s" % str(def.name).to_lower()}
	return {"state": "dish"}


# --- Nutrientes, duplas, sabor ------------------------------------------------------------------------------

static func nutrient_ids() -> Array:
	return data().get("nutrients", {}).keys()


static func duples_of(ingredients: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for duple: Dictionary in data().get("duples", []):
		if str(duple.a) in ingredients and str(duple.b) in ingredients:
			result.append(duple)
	return result


static func stars_multiplier(stars: int) -> float:
	return float(data().get("stars", {}).get(str(clampi(stars, 1, 3)), 1.0))


## Força/Brilho/Foco/Ânimo do prato. `phase` = fase do Tiro (a papinha é macia em Recém-chegado e Filhotinho).
static func nutrients(type: String, ingredients: Array, stars: int = 1, phase: String = "") -> Dictionary:
	var total := {}
	for key: String in nutrient_ids():
		total[key] = 0
	for ingredient_id: Variant in ingredients:
		var points: Dictionary = ingredient(str(ingredient_id)).get("n", {})
		for key: String in total:
			total[key] += int(points.get(key, 0))
	var def := type_def(type)
	for key: String in def.get("flat", {}):
		total[key] = int(total.get(key, 0)) + int(def.flat[key])
	for duple: Dictionary in duples_of(ingredients):
		for key: String in duple.bonus:
			total[key] = int(total.get(key, 0)) + int(duple.bonus[key])
	var factor := float(def.get("mult", {}).get(phase, 1.0)) * stars_multiplier(stars)
	var result := {}
	for key: String in total:
		result[key] = roundi(snappedf(float(total[key]) * factor, 0.0001))
	return result


static func nutrient_total(values: Dictionary) -> int:
	var sum := 0
	for key: String in values:
		sum += int(values[key])
	return sum


## Nutrientes em que o prato mais rende (os maiores valores positivos; empate lista os dois).
static func top_nutrients(values: Dictionary) -> Array[String]:
	var best := 0
	for key: String in values:
		best = maxi(best, int(values[key]))
	var result: Array[String] = []
	if best <= 0:
		return result
	for key: String in nutrient_ids():
		if int(values.get(key, 0)) == best:
			result.append(key)
	return result


## Sabor: o que aparece em mais ingredientes; empate: o de mais pontos; persistindo, o do primeiro ingrediente.
static func taste(ingredients: Array) -> String:
	var counts := {}
	var points := {}
	var first_seen: Array[String] = []
	for ingredient_id: String in canon(ingredients):
		var def := ingredient(ingredient_id)
		var flavor := str(def.get("taste", ""))
		counts[flavor] = int(counts.get(flavor, 0)) + 1
		points[flavor] = int(points.get(flavor, 0)) + nutrient_total(def.get("n", {}))
		if flavor not in first_seen:
			first_seen.append(flavor)
	var best := ""
	for flavor: String in first_seen:
		if best == "" or int(counts[flavor]) > int(counts[best]) \
				or (int(counts[flavor]) == int(counts[best]) and int(points[flavor]) > int(points[best])):
			best = flavor
	return best


# --- Nome, ícone, preço -------------------------------------------------------------------------------------

## Prato com nome próprio ({} se não tem): casa o tipo e os ingredientes (multiconjunto) exatos.
static func named(type: String, ingredients: Array) -> Dictionary:
	var key := canon(ingredients)
	for entry: Dictionary in data().get("named", []):
		if str(entry.type) == type and canon(entry.ingredients) == key:
			return entry
	return {}


static func name_of(type: String, ingredients: Array) -> String:
	var own := named(type, ingredients)
	if not own.is_empty():
		return str(own.name)
	var names: Array[String] = []
	for ingredient_id: String in canon(ingredients):
		var label := str(ingredient(ingredient_id).get("name", ingredient_id)).to_lower()
		if label not in names:
			names.append(label)
	var text := names[0]
	if names.size() == 2:
		text = "%s e %s" % [names[0], names[1]]
	elif names.size() > 2:
		text = "%s e %s" % [", ".join(names.slice(0, names.size() - 1)), names.back()]
	return "%s de %s" % [str(type_def(type).get("name", type)), text]


## Item cujo ícone o prato usa (o do prato nomeado, senão o do tipo). Provisório até a E16.
static func icon_item(type: String, ingredients: Array) -> String:
	var own := named(type, ingredients)
	if not own.is_empty() and own.has("icon_item"):
		return str(own.icon_item)
	return str(type_def(type).get("icon_item", ""))


static func sell_price(type: String, ingredients: Array, stars: int = 1) -> int:
	var sum := 0
	for ingredient_id: Variant in ingredients:
		sum += int(ingredient(str(ingredient_id)).get("sell", 1))
	var price := float(sum) * float(type_def(type).get("sell_mult", 1.0)) * (1.0 + 0.1 * float(clampi(stars, 1, 3) - 1))
	return maxi(int(data().get("sell_min", 4)), roundi(price))


## Item de inventário do prato (o que `Database.ensure_dish` registra). {} se o id não é um prato.
static func item_def(id: String) -> Dictionary:
	var info := parse(id)
	if info.is_empty():
		return {}
	var type := str(info.type)
	var ingredients: Array = info.ingredients
	var def := type_def(type)
	var item_icon := str(Database.items.get(icon_item(type, ingredients), {}).get("icon", ""))
	var phases: Array = []
	for phase: Dictionary in Database.growth.get("phases", []):
		phases.append(str(phase.id))
	var result := {
		"name": name_of(type, ingredients),
		"category": "food",
		"storage": "fridge",
		"icon": item_icon,
		"sell_price": sell_price(type, ingredients, int(info.stars)),
		"trade_xp": 4,
		"feed": def.get("feed", {"hunger": 10}).duplicate(),
		"dish": {"type": type, "ingredients": ingredients.duplicate(), "stars": int(info.stars), "meal": is_meal(type)},
		"growth": {"phases": phases},
	}
	if not is_meal(type):
		result["treat"] = true  # lanche: alegra, mas não conta como refeição
	return result


# --- Catálogo ---------------------------------------------------------------------------------------------------

static func _multisets(pool: Array, size: int, start: int = 0) -> Array:
	if size == 0:
		return [[]]
	var result: Array = []
	for index in range(start, pool.size()):
		for rest: Array in _multisets(pool, size - 1, index):
			result.append([pool[index]] + rest)
	return result


## Ingredientes que já abriram no dia.
static func available(day: int) -> Array:
	var result: Array = []
	for id: String in order():
		if int(ingredient(id).get("opens", 1)) <= day:
			result.append(id)
	return result


## Todos os pratos válidos (não Gororoba) do dia, acumulados: [{type, ingredients}] sem repetir.
static func combinations(day: int) -> Array:
	var result: Array = []
	var pool := available(day)
	for type: String in types():
		if opens(type) > day:
			continue
		var def := type_def(type)
		for size in range(int(def.get("min", 1)), max_count(type, day) + 1):
			for combo: Array in _multisets(pool, size):
				if str(evaluate(type, combo).state) == "dish":
					result.append({"type": type, "ingredients": combo})
	return result


static func count_for_day(day: int, only_meals: int = -1) -> int:
	var total := 0
	for entry: Dictionary in combinations(day):
		if only_meals == -1 or is_meal(str(entry.type)) == (only_meals == 1):
			total += 1
	return total


# --- Pratos conhecidos e prévia (E03) ------------------------------------------------------------------------------

## Chave do prato SEM estrelas ("papinha:cenoura+ovo"): é o que o jogo lembra como "prato conhecido".
static func key_of(type: String, ingredients: Array) -> String:
	if not data().get("types", {}).has(type) or ingredients.is_empty():
		return ""
	return "%s:%s" % [type, "+".join(PackedStringArray(canon(ingredients)))]


## {type, ingredients} da chave `key_of`; {} se não descreve um prato conhecido do motor.
static func parse_key(key: String) -> Dictionary:
	var parts := key.split(":")
	if parts.size() != 2 or not data().get("types", {}).has(parts[0]):
		return {}
	var ingredients: Array[String] = []
	for part: String in parts[1].split("+"):
		if ingredient(part).is_empty():
			return {}
		ingredients.append(part)
	if ingredients.is_empty() or canon(ingredients) != ingredients:
		return {}
	return {"type": parts[0], "ingredients": ingredients}


## Item que o prato vale para o crescimento (`counts_as` do prato nomeado, p. ex. "fish_mash"); "" se nenhum.
static func counts_as(type: String, ingredients: Array) -> String:
	return str(named(type, ingredients).get("counts_as", ""))


## Frases "Conta como prato com ovo" dos ingredientes-chave do prato (só refeições; lanche não conta).
static func key_notes(type: String, ingredients: Array) -> Array[String]:
	var result: Array[String] = []
	if not is_meal(type):
		return result
	for ingredient_id: String in canon(ingredients):
		var note := str(ingredient(ingredient_id).get("key_note", ""))
		if note != "" and note not in result:
			result.append(note)
	return result


## Tipos abertos no dia (na ordem do JSON).
static func open_types(day: int) -> Array[String]:
	var result: Array[String] = []
	for type: String in types():
		if opens(type) <= day:
			result.append(type)
	return result


## Quantos espaços a panela mostra para o tipo no dia: o menor entre os espaços do tipo e o máximo do dia.
static func slot_count(type: String, slots: int, day: int) -> int:
	if type_def(type).is_empty():
		return slots
	return mini(slots, max_count(type, day))
