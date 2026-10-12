extends Node
## Estado global do jogador (autoload "GameState").
##
## Única fonte da verdade para dados que precisam sobreviver entre cenas
## e sessões. Não acessa disco: o SaveManager usa to_dict()/from_dict().
## Ao adicionar um campo novo, atualize to_dict(), from_dict() e reset().

## Contador de exemplo para testar o save. Remover quando o jogo real existir.
var counter: int = 0


func reset() -> void:
	counter = 0
	Events.state_changed.emit()


func add_to_counter(amount: int = 1) -> void:
	counter += amount
	Events.state_changed.emit()


func to_dict() -> Dictionary:
	return {
		"counter": counter,
	}


func from_dict(data: Dictionary) -> void:
	counter = int(data.get("counter", 0))
	Events.state_changed.emit()
