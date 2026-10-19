# Registro de decisões R1



## 16/10/2026 — planejamento solicitado, implementação ainda pendente



O usuário pediu um plano completo após a pesquisa, dividido para agentes futuros. R1 substitui a V0 pausada. As tabelas são decisões iniciais de implementação, não resultados de playtest. A pesquisa continua como fonte de hipóteses e evidência; os arquivos R1 governam a execução futura.



Decisões: quatro limites desde o primeiro material; quatro apresentações contextuais; sementes livres; renda de venda/encomenda; proteção de ausência; volta independente da bagagem; fila sequencial com preparo em lote; variedade e poucas novidades úteis; três projetos locais mais festa; preservar saves. Não adotar seis produtos genéricos, grandes multiplicações de colheita, afeto fabricável, crescimento por idade ou duração imposta em semanas.



Três novos produtos, uma receita de gravetos sem item novo, três encomendas novas (e uma existente reaproveitada), três clientes, maestria de seis estações, oito ampliações finais de depósitos, quatro projetos e três capítulos novos compõem a ampliação. O plano não garante que os valores funcionem antes de medição. Não declarar a economia equilibrada apenas porque todos os preços têm margem positiva.



Arquivo `historico_v0/` é consulta histórica e não deve ser executado. Mudanças futuras precisam atualizar todos os quadros afetados, incluindo matriz de missões e README, no mesmo passo.



## Modelo para cada ajuste futuro



- Data, etapa e agente.

- Problema observado e caso reprodutível (seed/perfil/save; link de log).

- Valor/regra anterior → nova, quais arquivos dependem.

- Hipótese causal; por que não é necessário novo conteúdo/sistema.

- Efeito esperado em aprendizado, renda, estoque, retorno e save.

- Resultados antes/depois; falhas restantes; teste manual efetivamente feito.

- Decisão: manter/reverter/necessita decisão de design. Nunca escrever “PASS” quando só houve cálculo estático.



O agente pode ajustar até 25% por família/rodada conforme04; após três rodadas sem solução, documentar causa e proposta concreta. Não alongar esperas sem checar quantas visitas passam sem progresso. Valores de proteção/transação/invariantes não são flexibilizados para fazer um teste passar.

## 17/10/2026 — etapa 00 (linha de base real), agente Claude Code

Auditoria estática concluída ([BASELINE.md](BASELINE.md)). **Nenhum número de balanceamento foi alterado**; os esclarecimentos abaixo corrigem apenas referências factuais da R1, sem mudar tabelas.

1. **“XP Horta” (02 §C) = `skill_xp` da cultura.** As culturas não têm campo `xp`: `crops.*.skill_xp` (atributo Agricultura) é pago a cada colheita (dobrado na primeira descoberta de `crop:<id>`), e o XP do jogador por colheita é `config.xp.harvest = 2`, fixo. Destino: etapa 10 grava os valores 6/16/24/35/45/18/24/50/65 em `skill_xp`; os valores atuais (10/22/15/35/30/12/15/55/40) são o “antes”. Não criar campo `xp` novo.
2. **Capacidades legadas são maiores que as “Construído” da R1** (silo 40 > 32, geladeira 30 > 24, armazém 40 > 32; só o baú sobe, 20 → 24; `_2`/`_3` somam +40/+20/+40/+20 e +60/+30/+60/+30). Destino: etapa 02 (`legacy_capacity_floor`) e etapas 05–08 — quem já comprou o edifício ou as ampliações mantém o piso atual; a capacidade da R1 vale para quem ainda não comprou.
3. **Aros de ferro.** Fontes determinísticas únicas hoje: 7 (6 em missões — `bloblo_bigger` 3, `bloblo_biggest` 2, Feirante 1 — e 1 no nível 8). A etapa 07 retira 5 delas; restam 2 até `banquet_contract` (15) e `workshop_first_set` (17). Como `chest_3` só troca para o custo R1 na etapa 08 e hoje pede 1 aro, o executor da 07 deve conferir que `fridge_3`, `silo_3`, `warehouse_3` e `chest_3` continuam alcançáveis (nível 8 + contratos) ou antecipar o custo R1 sem aro. Sem mudança agora.
4. **Estação × melhoria.** Não existe estação `fridge`; a estação `sewing` é liberada pela melhoria `sewing_table` (campo `station` em `upgrades`, `Database.station_upgrade`). Destino: etapas 12 e 18 devem usar essa ponte ao exigir “estação comprada” (ex.: `mill_queue` exige `mill`, `atelier_queue` exige `atelier`).
5. **Testes de campanha usam `unlimited_storage = true`** (`progression_test`, `animals_test`, `flavors_test`, `world_life_test`). Destino: etapa 01 (simulador sem esse atalho); até lá, essas suítes não validam depósitos finitos.
6. **Valores da ROADMAP reproduzidos** (2.660 + 700 moedas, caixa 121 → 60, contrato 220 vs 363, 51,4 moedas/min nos quatro canteiros): nenhuma divergência.
7. **Dependência de ordem observada para a etapa 09:** a caixa de petiscos é a única receita com margem imediata negativa (−61) — corrigida pela tabela B (`treat_box` 140). A margem contra matéria-prima de quase todas as receitas curtas é pequena (+4 a +19 por lote); a etapa 09 deve medir o efeito antes/depois e não esperar renda grande dessa correção.

Teste manual: não aplicável (só dados e documentação). Decisão: manter a R1 sem alteração; os pontos 1–5 são lembretes obrigatórios para as etapas indicadas.

## 17/10/2026 — etapa 01 (simulador), Claude Code + retomada Codex

**Nenhum valor R1 ou JSON de balanceamento ajustado.** [SIMULADOR.md](SIMULADOR.md) registra a linha de base simulada, separada da auditoria estática: 35/35 campanhas completas, 107.653 ações e zero violações. A primeira colheita/passeio e o fim do capítulo 9 foram medidos; os valores antigos não precisam cumprir as metas R1 nesta etapa.

As tentativas comerciais antigas (`*_base`, `*_trace*`) tinham falhas da política/reserva do planejador. A versão local deixada pelo Claude já corrige os casos das sementes 2/3 e foi validada novamente, sem alterar as regras para o bot passar. Esses diagnósticos foram preservados, mas não entram nas estatísticas finais: usar apenas o lote `validada` (inclui `_raro0`). Requisitos encontrados em caminhos descartados não são prova de campanha impossível.

Correções de instrumentação no fechamento: o modo compacto também conserva saldo anterior/fila por ação; baseline usa ledger completo. O filtro do relatório passou a incluir raro zero e separar suas medianas das execuções normais. Campanha referência semente 1 repetida com registro byte a byte idêntico. Testes focados PASS; `progression_test` histórico excedeu 3 min nesta retomada, sem alegação de aprovação nem correção desse bot antigo. Sem playtest, commit ou publicação; etapa 02 é a próxima.

## 17/10/2026 — etapa 02 (transações, snapshots e presentes para guardar), Claude Code

**Nenhum número de balanceamento foi ajustado** (preços, capacidades, tempos, rendimentos e XP iguais; nenhuma categoria ganhou limite nova). Só infraestrutura de proteção, para as etapas 03–08 limitarem estoques sem perder nada. Decisões de implementação:

1. **`SAVE_VERSION` continua 12.** Os campos novos (`economy`, `plots[].job`, `queue[].job`, `walks.current.snapshot`, `rewards` da rota) têm padrão; a mudança de CONTEÚDO usa `economy.revision` (1) e `EconomyMigration`, pura e idempotente (migrar duas vezes dá o mesmo save; relatórios de slot e "copiar da publicada" passam por `SaveManager._migrate`). O ramo `<12` (reset histórico) não foi ampliado.
2. **Piso legado persistido e monotônico**: `economy.storage_floor[depósito]` sobe com compras (tabela congelada em `data/legacy_r0.json`, gerada por `tools/freeze_legacy.py` com o jogo ANTES da R1: silo 40+40+60, geladeira 30+20+30, armazém 40+40+60, baú 20+20+30 → exatamente o `base`/`levels` atuais). Hoje curva = piso, por isso nada muda; a diferença aparece quando as etapas 05–08 trocarem as curvas (ex.: silo "construído" 32 < 40 legado). Capacidade = `max(curva do estágio, piso)`. O estoque nunca entra no piso.
3. **Recebimentos MANUAIS passam a bloquear por espaço projetado.** Antes, missão, encomenda, diária/semanal, presente do dia, desejo e a rota global (`collect_activity`) faziam `inventory.add` sem checar o limite (o depósito podia passar do teto sem aviso). Agora consultam `storage_error(entra, sai)` antes de consumir (entregar e receber no mesmo depósito conta o que sai primeiro). Efeito esperado: nenhum em saves sem depósito cheio; com depósito cheio o jogador vê "<Depósito> sem espaço". Verificado no simulador (abaixo).
4. **Recibos só para nível, capítulo e vínculo** (e o formato pronto para `customer:<npc>:<n>` e `project:<id>`, que as etapas 15–22 ativam). Recompensa manual nunca vira recibo. Identidade em `economy.granted`; migração marca níveis ≤ atual, capítulos concluídos pelo mapa ANTIGO e vínculos já pagos.
5. **Passeio**: o contrato (caminho, lendário e tabelas de achados citadas) é congelado ao sair, e `collect_walk`/`walk_loot` leem dele. O RESULTADO ainda depende de estado vivo (garantia/`pity`, coleção, bolsa de passeio, bônus de amigos): fixar o resultado e separar viagem × bagagem é da etapa 03, não antecipada.
6. **Testes antigos**: `friends_test` testava o comportamento anterior (alterar a tabela com o passeio em andamento mudava o sorteio); agora verifica que o passeio em andamento mantém a tabela e que a nova saída usa a nova. `npc_lines_test` ("Recebe etapa da venda") e `finds_test` ("Faro: missão pronta") **já falham no commit `6c01198`** (provado com `git archive HEAD` em pasta temporária; ordem das missões da banca/venda, não relacionado). `onboarding_test` ("primeiro raro em até 60 min") tem resultado dependente do segundo do relógio (a semente do passeio é `int(now())`): no HEAD deu 25,8 min três vezes e 53,6 uma; com o código novo 51–55 min e uma falha isolada na suíte completa; os sorteios são idênticos para a mesma semente (comparação de 80 sorteios fixos). Não relaxei nenhum assert.

Teste manual: toque real no export Web dev (Chrome mobile emulado): ferramenta DEV "Presente para guardar" → Mochila → **Guardar** (`build/economy/etapa_02/toque/web/`); o save no IndexedDB ficou com os itens no inventário, recibo vazio e `economy.revision` 1. Não é teste em iPhone/Android físico. Decisão: manter.

## 17/10/2026 — etapa 03 (volta do Tiro × bagagem), Claude Code

**Nenhum número de balanceamento foi ajustado** (chances, tempos, garantias, recompensas e limites iguais; o baú não ganhou limite). Mudou a REGRA de estado: viagem (`current`) e bagagem (`pending_return`) são distintas; ver `docs/PROGRESSION.md`. Decisões:

1. **`SAVE_VERSION` e `economy_revision` não mudaram.** `walks.pending_return` tem padrão vazio e a liquidação roda em `from_dict`, idempotente: save antigo com passeio pronto vira bagagem com o resultado que o recolhimento antigo daria, sem segundo sorteio.
2. **A volta paga tudo que não é item** (moedas, XP, afeto, coleção, cuidados, contadores `walk`/`walk_rare`/`walk_legendary`, histórico e garantia) uma vez, no tick; só os itens esperam. Efeito esperado: o jogador com depósito cheio não fica sem o Tiro; nada se perde. Antes, depósito cheio mantinha o Tiro fora e adiava prêmio e garantia.
3. **Cuidados do Tiro entram em `ready_at`**, não na hora da abertura (seção G, política temporal vigente). A ausência protegida (metade das taxas, pisos, teto de 8 h) continua para a etapa 04.
4. **Rolagens extras (bolsinha/Pipoca) continuam lidas na VOLTA**, como antes; não foram congeladas na saída para não mudar comportamento fora do escopo. O resultado, sim, é congelado ao voltar.
5. **Testes antigos adaptados à nova definição** (não relaxados): `walking()` só na viagem; "depósito cheio mantém o passeio pronto" virou "o Tiro volta e a bagagem espera inteira"; `cancel_walk` só na viagem. O simulador ganhou a volta no `bg_tick` (equivale ao tick de 1 s) e o guarda "mutação fora de ação" acompanha essa regra por tempo, como os desejos.
6. **Simulador (35 execuções, `*_pos03`, `build/economy/etapa_03/comparacao_simulador.md`):** 35/35 campanhas completas, 0 violações, mesmas regras e limites reais (sem `unlimited_storage`/`dev_*`). Como o instante do passeio muda a trajetória do bot e a semente é `int(now())`, as medidas individuais variam em relação à etapa 02 (campanha: referência ~213–252 min ativos contra ~213–244), sem deslocamento sistemático; não é prova de equilíbrio.
7. **Falhas históricas, mantidas sem relaxar assert:** `npc_lines_test`, `finds_test`, `onboarding_test` (instável pelo relógio) e `progression_test` (bot preso em `merchant_festival`). Não foram reexecutados nesta etapa por não terem relação com o código alterado.

Teste manual: toque real no export Web dev (Chrome mobile emulado 390×844, `build/economy/etapa_03/toque/`): DEV "Voltar do passeio" → cartão "De volta!" → "Depois" → cantinho do Tiro com o Tiro em casa e "Guardar achados" → toque; o save no IndexedDB ficou com `pending_return` vazio, itens no inventário e `walk`/`walk_item` contados uma vez. O caso "não cabe" só é alcançável no jogo real depois da etapa 08 (hoje `trail`/`find` não têm depósito); foi verificado em testes com depósito de teste. Não é teste em aparelho físico. Decisão: manter.

## 17/10/2026 — etapa 04 (ausência protegida), Claude Code

**Números aplicados (valores do plano, sem ajuste medido):** fora do app o Tiro perde **50% da taxa online**, por **no máximo 8 h de queda por ausência contínua**, com pisos **fome 25 / alegria 35 / energia 25 / higiene 30**; dormindo, a energia sobe 40/h até 100 e não volta a cair. Em `config.json`: `offline.rate`, `offline.max_hours` e `needs.<id>.offline_floor`. Taxas online e efeitos de comida/banho/brincadeira não mudaram.

| Cenário (tudo em 100, acordado) | Antes (taxa cheia) | Depois |
|---|---|---|
| Fora 1 h | 92 / 95 / 94 / 97 | 96 / 97,5 / 97 / 98,5 |
| Fora 8 h | 36 / 60 / 52 / 76 | **68 / 80 / 76 / 88** |
| Fora 24 h e 72 h | 0 / 0 / 0 / 28 (e 0/0/0/0 em 72 h) | **68 / 80 / 76 / 88** (teto) |
| Fome 30, 24 h | 0 | 25 |
| Fome 10, 24 h | 0 | 10 (o piso não cura) |
| Dormindo, energia 10, 24 h | 100; demais 0 / 0 / 28 | 100; demais 68 / 80 / 88 |

Ordem: fome / alegria / energia / higiene.

Decisões:

1. **Sem `SAVE_VERSION` novo nem reset.** O estado novo é só `dog.away_since` (padrão 0 = online). Save antigo carrega igual; sem `last_active_at` gravado a ausência não é estimada e o trecho segue como era (online).
2. **Projeção em segmentos, sem estado extra de consumo.** `DogState.get_need` divide `[updated_at, now]` na ausência em curso; o tempo protegido do trecho `[a, b]` é `min(b−início, 8 h) − min(a−início, 8 h)` (seção G de 05). Assim o passeio que acaba aos 30 min (`dog.apply` em `ready_at`) e a volta aos 24 h somam 8 h de proteção, não 9; testado (higiene 78, alegria 81,25).
3. **Uma fronteira só.** `GameState.begin_absence/end_absence`, chamadas pelo `SaveManager` (foco/pausa/fechar e retorno) e por `load_game`. Foco+pausa+fechar abrem uma ausência uma vez; heartbeat e autosave não a reiniciam (o heartbeat nem roda fora do app). Fechamento abrupto: o início estimado é `friend_state.last_active_at`, aplicado em `from_dict` ANTES de `return_due_walk`, para o passeio e a ausência se encaixarem. Recarregar não cura nem repete: depois de `end_absence` o save grava `away_since = 0`.
4. **Troca/abertura de slot** projeta o tempo parado daquele slot como ausência protegida; não cria visita nem presente (isso continua só em `update_friend_visits`, primeira abertura).
5. **Relógio para trás** não gera ganho nem perda (tempo = `max(0, diferença)`); início de ausência no futuro vira "online".
6. **Cartão de volta inalterado:** o cartão agrupado "Que bom que você voltou!" já é neutro (sem multa nem modal de necessidades). A proteção aparece como uma linha no Manual.
7. **DEV `dev_advance_time`** agora é ausência protegida (antes era queda cheia); a expectativa de `dev_tools_test` ("1 h baixa a fome mais de 5") passou a "mais de 3" (queda esperada: 4).
8. **Limites desta etapa:** duas abas/janelas do mesmo save não são coordenadas (a arquitetura salva por aba; vence o último save). O simulador de economia ainda deixa o Tiro em taxa online entre sessões; a calibração (23) decide se passa a usar `begin/end_absence`. Teste só em viewport/desktop headless, não em aparelho físico.

## 17/10/2026 — etapa 05 (silo e Cesto da horta), Claude Code

**Números aplicados (tabela 02 A, sem ajuste medido):** provisório 16, silo 32, `_2` 56, `_3` 88; silo grátis após `first_harvest`; `silo_2` 100 + tábua 2 + parafuso 1 (pede `main_4_bench`); `silo_3` 260 + tábua 4 + tijolo 2 + parafuso 1 (pede `own_business`); `bloblo_silo` ordem 27, 10 moedas, sem parafuso.

| Cenário | Antes | Depois |
|---|---|---|
| Jogo novo, sem silo | colheitas sem limite | cesto de 16 |
| Silo construído | 120 moedas + madeira 6 (após a queijaria), 40 | grátis (após a 1ª colheita), 32 |
| `silo_2` / `silo_3` | +40 / +60 (total 80 / 140) | +24 / +32 (total 56 / 88) |
| Save com silo comprado | 40 | 40 (piso legado) |
| Colheita não cabe | "Silo sem espaço" (só com silo) | "Cesto da horta sem espaço: abra lugar para Cenoura ×N" |

Decisões:

1. **Ajuste da decisão 2 da etapa 02:** o piso legado deixou de subir com compras (`_changed()`); só a migração o grava. Sem isso um jogo novo que construísse o silo ganharia 40 em vez de 32. Saves já em revisão 1 mantêm o piso que gravaram. Efeito para as etapas 06–08: as curvas novas valem para compras novas sem código extra.
2. **Aros de ferro:** `silo_3` não pede mais aro; o item continua nas demais ampliações (06–08 as ajustam). `bloblo_biggest` (goal `silo_3`) agora depende de `own_business` (capítulo 7) em vez de `bloblo_bigger`; a linha continua alcançável (auditor: 81/81 missões, 48/48 melhorias, 0 ciclos). A etapa 07 troca os objetivos.
3. **`warehouse` ainda exige `bloblo_silo`**, que agora chega bem antes; o armazém continua sem limite e o custo antigo até a etapa 07.
4. **Testes adaptados (não relaxados):** `economy_sim_test` ganhou `dev_grant_upgrade("silo")` na fixture (o roteiro guarda 19 colheitas; o cesto tem 16); `walk_return_test` usa `storage_name`; `tasks_test` passa pela nova missão; `economy_transactions_test` usa a tabela congelada para o piso e `fridge` para o teste de `prebuild_capacity`.
5. **Verificação:** suíte completa um a um (logs em `build/economy/etapa_05/logs*`): falham só os históricos `finds_test`, `npc_lines_test` (mesmas mensagens com os JSON de HEAD, provado trocando temporariamente os dados), `progression_test` (merchant_festival, excedeu o tempo, exit 124) e `park_test` aparece instável (passou na reexecução). Simulador `reference` semente 1, 5,8 dias: 79/81 missões, 41/48 melhorias, 0 violações, sem `unlimited_storage`/`dev_*`. Capturas antes/depois nas três resoluções em `build/screenshots/etapa05_antes|depois/` (abertas e conferidas). Não é teste em aparelho físico.

## 17/10/2026 — etapa 06 (despensa e geladeira), Claude Code

**Números aplicados (tabela 02 A, sem ajuste medido):** provisório 12, geladeira 24, `_2` 40, `_3` 64; geladeira 40 moedas, sem material, `lais_first_crops`; `fridge_2` 100 + tábua 2 + parafuso 1 (pede `main_4_bench`); `fridge_3` 240 + tábua 4 + tijolo 2 + parafuso 1 (pede `own_business`).

| Cenário | Antes | Depois |
|---|---|---|
| Jogo novo, sem geladeira | comidas sem limite | despensa de 12 |
| Geladeira construída | 30 | 24 |
| `fridge_2` / `fridge_3` | +20 / +30 (50 / 80); 150 e 400 moedas, aro de ferro no `_3` | +16 / +24 (40 / 64); 100 e 240, sem aro |
| Save com geladeira comprada | 30 / 50 / 80 | igual (piso legado da migração) |
| Coleta que não cabe | "Geladeira sem espaço" só com prédio | "Despensa sem espaço" desde o início; lote fica pronto, sem XP |

Decisões:

1. **Pré-requisitos das ampliações** seguem a tabela (`main_4_bench`, `own_business`) em vez de `bloblo_chest`/`bloblo_bigger`; as missões `bloblo_bigger`/`bloblo_biggest` continuam alcançáveis (a 07 troca os objetivos). O aro de ferro some do `fridge_3` como no `silo_3`.
2. **`storage` explícito** em todo alimento (não só a categoria `food`): garante que nenhum item caia em dois depósitos ou em nenhum. `dog_food` segue isento; ervas e mirtilo ficam no silo.
3. **Interface:** `DepotRow` no detalhe do item (ícone do depósito, nome, `usado/total`, "Ver"); distingue comida da Despensa de material sem texto técnico. Nada de redesenho geral.
4. **Testes adaptados (não relaxados):** os que supunham geladeira de 30/50 (`storage_test`, `economy_sim_test`, `economy_transactions_test`, `pending_gifts_test`) passaram a 24/40; `_prebuild_and_floor` agora trata a geladeira como já provisória.
5. **Verificação:** `fridge_test` novo PASS; suíte um a um (`build/economy/etapa_06/suite/`): falham só os históricos `finds_test`, `npc_lines_test`, `progression_test` (timeout, não rodado de novo), e `park_test`/`onboarding_test` instáveis. `walks_test` falhou uma vez (cartão grande) e passou na reexecução. Simulador `reference` semente 1, 5,8 dias: 79/81 missões, 40/48 melhorias (era 41 na etapa 05: a `fridge_3` agora espera `own_business`), 0 violações. Capturas antes/depois nas três resoluções em `build/screenshots/etapa06_antes|depois/`, conferidas.

## 17/10/2026 — etapa 07 (pilha de materiais e armazém), Claude Code

**Números aplicados (tabela 02 A e 03 Guia/materiais, sem ajuste medido):** provisório 16, armazém 32, `_2` 56, `_3` 88; armazém 40 moedas + madeira 4 + pedra 2 (`lais_forest`); `warehouse_2` 90 + tábua 2 + parafuso 1 (`main_4_bench`); `warehouse_3` 240 + tábua 4 + tijolo 2 + parafuso 1 (`own_business`). Novas missões: `guide_open_cave` (22), `storage_first_planks` (10) e `storage_first_delivery` (20).

| Cenário | Antes | Depois |
|---|---|---|
| Jogo novo, sem armazém | materiais sem limite | "Pilha de materiais" de 16 |
| Armazém construído | 40; 150 moedas + madeira 8 + pedra 4, depois de `bloblo_silo` | 32; 40 moedas + madeira 4 + pedra 2, depois de `lais_forest` |
| `_2` / `_3` | +40 / +60 (80 / 140 no total); 150 e 400 moedas, aro de ferro no `_3` | +24 / +32 (56 / 88); 90 e 240, sem aro |
| `bloblo_warehouse` | Bloblo, ordem 150, 50 moedas + 1 parafuso | Guia, ordem 25, 10 moedas (mesmo ID, conclusão preservada) |
| `main_4_materials` | madeira 6 | armazém + madeira 6 (não consome) |
| `bloblo_bigger` | silo_2 + fridge_2; 100 moedas, 3 parafusos, 3 aros | 1 ampliação qualquer; 15 moedas + 2 parafusos |
| `bloblo_biggest` | silo_3; 200 moedas, 3 parafusos, 2 aros | 3 ampliações quaisquer; 40 moedas + 1 parafuso |
| Primeiros parafusos | só sorteio, rotinas e a Bloblo tardia | `storage_first_planks` e `storage_first_delivery`: 1 cada, sem sorteio |
| Save com armazém antigo | 40 / 80 / 140 | igual (piso legado da migração) |

Decisões:

1. **Armazém não pede a Caverna comprada.** A pedra vem da Pedreira (capítulo 5, `cave_open` 80 moedas), que não exige armazém nem bancada: sem ciclo. `guide_open_cave` só reconhece a compra (5 moedas).
2. **`storage_upgrades` é derivado da posse** (`GameState.storage_upgrades_owned`, gravado em `progress.stats` a cada `_changed`, como `contracts`). Cumpre "migrar a posse histórica" sem migração nova e sem contar abrir painel; o edifício inicial nunca conta. Quatro ordens de compra (silo, geladeira, armazém, baú primeiro) dão o mesmo resultado.
3. **Orçamento de madeira:** armazém 4 + bancada 6 = 10 madeiras; as duas tábuas da `storage_first_planks` custam mais 6 (3 por tábua). A `guide_wood` (1 madeira) ajuda, e a `main_4_materials` não consome (a bancada cobra os 6). Cabem nos 16 provisórios.
4. **TaskHelp:** item sem receita nem rota (o parafuso) aponta o passo de missão aberto que o paga, em vez de "Veja na Mochila"; nada aponta para bancada inexistente (a `_2` só abre depois de `main_4_bench`).
5. **Testes adaptados (não relaxados):** `fridge_test`/`economy_transactions_test` passam a tratar só o baú como "ainda sem limite" (`treat_box` no lugar de `plank`); `nature_test` e `dev_tools_test` ligam `unlimited_storage` (enchem a pilha de 16 por desenho; o limite tem teste próprio); `content_test` aceita o contador `storage_upgrades`; `npc_lines_test` espera `guide_open_cave` depois de `guide_wood`. Teste novo: `warehouse_test`.
6. **Verificação:** suíte um a um (`build/economy/etapa_07/suite*/`): sem falhas novas; continuam os históricos `finds_test`, `npc_lines_test` (mesmas mensagens, falha antes da linha do Guia), `onboarding_test`/`park_test` instáveis e `progression_test` (merchant_festival). Simulador `reference` semente 1: campanha completa em 6,8 dias, 84/84 missões, 46/48 melhorias, 0 violações; caverna → armazém em 14,7 min ativos, bancada 18,1, `bloblo_bigger` 23,1 (sem raro). Capturas antes/depois nas três resoluções em `build/screenshots/etapa07_antes|depois/` (abertas e conferidas). Não é teste em aparelho físico.

## 17/10/2026 — etapa 08 (sacola de passeio e baú), Claude Code

**Números aplicados (tabela 02 A, sem ajuste medido):** provisório 12, baú 24, `_2` 40, `_3` 64; baú 0 moedas + 2 gravetos, `nina_walk`; `chest_2` 80 + tábua 2 + parafuso 1 (`main_4_bench`); `chest_3` 200 + tábua 3 + tecido 1 + parafuso 1 (`own_business` e ateliê).

| Cenário | Antes | Depois |
|---|---|---|
| Jogo novo, sem baú | achados de passeio sem limite | sacola de 12 |
| Baú construído | 20 | 24 |
| `chest_2` / `chest_3` | +20 / +30 (40 / 70); 150 e 400 moedas, aro no `_3` | +16 / +24 (40 / 64); 80 e 200, sem aro |
| Compra do baú | 80 moedas + madeira 4, pede `bloblo_warehouse` (Bloblo, 50 moedas + parafuso) | 0 moedas + 2 gravetos, pede `nina_walk` (Nina, 10 moedas, sem parafuso) |
| Save com baú comprado | 20 / 40 / 70 | igual (piso legado da migração) |
| Volta que não cabe | ilimitado | Tiro volta, bagagem espera por parcelas ("Sacola de passeio sem espaço") |

Decisões:

1. **Garantia dos gravetos por campo de dados** (`loot.guarantee` na `park_loop`: item, quantidade, `until_owned`). A primeira volta já tinha `loot.first` (2 gravetos + 1 fita); o campo cobre o save antigo sem baú e sem gravetos (próxima volta inicial completa até 2) e some com a compra. Soma só o que falta (estoque + sorteio), nunca duplica e não usa dado novo. Viagens iniciadas antes não têm a garantia (valem pelo snapshot).
2. **`bloblo_chest` ficou na linha da Nina** (ordem 25). Efeito colateral: o passo agora fica entre `nina_walk` e `nina_routes`; testes que marcavam a linha toda como recebida (`friends_test`, `tricks_test`) passaram a marcar também `bloblo_chest`.
3. **Medição de bloqueio (`bloqueio.md`, 400 sementes por caminho, sorteio real):** o maior volume é 10 itens do baú por volta (Beira do riacho/Clareira); nenhuma volta passa de 12, então a primeira bagagem cabe sempre na sacola vazia (0% de bloqueio). Com 6 itens já guardados bloqueiam parcialmente 0–21% das voltas; com 10, 56–86%, sempre com saída (vender os 11 itens, gastar na costura, desejo, baú). Limites não foram aumentados.
4. **Rótulo do botão** do cartão da bagagem: "Abrir <depósito>" (a forma "Ir ao <depósito>" ficava errada para "Despensa"/"Sacola de passeio").
5. **Testes adaptados (não relaxados):** `fridge_test`, `warehouse_test` e `economy_transactions_test` deixam de tratar o baú como "sem limite" (capacidade 12 e itens isentos conferidos); `content_test` agora exige `storage: chest` nos 11 materiais `trail`; `walk_return_ui_test` usa a sacola real (nome e botão) e só encolhe a capacidade a 4; `walks_test` liga `unlimited_storage` (acumula dezenas de voltas sem vender; o limite tem teste próprio). Teste novo: `chest_test`.
6. **Verificação:** suíte um a um (`build/economy/etapa_08/`): sem falhas novas; continuam os históricos `finds_test`, `npc_lines_test`, `progression_test` (merchant_festival) e o instável `onboarding_test` (falha igual com o limite do baú desligado). Simulador `reference` semente 1: campanha completa em 7,1 dias, 84/84 missões, 47/48 melhorias, 0 violações. Capturas antes/depois nas três resoluções em `build/screenshots/etapa08_antes|depois/`.

## 18/10/2026 — etapa 09 (fontes de renda e transformação), Claude Code

**Números aplicados (tabela 02 B, sem ajuste medido):** `crops.*.coins` e as duas rotas produtivas de Natureza (`lane` 8, `trail` 15) em **0**; `apple_biscuit` 40→30; `treat_box` 60→140; `special_order` 220→600; `festival_contract` 450→940; `merchant_stall` 150→30; `atelier_open` 200→40; capítulos 1–9 10/20/30/40/80/100/120/140/160 → 10/20/30/40/60/60/60/80/80; presente de nível acima do 10: `10 × nível` → `min(80, 20 + 3 × nível)`. `bloblo_biggest` já estava em 40 (etapa 07).

| Cenário | Antes | Depois |
|---|---|---|
| Colher (9 culturas) | 3–24 moedas por colheita | só itens + XP |
| Rotas `lane`/`trail` | 8 / 15 moedas | só materiais + XP |
| Biscoito (lote de 2) | usa 26, entrega 80 | usa 26, entrega 60 |
| Caixa de petiscos | vende 60 (insumos 101: destruía valor) | vende 140 (insumos 101) |
| `special_order` (3 caixas) | 220 (venda direta 180) | 600 (venda direta 420) |
| `festival_contract` | 450 (insumos vendidos: 376) | 940 |
| `merchant_stall` / `atelier_open` | 150 / 200 | 30 / 40 |
| Capítulos 5–9 | 80/100/120/140/160 | 60/60/60/80/80 |
| Nível 11 / 15 / 30 | 110 / 150 / 300 | 53 / 65 / 80 |

Decisões:

1. **Quem já plantou não perde.** O snapshot do plantio (`plots[i].job.coins`) e o da rota em andamento (`activity.rewards`) continuam pagando o que valia quando começaram; só trabalhos novos saem sem moeda. Presentes de capítulo/nível/missão já recebidos não são recalculados e nada é cobrado retroativamente (`economy.granted` já protege).
2. **Dado `coins` das culturas fica no JSON com valor 0** (não removido): a UI só mostra o chip de moeda se o valor (ou o snapshot) for maior que zero (`SheetBuilder.seed_picker`, `growing_plot`, `RoomView.harvest_plot`).
3. **Fórmula de nível dirigida por dados** (`level_rewards.default`: `coins_base` 20, `coins_per_level` 3, `coins_max` 80). Níveis 2–10 seguem na tabela; o 10 (100 moedas, 2 parafusos) fica como estava.
4. **Passeios, achados, diárias, desejos e vínculo não foram mexidos** (etapa 16 e seguintes); aparecem no ledger como "rotinas/diário/desejo/amigos/achado" só para medir.
5. **Margens recalculadas com cadeia completa** (`coins_test`): biscoito 26 → 60; caixa 101 → 140 (biscoitos valem 30 cada na conta); contrato 3 caixas 600 > venda 420; festival 940 > insumos 696 (a 140 a caixa; as peças `bolt`/`iron_band` são bônus, não cotação).
6. **Simulador (semente 1, até a campanha, `build/economy/etapa_09/report.md`):** colheita+coleta deixam de ser fonte (5,9–6,1 mil moedas → 0); venda+encomenda passa a 73–75% do ganho total; as recompensas únicas caem 17–18% (3830 → 3169 no `reference`); o total ganho cai 16–25% (22,9 mil → 17,4 mil no `reference`; 21,3 mil → 17,8 mil no `recovery`), saldo final 15,6 mil → 9,9 mil. Campanha completa em 7,1 / 7,8 / 7,3 dias (`reference`/`commercial`/`recovery`; antes 7,1 / 7,3 / 6,4), 84/84 missões, 0 violações. Melhorias 45/44/48 de 48 (antes 47/43/46): a janela final **não** é calibrada aqui (etapas 10–23). Primeira compra igual nos três (cama, 0,9 min ativos): nenhuma compra obrigatória exige moeda antes de vender.
7. **Testes adaptados (não relaxados):** `farm_test`, `tray_test`, `economy_sim_test` (colher = 0 moeda), `treasure_test` (mirtilo 0), `welcome_test` (nível 15 = 65, 30 = 80). Teste novo: `coins_test`. Ver README para as falhas históricas.

## 18/10/2026 — etapa 10 (colheitas para visitas curtas e para a volta), Claude Code

**Números aplicados (tabela 02 C, sem ajuste):** tempo / lote / XP Horta — cenoura 60 s/2/6; batata 300/3/16; morango 900/4/24; abóbora 3600/4/35; batata-doce 7200/6/45; trigo 600/4/18; milho 1200/6/24; ervas 7200/6/50; mirtilo 14400/8/65. Antes: 60/2/10, 300/2/22, 180/2/15, 600/1/35, 420/2/30, 120/3/12, 180/3/15, 900/2/55, 900/3/40. Canteiros 5–9: 40/70/100/150/220 → **80/140/220/340/500** (índices, 4 iniciais e presente de canteiros emprestados intactos). Rega 30% do que falta e fator estufa 0,7 mantidos.

| Cenário | Antes | Depois |
|---|---|---|
| Unidades por minuto (cenoura / batata / trigo / morango / milho / abóbora / batata-doce / ervas / mirtilo) | 2,0 / 0,4 / 1,5 / 0,67 / 1,0 / 0,10 / 0,29 / 0,13 / 0,20 | 2,0 / 0,60 / 0,40 / 0,27 / 0,30 / 0,07 / 0,05 / 0,05 / 0,03 |
| Quatro canteiros de uma vez | cenoura 8 … mirtilo 12 | cenoura 8, batata 12, trigo/morango/abóbora 16, milho/batata-doce/ervas 24, mirtilo 32 |
| Mirtilo na estufa (0,7) | 10 min 30 s | 2 h 48 |
| Linha da Bloblo | abóbora (colher, 600 s) na ordem 65 ANTES da escritura (70) | escritura logo depois do ensopado; sabores na linha própria |

Decisões:

1. **Tempo efetivo num só lugar:** `GameState.crop_seconds(índice, cultura)` aplica o fator da estufa UMA vez ao plantar; lista de sementes (`SheetBuilder.seed_picker`, que antes mostrava o tempo cru na estufa) e bandeja (`PlotTray.seeds`) usam a mesma função. A rega só age sobre o que falta e uma vez (`watered`); recarregar o save não recompõe nada (`ready_at` salvo). A interface mostra tempo e lote, nunca promete rendimento maior por regar (testado: regar não muda o lote).
2. **Sabores fora da linha principal:** `bloblo_strawberry/pumpkin/sweet_potato` (IDs, textos e prêmios preservados) vão para a linha `flavors` (npc `bloblo`), ordens 10/20/30. Entram depois de `first_kitchen`; além disso exijo `bloblo_dig`, `bloblo_potato` e `farm_deed` respectivamente (a 03 só pedia `farm_deed` na batata-doce), para o cartão nunca pedir colher uma planta que ainda não pode ser plantada — mesmos marcos que já liberam cada cultura. Missões já recebidas continuam recebidas (só mudam linha/ordem). Não havia gate circular (plantar nunca exigiu a missão de colher a própria planta); o problema real era a abóbora de 1 h no meio da linha principal, agora removido.
3. **Mirtilo × silo_2:** 4 canteiros = 32, cabe no silo_2 (56) com reserva de 24; testado com duas rodadas colher → vender → replantar. Milho (24) e batata-doce (24) cabem com reserva.
4. **Atenção por visita (cenário):** visita curta (1–2 min): cenoura (2 un/min, 6 XP/min) ou batata; visita de 10–15 min: trigo/morango; volta do trabalho/escola: abóbora ou milho; voltar no dia seguinte: batata-doce, ervas, mirtilo (cada toque rende 24–32 unidades). Nenhuma cultura longa ganha todas as comparações por minuto (cenoura ainda é a melhor por minuto; as longas valem pelo lote por visita).
5. **Simulador (semente 1, até a campanha; antes = cópia do projeto com os dados da etapa 09; `build/economy/etapa_10/`):** reference 7,1 → 6,4 dias (9924 → 11967 moedas, 46/48 melhorias); recovery 7,3 → 8,8 dias (10127 → 14401, 47/48); commercial 7,8 dias (9432) → **parou em 25,8 dias** (74/84 missões). Sementes 2 e 3 do commercial completam (7,3→7,8 e 7,8→7,4 dias). A parada da semente 1 não é da horta: o baú encheu de itens de passeio no dia 4 e o robô nunca vende itens da sacola nem compra uma terceira ampliação só para cumprir `storage_upgrades` (bloqueio `storage:chest@merchant_festival` / `stat:storage_upgrades@bloblo_biggest`, mesmo com 50 mil moedas). Um jogador vende o excesso e compra a ampliação; fica registrado como limite de política do simulador para a etapa 23 (não alterei o jogo nem o robô aqui).
6. **Testes adaptados (não relaxados):** `farm_test` (80 moedas; lotes 4 e 6), `flavors_test` (ordem das sementes por tempo), `treasure_test` (mirtilo 10081 s na estufa, 8 unidades), `animals_test` (milho 6). Teste novo: `garden_test` (tabela, custos, tempo efetivo, rega única, plantas exclusivas, snapshot, linha `flavors`, lotes longos com reserva, lista de sementes). Falhas históricas e instáveis permanecem: `progression_test`, `npc_lines_test`, `finds_test`, `onboarding_test`, `park_test`/`petshop_test` (raro) — ver README.


## 18/10/2026 — etapa 11 (aprender uma rota × ganhar mais vagas), Claude Code

**Números aplicados (tabela 02 E, sem ajuste):** segundos / saída / XP local — lane 120/wood 2/2; pebbles 120/stone 2/2; trail 600/wood 4+stone 3/8; quarry 600/stone 6/8; woodcutting 900/wood 8/12; timber 3600/wood 8+hardwood 3/35; copper_vein 1200/stone 3+copper 3/16; deep_quarry 3600/stone 8+copper 5/35; crystal_cave 2400/crystal 2+copper 2/26; crystal_deep 7200/crystal 5+copper 4/60; meadow 600/fiber 4+wood 2/8; reeds 3600/fiber 10+wood 3/35; orchard_harvest 3600/apple 8/sem XP local. Antes: lane 60/1, pebbles 75/1, trail 180/3+2, quarry 180/5, woodcutting 150/4, timber 240/5+2, copper_vein 360/3+3, deep_quarry 300/8+4, crystal_cave 600/2+2, crystal_deep 480/4+3, meadow 420/5+3, reeds 300/8+3, pomar 300/4; todas davam 10 XP local por busca. Patamares 0/30/90 (Bosque, Prado) e 0/40/120 (Caverna), vagas 1/2/3 → **0/24/120/360 e 1/2/2/3** nos três locais. `woodcutting` passa a exigir só `forest_open`.

| Cenário (por local) | Antes | Depois |
|---|---|---|
| XP por busca | 10 (qualquer rota) | 2 (curta) · 8–16 (média) · 26–60 (longa) |
| Nível 2 (segunda vaga) | 3 buscas (30 XP) | Bosque: 2 longas (24 XP) ou 12 curtas; Caverna: 3 pedreiras ou 12 pedrinhas |
| Nível 3 (madeira dura / cristal) | 9 buscas | 120 XP: 10 woodcuttings ou 60 lane |
| Terceira vaga | nível 3 (90–120 XP) | **nível 4 (360 XP)**: 30 woodcuttings ou 11 timber após o nível 3 |
| Material por hora de vaga (madeira) | lane 60 · woodcutting 96 (nível 2) | lane 60 · woodcutting 32 · timber 8 (+3 de madeira dura) |
| Pedra por hora de vaga | pebbles 48 · quarry 100 · deep 96 | pebbles 60 · quarry 36 · deep 8 (+5 de cobre) |
| XP local por hora de vaga (Bosque) | 600 (10 por busca de 60 s) | lane 60 · woodcutting 48 · timber 35 |

Decisões:

1. **XP guardado no lote:** `start_gathering` grava `nature_xp = activities.<rota>.nature_xp` (e `start_activity` também); recolher paga exatamente esse valor, uma vez. Lote/rota guardados sem o campo (saves anteriores) pagam o `xp_per_collection` antigo (10) e mantêm a saída que já traziam — mudar a tabela depois não altera o que está em andamento (testado, inclusive alterando `woodcutting.nature_xp` com um lote ativo). Iniciar, cancelar, erro ou colher antes da hora não pagam XP.
2. **Terceira vaga no nível 4 sem token novo:** `slot_levels: [2, 4]` nos dados diz em que nível cada `*_slot_N` entra; os tokens de nível (`*_level_2/3`) continuam como estão (liberam cobre/madeira dura/cristal/juncos). Assim nenhum teste/missão que cita esses IDs muda; os tokens `*_slot_3` apontam `nature_unlock.level` 4.
3. **Piso legado pelas ampliações possuídas (não por XP inventado):** `ProgressionState.nature_level` = max(nível do XP, nível dos tokens de nível e de vaga já possuídos). Quem tinha vaga 3 (XP antigo 90/120) vira nível 4 com XP guardado inalterado (a barra mostra o máximo; ninguém perde vaga, material nem paga de novo). Quem tinha só o token do nível 2 com XP baixo fica no nível 2 e a barra começa em zero. A única sincronização de tokens está em `ProgressionState.sync_nature_tokens`.
4. **Escolha de rota explícita, só na sessão:** `route_id` vazio = rota padrão (a elegível mais curta, como pede a 02 E); a escolha do jogador (`NatureUi.choose_route`) nunca é trocada sozinha — nem depois de recolher, nem quando outra rota fica disponível (testado: duas woodcutting + recolher mantêm a preferência; limpar a sessão volta para a mais curta). Rota bloqueada, de outro material ou de outro local é recusada sem tocar no estado. A lista de rotas por material ficou na ordem dos dados; a ordem exibida é por duração.
5. **Duas buscas longas × doze curtas (Bosque):** ambas fecham 24 XP e chegam ao nível 2, mas a longa pede 2 toques e 30 min de vaga, entrega 16 madeiras; a curta pede 12 toques e 24 min, entrega 24 madeiras. Por hora de vaga a curta rende **mais** XP (60 contra 48): o ganho da longa é menos toques por visita, não XP por hora. Mantive os números da tabela (não calibrei por conta própria); a etapa 23 deve decidir se isso basta.
6. **Pomar:** 1 h / 8 maçãs, sem receber XP de um local inexistente (`route_nature_xp` devolve 0 sem `site`).
7. **Textos:** "Faltam N XP" substitui "mais N buscas · +10 XP cada" (já não existe um XP único por busca); as vagas fechadas dizem o nível certo (2 e 4) via `nature_slot_level`.
8. **Simulador (semente 1 até a campanha; "antes" = `build/economy/etapa_10/*_depois`):**

| Perfil / semente | Etapa 10 | Etapa 11 (robô antigo) | Etapa 11 (robô escolhe a rota pelo ritmo) |
|---|---|---|---|
| reference s1 | 6,4 d (46/48) | 9,8 d (47/48) | **10,1 d** (47/48) |
| reference s2 | — | 10,3 d | 9,1 d |
| recovery s1 | 8,8 d (47/48) | 9,1 d | **8,1 d** (48/48) |
| recovery s2 | — | 10,3 d | 8,8 d |
| commercial s1 | parou em 25,8 d (74/84) | 8,3 d | **8,3 d** (44/48) |
| commercial s2 | 7,8 d | 8,1 d | 7,8 d |
| commercial s3 | 7,4 d | 10,3 d | 8,1 d |

   84/84 missões e 0 violações em todas. O robô antigo escolhia, para um item, a primeira rota na ordem dos dados — agora a longa (`woodcutting`, liberada cedo) — e passava horas esperando. Ajuste de **política do robô** (não do jogo): `economy_bot._routes_by_rate` ordena as rotas pelo rendimento no ritmo da sessão (taxa por segundo se cabe na sessão; senão por intervalo até a próxima visita), como um jogador que escolhe a duração. A semente 1 do `reference` (sessões muito espaçadas) fica 3,7 dias mais lenta que na etapa 10: marco "banca" 49,9 h → 74,0 h, porque pedra/madeira por hora de vaga caem (tabela acima) e a segunda/terceira vaga demoram mais; o `commercial` não parou nesta rodada (a parada da semente 1 na etapa 10 vinha do baú cheio e de `storage_upgrades`; não investiguei por que não se repetiu, e a política do robô continua a rever na etapa 23). Não ajustei números por isso: critério é "verificar, registrar"; a janela final é da etapa 23. Evidência: `build/economy/etapa_11/` (`run_depois_bot_antigo.txt`, `run_depois.txt`, resumos por perfil).
9. **Testes adaptados (não relaxados):** `nature_test` (XP 2 por lane, níveis 24/120/360 com woodcutting/timber, terceira vaga só no nível 4, lote de trilha 4+3, cristal profundo escolhido, `NatureLevel_*_4`), `content_test` (quatro patamares, `slot_levels`, XP por rota), `coins_test` (trilha 4 madeiras + 3 pedras). Teste novo: `nature_routes_test` (tabela, patamares por local, tokens, XP uma vez, erros sem efeito, `route_id` opcional, snapshot velho, legado vaga 3 + XP 90, três rotas simultâneas com pilha de 16, 2 woodcutting × 12 lane, interface da bandeja, vagas fechadas "Nível 2/4"). Falhas históricas e instáveis permanecem; ver README.

## 18/10/2026 — etapa 12: filas e Preparar N

1. **Tempos:** tabela 02 D aplicada nas 19 receitas listadas (carrot_snack 60 … milk 1800); ingredientes e rendimentos intactos (biscoito 2, farinha 2, ovos 2, leite 2 por animal); costura de coleção igual; lotes em andamento seguem o snapshot.
2. **Vagas:** `stove_queue` 180+tábua 3 → 80 sem tábuas (exige `first_kitchen`, como a tabela pede); `stove_queue_2` 320+tábua 5 → 220+tábua 3 (bancada + fila anterior); `blender_queue` nova (100 + tábua 1, bancada) em `config.json → stations.blender.slot_upgrades`, comprada no lugar Cozinha. Saves que já têm as filas antigas não são tocados (compra só vale na primeira vez).
3. **Preparar N:** `GameState.cook_many(receita, N)`; N máximo = min(vagas livres, lotes que os ingredientes pagam). Validação única antes de consumir: falta de vaga/ingrediente em QUALQUER lote recusa tudo ("Só cabem N na fila", "Falta X ×k"). Um lote pronto e não pego continua ocupando a vaga. Animais e costura de coleção: só 1.
4. **Relógio:** a hora "Pronto às" usa `GameState.clock_text` (o `economy_sim_test` proíbe ler o relógio do sistema fora do GameState).
5. **Texto:** "Tudo ×N" no lugar de "Máx." (glossário, `texts_test`).
6. **Medição (simulador, semente 1, até a campanha; antes = `etapa_11/*_depois`):**

| perfil | antes | depois |
|---|---:|---:|
| reference | 10,1 d | 16,1 d |
| commercial | 8,3 d | 10,3 d |
| recovery | 8,1 d | 11,3 d |

   84/84 missões e 0 violações. O ritmo piora porque os tempos de receita cresceram até 10× (leite 300→1800 s, tira de batata 150→600 s) e o **robô cozinha um lote por vez** (não usa Preparar N); a política do robô não foi alterada nesta etapa. Aviso para a etapa 23: calibrar tempos × autonomia (ou ensinar o robô a preparar N) antes de julgar o ritmo.
7. **Visitas (queue_test):** 10 lanches = 10 visitas com 1 vaga, 4 com 3 vagas (Preparar 3); o tempo de fogão é o mesmo (a fila poupa visitas, não acelera nada). Relatório: `build/economy/etapa_12/autonomia.md`.
8. **Testes adaptados (não relaxados):** `animals_test` (tempos 900/1800/300/1200), `station_tray_test` (tempo da receita lido dos dados). `onboarding_test` instável: ocioso 380 s (> 240 s; antes 310 s), reflexo dos tempos maiores, mesmo teste já instável. Históricos: `progression_test`, `npc_lines_test`, `finds_test`; `park_test` passou nas duas repetições.

## 18/10/2026 — etapa 13: capítulos 1–9 sem tarefas repetidas

1. **Cruzamentos (`shared_with`):** `main_5_pickaxe`→`guide_open_cave`, `stone_path`→`guide_stone` e `main_6_commerce`→`merchant_variety` viram só orientação (objetivo `quest`, prêmio vazio); a entrega e o prêmio ficam na missão do personagem (5, 25 e 10 moedas). O inventário real tem **10 pares** (os 7 anteriores a esta etapa incluem `first_sale` e `main_2_order`; o plano supunha menos): todos validados em `journey_test` (canônica de linha, um objetivo, sem prêmio, sem duas principais na mesma canônica, ordem crescente na linha). Perdas aceitas pela matriz: o cobre 2 e o XP de aventura que `stone_path` pagava e os 10 moedas de `main_5_pickaxe`.
2. **Objetivos:** `main_5_cooking` = `produce:carrot_snack` 2 + `produce:vegetable_soup` 1 + `produce:strawberry_juice` 1 (sem fresh); `merchant_variety` nova (merchant, ordem 45, `order:vegetables` 1 + `order:snacks` 1, 10 moedas, sem fresh); `main_7_greenhouse` = estufa + `harvest:herbs` 1; `main_8_building` sem fresh; `atelier_open` = ateliê + `produce:fabric` 2 + `produce:accessory_set` 1 (prêmio igual). `crops.herbs` sem `skills.agriculture 5` (continua só na estufa).
3. **Migração:** nenhum reset nem `SAVE_VERSION` novo. Marco antigo recebido resolve a canônica sem pagar (`_sync_shared_quests`); `_sync_step` agora descarta, num passo ativo de save antigo, as bases de contadores que deixaram de ser `fresh` (ex.: `produce` da cozinha). Save com banca montada e a variedade ainda pendente: a missão aparece uma vez, paga 10 e a linha segue para os contratos.
4. **Medição (simulador, semente 1, até a campanha; antes = `etapa_12/*_depois`):** reference 16,1 → **12,1 d**, commercial 10,3 → **12,9 d**, recovery 11,3 → **12,9 d**; 85/85 missões (84 + `merchant_variety`) e 0 violações; reference s2 11,8 d e s3 13,3 d (85/85). Ritmo medido, sem ajuste de números.
5. **Bloqueio encontrado e corrigido (política do robô):** a primeira rodada de reference s1 e recovery s1 travou em 31 d (84/85, `merchant_festival`): o perfil não vende achados de passeio (`sell_trail: false`), o baú encheu 64/64 de trilha e o `treat_box` não cabia. O jogo não bloqueia (a feira compra os 11 itens). Ajuste do **robô**, não do jogo: `economy_bot._make_space_for` tenta uma segunda passada vendendo trilha só quando não há mais nada a vender para abrir espaço. Depois do ajuste: reference s1 12,1 d e recovery s1 12,9 d. Aviso para a 18/23: um jogador que guarda tudo enche o baú de 64 (ampliações `_4/_5` previstas na 18).
6. **Testes adaptados (não relaxados):** `market_test` (a ordem da linha do Feirante ganha `merchant_variety`, que reconhece as entregas já feitas); `progression_test` (a campanha agora planta ervas nos canteiros da estufa, antes plantava só no sítio; com isso a campanha simulada completa 85 missões, o que antes não acontecia: parava em `merchant_festival`). Teste novo `journey_test` (entra em `tools/test_all.ps1`; relatório em `build/economy/etapa_13/repeticao.md`).
7. **Pendências históricas, não desta etapa:** `npc_lines_test` (4 erros no Guia, iguais aos da etapa 12), `finds_test` (1 erro "Faro: missão pronta"), `onboarding_test` (instável, ocioso 380 s). `dev_tools_test` imprime "TEST (dev): PASS" e aparece como FAIL no resumo mesmo passando.

## 18/10/2026 — etapa 14: investimentos e cadeia dos animais

1. **Custos (tabela 02 F, `progression.json → upgrades`, única fonte; a UI lê dali):** farm 180→220, workbench 120→160, chicken_coop 180→260, cow_barn 300→420, mill 240→300, dairy 320→420, orchard 300→400, stall 350→500 (só o preço; níveis 2/3 e contratos ficam na 15), greenhouse 480→850, atelier 600→1000. Materiais já coincidiam com a tabela.
2. **Animais (`config.json → animals`):** extras branca/ruiva/preta 60/80/90→120/150/180; vacas 140/180/200→220/280/340. Requisitos de variedade: ruiva e caramelo 2→8 produtos, preta e malhada 6→24. Sem campo de rendimento por variedade (o teste `animals_chain_test` proíbe): preço e desenho não viram produção escondida. IDs e índices intactos; o primeiro animal continua presente do abrigo.
3. **Linha da Bloblo:** ordem farm_deed 70 → coop 80 → eggs 90 → cows 100 → milk 110 → flour 120 → cheese 130 → **`bloblo_breakfast` 140** (novo: `order:farm_breakfast` 1, 15 moedas, sem consumir queijo; o pedido `farm_breakfast` ficou como estava: ovo 2 + farinha 2 + queijo 1, 95 moedas, recarga 600). `main_9_flour` = produzir 2 farinhas + construir o moinho, sem `fresh`. Falas de ovos/leite agora dizem "com 8".
4. **Ração:** milho (4) e trigo (6) das missões seguem como primeiro lote; milho/trigo plantam sem nenhum produto animal e as receitas de ovo/leite/farinha/queijo não dependem de produto colhido (testado).
5. **Retorno:** os prêmios da linha somam 265 moedas contra 1.400 de abrigos/moinho/queijaria; a missão mais cara não devolve seu custo.
6. **Medição (simulador, semente 1, até a campanha; antes = etapa 13 após o ajuste do robô: reference 12,1 d, commercial 12,9 d, recovery 12,9 d):**

| perfil | antes | depois |
|---|---:|---:|
| reference | 12,1 d | 11,1 d |
| commercial | 12,9 d | 12,1 d |
| recovery | 12,9 d | 10,3 d |

   86/86 missões (85 + `bloblo_breakfast`), 0 violações. O recovery (comprou conforto antes) financia o elo seguinte sem bônus dev. A queda de dias não foi investigada (os custos subiram; o simulador usa a política do robô e a semente 1): registrar para a calibração da etapa 23.
7. **Testes:** `animals_chain_test` novo (custos, preços, requisitos, ordem, cinco elos por ações reais, compra durante o lote sem entrar no snapshot, café com o pedido existente, nenhum pedido duplicado, save); ajustados `animals_test` (preços, 8/24 produtos por lotes reais) e `warehouse_test` (bancada 160). Suíte em `build/economy/etapa_14/suite/resumo.txt`: só falham os históricos (`npc_lines_test` 4, `finds_test` 1, `onboarding_test` instável, `dev_tools_test` imprime "(dev)").

## 18/10/2026 — etapa 15: clientes e sentido da banca

1. **Clientes (`progression.json → orders[*].customer`):** Laís = vegetables, soup_order, juice_order; Bloblo = snacks, puree_order, farm_breakfast; Nina = fruit_basket, pop_order. IDs, canal, cooldown, preço e requisitos intactos (farm_breakfast: 95 moedas, 600 s). Contratos do Feirante não têm cliente.
2. **Confiança (`customer_tiers`):** derivada de `order:<id>`; 3 entregas/1 tipo, 8/2, 18/2 pagam 10, 20 (+1 parafuso) e 30 moedas por `_grant_automatic("customer:<npc>:<n>")`, uma vez; histórico antigo recebe só o que nunca foi pago, no próximo pedido do cliente (a checagem é em `fulfill_order`, não no carregamento). Não muda preço, espera nem história. Sem decaimento.
3. **Banca:** stall_2 450→900 moedas, exige 6 contratos (antes 2) e 2 tipos; stall_3 800→1500, 15 (antes 5) e 3 tipos; materiais da tabela 02 já coincidiam. Novo requisito `distinct_orders: {contracts: N}` conta ids de contrato com contador > 0; encomenda e consulta não contam. Posse antiga não é retirada (só a compra valida).
4. **Banquete na banca 1:** `banquet_contract` troca `stall_2` por `stall` (dairy/blender, ingredientes, 300 moedas, recarga 1200 s e aro de ferro iguais). Tipos antes da banca 2: building_order, special_order e banquet_contract; fabric_order continua na banca 2 e festival na 3. O terceiro tipo da banca 3 vem de banquete + (fabric_order do ateliê ou special_order da estufa/pomar).
5. **Missões do Feirante:** `merchant_contracts` 2→6 e `merchant_clients` 5→15, falas e rótulos dizem "pelo menos dois/três tipos"; `merchant_expand` cita as 900 moedas.
6. **Interface:** resumo de clientes (`CustomerSummary`: três selos de laço bronze/prata/ouro + "Laís · Cliente de confiança · 10/18") no quadro dos vizinhos, linha de cliente no detalhe e cabeçalho da banca com "contratos · tipos" lido dos dados. Sem aba nova; toast ao subir de patamar. O selo é o laço (`item_ribbon`) tingido (`Palette.SEAL_*`), nunca o coração do vínculo do Tiro. Limitação: o laço é avermelhado e o "ouro" lê alaranjado.
7. **Robô do simulador (só teste):** contratos de tipo ainda não entregue vêm primeiro; o requisito `distinct_orders` persegue também tipos inacessíveis (ex.: banquete → laticínio), exceto os que dependem da banca seguinte ainda não comprada; o simulador passou a declarar o prêmio de patamar na conservação de moedas (`_add_customer_tiers`). Sem isso aparecia a violação "fulfill_order +28 (esperado +18)".
8. **Medição (simulador, semente 1, até a campanha; antes = etapa 14):**

| perfil | antes | depois |
|---|---:|---:|
| reference | 11,1 d | 15,1 d |
| commercial | 12,1 d | 17,8 d |
| recovery | 10,3 d | 14,3 d |

   86/86 missões, 0 violações. O aumento de 4 a 6 dias é o custo pretendido de 15 contratos, 3 tipos e +1.150 moedas de banca. Na primeira medição o commercial travou em 63/86 porque o robô não perseguia o laticínio nem aceitava o ateliê; com a regra do item 7 fecha em 17,8 d. Não há multiplicador de confiança: a renda extra dos clientes é de 60 moedas + 1 parafuso por cliente.
9. **Testes:** `customers_test` novo (mapeamento, patamares, reload, histórico antigo, 5/6 e 14/15, tipos repetidos, banquete, UI); `market_test` ajustado (6 e 15 contratos); `progression_test` (campanha entrega contratos até 5x); `economy_bot`/`economy_sim` ajustados. Rodados nesta etapa, todos PASS: customers, market, content, tasks, journey, animals_chain, coins, texts, lists, station_tray, economy_transactions, economy_sim, queue, animals, warehouse, progression. A suíte completa não foi repetida; históricos conhecidos seguem: `npc_lines_test` 4, `finds_test` 1, `onboarding_test` instável.

## 18/10/2026 — etapa 16: vínculo útil e rotinas sem sorte

1. **Carinho:** `pet()` concede +1 afeto se `affection:pet` (cooldown em `progress.cooldowns`, 120 s, sobrevive a reload) estiver livre; a reação continua livre. Devolve o afeto concedido; a UI não tem recompensa paralela (só o texto "+carinho" quando veio). Brincar paga +2 só se útil (ganho ≥5) ou por exceção, com `affection:play` de 120 s.
2. **`care_useful`:** conta ao recuperar ≥5 (carinho ≥3, guarda `useful:pet` 120 s) em qualquer necessidade, medido antes/depois do gesto. Exceção uma vez por instância: desejo de ação aberto que ainda falta (`slot.used`) ou passo ativo da história com o mesmo contador (`progress.seen["care:<missão>"]`); entregar desejo de comida (`fulfill_wish`) vale como cuidado pedido. Desejo satisfeito aguardando Receber não dá exceção. Contadores brutos (`pet`, `play`, `feed`, `bathe`) intactos. Limiares em `progression.json → settings` (`care_useful_gain`, `care_useful_gain_pet`, `care_affection_cooldown`).
3. **Moedas:** desejos de ação 2; comida/give `min(8,max(2,round(preço×0,5)))`; especial ×2 com teto `special_coin_cap` 12 (`wishes.json`); vínculo 2–8 = 10/15/20/25/30/40/50 (itens preservados). Sem recálculo retroativo (`bond:N` já pago não repete).
4. **Disponibilidade real:** `GameState.wish_item_reachable` — item na mochila ou planta/receita com estação e requisitos liberados; passeio/achado dependem só dos requisitos do desejo. Pedido que ficou impossível troca na hora (sem espera) e guarda `swap_reason: unreachable`, sem gerar item. `wish_item:<item>` conta na entrega efetiva (feed/give), nunca em `feed` direto. Garantia de mirtilo fica para a etapa 17 junto da missão.
5. **Rotinas:** catálogo R1 em `routines.json → missions` (diárias care/harvest/cook/order/tiro_walk; semanais care_week/big_harvest/chef_week/orders_week), metas `goal.targets {start,middle,community}` (fase pelo capítulo: ≤4, 5–9, 10+) congeladas em `progress.routines[kind].targets` na geração, `catalog: 2`. Definições anteriores ficam em `legacy` e continuam valendo para períodos já sorteados (meta e prêmio). Contador novo `production_jobs` (um por lote coletado, inclusive costura). Baseline por contador no sorteio. Com menos de 3 candidatas sorteia menos: o capítulo 3 abre com 2 diárias.
6. **Cosméticos:** as coleções que só vinham das semanais antigas (clean_bow, heart_collar, walker_bandana, garden_hat, trail_bandana, cook_apron, merchant_apron, miner_helmet) passaram a ser prêmio das novas semanais (care_week, big_harvest, chef_week, orders_week) para não ficarem inalcançáveis; `digger_bandana` já vem de `finds.json`. **Ponto para o Vitor revisar** (a distribuição é minha; a tabela da 07 não diz).
7. **Nina:** `nina_rare` → linha `nina_discoveries` ordem 10 (requisito `nina_walk`); pet shop (upgrade e lugar) exige `nina_routes`. Chances e pity do raro intactos; quem já recebeu mantém.
8. **Medição (semente 1, até a campanha; antes = etapa 15):** reference 15,1→14,3 d, commercial 17,8→16,8, recovery 14,3→13,4; 86/86, 0 violações. Afeto final 902→715, 364→353, 816→816. O vínculo máximo (520) segue sendo alcançado sem calendário artificial. Calibração fina fica para a etapa 23.
9. **Testes:** `bond_test` novo (100 carinhos diretos, reload antes/depois do cooldown, fome cheia × baixa, desejo satisfeito com prêmio pendente, tutorial uma vez, fórmula de moedas, rotinas antigas × novas, lotes, Nina com raro nunca saindo). Ajustados `wishes_test`, `tasks_test`, `lists_test`, `content_test`, `tricks_test`.


## 18/10/2026 — etapa 17: três produtos com usos reais

1. **Receitas e itens:** `braided_toy` (bancada: tecido 1 + graveto 2, 720 s, venda 40), `picnic_pack` (fogão: lanche de cenoura 2 + picolé 2 + suco 1, 1080 s, venda 110), `blueberry_treat` (fogão: mirtilo 2 + ervas 1 + lanche 1, 900 s, venda 65, geladeira, fome +20 e alegria +10) e a receita `cut_sticks` (bancada, madeira 1 → 2 gravetos, 60 s; sem item novo). Margens imediatas 12/34/19, como a tabela 07 previa (conferidas em `products_test`). Brinquedo e cesta não têm `feed`; só o petisco aparece no menu de comida. Brinquedo e cesta caem no baú (categoria `product`).
2. **Requisitos:** brinquedo e cesta pedem a missão `atelier_open` (a cesta também o liquidificador); o petisco pede `treasure` ≥ 1 e a estufa. Nada nasce visível antes das origens.
3. **`player_xp` por receita:** `WorkJobs.batch` usa o campo da receita quando existe e só então o XP global da ação (nunca os dois); o valor entra no snapshot do lote (`player_xp`, `player_xp_key: "recipe"`). Lotes antigos e receitas sem o campo seguem com o XP do cook (5). Valores: gravetos 1 (e `skill_xp` 0, sem treino local), brinquedo 8, cesta 10, petisco 10; `skill_xp` 20/25/25 (aventura/culinária/culinária).
4. **Encomendas** (`customer`, sem canal): `nina_toys` (brinquedo 2 → 110, 3600 s), `lais_picnic` (cesta 1 + suco 2 → 190, 3600 s), `nina_blueberries` (petisco 2 → 175, 7200 s); XP de Comércio 10/12/12. Exigem também `first_harvest` (regra do `content_test`).
5. **Missões:** linha `workshop` do Guia (ordens 10/20/30, após `atelier_open`): `workshop_toy` (10 moedas), `workshop_first_set` (iron_band 1; `produce:accessory_set` sem `fresh`, reconhece o conjunto do capítulo 9) e `workshop_picnic` (10 moedas). `nina_blueberry` (linha `nina_flavors`, ordem 10, tesouro + estufa, objetivo `wish_item:blueberry_treat`, afeto 8).
6. **Desejo do mirtilo:** `wishes.json → blueberry_treat` (especial, 8 moedas/10 afeto, dobrados com teto 12), campo `guarantee_quest`: `_pick_wish` oferece o pedido na próxima vaga vazia e pronta enquanto a missão estiver ativa, desde que não esteja em outro espaço, o item seja alcançável e não seja o último pedido trocado daquele espaço (o pedido inicial de tutorial continua tendo prioridade). Não substitui pedido atual, não gera ingrediente, não impede a troca. Depois de `nina_blueberry` recebida, volta a ser só um especial raro. A garantia não depende de raro (`walk_rare` 0).
7. **Usos (critério da etapa):** brinquedo = `workshop_toy` + `nina_toys` (o projeto Banco só entra na 20); cesta = `workshop_picnic` + `lais_picnic` (Piquenique/Festa na 21/22); petisco = desejo do Tiro + `nina_blueberries` + `nina_blueberry`. Nenhum é consumo diário obrigatório.
8. **Interface:** só dados, exceto a grade de receitas do fogão, que passou a ter 10 receitas (3 linhas): a bandeja `pick` com mais de duas linhas rola na vertical (altura de 2,5 linhas) para continuar dentro da sala e abaixo do HUD. Manual, origem e ajuda leem os dados (`Database`).
9. **Simulador (semente 1, até a campanha; antes = etapa 16):** reference 14,3→15,1 d, commercial 16,8→18,8 d, recovery 13,4→14,9 d; 90/90 missões, 0 violações. O custo vem dos passos novos de produção, do tesouro e do desejo. O robô passou a abrir o tesouro e a perseguir `wish_item` (política de teste) e o relatório declara as recompensas do tesouro como esperadas.
10. **Limites:** nenhum número fora da tabela 07 foi ajustado; o auditor estático (`tools/economy_audit.py`) não foi reexecutado (as margens são conferidas em `products_test`); a calibração fina fica na 23. Sem capturas novas: não há tela nova (só dados e a rolagem do fogão, coberta por `station_tray_test`).

## 18/10/2026 — etapa 18: ampliações de conforto e maestria das estações

1. **Depósitos `_4` e `_5`:** tabela 02 A sem ajuste (silo 550/1000, geladeira 500/900, armazém 500/900, baú 400/750; materiais e aros como na tabela). `storage_capacity` soma só a diferença (silo/armazém 40 e 48, geladeira/baú 24 e 32), conferido em `expansion_test` (totais 128/176, 88/120). O piso legado segue gravado só pela migração e a capacidade é `max(curva, piso)`; recarregar duas vezes não muda nada.
2. **Nome das filas:** a tabela usa `stove_queue_3` (o texto da etapa diz `stove_queue3`); ficou `stove_queue_3`, coerente com `stove_queue_2`. Nomes de exibição e descrições são novos ("Cozinha completa", "Moinho em dobro", "Queijaria ampliada", "Ateliê ampliado"), ícone do ateliê = `item_fabric` (o mesmo do próprio ateliê; não existe `station_atelier`).
3. **Maestria sem retrocesso:** o nível é "selo recebido (`economy.granted`) ou critério atual satisfeito". A variedade pedida usa o catálogo de receitas comuns abertas **ou já feitas**; abrir receita nova eleva a exigência futura, nunca remove selo já pago.
4. **Histórico inexato:** o save antigo guarda `produce:<item>` em unidades. O mínimo comprovável é unidades ÷ maior rendimento conhecido, arredondado para cima (tabela congelada `legacy_r0.json`, senão a receita viva); nunca um lote por unidade. A tábua é saída de duas receitas da bancada (comum, qty 1, e madeira de lei, qty 3): nesse caso só o total da estação sobe e o medidor de variedade da receita começa em 0 (informação incompleta, permitido pela seção 07 C). Método gravado em `economy.mastery_method` (`min_units_v1`) e `economy.legacy.mastery`; jogo novo = `r1`. Nada é pago na migração: o selo atingido sai no próximo lote recolhido da estação.
5. **Interface:** o medidor entrou na bandeja e no painel de cada estação (três selos, lotes e receitas até o próximo patamar, "?"). A linha extra estourava a sala (+42 px no fogão), então a grade rolável da bandeja `pick` caiu de 2,5 para 1,9 linha e o "?" ficou com 30 px. O texto do medidor ficou sem o nome do patamar (os selos já mostram) para caber numa linha.
6. **Simulador:** a guarda de conservação precisou declarar o novo efeito direto do recolhimento (moedas de selos novos, `economy_sim.gd`); sem isso as 8–12 violações eram só "moedas inesperadas". Depois: 0 violações nos quatro perfis.
7. **Cenários antes/depois (semente 1, até a campanha; antes = etapa 17):** reference 15,1→15,1 d, commercial 18,8→18,1 d, recovery 14,9→15,3 d, 90/90 missões, 0 violações. O robô compra as filas por ser barato (reference: `mill_queue` dia 3, `stove_queue_3` dia 5, `dairy_queue` 14, `chest_4` 14, `atelier_queue` 15). Perfil **leve** (120 dias): 89/90 em 85,3 dias, estagnado em `nina_sewing` por sorteio de passeio (`walk_locked`/`luck:walk:yarn|ribbon|bird_feather`), comprando as filas e todos os `_4`/`_5` possíveis; não há baseline leve da etapa 17 e a etapa 18 não mexe em passeios nem missões, então o bloqueio é anterior (anotado para a 23).
8. **Utilidade por inventário de retorno** (`tests/expansion_capacity.gd`, relatório `build/economy/etapa_18/capacidade.md`; volta de 24 h, todas as vagas cheias): silo reserva 24: `_3` deixa 18 colheitas prontas fora, `_4` resolve; reserva 64: `_4` ainda deixa 18, só o `_5` resolve. Armazém reserva 64: `_4` resolve; reserva 100: `_4` deixa 11 fora, `_5` resolve. Geladeira reserva 48: `_4` resolve (`_3` deixa 15 fora); baú reserva 60: `_4` resolve. Conclusão: `_4` é o conforto comum; `_5` só pesa em quem acumula muito (silo/armazém) e é só folga na geladeira e no baú — mantido opcional, sem reduzir limites menores. Limite: a carga do baú não inclui a bagagem do passeio.
9. **Testes:** `expansion_test` novo (em `tools/test_all.ps1`). O `dev_unlock_everything` passou a comprar `_4/_5`, então `fridge_test`, `garden_test`, `pending_gifts_test`, `economy_transactions_test` (dois pontos), `chest_test`, `silo_test` e `warehouse_test` foram ajustados (as asserções "nenhum `_4`" viraram "o `_4` é da etapa 18"). `progression_test` agora leva ~745 ciclos (o robô compra todas as melhorias, inclusive `_5` com 12 contratos e os aros dos contratos): **precisa de tempo máximo ≥ 20 min** (com 12 min o invocador o encerrava; com 50 min: PASS).
10. **Limites:** nenhum número fora das tabelas 02 A/D e 07 C foi ajustado; a calibração fina fica na 23. Sem ícones novos (usei os `station_*` e `item_ribbon` existentes).


## 18/10/2026 — etapa 19: obras comunitárias (estado e motor)

1. **Catálogo vazio de propósito:** `projects.json` entra com `{"schema": 1, "projects": {}}`; o projeto de teste vive só na fixture de `projects_test`. Nenhum capítulo 10–12, prédio ou texto novo para o jogador antes de a interface das etapas 20–22 existir. Nenhum número da tabela 07 E foi usado ou ajustado (os valores de banco/jardim/piquenique/festa continuam candidatos da 07).
2. **Nomes finais do esquema:** requisito = `requirements.projects: [ids]` (avaliador único `GameState.requirement_error`, não `owned`); objetivo = `{"type":"project","key":"<id>","target":1}`; estado em `GameState.projects` (`ProjectState`), chave `projects` no save com `schema` 1. Sem migração, sem `SAVE_VERSION` novo, sem `economy_revision` novo: save sem a chave vira "sem projetos".
3. **Unidade da contribuição:** inteiro positivo. Float só se for inteiro (JSON devolve `2.0`); `0`, negativo, `1.5`, texto e NaN são recusados sem consumir. Excesso é recusado ("Só faltam N"), não truncado, para a interface nunca gastar mais do que o jogador viu.
4. **Indivisível + recuperável:** a última entrega conclui e premia dentro da mesma chamada (um só `_changed`/save). Como defesa extra, `_recover_projects` (ao carregar e no tick de 1 s) conclui uma obra cuja contribuição final foi gravada sem a conclusão/prêmio. Pagamento protegido três vezes (`completed`, `completion_rewarded`, `economy.granted["project:<id>"]`): o caso "granted gravado, flag não" não paga de novo e o caso "flag gravada, granted não" não existe pela ordem de escrita.
5. **Prêmio sem espaço:** vai por `_grant_automatic` (mesmo caminho dos presentes de nível/capítulo); moedas/XP saem na hora, itens excedentes viram recibo `project:<id>` na Mochila. Nunca bloqueia nem desfaz a conclusão. `xp` do prêmio usa `_add_player_xp` só quando o prêmio foi pago agora.
6. **Eventos depois do salvamento:** `project_phase_completed`, `project_completed`, `project_used` são emitidos depois do `_changed`, uma vez por transição (a recuperação também emite, porque é quando o prêmio sai). Carregar um save já concluído não emite.
7. **Uso:** `use_project` é só consulta de estado + contador na primeira vez; repetir emite `first=false` e nada mais. Não altera necessidades, moedas, XP nem afeto. O afeto único da história continua sendo pago pela história (etapa 03), não pelo uso.
8. **Validação do catálogo** (`Database.project_issue`): ciclo, referência ausente, fase sem id/repetida/sem material e item inexistente deixam o projeto indisponível (não começa, não aparece, requisitos nunca valem). Entradas salvas de projetos fora do catálogo são preservadas, nunca apagadas.
9. **Cenários antes/depois (semente 1, até a campanha; antes = etapa 18):** reference 15,1→15,1 d, commercial 18,1→18,1 d, recovery 15,3→15,3 d, 90/90 missões, 0 violações; leve 89/90 em 85,3 d (mesmo travamento em sorteio de passeio de `nina_sewing`, anterior à 18). Idêntico porque o catálogo é vazio; confirma que `from_dict`, o tick e o avaliador de requisitos não mudaram o ritmo.
10. **Testes e armadilhas:** `projects_test` novo (158 verificações; em `tools/test_all.ps1`). Classe nova (`ProjectState`) exige reimportar o projeto (`godot --headless --path game --import`) antes de rodar testes `-s`, senão o `GameState` não compila e o teste acaba falhando de forma enganosa (log com "PASS" parcial e SCRIPT ERROR no `.err`). Limites: sem UI, sem capturas (nenhuma tela nova); calibração fica na 23.

## 18/10/2026 — etapa 20: Banco da Praça (primeiro projeto visível)

1. **Números da tabela 07 E sem ajuste:** `park_bench` entra com requisito `atelier_open`, entrada 150, base tábua 4 + tijolo 2, conforto tecido 2 + brinquedo 1, boas-vindas petisco de cenoura 3, prêmio XP 40 (nada em moedas ou itens: não devolve a obra). Nenhum valor de economia foi alterado; o robô do simulador não conhece o projeto (nenhuma missão o exige), então não houve prêmio novo a declarar na guarda de conservação.
2. **Descoberta lateral, sem missão:** o banco aparece pelo "Novo!" do lugar (`place:park/bench`, `place:park/community`) e pela fala da Laís (`pitch`) no painel; nenhuma missão principal ou de linha aponta para ele (capítulo 10 é da etapa 22).
3. **"Nossa praça" e o limite de quatro lugares:** a Praça já tinha quatro visíveis (Passeio, Pet shop, Amigos, Treino). `community` entra visível e agrupa as obras + os atalhos Amigos/Treino, que passaram a `hidden` (zonas tocáveis e painéis intactos; a lista "Lugares" agora mostra Passeio, Pet shop e Nossa praça). `community` abre com `nina_pipoca` (os serviços que ela agrupa), não com o requisito do banco; a obra só aparece lá com `atelier_open`. O banco é um lugar `hidden` (`bench`) para o "Ir" levar direto ao projeto.
4. **Posição do banco:** medida na prévia da Praça: `pos [400, 282]`, `footprint` losango de ~44×22 px, `approach [372, 280]`; grama livre ao lado do caminho, fora da zona de Amigos (345–390 × 218–249) e sem cobrir portão, árvore ou os quatro bancos desenhados no fundo. Etiqueta "Banco" em `[412, 298]` para não sobrepor "Amigos". Teste: ponto de uso a ≤ 12 px de chão livre e fora do footprint, caminho desde `dog_start`, toque acertado em zoom 0,85/1,4/2,0.
5. **Uso só conta quando o Tiro chega:** `DogWorld.react_at(kind, alvo, on_start)`; `on_start` roda depois do `_go_to` e só se ele estiver a ≤ 12 px do alvo. Se o caminho muda, ele dorme ou sai a passeio no meio, nada é contado e dá para tocar de novo. Dormindo/passeando o toque só mostra a dica e não consome a primeira vez.
6. **Arte:** três PNGs do PixelLab (Pixen, seed 201, contorno preto, 48×40/56×44) e um ícone 32 px (seed 202); a marcação inicial é o desenho da base a 50% de opacidade com balão de entrada. Prompt/descrições em `ART_PIPELINE.md`.
7. **Cenários antes/depois (semente 1, até a campanha; antes = etapa 19):** reference 15,1→15,1 d, commercial 18,1→18,1 d, recovery 15,3→15,3 d, 90/90, 0 violações; leve 89/90 em 85,3 d (mesmo travamento em `nina_sewing`). Idêntico, como esperado: obra opcional que o robô não faz.
8. **Testes:** `bench_test` novo (em `tools/test_all.ps1`); `projects_test` passou a esperar só `park_bench` no catálogo real; `content_test` aceita os painéis `community` e `project:<id>` (obra existente e do mesmo mundo). Suíte inteira em `build/economy/etapa_20/suite/`: só os históricos de sempre falham (`onboarding_test` 4 erros iguais aos da 19, `finds_test` "missão pronta", `npc_lines_test` 4 erros iguais); `park_test` falhou uma vez ("sem espaço: não guarda", intermitente conhecido) e passou duas vezes na reexecução; `bench_test` falhou uma vez numa execução inicial (espera do Tiro) e passou nas nove execuções seguintes.

## 18/10/2026 — etapa 21: Jardim da Vila e Piquenique da Praça

1. **Números da tabela 07 E sem ajuste:** entrada 250 cada, fases e materiais conforme a tabela, prêmio XP 60. Nenhum valor de economia foi alterado; nenhum prêmio automático novo (só XP), então a guarda de conservação só ganhou as duas ações (`start_project`: moedas −entrada; `contribute_project`: itens −quantidade).
2. **Independência:** requisito `projects: [park_bench]` nas duas; o piquenique não exige o jardim e vice-versa; ambos serão necessários à Festa na etapa 22 (não são finais alternativos).
3. **Posição do piquenique:** a primeira posição (ao lado do banco) deixava o Tiro preso numa fresta e quebrou o `bench_test`; medida de novo, a única faixa de grama livre e larga o bastante da Praça fica a leste ([436, 168], `scale` 0,8, ponto de uso [436, 190]). Jardim na Vila: grama livre entre o mercado e as caixas ([243, 290]).
4. **Texto/UX:** a fileira de fases quebra linha; o chip de falta virou "Falta X: onde achar?" (360 px). Sem tutorial repetido: a personagem só fala o `pitch` antes de começar.
5. **Simulador (robô):** a fase `ph_projects` só existe em `until=projects`, para não mexer na linha de base da campanha. **Duas tentativas descartadas:** (a) busca sem escudo → o robô vendia/gastava os petiscos e picolés que a cesta esperava (referência 37,8 d, comercial e recuperação travados); (b) proteger a cadeia inteira desde o começo do plano → travava outras metas (a referência passou a travar em `bloblo_bigger`). Ficou o escudo só na busca (`pursue_item(..., true, 2)`).
6. **Cenários antes/depois (semente 1):** campanha (`until=campaign`) idêntica à etapa 20: reference 15,1 d, commercial 18,1 d, recovery 15,3 d, 90/90, 0 violações; leve 89/90 em 85,3 d (mesmo travamento em `nina_sewing`). Até as três obras: reference 17,8 d, recovery 18,8 d, leve 50,3 d (as obras só começam no dia 35 porque o ateliê abre tarde), commercial **não conclui o piquenique** em 42 d.
7. **Leitura do `commercial` (pendência para a etapa 23):** o perfil vende e entrega encomendas o tempo todo, e `ph_orders` consome petisco/picolé antes de `ph_projects` poder protegê-los; só uma das duas cestas sai. Parece artefato da política do robô (o jogo não bloqueia nada), mas não foi provado: a 23 deve revisar. Se um jogador comercial real perde ingredientes assim, a Cesta (duas receitas de 1080 s + petisco/picolé em dobro) é o gargalo. Ajustes candidatos, **não aplicados**: cesta 1 em vez de 2, ou piquenique sem petisco/picolé na fase 3.
8. **Esforço registrado para a 23:** 500 moedas + 43 unidades (jardim 25, piquenique 18) + ingredientes das cestas (8 petiscos, 8 picolés, 2 sucos); 28–35 entregas em 11–18 sessões com progresso; tabela em `docs/PROGRESSION.md`.
9. **Testes:** Suíte inteira em `build/economy/etapa_21/suite/` (64 testes + `progression_test` PASS, ~745 ciclos): só falham os históricos `onboarding_test` (4 erros), `finds_test` ("missão pronta") e `npc_lines_test`; `walks_test`, `park_test` e `world_selector_test` falharam uma vez sob carga e passaram sozinhos na reexecução (instabilidade conhecida de UI/temporização). Capturas antes/depois nas três resoluções em `build/screenshots/etapa21_antes|depois/<resolução>/` (25 telas por conjunto; o "antes" tira só as obras novas em memória).

## 18/10/2026 — etapa 22: Festa da Vila, Lenço e capítulos 10–12

1. **Números da tabela 07 E sem ajuste:** entrada 500, fases e materiais, XP 100 + coleção; capítulos 30/40/60; afetos 5/5/10. Nenhum valor de economia foi alterado.
2. **Obra ≠ contrato:** `festival_contract` continua o contrato comercial (mesmo id, missão `merchant_festival`); só o nome visível virou "Encomenda para eventos". A obra tem id `village_festival` e não compartilha entrega nem marco.
3. **Lenço:** recolorido do lenço vermelho (matiz +0,46) em todos os 52 quadros por pose + base + ícone; mesma máscara e âncoras (a 07 E permite combinar recursos do projeto). `overlay_anchors.json` intacto. Conferido em pé e dormindo nas três resoluções.
4. **Encontro da turma:** chave `gathering` no projeto; estado em `completed_at` + `cycles` (esquema 1, campo aditivo: a entrada em branco passou de 8 a 9 campos). Intervalo conta da **última** conclusão (festa ou ciclo anterior); `dev_advance_time` desloca esses instantes. Nome das funções `meeting_*`/`gather_project` porque `gathering_error` já era da Natureza. Ciclo e prêmio (`project_gather:<id>:<n>`) no mesmo salvamento.
5. **Saves existentes:** quem terminou o capítulo 9 passa ao 10 e as obras/usos das etapas 20–21 já contam; só as duas conversas (`talk:lais`, `talk:nina`) são `fresh`. Capítulos 10/11 pagam ao serem completos; nada de material novo.
6. **Cenários antes/depois (reference, semente 1, campanha):** 15,1 d / 90 missões → **21,1 d / 99 missões**, 0 violações. A diferença está nos dias 8→19: a Festa só abre com `stall_3` e 500 moedas (começou no dia 17). Até as quatro obras: 17,3 d (antes, três obras: 17,8 d). Os perfis light/commercial/recovery **não foram rodados** (política da rodada: o menor perfil que prova o critério); o pendente do commercial (piquenique) segue para a 23.
7. **Robô:** a fase `ph_projects` continua só em `until=projects`; na campanha as obras vêm como meta das missões (`pursue_project`). `use_project` entrou como ação permitida (sem efeito em moedas/itens).
8. **Testes ajustados por mudança de contrato (não por bug):** `journey_test` (depois do ateliê vem o capítulo 10), `world_life_test` (obra não começada não é obstáculo), `projects_test`, `content_test`. `progression_test` não foi executado (decisão do Vitor); registrar na 23/24 se a suíte final o exigir.
9. **Limite honesto:** a suíte inteira não foi repetida nesta etapa (política de testes da rodada); a regressão completa fica para a 24.


## 19/10/2026 — etapa 23: calibração (rodada mínima, em andamento)

1. **Nenhum número alterado.** Antes = depois em `projects.json`, `progression.json`, `quests.json`, `walks.json` e `config.json`.
2. **Pendência do commercial (etapa 21, item 7): resolvida sem ajuste.** Na campanha inteira o commercial conclui Banco, Jardim, Piquenique e Festa (dias 16/18/21/27) com 99/99. O travamento da 21 vinha de `until=projects`, onde só `ph_projects` roda e `ph_orders` gasta petisco/picolé antes de a obra protegê-los (política do robô, não regra do jogo). "Cesta 1 em vez de 2" e "piquenique sem petisco/picolé" NÃO foram aplicados.
3. **Pendência do light (`nina_sewing`): era rótulo.** O texto de gargalo vem de uma sessão antiga; `nina_sewing` é recebida no dia 67,3 junto da Festa (`shared_with`). O perfil termina em 98/99 porque `nina_blueberry` (opcional) exige o baú aberto e o perfil leve não tem `ph_others`. Política do robô mantida (não alterar para produzir PASS).
4. **Experimento descartado (hipótese de fita):** estendi `loot.guarantee` (dicionário ou lista, `until_claimed`) para garantir 1 fita na `park_loop` até `nina_sewing`. Light antes = depois (dia 67,3, mesmos bloqueios), reference idêntica (21,1 d). Fita não era o gargalo; mudança, teste e dado revertidos.
5. **Ritmo:** reference 15,1 → 21,1 d (etapa 22). Fim 9 em 3,9 h ativas (dentro de 3–6 h), Festa +6,1 h (acima de 2–4 h pela métrica de sessão, que conta o orçamento de 10 min mesmo ocioso). O gargalo calendário é a banca 3 (dia 17,1 no reference). Proposta (não aplicada, aguarda sessão real): contratos da banca 3 de 15 → 12 (−20%); se necessário, 1.500 → 1.200 moedas.
6. **Encontro da turma:** o robô não o usa; a guarda de conservação não precisou do prêmio `project_gather:*`.
7. **Não cumprido ainda:** sementes 2–10, baseline de 35 execuções, relatório de progresso por visita, sessão no celular. Etapa 23 permanece **em andamento**; ver RESULTADOS.md.

## 19/10/2026 — etapa 24: fechamento e banca 3 (15 → 12 contratos)

1. **Decisão do Vitor:** encurtar a Festa. Aplicada só a primeira alavanca do protocolo: `stall_3.requirements.stats.contracts` 15 → 12 (`progression.json`) e a missão `merchant_clients` (`quests.json`: alvo 12, textos "doze entregas"/"Somar 12 contratos da sua banca"). `customer_tiers` (3/8/18 por personagem) não usa o número 15 e não mudou; custo 1.500 e três tipos mantidos. Tabela 02 atualizada (banca 3 = doze e três tipos).
2. **Antes → depois** (sementes 1–3, mesmo código): reference Festa dia 19,3 → 18,3 (mediana), Festa − fim 9 de 6,1 h → 5,6 h; commercial Festa dia 27,8 / 26,3 / 25,1 → 24,1 / 23,8 / 22,3. Ganho de ~1 dia; a faixa "+2–4 h" segue falha pela métrica de sessão. Resultado: **falha aceita e registrada**; a espera de ~11 dias de calendário será julgada no celular. Segunda alavanca (1.500 → 1.200) não aplicada.
3. **Testes ajustados:** `customers_test` (11/2 falha, 12/2 falha, 12/3 passa), `market_test` (12 contratos; total após o contrato final 13). `expansion_test` (ampliação `_5` com 12 contratos) não depende do valor.
4. **Política do robô inalterada.** commercial s2/s3 e todo o light param em 98/99 por `nina_blueberry` (opcional); ver RESULTADOS.
5. **Sem reset de save, sem `SAVE_VERSION` novo.** Quem já comprou a banca 3 mantém; quem estava entre 12 e 15 contratos passa a poder comprar.
