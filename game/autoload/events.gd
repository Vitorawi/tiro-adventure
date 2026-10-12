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

## Pede para a tela principal mostrar uma mensagem curta.
signal toast_requested(text: String)
## Pede para abrir o painel inferior (sheet) com um conteúdo.
signal sheet_requested(title: String, content: Control)
## Pede para fechar o painel inferior.
signal sheet_close_requested
## Pede para trocar de tela ("pet" ou "house").
signal screen_requested(screen: StringName)
## Emitido pelo PwaUpdater quando há uma versão nova do jogo pronta para instalar.
signal update_available

@warning_ignore_restore("unused_signal")
