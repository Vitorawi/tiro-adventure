# Etapa 04 — Gestos: carinho de segurar e esconde-esconde

**Estado: concluída (23/10/2026, Claude Code; pendências fechadas pelo Codex com toque Web).** Pré-requisito: 03 concluída. Evidências em [VALIDACAO_04](VALIDACAO_04.md).

## Objetivo

Cuidar vira gesto gostoso, não repetição: um carinho é **segurar**; o Tiro tem um lugar favorito para
descobrir; Esperteza ganha um minijogo curto que usa o que a fazenda produz.

## Leitura

[02 F](02_DESENHO.md), `scenes/ui/pet_screen/pet_screen.gd` (`back_rect`, gestos de esponja/bola/escova),
`scripts/ui/pet_care_tray.gd`, `scripts/ui/pet_animator.gd`, `GameState.pet/play`, `scenes/ui/trick_training/`
(referência de minijogo no Sheet), `docs/ART_PIPELINE.md`.

## Entrega

1. **Carinho de segurar** (1,2 s, anel pequeno no dedo); esfregar contínuo = um carinho por gesto.
2. **Lugar favorito:** zonas cabeça/queixo/barriga em `PetScreen` (retângulos derivados do quadro, como o
   `back_rect`), favorito pela semente do save em `GrowthState`; reação `roll_over` e Felicidade +25; primeira vez
   revela (diário + aviso "Ele ama carinho na barriga!").
3. **Esconde-esconde** (desde Aventureiro): em Brincar, escolha bola ou copinhos. Minijogo no Sheet: 3 copinhos,
   trocas por fase (3/4/5), toque para escolher; consome 1 petisco `treat: true` ao começar; momento de
   Esperteza ao terminar (acertando ou não; teto do período). `GameState.hide_and_seek_error/hide_and_seek(item)`.
4. Arte: copinho 32 px (PixelLab, fundo transparente, mesmo estilo dos ícones), em `assets/sprites/ui/`.

## Teste da etapa

`gestures_test`: segurar 1,2 s = um carinho (0,8 s = nenhum); esfregar longo = um; favorito revela uma vez e dá
+25; esconde-esconde exige fase e petisco, consome um, dá um momento, respeita o teto; trocas por fase.

`-Level etapa -Tests gestures_test -Areas pet,growth`. Capturas 360×780 do minijogo.

## Para passar para a próxima

- [x] Nível etapa verde; capturas conferidas (28 PASS em 233,5 s; após o último ajuste, 21 afetados PASS em 105,8 s).
- [x] Gesto testado com toque emulado (`tools/touch_test.ps1`, roteiro `tools/care_gestures_touch_steps.json`: segurar e jogar copinhos; 9 verificações PASS).
- [x] README e ROADMAP.

Fechamento: corrigidos posicionamento e seleção de Copinhos no Popover, encontrados pelo toque Web.
`world_selector_test`: falha preexistente/intermitente documentada em VALIDACAO_04, sem alteração no seletor.
Encadeamento da 05 não realizado: `create_thread` indisponível nesta sessão; 05 não executada.
