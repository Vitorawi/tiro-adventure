# Cozinha nova (fogão) — layout do Figma

Pedido do Vitor (15/11/2026): refazer SÓ a tela que abre ao tocar no **fogão**, igual ao Figma
`P7Z4cRwe49bHtmG67CG23z`, página **FogaoAutDetalhe** (nó `3895:13`). Nenhuma regra nova: usa a fila/receitas
que já existem (`GameState.cook_many`, `collect`, `station`, `cook_error` etc.). As outras estações continuam
na bandeja de madeira (`StationTray`). Sem estrelas, corações, ossinhos ou qualquer coisa que não esteja no Figma.

## Arte

`tools/cook_layout_art.py` (Python + Pillow) lê os exports das camadas em `IUREF/cozinha/nodes/` (1,5x, sobre o
cinza 229 da página) e grava `game/assets/sprites/ui/cook_ui/ck_*.png` com o cinza transparente. **Cada PNG tem
exatamente o tamanho do retângulo da camada no Figma × 1,5** (não é cortado), então basta desenhar cada imagem no
retângulo do Figma. Depois: `godot --headless --path game --import` e `mipmaps/generate=true` nos `.import`
(filtro `LINEAR_WITH_MIPMAPS`, como as outras telas de madeira).

| Arquivo | O que é |
|---|---|
| `ck_panel_top/mid/bottom.png` | painel (moldura, ícone do fogão, tábua da fila, caixa da lista e caixa tracejada do detalhe). Largura inteira do quadro (691,3); `top` = y 132,7→790, `mid` = 790→804,67 (**um período do tracejado: LADRILHAR, não esticar**), `bottom` = 804,67→1076,7 |
| `ck_toggle_dishes.png` / `ck_toggle_invent.png` | alternador com Pratos / Inventar escolhido (300×100) |
| `ck_slot_ready/busy/free/locked.png` | os quatro estados de um espaço da fila. `busy` está SEM o anel (o jogo desenha o anel de verdade). `free` já tem "+ Livre", `locked` já tem cadeado + "Ampliar" |
| `ck_ready_btn.png` | selo verde "Pronto!" (81×21) |
| `ck_cat_on/off.png` | cartão de categoria escolhido (dourado) / não escolhido (145×80) |
| `ck_cat_arrow.png`, `ck_ico_all.png` | seta ">" da faixa de categorias; ícone de "Todos" |
| `ck_filter_can/missing/tiro.png` | pílulas "Dá para fazer", "Faltam", "Do Tiro" (texto já desenhado) |
| `ck_dish_on/off.png` | cartão do prato escolhido (dourado) / não escolhido (160×164) |
| `ck_clock.png`, `ck_clock_detail.png` | relógio do cartão (18×17) e do detalhe (25×26) |
| `ck_scroll_track.png`, `ck_scroll_thumb.png` | trilho com as setinhas (sem o pegador) e o pegador amarelo, para a barra dinâmica |
| `ck_ingredient.png` | cartão de ingrediente (82×148), igual para todos |
| `ck_qty_ok/missing.png`, `ck_mark_ok/missing.png` | pílula verde/vermelha da quantidade e o selo ✓ / ! |
| `ck_btn_queue.png`, `ck_btn_together.png` | "Colocar na fila" (verde) e "Cozinhar junto" (texto já desenhado) |
| `ck_empty_detail.png` | "Toque num prato para ver o que precisa" (205×295), sem seleção |

## Medidas (unidades do Figma, relativas ao quadro `containercozinha` = canto (−345, −538))

Tudo é montado num `Control` em unidades do Figma com `scale = s`. A tela do Figma tem 710 de largura (x −355…355,
y −769…767), então `s = largura_da_tela / 710` e o quadro começa em x = 10·s. Imagens a 1,5x: cada `TextureRect`
com `expand_mode = IGNORE_SIZE` e `stretch_mode = SCALE` no retângulo do Figma.

**Altura variável.** Tudo com y ≥ 804,67 desce `E` unidades; a faixa `mid` vira `14,67 + E` de altura (ladrilhada).
`E = (fundo_disponível − topo_disponível)/s − 944` (944 = 1076,7 − 132,7). Topo disponível = logo abaixo da pílula
do mundo (`MapButton`) / linha 2 do HUD; fundo = 8 px acima do topo da barra de abas. Se `E < 0`, `E = 0` e `s`
diminui até caber (centralizado). Elementos que começam acima de 790 ficam no lugar.

- **Fechar** (pedido do Vitor): o X de madeira padrão (`ui/home/mission_close.png`, nó `CloseButton`, alvo ≥ 44 px
  na tela), no canto de cima à direita do painel, sobre a moldura, como na Venda/Encomendas. Tocar fora e Esc
  também fecham.
- **Estrelas** (pedido do Vitor): o espaço já existe, sempre 0 estrelas por enquanto (`ck_stars_0.png`).
  Cartão: estrelas em (18, 124, 50×18) e relógio + tempo em (83, 124) / (104, 124), como no Figma.
  Detalhe: estrelas `ck_stars_0_detail` em (434, 674, 75×27), traço fino em x 534 (y 676→700, cor da madeira),
  relógio (565, 674, 25×26) e tempo (595, 678) — substitui a linha "relógio + tempo centrados" abaixo. `ck_stars_1/2/3.png` ficam prontas para quando houver regra.
- **Alternador**: (214, 159, 300×100). Tocar em "Inventar" → aviso "Em breve!" (não troca).
- **Fila (4 espaços)**: centros x = 135,5 / 275,5 / 415,5 / 555,5, base y = 355. Cada estado é desenhado do seu
  tamanho (ready 129×97, busy 132×98, free 132×89, locked 140×92), centrado no x do espaço e com a base em 355.
  - *Pronto*: prato (30, 17, 74×50) + selo `ck_ready_btn` (24, 71, 81×21). Tocar = recolher (`GameState.collect`).
  - *Fazendo*: prato (30, 16, 74×50), anel de progresso centrado em (66, 39) do cartão, raio externo ~34, ~6 de
    espessura (trilho bege claro, progresso laranja), tempo restante centrado na pílula de baixo (48, 75, 38×17).
  - *Na fila (esperando)*: igual a Fazendo, anel vazio e o tempo total.
  - *Livre*: `ck_slot_free`. *Fechado*: `ck_slot_locked`, tocar abre a compra da próxima ampliação da fila.
  - Espaços = vagas que o jogador tem (estado pela fila) + fechados até completar 4.
- **Categorias**: faixa que rola na horizontal, janela x 32→605, y 388→469; cartões 145×80, passo 145. Dentro de
  cada cartão (igual em todos): ícone num quadro (12, 14, 52×52) e nome (66, 14, 72×52, até 2 linhas). "Todos"
  (`ck_ico_all`) + 4 de exemplo. Tocar escolhe (troca só o fundo on/off). Seta (610, 405, 47×49) rola um cartão.
  Por enquanto todas mostram a lista inteira.
- **Filtros**: (59, 496, 118×31), (183, 496, 92×31), (281, 498, 81×27).
- **Lista**: janela x 41→364, y 530→1022 (+E). Cartões 160×164, colunas x 41 e 204, passo vertical 164 (3 linhas
  à vista). Dentro do cartão (idêntico em todos): prato (36, 20, 89×60), nome (36, 80, 88×≈40, centrado, até 2
  linhas), relógio + tempo centrados na linha y 124 (relógio 18×17, tempo ~36×17). Escolhido = `ck_dish_on`.
- **Barra de rolagem**: trilho em (365,3, 539,7, 32,7×481,3), cresce com E (estica só o miolo liso). Pegador
  proporcional, arrastável; setinhas rolam uma linha.
- **Detalhe** (caixa tracejada x 420→657, y 485→1035+E):
  - Sem prato escolhido: `ck_empty_detail` centrado na caixa.
  - Prato (455, 503, 167×112), nome (447, 612, 174×≈50, centrado), relógio + tempo centrados em x 538,5, y 676.
  - Ingredientes: cartões em x 421 / 498 / 574, y 731, 82×148 (1 = só o primeiro, 2 = dois; sem centralizar).
    Dentro (ajuste pedido pelo Vitor): ícone (24, 10, 34×34), nome (4, 48, 74×56, centrado, até 3 linhas, UMA fonte fixa ≥ 18 para todos, sem reticências), pílula (10, 107, 61×33) verde
    se tem tudo / vermelha se falta, selo (44, 108, 27×30) ✓ / !, texto "tem/precisa" (14, 113, 32×20).
  - "Colocar na fila" (419, 886, 239×79) = o "Cozinhar" atual (1 lote). "Cozinhar junto" (414, 953, 250×84)
    → "Em breve!".
