extends SceneTree
## Apenas instrumentação: não executa uma campanha nem grava save pessoal.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var script: GDScript = load("res://tests/helpers/economy_sim.gd")
	var sim = script.new(root, {"profile": "reference", "seed": 1, "days": 1, "ledger": "off", "out": ""})
	sim.setup()
	var gs = sim.gs
	gs.coins = 0
	gs.inventory.counts.clear()
	var before: Dictionary = gs.inventory.counts.duplicate()
	var checkpoint: Dictionary = sim.economy_checkpoint()
	var failures := 0
	if checkpoint.inventory != before or gs.inventory.counts != before or gs.coins != 0:
		print("snapshot changed state: ", checkpoint.inventory, " / ", before, " coins ", gs.coins)
		failures += 1
	for target: Dictionary in checkpoint.targets:
		if target.missing_coins != target.cost or target.missing_items != target.materials:
			print("unexpected deficits: ", target)
			failures += 1
		if target.error != gs.upgrade_error(target.id):
			failures += 1
	gs.inventory.counts["wood"] = 7
	if checkpoint.inventory.has("wood"):
		failures += 1
	if checkpoint.targets.is_empty():
		failures += 1
	print("ECONOMY CHECKPOINT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
