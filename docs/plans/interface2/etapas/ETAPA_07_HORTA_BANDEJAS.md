# Etapa 07 — Barra da horta e bandejas das estações

> Tamanho: grande. Depende de: 06. Próxima: 08.
> Resultado que o Vitor vê: na horta, as sementes ficam numa **barra embaixo** e o dedo **arrasta a partir
> de qualquer canteiro** para plantar/regar/colher vários (mais fácil que hoje); "Colher tudo (N)" verde; as
> bandejas do fogão, bancada, liquidificador, moinho, queijaria, costura, criações e Natureza ficam
> menores, presas ao objeto, com o mundo visível.

## 1. Ler antes
`02_JORNADA.md` §6 e §6.1; `03_TELAS.md` "Bandejas"; protótipos `prototipo/horta_plantar.png`,
`horta_colher.png`, `fogao.png` e o HTML `prototipo/horta.html`.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Toque no canteiro | `room.gd:1274` `_on_plot_tapped(i)` | pronto → colhe; fechado → compra; regável → rega e abre `PlotTray.water`; vazio → `open_plot_tray(i)` |
| Abrir a bandeja | `room.gd:1299` `open_plot_tray(i, focus, center_camera, harvest_on_open)` | vazio → `PlotTray.seeds`; crescendo → `PlotTray.care` (`CareHeader`); pronto → colhe ou `PlotTray.sickle` |
| Bandejas da horta | `scripts/ui/plot_tray.gd` | cada entrada `{id, icon, caption/caption_fn, error, help, highlight, tap: Callable→String, drag: Callable(ponto_da_sala)→bool}`; `seeds` (ordem: foco, última usada `last_crop`, tempo; bloqueadas no fim), `water` (`×N`, tocar rega todos), `sickle` (foice arrasta; "Tudo" colhe lote a lote e avisa o que não coube); dicas `HINT_DRAG = "ui:tray_drag_hint"` e `HINT_HARVEST` |
| Bandeja genérica | `scripts/ui/action_tray.gd` (962) `ActionTray.open(room, âncora, entries, options)`; `current` (static); `is_open(room)`; arrasto de item com ficha 40 px acima do dedo, rolagem na borda (`EDGE`, `EDGE_SPEED`), bandeja a 30% durante o arrasto; `TOP_LIMIT 120`, `BOTTOM_LIMIT 34` (acha o `TabBar`); modo `pick` (estações: `PICK_WIDTH 328`, 4 por linha) | — |
| Consultas da horta | `RoomView.plot_at(ponto)`, `plot_center/plot_anchor/plot_indices`, `waterable_plots()`, `ready_plots()`, `plant_plot/water_plot/harvest_plot`, `plot_feedback`, `_bring_into_view`, `tray_dragging` | — |
| Estações | `scripts/ui/station_tray.gd`: `station(room, id, anchor, focus)`, `recipe_ids`, `_header`, `recipe_detail`, `_stepper`, `_cook`, `animal(...)`, `nature(...)`, `material_detail`, `_nature_header`; `SheetBuilder.station_slot_row`, `NatureUi.slot`, `SheetBuilder.mastery_row` (`Mastery_<estação>`) | grade com "!" e rolagem horizontal; "Ver tudo" em texto |
| Testes | `tray_test` (65 s: `drag_through`, `tap_item`, `item_center`, dicas, `Pointer` no canteiro), `station_tray_test` (135 s), `garden_test`, `queue_test`, `recipe_help_test` | — |

## 3. Passo a passo

### 3.1 `FarmDock` (novo, `game/scripts/ui/farm_dock.gd`)
1. `class_name FarmDock extends PanelContainer`, nó `FarmDock`, filho do `WorldsScreen` (camada de
   interface, não do mundo), preso embaixo **logo acima do rodapé** (bottom = 84), largura total, cantos de
   cima 28, fundo `BASE_GLASS`, sombra para cima; enquanto aberto, `main.set_tab_joined(true)`.
2. Modos: **`plant`** (sementes + Regar) e **`harvest`** (foice + "Colher tudo (N)"). API:
   `static func open(room: RoomView, mode: String, plot_index: int = -1, focus: String = "") -> FarmDock`,
   `static func current() -> FarmDock`, `close()`, `select(entry_id: String)`, `selected_entry() -> Dictionary`.
3. **Reaproveite as entradas do `PlotTray`** (não duplique regras): extraia de `PlotTray.seeds/water/sickle`
   funções que **só montam as entradas** (`PlotTray.seed_entries(room, index, focus)`,
   `PlotTray.water_entry(room)`, `PlotTray.sickle_entries(room)`) e use-as no `FarmDock`. As funções antigas
   que abrem `ActionTray` podem continuar para outros chamadores, montadas a partir das mesmas entradas.
4. Visual `plant`: linha rolável na horizontal de `UiKit.tile` 52×64 (ícone 36 + tempo `SmallLabel`;
   bloqueada = `locked` com o motivo no toque via `TaskHelp`), separador 1 px, tile **Regar** (`action_water`,
   legenda "×N" quando há regáveis), e `ctl_button("check", close, 32, "sunken")` à direita. Selecionada =
   `tile selected`. Ao abrir, a selecionada é: `focus` > `PlotTray.last_crop` > a primeira liberada.
   Visual `harvest`: tile da foice selecionado + `primary("Colher tudo (N)")` (a entrada "all" do `sickle`)
   + `ctl_button("x")`. Depósito cheio (o `tap` da entrada devolve erro): o verde vira `lock_hint` com o
   ícone do depósito.
5. Quando abre: `_on_plot_tapped(i)` com canteiro **vazio** → `FarmDock.open(room, "plant", i)` **e planta
   nesse canteiro** com a semente selecionada (o toque já é o primeiro plantio; se a seleção for o regador,
   não planta). Tocar num canteiro **pronto** continua colhendo na hora; se ainda sobrarem prontos, abre o
   `FarmDock` em `harvest`. Canteiro **regável** continua regando na hora; se sobrarem regáveis, abre em
   `plant` com Regar selecionado. Canteiro **crescendo** sem rega: `CareHeader` num `Popover` sobre o
   canteiro (como o `PlotTray.care` de hoje, sem o resto da bandeja).
6. A câmera sobe para os canteiros ficarem acima da barra: use `_bring_into_view` com a área confortável
   descontando a altura da barra (≈ 96).

### 3.2 Arrastar a partir do canteiro (`RoomView`)
1. Com `FarmDock.current()` aberto, um `pressed` **sobre um canteiro** (`plot_at(ponto) >= 0`) inicia o
   **modo ferramenta**: `tray_dragging = true`; a câmera não mexe; a cada movimento, chama a função `drag` da
   entrada selecionada com o ponto **do dedo** (não 40 px acima: o dedo já está no canteiro), e cada canteiro
   só recebe uma vez por gesto (guarde os índices já feitos).
2. Ficha (`DragGhost`) com o ícone da semente/regador/foice 56 px **acima** do dedo + contador (disquinho
   `GO` com o total feito no gesto); rastro claro (`Line2D` largura 14, `HONEY_SOFT` alfa 0,55) pelos pontos
   onde agiu; losango tracejado branco nos canteiros que ainda aceitam aquela ferramenta (`plant_error == ""`,
   `water_error == ""`, `plot_status == "ready"`), desenhado sobre o canteiro enquanto o gesto dura.
3. Perto da borda (36 px), a câmera rola (reaproveite a lógica de `ActionTray`: `EDGE`, `EDGE_SPEED`).
4. `pressed` **fora** dos canteiros com a barra aberta: câmera normal; tocar fora de canteiros **e** da barra
   fecha a barra (sem agir no mundo, como a regra de hoje da bandeja).
5. `plot_feedback`, `Haptics.tap()` por canteiro e o `CollectFx` da colheita continuam iguais.
6. Dica "Arraste pelos canteiros" (pílula `INK` com texto branco e `ctl spark`) acima da barra nas três
   primeiras aberturas em `plant` com ≥ 2 canteiros vazios (`progress.seen["ui:tray_drag_hint"]` passa a
   contar as vezes: número em vez de booleano).

### 3.3 Bandejas das estações (`ActionTray` modo `pick` + `StationTray`)
1. `ActionTray`: cartão `CARD` 24, sombra (0, 10) 16 alfa 0,25, setinha 20 girada 45° com canto 4 apontando
   para o objeto; abre com escala 0,92 → 1 a partir da setinha (`Motion.TRAY_IN`); largura 336; altura
   máxima até 8 px acima do rodapé; se não couber embaixo do objeto, abre em cima (setinha para baixo).
2. `StationTray._header`: ícone da estação 32 + nome `StrongLabel` + selo pequeno de maestria (disquinho
   bronze/prata/ouro com o número; o detalhe da maestria vai para o "Ver tudo") + `ctl_button("list")` (Ver
   tudo) + `ctl_button("x")`. O "Ver tudo" em texto embaixo sai.
3. Fila: `SlotDot` 52 (02) em linha, legenda embaixo (tempo `SKY_INK`/"Pronto" `GO_INK`/preço).
4. Grade de receitas: 4 colunas de `UiKit.tile` 68 (ícone 36, tempo), **sem rolagem horizontal**; altura fixa
   de 2,5 linhas quando houver mais de 8 (rola na vertical dentro da grade); receita sem ingrediente =
   `tile missing(ingrediente que falta)` em vez do "!"; selecionada = `selected`.
5. Detalhe (`recipe_detail`): nome `StrongLabel` + `chip(time)`; linha "entra → sai": ingredientes em
   `chip have/missing` (tocáveis → Como fazer), `ctl arrow`, ganhos em `chip prize`; embaixo
   `UiKit.stepper` (troca o `_stepper` próprio) + `primary("Cozinhar"/"Fazer")` ocupando o resto. Fila cheia:
   o verde vira `lock_hint` com a próxima vaga e o preço.
6. Criações (`StationTray.animal`): uma coluna por animal (retrato em disco + `SlotDot`), detalhe e botão
   "Alimentar"; "Comprar animais" como linha `list_row` com `ctl chev` no rodapé da bandeja.
7. Natureza (`StationTray.nature`): materiais em tiles; escolha de rota (`RouteChoice_<material>`) em
   `UiKit.segmented`.
8. "Ver tudo" (`SheetBuilder.station_view`, `NatureUi.panel`): mesmas peças em folha alta.

### 3.4 Tour
`--i2-07-only`: `i2_07_dock_plant` (barra aberta), `i2_07_dock_drag` (meio do arrasto: chame as funções
públicas do gesto para parar com a ficha visível), `i2_07_dock_harvest`, `i2_07_growing` (`CareHeader` em
popover), `i2_07_stove`, `i2_07_stove_missing`, `i2_07_coop`, `i2_07_trees` (Natureza), `i2_07_station_full`
(Ver tudo do fogão).

## 4. Não fazer
- Mudar `plant/water/harvest` ou os `*_error` do `GameState`, tempos, rendimentos, ordem de compra dos
  canteiros, regras da estufa.
- Mudar o que o toque simples faz em canteiro pronto/regável (continua agindo na hora).

## 5. Armadilhas
- O arrasto agora começa no mundo, não na bandeja: o `_gui_input` do `RoomView` precisa decidir **no
  `pressed`** entre câmera e ferramenta (`plot_at`), e a pinça (`_is_pinching`) tem prioridade.
- `tray_dragging` também bloqueia o fechamento por câmera (`_camera_changed`): confira que a barra não fecha
  durante o próprio gesto.
- `tray_test` usa `drag_through`/`tap_item`/`item_center` do `ActionTray`: mantenha essas funções para as
  bandejas que continuam no `ActionTray` (estações) e escreva os equivalentes no `FarmDock`
  (`tap_tile(id)`, `drag_plots(indices)`), atualizando o teste da horta.
- Estufa: canteiros de estufa só aceitam as sementes de estufa; ao abrir pelo canteiro de estufa, a barra
  mostra só elas (o `seed_entries` já filtra por `crop_plot_error(index, …)`); um arrasto que passe de um
  canteiro comum para um de estufa só age nos compatíveis (o `drag` já ignora em silêncio).

## 6. Testes

**`game/tests/farm_dock_test.gd`** (área `farm`; Sítio com 9 canteiros abertos via `dev_*`):
1. Tocar num canteiro vazio planta nele (status `growing`) **e** abre o `FarmDock` em `plant` com a semente
   usada selecionada.
2. Gesto começando no canteiro 3 e passando pelos 4, 5 e por um canteiro já plantado: plantou exatamente nos
   vazios (3, 4, 5), uma vez cada; o já plantado não mudou; a câmera não se moveu (`_content.position` igual).
3. Gesto começando fora dos canteiros mexe a câmera e não planta nada.
4. Selecionar Regar e arrastar por 2 canteiros crescendo: os dois regados (`water_error` deixa de ser "").
5. Com 3 prontos: tocar num pronto colhe só ele e abre `harvest`; "Colher tudo (2)" colhe os outros dois;
   com o depósito sem espaço, o botão vira `lock_hint` e nada é colhido.
6. Tocar fora dos canteiros e da barra fecha a barra sem agir no mundo.
7. A barra fica acima do `Layout/TabBar` e nenhum tile dela tem alvo menor que 44.

**Atualizar:** `tray_test` (horta pelo `FarmDock`; estações continuam pelo `ActionTray`; o `Pointer` no
primeiro canteiro continua), `station_tray_test` (cabeçalho com Ver tudo em ícone, grade sem rolagem
horizontal, stepper do `UiKit`), `garden_test`/`queue_test` só se tocarem em nós de interface.

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests farm_dock_test,tray_test,garden_test,queue_test,recipe_help_test,station_tray_test` (~4 min; o `station_tray_test` entra porque a `StationTray` muda — exceção registrada).

**Toque real (04 §F):** `build/touch_steps_i2_07.json`: tap num canteiro vazio → drag de um canteiro vazio
por mais três → shot; tap em Regar → drag por dois crescendo → shot; (com prontos) tap em "Colher tudo" →
shot; tap no fogão → tap numa receita → tap em Cozinhar → shot.

## 7. Capturas
`--i2-07-only` antes (use os `e0*` do tour completo) e depois nas 3 resoluções; compare com `horta_*.png` e
`fogao.png`.

## 8. Pronto quando
- [ ] Plantar 6 canteiros = 1 toque + 1 arrasto começando em qualquer canteiro.
- [ ] Colher tudo num toque; regar arrastando; tocar simples igual a hoje.
- [ ] Bandejas das estações como `fogao.png`, com o objeto visível e sem cobrir o rodapé.
- [ ] Testes verdes; toque real feito; `CLAUDE.md`/`AGENTS.md` (`FarmDock`, entradas do `PlotTray`).

## 9. Registro
```
**Etapa 07 (data, executor):** FarmDock (plantar/regar/colher com arrasto começando no canteiro, Colher tudo),
entradas do PlotTray extraídas, CareHeader em popover, ActionTray/StationTray no visual novo (cabeçalho com
ícones, grade sem rolagem lateral, tile missing, stepper do UiKit). Testes … PASS em … s. Toque real: …
```
