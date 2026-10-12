# CLAUDE.md — Mapa do projeto

Leia este arquivo primeiro. Ele diz **o que é o projeto, como está organizado e onde trabalhar**.
Detalhes ficam em `docs/`.

## O que é
**Tiro Adventure** — repo `github.com/Vitorawi/tiro-adventure`, jogo em
https://vitorawi.github.io/tiro-adventure/

**Bichinho virtual (cachorrinho) + produção em cadeia estilo Hay Day.** Celular **em pé**,
tela inteira, **100% toque**: o jogador não controla o movimento do cachorro (ele anda sozinho),
só toca nos objetos (geladeira, horta, fogão...) e arrasta para mover a câmera.

Jogo 2D em **Godot 4.7.2** (GDScript), exportado para **Web** e instalado no celular como **PWA**
("Adicionar à tela inicial" no iPhone/Android). Publicado automaticamente no **GitHub Pages**
a cada push na `main`. Progresso salvo **localmente no aparelho** (IndexedDB via `user://`).
Arte em pixel art gerada com o **MCP PixelLab**.

- Ideia/regras do jogo: `docs/GAME_DESIGN.md`
- Fases e próximas tarefas: `docs/ROADMAP.md`

## Estrutura
```
CLAUDE.md            este mapa
README.md            descrição pública + link do jogo
docs/                documentação (design, arquitetura, arte, deploy, roadmap)
tools/               export_web.ps1, serve_local.ps1, screenshot.gd (captura telas), pixel_tools.ps1 (recorte/prancha de sprites)
.github/workflows/   deploy.yml: build Web + GitHub Pages
build/               saída do export e screenshots (gerada, ignorada no git)
game/                PROJETO GODOT (abra game/project.godot no editor)
  autoload/          Events (sinais), Database (lê data/*.json), GameState (estado + ações), SaveManager
  data/              CONTEÚDO em JSON: items.json, recipes.json, config.json (necessidades, ações, XP, início)
  scenes/            cenas, uma pasta por cena (.tscn + .gd juntos)
    main/            casca: barra superior, abas Tiro/Casa/Sítio, Sheet, toast
    ui/pet_screen/   Tela do Pet (Tiro grande, necessidades, ações)
    ui/sheet/        painel inferior genérico (menus de objetos)
    levels/room/     RoomView genérico (`room_id`): monta data/rooms/<id>.json (casa, sítio), canteiros, navegação, toque, câmera
    entities/dog_world/  Tiro pequeno com IA autônoma (anda pelo caminho calculado)
  scripts/state/     DogState, Inventory, StationState (dados + to_dict/from_dict)
  scripts/ui/        UiKit (peças), SheetBuilder (painéis) e PetAnimator (animações do Tiro na aba Tiro; reage a Events.dog_action)
  assets/            sprites/(characters,areas,tiles,ui,fx), theme/, audio/, fonts/, icons/ (PWA)
  tests/             testes (excluídos do export)
```

## Onde trabalhar (guia rápido)
| Quero...                              | Vá para |
|---------------------------------------|---------|
| Novo item / receita / ajuste de números | `game/data/*.json` (sem mexer em código) |
| Nova ação do jogo (ex.: plantar)      | método em `game/autoload/game_state.gd` + estado em `game/scripts/state/` |
| Novo móvel / mudar layout da casa     | `game/data/rooms/house.json` (sprite, pos, footprint, action) + ação em `_on_object_tapped` de `room.gd` |
| Nova planta da horta / tempo / colheita | `game/data/crops.json` (+ ícone do item em `items.json`); nº de canteiros em `config.json` → `farm` |
| Novo ambiente (sala)                  | `game/data/rooms/<id>.json` + instância de `levels/room/room.tscn` com `room_id` em `main.tscn` (+ aba em `main.gd`) |
| Novo menu de objeto                   | função em `game/scripts/ui/sheet_builder.gd` (montar com `UiKit`) + `Events.sheet_requested` |
| Visual da interface (cores, botões, fonte) | `game/assets/theme/main_theme.tres` (variações: PrimaryButton, TabButton, CloseButton, CardPanel, ReadyCardPanel, ChipPanel, SheetPanel, TopBarPanel, TitleLabel, SectionLabel, SmallLabel, BarLabel, ToastLabel) |
| Ícone de item/necessidade             | PNG 32 px em `game/assets/sprites/ui/icons/` + campo `"icon"` no JSON (`items.json`, `needs` do `config.json`) |
| Adicionar dado que deve ser salvo     | `game/autoload/game_state.gd` (campo + `to_dict`/`from_dict`/`reset`) |
| Mudar formato do save                 | `game/autoload/save_manager.gd` (`SAVE_VERSION` + `_migrate`) |
| Comunicar sistemas desacoplados       | sinal novo em `game/autoload/events.gd` |
| Criar tela/menu                       | `game/scenes/ui/<nome>/` |
| Criar personagem/inimigo/item         | `game/scenes/entities/<nome>/` |
| Criar fase                            | `game/scenes/levels/<nome>/` |
| Adicionar sprite do PixelLab          | `game/assets/sprites/<categoria>/` (ver `docs/ART_PIPELINE.md`) |
| Mudar resolução/orientação            | `game/project.godot` `[display]` + `progressive_web_app/orientation` em `game/export_presets.cfg` |
| Mudar build/deploy                    | `tools/export_web.ps1`, `.github/workflows/deploy.yml`, `docs/DEPLOY.md` |

## Regras de arquitetura
- **Disco só via `SaveManager`.** Nenhum outro script usa `FileAccess` para save.
- **Estado persistente só em `GameState`.** Cenas leem/alteram o estado por métodos dele.
- **Sinais globais só em `Events`.** Sinais locais ficam na cena.
- Export **Web single-thread** e renderer **Compatibility**: não ligar threads (GitHub Pages
  não envia headers COOP/COEP) nem usar recursos exclusivos de Forward+/Mobile.
- Pensar **mobile primeiro**: celular em pé (base 360×780, `stretch=expand`), só toque,
  alvos grandes, ações perto do polegar, pouca memória. **Nada de botões direcionais/joystick.**
- **Tempo real:** timers (plantação, fogão) e necessidades guardam timestamps Unix, nunca
  contadores por frame, para continuarem com o app fechado.
- **Conteúdo orientado a dados:** itens, receitas, plantas, missões e números de balanceamento
  ficam em `game/data/*.json` (lidos pelo `Database`); o código dos sistemas não tem conteúdo fixo.
  O preset Web inclui `data/*.json` via `include_filter` — novos tipos de arquivo não-recurso
  precisam ser adicionados lá.
- **Ações passam pelo `GameState`** (feed, play, cook, collect...), que emite `state_changed`;
  o `SaveManager` salva automaticamente a cada mudança.
- **Ambientes (salas):** fundo vazio (piso + paredes) + cada móvel como sprite separado, tudo
  descrito em `game/data/rooms/<id>.json`. Coordenadas em pixels do fundo; `pos` = meio da base
  do sprite (usado na ordenação por Y); `footprint` = polígono no chão que bloqueia o caminho;
  `zones` = partes tocáveis do fundo (ex.: porta); `"slice": true` = peça recortada do fundo
  (ex.: ilha), fatiada em colunas para o Tiro passar atrás/na frente, sem toque;
  `"station"` + `"busy_frames"` (pasta de PNGs) = móvel que anima enquanto a estação produz
  (ex.: fogão cozinhando). Quadros de animação usam o MESMO recorte da imagem base.
  `"plot": N` = canteiro N da horta (estado em `GameState.plots`; broto/planta madura por cima).
  O Tiro só aparece na sala que tiver o ponto `dog_start`. O piso vira uma grade `AStarGrid2D` (8 px)
  e o Tiro anda por ela. Para posicionar móveis, gere prévias com `tools/pixel_tools.ps1`.
- **Toque:** a sala trata toque curto = clique (teste por pixel opaco do sprite) e arrastar =
  câmera. Eventos de toque chegam como mouse (`emulate_mouse_from_touch`): trate `InputEventMouse*`.

## Convenções
- Arquivos e pastas em `snake_case`; `class_name` em `PascalCase`; GDScript **sempre tipado**.
- Cena e script com o mesmo nome, na mesma pasta (`player/player.tscn` + `player/player.gd`).
- Nós acessados por código usam nome único (`%Nome`).
- Comentários e docs em português.
- Commitar os arquivos `.uid` e `.import` gerados pelo Godot; nunca commitar `.godot/` ou `build/`.
- Ao mudar estrutura ou arquitetura, **atualize este arquivo e o doc relevante em `docs/`**.

## Comandos
```powershell
# Godot (caminho atual; pode ser sobrescrito com $env:GODOT_BIN)
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

powershell -ExecutionPolicy Bypass -File tools\export_web.ps1   # build Web em build/web
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1  # http://localhost:8000
& $env:GODOT_BIN --headless --path game --quit-after 60         # checar erros de script
& $env:GODOT_BIN --path game --resolution 360x780 -s ../tools/screenshot.gd  # PNGs em build/screenshots/
# Teste de TOQUE real (Chrome headless em modo celular): exporte, rode serve_local.ps1 e então
powershell -ExecutionPolicy Bypass -File tools\touch_test.ps1 [-Steps roteiro.json]  # tap/drag/pinch/ghost_drag/shot
```
Deploy: `git push` na `main` → GitHub Actions → GitHub Pages.
