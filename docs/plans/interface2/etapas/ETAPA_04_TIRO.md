# Etapa 04 — Tela do Tiro: cenário aproximado e botão Cuidar com roleta

> Tamanho: grande. Depende de: 03. Próxima: 05.
> Resultado que o Vitor vê: o Tiro grande no meio da tela; as necessidades em anéis pequenos no topo; o
> desejo num balão branco com ✦; embaixo só o botão **Cuidar**, que abre a **roleta** espaçada e meio
> transparente (decisão do Vitor, 24/10/2026).

## 1. Ler antes
`02_JORNADA.md` §7; `03_TELAS.md` "Tiro"; protótipos `prototipo/tiro_cuidar.png` (fechado) e
`prototipo/tiro_roleta.png` (aberto), e o HTML `prototipo/tiro.html` (modos `#cuidar` e `#roleta`: posições,
ângulos, transparências). `04_REGRAS_E_TESTES.md` §E, §F.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Tela | `scenes/ui/pet_screen/pet_screen.gd` (697) / `.tscn` | anéis das necessidades em cartão (`_build_need_rings`, nós `NeedPillar_<id>`), balão do desejo (`_build_wish_widgets`, `WishBubble`), humor (`MoodLabel`, `MOOD_TEXTS`), caderninho (`ManualButton`), gestos do Tiro (`_on_dog_input`, `hold_*`, `spot_*`), efeitos (`care_bubbles`, `throw_ball`, `food_effects`, `brush_*`), `AwayView` no passeio, `dog_rect/head_rect/back_rect` |
| Cenário | `scripts/ui/pet_backdrop.gd` | `SOURCE := Rect2(36, 72, 289, 277)` de `areas/pet/corner.png`, largura cheia (escala ≈ 1,25), `RUG := Vector2(0.39, 0.8)`, `pet_feet()` = (0,39 × largura, 0,73 × altura), `scene_rect()` |
| Cuidados | `scripts/ui/pet_care_tray.gd` (520), classe `PetCareTray extends PanelContainer`, nó `CareTray` | faixa de 104 px com `FoodButton` (`action_tile`, abre `FoodMenu`), `Care_sponge`, `Care_ball`, `Care_brush` (`BrushTile`, só com a escova), `SleepButton`; `PlayGrowthTimer` (dica em texto); `ShampooToggle` ("Com xampu"); `FoodMenu` (guia vertical de comidas); seta `CarePointer` (`Polygon2D`, `point_at(id)` via `Events.care_requested`) |
| Motor dos gestos | `PetCareTray.press_item(id, ponto)`, `move_item(ponto)`, `release_item(ponto)`, `_act(id)`, `open_food_menu()`, `open_play_choice()`, `cancel()` | **toque sem arrastar**: esponja dá banho na hora, bola joga (ou abre Bola/Copinhos se `GameState.hide_unlocked()`), escova só avisa "Passe a escova nas costas dele"; **arrastar**: comida até a cabeça, esponja esfregando 800 px no Tiro, bola jogada para cima, escova 600 px nas costas |
| Testes que dependem | `pet_care_test` (ordem e nomes `FoodButton`, `Care_sponge`, `Care_ball`, `SleepButton`; `item_center`; `PlayGrowthTimer` contém "satisfeito"; `CarePointer` filho do item), `brush_taste_test` (ordem Comida → Banho → `BrushTile` → Brincar → Dormir), `wish_guide_test` (`CarePointer` como **`Polygon2D`** filho do `WishBubble`), `gestures_test` (`CareTray`), `walk_return_ui_test` (`SleepButton`), `pet_anchor_test` (âncora do Tiro) |

## 3. Passo a passo

### 3.1 Cenário aproximado
1. `PetBackdrop`: novas constantes `ZOOM := 1.75` (multiplica a escala de largura cheia) e `FOCUS_X := 168.0`
   (posição x do Tiro na base 360; proporcional em telas maiores: `size.x * 168 / 360`). `scene_rect()` =
   recorte escalado por `ZOOM`, posicionado para o tapete (`RUG`) cair em `FOCUS_X`; `pet_feet()` com y =
   `0.71 * size.y`. Parede acima e piso abaixo continuam preenchidos como hoje (pixel de amostra e faixa da
   última tábua).
2. O Tiro (`PetAnimator`) segue `pet_feet()`/escala do cenário: aumente a escala do Tiro na mesma proporção
   (`ZOOM`). Confira `pet_anchor_test` (ele mede âncoras relativas; atualize só números, não a regra).
3. Some o anel "5" solto e o balão "Crescer: …" (o crescimento está no avatar e no próximo passo).

### 3.2 Topo
1. Os quatro anéis das necessidades saem do cartão e vão para `Hud.set_row2_right(...)` só enquanto a aba
   Tiro está aberta: pílula `CARD` com 4 `UiKit.ring(icone, valor, cor, 40)` sem rótulo; cor `GO` normal,
   `ALERT` + `UiKit.dot()` quando `GameState.need_asking(id)`. Tocar num anel = `Popover` com nome e valor
   (ex.: "Barriga 35%"). Os nós `NeedPillar_<id>` continuam (agora dentro da pílula).
2. `ManualButton`: disco branco 52 (`IconButton`) com o caderninho pixel, à direita, a 46% da altura.
3. `MoodLabel`: etiqueta translúcida (branco 86%, canto 14, `SmallLabel` em `INK`) sob o Tiro; aparece 2,5 s
   quando o humor muda ou ao tocar no Tiro; escondida o resto do tempo e sempre com a roleta aberta.
4. `WishBubble`: balão branco canto 20 com rabinho de duas bolinhas, ícone 36 e `UiKit.spark()` no canto
   quando atender vale momento. Comportamento (abrir o cartão do desejo) igual.

### 3.3 Botão Cuidar e roleta (`PetCareTray` vira a roleta)
Mantenha a classe `PetCareTray` e o nó `CareTray` (os testes o procuram). Troque só a forma:
1. **Base:** `PetCareTray` passa a `extends Control` de tela cheia dentro do `PetScreen`
   (`mouse_filter = PASS` no fundo). Ele contém:
   - **`CareButton`** (novo): disco 72 branco 90% com anel mel 4 px e sombra, centrado na horizontal,
     com o centro a **126 px acima da borda de baixo** (logo acima do rodapé de 84); ícone `heart` pixel 42;
     etiqueta "Cuidar" (`SmallLabel` em pílula branca 85%) embaixo, só com a roleta fechada.
   - **`CareAsk`** (novo): disquinho 30 rosado (`ALERT_SOFT`, borda branca 2) no canto de cima à direita do
     `CareButton`, com o ícone do que ele pede (`GameState.asking_need()`: `hunger` → `dog_food`,
     `hygiene` → `action_sponge`, `happiness` → `action_play`, `energy` → `action_sleep`). Escondido sem
     pedido. **Tocar no `CareAsk`** = atalho: `hunger` → `open_food_menu()`; `hygiene` → `_act("sponge")`;
     `happiness` → o mesmo do toque na bola (`_act("ball")` ou `open_play_choice()`); `energy` → dormir.
   - **`CareWheelOpen`** (novo): véu radial (gradiente: alfa 0,26 perto do botão → 0,10 longe; com
     `Motion.reduced`, cor chapada 0,18), faixa em arco (branco 30%, espessura 82, raio 150, centrada no
     botão; desenhe em `_draw` com `draw_arc`) e os **discos**.
2. **Discos:** os itens que já existem viram discos 64 (branco **82%**, sombra suave, contorno interno
   branco 1,5 px) com o nome embaixo em pílula clara (branco 80%, `SmallLabel` `INK`). **Mesma ordem e
   mesmos nomes de hoje**: `FoodButton` (Comida) · `Care_sponge` (Banho) · `BrushTile`/`Care_brush`
   (Escovar, só com a escova) · `Care_ball` (Brincar) · `SleepButton` (Dormir/Acordar).
   Posições: centro no `CareButton`, raio 150, ângulos (graus, 0 = direita, contando para cima) com
   **cinco**: 160, 125, 90, 55, 20; com **quatro**: 155, 112, 68, 25. Disco pedido: fundo `ALERT_SOFT` 92% +
   `UiKit.dot()`; disco que vale momento: `UiKit.spark()` (substitui o texto do `PlayGrowthTimer`, que
   continua existindo **invisível** com o mesmo texto — `pet_care_test` lê o texto).
3. **Abrir/fechar:** tocar no `CareButton` abre (discos saem do botão com `Motion.stagger_in`, 30 ms,
   escala 0,6 → 1, `BACK`); o botão ganha um halo mel. Fecha ao: tocar no botão de novo, tocar fora dos
   discos, arrastar para baixo no véu, escolher um cuidado, trocar de aba. Dormindo: o botão vira a lua
   (`action_wake`) com a etiqueta "Acordar" e o toque acorda direto (a roleta não abre). Passeando:
   `CareTray` invisível (como hoje).
4. **Escolher (mesmo motor de hoje):** os discos recebem o `gui_input` que já existe
   (`_on_item_input` → `press_item`/`move_item`/`release_item`). Então: tocar e soltar = o toque de hoje;
   tocar e arrastar = o gesto de hoje (a ficha `DragGhost` segue o dedo). Ao **começar a arrastar**, a roleta
   fica com alfa 0,3 (como o `FoodMenu` hoje) e, ao soltar, fecha. `FoodButton` (tocar) fecha a roleta e
   abre o `FoodMenu`.
5. **`FoodMenu`:** cartão branco canto 20, linhas 56 (ícone 40 em disco, nome, chip de quantidade, coração da
   favorita, "Provar"), posicionado **acima do `CareButton`** (borda de baixo do cartão 12 px acima do
   botão, x = 12). `_place_menu()` usa o `CareButton` como âncora.
6. **`ShampooToggle`:** com a roleta aberta e xampu na mochila, chip "Com xampu" logo acima do disco Banho.
7. **Seta dos cuidados (`CarePointer`):** quando `Events.care_requested(id)` chega (ex.: `Ir` de um desejo),
   abra a roleta e ponha o alfinete sobre o disco certo. **A raiz continua `Polygon2D`** chamada
   `CarePointer` (o rabinho mel, apontando para baixo) e é **filha do disco** (ou do `WishBubble`, para
   `"wish"`), como hoje; o disco branco 40 com anel mel e o ícone ficam como **filhos** do polígono. Some
   quando a ação acontece ou ao sair da tela (regras de hoje).
8. **Rodapé:** com a aba Tiro aberta, `main.set_tab_joined(true)`; nas outras, `false`.

### 3.4 Tour
Bloco `--i2-04-only`: `i2_04_pet` (fechado, sem pedido), `i2_04_pet_ask` (fome baixa:
`state.call("dev_set_need", "hunger", 10.0)`), `i2_04_wheel` (aberta, cinco discos com a escova), `i2_04_wheel_four` (sem
escova), `i2_04_food_menu`, `i2_04_sleep` (dormindo, botão lua), `i2_04_pointer` (`Events.care_requested
.emit("sponge")`).

## 4. Não fazer
- Mudar regras dos cuidados (`feed`, `bathe`, `play`, `brush`, `pet`, sono) ou as distâncias dos gestos.
- Mexer no `PetAnimator` além da âncora/escala.
- Arte nova (a roleta usa os ícones que já existem).

## 5. Armadilhas
- `PanelContainer` → `Control`: o `PetCareTray._ready` monta estilo de painel; remova isso. O `custom_
  minimum_size.y = 104` some.
- Itens escondidos não recebem `gui_input`: os testes que chamam `press_item` direto continuam funcionando,
  mas os que enviam eventos de mouse para `item_center` precisam da roleta aberta — abra no teste
  (`tray.call("open_wheel")`), não mude a regra.
- O arco da roleta passa por cima do Tiro: os discos não podem pegar o toque do carinho fora deles (o véu
  só fecha a roleta; não faz carinho).
- O `DragGhost` sobe 40 px do dedo: com a roleta embaixo, o arrasto até a cabeça fica natural — confira o
  banho em 412×915.
- Popover dos anéis e roleta abertos ao mesmo tempo: abrir um fecha o outro.

## 6. Testes

**`game/tests/care_wheel_test.gd`** (área `pet`; modelo 04 §E.2, depois `main.call("show_screen", &"pet")`):
1. Fechado: `CareButton` visível; `CareWheelOpen` invisível; o centro do `CareButton` fica acima do topo do
   `Layout/TabBar` e a ≥ 8 px dele.
2. Tocar no `CareButton` abre: `FoodButton`, `Care_sponge`, `Care_ball`, `SleepButton` visíveis; sem a
   escova, 4 discos; com `basic_brush` na mochila (`GameState.inventory.add`), 5 e a ordem dos filhos é
   Comida, Banho, Escovar, Brincar, Dormir.
3. Espaçamento: distância entre centros de discos vizinhos ≥ 80 px; nenhum disco sai da tela (margem ≥ 4)
   em 360×780.
4. Tocar fora dos discos fecha; tocar no `CareButton` de novo fecha.
5. Tocar em `FoodButton` fecha a roleta e abre `FoodMenu`, e a borda de baixo do `FoodMenu` fica acima do
   `CareButton`.
6. Tocar e soltar `Care_sponge` dá banho (higiene sobe; `state.dog` antes/depois) e fecha a roleta.
7. Arrastar comida do `FoodMenu` até `head_rect()` alimenta (barriga sobe), como hoje (`press_item`/
   `move_item`/`release_item`).
8. `CareAsk`: com fome pedindo (`asking_need() == "hunger"`), está visível com o ícone `dog_food`; tocar abre
   o `FoodMenu`. Sem pedido, invisível.
9. Dormindo (`state.call("set_sleeping", true)`): tocar no `CareButton` acorda e a roleta não abre.
10. `Events.care_requested.emit("sponge")`: roleta aberta e um `Polygon2D` chamado `CarePointer` filho do
    `Care_sponge`.
11. `Motion.reduced = true`: abrir mostra os discos já no lugar final no mesmo quadro.

**Atualizar** (mesmas garantias, nova forma de achar/abrir): `pet_care_test` (abrir a roleta antes de
eventos de mouse nos itens), `brush_taste_test` (ordem continua), `wish_guide_test` (`CarePointer`
continua `Polygon2D`), `gestures_test`, `pet_anchor_test` (números da âncora), `care_ui_test` (anéis na
linha 2 do HUD).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests care_wheel_test,pet_care_test,care_ui_test,brush_taste_test,gestures_test,wish_guide_test,pet_anchor_test` (~2 min 30).

**Toque real (04 §F):** roteiro `build/touch_steps_i2_04.json`: tap no `CareButton` → shot; tap em Banho →
shot; tap no `CareButton` → tap em Comida → arrastar o primeiro item do `FoodMenu` até a cabeça do Tiro →
shot; tap fora → shot.

## 7. Capturas
`--i2-04-only` antes (use `--pet-only` como "antes") e depois nas 3 resoluções; compare com
`tiro_cuidar.png` e `tiro_roleta.png`.

## 8. Pronto quando
- [x] Embaixo só o rodapé e o botão Cuidar; a roleta abre espaçada, meio transparente, sem cobrir o rosto
      do Tiro com o véu escuro.
- [x] Todos os cuidados funcionam pela roleta, com toque e com arrasto, como antes.
- [x] O atalho do pedido no botão funciona para as quatro necessidades.
- [x] Testes da lista verdes; toque real feito e capturas abertas.

## 9. Registro
```
**Etapa 04 (data, executor):** cenário 1,75×, anéis na linha 2 do HUD, MoodLabel discreto, WishBubble novo,
PetCareTray como botão Cuidar + roleta (CareButton, CareAsk, CareWheelOpen), FoodMenu acima do botão,
CarePointer alfinete. Testes … PASS em … s. Toque real: … Diferenças do protótipo: … Pendências: …
```
