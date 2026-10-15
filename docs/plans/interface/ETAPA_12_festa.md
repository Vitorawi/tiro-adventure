# Etapa 12 — Festa e polimento: comemorações, números que contam, vibração

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_12_festa.md."
> Pré-requisito: Etapas 00–11.

## Objetivo (o que o jogador sente)
"Quando eu ganho alguma coisa, o jogo comemora comigo: o cartão salta, as moedas contam, cai confete e o
celular vibra de leve." E o acabamento final: nada torto, nada cortado, nada parado demais.

## Leia antes
`scenes/ui/celebration/` (`show_level`, `show_chapter`, `show_unlocks`, `show_bond`, `show_trick`,
`show_treasure`, `show_find`), `scenes/ui/walk_result/`, `scenes/ui/welcome_back/` (`WelcomeBack`,
`GameState.welcome_ready_lines`), `scripts/ui/collect_fx.gd`, `main.gd` (`_queue_modal`), `settings_panel.gd`,
`save_manager.gd` (onde ficam as configurações em `settings.json`).

## Passo a passo

### 12.1 Cartão de comemoração único — `scripts/ui/modal_card.gd`
- [ ] Peça comum para todos os cartões modais (nível, capítulo, Novo!, vínculo, truque, tesouro, achado,
  volta do passeio, boas-vindas, roupa nova):
  - fundo `DIM` (fade 0,2 s);
  - cartão `PAPER`, cantos 22, largura 320, entra com `pop_in` a partir de 0,7;
  - **fita** no topo (faixa `GOLD` ou cor do mundo, com o título em `NumberLabel` 26);
  - **ícone grande** (64–96) com **raios** girando devagar atrás (arte nova, 12.4);
  - prêmios em chips que entram um por um (`pop_in` com 80 ms entre eles); números de moeda/XP com
    `count_up`;
  - um `primary` ("Oba!", "Continuar", "Ver") + `ghost` opcional.
- [ ] Refaça os `show_*` da `Celebration`, o `WalkResult` e o `WelcomeBack` usando o `ModalCard`.
  **Nomes de nós mantidos** (`Celebration`, `CelebrationScroll`, `WalkResult`, `WalkResultScroll`,
  `CloseResult`, `FirstTime`, `RareStar`, `WelcomeBack`...). A fila (`_queue_modal`) não muda.

### 12.2 Confete
- [ ] `CPUParticles2D` (funciona no renderer Compatibility/Web): 40 partículas, retângulos 4×6 em
  `PRIMARY`/`GOLD`/`ACCENT`/`INFO`/`DANGER`, gravidade 300, vida 1,6 s, `one_shot`. Disparado no
  nível, capítulo, tesouro, raro/lendário do passeio e vínculo novo. Não no "Novo!" simples (para não
  banalizar).

### 12.3 Boas-vindas agrupado
- [ ] `welcome_ready_lines` mostra uma linha por **tipo**: "3 achados" com os ícones dos mundos em fileira
  (tocar → Ir ao primeiro), "2 prontos no Sítio" (canteiros + estações do mundo juntos), visita de amigo,
  presente do dia em destaque no topo. Hoje vem uma linha por achado/mundo.

### 12.4 Arte
- [ ] `ui/fx/rays.png` 128×128: "radial sun rays burst, soft golden, transparent background, pixel art" —
  receita de ícone com 128×128 (`create_image_pixen`). Gira 20°/s, `modulate.a 0.6`.

### 12.5 Vibração
- [ ] `scripts/ui/haptics.gd`: `Haptics.tap()` (12 ms), `Haptics.success()` (30 ms), `Haptics.big()`
  (60 ms), `Haptics.error()` (2×20 ms). Usa `Input.vibrate_handheld(ms)`; não faz nada se desligado.
- [ ] Liga em: cada canteiro do arrasto (tap), colher/pegar (success), nível/capítulo/tesouro (big),
  `Motion.shake` de erro (error).
- [ ] Configuração **"Vibrar"** (ligado por padrão) no painel de configurações, salva em `settings.json`
  pelo `SaveManager` (é preferência do aparelho, vale para todos os saves). Nota: iPhone/Safari ignora
  vibração na web — tudo bem.
- [ ] Na mesma tela de configurações: **"Menos animação"** → `Motion.reduced` (também em `settings.json`).

### 12.6 Polimento final (varredura)
- [ ] Rode o tour completo em **360×780, 390×844 e 412×915**; abra tudo; anote e corrija: texto cortado,
  peça encostada na borda, cor solta (`Select-String 'Color\("' scripts/ui scenes`), botão sem `Motion.press`,
  dois `primary` na mesma tela, ícone esticado (escala não inteira em ícone 32).
- [ ] Desempenho no celular: export Web, abrir no celular (ou `touch_test`) e conferir que arrastar o
  Sítio com balões, nuvens e partículas não engasga. Se engasgar: desligue o brilho do 6.4 e reduza nuvens.
- [ ] Atualize `docs/GAME_DESIGN.md` (seção "Interface": mundo em tela cheia, bandeja, arrastar,
  caderninho) e `docs/ART_PIPELINE.md`.

## Testes
- [ ] `game/tests/festa_test.gd` (novo): `Celebration.show_level` monta um `ModalCard` com o número do
  nível; com `Motion.reduced` os chips aparecem na hora; `Haptics` desligado não chama vibração (use uma
  flag de teste `Haptics.calls`); boas-vindas com 3 achados mostra **uma** linha de achados.
- [ ] `welcome_test`, `walks_test`, `treasure_test`, `tricks_test`, `friends_test`, `tasks_test`
  (comemorações) passam.

## Capturas
Tour completo `etapa12_depois` nas três resoluções + `h01_level_card`, `h02_chapter_card`,
`h03_treasure_confetti`, `h04_welcome_grouped`, `h05_settings_haptics`.

## Lista de conferência (aceite)
- [ ] Todas as comemorações com o mesmo cartão bonito; números contam; confete nos grandes momentos.
- [ ] Vibração e "Menos animação" nas configurações.
- [ ] Varredura final feita nas três resoluções, sem pendências visuais (ou pendências anotadas no ROADMAP).
- [ ] README do plano: marcar a etapa e escrever o bloco **"PLANO CONCLUÍDO"** (o que mudou, capturas
  antes/depois de referência: `etapa00_antes` × `etapa12_depois`, pendências, ideias para o FUTURO).
- [ ] CLAUDE.md/AGENTS.md: `ModalCard`, `Haptics`, configurações novas; Estrutura atualizada.
- [ ] ROADMAP, ART_PIPELINE marcados; commit `feat(ui): comemorações novas, vibração e polimento final`.
  **Avisar o Vitor** para testar no celular (`/dev/`) antes de publicar.
