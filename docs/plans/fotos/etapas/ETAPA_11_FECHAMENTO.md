# Etapa 11 — Fechamento

> Tamanho: médio. Depende de: todas. Fim do plano.
> Resultado que o Vitor vê: tudo das fotos conferido nas 3 resoluções e no navegador em modo celular, com um
> roteiro curto para ele testar no aparelho. Nada publicado.

## 1. Ler antes
README do plano (registro de todas as etapas e pendências), `02_REGRAS_E_TESTES.md`.

## 2. Passo a passo
1. Rode a etapa 02 de novo (instalador) para pegar os lotes de arte revisados desde então; `check` do pipeline.
2. **Portão** uma vez: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao -KeepGoing`.
   Falhas: separe as causadas pelo plano (corrigir) das antigas (registrar). Sem campanha nem simulador.
3. Tour: acrescente ao `tests/ui_tour.gd` um bloco `--fotos-only` com álbum, carta 1/3/4 inclinada, revelação,
   varal, tutorial e cartão de marco; rode nas 3 resoluções e olhe tudo.
4. **Toque real**: `tools/export_web.ps1`, `tools/serve_local.ps1` e `tools/touch_test.ps1` com um roteiro
   (`tests/touch/fotos.json`): abrir o álbum, abrir carta, arrastar para inclinar, rolar, melhorar, pôr no varal,
   tocar no varal. Meça `perf_start/perf_stop` com a carta Holográfica aberta (alvo: ≥ 50 fps no headless).
5. Roteiro do celular para o Vitor em `docs/plans/fotos/RESULTADOS.md` (10 passos, o que observar).
6. Atualize `docs/PROGRESSION.md` (seção do álbum), `AGENTS.md` = `CLAUDE.md` e o "Estado atual" do ROADMAP.

## 3. Pronto quando
Portão sem falhas novas, tour e toque real olhados, RESULTADOS.md com o roteiro do celular, docs atualizadas.
Publicar só quando o Vitor pedir.
