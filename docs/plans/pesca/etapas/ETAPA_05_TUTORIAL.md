# Etapa 05 — Tutorial "A vovó ensina a pescar" e capítulo 2

> Tamanho: grande. Depende de: 02, 03, 04. Próxima: 06.
> Resultado que o Vitor vê (save novo): no capítulo 2, depois de "Mãos na terra", a Laís fala do peixinho; a
> vovó dá a vara de bambu; um tutorial guiado, com o jogo pausando para explicar, leva até o primeiro lambari
> (impossível de perder); depois, pegar os três peixes da lagoa e aprender a comprar minhocas na banca.

## 1. Ler antes

- `02_HISTORIA_E_TUTORIAL.md` §1 (capítulo 2) e §3 (os 13 passos e as dicas de primeira vez).
- `CLAUDE.md`: "História e linhas de NPC" (`kind main/line`, `shared_with`, `fresh`, `talk:<npc>`,
  `_sync_shared_quests`), "Jornada e prêmios" (`QuestReward`, `ProgressionUi.claim_quest_fx`), parágrafo
  "Fotos do Tiro — etapa 09, tutorial" (`AlbumTutorial`: véu `Veil_T/B/L/R`, `TutorialHighlight`, balão com
  `ProgressionUi.npc_header`, `TutorialHand`, passos salvos, espera a fila modal com `Main.notice_blocked`).
- Código:
  - `game/data/quests.json`: formato real (ex.: `lais_first_crops` com `shared_with`, `go`; `bloblo_more_crops`
    com `goals [{type stat, key, target, fresh, label}]`, `kind line`, `line bloblo`, `order`).
  - `game/scripts/ui/album_tutorial.gd` inteiro (é o molde: `maybe_start`, `_go(next)`, `_build_layer`,
    `target_rect`, `_layout`, `_start_hand`, `_finish`).
  - `game/scripts/state/progression_state.gd`: `active_steps`, `requirement_error`.
  - `game/data/npcs.json → bloblo` (`lines`, `introduction`, `services`).
  - `tests/journey_test.gd` e `tests/progression_test.gd` (contam missões; vão mudar de número).

## 2. Como está hoje

Capítulo 2 = `lais_first_wish` (o5), `lais_meet_bloblo` (o10), `lais_first_crops` (o20). Pesca existe completa
(01–02), arte (03), banca com compra (04). Nenhuma missão de pesca.

## 3. Passo a passo

1. **Missões** (`quests.json`), textos exatamente como no §1 do `02_HISTORIA`:
   - `lais_fishing` (`kind main`, `chapter 2`, `order 30`, `npc lais`, `shared_with "bloblo_first_fish"`,
     goal `{type quest, key bloblo_first_fish, label "Pescar com a vovó"}`, `go {world farm, place npc:bloblo,
     hint "Sítio → vovó Bloblo"}`, `dialogue` da Laís do §1);
   - `bloblo_rod` (`line bloblo`, `order 32`, `requirements {quests [lais_first_crops]}`, goal
     `{type stat, key "talk:bloblo", target 1, fresh true, label "Falar com a vovó"}`, rewards
     `{"rods": ["bamboo_rod"], "items": {"bait_worm": 5}}`, `dialogue` "Essa vara de bambu era do meu velho…");
   - `bloblo_first_fish` (o34, goal `{type stat, key fish, target 1, fresh true, label "Pescar um peixe"}`,
     `go {world farm, place fishing}`, rewards coins 10);
   - `bloblo_three_fish` (o36, três goals `fish:fish_lambari`, `fish:fish_cara`, `fish:fish_tilapia`, target 1
     cada, sem fresh; rewards coins 15 + bait_worm 5);
   - `bloblo_worms` (o38, goal `{type stat, key "bought:bait_worm", target 1, fresh true, label "Comprar
     minhocas na banca"}`, `go {world farm, place early_market, action "shop:worm_pack"}`, rewards coins 5).
   Conferir que nenhuma ordem colide com a linha `bloblo` atual (`bloblo_dig 25`, `bloblo_silo 27`,
   `bloblo_more_crops 30`, `bloblo_potato 50`): 32/34/36/38 ficam livres.
2. **`Places.goal_target`**: `fish`, `fish:<id>`, `fish_size:*` → `{world farm, place fishing}`;
   `bought:<item>` → loja que vende o item (`shop:<id>` da 04). `TaskHelp.describe("stat", "fish…")` → "Pescar
   na lagoa do Sítio" com Ir; `bought:` → "Comprar na banca".
3. **Tutorial — `game/scripts/ui/angler_tutorial.gd`** (`class_name AnglerTutorial`, filho de `Main`, z 13,
   sempre o último filho; **copie a estrutura do `AlbumTutorial`**, troque Laís pela vovó e a carta pela lagoa):
   - começa quando `bloblo_rod` foi entregue e `GameState.fishing.tutorial.done == false`, ao entrar no Sítio ou
     ao tocar na lagoa; espera `Main.notice_blocked()` ficar falso (fila modal vazia);
   - passos e falas: tabela do `02_HISTORIA §3` (13 passos). Passo salvo em `fishing.tutorial.step` via
     `GameState.advance_fishing_tutorial(step)` / `finish_fishing_tutorial()` (ações novas, com teste);
   - véu com buraco só no alvo de cada passo (lagoa → `CastButton` → força → toque na mordida → tela do minigame);
   - passos 7–9 **pausam** o `FishingGame` (`FishingGame.paused = true`: o `FishingSim` não anda) e mostram
     setas na barra e no peixe; passo 8 só avança depois de 1 s segurando; passo 9 depois de soltar;
   - passos 10–11: regras do tutorial no motor (já previstas na 01): lambari com D 8, dreno 0 até a rede passar
     de 50%, e depois a rede nunca cai abaixo de 0,2 — implemente como campos de `cast`
     (`tutorial: true`) lidos pelo `FishingGame` ao criar o `FishingSim` (`difficulty_override`,
     `drain_until`, `meter_floor`). **A primeira partida não pode falhar**;
   - passo 12: o `FishResult` normal com um balão por cima; passo 13 fecha o tutorial e mostra o próximo passo
     (`bloblo_three_fish`).
   - Retomar: fechar o app em qualquer passo → volta naquele passo na próxima visita à lagoa (passos 7–11
     recomeçam a partida do passo 6 com a mesma isca já gasta: `cast` do tutorial não gasta isca).
4. **Dicas de primeira vez** (`02_HISTORIA §3`, fim): `Notice` de madeira com o rosto da vovó, uma vez cada,
   marcadas em `progress.seen["fishing_tip:<id>"]` por `GameState.mark_seen`: `bubble`, `escape`, `no_bait`.
   (`chest` vem na 07.)
5. **Falas da vovó** em `npcs.json → bloblo.lines`: `lake_locked`, `tips.*`, para não ter texto no código.
6. Contagem de missões: atualizar `docs/PROGRESSION.md` e os números esperados no `journey_test`/
   `progression_test` (eles contam missões totais e principais).

## 4. Não fazer

Papinha/Dentinhos (06). Mudar as missões existentes do capítulo 2. Pular passos no tutorial.

## 5. Armadilhas

- `shared_with`: a principal só orienta; a entrega e o prêmio são da linha da vovó (`_sync_shared_quests`
  avança a principal junto). Não duplique o prêmio.
- O robô da campanha (`progression_test`) precisa conseguir passar pelo capítulo 2: ele ainda não pesca (09/10).
  **Nesta etapa** dê a ele uma ação simples: no `economy_bot.gd`, quando a missão ativa pedir `fish*`, chamar
  `cast → hook → finish_fishing({caught true, score 0.6, perfect false})` direto no `GameState` (sem tela),
  respeitando iscas e comprando minhocas com `buy_shop_item`. Sem isso a campanha trava no capítulo 2.
- O tutorial depende da fila modal: a recompensa da `bloblo_rod` (QuestReward) precisa fechar antes.

## 6. Testes

Novo **`game/tests/fishing_tutorial_test.gd`** (área `fishing` + `story`):
1. Save novo até `lais_first_crops`: `lais_fishing` e `bloblo_rod` ativas; falar com a vovó dá a vara e 5
   minhocas (uma vez).
2. O tutorial começa sozinho ao tocar na lagoa, no passo 1; o véu só deixa tocar no alvo.
3. Cada passo avança só com a ação certa; o passo salvo bate.
4. No minigame do tutorial, ficar sem tocar nenhuma vez **ainda assim** termina em captura (rede com piso).
5. O peixe é lambari; a isca não é gasta no tutorial.
6. Fechar no passo 9 e recarregar: retoma no passo 6/7 sem duplicar prêmio.
7. Fim: `bloblo_first_fish` pronta; entregar mostra o `QuestReward`; `bloblo_three_fish` ativa.
8. `bloblo_worms` com Ir abre a banca na aba Comprar com as minhocas escolhidas; comprar conclui.
9. Dicas `escape` e `no_bait` aparecem uma vez cada.
10. Robô: com a ação simples, chega ao fim do capítulo 2.
Afetados: `journey_test`, `quest_reward_test`, `next_step_test`, `npc_lines_test`, `texts_test`,
`fishing_lake_test`, `shop_test`, `progression_test` (campanha: rodar só se der ≤ 20 min; senão fica para a 06).

## 7. Capturas

`game/tests/fishing_tutorial_shots.gd` → `build/screenshots/fishing_tutorial/`, um PNG por passo (13), nas três
resoluções, FAIL se o balão cobrir o alvo, sair da tela ou cortar texto.

## 8. Pronto quando

Testes PASS, os 13 PNGs abertos e lidos em sequência como uma história, registro no README do plano, ROADMAP,
`CLAUDE.md`/`AGENTS.md`.

## 9. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 05 do plano "Pesca na lagoa da vovó" (tutorial + capítulo 2).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–04), 02_HISTORIA_E_TUTORIAL.md e
docs/plans/pesca/etapas/ETAPA_05_TUTORIAL.md. Copie a estrutura do AlbumTutorial. A primeira
pesca não pode falhar. Dê ao robô da campanha a ação simples de pescar (armadilha 2).
Registre fishing_tutorial_test em suite e nas áreas fishing/story. Capturas SEM --headless.
Ao terminar: Registro da 05 no README, ROADMAP, CLAUDE.md = AGENTS.md, PROGRESSION.md.
Sem commit/push/publicação. Não executar a 06.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
