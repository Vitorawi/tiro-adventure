# Etapa 01 — Visual base: cartão não é botão

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_01_visual.md."
> Pré-requisito: Etapa 00.

## Objetivo (o que o jogador sente)
"Bati o olho e sei o que é botão." Cartões ficam leves (sem degrau), botões ficam vivos, cada tela tem
**um** botão verde, e "ainda não dá" vira um cadeado discreto em vez de um botão cinza largo.
É a mudança que mais tira a "cara de amador", e quase tudo acontece no tema e no `UiKit`, então vale
para o jogo inteiro de uma vez.

## Leia antes
`game/assets/theme/main_theme.tres` (todas as `sub_resource` e variações), `game/scripts/ui/ui_kit.gd`,
`progression_ui.gd` (`upgrade_card`, `quest_action`, `routine_card`, `item_chip`, `reward_chips`),
`sheet_builder.gd` (`food_picker`, `seed_picker`, `_recipe_card`, `inventory_view`), `wish_ui.gd`
(`slot_card`), `nature_ui.gd`, `places.gd` (`world_list`), `tasks_screen.gd`.

## Passo a passo

### 1.1 Tema (`main_theme.tres`)
Edite os `StyleBoxFlat` existentes (não crie um tema novo) usando os valores de `01 → B`:
- [ ] `card` (CardPanel): `bg_color = CARD`, `border_width_* = 2`, **`border_width_bottom = 2`** (sem degrau),
  `border_color = CARD_LINE`, cantos 14, `shadow_color = SHADE`, `shadow_size = 3`, `shadow_offset = (0, 2)`,
  `content_margin_* = 12`.
- [ ] `card_ready` (ReadyCardPanel): igual ao `card`, `border_color = PRIMARY`, `border_width_* = 3`,
  `bg_color` = `CARD` misturado 15% com `PRIMARY` (`Color("eef0c8")` aproximado).
- [ ] `chip` (ChipPanel/ChipButton): `bg_color = SUNKEN`, **sem borda**, cantos 999 (pílula),
  `content_margin` 6 horizontal / 2 vertical. `chip_pressed`: `SUNKEN` escurecido 10%.
- [ ] `btn_*` (Button = **secundário**): `bg ACCENT`, borda 2 `ACCENT_EDGE`, `border_width_bottom = 5`
  (degrau), cantos 12; `pressed`: degrau 2 e `content_margin_top` +3 (afunda); `disabled`: `SUNKEN`,
  borda `CARD_LINE`, degrau 2.
- [ ] `primary_*` (PrimaryButton): `bg PRIMARY`, borda/degrau `PRIMARY_EDGE`, texto branco
  (`font_color = Color.WHITE`, `font_outline_color = PRIMARY_EDGE`, `outline_size = 3`).
- [ ] `sheet_panel` (SheetPanel): `bg PAPER`, cantos 22 só em cima, sem borda, sombra para cima
  (`shadow_offset (0, -2)`, `shadow_size 8`).
- [ ] `close_*` (CloseButton): vira círculo 44 `CARD` com borda 2 `CARD_LINE` e "✕" `INK` (ou o ícone
  `ui_close.png`, ver 1.6).
- [ ] Novas variações:
  - `SecondaryButton` = alias do `Button` (para deixar a intenção explícita no código);
  - `GhostButton`: styleboxes vazios (`StyleBoxEmpty`), `font_color = INK_SOFT`, `font_pressed_color = INK`;
  - `IconButton`: círculo `CARD` + borda 2 `CARD_LINE`, `content_margin` 6;
  - `PillPanel`: `bg HUD`, cantos 999, `content_margin` 10/4;
  - `NumberLabel`: tamanho 22, `font_color INK_ON_DARK`, `font_outline_color INK`, `outline_size 4`;
  - `BadgeLabel`: tamanho 16, branco, stylebox `DANGER` cantos 10, margens 5/1.
- [ ] Tipografia: `TitleLabel` 30, `SectionLabel` 22 (`INK_SOFT`), `Label` padrão 22, `SmallLabel` 18 (`INK_SOFT`).
  Confira que nada quebra linha onde não devia (abas e chips usam `short_label`).

### 1.2 `UiKit`: peças novas e as antigas com o estilo novo
- [ ] `UiKit.button(...)` continua igual (para não quebrar chamadas), mas chama `Motion.press(result)`.
- [ ] Novas:
```gdscript
static func primary(text: String, on_pressed: Callable, texture: Texture2D = null) -> Button   # PrimaryButton
static func secondary(text: String, on_pressed: Callable, texture: Texture2D = null, small := false) -> Button  # altura 44 se small
static func ghost(text: String, on_pressed: Callable) -> Button  # GhostButton, altura 44
static func icon_button(texture: Texture2D, on_pressed: Callable, px := 44, text := "") -> Button  # IconButton; text p/ "?"
static func pill(texture: Texture2D, text: String) -> PanelContainer  # PillPanel + NumberLabel
static func lock_hint(text: String, on_help: Callable = Callable()) -> HBoxContainer  # ui_lock 32 + SmallLabel + "?" opcional
```
- [ ] `UiKit.square_button("?", ...)` passa a devolver um `icon_button` com texto "?" (mesma assinatura).

### 1.3 Um botão principal por tela
Troque `&"PrimaryButton"` repetido em listas por `secondary(..., small = true)`. Fica `primary` só a ação
principal do painel. Casos conhecidos:
| Onde | Hoje | Depois |
|------|------|--------|
| `seed_picker` | "Plantar" verde em cada semente | `secondary` pequeno "Plantar" (a bandeja da Etapa 07 substitui no mapa) |
| `food_picker` | "Dar" verde em cada comida | `secondary` pequeno; o que o Tiro quer ("Ele quer!") fica `primary` |
| `_recipe_card` (estações) | "Produzir" verde em cada receita | `secondary` pequeno com o `action_label` |
| `NatureUi` materiais | "Coletar" verde em cada material | `secondary` pequeno |
| `ProgressionUi.routine_card` | "Ir" verde em cada diária | `secondary` pequeno "Ir"; **pronta** = `primary` "Pegar prêmio" |
| `quest_action` (história) | "Ir" verde | continua `primary` (é a ação principal da aba) |
| `collection_panel` | "Vestir" laranja grande em cada roupa | `secondary` pequeno (a Etapa 10 troca por toque no cartão) |
| `sell_panel` | "+12" verde em cada item | `secondary` pequeno com moeda |
| `wish_ui.slot_card` | "Ir" verde | `secondary` pequeno; "Dar" (cumprível) = `primary` |
- [ ] Teste automático (1.7) garante no máximo um `PrimaryButton` **visível e habilitado** por painel nos
  painéis da tabela (exceção: listas de desejos/missões prontas, ver teste).

### 1.4 Bloqueado = cadeado
- [ ] `ProgressionUi.upgrade_card`: quando `upgrade_error != ""` por **requisito** (não por moedas), em vez de
  botão "Comprar" cinza + "?": `lock_hint(<motivo curto>, TaskHelp.open...)`. Falta de moedas continua botão
  desabilitado com o preço em `BAD` (é uma meta, não um bloqueio).
- [ ] `_recipe_card`/`seed_picker`/`NatureUi` com `content_error` (receita/planta fechada): cartão com
  `modulate.a = 0.55` + `lock_hint` no lugar do botão.
- [ ] Mesma regra em `quest_action` quando o passo não pode ser recebido ainda? **Não** — lá o "Ir" sempre
  funciona. Só onde hoje há botão desabilitado + "?".

### 1.5 Cores soltas
- [ ] Procure `Color("` e `Color(0.` em `scripts/ui/` e `scenes/ui/` (`Select-String`). Troque por `Palette.*`
  nas telas desta etapa (worlds_screen `_build_cards`, `main.gd` badge, `UiKit`). Anote no ROADMAP as que
  ficarem para as etapas seguintes.

### 1.6 Arte (2 ícones)
- [ ] `ui_close.png` — "game UI icon: bold X close symbol, dark brown, rounded ends, no background, no text".
- [ ] `ui_check.png` — "game UI icon: bold green check mark with dark outline, no text" (usado nos balões
  de pronto, Etapa 06, e em listas).
  (O `ui_lock.png` veio da Etapa 00.)

### 1.7 Teste — `game/tests/ui_style_test.gd`
- [ ] Função `count_primary(node) -> int` (botões com `theme_type_variation == &"PrimaryButton"`, visíveis
  e não desabilitados, recursivo).
- [ ] Com `dev_unlock_everything` e ingredientes (dev_add_items): `station_view("stove")`,
  `seed_picker(3)`, `food_picker()`, `NatureUi.panel("trees")`, `ProgressionUi.collection_panel()`,
  `ProgressionUi.sell_panel()` → cada um `count_primary ≤ 1`.
- [ ] `UiKit.card` não tem degrau: `get_theme_stylebox("panel", "CardPanel").border_width_bottom == 2`.
- [ ] `lock_hint` contém um `TextureRect` com `ui_lock`.
- [ ] Todos os testes passam (se algum procurava `PrimaryButton` para achar um botão, ajuste-o para procurar pelo texto/nome).

## Capturas
`etapa01_antes`/`etapa01_depois` (tour inteiro). Confira em especial: b12 fogão, b07 sementes (painel),
b13 tigela, b20 coleção, b03 missões, a05 geladeira (cadeado), b14 feira.

## Lista de conferência (aceite)
- [ ] Cartões sem degrau; botões com degrau que afunda ao tocar.
- [ ] Nenhum painel da tabela 1.3 tem dois botões verdes.
- [ ] Bloqueios por requisito mostram cadeado + motivo, não botão cinza largo.
- [ ] Texto legível (nada abaixo de 18, exceto selos); nada cortado em 360 px.
- [ ] CLAUDE.md/AGENTS.md: variações novas do tema na linha "Visual da interface" e peças novas do `UiKit`.
- [ ] ROADMAP, ART_PIPELINE, README marcados; commit `feat(ui): tema novo — cartão leve, botão principal único, cadeado`.
