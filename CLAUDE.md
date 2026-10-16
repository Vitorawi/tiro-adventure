# AGENTS.md — Mapa do projeto

Leia este arquivo primeiro. Ele diz **o que é o projeto, como está organizado e onde trabalhar**.
Detalhes ficam em `docs/`.

## O que é
**Tiro Adventure** — repo `github.com/Vitorawi/tiro-adventure`, jogo em
https://vitorawi.github.io/tiro-adventure/ (versão de testes: `.../tiro-adventure/dev/`)

**Bichinho virtual (cachorrinho) + produção em cadeia estilo Hay Day + progressão longa.**
Celular **em pé**, tela inteira, **100% toque**: o jogador não controla o movimento do cachorro
(ele anda sozinho), só toca nos objetos (geladeira, horta, fogão...) e arrasta para mover a câmera.
Começa com a casa quase vazia e vai comprando fogão, geladeira, sítio, oficina... com 4 atributos
que evoluem e missões de personagens. Abas: **Tiro · Mapa** (mini mundos: Casa, Sítio, Praça, Vila e Natureza — o portão da Vila leva a Natureza —
cada um com seus personagens e lugares) **· Missões** (História passo a passo, Diárias e Semanais, com botão "Ir" e "?") **· Mochila**.
Após a caminha, a aba **Desejos** entra entre Tiro e Mapa: até três pedidos, balão sobre o Tiro e vínculo em corações.

Jogo 2D em **Godot 4.7.2** (GDScript), exportado para **Web** e instalado no celular como **PWA**
("Adicionar à tela inicial" no iPhone/Android). Publicado automaticamente no **GitHub Pages**
a cada push na `main` (versão publicada em `/` e versão dev em `/dev/`). Progresso salvo
**localmente no aparelho** (IndexedDB via `user://`). Arte em pixel art gerada com o **MCP PixelLab**.

- Ideia/regras do jogo: `docs/GAME_DESIGN.md`
- Progressão (atributos, construções, missões, NPCs, versão dev): `docs/PROGRESSION.md`
- Mundos, navegação e **como criar um mundo novo**: `docs/WORLDS.md`
- Fases, **estado atual e próximas tarefas**: `docs/ROADMAP.md`
- Planos detalhados prontos para executar: `docs/plans/` (ex.: `TASKS_V2.md`)
- Etapas 10 e 11 concluídas: truques com treino de um toque na Praça e o tesouro (mapa completo, baú da Clareira, mirtilo); ver `docs/PROGRESSION.md` e `docs/ART_PIPELINE.md`. **Plano de 12 etapas concluído.**
- **Plano Interface nova CONCLUÍDO** (`docs/plans/interface/README.md`): 13 etapas (00–12) feitas, uma por vez — visual, painel, HUD, mundo em tela cheia, seletor, balões, **bandeja de ação** (plantar/colher arrastando), estações, tela do Tiro, listas, textos e comemorações. Regras e estilo em `docs/plans/interface/01_REGRAS_E_ESTILO.md`. **Etapas 00–12 concluídas** (00: tour de capturas, `Palette`, `Motion`, `RingProgress`, ícones das estações, Casa enquadrada; 01: tema novo — cartão leve, botão com degrau, um botão verde por painel, cadeado no lugar do botão cinza; 02: painel do tamanho do conteúdo com alça para arrastar e fechar, espaços de produção em bolinhas (`SlotDot`), linhas baixas de lista (`UiKit.list_row`) e fala de personagem em balão (`SpeechBubble`); 03: HUD flutuante com avatar do Tiro e anel de XP (`Hud`), pílula de moedas que conta, abas com rosto animado (`NavTab`), balão do nível (`Popover`) e aviso que desce abaixo do HUD; 04: mundo em tela cheia — céu, paisagem e chão atrás da maquete (`backdrop`), enquadramento por mundo, câmera com inércia/duplo toque/elástico, `RecenterButton`, sem botões +/− e sem cabeçalho (`WorldBar` com `WorldPill` e `NpcFace`); 05: seletor em carrossel sobre o mundo, encaixe ao arrastar, bloqueios por nome de história/missão, ícones próprios e viagem com nuvens; 06: balões do mundo `WorldBalloon` com anel de progresso/pronto pulando em canteiros, estações, Natureza e passeio, compra em balão `buy` e etiquetas `WorldLabel` só quando importam; 07: bandeja de ação `ActionTray` na horta — tocar num canteiro abre as sementes ao lado do dedo, arrastar a semente planta vários, regador e foice arrastam por vários canteiros, "Tudo" colhe de uma vez; 08: bandejas nas estações, criações e Natureza, com fila, grade e detalhe; 09: cantinho do Tiro com anéis, quatro cuidados iguais, guia vertical de comidas e caderninho; 10: listas compactas — Missões com "Pegar tudo", Mochila com depósitos e filtros, Coleção em abas com toque para vestir; 11: textos com glossário único — Pegar/Colher/Cozinhar/Fazer/Buscar/Ir —, erros com o item que falta, `texts_test` e `tools/list_texts.ps1`; 12: `ModalCard` único para todas as comemorações (fita, ícone com raios, chips que entram e contam), confete nos grandes momentos, boas-vindas agrupado por tipo, `Haptics` e as preferências "Vibrar"/"Menos animação" em `settings.json`, varredura final nas três resoluções). Próximo: só o que estiver em `docs/plans/interface/FUTURO.md`.

## Trabalho em dupla (Claude Code + Codex)
O projeto é desenvolvido alternando **Claude Code** (lê `CLAUDE.md`) e **Codex** (lê `AGENTS.md`).
- `CLAUDE.md` e `AGENTS.md` têm **o mesmo conteúdo** (inclusive o título): ao editar um, copie para o outro.
- Ao terminar uma tarefa, atualize a seção **"Estado atual"** de `docs/ROADMAP.md` (o que foi feito,
  o que ficou pela metade, próximos passos). É por ali que o outro agente continua.
- `.codex/` é config local do Codex (tem token): fica fora do git.

## Estrutura
```
CLAUDE.md / AGENTS.md  este mapa (mesmo conteúdo)
README.md            descrição pública + link do jogo
docs/                documentação (design, progressão, arquitetura, arte, deploy, roadmap); plans/ = planos a executar
tools/               export_web.ps1 (prod + dev), serve_local.ps1, touch_test.ps1, screenshot.gd, pixel_tools.ps1, list_texts.ps1 (build/texts.csv)
.github/workflows/   deploy.yml: build Web (prod em /, dev em /dev/) + GitHub Pages
build/               saída do export e screenshots (gerada, ignorada no git)
game/                PROJETO GODOT (abra game/project.godot no editor)
  autoload/          Events (sinais), Database (lê data/*.json), GameState (estado + ações), SaveManager, PwaUpdater
  data/              CONTEÚDO em JSON:
                       items.json, recipes.json, crops.json, config.json (necessidades, estações, sítio, XP, início)
                       progression.json (atributos, construções, rotas, pedidos, capítulos)
                       quests.json, npcs.json, collections.json (história, personagens, roupas/apetrechos)
                       routines.json (modelos de missões diárias e semanais, sorteados por período)
                       wishes.json (pedidos do Tiro, espaços, esperas, prioridade das necessidades e especiais)
                       finds.json (faro: achados por mundo, conjuntos, álbum), walks.json (passeios: tempo, energia, necessidades, sorteio, postal)
                       friends.json (amigos: petiscos, corações, recompensas, visitantes e presentes de visita)
                       worlds.json (mundos: lugares, personagens, requisitos)
                       rooms/<id>.json (cena de cada mundo: fundo, móveis, zonas tocáveis), version.json (versão + canal prod/dev, gravado no deploy)
  scenes/            cenas, uma pasta por cena (.tscn + .gd juntos)
    main/            casca: HUD flutuante (avatar com anel de XP, moedas, DEV, engrenagem), abas Tiro/Desejos/Mapa/Missões/Mochila (barra `TabBar` sobre as telas), Sheet, aviso (`Toast`)
    ui/pet_screen/   Cantinho do Tiro (cenário original sem margens, anéis, cuidados por toque/arrasto, caderninho)
    ui/wishes_screen/  aba Desejos: até 3 pedidos, progresso, Dar/Receber, Ir/?, trocar e vínculo
    ui/worlds_screen/  aba Mapa: retoma o mundo atual; `MapView` é seletor em carrossel sobre a sala (pílula, Lugares e rostos em `WorldBar`)
    ui/world_transition/ viagem entre mundos: duas nuvens de papel cobrem a troca, abaixo do HUD; "Ir" espera terminar
    ui/tasks_screen/   aba Missões (História: um passo por vez, visual; Diárias; Semanais; botões "Ir" e "?")
    ui/trick_training/ minijogo de truques (barra, zona verde, três acertos; usa PetAnimator)
    ui/celebration/  comemorações acima do Sheet (nível, capítulo, tesouro, vínculo, achado, truque, "Novo!") em `ModalCard`
    ui/walk_result/  cartão "Volta do passeio" (postal, achados, moedas, vínculo) em `ModalCard`
    ui/welcome_back/ cartão "que bom que você voltou" (presente do dia + o que ficou pronto): presente em destaque + uma linha por tipo
    ui/intro/        chegada da Laís com o Tiro (falas em npcs.json; uma vez por save)
    ui/bag_screen/     aba Mochila (itens por categoria; detalhe: para que serve, onde usar, vender)
    ui/sheet/        painel inferior genérico (menus de objetos)
    levels/room/     RoomView genérico (`room_id`, `world_id`): monta data/rooms/<id>.json (casa, sítio, vila), fundo de céu/chão/paisagem/nuvens (`Backdrop`, grama repetível `WorldGround`), canteiros, etiquetas, navegação, toque, câmera (enquadramento, inércia, duplo toque, `recenter`)
    entities/dog_world/  Tiro pequeno com IA autônoma (anda pelo caminho calculado)
    entities/npc_world/  NPC pequeno (Laís, vovó Bloblo) que passeia perto de casa, com balão "!"/"✓"
  scripts/state/     DogState, Inventory, StationState, ProgressionState, WishState, FindState, WalkState, FriendState (dados + to_dict/from_dict)
  scripts/ui/        Palette (cores), Motion (microanimações), ModalCard (cartão modal único: fita, ícone com raios, chips que entram, confete), Haptics (vibração tap/success/big/error), RingProgress (anel de progresso), Hud (barra superior flutuante, nó `TopBar`), NavTab (rosto das abas), Popover (balão que some sozinho), SlotDot (bolinha de espaço de produção), SpeechBubble (fala em balão), WorldPill (pílula do mundo), WorldSelector (carrossel com encaixe), WorldCard (miniatura/estado do mundo), NpcFace (rosto redondo do personagem no mapa), UiKit (peças), SheetBuilder (painéis), Places (lugares/personagens/avisos dos mundos),
                     ProgressionUi (painéis: personagem, construir, vender, encomendas, rotas, atributos, coleção),
                     GameManual (catálogo), NatureUi (coleta/níveis/refino), DevPanel (DEV),
                     WishUi (cartões de desejos, ícones e painel de vínculo), FriendUi (cartões/álbum de amigos), TrickUi (treino/lista),
                     WorldBalloon (balão do mundo: progress/ready/queued/buy/alert), PlotIndicator, StationIndicator (estações/criações), RouteIndicator (exploração), WalkIndicator (passeio no portão da Praça) — os quatro são WorldBalloon —, WorldLabel (pílula de lugar), ActionTray (bandeja de ação perto do dedo, filha da sala) e PlotTray (as bandejas da horta: sementes, cuidado, regador, foice), StationTray (estações, criações e Natureza),
                     DragGhost (gesto/ficha compartilhados com ActionTray), PetBackdrop (enquadramento do cantinho original), PetCareTray (quatro cuidados iguais + comidas em guia vertical), PetNotebook (Manual/Atributos/Coleção/Truques),
                     InventoryList (Mochila/depósitos, filtros segmentados, grade e selo Novo),
                     PetAnimator (animações do Tiro na aba Tiro), NpcPortrait (pedido/aceno nas conversas)
  scripts/util/      BuildInfo (canal prod/dev, arquivo de save), TimeText (texto de duração), Loot (sorteios com semente)
  assets/            sprites/(characters,areas,tiles,ui,fx), theme/, audio/, fonts/, icons/ (PWA)
  tests/             testes headless (excluídos do export)
```

## Onde trabalhar (guia rápido)
| Quero...                              | Vá para |
|---------------------------------------|---------|
| Novo item / receita / ajuste de números | `game/data/*.json` (sem mexer em código) |
| Nova construção, rota, pedido, capítulo ou atributo | `game/data/progression.json` (formato em `docs/PROGRESSION.md`) |
| Novo mundo (mini mundinho)            | `data/worlds.json` + `data/rooms/<id>.json` + arte (receita em `docs/WORLDS.md`; sem código) |
| Novo lugar tocável num mundo          | `places` em `worlds.json` (máx. 4 visíveis por mundo; `upgrades` = compras ali dentro) + zona/objeto com `"action": "place:<id>"` (e `label`) em `rooms/<id>.json` |
| História principal (linha da Laís)    | `quests.json` (`kind: "main"`, chapter/order, `dialogue`); `progression.json`: capítulos/rewards. Plano: `docs/plans/TASKS_QUESTLINES.md` |
| Linha de missões de um NPC (ex.: vovó) | `quests.json` com `kind: "line"`, `line`, `order`, `requirements` (quando começa); cruzamento = goal `{"type": "quest", "key": "<id>"}` |
| Missão diária / semanal               | `data/routines.json` (`goal` = contador + alvo, `rewards`, `requirements`; `count` por tipo); ações `GameState.claim_routine` |
| Desejos do Tiro / vínculo             | `data/wishes.json`, `scripts/state/wish_state.gd`, `scenes/ui/wishes_screen/` + `scripts/ui/wish_ui.gd`; `GameState.update_wishes/fulfill_wish/swap_wish`; níveis em `progression.json → bond_levels` |
| Faro do Tiro (achados, álbum, mapa rasgado) | `data/finds.json` (mundos, `guaranteed`, `table`, conjuntos), `scripts/state/find_state.gd`, `GameState.update_finds/dig/claim_find_set`, `scripts/ui/find_ui.gd`; `"dig_spots"` (pontos no chão alcançável) em `rooms/<id>.json`; montinho `DigSpot` no `RoomView`, `sniff`/`dig` no `DogWorld` |
| Passeios do Tiro (Praça)              | `data/walks.json` (tempo, `energy`, `needs`, `rewards`, `loot` com `find:<mundo>`, postal), `scripts/state/walk_state.gd`, `GameState.walk_error/start_walk/collect_walk/cancel_walk/walking`; painel `walks` (`ProgressionUi.walks_panel`), `scenes/ui/walk_result/`, tela do Tiro (`pet_screen.gd` → `AwayView`), `WalkIndicator` no `walk_marker` da sala. 7 caminhos, primeira volta, raro com garantia/consolo e `ProgressionUi.walk_diary` (Diário) |
| Amigos / visitante / presente na Casa | `data/friends.json`, `FriendState`, `GameState.friend_window/friends_present/give_friend/collect_friend_visit`, `FriendUi`; `NpcWorld.friend_id/friend_visit`, `RoomView._sync_friends`; ausência via `SaveManager` (não via timer/from_dict/troca de slot) |
| Truques / treino com Nina | `progression.json → tricks/trick_settings`, `progress.tricks/cooldowns`, `GameState.learn_trick/perform_trick` e `*_error`, `TrickUi`, `scenes/ui/trick_training/`; lugar `training` na Praça |
| Tesouro / baú da Clareira / mirtilo | `quests.json → guide_treasure` (objetivos `have` map_piece_1..4, não consomem), `progression.json → treasure` (requisitos/prêmios), `GameState.open_treasure/open_treasure_error`, `Events.treasure_opened` → `Celebration.show_treasure`; objeto `treasure_chest` (`action: "treasure"`, `requirements`, `seen_sprite`) em `rooms/nature.json`; `crops.json → blueberry` |
| NPC enfeite / que segue outro         | `npcs.json`: `"decor": true` (sem conversa/balão/lista; toque = pulinhos) e `"follow": "<npc>"` (destinos a ≤ 40 px dele); ex.: Pipoca segue a Nina |
| "Como fazer" (o que falta, 1º passo)  | `scripts/ui/task_help.gd` (`TaskHelp.describe` calcula; `TaskHelp.panel` mostra em ícones) |
| Vestir o Tiro / camadas / poses | Coleção: `UiKit.segmented` Roupas/Achados/Amigos, grade de 3 colunas; `Equip_<id>` é o quadrado tocável que veste/tira (check), origem das bloqueadas no detalhe;  `collections.json → overlay/slot`, `progress.equipped`, `GameState.equip/unequip`, `PetAnimator` + `tiro_pet/overlay_anchors.json` e `overlays/<id>/<clip>/`; `tools/outfit_extract.py` reproduz os recortes/variantes |
| Pet shop / costura / receita que entrega roupa | `progression.json → shop_items/upgrades`, `config.json → stations.sewing`, `recipes.json → output_collection`; `GameState.buy_cosmetic/buy_shop_item/cook/collect`; `ProgressionUi.petshop_panel` |
| Lendários dos passeios | `walks.json → legendary` (requisitos/chance/garantia/coleções); sorteio independente em `walk_loot`, `WalkState.pity.legendary`, contador `walk_legendary`; não substitui raro |
| Nova missão / personagem (NPC) / roupa | `quests.json` / `npcs.json` (`portrait`, `sprite_dir` com rotations/ + walk/, `services`) + mundo dele em `worlds.json` → `npcs` + ponto `npc_<id>` em `rooms/<id>.json → points` / `collections.json` |
| Requisitos de conteúdo (nível, compra, missão) | campo `"requirements"` no JSON; validados por `ProgressionState.requirement_error` (+ `bond`/`hours` em `GameState.requirement_error`; também `stats`). Recompensas `affection`/`needs` em `GameState._apply_rewards` |
| Sorteio com semente / faixas `[min, max]` | `scripts/util/loot.gd` (`Loot.pick_weighted/amount/roll`) |
| "O que dá para fazer agora" / medir o ritmo do começo | `GameState.available_actions()`; `progress.firsts` + aba **Ritmo** do `DevPanel` (todo contador passa por `GameState._count`) |
| Nova ação do jogo (ex.: plantar)      | método em `game/autoload/game_state.gd` + estado em `game/scripts/state/` |
| Novo móvel / mudar layout da casa     | `game/data/rooms/house.json` (sprite, pos, footprint, `"action": "place:<id>"`, `upgrade`) + lugar em `worlds.json` |
| Estufa (canteiros delicados)          | `config.json → farm.greenhouse_plots/greenhouse_speed` (índices a partir de `farm.plots`), `crops.json → greenhouse: "only"` ou `"any"`, `GameState.is_greenhouse_plot/usable_plot_indices/crop_plot_error`; objetos `plot_9..12` com `requirements.owned greenhouse` em `rooms/farm.json`, desenhados com `areas/farm/plot_greenhouse.png` (caixa de pedra clara com vidro, terra escura; os do sítio seguem `plot.png`) |
| Nova planta da horta / tempo / colheita | `game/data/crops.json` (tempo, itens, moedas, XP, requisitos; ícone em `items.json`); terrenos em `config.json` → `farm` |
| Produção/coleta (padrão) | Caminho principal no mapa: `StationTray` sobre `ActionTray` em modo `pick` (largura 328, quatro receitas/materiais por linha, seleção e detalhe com um `UiKit.primary`). Cabeçalho usa `SheetBuilder.station_slot_row` / `NatureUi.slot` e `SlotDot`; `LockedSlot_*`, `GatherItem_*` e `Material_*` preservados. `StationTray.recipe_detail/material_detail` mostram ingredientes tocáveis, tempo e saída/XP. `last_recipe/last_material` guardam a seleção só na sessão. Criações usam uma ração tocável; sem animais, Comprar animais. O painel completo continua em Ver tudo (`station_view`, `NatureUi.panel`), com `slot_strip`, `UiKit.list_row` e as mesmas ações do GameState. |
| Altura/arrasto do painel (Sheet)      | `scenes/ui/sheet/sheet.gd`: `Events.sheet_requested(título, conteúdo)` não mudou; o conteúdo pede altura com `content.set_meta("sheet_size", "half" \| "tall")` (`SheetBuilder.tall(...)`; sem meta = automático: altura do conteúdo se couber em 55% da tela, mínimo 30%, senão 88% com rolagem; painel preso embaixo, `offset_top`). Alça (`Handle`) e título arrastam: > 25% da altura ou > 900 px/s fecha, para cima vira alto. `sheet_close_requested` fecha na hora (`is_open()` falso, conteúdo some) e só o fundo desliza. Título = nome da coisa (item, construção), nunca "Construir"/"Mochila" genérico; `stations_view` só repete o nome da estação com mais de uma liberada |
| Fala de personagem em balão           | `scripts/ui/speech_bubble.gd` (`SpeechBubble`: balão `CARD` + rabinho + etiqueta com o nome; `label` = texto) usado por `ProgressionUi.npc_header` (retrato 96 embaixo à esquerda; `NpcPortrait` continua fora do corpo reconstruído) |
| Novo tipo de painel de lugar          | caso em `Places._panel` (`scripts/ui/places.gd`) + função que monta o painel (`SheetBuilder`/`ProgressionUi`, com `UiKit`) |
| Revelar algo aos poucos ("Novo!")     | `progression.json` → `features` (aba/seção com `requirements` e `go`); mundos, lugares e NPCs com `requirements` entram sozinhos. `GameState.new_unlocks`/`mark_seen`; tela em `scenes/ui/celebration/` |
| Regar, presente de nível, presente do dia | `GameState.water/water_error` (`config.json → farm.water`), `progression.json → level_rewards`/`daily_gift` + `settings` (welcome_*, idle_hint_*); `Events.level_up` → `Celebration.show_level`; cartão `scenes/ui/welcome_back/` (`GameState.welcome_ready_lines`, uma linha por tipo; ver a linha do `ModalCard`); dica parada em `WorldsScreen.advance_idle`; cartões modais esperam a vez em `main.gd._queue_modal` |
| Botão "Ir até lá"                     | `Events.world_requested.emit(mundo, "<lugar>" | "npc:<id>" | "buy:<construção>")`; `WorldsScreen.enter` espera a viagem antes da seta/painel e invalida destinos substituídos |
| Mudar a aba Missões / Mochila         | `scenes/ui/tasks_screen/tasks_screen.gd` (História/destino, rotinas compactas, um Pegar tudo global) / `InventoryList` via `SheetBuilder.inventory_view` (depósitos filtram, `UiKit.segmented` horizontal, grade 4, `ui:bag:<id>` marca Novo só ao abrir) e `item_detail` automático (comida usa `give_food`). `UiKit.grid_tile/collection_progress` são peças compartilhadas dos álbuns. Teste: `lists_test.gd` |
| Manual / caderninho do Tiro | `PetNotebook` (`ManualButton`): painel alto abre Manual (`ManualPanel`) por padrão, abas `UiKit.segmented` para Atributos/Coleção/Truques conforme liberação. `GameManual` mantém o catálogo derivado do Database. |
| Tela do Tiro / cuidados | `PetBackdrop` recorta a moldura do PNG original sem esticar o ambiente; `scene_rect/pet_feet` alinham Tiro/sombra/estrelas. Sem nome no topo: quatro anéis e coração/nível na mesma fileira; caderninho flutuante. `PetCareTray`: quatro `UiKit.action_tile` idênticos (Comida/Banho/Brincar/Dormir), ícones contidos e alinhados. Comida abre `FoodMenu` vertical com 5 linhas, mais usadas por `progress.stat("feed:<id>")` e desempate recente na sessão; arrastar nome rola, ícone alimenta só ao soltar na cabeça. `SheetBuilder.give_food` compartilha “Ele quer!”; `DragGhost` é comum à horta. Esponja: 800 px dentro do Tiro = um banho; bola: arremesso para cima = um play. Sono bloqueia cuidados; passeio oculta faixa e mostra AwayView. `MoodLabel`, `WishBubble`, `BondChip`, `ManualButton`, `SleepButton` preservados; SleepButton usa `Visual/Caption`. |
| Expandir o sítio com áreas fechadas  | `rooms/farm.json → regions` (polígono, cerca e compra existente que libera a área) |
| Zonas da Natureza e seus materiais | `rooms/nature.json → regions` (requirements/upgrade), `worlds.json → nature.places`, `progression.json → activities` (walk/creek/mine/crystal/meadow) |
| Coletar na Natureza e liberar vagas | `progression.json → nature_sites` (Bosque/Caverna/Prado, levels/XP, tokens level_upgrades/slot_upgrades), `nature_resources` (rotas); `GameState.start_gathering/collect_gathering` e `NatureUi.panel` |
| Comprar galinhas/vacas e variedades | `config.json → animals` (nome, preço, abrigo, sprite/escala); `GameState.buy_animal`, `animals` salvo; loja em `SheetBuilder.animal_shop` |
| Galinhas/vacas e seus produtos       | `config.json → stations` com `kind: "animal"`, `animal_capacity`; alimentação/ovos/leite em `recipes.json`, timer em `StationState` |
| Recolher/colher com animação          | `Events.items_gained(itens, moedas, origem)` → `scripts/ui/collect_fx.gd` (miniaturas ícone +N saltam na tela). No mapa, tocar em estação/criação pronta, marcador de coleta da Natureza ou planta madura recolhe direto (`RoomView._collect_station/_collect_site/harvest_plot`; o canteiro só emite `items_gained` se a colheita coube no depósito), sem abrir painel; plantar e regar também não abrem painel (bandeja de ação, linha abaixo). O que cresce/está pronto no mapa é sempre um `WorldBalloon` (`scripts/ui/world_balloon.gd`, `Node2D` que desenha em `_draw`): `state` `progress` (anel `INFO` + produto), `ready` (verde, `ui_check`, pulinho a cada `Motion.WORLD_BOUNCE`), `queued`, `buy` ("+" e preço) ou `alert` ("!"); `caption` só com `show_caption` (zoom ≥ 1,2 ou 2 s após tocar o canteiro: `PlotIndicator.reveal_caption`; "×N" quando há vários prontos). Tamanho acompanha o zoom sem mínimo: balões permanecem na própria âncora, mesmo sobrepostos; `RoomView._zoom_balloons` avisa só os balões da própria sala e `_layout_balloons` mantém `draw_offset` zerado. O seletor (`MapView`, z 6) cobre os indicadores do mundo (até z 5), abaixo do HUD (z 8). O toque usa `hit_rect` no espaço do pai (`RoomView._tap_balloon`, antes das etiquetas); balões sem texto: não crie indicador novo em `_draw` |
| Bandeja de ação (plantar/colher/regar perto do dedo) | `scripts/ui/action_tray.gd` (`ActionTray.open(room, âncora, entries, options)`: painel `PAPER` com setinha filho da `RoomView`, z 5, itens 60×72 com ícone 48, legenda e selo; `entry` = `{id, icon, caption, caption_fn, badge, error, help, highlight, keep_open, tap: Callable→String, drag: Callable(ponto da sala)→bool}`; toque = `tap`, arrastar mais de 12 px = fantasma 56 px que anda **40 px acima do dedo** e age no ponto dele a cada movimento, rola a câmera 6 px/quadro a menos de 36 px da borda, bandeja fica a 30% de opacidade e fecha se agiu em algum alvo; só uma por vez, fecha ao tocar fora (o toque é consumido: `RoomView._swallow_touch`), ao mexer na câmera (`_camera_changed`, salvo `tray_dragging`), ao abrir painel ou trocar de aba, e por `auto_close`; teste/capturas: `drag_through/tap_item/item_center`) e `scripts/ui/plot_tray.gd` (`PlotTray.seeds/care/water/sickle`: sementes = última usada primeiro, depois por tempo, bloqueadas no fim com `TaskHelp.open`; cuidado = `CareHeader` com `RingProgress`, tempo e "Regado"; regador "×N"; foice + "Tudo"; dicas de arrasto em `progress.seen["ui:tray_drag_hint"/"ui:tray_harvest_hint"]` via `hint`). `RoomView`: `plot_at` (losango do chão +20%, vence o mais perto do centro), `plot_center/plot_anchor/plot_indices/waterable_plots/ready_plots`, `plant_plot/water_plot/harvest_plot`, `plot_feedback`, `open_plot_tray(índice, planta, centralizar)`, `world_to_screen/screen_to_world`, `scroll_by`, `tray_dragging`, `close_tray`; `GameState.plant_error/harvest_error` (mesmas checagens de `plant/harvest`); `Events.plot_tray_requested(planta, índice)` (−1 = primeiro canteiro vazio compatível) vem do "Ir" (`Places.run "crop:<id>"` no Sítio) e da grade do painel Canteiros (resumo: tocar fecha o painel, leva a câmera e abre a bandeja). Estações e Natureza já usam `StationTray`: modo `pick`, `selected`, `detail: Callable(id)`, `on_select`, `badge_fn/error_fn`, ✕ e `fly_icon`; não fecha ao agir. Criações usam toque na ração, `close_after(1.5)`. Tiro reutiliza `DragGhost` (extraído de `ActionTray`), sem exigir `RoomView` |
| Reações do Tiro no mundo             | `Events.world_activity` (GameState) → `RoomView` (alvo) → `DogWorld.react_at` (animação/caminho) |
| Cor, animação ou anel de progresso da interface | `scripts/ui/palette.gd` (`Palette.*`: nada de `Color("...")` solto no código novo), `scripts/ui/motion.gd` (`Motion.press/pop_in/pop_out/slide_up/bounce/pulse/count_up/shake/float_text`; `Motion.reduced` zera os tempos), `scripts/ui/ring_progress.gd` (`RingProgress`: `progress` 0..1 + `texture`). Guia: `docs/plans/interface/01_REGRAS_E_ESTILO.md` |
| Ícone próprio de estação/lugar (`station_*`, `ui_lock`) | PNG 32 px em `ui/icons/` + campo `"icon"` em `progression.json → upgrades` e `worlds.json → places`; teste `ui_base_test.gd` impede ícone emprestado (`tab_*`, `item_carrot_snack`) nas estações |
| Capturas de toda a interface (antes/depois de mudar visual) | `tests/ui_tour.gd` (régua do plano Interface nova; NÃO é teste). Cada tela nova acrescenta a captura dela |
| Nova ferramenta de teste (dev)        | `GameState.dev_*()` (com guarda `BuildInfo.is_dev()`) + botão em `scripts/ui/dev_panel.gd` |
| Visual da interface (cores, botões, fonte) | `game/assets/theme/main_theme.tres` (variações: botões `Button`=secundário/`SecondaryButton`, `PrimaryButton`, `GhostButton`, `IconButton`, `CloseButton`, `TabButton`, `ChipButton`; painéis `CardPanel` (sem degrau), `ReadyCardPanel`, `ChipPanel`, `PillPanel`, `SheetPanel`, `TopBarPanel`; rótulos `TitleLabel` 30, `SectionLabel` 22, `SmallLabel` 18, `NumberLabel`, `BadgeLabel`, `BarLabel`, `ToastLabel`). Cores do `.tres` em decimais = `Palette` |
| Botão/peça de interface nova | Sempre no `UiKit`: `primary` (um por tela/painel), `secondary(..., small)` (listas, altura 44), `ghost`, `icon_button`/`square_button("?")`, `pill`, `lock_hint` (cadeado + motivo; bloqueio por requisito, nunca botão cinza), `lock_icon`, `slot_dot` (bolinha de produção), `list_row` (linha baixa de lista, tema `RowPanel`); `UiKit.button` já aplica `Motion.press`. Teste `ui_style_test.gd` (≤ 1 `PrimaryButton` por painel) |
| Ícone de item/necessidade/atributo    | PNG 32 px em `game/assets/sprites/ui/icons/` + campo `"icon"` no JSON (caminho em `items.json`/`needs`; nome do arquivo sem `.png` em `progression.json`, `npcs.json`, `collections.json`) |
| Armazenamento (limites e ampliações)  | `progression.json → storage` + melhorias com `storage_capacity`; `items.json → storage`; `GameState.storage_*`; plano `docs/plans/ARMAZENAMENTO.md` |
| Adicionar dado que deve ser salvo     | classe em `game/scripts/state/` (ou campo no `GameState`) + `to_dict`/`from_dict`/`reset` |
| HUD, abas e aviso (casca)             | `scripts/ui/hud.gd` (`Hud`, nó `TopBar` direto em `Main`, `mouse_filter` ignora; `refresh()` chamado pelo `main.gd` a cada `state_changed`; `LevelLabel` = número do nível no selo, `XpRing` mostra o XP, `XpBar` invisível só por compatibilidade, `CoinsLabel` conta com `Motion.count_up`, `DevButton`, `SettingsButton`, `show_level_popover()`, `coins_target()` é o destino das moedas do `CollectFx`); `scripts/ui/nav_tab.gd` (`NavTab.attach(botão)`: círculo + ícone sobem 6 px na aba ativa; `lift_node()` é o que pulsa; selos de aba em centro do ícone + (14, −20)); `scripts/ui/popover.gd` (`Popover.open(host, âncora, conteúdo)`: some em 2 s ou ao tocar fora); `main.gd._show_toast` (pílula `Toast` que desce de y −40 até 68, ou 116 com o banner de atualização; segundo aviso troca o texto e pula; "Missão concluída…" leva `ui_check`); `TabBarPanel` no tema; telas sem mundo deixam 64 px de margem em cima. Nada fixo no `Layout` além de `Screens`/`TabBar` (separação −22: a barra de abas cobre 22 px do fim das telas) |
| Fundo, enquadramento e câmera do mundo | `rooms/<id>.json`: `backdrop` (`sky`, `ground`, `ground_texture`, `texture`, `clouds`: `true`/`"mist"`/`false`, `parallax`, `horizon`), `framing` (`width`/`height`/`fit`), `initial_zoom`, `view_center`, `min_zoom`, `edge_cover` (polígono que esconde a terra nos quatro mundos externos); `WorldGround` (`scripts/ui/world_ground.gd`) tinge e repete a grama e compartilha a textura com a borda, alinhada ao mapa; `RoomView._setup_backdrop/_layout_backdrop/_initial_zoom/_min_zoom/_tween_camera/zoom_to/recenter/_lift_for_sheet/_nudge_labels`; constantes de câmera no topo do `room.gd`, tempos `Motion.CAMERA/SETTLE`; PNG do mapa precisa de fundo transparente (`Invoke-ClearCorner`). Detalhes em `docs/WORLDS.md` |
| Barra do mundo (pílula, Lugares, rostos) | `WorldsScreen._build_world_bar` (nós `WorldBar`, `MapButton` = `WorldPill`, `PlacesButton` = `UiKit.icon_button`, `WorldTitle` escondido, `NpcRow` = coluna de `NpcFace`; `Places.npc_badge` dá o selo "!"/check); a pílula abre o seletor (`show_map`), sem mover os rostos; `toast_top()` preserva os controles |
| Seletor e viagem entre mundos | `WorldSelector` (`MapView`): cartões `WorldCard_<mundo>` 240×330, laterais centralizam, central viaja, arrasto encaixa; `show_map/is_map_open/close_map`; `Places.unlock_hint` mostra "Abre no capítulo N" (exceção do `texts_test`) e o nome da história/missão (pedido do Vitor); `worlds.json → icon` alimenta pílula/cartão. `WorldTransition` coordena `CloudCover` no canvas da tela (z 5, HUD z 8), duas coberturas arredondadas `PAPER` 0,22+0,22 s; `Motion.reduced` troca na hora. Último mundo só nesta sessão |
| Cartão de comemoração (nível, capítulo, tesouro, passeio, boas-vindas...) | `scripts/ui/modal_card.gd` (`ModalCard.open(host, opções)` troca o cartão do `CanvasLayer` e devolve o cartão: fundo `Palette.DIM` (fade 0,2 s), cartão `PAPER` 320 com cantos 22 que salta de 0,7, **fita** (`title`, `ribbon` cor, `NumberLabel` 26), ícone grande 64–96 com **raios** (`ui/fx/rays.png`, 20°/s, alfa 0,6) ou `hero`; opções `scroll_name`, `separation`, `confetti`, `haptic` ("big"/"success"), `animate`; métodos `add/add_text/add_chips/add_primary/add_ghost/reveal/fire_confetti`; `reveal` faz os filhos entrarem um por um (`pop_in`, 80 ms) e "+N"/"×N" contam com `Motion.count_up`; um `primary` + `ghost` opcional por cartão; com `Motion.reduced` tudo aparece na hora e sem confete). Confete = `CPUParticles2D` `Confetti` (40 retângulos 4×6, 1,6 s, uma vez; só nível/capítulo/tesouro/vínculo/raro). `Celebration.show_*` (`scenes/ui/celebration/`, `CelebrationScroll`), `WalkResult` (`WalkResultScroll`, `CloseResult`, `FirstTime`, `RareStar`, `Found_<item>`, `Equip_<roupa>`) e `WelcomeBack` (`WelcomeScroll`, `DailyGift`, `Line_dig`/`Line_ready_<mundo>`/`Line_walk`/`Line_friend_visit`) são só montadores do `ModalCard`; a fila `main.gd._queue_modal` não mudou. `GameState.welcome_ready_lines` devolve **uma linha por tipo**: `dig` (achados juntos, `worlds`), `ready` (canteiros + estações + Natureza do mesmo mundo, `icons`; texto "N prontos no Sítio" usa `worlds.json → in_name`), `walk`, `friend_visit`. Teste: `festa_test.gd` (`ModalCard` não pode ser referenciado por tipo em teste `-s`: carrega por `find_child`/`get`) |
| Vibração e preferências do aparelho ("Vibrar", "Menos animação") | `scripts/ui/haptics.gd` (`Haptics.tap()` 12 ms, `success()` 30, `big()` 60, `error()` 2×20; `Haptics.enabled`; `Haptics.calls` guarda o que foi pedido, para teste; usa `Input.vibrate_handheld`). Ligações: `ActionTray._act_here` (tap por canteiro do arrasto), `CollectFx._on_items_gained` (success ao colher/pegar), `ModalCard` (`haptic`), `Motion.shake` (error). Preferências no painel de configurações (`SettingsPanel._toggle_row`, nós `VibrateToggle`/`ReducedMotionToggle`, botões `NotebookTab_on/off`) → `SaveManager.set_vibrate/set_reduced_motion` (`vibrate_enabled`, `reduced_motion`) gravam `vibrate`/`reduced_motion` em **`settings.json`** (preferência do aparelho, vale para todos os saves; NÃO vai no save, `SAVE_VERSION` 12) e aplicam em `Haptics.enabled`/`Motion.reduced` ao abrir o jogo |
| Configurações / vários saves          | Engrenagem do HUD (`Hud.settings_button`, nome `SettingsButton`) → `scripts/ui/settings_panel.gd` (a versão do jogo fica no rodapé, `VersionLabel`; tocar nela força a atualização). Saves 1..5 em `SaveManager` (`list_slots/switch_slot/new_slot/delete_slot/set_default_slot`; slot 1 = `save.json`/`save_dev.json`, outros `save_N.json`; padrão em `settings.json`); trocar de save recarrega a cena |
| Mudar formato do save                 | `game/autoload/save_manager.gd` (`SAVE_VERSION` + `_migrate`) |
| Comunicar sistemas desacoplados       | sinal novo em `game/autoload/events.gd` |
| Criar tela/menu                       | `game/scenes/ui/<nome>/` |
| Criar personagem/inimigo/item         | `game/scenes/entities/<nome>/` |
| Criar fase                            | `game/scenes/levels/<nome>/` |
| Adicionar sprite do PixelLab          | `game/assets/sprites/<categoria>/` (ver `docs/ART_PIPELINE.md`) |
| Mudar resolução/orientação            | `game/project.godot` `[display]` + `progressive_web_app/orientation` em `game/export_presets.cfg` |
| Mudar build/deploy                    | `tools/export_web.ps1`, `.github/workflows/deploy.yml`, `docs/DEPLOY.md` |

## Regras de arquitetura
- **História e linhas de NPC:** a Laís (casa) conduz a história (`kind: "main"`, capítulos); cada NPC pode ter uma linha (`kind: "line"`). Um passo ativo **por linha**, em paralelo (`ProgressionState.active_steps`), derivado de `progress.claimed_quests`; `progress.steps[linha]` guarda a base dos objetivos `fresh`. Objetivos `talk:<npc>` (tocar no NPC → `Places.open_npc` → `GameState.talk_to`), `open:<aba|mundo>` (`GameState.note_screen_opened`) e `quest` (cruzamento entre linhas). Save v11 recomeçou do zero (história refeita). `Places.goal_target` resolve o botão Ir.
- **Disco só via `SaveManager`.** Nenhum outro script usa `FileAccess` para save.
- **Estado persistente só em `GameState`** (e nas classes de `scripts/state/` que ele guarda, ex.:
  `GameState.progress`). Cenas leem o estado e o alteram **só por métodos do `GameState`**.
- **Ações passam pelo `GameState`** (feed, cook, plant, buy_upgrade, claim_quest...): validam,
  alteram e emitem `state_changed`; o `SaveManager` salva automaticamente a cada mudança.
  Convenção: ação devolve `""` se deu certo ou o motivo da falha (texto pronto para toast), e tem
  um `*_error()` igual que a UI usa para desabilitar botões.
- **Classes de estado** (`scripts/state/`): só dados + consultas puras + `to_dict`/`from_dict`.
  O estado não depende da UI (ex.: texto de tempo vem de `TimeText`, não do `SheetBuilder`).
- **Apresentação de NPC:** `npcs.json → introduction` (falas) abre na primeira conversa;
  conclusão em `progress.seen["npc_intro:<id>"]`. Laís usa a cena de chegada (`intro`).
  Badge no Mapa prioriza missão pronta (✓) sobre nova (!), só em NPCs/mundos abertos.
  `portrait_animations.request/complete` define pastas de quadros do retrato; `NpcPortrait`
  fica fora do corpo reconstruído da conversa para preservar o aceno ao receber a missão.
- **Sinais globais só em `Events`.** Sinais locais ficam na cena.
- **Desejos e vínculo:** só após `lais_bed`, mesmo com afeto alto. `GameState.wishes` salva espaços/base/timestamps/último id e contagem;
  sorteio sem ids repetidos, necessidade baixa primeiro e especial elegível com vínculo 3. `feed` direto não cumpre desejo;
  `fulfill_wish` e o "Ele quer!" cumprem, alimentam uma vez e recompensam. A guia de comida do Tiro e o seletor compartilham `SheetBuilder.give_food` (toque/arrasto); `feed` direto continua só alimentando. Reposição 60 s nos 3 primeiros,
  depois 600 s; trocar espera 300 s, sem custo. `claimed_bond_level` evita presentes repetidos; `Events.bond_up` entra na fila modal.
  Balão some dormindo; toque no Tiro com balão abre Desejos. `dev_add_affection/dev_refresh_wishes` têm guarda DEV.
- **Passeios:** a Praça (`park`) abre com a primeira encomenda (`main_2_order`). `GameState.walk_state` guarda um passeio
  por vez (`current` com `ready_at` Unix, `seed`); enquanto `walking()` o Tiro não existe nas salas (`RoomView._sync_dog`),
  `feed/play/bathe/pet/dormir/cavar` são bloqueados (`away_text`) e desejos de comida mostram "Quando ele voltar".
  `start_walk` gasta energia (precisa `energy + 5`); `collect_walk` (sorteio estável pela semente, checa `storage_error`)
  aplica `rewards`/`needs`, conta `walk`, `walk:<id>`, `walk_item`, `walk_item:<item>` e `find_item:<item>` e emite `Events.walk_collected`;
  `cancel_walk` devolve a energia sem prêmio. `loot.first` soma materiais só na primeira coleta; `loot.rare` define chance/garantia por caminho/apetrecho/consolo. Histórico e `pity` só mudam ao recolher; raro novo conta `walk_rare`/`walk_rare:<id>`, duplicado vira moedas/material. `walk_lock_error` exclui horas e `walk_hours_error` verifica início (17h inclusivo, 21h exclusivo no Pôr do sol). Diário após 3 voltas; materiais `trail` sem depósito, `note` no detalhe; Coleção mostra silhuetas dos raros. `walk_unlock_keys` entra no Novo! com postal e Ir, anunciado na fila após o cartão de volta. Testes: `tests/park_test.gd` e `tests/walks_test.gd`; capturas: `tests/walks_shots.gd`.
- **Amigos (Etapa 09):** Pipoca usa arte/IA existentes e segue Nina; toque vira amizade após receber `nina_sewing` (missão `nina_pipoca` ativa, sem ciclo). Visitante não-always na Praça em `points.friend_1`; rotação determinística dos elegíveis por bloco local de 3 h, fixada na janela. `FriendState.window_index` é o maior bloco observado: atrasar relógio/fuso não reabre janelas; avançar permite a próxima. Um petisco por amigo/bloco; corações em 1/3/6, `claimed_hearts` e `visit_gift` persistidos; `friend_level` é soma recalculada (inclusive ao carregar). Pipoca ♥2 soma um sorteio em `walk_loot`, junto à bolsinha, sem deslocar raro/lendário. Visita exige ♥3 e ausência contínua de 8 h após melhor amizade/última visita; só `SaveManager` processa primeira abertura/retorno do segundo plano. `last_session_active` nas configurações é compartilhado entre slots; heartbeat de 60 s limita ausência após crash. `from_dict`, timer e troca de slot não criam visitas. Presentes sorteados ficam pendentes até caber; falha/reabrir não ressorteia nem consome. Casa reutiliza `NpcWorld` perto do Tiro; boas-vindas → Ver apenas aponta, toque recebe com CollectFx/aceno. Coleção → Amigos usa silhuetas; bandana caramelo fica na Coleção sem overlay (não pode vestir roupa invisível). Nenhum reset/SAVE_VERSION novo.
- **Truques (Etapa 10):** `progress.tricks` guarda aprendidos, `cooldowns["trick:<id>"]` usa Unix; sem migração/reset. Sequência paw/talk/roll/jump/spin com requisitos de Nina/vínculo nos dados. Minijogo no Sheet, três acertos, tentativas sem custo; progresso da tentativa é local, aprendizado só via `GameState.learn_trick`. Mostrar aplica felicidade/afeto e contadores uma vez por recarga, bloqueado dormindo/passeando. `Events.trick_learned` entra na fila modal; `PetAnimator` reutiliza give_paw/bark/roll_over/happy_jump/chase_tail e conserva as regras das três roupas. `dev_force_marker` só em DEV; teste/capturas em `tricks_test.gd`/`tricks_shots.gd`.
- **Tesouro (Etapa 11):** `guide_treasure` (Guia, ordem 50) usa objetivos `have` nos quatro pedaços (não consumidos; `Database.item_sources` aponta onde cavar). `open_treasure` só abre uma vez (`progress.seen["treasure_opened"]`, contador `treasure`), aplica `progression.json → treasure.rewards` (moedas, `explorer_hat`, `unlocks crop:blueberry`, parafusos) e emite `Events.treasure_opened` (fila modal). Objetos de sala aceitam `requirements` (invisível/intocável/sem footprint até valer) e `seen_sprite` (troca o desenho por marca em `progress.seen`). Mirtilo exige `guide_treasure` + `stats.treasure`. Sem `SAVE_VERSION` novo. Teste: `treasure_test.gd`.
- **Roupas (Etapa 08):** `progress.equipped` salva head/neck/body (strings vazias em saves anteriores); equipar exige posse + overlay, trocar igual não repete contador. Camadas corpo → pescoço → cabeça em `PetAnimator`, canvas 256×216; `overlay_anchors.json` inclui sono e exclui acrobacias. Variantes por quadro em `overlays/<id>/<clip>/`; cache máximo 48. Retratos de Desejos/boas-vindas usam `PetAnimator.portrait`. JSON das âncoras incluído explicitamente no preset Web. Costura usa a estação existente com `output_collection` (sem output/qty): valida posse/fila global, entrega coleção e conta sew/produce uma vez; evento cosmetic_received entra na fila modal e não vira inventário. `Database.recipe_output` e item_name/item_icon resolvem ambos os tipos; `station_upgrade` associa sewing a sewing_table. Pet shop compra quatro roupas/ração/bolsinha; sem diária de costura. `flower_clip` é id legado dos óculos escuros, preservando saves. Lendário tem sorteio/pity independente e soma ao raro; cancelar/armazenamento cheio não gasta garantias.
- **Revelar aos poucos:** nada aparece antes da história apresentar (Mochila, diárias, semanais, atributos,
  Vila, portão, personagens). Ao abrir, a tela "Novo!" mostra ícone + Ir uma vez (`ProgressionState.seen`).
  O "Ir" mostra uma seta sobre o objeto (`RoomView.point_at` + `Places.highlight_action`) e abre o painel em seguida.
  Exceção de consulta: o **Manual** na tela Tiro mostra o catálogo completo desde o começo,
  conforme pedido do Vitor. Não altera progresso; atalhos respeitam requisitos de mundos/lugares
  e estações não compradas levam à compra. Ingredientes abrem sua origem no próprio manual.
- **Navegação intuitiva:** cada função mora num lugar de um mundo (`worlds.json`); toda tela que
  sugere algo (Missões, Mochila, personagem) tem botão que leva até lá (`Events.world_requested`).
  Nada de menus genéricos escondidos: um lugar novo entra no mundo onde faria sentido.
- **Versão dev x publicada:** `BuildInfo.is_dev()` (canal em `data/version.json`; o executável do
  Godot é sempre dev). A dev usa `user://save_dev.json`, mostra o selo **DEV** e libera as
  ferramentas de teste. Toda ferramenta `GameState.dev_*` começa com a guarda `if not BuildInfo.is_dev(): return`.
- Export **Web single-thread** e renderer **Compatibility**: não ligar threads (GitHub Pages
  não envia headers COOP/COEP) nem usar recursos exclusivos de Forward+/Mobile.
- Pensar **mobile primeiro**: celular em pé (base 360×780, `stretch=expand`), só toque,
  alvos grandes, ações perto do polegar, pouca memória. **Nada de botões direcionais/joystick.**
- **Tempo real:** timers (plantação, fogão, rotas, recargas) e necessidades guardam timestamps Unix,
  nunca contadores por frame, para continuarem com o app fechado.
- **Conteúdo orientado a dados:** itens, receitas, plantas, construções, missões, NPCs e números de
  balanceamento ficam em `game/data/*.json` (lidos pelo `Database`); o código dos sistemas não tem
  conteúdo fixo. O preset Web inclui `data/*.json` via `include_filter` — novos tipos de arquivo
  não-recurso precisam ser adicionados lá.
  Criações usam o mesmo sistema de estações: `kind: "animal"`, `action_label`, `queue_label`,
  `recipe_label` e `instruction` em `config.json`; entrada = comida, saída = ovos/leite.
  `GameState.cook_error/cook` valida/consome uma vez; `collect` só entrega lotes prontos,
  sem duplicar. `GameState.animals` guarda quantidade por variedade comprada; abrigo com `gift_animal` entrega uma unidade da variedade ao adquirir, uma vez só.
  `requirements.produced` libera variedades pela quantidade já recolhida (contador `produce:<item>`). Alimentação consome/produz por animal; lote salva `qty` ao alimentar,
  então novas compras não alteram produção já iniciada. Save v7 preserva os dois animais
  dos abrigos comprados em saves sem `animals`; filas antigas mantêm rendimento original.
- **Ambientes (salas):** fundo vazio (piso + paredes) + cada móvel como sprite separado, tudo
  descrito em `game/data/rooms/<id>.json`. Coordenadas em pixels do fundo; `pos` = meio da base
  do sprite (usado na ordenação por Y); `footprint` = polígono no chão que bloqueia o caminho;
  `zones` = partes tocáveis do fundo (ex.: porta); `"slice": true` = peça recortada do fundo
  (ex.: ilha), fatiada em colunas para o Tiro passar atrás/na frente, sem toque;
  `"station"` + `"busy_frames"` (pasta de PNGs) = móvel que anima enquanto a estação produz
  (ex.: fogão cozinhando). Quadros de animação usam o MESMO recorte da imagem base.
  `"upgrade": "<id>"` = móvel só aparece depois de comprado (antes: marcador "+" que abre a compra).
  `"action"`: `"place:<id>"` (lugar do mundo em `worlds.json`), `"npc:<id>"` ou `"plot"`; `"label"` +
  `"label_pos"` = etiqueta flutuante mostrando que dá para tocar. Sala sem `"floor"` = só toques.
  `"obstacles"` = lista de `{ "id", "polygon" }` para bloquear elementos já desenhados no fundo;
  essas áreas são independentes das `zones` tocáveis. `"navigation_margin"` = folga em pixels
  nos cantos da célula (padrão 4; sítio/vila usam 8). Canteiros também têm `footprint`.
  `"dog_scale"` = escala do Tiro, sombra e área de toque por sala (padrão 1; sítio/vila usam 0,5).
  `"regions"` = áreas cercadas com `id`, `polygon`, `gate` (2 pontos), `upgrade`, `label`,
  `label_pos` e `locked_label: true`. Até comprar, bloqueiam caminho e toque abre a compra.
  Objetos da área usam `"region"` para esconder o "+" enquanto a área está fechada; após
  abrir, compras internas pendentes mostram "+". A compra revela o sprite,
  tira a cerca e atualiza a navegação; o save continua usando a construção já adquirida.
  Alternativa: `regions[].requirements` abre automaticamente por capítulo/atributo/ferramenta;
  `action` abre o painel da zona fechada. RoomView observa mudança de requisito e recalcula
  o chão; etiquetas com `requirements`/`locked_label` alternam entre nome e bloqueio.
  Natureza é um mundo próprio, aberto no capítulo 3. `route_group` em objetos associa
  `RouteIndicator` ao grupo de exploração e mostra tempo/Recolher no destino.
  Natureza usa cenário contínuo 512×384 (sala com `"region_shade": false`: as áreas fechadas não escurecem o chão, só cerca e balão "+"), com obstáculos de rio/árvores/rochas no fundo.
  Bosque/Caverna/Prado (`trees`/`rocks`/`fibers`) usam painel `nature:<grupos>` e aliases
  `routes:<grupo>`. Desbloqueio inicial é compra; depois XP de uso libera materiais/vagas.
  `nature_sites.levels` define xp total/label/materials/slots e `xp_per_collection` a recompensa.
  `progress.nature_xp` é persistente; nature_info/nature_level consultam XP + abertura inicial.
  Primeira coleta dá 10 XP somente ao recolher; locais têm XP independente. Snapshot de XP
  no lote mantém recompensa após balanceamentos; coletar duas vezes não duplica XP/produtos.
  Níveis 2/3 liberam espaços 2/3 automaticamente. Tokens level_upgrades/slot_upgrades em
  owned preservam requirements; metadata nature_unlock impede comprar marcos de XP.
  `start_next_gathering` inicia na primeira vaga livre; até três tarefas simultâneas por local.
  NatureUi mostra barra, próximo marco, coletas restantes e cadeia no ?. Atributos do Tiro
  também mostra as três regiões. Refinar lista receitas e leva às estações existentes.
  Save v10 converte ferramentas, níveis/vagas comprados e uso anterior em XP equivalente;
  nature_levels_version 2 impede conversão repetida. Moedas, missões e coletas são preservadas.
  Save v8 move activity antiga para vaga 1; pomar mantém API global. Ir preserva a rota exata
  das missões; route_markers.site mostra tempo/prontos e route_level a ampliação exigida.
  `"initial_zoom"`/`"view_center"` definem o enquadramento inicial de mapas maiores; `"framing"` (`width` padrão, `height`, `fit`) escolhe o zoom quando não há `initial_zoom`, e `"min_zoom"` (padrão: o menor entre a sala inteira e a abertura) deixa afastar até ver tudo (máx. 2,0).
  O mundo ocupa a tela toda (HUD e `WorldBar` flutuam por cima): `"backdrop"` (`sky` degradê, `ground`, `ground_texture` grama repetível opcional, `texture` faixa de paisagem, `clouds` `true`/`"mist"`/`false`, `parallax`, `horizon`) monta céu/chão/paisagem/nuvens atrás da maquete (nó `Backdrop`; sem ele a sala fica com a cor escura antiga). `WorldGround` ajusta o brilho da grama à cor do chão, acompanha a câmera e compartilha a textura/UV com `"edge_cover"`, que cobre toda a terra lateral dos quatro mapas externos. Nuvens desligadas nos mundos atuais; Casa mantém chão liso e enquadramento pela largura. Os PNGs dos mapas têm fundo transparente. Câmera: arrasto elástico (48 px) e com inércia, duplo toque em área vazia (zoom 1,6 ↔ enquadramento), `zoom_to`/`recenter` animados, `RecenterButton` quando longe do enquadramento, botões +/− escondidos, painel aberto por objeto que ficaria atrás dele sobe a câmera, etiquetas e balões fixos no mapa (arrastar a câmera não os move). O aviso usa `WorldsScreen.toast_top()` para ficar abaixo da pílula e dos rostos. Ver `docs/WORLDS.md`.
  O enquadramento inicial só vale com a sala já com tamanho: `RoomView._framed` fica falso até
  `_show_whole_room` rodar com `size > 0` (senão `_on_resized` repete); sem isso a Casa abria cortada.
  `"approach"` é o ponto seguro para o Tiro se aproximar de um objeto/estação ao reagir.
  `"z_index"` (padrão 0) coloca objetos apoiados em móveis acima das fatias, como o liquidificador sobre a ilha.
  `"station"` também detecta produção pronta, mesmo sem `busy_frames`.
  `StationIndicator` (balão) mostra produto, anel de tempo e "×N" sobre a estação. `animal_idle: true` dá movimento
  leve ao sprite; `decoration: true` esconde marcadores de compra duplicados dos animais.
  `animal_station`/`animal_slot` vinculam o sprite a uma vaga da criação: só aparece e
  bloqueia o chão se houver animal comprado; a variedade fornece textura/escala do mapa.
  `scale` ajusta o tamanho de objetos (galinhas 0,6); toque considera essa escala.
  Etiquetas (`WorldLabel`, pílula `PAPER` com ícone do lugar): fixas no `label_pos` do mapa e visíveis em qualquer zoom (nada de empurrar para dentro da tela ao mexer a câmera); as "importantes" (lugar com `Places.place_alert`, compra disponível, passo de missão apontando, personagem com missão/aviso) ganham borda na cor do mundo. Só `detail_label` (aparece a partir do zoom 0,9) e `overview_label` (ex.: "Animais", nome do conjunto, só abaixo de 0,9) trocam com o zoom. Regiões fechadas mostram cadeado + nome no **centro** do polígono (`label_pos` = centroide; o balão `buy` com o preço fica logo acima, na mesma posição).
  Moinho/queijaria têm lugares próprios `hidden` para o toque direto, além do agrupamento
  Produção. `Database.place_with_panel` prioriza painel exato antes dos agrupados.
  `"plot": N` = canteiro N da horta (estado em `GameState.plots`; broto/planta madura por cima).
  `GameState.unlocked_plots` guarda os terrenos comprados em ordem fixa; `buy_plot` valida a compra.
  `PlotIndicator` desenha ícone, tempo e barra sobre a planta; `SheetBuilder` monta os painéis do sítio.
  NPCs do mundo (`worlds.json → npcs`) andam na sala que tiver o ponto `npc_<id>` (`NpcWorld`, mesma grade do Tiro,
  escala `dog_scale`); balão `Places.npc_badge`; `point_at("npc:<id>")` aponta para ele. Antes da escritura,
  a vovó empresta canteiros: `config.json → farm.lent_plots` (`count` + `requirements`).
  O "+" de compra só aparece quando os `requirements` da construção já valem (revelar aos poucos).
  O Tiro só aparece na sala que tiver o ponto `dog_start`. O piso vira uma grade `AStarGrid2D` (8 px)
  e o Tiro anda por ela, sorteando apenas destinos alcançáveis. Sem tigela/sofá no mapa,
  ele passeia e dorme no próprio chão. Para posicionar móveis, gere prévias com `tools/pixel_tools.ps1`.
  Reações a colheita/coleta/compra chegam por `Events.world_activity`; não alteram necessidades
  nem acordam o Tiro. Caminhos são interrompidos/recalculados quando a navegação muda.
- **Toque:** a sala trata toque curto = clique (teste por pixel opaco do sprite) e arrastar =
  câmera. Eventos de toque chegam como mouse (`emulate_mouse_from_touch`): trate `InputEventMouse*`.
- **Estação tocada no mapa:** `RoomView._on_object_tapped` pega os prontos e abre `open_station_tray`
  (`StationTray`), usando `station` ou `animal_station` do sprite. `open_nature_tray` atende locais abertos.
  `Places.run` usa bandejas para Lugares e receitas com foco; `Places.open` mantém a consulta em painel,
  também acessível em Ver tudo. Compra/local fechado continuam em painel. `station_slot_row` e `NatureUi.slot`
  são compartilhados pela bandeja e pelo painel; o painel de consulta ainda aceita `sheet_size: half`.

## Convenções
- Arquivos e pastas em `snake_case`; `class_name` em `PascalCase`; GDScript **sempre tipado**.
- Cena e script com o mesmo nome, na mesma pasta (`player/player.tscn` + `player/player.gd`).
- Nós acessados por código usam nome único (`%Nome`).
- Comentários e docs em português.
- JSON de conteúdo: 2 espaços; listas de coordenadas numa linha só (`[[45, 284], [336, 138]]`).
- Commitar os arquivos `.uid` e `.import` gerados pelo Godot; nunca commitar `.godot/` ou `build/`.
- **Visual e simples:** ícone + número em vez de frase (`ProgressionUi.goal_row`, `reward_chips`, `item_chip`);
  ingrediente que falta é chip tocável (abre o "Como fazer"); bloqueio = botão desabilitado + "?". Uma linha de texto no máximo.
  Nas missões, mostre também uma instrução breve da ação: `goals[].label` na História
  e `description` nas diárias/semanais. Pode quebrar a frase no celular; não truncar o objetivo.
  Verbos: Colher, Pegar, Cozinhar, Fazer, Buscar, Ir (glossário em docs/GAME_DESIGN.md).
- Ao mudar estrutura ou arquitetura, **atualize este arquivo (e o `AGENTS.md`) e o doc relevante em `docs/`**.

## Comandos
```powershell
# Godot (caminho atual; pode ser sobrescrito com $env:GODOT_BIN)
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

powershell -ExecutionPolicy Bypass -File tools\export_web.ps1   # build Web: prod em build/web, dev em build/web/dev
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1  # http://localhost:8000 (dev: /dev/)
& $env:GODOT_BIN --headless --path game --quit-after 60         # checar erros de script
& $env:GODOT_BIN --path game --resolution 360x780 -s ../tools/screenshot.gd  # PNGs em build/screenshots/

# Testes (rodar todos antes de commitar; cada um imprime "... TEST: PASS")
& $env:GODOT_BIN --headless --path game -s res://tests/farm_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/progression_test.gd   # inclui campanha simulada do zero ao fim
& $env:GODOT_BIN --headless --path game -s res://tests/dev_tools_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/dev_tools_test.gd -- --prod   # ferramentas desligadas na prod
& $env:GODOT_BIN --headless --path game -s res://tests/tasks_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/content_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/navigation_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/manual_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/world_life_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/animals_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/nature_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/worlds_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/wishes_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/finds_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/park_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/tricks_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/treasure_test.gd
& $env:GODOT_BIN --headless --path game -s res://tests/ui_base_test.gd       # Palette, Motion, RingProgress, ícones das estações
& $env:GODOT_BIN --headless --path game -s res://tests/ui_style_test.gd      # tema (cartão sem degrau), peças do UiKit, um botão principal por painel, cadeado
& $env:GODOT_BIN --headless --path game -s res://tests/sheet_test.gd         # Sheet: alturas (automática/half/tall), fechar na hora, arrastar, título único, bolinhas e linhas
& $env:GODOT_BIN --headless --path game -s res://tests/hud_test.gd           # HUD flutuante, moedas que contam, abas ativas, balão do nível, aviso
& $env:GODOT_BIN --headless --path game -s res://tests/world_view_test.gd    # fundo cobre a tela, enquadramento, câmera (inércia, duplo toque, elástico), +/− fora, barra do mundo, etiquetas
& $env:GODOT_BIN --headless --path game -s res://tests/world_selector_test.gd # carrossel, retomada da aba, bloqueios, gestos, transição e destino do Ir
& $env:GODOT_BIN --headless --path game -s res://tests/balloon_test.gd        # balões do mundo (progress/ready, tamanho de tela, toque) e etiquetas por zoom/primeira visita
& $env:GODOT_BIN --headless --path game -s res://tests/tray_test.gd           # bandeja da horta: plantar/colher/regar tocando e arrastando, bloqueios, fechar, dica, "Ir" e resumo
& $env:GODOT_BIN --headless --path game -s res://tests/station_tray_test.gd   # receitas, ingredientes, filas, criações, Natureza e atalhos
& $env:GODOT_BIN --headless --path game -s res://tests/lists_test.gd          # listas compactas, prêmios, filtros e vestir/tirar
& $env:GODOT_BIN --headless --path game -s res://tests/texts_test.gd          # glossário: nenhuma palavra proibida nos textos visíveis (lista: tools/list_texts.ps1 → build/texts.csv)
& $env:GODOT_BIN --headless --path game -s res://tests/festa_test.gd          # ModalCard, confete, números que contam, Haptics, Vibrar/Menos animação em settings.json e boas-vindas agrupado
& $env:GODOT_BIN --headless --path game -s res://tests/pet_care_test.gd       # comida/banho/bola, consumo único, sono/passeio/desejo, guia vertical e geometria
# Ou rode toda a suíte: powershell -File tools/test_all.ps1
# Capturas das telas: rode sem --headless, com --resolution 360x780 e "-- --screenshots"
# Tour de capturas da interface (72 PNGs em build/screenshots/<pasta>/; não grava o save):
& $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --out=etapaNN_antes

# Teste de TOQUE real (Chrome headless em modo celular): exporte, rode serve_local.ps1 e então
powershell -ExecutionPolicy Bypass -File tools\touch_test.ps1 [-Url http://localhost:8000/dev/] [-Steps roteiro.json]  # tap/drag/pinch/ghost_drag/shot
```
Deploy: `git push` na `main` → GitHub Actions → GitHub Pages (prod em `/`, dev em `/dev/`).
