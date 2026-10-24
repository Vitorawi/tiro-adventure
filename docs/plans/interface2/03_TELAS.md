# 03 — Telas: hoje → proposta

> Capturas "hoje" em `build/screenshots/interface2_antes/` (nome entre parênteses). Cada linha diz o que
> muda; a etapa que faz está em **[E..]**. **Nós preservados** = nomes que testes procuram; mudar o visual
> não pode sumir com eles (04 §A.5).

## Casca

### HUD (`scripts/ui/hud.gd`) — [E03]
- **Hoje (`a01_pet`):** avatar com anel e número da fase, pílula de moedas escura, engrenagem, selo DEV.
- **Proposta (`tiro.png`):** linha 1 — avatar 58 em disco branco com anel **mel** (crescimento) + pílula de
  perfil "Tiro" com barrinha `3/5` (requisitos da fase) · moedas em pílula **branca** com número Fredoka
  18 · engrenagem vetor em disco 40. Linha 2 (só Tiro e Mapa) — **Próximo passo** à esquerda
  (02 §2) e, na tela do Tiro, as **quatro necessidades** em anéis 40 sem rótulo à direita (tocar mostra
  nome + valor num `Popover`). DEV vira selo pequeno vermelho sobre a engrenagem.
- **Nós preservados:** `TopBar`, `HudAvatar` (propriedade `avatar_button`), `XpRing`, `XpBar` (invisível),
  `LevelBadge`, `LevelLabel`, `CoinsPill`, `CoinsLabel`, `DevButton`, `SettingsButton`, `AvatarAsk`,
  `AnimatedBadge`, `GrowthBadge`, `GrowthQuickGrid`, `GrowthQuick_<id>`, `ViewGrowth`.

### Rodapé de abas (`main.tscn` `TabBar`, `NavTab`) — [E03]
- **Hoje:** barra marrom-escura, aba ativa num círculo branco que sobe.
- **Proposta (`prancha_rodape.png`):** base presa à borda (84, cantos de cima 24), quatro abas iguais com
  ícone pixel 32 numa almofada 60×38 e o **nome embaixo de todas**; ativa = almofada `TAB_ON` + nome em
  `INK`. Selo vermelho no canto da almofada. Versão clara (recomendada) ou madeira (decisão do Vitor).
  `NavTab.attach` continua sendo o ponto de entrada; `lift_node()` passa a ser a almofada.
- **Nós preservados:** `TabBar`, `PetTab`, `MapTab`, `TasksTab`, `BagTab`, `NpcMapBadge` (`WishesTab` só
  aparece num teste antigo que confere que a aba saiu: não recriar).

### Avisos (`main.gd._show_toast`, `MomentNotice`, foto) — [E03]
- **Proposta:** central `Notice` (02 §5): um por vez, tipos erro/momento/foto/info, posição única.
- **Nós preservados:** `Toast` (o nó da pílula continua com esse nome), `MomentNotice`, `MomentIcon`,
  `MomentText`, `FlyingMoment`.

## Tiro

### Cantinho do Tiro (`scenes/ui/pet_screen`, `PetBackdrop`, `PetCareTray`) — [E04]
- **Hoje (`b02_pet`):** cartão de necessidades com rótulos, anel "5" solto, balão "Crescer: Tiro está
  feliz da vida!", cuidados num cartão flutuante com dica em texto.
- **Proposta (`tiro.png`):** cenário **aproximado** (escala 1,75 em vez de 1,25, recorte centrado no
  Tiro); necessidades na linha 2 do HUD; desejo em balão branco com rabinho de bolinhas e ✦; humor numa
  etiqueta pequena translúcida sob o Tiro ("Feliz da vida"), só quando muda ou ao tocar nele; caderninho
  em disco branco à direita; **botão Cuidar + roleta** (02 §7, `tiro_cuidar.png` e `tiro_roleta.png`): um
  botão redondo acima das abas com o ícone do pedido no canto; a roleta abre em leque com cinco discos
  meio transparentes bem espaçados. Sem arte nova.
- **Nós preservados:** `PetScreen`, `MoodLabel`, `WishBubble`, `ManualButton`, `SleepButton`
  (`Visual/Caption`, vira o disco Dormir da roleta), `BrushTile` (disco Escovar), `FoodMenu`, `FavoriteHeart`, `NewTaste`, `NeedPillar_<id>`,
  `AwayView`, `CollectWalk`, `BrushKnot`, `HideSeek*`.

### Cardápio de comida (`FoodMenu`) — [E04]
Guia vertical continua (pedido antigo do Vitor); vira cartão branco 20 com linhas 56: ícone 40 em disco,
nome, quantidade em chip, coração da favorita. "Ele quer!" vira chip mel.

### Caderninho (`PetNotebook`: Manual, Crescimento, Coleção, Truques, Álbum) — [E08]
Folha alta com `segmented` novo (trilho afundado, ativa em pílula branca). Manual em lista agrupada com
rótulos de seção; Coleção em grade 3 colunas de tiles; Truques em linhas.

## Missões

### Aba Missões (`scenes/ui/tasks_screen`) — [E05]
- **Hoje (`a02_tasks`, `b03_tasks`, `g01_tasks_ready_many`):** três abas (Principal/Personagens/Temporárias),
  legenda, personagens com Abrir/Fechar, diárias com descrição repetida e botão "Ir" grande laranja.
- **Proposta (`missoes2_*.png`, 02 §3):** continuam **três abas** (História · Pessoas · Diárias) no
  `segmented` novo com selos; História com o cartão grande + "Neste capítulo"; Pessoas e Diárias em
  cartões-lista de linhas 64 com sanfona; "Pegar tudo (N)" na linha 2.
- **Nós preservados:** `StoryCard`, `SharedQuestGuidance`, `LineCard_<line>` (vira a linha da missão do
  personagem; manter o nome), as funções `choose_group`, `choose_character` e `choose_routine`
  (os nós `Character_<npc>`/`CharacterOpen_<npc>` saem; os testes mudam na 05), `Routines_<kind>`, `Routine_<kind>_<id>`,
  `ReadyDot`, `ClaimAllRoutines`, `QuestDestination`, `GroupTabs`, `Holder`, `Scroll`. Os ids das abas
  continuam `story`, `characters`, `timed` (os testes chamam `choose_group`). Nós novos: `ChapterSteps`,
  `ChapterStep_<id>`, `StoryFull`, `ClaimAllCharacters`.

### Folha de prêmio (nova, `QuestReward`) — [E05]
`missoes_premio.png`: fita, fala, chips grandes, Próximo passo, `Depois` + `Ir para …`. Nós novos:
`QuestReward`, `RewardChip_<item|coins>`, `NextStepCard`, `RewardGo`, `RewardLater`.

### História completa (`ProgressionUi.story_panel`) — [E05]
Capítulos como linhas com ✓ (feitos), o atual expandido com os passos, os próximos apagados com cadeado.

## Mundo

### Mundo e câmera (`RoomView`) — [E06]
Sem mudança de câmera. **Sem etiquetas com nomes** (02 §1.1): `WorldLabel` deixa de aparecer no mapa; vira
o balãozinho do "tocar e segurar" (pílula branca, ícone pixel 20, Nunito 12/800) e o brilho ✦ de lugar
novo. `detail_label`/`overview_label` saem; `label`/`label_pos` dos JSON continuam (nome da bandeja e
posição do balãozinho). **Balões** (`WorldBalloon`): disco
branco com anel 4 px (`SKY` andando / `GO` pronto + ✓ vetor / `HONEY` "+" de compra com preço em chip);
"!" vira pontinho vermelho. Com bandeja aberta, as outras etiquetas esmaecem (alfa 0,35).
- **Nós preservados:** `Pointer`, `PurchaseMarker`, `Region_<id>`, `World_<mundo>`, `RecenterButton`, `DigSpot`.

### Barra do mundo (`WorldBar`, `WorldPill`, `NpcFace`) — [E06]
`fogao.png`: pílula branca com ícone do mundo + nome Fredoka 18 + `⌄` vetor; rostos em discos brancos
44 com sombra; botão Lugares vira ícone `list` em disco. **Nós:** `WorldBar`, `MapButton`, `PlacesButton`,
`WorldTitle`, `NpcRow`.

### Seletor de mundos (`WorldSelector`, `WorldCard`) — [E06]
- **Hoje (`b05_map_list`):** cinco linhas iguais com ícone, nome e "1 achado" — "executiva demais" (Vitor).
- **Proposta (`mundos.png`):** folha alta "Para onde vamos?" com **cartões-postais** em duas colunas: a foto
  do mundo (miniatura pixel com moldura branca e cantos 15), nome Fredoka com o ícone do mundo embaixo,
  chips sobre a foto (rosto de quem tem missão com "!", prontos com ✓ e número), o mundo atual com contorno
  mel e chip "Aqui"; o último mundo ímpar ocupa a largura toda; fechado = foto cinza + cadeado + uma linha
  com o rosto de quem abre ("Depois do baú da Nina"). Toque único viaja (como hoje).
- **Miniaturas:** `tools/world_thumbs.gd` (novo, etapa 06) fotografa cada mundo montado (fundo + objetos
  comprados no save novo) no enquadramento do cartão e grava `assets/sprites/ui/worlds/<mundo>.png`
  (≈ 300×200); o jogo usa a imagem fixa (não captura em tempo real).
- **Nós:** `MapView`, `WorldCard_<mundo>`.

### Conversa com personagem (`ProgressionUi.npc_view/npc_introduction`, `SpeechBubble`, `NpcPortrait`) — [E06]
02 §8. **Nós:** `NpcIntroduction`, `NpcPortrait`.

### Seta até o lugar (`RoomView.point_at`, nó `Pointer`) — [E06]
- **Hoje:** seta amarela poligonal com contorno escuro grosso, pulando.
- **Proposta (`horta_seta.png`, 02 §2.1):** alfinete liso (disco branco + anel mel + ícone do destino +
  rabinho) e anel pulsando no chão. Nó `Pointer` preservado (`intro_test`, `tasks_test`, `tray_test`).

### Viagem entre mundos (`WorldTransition`) — sem mudança.

## Bandejas

### Horta (`PlotTray` → barra da horta `FarmDock`) — [E07]
- **Hoje (`e01_tray_seeds`, `e02_tray_drag`):** a bandeja de sementes abre em cima dos canteiros e o
  arrasto precisa começar no ícone dentro dela.
- **Proposta (`horta_plantar.png`, `horta_colher.png`, 02 §6.1):** barra embaixo, apoiada no rodapé;
  arrastar começa no próprio canteiro; "Colher tudo (N)" verde no modo colher. Canteiro plantando/crescendo
  tocado sozinho continua abrindo o `CareHeader` (anel, tempo, "Regado") num `Popover` sobre o canteiro.
- **Nós:** `CareHeader`; `tray_test` muda junto (`drag_through` passa a começar no canteiro; `tap_item`
  continua para escolher na barra).

### Estações, criações e Natureza (`StationTray`) — [E07]
`fogao.png`: cabeçalho (ícone da estação, nome, ≡ Ver tudo, X), fila em `slot` 52, grade 4×N de tiles 68,
detalhe (nome + chip de tempo, entra → sai, `stepper` + verde). Criações: uma coluna por animal com retrato
em disco; Natureza: escolha de rota em `segmented`. Maestria vira selo pequeno ao lado do nome
(bronze/prata/ouro em vetor mel), detalhe no ≡. **Nós:** `LockedSlot_*`, `GatherItem_*`, `Material_*`,
`RouteChoice_<material>`, `Mastery_<estação>`, `StationTray`, `ActionTray`.

## Mochila e itens

### Mochila (`InventoryList`) — [E08]
- **Hoje (`b04_bag`, `g02_bag_filter`):** quatro barras de depósito em lista, filtros em pílulas, grade com
  "Novo" em tudo.
- **Proposta:** depósitos em **quatro mini-cartões 2×2** (ícone pixel, `12/176` Fredoka, barrinha;
  cheio = barra vermelha); filtros `segmented` com ícones; grade 4 colunas de tiles 76 (ícone 40 + `×9` em
  chip no canto); "Novo" só no que chegou desde a última visita. "Presentes para guardar" vira um cartão mel
  no topo quando houver.
- **Nós:** `PendingGifts`, `GiftsToggle`, `StoreGifts`, `GiftsBlocked`, `Gift_<item>`, filtros de `lists_test`.

### Detalhe do item (`SheetBuilder.item_detail`) — [E08]
Folha meia: ícone 64 no disco, nome, uma linha de uso, chips "Vende por 12", "Na geladeira 4/24", linhas
"De onde vem" com `›`; ação principal verde contextual (Dar ao Tiro, Vender, Ir).

### Álbum (`AlbumView`, `PhotoCard`) — [E08]
Polaroides continuam (são "coisa do mundo"); moldura da tela vira papel liso; seções em `segmented`.

## Painéis grandes — [E09]
- **Crescimento (`GrowthUi`):** grade de passos vira tiles afundados com anel; detalhe em faixa branca;
  `GrowButton` verde. Resumo do avatar (`GrowthQuick_<id>`) em `Popover` branco. Nós `GrowthHero`,
  `CurrentDog`, `NextSilhouette`, `GrowthSteps`, `GrowthReq_<id>`, `GrowthDetail*`, `GrowthNextAction`,
  `GrowButton`, `GrowthHistoryButton`, `GrowthDetails`, `GrowthCard_<fase>`.
- **Feira, Encomendas, Banca (`MarketUi`):** encomendas em cartões 2 colunas (ícones do pedido, prêmio em
  chip mel, quem pede em retrato 28); venda com `stepper`; selos de cliente em vetor mel.
- **Construir/comprar (`ProgressionUi.upgrade_card`, `SheetBuilder.animal_shop`, pet shop):** folha de compra
  (02 §10); lojas em cartões com preço em pílula verde (referência Ms Farm), indisponível em cinza + cadeado.
- **Obras (`ProjectUi`):** fases em `UiKit.steps` grandes; entrega por item com `stepper`.
- **Passeios (`ProgressionUi.walks_panel`, `WalkResult`):** caminhos em cartões com postal; resultado vira
  folha de prêmio (médio) ou cartão grande se raro.
- **Amigos, Truques, Esconde-esconde, Rotas da Natureza (`NatureUi`):** mesmas peças (linhas, tiles, steps).
- **Como fazer (`TaskHelp`):** cadeia em linhas com ícone, `✓` vetor no que já tem, `Ir` calmo em cada passo
  e um verde no primeiro que falta.

## Comemorações e retorno — [E10]
- **`ModalCard`:** cartão `PAPER` 28, fita em pílula colorida (verde: concluído; mel: crescimento/prêmio;
  azul: descoberta), raios mais suaves (alfa 0,35), chips grandes que contam, um verde + um calmo.
  Nós `Celebration`, `CelebrationScroll`, `Confetti`, `WalkResult*`, `WelcomeScroll`, `DailyGift`,
  `Line_*`, `GrowthCeremony`, `BeforeAfter`, `HeightMark`, `CloseCeremony`.
- **Boas-vindas:** folha de prêmio (02 §9).
- **Novo!:** cartão pequeno (médio) com ícone + `Ir`, um por novidade, na fila.

## Outras — [E09/E11]
- **Configurações (`SettingsPanel`):** linhas com interruptor (`toggle` novo, pílula verde/afundada),
  saves em linhas com `›`; versão em legenda. Nós `VibrateToggle`, `ReducedMotionToggle`, `Save_<n>`,
  `NewSave`, `VersionLabel`. Nova preferência **Texto maior** (E11).
- **DEV (`DevPanel`):** só troca de peças; sem redesenho.
- **Chegada da Laís (`IntroScene`):** falas em `SpeechBubble` novo; botão `›`.
