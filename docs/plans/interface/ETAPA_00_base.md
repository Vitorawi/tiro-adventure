# Etapa 00 — Base: tour de capturas, paleta, movimento, anel e ícones próprios

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_00_base.md."
> Pré-requisito: nenhum.

## Objetivo
Preparar as ferramentas que todas as etapas usam e corrigir o que está "errado" sem mudar o visual
geral ainda: régua de capturas, cores e tempos em constantes, anel de progresso, ícones próprios para
cada estação (chega de fogão com ícone de petisco) e a Casa abrindo enquadrada.

## Leia antes
`docs/plans/interface/ui_tour_rascunho.gd` (rascunho do tour), `game/tests/walks_shots.gd` (modelo de captura),
`game/scripts/ui/ui_kit.gd`, `game/scenes/levels/room/room.gd` (`_ready`, `_show_whole_room`,
`_zoom_at`, `_on_resized`, `_fit_zoom`), `game/data/progression.json → upgrades[*].icon`,
`game/data/worlds.json → places[*].icon`.

## Passo a passo

### 0.1 Tour de capturas — `game/tests/ui_tour.gd`
- [ ] Copie `docs/plans/interface/ui_tour_rascunho.gd` para `game/tests/ui_tour.gd` (se o arquivo não existir mais, recrie a
  partir da lista abaixo usando o padrão de `walks_shots.gd`: remove o `SaveManager`, `GameState.reset()`,
  instancia `main.tscn`, salva PNG com `root.get_texture().get_image().save_png`).
- [ ] Argumento `--out=<pasta>` lido de `OS.get_cmdline_user_args()`; padrão `ui_tour`. PNGs em
  `build/screenshots/<pasta>/`.
- [ ] Capturas (nomes fixos, para comparar antes/depois):
  - **Começo de jogo** (reset + `seen["intro"]`): `a01_pet`, `a02_tasks`, `a03_map`, `a04_house`, `a05_fridge_sheet`.
  - **Jogo avançado** (`dev_unlock_everything`, `_mark_all_seen`, plantar canteiros 0–2, cozinhar 1 petisco):
    `b01_pet`, `b02_wishes`, `b03_tasks`, `b04_bag`, `b05_map_list`, `b06_world_<house|farm|park|village|nature>`,
    `b07_plot_empty_tap`, `b08_plot_growing_tap`, `b09_farm_view`, `b10_workbench`, `b11_coop`, `b12_stove`,
    `b13_bowl`, `b14_market`, `b15_nature_trees`, `b16_walks`, `b17_npc_lais` (na Casa), `b18_item_detail`,
    `b19_skills`, `b20_collection`, `b21_story`, `b22_orchard`, `b23_settings`, `b24_manual`.
  - **Cartões:** `c01_level_up` (`Celebration.show_level`), `c02_unlocks` (`show_unlocks` com 1 item),
    `c03_welcome_back` (`WelcomeBack.open` com presente + 3 achados), `c04_walk_result` (igual `walks_shots.gd`),
    `c05_toast` (emite `toast_requested` com o mundo aberto e captura em 0,3 s).
- [ ] Use `places.call("open", mundo, lugar)` para painéis; feche com `sheet_close_requested`; esconda
  `Celebration`/`WelcomeBack`/`WalkResult` entre capturas.
- [ ] **Não** entra no `test_all.ps1`. Documente o comando em `01_REGRAS_E_ESTILO.md` (já está) e no `CLAUDE.md` (Comandos).

### 0.2 Paleta — `game/scripts/ui/palette.gd`
- [ ] Crie exatamente como em `01_REGRAS_E_ESTILO.md → B.1`.
- [ ] `UiKit.GOOD`/`UiKit.BAD` passam a ser `Palette.GOOD`/`Palette.BAD` (constantes com o mesmo nome).

### 0.3 Movimento — `game/scripts/ui/motion.gd`
- [ ] `class_name Motion extends RefCounted` com as funções estáticas da tabela `01 → C`
  (`press`, `pop_in`, `pop_out`, `slide_up`, `bounce`, `pulse`, `count_up`, `shake`, `float_text`).
- [ ] Todas recebem o nó, criam o `Tween` com `node.create_tween()` e devolvem o `Tween`.
- [ ] `pivot_offset`: definir `node.pivot_offset = node.size / 2.0` dentro da função (para `Control`);
  para `Node2D` não precisa.
- [ ] `static var reduced := false` — quando `true`, as funções aplicam o estado final sem animar.
- [ ] `float_text(parent: Node, pos: Vector2, text: String, color: Color)`: cria `Label` com
  `NumberLabel` (se a variação ainda não existir no tema, usar `add_theme_*_override`), sobe 28 px e some.

### 0.4 Anel de progresso — `game/scripts/ui/ring_progress.gd`
- [ ] `class_name RingProgress extends Control`:
```gdscript
@export var progress := 0.0:  # 0..1
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
@export var thickness := 4.0
@export var color := Palette.INFO
@export var track := Palette.SUNKEN
var texture: Texture2D  # ícone no meio (desenhado em escala inteira quando couber)

func _draw() -> void:
	var r := minf(size.x, size.y) / 2.0 - thickness / 2.0
	draw_arc(size / 2.0, r, 0.0, TAU, 48, track, thickness, true)
	if progress > 0.0:
		draw_arc(size / 2.0, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, color, thickness, true)
	if texture:
		# maior múltiplo inteiro de 32 que cabe dentro do anel
		...
```
- [ ] `custom_minimum_size` padrão 56×56; `mouse_filter = IGNORE`.

### 0.5 Casa abrindo enquadrada (bug)
Hoje `_show_whole_room.call_deferred()` roda quando a sala ainda tem tamanho 0 (`_zoom_at` sai cedo) e
nunca é refeito: a Casa fica no zoom 1 e cortada.
- [ ] Em `room.gd`: `var _framed := false`. `_show_whole_room()` só marca `_framed = true` se
  `size.x > 0 and size.y > 0`. Em `_on_resized()`: se `not _framed`, chama `_show_whole_room()`; senão
  mantém o comportamento atual.
- [ ] Confira nas capturas `a04_house` e `b06_world_house`: a casa inteira aparece (ainda com o vazio em
  volta — o fundo bonito vem na Etapa 04). Confira Praça e Vila também.

### 0.6 Ícones próprios das estações e lugares
Hoje vários lugares usam ícones emprestados. Gere (receita "Ícone de estação" em `01 → E`) e troque nos JSON:

| Arquivo novo (`ui/icons/`) | O que desenhar | Usar em |
|---|---|---|
| `station_stove.png` | fogão pequeno de 4 bocas com panela | `upgrades.stove`, `stove_queue`, `stove_queue_2`; `worlds.house.places.stove` |
| `station_fridge.png` | geladeira prata de duas portas | `upgrades.fridge`, `fridge_2`, `fridge_3`; lugar `fridge` |
| `station_blender.png` | liquidificador com copo vermelho | `upgrades.blender`; lugar `blender` (se houver) |
| `station_chest.png` | baú de madeira de casa | `upgrades.chest`, `chest_2`, `chest_3`; lugar `chest` |
| `station_workbench.png` | bancada de madeira com serrote | `upgrades.workbench`; lugar `workbench` |
| `station_silo.png` | silo vermelho de fazenda | `upgrades.silo*`; lugar `silo` |
| `station_warehouse.png` | celeiro/armazém de madeira | `upgrades.warehouse*`; lugar `warehouse` |
| `station_mill.png` | moinho de vento pequeno | `upgrades.mill`; lugar `mill` |
| `station_dairy.png` | queijaria: casinha com queijo na placa | `upgrades.dairy`; lugar `dairy` |
| `station_coop.png` | galinheiro com telhado vermelho | `upgrades.chicken_coop`; lugar `chicken_coop` |
| `station_barn.png` | curral/estábulo com porta em X | `upgrades.cow_barn`; lugar `cow_barn` |
| `station_sewing.png` | máquina de costura | `upgrades.sewing_table` |
| `station_stall.png` | barraca de feira listrada | `upgrades.stall`; lugar `market` |
| `ui_lock.png` | cadeado dourado | (usado na Etapa 01) |

- [ ] Itens que ainda fazem sentido (`orchard: item_apple`, `greenhouse: item_herbs`, ferramentas,
  tokens de nível da Natureza) ficam como estão.
- [ ] Confira as telas que mostram esses ícones: compra (`ProgressionUi.upgrade_card`), "Novo!",
  manual (`GameManual`), "O que tem aqui?" (`Places.world_list`), `stations_view`.
- [ ] Registre no `ART_PIPELINE.md`.

## Testes
- [ ] `game/tests/ui_base_test.gd` (novo, no `test_all.ps1`):
  - `RingProgress.progress = 1.7` vira 1,0; `-1` vira 0;
  - `Motion.reduced = true`: `pop_in` deixa `scale == Vector2.ONE` e `modulate.a == 1` na hora;
  - `Motion.count_up` com `reduced` escreve o valor final;
  - todo `icon` de `progression.json → upgrades` e `worlds.json → places` existe em `ui/icons/`;
  - nenhum upgrade de estação usa ícone `tab_*` ou `item_carrot_snack`.
- [ ] `world_life_test` ou `navigation_test`: depois de entrar na Casa e esperar 2 quadros, o zoom da
  sala é `_fit_zoom()` (ou `initial_zoom`) e o Tiro está dentro do retângulo visível.
- [ ] Todos os testes passam.

## Capturas
Tour completo `etapa00_antes` (antes de qualquer mudança) e `etapa00_depois`. Compare: ícones novos em
compra/manual/lista de lugares; Casa inteira.

## Lista de conferência (aceite)
- [ ] `ui_tour.gd` gera todas as capturas listadas em 0.1 sem erro.
- [ ] `Palette`, `Motion`, `RingProgress` existem, tipados, comentados em português.
- [ ] Casa abre inteira.
- [ ] Nenhum lugar/estação usa ícone emprestado (tabela 0.6).
- [ ] CLAUDE.md/AGENTS.md: linhas novas na tabela "Onde trabalhar" (Paleta/Movimento/Anel; tour de capturas nos Comandos).
- [ ] ROADMAP, ART_PIPELINE, README marcados; commit `feat(ui): base do plano de interface (tour, paleta, movimento, ícones)`.
