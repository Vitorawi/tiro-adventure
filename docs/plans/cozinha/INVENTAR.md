# Cozinha — aba "Inventar" (Figma)

Pedido do Vitor (16/11/2026): o alternador Pratos/Inventar do `CookPanel` passa a trocar de verdade. A aba
**Inventar** usa o MESMO painel, o mesmo lugar e o mesmo fundo; muda só o miolo. Agora é a **carcaça funcional**:
poucos dados de exemplo, tudo orientado a dados (`game/data/invent.json`) para o Vitor depois só "brincar com os
elementos". Sem estrelas, corações etc. Nada além do Figma.

Figma `P7Z4cRwe49bHtmG67CG23z`:
- **FogaoInventar** (nó `3907:16`): tela principal da aba.
- **FogaoIngredientes** (nó `3909:213`): janelinha de escolher ingrediente (abre ao tocar num espaço).

Coordenadas abaixo em unidades do Figma **relativas ao quadro** `containercozinha` = canto (−345, −538), como no
`README.md` desta pasta (o `CookPanel` já monta tudo num `Control` com `scale = s`, quadro em x = 10·s).

## Arte (exportar a 1,5x, como na aba Pratos)

Baixar cada nó com `download_assets` (scale 1.5) para `IUREF/cozinha/inventar/nodes/<nome>.png` e tratar com
`tools/cook_layout_art.py` (mesmo `key_gray`/`trim`, mesmos tamanhos = retângulo do Figma × 1,5), saída
`game/assets/sprites/ui/cook_ui/ck_inv_*.png`, depois `--import` e `mipmaps/generate=true`.

| nó | nome local | saída | retângulo (rel. ao quadro) |
|---|---|---|---|
| 3907:21 | inv_cover (image 8) | entra no fundo `ck_inv_panel_top/mid/bottom` | (32, 389, 631×654) |
| 3909:115 | type_on | `ck_inv_type_on` | (78, 246, 113×118) |
| 3909:122 | type_off | `ck_inv_type_off` | (214, 246, 118×116) |
| 3909:136 | slot_legume | `ck_inv_slot_legume` | (41, 389, 173×182) |
| 3909:140 | slot_protein | `ck_inv_slot_protein` | 150×182 |
| 3909:147 | slot_fruit | `ck_inv_slot_fruit` | 149×182 |
| 3909:145 | slot_dairy | `ck_inv_slot_dairy` | 155×182 |
| 3909:153 | slot_grain | `ck_inv_slot_grain` | (491, 389, 154×182) |
| 3909:149 | slot_free | `ck_inv_slot_free` | 141×182 |
| 3909:156 | slot_filled (image 35) | `ck_inv_slot_filled` | (65, 446, 124×101) = frente dourada por cima do espaço |
| 3909:175 | card_unknown (image 41) | `ck_inv_card_unknown` | (31, 572, 634×459) |
| 3909:168 | bowl_unknown (image 38) | `ck_inv_bowl_unknown` | (62, 644, 128×127) |
| 3909:172 | box_hint (image 40) | `ck_inv_box_hint` | (64, 767, 568×120) |
| 3907:71 | btn_together | `ck_inv_btn_together` | (154, 869, 387×129) |
| 3909:183 | card_known (image 42) | `ck_inv_card_known` | (31, 572, 634×459) |
| 3909:188 | box_known (image 43) | `ck_inv_box_known` | (75, 757, 544×112) |
| 3909:192 | plate_known (image 44) | `ck_inv_plate_known` | (75, 639, 121×116) |
| 3909:196 | card_empty (image 45) | `ck_inv_card_empty` | (31, 572, 634×459) |
| 3909:208 | ring_empty (image 49) | `ck_inv_ring_empty` | (72, 638, 127×127) |
| 3909:211 | box_info (image 50) | `ck_inv_box_info` | (48, 748, 600×200) |
| 3909:259 | pick_panel (image 49) | `ck_inv_pick_top/mid/bottom` (fatiado, faixa do meio lisa) | (9, 526, 665×538) |
| 3910:268 | pick_head_match | `ck_inv_pick_head_match` ("Combina com o espaço") | (62, 588, 300×43) |
| 3910:273 | pick_head_other | `ck_inv_pick_head_other` ("Outros ingredientes") | (65, 778, 300×47) |
| 3910:331 | pick_close | `ck_inv_pick_close` | (582, 546, 81×83) |
| 3910:329 | pick_select | `ck_inv_pick_select` | (90, 969, 264×54) |
| 3910:334 | pick_remove | `ck_inv_pick_remove` | (354, 955, 241×80) |
| 3910:313 | cell_plain | `ck_inv_cell_plain` | (62, 827, 126×132) |
| 3910:284 | cell_rec | `ck_inv_cell_rec` (contorno verde) | (444, 640, 126×132) |
| 3910:279 | cell_on | `ck_inv_cell_on` (dourado) | (62, 636, 126×132) |
| 3910:293 | cell_out | `ck_inv_cell_out` (cinza) | (191, 640, 126×132) |
| 3910:309 | tag_pot | `ck_inv_tag_pot` ("Na panela") | (57, 636, 86×24) |
| 3910:302 | qty_pill | `ck_inv_qty_pill` | (99, 733, 49×22) |
| 3910:297 | out_pill | `ck_inv_out_pill` ("Acabou") | (210, 735, 86×35) |
| 3910:277 | pick_scrollbar | `ck_inv_pick_track` + `ck_inv_pick_thumb` | (546, 610, 128×386) |

Reaproveitar: `ck_toggle_dishes/invent`, `ck_cat_arrow` (a seta dos tipos é igual, em (610, 287, 47×49)),
`ck_panel_*` (só para comparar). O fundo da Inventar = `panel` + `image26` (217,184) + **inv_cover** (32,389), sem a
`image7` nem a `shelf` da aba Pratos. Fatiar igual (`top` até 790, `mid` = faixa lisa ladrilhada, `bottom`).

## Tela principal (FogaoInventar)

- **Alternador** (214, 159, 300×100): metade esquerda = Pratos, direita = Inventar; troca o desenho e o miolo.
  O modo fica guardado na sessão (static), como o resto da escolha.
- **Tipos de prato** (no lugar da fila de 4 espaços): faixa que rola na horizontal, janela x 72→606, y 240→370;
  cartões no passo 139, centros x = 134,5 + 139·i, topo y 246. Escolhido = `ck_inv_type_on` (113×118),
  não escolhido = `ck_inv_type_off` (118×116), ambos centrados no x do cartão. Dentro (IGUAL em todos): prato
  (`CookPanel.dish_pic` do item do tipo) centrado em (centro, 296), 74×50; nome centrado, topo y 322, 14 px,
  uma linha. Tocar escolhe (troca só o fundo). Seta (610, 287, 47×49) rola um cartão.
- **Espaços de ingrediente** (até 4; o exemplo usa 3): topo y 389, 182 de altura. Cada desenho tem largura
  diferente (a aba do nome muda); alinhar pelo **corpo** (o quadrado debaixo da aba), medido no PNG pelo script de
  arte. Centros do corpo com 3 espaços = os do Figma: pos1 = legume em x 41, pos2 = legume em x 266, pos3 = grão em
  x 491. Com 1, 2 ou 4 espaços: espalhar igual entre o primeiro e o último centro de 3 (1 = o do meio).
  Vazio = arte do tipo (já tem o ícone e o "+"). Preenchido = arte do tipo + `ck_inv_slot_filled` + a figura do
  ingrediente (79×80) por cima, nas mesmas posições relativas do Figma (frente dourada em (+24, +57) do canto do
  legume; figura em (+47, +57)). Tocar abre a janelinha de ingredientes daquele espaço.
- **Cartão grande** (31, 572, 634×459), três estados (fica centrado no espaço livre: desce E/2):
  1. *Nada escolhido*: `ck_inv_card_empty`, anel tracejado `ck_inv_ring_empty` (72,638), título do tipo
     ("Sua Papinha", "Seu Petisco"...) em (205, 654, 287×48) 40 px, texto "Toque em um espaço para colocar seus
     ingredientes" em (208, 720, 407×19) 16 px, caixa `ck_inv_box_info` (48,748) com a dica longa do tipo em
     (164, 823, 420×57) 20 px. Sem botão.
  2. *Prato desconhecido* (escolheu algo e não bate com receita conhecida): `ck_inv_card_unknown`,
     `ck_inv_bowl_unknown` (62,644), nome "Prato desconhecido" (205,654), dica curta do tipo (208,720),
     `ck_inv_box_hint` (64,767) com a dica longa em (160, 805, 420×57), botão `ck_inv_btn_together` (154,869).
  3. *Prato conhecido* (os ingredientes escolhidos = exatamente as entradas de uma receita do fogão liberada):
     `ck_inv_card_known`, `ck_inv_plate_known` (75,639) com o prato (90, 672, 90×60), nome do item da receita
     (205,654), descrição curta (208,720), `ck_inv_box_known` (75,757) com "Prato já conhecido!" em
     (171, 791, 420×57), mesmo botão (154,869).
  Textos: fonte da madeira, tamanho fixo por campo, reduz até caber (até 2 linhas na caixa).
- **Cozinhar junto** (pedido do Vitor): conhecido → `GameState.cook_many(receita, 1)` (regra de hoje).
  Desconhecido → prato surpresa PROVISÓRIO: gasta os ingredientes escolhidos e põe na fila do fogão um item
  `invented_dish` ("Prato inventado") com tempo de `invent.json → invented.seconds` (60 s). Depois de entrar na
  fila, os espaços daquele tipo esvaziam. Erro (sem vaga, sem ingrediente) = aviso com o motivo.

## Janelinha de ingredientes (FogaoIngredientes)

Abre por cima do cartão grande (o resto da tela continua visível), modal: fundo `ck_inv_pick_*` em (9, 526, 665×538),
topo fixo; o fundo da janela, a rolagem e os botões descem com E (a faixa do meio é lisa e estica/ladrilha).

- X `ck_inv_pick_close` (582,546): fecha sem mudar nada. Toque fora da janela também fecha.
- Área que rola (janela x 50→545, y 582→952+E), com a barra própria `ck_inv_pick_track/thumb` em (546,610), igual à
  barra da lista de pratos (arrastar o pegador, setinhas, proporcional). Dentro, de cima para baixo:
  - cabeçalho `ck_inv_pick_head_match` (62,588);
  - grade dos **recomendados** do espaço (fixos, até 4 por linha): colunas x 62/191/318/444, linha y 640, 126×132;
  - cabeçalho `ck_inv_pick_head_other` (65,778);
  - grade dos **outros** ingredientes que combinam com o espaço e que o jogador TEM (quantidade > 0), linha y 827,
    passo vertical 140.
- Célula (igual em todas): figura do ingrediente (32, 18, 59×55) do canto da célula, nome centrado (y +73,
  16 px), pílula `ck_inv_qty_pill` (37, 93, 49×22) com "x<quantidade que tem>". Fundos: escolhida =
  `ck_inv_cell_on` (desenhada 4 px acima, como no Figma), recomendada = `ck_inv_cell_rec`, outra =
  `ck_inv_cell_plain`, recomendada com 0 = `ck_inv_cell_out` + `ck_inv_out_pill` "Acabou" (19, 95) no lugar da
  quantidade (não escolhível). Selo `ck_inv_tag_pot` "Na panela" em (−5, −4) na célula do ingrediente que JÁ está
  nesse espaço.
- Fora da rolagem: `ck_inv_pick_select` "Selecionar" (90,969) põe a célula escolhida no espaço e fecha;
  `ck_inv_pick_remove` "Remover" (354,955) esvazia o espaço e fecha.

## Dados (`game/data/invent.json`)

```json
{
  "schema": 1,
  "slot_kinds": { "legume": {"name": "Legume", "art": "ck_inv_slot_legume"}, ... protein/fruit/dairy/grain/free },
  "items": { "carrot": ["legume"], "corn": ["grain"], "egg": ["protein"], ... },   // free aceita todos daqui
  "recommended": { "legume": ["carrot", "potato", "pumpkin", "sweet_potato"], ... },
  "dish_types": [
    {"id": "papinha", "name": "Papinha", "dish": "puppy_mash", "title": "Sua Papinha",
     "slots": ["legume", "legume", "grain"], "hint": "...", "hint_long": "..."},
    ... (5 tipos de exemplo para a faixa rolar)
  ],
  "invented": {"item": "invented_dish", "seconds": 60}
}
```

Um tipo pode sobrescrever `recommended` por espaço. Combinar com receita: multiconjunto dos ingredientes escolhidos
(1 unidade por espaço) == `inputs` de uma receita do fogão sem `content_error`.

## Feito (16/11/2026, local)

- Arte: `tools/cook_layout_art.py` (seção "Inventar") → `ck_inv_*.png` + `ck_inv_slots.json` (medidas do corpo; o código usa o centro do desenho, diferença < 0,4 unidade). Exports em `IUREF/cozinha/inventar/nodes/`. O painel `3907:19` é idêntico ao antigo. Fundo `ck_inv_panel_top/mid/bottom` (mesma linha 790; a faixa do meio é lisa). A janelinha é UM NinePatch vertical `ck_inv_pick.png` (margens 150 px em cima e embaixo), no lugar de top/mid/bottom. Barra: `ck_inv_pick_track/thumb` (22,67 × 337,33, em (598,67; 634)).
- Dados: `game/data/invent.json` (6 tipos de espaço, 18 ingredientes crus, recomendados, 5 tipos de prato, `invented`), `Database.invent`, `Database.invent_problems()`. Item provisório `invented_dish` ("Prato inventado", ícone da papinha da vovó). A receita escondida `invented_dish` (`hidden: true`, fogão, sem ingredientes fixos) é registrada em memória por `Database._register_invented_recipe`; `recipes_for` pula `hidden`, então não aparece em Pratos nem na maestria por receita.
- Regra: `GameState.invent_match(items)`, `cook_invented_error/cook_invented(items)` (mesmo caminho do `cook_many`: lote com snapshot, `collect` entrega 1). Conta como lote do fogão (`station_jobs:stove`, `produce:invented_dish`, `production_jobs`), sem receita nova. Sem mudança de `SAVE_VERSION`.
- Tela: `CookInvent` (`scripts/ui/cook_invent.gd`) e `CookInventPicker` (`cook_invent_picker.gd`); alternador no `CookPanel` (`invent_mode`, `_set_mode`). Nós: `InventView`, `InvType_<id>`, `InvTypeArrow`, `InvSlot_<i>`, `InvCard`, `InvCardName`, `InvCookButton`, `InvPicker`, `InvPickerScroll`, `InvCell_<item>`, `InvSelect`, `InvRemove`, `InvPickerClose`, `InvPickerBar`, `InvPickerCatcher`.
- Diferenças em relação à especificação: a janela de rolagem da janelinha vai de x 50 a 596 (não 545: as células chegam a 570); a quantidade da célula é "o que tem menos o que já está nos outros espaços"; o cabeçalho "Outros ingredientes" some se não há nenhum; tocar no cartão vazio não faz nada; sem aviso de sucesso ao cozinhar (os espaços esvaziam).
- Provisório: prato inventado (item, ícone, efeito, 60 s), tipos de prato e ingredientes de exemplo.
- Testes: `cook_invent_test`; capturas `tests/cook_invent_shots.gd` → `build/screenshots/cook_invent/`.
