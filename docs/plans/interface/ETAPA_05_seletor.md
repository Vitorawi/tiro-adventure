# Etapa 05 — Seletor de mundos em carrossel e transição de nuvem

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_05_seletor.md."
> Pré-requisito: Etapas 00–04.

## Objetivo (o que o jogador sente)
"A aba Mapa me leva direto para onde eu estava. Para ir a outro lugar, abro um carrossel bonito com
os mundos, deslizo e toco — e uma nuvem passa na tela enquanto eu viajo."
Fim da lista vertical de blocos grandes com "Abre no capítulo 4".

## Leia antes
`worlds_screen.gd` (`show_map`, `is_map_open`, `enter`, `_build_cards`, `_thumbnail`),
`main.gd` (`_on_tab_pressed`, `_on_world_requested`), `places.gd` (`world_error`, `world_alerts`),
`progression.json → chapters` (nomes dos capítulos), `worlds.json` (`map_name`, `map_caption`, `banner`),
`tests/worlds_test.gd`, `tests/navigation_test.gd`.

## Passo a passo

### 5.1 Aba Mapa abre no mundo
- [x] Ao entrar na aba Mapa, mostra o `current_world` (o último visitado nesta sessão). No começo do jogo,
  `current_world = "house"` (como hoje). Não salvar em disco.
- [x] Tocar na aba Mapa **já estando nela** abre o seletor (hoje volta para a lista).
- [x] A pílula do mundo (`MapButton`, Etapa 04) abre o seletor.
- [x] `show_map()` e `is_map_open()` continuam existindo: agora abrem/consultam o seletor.

### 5.2 Seletor (`MapView` refeito)
- [x] `MapView` vira uma camada por cima do mundo (o mundo atual continua desenhado atrás, com `DIM`),
  em vez de uma tela que esconde o `WorldView`.
- [x] Título "Para onde vamos?" (`TitleLabel`, `INK_ON_DARK` com contorno) no topo, abaixo do HUD.
- [x] Carrossel horizontal (`ScrollContainer` só horizontal + `HBoxContainer`), cartões 240×330 com
  separação 16 e margem lateral para o primeiro/último ficarem centralizados:
  - faixa superior 8 px na cor do mundo (`Palette.WORLD`);
  - miniatura grande (banner ou fundo da sala) **sobre o backdrop do mundo** (degradê `sky` + `ground` da
    Etapa 04), para os cartões não terem fundo escuro;
  - nome (`TitleLabel` 26) + legenda (`map_caption`, `SmallLabel`, uma linha);
  - estado no rodapé: "Você está aqui" (pílula verde), "2 prontos" com `ui_check` (alertas de
    `Places.world_alerts`), ou bloqueado (5.3);
  - selo `!` se algum personagem do mundo tem missão nova/pronta (mesma regra do `_map_badge`).
- [x] **Encaixe (snap):** ao soltar o arrasto, o cartão mais perto do centro desliza para o centro
  (tween 0,2 s). Ao abrir, o carrossel já começa no mundo atual.
- [x] Cartão central um pouco maior (escala 1,0) e os laterais 0,92 com `modulate.a 0.85`.
- [x] Tocar no cartão central aberto = viajar (5.4). Tocar num lateral = centralizá-lo. Bloqueado:
  `Motion.shake` + nada.
- [x] Fechar: tocar fora dos cartões, botão ✕ (`icon_button`) ou arrastar para baixo.
- [x] Nome dos botões: `WorldCard_<mundo>` (os testes procuram). Cartão bloqueado tem `disabled = true`.

### 5.3 Texto do bloqueio
- [x] Nova função `Places.unlock_hint(world_id) -> Dictionary` `{icon, text}`:
  - requisito `chapter: N` → ícone da história + "Na história: <nome do capítulo N>" (nome de
    `progression.json → chapters[N-1].name`, sem o número);
  - requisito `quests: [id]` → retrato do NPC da missão + "Depois de: <nome da missão>";
  - outro requisito → o texto que `world_error` já devolve.
- [x] O cartão mostra `lock_hint` com esse ícone/texto; a miniatura fica com `modulate.a 0.55` e um
  cadeado grande no meio.

### 5.4 Viagem (transição)
- [x] `scenes/ui/world_transition/world_transition.tscn` + `.gd` (`CanvasLayer` acima do mundo e abaixo
  do HUD): duas nuvens grandes (sprites das nuvens da Etapa 04 em escala 6×, ou um retângulo `PAPER` com
  borda arredondada se ficar feio) entram dos lados e se encontram no meio (0,22 s), o mundo troca,
  e elas saem (0,22 s).
- [x] `WorldsScreen.enter(world_id, place)` usa a transição **quando o mundo muda** e a aba já estava
  visível. Entrar pelo "Ir" de missão também usa (a seta e o painel esperam a transição acabar).
- [x] Testes headless: `Motion.reduced = true` → sem transição (troca imediata), para não atrasar.

### 5.5 Ícones de mundo
- [x] Faltam `tab_village.png` (casinha com telhado de telha e toldo) e `tab_nature.png` (pinheiro + pedra +
  riacho) — receita "Ícone 32×32". Use `tab_house`, `tab_farm`, `tab_park` que já existem.
- [x] Campo `"icon"` em `worlds.json` para cada mundo (se não existir) e usar na pílula do mundo e no cartão.

## Testes
- [x] `worlds_test`/`navigation_test`: atualizar onde dependem da lista antiga. Casos novos:
  - aba Mapa abre no mundo atual (não no seletor);
  - tocar de novo na aba abre o seletor; `is_map_open()` verdadeiro;
  - `WorldCard_nature` desabilitado antes do capítulo; `Places.unlock_hint("nature").text` não contém "capítulo";
  - pressionar `WorldCard_farm` (central) entra no Sítio;
  - `Events.world_requested("village", "market")` com `reduced` abre a Vila e o painel da feira.

## Capturas
`etapa05_antes`/`etapa05_depois`: `b05_map_list` (agora o seletor por cima do mundo), `a03_map` (começo:
Sítio bloqueado com "Depois de: …"), `d04_transition` (meio da nuvem — capture com `reduced = false`
esperando 0,2 s).

## Lista de conferência (aceite)
- [x] Aba Mapa abre no mundo; seletor em carrossel com encaixe.
- [x] Bloqueio sem "capítulo N".
- [x] Transição de nuvem entre mundos (alternativa `PAPER` arredondada).
- [x] CLAUDE.md/AGENTS.md (`ui/worlds_screen/` e `ui/world_transition/` na Estrutura; "Botão Ir até lá");
  `docs/WORLDS.md` (ícone do mundo).
- [x] ROADMAP, ART_PIPELINE, README marcados; commit `feat(ui): seletor de mundos em carrossel e viagem com nuvens`.
