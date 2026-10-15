# Etapa 10 — Missões, Desejos, Mochila e Coleção: listas compactas e filtros

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_10_listas.md."
> Pré-requisito: Etapas 00–09.

## Objetivo (o que o jogador sente)
"As abas de lista são organizadas: vejo tudo de uma vez, o que está pronto brilha, e acho as coisas
pelos ícones." Hoje: cartões altos (3 diárias = uma tela inteira), descrição repetida, seções empilhadas
na Mochila, botão "Vestir" grande em cada roupa.

## Leia antes
`scenes/ui/tasks_screen/tasks_screen.gd`, `progression_ui.gd` (`story_panel`, `quest_card`,
`quest_action`, `routine_card`, `collection_panel`, `_clothes_panel`, `goal_row`, `reward_chips`),
`scenes/ui/wishes_screen/` + `wish_ui.gd` (`header`, `slot_card`, `bond_bar`),
`sheet_builder.gd` (`inventory_view`, `item_detail`), `find_ui.gd`, `friend_ui.gd`,
`tests/tasks_test.gd`, `tests/wishes_test.gd`, `tests/finds_test.gd`, `tests/friends_test.gd`.

## Passo a passo

### 10.1 Peça nova: abas segmentadas
- [ ] Se a Etapa 09 ainda não criou: `UiKit.segmented(options: Array[Dictionary], selected: String, on_select: Callable) -> HBoxContainer`
  — `options` = `{id, text, icon}`; pílulas de altura 40; ativa `PAPER` com borda 2 `PRIMARY` e texto `INK`;
  inativas `SUNKEN` com texto `INK_SOFT`. Toque troca com `Motion.bounce`.

### 10.2 Missões
- [ ] **História (cartão do topo):** mantém a estrutura (é a ação principal), com melhorias:
  - à direita do título, miniatura 64 do **lugar** do passo (ícone do lugar sobre a cor do mundo) em vez
    da linha "Casa › Laís" pequena;
  - objetivo com ícone 48 + `3/6` + barra grossa (10 px, cantos redondos);
  - `primary` "Ir" grande; quando pronto, vira "Pegar prêmio" com `Motion.pulse` e o cartão `ReadyCardPanel`;
  - "Capítulo 1/9 ›" vira só a fileira de pontinhos dos passos + nome do capítulo (sem "1/9").
- [ ] **Diárias/Semanais:** cada missão vira uma `list_row` (altura ~76):
  `RingProgress` 52 com o ícone do objetivo · nome (`Label`) + instrução curta (`SmallLabel`, a `description`,
  pode quebrar) · chip do prêmio · à direita `secondary` pequeno "Ir" ou, se pronta, `primary` pequeno
  "Pegar". Contagem regressiva ("23h 28") como pílula no título da seção.
- [ ] Se 2+ missões prontas: botão "Pegar tudo" (`primary`) no topo da seção, e as linhas prontas ficam
  `secondary` (regra de um principal).
- [ ] Missão pega: a linha some com `pop_out` e as moedas voam (`CollectFx`).

### 10.3 Desejos
- [ ] Cabeçalho: Tiro (retrato) + "O que o Tiro quer" + barra do vínculo (corações).
- [ ] Cada espaço: cartão com ícone 64 do desejo à esquerda, frase do desejo (`Label`), progresso
  (barra ou `tem/precisa`), prêmio em chips; ações: `primary` "Dar" **só** se cumprível; senão `secondary`
  pequeno "Ir"; trocar = `icon_button` "↔" no canto superior direito do cartão; "?" = `icon_button`.
- [ ] Espaço fechado: `lock_hint` ("Com vínculo ♥4"). Espera de reposição: anel com o tempo.

### 10.4 Mochila
- [ ] Topo: **depósitos** em linhas finas — ícone da estação (Etapa 00) + nome + barra + `3/80`
  (Geladeira, Baú, Silo, Armazém…), em vez de ícones soltos. Toque numa linha filtra a grade pelos itens
  daquele depósito.
- [ ] Filtros `segmented` com ícones: Tudo · Comidas · Colheitas · Materiais · Passeio (só as categorias com
  itens). Sem seções empilhadas.
- [ ] Grade de 4 colunas, quadradinhos 76: `CARD`, ícone 48, quantidade "×3" no canto inferior direito
  (`NumberLabel` 18). Item novo desde a última vez que abriu a Mochila (`seen["ui:bag:<id>"]`) ganha selo "Novo".
- [ ] Toque → `item_detail` em altura automática (Etapa 02), título = nome do item:
  ícone 64 + "Você tem 3" (ou "Você não tem" em `INK_SOFT` — **nunca** "×0"); `primary` "Dar ao Tiro" se for
  comida (ou "Vender por 🪙3" quando estiver na Vila? não — vender continua na feira); "De onde vem" e
  "Usado em" como chips tocáveis (já existem).

### 10.5 Coleção (Roupas / Achados / Amigos)
- [ ] Abas `segmented` (no lugar dos três botões laranja).
- [ ] Roupas: grade de 3 colunas, quadrados 100 com o ícone 64 e o nome embaixo (`SmallLabel`); **tocar
  veste/tira** (com `Motion.bounce` e um "check" verde no canto quando vestida). Sem botão "Vestir".
  Nó de cada quadrado: `Equip_<id>` (o teste procura). Não possuídas: silhueta (já existe) + cadeado.
- [ ] Contador "18/33" vira barra fina com o número.
- [ ] Achados e Amigos: mesmas grades/silhuetas (reaproveite).

## Testes
- [ ] `tasks_test`, `wishes_test`, `finds_test`, `friends_test`, `walks_test`, `petshop_test` passam
  (ajuste o que procurava botões por texto antigo — anote).
- [ ] `game/tests/lists_test.gd` (novo): 3 diárias cabem numa tela de 780 (altura total da seção < 300);
  com 2 prontas aparece "Pegar tudo" e só 1 `PrimaryButton`; Mochila sem "×0" (item com 0 não aparece na
  grade; detalhe mostra "Você não tem"); filtro "Colheitas" esconde comidas; tocar em `Equip_red_scarf`
  veste e tocar de novo tira.

## Capturas
`etapa10_antes`/`etapa10_depois` (a02, b02, b03, b04, b18, b20, b21) + `g01_tasks_ready_many`,
`g02_bag_filter`, `g03_collection_grid`.

## Lista de conferência (aceite)
- [ ] Missões: 3 diárias + 1 semanal + história visíveis com pouca rolagem.
- [ ] Mochila com filtros e depósitos com nome.
- [ ] Coleção sem botões repetidos.
- [ ] CLAUDE.md/AGENTS.md: "Mudar a aba Missões / Mochila" e "Vestir o Tiro" atualizadas (`segmented`, toque para vestir).
- [ ] ROADMAP e README marcados; commit `feat(ui): listas compactas em Missões, Desejos, Mochila e Coleção`.
