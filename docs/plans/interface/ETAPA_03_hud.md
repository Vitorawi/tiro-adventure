# Etapa 03 — Barra superior flutuante, abas que pulam e aviso novo

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_03_hud.md."
> Pré-requisito: Etapas 00–02.

## Objetivo (o que o jogador sente)
"A barra de cima não é mais uma faixa marrom pesada: é o rostinho do Tiro com o nível e as moedas
flutuando. As abas respondem ao toque." Libera ~50 px de tela e prepara o mundo em tela cheia (Etapa 04).

## Leia antes
`scenes/main/main.tscn` + `main.gd` (`_refresh_top_bar`, `_build_settings_button`, `_build_tasks_badge`,
`_show_toast`, `_ready` das abas), `scripts/ui/collect_fx.gd` (para onde as moedas voam),
`scripts/ui/settings_panel.gd`, `scenes/ui/*/` (margens do topo de cada tela).

## Passo a passo

### 3.1 HUD sobre a tela (não mais na coluna)
- [ ] Tire o `TopBar` de dentro do `Layout` (VBox) e coloque-o como filho direto de `Main`, **depois** de
  `Layout` e **antes** de `Sheet` (fica por cima das telas e por baixo dos painéis), âncora no topo, altura 60,
  `mouse_filter = IGNORE` no fundo (só as peças recebem toque). Fundo transparente.
- [ ] Telas que não são o mundo (Tiro, Desejos, Missões, Mochila) ganham margem superior de 64 para o
  conteúdo não ficar embaixo do HUD (cada tela tem seu `MarginContainer`; ajuste lá). O Mapa **não** ganha
  margem: o mundo vai até o topo (o HUD flutua por cima).
- [ ] Mantenha os nomes `LevelLabel`, `XpBar`, `CoinsLabel`, `DevButton`, `VersionLabel`, `SettingsButton`
  (o `main.gd` e os testes usam). Eles mudam de lugar/aparência, não de nome.

### 3.2 Esquerda: Tiro + nível
- [ ] Botão redondo 52 (`HudAvatar`): fundo `PAPER`, borda 3 `INK`, retrato `hud_tiro.png` (48; crie nesta
  etapa com a receita "Retrato do Tiro para o HUD" de `01 → E`: recorte da cabeça, sem gerar arte nova) e `RingProgress` (`GOLD`, espessura 4) **em volta** mostrando o XP do nível.
- [ ] Selo do nível no canto inferior direito do avatar: círculo 22 `GOLD` com o número (`NumberLabel` 18).
  O `LevelLabel` passa a ser esse número; o `XpBar` fica invisível (mantido para compatibilidade) e o anel
  mostra o progresso.
- [ ] Tocar no avatar → pequeno balão (Popover, some em 2 s ou ao tocar fora): "Nível 5" + barra
  "120/300 XP" + "Próximo presente: [ícones]" (de `progression.json → level_rewards`, se houver).
- [ ] Subiu de nível: `Motion.bounce` no avatar + anel enche até o fim e reinicia.

### 3.3 Direita: moedas e engrenagem
- [ ] Pílula `UiKit.pill(coin, valor)` (altura 40). Ao mudar o valor: `Motion.count_up` (do valor antigo ao
  novo) + `Motion.bounce` quando aumenta; `Motion.shake` quando o jogador tenta gastar sem ter (escute o
  toast de erro "moedas"? Não: crie `Events.coins_short` **só se** necessário; senão, sem shake).
- [ ] `CollectFx`: as moedas que voam devem terminar **na pílula** (pegue a posição global do nó
  `CoinsLabel`). Confira o destino atual no `collect_fx.gd` e ajuste.
- [ ] Engrenagem = `UiKit.icon_button(settings, …, 44)`, sem o fundo marrom.
- [ ] `DEV`: pílula pequena `DANGER` "DEV" **abaixo** da pílula de moedas (alinhada à direita, 24 px de
  altura). `VersionLabel` sai do HUD e vai para o rodapé do painel de configurações (mantém o atalho: tocar
  na versão força a atualização).

### 3.4 Abas
- [ ] Barra de abas: fundo `INK` com 92% de opacidade, cantos 22 em cima, altura 72, sombra para cima.
- [ ] Aba normal: ícone 32 + texto 16 `INK_ON_DARK` 70%. Aba ativa: círculo `PAPER` 52 atrás do ícone,
  ícone 36, sobe 6 px (tween 0,15 s), texto 100%. Ao tocar: `Motion.bounce` no ícone.
- [ ] Selos (`_tasks_badge`, `_map_badge`, `_wishes_badge`) usam `BadgeLabel` e ficam no canto superior
  direito do **ícone** (não da aba): posição = centro + (14, −20).
- [ ] O pulsar da aba Missões no começo (`_tasks_pulse`) troca a cor por `Motion.pulse` (escala) + uma
  seta pequena apontando (ponteiro existente `Pointer`, se for fácil) — sem frase "Veja suas missões aqui
  embaixo!" na tela do Tiro (essa frase sai na Etapa 09; aqui só a aba).

### 3.5 Aviso (toast)
- [ ] Sai do meio/topo por cima dos botões e passa a ser uma pílula `HUD` que **desce** de y=−40 até y=68
  (logo abaixo do HUD), centralizada, largura até 320, texto `INK_ON_DARK` 20, quebra em 2 linhas no máximo.
- [ ] Fila curta: se chegar outro aviso enquanto um está na tela, troca o texto com um pulinho
  (`Motion.bounce`) e reinicia o tempo (1,6 s + 0,3 s para sumir).
- [ ] Ícone opcional: se o texto começar com "Missão concluída" use `ui_check`; erros (textos que vêm de
  `*_error`) não têm marcação — **não** invente parser; só o caso da missão, que o `main.gd` emite.
- [ ] Nome do nó continua `Toast`.

### 3.6 Banner de atualização
- [ ] `UpdateBanner` vira pílula `ACCENT` abaixo do HUD ("Nova versão! Tocar para atualizar"), sem cobrir o avatar.

## Testes
- [ ] `game/tests/hud_test.gd` (novo): ganhar 50 moedas → `CoinsLabel.text` termina em "50" a mais (com
  `Motion.reduced`); `LevelLabel` mostra o nível; `DevButton.visible == BuildInfo.is_dev()`; o `TopBar` não
  está dentro do `Layout`; toast duas vezes seguidas mostra o último texto.
- [ ] `dev_tools_test`, `saves_test` (SettingsButton), `wishes_test` (WishesTab/BagTab) continuam passando.

## Capturas
Tour `etapa03_antes`/`etapa03_depois` + capturas novas `c06_hud_popover` (balão do nível) e `c05_toast`
com o mundo aberto. Confira em 390×844 e 412×915.

## Lista de conferência (aceite)
- [ ] HUD flutua; nas abas sem mundo nada fica escondido embaixo dele.
- [ ] Moedas contam e as moedas do `CollectFx` chegam na pílula.
- [ ] Aba ativa sobe e pula; selos no ícone.
- [ ] Aviso aparece abaixo do HUD, nunca sobre botões.
- [ ] CLAUDE.md/AGENTS.md: `main/` na Estrutura ("HUD flutuante: avatar com XP, moedas, DEV") e Configurações (versão no rodapé).
- [ ] ROADMAP e README marcados; commit `feat(ui): HUD flutuante, abas animadas e aviso novo`.
