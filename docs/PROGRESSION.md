# Progressão (Jornada)

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
| **Feira** | `progression.json` → `orders` + `sell_price` em `items.json` | Encomendas com recarga + venda direta. |
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

## Missões: História, Diárias e Semanais

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
secundárias agora vêm das semanais. Ações: `claim_routine`/`routine_error`.

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
o que falta em chips tocáveis), as Diárias e as Semanais, sempre com **Ir** e **?** ("Como fazer"). Detalhes em **`docs/WORLDS.md`**. Painéis em `scripts/ui/progression_ui.gd`.
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

Feirante (cap. 4): conversar → vender 5 produtos → 1 encomenda → mais 2 encomendas.
Guia (cap. 5): conversar → recolher lane → quarry → meadow. Metas de ações são `fresh`;
passos anteriores da Laís não contam retroativamente. As novas linhas não bloqueiam
as existentes. São quatro linhas possíveis em paralelo (Laís, Bloblo, Feirante, Guia).
`npcs.json → portrait_animations` define pastas `request`/`complete`. `NpcPortrait`
executa o aceno uma vez ao receber missão do NPC, depois retorna ao pedido quando houver
passo ativo. Sem animação configurada, o NPC continua com seu retrato estático.
