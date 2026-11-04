class_name LockedButton
extends Button
## Botão de madeira BLOQUEADO (peça única; monte com `StepCardUi.locked_button`): mesma forma e altura do verde
## (`go_button`), arte apagada, cadeado dourado + ícone opcional + motivo curto. Não é `disabled` (precisa receber o toque):
## tocar explica o motivo. A altura cresce se o motivo precisar de mais de uma linha.

const MIN_HEIGHT := 44.0
var row: Control


func _get_minimum_size() -> Vector2:
	var wanted := MIN_HEIGHT
	if row != null:
		wanted = maxf(MIN_HEIGHT, row.get_combined_minimum_size().y + 8.0)
	return Vector2(0.0, wanted)


## Versão estreita (colunas de ~110 px, ex.: a entrega da encomenda): margens menores, cadeado 18 e motivo em 13 px,
## para o texto quebrar em até duas linhas sem partir palavras.
func compact() -> void:
	row.offset_left = 8.0
	row.offset_right = -8.0
	row.add_theme_constant_override("separation", 4)
	var lock := row.get_node_or_null("LockIcon") as Control
	if lock != null:
		lock.custom_minimum_size = Vector2(18, 18)
	var text := row.get_node_or_null("LockText") as Label
	if text != null:
		HomeUi.resize(text, 13)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.custom_minimum_size.x = 30.0
