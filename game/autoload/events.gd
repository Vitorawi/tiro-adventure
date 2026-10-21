extends Node

## Roupa produzida/conquistada fora do passeio; entra na fila de cartões da casca.
signal cosmetic_received(id: String)
signal trick_learned(id: String)
## Baú da Clareira aberto; `rewards` já foi entregue.
signal treasure_opened(rewards: Dictionary)
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
## Subiu de nível; `rewards` já foi entregue (soma dos níveis atingidos).
signal level_up(level: int, rewards: Dictionary)
## Subiu de vínculo com o Tiro; `rewards` já foi entregue (soma dos níveis atingidos).
signal bond_up(level: int, rewards: Dictionary)

## Emitido pelo GameState quando o jogador cuida do Tiro ("feed", "play", "bathe", "pet").
signal dog_action(action: StringName)
## Ação concluída no mundo; reação visual do Tiro, sem efeito no save.
signal world_activity(kind: StringName, subject: String, plot_index: int)

## Obra comunitária: uma fase ficou completa (emitido uma vez, depois de salvar o estado).
signal project_phase_completed(id: String, phase_id: String, index: int)
## Obra concluída; `result` = o que o `_grant_automatic` devolveu (itens guardados/em recibo). Uma vez por obra.
signal project_completed(id: String, result: Dictionary)
## Uso da obra pronta; `first` só na primeira vez (as demais são só visuais).
signal project_used(id: String, first: bool)
## Um ciclo do "Encontro da turma" (opção repetível depois da obra) acabou de ser confirmado.
signal project_gathered(id: String, cycle: int)

## Pede para a tela principal mostrar uma mensagem curta.
signal toast_requested(text: String)
## Recolheu algo: itens (id → qtd) e moedas; a tela mostra miniaturas saltando de `origin`
## (coordenadas da tela; Vector2(-1, -1) = meio da tela). Ver CollectFx.
signal items_gained(items: Dictionary, coins: int, origin: Vector2)
## Novo item do álbum ou mudas iniciais: cartão na fila de comemorações.
signal find_discovered(result: Dictionary)
## Recolheu um passeio: resumo para o cartão "Volta do passeio" (ver WalkResult).
signal walk_collected(result: Dictionary)
## Pede para abrir o painel inferior (sheet) com um conteúdo.
signal sheet_requested(title: String, content: Control)
## Pede para fechar o painel inferior.
signal sheet_close_requested
## O painel inferior acabou de fechar (por qualquer caminho: botão, arrasto ou pedido).
signal sheet_closed
## Pede para trocar de aba ("pet", "map", "tasks", "bag").
signal screen_requested(screen: StringName)
## Aponta para um cuidado na tela do Tiro depois de usar Ir.
signal care_requested(item: String)
## Pede para ir a um mundo (aba Mapa) e, se `place` vier, abrir um lugar ("stove")
## ou personagem ("npc:bloblo") dele. Usado pelos botões "Ir" das Missões e da Mochila.
signal world_requested(world: String, place: String)
## Pede a bandeja de ação da horta (Sítio): `crop_id` = planta a destacar ("" = nenhuma);
## `plot_index` = canteiro (−1 = o primeiro vazio que aceite a planta). Usado pelo "Ir" e pelo painel de canteiros.
signal plot_tray_requested(crop_id: String, plot_index: int)
## Emitido pelo PwaUpdater quando há uma versão nova do jogo pronta para instalar.
signal update_available

@warning_ignore_restore("unused_signal")

# Crescimento do Tiro (fases e ganhos dos quatro atributos).
signal grew(phase: String)
signal growth_ready(phase: String)
signal silk_up(level: int)
signal growth_requirement_done(phase: String, req_id: String)
signal taste_discovered(item: String, reaction: String)
signal taste_reacted(item: String, reaction: String)
signal pillar_gained(pillar: String, points: int, level_up: bool)
signal photo_taken(id: String)
signal house_item_arrived(id: String)
