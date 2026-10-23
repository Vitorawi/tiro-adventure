# Etapa 06 — Missões e história falam a mesma língua

**Estado: concluída em 23/10/2026 (Codex, local).** Pré-requisito: 05 conferida concluída no README, ROADMAP e VALIDACAO_05. Evidência em [VALIDACAO_06](VALIDACAO_06.md).

## Objetivo

Tirar o cuidado das diárias (o Tiro pede pelos desejos; as rotinas são da fazenda) e fazer a história
apresentar desejo, momento e Tiro animado no começo.

## Leitura

[02 G](02_DESENHO.md), `data/routines.json`, `data/quests.json` (linha da Laís, capítulos 1–3), `data/npcs.json`
(falas), `progression.json → features`, `scripts/ui/task_help.gd`.

## Entrega

1. `routines.json`: saem `care`, `care_week`, `tiro_walk`; as roupas de `care_week` vão para outras semanais ou
   presentes de fase (registrar onde em DECISOES). Contagens `count` ajustadas se o catálogo ficar menor que o pedido.
2. Laís: passo novo depois de `lais_bed`, "Atender o primeiro desejo" (objetivo `wish` 1), com fala curta:
   quando ele pede, é hora de cuidar; cada cuidado assim é um momento que faz ele crescer. Uma fala depois, no
   capítulo do Sítio, apresenta o "Tiro animado" ("Ele adora te ajudar quando está bem cuidado").
3. `TaskHelp.describe` para requisitos `moments` e objetivo `wish` (o que fazer + Ir).
4. Revisar missões que pedem contagem de cuidado (`lais_feed/bath/play`) — continuam como tutorial — e qualquer
   texto que fale em afeto, corações, vínculo, "a cada 2 minutos" ou aba Desejos (`tools/list_texts.ps1`).

## Teste da etapa

`care_story_test`: rotinas sorteadas nunca pedem cuidado do Tiro; passo do primeiro desejo aparece depois da
caminha e conclui ao atender; Como fazer de `moments` aponta as fontes; nenhuma palavra proibida
(`texts_test` com "vínculo", "afeto", "corações" na lista).

`-Level etapa -Tests care_story_test -Areas story,navigation`.

## Para passar para a próxima

- [x] Nível etapa verde.
- [x] README e ROADMAP.
