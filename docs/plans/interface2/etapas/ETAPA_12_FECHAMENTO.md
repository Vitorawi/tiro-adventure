# Etapa 12 — Fechamento: varredura, suíte inteira, toque real e desempenho

> Tamanho: médio. Depende de: 11. Última etapa.
> Resultado que o Vitor vê: o plano pronto para ele testar no celular quando pedir a publicação.

## 1. Passo a passo
1. **Tour completo** nas 3 resoluções (`--out=i2_12_tour`, `_390`, `_412`) e **pranchas finais** antes ×
   depois: reaproveite `docs/plans/interface2/prototipo/prancha.html` com uma entrada nova que aponta para
   `build/screenshots/interface2_antes/` e `i2_12_tour/` (Tiro, Missões nas 3 abas, folha de prêmio, Mapa,
   alfinete, lista de mundos, horta, fogão, Mochila, Crescimento, boas-vindas). Abra todas e anote o
   checklist 04 §B por tela.
2. **A única suíte inteira do plano:** `tools\test.ps1 -Level portao` (3 processos, ~10 min). Verde é verde:
   o que falhar é consertado aqui.
3. **Toque real** (04 §F) com o roteiro completo `build/touch_steps_i2_12.json`: abrir o jogo → tocar no
   próximo passo → `Ir` → (Casa) tocar no fogão → cozinhar → voltar → pegar o prêmio pela pílula → folha →
   "Ir para…" → (Sítio) plantar arrastando 4 canteiros → Mapa → lista de mundos → Praça → Tiro → Cuidar →
   Banho → Mochila.
4. **Desempenho na Web:** exportar e medir o tempo de quadro (o mesmo jeito da etapa 12 do plano anterior,
   ver `docs/plans/interface/README.md`): arrastar o Sítio com balões, abrir a roleta, abrir a folha de
   prêmio. Meta: média ≤ 20 ms no computador; anotar picos. Tamanho final do `.pck`.
5. **Roteiro do celular** em `docs/plans/interface2/RESULTADOS.md`: o que o Vitor deve olhar no `/dev/` quando
   pedir publicação (legibilidade das fontes, rodapé translúcido sobre o mundo, roleta com o polegar, arrasto
   da horta, alfinete, cartões dos mundos, vibração).
6. **Docs:** `CLAUDE.md` e `AGENTS.md` (iguais): tabela "Onde trabalhar" com `NextStep`, `QuestGuide`,
   `Notice`, `QuestReward`/`RewardSheet`, `claim_quest_fx`, `CareWheel`/`PetCareTray` em roleta, `FarmDock`,
   `WorldPin`, miniaturas dos mundos, `ctl_icon`, fontes e tokens; seção Comandos com `-Exact` e `--i2-NN-only`;
   `docs/ART_PIPELINE.md` (fontes OFL, ícones Lucide ISC, miniaturas); `docs/plans/interface2/FUTURO.md`
   (sons, tema escuro, dia/noite, decorar a casa); README do plano marcado como concluído; Estado atual do
   ROADMAP.
7. **Não publicar.** Commit local; a publicação é só quando o Vitor pedir.

## 2. Pronto quando
- [ ] Suíte inteira verde, toque real ok, desempenho medido, pranchas finais abertas e anotadas.
- [ ] Docs atualizados e idênticos (`CLAUDE.md` = `AGENTS.md`).

## 3. Registro
```
**Etapa 12 (data, executor): PLANO CONCLUÍDO.** Suíte inteira N/N PASS em … min; toque real …; quadro médio …
ms (pico …); pck … KB. Pranchas em …; roteiro do celular em RESULTADOS.md. Sem publicação.
```
