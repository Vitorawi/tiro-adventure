# Etapa 18 — Fechamento e roteiro do celular (PORTÃO)

**Estado: concluída em 19/10/2026** (ver RESULTADOS.md e o registro do README).

## Objetivo

Entregar ao Vitor o jogo com o Tiro no centro, verificado, documentado e com um roteiro curto para testar no
celular (`/dev/`) antes de publicar.

## Leitura obrigatória

Todos os documentos deste plano (para conferir o que foi feito), README (registro), DECISOES, RESULTADOS.

## Entrega e implementação

1. **Conferência da visão:** tabela em RESULTADOS.md com os 10 itens de "O que muda para o jogador" (00) e, para
   cada um, onde está no jogo e como foi verificado. Item não entregue fica como pendência explícita.
2. **Passagem total:** `tools/test_all.ps1` inteiro + `dev_tools_test -- --prod`; `ui_tour` completo nas três
   resoluções (`--out=tiro18_depois`, `_390`, `_412`), comparando com `tiro00_antes`; abrir os PNGs das telas
   do Tiro, HUD, painel, cerimônia, caderninho, álbum e Casa.
3. Export Web local (`tools/export_web.ps1` + `serve_local.ps1`) e um `touch_test` curto: crescer, entregar,
   escovar, abrir álbum.
4. **Documentação final:** `docs/GAME_DESIGN.md` (o objetivo do jogo agora é o Tiro: fases, pilares, álbum,
   Casa), `docs/PROGRESSION.md`, `docs/ART_PIPELINE.md`, `docs/ARCHITECTURE.md` (estados novos), `CLAUDE.md` e
   `AGENTS.md` (Estrutura, "Onde trabalhar", regras; idênticos), `README.md` público (uma frase nova sobre o
   crescimento), `docs/ROADMAP.md` (Estado atual), [FUTURO](FUTURO.md) com o que ficou de fora.
5. **Roteiro do celular** em RESULTADOS.md (≤ 15 itens): save novo até Dentinhos; conferir que o filhote é o
   mesmo Tiro; cerimônia com e sem "Menos animação"; escovar; álbum e dicas; Casa; save antigo é zerado e recomeça
   no Recém-chegado.

## Teste da etapa

A passagem total acima. Nenhum teste novo.

## Para passar (encerrar o plano)

- [x] Suíte inteira sem falha nova; tour nas três resoluções conferido.
- [x] RESULTADOS.md com a conferência da visão e o roteiro do celular.
- [x] Docs e `CLAUDE.md`/`AGENTS.md` atualizados.
- [x] Nada publicado; o Vitor decide quando publicar.

## Evidência e passagem de bastão

`build/test_logs/tiro18/`, `build/screenshots/tiro18_*`. README marcado como **plano concluído**, ROADMAP.
Sem push.
