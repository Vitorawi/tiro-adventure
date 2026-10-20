# Simulador de economia (etapa 01)

Criado em **17/10/2026** pela etapa 01. Mede **sessões simuladas usando as regras reais**: o `GameState`, o `Database`, os requisitos e o `to_dict/from_dict` do jogo, com um relógio injetável. O que sai daqui é **SIMULADO** (agente idealizado); não é a estimativa teórica do auditor estático (`BASELINE.md`, `tools/economy_audit.py`) nem a experiência de uma pessoa. Ajustes de número da R1 só podem ser julgados com este simulador depois da etapa 02 em diante; a etapa 01 não mudou nenhuma regra do jogo.

## Arquivos

| Arquivo | Papel |
|---|---|
| `game/tests/economy_simulation.gd` | Runner headless (`SceneTree`). Lê opções, roda uma execução, imprime `ECONOMY SIM: ...` e grava `summary.json` + `ledger.jsonl`. **Não é teste.** |
| `tools/economy_simulate.ps1` | Invocador: perfil, semente(s), horizonte, saída, paralelismo e tempo máximo (mata o Godot se travar). |
| `game/tests/helpers/economy_clock.gd` | Relógio injetável: estende `game_state.gd` e só troca a fonte de `now()` e do fuso (`_local_time`). Mesmo recurso de `tests/friend_clock.gd`; o código de produção não mudou. |
| `game/tests/helpers/economy_progress.gd` | Cache de consultas puras de capítulos/missões, usado apenas no simulador; equivalência com `ProgressionState` conferida pelo teste. |
| `game/tests/helpers/economy_sim.gd` | Motor: agenda, tempo de toque, execução das ações, ledger, guardas, marcos e resumo. |
| `game/tests/helpers/economy_bot.gd` | Política do jogador simulado (somente leitura; devolve a próxima ação). |
| `game/tests/helpers/economy_bad_bot.gd` | Planejador defeituoso de propósito, só para provar a guarda de pureza. |
| `game/tests/economy_sim_test.gd` | Teste (entra no `test_all.ps1`). |
| `tools/economy_compare.py` + `economy_compare_selftest.py` | Relatório local (tabelas, marcos, gargalos, gráficos SVG) e comparação entre duas revisões. |
| `tools/run_godot_test.ps1` | Roda qualquer teste headless com tempo máximo e guarda o log (o Godot não encerra sozinho se o script travar). |

## Como rodar

```powershell
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# uma execução (saída em build/economy/etapa_01/reference_s1/)
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Profile reference -Seed 1 -Days 40 -Until campaign
# dez sementes, quatro em paralelo, ledger completo
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Profile light -Seed 1..10 -Days 120 -Until campaign -Parallel 4 -Ledger full
# pior caso de raro (chance 0, garantia preservada) e reload a cada sessão
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Profile reference -Seed 1 -Rare worst -Reload session
# relatório de todas as pastas e, opcionalmente, comparação com outra revisão
py -X utf8 -I tools\economy_compare.py --in build\economy\etapa_01 [--base build\economy\etapa_XX]
# teste do simulador
powershell -ExecutionPolicy Bypass -File tools\run_godot_test.ps1 economy_sim_test
```

Perfis (`-Profile`): `reference`, `light`, `active`, `affective`, `commercial`, `recovery` (tabela B de `04_SIMULACAO_E_ACEITE.md`). `-Until campaign` encerra quando as 81 missões foram recebidas; sem isso vale `-Days`. `-StallDays`/`-StallActiveMin` encerram uma execução sem avanço de história (estado `stalled`, com o gargalo no resumo).

## Contrato do que é medido

* **Tempo.** Toque 3 s; +2 s ao trocar de painel/mundo (`ctx`); arrasto: 3 s no primeiro alvo e 1 s em cada alvo seguinte. O relógio anda **antes** da ação, então o timer nasce no fim do gesto. Esperar um timer dentro da sessão também gasta tempo da sessão (`waits_by_reason`).
* **Agenda.** Sessão de abertura de 20 min no dia 0 às ~12h locais (desvio por semente), depois: referência/afetivo/comercial/recuperação 3×10 min (08h, 14h, 20h); leve 1×10 min (19h); ativo 3 blocos de 2 h. Desvio de ±15 min por sessão (semente). **A sessão fecha no orçamento mesmo com ações disponíveis**, e nada age durante a ausência (só o relógio anda). O app "abre" com `update_friend_visits` e as mesmas atualizações que o `Timer` de 1 s do `GameState` faz.
* **Sem atalhos.** `unlimited_storage = false`, nada de `dev_*`, `ready_at`, `owned`, nível ou saldo forçados. O jogador simulado só chama as ações públicas listadas em `ALLOWED` (lista branca). Fixtures de regras isoladas (testes) podem preparar dados, a campanha nunca.
* **Semente.** Muda o início do dia 0 (0–30 min depois das 12h locais) e o desvio de cada sessão (±15 min); os sorteios do jogo continuam deterministas pelos timestamps, então o desvio é o que "re-sorteia" desejos, achados e passeios entre sementes. O planejador não usa sorteio algum (nem lê o que o RNG do jogo vai dar: nada de `walk_loot()`/`find_reward()`), logo o perfil comercial também não olha sorte futura. `-Rare worst` põe chance 0 no raro dos passeios (e no lendário) e preserva a garantia (`pity`).
* **Política.** Um objetivo reservado (primeiro passo ativo não recebido, na ordem de linhas do perfil); o que ele precisa fica protegido. As outras linhas usam só o que sobra. Cuidado quando útil (necessidade baixa) e para desejos/missões; produção elegível (plantar a cultura de melhor valor para a próxima volta, cozinhar só com margem positiva, coletar, passear); venda do excedente quando falta moeda para a próxima compra, o depósito aperta ou a sessão vai fechar; "preparar saída" no fim da sessão (trabalhos longos, Tiro dorme). Recuperação faz de propósito o erro do sofá e a venda de ingredientes.

## Ledger e resumo

`ledger.jsonl` (uma linha por ação/espera/fim de sessão): tempo relativo, dia, sessão, tempo ativo acumulado, ação, motivo (`why`), meta, argumentos, custo em s, sucesso/erro, saldo antes/depois, variação de itens, depósitos usados/limite, fila (nos modos `full` e `compact`, que agora preservam os mesmos campos de auditoria), navegação e, nos erros, as ações legais seguintes (`available_actions`). `summary.json`: fim, tempos, marcos, fluxo de moedas (únicas × recorrentes × gastos), fluxo de itens, esperas por motivo, bloqueios, erros, prontos ao fechar, itens fora de depósito limitado, tempos de cada missão, série diária, guardas e desempenho do próprio simulador (`perf_ms`).

## Guardas (violação = execução marcada e código de saída 1)

| Guarda | O que detecta |
|---|---|
| `unlimited_storage` | atalho de estoque ligado |
| `mutacao_fora_de_acao` | qualquer mudança de moedas/itens/posses/timers entre duas ações (por exemplo `dev_add_coins`) |
| `planejador_alterou_estado` | `plan()` alterou o estado (resumo comparado antes/depois) |
| `ready_at_forcado`, `timer_fora_da_regra` | `ready_at` de canteiro/estação/Natureza/passeio que não nasceu de plantar/regar/cozinhar/coletar/passear, ou fora da fórmula |
| `conservacao`, `falha_alterou_estado`, `moeda_negativa`, `inventario_negativo` | cada ação confere moedas e itens contra o efeito declarado pelas regras (mais prêmios de nível, vínculo e capítulo); falha não pode mexer em nada |
| `acao_nao_permitida`, `acao_fora_da_sessao` | ação fora da lista branca (inclui `dev_*`) ou com o app fechado |

## Bloqueio do jogo × falha de política

Cada busca do jogador simulado que não acha caminho registra um motivo. `jogo:*` registra requisitos ou limites encontrados (fonte, sorte, capítulo/atributo/vínculo, depósito); `politica:*` (sem caminho achado, recursão, rota sem tratamento) = o agente não soube fazer algo que o jogo permite. São ocorrências da busca, inclusive em alternativas descartadas: não provam que a campanha está travada. Ao parar sem terminar, conferir o estado final, a meta, o ledger e o último motivo (`last_sessions`).

## Limites conhecidos

* Agente idealizado: não erra toque, não demora a decidir e conhece tudo. Calibrar com toque manual (etapa 23).
* O ledger registra a **próxima opção legal** do jogo só nas falhas; nas demais, a próxima linha já é a próxima ação escolhida.
* O tempo de execução depende do perfil, da máquina e do paralelismo; `perf_ms` registra o custo observado. O cache de consultas de progressão é exclusivo dos testes e não altera as regras de produção.
* Sorteios dependem do instante absoluto (`now()`): semente diferente muda o início do dia 0, mas não "re-sorteia" tudo.

## Verificação da retomada — 17/10/2026

Codex retomou a sessão `b198f85a-a84c-50e8-a0f5-55550e18013f` do Claude Code, interrompida pelo limite da sessão. O código local já continha a correção da política que permite concluir as sementes comerciais 2 e 3; as saídas antigas `*_base`/`*_trace*` pertencem a versões anteriores do planejador e foram preservadas apenas para diagnóstico. Não misturar essas tentativas com a linha de base final.

Correções finais: `ledger` conserva saldo anterior e fila também com `compact`; o invocador de baseline usa `full`; o relatório inclui o sufixo `_raro0` ao filtrar um lote e separa esse cenário das medianas de sorte normal. Os processos headless auxiliares abrem ocultos. Nenhum JSON de balanceamento, regra de produção ou formato de save foi alterado.

Evidências finais: `build/economy/etapa_01/*_validada*/`, `validada_run.txt`, `relatorio_validada/report.md` e `evidence_check.json` (conferência independente dos ledgers). **35/35 campanhas completas, 81/81 missões cada, 107.653 ações, zero violações.** A conferência externa verificou o conjunto exato de perfis/sementes da seção B da 04, campos de auditoria em cada ação, continuidade dos saldos, soma das fontes/gastos e os dois erros intencionais nas três campanhas de recuperação.

| Perfil | Sementes | Dias (mín/mediana/máx) | Minutos de ações (mín/mediana/máx) |
|---|---:|---|---|
| Referência | 10 | 6,3 / 7,3 / 7,3 | 214,7 / 243,6 / 244,1 |
| Leve | 10 | 27,3 / 28,8 / 32,3 | 290,4 / 305,6 / 340,5 |
| Ativo | 3 | 0,9 / 1,1 / 1,1 | 374,3 / 494,7 / 494,9 |
| Afetivo | 3 | 7,1 / 7,8 / 8,8 | 233,6 / 253,9 / 283,3 |
| Comercial | 3 | 7,3 / 7,3 / 7,8 | 242,8 / 243,9 / 253,2 |
| Recuperação | 3 | 6,3 / 6,8 / 7,8 | 214,3 / 224,1 / 253,7 |
| Referência, raro zero | 3 | 7,1 / 7,3 / 7,3 | 234,2 / 243,6 / 244,2 |

Uma campanha referência semente 1 foi repetida inteira com o mesmo ledger **byte a byte** (`reference_s1_reprodutivel` versus `reference_s1_validada`; SHA-256 `f5add6a7b68a910cd271e10ff5345be454dcf1b04d11f9571c08d9ee77a391ee`). O manifesto dos scripts fica em `final_source_manifest.json`. `end.days` arredondado e os relatórios com uma casa decimal podem diferir da linha impressa pelo Godot no arredondamento final.

Leitura econômica, ainda **SIMULADA**: no perfil referência, primeira colheita 1,8 min de ações, desejo 1,3, achado 2,4, passeio 11,6–11,7; fogão 3,9–4,0 (antes da faixa R1 de 15–30). Fim do capítulo 9 em 102,5–156,4 min de ações, antes do alvo R1 de 3–6 h; terminar todas as linhas leva mais tempo. Os perfis têm prioridades distintas, portanto maior intensidade não garante menor tempo de ações. A compra dos 48 upgrades não é o critério de fim: os perfis podem concluir a história sem comprar todas as melhorias opcionais. As ocorrências transitórias de requisitos/recursão no relatório não são travas finais; nenhuma execução do lote final ficou em `stalled`. Não ajustar números nesta etapa para alcançar as faixas R1.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/economy_baseline.ps1 -Tag validada -Parallel 4
py -X utf8 -I tools/economy_compare.py --in build/economy/etapa_01 --tag validada --out build/economy/etapa_01/relatorio_validada
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_godot_test.ps1 economy_sim_test -Log build/economy/etapa_01/retomada_test_final.log
```

Testes focados executados: `economy_sim_test` PASS (24 ações × GameState direto, fila sequencial/estoque cheio, guardas, agenda 1×10/3×10, semente e reload); `economy_audit_selftest` e `economy_compare_selftest` PASS; `content_test`, `tasks_test`, `storage_test`, `farm_test` e `dev_tools_test` (dev e prod) PASS. Logs `retomada_*` no mesmo diretório. Os avisos `GUARDA` no stderr do teste do simulador são as violações injetadas de propósito pelas fixtures.

Limitação de regressão: `progression_test` antigo excedeu o tempo máximo de **3 minutos**, encerrado pelo invocador após registrar os ciclos 0 e 100; **não é PASS**. A etapa 00 já havia documentado falha desse bot em `merchant_festival`. A retomada não alterou esse teste nem o usou como evidência de ritmo. Sem suíte completa, commit, export, captura visual ou teste no celular nesta etapa de ferramentas; sem publicação. A etapa 02 continua pendente.

## O robô sabe crescer — Tiro no centro, etapa 11 (19/10/2026)

Com a história conduzida pelo crescimento (a última missão dos capítulos 1, 3, 6, 9 e 12 é `growth: <fase>`), o jogador simulado precisou aprender a cuidar do Tiro até ele crescer, senão a campanha travava no fim do capítulo 1. Tudo pelas **mesmas ações do `GameState`**, sem `dev_*`:

* `economy_bot.gd`: `pursue_growth(fase)` (objetivo `growth` em `pursue_goal` e requisito `growth` em `pursue_reqs`, o que cobre truques e passeios longos) resolve cada requisito da próxima fase — `owned`/`quest`/`project` pelos caminhos de sempre, `deliver` (entrega o item-chave com `deliver_growth`; item `keepsake` sem receita vem do prêmio da missão que o dá), `feed` (a refeição da fase, ou qualquer comida), `stat` (`walk` e `shampoo_bath`, que espera o Tiro sujar antes do banho com xampu), `collection` (lacinho pela costura) e `pillars` (banho com a recarga de 2 h, comida da fase, brincar e carinho nos momentos em que dão pontos) — e, com tudo pronto, aperta **Crescer** (`grow`).
* `economy_sim.gd`: ações novas `grow` e `deliver_growth` (esta declara o item consumido) e `bathe` com `shampoo` (declara o xampu consumido); `grow` é conferida como efeito não exato porque o presente da fase pode virar recibo com a mochila cheia.
* `economy_sim_test`: nova parte 9 — Dentinhos, Mocinho e Azul e Dourado crescem pelo robô em estados de fixture (argolinha pela missão da vovó, três refeições, escova, dois banhos com xampu, medalhinha), sem violação de guarda/conservação, e uma campanha do zero de dois dias passa do Filhotinho e abre o capítulo 2. Os pilares da fixture usam `dev_add_pillar` (só ali).
* Diagnóstico (não é medida de ritmo, que fica para a etapa 17): semente 1, perfil referência, 14 dias → Aventureiro e capítulo 9; 40 dias → Mocinho e capítulo 12 (falta o Azul e Dourado, que espera os pilares em 8), zero violações.

Limite conhecido: o ritmo de crescimento do robô (dias por fase) não foi calibrado; é exatamente o que a etapa 17 mede.

## Campos de crescimento — Tiro no centro, etapa 17 (19/10/2026)

`summary.json` ganhou `growth_days` (`{fase: {day, active_min}}`, dia simulado em que cada fase começou), `chapter_coins` (`{capítulo: {coins, day}}`, moedas ao fechar cada capítulo) e `end.phase`, `end.silk`, `end.pillars` (`{pilar: {level, points}}`). `tools/economy_compare.py` escreve a seção "4b. Fases do Tiro × dia" contra os alvos da 02 E. Resultado da única execução `-Quick`: `docs/plans/tiro/RESULTADOS.md`.
