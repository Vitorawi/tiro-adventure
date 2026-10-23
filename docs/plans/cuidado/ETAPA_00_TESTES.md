# Etapa 00 — Circuito de testes em quatro níveis

**Estado: concluída (23/10/2026, Codex).** Pré-requisito: nenhum. Nada muda para o jogador.

## Objetivo

Trocar "rodar tudo" por ciclos que façam sentido para o que a etapa mexe: `rapido` ≤ 1 min, `etapa` ≤ 5 min,
`portao` ≤ 8 min em paralelo e `campanha` só no fim. Ver [01](01_REGRAS_E_TESTES.md).

## Leitura

[README](README.md), [00](00_VISAO.md), [01](01_REGRAS_E_TESTES.md), `tools/test_all.ps1`,
`tools/run_godot_test.ps1`, `docs/plans/tiro/MAPA_DE_TESTES.md`, `game/scripts/util/build_info.gd`,
`game/autoload/save_manager.gd`.

## Antes de começar

`git status`. Se houver trabalho local de outra tarefa com testes falhando (em 23/10/2026 o último CSV tinha
`farm_market_label_test`, `world_view_test`, `balloon_test`, `market_test` e `content_test` em FAIL, junto com
alterações não commitadas do Codex), **não mexa nelas**: rode `tools\test_all.ps1 -Only <esses>` uma vez, e, se
ainda falharem, avise o Vitor e pare. A linha de base precisa partir de um estado conhecido.

## Entrega

1. **Saves isolados por teste.** `BuildInfo.save_path()` (e o caminho de `settings`) usam
   `OS.get_environment("TIRO_TEST_TAG")` quando não vazio **e** `BuildInfo.is_dev()`: `user://test_<tag>/save_dev.json`
   (pasta criada se faltar). Sem a variável, nada muda. Conferir com `grep "user://"` que só `save_manager.gd` e
   `build_info.gd` gravam em `user://`.
2. **`tools/test_areas.json`** a partir da tabela do [01](01_REGRAS_E_TESTES.md#áreas-iniciais-a-00-transforma-em-toolstest_areasjson)
   e do mapa do plano Tiro: `{"always": [...], "broad": [...], "campaign": [...], "areas": {"<id>": {"paths": [...],
   "tests": [...]}}}`. Todo teste do `$Suite` atual pertence a pelo menos uma área ou à campanha; o script
   recusa rodar se não for assim (teste órfão = erro, com o nome).
3. **`tools/test.ps1`** (novo; `test_all.ps1` vira só um atalho para `-Level portao` + `campanha`, para não quebrar
   o costume):
   - `-Level rapido|etapa|portao|campanha`, `-Tests "a,b"`, `-Areas "x,y"`, `-Since <ref>`, `-Jobs N` (padrão 3 no
     portão, 1 nos outros), `-KeepGoing`, `-DryRun` (só lista e estima).
   - `rapido`: `godot --headless --path game --import` só se houver classe nova sem cache, depois checagem de
     scripts (`--quit-after`), `content_test`, `texts_test`.
   - `etapa`: `rapido` + `-Tests` + áreas dos arquivos mudados (`git status --porcelain` ou `git diff --name-only
     <Since>`) + `-Areas`. Arquivos `broad` não escolhem área: o script avisa "game_state.gd mudou: passe -Areas".
   - `portao`: todos os testes das áreas, sem `campaign`, em `-Jobs` processos com `TIRO_TEST_TAG` diferente.
   - `campanha`: `progression_test`, `economy_sim_test`, autotestes Python e `economy_simulate.ps1 -Quick`.
   - Antes de rodar: imprime a lista e a estimativa pelos tempos de `build/test_logs/times.csv` (acumulado do último
     tempo medido de cada teste). Acima do orçamento do nível, avisa (não bloqueia).
   - Saída: `build/test_logs/last_run.csv` (teste, segundos, resultado, nível) e o total.
4. **Falhas históricas resolvidas.** Para `onboarding_test`, `finds_test`, `npc_lines_test`, `petshop_test`,
   `park_test`, `ui_style_test` (e `progression_test` se ainda falhar): corrigir o teste (asserção desatualizada,
   recurso preso na saída) ou, se testa algo que não existe mais, apagar a parte. Registrar o que foi feito em
   cada um. Depois desta etapa **não há lista de falhas aceitas**.
5. **Testes de save antigo removidos.** Saves são sempre zerados: apagar casos que montam save de versão anterior
   ou chamam `EconomyMigration` (ex.: partes de `saves_test`, `economy_transactions_test`, "piso legado" em
   `silo_test`/`fridge_test`/`warehouse_test`/`nature_routes_test`, "saves antigos" em `journey_test`). O código de
   migração **fica** (ver [DECISOES](DECISOES.md)); só os testes saem.
6. **Os mais lentos.** Para os testes acima de 30 s (`tray_test`, `bench_test`, `station_tray_test`, `animals_test`,
   `nature_test`, `garden_picnic_test`): procurar `await create_timer`/esperas reais que possam virar relógio
   injetável ou quadros mínimos. Só aplicar o que for simples e seguro; registrar o antes/depois.
7. Documentação: seção **Comandos** do `CLAUDE.md` e `AGENTS.md` (idênticos) com os quatro níveis; o
   `docs/plans/tiro/MAPA_DE_TESTES.md` ganha no topo "substituído por `tools/test_areas.json`".

## Teste da etapa

- `tools\test.ps1 -Level rapido` (≤ 1 min).
- `tools\test.ps1 -Level etapa -Areas wishes -DryRun` lista `wishes_test`, `bond_test` + sempre.
- **Isolamento:** dois testes que gravam save rodando ao mesmo tempo (`-Level etapa -Tests "saves_test,pet_care_test" -Jobs 2`) passam.
- **Linha de base nova:** `-Level portao` uma vez (registrar duração com `-Jobs 1` e `-Jobs 3`, se der tempo os
  dois) e `-Level campanha` **uma vez** (registrar duração; é a referência antes do plano mexer no ritmo).

## Para passar para a próxima

- [x] `TIRO_TEST_TAG` isola saves; dois testes em paralelo passam.
- [x] `test_areas.json` sem teste órfão; `test.ps1` com os quatro níveis e `-DryRun`.
- [x] Nenhuma falha aceita: portão verde (87/87).
- [x] Testes de save antigo removidos.
- [x] Tempos do portão (paralelo) e da campanha registrados aqui; progressão validada em reexecução focada autorizada.
- [x] CLAUDE.md/AGENTS.md (Comandos) atualizados.

## Fora desta etapa

Mudar regra do jogo, robô do simulador, código de migração.

## Resultado

Implementados `tools/test.ps1`, `tools/test_worker.ps1` e `tools/test_areas.json`; `test_all.ps1` é o atalho de portão + campanha. Saves e settings dev recebem pasta por `TIRO_TEST_TAG`, inclusive fixtures/capturas com caminho descartável. Produção ignora a tag. `CLAUDE.md` e `AGENTS.md` sincronizados.

Pré-condição: cinco testes locais repetidos uma vez, todos PASS em 129,8 s (2,2 min): `farm_market_label_test`, `world_view_test`, `balloon_test`, `market_test`, `content_test`. Evidência: `build/test_logs/cuidado00/preflight.csv` e `preflight.log`. Trabalho local de ActionTray/receitas/Vender Colheita preservado.

Falhas históricas:

- `onboarding_test`: reconhece `sold:village`, vende excedente do silo, usa semente fixa e relógio injetável; retirados tetos de espera do protótipo pré-R1 (ver DECISOES), mantendo prazos das primeiras vezes e passeio/raro. PASS focado.
- `finds_test`: completa também a apresentação da venda de excedentes que antecede a missão do faro. PASS focado.
- `npc_lines_test`: primeira venda ao Feirante, visita à Vila e requisitos atuais de capítulos; cenário do Guia separado do teste do começo do Feirante, sem exigir acesso antes do capítulo 5; armazenamento ilimitado só na fixture da coleta. PASS na seleção final por áreas.
- `petshop_test`: passou na reprodução inicial; saiu o caso sem `equipped`. A execução por áreas revelou estoque residual da costura lotando o baú em sorteios de passeio; a fixture limpa o inventário antes dos passeios e fixa a semente. Portão PASS.
- `park_test`: ordem Casa/Sítio/Vila/Praça/Natureza atualizada; painel emitido sem consumidor liberado; tolerância de meia diagonal da célula ao verificar destino da Pipoca. Semente fixa, portão PASS sem erro de saída.
- `ui_style_test`: libera todos os botões e a pílula temporários criados sem pai em `_kit`. PASS sem erro de saída; filtro de erros continua estrito.

Removidos casos de versões/campos antigos em transações, saves, depósitos, Natureza, jornada, crescimento, cuidados, tarefas, animais, obras, álbum, truques, roupas e retorno de passeio. Snapshots gerados pelas ações atuais e roundtrips atuais continuam cobertos. Nenhum código de migração ou robô da campanha foi alterado.

Circuito: `rapido` PASS em 19,5 s (script/content/texts); autoteste do seletor PASS (seleção explícita/automática, arquivo amplo, áreas/testes desconhecidos, órfão, separação portão/campanha). `-Areas wishes -DryRun` inclui `wishes_test`/`bond_test` + sempre; neste checkout soma também as áreas das outras mudanças locais, como contratado.

Isolamento/seleção por áreas: comando exato `tools\test.ps1 -Level etapa -Tests "saves_test,pet_care_test" -Jobs 2 -KeepGoing`. As duas provas de save passaram com sobreposição de processos e caminhos próprios; a seleção automática totalizou 79 testes por incluir as mudanças locais de outras tarefas e desta infraestrutura. Rodagem exploratória de 702,8 s: 72 PASS + sete falhas de fixture (`tasks`, `tray`, `world_selector`, `bench`, `dev_tools`, `park`, `petshop`). Todas foram corrigidas e repetidas individualmente PASS; nenhum FAIL é aceito na linha de base final. `tasks_test` teve erro de delimitação ao remover um bloco antigo, corrigido antes do portão. Evidência em `build/test_logs/r20261023_010831_033c9283/results.csv` e logs focados em `build/test_logs/cuidado00/`.

**Portão final:** `tools\test.ps1 -Level portao -Jobs 3 -KeepGoing`, uma execução: **87/87 PASS**, **506,2 s (8 min 26 s)**, sem falha aceita. Meta de 8 min excedida em 26,2 s; aviso registrado, como previsto na regra do runner. Evidência: `build/test_logs/r20261023_012135_1723620b/results.csv` e `build/test_logs/cuidado00/portao.log`. Não foi repetido em `-Jobs 1`; a rodada serial é opcional e não foi medida.

**Campanha única:** `tools\test.ps1 -Level campanha -KeepGoing`. A fixture de vendas do `progression_test` foi atualizada antes de iniciar (`world_id = village`). Durante a execução, outra inspeção identificou a visita ao Álbum ausente: no ciclo 400 o único passo pendente era `lais_album`; o teste cobra as 110 missões, mas só simulava abrir Mochila e Vila. A tentativa foi interrompida em **526,3 s** para evitar rodar até 1.500 ciclos sem possibilidade de fechar. O runner registra FAIL, não PASS. A fixture atual já chama `note_album_section("story")` quando a missão está disponível; parse PASS, porém a execução iniciada conservava a versão anterior.

Na tentativa inicial foi solicitada autorização ao Vitor para repetir **só** `progression_test`, mantendo o Quick em execução única. O bloqueio foi superado pela autorização e pelo PASS registrados no fechamento abaixo. Robô/driver do simulador preservados.


### Tempos dos testes mais lentos

A coluna anterior é a referência histórica do `MAPA_DE_TESTES.md` (19/10, serial); a nova é medida neste portão (23/10, três processos). Há casos de teste e contenção de CPU diferentes; não é comparação controlada de desempenho.

| Teste | Referência anterior (s) | Portão atual (s) | Inspeção/ajuste |
|---|---:|---:|---|
| `tray_test` | ~49 | 91.3 | Ir aguarda a bandeja com prazo máximo; espera fixa de 0,3 s mantida porque envolve o Sheet. |
| `bench_test` | ~42 | 41.5 | Faro isolado na fixture; mantém chegada real; retira 12 s redundantes depois da segunda interação. |
| `station_tray_test` | ~42 | 156.4 | Arquivo local protegido; esperas inspecionadas, nenhuma alterada. |
| `animals_test` | ~40 | 61.9 | Esperas de layout substituídas por seis quadros; viagens de 1,2 s preservadas. |
| `nature_test` | ~39 | 56.5 | Esperas curtas de layout substituídas por seis quadros; animações e viagens longas preservadas. |
| `garden_picnic_test` | ~31 | 41.6 | Esperas de layout substituídas por seis quadros; viagens de 3 s preservadas. |

### Tentativa inicial e bloqueio histórico

Campanha única encerrada em **974,7 s (16 min 15 s)**, com **5 PASS e 1 FAIL/interrompido**. Esse total inclui a tentativa interrompida de progressão; **não é uma linha de base verde nem a duração de uma campanha completa validada do progression_test**. CSV: `build/test_logs/r20261023_013037_13609c8b/results.csv`; log: `build/test_logs/cuidado00/campanha.log`.

| Componente | Tempo (s) | Resultado |
|---|---:|---|
| `progression_test` | 526,3 | Interrompido no ciclo 400: só `lais_album` pendente; runner registra FAIL. Fixture corrigida, parse PASS, reexecução pendente. |
| `economy_sim_test` | 91,0 | PASS |
| `economy_audit_selftest` | 1,8 | PASS |
| `economy_compare_selftest` | 0,9 | PASS |
| `economy_quick` | 345,9 | PASS, execução única |
| `test_circuit_selftest` | 7,9 | PASS |

Quick **SIMULADO**: reference, semente 1, campanha em **40,35 dias**, **110/110 missões**, adulto, capítulo 13 e **zero violações de guarda**. Dias das fases: Filhotinho 0,00; Dentinhos 0,01; Aventureiro 2,33; Mocinho 24,08; adulto 39,08. Nenhum ajuste de ritmo. Evidência: `build/economy/cuidado00_r20261023_013037_13609c8b_economy_quick/reference_s1/summary.json` (sem erro no motor).

### Fechamento validado

Vitor autorizou a reexecução focada ("Vai testando aí entao"). Executado somente `progression_test`, com `TIRO_TEST_TAG=cuidado00_progression_final_20261023`, pelo `tools/run_godot_test.ps1`, limite de 40 min. **PASS: 767 ciclos, 64 aquisições e 110 missões; exit 0, stderr vazio.** Intervalo entre criação e última escrita do log: **959,3 s (aproximadamente 16 min)**, de 01:51:59 a 02:07:59 em 23/10/2026. Esse intervalo é uma aproximação pelo log, não medição do cronômetro do circuito. Evidência: `build/test_logs/cuidado00/progression_final.log` e `.log.err`.

Os seis componentes da campanha estão validados: cinco na rodada original e progressão nesta reexecução autorizada. A soma dos tempos individuais válidos é aproximadamente **1.406,8 s (23 min 27 s)**; não houve uma segunda campanha completa e esse total não inclui overhead entre processos. A tentativa interrompida permanece registrada acima e no CSV original como FAIL histórico. Portão e Quick não repetidos, nenhuma falha remanescente aceita. **Etapa 00 concluída.** A sessão **Cuidado — Etapa 01** já foi criada, no mesmo projeto local e com Codex 6.1, por autorização do Vitor; a implementação da 01 continua para aquela sessão.

Verificação final: `git diff --check` sem erros; AGENTS.md/CLAUDE.md idênticos. Sem commit, push, publicação, migração nova, alteração do robô do simulador ou do trabalho local protegido.
