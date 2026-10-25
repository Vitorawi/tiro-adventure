# Etapa 01 — Linha de base e testes estáveis

> Tamanho: médio. Depende de: 00 (plano). Próxima: 02.
> Itens da revisão: **17** (testes instáveis `world_pin_test`/`world_life_test`) e **33** (fixtures
> enganosas `g01`/`t03` do tour).
> Resultado que o Vitor vê: nada no jogo muda. O plano ganha um ponto de partida medido (capturas e tempo
> de quadro "antes") e dois testes que deixam de falhar ao acaso, para que todo portão seguinte seja
> confiável.

## 1. Objetivo
1. Registrar a **linha de base** do plano: tour completo nas três resoluções e medição de quadro no Sítio.
2. Criar o mecanismo de captura por etapa (`--aj-NN-only`) que todas as outras etapas usam.
3. Deixar `world_pin_test` e `world_life_test` **10/10 PASS** rodando em paralelo, sem tirar nenhuma
   garantia.
4. Fazer `g01_tasks_ready_many` e `t03_growth_ready` mostrarem o estado que o nome promete.

## 2. Ler antes
`REVISAO_OPUS.md` itens 17 e 33, e o item 4 (medição); `04_REGRAS_E_TESTES.md` §D (capturas), §E (testes) e
§F (toque real); `docs/plans/interface2/RESULTADOS.md` (como a etapa 12 mediu desempenho e quais números
saíram: 28,3 ms de média, picos de 150 ms).

## 3. Arquivos
| Arquivo | Mudança |
|---|---|
| `game/tests/ui_tour.gd` | bloco `--aj-01-only` + o padrão dos blocos `--aj-NN-only`; fixtures `g01`/`t03` |
| `game/tests/world_pin_test.gd` | auditoria sem NPCs/Tiro/montinho/balões e com vários pontos por zona |
| `game/tests/world_life_test.gd` | `before` lido depois da troca de tela; relógio fixo; esperas por condição |
| `docs/plans/interface2_ajustes/README.md` | registro (números da linha de base) |

Nenhum arquivo fora de `game/tests/` e dos docs muda nesta etapa.

## 4. Como está hoje (estado esperado ao começar)
- `ui_tour.gd` (≈1.300 linhas) aceita `--out=<pasta>` e recortes `--i2-01-only` … `--i2-11-only`
  (procure `OS.get_cmdline_user_args()` perto da linha 320). Cada bloco chama funções `_i2_NN_shots()`.
- `world_pin_test` (≈24 s) às vezes falha com `SEM CAMINHO` em `place:friends` na Praça.
  Causa provável (revisão, item 17): a auditoria `_audit` toca a zona `friends` só no **centro** do polígono;
  antes das zonas, `_handle_tap` testa montinho do faro, balões e **NPCs** (Nina, Pipoca, cachorro visitante
  escolhido pelo bloco de 3 h do relógio real e andando perto de `points.friend_1`).
- `world_life_test` (≈31 s) às vezes falha com "Não reage em mapa oculto". Causa provável: `before` é lido
  **antes** de `set_sleeping(false)`, que roda com a Vila visível e dispara eventos reais (álbum por horário,
  desejos, `world_activity`) que mudam `last_reaction`; depende do relógio de parede. `create_timer(0.3)` com
  "andou mais de 1 px" também é sensível à carga do portão (3 processos).
- `g01_tasks_ready_many` e `t03_growth_ready` montam um estado que não mostra "muitas missões prontas" nem
  "todos os requisitos feitos".
- Roteiro de toque da 12: `build/touch_steps_i2_12.json` (existe). `tools/touch_test.ps1` aceita
  `perf_start/perf_stop`.

## 5. Passo a passo

### 5.1 Capturas por etapa (`--aj-NN-only`)
1. No `ui_tour.gd`, ao lado dos `--i2-NN-only`, crie o padrão `--aj-NN-only`: cada etapa do plano acrescenta
   um bloco com a lista de capturas dela, **reaproveitando** as funções que já geram os nomes (`b05_map_list`,
   `i2_07_stove` …). Capturas novas recebem prefixo `aj_NN_<tela>`.
2. Bloco `--aj-01-only` = `g01_tasks_ready_many`, `t03_growth_ready`, `b05_map_list`, `i2_06_npc`.
3. Escreva no topo do bloco um comentário curto com a regra: "um bloco por etapa do plano de ajustes".

### 5.2 Linha de base do plano (antes de qualquer outra mudança)
1. Tour completo nas três resoluções:
   `& $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --out=aj_base`
   e o mesmo com `--resolution 390x844 --out=aj_base_390` e `--resolution 412x915 --out=aj_base_412`.
   Confira que saem os 114 PNGs em cada pasta. **Estas pastas são a régua do "antes" do plano inteiro**:
   a etapa 12 compara com elas.
2. Desempenho: exporte (`tools\export_web.ps1`), sirva (`tools\serve_local.ps1`) e rode
   `tools\touch_test.ps1 -Url http://localhost:8000/dev/ -Steps build\touch_steps_i2_12.json`
   com `perf_start/perf_stop` no trecho do Sítio (se o roteiro não tiver, copie para
   `build/touch_steps_aj_perf.json` e acrescente; arquivo de build, não versionado). Anote média, p95,
   quadros > 33 ms e picos. Repita uma vez para ver a variação. É a base da etapa 03.

### 5.3 `world_pin_test` estável
1. Na auditoria, antes de tocar as zonas de uma sala: esconda e pare NPCs (`NpcWorld`), o Tiro (`DogWorld`),
   montinhos do faro (`DigSpot`) e balões (`WorldBalloon`): `set_process(false)` + `visible = false`. Use
   `find_children` por classe/grupo, não nomes fixos.
2. Tente **vários pontos** dentro do polígono da zona (centro, mais 4–8 pontos internos; o mesmo jeito que já
   se faz com os pixels dos sprites). Passa se **algum** ponto leva ao alvo esperado. A garantia continua:
   "toda zona/lugar visível é tocável e leva ao lugar certo".
3. Se ainda houver intermitência, registre a mensagem exata e a sala no handoff antes de mudar de abordagem.

### 5.4 `world_life_test` estável
1. Leia `before` (o `last_reaction` e a posição) **depois** de `show_screen(&"pet")` e de um quadro.
2. Fixe a hora do teste com o relógio injetável (`tests/helpers/economy_clock.gd`, só troca `now()`/fuso),
   numa hora diurna sem foto noturna.
3. Troque `create_timer(0.3)` + "andou > 1 px" por espera por condição com limite:
   `var frames := 0; while not cond() and frames < 180: await get_tree().process_frame; frames += 1`.
   A asserção continua a mesma (anda/reage quando visível; não reage quando oculto).

### 5.5 Fixtures do tour (item 33)
1. `g01_tasks_ready_many`: monte pelo menos três missões prontas (história + pessoas + diária) usando as
   ações reais do `GameState` ou os `dev_*` existentes (guarda `BuildInfo.is_dev()`; o tour roda como dev).
2. `t03_growth_ready`: todos os requisitos da fase atual feitos (`GrowButton` visível, grade toda ✓).
3. Não grave o save do jogador (o tour já não grava; confira).

### 5.6 Armadilhas
- Não referencie `NextStep`/`Notice`/`QuestGuide`/`ModalCard` por tipo em teste `-s`: use `find_child`/`get`.
- Não suba o tempo máximo do teste para "resolver" instabilidade.
- O `test.ps1` dá a cada processo um `TIRO_TEST_TAG` (save próprio): rodar em paralelo é seguro.

## 6. Testes
- Lista: `world_pin_test,world_life_test` (~55 s).
- `tools\test.ps1 -Level etapa -Exact -Tests world_pin_test,world_life_test -DryRun` e depois sem `-DryRun`.
- **Estabilidade:** 10 rodadas seguidas, três processos ao mesmo tempo (para simular a carga do portão):
  `1..10 | % { powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests world_pin_test,world_life_test,world_view_test -Jobs 3 -KeepGoing }`
  Meta: **10/10 PASS** dos dois. Guarde o caminho de cada log.

## 7. Capturas
`--aj-01-only` antes (`aj_01_antes`) e depois (`aj_01_depois`, `_390`, `_412`). Mais as pastas de base do
§5.2 (`aj_base`, `aj_base_390`, `aj_base_412`).

## 8. Pronto quando
- [ ] `aj_base*` com 114 PNGs em cada resolução; números de desempenho anotados no registro.
- [ ] `--aj-01-only` existe e o padrão `--aj-NN-only` está comentado no `ui_tour.gd`.
- [ ] `world_pin_test` e `world_life_test`: 10/10 PASS em paralelo, sem garantia removida (o executor
      descreve o que cada teste confere antes e depois).
- [ ] `g01` mostra ≥ 3 prontas; `t03` mostra a grade toda ✓ e `GrowButton`.
- [ ] Nenhum arquivo fora de `game/tests/` e docs alterado.

## 9. Handoff (pontos naturais de parada)
1. Depois do §5.1 + §5.2 (linha de base gravada): diga as pastas e os números.
2. Depois do §5.3: diga quantas rodadas já passaram.
3. Depois do §5.4. 4. Depois do §5.5.
Se parar no meio do §5.2, diga qual resolução falta; o tour não precisa ser refeito nas que já saíram.

## 10. Registro
```
**Etapa 01 (data, executor[es]):** linha de base aj_base(_390,_412) com 114 PNGs; Sítio na Web: média … ms,
p95 … ms, … quadros > 33 ms, pico … ms. world_pin_test e world_life_test 10/10 PASS em paralelo (logs …);
mudanças: … . Fixtures g01/t03 corrigidas. Bloco --aj-NN-only criado. Pendências: … Sem push.
```
