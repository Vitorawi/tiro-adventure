extends PanelContainer
## Aba Mochila: tudo o que você tem, por categoria. Tocar num item mostra o que
## ele faz, como conseguir, onde usar e o atalho para vender (SheetBuilder.item_detail).
## Visual "madeira ilustrada": moldura de madeira na tela inteira (`BagFrame`) e lista com `BagUi`.


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var holder := Control.new()
	holder.name = "BagFrame"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 0)
	BagUi.frame(holder, "frame", Vector4(14, 150, 14, 77), "Frame")
	var list := InventoryList.new()
	list.wood = true
	# Peças ilustradas suaves (o projeto é "nearest" por causa da pixel art; ícones pixel pedem nearest neles mesmos).
	list.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	%Holder.add_child(list)


## A casca sobe o conteúdo quando a linha 2 do HUD está vazia (história concluída): `top` = margem de cima.
func set_content_top(top: float) -> void:
	$Margin.add_theme_constant_override("margin_top", roundi(top))
