# Etapa 08 — Bandeja nas estações, criações e Natureza

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_08_bandeja_estacoes.md."
> Pré-requisito: Etapas 00–07 (usa a `ActionTray` da Etapa 07).

## Objetivo (o que o jogador sente)
"Toco no fogão e aparece a fila e as receitas em ícones, ali do lado. Escolho o petisco, vejo se tenho
os ingredientes e toco em Cozinhar — sem sair do mapa. Com as galinhas é um toque para alimentar."

## Leia antes
`action_tray.gd` (Etapa 07), `room.gd` (`_on_object_tapped`, `_collect_station`, `_collect_site`,
objetos com `station`/`animal_station`/`route_group`), `sheet_builder.gd` (`station_view`, `_recipe_card`,
`animal_shop`, `slot_dot` da Etapa 02), `nature_ui.gd` (`panel`, materiais, níveis), `game_state.gd`
(`cook`, `cook_error`, `collect`, `station_slots`, `pending_slot_upgrades`, `animal_count`,
`start_gathering`, `start_next_gathering`, `gathering_*`), `places.gd` (`run`, `_panel`),
`config.json → stations` (`kind`, `action_label`, `queue_label`, `recipe_label`), `recipes.json`.

## Passo a passo

### 8.1 A bandeja ganha o modo "grade + detalhe"
- [ ] `ActionTray` aceita `options.mode = "pick"`: os itens viram uma **grade** (4 por linha, ícone 48,
  legenda tempo) e tocar num item **seleciona** (borda `PRIMARY`, `Motion.bounce`) em vez de agir.
  Abaixo da grade aparece a **linha de detalhe** do selecionado (`options.detail: Callable(id) -> Control`)
  com o botão de ação (`UiKit.primary`). Só existe um `primary` na bandeja.
- [ ] Cabeçalho (`options.header`): fileira de `slot_dot` (Etapa 02) da estação + botão "Pegar tudo (N)"
  quando houver prontos.
- [ ] Largura da bandeja neste modo: 328 (cabe em 360 com 16 de margem); setinha para o objeto.
- [ ] A bandeja **não fecha** ao agir neste modo (dá para enfileirar várias receitas); fecha ao tocar fora,
  mover a câmera ou ✕ pequeno no canto.

### 8.2 Estações de produção (fogão, liquidificador, bancada, moinho, queijaria, costura, ateliê)
Ao tocar no sprite da estação (`meta station`), depois do `_collect_station` (que já pega os prontos):
- [ ] Estação não comprada → continua abrindo a compra (painel, como hoje).
- [ ] Senão, abre a bandeja `pick`:
  - **cabeçalho:** bolinhas da fila (`GameState.station(id).queue`, `station_slots`) + bolinhas "+" das
    ampliações pendentes (`pending_slot_upgrades` → toque abre a compra). Nomes `LockedSlot_<id>` mantidos;
  - **grade:** `Database.recipes_for(id)`; bloqueadas (`content_error`) apagadas no fim; selo vermelho "!"
    nas que faltam ingredientes (`cook_error` por falta de item);
  - **detalhe:** nome + chips dos ingredientes `tem/precisa` (`ProgressionUi.item_chip`: o que falta é
    tocável e abre o "Como fazer") + saída (`ícone ×qty`; comidas: chips de efeito) + tempo +
    `primary` com o verbo do glossário (`action_label` do `config.json`: fogão/liquidificador "Cozinhar",
    demais "Fazer"; costura "Costurar") desabilitado com o motivo curto se `cook_error != ""`;
  - ao cozinhar: `GameState.cook(recipe)`; sucesso → a bolinha nova "acende" (`Motion.pop_in`), o ícone da
    receita voa da grade até a bolinha (tween 0,3 s), e a receita continua selecionada (para enfileirar outra);
  - seleção inicial: a última receita usada nesta estação (memória da sessão) ou a primeira disponível.
- [ ] Rodapé `ghost` "Ver tudo" → painel antigo `station_view` (continua para consulta).
- [ ] Lugar com várias estações (`stations:stove+blender`): a bandeja é da estação do **sprite tocado**.
  Pelo "Lugares"/"Ir" de missão com receita (`focus`), abre a bandeja da estação da receita, com ela
  selecionada (seta + bandeja, como na Etapa 07).
- [ ] **Extra (se der tempo, não obrigatório):** arrastar o ícone da receita até o sprite da estação
  também cozinha (`drag` que testa `_hits(sprite)`).

### 8.3 Criações (galinheiro, curral)
- [ ] Sem animais → bandeja simples com o abrigo vazio e `primary` "Comprar animais" → `animal_shop` (painel).
- [ ] Com animais, tocar no abrigo (depois do `_collect_station`):
  - **cabeçalho:** fileirinha com os animais (ícones 32 das variedades, `GameState.animal_roster`) +
    bolinha(s) da produção;
  - **um item** de ração (receita de alimentação da estação) com `tem/precisa` na legenda; `tap` = alimentar
    (`cook`), bandeja fica para mostrar a bolinha acendendo e fecha em 1,5 s;
  - `ghost` "Comprar animais" (painel da loja) e "Ver tudo".
- [ ] Animal individual (`animal_slot`) tocado = mesmo comportamento do abrigo dele.

### 8.4 Natureza (Bosque, Caverna, Prado)
Ao tocar no local/etiqueta/marcador (depois de `_collect_site` pegar os prontos):
- [ ] Local fechado → compra/abertura como hoje.
- [ ] Bandeja `pick`: cabeçalho com as 3 bolinhas de coleta (`GatherItem_<local>_<i>` mantidos) e o nível
  do local como `RingProgress` (XP até o próximo marco) com "Nível 2" ao lado; `icon_button` "?" → painel de
  níveis (`NatureUi.levels_panel`).
- [ ] Grade: materiais do local (`Material_<item>` mantidos), bloqueados pelo nível apagados com
  "Nível 3" na legenda. Detalhe: tempo, quantidade, XP da coleta, `primary` "Buscar".
- [ ] `start_gathering` na primeira vaga livre (`start_next_gathering`) — igual ao painel.

### 8.5 O que continua em painel (consulta, compras e coisas ricas)
Passeio (postais, raros), mercado/encomendas, pet shop, compras, manual, amigos, treino de truques.
Esses ganham o visual das Etapas 01–02, mas não viram bandeja.

## Testes
- [ ] `game/tests/station_tray_test.gd` (novo):
  1. fogão com cenouras: tocar no sprite abre a bandeja `pick`; selecionar petisco; `primary` cozinha;
     cenouras descontadas **uma vez**; bolinha 1 ocupada; a bandeja continua aberta;
  2. fila cheia → `primary` desabilitado com o motivo de `cook_error`;
  3. faltam ingredientes → selo "!" na grade; chip do ingrediente tocável abre "Como fazer";
  4. `dev_finish_timers` → tocar no fogão pega os prontos (via `_collect_station`) e abre a bandeja;
  5. galinheiro sem animais → "Comprar animais"; com 1 galinha e milho → alimentar consome o milho uma vez;
  6. Bosque: "Buscar" inicia coleta na vaga 1; material de nível 3 bloqueado com 0 XP;
  7. "Ver tudo" abre o `station_view` antigo.
- [ ] `animals_test`, `nature_test`, `flavors_test`, `petshop_test` (costura), `tasks_test` passam
  (eles chamam o `GameState` e os painéis diretamente).
- [ ] Toque real: `build/touch_steps_etapa08.json` — Casa → tocar no fogão → tocar no petisco → tocar em
  Cozinhar → `shot`; Sítio → galinheiro → alimentar → `shot`.

## Capturas
`etapa08_antes`/`etapa08_depois` + `e07_tray_stove`, `e08_tray_stove_missing`, `e09_tray_coop_empty`,
`e10_tray_coop_feed`, `e11_tray_trees`, `e12_tray_blender`. Em 360×780 e 412×915.

## Lista de conferência (aceite)
- [ ] Cozinhar/fazer/alimentar/buscar sem abrir painel grande; o mundo aparece atrás.
- [ ] Um único botão verde na bandeja.
- [ ] Ingredientes que faltam levam ao "Como fazer".
- [ ] CLAUDE.md/AGENTS.md: "Painel de produção/coleta (padrão)" passa a citar a bandeja como caminho
  principal e o painel como "Ver tudo"; linha da bandeja atualizada.
- [ ] ROADMAP e README marcados; commit `feat(ui): bandeja nas estações, criações e Natureza`.
