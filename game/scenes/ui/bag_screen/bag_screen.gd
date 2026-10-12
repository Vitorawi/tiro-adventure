extends PanelContainer
## Aba Mochila: tudo o que você tem, por categoria. Tocar num item mostra o que
## ele faz, como conseguir, onde usar e o atalho para vender (SheetBuilder.item_detail).


func _ready() -> void:
	%Holder.add_child(SheetBuilder.inventory_view())
