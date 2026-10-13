# Plano: Simplificar (missões em 3 tipos, 3 mundos, revelar aos poucos, menos texto)

Pedido do Vitor (12/10/2026): "está muito confuso; muitos lugares, muita pessoa; é um bombardeamento
de informação. Missão de história, diária e semanal; história bem clara (o que precisa, o lugar);
simplificar os mundos; ir mostrando aos poucos." Antes disso: "menos texto, mais imagem em todo canto"
e "facilitar encontrar como fazer a missão e os ingredientes".

## Decisões do Vitor
- **3 mundos:** Casa, Sítio, Vila. A Trilha vira um portão dentro da Vila.
- **Personagens:** os 4 continuam, mas cada um só aparece quando a história o apresenta. A Bloblo guia.
- **Atributos:** de 7 para 4 (Horta, Cozinha, Comércio, Aventura), escondidos no começo.
- **História:** mantém os 8 capítulos, com passos reescritos para serem concretos e visuais.

## Princípios (valem para toda tela)
1. **Uma coisa por vez:** a tela mostra o próximo passo, não o catálogo inteiro.
2. **Ícone + número em vez de frase:** `[cenoura] 2/6`, `[moeda] +40`. Texto: no máximo uma linha curta.
3. **Todo objetivo tem o lugar:** ícone do lugar + botão **Ir**, que leva até o objeto e o destaca.
4. **Nada aparece antes de ser apresentado:** recursos são liberados pela história com um "Novo!".

## Situação de partida (commit ddab0df)
- 4 mundos, 18 lugares, 4 NPCs, 7 atributos, 28 passos de história + 9 secundárias.
- A aba Tarefas tem 5 seções: História, Para evoluir, Prontos agora, Secundárias e Sua evolução.
- `scripts/ui/task_help.gd` (Codex, inacabado): calcula o que falta e o primeiro passo (`TaskHelp.describe`).
  O painel dele tem muito texto e 5 tipos de botão espalhados. A **lógica** será reaproveitada; o painel será refeito.

---

## Fase 1: Missões em 3 tipos (aba "Missões") — FEITA
**Aba Tarefas → Missões**, com só 3 blocos:

1. **História** (cartão grande):
   - Linha do topo: `Cap. 2/8` + pontinhos dos passos (●●○○).
   - Rosto de quem pede + nome do passo.
   - Objetivo: **ícone grande** + `0/6` + barra.
   - Lugar: ícone do mundo › ícone do lugar (`Casa › Fogão`).
   - Se faltar algo: fileira de ícones dos ingredientes ou materiais com `tem/precisa` (vermelho/verde).
     Tocar num ícone mostra o painel curto daquele item: de onde vem + **Ir**.
   - Botões: **Ir** (grande) + **?** (painel "Como fazer" visual, com o primeiro passo calculado por `TaskHelp`).
   - Recompensa do passo em chips (`[moeda] 40  [estrela] +20`).
   - Pronto: o botão vira **Receber** (verde).
2. **Diárias:** 3 linhas compactas `[ícone] Colha 3x  1/3  [moeda] 15  [Ir]`, renovadas à meia-noite (hora local).
3. **Semanais:** 1–2 linhas, renovadas na segunda-feira à meia-noite, com recompensa maior.

**Sai:** secundárias, "Para evoluir", "Prontos agora" (vira selo no mapa e nos lugares) e "Sua evolução"
(atributos e coleção vão para a aba Tiro).

**Dados (como ficou):**
- `quests.json` só tem `main`; as 9 secundárias saíram e as roupas delas viraram prêmio das semanais.
- Diárias e semanais ficam em `data/routines.json` (arquivo próprio, fora da máquina de missões):
  `{ "daily": { "count": 3, "requirements": {"chapter": 2}, "missions": { id: { "name", "goal": {"key", "target"}, "rewards", "requirements" } } }, "weekly": {...} }`.

**Estado (`ProgressionState.routines`):**
```
{ "daily":  { "period": "2026-10-12", "ids": [...], "base": { "harvest": 12, ... }, "claimed": [...] },
  "weekly": { "period": "2026-W42",   ... } }
```
- O progresso é `stat atual − base` (base = contador no início do período), então não precisa de contador novo.
- O sorteio é determinístico pelo período (`hash(period)`): é o mesmo ao recarregar e não depende de quantas vezes abre.
- O período usa a hora local (`Time.get_datetime_dict_from_system`). Guarda só texto e números, nada por frame.
- Ações: `GameState.claim_routine(kind, id)` + `routine_error(kind, id)`, seguindo a convenção `""` = ok.
- Diárias liberadas no capítulo 2 e semanais no capítulo 3, com um "Novo!" na hora.

**Testes:** `tasks_test` (troca de dia e de semana, sorteio estável, recompensa só uma vez, base correta)
e a campanha do `progression_test` sem as secundárias.

## Fase 2: Atributos 7 → 4 e passos concretos — FEITA
> Como ficou: construções não exigem nível (atributos só liberam sementes, receitas e rotas);
> passos novos usam `"fresh": true` (contam a partir do início do passo); bancada dá XP de Aventura.
- **Horta** (agriculture), **Cozinha** (cooking), **Comércio** (commerce),
  **Aventura** (walking + mining + building: materiais e obras com o que se acha nas rotas).
- **Vínculo** deixa de ser atributo: vira o coração do Tiro (necessidade de felicidade). Recompensas de XP de vínculo saem.
- `progression.json`: `skills` com 4 entradas. Todo `skill`/`skill_xp`/`requirements.skills` é remapeado
  e os níveis exigidos são revistos (somar 3 atributos num só sobe o nível mais rápido).
- Passos de história "subir atributo" viram ação concreta:
  - `main_3_agri` → "Colha 5 vezes"
  - `main_5_cooking` → "Prepare 3 receitas"
  - `main_6_commerce` → "Venda 10 itens"
  - `main_8_building` → "Faça 4 tábuas"
- Atributos ficam escondidos até o capítulo 3 (aparecem na aba Tiro com "Novo!").
- **Save v6:** XP de walking+mining+building é somado em `adventure`; `bond` é descartado.

## Fase 3: Mundos (3 mundos, no máximo 4 lugares cada) — FEITA
> Como ficou: painéis combinados (`stations:stove+oven`, `market:<aba>`, `routes:walk+mine`),
> `upgrades` por lugar, `Database.place_of_upgrade` para o Ir, mapa com cartões enxutos.
| Mundo | Lugares (tocáveis) | Personagem |
|---|---|---|
| Casa | Tigela, Cozinha (fogão + forno no mesmo painel), Geladeira (= Mochila), Porta → Sítio | — |
| Sítio | Canteiros, Bancada, Pomar, Porteira → Vila | Bloblo |
| Vila | Feira (vender + encomendas, 2 abas), Ateliê, Portão da trilha (passeios + mina) | Feirante, Laís, Guia (no portão) |

- **Saem os menus "Construir em…"**: cada construção é comprada **no próprio lugar** (o "+" da cena,
  que já existe), e a história leva até ela. Picareta → no Portão (cartão da mina). Banca → na Feira.
  Fila extra do fogão → no painel do fogão.
- Sofá: só enfeite (a soneca fica na aba Tiro).
- `worlds.json`: remove `trail` e o `build` de cada mundo; a Vila ganha a zona `gate` (nova zona tocável
  + etiqueta em `rooms/village.json`). A arte da trilha fica guardada para um mundo futuro.
- Mapa: 3 cartões grandes com a imagem do mundo; os bloqueados mostram cadeado + ícone do passo que libera.
  Selo de "pronto" (colheita, preparo, rota que voltou) no cartão e no lugar da cena.
- **Save v6:** se o jogador estava na trilha, volta para a Vila; nada mais muda (rotas e mina continuam com o mesmo id).

## Fase 4: Revelar aos poucos — FEITA
> Como ficou: o Mapa continua desde o início (é onde fica a Casa); some só a Mochila. Diárias/semanais usam
> `features` em vez de requisitos em routines.json; atributos idem (saiu `settings.skills_from_chapter`).
- `progression.json` → `features`: `{ "bag": {"quest": "…"}, "map": {…}, "farm": {…}, "village": {…},
  "sell": {…}, "orders": {…}, "routes": {…}, "mine": {…}, "skills": {…}, "daily": {…}, "weekly": {…} }`.
  Usa os mesmos `requirements` de sempre (`ProgressionState.requirement_error`).
- `GameState.feature_unlocked(id)`. A UI esconde abas, lugares, NPCs e seções ainda não liberados.
- Início do jogo: só **Tiro**, **Casa** e **Missões** (Mapa e Mochila aparecem nos primeiros passos).
- Momento **"Novo!"**: a comemoração mostra o ícone do que abriu + **Ir**. A aba ou o lugar novo pulsa
  até o primeiro toque (`ProgressionState.seen_features`).
- **Seta de destaque:** `world_requested(mundo, lugar)` faz a sala mostrar uma seta pulsando sobre o
  objeto do lugar até ele ser tocado. É o que transforma o **Ir** em "vá ali".
- NPC só aparece no mundo depois do passo que o apresenta (`npcs.json` → `requirements`).

## Fase 5: Menos texto no resto do jogo — FEITA
> Como ficou: Mochila 4 colunas (ícone + x12), detalhe do item com "De onde vem"/"Usado em" tocáveis
> (`SheetBuilder._sources/_uses`), sítio em grade de canteiros, sementes compactas, coleção em grade,
> personagem = rosto + fala curta + atalhos. Ícones novos do PixelLab ficaram para depois (os atuais bastaram).
- **Mochila:** blocos com ícone grande + `x12` (sem nome; o nome aparece no detalhe).
- **Detalhe do item:** "De onde vem" e "Usado em" viram fileiras de ícones tocáveis com **Ir**
  (`Database.item_sources` já devolve destinos).
- **Receita:** ícones dos ingredientes com `2/3` (tocar = de onde vem), chip de tempo e de XP com ícone,
  botão Produzir. Sem "Precisa de:" e sem nomes nos chips.
- **Sítio, feira, rotas, construções:** cortar frases de instrução; motivo de bloqueio vira cadeado + ícone
  do que falta (tocar = "?").
- Ícones novos (PixelLab, 32 px) para objetivos sem ícone: encomenda, passeio, receita genérica, cadeado, seta.
- `UiKit`: `goal_icon(goal)`, `reward_chips(rewards)`, `item_chip(id, have, need)` (tocável), `place_chip(world, place)`.

## Ordem, testes e entrega
- Uma fase por vez; ao fim de cada uma: `tools/test_all.ps1` + `dev_tools_test -- --prod`, capturas 360×780
  das telas mexidas e um commit.
- `SAVE_VERSION` 6 com `_migrate`, testado com um save v5 de meio de jogo.
- Atualizar `docs/PROGRESSION.md`, `docs/WORLDS.md`, `docs/GAME_DESIGN.md`, `CLAUDE.md` = `AGENTS.md`
  (abas e estrutura) e o "Estado atual" do `docs/ROADMAP.md`.
- **Sem push na main** até o Vitor aprovar as capturas.
