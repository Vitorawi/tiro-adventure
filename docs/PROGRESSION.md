# Progressão (Jornada)

## Primeiros sabores (Etapa 04)

Morango abre após `bloblo_more_crops` (180 s, 2 unidades, 15 XP); batata-doce após
`farm_deed` (420 s, 2 unidades, 30 XP). Abóbora mantém `bloblo_potato`: exigir a conclusão
de `bloblo_pumpkin`, que pede colher abóbora, criaria um ciclo impossível. A papinha, por
sua vez, abre após `bloblo_pumpkin`. Sementes são ordenadas por duração; empates usam id
decrescente para uma ordem determinística (morango antes de milho).

O liquidificador custa 30 moedas após `first_kitchen`, tem um espaço e usa `StationState`.
O lugar oculto `house/blender` abre seu painel; Cozinha agrupa fogão, liquidificador e forno.
O lugar exige `first_kitchen` também, entrando automaticamente na comemoração "Novo!".
O objeto fica sobre a ilha, sem bloquear o chão; `z_index: 1` desenha sobre as fatias.

| Receita | Estação | Ingredientes | Tempo | XP Cozinha | Requisito adicional |
|---|---|---|---|---|---|
| Picolé de morango | Liquidificador | 2 morangos | 90 s | 12 | — |
| Suco de morango | Liquidificador | 3 morangos | 60 s | 10 | — |
| Purê de batata | Fogão | 2 batatas | 90 s | 15 | `bloblo_potato` |
| Chips de batata-doce | Fogão | 2 batatas-doces | 150 s | 25 | `bloblo_sweet_potato` |

Suco não alimenta o Tiro e vai à geladeira; os outros alimentos viram mimos e desejos.
Missões da vovó apresentam morango, abóbora e batata-doce; Laís apresenta o liquidificador.
`bloblo_strawberry`/`bloblo_pumpkin` usam ordens 62/65, depois do ensopado e antes da
escritura, para que as novas colheitas não bloqueiem a abertura da Vila. Morango continua
disponível cedo, após `bloblo_more_crops`; as duas missões e seus rendimentos ficam preservados.
Pedidos de morango, picolé, purê e suco preservam `first_harvest` além dos requisitos
específicos, como os pedidos antigos. Diárias de picolé e morango usam contadores existentes.

## Desejos e vínculo

`Database.wishes` carrega `data/wishes.json`; `settings` define espaços/requisitos, esperas,
primeiro desejo, limiar de necessidades e chance/multiplicador de especiais. Modelos têm
tipo, nome, ícone ou item, objetivo de ação, destino, recompensas, peso e requisitos.
`WishState` guarda três espaços (`id`, `base`, `since`, `ready_at`, `special`, `last`),
`done_count` e `first_done`; participa de reset e serialização de `GameState`.

`update_wishes` roda ao carregar, após ações e a cada segundo; só preenche espaços revelados
pela caminha e pelo vínculo. Semente = `int(ready_at) + índice`; evita ids simultâneos repetidos.
Primeiro vem carinho, depois necessidade baixa, especial elegível ou sorteio por peso.
`last` evita repetir o pedido trocado no sorteio comum, com fallback se só restar ele;
a prioridade de necessidade e o pedido inicial podem prevalecer. Nada expira.

`wish_value/target/error` consultam progresso; ações usam contador menos base. `fulfill_wish`
alimenta (`feed`), entrega (`give`) ou recebe ação pronta; conta `wish`/`wish:<id>`, paga
e inicia a espera. `give` já tem suporte, sem modelos nesta etapa. `swap_wish/error` troca sem
custo. Balão prefere um pedido pronto; `fulfillable_wish_count` alimenta o badge.
`available_actions` inclui `wish`; `Places.goal_target` resolve `wish`/`wish:<id>` para a aba.
`TaskHelp` aceita tipo `wish` para orientar ações e reutiliza a cadeia de item para comida.

`progression.json → bond_levels` define afeto total e presentes. `bond_level` e `bond_info`
consultam o nível/barra; `progress.claimed_bond_level` salva o maior presente entregue.
`_check_bond` soma os níveis alcançados em uma mudança e emite `Events.bond_up` para a fila
de comemorações. Saves v12 sem o campo inicializam esse marco no vínculo atual, sem repetir
presentes antigos. Não há mudança da versão do save nem reset adicional nesta etapa.
`dev_add_affection`, `dev_refresh_wishes` e avanço de tempo permitem testar, com guarda DEV.

## Introdução da história

Em jogo novo, `IntroScene` apresenta a Laís e o Tiro antes das abas. As cinco falas e a
animação do retrato vêm de `npcs.json → lais.intro/intro_wave`. Ao soltar o Tiro, a cena
marca `progress.seen["intro"]` via `GameState.mark_seen`, abre a Casa, emite `arrive`
(entrada em `rooms/house.json → points.door_in`) e conduz à conversa com a Laís.
Não recebe a missão automaticamente. Saves com `talk:lais` também pulam a apresentação.
Ferramentas DEV permitem rever a cena. O retrato e o aceno usam o personagem PixelLab
"Laís Avatar"; as rotações/caminhada do mapa usam "Laís Mapa".

## Regiões e experiência de coleta

Bosque, Caverna e Prado são desbloqueados uma vez com moedas. Depois, evoluem com uso:
cada coleta recolhida dá 10 XP próprios àquela região. Iniciar/esperar não dá XP; recolher
de novo não duplica. Aventura continua existindo como atributo geral, separado do XP local.
Não há ferramentas, compra de níveis nem compra de espaços extras.

| Região | Desbloqueio / nível 1 | Nível 2 (XP total) | Nível 3 (XP total) |
|---|---|---|---|
| Bosque | 40 moedas; madeira; 1 espaço | 30 XP; mais madeira; 2 espaços | 90 XP; madeira dura; 3 espaços |
| Caverna | 80 moedas; pedra; 1 espaço | 40 XP; cobre; 2 espaços | 120 XP; cristais; 3 espaços |
| Prado | 50 moedas; fibras; 1 espaço | 30 XP; mais fibras; 2 espaços | 90 XP; 3 espaços |

O painel mostra barra de XP, próxima liberação e quantas coletas faltam. O ? mostra a
cadeia inteira de níveis, liberados/futuros e preço inicial. Atributos do Tiro também
mostra cada região com nível, barra, próximo marco e Ver evolução. Desbloqueio inicial
usa o painel normal de compra: preço, requisitos e ajuda; evoluções seguintes são automáticas.

Conteúdo em `nature_sites`: `levels` (xp total, label, materials, slots), `xp_per_collection`,
`level_upgrades` e `slot_upgrades`. O primeiro level_upgrade é a compra inicial; os demais
e slots têm `nature_unlock: {site, level}` e não podem ser comprados. São tokens de owned
concedidos automaticamente para manter requirements/rotas/ajuda compatíveis. Materiais novos
e rendimento usam as mesmas rotas e não têm trava adicional de Aventura.

`progress.nature_xp` guarda XP total por região. `nature_info`/`nature_level` são consultas
puras com base no XP e no desbloqueio inicial. `_award_nature_xp` concede XP ao recolher e
sincroniza tokens em owned; `_grant_upgrade` permite simulação DEV coerente com esses níveis.
Até três coletas por local, sempre simultâneas. Tocar material inicia na primeira vaga livre.
Refinar lista receitas existentes, ingredientes e atalho às estações (tábuas/tijolos/tecidos,
cristais em apetrechos); cobre continua material de construção.

`progress.gathering` salva id/resource/prazos e snapshots de produtos, XP do jogador e XP
local. Melhorias não alteram lotes iniciados. Save v10 converte ferramentas antigas,
níveis/vagas comprados e histórico de coletas em XP equivalente, sem perder acesso nem
cobrar outra vez. `nature_levels_version: 2` evita converter o histórico duas vezes.
Moedas, missões, vagas e tarefas são preservadas; main_5_pickaxe mantém id e pede abrir
a Caverna. Migração v8 de activity para vaga 1 e API global do pomar seguem compatíveis.

## Compra de animais

`config.json.animals` define variedades, `station`, `price`, `sprite` e `map_scale`.
Galinheiro/curral têm `animal_capacity: 3`, incluem um primeiro animal (`upgrades.gift_animal`) e abrem uma loja própria.
Galinhas: branca (60), ruiva (80), preta (90 moedas). Vacas: pintadinha (140), caramelo
(180), malhada (200). Todas as variedades da mesma espécie têm o mesmo rendimento;
a escolha é visual. Pode repetir variedades até ocupar as três vagas.

`GameState.buy_animal_error/buy_animal` valida abrigo comprado, vagas e saldo antes de
cobrar. `GameState.animals` persiste quantidades por variedade. Alimentar o abrigo inteiro
consome os ingredientes por animal e produz `qty` por animal; a fila fixa a quantidade ao
iniciar. Save v7 mantém as filas anteriores e concede os dois animais que já apareciam
nos abrigos comprados da versão anterior, somente quando não existe o campo `animals`.

Na bandeja do abrigo, cada animal tem um retrato com seu `SlotDot` embaixo (vazio, produzindo ou pronto); os três ficam na mesma fileira. O rodapé é **Comprar animais**, que abre a loja diretamente, no lugar de Ver tudo. O produto (ovos/leite) é selecionável no mesmo modo `pick` das outras estações; `StationTray.recipe_detail` mostra tempo, rendimento do lote, ingredientes tocáveis e o botão **Alimentar**. Selecionar o produto não consome comida; a ação fica no botão e a bandeja permanece aberta. A alimentação continua por lote. A fila guarda o retrato do lote em `animals` (lista de variedades alimentadas), além de `qty`: animais comprados durante o timer aparecem vazios e entram na próxima alimentação. Esse campo opcional sobrevive ao save sem mudar a versão 12; filas antigas usam a quantidade salva para indicar quantos espaços estão ocupados. O painel de consulta usa a mesma fileira da bandeja.

> Sistema implementado em 12/10/2026 (Codex) e revisado/organizado no mesmo dia (Claude Code).
> Conteúdo e números ficam nos JSON de `game/data/`; este doc explica **como funciona e como estender**.

## Ideia
Você começa cuidando do Tiro numa **casa quase vazia**: sem geladeira, sem fogão, sem sítio próprio,
só a tigela, 3 rações e 10 moedas. A Laís (que trouxe o Tiro) apresenta a vovó Bloblo, que empresta **um canteiro**. A partir daí:

```
cuidar do Tiro ─┐
plantar/colher ─┼─▶ moedas + itens + XP de atributo ─▶ comprar construções ─▶ novas receitas,
passear/minerar ┤                                      e terrenos              rotas e pedidos
vender/pedidos ─┘                         missões dos NPCs ─▶ roupas/apetrechos (Coleção)
```

A complexidade cresce aos poucos: no começo duas ou três decisões (cuidar, plantar cenoura, juntar
para o fogão); no fim, cadeias com várias estações (madeira → tábua → cozinha organizada; maçã +
petisco → biscoito → caixa de petiscos → encomenda especial).

## Peças do sistema

### Criações e processamento no sítio (13/10/2026)

Galinheiro abre após Escritura e Bancada; curral após recolher 2 ovos.
Galinheiro, curral, moinho e queijaria são compras permanentes; aparecem no mapa.
As criações reutilizam `StationState` e os timestamps Unix das receitas, com um lote por vez.

| Cadeia | Entrada | Tempo | Saída | Construção |
|---|---|---|---|---|
| Plantar milho | Semente gratuita | 3 min | 3 milhos | Sítio próprio |
| Plantar trigo | Semente gratuita | 2 min | 3 trigos | Sítio próprio |
| Alimentar galinhas | 2 milhos | 3 min | 2 ovos | Galinheiro (inclui duas galinhas) |
| Alimentar vacas | 2 trigos | 5 min | 2 leites | Curral (inclui duas vacas) |
| Moer trigo | 3 trigos | 2 min | 2 farinhas | Moinho |
| Fazer queijo | 2 leites | 4 min | 1 queijo | Queijaria |

- `config.json → stations`: `kind: animal` muda os textos para Alimentar/Alimentação;
  `instruction`, `action_label`, `queue_label` e `recipe_label` são configuráveis.
- `recipes.json`: mesma estrutura de produção. `GameState.cook_error` valida sem consumir;
  `cook` consome uma vez e agenda o lote; `collect` entrega só os prontos, uma vez.
- Galinheiro abre a área dos animais; curral exige galinheiro, moinho exige galinheiro e
  queijaria exige curral. Novas culturas e construções usam os atributos existentes.
- **Capítulo 9** acrescentado após os oito anteriores, com cinco passos: galinheiro, ovos,
  curral, farinha e entrega de dois queijos (com queijaria comprada). Saves que concluíram
  os oito capítulos continuam no 9, preservando tudo. Nenhuma missão antiga foi reordenada.
- Novas diárias de ovos/leite, semanal de queijo e encomenda Café da manhã (ovos, farinha,
  queijo). Recursos têm preços de venda e entram no catálogo/manual automaticamente.
- Mesmo save v6: as quatro filas novas são criadas vazias ao carregar saves antigos;
  alimentação/produção em andamento sobrevive ao fechamento do app.

### Demais peças

| Peça | Onde está | O que é |
|---|---|---|
| **Atributos (4)** | `progression.json` → `skills` | Horta (`agriculture`), Cozinha (`cooking`), Comércio (`commerce`), Aventura (`adventure`: passeios, mina e bancada). Aparecem no capítulo 3 (`features.skills`). Liberam sementes, receitas e rotas; **construções não exigem nível**. |
| **Construções** | `progression.json` → `upgrades` | Compras permanentes (moedas + materiais + requisitos): equipamentos da casa/vila, sítio, estufa, pomar, galinheiro, curral, moinho e queijaria. |
| **Estações** | `config.json` → `stations` + `recipes.json` | Fogão, bancada, forno, ateliê, galinheiro, curral, moinho e queijaria; filas com tempo real. `slot_upgrades` = construção que aumenta a fila. |
| **Rotas** | `progression.json` → `activities` | Passeios/mineração com tempo (uma por vez): bairro, trilha, pedreira, cobre, gruta, pomar, prado. |
| **Comércio** | `progression.json` → `orders` + `sell_price` em `items.json` | Venda no Sítio/Vila, encomendas dos vizinhos e contratos da banca própria em três níveis. Interface `MarketUi`. |
| **Capítulos** | `progression.json` → `chapters` (+ `final_chapter`) | A "história": cada capítulo termina ao comprar seu `target`. Aparece em Jornada → Hoje. |
| **Novidades** | `progression.json` → `features` | O que a história revela (Mochila, diárias, semanais, atributos), com `requirements` e `go`. |
| **Missões** | `quests.json`, `routines.json` | História (capítulos em passos) + diárias e semanais sorteadas. Objetivos + recompensas. |
| **NPCs** | `npcs.json` (+ mundo em `worlds.json`) | Laís (Casa, história), vovó Bloblo (Sítio, linha própria), Feirante e Artesã (Vila), Guia da trilha (Natureza). `portrait` = retrato, `sprite_dir` = personagem que anda no mapa, `services` = atalhos para lugares. |
| **Coleção** | `collections.json` | Roupas/apetrechos ganhos em missões (`slot`: head/neck/body; `sprite` para vestir no futuro). |
| **Sítio** | `config.json` → `farm` | 1 canteiro emprestado antes da escritura; depois 3 iniciais e expansão até 9 (`unlock_costs`). |

## Como os atributos sobem
- XP total por atributo fica salvo em `GameState.progress.skills`; o nível é calculado
  (`ProgressionState.skill_info`): ir do nível N ao N+1 custa `skill_base_xp + (N-1) * skill_xp_step`
  (30, 50, 70...). Máximo `max_skill_level` (20).
- **Descoberta:** a primeira colheita de cada cultura e a primeira receita de cada tipo valem
  XP × `first_discovery_multiplier` (2).
- **Cuidar** (comer, brincar, banho) só dá XP do jogador quando o Tiro **precisa** (necessidade abaixo
  de `care_need_threshold`) e fora da recarga `care_reward_cooldown` — não dá para "farmar" tocando.
  (O antigo atributo Vínculo saiu na simplificação; o save v6 soma Passeio, Mineração e Construção em Aventura.)
- Fontes: colheita → Horta; receita → atributo do campo `skill` da receita (padrão Cozinha; bancada → Aventura);
  venda → Comércio (`trade_xp` do item); recompensas de rotas, pedidos, missões e construções → `skill_xp`.
- **Nível do jogador** (estrela da barra superior) é separado: XP de ações (`config.json` → `xp`),
  missões (`player_xp`), construções e rotas.

**Passos concretos:** a história não pede "suba o atributo"; pede ações ("Colha 5 vezes", "Venda 15 itens").
Objetivo `stat` com `"fresh": true` conta só o que foi feito depois que o passo começou
(`ProgressionState.step` guarda a base; `GameState._sync_step` a atualiza a cada mudança).

## Requisitos (um formato para tudo)
Construções, culturas, receitas, rotas e pedidos aceitam:
```json
"requirements": { "owned": ["farm"], "quests": ["first_sale"], "skills": { "agriculture": 4 }, "chapter": 3 }
```
Validados por `ProgressionState.requirement_error()` (a mensagem vira o motivo na UI).
`progress.unlocks` ("crop:potato", "recipe:pumpkin_mash") libera conteúdo **sem** cumprir requisitos
(usado para saves antigos e pode ser recompensa: `"rewards": { "unlocks": [...] }`).
Requisitos extras: `"stats": {"walk": 5}` (contador mínimo; rótulos em `settings.stat_labels`), `"bond": 3` (vínculo, `bond_levels`)
e `"hours": [17, 21]` (hora local em [início, fim)). `bond` e `hours` dependem de fora do `ProgressionState`, então são
checados em `GameState.requirement_error` (que embrulha o do `progress`; `content_error` também passa por ele).
Recompensas extras: `"affection": N` (afeto do Tiro) e `"needs": {"happiness": 20, "energy": -8}`.
`GameState.available_actions()` lista o que dá para fazer agora (`plant`, `harvest`, `cook`, `collect`, `gather`, `gather_ready`,
`quest_ready`, `routine_ready`, `care`); `Loot` (`scripts/util/loot.gd`) sorteia tabelas com semente e faixas `[min, max]`.

## Missões: História, Diárias e Semanais

Nos cruzamentos repetidos do começo, a história usa `shared_with` para apontar para a missão
canônica da Bloblo: `lais_meet_bloblo → bloblo_meet`, `lais_first_crops → bloblo_more_crops` e
`lais_stew → bloblo_stew`. O cartão principal orienta “Complete as missões de Vovó Bloblo até
‘Mais canteiros’” (com o nome do marco correspondente) e oferece Ir para o passo atual.
A missão secundária mantém sua entrega e seu prêmio logo abaixo, uma única vez.
Receber a missão canônica avança o marco principal automaticamente:
ele não paga moedas/XP de missão, não conta outra conclusão e não emite outro aviso de missão.
Recompensas de capítulo continuam independentes. IDs anteriores seguem nos saves/requisitos;
ao carregar missão canônica já recebida, o marco pendente é sincronizado sem repetir seu prêmio.
Não há devolução de recompensas que saves antigos já receberam.

**Linhas de missões por NPC (13/10/2026).** Design em `docs/plans/QUESTLINES.md`, plano em
`docs/plans/TASKS_QUESTLINES.md`. A **Laís** (mora na Casa, trouxe o Tiro) conduz a história:
`kind: "main"`, `chapter` (1..10) e `order` consecutivo. Cada outro NPC pode ter uma **linha**
própria: `kind: "line"`, `line` (ex.: `"bloblo"`), `order` e `requirements` (quando o passo pode
começar). Há **um passo ativo por linha, em paralelo** (`ProgressionState.active_steps()`):
`current_main_quest()` para a história e `current_line_quest(linha)` para as demais. As linhas se
cruzam com o objetivo `quest` (ex.: a Laís pede que você conheça a vovó). Cada passo tem `dialogue`
(a fala curta mostrada na conversa com o NPC). Tocar no NPC abre a conversa e conta `talk:<npc>`.

| Cap. | Laís (história) | Vovó Bloblo (linha `bloblo`, em paralelo) |
|---|---|---|
| 1. Um novo lar | falar, alimentar, banho, brincar, abrir a Mochila | — |
| 2. O sítio da vovó | conhecer a vovó; ajudar na horta (cruzamentos) | conhecer (1 canteiro), colher, colher 3× (3 canteiros) |
| 3. A cozinha | geladeira (40), fogão (60), ensopado para a vovó | 4 cenouras (libera batata), batata, **ensopado** (2 cenouras + 1 batata) |
| 4. Conhecendo a Vila | ir à Vila, 1 venda, 1 encomenda | escritura do sítio (180) |
| 5. Além do portão | abrir o Bosque, 6 madeiras, bancada (120 + 6 madeiras) | (fase 2: galinheiro/curral) |
| 6–9 | forno, banca, estufa e ateliê | |

Capítulos sem `target` (1, 2, 4) não exigem construção. Só a história avança capítulos;
`chapters[].rewards` é entregue uma vez; os sinais `quest_completed(id)` e `chapter_completed(index)`
acionam a UI.
**Diárias e semanais** ficam em `data/routines.json`: por tipo, `count` (quantas sorteia),
`requirements` (quando aparecem: diárias no capítulo 2, semanais no 3) e `missions` com
`goal: { key: <contador>, target }`, `rewards` (moedas, itens, roupas) e `requirements`.
`GameState.routine_ids(kind)` sorteia ao virar o dia (meia-noite local) ou a semana (segunda),
com o período como semente (o mesmo sorteio ao reabrir). O progresso é contador − `base`
(valor no início do período), guardado em `ProgressionState.routines`. As roupas que eram das
secundárias agora vêm das semanais. Ações: `claim_routine`/`routine_error`. A interface compacta da Etapa 10 usa essas mesmas ações: Pegar tudo recebe apenas as rotinas elegíveis, uma vez cada; linhas recebidas somem, com moedas no CollectFx.

`hint` substitui a dica gerada; `go: {"world": "...", "place": "..."}` substitui o
destino. `Places.goal_target` resolve objetivos; `Database.item_sources` fornece
fontes estruturadas de itens. Atributos têm `how_to` e a UI mostra o nível que a
história pede, inclusive requisitos da construção atual.

## Objetivos de missão
| `type` | `key` | Conta |
|---|---|---|
| `stat` | contador | `progress.stats[key]` (ver tabela abaixo) |
| `owned` | construção | 1 se comprada |
| `skill` | atributo | nível atual |
| `deliver` | item | itens na mochila; **são consumidos** ao concluir |
| `have` | item | itens na mochila; não consome |
| `coins` | — | saldo atual; não consome |
| `chapter` | — | capítulo atual (11 = história completa) |
| `quest` | missão | 1 se já recebida (cruzamento entre linhas) |

Contadores (`progress.stats`), incrementados pelas ações do `GameState`:
`feed`, `play`, `bathe`, `harvest`, `harvest:<crop>`, `produce`, `produce:<item>`, `trade`, `sold`,
`orders`, `order:<id>`, `activity:<id>`, `explore`, `build`, `quests`, `talk:<npc>` (conversa
aberta) e `open:<aba|mundo>` (primeira vez que abriu a Mochila ou entrou num mundo).
`fresh` usa a base da linha dona do passo (`progress.steps[linha].base`).

## Recompensas (missões, pedidos, rotas)
```json
"rewards": { "coins": 20, "items": { "dog_food": 2 }, "skill_xp": { "agriculture": 10 },
             "collections": ["farm_ribbon"], "unlocks": ["crop:potato"] }
```

## Caminho atual (resumo do balanceamento)
| Capítulo | Alvo | O que destrava |
|---|---|---|
| 1. Um novo lar | — | Mochila, Sítio e a vovó Bloblo |
| 2. O sítio da vovó | — | canteiros emprestados (1 → 3), geladeira à venda |
| 3. A cozinha | Fogão (60; geladeira 40 antes) | ensopado, Vila, diárias |
| 4. Conhecendo a Vila | — | portão/Natureza, semanais |
| 5. Além do portão | Bancada (120 + 6 madeiras) | tábuas, atributos |
| 6. Uma produção de verdade | Forno (240 + materiais) | biscoito de maçã, caixa de petiscos |
| 7. Nosso lugar na vila | Banca (350 + materiais) | pedidos grandes |
| 8. Um mundo de possibilidades | Estufa (480 + cristais) | ervas |
| 9. Feito por nós | Ateliê (600 + materiais) | tecido, conjunto de acessórios |


O `progression_test.gd` joga uma **campanha simulada** do zero (só ações reais, tempo acelerado) e
falha se alguma construção ou missão ficar inalcançável. Rode-o depois de mexer em números.

## Interface
Desde a reorganização da navegação, a progressão não fica mais num menu único: cada coisa mora
num lugar de um mundo (feira, ateliê e portão da trilha na Vila; cada construção comprada no próprio lugar) e a aba **Missões** mostra a História (um passo por vez: quem pede, ícone + `0/6`, onde,
o que falta em chips tocáveis), as Diárias e as Semanais em linhas com anel, instrução e prêmio. História mantém **Ir** e **?** ("Como fazer"); rotinas usam **Ir/Pegar** e **Pegar tudo** quando há várias prontas. Detalhes em **`docs/WORLDS.md`**. Painéis em `scripts/ui/progression_ui.gd`.
- Casa: móveis com `"upgrade"` em `rooms/house.json` só aparecem depois de comprados; antes há um
  marcador "+" que abre a compra. Sítio: canteiros bloqueados mostram "Sítio" (antes da escritura)
  ou o preço do próximo terreno.
- **Ajuda de comida:** sem nenhuma comida na mochila, a Bloblo dá ração grátis (recarga de 5 min)
  — o cuidado com o Tiro nunca trava por falta de moedas.

## Versão dev (testar as partes avançadas)
Para chegar nas partes avançadas sem jogar horas, existe a **versão dev** (detalhes de build em
`docs/DEPLOY.md`):
- Endereço: https://vitorawi.github.io/tiro-adventure/dev/ (local: `http://localhost:8000/dev/`;
  rodando pelo Godot é sempre dev). Pode ser instalada na tela inicial como **"Tiro DEV"**.
- **Save separado** (`user://save_dev.json`): nada do que se faz lá afeta o jogo de verdade.
- Selo vermelho **DEV** na barra superior abre as **Ferramentas DEV** (`scripts/ui/dev_panel.gd`):
  - **Recursos:** +100/+1000/+10000 moedas; +10 de cada item (todos, materiais, colheitas, comidas); necessidades 100%.
  - **Progresso:** atributos para nível 3/5/10/máx.; **pular para o capítulo N** (libera de graça tudo
    o que vem antes, inclusive missões e atributos exigidos); liberar uma construção específica;
    concluir uma missão e suas predecessoras; **concluir passo atual da história**; **liberar tudo**.
    O índice interno de dev_jump_to_chapter é zero-based; capítulo 4 recebe índice 3.
  - **Tempo:** terminar todos os timers agora; avançar 10 min / 1 h / 4 h / 12 h (como se o app
    ficasse fechado: necessidades caem, plantas crescem, filas andam).
  - **Save:** copiar o save da versão publicada (mesmo aparelho) para testar em cima do progresso
    real; salvar; recomeçar do zero (toque duplo).
- Ferramentas são métodos `GameState.dev_*` com a guarda `BuildInfo.is_dev()` — na versão publicada
  não fazem nada (testado em `dev_tools_test.gd -- --prod`).

## Saves antigos
O formato atual é **v11**. Com a história refeita (Laís + vovó Bloblo), combinado com o Vitor,
qualquer save anterior **recomeça do zero** (`SaveManager._migrate` devolve estado vazio).
As migrações antigas (v2–v10) foram removidas. Novas mudanças de formato voltam a migrar a partir da v11.

## Validação

`tools/test_all.ps1` executa farm, campanha, DEV, tasks, content e DEV prod.
`tasks_test.gd -- --screenshots` (sem headless, 360×780) captura começo, capítulo 4,
fim, História, "Como fazer" e comemoração em `build/screenshots/tasks_*.png`.
`content_test` valida ordem, alvos, referências e acesso aos destinos.
`tools/touch_test.ps1 -Steps tools/tasks_touch_steps.json` exercita Missões → Ir
na Web local com perfil de navegador descartável.

## Como estender
- **Nova construção:** entrada em `upgrades` (name, description, cost, materials, requirements,
  skill_xp, icon). Se for estação: `"station": "<id>"` + entrada em `config.json → stations` +
  receitas com `"station"`. Se tiver móvel: objeto em `rooms/<sala>.json` com `"upgrade": "<id>"`.
- **Novo capítulo:** item em `chapters` com `target`, `rewards`, `unlocks_text` e 3–5 missões main.
- **Nova missão:** entrada em `quests.json` com `kind`, `npc`, `goals`, `rewards`; main usa chapter/order. Diária/semanal: entrada em `routines.json`.
- **Novo NPC com foto:** entrada em `npcs.json`; coloque o retrato (pixel art do PixelLab feita a
  partir da foto) em `assets/sprites/characters/npc_<id>/portrait.png` e preencha `"portrait"`.
- **Nova roupa:** entrada em `collections.json` (+ `sprite` quando existir a camada para vestir).
- Depois de mudar números: rode `progression_test.gd` (campanha simulada).

## Pendências conhecidas / próximos passos
Ver `docs/ROADMAP.md` → "Estado atual". Principais: vestir as roupas da Coleção no Tiro, retratos
dos NPCs (fotos do Vitor), NPCs no mundo, móveis da bancada/forno/ateliê na casa ou no sítio,
sprite próprio da planta de ervas, e balancear o ritmo real (hoje medido só pela campanha simulada).

### Animais na linha da Bloblo (Fase 2)

B8–B13: galinheiro → 2 ovos → curral → 2 leites → farinha → queijo.
B8 espera a Bancada da Laís (`main_4_bench`); as linhas continuam em paralelo.
Galinheiro: 180 moedas + 4 tábuas e uma galinha branca; curral: 300 moedas +
6 tábuas e uma vaca pintadinha. O presente é concedido em `_grant_upgrade`, somente
na primeira aquisição, antes de salvar; carregar um save não repete a concessão.
`requirements.produced` usa os contadores de coleta: 2 ovos/leites liberam ruiva/caramelo,
6 liberam preta/malhada. Alimentar ou esperar sem recolher não libera variedades.
O requisito também aparece no Como fazer, e as ferramentas DEV o respeitam.

### Apresentação dos NPCs e avisos

`npcs.json → introduction` é uma lista de falas da primeira conversa (Bloblo).
Terminar grava `npc_intro:<id>` via `GameState.mark_seen`; fechar antes permite rever.
Laís usa a cena inicial própria (`intro`). O Mapa indica ! para passos não conversados
ou ✓ para missão pronta, com prioridade para ✓ e respeito aos requisitos dos NPCs/mundos.
Atalhos `services` exigem lugar aberto e construção comprada. Canteiros emprestados
fechados levam à vovó enquanto a escritura não estiver liberada.

### Feirante, Guia e retratos animados

Feirante (cap. 4): conversar → primeira venda → vender 5 produtos → 1 encomenda → mais 2 encomendas
→ montar a própria banca → 2 contratos → ampliar para nível 2 → somar 5 contratos → nível 3
→ contrato Festa da vila. `first_sale`, `main_2_order`, `market_day` e `own_business` usam
`shared_with` para orientar até os respectivos marcos, sem pagamento repetido. A Bloblo ensina
a primeira venda no próprio Sítio (`bloblo_sell_surplus`, depois da primeira colheita): `early_market`
fica disponível desde `bloblo_meet`, sem exigir a Vila, a escritura ou a banca.
Guia (cap. 5): conversar → recolher lane → quarry → meadow. Metas de ações são `fresh`;
passos anteriores da Laís não contam retroativamente. As novas linhas não bloqueiam
as existentes. São quatro linhas possíveis em paralelo (Laís, Bloblo, Feirante, Guia).
`npcs.json → portrait_animations` define pastas `request`/`complete`. `NpcPortrait`
executa o aceno uma vez ao receber missão do NPC, depois retorna ao pedido quando houver
passo ativo. Sem animação configurada, o NPC continua com seu retrato estático.

## Começo mais fácil (Etapa 01 do plano `docs/plans/comeco`)
- **Canteiros:** vovó empresta 2 (`bloblo_meet`) e depois 4 (`bloblo_more_crops`); `farm.initial_plots` = 4 e a
  escritura mantém os 4. Só o próximo canteiro fechado tem etiqueta (Vovó antes da escritura, moeda + preço depois).
- **Regar** (`config.json → farm.water`: `speedup` 0,3, `xp` 1): `GameState.water/water_error`, uma rega por plantio,
  contador `water`; gotinha sobre a planta no mapa, tocar rega. Primeira colheita pede regar.
- **Nada preso a atributo escondido (cap. 1–5):** abóbora exige `bloblo_potato`, papinha exige `lais_stew`;
  `content_test` recusa `requirements.skills` sem capítulo ≥ 6 ou construção com materiais.
- **Nível dá presente:** `progression.json → level_rewards` (por nível; `default.coins_per_level` × nível acima da
  tabela). `Events.level_up(level, rewards)` abre a comemoração "Nível N!".
- **Presente do dia:** `progression.json → daily_gift` (ciclo de 7 dias jogados, nunca zera),
  estado `progress.daily_gift {period, count}`, `GameState.claim_daily_gift/daily_gift_error`.
- **Bem-vindo de volta:** cartão `scenes/ui/welcome_back/` ao abrir/voltar após `settings.welcome_back_seconds` (300 s),
  só depois de `settings.welcome_requirements` (`lais_bed`) e se houver presente ou algo pronto
  (`GameState.welcome_ready_lines`).
- **Dica parada:** `settings.idle_hint_seconds` (15) / `idle_hint_max_chapter` (4): seta sozinha no alvo do passo
  (`WorldsScreen.advance_idle`), uma vez por passo.
- Diárias abrem no capítulo 3 e semanais no 4 (`features.daily/weekly`); nova diária "Regue 5 plantas".


## Passeios da Praça (Etapa 07)

`walks.json` define sete passeios, separados das rotas de coleta da Natureza. `loot.first` soma materiais
na primeira coleta; `loot.table` faz sorteios com a semente salva, e `find` consulta uma tabela existente
em `finds.json`, sem gastar seus garantidos. `loot.rare` tem `chance`, `pity`, `collection` e `duplicate`.
A N-ésima coleta sem raro atinge a garantia. Somente uma coleta bem-sucedida altera `WalkState.history`
e `pity`; cancelar e armazenamento cheio preservam ambos. Saves da Etapa 06 preservam suas voltas,
e saves sem `walks` começam vazios, sem migração/reset adicional.

| Passeio | Abre com | Tempo | Raro / garantia |
|---|---|---|---|
| Volta na praça | `nina_meet` | 2 min | Laço xadrez / 6 |
| Rua das flores | 3 passeios | 5 min | Óculos escuros (`flower_clip` legado) / 8 |
| Feirinha da Vila | 6 passeios | 10 min | Gravata-borboleta / 8 |
| Beira do riacho | vínculo 3 + `forest_open` | 20 min | Lenço de marinheiro / 10 |
| Clareira dos passarinhos | 15 passeios + vínculo 4 | 30 min | Mochilinha de explorador / 10 |
| Mirante do morro | 25 passeios + vínculo 5 | 60 min | Óculos de estrelinha / 12 |
| Passeio ao pôr do sol | 10 passeios, início das 17h às 21h | 15 min | Coleira que brilha / 6 |

Contadores: `walk`, `walk:<id>`, `walk_item` (quantidades), `walk_item:<item>`, `walk_rare` e
`walk_rare:<id>` (apetrechos novos; consolo não conta). Achados do faro também contam `find_item:<item>`.
`walk_pity_left` consulta a garantia; `walk_lock_error` exclui horas, `walk_hours_error` verifica o início.
`walk_unlock_keys` entra em `new_unlocks`/`_mark_all_seen`; `Places.unlock_view` mostra o postal.
`collect_walk` devolve `first`, `rare`, `rare_item`, `rare_duplicate`, `new_items` e o alias anterior `new`.
`ProgressionUi.walk_diary` abre no Sheet; o cartão de volta rola quando grande para manter Oba acessível.
Materiais `trail` têm `storage: none` e `note`; `Database.item_sources` e `TaskHelp` apontam aos passeios.

## Apetrechos, pet shop e costura (Etapa 08)

`progress.equipped` salva `head`, `neck` e `body`; saves v12 anteriores começam com três strings
vazias e mantêm coleção/progresso. `GameState.equip_error/equip/unequip_error/unequip` valida posse,
slot e arquivo de overlay; uma roupa por lugar. Revestir a mesma peça não soma `equip` novamente.
Roupas antigas sem arte mostram **Em breve no Tiro**. Há 18 peças vestíveis (incluindo dois lendários).

Pet shop Patinhas: após `nina_rare`, custa 150 moedas + 4 gravetos + 2 fitas. Costura custa 100 +
2 novelos + 2 fitas, com uma vaga; bolsinha custa 200 + 3 novelos + 2 fitas, após 10 passeios.
Quatro roupas à venda (50/60/80/140 moedas), cinco receitas exclusivas de materiais `trail` e
pacote de cinco rações por 15 moedas. A linha da Nina continua com montar → vestir → costurar.
Não foi criada diária de costura. `features.dress` anuncia vestir; `features.legendary_walks`
anuncia os lendários somente quando elegíveis.

Receitas usam **ou** `output`/`qty` **ou** `output_collection`. `Database.recipe_output` resolve
o id; `item_name/item_icon` também entendem coleções. `Database.station_upgrade` associa uma
estação à construção que a libera (`sewing` → `sewing_table`). Filas conservam receita/tempo/qty;
`cook_error` rejeita roupa já possuída ou sendo costurada em qualquer fila. Coleta de roupa não
usa inventário/depósito: soma `sew`, `produce:<id>` e `produce`, entrega coleção uma vez e emite
`cosmetic_received`. A casca põe o cartão com **Vestir agora** na fila modal existente.
Manual, Mochila/usos, ajuda, DEV e painéis reconhecem os dois tipos de saída. Materiais com uso
de receita deixam de mostrar a nota provisória. DEV: `dev_grant_cosmetics`, com guarda prod.

`walk_bag` acrescenta um sorteio da tabela comum em `walk_loot`; semente e ordem dos sorteios
anteriores são preservadas. A mesma função calcula os itens de `collect_walk_error` e da coleta.

**Lendários cosméticos Bob Esponja:** Chapéu do Siri Cascudo (`sponge_hat`, cabeça) e Uniforme de
esponjinha (`sponge_uniform`, corpo), aprovados pelo Vitor. Após pet shop e 20 passeios concluídos,
todo passeio tem um sorteio **adicional independente**, com chance 1% e garantia em 30 voltas
elegíveis por peça; primeiro chapéu, depois uniforme, sem duplicados. Regras em `walks.json.legendary`.
`WalkState.pity.legendary` persiste a garantia; `walk_legendary` conta as peças novas. Cancelar ou
não caber no depósito não muda prêmio/garantias/histórico. Raro e lendário podem vir juntos;
os sete raros mantêm suas tabelas e garantias. Diário mostra garantia/conjunto completo e Coleção
mostra a raridade. `flower_clip` conserva o id legado, mas agora é **Óculos escuros**, sem perder
posse ou progresso da Rua das flores.

Validação: `petshop_test` (ações/save antigo/fila/bolsa/depósito/duas garantias/atalhos), campanha
216 ciclos, 47 aquisições, 69 missões. Onboarding com chance rara zero: primeiro raro em 54,5 min,
capítulo 4 em 11,4 min; ocioso 220 s, maior trecho 30 s; limites anteriores mantidos.

## Etapa 09 — Amigos do Tiro

`friends.json` define os quatro amigos e seus requisitos, petiscos, marcos, recompensas e tabelas de visita.
Pipoca (`pipoca`, NPC `dog_pipoca`) passa dos pulinhos ao cartão após `nina_sewing`, enquanto
`nina_pipoca` ainda está ativa. Continua seguindo Nina. Os outros exigem `nina_pipoca`;
Mel também exige `blender`, Bolota `bloblo_potato` (purê desbloqueado) e Fred `bloblo_sweet_potato`.
Petiscos reais: `carrot_snack`, `strawberry_pop`, `mashed_potato`, `sweet_potato_chips`.

Um petisco por amigo em cada bloco local de 3 horas. O bloco inclui a data; o maior índice observado
é salvo para impedir repetição ao atrasar hora/fuso. O visitante usa rotação determinística dos ids
elegíveis ordenados, fixada durante a janela; novos desbloqueios não trocam um visitante já escolhido.
Se ainda não havia visitante elegível, o primeiro pode aparecer na própria janela. Pipoca sempre está.
Corações em 1/3/6 petiscos; `claimed_hearts` impede repetir os três prêmios. O contador `friend_level`
é a soma de corações, recalculada ao dar e carregar. `friend_gift` e `friend_gift:<id>` contam entregas.

Pipoca ♥2 adiciona +1 sorteio comum em `walk_loot`, somado à bolsinha. Raros, consolos, histórico,
garantias e sorteio independente dos dois lendários mantêm as sementes e posições. Erro/coleta usam
o mesmo resultado. Pipoca ♥3 entrega `caramel_bandana` à Coleção; sem overlay por decisão desta
etapa (opcional no plano), permanece “Em breve no Tiro”, usando `friend_pipoca` como ícone.

Visitas exigem ♥3 e ausência contínua de 8 h, posterior a `best_at`/`last_visit`.
O SaveManager trata primeira carga e retorno do segundo plano; carregar estado e trocar de slot
não geram visitas. Presença global entre slots fica em `settings*.json → last_session_active`;
`FriendState.last_active_at` guarda o último contato do save, com heartbeat a cada minuto.
O presente é sorteado uma vez com Loot e salvo em `visit_gift`; só sai após coleta bem-sucedida.
Armazenamento cheio preserva visita, horário e prêmio. Sem reset ou aumento de SAVE_VERSION.

Nina: `nina_pipoca` (ordem 80), `nina_friends` (100, quatro corações somados).
Feature `friends`, desejo `friend`, diária `friend` e semanal `pack_week` usam os mesmos contadores
e navegação. `FriendUi` monta cartão e Coleção → Amigos no Sheet com rolagem existente.
`friends_test` testa calendário/fuso, requisitos, recompensas, persistência, ciclo real do SaveManager,
visitas, armazenamento, NPCs/caminhos e bônus/garantias; `friend_clock.gd` é exclusivo de testes.
Campanha simula janelas e entrega petiscos produzidos, sem alterar limites ou conceder itens.

## Truques — Etapa 10 (14/10/2026)

`progression.json.tricks` é a fonte de nomes, ícones, animações, requisitos, largura da zona e segundos por ida do marcador; `trick_settings` define 3 acertos, recarga de 120 s e efeitos +3 felicidade/+1 afeto. Ordem: `paw`, `talk`, `roll`, `jump`, `spin`; todos exigem `nina_pipoca`, os quatro últimos vínculo 2/3/4/5. Só o próximo pode ser aprendido. O Treino é o quarto lugar visível da Praça; Nina tem o serviço `training`, com a mesma guarda do lugar.

`GameState.learn_trick_error/learn_trick` validam e gravam `progress.tricks[id] = true`, contam `trick_learned` uma vez e emitem `Events.trick_learned` para a fila modal. `perform_trick_error/perform_trick` validam posse, requisitos, sono/passeio e recarga, aplicam efeitos, contam `trick`/`trick:<id>`, salvam timestamp Unix em `progress.cooldowns` e emitem a animação existente. Save anterior começa com dicionário vazio; `SAVE_VERSION` continua 12. Não se persiste uma partida parcial, nem se premia o treino repetido.

`TrickUi` usa o Sheet/LiveBox (rolagem e atualização de recarga); executar fecha o painel e mostra a animação na aba Tiro. `TrickTraining` usa PetAnimator, Tween ping-pong, zona central com pequena variação, botão 64 px e feedback sem punição. `check_hit` é uma consulta pura; `dev_force_marker` tem guarda `BuildInfo.is_dev()`, só para testes. As roupas respeitam as mesmas âncoras, variantes e três slots; nenhuma arte do Tiro foi substituída.

Linha da Nina: `nina_trick` ordem 90 (um aprendido, 20 moedas/+5 afeto), `nina_friends` ordem 100 preservada, `nina_roll` ordem 110 (três aprendidos, 40 moedas). Os objetivos são totais, sem `fresh`, permitindo treinar antes de receber a missão. Após `nina_trick`, `features.tricks`, desejo `trick` e diária `trick` (duas execuções, 10 moedas). Objetivos/ajuda levam ao Treino para aprender e à aba Tiro para executar.

Validação: `tricks_test` cobre fronteiras da zona, erro sem custo, três acertos/toque repetido, anúncio/contadores únicos, vínculo, recarga independente/exata/persistida, sono/passeio, missão/recompensa única, saves antigos, navegação e os três slots durante todas as cinco animações. `tricks_shots` usa mouse (mesmo caminho do toque), capturas gráficas 360×780 com timeout externo. Campanha usa `learn_trick/perform_trick` conforme elegibilidade, sem concessões novas.

## Tesouro — Etapa 11 (14/10/2026)

Fecha o mistério dos pedaços do mapa (`map_piece_1..4`, obtidos como achados garantidos no sítio, praça, vila e natureza; guardados na Mochila, `storage: none`, e contados em `find_item:map_piece_N`).

Enquanto `guide_treasure` estiver ativa, `finds.json → worlds.<mundo>.quest_find {quest, item}` garante um montinho imediato para o pedaço ausente em cada mundo acessível, sem depender do intervalo ou de quantas escavações o save já fez. O pedaço é somado ao prêmio normal (preserva mudas, itens, moedas e sorteio pendente). A posse do item encerra a garantia naquele mundo; depois da missão, os intervalos normais continuam. A garantia também cobre saves antigos e não exige iniciar linhas opcionais de outros personagens. O “Ir” aponta apenas para um montinho real, sem seta numa posição vazia.

- Missão `guide_treasure` ("O mapa completo", linha do Guia, ordem 50, após `guide_fibers`): quatro objetivos `have` (um por pedaço). `claim_quest` só consome `deliver`, então os pedaços continuam no álbum. Recompensa 30 moedas + 40 XP de aventura. `Database.item_sources` agora lista, para itens da categoria `find`, o mundo onde se cava (`find:<mundo>`), e o botão Ir do objetivo leva ao lugar de cavar.
- `progression.json → treasure`: `requirements {"quests": ["guide_treasure"]}` e `rewards` (150 moedas, `explorer_hat`, `unlocks ["crop:blueberry"]`, 2 parafusos). `GameState.open_treasure_error()/open_treasure()`: marca `progress.seen["treasure_opened"]`, conta `treasure` e emite `Events.treasure_opened` (fila modal → `Celebration.show_treasure`). Repetir devolve "Já aberto" e não paga nada; sem espaço no armazenamento a abertura é recusada sem gastar. O Chapéu de explorador também sai do conjunto "Tesouros da trilha": a coleção é um dicionário, então não duplica.
- Mirtilo: `crops.json → blueberry` (900 s, 20 moedas, 3 mirtilos, 40 XP). Requisitos `quests: guide_treasure` **e** `stats: {treasure: 1}` (só depois de abrir o baú; o `unlocks` do baú também o libera). Desejo especial `blueberry` com o mesmo requisito. Item `blueberry`: venda 9, `feed` fome 4 / felicidade 8.
- Sem `SAVE_VERSION` novo: tudo usa `progress.seen`, `progress.unlocks`, `progress.collection` e contadores existentes.

## Banca própria e contratos (16/10/2026)

`orders.<id>.channel = "contracts"` separa os contratos; ausência do campo significa vizinhança.
`building_order` e `special_order` exigem `stall`; `fabric_order` exige `stall_2` e ateliê;
`banquet_contract` exige `stall_2`, queijaria e liquidificador; `festival_contract` exige `stall_3`,
ateliê e liquidificador. Contadores gerais `orders`/`order:<id>` continuam compatíveis; `contracts`
é a soma dos `order:<id>` de contratos, recalculada em `_changed`, inclusive ao carregar saves
anteriores. Não há reset, novo SAVE_VERSION ou repetição de prêmio antigo.

| Estágio | Compra | O que muda |
|---|---|---|
| Minha banca | 350 moedas, 5 tábuas, 3 tijolos; sítio adquirido | Dois contratos, moedas e parafusos |
| Banca ampliada | 450 moedas, 6 tábuas, 4 tijolos; 2 contratos | Tecidos e Mesa da comunidade; bandeirolas no mapa |
| Banca da vila | 800 moedas, 8 tábuas, 6 tijolos, 2 tecidos; 5 contratos | Festa da vila, materiais e estrela no mapa |

As missões novas da linha `merchant` usam metas totais para contratos (2/5) e compras reais;
as encomendas introdutórias preservam `fresh`. `merchant_festival` pede uma entrega real de
`festival_contract`. Marcos da história recebidos em saves antigos também marcam suas novas
missões canônicas sem novo pagamento. As melhorias permanecem em `owned`, e a etiqueta do
mapa usa `label_levels` para mostrar o nível. `market_test.gd` percorre a linha inteira, confere
venda inicial, margem das encomendas, canais, recarga, compras e compatibilidade de save.
