# Revisão Opus — Interface 2 "aconchego moderno" (25/10/2026)

Revisor: Claude Opus 5.5. Base: commits `f4c4e68` → `78f4db5` (etapas 01–12, só locais).
Fontes conferidas: plano (`00`–`05`, `etapas/`, `VALIDACAO_*`, `RESULTADOS`, `FUTURO`), pranchas do
protótipo (`prototipo/prancha_*.png`, `fogao.png`, `horta_*.png`, `missoes2_*.png`, `mundos.png`, `tiro_*.png`),
pranchas finais (`build/i2_12_review/final_*.png`, contatos `tour*`), capturas `i2_12_tour*`,
`i2_12_extra_*`, `i2_NN_depois`, logs do portão e o código atual.

**O que NÃO fiz nesta fase:** não editei código, não rodei a suíte nem o tour de novo (as conclusões vêm
das capturas existentes e da leitura do código). Onde a causa é hipótese, está escrito "provável".

---

## 1. Resumo geral

**Ficou bom.** A direção do protótipo chegou ao jogo nas telas que tinham prancha: rodapé claro preso,
HUD em duas linhas com pílula de próximo passo, Missões em três abas com sanfona, folha de prêmio
(quase idêntica a `missoes_premio.png`), seletor de mundos em cartões-postais (muito perto de
`mundos.png`), alfinete no lugar da seta, barra da horta com "Colher tudo (N)", roleta de cuidados,
Mochila com depósitos 2×2, detalhe do item, boas-vindas e cartão de capítulo. As fontes, a paleta e os
controles vetoriais mudaram de fato a cara do jogo. A documentação do fechamento é honesta.

**Ficou fraco.** O "meio feio" que o Vitor sente vem de quatro coisas:

1. **Hierarquia achatada.** Na etapa 01 a variação `SectionLabel` (que era título de seção, 22 px) virou
   igual à `SmallLabel` (Nunito 12, `INK_SOFT`). Ela é usada **82 vezes**, muitas delas para **nomes e
   títulos** (nome do produto na Feira, título do Como fazer, nome do passeio, corpo dos cartões do
   Manual, fases das obras). Resultado: telas cheias de texto de 12 px cinza, sem nada em 18.
2. **Painéis sem prancha ficaram "meio migrados".** As etapas 08–10 foram pequenas (324/441/595 linhas)
   e trocaram cores e fontes sem refazer a estrutura: Como fazer, painel da seda, "O que tem aqui?",
   Manual, Encomendas/banca, obras e Configurações ainda têm cara de visual antigo com fonte nova.
3. **Regras da bíblia furadas em vários lugares:** cerca de 20 botões cinza desabilitados (a regra é
   "nunca botão cinza, sempre `lock_hint`"), vermelho usado para "Provar"/"tem 0" (vermelho é só
   "pede atenção"), segmentados de uma opção só, rótulos de 6–9 px no Álbum.
4. **Defeitos de composição:** aviso por cima do título da folha, folha da conversa cortada, bandeja
   do fogão escondendo o fogão, HUD que se sobrepõe com "Texto maior" e engasgos no Sítio.

Nada disso exige refazer o plano. São ajustes localizados, e a maior parte é P ou M.

---

## 2. Avaliação por etapa

Nota de 0 a 10: entrega em relação ao plano e acabamento visual juntos.

| Etapa | Entrega × plano | Visual / coerência | Onde melhorar | Nota |
|---|---|---|---|---|
| **01 Base** | Completa: Fredoka/Nunito, `Palette`, 17 SVGs, tema, `test.ps1 -Exact`. | Base boa. | `SectionLabel` mapeada para 12 px achatou a hierarquia do jogo inteiro. `OverLabel` (maiúsculas) nunca é usada: o rótulo de seção usa `font_caption_spaced`. Variações mortas no tema (`TopBarPanel`, `BarLabel`, `ToastLabel`, `SoftButton`). | 7 |
| **02 Peças** | Completa (vitrine nas três resoluções). | Peças fiéis à bíblia. | `UiKit.stepper` nasceu sem "Tudo"/máximo, o que forçou a remoção do "Tudo ×N" na 07. `tile` com rótulo 12 em duas linhas fica apertado nos cartões da Coleção. | 8 |
| **03 Casca** | Completa: rodapé preso, HUD de 128, `NextStep`, `Notice`. | Rodapé e HUD bonitos e fiéis a `prancha_rodape.png`. | O `Notice` não sabe que há folha aberta e cobre o título (ponto 1). A linha 2 vazia deixa um vão de 50 px na Mochila e nas Missões quando a história acabou. Perfil e moedas se sobrepõem com "Texto maior". | 7 |
| **04 Tiro** | Completa: zoom, anéis no topo, Cuidar + roleta, alfinete. | Roleta muito boa (`tiro_roleta.png`). | O humor ("Tiro está feliz da vida!") é texto solto sobre o tapete, sem a etiqueta translúcida do plano, sempre visível. "Animado" é uma legenda verde solta sob o avatar. O cardápio usa chip **vermelho** "Provar", que fere a semântica da cor. O cardápio cobre o focinho do Tiro. | 7 |
| **05 Missões** | Completa: três abas, sanfona, folha de prêmio, voos. | A mais próxima do protótipo. | Linhas de "Neste capítulo" com discos de 44 (› e cadeado) pesadas demais; no protótipo são ícones de 20. Segmentado de uma opção só ("História" sozinha) vira uma pílula gigante. Nomes quebram em duas linhas (o › em disco rouba largura). História concluída = cartão vazio. | 8 |
| **06 Mundo** | Completa: mapa sem nomes, segurar mostra o nome, brilho, alfinete, postais, conversa, compra. | Postais e alfinete excelentes. | Dica de bloqueio "Após Uma encomenda da vizinhança" / "Após Ele está crescendo!" (gramática). Conversa: nome repetido (título + rótulo do balão), retrato repetido em cada cartão de missão, linhas de serviço com o texto preso no topo, folha cortada (ponto 2). A pílula do mundo aparece atrás do seletor. "O que tem aqui?" continua com botões antigos (um deles verde). | 7 |
| **07 Horta e bandejas** | Completa, com três desvios (ponto 5). | Barra da horta fiel a `horta_*.png`. | A bandeja do fogão cobre o fogão (o protótipo mostra o objeto em cima). Grade com 2,5 linhas deixa a bandeja muito alta. O tile Regar mostra só "×3", sem "Regar", e falta o separador. | 7 |
| **08 Mochila** | Parcial: depósitos, grade e detalhe ok; caderninho, Manual e Álbum só ganharam o tema. | Mochila e item bons. | Caderninho com dois segmentados empilhados; o rótulo ativo do Álbum aparece cortado ("·· Álbum"). O Manual segue como parede de texto de 12 px com um "Ir" largo por cartão. Fontes 6–9 px no Álbum. O título "Mochila" fica solto depois de um vão. | 6 |
| **09 Painéis** | Parcial: Crescimento e lojas ok; Como fazer, seda, Encomendas/banca, obras e Configurações ficaram no meio do caminho. | A etapa mais irregular. | Ponto 4 (cartões antigos no Como fazer); painel da seda com cartões brancos sem ícone; botões cinza "Entregar" / "Entregar contrato" / "Jogando" / "É o padrão"; vermelho demais nas obras ("tem 0", "faltam 4", linha vermelha "onde achar?") e barra azul repetindo os tracinhos; nomes em 12 px na Feira. | 5 |
| **10 Festa** | Completa: `RewardSheet` médio, `ModalCard` grande, boas-vindas, Novo! um por vez. | Boas-vindas e capítulo bonitos. | O cartão de capítulo com muitas novidades estoura a altura: rola e esconde fita e herói (`i2_05_chapter`), com Novos repetidos (dois "Sítio"). Na cerimônia, o Tiro aparece duas vezes (mini no raio + antes/depois) e a régua é fraca. Textos do ponto 7. | 7 |
| **11 Texto** | Parcial: `text_budget_test` e "Texto maior" existem; a limpeza ficou incompleta. | — | "Texto maior" sobrepõe perfil e moedas no HUD, e as Configurações perdem a margem de 16 (conteúdo mais largo que a folha). Sobram os apelidos `UiKit.GOOD/BAD` (35 usos) e `secondary`, e seis `add_theme_font_size_override` (6, 9, 11, 22 e 28 px) que o "Texto maior" não escala. | 6 |
| **12 Fechamento** | Feita com ressalvas honestas. | — | A meta de 20 ms do Sítio não foi atingida (ponto 3) e os testes instáveis ficaram para depois (ponto 6). As fixtures `g01`/`t03` do tour continuam enganosas. | 7 |

---

## 3. Lista priorizada de ajustes

Legenda de tamanho: **P** ≤ 1 h · **M** meia sessão · **G** uma sessão ou mais.
"Paralelo" diz com quem o item **não** conflita em arquivos.

### P0 — defeito visível ou quebrado

**1. O aviso cobre o título da folha (ponto conhecido 1)**
- **O quê:** com folha, seletor ou bandeja aberta, o `Notice` passa a nascer na faixa da linha 2 do HUD
  (y = `NOTICE_Y`, a mesma que a linha 2 recolhida libera). A folha alta para no fim do HUD: o topo nunca
  sobe acima de `Hud.HEIGHT` (128), o que troca o `TALL` fixo de 0,88 por `size.y - Hud.HEIGHT`
  (perde cerca de 34 px em 360×780). Assim o aviso nunca encosta no título.
- **Onde:** `scenes/main/main.gd` (`notice_top`, reaproveitando a condição de `_check_row2`),
  `scenes/ui/sheet/sheet.gd` (`_target_height`), `scenes/ui/worlds_screen/worlds_screen.gd` (`toast_top`
  devolve 0 com o seletor aberto).
- **Por quê:** 02 §5 diz "posição única, logo abaixo da segunda linha do HUD". Hoje `toast_top()` mede a
  pílula e os rostos do mundo, que ficam **atrás** do seletor (captura `b05_map_list`, em 360 e 412).
- **Como verificar:** `notice_test` com caso novo (seletor aberto + aviso de momento: o retângulo do
  aviso não cruza o título da folha); `ui_tour` `b05_map_list` e `b17_npc_lais` nas três resoluções.
- **Tamanho:** P. Paralelo com 3, 4 e 6.

**2. A folha da conversa fica cortada embaixo (ponto conhecido 2)**
- **O quê:** a `Sheet` mede de novo sempre que o **conteúdo** muda de tamanho mínimo: ligar
  `_content_holder.minimum_size_changed` (ou o do conteúdo) a `_queue_fit`. Acrescentar uma folga
  inferior fixa de 16 px no fim da rolagem.
- **Onde:** `scenes/ui/sheet/sheet.gd` (`open`, `_queue_fit`).
- **Por quê (causa provável):** a altura é medida uma vez, dois quadros depois de abrir (`_slide_in`),
  e só volta a ser medida quando a própria folha muda de tamanho (`resized`). A conversa reconstrói o
  corpo depois disso (`SheetBuilder._schedule_rebuild` em `state_changed`; o aviso de momento da captura
  vem de uma mudança de estado), e a folha fica com a altura do conteúdo antigo: só a fala aparece
  (`b17_npc_lais`). Na Bloblo (`i2_06_npc`), a última linha "Vender" encosta na borda sem folga.
- **Como verificar:** `sheet_test` com caso novo (abrir folha pequena, crescer o conteúdo dois quadros
  depois: a altura acompanha até o limite); tour `b17_npc_lais` e `i2_06_npc` nas três resoluções.
- **Tamanho:** P. Paralelo com 3, 4 e 6 (conflita com 1 no `sheet.gd`; faça 1 e 2 juntos).

**3. "Texto maior" quebra o HUD e as Configurações**
- **O quê:** a `HudProfile` encolhe (nome com reticências e largura mínima) e a pílula de moedas cresce
  para a esquerda sem invadir o perfil. As linhas das Configurações e dos saves quebram o texto em vez
  de alargar a folha (a margem de 16 some porque o conteúdo fica mais largo que a tela).
- **Onde:** `scripts/ui/hud.gd`, `scripts/ui/settings_panel.gd`, `scripts/ui/large_text.gd`.
- **Por quê:** `i2_11_pet`, `i2_11_tasks` e `i2_11_stove_tray` mostram as moedas por cima de "Tiro".
  Em `i2_11_settings` o título está a x = 8.
- **Como verificar:** `text_budget_test` ganha checagem geométrica (perfil × moedas sem interseção;
  folha sem rolagem horizontal) com "Texto maior" em 360×780; tour `--i2-11-only` em 360/390/412.
- **Tamanho:** P/M. Paralelo com 1, 2 e 4.

**4. Engasgos no Sítio: 28,3 ms em média, picos de 150 ms (ponto conhecido 3)**
- **Diagnóstico provável.** O sinal mais forte está nos números: 121 de 479 quadros passaram de
  33 ms em cerca de 13,5 s, ou seja, **cerca de 9 quadros lentos por segundo**. Isso bate com o
  temporizador de 8 Hz do `RoomView._animate_objects`. Cada tique faz, para **todos** os 28 objetos
  do Sítio:
  - `GameState.album_hint_glow(id)`: percorre as 54 fotos, monta um dicionário e chama
    `AlbumRules.holds` (cerca de 1.500 iterações por tique, mais de 12 mil por segundo);
  - para cada canteiro, `plot_status`, `plot_progress`, `water_error` e `PlotIndicator.refresh`;
  - para cada estação, `ready_count` e `StationIndicator.refresh`.

  Além disso, `_place_labels()` recalcula `requirement_error` de todas as etiquetas e regiões e os
  brilhos, e `_layout_balloons()` faz `get_nodes_in_group` na árvore inteira só para zerar um
  deslocamento que já é sempre zero. Somado a isso, **todo `WorldBalloon` e o `WorldPin` chamam
  `queue_redraw()` em todo quadro** (`_process`), mesmo parados, redesenhando arcos suavizados de 48
  segmentos. A legenda (`UiKit.surface`) cria um `StyleBox` novo a cada desenho. No WebAssembly, o
  GDScript é várias vezes mais lento: o custo por tique vira um quadro lento a cada 125 ms.

  Os picos de cerca de 150 ms que aparecem **também** na roleta e na folha (fora do Sítio) parecem de
  outra natureza: provavelmente a primeira rasterização de glifos da Fredoka/Nunito variáveis em
  tamanhos novos, ou a compilação de shader no renderer Compatibility.
- **O quê:**
  1. **Medir antes**: profiler do Godot no desktop, na cena do Sítio com balões, mais o
     `touch_test` com `perf_start/perf_stop` (mesmo roteiro) para ter a linha de base.
  2. `album_hint_glow`: calcular um conjunto `{objeto: brilha}` por mundo **uma vez** por
     `state_changed` ou por segundo, e consultar só o dicionário no tique.
  3. Dividir `_animate_objects`: a 8 Hz fica só o que anima (`busy_frames`, `idle_offset`, piscar);
     indicadores, canteiros, etiquetas e regiões passam a 1 Hz ou a `state_changed`.
  4. Apagar `_layout_balloons()` (é sem efeito) e as `requirement_error` das regiões no tique.
  5. `WorldBalloon`/`WorldPin`: redesenhar só quando o estado ou o progresso mudam ou durante o
     pulinho. O balanço do alfinete pode virar tween de posição num nó filho em vez de redesenho.
     Guardar em cache o `StyleBox` da legenda.
  6. Picos gerais: aquecer na carga os glifos dos quatro tamanhos do tema (um `Label` fora da tela
     com o alfabeto em cada variação, por alguns quadros) e conferir se o pico some.
- **Onde:** `scenes/levels/room/room.gd` (`_animate_objects`, `_place_labels`, `_layout_balloons`,
  `_update_plot`), `autoload/game_state.gd` (`album_hint_glow`), `scripts/ui/world_balloon.gd`,
  `scripts/ui/plot_indicator.gd`, `scripts/ui/world_pin.gd`, `scenes/main/main.gd` (aquecimento).
- **Por quê:** 04 §B pede resposta em menos de 200 ms e 60 FPS no celular. Picos periódicos são
  engasgos visíveis ao arrastar a câmera e ao plantar.
- **Como verificar:** mesmo roteiro de toque `build/touch_steps_i2_12.json`, export dev. Meta: média
  ≤ 20 ms e nenhum padrão periódico acima de 33 ms. Testes `balloon_test`, `world_view_test`,
  `world_life_test`, `album_secrets_test` (brilho), `tray_test`, `farm_dock_test`.
- **Tamanho:** M (G se o aquecimento de fontes não resolver os picos gerais). Conflita com 7 e 23
  (`room.gd`); paralelo com o resto.

**5. Dica de bloqueio com gramática errada no seletor de mundos**
- **O quê:** trocar `"Após " + nome_da_missão` por `"Depois de: " + nome`, o mesmo formato da compra
  bloqueada ("Depois de: Mãos na terra"). Melhor ainda: `map_locked_hint` escrito à mão para os mundos
  que não têm (a Natureza já tem). Uma linha só, com o rosto de quem abre.
- **Onde:** `scripts/ui/world_card.gd` (`_locked_hint`), `data/worlds.json` (`map_locked_hint` da
  Praça, da Vila e do Sítio).
- **Por quê:** a tela mostra "Após Uma encomenda da vizinhança" e "Após Ele está crescendo!"
  (`i2_06_worlds_locked`, `tour412` `a03_map`). O protótipo usa uma linha curta: "Depois do baú da Nina".
- **Como verificar:** `world_selector_test`/`worlds_test`; `texts_test`; captura `i2_06_worlds_locked`
  nas três resoluções, com a dica em no máximo duas linhas.
- **Tamanho:** P. Paralelo com tudo.

### P1 — desvio importante do protótipo ou da bíblia

**6. Restaurar a hierarquia de texto (`SectionLabel`)**
- **O quê:** revisar os 82 usos de `SectionLabel`. **Nome de coisa** (produto, receita, passeio,
  material, fase, título de cartão) vira `StrongLabel` 18. **Frase** vira `Label` 15. **Rótulo de
  seção** vira `UiKit.section` (que passa a usar `OverLabel`). Fica 12 só a legenda de verdade (tempo
  sob ícone, "1 de 3"). Depois, `SectionLabel` vira apelido de `OverLabel` ou sai do tema.
- **Onde:** `market_ui.gd`, `task_help.gd`, `progression_ui.gd` (passeios, conversa, compra),
  `nature_ui.gd`, `game_manual.gd`, `project_ui.gd`, `growth_ui.gd` (seda), `walk_result.gd`,
  `celebration.gd`, `pillar_ui.gd`, `inventory_list.gd`; `assets/theme/main_theme.tres`.
- **Por quê:** 01 §A define quatro tamanhos com um nome em 18. Hoje a Feira, as Encomendas, o Como
  fazer, o Manual, os passeios e as obras mostram nomes em 12 cinza: o principal motivo do "meio feio".
- **Como verificar:** `ui_style_test` com regra nova (nenhum `SectionLabel` como primeiro texto de
  cartão ou linha); `text_budget_test`; tour completo com comparação lado a lado de `b14_market`,
  `b14b`, `b15`, `b16_walks`, `i2_09_taskhelp`, `b24_manual` e `b16c–f`.
- **Tamanho:** G. Conflita com quase todos os painéis: rodar sozinho, depois de 1–5.

**7. A bandeja do fogão esconde o fogão (ponto conhecido 5a): reverter**
- **Decisão: reverter.** O princípio 8 da visão ("bandejas apontam para o objeto") e 02 §6 ("câmera
  sobe se o objeto ficaria atrás", "mundo visível") são o coração da etapa 07. Com o fogão escondido,
  o anel do lote e a animação do fogão não aparecem enquanto o jogador cozinha.
- **O quê:** antes de abrir uma bandeja `pick`, levar o objeto ao **terço de cima** da sala (abaixo da
  linha 2, y ≈ 140–220) com `_bring_into_view(..., bottom_extra = altura prevista da bandeja)`. Limitar a
  grade a **duas linhas** visíveis (rolagem vertical na terceira em diante, como no protótipo). Juntar
  "entra → sai" numa linha (tirar o chip `×1` da saída quando a quantidade é 1). Altura máxima da
  bandeja: até 8 px acima do rodapé, sem passar do topo do objeto.
- **Onde:** `scenes/levels/room/room.gd` (`open_station_tray`, `open_nature_tray`, `_bring_into_view`),
  `scripts/ui/action_tray.gd` (`_place`, altura da grade), `scripts/ui/station_tray.gd` (`recipe_detail`).
- **Como verificar:** `station_tray_test` com caso novo (retângulo da bandeja não cobre o retângulo do
  sprite do fogão, nem o do liquidificador e da bancada, em 360×780); `i2_07_stove`, `i2_07_coop` e
  `i2_07_trees` nas três resoluções, comparadas com `fogao.png`.
- **Tamanho:** M. Conflita com 4 (`room.gd`): fazer no mesmo lote, em sequência.

**8. "Tudo ×N" no seletor de quantidade (ponto conhecido 5c): reverter, no padrão novo**
- **Decisão: reverter.** A Feira e as obras ganharam "Tudo" ao lado do `stepper` na etapa 09; só as
  estações ficaram sem. Com filas de até 6 vagas, ir de ×1 a ×6 no "+" são cinco toques. Um atalho igual
  em todo lugar é mais coerente do que três telas diferentes.
- **O quê:** opção `max_label` em `UiKit.stepper` (pílula `soft` pequena "Tudo" que leva ao máximo e se
  apaga no limite), usada pelas estações, pela Feira e pelas obras. Os botões "Tudo" próprios de
  `market_ui.gd:331` e `project_ui.gd:185` saem.
- **Onde:** `scripts/ui/ui_kit.gd`, `station_tray.gd`, `market_ui.gd`, `project_ui.gd`.
- **Como verificar:** `queue_test` (nó `QuantityMax` de volta), `market_test`, `bench_test`, `ui2_kit_test`.
- **Tamanho:** P. Paralelo com 6 se for feito antes.

**9. Mexer na câmera não fecha a barra da horta (ponto conhecido 5b): manter**
- **Decisão: manter.** A barra fica presa ao rodapé, não ao objeto, então não desalinha quando a câmera
  anda. Plantar em canteiros fora da tela pede arrastar a câmera **sem perder a semente escolhida**.
  02 §6.1 item 7 lista como fechar a barra (✓/X, tocar fora dos canteiros e da barra, trocar de aba ou
  de mundo) e não inclui a câmera. A regra "arrastar a câmera fecha" (02 §6 item 4) é das bandejas
  presas ao objeto.
- **O quê:** só registrar a decisão em `02_JORNADA.md` §6.1 e no `FarmDock`, e conferir que a pinça
  cancela o gesto sem fechar a barra.
- **Tamanho:** P. Paralelo com tudo.

**10. Como fazer ainda com cartões antigos (ponto conhecido 4)**
- **O quê:** refazer `TaskHelp.panel` com as peças novas. Cabeçalho = ícone 64 em disco + nome
  `StrongLabel` + estoque em chip `have`/`missing`. O guia de preparo e os **passos de crescimento**
  (`care`) viram `list_card` com `list_row` (anel de progresso no disco, chips, `Ir` calmo e **um**
  verde só no primeiro passo que falta). "Onde conseguir" vira linhas com `›`. Trocar
  `UiKit.GOOD/BAD` por `Palette.GO_INK/ALERT_INK`. O caso "Você já tem" deixa de oferecer
  "Missões" em verde: vira chip `have` + `Ir` para onde se usa.
- **Onde:** `scripts/ui/task_help.gd` (linhas 513–610: `UiKit.card(..., &"ReadyCardPanel")`,
  `SectionLabel`, `UiKit.button(..., &"PrimaryButton")`).
- **Por quê:** 03 "Como fazer: cadeia em linhas com ícone, ✓ vetor no que já tem, Ir calmo em cada
  passo e um verde no primeiro que falta". Hoje: `i2_09_taskhelp`, com folha quase vazia, nome em 12
  e botão "Missões" verde.
- **Como verificar:** `recipe_help_test`, `item_sources_test`, `growth_ui_test`, `ui_style_test`; tour
  `i2_09_taskhelp` mais uma captura nova do Como fazer de um requisito de crescimento.
- **Tamanho:** M. Paralelo com 7, 11 e 12; conflita com 6 (fazer antes de 6 ou dentro do mesmo lote).

**11. Painel da seda (adulto) fora do padrão do Crescimento**
- **O quê:** os requisitos da seda (`SilkReq_*`) usam a mesma grade de tiles do `GrowthSteps`
  (ícone do pilar ou do item, anel, `n/m`, ✓). A silhueta de "?" dá lugar a uma prévia do brilho do
  pelo (`SilkSilhouette`, com o `sheen` do shader). O bloqueio usa `lock_hint` com ícone.
- **Onde:** `scripts/ui/growth_ui.gd` (ramo da seda).
- **Por quê:** `b19_skills`: cartões brancos sem ícone, alturas diferentes e um "?" que não diz nada.
  É a tela que o jogador vê por mais tempo depois de adulto.
- **Como verificar:** `silk_test`, `growth_ui_test`; captura `b19_skills` nas três resoluções.
- **Tamanho:** M. Paralelo com 7, 8 e 10.

**12. Nada de botão cinza: bloqueio vira `lock_hint`**
- **O quê:** nos cerca de 20 lugares com `button.disabled = erro != ""`, trocar o botão desabilitado por
  `UiKit.lock_hint(motivo)` tocável (Como fazer) ou esconder o botão quando o motivo já aparece.
  Prioridade: Encomendas (`Entregar`), Minha banca (`Entregar contrato`), saves (`Jogando` vira chip
  "Jogando ✓" e `É o padrão` vira chip), truques, passeios, amigos, achados (`find_ui`), Manual,
  compra (`sheet_builder` 551/700), `nature_ui` 222. Ficam de fora o `stepper`, a paginação, a
  roleta dormindo e o minijogo.
- **Onde:** os arquivos listados na saída de `grep "\.disabled = "` (registrada nesta revisão).
- **Por quê:** 02 §11 e 01 §F ("desabilitado = vira `lock_hint`"). Capturas `b14b`, `b14c`,
  `i2_11_settings`.
- **Como verificar:** `ui_style_test` com regra nova (nenhum `Button` desabilitado com texto dentro de
  `Sheet`/bandeja, salvo lista branca); `market_test`, `saves_test`, `tricks_test`, `walks_test`,
  `friends_test`.
- **Tamanho:** M. Conflita com 6 nos mesmos arquivos: fazer no mesmo lote.

**13. "O que tem aqui?" (lista de Lugares) no visual antigo**
- **O quê:** `list_card` com `list_row` (ícone em disco, nome, selo "!" ou ✓ do personagem, `›`). Sem
  verde por linha: o pronto ganha fundo `GO_SOFT`, como nas Missões. Tirar o prefixo de texto `"! "`.
- **Onde:** `scripts/ui/places.gd` (linhas 263 e 273).
- **Por quê:** `b22b_places_list`: botões grandes, um verde ("Canteiros"). 02 §8 pede "lugares como
  linhas com ícone e ›".
- **Como verificar:** `places_test`/`worlds_test`; captura `b22b_places_list`.
- **Tamanho:** P. Paralelo com tudo, menos 6.

**14. Conversa com personagem: tirar repetições e alinhar**
- **O quê:** sem o rótulo de nome sobre o balão quando o título da folha já é o nome; sem o retrato
  em cada cartão de missão quando a folha é do próprio personagem; linhas de serviço ("Canteiros",
  "Vender") centralizadas na vertical (hoje o texto fica no topo da linha).
- **Onde:** `scripts/ui/progression_ui.gd` (`npc_header`, `npc_quest_card`, `character_quest_detail`,
  `NpcServices`).
- **Por quê:** `i2_06_npc`, comparado a 02 §8.
- **Como verificar:** `npc_test`/`sheet_test`; `i2_06_npc` e `b17_npc_lais` nas três resoluções.
- **Tamanho:** P. Paralelo com tudo, menos 6 e 2 (mesma tela).

**15. Humor e "Animado" na tela do Tiro**
- **O quê:** o humor vira pílula translúcida (`CARD` a 85%, Nunito 12) presa sob o Tiro, que aparece
  ao mudar ou ao tocar nele e some depois de 3 s (03 "só quando muda ou ao tocar nele"), ancorada
  acima do tapete. "Animado" vira selo pequeno no avatar (mel com ✦), não legenda solta.
- **Onde:** `scenes/ui/pet_screen/pet_screen.gd` (`MoodLabel`), `scripts/ui/hud.gd` (`AnimatedBadge`).
- **Por quê:** `i2_04_pet`: texto sem fundo sobre o tapete vermelho, ilegível. Já está no `FUTURO`.
- **Como verificar:** `care_ui_test`, `mood_test`, `care_wheel_test`; `i2_04_pet` e `f07_pet_low_needs`.
- **Tamanho:** P. Paralelo com tudo.

**16. Cartão de capítulo com muitas novidades estoura a altura**
- **O quê:** no `ModalCard` de capítulo, as novidades viram grade de chips (ícone 40 + nome, três por
  linha), sem uma linha por Novo. Repetições do mesmo destino (lugar e mundo "Sítio") se juntam.
  Fita e herói ficam sempre visíveis (só a grade rola).
- **Onde:** `scenes/ui/celebration/celebration.gd` (`_unlock_rows`), `scripts/ui/modal_card.gd`.
- **Por quê:** `i2_05_chapter`: o cartão rolado esconde a fita "Capítulo concluído!" e mostra cinco
  linhas grandes. 02 §4: grande = fita + ícone com raios.
- **Como verificar:** `festa_test`, `quest_reward_test`; captura `i2_05_chapter` (salto DEV) e
  `h02_chapter_card` nas três resoluções.
- **Tamanho:** P/M. Paralelo com tudo, menos 23.

**17. Testes instáveis `world_pin_test` e `world_life_test` (ponto conhecido 6)**
- **`world_pin_test`, causa provável:** a auditoria `_audit` toca a zona `friends` da Praça num
  **único ponto** (o centro do polígono). Antes das zonas, `_handle_tap` testa o montinho do faro
  (posição sorteada), os balões e **os NPCs**. Nina, a Pipoca que a segue e o cachorro visitante
  (escolhido por bloco de 3 h do **relógio real** e andando a esmo perto de `friend_1`, que fica ao
  lado da zona) podem estar sobre esse ponto. Daí o `SEM CAMINHO` intermitente em `place:friends`.
  **Correção:** na auditoria, esconder ou desligar NPCs, Tiro, montinho e balões da sala auditada
  (`set_process(false)` + `visible = false`) e tentar vários pontos dentro do polígono da zona, como
  já se faz com os pixels dos sprites.
- **`world_life_test`, causa provável:** a falha registrada foi "Não reage em mapa oculto". O
  `before` é lido **antes** de `set_sleeping(false)`, que roda com a Vila ainda visível. Acordar
  dispara eventos reais (álbum por horário de sono, desejos, `world_activity`) que podem fazer o
  cachorro da Vila reagir e mudar `last_reaction` antes da troca para a tela do Tiro. Isso depende do
  relógio de parede (hora local e foto noturna), por isso é intermitente. Os `create_timer(0.3)` com
  "andou mais de 1 px" também são sensíveis à carga dos três processos do portão.
  **Correção:** ler `before` **depois** de `show_screen(&"pet")`; usar o relógio injetável
  (`tests/helpers/economy_clock.gd`) com hora fixa no teste; trocar esperas por tempo por esperas por
  condição (`while ...: await process_frame` com limite de quadros).
- **Onde:** `game/tests/world_pin_test.gd`, `game/tests/world_life_test.gd` (só testes; nenhuma
  garantia removida).
- **Como verificar:** rodar cada teste 10 vezes seguidas em paralelo com `-Jobs 3` (ou dentro do
  portão) e conseguir 10/10 PASS. Registrar no README do plano.
- **Tamanho:** P/M. Paralelo com tudo (só arquivos de teste).

**18. Mochila e Missões: título e vão inconsistentes**
- **O quê:** escolher uma regra: **sem título de tela** (02 §3: "a aba ativa do rodapé já diz") e a
  linha 2 recolhe quando a pílula não existe (história concluída), subindo o conteúdo. Tirar o
  título "Mochila".
- **Onde:** `scenes/ui/bag_screen/`, `scripts/ui/hud.gd` (`set_row2_shown`), `tasks_screen.gd`.
- **Por quê:** `b04_bag` (título solto depois de um vão) e `i2_11_tasks` (vão vazio de 50 px).
- **Como verificar:** `lists_test`, `hud_test`, `next_step_test`; capturas `b04_bag`, `b03_tasks`.
- **Tamanho:** P. Paralelo com tudo, menos 6.

**19. Cardápio de comida: "Provar" em vermelho**
- **O quê:** o chip de sabor novo vira chip mel "Nova!" com ✦ (a semântica do `NewTaste`), e a
  quantidade fica no mesmo chip `×12`. O cardápio nasce acima do focinho do Tiro (ancorado no botão
  Cuidar, como pede 02 §7) sem cobrir a cabeça, que é o alvo do arrasto da comida.
- **Onde:** `scripts/ui/pet_care_tray.gd` (`FoodMenu`).
- **Por quê:** 00 §3.4 "Vermelho = pede atenção/falta". Captura `i2_04_food_menu`.
- **Como verificar:** `brush_taste_test`, `care_wheel_test`; captura `i2_04_food_menu`.
- **Tamanho:** P. Paralelo com 15 (mesma tela: fazer juntos).

**20. Obras e encomendas: vermelho demais e progresso repetido**
- **O quê:** "faltam 4" + "tem 0" vira **um** chip (`have`/`missing` com `0/4`). A linha "onde achar?"
  passa a ser `list_row` calma com `›`, não faixa vermelha. Barra azul **ou** tracinhos de fase, não
  os dois.
- **Onde:** `scripts/ui/project_ui.gd`, `scripts/ui/market_ui.gd`.
- **Por quê:** `b16c–f`, `b16h`, `b14b`: três sinais vermelhos por cartão e duas barras para a mesma
  coisa.
- **Como verificar:** `bench_test`, `garden_picnic_test`, `festival_test`, `market_test`, `customers_test`.
- **Tamanho:** M. Conflita com 6, 8 e 12 (mesmos arquivos): mesmo lote.

**35. Tela de Crescimento (`GrowthUi.panel`) sem hierarquia (sugestão do revisor)**
- **O quê:**
  - **Cabeçalho herói:** Tiro atual em 96 num disco `SUNKEN`, seta vetorial e próxima fase no mesmo
    tamanho, com silhueta preenchida (sem o "?" em traço). Nome da fase atual e da próxima embaixo de
    cada figura (`StrongLabel`), com a próxima em `INK_SOFT`. Os botões ⓘ e ≡ saem da lateral e vão
    para a linha do título da folha (discos 32 `SUNKEN`, sem sombra).
  - **Um só indicador de progresso:** fica `UiKit.steps` (ou o anel mel) com "1/3"; saem a frase
    "0 de 3 passos · falta 3" e as barrinhas separadas.
  - **Passos:** tiles com ícone 40, anel de 4 px em volta e `n/m` em `NumberLabel`. As bolinhas dos
    momentos ficam com 10 px.
  - **Detalhe:** nome em 18, caminho como linha "Casa › Liquidificador" com ícones, `?` como
    `ctl_button` 32 sem sombra e o verde ocupando a largura do cartão.
  - **Altura:** a folha usa a altura do conteúdo (`sheet_size` automático), sem a metade vazia
    embaixo. O rodapé "Ao crescer: …" vira chips de prêmio (ícone + nome).
- **Onde:** `scripts/ui/growth_ui.gd` (`panel`, `step_view`, `progress_strip`, `GrowthHero`),
  `scripts/ui/pillar_ui.gd` (`dots`).
- **Por quê:** 01 §A/§F (valor maior que o rótulo, um título por tela) e 03 "grade de passos vira
  tiles afundados com anel; detalhe em faixa branca". É a tela que resume o objetivo do jogo e hoje
  tem a menor hierarquia de todas (`i2_09_growth`, `t_phase_*`, `t02_growth_almost`).
- **Como verificar:** `growth_ui_test`, `growth_story_test`, `ceremony_test`, `care_ui_test`
  (`GrowthQuick_*`); capturas `t_phase_*` (cinco fases), `t01`, `t02`, `t03` e `i2_09_growth` nas três
  resoluções; antes de codar, prancha HTML rápida em `prototipo/` para o Vitor aprovar.
- **Tamanho:** M (mais a prancha). Junto com o item 11 (seda), no lote E.

### P2 — polimento

**21.** Seletor de mundos aberto: esconder `WorldBar` (pílula e rostos) por trás da folha, para não
aparecer um pedaço de "Sítio" no topo (`i2_06_worlds`). `worlds_screen.gd`. P. Paralelo.

**22.** "Neste capítulo": ✓ e cadeado como ícones vetoriais de 20 sem disco, linha de 56 e atual em
`HONEY_SOFT` sem o › gigante. Linhas de Pessoas/Diárias com `›` sem disco, para os nomes caberem numa
linha em 360. `tasks_screen.gd`, `progression_ui.gd`. Verificar `i2_05_story`, `i2_05_people`,
`i2_05_daily`. P. Paralelo com tudo, menos 6.

**23.** Orçamento de atenção: só **um** balão pulando por tela (o mais importante, ou um por vez em
rodízio de 4 s); os outros prontos ficam verdes e parados. `room.gd` + `world_balloon.gd`. Fazer junto
com 4. P.

**24.** Segmentado de uma opção só some (Missões no início, seção única do Álbum). No caderninho, os
rótulos ficam sempre visíveis (sem o "·· Álbum" cortado) ou só ícones com o rótulo da aba ativa
*fora* da pílula. Tirar o selo vermelho com "∞" da seção do Álbum. `ui_kit.gd` (`segmented`),
`pet_notebook.gd`, `album_view.gd`. P.

**25.** Fontes menores que 12: `album_view.gd:89` (6 px), `photo_card.gd` (9–13 com escala),
`npc_world.gd:42` (28), `motion.gd:224` (22). Viram variações do tema ou ficam documentadas como
"texto do mundo" (polaroide) e passam a acompanhar o "Texto maior". P.

**26.** Barra da horta: tile Regar com "Regar" + `×3` no selo, separador de 1 px antes dele
(`horta_plantar.png`); conferir que o botão Lugares (≡) não fica meio escondido atrás do rosto da
Bloblo com a barra aberta (`i2_07_dock_plant`). `farm_dock.gd`, `plot_tray.gd`. P.

**27.** Passeios: o `?` solto no canto da lista entra no cabeçalho; o espaço vazio dos cartões diminui
(achados e botão na mesma linha). `progression_ui.gd` (`walks_panel`). P.

**28.** Feira: cartão de venda com ícone 40 em disco, nome `StrongLabel` (item 6), contorno de tinta
no selecionado (hoje o primeiro selecionado não mostra contorno em `i2_09_market`). `market_ui.gd`. P.

**29.** História concluída: em vez do cartão vazio, "Nosso lugar no mundo ✓" com "História completa ›"
e um atalho para o Álbum. `tasks_screen.gd`. P.

**30.** Cerimônia: tirar o mini-Tiro dos raios (o antes/depois já é o herói, e os raios ficam atrás dos
dois); a régua (`HeightMark`) com marcas e rótulo da altura. `growth_ceremony`. P.

**31.** Textos da etapa 10 (ponto conhecido 7):
- **"Um mundo novo para explorar" → trocar.** A fita já diz "Novo!" e o título diz o nome. A linha
  deve dizer **onde** a coisa está: mundo = "Já está no Mapa"; lugar = "No Sítio" (`in_name` do
  mundo); amizade = "Na Praça". O botão vira "Ir para a Vila" em vez de só "Ir".
  `celebration.gd` (`_unlock_line`).
- **"De volta!" → trocar por "Voltou do passeio!".** Hoje a fita "De volta!" fica logo acima de
  "Volta na praça" ("volta" duas vezes, e a fita não diz quem voltou). O nome do caminho continua
  embaixo. A versão de roupa ("Roupa pronta!") fica igual. `walk_result.gd:22`, `texts_test`.
P. Paralelo.

**32.** Limpeza de código: apagar os apelidos `UiKit.GOOD/BAD` (35 usos) e `UiKit.secondary`; apagar
variações mortas do tema (`TopBarPanel`, `BarLabel`, `ToastLabel`, `SoftButton`) ou usar `OverLabel`
em `UiKit.section`; juntar `ModalCard.reveal` e `RewardSheet.reveal_in` (já no `FUTURO`); conferir o
`world_selector.gd` (só a `.tscn` o referencia: ok, não é órfão). M. Rodar por último.

**33.** Fixtures históricas do tour: `g01_tasks_ready_many` e `t03_growth_ready` passam a montar o
estado que o nome promete (missões prontas; todos os requisitos feitos). `tests/ui_tour.gd`. P.
Paralelo.

**34.** Compra bloqueada (`a05_fridge_sheet`): o cartão inteiro esmaecido (opacidade 0,55) fica sem
contraste; deixar a figura e o ganho nítidos e só o rodapé com `lock_hint`. `progression_ui.gd`
(`upgrade_card`). P.

---

## 4. Plano de execução proposto

Cada lote é um subagente **Sonnet 5.5** (`claude-sonnet-5-5`) com uma lista fechada de itens,
arquivos e testes. Eu (Opus) reviso o diff, comparo capturas antes e depois com o protótipo e as três
resoluções, rodo `tools\test.ps1 -Level portao` no fim de cada lote (a "suíte completa" sem campanha;
cerca de 11 min) e faço **um commit local por lote**. Sem push e sem publicação. Sem mudança de regra,
save, falas ou dados de balanceamento.

| Ordem | Lote | Itens | Arquivos principais | Pode rodar junto com | Verificação do lote |
|---|---|---|---|---|---|
| 1 | **A — Casca e folhas (P0)** | 1, 2, 3, 5, 21 | `main.gd`, `sheet.gd`, `hud.gd`, `settings_panel.gd`, `world_card.gd`, `worlds_screen.gd`, `worlds.json` | F | `notice_test`, `sheet_test`, `hud_test`, `text_budget_test`, `worlds_test`; tour `--i2-03-only`, `--i2-06-only`, `--i2-11-only` e `b05`/`b17` em 360/390/412 |
| 1 | **F — Testes estáveis** | 17, 33 | só `game/tests/` | A, B | 10× seguidas de `world_pin_test` e `world_life_test` com `-Jobs 3`; tour completo com `g01`/`t03` corretos |
| 2 | **B — Mundo: desempenho e bandejas** | 4, 7, 8, 9, 23, 26 | `room.gd`, `world_balloon.gd`, `world_pin.gd`, `plot_indicator.gd`, `game_state.gd` (`album_hint_glow`), `action_tray.gd`, `station_tray.gd`, `ui_kit.gd` (`stepper`), `farm_dock.gd`, `market_ui.gd`/`project_ui.gd` (só o "Tudo") | — (mexe em `room.gd` e `ui_kit.gd`) | medição antes/depois com o mesmo roteiro de toque (meta ≤ 20 ms, sem padrão de 8 Hz); `balloon_test`, `world_view_test`, `tray_test`, `farm_dock_test`, `station_tray_test`, `queue_test`, `market_test`, `bench_test`, `album_secrets_test`; tour `--i2-07-only` nas três resoluções contra `fogao.png`/`horta_*.png` |
| 3 | **C — Telas do Tiro e Missões** | 15, 19, 16, 18, 22, 24, 29, 30 | `pet_screen.gd`, `pet_care_tray.gd`, `hud.gd`, `celebration.gd`, `modal_card.gd`, `tasks_screen.gd`, `bag_screen`, `pet_notebook.gd`, `album_view.gd`, `growth_ceremony` | E (arquivos distintos) | `care_ui_test`, `care_wheel_test`, `mood_test`, `brush_taste_test`, `festa_test`, `quest_reward_test`, `lists_test`, `album_test`, `ceremony_test`; tour `--i2-04/05/08/10-only` |
| 3 | **E — Painéis antigos e Crescimento** | 35 (prancha aprovada antes), 10, 11, 13, 14, 34 | `growth_ui.gd`, `pillar_ui.gd`, `task_help.gd`, `places.gd`, `progression_ui.gd` (conversa/compra) | C | `growth_ui_test`, `growth_story_test`, `ceremony_test`, `recipe_help_test`, `item_sources_test`, `silk_test`, `sheet_test`; capturas `t_phase_*`, `i2_09_growth`, `i2_09_taskhelp`, `b19_skills`, `b22b`, `i2_06_npc`, `i2_06_buy` |
| 4 | **D — Hierarquia e bloqueios (sistêmico)** | 6, 12, 20, 25, 27, 28 | ~15 arquivos de painel + tema | sozinho | `ui_style_test` com as duas regras novas (sem `SectionLabel` como nome; sem botão cinza), `text_budget_test`, `market_test`, `customers_test`, `bench_test`, `walks_test`, `tricks_test`, `saves_test`, `friends_test`; **tour completo** nas três resoluções e prancha nova `#revisao_antes_depois` |
| 5 | **G — Textos e limpeza** | 31, 32 | `celebration.gd`, `walk_result.gd`, `ui_kit.gd`, tema, `modal_card.gd`, `reward_sheet.gd` | sozinho (último) | `texts_test`, `ui2_kit_test`, `festa_test`, `walk_return_ui_test`; `tools\list_texts.ps1 -ByScreen` |

Notas de execução:
- A e F começam juntos (arquivos distintos). B depois de A, porque A mexe no `Notice`/`Sheet` que as
  bandejas consultam. C e E em paralelo, em worktrees separadas. D vai sozinho depois, por tocar quase
  todos os painéis. G fecha.
- Em cada lote, o subagente entrega: diff, lista de testes com resultado, capturas antes e depois em
  `build/revisao_opus/<lote>/` (360/390/412) e as diferenças que sobraram em relação ao protótipo. Eu só
  faço o commit depois de abrir as capturas.
- Os itens 7/8/9 (decisões sobre os desvios da 07) e 31 (textos) dependem da aprovação do Vitor. Se ele
  preferir manter o fogão como está ou não restaurar o "Tudo", os itens saem do lote B sem afetar o resto.
- Ao fim de tudo: atualizar `RESULTADOS.md`/`FUTURO.md` do plano, o "Estado atual" do `ROADMAP.md` e,
  se a estrutura mudar, `CLAUDE.md` = `AGENTS.md`.
