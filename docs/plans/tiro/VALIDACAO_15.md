# Etapa 15 — Validação (19/10/2026, Codex)

**Concluída.** Alterações locais anteriores preservadas; sem reset, commit, push ou publicação.

## Cobertura das 54 fotos

O catálogo tem 22 fotos da etapa 13 e **32** novas, apesar da menção a 40 no arquivo da etapa. Fixtures montam o estado necessário; os gatilhos passam pelas ações reais. Os casos novos também executam a combinação incompleta e recarregam o save antes de repetir.

| Foto | Seção | Evento da ação real | Teste |
|---|---|---|---|
| `h_arrival` | story | `intro_done` | album_test (`_story`/`_campaign`) |
| `h_first_night` | story | `['slept', 'quest_claimed']` | album_test (`_story`/`_campaign`) |
| `h_growth_puppy` | story | `grew` | album_test (`_story`/`_campaign`) |
| `h_kitchen` | story | `fed` | album_test (`_story`/`_campaign`) |
| `h_growth_teething` | story | `grew` | album_test (`_story`/`_campaign`) |
| `h_first_walk` | story | `walk_returned` | album_test (`_story`/`_campaign`) |
| `h_first_trick` | story | `trick_learned` | album_test (`_story`/`_campaign`) |
| `h_growth_explorer` | story | `grew` | album_test (`_story`/`_campaign`) |
| `h_banca` | story | `quest_claimed` | album_test (`_story`/`_campaign`) |
| `h_growth_young` | story | `grew` | album_test (`_story`/`_campaign`) |
| `h_bench` | story | `quest_claimed` | album_test (`_story`/`_campaign`) |
| `h_courage` | story | `quest_claimed` | album_test (`_story`/`_campaign`) |
| `h_growth_adult` | story | `grew` | album_test (`_story`/`_campaign`) |
| `h_guardian` | story | `chapter_done` | album_test (`_story`/`_campaign`) |
| `f_bath` | firsts | `bathed` | album_test (`_firsts`/`_milk_tooth`) |
| `f_taste` | firsts | `fed` | album_test (`_firsts`/`_milk_tooth`) |
| `f_dig` | firsts | `dug` | album_test (`_firsts`/`_milk_tooth`) |
| `f_tooth` | firsts | `dug` | album_test (`_firsts`/`_milk_tooth`) |
| `f_friend` | firsts | `friend_heart` | album_test (`_firsts`/`_milk_tooth`) |
| `f_outfit` | firsts | `equipped` | album_test (`_firsts`/`_milk_tooth`) |
| `f_rare` | firsts | `walk_returned` | album_test (`_firsts`/`_milk_tooth`) |
| `f_brush` | firsts | `brushed` | album_test (`_firsts`/`_milk_tooth`) |
| `s_foam_ghost` | tricks | `petted` | album_secrets_test (`_case("s_foam_ghost")`) |
| `s_carrot_thief` | tricks | `harvested` | album_secrets_test (`_case("s_carrot_thief")`) |
| `s_hero_shadow` | tricks | `tapped_dog` | album_secrets_test (`_case("s_hero_shadow")`) |
| `s_sock_hunter` | tricks | `tapped_object` | album_secrets_test (`_case("s_sock_hunter")`) |
| `s_blueberry_face` | tricks | `fed` | album_secrets_test (`_case("s_blueberry_face")`) |
| `s_soap_explorer` | tricks | `bathed` | album_secrets_test (`_case("s_soap_explorer")`) |
| `s_sprinkler` | tricks | `watered` | album_secrets_test (`_case("s_sprinkler")`) |
| `s_sofa_throne` | tricks | `slept` | album_secrets_test (`_case("s_sofa_throne")`) |
| `s_photobomb` | tricks | `album_opened` | album_secrets_test (`_case("s_photobomb")`) |
| `s_moon_friend` | tricks | `project_used` | album_secrets_test (`_case("s_moon_friend")`) |
| `s_zoomies` | tricks | `played` | album_secrets_test (`_case("s_zoomies")`) |
| `s_begging` | tricks | `tapped_object` | album_secrets_test (`_case("s_begging")`) |
| `s_muddy` | tricks | `walk_returned` | album_secrets_test (`_case("s_muddy")`) |
| `p_curled` | sleep | `slept` | album_secrets_test (`_case("p_curled")`) |
| `p_belly_up` | sleep | `['slept', 'app_opened']` | album_secrets_test (`_case("p_belly_up")`) |
| `p_ball_hug` | sleep | `['slept', 'app_opened']` | album_secrets_test (`_case("p_ball_hug")`) |
| `p_sofa` | sleep | `slept` | album_secrets_test (`_case("p_sofa")`) |
| `p_pipoca` | sleep | `friend_visit` | album_secrets_test (`_case("p_pipoca")`) |
| `p_crown` | sleep | `['slept', 'app_opened']` | album_secrets_test (`_case("p_crown")`) |
| `p_sweater` | sleep | `['slept', 'app_opened']` | album_secrets_test (`_case("p_sweater")`) |
| `p_luxe` | sleep | `['slept', 'app_opened']` | album_secrets_test (`_case("p_luxe")`) |
| `a_pipoca` | friends | `friend_heart` | album_secrets_test (`_case("a_pipoca")`) |
| `a_nina_class` | friends | `trick_learned` | album_secrets_test (`_case("a_nina_class")`) |
| `a_bloblo_helper` | friends | `customer_delivery` | album_secrets_test (`_case("a_bloblo_helper")`) |
| `a_gathering` | friends | `project_gathered` | album_secrets_test (`_case("a_gathering")`) |
| `a_lais_lap` | friends | `bond_up` | album_secrets_test (`_case("a_lais_lap")`) |
| `a_four_friends` | friends | `friend_heart` | album_secrets_test (`_case("a_four_friends")`) |
| `d_month` | dates | `app_opened` | album_secrets_test (`_case("d_month")`) |
| `d_gotcha` | dates | `app_opened` | album_secrets_test (`_case("d_gotcha")`) |
| `d_full_moon` | dates | `['world_entered', 'app_opened']` | album_secrets_test (`_case("d_full_moon")`) |
| `d_first_cold` | dates | `app_opened` | album_secrets_test (`_case("d_first_cold")`) |
| `d_after_party` | dates | `world_entered` | album_secrets_test (`_case("d_after_party")`) |

## Checagens adicionais

Lupa diária e câmera, atraso de relógio, fala após três dias e recibo, comentário de personagem único, brilho com duas de três condições, Penetra na oitava elegível, calendário bissexto, festa no ano seguinte, roupa pela ação equip, lua cheia e lua nova, local de sono persistido e dois arrastos que não se somam. `birthday_cake` usa a receita/condição do Dia do Tiro. Todas as janelas de horário têm ao menos três horas; os intervalos curtos de banho/carinho e brincadeiras são combinações de ações, não janelas de calendário. Só Penetra usa sorte e tem garantia.

## Arquivos → testes → resultado

| Área mudada | Testes | Resultado |
|---|---|---|
| Álbum, calendário, estado, pistas, ações e PhotoCard | album_secrets_test, album_test | PASS |
| Casa, sala, sono, visitas e rega | house_test, friends_test, welcome_test, tray_test, world_life_test | PASS após corrigir o brilho que restaurava a opacidade de objetos bloqueados |
| Conteúdo e textos | content_test, texts_test | PASS |
| Visual, roupas, cuidado, receitas e navegação | pet_care_test, wishes_test, manual_test, lists_test, growth_visual_test, station_tray_test, products_test, fridge_test, world_view_test, navigation_test | PASS |

## Capturas e limites

360×780: before_sections, secret_grid, secret_hint, secret_lupa, secret_discovered, tiro_party, sleep_pipoca. PNGs abertos; a revisão corrigiu tamanho do chapéu e espuma sobre o rosto. Evidência em `build/screenshots/tiro15/`. Sem aparelho físico; nenhum gesto novo criado (a rega aproveita o arrasto existente). Sem suíte completa nem simulação de economia. Importação Godot com permissão para user:// e configurações do editor; tentativa inicial no sandbox falhou por acesso ao disco, não foi contada como PASS.

## Resultado final

**19 testes distintos: todos PASS.** Rodadas restritas via `test_all.ps1 -Only`: `affected.log/csv` (2,5 min; detectou opacidade, corrigida), `final.log/csv` (4,4 min; 12 PASS), `recheck.log/csv` (0,8 min; 4 PASS), `last.log/csv` (0,4 min; dois testes do álbum após a revisão da pose de sono e dos comentários da turma). Teste novo: **11,1 s** na última execução; 32 novos IDs listados em PHOTO COVERAGE. `album_test` mantém a cobertura das 22 anteriores, isolando essas seções nos casos da etapa 13 e verificando 54 no contador atual.

O quinto truque foi conferido com a fase Mocinho na fixture; o bolo foi preparado pela fila real do fogão e recolhido após 600 s. A pose de sono da foto usa o último quadro da animação (o primeiro é a transição em pé); sofá e caminha de luxo reutilizam os objetos existentes na composição. Fotos com roupa usam corpo/âncoras pela fase real, sem redesenhar o Tiro.

Encadeamento tentado após a conclusão: `mcp__codex_app.create_thread` recusou a criação de “Tiro — Etapa 16” pela política `approval policy is never`. Não houve novo chat; abrir manualmente no projeto local ClaudeGame. A etapa 16 não foi iniciada aqui.

Importação final limpa; capturas finais sem erro de script. As sete imagens foram geradas, e grade/lupa/foto descoberta/Dia do Tiro/Encostadinhos foram abertas e inspecionadas. A primeira lama PixelLab incluiu animal; a primeira Pipoca permaneceu em pé: ambas preservadas como fontes rejeitadas, nunca instaladas. Nova pose da Pipoca usa a referência original, com preparo alinhado à linha dos pés. Manifesto contém 14 gerações, 12 fontes aceitas; o Tiro anterior permaneceu intacto. `AGENTS.md` e `CLAUDE.md` idênticos. Próxima: etapa 16 em sessão própria.
