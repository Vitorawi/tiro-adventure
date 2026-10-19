extends "res://scripts/state/progression_state.gd"
## ProgressionState com memória das duas consultas mais caras e puras (etapa 01, só nos testes de economia).
##
## `chapter_index()` e `main_quests()` percorrem as 81 missões e ordenam listas a cada chamada, e o
## `requirement_error` do jogo chama `chapter_index()` sempre. O simulador faz milhares de consultas por
## ação, então guardar o resultado acelera a execução SEM mudar nenhuma regra:
##   * `main_quests(capítulo)` depende só de data/quests.json (estático);
##   * `chapter_index()` depende só de quais missões foram recebidas (`claimed_quests`, que só cresce).
## `tests/economy_sim_test.gd` confere que o resultado é idêntico ao da classe original.

var _chapter_key: int = -1
var _chapter_value: int = 1
var _main_cache: Dictionary = {}


func chapter_index() -> int:
	var key := claimed_quests.size()
	if key != _chapter_key:
		_chapter_value = super.chapter_index()
		_chapter_key = key
	return _chapter_value


func main_quests(chapter: int) -> Array[String]:
	if not _main_cache.has(chapter):
		_main_cache[chapter] = super.main_quests(chapter)
	var result: Array[String] = []
	result.assign(_main_cache[chapter])
	return result


func from_dict(data: Dictionary) -> void:
	_chapter_key = -1
	super.from_dict(data)
