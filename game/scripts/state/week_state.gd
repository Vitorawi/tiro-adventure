class_name WeekState
extends RefCounted
## Relógio da primeira semana do Tiro (plano `docs/plans/primeira_semana`, E00 e E01).
## Só guarda dados; as regras (janelas, refeição na hora, patinha) ficam no `GameState`.

## Número do dia local (dias desde 1970 no fuso do aparelho) em que o save começou; -1 = ainda não marcado.
var started_day: int = -1
## DEV: segundos somados ao relógio da semana. Fica 0 na versão publicada.
var clock_offset: float = 0.0
## Maior número de dia local já visto: o dia do jogo só avança, mesmo se o relógio do aparelho voltar.
var high_day: int = -1
## Refeições por dia do jogo (chave = número do dia, texto):
## {"1": {"sun": {"at": 0.0, "on_time": true, "item": "puppy_mash"}, "moon": {...}, "paw": true}} (`missed: true` = dia sem patinha)
var days: Dictionary = {}
## Última metade do dia (dia local × 2 + 0 sol/1 lua) já fechada e conferido; -1 = não iniciado.
var settled: int = -1
## Tigela de dois lugares (Deixar pronto): até `meals.stored_slots` refeições, uma por período, em ordem de
## janela: [{"item", "day" (dia do Tiro, virada às 6h), "period"}]; vazio = nenhuma.
var stored: Array = []
## Recados de refeição servida sozinha pela tigela, para o Bom dia/boas-vindas mostrarem
## ("Comeu sozinho da tigela às 16h"): [{"period", "at" (instante da semana), "item", "seen"}].
var served: Array = []
## A aula da comida (F02) já foi dada: o relógio das refeições passa a existir para o jogador.
var food_lesson: bool = false
## Instante (relógio da semana) em que o dia da chegada (a caixinha) começou.
var arrival_at: float = 0.0
## Pratos e receitas que o jogador já fez (E03): chave -> {stars (melhor, 1 a 3), made (lotes), day (primeiro dia)}.
## Chaves: `dish:<tipo>:<ingredientes>` (prato do motor, sem estrelas) e `recipe:<receita>` (receita fixa do fogão).
var dishes: Dictionary = {}
## Provas, pistas, páginas e desafio do ingrediente do dia.
var recipe_book: Dictionary = {}
## Dia civil do último presente de iscas e término por árvore do pomar.
var bait_day: int = -1
var orchard_ready: Dictionary = {}
## Último dia do jogo em que a plateia premiou um show.
var last_trick_show_day: int = -1
## Uso por período e recordes da Bolinha. A partida aberta vive somente na sessão.
var play: Dictionary = {}
## Último dia civil em que cada pedido da carroça foi entregue.
var cart_deliveries: Dictionary = {}
## E12: contadores do desafio corrente e os pratos servidos no almoço de despedida.
var story_challenge: Dictionary = {}
var farewell: Dictionary = {}
## E13: sorteios, ações e cartões por dia civil, objetivos das linhas e preferência de aviso.
var routine: Dictionary = {}
## E14: passos, lições dispensadas e ponto para reabrir pelo mesmo lugar.
var tutorial: Dictionary = {}
## F04b: patinhas extras do Ensopado Dourado (dia -> 1), último dia em que o peixe dourado mordeu e montinhos cavados
## com a missão secreta aberta sem achar a minhoca gorda (garantia no 4º).
var bonus_paws: Dictionary = {}
var golden_day: int = -1
var worm_digs: int = 0


func reset() -> void:
	bonus_paws = {}
	golden_day = -1
	worm_digs = 0
	routine.clear()
	tutorial.clear()
	story_challenge.clear()
	farewell.clear()
	play.clear()
	cart_deliveries.clear()
	last_trick_show_day = -1
	dishes = {}
	recipe_book = {}
	bait_day = -1
	orchard_ready = {}
	settled = -1
	stored = []
	served = []
	food_lesson = false
	arrival_at = 0.0
	started_day = -1
	clock_offset = 0.0
	high_day = -1
	days = {}


func day_record(day: int) -> Dictionary:
	return days.get(str(day), {})


func to_dict() -> Dictionary:
	return {
		"started_day": started_day,
		"clock_offset": clock_offset,
		"high_day": high_day,
		"days": days.duplicate(true),
		"settled": settled,
		"stored": stored.duplicate(true),
		"served": served.duplicate(true),
		"food_lesson": food_lesson,
		"arrival_at": arrival_at,
		"dishes": dishes.duplicate(true),
		"recipe_book": recipe_book.duplicate(true),
		"bait_day": bait_day,
		"orchard_ready": orchard_ready.duplicate(),
		"last_trick_show_day": last_trick_show_day,
		"play": play.duplicate(true),
		"cart_deliveries": cart_deliveries.duplicate(),
		"story_challenge": story_challenge.duplicate(),
		"farewell": farewell.duplicate(),
		"routine": routine.duplicate(true),
		"tutorial": tutorial.duplicate(true),
		"bonus_paws": bonus_paws.duplicate(),
		"golden_day": golden_day,
		"worm_digs": worm_digs,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	started_day = int(data.get("started_day", -1))
	clock_offset = float(data.get("clock_offset", 0.0))
	high_day = int(data.get("high_day", -1))
	story_challenge = data.get("story_challenge", {}).duplicate()
	farewell = data.get("farewell", {}).duplicate()
	routine = data.get("routine", {}).duplicate(true)
	tutorial = data.get("tutorial", {}).duplicate(true)
	bait_day = int(data.get("bait_day", -1))
	golden_day = int(data.get("golden_day", -1))
	worm_digs = int(data.get("worm_digs", 0))
	var bonus: Variant = data.get("bonus_paws", {})
	if bonus is Dictionary:
		bonus_paws = (bonus as Dictionary).duplicate()
	var orchard: Variant = data.get("orchard_ready", {})
	if orchard is Dictionary:
		orchard_ready = (orchard as Dictionary).duplicate()
	var deliveries: Variant = data.get("cart_deliveries", {})
	if deliveries is Dictionary:
		cart_deliveries = deliveries.duplicate()
	last_trick_show_day = int(data.get("last_trick_show_day", -1))
	var play_data: Variant = data.get("play", {})
	if play_data is Dictionary:
		play = (play_data as Dictionary).duplicate(true)
	settled = int(data.get("settled", -1))
	var stored_data: Variant = data.get("stored", [])
	if stored_data is Array:
		stored = (stored_data as Array).duplicate(true)
	var served_data: Variant = data.get("served", [])
	if served_data is Array:
		served = (served_data as Array).duplicate(true)
	food_lesson = bool(data.get("food_lesson", false))
	arrival_at = float(data.get("arrival_at", 0.0))
	var book: Variant = data.get("recipe_book", {})
	if book is Dictionary:
		recipe_book = book.duplicate(true)
	var dishes_data: Variant = data.get("dishes", {})
	if dishes_data is Dictionary:
		for key: Variant in dishes_data:
			if dishes_data[key] is Dictionary:
				dishes[str(key)] = (dishes_data[key] as Dictionary).duplicate(true)
	var loaded: Variant = data.get("days", {})
	if loaded is Dictionary:
		for key: Variant in loaded:
			if loaded[key] is Dictionary:
				days[str(key)] = (loaded[key] as Dictionary).duplicate(true)
