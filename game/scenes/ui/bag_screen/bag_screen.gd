extends PanelContainer
## Aba Mochila: tudo o que você tem, por categoria. Tocar num item mostra o que
## ele faz, como conseguir, onde usar e o atalho para vender (SheetBuilder.item_detail).


func _ready() -> void:
	%Holder.add_child(SheetBuilder.inventory_view())


## A casca sobe o conteúdo quando a linha 2 do HUD está vazia (história concluída): `top` = margem de cima.
func set_content_top(top: float) -> void:
	$Margin.add_theme_constant_override("margin_top", roundi(top))
