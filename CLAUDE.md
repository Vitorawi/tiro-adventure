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
que evoluem e missões de personagens. Abas: **Tiro · Mapa** (mini mundos: Casa, Sítio, Vila — a trilha é um portão da Vila —
cada um com seus personagens e lugares) **· Missões** (História passo a passo, Diárias e Semanais, com botão "Ir" e "?") **· Mochila**.

Jogo 2D em **Godot 4.7.2** (GDScript), exportado para **Web** e instalado no celular como **PWA**
("Adicionar à tela inicial" no iPhone/Android). Publicado automaticamente no **GitHub Pages**
a cada push na `main` (versão publicada em `/` e versão dev em `/dev/`). Progresso salvo
**localmente no aparelho** (IndexedDB via `user://`). Arte em pixel art gerada com o **MCP PixelLab**.

- Ideia/regras do jogo: `docs/GAME_DESIGN.md`
- Progressão (atributos, construções, missões, NPCs, versão dev): `docs/PROGRESSION.md`
- Mundos, navegação e **como criar um mundo novo**: `docs/WORLDS.md`
- Fases, **estado atual e próximas tarefas**: `docs/ROADMAP.md`
- Planos detalhados prontos para executar: `docs/plans/` (ex.: `TASKS_V2.md`)

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
                       worlds.json (mundos: lugares, personagens, requisitos)
                       rooms/<id>.json (cena de cada mundo: fundo, móveis, zonas tocáveis), version.json (versão + canal prod/dev, gravado no deploy)
  scenes/            cenas, uma pasta por cena (.tscn + .gd juntos)
    main/            casca: barra superior (selo DEV), abas Tiro/Mapa/Missões/Mochila, Sheet, toast
    ui/pet_screen/   Tela do Pet (Tiro grande, necessidades, ações)
    ui/worlds_screen/  aba Mapa: lista de mundos + mundo atual (cabeçalho com Mapa, Lugares e personagens)
    ui/tasks_screen/   aba Missões (História: um passo por vez, visual; Diárias; Semanais; botões "Ir" e "?")
    ui/celebration/  comemoração de capítulo acima do Sheet
    ui/bag_screen/     aba Mochila (itens por categoria; detalhe: para que serve, onde usar, vender)
    ui/sheet/        painel inferior genérico (menus de objetos)
    levels/room/     RoomView genérico (`room_id`, `world_id`): monta data/rooms/<id>.json (casa, sítio, vila), canteiros, etiquetas, navegação, toque, câmera
    entities/dog_world/  Tiro pequeno com IA autônoma (anda pelo caminho calculado)
  scripts/state/     DogState, Inventory, StationState, ProgressionState (dados + to_dict/from_dict)
  scripts/ui/        UiKit (peças), SheetBuilder (painéis), Places (lugares/personagens/avisos dos mundos),
                     ProgressionUi (painéis: personagem, construir, vender, encomendas, rotas, atributos, coleção),
                     GameManual (catálogo visual de recursos/estações), DevPanel (ferramentas DEV),
                     PlotIndicator, StationIndicator (tempo/coleta de estações e criações),
                     PetAnimator (animações do Tiro na aba Tiro)
  scripts/util/      BuildInfo (canal prod/dev, arquivo de save), TimeText (texto de duração)
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
| História principal                    | `quests.json` (só `kind: "main"`, chapter/order); `progression.json`: capítulos/rewards |
| Missão diária / semanal               | `data/routines.json` (`goal` = contador + alvo, `rewards`, `requirements`; `count` por tipo); ações `GameState.claim_routine` |
| "Como fazer" (o que falta, 1º passo)  | `scripts/ui/task_help.gd` (`TaskHelp.describe` calcula; `TaskHelp.panel` mostra em ícones) |
| Nova missão / personagem (NPC) / roupa | `quests.json` / `npcs.json` (`portrait`, `services`) + mundo dele em `worlds.json` → `npcs` / `collections.json` |
| Requisitos de conteúdo (nível, compra, missão) | campo `"requirements"` no JSON; validados por `ProgressionState.requirement_error` |
| Nova ação do jogo (ex.: plantar)      | método em `game/autoload/game_state.gd` + estado em `game/scripts/state/` |
| Novo móvel / mudar layout da casa     | `game/data/rooms/house.json` (sprite, pos, footprint, `"action": "place:<id>"`, `upgrade`) + lugar em `worlds.json` |
| Nova planta da horta / tempo / colheita | `game/data/crops.json` (tempo, itens, moedas, XP, requisitos; ícone em `items.json`); terrenos em `config.json` → `farm` |
| Novo tipo de painel de lugar          | caso em `Places._panel` (`scripts/ui/places.gd`) + função que monta o painel (`SheetBuilder`/`ProgressionUi`, com `UiKit`) |
| Revelar algo aos poucos ("Novo!")     | `progression.json` → `features` (aba/seção com `requirements` e `go`); mundos, lugares e NPCs com `requirements` entram sozinhos. `GameState.new_unlocks`/`mark_seen`; tela em `scenes/ui/celebration/` |
| Botão "Ir até lá"                     | `Events.world_requested.emit(mundo, "<lugar>" | "npc:<id>" | "buy:<construção>")` |
| Mudar a aba Missões / Mochila         | `scenes/ui/tasks_screen/tasks_screen.gd` / `SheetBuilder.inventory_view` e `item_detail` |
| Manual de recursos e estações        | `scripts/ui/game_manual.gd` (conteúdo derivado do Database); atalho na tela `pet_screen.gd` |
| Expandir o sítio com áreas fechadas  | `rooms/farm.json → regions` (polígono, cerca e compra existente que libera a área) |
| Galinhas/vacas e seus produtos       | `config.json → stations` com `kind: "animal"`; alimentação/ovos/leite em `recipes.json`, estado/timer em `StationState` |
| Reações do Tiro no mundo             | `Events.world_activity` (GameState) → `RoomView` (alvo) → `DogWorld.react_at` (animação/caminho) |
| Nova ferramenta de teste (dev)        | `GameState.dev_*()` (com guarda `BuildInfo.is_dev()`) + botão em `scripts/ui/dev_panel.gd` |
| Visual da interface (cores, botões, fonte) | `game/assets/theme/main_theme.tres` (variações: PrimaryButton, TabButton, CloseButton, CardPanel, ReadyCardPanel, ChipPanel, SheetPanel, TopBarPanel, TitleLabel, SectionLabel, SmallLabel, BarLabel, ToastLabel) |
| Ícone de item/necessidade/atributo    | PNG 32 px em `game/assets/sprites/ui/icons/` + campo `"icon"` no JSON (caminho em `items.json`/`needs`; nome do arquivo sem `.png` em `progression.json`, `npcs.json`, `collections.json`) |
| Adicionar dado que deve ser salvo     | classe em `game/scripts/state/` (ou campo no `GameState`) + `to_dict`/`from_dict`/`reset` |
| Mudar formato do save                 | `game/autoload/save_manager.gd` (`SAVE_VERSION` + `_migrate`) |
| Comunicar sistemas desacoplados       | sinal novo em `game/autoload/events.gd` |
| Criar tela/menu                       | `game/scenes/ui/<nome>/` |
| Criar personagem/inimigo/item         | `game/scenes/entities/<nome>/` |
| Criar fase                            | `game/scenes/levels/<nome>/` |
| Adicionar sprite do PixelLab          | `game/assets/sprites/<categoria>/` (ver `docs/ART_PIPELINE.md`) |
| Mudar resolução/orientação            | `game/project.godot` `[display]` + `progressive_web_app/orientation` em `game/export_presets.cfg` |
| Mudar build/deploy                    | `tools/export_web.ps1`, `.github/workflows/deploy.yml`, `docs/DEPLOY.md` |

## Regras de arquitetura
- **História:** capítulo/passo derivados de `progress.claimed_quests`; só a main atual pode ser recebida. Save v5 migra alvos já adquiridos sem pagar de novo. `Places.goal_target` resolve o botão Ir.
- **Disco só via `SaveManager`.** Nenhum outro script usa `FileAccess` para save.
- **Estado persistente só em `GameState`** (e nas classes de `scripts/state/` que ele guarda, ex.:
  `GameState.progress`). Cenas leem o estado e o alteram **só por métodos do `GameState`**.
- **Ações passam pelo `GameState`** (feed, cook, plant, buy_upgrade, claim_quest...): validam,
  alteram e emitem `state_changed`; o `SaveManager` salva automaticamente a cada mudança.
  Convenção: ação devolve `""` se deu certo ou o motivo da falha (texto pronto para toast), e tem
  um `*_error()` igual que a UI usa para desabilitar botões.
- **Classes de estado** (`scripts/state/`): só dados + consultas puras + `to_dict`/`from_dict`.
  O estado não depende da UI (ex.: texto de tempo vem de `TimeText`, não do `SheetBuilder`).
- **Sinais globais só em `Events`.** Sinais locais ficam na cena.
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
  sem duplicar. Nenhum estado paralelo dos animais nem novo formato de save.
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
  `"initial_zoom"`/`"view_center"` definem o enquadramento inicial de mapas maiores.
  `"approach"` é o ponto seguro para o Tiro se aproximar de um objeto/estação ao reagir.
  `"station"` também detecta produção pronta, mesmo sem `busy_frames`.
  `StationIndicator` mostra tempo/Coletar sobre a estação. `animal_idle: true` dá movimento
  leve ao sprite; `decoration: true` esconde marcadores de compra duplicados dos animais.
  `scale` ajusta o tamanho de objetos (galinhas 0,6); toque considera essa escala.
  Etiquetas com `detail_label` aparecem no zoom ≥0,5; `overview_label` abaixo disso.
  Moinho/queijaria têm lugares próprios `hidden` para o toque direto, além do agrupamento
  Produção. `Database.place_with_panel` prioriza painel exato antes dos agrupados.
  `"plot": N` = canteiro N da horta (estado em `GameState.plots`; broto/planta madura por cima).
  `GameState.unlocked_plots` guarda os terrenos comprados em ordem fixa; `buy_plot` valida a compra.
  `PlotIndicator` desenha ícone, tempo e barra sobre a planta; `SheetBuilder` monta os painéis do sítio.
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
# Ou rode toda a suíte: powershell -File tools/test_all.ps1
# Capturas das telas: rode sem --headless, com --resolution 360x780 e "-- --screenshots"

# Teste de TOQUE real (Chrome headless em modo celular): exporte, rode serve_local.ps1 e então
powershell -ExecutionPolicy Bypass -File tools\touch_test.ps1 [-Url http://localhost:8000/dev/] [-Steps roteiro.json]  # tap/drag/pinch/ghost_drag/shot
```
Deploy: `git push` na `main` → GitHub Actions → GitHub Pages (prod em `/`, dev em `/dev/`).
