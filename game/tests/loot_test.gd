extends SceneTree
## Sorteios com semente (Loot): determinismo, faixas [min, max] e pesos.

var failures: int = 0


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Loot: " + message)


func _initialize() -> void:
	var entries: Array = [
		{"id": "a", "weight": 9, "coins": [1, 3]},
		{"id": "b", "weight": 1, "items": {"x": [2, 4]}},
		{"id": "c", "items": {"y": 1}, "weight": 0},
	]
	check(Loot.pick_weighted([], 1).is_empty(), "lista vazia devolve vazio")
	check(Loot.amount(5, 1) == 5, "número vira ele mesmo")
	for seed in 50:
		var value := Loot.amount([2, 4], seed)
		check(value >= 2 and value <= 4, "faixa respeita limites")
	check(Loot.roll(entries, 10, 42) == Loot.roll(entries, 10, 42), "mesma semente, mesmo resultado")
	check(Loot.pick_weighted(entries, 7) == Loot.pick_weighted(entries, 7), "pick determinístico")
	var counts := {"a": 0, "b": 0, "c": 0}
	for seed in 1000:
		counts[str(Loot.pick_weighted(entries, seed).id)] += 1
	check(counts.a > 800 and counts.a < 970, "peso 9 domina (%d)" % counts.a)
	check(counts.b > 30 and counts.b < 200, "peso 1 aparece (%d)" % counts.b)
	check(counts.c == 0, "peso 0 nunca sai")
	var total := Loot.roll([{"coins": 5, "items": {"x": 2}}], 3, 1)
	check(total.coins == 15 and total.items.x == 6, "roll soma os sorteios")
	print("LOOT TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
