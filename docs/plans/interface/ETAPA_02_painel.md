# Etapa 02 — Painel novo: do tamanho do conteúdo, compacto e arrastável

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_02_painel.md."
> Pré-requisito: Etapas 00 e 01.

## Objetivo (o que o jogador sente)
"O painel abre do tamanho certo, eu continuo vendo o mundo em cima, e consigo fechar puxando para baixo."
Fim do painel de 70% com meia tela vazia; espaços de produção viram bolinhas; listas cabem 4–5 itens.

## Leia antes
`scenes/ui/sheet/sheet.tscn` + `sheet.gd`, `main.tscn` (onde o Sheet fica), `sheet_builder.gd`
(`slot_frame`, `_slot_card`, `_locked_slot`, `station_view`, `stations_view`, `_recipe_card`, `food_picker`,
`item_detail`), `progression_ui.gd` (`npc_view`, `npc_header`, `npc_introduction`, `routes_panel`,
`walks_panel` — só a parte dos espaços, `sell_panel`), `nature_ui.gd` (espaços e materiais),
`npc_portrait.gd`.

## Passo a passo

### 2.1 Alturas: meia, alta e automática
- [ ] `Events.sheet_requested(title, content)` **não muda**. O conteúdo pode pedir altura com
  `content.set_meta("sheet_size", "half" | "tall")`; sem meta = **automático**.
- [ ] Automático: depois do layout (`await get_tree().process_frame`), mede
  `content.get_combined_minimum_size().y + cabeçalho`. Se couber em **55%** da altura útil → altura do
  conteúdo (mínimo 30%); senão → **88%** com rolagem.
- [ ] O painel fica preso embaixo (âncora inferior); a altura muda por `offset_top`. Ao trocar o conteúdo
  com o painel aberto (ex.: comprar e o `LiveBox` refazer), a altura acompanha com tween de 0,18 s
  (só cresce/diminui se mudar mais de 24 px, para não "respirar").
- [ ] Painéis que já sabem que são longos marcam `tall`: `inventory_view`, `collection_panel`,
  `GameManual.panel`, `ProgressionUi.walk_diary`, `sell_panel`, `story_panel`.

### 2.2 Alça, fechar arrastando e cabeçalho único
- [ ] No topo do painel: alça 40×5 `CARD_LINE` centrada (nó `Handle`), área de arrasto = faixa de 28 px
  do topo **e** o título.
- [ ] Arrastar para baixo move o painel junto do dedo; ao soltar: desceu > 25% da altura **ou** velocidade
  > 900 px/s → fecha (desliza para baixo, 0,2 s); senão volta (`TRANS_BACK`). Arrastar para cima num painel
  automático/meio → vira alto (88%).
- [ ] Rolagem do conteúdo continua funcionando (o arrasto do painel só vale começando na alça/título,
  ou quando o `Scroll` está no topo e o dedo desce — igual aos apps).
- [ ] Fechar também desliza (hoje `close()` some de uma vez): `close()` anima e só então `hide()`; os
  testes que chamam `sheet_close_requested` e esperam o painel fechado precisam funcionar —
  use `Motion.reduced` nos testes **ou** esconda o `ContentHolder` na hora e anime só o fundo. Escolha a
  segunda opção (mais segura) e anote.
- [ ] Botão fechar = `UiKit.icon_button(ui_close)` 44 (mantém nome `CloseButton`). Título `TitleLabel`.
- [ ] **Título único:** `stations_view` só mostra o nome de cada estação se houver **mais de uma estação
  visível** (hoje conta as ids, inclusive as ainda não liberadas → "Cozinha" + "Fogão"). `item_detail` usa
  o nome do item como título (quem chama: `inventory_view` e `GameManual`). Procure outros títulos
  genéricos ("Mochila" para item, "Construir") e use o nome da coisa.

### 2.3 Espaços de produção em bolinhas — `UiKit.slot_dot`
- [ ] Nova peça (Control 56×56 + legenda 18 embaixo, total ~76 de altura):
  | Estado | Desenho |
  |---|---|
  | vazio | círculo tracejado `CARD_LINE` (desenhar 12 arcos curtos), sem texto |
  | na fila | ícone do produto 32, `modulate.a 0.6`, legenda "Na fila" |
  | produzindo | `RingProgress` `INFO` + ícone, legenda tempo (`TimeText.short`) |
  | pronto | `RingProgress` cheio `PRIMARY` + ícone + `ui_check` pequeno no canto; `Motion.pulse` |
  | fechado (comprar) | círculo `SUNKEN` com "+" 28 e legenda moeda+preço (`GOOD`/`BAD`) |
  | fechado (nível) | cadeado + legenda "Nível 2" |
- [ ] `SheetBuilder.slot_frame(...)` passa a desenhar via `slot_dot` (mesma assinatura → todos os painéis
  que usam o molde mudam juntos: estações, Natureza, rotas, passeio). A fileira de espaços vira
  `HBoxContainer` alinhado à esquerda com separação 8 (não `EXPAND_FILL`).
- [ ] Nomes de nós usados nos testes continuam: `LockedSlot_<id>`, `WalkSlot`, `GatherItem_<local>_<i>`.
- [ ] O rótulo de seção acima dos espaços sai ("Preparando 0/3", "Coletas · 0/3"): os pontinhos já dizem
  isso. Se houver prontos, o botão "Pegar tudo (N)" (`primary`) fica **ao lado** da fileira.

### 2.4 Linha de lista — `UiKit.list_row`
```gdscript
## Linha baixa: [ícone 48] [título + chips numa linha] [ação à direita]. Toque na linha = on_tap (opcional).
static func list_row(texture: Texture2D, title: String, chips: Array[Control], action: Control = null, on_tap: Callable = Callable()) -> PanelContainer
```
- [ ] Altura 64–72, `CardPanel`, separação 8 entre linhas. Chips em `HFlowContainer` (podem quebrar).
- [ ] Aplicar em: `_recipe_card` (receitas das estações: ícone · nome · [⏱ tempo] [ingredientes] · Fazer),
  `seed_picker`, `food_picker`, `sell_panel`, materiais da `NatureUi`, lista de rotas. Resultado esperado:
  **4 receitas por tela** no fogão (hoje 1,5).
- [ ] Ingredientes: chips `item_chip` (já tocáveis quando faltam); efeitos (barriga/coração) só nas comidas.

### 2.5 Fala de personagem em balão
- [ ] `ProgressionUi.npc_header`: retrato 96 à esquerda, ancorado embaixo; à direita, balão `CARD` com
  "rabinho" apontando para o retrato (triângulo de 10 px desenhado no `_draw` de um Control) e etiqueta
  com o nome (`PillPanel` pequeno sobre o canto do balão). Texto 22.
- [ ] `npc_view`: balão + cartão da missão logo abaixo; painel em altura automática → sem meia tela vazia.
- [ ] `NpcPortrait` (aceno) continua fora do corpo reconstruído (regra do `CLAUDE.md`).

### 2.6 Animação
- [ ] Abrir: `Motion.slide_up` do painel + `DIM` de 0 → 0,45 (já existe; trocar para os tempos do `Motion`).
- [ ] Trocar conteúdo com o painel aberto: conteúdo novo entra com fade 0,12 s.

## Testes
- [ ] `game/tests/sheet_test.gd` (novo): conteúdo pequeno (1 label) → altura ≤ 55%; conteúdo com 30
  linhas → 88%; meta `tall` → 88%; `sheet_close_requested` deixa o painel fechado no mesmo quadro
  (para os testes antigos); simular arrasto (chamar o handler com eventos de mouse) > 25% → fecha.
- [ ] `stations_view(["stove", "blender"])` sem o liquidificador: **não** mostra o título "Fogão".
- [ ] Testes existentes que procuram `slot_frame`/`LockedSlot_*`/`WalkSlot` continuam passando.

## Capturas
Tour `etapa02_antes`/`etapa02_depois`. Confira: b12 fogão (bolinhas + 4 receitas), b15 Bosque, b16 Passeio,
b17 fala da Laís (sem vazio), a05 geladeira (painel baixo), b04/b18 item com o nome no título.

## Lista de conferência (aceite)
- [ ] Painéis curtos não cobrem o mundo inteiro; o mundo aparece acima deles.
- [ ] Arrastar a alça fecha; rolagem das listas continua normal.
- [ ] Espaços de produção em bolinhas em todos os painéis que usam o molde.
- [ ] Fogão mostra ≥ 4 receitas sem rolar em 360×780.
- [ ] CLAUDE.md/AGENTS.md: linha "Painel de produção/coleta (padrão)" atualizada (bolinhas + `list_row`), e
  linha nova sobre alturas do Sheet (`sheet_size`).
- [ ] ROADMAP e README marcados; commit `feat(ui): painel do tamanho do conteúdo, bolinhas de produção e linhas compactas`.
