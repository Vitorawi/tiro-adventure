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

@warning_ignore_restore("unused_signal")
