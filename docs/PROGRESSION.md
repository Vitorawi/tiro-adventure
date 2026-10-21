# Progressão (Jornada)

**Passeios antes da Natureza (21/10/2026):** capítulo 4 agora inclui `main_4_nina_chest` (“Os primeiros passeios”), marco sem prêmio próprio com `shared_with: bloblo_chest`. Após a encomenda da Vila, a principal acompanha `nina_meet` → `nina_walk` → `bloblo_chest`; o primeiro passeio garante os dois gravetos do baú, sem precisar da Natureza. Comprar o baú não basta: receber a missão da Nina encerra o marco/capítulo e leva a `lais_forest` (“Além do portão”). Natureza, portão da Vila, Guia/`guide_meet` e Bosque continuam exigindo capítulo 5, portanto aguardam essa conclusão. Saves com `bloblo_chest` já recebido reconhecem o marco via sincronização existente, sem repetir recompensa; quem ainda não o recebeu vê a principal voltar a esse passo, preservando compras, itens e missões já registradas. Capítulo 4 se chama “Vila e primeiros passeios”; 110 missões, 50 principais e 14 pares compartilhados. A rota `lane` (“Trilha do bosque”), usada em “Primeiro caminho”, agora usa `item_wood` no lugar de `action_play`.

**Estado das receitas nas bandejas (21/10/2026):** sem ingredientes = ícone esmaecido, sem exclamação/cadeado; bloqueada por progressão = esmaecida com cadeado; disponível com ingredientes = cor normal. A mudança acompanha o inventário enquanto a bandeja está aberta, sem impedir selecionar uma receita para consultar seus ingredientes. Motivos e ingredientes tocáveis continuam no detalhe. O antigo “!” de ingredientes faltantes foi retirado para não parecer missão.

**Primeiros cuidados e passos da horta (20/10/2026):** ajuda de ração só aparece após terminar a apresentação da vovó (`npc_intro:bloblo`) ou já ter concluído `bloblo_meet`. Ir de Banho/Brincar mostra seta no cuidado correspondente; a primeira plantação enquanto `first_harvest` estiver aberta e sem nenhuma rega aponta o canteiro para tocar e regar. Refeições necessárias ao próximo crescimento anunciam progresso/ganho efetivo de Corpo e conclusão; HUD pronto usa aviso vermelho “! Pode Crescer!” no lugar do pulso do avatar. A missão de entregar quatro cenouras `bloblo_carrots` saiu do catálogo: `bloblo_more_crops` libera diretamente a batata e segue para `bloblo_potato`. Saves na entrega retirada seguem para batatas, sem descontar cenouras, reset ou novo prêmio; registros antigos dessa missão podem permanecer no histórico. Catálogo atual: 109 missões, 49 principais.

**Quadro de encomendas compacto (20/10/2026):** resumo superior em uma linha com retratos e nível dos clientes; tocar abre os selos/progresso. “?” guarda explicação, legenda de missão e próximo pedido. Quatro cartões menores por página e detalhe com cliente no título, ingredientes/prêmio juntos e Entregar, sem exigir rolar a tela da vizinhança. Destaques de missão e acesso aos ingredientes preservados. Nenhuma alteração de estoque, pagamentos, objetivos ou save.

**Resumo dos mundos (20/10/2026):** `Places.world_summary` separa missões disponíveis (passos ativos ainda não vistos), prêmios de missão para receber, coletas de produção/passeio/visita, achados do Tiro e tesouro da Clareira. Os cartões do seletor têm uma linha por categoria não vazia, com ícone e contagem; o ponto verde continua indicando coleta. O resumo não modifica o save nem o total legado de `world_ready_counts` usado pelas abas. Mundos bloqueados mostram só o bloqueio.

**Espaço das bandejas de estação (20/10/2026):** receitas em faixa horizontal; corpo com rolagem vertical limitada ao espaço entre HUD e abas, com espaçamentos maiores. Cabeçalho/fechar, Cozinhar e Ver tudo ficam fora da rolagem, acima da barra de navegação. O seletor de lotes não aumenta a bandeja para fora da área útil. Ações/custos/filas preservados.

**Atalhos de comida e receitas (20/10/2026):** a ajuda de refeição do crescimento leva à receita da estação mesmo com ingredientes faltantes/fila cheia. Ingredientes completos mostram Pronto ✓; só os faltantes têm Buscar. Fila cheia orienta esperar/pegar com Ver fila no Fogão. A bandeja põe a receita do Ir primeiro e selecionada; sem foco, prioriza comida ainda pedida pelo próximo crescimento, incluindo favorita já descoberta. Grades longas têm dica explícita de rolagem. Produção só começa pelo botão Cozinhar/Fazer existente.

## Tiro no centro — etapa 07 (19/10/2026)

O HUD mostra o retrato e a pelagem da fase, anel por fração de requisitos concluídos e número da fase
(Recém-chegado = •; demais 1–5). O avatar pronto pulsa; Menos animação desliga o pulso. Toque abre
nome da fase, quantos requisitos faltam e Ver → painel Crescimento. Nível/XP/atributos do jogador
saíram da interface, inclusive prêmios, lista de saves e ferramentas DEV. `level` fica congelado;
`xp`/`skills` são contadores internos preservados para snapshots/testes/simulador, sem presentes ou avisos.
`Events.level_up` não é emitido; `Celebration.show_level` e sua conexão na casca foram removidos.
`features.skills` foi removida; a antiga entrada `skills_panel()` encaminha ao Crescimento.
`treat_box` exige `growth: explorer`, mantendo bancada e geladeira. Rotinas de cuidado dão Coragem 4,
banho Pelagem 4; Banco/Jardim/Piquenique/Festa dão Coragem 5 pela ação única `_grant_automatic`.
Radiante e reserva seguem `_gain_pillar`. Os demais XP ficam internos, inclusive Encontro da turma.
XP/níveis locais da Natureza continuam válidos. Nenhum preço foi alterado: presentes de nível deixam
de entrar; os cinco presentes de fase já existentes somam 590 moedas. Conferência econômica só na 17.


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
| Alimentar galinhas | 2 milhos por galinha | 15 min | 2 ovos por galinha | Galinheiro (galinhas compradas separadamente) |
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
**Encomendas ligadas às missões (20/10/2026).** `MarketUi.mission_quests` consulta objetivos pendentes das linhas ativas: `order:<id>`, `orders` e `contracts` (este último só canal da banca). Esses pedidos vêm primeiro em `order_ids`, antes do critério normal pronto/preparar/espera; recebem ! na grade e o nome da missão no detalhe. Objetivos já cumpridos deixam de destacar mesmo com prêmio da missão ainda não recebido; missões futuras não geram destaque. Paginação e foco explícito são preservados, sem alterar pagamentos, recargas ou progresso.

**Pedras da caverna (20/10/2026).** `guide_stone` aceita buscas recolhidas em Pedras da margem (`pebbles`), Pedreira (`quarry`) e Veio profundo (`deep_quarry`), sem `fresh`. O objetivo `stat` histórico soma o contador principal às alternativas de `also_counts`; usa os contadores já existentes no save, mesmo sem pedra restante no inventário. Iniciar ou terminar o timer sem pegar não conta. Recompensa de 25 moedas e cruzamento `stone_path` preservados. Atalhos `activity:<rota>` agora abrem `route:<rota>` com foco, em vez de apenas o local genérico.

Desde a reorganização da navegação, a progressão não fica mais num menu único: cada coisa mora
num lugar de um mundo (feira, ateliê e portão da trilha na Vila; cada construção comprada no próprio lugar) e a aba **Missões** mostra a História (um passo por vez: quem pede, ícone + `0/6`, onde,
o que falta em chips tocáveis). Três pílulas fixas separam **Principal**, **Personagens** e **Temporárias**. Principal mostra só a história; Personagens agrupa as linhas por NPC, recolhidas até Abrir (um personagem aberto por vez), com prêmios disponíveis primeiro; Temporárias alterna **Diárias/Semanais**, preservando **Pegar tudo** para as rotinas prontas. Exclamação vermelha no grupo, personagem e missão significa prêmio que já pode ser recebido, sem confundir missão nova com concluída; o cartão também diz “Prêmio pronto!”. História mantém **Ir** e **?** ("Como fazer"); marcos compartilhados têm Ver missões do personagem, abrindo o grupo correto. Seleção de grupo/personagem/período fica na sessão e resiste ao refresh por segundo; nada muda no save, metas ou prêmios. Detalhes em **`docs/WORLDS.md`**. Painéis em `scripts/ui/progression_ui.gd`.
- Casa: móveis com `"upgrade"` em `rooms/house.json` só aparecem depois de comprados; antes há um
  marcador "+" que abre a compra. Sítio: canteiros bloqueados mostram "Sítio" (antes da escritura)
  ou o preço do próximo terreno.
- **Ajuda de comida:** “Pedir à vovó” fica sempre na Tigela, mesmo com comida no estoque, e aparece direto na guia Comida do cantinho quando ela está vazia. Bloblo dá 2 rações grátis por pedido, com recarga salva de 5 min; botão desabilitado e contagem “Pedir de novo em…” até liberar automaticamente. As duas telas compartilham o mesmo pedido/relógio.
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
Galinheiro: 260 moedas + 4 tábuas, começa vazio; galinhas são compradas separadamente
(branca 120, ruiva 150, preta 180 moedas). Curral: 420 moedas + 6 tábuas e uma vaca
pintadinha; esse presente continua em `_grant_upgrade`, somente na primeira aquisição.
Carregar um save preserva os animais já possuídos. `requirements.produced` usa os contadores
de coleta: 8 ovos/leites liberam ruiva/caramelo, 24 liberam preta/malhada.
Alimentar ou esperar sem recolher não libera variedades.
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
- **Nível dá presente:** `progression.json → level_rewards` (por nível; `default`: `min(coins_max, coins_base + coins_per_level × nível)` (20 + 3n, máx. 80) acima da
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

**Primeira venda ao Feirante (correção de 20/10/2026):** `merchant_first_sale` exige `sold:village` com `fresh: true`: uma venda na Vila depois de a missão começar. `GameState.sell(item, quantidade, world_id)` mantém `trade`/`sold` globais e acrescenta `sold:farm` ou `sold:village` quando informado o lugar. Os painéis carregam esse mundo de `Places.open/run` até `MarketUi.sell`. A ajuda e o objetivo dizem “Vender um produto ao Feirante”. Vendas antigas e vendas no Sítio não satisfazem essa missão; missões já recebidas permanecem recebidas, sem reset ou novo prêmio. O simulador informa o mundo da venda (argumento opcional `world`, padrão Vila se aberta, caso contrário Sítio).

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

## Economia R1 — etapa 02: transações, snapshots e presentes para guardar

Infraestrutura de proteção de saves antes de limitar estoques (17/10/2026). **Nenhum número de balanceamento mudou**
e nenhuma categoria nova ganhou limite: o jogo continua com os limites anteriores. Plano: `docs/plans/economia/`.

- **Migração sem reset.** `economy_revision` (conteúdo, `EconomyState.CURRENT_REVISION`, agora 1) é separada do formato
  (`SAVE_VERSION` continua 12: os campos novos têm padrão). `EconomyMigration.migrate` é pura e idempotente (a segunda passada
  encontra a revisão e não faz nada); roda em `SaveManager._migrate` (carregamento, resumo dos slots, "copiar da publicada") e
  em `GameState.from_dict`. Não paga, não altera timestamps nem gera visita. O ramo histórico `<12` não foi ampliado.
  Registra: piso de capacidade, recompensas automáticas já pagas, snapshots dos trabalhos em andamento e o capítulo concluído
  segundo o mapa de missões ANTIGO. Tabelas antigas ficam em `data/legacy_r0.json` (gerado por `tools/freeze_legacy.py`,
  imutável; só a migração lê). Estado novo: `GameState.economy` (`EconomyState`, bloco `economy` do save).
- **Validação única.** `GameState.storage_shortage(entra, sai)` calcula o inventário PROJETADO por depósito
  (usado − o que sai + o que entra) e devolve a falta real; `storage_full`/`storage_error` delegam a ela e `transaction_error`
  junta moedas, ingredientes e espaço. Consulta pura (sem RNG, contador, recarga). Quem só consome/vende nunca é bloqueado,
  mesmo acima do limite. Missões, encomendas, diárias/semanais, presente do dia, desejos, amigos, colheita, lotes, rotas,
  Natureza, achados, tesouro, loja e visitas usam a mesma função; entregar e receber no mesmo depósito conta o que sai primeiro.
- **Capacidade.** `max(curva do estágio, piso legado)`. O piso (`economy.storage_floor`, só sobe) vem das COMPRAS segundo a tabela
  congelada, nunca do estoque; estoque acima do teto não some, só bloqueia novas entradas. `prebuild_capacity` (campo opcional em
  `progression.json → storage.<depósito>`) liga o limite desde antes do prédio; sem o campo vale a regra antiga (nenhum depósito usa
  o campo ainda: cada etapa 05–08 liga o seu).
- **Snapshots.** Canteiro (`plots[i].job`: colheita, moedas, XP), lote de estação (`queue[i].job`: saída, quantidade, entradas pagas,
  XP), rota/coleta (`rewards`, `player_xp`) e passeio (`current.snapshot`: caminho, lendário e tabelas de achados) guardam o
  contrato do momento em que começaram (`WorkJobs`). Mudar receita, cultura ou tabela depois NÃO muda o que já está em andamento;
  `ready_at` já gravado prevalece. Trabalhos de saves antigos recebem o contrato calculado UMA vez com as tabelas congeladas.
- **Presentes para guardar.** Recompensas automáticas (nível, capítulo, vínculo; futuro: cliente, projeto) passam por
  `GameState._grant_automatic(id, rewards)` com identidade estável (`level:8`, `chapter:6`, `bond:4`, `customer:<npc>:<n>`,
  `project:<id>`): moedas, XP, coleções e desbloqueios saem uma vez (`economy.granted`); só os itens que não cabem ficam num
  recibo (`economy.pending`), que não expira nem ressorteia. `claim_pending_rewards` guarda o que cabe de cada item e mantém o
  saldo; `pending_reward_error/hint` explicam a falta real. Recompensas manuais continuam transacionais (bloqueiam antes de
  consumir) e nunca viram recibo. Na Mochila, `InventoryList` mostra a seção recolhida "Presentes para guardar (N)" só quando há
  algo esperando (chips tocáveis levam ao depósito, `Guardar` é o botão principal, cadeado + falta real quando nada cabe).
- Testes: `economy_transactions_test.gd` (fixtures v12, capacidade, transações, snapshots, passeio, recibos, prebuild/piso,
  migração pura, cinco slots) e `pending_gifts_test.gd` (toque real nas três resoluções); `friends_test.gd` agora separa
  "passeio em andamento mantém a tabela" de "nova saída usa a tabela nova". Capturas: `tests/storage_shots.gd`, `ui_tour.gd` (`b04b_bag_gifts`).

## Economia R1 — etapa 03: volta do Tiro × bagagem do passeio

Viagem e bagagem passaram a ser estados diferentes (17/10/2026). **Nenhum número foi ajustado** (chances, tempos de viagem, garantias, recompensas
e limites iguais; o baú continua sem limite para `trail`/`find`: a categoria só ganha depósito na etapa 08). Plano: `docs/plans/economia/`,
contrato D de `05_SAVES_E_TRANSACOES.md`.

- **Estado.** `WalkState.current` é só a VIAGEM não retornada; `WalkState.pending_return` é a BAGAGEM, no máximo uma:
  `{id, started_at, ready_at, returned_at, seed, result, left, rewards_applied, result_shown}`. `result` é o resultado congelado
  (itens, moedas, `first`, `rare`, `rare_duplicate`, `legendary`, `collections`, `new`, afeto e cuidados); `left` é o que ainda espera para
  ser guardado. Vai no save em `walks.pending_return` (sem `SAVE_VERSION` novo; save antigo = sem bagagem). Bagagem já vista e vazia não persiste.
- **`GameState.return_due_walk(announce := true)`** é idempotente (sem viagem vencida não faz nada) e não depende de tela: roda no tick de 1 s
  do `GameState`, ao carregar (`from_dict`, sem emitir sinal) e antes de `start_walk`/`collect_walk`. Sorteia pela semente e pelo snapshot
  (`walk_state.current.snapshot`), congela o resultado e, **uma única vez**, paga moedas/XP/afeto/coleções, aplica os `needs` do passeio,
  conta `walk`, `walk:<id>`, `walk_rare(:<id>)` e `walk_legendary`, atualiza `history` e `pity`, move os achados para `pending_return` e emite
  `Events.walk_collected` (um por viagem). Carregar um save com viagem vencida liquida do mesmo jeito, sem segundo sorteio; um save antigo
  pronto e nunca recolhido vira bagagem com o resultado que o recolhimento antigo teria dado (com ou sem snapshot).
- **`walking()`** vale só durante a viagem real (tempo restante > 0). Bagagem esperando NÃO prende o Tiro: ele reaparece nas salas e no
  cantinho, e cuidados, sono, horta, projetos e troca de mundo/aba funcionam. `walk_ready()` passou a significar "há achados para guardar".
- **Efeitos no Tiro no instante certo.** Os `needs` entram em `ready_at` (`dog.apply(..., max(ready_at, updated_at))`) e o tempo depois
  segue normal; abrir o jogo horas depois não "cura" como se tivesse voltado agora. É a segmentação da seção G usando a política temporal
  vigente; as metades de taxa, pisos e o teto de 8 h da ausência protegida são da etapa 04 e não foram antecipados.
- **Guardar.** `claim_walk_baggage()` guarda por parcelas que cabem (`walk_baggage_plan`: `{moved, blocked, item, missing}`), mantém o resto
  em `left`, repete sem duplicar e só então conta `walk_item`, `walk_item:<item>` e `find_item:<item>` (os contadores de voltar e de receber
  ficaram separados). `walk_baggage_error/hint/depot` explicam a falta real ("Baú sem espaço: abra lugar para Graveto ×3") e apontam o depósito.
  A bagagem nunca é ressorteada nem perdida por falta de espaço. `start_walk` recusa novo passeio enquanto houver bagagem com itens
  (mensagem com o depósito); `cancel_walk` só vale na viagem (depois de voltar responde "O Tiro já voltou", sem devolver energia).
- **Wrappers.** `collect_walk()` liquida a volta (se preciso) e tenta guardar, devolvendo o resumo; `collect_walk_error()`, `walk_loot()`
  (prévia na viagem, resultado congelado na bagagem) e `cancel_walk()` continuam. `Events.walk_collected(resultado)` agora sai na VOLTA.
- **Interface.** Tiro: `AwayView` só durante a viagem; com bagagem aparece `CollectWalk` ("Guardar achados", ou "Ver bagagem" quando não cabe,
  que leva ao portão da Praça). Cartão "De volta!" (`WalkResult`): mostra tudo o que veio; com sobra, `StoreBaggage` ("Guardar achados"/"Ver
  bagagem") + `CloseResult` "Depois"; abrir o cartão só marca `result_shown` (`mark_walk_result_shown`) e reabrir nunca premia
  (`walk_result_unseen` recoloca o cartão na fila ao abrir o jogo se ele ainda não foi visto). Painel da Praça: espaço "Voltou!" com postal,
  chips `Baggage_<item>`, `CollectWalk` ou `BaggageBlocked` + `GoDepot` ("Ir ao Baú"). Mochila: cartão `WalkBaggage` ("Achados do
  passeio (N)", `StoreBaggage`/`BaggageBlocked`). Marcador do portão, contador de prontos do Mapa, "boas-vindas" e ações disponíveis usam a
  bagagem. DEV: "Voltar do passeio" (`dev_walk_return`).
- Testes: `walk_return_test.gd` (relógio antes/no/depois de `ready_at`, reload em cada transição, quatro depósitos cheios, parcelas, raro
  e lendário garantidos, linha do tempo do Tiro, saves antigos, wrappers, superfícies) e `walk_return_ui_test.gd` (toque real nas três
  resoluções). `park_test`, `walks_test`, `friends_test`, `petshop_test`, `pet_care_test`, `ready_badges_test`, `tricks_test`,
  `economy_transactions_test` e o simulador (`bg_tick` liquida a volta como o tick real) foram adaptados à nova definição de `walking()`.


## Economia R1 — etapa 04: ausência protegida do Tiro

Fora do app o Tiro cuida de si (17/10/2026). Plano: `docs/plans/economia/` (02 G, 05 E e G). **Online nada mudou** (taxas e efeitos iguais).

- **Regra.** Offline cada barra cai a `offline.rate` (0,5) da taxa online, por no máximo `offline.max_hours` (8) de queda por ausência contínua, e para no piso `needs.<id>.offline_floor` (fome 25, alegria 35, energia 25, higiene 30). Fórmula por trecho: `max(min(x, piso), x − taxa×0,5×horas_protegidas)`; uma barra que já estava abaixo do piso não sobe. Dormindo, a energia sobe `sleep_regen_per_hour` (40/h) até 100 e o Tiro só acorda ao voltar; as demais barras seguem a proteção. 100 acordado: 8 h e 24 h dão 68/80/76/88.
- **Estado.** `DogState.away_since` (0 = online; salvo). `get_need` projeta `[updated_at, now]` em trecho online (antes de `away_since`) + trecho offline; tempo protegido do trecho = `min(b−início, 8 h) − min(a−início, 8 h)`, por isso `commit` no meio (volta do passeio) não reinicia o teto. `DogState.begin_absence/end_absence` (idempotentes).
- **Fronteira.** `GameState.begin_absence(at)` / `end_absence()` chamadas pelo `SaveManager` (foco, pausa, fechar → começa; retorno e `load_game` → termina). Fechamento abrupto: início estimado = `friend_state.last_active_at`, aplicado em `GameState.from_dict` antes de `return_due_walk` (os efeitos do passeio entram em `ready_at` e o resto da ausência continua). Relógio para trás não gera ganho; trocar de slot não gera visita nem presente.
- **Dados.** `config.json → offline {rate, max_hours}` e `needs.<id>.offline_floor` (`Database.offline`). DEV: `dev_advance_time` é uma ausência protegida.
- **Interface.** Nenhum cartão novo: o "Que bom que você voltou!" já é neutro; o Manual (Recursos) ganhou uma linha curta. Testes: `absence_test.gd` (1 h/8 h/24 h/72 h, pisos, sono, recarregar, foco repetido, passeio de 30 min, relógio para trás, slot, DEV).


## Economia R1 — etapa 05: espaço finito junto da primeira horta

Só a categoria silo (colheitas e maçã) ficou finita nesta etapa (17/10/2026). Plano: `docs/plans/economia/` (02 A, 03 B, 05 B, 06).

- **Capacidades.** Provisório 16 (`storage.silo.prebuild_capacity`, nome "Cesto da horta" em `prebuild_name`) → silo construído 32 (`base`) → `silo_2` +24 = 56 → `silo_3` +32 = 88. `silo_2`: 100 moedas, tábua 2 + parafuso 1, pede `main_4_bench`; `silo_3`: 260, tábua 4 + tijolo 2 + parafuso 1, pede `own_business` (sem aro de ferro). Sem `_4/_5` (etapa 18).
- **Silo grátis.** Upgrade `silo`: custo 0, sem material, requisito `first_harvest` (não mais `main_9_cheese`); ação "Construir", balão "Grátis"; o painel mostra `16 → 32` (`GameState.storage_upgrade_preview`). Comprar com o cesto cheio amplia sem perder nada.
- **Missão `bloblo_silo`** (ID preservado): ordem 27 da Bloblo (depois do faro 25, antes de `bloblo_more_crops` 30), objetivo `owned:silo`, 10 moedas, sem parafuso. Quem já a recebeu continua recebido. Fala de `first_harvest` avisa que o cesto cabe pouco.
- **Piso legado só da migração.** `GameState.storage_floor` lê apenas `economy.storage_floor` (gravado por `EconomyMigration`); `_changed()` não o sobe mais com compras. Save antigo com silo 40 (ou `_2` 80) mantém a capacidade; jogo novo vale 32. Sem silo e com 100 cenouras: estoque preservado, entradas bloqueadas, vender/consumir funciona.
- **Colheita cheia.** `harvest_error` diz "Cesto da horta sem espaço: abra lugar para Cenoura ×N" (falta real); planta continua madura, sem item/moeda/XP/contador. "Tudo" da foice valida cada lote (um menor ainda pode caber), colhe os que cabem e avisa "N ficaram prontos. …". Mochila: `storage_name` mostra "Cesto da horta" até o silo; a linha só aparece com item ou prédio.
- **Fora desta etapa:** geladeira, armazém e baú seguem sem limite provisório (etapas 06–08). Testes: `silo_test.gd` (novo), `economy_transactions_test`, `storage_test`, `tasks_test`, `economy_sim_test`, `walk_return_test` ajustados à nova regra; capturas `tests/silo_shots.gd`.


## Economia R1 — etapa 06: a despensa ligada à cozinha

Só a categoria geladeira ficou finita nesta etapa (17/10/2026). Plano: `docs/plans/economia/` (02 A, 03 início da cozinha, 05 B, 06).

- **Capacidades.** Despensa provisória 12 (`storage.fridge.prebuild_capacity`, nome "Despensa" em `prebuild_name`) → geladeira construída 24 (`base`) → `fridge_2` +16 = 40 → `fridge_3` +24 = 64. `fridge`: 40 moedas, sem material, pede `lais_first_crops` (como antes); `fridge_2`: 100, tábua 2 + parafuso 1, pede `main_4_bench`; `fridge_3`: 240, tábua 4 + tijolo 2 + parafuso 1, pede `own_business` (sem aro de ferro e sem exigir `bloblo_chest`/`bloblo_bigger`). Sem `_4/_5` (etapa 18). O fogão continua pedindo `owned fridge`; `main_2_fridge → first_kitchen` intactas.
- **Classificação.** `storage: "fridge"` explícito em todo alimento (`carrot_snack`, `pumpkin_mash`, `vegetable_soup`, `apple_biscuit`, `cheese`, `strawberry_pop`, `mashed_potato`, `sweet_potato_chips`, `mint_snack`), além de `egg`, `milk`, `flour` e `strawberry_juice`. `dog_food` (e ração de segurança) segue `none`; ervas e mirtilo crus continuam no silo (categoria `crop`). Cada item resolve para um depósito só (`storage_of`).
- **Lote que não cabe.** `collect` já validava com `storage_error`: o lote inteiro fica pronto na fila, sem item, XP, contador nem moeda ("Despensa sem espaço"/"Geladeira sem espaço"). Receita nova libera o espaço dos ingredientes pela validação projetada. Nada é vendido nem iniciado sozinho. `feed` tira do estoque (inclusive acima do piso legado).
- **Interface.** `SheetBuilder.item_detail` ganhou a linha `DepotRow` (ícone do depósito + nome + `usado/total`, "Ver" quando o depósito tem lugar no mapa) só com o limite ligado; é a forma de distinguir a comida (vai à Despensa e ao Tiro) dos materiais. A Mochila mostra "Despensa 11/12" assim que há comida e a descrição da geladeira fala em despensa.
- **Saves antigos.** Piso legado só da migração: geladeira antiga 30 / `_2` 50 mantém a capacidade; jogo novo vale 24. Sem geladeira e com 40 comidas, o estoque é preservado, entradas bloqueiam e vender/dar ao Tiro funciona.
- **Fora desta etapa:** armazém e baú seguem sem limite (etapas 07–08). Testes: `fridge_test.gd` (novo, em `test_all.ps1`); capturas `tests/fridge_shots.gd`.

## Economia R1 — etapa 07: o armazém junto da Natureza

Só a categoria armazém ficou finita nesta etapa (17/10/2026). Plano: `docs/plans/economia/` (02 A, 03 Guia/materiais e linha `storage`, 05, 06).

- **Capacidades.** "Pilha de materiais" provisória 16 (`storage.warehouse.prebuild_capacity`, nome em `prebuild_name`) → armazém construído 32 (`base`) → `warehouse_2` +24 = 56 → `warehouse_3` +32 = 88. `warehouse`: 40 moedas + madeira 4 + pedra 2, pede `lais_forest` (antes: 150 moedas, madeira 8, pedra 4, `bloblo_silo`); `warehouse_2`: 90, tábua 2 + parafuso 1, pede `main_4_bench`; `warehouse_3`: 240, tábua 4 + tijolo 2 + parafuso 1, pede `own_business` (sem aro). Sem `_4/_5` (etapa 18). O armazém **não** exige a Caverna comprada: a pedra vem da Pedreira (capítulo 5, `cave_open` 80 moedas), que por sua vez não exige armazém nem bancada, sem ciclo.
- **Classificação.** Já estava certa: `wood/stone/copper/crystal/plank/brick/fiber/fabric/hardwood` (categoria `material`) moram no armazém; `bolt`, `iron_band`, `bed_gift` são `none`; `flour` é geladeira; materiais de passeio (`trail`) ainda sem depósito (baú, etapa 08).
- **Guia.** Ordem: `guide_meet` 10 → `guide_wood` 20 → **`guide_open_cave` 22** (`owned cave_open`, 5 moedas) → **`bloblo_warehouse` 25** (mesmo ID e conclusão histórica, agora `npc`/`line` `guide`, `owned warehouse`, 10 moedas, sem parafuso) → `guide_stone` 30 → `guide_fibers` 40 → `guide_treasure` 50.
- **Madeira.** `main_4_materials` = `owned warehouse` + `have wood 6` (não consome). O armazém gasta 4 e a bancada 6: são 10 madeiras no total, em duas pilhas dentro dos 16 provisórios.
- **Linha `storage` (Bloblo).** Abre com `main_4_bench`: `storage_first_planks` 10 (`produce:plank` 2 *fresh*, 1 parafuso) → `storage_first_delivery` 20 (`orders` 1 *fresh*, 1 parafuso) → `bloblo_bigger` 30 "Mais espaço onde importa" (`storage_upgrades` ≥ 1; 15 moedas + 2 parafusos) → `bloblo_biggest` 40 "Uma casa organizada" (`storage_upgrades` ≥ 3; 40 moedas + 1 parafuso). Os dois últimos mantêm o ID e a conclusão; só o que ainda não foi pago mudou (o aro de ferro saiu). Parafusos determinísticos, sem sorteio.
- **Contador `storage_upgrades`.** Derivado da posse em `GameState._changed` (`storage_upgrades_owned()`): conta `_2` em diante de qualquer depósito, nunca o edifício inicial. Saves antigos entram sozinhos; comprar conta uma vez; abrir painel nunca. Escolher silo, geladeira, armazém ou baú primeiro dá o mesmo resultado.
- **TaskHelp.** Item sem receita/rota (o parafuso) aponta para o passo de missão aberto que o paga (`TaskHelp._reward_step`), em vez de "Veja na Mochila". Na ajuda de produtos com receita, o botão principal Ir abre a estação com a receita selecionada mesmo sem ingredientes para toda a meta; não desvia para a matéria-prima. Os chips dos ingredientes continuam abrindo suas origens separadamente.
- **Missão cumprida e prêmio sem espaço.** Objetivos/entregas são consultados por `GameState.quest_objectives_error`, separadamente da capacidade para o prêmio (`quest_reward_shortage`, saldo após entregar). O cartão e a ajuda explicam o depósito e as vagas que faltam; Liberar espaço abre esse depósito. O recebimento continua manual e atômico, sem refazer o objetivo ou pagar parcialmente.
- **Galinheiro e milho (20/10/2026).** Novos moradores (`main_9_coop`) paga só 35 moedas, sem milho; o galinheiro começa vazio e a primeira galinha é comprada separadamente por 120 moedas. Bloblo orienta comprar a galinha, plantar milho, colher e alimentar no abrigo. O plantio já abre no capítulo 5 com `farm`, independente de receber essa missão ou produzir ovos. Saves que receberam os antigos presentes mantêm seus itens e animais.
- **Saves antigos.** Piso legado só da migração: armazém antigo 40/80/140 mantém a capacidade; jogo novo vale 32. Quem já recebeu `bloblo_warehouse` não recebe o prêmio de novo, e `guide_open_cave` aparece para quem ainda não abriu a Caverna.
- **Fora desta etapa:** o baú segue sem limite (etapa 08). Testes: `warehouse_test.gd` (novo, em `test_all.ps1`); capturas `tests/warehouse_shots.gd`.

## Economia R1 — etapa 08: o baú junto dos passeios

Os quatro depósitos passaram a limitar desde o primeiro recebimento (17/10/2026). Plano: `docs/plans/economia/` (02 A, 03 Nina/bagagem, 05 D, 06).

- **Capacidades.** "Sacola de passeio" provisória 12 (`storage.chest.prebuild_capacity`, nome em `prebuild_name`) → baú construído 24 (`base`) → `chest_2` +16 = 40 → `chest_3` +24 = 64. `chest`: **0 moedas + 2 gravetos**, pede `nina_walk` (antes: 80 moedas, madeira 4, `bloblo_warehouse`); `chest_2`: 80, tábua 2 + parafuso 1, pede `main_4_bench`; `chest_3`: 200, tábua 3 + tecido 1 + parafuso 1, pede `own_business` e `atelier`, sem aro (antes: 150/400, `bloblo_chest`/`bloblo_bigger`, aro). Sem `_4/_5` (etapa 18). O piso legado continua só da migração: baú antigo 20/40/70 não encolhe.
- **Classificação.** Os **11 materiais `trail`** (`stick ribbon wildflower color_button yarn smooth_pebble river_shell wild_mint bird_feather golden_leaf moon_pebble`) trocaram `storage: none` por `storage: chest` (override por item); `treat_box` e `accessory_set` já caíam no baú pela categoria `product`. Continuam isentos: ração, `bed_gift`, `bolt`, `iron_band`, pedaços do mapa, coleções e os achados de álbum (`find`). Nenhum item novo cai numa categoria sem depósito.
- **Nina.** `bloblo_chest` (mesmo ID e conclusão histórica) foi para a linha `nina`, ordem 25, entre `nina_walk` (20) e `nina_routes` (30): objetivo `owned chest`, 10 moedas, sem parafuso, fala "Trouxe gravetos? Vamos montar um baú para as coisas dos passeios."
- **Gravetos garantidos.** Primeira volta da Volta na praça: `loot.first` já dava 2 gravetos + 1 fita. Novo campo `loot.guarantee` (`{item, count, until_owned}`) na `park_loop`: enquanto o jogador não tem o baú, a volta completa os gravetos até `count` (`GameState._roll_walk` soma só o que falta: inventário + sorteio). Sem dado aleatório novo; encerra com a compra do baú; quem já tem 2 não recebe nada; nunca vende nada sozinho. Save antigo sem baú e sem gravetos recebe os 2 na próxima volta. Vale o snapshot da viagem (viagens iniciadas antes não ganham a garantia).
- **Bagagem.** Regras da etapa 03 intactas: o Tiro volta mesmo com a sacola cheia; a bagagem entra por parcelas (`claim_walk_baggage`), a recarga não repete prêmio/contador. A falta aparece como "Sacola de passeio sem espaço" até o baú existir. Saídas recuperáveis para qualquer bloqueio: vender na feira (os 11 itens têm preço), gastar na costura, dar o item no desejo, ampliar o baú.
- **Medição.** `build/economy/etapa_08/bloqueio.md` (gerado por `chest_test`): nenhuma volta de nenhum dos 7 caminhos passa de 12 itens do baú, então a primeira bagagem sempre cabe vazia; com 10 itens já guardados, 56–86% das voltas bloqueiam parcialmente, sempre com saída.
- **Interface.** O botão do cartão da bagagem bloqueada agora diz "Abrir <depósito>" (antes "Ir ao <depósito>", errado para "Despensa" e "Sacola de passeio"); a Mochila mostra o filtro "Sacola de passeio 9/12" desde o primeiro item de passeio e vira "Baú x/24" depois da compra; `worlds.json` descreve o baú como "Achados dos passeios, produtos e acessórios.".
- **Testes.** `chest_test.gd` (novo, em `test_all.ps1`); `friends_test` e `tricks_test` marcam `bloblo_chest` (passo novo da linha da Nina); `walks_test` liga `unlimited_storage` (acumula voltas sem vender); `fridge_test`, `warehouse_test`, `economy_transactions_test`, `content_test` ajustados (o baú deixou de ser "sem limite"). Capturas `tests/chest_shots.gd` (`--antes` volta ao baú antigo).

## Economia R1 — etapa 09: fontes de renda e transformação

Colher deixou de pagar moeda (18/10/2026). Plano: `docs/plans/economia/` (02 B); números e cenários antes/depois em `DECISOES.md`.

- **Sem moeda na produção.** `crops.json → coins` = 0 nas nove culturas e `activities.lane/trail.rewards.coins` = 0; itens, XP e tempos intactos. Plantar/regar continuam gratuitos. Plantios e rotas **já em andamento** pagam o snapshot (`plots[i].job.coins`, `activity.rewards`), então ninguém perde o que foi prometido ao começar. A UI esconde o chip de moeda quando o valor (ou o snapshot) é 0 (`SheetBuilder.seed_picker/growing_plot`, `RoomView.harvest_plot`).
- **Renda recorrente = vender/entregar.** A venda inicial (`early_market`, `bloblo_meet`) permite recomeçar com zero moeda e zero estoque: plantar grátis → colher → vender. Nenhuma compra obrigatória antes disso exige moeda.
- **Transformação sem perda.** `apple_biscuit` vale 30 (lote de 2: usa 26, entrega 60); `treat_box` 140 (insumos 101); `special_order` 600 (venda direta das 3 caixas: 420); `festival_contract` 940 (insumos vendidos: 696). Os demais preços ficam.
- **Prêmios pontuais.** `merchant_stall` 30, `atelier_open` 40, `bloblo_biggest` 40 (da etapa 07); capítulos 1–9: 10/20/30/40/60/60/60/80/80. Itens, XP, coleções e `shared_with` preservados; nada retroativo.
- **Presente de nível.** Tabela 2–10 igual; acima: `level_rewards.default` = `{coins_base: 20, coins_per_level: 3, coins_max: 80}` → `min(80, 20 + 3 × nível)` (`GameState.level_reward`).
- **Medição.** `build/economy/etapa_09/report.md` (`compare.py`): origem do saldo por perfil, antes × depois; teste `coins_test.gd`; capturas `tests/coins_shots.gd` (`--antes` volta aos valores antigos em memória).

## Economia R1 — etapa 10: colheitas para visitas curtas e para a volta

Plano: `docs/plans/economia/` (02 C, 03 C); números e cenários em `DECISOES.md` (18/10/2026).

- **Tabela de culturas** (`crops.json`: segundos / lote / `skill_xp`): cenoura 60/2/6, batata 300/3/16, trigo 600/4/18, morango 900/4/24, milho 1200/6/24, abóbora 3600/4/35, batata-doce 7200/6/45, ervas 7200/6/50, mirtilo 14400/8/65. Requisitos não trocados; `coins` continua 0.
- **Canteiros 5–9** (`config.json → farm.unlock_costs`): 80/140/220/340/500. Quatro iniciais, índices e `lent_plots` iguais.
- **Tempo efetivo:** `GameState.crop_seconds(índice, cultura)` = `seconds` × `greenhouse_speed` (0,7) se o canteiro é da estufa; `plant` grava `ready_at` com ele (uma vez) e a lista de sementes e a bandeja mostram o mesmo valor. Rega: 30% do tempo que falta, uma por plantio; não muda o lote.
- **Linha `flavors`** (npc Bloblo): `bloblo_strawberry` 10 (`first_kitchen` + `bloblo_dig`), `bloblo_pumpkin` 20 (`first_kitchen` + `bloblo_potato`), `bloblo_sweet_potato` 30 (`first_kitchen` + `farm_deed`). A linha principal da Bloblo vai de `bloblo_stew` direto a `farm_deed` e aos animais: nenhum timer opcional segura a escritura.
- **Medição:** mirtilo ×4 = 32 cabe no silo_2 com reserva 24; teste `garden_test.gd`; capturas `tests/garden_shots.gd` (`--antes`).


## Economia R1 — etapa 11: aprender uma rota × ganhar mais vagas

Plano: `docs/plans/economia/` (02 E); números, cenários e medições em `DECISOES.md` (18/10/2026).

- **XP local por rota** (`progression.json → activities.*.nature_xp`, gravado no lote ao começar; `GameState.route_nature_xp`): `lane` 2, `pebbles` 2, `trail` 8, `quarry` 8, `meadow` 8, `woodcutting` 12, `copper_vein` 16, `crystal_cave` 26, `timber` 35, `deep_quarry` 35, `reeds` 35, `crystal_deep` 60. Tempos/saídas: lane 120 s wood 2; pebbles 120 s stone 2; trail 600 s wood 4+stone 3; quarry 600 s stone 6; woodcutting 900 s wood 8; timber 3600 s wood 8+hardwood 3; copper_vein 1200 s stone 3+copper 3; deep_quarry 3600 s stone 8+copper 5; crystal_cave 2400 s crystal 2+copper 2; crystal_deep 7200 s crystal 5+copper 4; meadow 600 s fiber 4+wood 2; reeds 3600 s fiber 10+wood 3. O XP de atributo (`skill_xp`) não mudou. `xp_per_collection` (10) ficou só como valor de compatibilidade para lotes/rotas guardados sem `nature_xp`. Pomar (`orchard_harvest`): 3600 s, 8 maçãs, sem local, sem XP local.
- **Quatro patamares** por local (`nature_sites.*.levels`): XP 0/24/120/360, vagas 1/2/2/3. Cobre (e juncos do Prado) e a segunda vaga no nível 2; madeira dura e cristal no 3; **a terceira vaga só no nível 4**. `slot_levels: [2, 4]` diz em que nível cada token `*_slot_N` entra; os tokens `forest/cave/meadow_level_2/3` seguem liberando os recursos; o nível 4 não tem token próprio. `trees_slot_3`/`rocks_slot_3`/`fibers_slot_3` agora têm `nature_unlock.level` 4. `ProgressionState.sync_nature_tokens(site)` é a única sincronização (usada por `GameState._sync_nature_unlocks` e `from_dict`).
- **Piso legado:** `nature_level` é o maior entre o nível do XP e o das ampliações já possuídas (`level_upgrades[i]` → i+1; `slot_upgrades[i]` → `nature_slot_level`). Quem tinha vaga 3 ou madeira dura/cristal (XP 90/120 antigos) continua com as três vagas e os recursos (nível 4, sem cobrar de novo); a barra nunca inventa XP retroativo (`nature_info.xp` é limitado a 0..patamar). Sem `SAVE_VERSION` novo e sem reset.
- **Rota escolhida pelo jogador:** `start_gathering/start_next_gathering/start_gathering_all/gathering_error/next_gathering_error` aceitam `route_id` vazio (usa `GameState.default_gathering_route(recurso)`, a elegível mais curta); rota de outro local/material, desconhecida ou bloqueada devolve o motivo e não mexe no estado. `woodcutting` abre com o Bosque (`forest_open`, sem nível 2). Na interface, `NatureUi.eligible_routes/best_route/choose_route/route_choice` e `StationTray.material_detail`/painel `NatureUi.panel` mostram uma linha `RouteChoice_<material>` (botões `NotebookTab_<rota>` com a duração) quando há mais de uma rota elegível; a escolha vale só na sessão (`NatureUi.chosen`), nada troca sozinho e escolher não inicia a busca. O detalhe mostra saída, tempo e `+N XP` da rota selecionada; o "Ir" de uma missão (`NatureUi.open_route`) escolhe a rota exata. Desde a correção de 20/10/2026, com o local aberto e a sala visível, ele abre a mesma `StationTray.nature` do toque no objeto, já no material pedido; não abre mais o painel antigo por padrão. `RoomView.can_open_nature_tray` valida marcador/local. A consulta completa continua em Ver tudo e o painel de desbloqueio continua disponível quando o local está fechado.
- **Textos:** "Faltam N XP" (sem "N buscas", que dependia de uma rota única); vagas fechadas mostram o nível de verdade (2 e 4).
- Testes: `nature_routes_test` (novo), `nature_test`, `content_test`, `coins_test` ajustados. Capturas: `tests/nature_shots.gd` (`--antes` volta só os dados).

## Economia R1 — etapa 12: filas e Preparar N

- Tempos das receitas = tabela 02 D (`recipes.json`); ovos/leite são a duração do LOTE (um lote cobre até 3 animais, sem fila de animais).
- Vagas: `stove_queue` (80, exige `first_kitchen`), `stove_queue_2` (220 + tábua 3, bancada + fila anterior), `blender_queue` (100 + tábua 1, bancada). Cada vaga é um trabalho sequencial, sem processamento paralelo.
- `GameState.cook_many(receita, N)` (e `cook` = N 1): tudo ou nada, N jobs individuais com `ready_at` encadeado e snapshot próprio; `cook_max`, `cook_inputs`, `cook_finish_at`, `station_free_slots`, `cook_many_error`. Pronto e não pego ocupa a vaga. Criações e costura (`output_collection`): N = 1.
- Interface: `StationTray.recipe_detail` mostra `− ×N + Tudo ×N`, ingredientes/saída/tempo totais e "Pronto às HH:MM"; `StationTray.quantity` guarda a escolha só na sessão. Teste `queue_test`.

## Economia R1 — etapa 13: capítulos 1–9 sem tarefas repetidas

- História que orienta, personagem que entrega: `main_5_pickaxe`→`guide_open_cave`, `stone_path`→`guide_stone`, `main_6_commerce`→`merchant_variety` (novo, linha merchant, ordem 45, 10 moedas) somam-se aos cruzamentos que já existiam (10 pares `shared_with` no total). O alias tem um único objetivo `quest` e prêmio vazio; save antigo com o marco recebido resolve a canônica sem pagar.
- Objetivos reconhecem o histórico (sem `fresh`): `main_5_cooking` (lanche de cenoura 2, sopa de legumes 1, suco de morango 1), `main_7_greenhouse` (estufa + `harvest:herbs` 1; as ervas não exigem mais o atributo Horta 5), `main_8_building` (6 tábuas), `atelier_open` (ateliê + tecido 2 + conjunto de acessórios 1).
- `GameState._sync_step` poda as bases de contadores que deixaram de ser `fresh` num passo ativo carregado de save antigo.
- Testes: `journey_test` (pares, entrega única, saves antigos e dos capítulos 3/5/7/9, base obsoleta, ateliê); capturas `tests/journey_shots.gd` (`--antes` troca em memória as missões/ervas anteriores).

## Economia R1 — etapa 14: investimentos e cadeia dos animais

- Custos da tabela 02 F em `progression.json → upgrades` (escritura 220, bancada 160, galinheiro 260, curral 420, moinho 300, queijaria 420, pomar 400, banca 500, estufa 850, ateliê 1000); preços dos animais em `config.json → animals` (galinhas 120/150/180, vacas 220/280/340). Variedades ruiva/caramelo exigem 8 produtos recolhidos (`produced`), preta/malhada 24; rendimento igual para todas.
- Linha da Bloblo 70–140: `main_9_flour` pede moinho + 2 farinhas (histórico, sem `fresh`); `bloblo_breakfast` (ordem 140, 15 moedas) reconhece o pedido `farm_breakfast` já existente (`order:farm_breakfast` 1), sem recolher queijo de novo.
- Milho/trigo são sementes renováveis; nada exige colher produto animal antes de alimentar. A compra de animal durante um lote não altera o snapshot em andamento (`animals` do lote).
- Teste: `animals_chain_test`.

## Economia R1 — etapa 15: clientes e banca

- `progression.json → orders[*].customer` (lais/bloblo/nina) e `customer_tiers` (3/8/18 entregas, variedade 1/2/2, prêmios 10/20+parafuso/30). `ProgressionState.customer_orders(npc)` (entregas e tipos), `customer_level(npc)` (0..3, derivado de `order:<id>`), `distinct_orders(canal)`. `GameState._pay_customer_tiers` (chamado em `fulfill_order`) paga cada patamar uma vez por `_grant_automatic("customer:<npc>:<n>")` e avisa por toast.
- Requisito novo `distinct_orders: {"contracts": N}` (tipos de contrato com contador > 0; erro "Faça N tipos de contrato"). stall_2: 900 moedas, `contracts` 6 + 2 tipos; stall_3: 1500, 15 + 3 tipos. `banquet_contract` exige `stall` (não `stall_2`).
- Interface: `MarketUi.customer_seals/customer_text/customer_row`, `CustomerSummary` no quadro dos vizinhos, `Customer_<npc>` no detalhe do pedido, cabeçalho da banca com "contratos · tipos". Selo = laço tingido (`Palette.SEAL_BRONZE/SILVER/GOLD`).
- Testes: `customers_test`; capturas `tests/customers_shots.gd` (`--antes` remove o cliente em memória).

## Economia R1 — etapa 16: vínculo útil e rotinas

- Cuidado: `GameState.pet/play/feed/bathe` medem o ganho antes/depois (`_care_gain`) e contam `care_useful`/`care_useful:<ação>`; afeto do carinho (+1) e do brincar (+2 se útil) com recarga de 120 s em `progress.cooldowns` (`affection:pet`, `affection:play`, `useful:pet`). Exceções (`_care_exception`): desejo de ação que ainda falta (`slot.used`) ou passo de história; `_care_forced` na entrega de desejo de comida.
- Desejos: moedas pela fórmula da tabela 02 G, teto 12 nos especiais, `wish_item:<item>`, `wish_item_reachable`, troca imediata do impossível (`swap_reason`). Vínculo 2–8 paga 10/15/20/25/30/40/50.
- Rotinas: `routines.json → missions` (catálogo R1) e `legacy`; `routine_target/routine_phase`, snapshot `targets`/`catalog` em `progress.routines`; contador `production_jobs`. Cosméticos das semanais antigas migrados para as novas.
- Nina: `nina_rare` na linha `nina_discoveries`; pet shop depende de `nina_routes`.
- Teste: `bond_test`.


## Economia R1 — etapa 17: três produtos e gravetos renováveis

- Receitas em `recipes.json` (`braided_toy`, `picnic_pack`, `blueberry_treat`, `cut_sticks`); itens em `items.json` com ícones `item_braided_toy/picnic_pack/blueberry_treat.png` (PixelLab Pixen 32 px). Só `blueberry_treat` tem `feed` (fome 20, alegria 10) e `storage: fridge`; brinquedo/cesta são `product` (baú).
- `player_xp` opcional por receita (`WorkJobs.batch`): substitui o XP global do cook e é congelado no snapshot do lote; sem o campo, vale o XP da ação. `cut_sticks`: 1 e `skill_xp` 0.
- Encomendas `nina_toys`, `lais_picnic`, `nina_blueberries` (com `customer`, sem `channel`); linha `workshop` do Guia e `nina_blueberry` na linha `nina_flavors` (`wish_item:blueberry_treat`).
- Desejos: `wishes.json → <id>.guarantee_quest` faz `GameState._pick_wish` oferecer o pedido na próxima vaga vazia enquanto a missão está ativa (`current_line_quest`), respeitando alcance, pedidos já ativos e o último pedido trocado do espaço.
- Interface: `ActionTray` no modo `pick` rola quando tem mais de duas linhas (fogão com 10 receitas).
- Teste: `products_test`.

## Economia R1 — etapa 18: ampliações de conforto e maestria das estações

- **Depósitos `_4` e `_5`** (`progression.json → upgrades`, `storage.<depósito>.levels` agora com quatro ampliações): totais 128/176 (silo e armazém) e 88/120 (geladeira e baú) somando só a diferença em `storage_capacity` (40/48, 24/32, 40/48, 24/32). Custos da tabela 02 A (silo 550/1000, geladeira 500/900, armazém 500/900, baú 400/750, tábuas, tijolos/tecido e 1/2 aros). `_4` exige o estágio anterior + `atelier_open`; `_5` exige o `_4` + `stats.contracts ≥ 12`. Nada pede o último estágio (campanha e projetos seguem sem ele). O piso legado continua gravado só pela migração: `max(curva, piso)`, recarregar não soma de novo.
- **Filas novas** (`config.json → stations.<id>.slot_upgrades`): `stove_queue_3` (500 + tábua 4 + parafuso 1; exige `stove_queue_2` e `own_business`), `mill_queue` (250 + tábua 3), `dairy_queue` (350 + tábua 3 + tijolo 2), `atelier_queue` (450 + tábua 4 + tecido 1). Só dão +1 vaga (fogão 4, moinho/queijaria/ateliê 3); tempo e rendimento ficam como estavam; sem exigir maestria. Lugares em `worlds.json → places.<id>.upgrades`.
- **Maestria** (`progression.json → mastery`: `stations` fogão/liquidificador/bancada/moinho/queijaria/ateliê e `tiers` 12/40/100 lotes com variedade 2/3/4): derivada de lotes recolhidos em `GameState.collect` (`_count_station_job`), contadores `station_jobs:<estação>` e `station_recipe_jobs:<estação>:<receita>`; um lote = 1 qualquer que seja a saída, repetir a coleta não conta, lote que não coube continua na fila e só conta ao ser recolhido. Variedade pedida = `min(meta, catálogo elegível)` (`mastery_catalog_size`: receitas comuns abertas ou já feitas, sem cosméticos), nunca menos de 1: o moinho (uma receita) alcança os três selos. O nível é "recebido ou alcançado": o que já foi pago (`mastery:<estação>:<n>`) não retrocede com receitas novas. Prêmios 10/20/30 moedas por `_grant_automatic`, sem multiplicador de renda/produção/velocidade; animais e costura de coleção ficam de fora.
- **Histórico antigo:** `GameState._seed_mastery` (uma vez, marcado em `economy.mastery_method`: `"r1"` = jogo novo contado lote a lote, `"min_units_v1"` = saves anteriores, registrado também em `economy.legacy.mastery`) usa `produce:<item>` ÷ maior rendimento conhecido (arredondando para cima = mínimo comprovável). Saída compartilhada por duas receitas da estação (tábua: bancada comum e madeira de lei) só soma ao total da estação e deixa a variedade da receita em 0. Nada é pago na migração: o selo alcançado sai no próximo lote recolhido.
- **Interface:** `SheetBuilder.mastery_row` (nó `Mastery_<estação>`: três selos de fita, "N/M lotes · k/n receitas" e "?") no cabeçalho da `StationTray` e em `station_view`; `mastery_help` lista total e variedade de cada patamar e diz que não acelera nada. A grade de receitas rolável da bandeja `pick` passou de 2,5 para 1,9 linha para o medidor caber na sala.
- **Utilidade verificada** (`tests/expansion_capacity.gd` → `build/economy/etapa_18/capacidade.md`): volta de 24 h com todas as vagas cheias e uma reserva no depósito. Silo: reserva 24 → `_4` resolve (18 colheitas ficavam fora no `_3`); reserva 64 → só o `_5` resolve. Armazém: reserva 64 → `_4`; reserva 100 → `_5`. Geladeira (reserva 48) e baú (60): `_4` resolve, o `_5` é só conforto. Lotes que não cabem ficam prontos na fila.
- Testes: `expansion_test` (novo); `chest_test`, `fridge_test`, `silo_test`, `warehouse_test`, `garden_test`, `pending_gifts_test`, `economy_transactions_test` ajustados (o `dev_unlock_everything` agora compra `_4/_5`); o simulador (`tests/helpers/economy_sim.gd`) declara as moedas dos selos na guarda de conservação. Capturas: `tests/expansion_shots.gd`.


## Economia R1 — etapa 19: obras comunitárias (estado e motor, sem conteúdo)

Só infraestrutura: o catálogo `game/data/projects.json` fica **vazio** (`{"schema": 1, "projects": {}}`) até as etapas 20–22; nenhum prédio, balão, missão ou tela de obra aparece para o jogador. O banco, o jardim, o piquenique e a festa entram com a interface, nunca antes.

- **Esquema de `projects.json`** (lido por `Database.projects`; `Database.project(id)`, `project_ids()`): por projeto `id`, `name`, `npc`, `world`, `requirements` (avaliador comum, aceita `"projects": ["<id>"]`), `start_coins` (taxa **só ao começar**), `phases[{id, items{item: qtd}, visual_state}]` (material **total** da fase, entregável aos poucos, sem `fresh`), `rewards` (`coins`, `items`, `collections`, `unlocks`, `xp`), `go` (destino do "Ir", formato de `Places.goal_target`) e `interaction`. IDs de projeto e de fase são estáveis: texto/arte mudam, ID não. `Database.project_issue(id)` / `project_problems()` acusam fase sem id ou repetida, sem material, item inexistente ou quantidade não inteira, referência a projeto ausente e requisito **cíclico**; projeto com problema nunca começa nem aparece.
- **Estado** (`scripts/state/project_state.gd`, `GameState.projects`, chave `projects` no save, `schema` 1): por id `started`, `paid_start`, `phase_index`, `contributions{fase{item: qtd}}`, `completed`, `completion_rewarded`, `used_once`, `cycles{}` (reservado ao "Encontro da turma" da etapa 22). Save sem a chave = sem projetos (nenhuma migração, sem `SAVE_VERSION` novo, sem reset). Entradas de ids que o catálogo atual não conhece, campos desconhecidos e `schema` mais novo são **preservados** no ciclo de save. Consultar (`ProjectState.entry`) devolve cópia e nunca cria entrada.
- **APIs do `GameState`** (todas passam por `_changed`/`_count`): `project_available/started/completed`, `project_stage(id)` (consulta pura: `index`, `count`, `phase`, `needed`, `given`, `remaining`, `progress` da fase, `total_progress`, `done`), `project_ready`, `project_error/start_project`, `project_contribution_error/contribute_project(id, item, qty)`, `complete_project`, `project_use_error/use_project`.
- **Regras.** Começar valida requisito + moedas e cobra numa só passada; segunda tentativa recusa sem cobrar. Contribuir aceita só quantidade **inteira positiva** (decimal inteiro vindo de JSON, como `2.0`, vale 2; `0`, negativo, `1.5`, texto e NaN são recusados), só item da fase atual, nunca acima do restante e nunca sem estoque; erro não consome nem avança. Aceito: o estoque sai e a contribuição entra na mesma chamada (mesmo `to_dict`), então o material não reaparece depois de recarregar. Fase cheia avança uma vez; a **última entrega conclui e premia no mesmo passo** (`_finish_project` → `_grant_automatic("project:<id>", rewards)` + `xp`): moedas/XP/coleções/desbloqueios uma vez, itens que não couberem viram recibo `project:<id>` ("Presentes para guardar"), e a obra concluída **nunca** é bloqueada por falta de espaço. Idempotência tripla: `completed`+`completion_rewarded` na obra e `economy.granted["project:<id>"]`.
- **Recuperação.** `GameState._recover_projects()` roda ao carregar e no tick de 1 s: avança fases cheias e conclui/premia uma obra interrompida entre a última contribuição e o registro do prêmio (flag de prêmio faltando, `granted` já gravado = não paga de novo). `complete_project(id)` é o mesmo caminho, idempotente (`""` se já concluída); a interface **não** paga nada por conta própria.
- **Objetivo, requisito, TaskHelp.** Objetivo `{"type": "project", "key": "<id>", "target": 1}` (`goal_value` consulta `completed`; `content_test` valida a chave), requisito `{"projects": [...]}` no avaliador único `GameState.requirement_error` (ausente = "Projeto desconhecido", pendente = "Depois de: <nome>"), `TaskHelp.describe("project", id)` (antes de começar: requisitos + taxa; depois: material restante da fase; pronto: "Obra pronta!"; destino = `go`), `TaskHelp._requirements/_need`, `Places.goal_target`, `ProgressionUi.goal_icon`. Nunca simular conclusão com `owned`.
- **Eventos** (`Events`, emitidos **depois** de `_changed`/salvar, uma vez por transição, também na recuperação): `project_phase_completed(id, phase_id, index)`, `project_completed(id, result)` (`result` = o que o `_grant_automatic` devolveu: itens guardados e em recibo), `project_used(id, first)`.
- **Uso.** `project_use_error` exige obra concluída e Tiro em casa e acordado; `use_project` conta `project_use:<id>` e `used_once` só na primeira vez; repetir só emite `project_used(id, false)` (sem moedas, XP, afeto nem necessidades). A interface chama quando a reação efetivamente começa em ponto alcançável.
- Contadores novos: `project_start`, `project_contribution` (unidades), `projects` (concluídos), `project_use:<id>`.
- Teste `projects_test` (fixture de três fases + jardim + ciclo/ausente/inválido; 158 verificações; em `tools/test_all.ps1`). A fixture vive só no teste (`Database.projects` é trocado em memória).

## Economia R1 — etapa 20: Banco da Praça (primeiro projeto visível)

Primeira obra comunitária entregue ao jogador, sobre o motor da etapa 19 (nada do estado mudou: a interface só chama `start_project`/`contribute_project`/`use_project`).

- **Dados** (`game/data/projects.json`, tabela 07 E): `park_bench` — requisito `quests: [atelier_open]`, entrada **150 moedas**, fases `base` (tábua 4 + tijolo 2), `comfort` (tecido 2 + brinquedo trançado 1) e `welcome` (petisco de cenoura 3), prêmio **XP 40** (não devolve as moedas; sem itens), `npc: lais`, `icon: project_bench`, `pitch` (fala da Laís antes de começar), `go: {world: park, place: bench}`, `interaction: {kind: bench, hint}`. Nenhuma missão principal aponta para ele: é uma descoberta lateral — o "Novo!" do lugar `bench`/`community` e a fala da Laís no painel.
- **Acesso "Nossa praça"** (`worlds.json → park.places`): lugar visível `community` (painel `community`, aparece com `nina_pipoca`) que agrupa as obras da Praça (`ProjectUi.community`, uma linha por projeto `world: park` já disponível) e os atalhos **Amigos** e **Treino**. Estes dois passaram a `hidden` (continuam com zona tocável na sala e com o mesmo painel) para a Praça manter no máximo quatro lugares visíveis (Passeio, Pet shop, Nossa praça + a Costura, escondida). `bench` é um lugar `hidden` com painel `project:park_bench`, alvo do `go` e do "Ir". Costura, treino, passeio e amigos seguem acessíveis (teste confere as ações da sala).
- **Painel de projeto genérico** (`scripts/ui/project_ui.gd`, `ProjectUi.panel(id)`): fala do personagem (`SpeechBubble`), barra total, fases em fileira (feita = check), e UM botão primário: antes de começar "Começar por N moedas" (com o aviso de que a entrega é aos poucos e não vence/volta) ou o motivo em `lock_hint`; depois, a grade `ProjectItem_<item>` (ícone, nome, entregue/necessário, tocáveis), o seletor `− + Tudo` (`Qty_*`, limitado ao que falta e ao que se tem) e "Entregar ×N item" (`DeliverProject`). Sem material: chip `ProjectMissing` abre o "Como fazer". A seleção vive no modelo do painel e sobrevive às reconstruções (`LiveBox`); item completo passa o foco ao próximo que falta; o painel permanece aberto com um aviso "Entregue: …". Obra pronta: cartão verde com "Ir ao banco". `ProjectUi.open(id)` serve a qualquer projeto futuro.
- **Cena** (`rooms/park.json → community_bench`): objeto com `project` e `project_sprites` por `visual_state` (`ghost`, `base`, `comfort`, `welcome`; PNGs `bench_base/comfort/welcome.png` em `areas/park/`, 48×40 e 56×44, geradas no PixelLab), `pos [400, 282]` (grama livre entre a árvore da frente e a cerca, medida na prévia), `footprint [[380,274],[402,264],[424,274],[402,286]]`, `approach [372, 280]` e etiqueta "Banco" em `[412, 298]` (longe da etiqueta "Amigos"). `RoomView._refresh_projects` (ligado a `state_changed`) usa `GameState.project_visual(id)` (nova consulta pura: `""` inexistente, `ghost` = marcação translúcida com balão "buy" da entrada, ou o `visual_state` da última fase entregue; concluída = o da última) e um balão `ProjectMarker` (entrada/progresso); o chão que o Tiro pisa recalcula só quando o desenho muda (o footprint só bloqueia quando a obra existe). `_refresh_gated` não mexe em objetos de projeto.
- **Uso pelo Tiro**: tocar o banco pronto chama `RoomView._use_project` → `GameState.project_use_error` (dormindo: "Tiro está dormindo. Quando ele puder, é só tocar de novo!"; passeando: o texto de ausência; nada é consumido) → `DogWorld.react_at(&"bench", approach, on_start)`. A nova reação `bench` senta ao lado por 2,5 s e comemora (animações existentes; nada de controle direto do cachorro). `on_start` só roda quando ele chegou ao ponto (≤ 12 px): aí `use_project` conta `project_use:park_bench` na **primeira** vez; repetir só repete o visual (sem moedas/XP/afeto/necessidades).
- **Conclusão**: `Events.project_completed` → `main.gd._queue_modal` → `Celebration.show_project` ("Obra pronta!", XP, dica de toque), mesmo com o Tiro dormindo/passeando; as fases intermediárias só dão um aviso. Manual: card "Obras" (só as já disponíveis) com a localização. Tour: `b16b`–`b16f`.
- **Testes**: `bench_test` (dados e lugares, requisito/taxa, material feito por receitas reais com relógio avançado, entrega parcial, salvar/reabrir no meio, conclusão com depósito cheio, XP uma vez, desenho por fase, caminho ao banco, toque em três zooms, sono/passeio sem consumir, uso uma vez só, painel: um primário, seleção, "Tudo", permanência). Capturas `tests/bench_shots.gd` (antes/depois nas três resoluções).

## Economia R1 — etapa 21: Jardim da Vila e Piquenique da Praça

Duas obras que começam juntas depois do Banco, sobre o motor da 19 e a interface da 20 (nenhuma regra de estado mudou).

- **Dados** (`projects.json`, tabela 07 E sem ajuste): `village_garden` (npc `bloblo`, mundo `village`) — canteiros tábua 4 + tijolo 4, plantio ervas 8 + madeira 6, abertura suco de morango 3; `park_picnic` (npc `nina`, mundo `park`) — cantinho tábua 3 + tecido 3, cesta cesta do encontro 2 + queijo 2, encontro petisco de cenoura 4 + picolé de morango 4. Entrada **250** cada, prêmio **XP 60**, requisito só `projects: [park_bench]`: ninguém exige o outro, contribuir a um não avança o outro, nenhum cobra manutenção. Campos novos para o painel genérico: `done_speech` (fala da obra pronta) e `interaction.go_label` ("Ir ao jardim"/"Ir à toalha"). `icon`: `project_garden`/`project_picnic`.
- **Acesso**: a Vila ganha o lugar visível **Nossa vila** (`community:village`, requisito `projects: [park_bench]`; agrupa as obras da Vila e as Encomendas; `Feirante`, `Ateliê`, `Encomendas` e `Minha banca` continuam como estavam e a Vila fica com quatro lugares visíveis fora a viagem) e o lugar escondido `garden` para o "Ir". Praça: lugar escondido `picnic`; "Nossa praça" também lista o piquenique. `ProjectUi.community(world)` lê `services` do lugar `community` (Praça: Amigos/Treino; Vila: Encomendas) e `Places._panel` aceita `community:<mundo>`.
- **Cena**: `community_garden` (Vila, pos [243, 290], approach [270, 268]) e `community_picnic` (Praça, pos [436, 168], `scale` 0,8, approach [436, 190]; a posição ao lado do banco prendia o Tiro numa fresta e foi trocada por uma faixa de grama livre a leste). Três desenhos por fase cada (`garden_beds/planting/opening.png` 64×48, `picnic_corner/basket/meeting.png` 56×40) + ícones 32 px, todos PixelLab (ver `ART_PIPELINE`). Reações novas no `DogWorld`: `garden` (fareja 2,5 s e comemora) e `picnic` (senta, mordisca e comemora); `RoomView._use_project` escolhe a reação por `interaction.kind`. Primeiro uso = `project_use:<id>` 1, repetição só visual; sono/passeio só adiam o convite e não impedem entregar nem concluir.
- **Interface**: a fileira de fases virou `HFlowContainer` (os nomes com ✓ passavam de 360 px e empurravam o painel); o chip do que falta diz "Falta X: onde achar?" (a frase antiga estourava 360 px com "Suco de morango").
- **Simulador**: `--until=projects` (e `economy_simulate.ps1 -Until projects`) injeta a fase `ph_projects` no robô (começa a obra que cabe na reserva da meta, entrega o que há sobrando, busca o que falta por `pursue_item` com escudo); ações permitidas `start_project`/`contribute_project` com conservação exata (moedas −entrada; itens −quantidade); o resumo ganha `projects` (começo e entregas com dia, horas, minutos ativos, sessão e saldo) e marcos `bench_done/garden_done/picnic_done/projects_all`. Fora de `until=projects` o robô não muda: a campanha é idêntica à da 20.
- **Testes**: `garden_picnic_test` (dados, requisitos, taxa, as duas ordens, conclusões consecutivas, começar os dois + contribuir + recarregar, material faltante, sono, contador de uso e reconhecimento após reload, painel e lista em 360 px, desenho por fase, caminho e navegação). `projects_test` espera os três projetos no catálogo real. Capturas: `tests/garden_picnic_shots.gd`; tour `b16g`–`b16k`.

**Esforço medido** (simulador, `until=projects`, `build/economy/etapa_21/*_s1_obras`):

| Perfil (semente 1) | Campanha 90/90 | Banco | Jardim | Piquenique | Fim | Entregas / unidades | Sessões com progresso | Violações |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| reference | dia 16 | dia 13 | dia 14 | dia 17 | 17,8 d | 34 / 55 | 17 | 0 |
| recovery | dia 17 | dia 13 | dia 17 | dia 18 | 18,8 d | 35 / 55 | 18 | 0 |
| light | 86/90 (travado como antes em `nina_sewing`) | dia 35 | dia 38 | dia 50 | 50,3 d | 32 / 55 | 12 | 0 |
| commercial | dia 18 | dia 17 | dia 22 | **não concluiu** (fase "Cesta": 1 de 2 cestas) | 42,1 d (travou) | 28 / 46 | 11 | 0 |

Custo total das duas obras: 500 moedas de entrada + jardim 25 unidades (tábua 4, tijolo 4, ervas 8, madeira 6, suco 3) + piquenique 18 unidades (tábua 3, tecido 3, cesta 2, queijo 2, petisco 4, picolé 4); cada cesta ainda consome 2 petiscos + 2 picolés + 1 suco, ou seja, 8 petiscos e 8 picolés no total. O piquenique é a obra cara: leva 1–4 dias a mais que o jardim no robô ativo e 12 dias a mais no leve (ver DECISOES, "etapa 21", para a leitura do `commercial`).

## Economia R1 — etapa 22: Festa da Vila, Lenço da nossa turma e capítulos 10–12

Fecha a nova história sobre o motor da 19 e as obras das 20–21.

- **Festa** (`projects.json → village_festival`, tabela 07 E sem ajuste): npc `lais`, mundo `village`, requisitos `projects: [village_garden, park_picnic]` + `owned: [stall_3]` (o jardim e o piquenique podem vir em qualquer ordem), entrada **500**, fases `decorate` (tecido 4 + tábua 6 + conjunto de acessórios 2), `table` (cesta do encontro 3 + biscoito de maçã 6 + queijo 4) e `gifts` (caixa de petiscos 3 + brinquedo trançado 2), prêmio **XP 100 + coleção `community_ribbon`** (sem moedas nem itens). Interação `festival`. **Não é o contrato comercial**: `festival_contract` continua do Feirante com o mesmo id e a missão `merchant_festival`, agora com o nome "Encomenda para eventos" (`progression.json → orders` e textos); as duas coisas não compartilham entrega, prêmio nem marco.
- **Lenço da nossa turma** (`collections.json → community_ribbon`, slot `neck`, `source: project:village_festival`): overlay + 52 quadros por pose gerados do lenço vermelho (`tools/ribbon_recolor.gd`; mesma máscara e âncoras), ícone `outfit_community_ribbon`. Vem pelo prêmio da obra (`_apply_rewards → collections`), não ocupa depósito, entra na Coleção e se veste/tira como as demais roupas. O cartão "Obra pronta!" mostra o nome do lenço (`Celebration.show_project`).
- **Cena**: objeto `community_festival` em `rooms/village.json` (pos [385, 236], approach [385, 258], footprint losango, requisitos iguais aos da obra), três desenhos 72×52 (`festival_decorate/table/gifts.png`) + ícone `project_festival`; lugar escondido `festival` (`panel: project:village_festival`, o "Ir" leva direto) — "Nossa vila" já lista a obra sozinha (a Vila continua com quatro lugares visíveis). Reação `festival` no `DogWorld` (senta, late de alegria e comemora). A festa **fica no mapa para sempre**.
- **Uso**: igual às outras obras (`use_project`; o primeiro conta `project_use:village_festival`, repetir é só visual).
- **Encontro da turma** (`village_festival.gathering`, só depois da festa): material `picnic_pack 1 + carrot_snack 2`, intervalo `hours: 24`, recompensa só **XP 10**, sem moedas, afeto, ferramentas nem material de ampliação, nada em rotina. `ProjectState` ganhou `completed_at` (Unix, gravado na primeira conclusão; entrada em branco passou a 9 campos, `SCHEMA` continua 1) e `cycles` (`{"1": {"at": Unix}}`); `GameState.meeting_def/meeting_ready_at/meeting_error/gather_project`: valida tudo antes (obra concluída, Tiro em casa e acordado, 24 h desde a **última** conclusão — a da festa ou a do último ciclo —, material) e só então consome, registra o ciclo e paga por `_grant_automatic("project_gather:<id>:<ciclo>")` (identidade própria por ciclo, XP uma vez); tudo no mesmo salvamento. Eventos: `Events.project_gathered(id, ciclo)` → `RoomView._on_project_gathered` manda o Tiro até a festa (primeiro uso conta). Contadores `project_gather` e `project_gather:<id>`. DEV: `dev_advance_time` também desloca `completed_at`/`cycles`. Interface: `ProjectUi._gathering_card` (nó `GatheringCard`, botão `GatherProject`, chips do material, espera em `lock_hint`).
- **Capítulos 10–12** (`progression.json → chapters`, `final_chapter` continua, agora o 13º estado): 10 "Um lugar para descansar" (30 moedas), 11 "Um encontro especial" (40), 12 "A festa da nossa turma" (60). Nove missões principais em `quests.json` (31 + 9 = **40**; 81 + 18 = 99 no total): `community_10_meet` (`talk:lais` fresh), `community_10_bench` (`project park_bench`), `community_10_use` (`stat project_use:park_bench`, afeto 5), `community_11_garden`, `community_11_picnic`, `community_11_tiro` (afeto 5), `community_12_prepare` (`talk:nina` fresh), `community_12_festival` (`project village_festival`), `community_12_memory` (`project_use:village_festival`, afeto 10). Só as duas conversas pedem toque novo; obras e usos já feitos contam na hora (saves das etapas 20–21 entram no 10 sem refazer entregas e sem material novo). Missões não pagam moedas nem itens. `Places.goal_target` entende `project_use:<id>`; `content_test` aceita o contador e trata obra feita pela história como concluída ao validar destinos.
- **Simulador/robô**: `pursue_project` (cumpre requisitos, começa, entrega e busca o que falta com escudo) serve de meta para os objetivos `project` e `project_use:` (nova ação permitida `use_project`, sem efeito em moedas/itens), `pursue_reqs` entende `projects`, `_protect_project` protege taxa e material da obra que a meta espera, e `ph_projects` busca o requisito de compra (a banca 3) de uma obra indisponível. A campanha agora **inclui a Festa**.
- **Testes**: `festival_test` (dados, requisitos, taxa, prêmio e lenço, história de jogo novo até o final, legado do capítulo 9 e obras anteriores, recebimento repetido, Encontro antes/depois de 24 h, material, sono, reload, última entrega salva no meio, painel e sala). Capturas `tests/festival_shots.gd`; tour `b16l`/`b16m`.

**Esforço medido** (simulador, referência, semente 1, `build/economy/etapa_22/`): campanha completa **99/99 em 21,1 dias** (antes: 15,1 d com 90 missões), 65 sessões, 648 min ativos, 0 violações; Banco dia 7–8, Jardim dia 8, Piquenique dia 8–10, **Festa dia 17–19** (espera a banca 3 e as 500 moedas; 31 875 moedas em caixa na entrada). Até as quatro obras (`until=projects`): 17,3 d, 0 violações. Custo da festa: 500 moedas + 30 unidades (tecido 4, tábua 6, conjunto de acessórios 2, cestas 3, biscoito 6, queijo 4, caixas 3, brinquedos 2), além dos ingredientes de cadeia de cada receita.



## Crescimento do Tiro

Etapa 02 do plano Tiro (19/10/2026): motor sem interface do jogador nem troca de arte.
`growth.json` define Recém-chegado → Filhotinho → Dentinhos → Aventureiro → Mocinho → Azul e Dourado,
quatro pilares (Corpo/Pelagem/Esperteza/Coragem), níveis 10/25/45/70/100/135/175/220/270/330 pontos,
tetos 1/2/4/6/8/10 e os requisitos provisórios de `docs/plans/tiro/02_FASES_E_PILARES.md`, seção C.
Itens-chave e presentes decorativos de etapas futuras ainda não existem: presentes atuais são
30/60/100/150/250 moedas e três rações no Filhotinho. A etapa 03 usa `growth: puppy` na feature `growth_tab`.

`GrowthState` persiste em `growth`: fase/instante, pontos/reserva, requisitos definitivos, entregas,
base dos contadores, cerimônias, recargas e primeiras vezes. `GameState.growth_info()` e `grow_error()`
são consultas puras; `_sync_growth` grava os requisitos cumpridos nas mutações. `feed`/`stat` usam a
diferença em relação à base do começo da fase. `deliver_growth(item)` entrega até o restante necessário,
consome itens e preserva a entrega parcial. `grow()` registra a cerimônia ainda não vista, aplica a reserva
até o novo teto, usa o recibo `growth:<fase>` para pagar uma vez e emite `grew`.
`growth_ready` e `growth_requirement_done` só anunciam novas conclusões. A etapa 03 emite
`pillar_gained` nas fontes reais descritas abaixo.

DEV → Crescimento permite escolher fase, somar pontos, completar requisitos e crescer.
As três ferramentas `dev_*` têm guarda de canal. O requisito genérico `growth: "teething"` retorna
"Quando ele for Dentinhos" antes de alcançar a fase e aceita fases posteriores.

Save versão 13: abrir qualquer slot <13 recomeça no Recém-chegado, sem migração de crescimento.
Preferências de `settings.json` permanecem; o timestamp de atividade continua sendo atualizado.
O aviso "O Tiro chegou de novo, filhotinho!" aparece uma vez após a introdução (ou imediatamente
se não houver introdução). Os testes usaram cópia do save do Vitor e armazenamento descartável.

### Etapa 03 — Corpo, Pelagem, Esperteza e Coragem (19/10/2026)

**Refeições e Corpo alinhados (20/10/2026):** as porções de cada crescimento são uma única tarefa
de alimentação. `feed.body_level` garante o patamar de Corpo ao completar a quantidade pedida:

| Próxima fase | Refeições na fase atual | Corpo garantido |
|---|---|---|
| Filhotinho | Qualquer comida ×3 | 10 pontos (nível 1) |
| Dentinhos | Cenoura gelada ×3 | 25 pontos (nível 2) |
| Aventureiro | Ração de crescimento ×3 | 70 pontos (nível 4) |
| Mocinho | Mingau de leite ×3 | 135 pontos (nível 6) |
| Azul e Dourado | Comida favorita ×3 | 220 pontos (nível 8) |

Os ganhos próprios dos alimentos continuam valendo. `_sync_meal_body`, chamado nas mutações,
completa apenas a diferença até o patamar, sem bônus Radiante nessa diferença ou reserva extra;
`growth.firsts[meal_body:<fase>]` impede repetição. Consultas continuam puras. Saves que já
concluíram as porções recebem o reconhecimento no carregamento. Nenhuma refeição da fase anterior
passa a contar para a próxima. Corpo não é cobrado outra vez em `pillars`.

Os demais cuidados são requisitos `pillars` independentes de um único atributo: `pillars` = Fazer
carinho/Coragem, `care_smart` = Brincadeiras e descobertas/Esperteza, `care_coat` = Banhos e
escovação/Pelagem. A migração única `care_actions_v1`, em `growth.firsts`, copia confirmações do
antigo grupo para os novos cuidados; saves novos não propagam uma confirmação entre ações.
Os patamares e recargas dos cuidados foram preservados. O painel mostra cada ação, seus pontos
e o próximo passo real. A comida informa Desenvolve Corpo/Corpo completo, incluindo a comida
especial/favorita na ajuda. Teste `growth_meals_test`; capturas `growth_ui_test --meal-shots`.

Todas as fontes da tabela 02 D do plano passam por `GameState._gain_pillar(id, pontos, origem)`:
comida, banho útil, brincadeira útil, carinho com afeto, desejos, retorno de passeio, faro,
truques, petiscos/visitas de amigos, primeira conversa, primeira visita com o Tiro e uso contado de obra.
Soneca de pelo menos 1 h terminada com energia 100 soma Corpo 2, com recarga de 12 h.
`growth.cooldowns.sleep_since` registra o começo; um cochilo que já encheu a energia antes de 1 h
não passa a valer só por esperar. Recargas de banho (2 h) e brincar (30 min) ficam em `growth.cooldowns`;
primeiras conversas/mundos/truques e comidas ficam em `growth.firsts`. Todos sobrevivem à recarga.

Números em `growth.json.sources`. Radiante: quatro necessidades ≥60 no instante do ganho, ×1,5 e
arredondamento para cima (após o fator da comida); sem perda de pontos por necessidade baixa.
Teto e reserva usam o motor da 02. `pillar:<id>` conta os pontos concedidos; `pillar_gained` informa
pontos e se houve novo nível. A ferramenta DEV usa a mesma função, com quantidade exata, sem Radiante.
`_apply_rewards` aceita `pillars: {id: pontos}`; `_grant_automatic` preserva o recibo único.

Dez comidas existentes têm `growth.pillars/phases`; fora da fase vale ×0,5; ração usa `only_phases`
e só soma Corpo no Recém-chegado/Filhotinho. Cru continua sem pontos. `feed` é a única aplicação da
comida, inclusive no "Ele quer!". Banho com xampu tem caminho interno `bathe(true)` e recarga comum ao
banho normal; item/receita/opção visual só chegam na 09. Escovar continua na 12. Bônus de Esperteza +1
ao brincar usa a fase Aventureiro em diante, quando o plano concede o cesto; decoração fica na 14.

Carinho concede Coragem junto do afeto uma vez a cada 120 s, sem limite diário; reage livremente
durante a espera. `GameState.pet_growth_info()` consulta a recarga persistida, pontos, teto e reserva.
O balão do Tiro mostra o ganho real (ex.: Coragem +1 · 69/70), a espera ou o ganho guardado após
atingir o teto. Caderninho e ajuda de Coragem explicam o intervalo; a contagem no caderninho atualiza
a cada segundo. Não muda a regra de Radiante nem os pontos/recargas existentes.

**Brincar e Esperteza (20/10/2026):** cada brincadeira pode render **3 de Esperteza a cada 5 min**, mesmo com Felicidade cheia; bônus do cesto (+1 por brinquedo, até +3) e Radiante continuam. `_pillar_source("play")` roda no brincar bem-sucedido, separado de `_care_useful`: afeto e contadores de cuidado útil ainda exigem recuperação ≥5 ou pedido, sem recompensar cuidado vazio. Energia mínima 15, sono/passeio e custos de necessidades preservados. Carregamento limita uma espera antiga ao novo intervalo, sem zerar pontos nem reiniciar o relógio ao reabrir. `GameState.play_growth_info()` consulta `growth.cooldowns.play`, sem consumir a espera. `PetCareTray` mostra `PlayGrowthTimer` abaixo dos cuidados, atualizado pelo refresh; a reação junto ao Tiro diz Esperteza +N/progresso/reserva ou o motivo de não ganhar. Ajuda de Esperteza e caderninho Crescimento (`PlayGrowthHint`) repetem ganho, regra e espera real. Pode brincar durante a espera, sem pontos extras.

Caderninho substitui Atributos por Crescimento após a primeira fase (`growth_tab`, `growth: puppy`):
nome/idade, quatro `PillarRing_<id>` com ícones, nível/teto e reserva. `PillarUi` atualiza enquanto aberto
e anima uma subida de nível. Os níveis locais de Natureza continuam no painel próprio. A tela Tiro
agrupa os eventos do mesmo quadro, mostra um ganho por vez com ícone e brilho Radiante, respeitando
Menos animação. Sem troca da arte do cachorro, HUD, reset ou publicação nesta etapa.

## Tiro no centro — etapa 05 (19/10/2026): visual por fase

`GameState.dog_look()` retorna corpo, pastas pet/mundo, retrato, frontal, fallback e coat do catálogo
`growth.json.phases/bodies`. Recém-chegado/Filhotinho usam puppy; Dentinhos/Aventureiro young;
Mocinho/ Azul e Dourado adult. Mocinho: `0,3 + 0,4 × média(níveis dos pilares)/teto`; adulto: 1.
Tela do Tiro, mapa, caminhada do passeio, cartões/retratos, introdução e HUD trocam sem recarregar a cena.
Filhote permite equipar, mas oculta roupas e avisa no caderninho; jovem usa âncoras por clipe/slot.
Sem mudança de crescimento, progressão, salvamento ou números econômicos nesta etapa.


## Tiro no centro — etapa 06 (19/10/2026): tela de crescimento

`GrowthUi.panel/open` consulta `GameState.growth_info()` (fase atual, catálogo/datas/arte, próxima,
requisitos e atributos). `GrowthBadge` junto do vínculo abre o painel desde Recém-chegado; anel 44,
número da fase, Falta 1! quando falta um requisito e pulso pronto. Caderninho → Crescimento tem
Ver crescimento. Requisitos abrem `TaskHelp.describe("growth_req", id)` com Ir via `Places`.
Entregáveis usam Dar no painel e no detalhe da Mochila, pelo mesmo `deliver_growth`; entrega parcial
fica definitiva e o painel permanece aberto. Crescer só aparece pronto, caso contrário há cadeado
com o primeiro motivo legível. Feedback provisório: pop no Tiro e aviso O Tiro cresceu!.
Caderneta: retratos/datas/idade/peso/fato para passado/atual, atributos do atual, silhueta/teaser/Cap. N
para futuras. Sem data própria de chegada histórica: Primeira chegada. Próxima fase nunca mostra
cor/textura (shader só lê alfa). Adulto mostra Guardião do Vale. Não muda requisitos, custos ou save.


### Organização do painel revisada em 20/10/2026

**Resumo ao tocar no avatar:** `Hud.show_level_popover` usa `GrowthUi.compact_steps` para mostrar a próxima fase e só os requisitos pendentes em duas colunas (ícone real, anel, nome curto e quantidade). Cuidados usam a contagem de pilares pedidos já prontos; refeições mostram a comida, itens-chave usam seu próprio ícone, passeios usam a guia. Quando pronto, troca a grade por “Tudo pronto para crescer!”. Ver detalhes abre o painel completo. O balão fica aberto até tocar fora ou em detalhes (`Popover` com tempo zero) e reajusta sua altura após a quebra das linhas.

O painel principal de `GrowthUi` agora tem cabeçalho compacto (fase atual e próxima), resumo/barra de passos e **uma ação principal “Agora”**. Comida oferece o próximo passo real da receita; lembrança já possuída oferece Dar; Crescer substitui essa ação quando tudo estiver pronto. Os requisitos ficam em lista de largura inteira com ícone, nome, quantidade/unidade e ação por linha. O requisito agrupado de pilares mostra quantos cuidados estão prontos e abre a ajuda com cada cuidado separado; os pontos/anéis completos ficam em **Ver cuidados** (`PillarUi.panel`). A etapa automática “Chegou em casa” não entra na contagem visual de passos. Não há cadeado repetindo o mesmo objetivo nem anéis duplicados abaixo da lista.

**Caderneta · fases e lembranças** abre `GrowthUi.history`, um painel próprio com as mesmas fotos, datas, fatos, silhuetas e níveis de seda, com botão de voltar. Regras de crescimento, persistência, prioridade das cerimônias e entregas não mudam. Contratos: `GrowthHero`, `GrowthSummary`, `GrowthProgress`, `GrowthNextStep`/`GrowthNextAction`, `GrowthReq_<id>`/`GiveGrowth_<item>`, `GrowthDetails`, `GrowthHistoryButton`, `GrowthHistory` e `GrowthCard_<fase>`. `growth_ui_test` cobre todas as fases, histórico separado, ação principal única e toques de entrega/crescer; `--layout-shots` captura a tela de exemplo do Vitor e o estado pronto.

## Tiro no centro — etapa 09: comidas e xampu (19/10/2026)

As sete comidas de crescimento e Xampu de ervas da tabela docs/plans/tiro/03_COMIDAS_E_ECONOMIA.md C estão em items/recipes, com player_xp 0, storage fridge e preços 8/12/7/14/20/8/15/18. Adequação por fase dá ×1 ou ×0,5, além do Radiante existente. A guia mostra o selo do maior pilar (primeiro em empate); segurar outra comida dá a dica sem bloquear. Crus continuam sem selo. Com xampu aparece acima do banho quando há estoque e lembra a escolha na sessão. bathe(true) consome 1, conta shampoo_bath e dá Pelagem 12 em vez de 3, com a mesma recarga de 2 h e cuidado útil.

Refeições para Dentinhos/Aventureiro/Mocinho: frozen_carrot/growth_kibble/milk_porridge ×3; Mocinho também pede 2 banhos com xampu. Itens-chave permanecem provisórios até a 10. Troca dos requisitos de saves v13 em andamento usa foods_revision uma vez (DECISOES); sem reset nem perda de fases alcançadas. Manual/Como fazer e categoria Cuidados incluem o xampu.


## Tiro no centro — etapa 10: itens-chave e entregas (19/10/2026)

Categoria `keepsake` (`storage: none`, sem `sell_price`, não some da Mochila antes de entregar) e quatro itens com ícone próprio: `chew_ring`, `stick_chew`, `soft_brush`, `courage_medal`. Receitas da bancada `stick_chew` (graveto 3 + madeira 1, 300 s) e `soft_brush` (tábua 1 + fibra 2, 600 s, `main_8_fiber`), ambas `player_xp` 0, e da costura `sew_topknot_bow` (tecido 1 + fita 2, 600 s, `growth: young`), que entrega a roupa `topknot_bow` (cabeça) pela coleção. Missão da vovó `bloblo_chew_ring` (linha `bloblo`, ordem 62, requisito `first_kitchen`; entrega cenoura 3 + batata 1 → `chew_ring` + 10 moedas). `community_12_memory` passa a dar também `courage_medal` (+ afeto 10).

`growth.json` final dos itens-chave: Dentinhos `deliver chew_ring`; Aventureiro `deliver stick_chew`; Mocinho `deliver soft_brush`; Azul e Dourado `deliver courage_medal` + `feed any ×3` (provisório até a 12, favorita) + `collection topknot_bow`. O id do requisito `key` foi preservado nas três primeiras fases (recibos antigos continuam valendo); a fase adulta perdeu `festival` (a obra continua existindo, só não exige mais). A entrega usa o `deliver_growth` da 02 (definitivo, grava em `growth.delivered`).

Interface: "Dar" no cartão do requisito e no detalhe do item da Mochila (`GiveGrowth_<id>`), com `Haptics.tap` e o ícone voando até o Tiro do painel (`GrowthUi._fly_to_tiro`, nó `FlyingKeepsake`, ignorado com Menos animação); o item some da Mochila ao entregar. Mochila: filtro "Para o Tiro" (`keepsake`) e botão "Ir" (`KeepsakeGo`) no detalhe, que abre o painel de crescimento; o Manual também lista a categoria. Teste `keys_test`; capturas `tests/keys_shots.gd`.


## Tiro no centro — etapa 11: a história conduzida pelo crescimento (19/10/2026)

**Ajuste de ritmo em 20/10/2026:** Dentinhos → Aventureiro pede Esperteza nível 2 (25 pontos) em Brincadeiras e descobertas, antes nível 3 (45). O histórico de pontos do save já vale, sem ações extras; as demais condições e os ganhos/recargas continuam iguais. Referência atual: `growth.json → explorer.requirements.care_smart`.

**Objetivo `growth`** (`{"type": "growth", "key": "<fase>"}`): cumprido quando o Tiro **já está** nessa fase ou além (`GameState.goal_value`: `growth.phase_index() >= phase_index(key)`; vale também se ele cresceu antes de a missão ficar ativa). "Ir" abre o painel de crescimento (`Places.goal_target` → `{"growth": true}`); o "?" é `TaskHelp.describe("growth", fase)`, que lista os requisitos da próxima fase que ainda faltam como chips `growth_req` tocáveis (o mesmo `_growth_requirement` do painel). No cartão da História, `ProgressionUi.goal_row` mostra a **silhueta** da fase que vem (`GrowthGoalSilhouette`, a mesma do painel) e, cumprido, o retrato dela (`GrowthGoalPhoto`). Atalho dev: `_dev_complete_quest` de um objetivo `growth` coloca o Tiro na fase (`dev_set_phase`), então `dev_jump_to_chapter` e `dev_complete_quest` deixam a fase coerente com a história.

**Requisito `growth`** (`requirements: {"growth": "<fase>"}`) no avaliador único (`GameState.requirement_error`, já da etapa 02): "Quando ele for Aventureiro". Ligado agora em truques (`paw`/`talk` Dentinhos, `roll`/`jump` Aventureiro, `spin` Mocinho) e nos passeios `creek_walk`/`bird_clearing`/`hill_view` (Aventureiro); a feature `wishes`, a receita `treat_box` (Aventureiro) e a costura `sew_topknot_bow` (Mocinho) já tinham sido ligadas nas etapas 02/07/10. O "Como fazer" de qualquer conteúdo com esse requisito ganha o passo "Quando ele for …" (`TaskHelp._requirements`, kind `growth`).

**Nove missões principais novas** (40 → 49 principais; 99 → 109 no total com a da vovó da etapa 10), todas sem prêmio próprio (o presente vem da fase), com o crescimento como **último passo** dos capítulos 1, 3, 6, 9 e 12 — como o capítulo seguinte só abre com o anterior completo, crescer abre o próximo:

**Abertura do Sítio (correção de 19/10/2026):** mapa, porta/área de toque da Casa, visibilidade da Bloblo e primeira missão da linha dela exigem receber `growth_1_puppy`, em vez de apenas `lais_bed`. Primeiro termina “Um novo lar” com o Tiro Filhotinho; depois conhece a vovó no capítulo 2 e recebe os dois canteiros de `bloblo_meet`. Nenhum save, canteiro ou item é apagado.

| Cap. | Missão | Ordem | Objetivo |
|---|---|---|---|
| 1 | `growth_1_puppy` "Ele está crescendo!" | 70 | `growth: puppy` |
| 3 | `teeth_3_ring` "Dentinhos coçando" | 35 | `quest: bloblo_chew_ring` (`shared_with`) |
| 3 | `growth_3_teething` "As orelhinhas subiram!" | 40 | `growth: teething` |
| 6 | `explorer_6_eggs` "Comida de quem cresce" | 45 | `quest: main_9_eggs` (`shared_with`) |
| 6 | `growth_6_explorer` "Um pequeno aventureiro" | 50 | `growth: explorer` |
| 8 | `young_8_shampoo` "Banho de ervas" | 40 | `stat: shampoo_bath` 1 (10 moedas) |
| 9 | `young_9_milk` "Mingau de mocinho" | 35 | `quest: main_9_flour` (`shared_with`) |
| 9 | `growth_9_young` "Pelo de mocinho" | 40 | `growth: young` |
| 12 | `growth_12_adult` "Azul e dourado" | 40 | `growth: adult` |

Os três pares `shared_with` novos seguem a regra de sempre (a principal só orienta, a linha da vovó entrega e paga uma vez; `journey_test` agora espera **13 pares**). Capítulos: o 1 passou a ter **7 passos** (`content_test` aceita 2–7); `lais_stew` deixou de fechar o capítulo 3 (o prêmio do capítulo agora sai em `growth_3_teething`). Depois de `community_12_memory`, só falta `growth_12_adult` e então vem o `final_chapter` ("O filhotinho da caixinha virou o Guardião do Vale…").

**Falas reescritas** (só `dialogue`; IDs, objetivos e prêmios iguais): a Laís apresenta um filhote assustado ("ele tremia na caixinha") e banho/brincar/caminha viram "deixar ele à vontade"; capítulo 2 "filhote precisa de comida de verdade"; cozinha "papinha"/"algo geladinho para os dentinhos"; Vila "ele precisa conhecer gente nova" e a Praça "ótima para filhote aprender"; Bosque "energia demais" e bancada "coisas para ele roer"; "comida caseira para quem cresce"; clientes que perguntam pelo Tiro; estufa "banho cheiroso"; fibras "escova macia"; obras com o Tiro como membro da turma; `community_12_memory` com a homenagem à **Smoky** (Yorkie de 1,8 kg que, em 1944, passou um cabo por um cano de 20 m). Cada fala é curta e tem o Tiro como motivo (`growth_story_test` confere palavras proibidas e tamanho).

**Robô do simulador:** `economy_bot.gd` ganhou `pursue_growth`/`_pursue_growth_req` (objetivo `growth` e requisito `growth` em `pursue_reqs`), refeição da fase, banho com xampu (`pursue_stat "shampoo_bath"`), entrega do item-chave (`deliver_growth`), lacinho pela costura, pilares por gesto quando a recarga deixa e `grow`; item `keepsake` sem receita vem do prêmio da missão. `economy_sim.gd` aceita as ações `grow`/`deliver_growth` e o `bathe` com xampu (conservação declarada). Ver `docs/plans/economia/SIMULADOR.md`. Em 14 dias simulados (semente 1, só diagnóstico, não é medida) o robô chegou ao Aventureiro e ao capítulo 9; em 40 dias, ao Mocinho e ao capítulo 12, sem violações.

**Campanha do `progression_test`:** passa pelos cinco crescimentos (refeição da fase, item-chave, xampu, lacinho e `grow` pelas ações reais; só os **pontos dos pilares** usam `dev_add_pillar`, porque o ritmo deles é de `pillars_test`) e pelas obras da vila (capítulos 10–12: taxa e material postos na mochila, uso pelo Tiro) — antes a campanha parava em `community_10_*`. `onboarding_test` cresce o Tiro da mesma forma para chegar ao capítulo 4.

Teste novo `growth_story_test`; capturas `tests/story_shots.gd`.

## Tiro no centro — etapa 12: escovar e paladar (19/10/2026)

- **Escovar:** `basic_brush` (keepsake, `growth.json` presente de Dentinhos). `GameState.brush_owned/brush_error/brush`: Pelagem 5 (`sources.brush.coat`), 8 se o `soft_brush` já foi entregue (`soft_coat`), recarga 4 h (`growth.cooldowns.brush`), grava o dia local em `growth.brush_days`, conta `brush`, emite `dog_action brush`. Bloqueado dormindo, passeando ou sem a escova.
- **Paladar:** `growth.json → tastes` (`favorite_pool`, `odds`, `grimace`, `favorite_bonus` 0,5). `GameState.favorite_food/favorite_found/taste_reaction_for/untasted_foods`; `GrowthState.tastes/taste_seed/brush_days` (chaves novas do `growth`, sem reset). Favorita dá +50% nos pilares (`_feed_pillars`).
- **Requisito do Azul e Dourado:** `feed favorite ×3` (`_growth_label` mostra "Descubra a favorita" até a primeira prova; `_growth_have` conta `feed:<favorita>`).
- **Interface:** `PetCareTray._sync_brush` (BrushTile entre Banho e Brincar), `PetScreen.back_rect/brush_stroke/brush_knot_off/brush_cleanup/_on_taste`, ♥ (`FavoriteHeart`) e "Nova!" (`NewTaste`) na guia de comida, `PillarUi.taste_guide` (`TasteGuide`, `Taste_<item>`) na aba Crescimento. Teste: `brush_taste_test`; capturas: `tests/brush_taste_shots.gd`.

## Tiro no centro — etapa 13: álbum de recordações (19/10/2026)

**Apresentação e avisos (20/10/2026):** o Álbum aparece no caderninho com a primeira foto,
mas fotos registradas antes de conhecê-lo não geram aviso, bolinha nem linha de boas-vindas.
`lais_album` (Laís, “Nossas primeiras lembranças”) é uma missão opcional da linha
`lais_memories`, disponível após `lais_play`, sem prêmio nem bloqueio da história principal.
O objetivo `stat: open:album` e o botão Ir (`{notebook: "album"}` em `Places.go`) levam direto
à aba Álbum; a ajuda explica Tiro → caderninho → Álbum. Total atual: 110 missões, 50 principais (entrega repetida `bloblo_carrots` retirada em 20/10/2026 e marco do baú dos passeios acrescentado em 21/10/2026).
`note_album_section/open_album_photo` registram a primeira visita no contador persistido
`open:album`. `photo_alerts_enabled` preserva também saves anteriores com foto vista ou seção
já explorada. Os snapshots anteriores ficam intactos; a primeira visita não anuncia o passado.
Só fotos tiradas depois da descoberta entram na fila de “Nova foto!”. A bolinha nas abas/seções
e fotos continua até a leitura das fotos. Nenhum reset ou mudança de versão de save.

- **Dados:** `game/data/album.json` (`schema`, `active_sections`, `sections`, `scenes`, `props`, `photos[54]`). Cada foto: `id`, `section`, `title`, `on` (evento ou lista), `when` (até 3 condições), `photo {scene, pose {clip, frame}, props, friend?, ribbon?, compare?}`; secretas/soninhos também `hint`, `icons`, `hint_npc`, `hint_object`. `Database.album/photo(id)/album_sections()/album_problems()` (rejeita evento/condição/cenário/adereço desconhecido, id repetido, mais de 3 condições, total ≠ 54).
- **Estado:** `AlbumState` (`photos {id: {at, phase, coat, seen}}`, `hints`, `lupa_day`, `lupas_used`, `photobomb_pity`, `wall`, `main_photo`, `recent {evento: [instantes]}`), chave `album` do save; `SAVE_VERSION` continua 13.
- **Motor:** `AlbumRules` (`EVENTS`, `CONDITIONS`, `matches`, `holds`, `full_moon`) e `GameState._album_event(evento, ctx)`, chamado por `mark_seen(["intro"])` (`intro_done`), `set_sleeping(true)` (`slept`), `_finish_quest` (`quest_claimed`, `chapter_done`), `grow` (`grew`), `feed` (`fed`, com `growth_food`), `bathe`, `pet`, `play`, `brush`, `dig` (`dug`, uma vez geral e uma por item), `return_due_walk` (`walk_returned`, com `route`/`rare`), `learn_trick`, `equip`, `give_friend` (`friend_heart`). Só fotos das seções ativas são avaliadas; foto tirada uma vez; `Events.photo_taken(id)`; contador `photos`.
- **Fotos ativas hoje (22):** História `h_arrival`, `h_first_night`, `h_growth_puppy/teething/explorer/young/adult`, `h_kitchen`, `h_first_walk`, `h_first_trick`, `h_banca`, `h_bench`, `h_courage`, `h_guardian`; Primeiras vezes `f_bath`, `f_taste`, `f_dig`, `f_tooth`, `f_friend`, `f_outfit`, `f_rare`, `f_brush`.
- **Dentinho de leite:** `milk_tooth` (categoria `find`, sem depósito) entra no primeiro montinho de Dentinhos em diante (`GameState._milk_tooth_due`, também reflete em `find_reward`).
- **Interface:** `PhotoCard.make(id, largura, {locked, secret, caption})` (polaroide em 176×176 unidades; Tiro no corpo/coat gravado; silhueta `flat_silhouette.gdshader` quando falta), `AlbumView.panel(seção)`/`detail(id)`/`open_photo(id)` (nós `AlbumView`, `AlbumSections`, `AlbumGrid`, `Photo_<id>`, `NewBadge`, `PhotoDetail`, `PhotoWhen`, `BeforePhoto`), aba `album` no `PetNotebook` (`open("album:<seção>")`, aparece com a primeira foto), selo Novo (`GameState.photos_unseen`, `mark_photo_seen`), aviso "Nova foto!" tocável em `main.gd` (pela fila modal) e linha `photo` em `welcome_ready_lines`/`Line_photo`. Caderneta do painel de crescimento: `CeremonyPhoto_<fase>`.
- **DEV:** `dev_take_photo(id)`, `dev_reset_album()` (botões "Tirar a próxima foto"/"Zerar álbum" na aba Crescimento).
- **Teste:** `album_test` (~12 s). Capturas: `tests/album_shots.gd`.

## Tiro no centro — etapa 14: Casa que cresce (19/10/2026, concluída)

- Catálogo `data/house.json`, `Database.house/house_problems`, requisitos de sala `house`. Chegadas por fase, primeira lembrança entregue e metas do álbum 6/12/18/30/45. `_sync_house` grava `progress.house.arrived` e emite `house_item_arrived` uma vez; não usa inventário nem paga moedas. Caixinha sai do chão ao aparecer a prateleira; a prateleira mostra apenas lembranças entregues, além da caixinha e câmera ganha.
- `HouseDecor`: régua por cerimônias persistidas (nome, data e proporção do peso), prateleira e fotos escolhidas compostas com `PhotoCard`. `HouseUi`: prateleira, parede, moldura, cesto e caminha. Caminha abre Dormir/Acordar e acesso à compra da próxima; tigela tem a melhoria no próprio painel. `hidden_by` substitui o desenho/footprint anterior.
- Caminhas `bed_soft` (fase young, tecido 2 + novelo 2) e `bed_luxe` (adult, macia possuída, tábua 2 + tecido 2 + pena 2) são melhorias de zero moedas. `house_sleep_bonus` usa apenas a melhor (+10%/+20%), derivada no `DogState.sleep_bonus`, incluindo ausência e recarga sem ultrapassar 100. Sem caminha o ponto de sono da Casa é a caixinha.
- `named_bowl` (Dentinhos+, tábua 1 + tijolo 1) multiplica os pilares da comida de crescimento por 1,1 antes do arredondamento e combina com favorita/Radiante.
- Itens `toy: true`: `give_toy_error/give_toy` exige cesto e consome uma unidade por tipo. `progress.house.toys` persiste; brincar soma +1 Esperteza por tipo, limitado a +3, na recarga normal. Catálogo atual: `braided_toy` e `lost_ball`. Mochila oferece Dar ao Tiro; ambos entram no filtro Para o Tiro.
- `hang_photo_error/hang_photo/unhang_photo`: três lugares, substituição por índice, sem foto inexistente ou duplicada. `main_photo_error/set_main_photo` exige moldura dourada. Escolhas persistem em `AlbumState.wall/main_photo`. `lupas_per_day` retorna 1/2 com câmera; uso da lupa continua fora desta etapa.
- `CornerDecor`: tapete, foto principal e cesto (máximo três), régua pequena tocável e enfeites atrás do Tiro. Sem mudar o cenário original ou as imagens do cachorro.
- Arte final PixelLab: 13 fontes em `tools/art/house_pixellab/`, manifesto com prompts/jobs/hashes; `tools/house_art.gd` recorta e prepara 14 objetos e `gold_frame_front.png`. Moldura frontal também no cantinho. Nenhum PNG do Tiro alterado. Testes/capturas: `house_test`, `house_shots`, `VALIDACAO_14.md`.

## Tiro no centro — etapa 15: álbum completo e segredos

As seis seções estão ativas: 54 fotos (22 anteriores + 32 novas). Travessuras e Soninhos têm uma pista permanente; tocar a foto que falta abre sua silhueta e a lupa. Uma lupa por dia local, duas após a câmera antiga (12 fotos); as condições reveladas ficam salvas. Após três dias desde a primeira abertura da seção, e com cinco fotos, o personagem dá uma dica por foto. Objetos ligados brilham quando duas de três condições valem, preservando bloqueios e Menos animação. Personagens comentam suas fotos uma vez na próxima conversa.

Fotos vêm das ações: carinho após banho, colheita, dois toques no cesto, roupa, cinco regas num arrasto, sofá, fotos revistas (Penetra garantido até a oitava), banco ao luar, brincadeiras, geladeira, riacho, soninhos, vínculos, aulas, clientes e encontros. O lugar de sono fica no save; o sofá pode ser escolhido tocando nele. A bolinha precisa estar entregue no cesto, e a visita de sono exige a Pipoca e o Tiro na Casa. O chapéu de explorador do tesouro agora pode ser vestido. Fotos novas guardam também as roupas do momento.

Um mês juntos tem janela de dias 30–36. Dia do Tiro reaparece a cada aniversário do início do save, numa janela de sete dias: bolo na Casa/cantinho, chapéu de festa temporário e receita permanente do Bolo do Tiro (fogão, farinha + maçã + ovo, 600 s, Coragem 5). A foto continua única; festa e lupas não reabrem ao atrasar o relógio. Lua cheia usa ciclo médio de 29,530588853 dias, margem de um dia, Praça/Natureza após 20h e Aventureiro+. Frio usa `config.json → album.cold_months`; Depois da festa vale a partir do dia civil seguinte à conclusão da Festa.

Estado novo: `AlbumState.opened_at/spoken/years/party_from/party_until/sleep_spot`, além de hints/lupas/pity já existentes. Sem reset ou migração. Testes e tabela das 54 fotos: `docs/plans/tiro/VALIDACAO_15.md`.


## Tiro no centro — etapa 16: jeito, comportamentos e diário

`growth.json.personality/behaviors/diary` define pesos, janela, confirmação, intervalos visuais e modelos. `PersonalityRules.record/relative_scores/id/title/behavior` calcula o jeito; `_count` alimenta a memória a partir das ações reais, primeiras provas de comidas de crescimento e primeiros mundos acrescentam variedade. `GrowthState.personality/diary/diary_receipts` participa de reset/to_dict/from_dict sem reset de save. Janela de 14 dias jogados (sem ausência), teto 1 por jeito/dia, 65% recente + 35% histórico, troca com margem 0,20 e três dias de vantagem; relógio atrasado não cria outro dia.

`PetAnimator` escolhe fidgets e intervalo pelo dado; cochilo visual termina sozinho. `DogWorld` escolhe cochilo/sentar/farejar, pausa/pulinho no caminho, sequência de três destinos próximos e preferência por NPCs/estações em uso. Caminho, interrupção de reação e revisão de navegação permanecem ativos. Só apresentação: sem ganho de energia, prêmio, pilar ou contagem de cuidado.

`PillarUi` mostra título e diário na aba Crescimento do caderninho; `GrowthUi` mostra o mesmo título. Revelação desde Aventureiro, fila Novo existente com recibo `personality:revealed` e Ir para o painel. `_diary` recebe os eventos reais, descarta as linhas mais antigas acima de 20 e mantém recibos de fotos/provas/fases. Teste `personality_test` e passagem do portão em `docs/plans/tiro/VALIDACAO_16.md`.

## Tiro no centro — etapa 17: Pelagem de seda e simulador (19/10/2026)

* **Seda (pós-jogo, só cosmética):** `growth.json → silk.levels` (I–III: `sheen` 0,33/0,66/1; Pelagem 10 + escovações em 5/10/20 dias diferentes + banhos com xampu 3/6/10; presentes 50/80/120 moedas). `growth.silk` (0–3) é salvo em `GrowthState.to_dict/from_dict` (sem migração).
* `GameState.silk_info()` (consulta pura, só no adulto), `silk_error()`, `brighten()` ("Mais brilho!": presente pelo recibo `silk:<id>` com `_grant_automatic`, diário, `Events.silk_up`) e `silk_sheen()`; `dog_look()` devolve `sheen`.
* Contadores: dias = `growth.brush_days` (um por data local), banhos = `progress.stat("shampoo_bath")` total.
* Shader `tiro_coat`: `sheen` (faixa de brilho que desliza no pelo claro) e `reduced` (Menos animação = faixa parada); `sheen = 0` não muda um pixel. `DogLook` aplica os dois em todos os usos.
* Interface: no adulto, `GrowthUi` troca a próxima fase por `SilkSilhouette` + `SilkRequirements` (`SilkReq_<id>`) + `SilkButton` ("Mais brilho!") ou `SilkLock`; níveis ganhos viram `SilkCard_<n>` na caderneta; `Celebration.show_silk` (confete só a partir do II).
* Simulador: `summary.json` ganha `growth_days` (dia e minutos ativos de cada fase), `chapter_coins` (moedas ao fechar cada capítulo) e `end.phase/silk/pillars`; `economy_compare.py` escreve a seção "4b. Fases do Tiro × dia" contra os alvos da 02 E. Teste: `silk_test`.

## Tiro no centro — fechamento (etapa 18, 19/10/2026)

Plano concluído: crescimento em seis estados (`growth.json`), pilares, itens-chave, comidas, escovar/paladar,
álbum de 54 fotos, Casa que cresce, jeito e seda. A conferência dos dez itens da visão e o roteiro do celular
estão em `docs/plans/tiro/RESULTADOS.md`; o que ficou de fora, em `docs/plans/tiro/FUTURO.md`.

### Ajuda de origem dos itens (20/10/2026)

O Como fazer não manda buscar um material ausente na Mochila. Missões com prêmio mostram personagem/lugar/nome da missão e orientam a etapa atual da linha; o texto usa a missão escolhida. Sem prêmio de missão pendente, contratos com o material na recompensa são classificados pelos bloqueios, insumos faltantes e espera. O painel mostra onde entregar, qual contrato, produtos e quantidade do prêmio, além do próximo passo para desbloquear/preparar. Fontes de crescimento/achados e o Dentinho de leite também têm orientação própria. Presentes únicos já recebidos são identificados como tais, sem sugerir recebê-los novamente. Nenhuma fonte nova nem recompensa foi criada. Regressões: `item_sources_test`, `keys_test`, `warehouse_test`, `texts_test`.
