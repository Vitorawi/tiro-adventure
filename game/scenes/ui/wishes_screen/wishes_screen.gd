extends PanelContainer
## Aba Desejos: o que o Tiro está pedindo (até três espaços) e o vínculo com ele.
## Quadro de pedidos do próprio cachorro: carinho, brincar e comidinhas que o jogador já sabe fazer.


func _ready() -> void:
	%Holder.add_child(SheetBuilder.LiveBox.new(_build))


func _build(box: VBoxContainer) -> void:
	WishUi.header(box)
	for i in GameState.wishes.slots.size():
		WishUi.slot_card(box, i)
