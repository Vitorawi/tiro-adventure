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
- Etapa 08 concluída: vestir (3 slots), pet shop/costura e dois lendários Bob Esponja; ver `docs/PROGRESSION.md` e `docs/ART_PIPELINE.md`. Próxima: Etapa 09.

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
tools/               export_web.ps1 (prod + dev), serve_local.ps1, touch_test.ps1, screenshot.gd, pixel_tools.ps1
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
                       worlds.json (mundos: lugares, personagens, requisitos)
                       rooms/<id>.json (cena de cada mundo: fundo, móveis, zonas tocáveis), version.json (versão + canal prod/dev, gravado no deploy)
  scenes/            cenas, uma pasta por cena (.tscn + .gd juntos)
    main/            casca: barra superior (selo DEV), abas Tiro/Mapa/Missões/Mochila, Sheet, toast
    ui/pet_screen/   Tela do Pet (Tiro grande, necessidades, ações)
    ui/wishes_screen/  aba Desejos: até 3 pedidos, progresso, Dar/Receber, Ir/?, trocar e vínculo
    ui/worlds_screen/  aba Mapa: lista de mundos + mundo atual (cabeçalho com Mapa, Lugares e personagens)
    ui/tasks_screen/   aba Missões (História: um passo por vez, visual; Diárias; Semanais; botões "Ir" e "?")
    ui/celebration/  comemoração de capítulo e de nível acima do Sheet
    ui/walk_result/  cartão "Volta do passeio" (postal, achados, moedas, vínculo)
    ui/welcome_back/ cartão "que bom que você voltou" (presente do dia + o que ficou pronto)
    ui/intro/        chegada da Laís com o Tiro (falas em npcs.json; uma vez por save)
    ui/bag_screen/     aba Mochila (itens por categoria; detalhe: para que serve, onde usar, vender)
    ui/sheet/        painel inferior genérico (menus de objetos)
    levels/room/     RoomView genérico (`room_id`, `world_id`): monta data/rooms/<id>.json (casa, sítio, vila), canteiros, etiquetas, navegação, toque, câmera
    entities/dog_world/  Tiro pequeno com IA autônoma (anda pelo caminho calculado)
    entities/npc_world/  NPC pequeno (Laís, vovó Bloblo) que passeia perto de casa, com balão "!"/"✓"
  scripts/state/     DogState, Inventory, StationState, ProgressionState, WishState, FindState, WalkState (dados + to_dict/from_dict)
  scripts/ui/        UiKit (peças), SheetBuilder (painéis), Places (lugares/personagens/avisos dos mundos),
                     ProgressionUi (painéis: personagem, construir, vender, encomendas, rotas, atributos, coleção),
                     GameManual (catálogo), NatureUi (coleta/níveis/refino), DevPanel (DEV),
                     WishUi (cartões de desejos, ícones e painel de vínculo),
                     PlotIndicator, StationIndicator (estações/criações), RouteIndicator (exploração), WalkIndicator (passeio no portão da Praça),
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
| NPC enfeite / que segue outro         | `npcs.json`: `"decor": true` (sem conversa/balão/lista; toque = pulinhos) e `"follow": "<npc>"` (destinos a ≤ 40 px dele); ex.: Pipoca segue a Nina |
| "Como fazer" (o que falta, 1º passo)  | `scripts/ui/task_help.gd` (`TaskHelp.describe` calcula; `TaskHelp.panel` mostra em ícones) |
| Vestir o Tiro / camadas / poses | `collections.json → overlay/slot`, `progress.equipped`, `GameState.equip/unequip`, `PetAnimator` + `tiro_pet/overlay_anchors.json` e `overlays/<id>/<clip>/`; `tools/outfit_extract.py` reproduz os recortes/variantes |
| Pet shop / costura / receita que entrega roupa | `progression.json → shop_items/upgrades`, `config.json → stations.sewing`, `recipes.json → output_collection`; `GameState.buy_cosmetic/buy_shop_item/cook/collect`; `ProgressionUi.petshop_panel` |
| Lendários dos passeios | `walks.json → legendary` (requisitos/chance/garantia/coleções); sorteio independente em `walk_loot`, `WalkState.pity.legendary`, contador `walk_legendary`; não substitui raro |
| Nova missão / personagem (NPC) / roupa | `quests.json` / `npcs.json` (`portrait`, `sprite_dir` com rotations/ + walk/, `services`) + mundo dele em `worlds.json` → `npcs` + ponto `npc_<id>` em `rooms/<id>.json → points` / `collections.json` |
| Requisitos de conteúdo (nível, compra, missão) | campo `"requirements"` no JSON; validados por `ProgressionState.requirement_error` (+ `bond`/`hours` em `GameState.requirement_error`; também `stats`). Recompensas `affection`/`needs` em `GameState._apply_rewards` |
| Sorteio com semente / faixas `[min, max]` | `scripts/util/loot.gd` (`Loot.pick_weighted/amount/roll`) |
| "O que dá para fazer agora" / medir o ritmo do começo | `GameState.available_actions()`; `progress.firsts` + aba **Ritmo** do `DevPanel` (todo contador passa por `GameState._count`) |
| Nova ação do jogo (ex.: plantar)      | método em `game/autoload/game_state.gd` + estado em `game/scripts/state/` |
| Novo móvel / mudar layout da casa     | `game/data/rooms/house.json` (sprite, pos, footprint, `"action": "place:<id>"`, `upgrade`) + lugar em `worlds.json` |
| Nova planta da horta / tempo / colheita | `game/data/crops.json` (tempo, itens, moedas, XP, requisitos; ícone em `items.json`); terrenos em `config.json` → `farm` |
| Painel de produção/coleta (padrão)    | Sempre o molde da estação: espaços em cima (`SheetBuilder.slot_frame`: ícone, tempo, barra; fechado = "+" com preço ou nível/XP), "Recolher/Coletar prontos", e embaixo cartões do que escolher (ícone 64, chips de tempo/ganho, botão). Usado em `station_view`, `NatureUi.panel` e `ProgressionUi.routes_panel` |
| Novo tipo de painel de lugar          | caso em `Places._panel` (`scripts/ui/places.gd`) + função que monta o painel (`SheetBuilder`/`ProgressionUi`, com `UiKit`) |
| Revelar algo aos poucos ("Novo!")     | `progression.json` → `features` (aba/seção com `requirements` e `go`); mundos, lugares e NPCs com `requirements` entram sozinhos. `GameState.new_unlocks`/`mark_seen`; tela em `scenes/ui/celebration/` |
| Regar, presente de nível, presente do dia | `GameState.water/water_error` (`config.json → farm.water`), `progression.json → level_rewards`/`daily_gift` + `settings` (welcome_*, idle_hint_*); `Events.level_up` → `Celebration.show_level`; cartão `scenes/ui/welcome_back/` (`GameState.welcome_ready_lines`); dica parada em `WorldsScreen.advance_idle`; cartões modais esperam a vez em `main.gd._queue_modal` |
| Botão "Ir até lá"                     | `Events.world_requested.emit(mundo, "<lugar>" | "npc:<id>" | "buy:<construção>")` |
| Mudar a aba Missões / Mochila         | `scenes/ui/tasks_screen/tasks_screen.gd` / `SheetBuilder.inventory_view` e `item_detail` |
| Manual de recursos e estações        | `scripts/ui/game_manual.gd` (conteúdo derivado do Database); atalho na tela `pet_screen.gd` |
| Expandir o sítio com áreas fechadas  | `rooms/farm.json → regions` (polígono, cerca e compra existente que libera a área) |
| Zonas da Natureza e seus materiais | `rooms/nature.json → regions` (requirements/upgrade), `worlds.json → nature.places`, `progression.json → activities` (walk/creek/mine/crystal/meadow) |
| Coletar na Natureza e liberar vagas | `progression.json → nature_sites` (Bosque/Caverna/Prado, levels/XP, tokens level_upgrades/slot_upgrades), `nature_resources` (rotas); `GameState.start_gathering/collect_gathering` e `NatureUi.panel` |
| Comprar galinhas/vacas e variedades | `config.json → animals` (nome, preço, abrigo, sprite/escala); `GameState.buy_animal`, `animals` salvo; loja em `SheetBuilder.animal_shop` |
| Galinhas/vacas e seus produtos       | `config.json → stations` com `kind: "animal"`, `animal_capacity`; alimentação/ovos/leite em `recipes.json`, timer em `StationState` |
| Recolher/colher com animação          | `Events.items_gained(itens, moedas, origem)` → `scripts/ui/collect_fx.gd` (miniaturas ícone +N saltam na tela). No mapa, tocar em estação/criação pronta, marcador de coleta da Natureza ou planta madura recolhe direto (`RoomView._collect_station/_collect_site`), sem abrir painel |
| Reações do Tiro no mundo             | `Events.world_activity` (GameState) → `RoomView` (alvo) → `DogWorld.react_at` (animação/caminho) |
| Nova ferramenta de teste (dev)        | `GameState.dev_*()` (com guarda `BuildInfo.is_dev()`) + botão em `scripts/ui/dev_panel.gd` |
| Visual da interface (cores, botões, fonte) | `game/assets/theme/main_theme.tres` (variações: PrimaryButton, TabButton, CloseButton, CardPanel, ReadyCardPanel, ChipPanel, SheetPanel, TopBarPanel, TitleLabel, SectionLabel, SmallLabel, BarLabel, ToastLabel) |
| Ícone de item/necessidade/atributo    | PNG 32 px em `game/assets/sprites/ui/icons/` + campo `"icon"` no JSON (caminho em `items.json`/`needs`; nome do arquivo sem `.png` em `progression.json`, `npcs.json`, `collections.json`) |
| Armazenamento (limites e ampliações)  | `progression.json → storage` + melhorias com `storage_capacity`; `items.json → storage`; `GameState.storage_*`; plano `docs/plans/ARMAZENAMENTO.md` |
| Adicionar dado que deve ser salvo     | classe em `game/scripts/state/` (ou campo no `GameState`) + `to_dict`/`from_dict`/`reset` |
| Configurações / vários saves          | Engrenagem na barra superior (`main.gd._build_settings_button`) → `scripts/ui/settings_panel.gd`. Saves 1..5 em `SaveManager` (`list_slots/switch_slot/new_slot/delete_slot/set_default_slot`; slot 1 = `save.json`/`save_dev.json`, outros `save_N.json`; padrão em `settings.json`); trocar de save recarrega a cena |
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
  `fulfill_wish` e o "Ele quer!" do seletor cumprem, alimentam uma vez e recompensam. Reposição 60 s nos 3 primeiros,
  depois 600 s; trocar espera 300 s, sem custo. `claimed_bond_level` evita presentes repetidos; `Events.bond_up` entra na fila modal.
  Balão some dormindo; toque no Tiro com balão abre Desejos. `dev_add_affection/dev_refresh_wishes` têm guarda DEV.
- **Passeios:** a Praça (`park`) abre com a primeira encomenda (`main_2_order`). `GameState.walk_state` guarda um passeio
  por vez (`current` com `ready_at` Unix, `seed`); enquanto `walking()` o Tiro não existe nas salas (`RoomView._sync_dog`),
  `feed/play/bathe/pet/dormir/cavar` são bloqueados (`away_text`) e desejos de comida mostram "Quando ele voltar".
  `start_walk` gasta energia (precisa `energy + 5`); `collect_walk` (sorteio estável pela semente, checa `storage_error`)
  aplica `rewards`/`needs`, conta `walk`, `walk:<id>`, `walk_item`, `walk_item:<item>` e `find_item:<item>` e emite `Events.walk_collected`;
  `cancel_walk` devolve a energia sem prêmio. `loot.first` soma materiais só na primeira coleta; `loot.rare` define chance/garantia por caminho/apetrecho/consolo. Histórico e `pity` só mudam ao recolher; raro novo conta `walk_rare`/`walk_rare:<id>`, duplicado vira moedas/material. `walk_lock_error` exclui horas e `walk_hours_error` verifica início (17h inclusivo, 21h exclusivo no Pôr do sol). Diário após 3 voltas; materiais `trail` sem depósito, `note` no detalhe; Coleção mostra silhuetas dos raros. `walk_unlock_keys` entra no Novo! com postal e Ir, anunciado na fila após o cartão de volta. Testes: `tests/park_test.gd` e `tests/walks_test.gd`; capturas: `tests/walks_shots.gd`.
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
  Natureza usa cenário contínuo 512×384, com obstáculos de rio/árvores/rochas no fundo.
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
  `"initial_zoom"`/`"view_center"` definem o enquadramento inicial de mapas maiores.
  `"approach"` é o ponto seguro para o Tiro se aproximar de um objeto/estação ao reagir.
  `"z_index"` (padrão 0) coloca objetos apoiados em móveis acima das fatias, como o liquidificador sobre a ilha.
  `"station"` também detecta produção pronta, mesmo sem `busy_frames`.
  `StationIndicator` mostra tempo/Coletar sobre a estação. `animal_idle: true` dá movimento
  leve ao sprite; `decoration: true` esconde marcadores de compra duplicados dos animais.
  `animal_station`/`animal_slot` vinculam o sprite a uma vaga da criação: só aparece e
  bloqueia o chão se houver animal comprado; a variedade fornece textura/escala do mapa.
  `scale` ajusta o tamanho de objetos (galinhas 0,6); toque considera essa escala.
  Etiquetas com `detail_label` aparecem no zoom ≥0,5; `overview_label` abaixo disso.
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
# Ou rode toda a suíte: powershell -File tools/test_all.ps1
# Capturas das telas: rode sem --headless, com --resolution 360x780 e "-- --screenshots"

# Teste de TOQUE real (Chrome headless em modo celular): exporte, rode serve_local.ps1 e então
powershell -ExecutionPolicy Bypass -File tools\touch_test.ps1 [-Url http://localhost:8000/dev/] [-Steps roteiro.json]  # tap/drag/pinch/ghost_drag/shot
```
Deploy: `git push` na `main` → GitHub Actions → GitHub Pages (prod em `/`, dev em `/dev/`).
