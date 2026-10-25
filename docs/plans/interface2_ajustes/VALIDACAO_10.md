# Validação — Interface 2 ajustes, etapa 10

Pré-checagem: etapa 09 [x], HEAD `2dd58a4`. Exclusões preexistentes em `assets/.../python_libs` fora do escopo.

Inventário original por `rg -n SectionLabel game/scripts game/scenes`: **75 usos**, classificados antes da implementação. Linhas abaixo referem-se ao antes.

| Arquivo:linha (antes) | Expressão original | Papel | Destino | Feito |
|---|---|---|---|---|
| `game/scripts/ui/game_manual.gd:51` | `box.add_child(UiKit.label(SheetBuilder.CATEGORIES[category], &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/game_manual.gd:130` | `box.add_child(UiKit.label("Como conseguir", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/game_manual.gd:148` | `box.add_child(UiKit.label("Serve para", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/game_manual.gd:172` | `card.add_child(UiKit.label(str(walk.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:181` | `card.add_child(UiKit.label("Plantar → esperar → colher", &"SectionLabel"))` | frase | Label | [x] |
| `game/scripts/ui/game_manual.gd:188` | `card.add_child(UiKit.label(route.name, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:195` | `card.add_child(UiKit.label("Recompensa de missão", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:199` | `card.add_child(UiKit.label("Faro do Tiro", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:212` | `card.add_child(UiKit.label("Presente do Tiro", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:215` | `card.add_child(UiKit.label("Ajuda da Bloblo", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:223` | `box.add_child(UiKit.label(Database.stations[station_id].name, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:278` | `box.add_child(UiKit.label("Onde fazer", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/game_manual.gd:281` | `card.add_child(UiKit.label(Database.stations[id].name, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/game_manual.gd:287` | `box.add_child(UiKit.label("Onde buscar", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/game_manual.gd:289` | `crops.add_child(UiKit.label("Canteiros", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:143` | `card.add_child(UiKit.label(quest.name, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:249` | `box.add_child(UiKit.label("Rotas", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/progression_ui.gd:292` | `heading.add_child(UiKit.fill_label("Passeios", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/progression_ui.gd:339` | `heading.add_child(UiKit.fill_label(str(GameState.walk_def(str(entry.id)).get("name", "")), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:367` | `heading.add_child(UiKit.fill_label(str(view.get("name", "")), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:485` | `cell.add_child(UiKit.label("✓", &"SectionLabel", UiKit.GOOD))` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/progression_ui.gd:500` | `card.add_child(UiKit.label("Conjunto de esponjinha · LENDÁRIO", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:523` | `info.add_child(UiKit.label("???" if locked else str(data.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/progression_ui.gd:791` | `var title := UiKit.label(text, &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:16` | `card.add_text(str(chapter.name), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:37` | `card.add_text(str(def.get("name", "")), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:53` | `card.add_text(str(def.name), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:66` | `card.add_text(Database.item_name(item) if item != "" else str(result.get("announcement", result.label)), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:86` | `card.add_text(str(def.get("name", "")), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/celebration/celebration.gd:107` | `card.add_text(str(def.name), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/pillar_ui.gd:97` | `box.add_child(UiKit.label("De onde vêm os momentos", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/pillar_ui.gd:103` | `head.add_child(UiKit.fill_label(str(Database.growth.pillars[pillar].name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/pillar_ui.gd:133` | `box.add_child(UiKit.label("Guia de sabores %d/%d" % [found, foods.size()], &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/pillar_ui.gd:166` | `var title := UiKit.fill_label(PersonalityRules.title(GameState.growth), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/pillar_ui.gd:175` | `box.add_child(UiKit.label("Hoje o Tiro...", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/market_ui.gd:63` | `box.add_child(UiKit.label(str(data.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/market_ui.gd:234` | `heading.add_child(UiKit.fill_label(str(data.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/market_ui.gd:281` | `box.add_child(UiKit.label("Minha banca · nível %d/3" % level, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/market_ui.gd:326` | `box.add_child(UiKit.label(Database.item_name(id), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/sheet_builder.gd:283` | `box.add_child(UiKit.label("%d de %d animais" % [GameState.animal_count(station_id), int(data.animal_capacity)], &"SectionLabel"))` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/sheet_builder.gd:297` | `box.add_child(UiKit.label(data.get("recipe_label", "Receitas"), &"SectionLabel"))  # estações comuns: a lista fala por si` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/sheet_builder.gd:515` | `box.add_child(UiKit.label("%s · %d/%d animais" % [data.name, GameState.animal_count(station_id), int(data.animal_capacity)], &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/sheet_builder.gd:689` | `row.add_child(UiKit.fill_label("Terreno %d" % (index + 1), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/growth_ui.gd:545` | `box.add_child(UiKit.label("Caderneta", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/growth_ui.gd:563` | `row.add_child(UiKit.fill_label(str(phase.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/growth_ui.gd:580` | `card.add_child(UiKit.label(str(def.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/project_ui.gd:134` | `card.add_child(UiKit.label("Fase %d de %d" % [int(stage.index) + 1, int(stage.count)], &"SectionLabel"))` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/project_ui.gd:198` | `card.add_child(UiKit.label("Obra pronta!", &"SectionLabel"))` | frase | Label | [x] |
| `game/scripts/ui/project_ui.gd:215` | `card.add_child(UiKit.label(str(def.get("name", "Encontro")), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/station_tray.gd:257` | `var note := UiKit.label("Abrigo vazio", &"SectionLabel")` | frase | Label | [x] |
| `game/scripts/ui/station_tray.gd:351` | `var level_label := UiKit.short_label("Nível %d" % info.level, &"SectionLabel")` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/station_tray.gd:384` | `var title := UiKit.fill_label("%s ×%d" % [Database.item_name(primary), int(route.rewards.items[primary])], &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/walk_result/walk_result.gd:37` | `_text(str(result.name), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/walk_result/walk_result.gd:47` | `var first_label := UiKit.label("Primeira vez!", &"SectionLabel", UiKit.GOOD)` | frase | Label | [x] |
| `game/scenes/ui/walk_result/walk_result.gd:206` | `card.add_text(str(data.get("name", rare)), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/album_view.gd:28` | `var title := UiKit.label(str(current.name), &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/album_view.gd:33` | `var section_count := UiKit.short_label("%d/%d" % [counts.x, counts.y], &"SectionLabel", Palette.INK_SOFT)` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/find_ui.gd:23` | `map_card.add_child(UiKit.label("Mapa rasgado · %d/4" % found, &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/find_ui.gd:28` | `card.add_child(UiKit.label(str(Database.finds.album_names[world]), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/friend_ui.gd:46` | `box.add_child(UiKit.label(Database.item_name(item), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/friend_ui.gd:87` | `text.add_child(UiKit.label(str(def.name) if known or not album else "?", &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/nature_ui.gd:127` | `box.add_child(UiKit.label("Materiais", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/nature_ui.gd:144` | `var title := UiKit.fill_label(("Nível %d ★" % info.level) if info.max else "Nível %d · %d/%d XP" % [info.level, info.xp, info.needed], &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/intro/intro.gd:74` | `var chapter := UiKit.label(str(Database.progression.chapters[0].name), &"SectionLabel", Palette.INK)` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/intro/intro.gd:97` | `speech.add_child(UiKit.label(str(Database.npcs.get(NPC, {}).get("name", "")), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/dev_panel.gd:66` | `box.add_child(UiKit.label(title, &"SectionLabel"))` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scripts/ui/hide_seek_ui.gd:89` | `_status = UiKit.label("", &"SectionLabel")` | frase | Label | [x] |
| `game/scripts/ui/house_ui.gd:112` | `box.add_child(UiKit.label("Suas fotos", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/hud.gd:460` | `titles.add_child(UiKit.label("Guardião do Vale" if info.next.is_empty() else "Rumo a " + str(info.next.name), &"SectionLabel"))` | nome de coisa | StrongLabel | [x] |
| `game/scripts/ui/pet_care_tray.gd:96` | `header.add_child(UiKit.fill_label("Comidinhas", &"SectionLabel"))` | rótulo de seção | UiKit.section / OverLabel | [x] |
| `game/scripts/ui/wish_ui.gd:37` | `var title := UiKit.fill_label(str(def.name) + "!", &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/growth_ceremony/growth_ceremony.gd:147` | `card.add_text(str(_after.age) + " · " + str(_after.weight), &"SectionLabel")` | legenda (DEV quando indicado) | SmallLabel | [x] |
| `game/scenes/ui/pet_screen/pet_screen.gd:512` | `_away_name = UiKit.short_label("", &"SectionLabel")` | nome de coisa | StrongLabel | [x] |
| `game/scenes/ui/trick_training/trick_training.gd:36` | `_feedback = UiKit.label("Sem pressa!", &"SectionLabel")` | frase | Label | [x] |
| `game/scenes/ui/welcome_back/welcome_back.gd:45` | `var title := UiKit.label("Presente do dia", &"SectionLabel")` | nome de coisa | StrongLabel | [x] |

Contagem por papel: rótulo de seção: 15, nome de coisa: 47, frase: 6, legenda (DEV quando indicado): 7.

As legendas de idade/peso, fração, fase e nível mantêm 12; nomes de fase/material/passeio e títulos de cartão passam a 18. DEV fica em SmallLabel. TaskHelp já não tem SectionLabel após a 09.

## Implementação e provas

- **6:** 75 ocorrências classificadas e convertidas: 47 nomes em StrongLabel, seis frases em Label,
  15 seções em UiKit.section e sete legendas em SmallLabel. Não resta SectionLabel em scripts/cenas;
  a variação saiu do tema. OverLabel usa font_caption_spaced no próprio tema; section não sobrescreve
  a fonte e expande horizontalmente, inclusive dentro de outro HBoxContainer.
- A revisão dos vizinhos no Manual também corrigiu frases que já estavam em SmallLabel (corpo 15),
  nomes de missão/mundo (18), títulos de materiais/patamares da Natureza (18) e nomes dos tiles de
  encomenda (18). Na grade de encomendas o nome ocupa uma linha com reticências; no detalhe está
  completo, sem reduzir a fonte. Na venda, o nome tem até duas linhas. Nenhum texto foi acrescentado.
- **27:** WalksPanel fornece sheet_actions por _walk_header_actions, com WalksInfo (ctl info 32,
  alvo 44) no Header. Abre a ajuda já existente de stat:walk, sem texto novo. A ajuda específica dos
  bloqueios continua em cada cartão. WalkExclusives e StartWalk_<id> compartilham a linha inferior;
  os cartões liberados ficaram menores sem mudar prêmios, requisitos, tempo ou início do passeio.
- **28:** _sell_tile reutiliza UiKit.tile e disc: ícone 40 em disco 48 centralizado, nomes 18,
  superfícies CARD, selected derivado de model.selected. O primeiro produto tem o mesmo contorno
  de tinta que uma seleção por toque. Sell_<id>/SellGrid/SellSelected continuam com seus nomes.
- **Regra de estilo:** _first_text/_flat_card_texts percorrem CardPanel/ReadyCardPanel/RowPanel e
  tiles; _text_hierarchy monta Feira, Manual, Passeios e Como fazer na Sheet real em 360×780.
  Há controle negativo com SectionLabel, verificação da seleção inicial/troca, ícone 40 no disco,
  info no Header, seção em uma linha e achados na mesma linha da ação. Garantias anteriores intactas.

## Falhas encontradas e correções

1. Aumentar os tiles de encomendas para 152 cortou Entregar no teste de 360×640. Mantida a garantia:
   tiles voltaram a 112, nome 18 em uma linha com reticências e nome completo no detalhe. market_test
   passou nas quatro larguras/alturas que já cobria.
2. UiKit.section dentro de HBox tinha largura mínima zero: Passeios quebrou letra por letra e o
   cabeçalho Comidinhas fez o cardápio cobrir a cabeça. SIZE_EXPAND_FILL na seção resolveu ambos;
   pet_care_test reexecutado passou, sem mudar o código do gesto/cardápio além da variação prevista.
3. O portão expôs tasks_test anterior à etapa 07: esperava VBox e Continuar dentro da rolagem,
   mas agora só ChapterUnlocks rola. A fixture usa destinos reais suficientes para exceder a grade,
   verifica o último tile inteiro após rolar e Continuar inteiro/fixo/acionável fora do scroll.
   Nenhuma garantia foi removida: fim da lista e fechamento continuam cobertos separadamente.
4. walks_test fazia a medida do botão após só dois frames, durante o pop e antes do ajuste do texto
   maior. Fixture explícita 360×780, Menos animação só nesta verificação geométrica, dez frames para
   o layout e quatro após rolar; mesmas garantias de botão inteiro e fechamento. Animações continuam
   cobertas pelos testes de festa/retorno. Reexecução focada passou.
5. A segunda passada do portão expôs park_test: o caso de terminar pelo DEV usava sorteio real e
   exigia walk_ready, embora só moedas seja um resultado possível. A fixture desse caso recebeu
   um graveto garantido em tabela temporária, restaurada após guardar; a partida também passou
   a ser conferida. O temporizador, retorno e bagagem continuam reais; sorteios já têm casos
   próprios no mesmo teste. Foco scripts_check/content/texts/park: 4/4 PASS em 35,5 s.

## Capturas e checklist

Bloco --aj-10-only: 16 PNGs por pasta antes/depois em 360×780, 390×844 e 412×915. O Banco segue a
mesma sequência do tour: painel inicial, base/conforto no mundo, painel da última fase. A primeira
fixture adiantava uma contribuição e foi corrigida antes de mexer no jogo; as três pastas antes
foram regeneradas. A tentativa inicial restrita falhou em user://; capturas válidas usam acesso normal.
Tour completo antes/depois em 360×780. Pranchas são apenas evidência em build/, fora do commit.

| Telas tocadas | Visual | Jogo | Celular |
|---|---|---|---|
| Feira / encomendas / banca | ✓ nomes 18, discos, contorno tinta, Palette | ✓ mesmas ações/quantidades/textos, um primário | ✓ 44, reticências na grade e nome completo no detalhe |
| Passeios / Natureza | ✓ nomes fortes, seção pequena, info vetor | ✓ achados + ação juntos, bloqueios preservados | ✓ largura reservada, cartões menores, rolável |
| Manual / ajudas / caderneta / demais painéis | ✓ nomes 18, frases 15, seção OverLabel | ✓ conteúdo e destinos preservados | ✓ quebra de nomes sem baixar fonte |
| Comemorações / resultado / introdução | ✓ só variação trocada onde pedido | ✓ fluxo/fila/prêmios/falas preservados | ✓ cartões mantêm rolagem e fechamento |

Fontes Fredoka/Nunito do tema; cores Palette; alvos e controles existentes preservados. Nenhuma nova
animação, mudança de regra/save/fala, dados JSON ou arte. As exceções visuais das etapas futuras
(bloqueios cinza/vermelho e limpeza) continuam fora desta etapa. Pendências herdadas: corpo da bandeja
do Galinheiro rolável, custo de update_finds/update_wishes no tique e Tudo junto da borda direita.

## Resultados finais

Lista fechada confirmada por DryRun: **15/15 PASS em 343.7 s**, `build/test_logs/r20261025_161350_fcc901b8/results.csv`.

| Teste da lista | Resultado | Segundos |
|---|---|---|
| scripts_check | PASS | 13.3 |
| content_test | PASS | 9.9 |
| texts_test | PASS | 4.1 |
| ui_style_test | PASS | 11.6 |
| text_budget_test | PASS | 33.9 |
| market_test | PASS | 48.8 |
| customers_test | PASS | 12.7 |
| walks_test | PASS | 23.6 |
| manual_test | PASS | 41.1 |
| lists_test | PASS | 34.4 |
| item_sources_test | PASS | 15.8 |
| growth_ui_test | PASS | 34.7 |
| festa_test | PASS | 21 |
| friends_test | PASS | 14.3 |
| tricks_test | PASS | 18.7 |

Portão: **102/102 PASS após reexecução focada de park_test**. Passada completa: 101/102 em 657.3 s (11.0 min), `build/test_logs/r20261025_162708_55e3d716/results.csv`; foco final 4/4 (incluindo park_test) em 35,5 s, `build/test_logs/r20261025_163151_0c95ef13/results.csv`. A tabela reúne o último resultado de cada teste; park_test vem do foco, os demais da passada completa. Logs originais preservados.

| Teste do portão | Resultado | Segundos |
|---|---|---|
| growth_test | PASS | 4.3 |
| moments_test | PASS | 5 |
| growth_meals_test | PASS | 4 |
| courage_start_test | PASS | 17.3 |
| growth_ui_test | PASS | 22.5 |
| hud_growth_test | PASS | 21 |
| personality_test | PASS | 8.8 |
| silk_test | PASS | 8.7 |
| ceremony_test | PASS | 26.5 |
| growth_foods_test | PASS | 13.3 |
| growth_visual_test | PASS | 16 |
| keys_test | PASS | 13.7 |
| wish_moments_test | PASS | 3.3 |
| wish_guide_test | PASS | 15.3 |
| care_ui_test | PASS | 16.7 |
| care_wheel_test | PASS | 16.3 |
| brush_taste_test | PASS | 13 |
| pet_anchor_test | PASS | 25.4 |
| pet_care_test | PASS | 35 |
| absence_test | PASS | 3.2 |
| gestures_test | PASS | 14.1 |
| manual_test | PASS | 23.9 |
| mood_test | PASS | 11.7 |
| growth_story_test | PASS | 12.3 |
| journey_test | PASS | 9.8 |
| tasks_groups_test | PASS | 18.6 |
| tasks_test | PASS | 26.4 |
| npc_lines_test | PASS | 20.7 |
| onboarding_test | PASS | 6.9 |
| care_story_test | PASS | 8.2 |
| walks_test | PASS | 13.1 |
| park_test | PASS | 9.3 |
| walk_return_test | PASS | 3.5 |
| friends_test | PASS | 10.4 |
| quest_reward_test | PASS | 30.6 |
| petshop_test | PASS | 7.4 |
| walk_return_ui_test | PASS | 25.5 |
| tricks_test | PASS | 13.5 |
| lists_test | PASS | 20.9 |
| finds_test | PASS | 9 |
| farm_test | PASS | 2.5 |
| treasure_test | PASS | 10.7 |
| garden_test | PASS | 9.2 |
| flavors_test | PASS | 7.9 |
| farm_market_label_test | PASS | 20.4 |
| farm_dock_test | PASS | 36.5 |
| album_secrets_test | PASS | 12 |
| album_test | PASS | 15.3 |
| hud_test | PASS | 13 |
| notice_test | PASS | 11.4 |
| next_step_test | PASS | 31.4 |
| festa_test | PASS | 12.6 |
| tray_test | PASS | 81.8 |
| welcome_test | PASS | 14.2 |
| ui_style_test | PASS | 10.4 |
| effects_layer_test | PASS | 22.7 |
| ui_base_test | PASS | 2.8 |
| ready_badges_test | PASS | 25.9 |
| ui2_tokens_test | PASS | 2.6 |
| ui2_kit_test | PASS | 2.6 |
| sheet_test | PASS | 21.8 |
| navigation_test | PASS | 15.2 |
| recipe_help_test | PASS | 12.7 |
| item_sources_test | PASS | 9.6 |
| dev_tools_test | PASS | 3.7 |
| dev_tools_test_prod | PASS | 10.2 |
| economy_transactions_test | PASS | 4.1 |
| saves_test | PASS | 15.8 |
| storage_test | PASS | 3.3 |
| fridge_test | PASS | 3.8 |
| warehouse_test | PASS | 14.4 |
| silo_test | PASS | 29.8 |
| chest_test | PASS | 11.5 |
| queue_test | PASS | 11.9 |
| products_test | PASS | 6.7 |
| pending_gifts_test | PASS | 35.6 |
| animals_chain_test | PASS | 9.2 |
| expansion_test | PASS | 9.9 |
| animals_test | PASS | 53.7 |
| nature_routes_test | PASS | 17.9 |
| loot_test | PASS | 2.3 |
| nature_test | PASS | 53.7 |
| worlds_test | PASS | 20.3 |
| station_tray_test | PASS | 202.9 |
| world_life_test | PASS | 21.3 |
| world_selector_test | PASS | 29.1 |
| world_view_test | PASS | 39.4 |
| balloon_test | PASS | 32.7 |
| intro_test | PASS | 17.7 |
| customers_test | PASS | 8.1 |
| world_pin_test | PASS | 25.8 |
| coins_test | PASS | 2.6 |
| projects_test | PASS | 8.3 |
| market_test | PASS | 29.9 |
| festival_test | PASS | 31.2 |
| bench_test | PASS | 44.5 |
| care_bot_test | PASS | 3.6 |
| garden_picnic_test | PASS | 43.5 |
| texts_test | PASS | 3.3 |
| content_test | PASS | 8.5 |
| house_test | PASS | 14.4 |
| text_budget_test | PASS | 28 |

DryRun, lista e portão incluem somente o circuito autorizado; nenhuma campanha/simulador.
A primeira lista (`r20261025_161125_fa4c983b`) parou em market_test (88,7 s), antes da correção compacta.
A primeira passada do portão (`r20261025_161259_aabe33d6`) encontrou pet_care/tasks/walks descritos acima.
Reexecuções justificadas por essas falhas: `r20261025_161613_ce0e1f34` (6/6, 179,7 s:
scripts_check/content/texts/ui_style/pet_care/market), `r20261025_161931_6b057ae2` (5/5, 98,7 s:
scripts_check/content/texts/tasks/walks). O portão final cobre todas as alterações, inclusive a fixture
360×780 de tasks_test. A segunda passada expôs park_test: o caso do temporizador DEV dependia do
sorteio e exigia bagagem, mas a rota pode sortear só moedas. Só essa fixture recebeu uma tabela
temporária determinística com um graveto (restaurada depois); a verificação de partida foi acrescentada,
temporizador/retorno/bagagem/guardar continuam reais. O sorteio segue coberto nos casos anteriores.
O foco final `r20261025_163151_0c95ef13` passou 4/4 em 35,5 s. Como só a fixture desse teste mudou,
a reexecução focada fecha os 102 resultados sem repetir os outros 101 já verdes. Nenhum teste apagado
ou garantia enfraquecida.

**Capturas finais abertas:** `build/screenshots/aj_10_antes`, `_antes_390`, `_antes_412`,
`aj_10_depois`, `_depois_390`, `_depois_412` (16 cada); `aj_10_tour_antes` e `aj_10_tour`
(114 cada). Todos os PNGs examinados nas pranchas `*_prancha_*.png`, mais detalhes de Feira,
Passeios, Manual e Banco abertos individualmente. As capturas 360 e 390 depois foram refeitas
após a correção de largura das seções; 412 e o tour completo já usam a correção.
Evidência original `i2_09_depois/i2_09_market` e `i2_09_walks` também aberta.
Não há protótipo novo previsto: seguimos a bíblia e as evidências dos itens 6/27/28.

**Diferenças:** os nomes escuros agora dominam os cartões; seções ficaram pequenas/maiúsculas,
Manual tem frases legíveis e mais quebra de linha; os passeios liberados têm achados e ação juntos.
Feira tem discos e selecionado inicial visível. Nomes longos de encomenda usam reticências na grade
e permanecem completos no detalhe, para preservar Entregar visível até em 360×640.
Mundos/Banco/Como fazer mantêm composição; nomes nas festas ficaram maiores. Poses, confete,
necessidades, moedas de fixtures e avisos temporais variam com tempo/sorteio do tour (não houve
alteração de regra). O tour contém os avisos de RIDs/ObjectDB no encerramento que também aparecem
no antes; as capturas finais não contêm SCRIPT ERROR. Sem export, push ou publicação.

**Pronto quando:** ✓ tabela completa e nenhum nome classificado em 12; ✓ UiKit.section em OverLabel,
SectionLabel removida sem alias órfão; ✓ passeios compactos/info no Header e seleção inicial da Feira;
✓ regra nova verde; ✓ lista e portão completos verdes. Pendências desta etapa: nenhuma.
Próxima: 11, não iniciada. Exclusões preexistentes das bibliotecas python_libs fora do commit.
