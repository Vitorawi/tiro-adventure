extends "res://tests/helpers/economy_bot.gd"
## Planejador DEFEITUOSO, só para provar que a guarda de pureza do runner funciona (economy_sim_test).
## Altera inventário ou moedas durante plan(), o que o planejador nunca pode fazer.

var mode: String = "inventory"


func plan(left: float, gap: float) -> Dictionary:
	if mode == "inventory":
		gs.inventory.add("carrot", 5)
	elif mode == "coins":
		gs.coins += 50
	return super.plan(left, gap)
