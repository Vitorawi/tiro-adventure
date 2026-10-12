extends Node
## Barramento global de sinais (autoload "Events").
##
## Sistemas que não se conhecem conversam por aqui: um emite, outro escuta.
## Declare aqui apenas sinais que cruzam fronteiras entre sistemas;
## sinais locais de uma cena ficam na própria cena.

@warning_ignore_start("unused_signal")

## Emitido pelo SaveManager depois de gravar o save no disco.
signal game_saved
## Emitido pelo SaveManager depois de carregar (ou criar) o save.
signal game_loaded
## Emitido pelo GameState quando qualquer dado do estado muda.
signal state_changed
signal quest_completed(id: String)
signal chapter_completed(index: int)

## Emitido pelo GameState quando o jogador cuida do Tiro ("feed", "play", "bathe", "pet").
signal dog_action(action: StringName)

## Pede para a tela principal mostrar uma mensagem curta.
signal toast_requested(text: String)
## Pede para abrir o painel inferior (sheet) com um conteúdo.
signal sheet_requested(title: String, content: Control)
## Pede para fechar o painel inferior.
signal sheet_close_requested
## Pede para trocar de aba ("pet", "map", "tasks", "bag").
signal screen_requested(screen: StringName)
## Pede para ir a um mundo (aba Mapa) e, se `place` vier, abrir um lugar ("stove")
## ou personagem ("npc:bloblo") dele. Usado pelos botões "Ir" das Tarefas e da Mochila.
signal world_requested(world: String, place: String)
## Emitido pelo PwaUpdater quando há uma versão nova do jogo pronta para instalar.
signal update_available

@warning_ignore_restore("unused_signal")
