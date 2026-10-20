# Etapa 17 — Pelagem de seda (pós-jogo) e simulador atualizado

**Estado: concluída em 19/10/2026.** Executar somente esta etapa. Pré-requisito: etapa 16 concluída (portão aprovado).

## Objetivo

"Mesmo depois de adulto, dá para deixar o pelo dele cada vez mais sedoso: um brilho que desliza pelo pelo
quando ele anda." E o Vitor tem um simulador rápido que mostra em que dia cada fase acontece.

## Leitura obrigatória

[02](02_FASES_E_PILARES.md) E, G; [06](06_INTERFACE_E_ARTE.md) E (shader `sheen`); `tools/economy_simulate.ps1`
(`-Quick` da etapa 00), `tests/economy_simulation.gd`, `tests/helpers/economy_sim.gd`, `economy_bot.gd`,
`tools/economy_compare.py`, `docs/plans/economia/SIMULADOR.md`.

## Entrega e implementação

1. **Pelagem de seda I–III** (02 G): requisitos em `growth.json → silk`, aparecem no painel de crescimento do
   adulto no lugar da "próxima fase" (silhueta brilhante + requisitos); "Crescer!" vira "Mais brilho!". Cada nível
   sobe `sheen` (0,33/0,66/1) no `tiro_coat.gdshader`, mostra um cartão curto (`ModalCard`, sem confete no I),
   adiciona um cartão na caderneta e o presente da 02 G (50/80/120 moedas). `growth.silk` salvo.
   Com `Motion.reduced`, o brilho fica parado.
2. **Simulador:** o resumo (`summary.json`) ganha `growth_days` (dia simulado de cada crescimento), pilares no
   fim e moedas no fim; `economy_compare.py` mostra a tabela "fase × dia" contra os alvos da 02 E.
3. Rodar **uma vez** `tools/economy_simulate.ps1 -Quick` e registrar em `RESULTADOS.md` (novo, nesta pasta):
   tempo de relógio gasto, dias de cada fase, campanha completa ou onde parou. **Sem** perfis extras nem sementes.
4. Se alguma fase cair fora do alvo por mais de 2× (ex.: Dentinhos no dia 8 em vez de 1–3), ajustar **uma**
   família de números (pontos de uma fonte, ou quantidade de uma refeição), rodar `-Quick` de novo e registrar
   em DECISOES. Se não resolver em 2 rodadas, só registrar o diagnóstico para o Vitor decidir.
5. Conferir o risco de moedas do meio do jogo (03 G) olhando as moedas no fim dos capítulos 5–9 no mesmo resumo;
   registrar, sem ajustar preços.

## Teste da etapa — `silk_test.gd` (novo, ≤ 2 min)

Seda só no adulto; requisitos contam escovações em dias diferentes e banhos com xampu; `sheen` sobe por nível;
presente uma vez; recarregar mantém o nível.

Rodar também: `economy_sim_test`, `growth_ui_test`, `ceremony_test`, `texts_test`.

## Para passar para a próxima

- [ ] Seda funcionando (captura do painel adulto e do Tiro brilhando, 360×780).
- [ ] `-Quick` roda e o resultado está em RESULTADOS.md com o tempo gasto.
- [ ] Ajustes (se houve) registrados em DECISOES.

## Fora desta etapa

Perfis/sementes múltiplos (o Vitor roda quando quiser), mudar preços de construções.

## Evidência e passagem de bastão

`build/economy/quick/…`, `build/test_logs/tiro17/`. README, ROADMAP, RESULTADOS, SIMULADOR.md (campos novos).
Sem push.
