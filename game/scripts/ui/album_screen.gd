class_name AlbumScreen
extends RefCounted
## Tela inteira do Álbum de cartas (saiu do caderninho). Mesma folha de madeira do `CodexUi`, sem a coluna de abas:
## a madeira usa a largura toda, a placa diz "Álbum", as seções são os filtros do topo e só a grade rola
## (a rolagem de cada seção fica em `CodexUi.album_scroll`). Abre por `AlbumScreen.open(seção)`; o botão da home
## (`AlbumButton`) e todas as entradas antigas (`PetNotebook.open("album...")`) passam por aqui.
## Nó raiz: `AlbumScreen`.


## Existe para o jogador quando já há alguma foto (mesma condição de antes).
static func available() -> bool:
	return GameState.photo_count() > 0


## Há foto nova para ver ou carta fechada para abrir (selo do botão). Respeita `photo_alerts_enabled`.
static func has_new() -> bool:
	if not GameState.photo_alerts_enabled():
		return false
	return not GameState.photos_unseen().is_empty() or not GameState.sealed_photos().is_empty()


static func panel(section: String = "") -> Control:
	return CodexUi.build("album", section, true)


static func open(section: String = "") -> void:
	Events.sheet_requested.emit("Álbum", panel(section))


## Ela está na tela agora?
static func is_open() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var main := tree.root.get_node_or_null("Main")
	return main != null and main.find_child("AlbumScreen", true, false) != null
