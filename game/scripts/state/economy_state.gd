class_name EconomyState
extends RefCounted
## Estado da economia que sobrevive a mudanças de balanceamento (etapa 02 do plano R1).
## Só dados + consultas puras + to_dict/from_dict; as AÇÕES ficam no GameState.
##
## - `revision`: revisão de CONTEÚDO/economia já aplicada ao save (separada do formato, SAVE_VERSION).
## - `storage_floor`: piso legado por depósito = capacidade anterior COMPRADA (nunca a quantidade
##   estocada). Só sobe; a capacidade vale max(curva do estágio, piso).
## - `pending`: recibos de presentes AUTOMÁTICOS (nível/capítulo/vínculo...) cujos itens não couberam.
## - `granted`: ids de recompensas automáticas já pagas (moedas/XP/desbloqueios saem uma única vez).
## - `legacy`: mapa de missões congelado usado na migração (capítulo concluído com o mapa ANTIGO).

const CURRENT_REVISION := 1

var revision: int = 0
var storage_floor: Dictionary = {}
## id estável -> { "items": { item: quantidade restante }, "label": String, "source": String }.
var pending: Dictionary = {}
var granted: Dictionary = {}
var legacy: Dictionary = {}
## Como o histórico de lotes das estações (maestria, etapa 18) foi obtido: "r1" = contado lote a lote,
## "min_units_v1" = mínimo comprovável pelo histórico de produção; "" = save ainda não semeado.
var mastery_method: String = ""


func reset() -> void:
	revision = CURRENT_REVISION
	storage_floor = {}
	pending = {}
	granted = {}
	legacy = {}
	mastery_method = "r1"


func floor_of(depot: String) -> int:
	return int(storage_floor.get(depot, 0))


## Piso só sobe: comprar mais não pode ser anulado por uma curva nova menor.
func raise_floor(depot: String, value: int) -> void:
	if value > floor_of(depot):
		storage_floor[depot] = value


## Quantidade total de unidades de itens esperando para ser guardadas.
func pending_total() -> int:
	var total := 0
	for receipt: Dictionary in pending.values():
		for amount: int in receipt.items.values():
			total += amount
	return total


## Quantidade de recibos (presentes) com algo a guardar.
func pending_count() -> int:
	return pending.size()


func to_dict() -> Dictionary:
	return {
		"revision": revision,
		"storage_floor": storage_floor.duplicate(),
		"pending": pending.duplicate(true),
		"granted": granted.duplicate(),
		"legacy": legacy.duplicate(true),
		"mastery_method": mastery_method,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	revision = int(data.get("revision", 0))
	for depot: String in data.get("storage_floor", {}):
		storage_floor[depot] = maxi(0, int(data.storage_floor[depot]))
	for id: String in data.get("pending", {}):
		var entry: Dictionary = data.pending[id]
		var items := {}
		for item: String in entry.get("items", {}):
			if int(entry.items[item]) > 0:
				items[item] = int(entry.items[item])
		if not items.is_empty():
			pending[id] = {"items": items, "label": str(entry.get("label", id)), "source": str(entry.get("source", id.get_slice(":", 0)))}
	for id: String in data.get("granted", {}):
		granted[id] = true
	legacy = data.get("legacy", {}).duplicate(true)
	mastery_method = str(data.get("mastery_method", ""))
