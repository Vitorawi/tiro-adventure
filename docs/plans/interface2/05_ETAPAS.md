# 05 — Etapas (índice)

> O detalhe de cada etapa está em `etapas/ETAPA_NN_*.md`: objetivo, o que ler, **como o código está hoje**
> (arquivos, funções, nós e testes que dependem), passo a passo, o que não fazer, armadilhas, **teste novo
> com os casos numerados**, lista fechada de testes com o comando, capturas, critério de pronto e modelo de
> registro. Regras comuns a todas em `04_REGRAS_E_TESTES.md`.

| # | Arquivo | Entrega | Teste novo | Testes (lista fechada) | Toque real |
|---|---|---|---|---|---|
| 00 | — (este plano) | bíblia, jornada, telas, protótipos, decisões do Vitor | — | — | — |
| 01 | [ETAPA_01_BASE.md](etapas/ETAPA_01_BASE.md) | fontes Fredoka/Nunito, `Palette` nova, ícones vetoriais, tema; `test.ps1 -Exact`, `--i2-NN-only` | `ui2_tokens_test` | ~1 min | — |
| 02 | [ETAPA_02_PECAS.md](etapas/ETAPA_02_PECAS.md) | peças do `UiKit` (botões, chips, tiles, stepper, toggle, steps, anéis, slots, fala, folha) | `ui2_kit_test` | ~1 min 10 | — |
| 03 | [ETAPA_03_CASCA.md](etapas/ETAPA_03_CASCA.md) | rodapé claro preso, HUD em 2 linhas, **próximo passo da história**, central de avisos | `next_step_test`, `notice_test` | ~2 min 30 | — |
| 04 | [ETAPA_04_TIRO.md](etapas/ETAPA_04_TIRO.md) | cenário aproximado, anéis no topo, **botão Cuidar + roleta** | `care_wheel_test` | ~2 min 30 | sim |
| 05 | [ETAPA_05_MISSOES.md](etapas/ETAPA_05_MISSOES.md) | Missões em **três abas** (História/Pessoas/Diárias), **folha de prêmio**, prêmios que voam | `quest_reward_test` | ~2 min 10 | — |
| 06 | [ETAPA_06_MUNDO.md](etapas/ETAPA_06_MUNDO.md) | **mapa sem texto**, balões, **alfinete**, **mundos em cartões-postais**, conversa, compra | `world_pin_test` | ~2 min 40 | — |
| 07 | [ETAPA_07_HORTA_BANDEJAS.md](etapas/ETAPA_07_HORTA_BANDEJAS.md) | **barra da horta** (arrasto começa no canteiro), bandejas das estações | `farm_dock_test` | ~4 min (exceção) | sim |
| 08 | [ETAPA_08_MOCHILA.md](etapas/ETAPA_08_MOCHILA.md) | Mochila, detalhe do item, caderninho, Coleção, Álbum | — | ~1 min 20 | — |
| 09 | [ETAPA_09_PAINEIS.md](etapas/ETAPA_09_PAINEIS.md) | Crescimento, feira, lojas, obras, passeios, amigos, truques, Natureza, Como fazer, Configurações | — | ~2 min | — |
| 10 | [ETAPA_10_FESTA.md](etapas/ETAPA_10_FESTA.md) | comemorações nos quatro tamanhos, boas-vindas, Novo! | — | ~1 min 20 | — |
| 11 | [ETAPA_11_TEXTO.md](etapas/ETAPA_11_TEXTO.md) | orçamento de texto, "Texto maior", limpeza do visual antigo | `text_budget_test` | ~40 s | — |
| 12 | [ETAPA_12_FECHAMENTO.md](etapas/ETAPA_12_FECHAMENTO.md) | tour completo, **única suíte inteira**, toque real, desempenho, docs | — | ~10 min | sim |
