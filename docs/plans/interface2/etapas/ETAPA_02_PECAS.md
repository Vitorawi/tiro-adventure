# Etapa 02 — Peças do `UiKit`

> Tamanho: médio. Depende de: 01. Próxima: 03.
> Resultado que o Vitor vê: todas as telas que já usam o `UiKit` ficam com botões, chips, cartões, linhas,
> abas internas, anéis e folhas no desenho novo. Telas montadas à mão ainda não mudam (cada uma tem sua etapa).

## 1. Ler antes
`01_BIBLIA_VISUAL.md` §C, §D, §F, §G; `04_REGRAS_E_TESTES.md` §A, §E; protótipo `prototipo/estilo.png`
(peças isoladas) e `missoes2_*.png`/`fogao.png` (peças em uso).

## 2. Como está hoje (`game/scripts/ui/ui_kit.gd`, 414 linhas)

Assinaturas existentes que **não podem quebrar** (muitos chamadores):
`ui_icon(name)`, `icon(texture, px=32)`, `ready_dot(px=14)`, `alert_badge()`, `label(text, variation, color)`,
`chip(texture, text, color=null)`, `tap_chip(texture, text, on_pressed, color=null)`,
`icon_button(texture, on_pressed, px=44, text="")`, `square_button(text, on_pressed, texture=null, px=52)`,
`primary(text, on_pressed, texture=null)`, `secondary(text, on_pressed, texture=null, small=false)`,
`ghost(text, on_pressed)`, `pill(texture, text)`, `lock_icon(px=32)`, `lock_hint(text, on_help=Callable())`,
`slot_dot(state, texture, progress, caption, caption_color, caption_icon…)`,
`list_row(texture, title, chips: Array[Control], action=null, on_tap=Callable())`, `short_label`,
`fill_label`, `card(parent, variation=&"CardPanel") -> VBoxContainer`, `action_tile(texture, caption, on_pressed)`,
`button(text, on_pressed, variation, texture)`, `hbox/vbox/flow`, `bar(value, color, height=14)`,
`tint_bar`, `effect_chips`, `effect_chip_list`, `segmented(entries, selected, choose) -> HBoxContainer`,
`grid_tile(texture, title, action, px=76, icon_px=48)`, `collection_progress(count, total)`.

Outras peças: `RingProgress` (`ring_progress.gd`, 56×56 padrão — `ui_base_test.gd:34` confere),
`SlotDot` (`slot_dot.gd`, `DOT := 56`, estados `empty/queued/busy/ready/buy/level`), `SpeechBubble`
(`speech_bubble.gd`), `Popover` (`popover.gd`), `Sheet` (`scenes/ui/sheet/sheet.gd/.tscn`), `Motion`
(`motion.gd`: `press`, `pop_in`, `pop_out`, `slide_up`, `bounce`, `pulse`, `count_up`, `shake`,
`float_text`, `fade_in`), `CollectFx` (`collect_fx.gd`, voo das moedas até `Hud.coins_target()`).

## 3. Passo a passo

### 3.1 Botões
1. `primary(...)`: só o visual vem do tema (01). Acrescente o aperto com o lábio: em `Motion.press`, para
   botões `PrimaryButton`, além da escala 0,96, troque para o estilo `pressed` (o tema já faz) — nada a
   programar se o tema estiver certo; confira.
2. **Novo** `soft(text, on_pressed, texture = null, small = false) -> Button`: variação `SecondaryButton`
   (calmo). `secondary(...)` passa a chamar `soft(...)` (apelido; não remova).
3. **Novo** `small_go(text, on_pressed) -> Button`: variação nova `SmallGoButton` (base `Button`): `GO`,
   pílula, altura 36, `font_display` 16 branca, lábio 2 px. Uso: "Pegar" nas linhas.
4. **Novo** `ctl_button(name: String, on_pressed: Callable, px: int = 40, surface: String = "card") -> Button`:
   disco com `UiKit.ctl(name)` no meio; `surface == "card"` → `IconButton` (HUD, sobre o mundo);
   `"sunken"` → `CloseButton` (dentro de folha). Alvo mínimo 44 (se `px < 44`, `custom_minimum_size`
   continua 44 e o disco desenha `px` no centro).
5. `icon_button(...)` e `square_button(...)`: mantêm a assinatura; quando `text == "?"`, desenham o `ctl
   help` (compatibilidade com quem ainda passa "?").

### 3.2 Superfícies e listas
1. `card(parent, variation)`: aceita `&"ReadyCardPanel"` como hoje; o visual vem do tema.
2. **Novo** `list_card(parent: Control) -> VBoxContainer`: `CardPanel` com `content_margin` 4 vertical/0
   horizontal e separação 0; as linhas dentro ganham divisória `LINE` de 1 px (desenhe com um
   `ColorRect` de 1 px entre linhas, não borda de estilo).
3. `list_row(...)`: altura 64, ícone/retrato 44 num disco `SUNKEN`, título `Label` 15, legenda `SmallLabel`
   com ícone 20, ação à direita. Novo parâmetro opcional no fim `ready: bool = false` → fundo `GO_SOFT`
   com canto 16.
4. **Novo** `section(text: String, right: Control = null) -> HBoxContainer`: rótulo `SmallLabel` com
   `uppercase = true` (propriedade do `Label`), cor `INK_SOFT` e fonte `font_caption_spaced.tres` (cópia do
   `font_caption` com `spacing_glyph = 1`, o "+6%" de espaçamento); `right` alinhado à direita.

### 3.3 Informação
1. `chip(texture, text, color = null, kind := "neutral")`: 28 de altura, ícone 24, `NumberLabel`-like 15
   (variação nova `ChipLabel`: `font_display` 15). Tipos: `neutral` (`SUNKEN`, `INK`), `prize`
   (`HONEY_SOFT`, `HONEY_INK`), `time` (`SKY_SOFT`, `SKY_INK`, ícone `ctl clock` 16 quando `texture == null`),
   `have` (`GO_SOFT`, `GO_INK`, `ctl check` 14 depois do número), `missing` (`ALERT_SOFT`, `ALERT_INK`).
   Quem passa só `color` continua funcionando (vira `neutral` com a cor do texto).
2. **Novo** `badge(count: int) -> Label` (selo vermelho com número, 20 de altura, borda 2 px da cor do
   fundo onde está — parâmetro `edge: Color = Palette.CARD`). `alert_badge()` passa a ser `badge(0)` sem
   número (pontinho 12).
3. **Novo** `dot() -> Control` (pontinho vermelho 12 com borda branca) e `spark() -> Control` (disco mel 22
   com `ctl spark` branco 13; significa "vale um momento").
4. `RingProgress`: novas propriedades `color` (padrão `SKY`) e `track` (padrão `SUNKEN`); espessura 4;
   tamanho padrão continua 56 (o `ui_base_test` confere). Atalho `UiKit.ring(texture, progress, color,
   px := 44) -> RingProgress`.
5. **Novo** `steps(total: int, current: int) -> HBoxContainer`: tracinhos 12×6 canto 3: feitos `GO`, atual
   `HONEY`, futuros `SUNKEN`; separação 3.
6. `bar(...)`: trilho `SUNKEN`, canto 4, altura padrão 8 (o parâmetro continua).

### 3.4 Escolha
1. `segmented(entries, selected, choose)`: mesmo contrato (cada `entry` tem `id`, `text`, `alert`). Visual:
   trilho `SUNKEN` canto 22, padding 4; opção ativa = pílula `CARD` com sombra pequena e texto `INK`;
   inativas texto `INK_SOFT`. Novos campos opcionais na entry: `icon: Texture2D` (24, à esquerda) e
   `count: int` (selo vermelho com número à direita; quando `alert == true` e sem `count`, pontinho).
   Mantenha o nome dos botões que os testes usam (confira `lists_test`, `tasks_groups_test`).
2. **Novo** `stepper(value: int, min_value: int, max_value: int, on_change: Callable) -> HBoxContainer`:
   trilho `SUNKEN` 44 de altura; botões disco `CARD` 36 com `ctl minus`/`plus`; no limite o botão fica sem
   fundo e `INK_FAINT`; número `×N` `font_display` 18. A `StationTray._stepper` passa a usar este na 07
   (não troque agora).
3. **Novo** `tile(texture: Texture2D, caption: String, state: String = "normal", missing: Texture2D = null) ->
   Button`: afundado (`PAPER` dentro de cartão branco), canto 16, ícone 36–40, legenda `SmallLabel`;
   estados `normal`, `selected` (fundo `CARD` + contorno 2,5 `INK` + sombra pequena), `missing` (ícone a
   45% + mini-disco `ALERT_SOFT` 22 com o `missing` 16 no canto de cima à direita), `locked` (`ctl lock`
   18 no meio, ícone a 35%).
4. **Novo** `toggle(on: bool, on_change: Callable) -> Button`: interruptor 48×28, trilho `GO` (ligado) ou
   `SUNKEN` (desligado), bolinha branca 22 com sombra; anima 0,15 s.

### 3.5 Produção, fala, folha, aviso de bloqueio
1. `SlotDot`: `DOT := 52`; `busy` = anel `SKY` + ícone + tempo embaixo (`SKY_INK`); `ready` = anel `GO`
   cheio + ícone + disquinho verde com `ctl check` no canto; `empty` = tracejado `INK_FAINT` com `ctl plus`;
   `queued` = anel tracejado `SKY`; `buy` = afundado + `ctl lock` + preço em chip pequeno embaixo; `level` =
   afundado + `ctl lock` + texto do nível embaixo. Mantenha `state`, `icon_rect` e os nomes de nó.
2. `SpeechBubble(text, speaker)`: novo parâmetro opcional `inside_card := false`. Solto: `CARD`, canto 16,
   sombra pequena, rabinho para o lado do retrato. Dentro de cartão: `PAPER`, sem sombra. O rótulo do nome
   (`speaker`) vira `SmallLabel` acima, sem pílula escura.
3. `lock_hint(text, on_help = Callable(), missing: Texture2D = null)`: `ctl lock` 18 + (ícone do que falta
   24 em disco `SUNKEN`) + uma linha `Label` 15; tocável quando `on_help` é válido (abre Como fazer).
4. `Sheet` (`scenes/ui/sheet/sheet.gd/.tscn`): fundo `SheetPanel` (01), alça 40×5 `LINE` centrada a 10 px do
   topo, título `TitleLabel` à esquerda, botão fechar `ctl_button("x", …, 32, "sunken")` à direita, margem
   lateral 16. Comportamento de arrasto, alturas (`sheet_size`) e sinais **não mudam**.
5. `Popover`: fundo `CARD` canto 16 sombra `SHADOW`; setinha de 8 px apontando para a âncora.

### 3.6 Movimento
1. `Motion`: novos tempos `FLY := 0.45`, `SHEET_IN := 0.26`, `SHEET_OUT := 0.18`, `TRAY_IN := 0.18`;
   novas funções `fly_arc(node: CanvasItem, from: Vector2, to: Vector2, seconds := FLY) -> Tween`
   (curva de Bézier quadrática com ponto de controle 80 px acima do meio; `TRANS_CUBIC`/`EASE_IN`) e
   `stagger_in(nodes: Array, gap := 0.03)` (pop_in de cada um com atraso). Ambas respeitam `Motion.reduced`.
2. `CollectFx._spawn`: usa `Motion.fly_arc` para o voo até o destino (o destino não muda nesta etapa).

### 3.7 Vitrine
`game/tests/ui2_kit_shots.gd` (não é teste; padrão dos `*_shots.gd`): monta numa tela 360×780 todas as
peças (botões nos estados, chips dos 5 tipos, anéis nas 4 cores, steps, stepper nos limites, tiles nos 4
estados, slots nos 6 estados, segmented com ícones e contagem, toggle ligado/desligado, list_card com 3
linhas uma pronta, speech bubble solto e dentro de cartão, lock_hint) e salva
`build/screenshots/i2_02_vitrine/vitrine.png`. Compare lado a lado com `prototipo/estilo.png`.

## 4. Não fazer
- Remover ou renomear funções existentes do `UiKit`.
- Reconstruir telas (Missões, Mochila, bandejas...) — elas ganham as peças pelo próprio `UiKit` e são
  refeitas nas etapas delas.

## 5. Armadilhas
- `list_row` é usado por muitas telas com alturas próprias: mude o visual, não o contrato; confira
  `lists_test` e `sheet_test` (`sheet_test.gd:244` usa largura útil 304).
- `segmented` mais alto (48) pode empurrar telas para baixo; confira Missões e Mochila nas capturas.
- `Motion.press` em botões dentro de `ScrollContainer`: a escala não pode atrapalhar o arrasto da lista.

## 6. Testes

**Teste novo `game/tests/ui2_kit_test.gd`** (área `ui_kit`; não precisa do `main`: monte as peças num
`Control` filho de `root`):
1. `primary`, `soft`, `small_go`, `ghost`, `ctl_button` (40 e 32), `icon_button`, `tile`, `toggle`,
   `stepper` (os dois botões), `segmented` (cada opção): `get_combined_minimum_size()` ≥ 44 em altura e
   largura **da área de toque** (para discos menores, o `Button` tem 44).
2. `primary` → `PrimaryButton`; `soft` e `secondary` → `SecondaryButton`; `small_go` → `SmallGoButton`.
3. `chip(..., kind)` para os 5 tipos: a cor de fundo do estilo bate com a bíblia; `have` contém um
   `TextureRect` com a textura `ctl check`.
4. `stepper(1, 1, 3, cb)`: o botão "−" está desligado; tocar "+" chama `cb(2)`; com valor 3 o "+" desliga.
5. `tile(..., "missing", tex)` tem o mini-disco com `tex`; `"locked"` tem a textura `ctl lock`;
   `"selected"` usa o estilo com contorno.
6. `segmented` com `count = 2` mostra selo com "2"; com `alert = true` e sem `count`, pontinho.
7. `steps(6, 2)`: 6 filhos; cores feito/atual/futuro certas.
8. `toggle(false, cb)`: tocar chama `cb(true)` e muda o estado visual.
9. `RingProgress.new()` continua 56×56; `UiKit.ring(..., px = 44)` tem 44×44.
10. `Motion.reduced = true`: `fly_arc` termina no destino no mesmo quadro.

**Atualizar:** `ui_style_test` se ele contar `PrimaryButton` em painéis que agora usam `small_go` (não
deve); `lists_test`/`sheet_test` só se um nome de nó mudar (não deve).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests ui2_kit_test,ui_style_test,ui_base_test,sheet_test,lists_test` (~1 min 10).

## 7. Capturas
- Vitrine (`ui2_kit_shots.gd`) e `--i2-01-only` (vitrine geral da 01) depois, nas 3 resoluções.

## 8. Pronto quando
- [ ] Vitrine parecida com `estilo.png` (diferenças anotadas).
- [ ] Nenhuma assinatura antiga do `UiKit` quebrou (o jogo abre todas as telas do `--i2-01-only`).
- [ ] `ui2_kit_test` e a lista fechada verdes.

## 9. Registro
```
**Etapa 02 (data, executor):** peças novas no UiKit (soft, small_go, ctl_button, list_card, section,
chip por tipo, badge/dot/spark, ring, steps, stepper, tile, toggle), SlotDot 52, SpeechBubble, Sheet,
Popover, Motion.fly_arc/stagger_in. Testes … PASS em … s. Diferenças da vitrine: … Pendências: …
```
