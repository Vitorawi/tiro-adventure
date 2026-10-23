# Etapa 07 — Ritmo e fechamento (PORTÃO + CAMPANHA)

**Estado: concluída e aprovada pelo Vitor em 23/10/2026, com ressalvas aceitas.** Pré-requisito 06 confirmado concluído.
Última etapa; ritmo atual aprovado por enquanto, sem nova calibração; terceira rodada Quick dispensada. Ver [RESULTADOS](RESULTADOS.md).

## Objetivo

Ensinar o robô do simulador a cuidar pelas regras novas, medir quanto tempo cada fase leva e calibrar os
números para o ritmo-alvo. Fechar a documentação.

## Leitura

[00](00_VISAO.md) (ritmo-alvo), [02](02_DESENHO.md) inteiro, `docs/plans/economia/SIMULADOR.md`,
`tests/helpers/economy_bot.gd` (`pursue_growth`), `tests/progression_test.gd` (campanha), `tools/economy_compare.py`.

## Entrega

1. **Robô:** cuida só quando a necessidade pede, atende o desejo do período, faz esconde-esconde quando falta
   Esperteza e tem petisco, passeia; sem esfregar sem motivo. Campanha do `progression_test` pelas mesmas regras.
2. **Medida:** `tools\test.ps1 -Level campanha` — resumo com o dia de cada crescimento (perfil `reference`) e a
   comparação com a linha de base da 00.
3. **Calibração** (só dados): se uma fase ficar fora do alvo (Filhotinho ≤ 30 min, Dentinhos dia 1–3, Aventureiro
   5–8, Mocinho 10–14, adulto 18–24), ajustar quantidades de momentos, `ask_below`, decaimento ou teto do
   período, nessa ordem de preferência. No máximo **duas** rodadas de campanha; o que sobrar vira diagnóstico para o
   Vitor em `RESULTADOS.md`.
4. **Portão:** `-Level portao` verde; capturas `ui_tour` nas três resoluções; toque emulado na tela do Tiro.
5. Docs: `docs/PROGRESSION.md` (seção "Cuidar é crescer"), `docs/GAME_DESIGN.md` (Desejos/necessidades),
   `CLAUDE.md`/`AGENTS.md` (mapa: abas, desejo, momentos, vínculo removido), `FUTURO.md` deste plano com o que
   ficou de fora.

## Para concluir o plano

- [x] Cinco crescimentos e dias por fase em `RESULTADOS.md`; `progression_test` 111/111 PASS.
- [x] Vitor dispensou a terceira rodada Quick em 23/10/2026: aceita evidência 110/111 + correção focada do petisco validada, sem declarar Quick integral verde.
- [x] 91 testes do portão validados: passagem 90 PASS/1 FAIL em 465,2 s + Festa corrigida e reexecutada PASS (441 verificações); capturas conferidas. CSV bruto preservado.
- [x] **Vitor aprovou o ritmo atual por enquanto em 23/10/2026**, sem nova calibração — registrado no README.
- [x] Nada publicado; sem commit, push ou nova sessão.
