# Cuidar é crescer — resultados da etapa 07

Executada localmente pelo Codex em 23/10/2026. Etapa 06 confirmada concluída no README,
ROADMAP e VALIDACAO_06 antes das alterações. Trabalho anterior preservado.
**Plano Cuidado concluído (00–07) e aprovado pelo Vitor em 23/10/2026, com ressalvas aceitas:** ritmo atual aprovado por enquanto, sem nova calibração; terceira rodada Quick dispensada. Evidência preservada: Quick 110/111 + teste focado de `nina_blueberry` PASS.

## Ritmo SIMULADO, perfil reference, semente 1

Sessão inicial de 20 min, depois três sessões de 10 min por dia. Dias contados desde a primeira
abertura; minutos ativos são tempo de ações. Agente idealizado, sem validação em aparelho físico.

| Fase | Linha de base da 00 (dia; min ativos) | Etapa 07 (dia; min ativos) | Alvo | Diagnóstico |
|---|---|---|---|---|
| Filhotinho | 0,00; 1,3 | 0,00; 1,5 | primeira sessão, ≤30 min | dentro |
| Dentinhos | 0,01; 10,0 | 0,34; 25,4 | dia 1–3 | adiantado |
| Aventureiro | 2,33; 87,3 | 2,08; 75,6 | dia 5–8 | adiantado |
| Mocinho | 24,08; 734,2 | 8,84; 275,1 | dia 10–14 | adiantado |
| Azul e Dourado | 39,08; 1.182,8 | 19,84; 603,7 | dia 18–24 | dentro |

Os cinco crescimentos e os 12 capítulos foram alcançados. O adulto saiu 19,24 dias antes da
linha de base. A comparação reúne a mudança do sistema, a política nova e a reprodução correta
da ausência; não isola o efeito de uma única variável de balanceamento. O dia 0,00 é arredondado
em centésimos no resumo: os 1,5 min de Filhotinho são minutos ativos, não precisão adicional do dia.

Fonte atual: `build/economy/cuidado07_r20261023_073452_996eb95e_economy_quick/reference_s1/summary.json`.
Base preservada: `build/economy/cuidado00_r20261023_013037_13609c8b_economy_quick/reference_s1/summary.json`.
Relatório comparativo: `build/economy/cuidado07_report/report.md`.

## Limite das campanhas e histórico das ressalvas

Foram feitas **duas invocações** de `tools/test.ps1 -Level campanha -Jobs 3 -KeepGoing`.
Não houve terceira invocação nem terceiro Quick. As depurações focadas do teste de integração
e da fixture `progression_test` não geraram medidas adicionais de ritmo.

1. `r20261023_072458_03b50cbf`: tentativa técnica inválida. O auditor ainda exigia vínculo;
   o teste de fidelidade não isolava o bônus Animado; a fixture de campanha priorizava comida
   e não atendia o tutorial; o Quick tinha acesso a constantes de cuidado removidas.
   Quick interrompido, logs preservados; **sem medida válida** nesta rodada.
2. `r20261023_073452_996eb95e`: **5 componentes PASS e Quick FAIL**, total 741,2 s.
   `progression_test` PASS em 408,0 s: 778 ciclos, 64 aquisições, **111/111 missões**, cinco
   crescimentos; `economy_sim_test`, auditor Python, comparador Python e circuito Python PASS.
   Quick: **stalled, 110/111 missões**, capítulo 13, adulto, 41,34 dias, 1.259,4 min ativos,
   16.565 ações e **zero violações**, em 721,5 s reais.

A única missão pendente do Quick foi `nina_blueberry`: `pursue_stat("feed:blueberry_treat")`
ignorava o alimento específico e dava comida genérica. Corrigido para buscar e dar o alimento
pedido; regressão em `care_bot_test` PASS no fechamento. Essa correção **não teve uma nova
campanha completa**, por respeito ao limite de duas rodadas. O Quick continua registrado como
FAIL, sem transformar 110/111 em aprovação nem atribuir o atraso restante ao jogo.

**Nenhum número de produção foi alterado nesta etapa.** A rodada técnica consumiu a primeira
invocação e a segunda forneceu o diagnóstico acima; não restou rodada para verificar ajuste
numérico. Os valores medidos continuam sendo os dados em `growth.json`/`config.json`.
Uma calibração posterior deve começar pelas quantidades de momentos, depois `ask_below`,
decaimento e teto, nessa ordem. Não aplicar números sem nova medida e não anunciar os três
desvios intermediários como resolvidos.

## Validação de jogo e visual

- Nível etapa final: `-Level etapa -Tests care_bot_test -ChangeList build/cuidado07_scope.txt -Jobs 3`:
  **4/4 PASS em 12,5 s**, `build/test_logs/r20261023_074834_8fc783ed/results.csv`.
  Lista: scripts_check, content_test, texts_test, care_bot_test.
- Primeiro portão: 91 testes, 955,4 s, **85 PASS, cinco FAIL e um TIMEOUT**, com falhas de fixtures
  em hud_growth/lists/park/tricks/nature/festival.
  Não é verde. Campanha e tours simultâneos aumentaram o tempo; não usar esse tempo como
  medição isolada do orçamento de 8 min. Referências a rotinas removidas foram trocadas por
  rotinas atuais; metas congeladas usam `routine_target`; Natureza usa relógio injetável.
  Praça isola recompensa de cenoura para não confundir retirada parcial com depósito cheio.
  O teste da Festa ainda contava 50 principais em vez das 51 atuais.
- `ui_tour`: **114 PNGs por resolução**, 360×780, 390×844, 412×915, em
  `build/screenshots/cuidado07_final/`, abertos e conferidos em 12 pranchas. Logs sem erros de
  script. O roteiro agora fecha o resumo persistente do avatar depois da captura correspondente;
  a primeira leva, encoberta pelo resumo, foi descartada como evidência final.
- Export DEV local em `build/cuidado07_export.log`; toque Chrome 390×844 com
  `tools/care_gestures_touch_steps.json`, log `build/cuidado07_touch.log` e saves descartáveis
  em `build/touch_test/`. Carinho: antes 0, após 0,8 s ainda 0, após segurar 3 s = 1.
  Copinhos: petiscos 10→9 ao iniciar, conclusão 0→1 e Esperteza 0→1 ao terminar, sem segundo
  consumo. Capturas de escolha e resultado abertas. Não equivale a teste físico no celular.

Comandos principais:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests care_bot_test -ChangeList build/cuidado07_scope.txt -Jobs 3
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Level portao -Jobs 3 -KeepGoing
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Level campanha -Jobs 3 -KeepGoing
py -X utf8 -I tools/economy_compare.py --in build/economy/cuidado07_r20261023_073452_996eb95e_economy_quick --base build/economy/cuidado00_r20261023_013037_13609c8b_economy_quick --out build/economy/cuidado07_report
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_web.ps1 -Channel dev
powershell -NoProfile -ExecutionPolicy Bypass -File tools/serve_local.ps1 -Port 8007
powershell -NoProfile -ExecutionPolicy Bypass -File tools/touch_test.ps1 -Url http://localhost:8007/ -Steps tools/care_gestures_touch_steps.json
```

## Decisões do Vitor — 23/10/2026

1. **Ritmo atual aprovado por enquanto, sem nova calibração:** Filhotinho 1,5 min de jogo ativo;
   Dentinhos 0,34 dia; Aventureiro 2,08 dias; Mocinho 8,84 dias; adulto 19,84 dias. Os desvios
   intermediários da tabela foram aceitos e continuam documentados.
2. **Terceira rodada Quick dispensada:** fica aceita para o fechamento a evidência 110/111 + teste
   focado de `nina_blueberry` PASS, como está. Sem nova campanha e sem reclassificar o Quick como 111/111.

**Plano Cuidado concluído e aprovado pelo Vitor em 23/10/2026, etapas 00–07, com essas ressalvas.**
As pendências descritas no histórico acima foram encerradas por essas decisões explícitas.
Nenhuma sessão nova aberta, commit, push ou publicação. Saves atuais, sem migração nem teste antigo.

## Fechamento do portão

Segunda passagem completa: `build/test_logs/r20261023_074844_28a6cf0e/results.csv`,
**465,2 s (7 min 45 s), 90 PASS e 1 FAIL**. Dentro do orçamento de 8 min; não rodou campanha/tour
ao mesmo tempo. Única falha: `festival_test` esperava 50 missões principais; a etapa 06 acrescentou
`lais_first_wish`, totalizando 51. Expectativa atualizada, preservando as outras 440 verificações.

Reexecução só da fixture corrigida:

```powershell
$env:TIRO_TEST_TAG='cuidado07_festival_final'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_godot_test.ps1 festival_test -Log build/cuidado07_festival_final.log
```

**FESTIVAL TEST: PASS (441 verificações)**, saída 0 e stderr vazio. Assim os **91 testes do portão
estão validados no código final**, compondo a passagem de 90 PASS com esta reexecução. Não houve
uma terceira passagem completa, nem se reescreveu o CSV bruto como 91/91. `care_bot_test` também
PASS nessa passagem, incluindo a execução real que consome o petisco de mirtilo e conta o objetivo.
Saves/toque: conferência automatizada **9/9 PASS** em `build/cuidado07_touch_checks.json`;
342 PNGs finais conferidos e logs dos três tours sem erro de motor.

Revalidação final dos autotestes do auditor e comparador Python: PASS; relatório comparativo
regenerado após explicitar Filhotinho ≤30 min e retirar Corpo da linha de momentos (Corpo vem das
refeições). `AGENTS.md` e `CLAUDE.md` idênticos; `git diff --check` sem erros de whitespace.
