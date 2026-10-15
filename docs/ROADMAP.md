# Roadmap

## Estado atual (passagem de bastão entre agentes)
> Atualize esta seção ao terminar cada tarefa: é por aqui que Claude Code e Codex continuam o trabalho
> um do outro. Última atualização: **15/10/2026, Codex (revisão visual da Interface nova, Etapa 04)**.

**▶ PLANO ATUAL (15/10/2026): Interface nova — `docs/plans/interface/README.md`.** Aprovado pelo Vitor
("vamos nessas ideias mesmo"). 13 etapas (00–12), executar **uma por vez, na ordem**, com o prompt do README.
Leitura obrigatória: `00_VISAO.md` (diagnóstico, referências, esboços) e `01_REGRAS_E_ESTILO.md` (regras,
paleta, medidas, componentes, movimento, glossário de textos, receitas de arte). Só interface: regras, números
e save (`SAVE_VERSION` 12) não mudam. Rascunho do tour de capturas usado no diagnóstico: `docs/plans/interface/ui_tour_rascunho.gd`
(já virou `game/tests/ui_tour.gd`). **Próximo passo: Etapa 05 (`docs/plans/interface/ETAPA_05_seletor.md`).**

**✔ Revisão da Etapa 04 concluída (15/10/2026, Codex, continuando o Claudi).** Base `7e84772`, com seis arquivos locais preservados e revisados por autorização do Vitor. O pedido após a entrega foi "deixa mais textura no chão". Commit local, sem push; próxima: Etapa 05.
- `WorldGround` (`scripts/ui/world_ground.gd`) repete uma textura PixelLab de grama (`backdrop.ground_texture`) com brilho ajustado ao chão de cada mundo. Textura e cobertura da borda usam as mesmas coordenadas do mapa e acompanham arrasto/zoom; não criam estado salvo.
- Os quatro mundos externos agora escondem a lateral de terra inteira: o contorno de baixo passa do fundo do PNG, eliminando os riscos escuros que sobravam na tentativa local do Claudi. A Casa mantém o fundo quente ajustado, mas voltou a `framing: width` para não cortar as laterais. Nuvens/névoa continuam desligadas nos JSON, preservando a simplificação visual iniciada por ele.
- O aviso no mundo usa `WorldsScreen.toast_top()`: aparece abaixo da pílula e dos rostos, inclusive na Vila com dois personagens. Nas outras telas mantém a posição da Etapa 03.
- Corrigida também a pendência do painel alto: `Places.open(..., from_object=true)` marca estações tocadas no mapa como `sheet_size: half`; a Bancada fica visível acima do painel e a alça ainda amplia a consulta. Listas/atalhos seguem automáticos. O `d03_sheet_over_object` do tour agora abre a Bancada de verdade (antes abria o Silo). Isso usa a peça da Etapa 02; nenhuma bandeja da Etapa 08 foi antecipada.
- Arte: duas tentativas de grama 128×128; a primeira ficou densa demais no jogo. Escolhida a segunda, esparsa e de baixo contraste. Jobs, originais e prancha no `ART_PIPELINE.md`.
- **Validação final:** 33 execuções PASS, uma por vez, incluindo DEV em prod; logs em `build/test_logs/etapa04/revisao/`. `world_view_test` cobre grama/UV, cobertura inteira da terra, Casa sem cortes, aviso livre dos controles e Bancada acima do painel. Já constava do `tools/test_all.ps1`; nenhum teste novo ficou fora da suíte. Avisos antigos de recursos/RID no encerramento de `park_test`/`ui_style_test` permanecem (PASS e saída 0).
- **Capturas:** 45 PNGs por tour, em `build/screenshots/etapa04_revisao_antes`, `etapa04_revisao_depois`, `etapa04_revisao_depois_390` e `etapa04_revisao_depois_412`. Comparação das 45 telas nos três tamanhos em 23 pranchas `build/preview/etapa04/revisao_comparacoes/`, abertas e conferidas; `revisao_mundos_final.png` mostra os cinco mundos juntos. Os tours e logs originais foram preservados.
- **Web/toque:** export prod/dev PASS; `tools/touch_test.ps1` com `build/touch_steps_etapa04_revisao.json`, 390×844, confirmou arrasto/inércia, elástico, pinça, duplo toque, centralizar e toque no nome da Bancada (x 282, y 120 CSS após centralizar). Painel em meia altura e Bancada acima dele, sem erros no console. PNGs/console preservados em `build/touch_test_etapa04_revisao_final/`; pranchas `revisao_touch_gestos.png` e `revisao_touch_zoom_painel.png`. Servidor encerrado.
- **Aceite 4.1–4.5 conferido:** fundo completo e coerente; Sítio com horta grande/Casa inteira/Praça e Vila preenchendo a largura; gestos funcionando; sem +/− e centralizar só quando precisa; barra flutuante sem cabeçalho; documentação/arte atualizadas; README marcado e commit local. Nuvens desligadas e chão texturado são os ajustes visuais desta revisão, sem bandejas antecipadas.
- **Pendências:** nenhuma obrigatória desta revisão. Cortes antigos nas linhas compridas do fogão (já no antes) ficam para as Etapas 08/10. A lista de mundos ainda é a atual: a Etapa 05 fará o seletor. Não foi implementada nenhuma parte dela; `SAVE_VERSION` continua 12. Nova sessão da Etapa 05 será criada no Codex após o commit (a ferramenta de sessões do Claude remoto não está disponível nesta conversa), com o roteiro completo e a instrução de encadear até a 12.

**✔ Interface nova — Etapa 04 (mundo em tela cheia: céu, paisagem e câmera gostosa) concluída (15/10/2026, Claude Code). Commit local, sem push. Próxima: Etapa 05 (`ETAPA_05_seletor.md`).**
- `SAVE_VERSION` continua 12; nenhuma regra/número/save mudou. Só interface (`Events.sheet_closed` é um sinal novo, sem estado).
- **Fundo (`backdrop`)** em `rooms/<id>.json` (formato e campos em `docs/WORLDS.md`): `room.tscn` trocou o `Void` por `Backdrop` (`Void` só como reserva, `Sky`, `Ground`, `Clouds`, `Far`), montado por `RoomView._setup_backdrop/_layout_backdrop`.
  Céu = degradê até o horizonte; chão = cor lisa; `Far` = faixa de paisagem em escala inteira com parallax 0,25 (limitada à sobra da largura); nuvens por `_process` (4 nuvens, 6–12 px/s, escala 2, alfa 0,9; semente = nome da sala) e, na Natureza, `"clouds": "mist"` (3 nuvens grandes a 20%, 3–5 px/s).
  Desvio: **`horizon`** (novo, fração da altura da tela no enquadramento inicial; padrão 0,42) porque a faixa de paisagem precisa ficar na altura do fundo da maquete (Sítio 0,2, Praça/Vila/Natureza 0,3, Casa 0,42).
- **Os mapas tiveram o fundo escuro "assado" no PNG** (`farm_animals`, `room`, `park`, `banner`): virou transparente por preenchimento a partir das bordas (`Invoke-ClearCorner`, novo em `tools/pixel_tools.ps1`; originais em `build/art_sources/interface_etapa04/originais/`). Sem isso o céu não aparece. `nature.png` já era transparente. As miniaturas da lista de mundos melhoraram de graça.
- **Borda da maquete — A × B:** testei as duas no Sítio. **A (`edge_cover`, polígono com a cor `ground` sobre a terra da lateral) ganhou no Sítio**: a maquete ocupa a tela toda e "assenta" no gramado. Em Praça, Vila e Natureza ficou a **B (terra à mostra)**: lá a maquete é uma ilha menor e o bloco com terra lê melhor como "ilha no gramado"; cobrir viraria um tapete de grama sobre grama lisa. `edge_cover` aceita um polígono ou lista (`edge_cover_color` troca a cor); `tools/edge_cover.ps1 <png>` sugere o contorno (o do Sítio foi ajustado à mão: topo 5 px acima da borda da grama, fundo 12 px abaixo da terra). O chão ficou liso (um degradê/neblina no chão deixava o retângulo do `edge_cover` aparecer).
- **Câmera** (`room.gd`): `framing` (`width` padrão/`height`/`fit`), `_initial_zoom()`, `_min_zoom()` (padrão = o menor entre a sala inteira e a abertura), máx. 2,0; `view_center` padrão = meio da maquete. Valores: Sítio `initial_zoom 1.0` + `view_center [562, 250]` (antes 0,62), Casa `framing width` (0,57), Praça e Vila `initial_zoom 0,85`, Natureza `width` (0,7).
  Arrasto elástico (passa 48 px e volta em 0,2 s), **inércia** (velocidade dos últimos 80 ms, ×0,9 por quadro a 60 fps, para < 10 px/s; bate na borda e para só naquele eixo), **duplo toque** só se o primeiro caiu em área vazia (`_handle_tap` agora devolve `bool`; 300 ms/24 px; < 1,4 → 1,6 no ponto, senão enquadramento inicial), `zoom_to(pivô, zoom, s)` e `recenter()` animados (`_tween_camera`; `Motion.CAMERA` 0,25 e `Motion.SETTLE` 0,2; `Motion.reduced` aplica na hora), `point_at` agora **desliza** até o alvo.
  `ZoomControls` ficou escondido (nós mantidos); `RecenterButton` (`ui_recenter`, `icon_button` 44, canto de baixo à direita **acima** da barra de abas) aparece quando o zoom difere > 15% ou o centro > 120 px do enquadramento inicial.
  **Achado no teste de toque real:** o botão do `UiKit` tem `mouse_filter` PASS e, sendo filho da sala, o toque no "centralizar" também chegava ao mapa (abriu a compra "Animais · Expandir"). Agora é STOP (e há asserção no teste).
  **Painel por cima do objeto** (`_lift_for_sheet`, só no `_on_object_tapped` padrão): objeto com y de tela > 45% sobe a câmera para 30%; pode passar da borda do mundo o necessário (a maquete do Sítio é menor que a tela em 360×780) e, **ao fechar o painel, só volta ao limite do mundo** (`Events.sheet_closed`, emitido por `Sheet.close()`; espera 1 quadro para não desfazer ao trocar de painel). O painel de Produção/Galinheiro tem 88% da altura: o objeto sobe, mas o painel alto ainda o cobre (a "Bancada visível acima do painel" só vale para painéis curtos; a Bancada fica no alto do mapa e nem precisa subir).
- **Cabeçalho do mundo saiu**: `WorldView` virou `Control` em tela cheia (sem `offset_top` 60; `Header` removido); `WorldBar` (z 2, ignora o mouse, y = 64) tem à esquerda `MapButton` = **`WorldPill`** (novo, `scripts/ui/world_pill.gd`: ícone 32 do mundo + `map_name` + seta desenhada, fundo `PAPER`, borda 2 em `Palette.WORLD`, todos os estados com o mesmo stylebox; abre a lista de mundos) e `PlacesButton` (`UiKit.icon_button` 44 com `tab_tasks`, painel sempre "Lugares"; a Natureza não tem mais "Locais"), e à direita `NpcRow` (coluna de **`NpcFace`**, novo, `scripts/ui/npc_face.gd`: círculo 48 com retrato recortado por `draw_colored_polygon` com UV, selo "!" `BadgeLabel` ou `ui_check`, pulso quando pronta, sem nome). `WorldTitle` ficou escondido só para os testes.
  Os nós `MapButton/PlacesButton/NpcRow/WorldTitle` são criados em `_build_world_bar` com `unique_name_in_owner` (os `%` continuam funcionando).
- **Etiquetas** (`_nudge_labels`, em toda mudança de câmera): a que sairia pelas laterais por menos que a largura é empurrada para dentro (8 px); totalmente fora fica onde está.
- **Arte (PixelLab, ver ART_PIPELINE):** 4 faixas de horizonte 480×192 (todas na 1ª tentativa), `cloud_1` (1ª) e `cloud_2` (3ª; o Pixen só aceita lado curto < 32 se for quadrado, então 64×32), `ui_recenter` (3 jobs em paralelo, escolhido o do seed 5).
- **Testes:** novo `world_view_test` (no `test_all.ps1`): fundo cobre a tela em cada mundo, enquadramentos (Sítio zoom 1,0 com os 9 canteiros na tela, Casa com o Tiro à vista, Praça/Vila 0,8–0,9, Natureza `width`), zoom mínimo/máximo, +/− escondidos, `RecenterButton`, elástico, inércia, duplo toque (perto/longe/devagar), toque simples abre a Bancada na hora, barra do mundo (pílula, rostos, selos), etiquetas inteiras, painel que sobe o galinheiro. `navigation_test` agora compara com `_initial_zoom()/_min_zoom()`; `worlds_test` não espera mais o texto "Locais". `animals_test`/`world_life_test` (`_zoom_at(…, 0,3)`) continuam passando: o zoom mínimo do Sítio é o `_fit_zoom()` (0,298). Suíte inteira um a um: 33 PASS (logs em `build/test_logs/etapa04/`).
- **Capturas:** `build/screenshots/etapa04_antes|depois` (360×780), `_depois_390`, `_depois_412`; o tour ganhou `d01_farm_zoom_out`, `d02_farm_doubletap`, `d03_sheet_over_object`; `tests/world_shots.gd` faz capturas rápidas dos mundos. Teste de **toque real** (`build/touch_steps_etapa04.json`, `tools/touch_test.ps1`, 390×844): arrasto com inércia, pinça, duplo toque, "centralizar" e toque na Bancada funcionam (o roteiro entra pela DEV: intro → Ferramentas DEV → Progresso → capítulo 6).
- **Pendências / avisos:** (1) a lista de mundos (`MapView`) continua igual (Etapa 05 faz o seletor); (2) a Casa abre pequena (0,57, largura da tela) — se parecer pouco, subir `initial_zoom`; (3) as faixas de paisagem de Praça/Sítio são baixas e ficam quase todas atrás da maquete; (4) `_lift_for_sheet` não vale para painéis de compra ("+") nem de canteiro (Etapa 07 troca o canteiro pela bandeja); (5) o aviso (toast, y 68) ainda cobre a pílula do mundo por 1,6 s; (6) NPCs do `NpcRow` sem retrato usam o ícone do `npcs.json` (Artesã: toras).

**✔ Interface nova — Etapa 03 (HUD flutuante, abas que pulam, aviso novo) concluída (15/10/2026, Claude Code). Commit local, sem push. Próxima: Etapa 04 (`ETAPA_04_mundo_cheio.md`).**
- `SAVE_VERSION` continua 12; nenhuma regra/número/save mudou.
- **HUD** (`scripts/ui/hud.gd`, `class_name Hud`, nó `TopBar` agora filho direto de `Main`, depois do `Layout` e antes do `Sheet`, `z_index` 8, `mouse_filter` ignora): construído em código.
  Esquerda: botão redondo 52 `HudAvatar` (papel, borda 3 `INK`, retrato `hud_tiro.png`) dentro de um `RingProgress` de 60 (ouro, trilho `Palette.HUD`) com o XP do nível; selo ouro 22 no canto de baixo à direita com o número (`LevelLabel` = só o número, "5").
  `XpBar` continua existindo mas invisível. Tocar no avatar abre o balão do nível (`Hud.show_level_popover`, usa o novo `Popover`): "Nível N", barra, "x/y XP" e "Próximo presente" com `ProgressionUi.reward_chips(GameState.level_reward(nível+1))`; some em 2 s ou ao tocar fora.
  Subiu de nível: `Motion.bounce` no avatar + o anel enche até o fim e recomeça do que sobrou. Direita: `UiKit.pill(coin)` (agora com o número chamado `Value`, renomeado `CoinsLabel` no HUD), engrenagem `UiKit.icon_button(settings, 44)` (`SettingsButton`) e, só na dev, o selo `DEV` (pílula `DANGER` 24 px, `DevButton`) embaixo das moedas.
  Moedas: `Motion.count_up` + `Motion.bounce` quando sobe; a pílula mora num `Control` simples (`CoinsHolder`) para o pulinho não brigar com o container.
- **`VersionLabel` saiu do HUD** e virou rodapé do painel de Configurações (`SettingsPanel._version_label`; tocar força a atualização).
- **CollectFx:** as moedas sobem 0,4 s e voam 0,45 s até o centro de `CoinsLabel` (`Hud.coins_target()`), encolhendo; itens continuam subindo e sumindo. Cores soltas do `collect_fx` trocadas por `Palette`.
- **Abas:** `TabBar` (`PanelContainer`, tema novo `TabBarPanel`: `INK` 92%, cantos 22 em cima, sombra para cima, altura 72) contém o `Tabs`. Cada aba ganha um rosto (`scripts/ui/nav_tab.gd`, `NavTab.attach`): ícone 32 e nome 18 a 70%; ativa = círculo `PAPER` 52, ícone 36, sobe 6 px (0,15 s `Motion.TAB`) e nome a 100%; `Motion.bounce` no ícone ao tocar. O botão deixa de ter texto/ícone próprios (estilos todos vazios).
  Selos (`_tasks_badge`, `_map_badge`, `_wishes_badge`) ficam em centro do ícone + (14, −20). Pulso da aba Missões no começo = `Motion.pulse` no círculo+ícone (sem trocar cor). `Layout` tem separação −22: a barra de abas cobre 22 px do fim das telas (cantos arredondados mostram o conteúdo); por isso as telas sem mundo ganharam margem inferior 30–34.
- **Margens:** Tiro/Desejos/Missões/Mochila e a lista de mundos (`MapView`) agora têm 64 px em cima. O mundo (`WorldView`) começa 60 px mais abaixo (`offset_top = 60`) por causa do cabeçalho "Mundos/Lugares", que continua existindo até a Etapa 04.
- **Aviso (`Toast`)**: agora um `PanelContainer` (pílula `PillPanel`, ícone `ToastIcon` + `ToastText` 20, máx. 320 de largura, 2 linhas) que desce de y −40 até 68 (116 se o banner de atualização estiver aberto), fica 1,6 s e some em 0,3 s. Um segundo aviso enquanto o primeiro está na tela troca o texto, dá um pulinho e reinicia o tempo. "Missão concluída…" leva `ui_check` (único caso). `UpdateBanner` virou pílula `ACCENT` ("Nova versão! Tocar para atualizar") centralizada em y 64.
- **Desvios:** (1) nome das abas em 18, não 16 (regra geral "texto legível nunca abaixo de 18"); (2) sem `Events.coins_short` e sem shake das moedas (nenhum sinal de "faltou moeda" existe; criar só se uma etapa futura precisar); (3) ainda **não há setinha** no pulso da aba Missões (o "Pointer" só vive nos mundos); (4) `TopBarPanel` e o estilo `top_bar` do tema ficaram sem uso (não removidos para não mexer em teste de tema).
- **Arte:** só `ui/icons/hud_tiro.png` (recorte da cabeça do Tiro, sem PixelLab; receita em `docs/ART_PIPELINE.md`).
- **Testes:** novo `hud_test.gd` (no `test_all.ps1`): `TopBar` fora do `Layout`, nomes mantidos, moedas +50 e volta, anel de XP, dois avisos seguidos, ícone da missão, largura ≤ 320, abas ativa/inativa, balão e fechar tocando fora, moedas do `CollectFx` com destino dentro da pílula. Suíte inteira um a um: ver lista no commit (logs em `build/test_logs/etapa03/`).
- **Capturas:** `build/screenshots/etapa03_antes|depois` (360×780), `etapa03_depois_390`, `etapa03_depois_412`; o tour ganhou `c06_hud_popover` (o `c05_toast` já era com o mundo aberto); `tests/hud_shots.gd` faz capturas rápidas do HUD (balão, aviso longo, banner, moedas voando, configurações).
- **Pendências / avisos para as próximas etapas:** no Mapa o aviso (y 68) cai sobre o cabeçalho "Mundos/Lugares", e o selo DEV encosta nele; some quando a Etapa 04 tirar o cabeçalho. Botões `+`/`−` do mapa ficam parcialmente sob a barra de abas (a Etapa 04 os remove). `Hud` não lê `Motion.reduced` do save (igual à Etapa 00).

**✔ Interface nova — Etapa 02 (painel novo) concluída (15/10/2026, Claude Code). Commit local, sem push. Próxima: Etapa 03 (`ETAPA_03_hud.md`).**
- `SAVE_VERSION` continua 12; nenhuma regra/número/save mudou.
- **Sheet** (`scenes/ui/sheet/`): painel preso embaixo, altura por `offset_top`. `content.set_meta("sheet_size", "half"|"tall")` (`SheetBuilder.tall(...)` marca); sem meta = automático (cabe em 55% → altura do conteúdo, mín. 30%; senão 88% com rolagem), medido 2 quadros depois de abrir e a cada `minimum_size_changed` (tween 0,18 s só se mudar > 24 px). Marcados `tall`: Mochila, Coleção, Manual, Diário, Vender/Feira, História. `Places._with_upgrades` repassa a meta.
  Alça (`Handle`, 40×5) + título + faixa de 28 px do topo arrastam; > 25% da altura ou > 900 px/s fecha, para cima vira alto, senão volta (`TRANS_BACK`). Botão fechar = `UiKit.icon_button(ui_close, 44)` criado no código (continua `CloseButton`). Fade de 0,12 s ao trocar conteúdo. Novos `Motion.FADE/RESIZE/CLOSE` e `Motion.fade_in`.
  **Fechar:** `close()`/`sheet_close_requested` esvazia o conteúdo na hora (`is_open()` falso, como pede a opção "mais segura") e só o fundo desliza 0,2 s; `visible` fica verdadeiro até acabar. `is_open()` e `panel_height()` são novos.
- **`SlotDot`** (`scripts/ui/slot_dot.gd`, `UiKit.slot_dot`): vazio tracejado, na fila, produzindo (`RingProgress` + tempo), pronto (anel verde + check 16 + pulso), "+" com preço, cadeado "Nível N". `SheetBuilder.slot_frame` (mesma assinatura + `queued`) desenha por ela; `slot_flow()`/`slot_strip()` = fileira + "Pegar tudo (N)" ao lado. Valem para estações, Natureza, rotas e passeio (`WalkSlot` virou bolinha + postal/ação ao lado; `CollectWalk`/`CancelWalk`/`LockedSlot_*`/`GatherItem_*` mantidos). Rótulos "Preparando 0/3", "Coletas · 0/3", "Em andamento 0/1" saíram; legenda vazia some. Desvio: o pulso do "pronto" é calculado no `_process` pelo relógio (não `Motion.pulse`), porque o `LiveBox` reconstrói a cada segundo e reiniciaria o tween. Quantidade "×N" saiu da legenda dos espaços.
- **`UiKit.list_row`** (+ tema `RowPanel`): `[ícone 48][título][ação]` e chips embaixo na largura toda (desvio: título e chips não cabem na mesma linha em 360 px). Aplicada em receitas, sementes, comidas, vender, materiais da Natureza e rotas; linha fechada = apagada + `lock_hint` no rodapé. Para caber 4 receitas: chip com margens 4/1, `RowPanel` 8/5, painel com margens 10/14, alça 16, separação do `LiveBox` 8. Efeito: **fogão sozinho mostra 4 receitas inteiras sem rolar em 360×780** (teste); com liquidificador liberado o título "Fogão" ocupa ~40 px e a 4ª aparece pela metade. Textos: "Coletar prontos/Recolher prontos" → "Pegar tudo (N)", "Recolher" (rotas/passeio) → "Pegar", "Coletar" (Natureza) → "Buscar"; o resto do glossário fica para a Etapa 11. "Receitas" só aparece em criações.
- **Título único:** `stations_view` só nomeia a estação se houver > 1 liberada; "Construir" genérico trocado pelo nome da construção; item usa o nome. **Fala em balão:** `SpeechBubble` (balão + rabinho + etiqueta com nome) em `ProgressionUi.npc_header`; retrato 96 embaixo; Laís abre com painel baixo.
- **Desvio:** arrastar valendo "quando a rolagem está no topo e o dedo desce" **não** foi feito (soltar o dedo sobre um botão dispararia o botão); só alça/título/topo.
- **Testes:** novo `sheet_test` (alturas, fechar, arrasto, título, 4 receitas, bolinhas/linha) no `test_all.ps1`; os 31 passam um a um (`build/test_logs/etapa02/`). `park_test` falhou 1 vez por sorteio ("destino da Pipoca perto da Nina", flaky antigo; 3 reexecuções PASS). `ui_style_test.gd.uid` (esquecido na Etapa 01) entrou no commit.
- **Capturas:** `build/screenshots/etapa02_antes|depois` (360×780), `_depois_390`, `_depois_412`; pranchas em `build/preview/etapa02/`. Tour ganhou `b25_stove_busy`; `tests/sheet_shots.gd` (fogão, arrasto, Bosque) para conferências rápidas.
- Pendências: `Canteiro`/`Plantação` ainda são títulos genéricos; botões "Passear" e "Ir" das missões seguem verdes (Etapas 05/06/10).

**✔ Interface nova — Etapa 01 (visual: cartão não é botão) concluída (15/10/2026, Claude Code). Commit local, sem push.**
- `SAVE_VERSION` continua 12; nenhuma regra/número/save mudou. Quase tudo no tema e no `UiKit`, então vale para o jogo inteiro.
- **Tema** (`main_theme.tres`, editado, não recriado; cores em decimais = `Palette`): cartão sem degrau (borda 2 `CARD_LINE`, sombra suave, cantos 14), `ReadyCardPanel`
  com borda verde 3 e fundo levemente esverdeado, chip = pílula `SUNKEN` sem borda, `Button` = secundário mel com degrau 5 que afunda ao tocar, `PrimaryButton` verde com texto
  branco contornado (desabilitado = verde apagado), painel do `Sheet` sem borda e com sombra para cima, tipografia título 30 / seção 22 `INK_SOFT` / pequeno 18.
  Variações novas: `SecondaryButton`, `GhostButton` (sem fundo, texto suave com **sublinhado de 2 px** — desvio do "stylebox vazio" do plano, para parecer tocável, como pede B.4),
  `IconButton` (círculo `CARD`), `PillPanel`, `NumberLabel`, `BadgeLabel`. Painel padrão (`PanelContainer`) e barras (`ProgressBar`) também ganharam as cores novas.
- **`UiKit`:** `primary`, `secondary(small)`, `ghost`, `icon_button`, `pill`, `lock_hint`, `lock_icon`; `square_button` (mesma assinatura) agora devolve `icon_button`;
  `UiKit.button` chama `Motion.press`. `WishUi.LockIcon` (cadeado desenhado em código) foi removida e trocada por `UiKit.lock_icon()` (ícone `ui_lock`).
- **Um botão verde por painel (tabela 1.3):** sementes, comidas (só "Ele quer!" fica verde, e só a primeira), receitas das estações, materiais da Natureza, diárias ("Ir" mel; pronta = verde "Pegar prêmio"),
  coleção/Pet shop (Vestir/Tirar/Comprar), vender, desejos ("Ir" mel; "Dar/Receber" verde), encomendas e rotas (`_action(..., primary = false)`). Também viraram mel: "Ir" do cartão "Que bom que você voltou",
  "Ir até lá" do Manual, "Jogar" por save, "Mostrar/Treinar" dos truques, "Dar petisco" e "Receber" do conjunto de achados. Abas Vender/Encomendas e Recursos/Estações: aba atual = mel, as outras = fantasma.
- **Cadeado:** construção bloqueada por **requisito** (não por moedas) e encomenda bloqueada mostram `lock_hint` (cartão a 55% + motivo + "?"), sem botão; receita e planta fechadas idem. Falta de moedas continua botão desabilitado com o preço em vermelho.
  Natureza: material de nível ainda fechado mostra o cadeado "Nível N", mas o `Material_<item>` continua existindo **escondido e desabilitado** (os testes de `nature_test` apertam esse botão).
- **Cores soltas trocadas por `Palette`:** `worlds_screen._build_cards`, selos de aba do `main.gd` (agora `BadgeLabel`), barra de XP, pisca da aba Missões, barras de tempo dos espaços (`Palette.INFO`), pontinhos de passo.
  **Ficaram para as etapas seguintes** (`Color("...")` em `plot_/station_/route_/walk_indicator` → Etapa 06; `intro`, `celebration`, `walk_result`, `trick_training`, `pet_screen` → Etapas 09/12; roxo do "LENDÁRIO" e silhueta em `progression_ui`, rosa da barra de vínculo em `wish_ui`).
- **Arte (2 ícones, 1ª tentativa cada):** `ui_close` (agora o "✕" do botão de fechar do `Sheet`, 48 px) e `ui_check` (ainda sem uso; vai nos balões da Etapa 06). Registro em `docs/ART_PIPELINE.md`.
- **Teste novo** `ui_style_test.gd` (no `test_all.ps1`): tema (cartão sem degrau, degrau do botão, variações), peças do `UiKit`, `lock_hint` com `ui_lock`, construção bloqueada = cadeado sem botão verde,
  e ≤ 1 `PrimaryButton` visível e habilitado em fogão, sementes, comida, Natureza, coleção, vender, encomendas e rotas. As classes de interface só são carregadas em tempo de execução
  (elas usam o autoload `Database`, que não existe ao compilar o script de teste).
- **Testes:** os 30 passam rodando um a um (logs em `build/test_logs/etapa01/`). Lembrete: `test_all.ps1` aborta no `park_test` por um aviso antigo de encerramento ("N resources still in use at exit"); não é regressão.
- **Capturas:** `build/screenshots/etapa01_antes` × `etapa01_depois` (360×780) e `etapa01_depois_390`, `etapa01_depois_412` (40 PNGs cada). Nada corta nem estoura nos três tamanhos. Pranchas lado a lado em `build/preview/etapa01/`.
- **Pendências / observações para as próximas etapas:**
  - `Manual`, `Atributos`, `Coleção` e a fala do Tiro na aba Tiro são `ChipButton`/chip: a pílula `SUNKEN` sem borda tem pouco contraste sobre o fundo bege/marrom. A Etapa 09 refaz essa tela.
  - Destaques de "pronto" em lista continuam `PrimaryButton` (Lugares/personagens no `places.gd`, chips de NPC no cabeçalho do Mapa); Etapas 05/06 trocam por indicadores.
  - Botões-bloco ainda com fonte 16 (tiles da Mochila e dos canteiros, chips de NPC, "Refinar"): ficam para a Etapa 10; selos de aba já são 16 pelo `BadgeLabel`.
  - Textos continuam os antigos ("Conclua: …", "Produzir", "Recolher"): só a Etapa 11 troca. Única exceção: o botão da diária pronta agora diz "Pegar prêmio", como manda a tabela 1.3.

**✔ Interface nova — Etapa 00 (base) concluída (15/10/2026, Claude Code). Commit local, sem push.**
- `SAVE_VERSION` continua 12; nenhuma regra/número/save mudou. Só ferramentas, constantes, ícones e um bug de enquadramento.
- **Tour de capturas** `game/tests/ui_tour.gd` (rascunho do plano + completado): 40 PNGs numerados (`a01–a05` começo, `b01–b24b` jogo avançado,
  `c01–c05` cartões/toast) em `build/screenshots/<--out>/`. Rodar SEM `--headless`: `--resolution 360x780 -s res://tests/ui_tour.gd -- --out=<pasta>`.
  Não entra no `test_all`. Decisão: o `SaveManager` **fica** (o painel de Configurações lista os saves), mas o tour desliga o autosave
  (`state_changed` desconectado, Timers removidos, `_save_path` num arquivo descartável); nada do save pessoal é gravado.
  Acrescentei `b22b_places_list` ("O que tem aqui?") e `b24b_manual_stations` ao que o plano listava.
- **`Palette`** (`scripts/ui/palette.gd`, igual ao guia B.1); `UiKit.GOOD/BAD` agora apontam para `Palette.GOOD/BAD` (cores levemente diferentes das antigas).
- **`Motion`** (`scripts/ui/motion.gd`): `press/pop_in/pop_out/slide_up/bounce/pulse/count_up/shake/float_text`, tempos como constantes, `static var reduced`.
  Desvios mínimos: `press` só conecta os sinais (devolve nada); com `reduced` as demais devolvem um Tween já encerrado; `reduced` ainda **não é lido do
  `settings.json`** (o `SaveManager` é o único dono do disco; ligar na tela de Configurações numa etapa futura).
- **`RingProgress`** (`scripts/ui/ring_progress.gd`): como no plano, mais `done_color` (verde quando `progress == 1`, "pronto" do guia B.5) e setters que redesenham;
  ícone desenhado no maior múltiplo inteiro do PNG que cabe no quadrado inscrito no anel.
- **Casa enquadrada:** `RoomView._framed`; `_show_whole_room` só marca enquadrado com `size > 0`, senão `_on_resized` tenta de novo. Conferido nas capturas
  (360×780, 390×844 e 412×915): Casa inteira, Tiro no quadro; Sítio/Praça/Vila/Natureza iguais ao antes (o vazio em volta fica para a Etapa 04).
  Teste: `navigation_test → _framing_check` (sala criada sem tamanho, ganha tamanho depois; **falha sem a correção**, verificado).
- **14 ícones PixelLab** (Pixen 32×32): `station_stove/fridge/blender/chest/workbench/silo/warehouse/mill/dairy/coop/barn/sewing/stall` + `ui_lock`, em
  `ui/icons/`, trocados em `progression.json → upgrades` (23 construções) e `worlds.json → places` (12 lugares). Todos aprovados em ≤ 3 tentativas
  (fogão na 3ª; liquidificador, silo e queijaria na 2ª). Recortados e recentralizados em canvas 32×32. Jobs/escolhas em `docs/ART_PIPELINE.md`.
  Ficaram como estavam (ícone de item faz sentido): pomar, estufa, ferramentas, tokens de nível da Natureza e o lugar `farm.animals` (ovo; agrupa galinheiro + curral);
  também o mapa de ícones dos contadores de missão em `ProgressionUi` (`produce → item_carrot_snack`), que é de rotina, não de estação.
- **Testes:** novo `ui_base_test` ("UI_BASE TEST: PASS", no `test_all.ps1`): anel corta 1,7→1 e −1→0, `Motion.reduced`, `count_up`, ícones existentes,
  nenhuma estação com ícone `tab_*`/`item_carrot_snack`. Suíte inteira PASS. Atenção: `tools/test_all.ps1` **aborta no `park_test`** porque o encerramento
  imprime `ERROR: N resources still in use at exit` (vazamento ao sair, igual no HEAD limpo — confirmado num worktree; é o aviso antigo já citado abaixo);
  por isso os demais (walks, petshop, friends, tricks, treasure, ui_base e `dev_tools_test` dev/prod) foram rodados um a um: todos PASS.
  Logs em `build/test_logs/etapa00_ui/`.
- **Capturas:** `build/screenshots/etapa00_antes/` (39) e `etapa00_depois/` (40) em 360×780; `etapa00_depois_390x844/` e `etapa00_depois_412x915/`.
  `b24b_manual_stations` só existe no "depois" (foi acrescentada depois do "antes").
- Pendências: nenhuma obrigatória. **Próxima: Etapa 01** (tema novo: cartão ≠ botão, `primary/secondary/ghost/icon_button`, `lock_hint` usando `ui_lock`).

**✔ Etapa 11 — Tesouro concluída (14/10/2026, Claude Code, retomando o Codex). Commit local, sem push.**
**Ajustes pós-plano (14–15/10/2026):** O **forno foi removido**: biscoito de maçã e caixa de petiscos agora são feitos no fogão (exigem bancada + geladeira), sem construção nem passo de história; capítulo 6 aponta para a Caverna. Coleção só lista roupas com arte (`GameState.has_overlay`); baú da Clareira some depois de aberto (`hide_seen`); etiquetas dos mapas tocáveis; **Estufa** ganhou 4 canteiros próprios (índices 9–12; ervas e mirtilo só lá, morango nos dois; crescem 30% mais rápido). Arte dos canteiros da estufa reaproveita `plot.png`.
**✔ PLANO DE 12 ETAPAS (00–11) CONCLUÍDO E PUBLICADO na `main` (14/10/2026).** Resumo final e pontas soltas em
`docs/plans/comeco/README.md` ("PLANO CONCLUÍDO"). Depois dele: etiquetas de texto dos mapas agora são tocáveis
(`RoomView._tap_label`, commit `6beacf4`). Próximo passo: definir um novo plano a partir desse resumo e de `FUTURO.md`.
- Base `66c5869` (Etapa 10). `SAVE_VERSION` continua 12, sem reset/migração: usa `progress.seen["treasure_opened"]`, `unlocks`, `collection` e contadores existentes.
- `quests.json → guide_treasure` (Guia, ordem 50, após `guide_fibers`): quatro objetivos `have` nos pedaços, que **não são consumidos** (só `deliver` consome). `Database.item_sources` passou a indicar onde cavar itens `find`, então o Ir dos pedaços leva ao faro do mundo certo (sítio, praça, vila, natureza).
- `progression.json → treasure` + `GameState.open_treasure/open_treasure_error` ("Já aberto", requisito, armazenamento); 150 moedas, `explorer_hat`, `crop:blueberry`, 2 parafusos; contador `treasure`; `Events.treasure_opened` → fila modal → `Celebration.show_treasure`. Chapéu também vem do conjunto da natureza e não duplica.
- Mirtilo: item, cultura (900 s, 3 por colheita, 40 XP; exige `guide_treasure` + `stats.treasure`) e desejo especial.
- `RoomView`: objetos aceitam `requirements` (invisível/intocável/sem footprint até valer) e `seen_sprite` (baú aberto). Baú em `rooms/nature.json`, `[96, 222]`, escala 2,2, etiqueta "Clareira escondida" abaixo dele.
- **Decisão/pendência de arte:** o mapa da Natureza não tem espaço livre para uma clareira e os 4 candidatos do PixelLab vieram como ilhotas flutuantes (rejeitados); então não há região fechada nem arte de clareira, só o baú revelado pela missão. Chapéu de explorador segue sem overlay ("Em breve no Tiro"). O baú é pequeno (arte ~19 px); se quiser, dá para gerar um maior depois.
- PixelLab: baú fechado/aberto, planta e ícone do mirtilo; jobs/ids/escolhas no ART_PIPELINE; originais em `build/art_sources/etapa11/`.
- Testes: todos PASS individualmente (26 scripts + DEV em prod), logs em `build/test_logs/etapa11/`; novo `treasure_test` (missão, não consumir pedaços, abrir uma vez, salvar/reabrir, mirtilo, Ir, sala real). `progression_test` (campanha) passou sem mudanças e `onboarding_test` manteve os limites. `navigation_test` agora respeita `requirements` dos objetos (igual ao jogo). Aviso antigo de recursos no encerramento do `park_test` permanece.
- 11 capturas 360×780 gráficas em `build/screenshots/etapa11/` (Natureza antes, Guia 3/4 e pronta, coleção 3/4 e 4/4, baú com seta, festa, aberto, "Já aberto", sementes, Mochila), abertas e conferidas.
- Web prod/dev exportados; baú, planta, ícone e dados conferidos nos dois PCKs; testes fora. Nenhuma publicação.
- Pendências obrigatórias: nenhuma. Ideias de FUTURO.md não implementadas.
**✔ Etapa 10 — Truques concluída (14/10/2026, Codex). Commit local, sem push.**
- Base `711d169` (Etapa 09); implementada somente a Etapa 10. `SAVE_VERSION` continua 12,
  sem reset ou migração: `progress.tricks` ausente começa vazio, recargas usam o dicionário existente.
- `progression.json → tricks/trick_settings`: `paw/talk/roll/jump/spin`, 3 acertos, zona/velocidade,
  +3 felicidade/+1 afeto e recarga Unix individual de 120 s. Requisitos reais: `nina_pipoca`, depois
  vínculo 2/3/4/5; aprendizado em sequência. `learn_trick/perform_trick` + `*_error` validam ids,
  requisitos, posse, sono e passeio; contadores `trick_learned`, `trick`, `trick:<id>` uma vez.
- Treino é o quarto lugar visível da Praça, na zona dos cones existentes; também serviço da Nina.
  Não alterados os 15 obstáculos, amigos, portão ou quiosque. `TrickUi` usa Sheet/LiveBox;
  `TrickTraining` reutiliza PetAnimator, Tween ping-pong, pequena variação central, botão 64 px,
  estrelas de acerto, Isso!/Quase! sem custo/limite. Consulta pura `check_hit`; posição forçada
  só via `dev_force_marker` com guarda DEV. Após aprender, botão “Voltar ao treino”.
- Botão Truques na tela Tiro após o primeiro aprendizado; Mostrar fecha o painel e exibe a animação.
  Mantidas as três camadas/slots e variantes: give_paw/bark vestidos; roll_over/happy_jump/chase_tail
  ocultam roupas e as restauram ao descansar. Nenhum sprite/animação do cachorro substituído.
  “Novo truque!” usa a fila modal e a rolagem da comemoração existente.
- Nina: `nina_trick` ordem 90, `nina_friends` preservada em 100, `nina_roll` em 110; objetivos totais
  permitem treinar antes de receber a missão. Feature/desejo/diária `tricks`/`trick`/`trick` após
  `nina_trick`; ajuda, ícones e Ir levam ao Treino ou à tela Tiro conforme a ação.
- Amigos/janelas locais/visitas offline/presentes únicos preservados; não alterados os sistemas de
  loot, sete raros, consolos, histórico/garantias ou sorteio independente dos dois lendários.
- PixelLab: 5 ícones 32×32; 7 jobs/candidatos, pata e fala refeitos após revisão (cachorro inteiro
  e quadro com escrita rejeitados). Originais/pranchas em `build/art_sources/etapa10/`; todos os
  jobs/ids, escolhas e alinhamento no ART_PIPELINE. PNGs/imports/UIDs incluídos; import concluído.
- **27 execuções individuais PASS** (26 scripts + DEV em prod), logs `build/test_logs/etapa10/`.
  `tricks_test` cobre zona/bordas, 3 acertos/toque duplo, tempo <30 s, abertura real de Treino,
  requisitos, efeitos/recargas independentes e limite 120 s, persistência/save antigo, anúncio,
  recompensa única da missão, navegação/chão e as três roupas em todos os truques.
  Friends/petshop/walks e DEV prod PASS. Campanha: **196 ciclos, 47 aquisições, 73 missões**;
  simulação usa novas ações conforme requisitos, sem brindes/limites relaxados novos.
  Onboarding mantém chance rara zero e limites: capítulo 4 **10,6 min**, passeio **14,3 min**,
  raro na **6ª volta em 25,7 min**, ocioso total **190 s**, máximo **30 s**.
- **22 capturas 360×780** gráficas, timeout externo 90 s, abertas e conferidas em
  `build/screenshots/etapa10/`: Praça antes/depois, lista/bloqueios/rolagem, barra/erro/acerto,
  festa, missão Nina/Novo!, botão/lista aprendidos, cinco animações vestidas/acrobáticas,
  roupas restauradas, recargas, sono e passeio. Botão Agora! testado por eventos de mouse
  (mesmo caminho do toque). Sem erros de script; avisos antigos de recursos/RIDs no encerramento
  de algumas cenas/testes permanecem; o novo `tricks_test` encerra limpo.
- Web prod/dev exportados; conferidos dados/scene/script/ícones nos dois PCKs e exclusão de testes.
  Nenhuma publicação. Saves pessoais restaurados byte a byte e hashes conferidos após validação.
  CLAUDE.md e AGENTS.md idênticos; docs de progressão/design/mundos/arte atualizados.
- Pendências obrigatórias da Etapa 10: nenhuma. **Próximo passo: Etapa 11 — tesouro**
  (`docs/plans/comeco/ETAPA_11_tesouro.md`), ainda não iniciada.

**✔ Etapa 09 — Amigos do Tiro concluída (14/10/2026, Codex). Commit local, sem push.**
- Base `ec64beb` (Etapa 08), sem reimplementar vestir, costura ou pet shop; nenhum conteúdo
  da Etapa 10. `SAVE_VERSION` continua 12: novos campos têm padrão vazio, sem reset/migração.
- `friends.json` e `FriendState`; Pipoca reaproveita toda arte, IA e seguir Nina. Toque vira amizade
  ao receber `nina_sewing`, enquanto `nina_pipoca` está ativa. Sem exigir concluir a própria missão.
  Mel/poodle, Bolota/pug e Fred/beagle usam NpcWorld/RoomView existentes; só um visitante na Praça.
- Petiscos conferidos nos dados: `carrot_snack`, `strawberry_pop`, `mashed_potato`,
  `sweet_potato_chips`. Bolota também exige `bloblo_potato`, evitando pedir purê ainda bloqueado.
  Mel exige liquidificador e Fred a missão da batata-doce. Praça com três lugares visíveis,
  15 obstáculos preservados, visitante em `[370, 230]` com caminho alcançável.
- Janela local de 3 h com data + bloco, visitante em rotação determinística dos elegíveis ordenados,
  fixado durante a janela. Se ainda não havia elegível, o primeiro pode aparecer sem esperar outra.
  Maior índice local observado persistido: atrasar relógio/fuso não reabre janelas; avançar abre
  a próxima. Um petisco por amigo por janela; corações 1/3/6, `claimed_hearts` e soma `friend_level`
  recalculada ao dar/carregar. Recompensas e presentes não repetem após salvar/reabrir.
- Pipoca ♥2 soma +1 sorteio comum em `walk_loot`, junto à bolsinha. Mesma prévia/validação/coleta;
  sete raros, consolos, histórico/garantias e dois lendários independentes preservados.
  ♥3 dá `caramel_bandana` à Coleção, com ícone Pipoca; **sem overlay, opção explícita do plano**:
  “Em breve no Tiro”, Vestir desabilitado. Sem roupa invisível ou alteração das camadas aprovadas.
- Visitas exigem ♥3 e ausência contínua de 8 h após melhor amizade/última visita. SaveManager
  trata só primeira abertura/retorno do segundo plano; timer, `from_dict` e troca de slot não geram
  visitas. Atividade global em `settings*.json` impede usar save antigo como ausência; heartbeat
  a cada minuto limita a margem após crash. Presente Loot fica sorteado no save até caber.
  Cheio não consome visita/prêmio nem permite ressorteio. Casa: amigo anda perto do Tiro,
  toque recebe com CollectFx/aceno; boas-vindas → Ver apenas aponta. Fila modal preservada.
- FriendUi no Sheet: retrato, raça, corações por ícones, próximo prêmio, petisco tem/precisa,
  Dar/Ir/?, já dado; Coleção → Amigos com silhuetas e rolagem. Boas-vindas ganhou rolagem.
  Nina `nina_pipoca`/`nina_friends`; feature `friends`, desejo `friend`, diária `friend`, semanal
  `pack_week`. Ajuda, ícones de objetivo, destinos e usos dos itens integrados.
- PixelLab: três personagens com oito direções + caminhada S/E/N (O espelhado), três retratos
  escolhidos entre 16 cada, quatro ícones. Pipoca mantém sprites/retrato existentes; ícone escolhido
  na terceira tentativa (orelhas erguidas e só cabeça). 72 quadros 64×64 preservam canvas/pivô.
  Todos os jobs, candidatos/rejeições, escolhas/alinhamentos no ART_PIPELINE; originais em
  `build/art_sources/etapa09/`. Pranchas abertas; PNGs/imports/UIDs versionados.
- **26 execuções individuais PASS** (25 scripts + DEV em prod); logs `build/test_logs/etapa09/`.
  `friends_test` cobre requisitos, janelas/data/fuso, corações/prêmios únicos, persistência, ausência
  online/offline, primeira abertura/troca de slot/notificações duplicadas, armazenamento, caminho,
  soma dos bônus e independência das garantias. Campanha usa ações/produção e janelas simuladas:
  **190 ciclos, 47 aquisições, 71 missões**. Onboarding mantém chance rara zero e todos os limites:
  capítulo 4 em **11,4 min**, passeio **15,0 min**, raro na **6ª volta em 35,8 min**; ocioso total
  **220 s**, máximo **30 s**. Nenhum erro de script. Avisos antigos de RIDs/ObjectDB/recursos
  no encerramento (incluindo park_test) continuam, sem falha nas verificações funcionais.
- **23 capturas 360×780** sem headless, timeout externo de 90 s, abertas e conferidas em
  `build/screenshots/etapa09/`: Pipoca antes/depois, missão Nina, falta/Dar/já dado, corações,
  três visitantes/cartões, Coleção/silhuetas/rolagem ao fim, bônus somados, Casa, boas-vindas,
  presente recebido. Fonte desenhava ♡ como ♥: substituída por ícones apagados; contador não quebra.
  Exportação Web prod/dev concluída; `friends.json` e scripts/arte conferidos nos dois PCKs,
  `tests/*` excluídos; nenhuma publicação. Saves pessoais desktop preservados pelo backup da suíte.
- Pendências da Etapa 09: nenhuma obrigatória. Overlay da bandana não faz parte desta entrega,
  conforme opção da 9.1. **Próximo passo: Etapa 10 — truques** (`ETAPA_10_truques.md`).

**✔ Etapa 08 — apetrechos, pet shop e costura concluídos (14/10/2026, Codex). Commit local, sem push.**
- Retomada da base `7211a42` (Etapa 07); `9ddd3b9` preservado. Nenhum reset/migração de save:
  campos novos têm padrão vazio. Saves locais restaurados e hashes conferidos após testes e capturas.
- **Aceite da Parte A recebido antes das demais roupas:** Vitor aprovou o lenço e o método `transfer_outfit`
  após comparar comer/dormir/lamber a pata; aprovou também o conjunto Bob Esponja ("Perfeito!").
  A troca da presilha por óculos escuros preserva o id `flower_clip` e a posse dos saves existentes.
- 18 peças vestíveis: 7 raros existentes, 4 do pet shop, 5 da costura e 2 lendários. Três slots persistidos
  (`head/neck/body`), camadas no Tiro e retratos de Desejos/boas-vindas; roupas continuam no sono,
  somem nas seis animações acrobáticas e voltam ao terminar. As 14 roupas antigas sem arte mostram
  "Em breve no Tiro", conforme o escopo do plano; não se veste uma roupa invisível.
- Arte PixelLab: camadas isoladas sem substituir o cachorro; 18 bases + 954 variantes por quadro.
  Método híbrido documentado: poses do lenço extraídas do transfer_outfit; demais quadros usam
  transformações/oclusão das camadas geradas. Candidatos, rejeições, jobs, máscaras e alinhamentos no
  `ART_PIPELINE.md`; originais em `build/art_sources/etapa08/`; extração em `tools/outfit_extract.py`.
- Pet shop Patinhas, pacote de ração, bolsinha (+1 sorteio) e costura no quiosque já desenhado.
  Arte nova acrescenta produtos/placa e mesa; preserva balcão, 15 obstáculos e caminhos da Praça.
  Nina ganhou os três passos previstos. **Não criada a diária de costura**, pois receitas são finitas.
- `output_collection` integrado à produção, filas salvas, coleta, indicadores, painéis, Manual,
  Mochila, ajuda, navegação, DEV e testes. Bloqueio de duplicata considera posse e qualquer fila.
  Costura entrega à Coleção e entra na fila modal existente com "Vestir agora"; cartão de volta
  mantém rolagem/fila. Bolsinha está em `walk_loot`, com sorteio determinístico e mesma checagem
  de armazenamento da coleta; falha/cancelamento não consome histórico nem garantia.
- Lendários cosméticos pedidos: chapéu do Siri Cascudo e uniforme de esponjinha, separados e combináveis.
  Depois de pet shop + 20 passeios recolhidos: 1% por volta elegível, garantia em até 30 por peça,
  primeiro chapéu, depois uniforme. Sorteio/garantia independentes dos sete raros; podem vir juntos.
  Após obter ambos não há duplicatas nem crescimento infinito da garantia lendária.
- **25 execuções individuais PASS** (24 scripts + DEV em prod), incluindo `petshop_test` novo.
  Logs em `build/test_logs/etapa08/`. Campanha: 216 ciclos, 47 aquisições, 69 missões; simulador
  passeia, veste e costura sem concessões. Onboarding com chance rara zero: capítulo 4 em 11,4 min,
  primeiro passeio 15,1 min, primeiro raro na 6ª volta em 54,5 min; ocioso total 220 s, máximo 30 s.
  Limites dos testes preservados. Avisos antigos de recursos/RIDs ao encerrar permanecem;
  nenhum erro de script. Capturas gráficas 360×780 com timeout externo abertas e conferidas:
  `build/screenshots/etapa08/` (40 telas, todas as 22 animações, três roupas, raros, lendários,
  costura, Coleção, Desejos, Diário e Praça antes/depois). Exportação Web prod/dev concluída sem
  erros; `overlay_anchors.json` conferido nos dois pacotes locais. Nenhuma publicação.
- Pendências da Etapa 08: nenhuma. **Próximo passo: Etapa 09 — amigos**, ainda não iniciada.

**✔ Etapa 07 do começo (sete passeios, materiais e raros) — Claude Code + Codex, 14/10/2026.** Commit local, sem push.
- Retomada exata da conversa Claude `bda53413-221b-4067-8fff-56762caff35b`: parou por limite após editar a Coleção,
  com 14 arquivos modificados e 8 jobs PixelLab enviados. Preservados os dados/código e recuperados os 6 postais + 2 ícones.
  Corrigidos erro de tipagem e substituição ampla que havia colocado requisito de 3 passeios em dez missões antigas.
- `walks.json`: sete caminhos conforme a tabela do plano, requisitos de contagem/vínculo/Bosque e início do Pôr do sol
  das 17h (inclusive) às 21h (exclusive), hora do aparelho. Horário não impede recolher nem esconde caminho já liberado.
  `loot.first` garante material na primeira coleta; `loot.rare` sorteia pela seed ou garante na N-ésima volta sem raro.
  `WalkState.pity/history` reutilizados; coleta altera uma vez, cancelar/armazenamento cheio não gastam histórico/garantia.
  Raro novo vai à Coleção e conta `walk_rare`/`walk_rare:<id>`; duplicado vira moedas/material e zera a garantia.
  `walk_item` soma quantidades; `walk_item:<item>` e achados do faro continuam. Alias `new_items` + `new` no resumo.
- Interface: painel com liberados em ordem de tempo e dois próximos bloqueados na ordem de progressão; materiais/raros
  em silhueta, chips de requisitos, Passear desabilitado + ?. Diário após 3 passeios, com postais, contagens e garantia.
  Cartão normal/Primeira vez!/Novo!/RARO (moldura dourada, estrela girando, vibração)/consolo. Rolagem limita o cartão à tela;
  tween vinculado à estrela para terminar ao recriar o cartão. Cabeçalho do Sheet quebra linha sem alargar a tela.
  Coleção usa duas colunas e mostra os sete raros com silhueta + origem + Ir. Mochila → Do passeio com ícone.
  Novos caminhos entram em `new_unlocks` e são anunciados na fila modal depois do cartão da volta, sem exigir receber missão.
  O Tiro reaparece no dog_start e reage via `wish` ao ganhar raro.
- Conteúdo: 11 materiais `trail` sem depósito + `note`; petisco de hortelã (fogão, hortelã + cenoura, após 1 Clareira);
  desejos de graveto/flor/petisco; Nina `nina_routes`/`nina_rare`; diária `walk_items`, semanal `walker_week` + bandana.
  Manual, Mochila e Como fazer mostram origens nos passeios (inclusive ingrediente da receita). Mantidos `tiro_walk` e
  os achados de mundos existentes em `finds.json`; nenhum material trail entra em colheita, produto de estação ou montinho.
- Arte: 6 postais 128×80 + 20 ícones 32×32, PixelLab, originais em `build/art_sources/etapa07/`; todos os job ids,
  candidatos e tentativas registrados no ART_PIPELINE. Coleira refeita para tirar cachorro; estrela escolhida na 3ª tentativa,
  geométrica sem rosto. Canvas inteiro preservado para alinhamento. `park_loop` reutilizado; quiosque da Praça preservado.
  Godot `--headless --import` terminou; PNGs, imports e UIDs incluídos.
- Validação: **23 testes + DEV em prod PASS**, executados individualmente; logs `build/test_logs/etapa07/`.
  `walks_test` cobre requisitos e limites horários, primeira volta, garantia independente por caminho, consolo, contadores,
  sorteio/save, receita, diário/silhuetas, Novo! na fila e largura do Sheet. `content_test` valida postais, raros, itens,
  tabelas `find` e exclusividade dos materiais. Campanha completa: **216 ciclos, 44 aquisições, 66 missões**.
  Simulação escolhe Flores só após 3 voltas para não travar a linha da Nina. Onboarding testa o pior caso (chance rara 0):
  primeiro raro na **6ª volta, 25,4 min**; primeiro passeio 14,4 min; capítulo 4 em 10,6 min; ocioso 190 s, maior trecho 30 s.
  Simulador deixa brincadeiras para depois quando precisa descansar (sem alterar energia/custos do jogo).
- Capturas 360×780 geradas sem headless, com processo limitado, abertas e conferidas em `build/screenshots/etapa07/`:
  painel (3 liberados/2 bloqueados), Pôr do sol fechado, Diário/bloqueados, volta normal/primeira/raro/botão/consolo,
  Coleção em silhuetas, Mochila Do passeio, detalhe com nota/origem. Rótulos que quebravam letra por letra corrigidos.
  `game/tests/walks_shots.gd` preservado como roteiro. `git diff --check` limpo; CLAUDE.md = AGENTS.md.
- Pendências: nenhuma da Etapa 07. Avisos de RIDs/ObjectDB/recursos no encerramento de testes continuam iguais aos logs
  da Etapa 06 (incluindo park_test); nenhum erro de script. Vestir o Tiro, costura, pet shop e bolsinha não foram adiantados.
  **Próximo passo: Etapa 08 — apetrechos**, `docs/plans/comeco/ETAPA_08_apetrechos.md`.

**✔ Etapa 06 do começo (Praça: Nina, Pipoca e o primeiro passeio) — Claude Code, 14/10/2026.** Commit local, sem push.
- Mundo `park` (Praça) entre Sítio e Vila em `worlds.json`; abre com a primeira encomenda (`main_2_order`), com "Novo!" listando Praça e
  Nina. Sala `rooms/park.json` (fundo novo, 8 `dig_spots` alcançáveis, 15 obstáculos, zona `walk_gate`, pontos `dog_start`,
  `npc_nina`, `npc_dog_pipoca`, `walk_marker`). NPCs `nina` (apresentação de 3 falas, serviço `walk`) e `dog_pipoca` (`decor` + `follow`:
  novos campos do `npcs.json`, tratados em `NpcWorld`/`Places`/`ProgressionState`).
- Motor de passeios: `data/walks.json` (só `park_loop`: 2 min, ⚡8, +20 felicidade/−10 higiene, loot 50% moedas / 30% `find: park` / 20% ração),
  `WalkState` (salvo em `walks`, sem mudar `SAVE_VERSION`: save antigo = sem passeio), `GameState.walking/walk_error/start_walk/walk_remaining/
  walk_ready/walk_loot/collect_walk_error/collect_walk/cancel_walk`, `Database.walks`, `Events.walk_collected`. Enquanto passeia: o Tiro some das
  salas (`RoomView._sync_dog`), `feed/play/bathe/pet/dormir/cavar` bloqueados e desejos de comida mostram "Quando ele voltar".
  `dev_finish_timers`/`dev_advance_time` também andam o passeio. `available_actions` e o cartão "bem-vindo de volta" ganharam `walk`.
- Telas: painel `walks` (`ProgressionUi.walks_panel`: espaço com postal/tempo/barra, Recolher ou "Chamar de volta" com 2 toques,
  cartões dos passeios com chips de tempo/⚡ e ícones dos achados possíveis, até 2 bloqueados apagados com cadeado), cartão "Volta do passeio"
  (`scenes/ui/walk_result/`), `WalkIndicator` no portão (tempo/Recolher; tocar recolhe direto), tela do Tiro com postal 2x e o Tiro andando
  (`AwayView`, botões de cuidado desabilitados e humor "Tiro está passeando").
- Conteúdo: linha `nina` (`nina_meet` ordem 10, `nina_walk` ordem 20), `finds.json → worlds.park` + `park_set` (laço `park_bow`), desejo `walk`
  (`go: "place:park:walk"`; `WishUi.go_target` entende `place:<mundo>:<lugar>`), diária `tiro_walk`, `Places.goal_target` para `walk`/`walk:<id>`.
- Arte (PixelLab, registrada no `ART_PIPELINE.md`): fundo da Praça, postal `park_loop`, Nina (caminhada S/E/N/O + retrato), Pipoca (caminhada S/E/N,
  parada S/E + retrato), ícones `tab_park` (2ª tentativa) e `action_walk`. Originais em `build/art_sources/etapa06/`.
- Decisões: (1) a diária se chama `tiro_walk` porque `walk` já era a diária "Faça um passeio" (rotas da Natureza). (2) O quiosque do fundo veio com
  balcão (não vazio); serve para a Etapa 08. (3) A Pipoca só tem pulinhos ao toque (a Etapa 09 a transforma em amiga). (4) Chão da Praça = calçada +
  gramado dentro da cerca, com fonte, bancos, árvores, canteiros, caixa de areia e quiosque como obstáculos; a fonte e a copa da árvore da frente
  foram encolhidas para deixar um corredor de 20 px entre elas (senão o lado leste ficava inalcançável). Os montinhos "na caixa de areia" ficaram
  na grama ao redor (a areia é obstáculo). (5) `onboarding_test` agora segue até o 1º passeio: capítulo 4 em ~10,5 min, 1º passeio recolhido em
  ~14 min (meta ≤ 60), ocioso 190 s; o jogador simulado também vende o excedente e entrega a encomenda. (6) `progression_test` faz um passeio por ciclo.
- Pendências da Etapa 05 fechadas: capturas 360×780 conferidas (`build/screenshots/etapa05/`: farejando, "Novo achado!", Coleção → Achados, Mochila,
  cartão de volta com achado); o álbum tinha o contador "4/16" quebrando letra por letra e nomes cortados: corrigido (`find_ui.gd`). Jobs PixelLab da 05
  registrados (por id de galeria) no `ART_PIPELINE.md`; faro incluído em `GAME_DESIGN.md`. Mojibake do `finds.json` ("sÃ­tio") corrigido.
  Isenção dos 5 achados da Praça removida do `manual_test`.
- Testes: `park_test` novo (no `test_all`); `content_test` (5 mundos, Praça, walks.json), `npc_lines_test`, `onboarding_test`, `progression_test` ajustados.
  Suíte inteira PASS rodada um a um (logs em `build/test_logs/etapa06b/`). Capturas 360×780 em `build/screenshots/etapa06/` conferidas
  (lista do Mapa, Praça com Nina e Pipoca, conversa, painel vazio/andando/pronto, tela do Tiro passeando, casa sem o Tiro, portão "Recolher", cartão de volta).
- Pendências/atenção: a Pipoca ainda é só enfeite; o Tiro andando na tela do Tiro é só leste (loop); `tab_park` é um banco sob árvore pequeno (legível,
  mas pode ser refeito). Avisos de RIDs/ObjectDB no fechamento dos testes continuam. Nada de conteúdo da Etapa 07 foi adiantado.
  Próximo passo: **Etapa 07 — passeios** (`docs/plans/comeco/ETAPA_07_passeios.md`).

**✔ Etapa 05 do começo (Faro do Tiro) — Claude Code, 14/10/2026** (código iniciado pelo Codex). Commit local, sem push.
- `data/finds.json` (mundos farm/village/nature, `guaranteed`, `table`, conjuntos), `FindState`, `GameState.update_finds/dig/dig_error/claim_find_set`,
  `find_ui.gd` (álbum Roupas · Achados), montinho `DigSpot` no `RoomView`, `sniff`/`dig` no `DogWorld`, `dig_spots` em
  `rooms/farm|village|nature.json`, missão `bloblo_dig` (ordem 25), diária `dig`, semanal `digger_week`, Mochila → Achados.
- Arte (Codex gerou, Claude instalou): 16 achados + `item_map_piece` + `find_paw`, `areas/fx/dig_spot.png`, `fx_sparkle.png`,
  `tiro_world/sniff/east` e `dig/east` (9 quadros). Originais em `build/art_sources/etapa05/`.
- Ajustes de teste: `dig_spots` movidos para chão alcançável (farm 7, village 6, nature 6); `farm_test`, `tasks_test`,
  `manual_test` (achados da Praça isentos até a Etapa 06), `progression_test` (cava a cada turno) e `onboarding_test`
  (primeiro achado em 2,5 min, meta ≤ 9; capítulo 4 em 11,4 min, ocioso 220 s) atualizados. `finds_test` entrou no `test_all`. Suíte toda PASS.
- **Pendências:** capturas 360×780 (farejando, "Novo achado!", Coleção → Achados, Mochila → Achados, cartão de volta) não foram
  conferidas visualmente; registrar os jobs PixelLab na tabela do `ART_PIPELINE.md`; `docs/WORLDS.md`/`GAME_DESIGN.md` com `dig_spots`.
  Próximo: **Etapa 06** (Praça, `park_set`, `map_piece_2`) em `docs/plans/comeco/`.

**✔ Etapa 04 do começo (primeiros sabores) — Codex, 14/10/2026.** Trabalho local, sem push.
- Morango e batata-doce, seis itens e quatro receitas; liquidificador de 30 moedas após
  `first_kitchen`, uma vaga, lugar oculto próprio e Cozinha agrupando as três estações.
  Lugar com requisito `first_kitchen` entra automaticamente na comemoração "Novo!".
  Objeto em `[318,186]`, sobre o tampo da ilha, com `z_index: 1` (suporte de dados no RoomView).
  Sem animação opcional; indicador existente mostra tempo/Coletar. Sementes ordenadas por
  tempo com desempate determinístico por id (morango antes de milho).
- Missões de morango/abóbora/batata-doce da vovó e liquidificador da Laís; cinco desejos,
  quatro pedidos da feira e duas diárias. Suco é para pessoas (sem `feed`, geladeira);
  os outros preparados alimentam o Tiro. Pedidos mantêm `first_harvest` como os antigos.
- Decisões: a cultura abóbora mantém `bloblo_potato`, porque exigir `bloblo_pumpkin` (que
  pede colher abóbora) criaria ciclo. Papinha passa a exigir `bloblo_pumpkin`. As novas
  missões de morango/abóbora usam ordens **62/65**, depois do ensopado (60) e antes da
  escritura (70), em vez de 35/55 do exemplo: sabores extras não bloqueiam a abertura da
  Vila; morango segue disponível cedo após `bloblo_more_crops`. A sequência original
  produziu 460–480 s ociosos totais no onboarding; apenas mover abóbora deu 270 s.
  Sequência final na suíte: capítulo 4 em **10,7 min**, ocioso **190 s** (meta 240), maior trecho
  **30 s** (meta 120), primeira colheita **1,6 min** e desejo **0,7 min**. Limites mantidos;
  simulação passou a cultivar objetivos `harvest:<cultura>` e atender cadeias dos desejos.
  Experimentos de reserva de mimos foram removidos; não houve escolha de seed para passar.
- Arte PixelLab: seis ícones, duas plantas e objeto gerados/revisados; jobs/candidatos/recortes
  em `ART_PIPELINE.md`. Batata-doce regenerada uma vez para tirar o rosto; referência do
  fogão reduzida para caber no canvas do liquidificador. PNGs e `.import` incluídos.
- Capturas 360×780 abertas e conferidas em `build/screenshots/etapa04/`: compra antes/depois,
  liquidificador trabalhando e receitas, sementes, plantas maduras (visão geral e close),
  desejo de picolé, pedidos de morango e suco. Objeto apoiado no tampo, indicador legível,
  balão do Tiro ocultado dormindo para inspecionar compra/objeto e câmera enquadrando a ilha.
- Validação final: **todos os 20 testes + DEV em prod PASS**, executados um a um; campanha
  completa em 216 ciclos, 44 aquisições e 61 missões. Logs `build/test_logs/etapa04/`.
  Godot importou arte/UIDs sem erro de script; `git diff --check` limpo e CLAUDE=AGENTS.
  Avisos já conhecidos de RIDs/ObjectDB no fechamento de alguns testes de UI permanecem.
  Novo `flavors_test` cobre compra, cadeias de produção/coleta única, suco não alimentável,
  destino próprio do liquidificador, ordenação das sementes e capturas; entrou no `test_all`.
- Etapa 04 concluída, sem pendências. Nada de conteúdo da Etapa 05 foi adiantado.
  Próximo passo: **Etapa 05 — Faro do Tiro**,
  `docs/plans/comeco/ETAPA_05_faro.md`.

**✔ Correção da rolagem dos desbloqueios — Codex, 14/10/2026.**
- A comemoração não tinha `ScrollContainer`: muitas novidades faziam o cartão ultrapassar a tela e
  cortavam o botão Continuar. `celebration.gd` agora limita a altura à área visível (16 px de folga
  em cima/baixo), rola o conteúdo e recalcula ao mudar o tamanho da janela/conteúdo.
  Cartões curtos continuam compactos e centrados; aplica-se também às comemorações de nível/vínculo.
- `tasks_test` cobre lista longa, limite de altura, rolagem até Continuar inteiro e fechamento;
  também verifica o cartão curto. Capturas 360×780 `unlocks_scroll_top/bottom` e `tasks_celebration`
  conferidas. Suíte completa executada um a um, incluindo DEV em prod. Sem push.
- Próximo passo continua sendo **Etapa 04**, `docs/plans/comeco/ETAPA_04_sabores.md`.

**✔ Etapa 03 do começo (Desejos e vínculo) feita — Claude Code + Codex, 14/10/2026.** Próximo passo: `docs/plans/comeco/ETAPA_04_sabores.md` (Etapa 04). Trabalho local, sem push.
- Retomada da conversa Claude `b3a5ed69-3c90-4cfc-9fcd-6448e677647e`: parou no limite da sessão logo após
  acrescentar `_ui_checks` ao `wishes_test.gd`; implementação e quatro ícones PixelLab estavam sem commit.
- `wishes.json`, `WishState`, `WishUi` e aba Desejos entre Tiro e Mapa. Após `lais_bed`, primeiro pedido =
  3 carinhos; até 3 espaços (vínculos 2/4), sem repetir ids simultâneos. Prioridade das necessidades, especial
  elegível com vínculo 3 (5%, prêmio dobrado), Dar/Receber, Ir/?, trocar grátis, badge e balões tocáveis.
  Reposição 60 s nos 3 primeiros cumpridos / 600 s depois; troca 300 s. Dados/base/timestamps persistem.
- Vínculo visível, barra e liberações; presentes uma vez por nível (`claimed_bond_level`, `Events.bond_up`),
  na fila de comemorações. Diária de 2 desejos, semanal de 12 e `heart_collar` sem sprite de vestir.
  Comida pedida aparece primeiro com "Ele quer!"; Dar ali cumpre e alimenta uma vez. `feed` direto não cumpre.
  Ferramentas DEV de afeto e desejos, avanço de tempo e contadores/atalhos integrados.
- Correções da retomada: teste carrega `SheetBuilder`/`WishUi` em runtime para evitar autoload indisponível;
  desejos não antecipam a caminha com vínculo alto; balão segue o layout da cabeça, some dormindo e tem
  área de toque mínima 48 px. Borda dourada distingue especiais; cadeado e troca compacta; todas as abas cabem.
- Decisões: reaproveitados os quatro ícones já gerados pelo Claude, sem novas gerações (jobs e revisão em
  `ART_PIPELINE.md`). Estrela de XP é o fallback do especial. `last` evita repetição no sorteio comum;
  pedido inicial e necessidade baixa podem prevalecer, conforme a ordem do plano. Canvas 32×32 preservado
  para alinhar balão/ícone. Saves v12 antigos inicializam o marco de vínculo no nível atual, sem presente retroativo;
  não houve reset adicional nem conteúdo das Etapas 04+. Suporte `give` fica sem modelo até etapa futura.
- Validação: todos os 19 testes da suíte + ferramentas DEV em prod passaram, executados um a um (histórico
  do `test_all.ps1` >10 min nesta máquina). Campanha: 212 ciclos, 43 aquisições, 57 missões. Onboarding:
  1º desejo ~0,7 min, 1ª colheita ~1,6 min, capítulo 4 ~10,5 min simulados. Ajustados `content_test`
  (contador wish) e `tasks_test` (reiniciar sorteio após preparar contadores, sem depender do modelo do dia).
  Capturas 360×780 abertas: início, especial+fechado, todos abertos, espera, Casa/Sítio/Tiro, seletor,
  comemoração e painel de vínculo. Godot importou PNGs/UIDs. Persistem avisos de RIDs/ObjectDB no encerramento
  de alguns testes de interface; nenhum erro de script. Nada ficou pela metade na Etapa 03.

**✔ Etapa 02 do começo (caminha) feita — Claude Code, 14/10/2026.** Próximo passo: `docs/plans/comeco/ETAPA_03_desejos.md` (Etapa 03).
- `lais_bag` agora dá o item `bed_gift` (Mochila); nova missão `lais_bed` (cap. 1, ordem 60, objetivo `owned: dog_bed`, +10 moedas, +5 carinho).
  Construção `dog_bed` (custo 0 + `bed_gift`, lugar `bed` oculto em `worlds.json → house`, objeto + pontos `bed_sleep`/`bed_approach` em `rooms/house.json`).
  Sítio, porta, vovó, `bloblo_meet` e `welcome_requirements` passam a exigir `lais_bed`.
- Tiro dorme na caminha (`RoomView.refresh_sleep_points`, chamado no spawn e a cada `state_changed`; mesmo fluxo do sofá (`_on_sofa` = z na frente),
  sem subir de verdade). Prioridade: caminha > sofá > chão. Custo 0 aparece como "Grátis" (painel de compra e marcador "+").
- Decisões: `content_test` agora aceita capítulo com até 6 passos (cap. 1 ficou com 6). Caminha em (372,336), Tiro deitado em `bed_sleep` (376,330), desenhado na frente dela (z_index, igual ao sofá; caminha com `scale` 1.5);
  conferido nas capturas 360×780. Arte no `ART_PIPELINE.md` (a `style_image` do PixelLab tem de caber no canvas: usei recorte do piso).
- Dicas p/ a próxima sessão: em testes headless não tipar com classes que usam autoloads (ex.: `DogWorld`; dá "Identifier not found: Events" e o teste trava) — use `Node2D` + `.get()`; `dev_unlock_everything`/`dev_add_items` já dão `dog_bed`/`bed_gift`; saída de teste com `grep` em pipe só aparece no fim (redirecione para arquivo). `tools/_*.gd` temporários de captura devem ser apagados.
- Testes: rodei cada teste da suíte direto no Godot (todos PASS, inclusive `-- --prod`); o `test_all.ps1` completo passa de 10 min nesta máquina, não esperei até o fim. `world_life_test` (caminha: sleep_point, grátis, consome presente), `content_test`, `welcome/intro/farm_test` usam `lais_bed`.

**✔ Etapa 01 do começo (facilitar) feita — Claude Code, 14/10/2026.**
- 1A: vovó empresta 2 e depois 4 canteiros; `initial_plots` 4, `unlock_costs` `[0,0,0,0,40,70,100,150,220]`. 1D: só o próximo
  canteiro fechado tem etiqueta (`PlotIndicator`: ícone `tab_farm` + "Vovó", ou moeda + preço).
- 1B: abóbora → `bloblo_potato`, papinha → `lais_stew`; regra nova no `content_test` (skills só com cap. ≥ 6 ou construção com
  materiais; herbas/caixa de petiscos passam por estufa/forno). 1C: diárias no cap. 3, semanais no 4; diária nova "Regue 5 plantas".
- 1E: regar (`GameState.water/water_error`, `watered` no canteiro salvo, tira 30% do tempo que falta, 1 XP, contador `water`;
  gotinha `action_water` no mapa e animação em `RoomView._water_fx`; `first_harvest` pede regar + colher; ação `water` em
  `available_actions`). Arte: `action_water.png` (PixelLab, ver ART_PIPELINE).
- 1F: `level_rewards` + `Events.level_up` + `Celebration.show_level`. Decisão: nível fora da tabela = `coins_per_level × nível`.
  Vários níveis juntos dão um cartão só (soma). 1G: presente do dia (`daily_gift`, `progress.daily_gift`, dias jogados) e cartão
  `welcome_back` (`SaveManager.last_saved_at`; abre após 300 s fora; decisão: só abre se houver presente ou algo pronto).
  `main.gd` ganhou fila de cartões (`_queue_modal`): nível/bem-vindo esperam a introdução e as comemorações fecharem.
- 1H: dica parada em `WorldsScreen.advance_idle` (15 s, cap. ≤ 4, uma vez por passo, só no mundo aberto).
- 1I: `onboarding_test.gd` (jogador simulado; imprime a linha do tempo: 1ª colheita ~1,5 min, cap. 4 em ~10,5 min, ocioso 220 s,
  maior trecho 30 s). O tempo é simulado com `dev_advance_time` (3 s por ação), então é só uma estimativa. Novos: `welcome_test`.
  Ajustes em `farm_test` (4 canteiros, regar), `tasks_test`, `navigation_test` (dica), `progression_test` (campanha rega).
- `tools/test_all.ps1` reescrito: modo "Continue" (no PowerShell 5.1 os avisos "RIDs leaked" do stderr derrubavam a suíte) e
  respeita `$env:GODOT_BIN`; inclui `welcome_test` e `onboarding_test`. Suíte completa verde. Capturas 360×780 conferidas:
  `farm_progress{,_vovo,_zoom}`, `welcome_back`, `level_up`.
- Pendente/atenção: economia do começo não foi jogada de verdade (ver 00_VISAO §6; se ficar fácil, escritura 220); `dev_advance_time`
  não mexe em `watered`. Nada publicado (sem push).

**✔ Etapa 00 do começo (fundação) feita — Claude Code, 13/10/2026.**
- Save **v12 zerado** (`_migrate` descarta qualquer save < 12, todos os slots); `quests.json` com `order` ×10;
  `content_test` espera ordens 10, 20, 30...
- `pet()` conta `pet`; `feed()` conta `feed:<item>`; todas as contagens do `GameState` passam por `_count`,
  que grava `progress.firsts[chave]` (primeira vez) e `progress.started_at` (novo jogo). Aba **Ritmo** no DevPanel
  (`ProgressionState.pace_lines`, botão Copiar).
- Requisitos `stats` (rótulos em `settings.stat_labels`), `bond` e `hours`; recompensas `affection` e `needs`.
  `progression.json → bond_levels` criado com os valores da Etapa 03.
- `Loot` (`scripts/util/loot.gd`, `loot_test.gd` novo na suíte) e `GameState.available_actions()`.
- Decisões: `bond` e `hours` ficam em `GameState.requirement_error` (precisam de `dog.affection` e da hora local;
  `content_error` do GameState agora passa por ele). `progress.requirement_error` continua puro (só stats/quests/etc.).
  Chip de `affection` nas recompensas usa `need_happiness` até a Etapa 03. Nenhuma arte nova (a etapa não pede).
- Observação: os testes aceitam avisos de "RIDs leaked" do Godot; o `tools/test_all.ps1` no PowerShell 5.1 trata
  esses avisos (stderr) como erro — rodei cada teste direto no Godot e todos deram PASS (inclusive `-- --prod`).

**▶ PRÓXIMO GRANDE TRABALHO: um começo mais gostoso — plano em andamento (Claude Code, 13/10/2026).**
- Pedido do Vitor: mais missões, itens, receitas, estruturas e um mapa novo, focando a primeira hora.
- **Plano por etapas para executar: pasta `docs/plans/comeco/`** — comece pelo `README.md` (ordem,
  mensagem pronta para o agente, andamento). `00_VISAO.md` = diagnóstico, pesquisa e princípios;
  `01_REGRAS_E_ARTE.md` = regras, receitas do PixelLab e catálogo de ids; um `ETAPA_XX_*.md` por etapa.
- Etapas: 00 fundação (save v12 zerado) · 01 facilitar · 02 caminha · 03 aba Desejos + vínculo ·
  04 sabores (morango, liquidificador) · 05 faro do Tiro · 06 Praça (abre depois da Vila; Nina, Pipoca,
  primeiro passeio) · 07 passeios (7 caminhos, materiais exclusivos, apetrechos raros) · 08 vestir o Tiro,
  pet shop, costura · 09 amigos · 10 truques · 11 mapa do tesouro.
- Decisões do Vitor: pode zerar os saves; Praça depois da Vila; Desejos em aba própria; foco nos passeios.
  Etapas 00–03 feitas; próxima: Etapa 04 (sabores).

**Armazenamento com limite (Claude Code, 13/10/2026) — local, sem commit.** Plano: `docs/plans/ARMAZENAMENTO.md`.
- Feito (base): `progression.json → storage` (geladeira/baú/silo/armazém: `categories`, `base`, `building`, `levels`) +
  melhorias `fridge_2/3`, `chest(_2/_3)`, `silo(_2/_3)`, `warehouse(_2/_3)` com `storage_capacity` (sem estado novo: níveis = `owned`).
  `items.json → storage` força o depósito (`"none"` = sem limite: ração). `GameState.storage_of/capacity/used/space/error`.
  O limite só vale com a construção comprada (a geladeira já vale). Sem espaço: `harvest`, `collect` e `collect_gathering`
  não entregam (lote continua pronto, toast "X sem espaço"); recompensas de missão sempre entram.
- UI: Mochila e painéis de depósito mostram chips usado/capacidade (`SheetBuilder._storage_bars`); painel `storage:<id>`.
  Lugares `chest`/`silo`/`warehouse` (ocultos) em `worlds.json`. `storage_test.gd` novo; testes que enchem a mochila usam `GameState.unlimited_storage`.
- Feito (2ª passada): objetos Baú (casa), Silo e Armazém (sítio) com arte PixelLab; ficam na parte ABERTA do sítio, fora das áreas fechadas (estufa/pomar/animais) para não dependerem de compra de outra área.
  Linha da vovó ganhou `bloblo_silo → warehouse → chest → bigger → biggest` (ordens 14–18): cada construção só aparece após a missão anterior;
  ampliações pedem itens novos `bolt` (Parafuso) e `iron_band` (Cinta de ferro), dados por essas missões e (parafuso) pelas semanais. Itens com `storage: "none"` não ocupam espaço.
- Falta: aviso de "cheio" no marcador do mapa; `dev_add_items` ignora o limite; painel de ampliação direto na tela de cada depósito; balancear números
  (parafuso aparece nas semanais antes de a história apresentá-lo); a simulação de campanha roda com `unlimited_storage`.

**Ajustes pós-publicação (Claude Code, 13/10/2026) — locais, sem commit.**
- Codex parou no limite de uso sem alterar arquivos. Feedback do Vitor após o deploy `2c78f95`:
  (1) a conversa com a Laís abria sozinha ao fim da introdução; (2) Laís pequena demais.
- (1) Fim da intro usa `world_requested("house", "look:npc:lais")`: `WorldsScreen.enter` aceita
  `look:<ação>` = só a seta, sem abrir o painel. `intro_test` agora exige talk:lais == 0 + seta.
- (2) `npcs.json → world_scale` (padrão 1) multiplica a escala do NPC na sala; Laís = 1.7
  (maior que o Tiro, quase na altura do balcão). Ajustar o número se ainda parecer pequena/grande.
- (3) Feedback do Vitor: o "Ir" pulava etapas (missão do ensopado levava direto à horta de cenoura).
  `ProgressionUi.quest_go_target` agora = `Places.quest_target` (lugar do objetivo: fogão/geladeira);
  a cadeia de ingredientes continua no "?" (`TaskHelp`). Os botões "Ir" de dentro do "?" seguem
  levando ao passo que falta.
- (4) Fogão expansível até 3 espaços: `stove_queue` (+1, 180 moedas + 3 tábuas) e novo `stove_queue_2`
  (+1, 320 + 5 tábuas, exige `stove_queue`); ambos em `config.json → stations.stove.slot_upgrades`,
  `progression.json → upgrades` e no lugar Cozinha de `worlds.json`. Números fáceis de ajustar.
- (6) Espaços do fogão a ampliar ficam na própria fileira de espaços ("+" com o preço; tocar abre
  a compra), em vez de um cartão lá embaixo: `SheetBuilder._locked_slot`, `GameState.pending_slot_upgrades`;
  `Places._with_upgrades` não repete as compras que são `slot_upgrades` de estação. Vale para qualquer
  estação com `slot_upgrades` em `config.json`. Teste em `progression_test` (captura `ui_kitchen_slots`).
  Local, depois do deploy `e2e2f90`; falta publicar.
- (7) Cartão de missão enxuto (pedido do Vitor): só o que fazer (objetivo), onde (lugar) e a recompensa;
  saíram os chips de ingredientes que faltam (a cadeia fica no "?"). `tasks_screen._quest_body`.
  Bancada não tinha bug: Vitor confirmou que "desbugou" (nada a corrigir). Falta publicar (itens 6 e 7).
- (8) Laís do mapa refeita (v3, pro 128 px, mesmo detalhe do Tiro, esguia) com caminhada de 8 quadros;
  `world_scale` removido do `npcs.json` (campo e suporte no `room.gd` continuam para outros NPCs).
  Detalhes em `docs/ART_PIPELINE.md`. Falta publicar.
- (9) Painéis de produção padronizados (pedido do Vitor: gostou do do fogão): espaços em cima com
  tempo/barra, espaço fechado mostrando preço (estações) ou nível/XP (Natureza), recolher, e embaixo
  os cartões do que escolher. Aplicado à Natureza (`NatureUi.panel/_material/_slot`) e ao Pomar
  (`ProgressionUi.routes_panel`); `SheetBuilder.slot_frame` agora é público. Regra em `CLAUDE.md`.
  Falta publicar (itens 8 e 9).
- (10) Geladeira só com comida e ingredientes: lugar `fridge` usa `panel: "fridge"` →
  `SheetBuilder.inventory_view(true)` (categorias food/crop + itens com `"storage": "fridge"` em
  `items.json`: ovos, leite, farinha). Materiais/produtos de oficina ficam só na aba Mochila.
  Teste em `content_test` (`_fits_fridge`). Falta publicar (itens 8–10).
- (11) Contador de ingrediente mostrava o estoque limitado ao que a receita pede (6 pedras = "3/3",
  e depois de gastar 3 continuava "3/3"; parecia que não descontava). `ProgressionUi.item_chip` e
  os chips do `TaskHelp` agora mostram o estoque real ("6/3" → "3/3"). O desconto em si (`GameState.cook`)
  sempre esteve correto. Falta publicar (itens 8–11).
- (12) Sombra das áreas bloqueadas (Estufa/Pomar/Animais) ficava NA FRENTE de objetos (galinheiro, plantas):
  `room.gd._spawn_regions` agora usa z_index 0 e `move_child(region, 0)`: sombra e cerca ficam atrás dos
  objetos. Falta publicar (itens 8–12).
- (13) Galinheiro e curral abriam o mesmo painel com os dois. Agora cada abrigo tem lugar próprio
  (`worlds.json → farm.places.chicken_coop / cow_barn`, `hidden`, `panel: station:<id>`) e os objetos do
  `rooms/farm.json` (abrigo + bichos) usam `place:chicken_coop` / `place:cow_barn`. A zona "Animais"
  (`animal_yard`) e a lista "Lugares" continuam com o painel junto. Teste em `content_test`.
  Falta publicar (itens 8–13).
- (14) Loja de animais: botão cinza só dizia o 1º motivo ("Recolha 2 × Ovos") mesmo faltando moedas
  também. `SheetBuilder._animal_missing` mostra tudo em chips ícone + número (ovos 0/2, moedas 78/80);
  texto só para outros motivos (abrigo cheio etc.). Falta publicar (itens 8–14).
- (15) "Ir" de comprar/construir (objetivo `owned`) levava ao lugar da estação (ex.: fogão). Agora
  `Places.goal_target` devolve sempre `buy:<construção>`: a seta aponta o "+" do objeto
  (`RoomView.point_at("buy:<id>")`, cai no lugar só se a sala não tiver o "+") e abre a compra com o que é
  preciso ter. `WorldsScreen.enter` espera um quadro numa sala recém-aberta e `RoomView._reveal` confere a
  câmera de novo após 0,2 s (a seta aparecia fora de vista na 1ª abertura). Falta publicar (itens 8–15).
- (16) Configurações com vários saves (pedido do Vitor): engrenagem (`ui/icons/settings.png`, Pixen job
  `2521958e-e74f-4ec9-a45c-38ad69c6b2d0`) ao lado das moedas abre `SettingsPanel`: até 5 saves, cada um com
  nível/capítulo/moedas, Jogar, Tornar padrão (o que o jogo abre ao iniciar) e Excluir (2 toques); "+ Novo save".
  O save de sempre vira o Save 1 (sem migração). Detalhes no cabeçalho de `save_manager.gd`.
  Teste: `saves_test` (usa o slot 4 e devolve o padrão). Falta publicar (itens 8–16).
- (5) Recolher direto no mapa + animação: `Events.items_gained` / `CollectFx` (z_index 20, filho de `main`).
  Tocar numa estação/criação com lote pronto, no marcador "Recolher" da Natureza ou numa planta
  madura recolhe sem abrir painel e salta ícone +N. Os botões de recolher dos painéis usam a mesma
  animação (a partir do meio da tela). `GameState.last_gain/last_coins` guardam o que a última coleta
  da Natureza trouxe. Teste em `nature_test` (captura `collect_fx`). Rotas legadas (`route_group` em
  objetos) ainda abrem o painel.
- Suíte completa verde. Falta publicar (aguardando OK do Vitor) e testar no celular.

**Publicação da nova história autorizada pelo Vitor (13/10/2026).**
- Pacote das Fases 1–3 e introdução preparado para envio na `main`, com deploy
  automático de prod (`/`) e dev (`/dev/`). Suíte completa e export local passaram.
- Save v11 reinicia saves anteriores, conforme decisão da reformulação da história.
- Próximo: testar no celular a chegada, as quatro linhas em paralelo e os animais;
  ajustar ritmo e clareza a partir da experiência do Vitor.

**Plano de linhas de NPC concluído — Fase 3 (Codex, 13/10/2026).**
- Feirante tem 4 passos a partir do capítulo 4 (conversa, vender 5, encomenda, mais 2).
  Guia tem 4 a partir do capítulo 5 (conversa, Bosque, Pedreira, Prado). As linhas
  progridem em paralelo sem bloquear Laís/Bloblo; metas fresh usam base de cada linha.
- Laís usa "Pedindo algo" nas conversas e "Acenando sorrindo" ao receber missão.
  Artes existentes do personagem correto "Laís Avatar", sem gerar imagens novas.
  `NpcPortrait` preserva a animação durante atualizações do painel e pausa oculto.
- Campanha simulada completa: 138 ciclos, 30 aquisições, 51 missões. Novo teste
  `npc_lines_test` cobre liberação gradual, independência, coleta real, save e animações.
- Suíte completa verde (incluindo DEV em prod); export Web prod/dev concluído sem
  erros em `build/web` e `build/web/dev`. PNGs, imports e UIDs novos gerados.
- Capturas 360×780: `npc_lais_request`, `npc_lais_complete`, `npc_merchant_line`,
  `npc_guide_line`. Próximo: jogar no aparelho e ajustar ritmo (publicação autorizada acima).

**Polimento das conversas e do sítio (Codex, 13/10/2026).**
- Mapa mostra ! para missão nova e ✓ com prioridade para missão pronta; NPCs fechados
  não geram aviso. Bloblo se apresenta em 3 falas, uma vez por save, com retomada se fechar.
- Canteiros fechados indicam Vovó e levam à conversa até liberar a escritura; atalhos
  dos NPCs escondem lugares fechados e construções não compradas (como o Pomar).
- Sheet remove conteúdo anterior da árvore antes da próxima fala, evitando nomes
  duplicados temporários. `intro_test` cobre apresentação, retomada, save, badges e atalhos.
- Capturas 360×780: `intro_bloblo.png` e `intro_bloblo_quest.png`.
- Suíte completa passou após os ajustes, incluindo introdução e DEV em prod;
  campanha do zero ao fim: 138 ciclos, 30 aquisições e 43 missões.
- Fase 3 ainda tem animações de missão da Laís e linhas próprias de Feirante/Guia.
  Trabalho local, sem commit/publicação.

**Fase 2 — animais na linha da vovó concluída (Codex, 13/10/2026).**
- B8–B13 ensinam galinheiro, ovos, curral, leite, farinha e queijo após a Bancada.
  Laís fica com 9 capítulos; ids antigos preservados, mais `bloblo_milk`.
- Abrigos custam moedas + tábuas (180 + 4 / 300 + 6), com primeiro animal presente.
  Variedades abrem com 2 e 6 produtos recolhidos; lojas e ajuda mostram o requisito.
- Campanha passou com 138 ciclos, 30 aquisições e 43 missões. Testes cobrem custo,
  presente único, persistência, desbloqueio só na coleta e produção por lote.
- Próximo: Fase 3 (badge no Mapa, apresentação da Bloblo, animações e outras linhas),
  além dos ajustes de canteiros/atalhos anotados no plano. Sem commit ou publicação.

**Introdução — retomada da última conversa do Claude (13/10/2026).**
- Após a Fase 1, Vitor pediu a chegada em casa com a Laís apresentando e soltando o Tiro.
  Claude implementou a cena e parou no limite da sessão após acrescentar título/capítulo.
- Codex conferiu o retrato contra o arquivo de "Laís Avatar" baixado pelo Claude (hash igual),
  revisou capturas 360×780 e protegeu o fim da cena contra toques repetidos no mesmo frame.
- `intro_test.gd`, incluído em `tools/test_all.ps1`, verifica apresentação automática,
  revelação do Tiro, persistência após recarregar, chegada em casa e primeira conversa
  sem receber a missão automaticamente. Capturas: `build/screenshots/intro_*.png`.
- Validação: suíte completa passou (incluindo DEV em prod), teste novo de introdução
  passou com renderização e novamente headless após a proteção contra toque repetido.
- Próximo: Fase 2 do plano (animais da vovó); apresentação da Bloblo e demais polimentos
  continuam pendentes. Alterações locais, sem publicação.

**▶ PRÓXIMO GRANDE TRABALHO: linhas de missões por NPC (Laís + vovó Bloblo) — Claude Code, 13/10/2026.**
- Design combinado com o Vitor: `docs/plans/QUESTLINES.md` (história, falas, paralelismo).
- **Plano de execução com fases e checklist: `docs/plans/TASKS_QUESTLINES.md`** — leia primeiro.
  Decisões fechadas: save zerado; Laís (casa) conduz a história; Bloblo é a vovó do sítio;
  um passo ativo por linha; casa começa sem fogão/geladeira; ensopado = 2 cenouras + 1 batata.
- **Fase 1 feita (Claude Code, 13/10/2026):** linhas em paralelo (`kind: "line"`), Laís andando na
  Casa e vovó Bloblo no Sítio (`NpcWorld`, balão `!`/`✓`, toque = conversa com retrato + fala),
  aba Missões com um cartão por linha, cap. 1–5 da Laís + B1–B7 da vovó, cozinha só depois do
  sítio, ensopado (2 cenouras + 1 batata), canteiros emprestados (`farm.lent_plots`), save v11 zerado.
  Suíte completa verde (campanha: 139 ciclos, 30 aquisições, 42 missões); capturas 360×780 conferidas.
  Ainda não publicado. **Próximo: Fase 2** (animais na linha da vovó, abrigos com moedas + tábuas,
  primeiro bicho de presente) e os "Pontos para olhar" listados no plano.

**Experiência por uso e cadeia clara de desbloqueios (Codex, 13/10/2026).**
- Região abre uma vez com moedas; recolher cada coleta dá 10 XP próprios. Níveis/espaços
  seguintes são automáticos: Bosque/Prado em 30/90 XP, Caverna em 40/120 XP.
- Painel mostra barra, próxima liberação, coletas restantes e ? com cadeia completa.
  Atributos do Tiro inclui as três regiões. Compra inicial mostra preço/requisitos normais.
- nature_xp persistente e consultas puras; XP local salvo no lote e entregue uma vez.
  Tokens owned mantêm rotas/ajuda; marcos de XP não podem ser comprados. Pomar não ganha XP local.
- Save v10 preserva ferramentas/níveis/vagas anteriores e histórico de uso como XP equivalente;
  nature_levels_version 2 impede conversão duplicada. Prazo/produtos/missões/moedas preservados.
- Suíte completa passou; campanha 129 ciclos, 30 aquisições, 33 missões. Nature/tasks/content
  repetidos após ajustes finais; capturas 360×780 verificadas (incluindo Caverna nível 2).
  Export Web prod/dev sem erros. Publicação prod/dev autorizada em 13/10/2026 via main.
  Próximo: avaliar clareza/ritmo de XP no celular.

**Níveis comprados — substituídos por experiência de uso acima (Codex, 13/10/2026).**
- Bosque, Caverna e Prado têm desbloqueio e níveis permanentes, comprados no próprio painel.
  Nível 3 do Bosque libera madeira dura; Caverna 2 cobre, Caverna 3 cristais; Prado 2 mais fibras.
  Coleta com um toque e três vagas simultâneas continuam. Vagas compradas separadamente.
- Removidas compras de ferramentas e trava extra de Aventura para materiais. Conteúdo em
  nature_sites.level_upgrades/requirements; progress.nature_level deriva ampliações compradas.
- Refinar lista receitas/ingredientes e leva às estações existentes. Sem novas receitas.
- Save v9 converte ferramentas e locais já explorados sem cobrar; preserva moedas, missões,
  vagas e tarefas com prazo/recompensa. main_5_pickaxe mantém id e agora pede abrir a Caverna.
- Suíte completa passou; campanha com 158 ciclos, 29 aquisições e 33 missões. Nature test
  repetido após ajustes, incluindo migração idempotente, acesso antigo sem ferramentas,
  prazo/recompensa em curso, níveis bloqueados e destino real do refino. Export Web prod/dev
  sem erros; capturas 360×780 verificadas (Bosque fechado/nível 1 e Caverna nível 3).
  Alteração local; ainda não publicada. Próximo: publicar e avaliar progressão no celular.

**Coleta com um toque e painel enxuto (Codex, 13/10/2026).**
- Material virou ação direta: tocar já chama `start_next_gathering` e ocupa a primeira
  vaga livre. Sem selecionar material e depois espaço; cada toque inicia uma tarefa.
- Painel compacto: materiais com ícone/rendimento/tempo, ferramenta em legenda, fila
  com ícone/tempo/barra, compra das vagas e botão único para recolher os prontos.
  Próxima ferramenta tem atalho Melhorar, em vez de cartão de compra completo na coleta.
- Nature test verifica um toque por tarefa, fila cheia sem sobrescrita, requisitos,
  coletas mistas e reutilização de vaga no meio preservando as outras tarefas.
- Suíte completa verde (incluindo campanha e dev/prod); Nature test repetido após ajuste
  visual, sem erros. Capturas 360×780 verificadas, incluindo fila mista e recolhimento.
  Publicação prod/dev autorizada em 13/10/2026 via main. Próximo: avaliar os toques no celular.

**Coleta por local e três vagas simultâneas (Codex, 13/10/2026).**
- Árvores e Pedras agora são pontos distintos no mapa; Fibras fica no prado. Um toque abre
  ferramenta, rendimento/tempo, vagas e próxima melhoria daquele local, sem abas/listão.
- Uma vaga inicial por local; segunda/terceira compradas ali (Árvores 100/200, Pedras 120/240,
  Fibras 80/160 moedas). Máximo três, começando juntas e terminando independentemente.
  Locais trabalham ao mesmo tempo; iniciar nos livres/recolher prontos tem botão único.
- Save v8: progress.gathering por local/índice, timestamps Unix e rewards congeladas. Atividade
  antiga da Natureza migra para a vaga 1, sem perder prazo/recompensa; pomar segue compatível.
  Ir das missões mantém lane/quarry exatos após comprar ferramentas melhores.
- Nature test cobre UI, compra das vagas, simultaneidade (três cortes + pedra), offline,
  coleta única, migração, melhorias durante coleta e indicador de três prontos. Campanha
  completa passou com 152 ciclos, 27 aquisições e 33 missões. Demais testes passaram.
- Suíte completa verde e export Web prod/dev concluído sem erros. Capturas 360×780 em
  `build/screenshots/nature_{trees_initial,trees_working,trees_ready,rocks,sites_map}.png`.
  Material por vaga fica salvo; coletas mistas preservam ícone, prazo e produtos extras.
- Publicação prod/dev autorizada em 13/10/2026, via push na main. Próximo: avaliar a clareza dos dois painéis no celular.

**Ferramentas por categoria — substituído pelos locais acima (Codex, 13/10/2026).**
- Aba Ferramentas com filtros Madeira/Mineração/Fibras, definidos em `nature_tool_groups`.
  Cada filtro mostra apenas seu kit; Mineração reúne as três picaretas, mesmo vindo de Pedras.
- Ícones dos materiais atendidos, próxima ferramenta destacada e custos existentes.
  Na coleta: ícone + Usa/Precisa/À mão; requisito deriva da rota, não da última ferramenta
  comprada. Próxima melhoria indicada e atalho Ferramentas abre o grupo correspondente.
- Nature test ampliado com troca real de filtros, compra após trocar abas, material sem
  ferramenta e indicação da ferramenta correta após comprar todos os níveis.
- Suíte completa verde, capturas 360×780 conferidas e export Web prod/dev sem erros.
  Capturas `nature_tools_mining.png`, `nature_tools_buy.png`, `nature_collect.png` em build/screenshots.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main. Próximo: acompanhar
  a clareza dos kits e dos requisitos de coleta no celular.

**Natureza integrada, ferramentas e seleção de mundos (Codex, 13/10/2026).**
- Substituído o mapa de pontos separados por paisagem PixelLab contínua 512×384: floresta,
  riacho com ponte, trilha e gruta. Obstáculos reais bloqueiam água, árvores e penhascos.
- NatureUi reúne todos os materiais e ferramentas num painel; botão Coletar no cabeçalho,
  cenário inteiro tocável. `nature_resources` prioriza melhor rota conforme ferramentas;
  madeira/pedra/cobre/cristais/fibras não exigem trocar de lugar para coletar.
- Machado → reforçado (madeira dura); picareta → reforçada → precisão; foice. Ferramentas
  são compras normais. Madeira dura vira tábuas na bancada e serve à picareta de precisão.
  Rotas existentes preservadas, melhorias opcionais; save/produção em curso mantêm resultados.
- Mundos: quatro cartões horizontais com miniatura inteira, nome curto, função, bloqueio/
  status; cartão inteiro entra com um toque. Título Para onde vamos?, volta por Mundos.
- Testes de Natureza cobrem compra via UI, seleção automática, rendimento, save e melhoria
  durante lote; campanha simulada chegou a 33 missões e 21 aquisições em 130 ciclos.
  Worlds test cobre bloqueio/entrada por cartão e atalho de coleta. Capturas 360×780.
- Suíte completa verde e export Web prod/dev sem erros. Capturas finais:
  `worlds_{locked,select}.png`, `nature_{open,collect,collect_ready,tools_buy}.png` em
  build/screenshots. Caminhos de ambos os lados da ponte e até a gruta também validados.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main, incluindo Natureza,
  ferramentas, seleção de mundos e variedades dos animais. Próximo: acompanhar no celular.

**Natureza como novo mundo — protótipo substituído pela versão acima (Codex, 13/10/2026).**
- Quarto mundo, mapa 1208×683 com árvores/troncos, riacho/ponte, prado de fibras, gruta
  de pedra/cobre e gruta de cristais. Portão da Vila viaja para Natureza; Guia mudou para lá.
- Abre no capítulo 3. Bosque disponível ao entrar; riacho = Aventura 2; pedra = picareta;
  cristais = picareta + Aventura 3; prado = Aventura 4. Mesmas rotas/ids/tempos/recompensas.
- `regions.requirements` abre cercas por progressão e recalcula a navegação. Etiquetas
  alternam entre requisito e nome; objetos de exploração mostram timer/Recolher no mapa.
- Destinos de missão/manual/mochila resolvem cada zona. Saves e rotas em curso preservados.
- `nature_test` valida viagem pelo portão, evolução real abrindo riacho, picareta/grutas,
  áreas bloqueadas/abertas, coleta única, indicadores e navegação. Capturas 360×780 em
  `build/screenshots/nature_{locked,open,ready,crystals}.png`.
- Suíte completa verde (incluindo Natureza e animais); export Web prod/dev concluído sem
  erros. Capturas conferidas em 360×780, com requisitos legíveis e sem etiquetas sobrepostas.
- Protótipo substituído pela versão integrada acima, incluída na publicação autorizada.

**Compra individual e variedades dos animais (Codex, 13/10/2026).**
- Galinheiro/curral novos começam vazios. Loja dentro do abrigo: três variedades por espécie,
  preço individual, quantidade possuída e três vagas por abrigo; cada compra aparece no mapa.
- Galinhas branca/ruiva/preta; vacas pintadinha/caramelo/malhada. Variedade muda o visual;
  cada animal consome o alimento da receita e produz duas unidades. Quantidade do lote é
  fixada ao alimentar, inclusive offline; comprar outro animal não aumenta lote em curso.
- Save v7 mantém os dois animais antes incluídos em cada abrigo já adquirido; saves novos
  guardam quantidades por variedade. Slots vazios não bloqueiam caminhos nem recebem toque.
- Suíte completa passou, incluindo campanha com compras reais, lotação, moedas,
  save/migração e caminhos com as seis variedades. Loja/mapa conferidos em 360×780.
- Export Web prod/dev concluído sem erros; capturas em `build/screenshots/animals_shop.png`
  e `animals_farm_overview.png`. O botão da loja também é testado acionando sua compra.
- Incluído na publicação autorizada em 13/10/2026, junto de Natureza e seleção de mundos.

**Sítio dos animais e processamento (Codex, 13/10/2026).**
- Quarta área no sítio (1208×683), cercada até comprar o galinheiro. Corredor independente
  das expansões de estufa/pomar; duas galinhas e duas vacas, com arte PixelLab e movimento leve.
- Cadeias: milho → ovos; trigo → leite → queijo; trigo → farinha. Galinheiro/curral = um lote
  por vez; moinho/queijaria = duas posições na fila. Alimentar, esperar, recolher; indicador
  de tempo/coleta no mapa. Reutiliza StationState/save v6, sem duplicação de alimentação/coleta.
- Abre após sítio próprio/capítulo ≥3; lugar Animais e lugar Produção (bancada+moinho+queijaria).
  Manual, mochila, venda, ajuda dos ingredientes e navegação já reconhecem os novos recursos.
- Capítulo 9 com cinco passos, preservando a campanha anterior; duas diárias, uma semanal e
  encomenda Café da manhã. Campanha simulada passou com 328 ciclos, 16 compras e 33 missões.
- Novo `animals_test` cobre requisitos, alimentação, lotação, coleta única, offline/save antigo,
  processamento e corredor. Capturas `animals_{farm_overview,feed,dairy,manual_milk}.png`.
- Suíte completa verde; export Web prod/dev concluído sem erros. Toque direto no moinho
  também validado com bancada ainda não comprada; destinos próprios no manual/missões.
- Publicação em prod/dev autorizada por Vitor em 13/10/2026, junto das melhorias de mundo
  abaixo, via push na main. Próximo: acompanhar balanceamento e experiência no celular.

**Tiro reagindo, construções visíveis e sítio ampliado (Codex, 13/10/2026).**
- Sítio 1208×539: duas laterais cercadas e sombreadas, abertas pelas compras já existentes
  de estufa/pomar. Centro anterior preservado, mesmos nove canteiros/índices de save; câmera
  começa no centro e pode arrastar/diminuir zoom. Ir enquadra destinos fora da tela.
- Arte PixelLab: bancada, estufa, pomar, forno, banca extra e estação de costura aparecem após
  comprar; caminhos contornam suas bases. `regions` bloqueia chão antes da compra e retira
  a cerca ao abrir. Requisitos/custos existentes preservados, sem migração de save.
- Colher, recolher e comprar emitem `world_activity`. Tiro vai ao objeto, cheira em colheita/
  produção pronta e comemora com pulo/coração. Reações não acordam o Tiro nem rodam em mapa
  oculto; o movimento se interrompe quando muda a navegação ou chega outra ação.
- Novo `world_life_test` cobre ações reais, construções em save avançado, áreas fechadas/abertas,
  reação a produção pronta, sono e caminhos completos após compras. Capturas 360×780 em
  `build/screenshots/{farm_expansion_start,farm_expansion_built,farm_orchard_focus,house_buildings,village_buildings}.png`.
- Suíte completa verde e export Web prod/dev concluído sem erros. Reação de colheita conferida
  em `build/screenshots/tiro_harvest_reaction.png`; o teste aguarda a chegada/animação do Tiro.
- Incluído na publicação autorizada em 13/10/2026. Próximo: acompanhar visual/reações no celular.

**Manual visual na tela principal (Codex, 13/10/2026).**
- Botão Manual acima do Tiro, disponível desde o começo. Catálogo Recursos/Estações em
  `GameManual`, gerado dos dados existentes: itens por categoria, origens, ingredientes,
  quantidades, tempos, usos e local mundo › lugar. Toque em ingrediente abre sua origem.
- Ir até lá para os lugares; Ver compra para estações não compradas; mundos/lugares fechados
  continuam bloqueados com motivo. Catálogo completo é consulta, sem mudar progresso/save.
- Atalhos acima do Tiro usam fluxo para caber Manual + Atributos + Coleção no celular.
- Suíte completa incluindo novo `manual_test`: consulta sem alterações, todos os itens,
  bloqueios, ingrediente tocável e navegação até a bancada. Capturas 360×780 `manual_*` conferidas.
- Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev), após suíte completa verde.
  Próximo: revisar no celular a consulta de recursos e os atalhos do manual.

**Instruções breves nas missões (Codex, 13/10/2026).**
- Pedido do Vitor: só ícones deixaram a ação difícil de entender. `goal_row` agora mostra
  `goals[].label` acima da barra, tanto na História quanto nos cartões dos personagens.
- Primeira colheita explica plantar e esperar crescer. Todas as diárias/semanais têm
  `description` com ação e quantidade, exibida na largura do cartão, sem exigir tocar em "?".
- Teste de Missões passou; capturas 360×780 `tasks_start` e `tasks_middle` conferidas.
  Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev); suíte completa
  rodada novamente antes do envio. Próximo: revisar a clareza das frases jogando no celular.

**Tiro andando no Sítio e na Vila (Codex, 13/10/2026).**
- Ambos têm `dog_start`; Vila ganhou `floor`. Canteiros têm `footprint`; `obstacles` bloqueia
  casas, feira, árvores/pomar, caixas e banco desenhados no fundo. Margem de navegação de 8 px
  nos mapas externos; grade da casa também confere cantos de células (4 px).
- Proporção ajustada após pedido do Vitor: `dog_scale: 0.5` no Sítio/Vila; Casa mantém 1.
  Sprite, sombra e área de toque acompanham a escala; patas continuam ancoradas no chão.
- Pontos de tigela/sofá são opcionais: fora da casa o Tiro dorme no local e não tenta ir à origem.
  Nasce no chão livre, sorteia apenas destinos alcançáveis e não anda direto até um alvo sem rota.
- Suíte completa verde, incluindo novo `navigation_test` (100 caminhos por mapa, limites,
  obstáculos, sono e ausência de rota). Capturas 360×780 conferidas em
  `build/screenshots/tiro_{farm,village}{,_walking}.png`.
- Publicação autorizada pelo Vitor em 13/10/2026: enviar pela `main` para o deploy automático
  de prod e dev no GitHub Pages. Suíte completa rodada novamente antes do envio.
- Próximo: conferir no aparelho o passeio e a proporção do Tiro; ajustar as áreas conforme
  novas artes/objetos entrarem nos mapas.

**Simplificar — todas as 5 fases concluídas (Claude Code, 13/10/2026). Sem push: esperando o Vitor aprovar.**
- O Vitor achou o jogo confuso ("bombardeamento de informação"). Plano aprovado em `docs/plans/SIMPLIFICAR.md`:
  missões em 3 tipos (História, Diárias, Semanais), 3 mundos (a Trilha vira portão na Vila), 4 atributos,
  personagens que aparecem aos poucos, revelação gradual com "Novo!" e menos texto em todo canto.
  Regra que vale sempre: **ícone + número em vez de frase; simplificar**.
- **Fase 1 feita:** aba Tarefas → **Missões** com 3 blocos. História = cartão visual (rosto, ícone + `0/6`,
  lugar em ícones, ingredientes que faltam em chips tocáveis, recompensa em chips, **Ir** + **?**).
  Diárias (3, a partir do cap. 2) e Semanais (2, a partir do cap. 3) em `data/routines.json`, estado em
  `ProgressionState.routines`. Secundárias removidas (roupas → semanais). Atributos/Coleção → aba Tiro.
  "Como fazer" do Codex (`task_help.gd`) refeito em ícones; os botões de ajuda espalhados viraram "?" e chips.
  Novas peças: `UiKit.tap_chip/square_button/short_label/fill_label`, `ProgressionUi.goal_row/reward_chips/item_chip`,
  `Places.target_view`, tema `ChipButton`. DEV: "Recomeçar diárias e semanais".
- Testes verdes (farm, progression, DEV dev/prod, tasks com diárias/semanais, content). Capturas:
  `build/screenshots/tasks_{start,middle,story,help,end,celebration}.png`.
- **Fase 2 feita:** 4 atributos (Horta, Cozinha, Comércio, Aventura), escondidos até o capítulo 3
  (`features.skills`). Construções não exigem nível. Passos "suba o atributo" viraram ações
  contadas a partir do início do passo (`"fresh": true` + `ProgressionState.step`). Save v6 soma
  Passeio+Mineração+Construção em Aventura e remove Vínculo. Painel de Atributos em ícones.
  Dados migrados com uma ferramenta única (não versionada); a formatação dos JSON foi mantida.
- **Fase 3 feita:** 3 mundos (Casa, Sítio, Vila), no máximo 4 lugares visíveis cada. Casa: Tigela, Cozinha
  (fogão + forno + fila extra), Geladeira, porta. Vila: Feira (abas Vender/Encomendas + banca), Ateliê,
  Portão da trilha (passeios + mina + picareta; capítulo 3). Sem menus "Construir em…": cada construção é
  comprada no próprio lugar (`upgrade`/`upgrades` em `worlds.json`; `Database.place_of_upgrade`).
  Mapa e "Lugares" em ícones. `rooms/trail.json` removido (arte guardada). `content_test` garante 3 mundos e ≤4 lugares.
- **Fase 4 feita:** revelar aos poucos. `progression.json → features` (Mochila após a 1ª colheita, diárias cap. 2,
  semanais e atributos cap. 3); NPCs com `requirements` (Feirante 2, Guia 3, Laís 4). Tela "Novo!" (com a
  comemoração de capítulo) lista o que abriu com ícone + Ir, uma vez só (`ProgressionState.seen`). O "Ir" mostra
  uma seta sobre o objeto da sala e abre o painel 0,8 s depois. Detalhes em `docs/WORLDS.md`.
- **Fase 5 feita:** menos texto no resto. Mochila em 4 colunas (ícone + `x12`); detalhe do item com preço,
  "De onde vem" e "Usado em" em chips que levam ao lugar; sementes compactas (bloqueada = "?"); canteiros em
  grade; compra de terreno em ícones; coleção em grade (conquistado colorido, resto "?"); personagem = rosto +
  fala curta + atalhos (falas encurtadas em `npcs.json`).
- Capturas: `build/screenshots/` → `tasks_*`, `go_pointer`, `ui_*` (mapa, vila, feira, portão, cozinha, mochila,
  item, NPC), `sheet_seeds`, `farm_*`.
- **Próximos passos sugeridos:** Vitor jogar a versão dev e aprovar → publicar (push na main); testar o toque
  real (`tools/touch_test.ps1`); ícones próprios (PixelLab) para encomenda, passeio e coleção (hoje reaproveitam
  ícones de itens); balancear diárias/semanais com jogo real.

**Tarefas v2 — todas as fases (1–6) concluídas (Codex, 12/10/2026).**
- 28 passos principais em 8 capítulos e 9 secundárias; recompensas por capítulo, destinos
  com Ir, painel História, recomendações por progresso e ajuda para evoluir atributos.
- Comemoração modal, faixa/toast com próximo passo, guia inicial e badge sem duplicação.
- Save v5 migra capítulos cujas construções já eram adquiridas sem pagar recompensas.
  Vila abre após first_harvest; Trilha no capítulo 3. Ferramentas DEV seguem a sequência.
- Todos os testes verdes: farm, progression (296 ciclos, 37 missões, 12 construções),
  tasks, content, DEV e DEV --prod. Export Web prod/dev local e toque real em Chrome
  headless confirmaram Tarefas → Ir → Tigela do Tiro, sem erros no console.
- Capturas 360×780: build/screenshots/tasks_{start,middle,end,story,side,celebration}.png.
  Símbolos da história têm fonte bitmap própria de apoio (a Web não tem fallback do Windows).
- Ajustes ao esboço para evitar produção antes da estação: oficina/tecidos são secundárias;
  capítulo 8 prepara fibras e Construção antes do ateliê. Nenhum trecho ficou pela metade.
- Seis commits locais, um por fase. **Sem push/publicação.** Próximo: Vitor revisar as capturas;
  só publicar quando solicitado. Depois, balanceamento em jogo real e vestir a coleção.

**Rodada 2 (12/10/2026, Claude Code): navegação intuitiva + mini mundos**
- Pedido do Vitor: "tá difícil achar rotas, vender, missões; deixar os menus intuitivos" e
  "vão ter vários mini mundinhos, cada um com seus NPCs".
- Abas novas: **Tiro · Mapa · Tarefas · Mochila** (a aba Jornada com 8 sub-botões foi removida).
  Cada função mora num lugar de um mundo; Tarefas mostra próximo passo, prontos agora e missões com "Ir".
- Mundos orientados a dados (`data/worlds.json`): Casa, Sítio, **Vila** (Feirante, Laís: vender,
  encomendas, ateliê, lojas) e **Trilha** (Guia: passeios, mina). Vila e Trilha ganharam cena própria
  (PixelLab) com zonas tocáveis e etiquetas. Receita para criar mundos em `docs/WORLDS.md`.
- Mochila com detalhe do item (como conseguir, onde usar, vender). Retratos provisórios dos 4 NPCs.
- Testes passando; teste de toque no Chrome confirmou Tarefas → Ir → Trilha → Guia.

**Próximos passos (rodada 2)**
1. Trocar os retratos provisórios pelas fotos do Vitor (`npcs.json → portrait`). Feito: **Laís** (artesã da Vila).
   Receita em `docs/ART_PIPELINE.md`.
2. NPCs pequenos dentro das cenas (sprite no mundo, além do botão no cabeçalho).
3. Novos mundos seguindo `docs/WORLDS.md` (ex.: parque, praia, clínica).
4. Tutorial curto inicial concluído em Tarefas v2 (guia no Tiro e aba pulsando).

**Rodada 1 — feito**
- Progressão completa (**Jornada**), criada pelo Codex: casa quase vazia no começo, canteiro emprestado,
  7 atributos, 12 construções, 7 rotas, feira (venda + 6 encomendas), 8 capítulos, 15 missões de 4 NPCs,
  6 itens de coleção. Save v4 com migração. Ver `docs/PROGRESSION.md`.
- Revisão e organização (Claude Code):
  - dados da progressão saíram de 9 variáveis soltas no `GameState` para `ProgressionState`
    (`scripts/state/`, acesso por `GameState.progress`), seguindo o padrão de `DogState`/`Inventory`;
  - o estado não depende mais da UI (`TimeText` em vez de `SheetBuilder.format_time`);
  - bugs corrigidos: rota removida do JSON travava o jogador para sempre; receita removida travava a coleta;
    texto do capítulo final fixo no código (agora `final_chapter` no JSON);
  - `house.json` voltou ao formato compacto (o Codex tinha expandido todas as coordenadas);
  - 14 ícones de itens novos + ícone da aba Jornada (PixelLab); ícones próprios em atributos,
    construções, rotas e chips "tem/precisa" com ícone na feira e nas construções;
  - abas inferiores com ícone em cima e texto embaixo (com 4 abas, "Jornada" não cabia).
- **Versão dev** (pedido do Vitor, que ficou sem resposta na conversa do Codex): `/dev/` com save
  separado, selo DEV e Ferramentas DEV (moedas, itens, atributos, pular capítulo, liberar tudo, terminar
  timers, avançar o tempo, copiar o save real). Deploy gera prod + dev. Ver `docs/DEPLOY.md`.
- Testes: `farm_test`, `progression_test` (campanha simulada) e `dev_tools_test` (dev e `--prod`) passando;
  teste de toque no Chrome headless confirmou prod sem selo e o painel DEV funcionando em `/dev/`.

**Próximos passos sugeridos**
1. Vestir as roupas da Coleção no Tiro (camadas sobre o sprite grande; `DogState.outfit` já existe).
2. Retratos dos NPCs a partir das fotos que o Vitor vai mandar (`npcs.json` → `portrait`).
3. NPCs pequenos no mundo (Bloblo no sítio, Tutor em casa) que abrem as missões ao toque.
4. Móveis da bancada, forno e ateliê na casa ou no sítio (hoje só pela Jornada → Produção).
5. Sprite próprio da planta de ervas (usa o broto como planta madura).
6. Balancear com jogo real (o ritmo hoje só é medido pela campanha simulada; ela termina com ~16 mil
   moedas, sinal de que vender o excedente rende demais no fim do jogo).
7. Telas do Hoje/Missões mais visuais (o painel ainda é bastante texto).

## Fase 0 — Fundação
- [x] Estrutura de pastas e documentação
- [x] Projeto Godot 4.7.2 (Compatibility, pixel art, celular em pé 360x780)
- [x] Autoloads `Events`, `GameState`, `SaveManager`
- [x] Preset Web PWA single-thread + scripts de export/servidor local
- [x] Workflow de deploy no GitHub Pages
- [x] Repositório no GitHub + primeiro deploy
- [ ] Testar instalação PWA e save no iPhone e no Android

## Fase 1 — Design
- [x] Ideia do jogo registrada (`GAME_DESIGN.md`)
- [ ] Receber referências visuais (`docs/references/`)
- [ ] Responder perguntas em aberto do design
- [ ] Padrões de arte (tamanho de tile/personagem, paleta)

## Fase 2 — Iteração 1 (ver `GAME_DESIGN.md`)
- [x] Base: toque/arrasto de câmera, `Hotspot`, tempo real offline, save automático
- [x] Tela do Pet: Tiro detalhado + 4 necessidades + comer/brincar/banho/dormir/carinho
- [x] Casa: geladeira, fogão (fila), tigela, sofá, brinquedos; Tiro autônomo
- [x] Inventário + receitas no fogão (dados em JSON) + XP/nível
- [x] Sprites PixelLab: Tiro pet (128px) e Tiro mundo (4 direções + andar)
- [x] Casa montada no PixelLab: sala vazia + móveis separados (geladeira, fogão, tigela, sofá)
- [x] Colisão com móveis (grade de navegação), profundidade (Y-sort), toque por pixel, sombra do Tiro
- [x] Animações do Tiro no mundo: andar, parado, sentar, latir, dormir, comer
- [ ] Mais móveis/decoração (caminha, brinquedos, TV, mesa) — por enquanto casa enxuta
- [ ] Barra de segurança no topo para notch do iPhone

## Iteração 2
- [x] Horta: Sítio da Bloblo (aba Sítio + porta da casa), cenoura/batata/abóbora (`crops.json`)
- [x] Progressão do sítio: canteiro emprestado, escritura, expansão até 9 em posições fixas, moedas por colheita, indicadores de crescimento e painel Meu sítio
- [x] Jornada: atributos, construções, rotas, feira (venda + encomendas), capítulos, missões de NPCs, coleção (`docs/PROGRESSION.md`)
- [x] Navegação intuitiva: abas Tiro/Mapa/Tarefas/Mochila, mundos em `worlds.json` (Casa, Sítio, Vila, Trilha) com NPCs (`docs/WORLDS.md`)
- [x] Versão dev em `/dev/` com save separado e Ferramentas DEV
- [ ] Bloblo como personagem no mundo (sprite + retrato); Tiro passeando no sítio
- [ ] Tutor dentro de casa (sprite pequeno + retrato detalhado + diálogo) com missões

## Iteração 3
- [ ] Customização (Ateliê): vestir as roupas da Coleção (camadas sobre o Tiro detalhado)
- [ ] Parque: passeio, truques, minigames

## Backlog / ideias técnicas
- [ ] `AudioManager` (música/sfx; destravar áudio no primeiro toque)
- [ ] Exportar/importar save como código (backup manual)
- [x] Aviso "nova versão disponível" no PWA
- [ ] Testes automatizados headless no CI
- [ ] `tools/pixel_tools.ps1` → `New-ContactSheet` falha ("Parâmetro inválido" ao criar o Bitmap)
