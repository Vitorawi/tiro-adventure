# Etapa 00 — Rotina de testes enxuta e ferramentas

**Estado: concluída (19/10/2026).** Executar somente esta etapa. Pré-requisito: nenhum (primeira do plano).

## Objetivo

Nada muda para o jogador. A equipe ganha um jeito rápido de rodar **só os testes afetados**, ver quanto
cada teste demora, e um simulador com modo rápido para quando o Vitor quiser medir o jogo. É a linha de base
do plano: tudo o que falhar aqui já falhava antes.

## Leitura obrigatória

`CLAUDE.md`, Estado atual do `docs/ROADMAP.md`, [README](README.md), [00](00_VISAO.md), [01](01_REGRAS_DE_EXECUCAO.md),
[MAPA_DE_TESTES](MAPA_DE_TESTES.md), `tools/test_all.ps1`, `tools/run_godot_test.ps1`, `tools/economy_simulate.ps1`,
`docs/plans/economia/SIMULADOR.md` (só para entender os parâmetros).

## Entrega e implementação

1. `tools/test_all.ps1` ganha parâmetros (sem eles, faz exatamente o que faz hoje):
   - `-Only "a,b,c"`: roda só esses testes (nomes sem `.gd`), na ordem dada.
   - `-Skip "a,b"`: pula esses.
   - `-Fast`: pula `progression_test`, `economy_sim_test` e os autotestes Python.
   - Mede e imprime a duração de cada teste e o total; grava `build/test_logs/last_run.csv`
     (teste, segundos, resultado). Teste novo da lista entra uma vez só, no fim da lista atual.
2. `tools/run_godot_test.ps1`: confirmar tempo máximo padrão de 5 min e mensagem clara "TEMPO ESGOTADO" (não PASS).
3. `tools/economy_simulate.ps1` ganha `-Quick`: perfil `reference`, semente 1, `-Until campaign`, `-Ledger off`,
   `-Days 60`, `-TimeoutMin 20`, saída `build/economy/quick/<AAAAMMDD_HHMM>/`. No fim imprime o tempo de relógio
   gasto e os dias simulados. Não muda o robô nem as regras.
   **Verificação:** rodar só `-Quick -Days 1` (tem que terminar em menos de 2 min). Não rodar a campanha.
4. **Linha de base (uma vez):** `tools/test_all.ps1` inteiro. Anotar no [MAPA_DE_TESTES](MAPA_DE_TESTES.md) o
   tempo aproximado de cada teste e, no README deste plano, as falhas que já existiam (com a primeira linha do erro).
5. Capturas "antes do plano": `tests/ui_tour.gd -- --out=tiro00_antes` em 360×780 (só guardar; nada muda).

## Teste da etapa

- Sem teste novo de jogo. Conferir as opções: `test_all.ps1 -Only hud_test,texts_test` (2 testes, tempos no CSV);
  `-Skip` e `-Fast` listam o que pulam antes de começar.
- A suíte inteira roda só no item 4 (é a linha de base).

## Para passar para a próxima

- [x] `-Only`, `-Skip`, `-Fast` funcionando e CSV gravado.
- [x] `-Quick` existe e `-Quick -Days 1` terminou em < 2 min.
- [x] Tempos no MAPA_DE_TESTES; falhas pré-existentes no README.
- [x] Capturas `tiro00_antes` guardadas.

## Fora desta etapa

Mudar regra do jogo, robô do simulador, testes existentes ou arte.

## Evidência e passagem de bastão

Logs em `build/test_logs/tiro00/`. Atualizar README (registro), ROADMAP (Estado atual) e, se a forma de rodar
testes mudou, a seção **Comandos** do `CLAUDE.md` e `AGENTS.md` (idênticos). Sem push.

## Resultado (19/10/2026)

| Arquivo mudado | Conferência | Resultado |
|---|---|---|
| `tools/test_all.ps1` | `-Only "hud_test,texts_test"` (2 testes, CSV com 15,3 s e 2 s); `-Fast` e `-Skip` listam o que pulam; `-Only economy_audit_selftest,dev_tools_test_prod` | ok |
| `tools/test_all.ps1` (linha de base) | suíte inteira com `-KeepGoing` | 37,7 min, 61/68; 7 falhas pré-existentes no [README](README.md#falhas-que-já-existiam-antes-do-plano) |
| `tools/run_godot_test.ps1` | leitura: estouro imprime "TEMPO ESGOTADO" e sai com 124; padrão agora 5 min | ok |
| `tools/economy_simulate.ps1` | `-Quick -Days 1` | 0,2 min de relógio, 0,83 dia simulado, saída em `build/economy/quick/20261019_0259/` |
| — | `tests/ui_tour.gd -- --out=tiro00_antes` (360×780) | 95 PNGs em `build/screenshots/tiro00_antes/` |

Logs: `build/test_logs/tiro00/` (`baseline.log`, `baseline.csv`, `quick_days1.log`, `ui_tour.log`, `extra.log`).
