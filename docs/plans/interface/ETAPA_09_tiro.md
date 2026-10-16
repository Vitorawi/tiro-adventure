# Etapa 09 — Tela do Tiro: cenário, anéis e cuidar com as mãos

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_09_tiro.md."
> Pré-requisito: Etapas 00–08.

## Objetivo (o que o jogador sente)
"O Tiro está no cantinho dele, com janela e tapete. Arrasto o petisco até a boca e ele come; passo a
esponja nele e saem bolhas; jogo a bolinha e ele pula." (Pou / My Talking Tom.)
Hoje: fundo liso, 4 botões grandes, chips soltos (Manual/Atributos/Coleção/Truques) acima dele.

## Leia antes
`scenes/ui/pet_screen/pet_screen.tscn` + `pet_screen.gd` (necessidades, `_build_extras`,
`_build_wish_widgets`, `_build_away_view`, `_on_dog_input` — já tem carinho por "passadas"),
`scripts/ui/pet_animator.gd` (clipes disponíveis: confira `eat`, `happy_jump`, `bark`, `give_paw`, `roll_over`,
`chase_tail`, `sleep`...), `sheet_builder.gd → food_picker` ("Ele quer!"), `game_state.gd`
(`feed`, `play`, `bathe`, `pet`, `set_sleeping`, `away_text`/`walking`), `wish_ui.gd`, `trick_ui.gd`,
`game_manual.gd`, `progression_ui.gd` (`skills_panel`, `collection_panel`), `tests/wishes_test.gd`
(usa `WishBubble`, `MoodLabel`), `tests/manual_test.gd` (usa `ManualButton`, `ManualPanel`).

## Passo a passo

### 9.1 Cenário
- [x] Arte nova `assets/sprites/areas/pet/corner.png` (360×420): canto aconchegante do apartamento —
  parede creme com uma janela à esquerda, tapete redondo no chão onde o Tiro fica, uma plantinha.
  Receita: `create_image_pro` com referência `areas/house/room.png` ("same palette, floor and wall style"),
  "cozy corner of a small apartment, window on the left wall, round rug on the wooden floor in the center,
  small potted plant, front view, empty center for a pet, no characters, no text, pixel art".
- [x] Ocupa a área central da tela (atrás do Tiro). O Tiro fica sobre o tapete (sombra atual mantida).
- [x] Janela muda com a hora local: dia (06–17h) normal; pôr do sol (17–19h) `modulate` laranja suave;
  noite `modulate` azul-escuro + 3 estrelinhas desenhadas (pontos) na janela. Atualiza a cada minuto.
- [x] Dormindo: tela inteira com `modulate` 0,8 azulado + "Zz" saindo do Tiro (já existe o ícone de sono?
  use `action_sleep` pequeno subindo com `float_text`).

### 9.2 Necessidades em anéis
- [x] As 4 barras viram 4 `RingProgress` 64 numa fileira no topo (abaixo do HUD): ícone da necessidade
  no meio, cor `PRIMARY` (> 50%), `ACCENT` (25–50%), `DANGER` (< 25%, com `Motion.pulse`).
- [x] Tocar num anel: balãozinho "Barriga 72%" + a frase do `MOOD_TEXTS` se estiver baixo (2 s).
- [x] O `MoodLabel` (frase de humor) vira um **balão de fala** que sai do Tiro às vezes (quando o humor
  muda ou a cada ~20 s), não uma caixa fixa. Mantenha o nó `MoodLabel` (testes) dentro do balão.
- [x] Chip do vínculo (`BondChip`) vai para a direita da fileira de anéis (coração + nível).

### 9.3 Bandeja de cuidados (embaixo)
- [x] Substitui os 4 botões. Faixa `PAPER` com cantos 22 em cima, altura ~112, acima das abas:
  - **comidas** da mochila (as mesmas do `food_picker`, com "×N"), em rolagem horizontal; a que o Tiro
    quer tem selo ♥ (`badge`) e vai primeiro;
  - **esponja** (ícone novo `action_sponge.png`) — banho;
  - **bolinha** (`action_play`) — brincar;
  - à direita, `secondary` pequeno **Dormir/Acordar** (o ícone muda; nome do nó `SleepButton` mantido).
- [x] Reaproveite a lógica de toque/arrasto da `ActionTray` (extraia a parte do fantasma/arrasto para uma
  classe comum, ex. `scripts/ui/drag_ghost.gd`, usada pelas duas — não duplique código).
- [x] **Comida:** tocar = `GameState.feed(id)` (como o "Dar"). Arrastar = fantasma da comida; ao soltar
  sobre a **boca** (retângulo da cabeça do Tiro, ~40% de cima do `DogSprite`) → `feed`; o Tiro faz o clipe
  de comer/feliz e sobem os chips de efeito (`float_text` "+20" com ícone). Soltar fora = nada.
  Desejo de comida cumprido pelo caminho certo: use a mesma função que o "Ele quer!" do `food_picker` usa
  (regra do `CLAUDE.md`: `feed` direto não cumpre desejo; `fulfill_wish`/"Ele quer!" cumprem).
- [x] **Esponja:** tocar = `bathe()` + bolhas. Arrastar esfregando sobre o Tiro: soma a distância percorrida
  sobre ele; a cada 260 px solta bolhas (partículas simples: 4 círculos brancos que sobem); ao chegar em
  ~800 px → `bathe()` uma vez e a esponja volta. (Use a mesma ideia do `STROKE_STEP` do carinho.)
- [x] **Bolinha:** tocar = `play()`. Arrastar e soltar com velocidade para cima = "jogar": a bolinha voa
  (tween parabólico), o Tiro faz `happy_jump`/`chase_tail` e `play()` é chamado uma vez.
- [x] **Carinho** no Tiro (arrastar a mão no Tiro sem item) continua como hoje.
- [x] Bloqueios (regras atuais): dormindo → só Acordar ativo, demais apagados com "Zzz"; passeando →
  bandeja some e a `AwayView` aparece (como hoje); desejos de comida mostram "Quando ele voltar".
- [x] Recargas/erros (`play`/`feed` devolvem falso) → `Motion.shake` no item + toast com o motivo.

### 9.4 Caderninho
- [x] `icon_button` 52 com ícone novo `ui_notebook.png` (caderninho marrom com fita) no canto superior
  direito, abaixo do HUD. **Nome do nó: `ManualButton`** (o `manual_test` toca nele e espera o manual).
- [x] Abre painel `tall` com abas segmentadas (`UiKit.segmented`, criar se não existir: pílulas lado a lado,
  a ativa `PAPER` com borda `PRIMARY`): **Manual** (padrão; contém o `ManualPanel`), **Atributos**
  (`skills_panel`), **Coleção** (`collection_panel`), **Truques** (`TrickUi`, só se a feature estiver
  liberada). Atributos/Coleção seguem as regras de revelar aos poucos (só aparecem quando liberados).
- [x] Selo "Novo" no caderninho quando uma das abas tiver novidade (`new_unlocks`).
- [x] Remover `Extras` (a fileira de chips) e o texto "Veja suas missões aqui embaixo!" (a aba já pulsa,
  Etapa 03).

### 9.5 Balão do desejo
- [x] `WishBubble` continua (nome mantido), agora com `Motion.bounce` a cada 3 s e o ícone do desejo 32.
  Tocar abre Desejos (como hoje).

## Arte
- [x] `areas/pet/corner.png` (cenário), `ui/icons/action_sponge.png` ("yellow kitchen sponge with soap
  bubbles"), `ui/icons/ui_notebook.png` ("small brown notebook with a red ribbon bookmark"). ART_PIPELINE.

## Testes
- [x] `game/tests/pet_care_test.gd` (novo): tocar na comida alimenta (barriga sobe, item −1); arrasto da
  comida soltando sobre a cabeça alimenta **uma vez**; soltando longe não alimenta; esponja: arrasto de
  800 px sobre o Tiro chama `bathe` uma vez; dormindo: comida apagada e tocar não alimenta; passeando:
  bandeja invisível; desejo de comida cumprido pelo arrasto conta como "Ele quer!".
- [x] `wishes_test`, `manual_test`, `tricks_test`, `walks_test` (AwayView) passam.

## Capturas
`etapa09_antes`/`etapa09_depois` (a01/b01) + `f01_pet_drag_food`, `f02_pet_sponge`, `f03_pet_sleep`,
`f04_pet_night` (force a hora), `f05_notebook_manual`, `f06_notebook_collection`, `f07_pet_low_needs`.

## Lista de conferência (aceite)
- [x] Tiro no cenário; anéis legíveis; nada solto flutuando acima dele.
- [x] Alimentar/banho/brincar por toque **e** por arrasto, no celular (touch_test com `ghost_drag`).
- [x] Regras de desejo/sono/passeio iguais às de antes.
- [x] CLAUDE.md/AGENTS.md: `ui/pet_screen/` na Estrutura (cenário, anéis, bandeja de cuidados, caderninho);
  linha "Manual" e "Desejos" atualizadas.
- [x] ROADMAP, ART_PIPELINE, README marcados; commit `feat(ui): tela do Tiro com cenário, anéis e cuidados por arrasto`.


## Ajustes pedidos pelo Vitor durante a execução (15/10/2026)
- O cenário da primeira geração foi mantido fiel. `PetBackdrop` tira só a moldura vazia, mantém a proporção e continua parede/piso; candidato com astronauta descartado, terceira geração cancelada.
- Sem nome Tiro no topo. O coração/nível fica na fileira dos quatro indicadores; o caderninho flutua à direita, fora da faixa.
- Quatro cuidados fixos, com o **mesmo formato, tamanho e alinhamento** (`UiKit.action_tile`): Dormir/Acordar também é circular.
- Comida abre uma guia **vertical**, com cinco linhas visíveis e rolagem para todas. Mais usadas primeiro por contadores existentes; desempate recente na sessão. O nome rola e o ícone arrasta. Isto substitui a rolagem horizontal prevista em 9.3.
- Validação/conferência: `build/test_logs/etapa09/verified.txt`, tours de 69 PNGs nos três tamanhos e `build/preview/etapa09/`; capturas/saves descartáveis de toque em `build/touch_test_etapa09_final/`. `DragGhost` preserva velocidade em posições duplicadas do mesmo dedo sem duplicar o movimento da esponja.
