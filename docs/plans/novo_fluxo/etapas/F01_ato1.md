# F01 — Ato 1 em casa (passos 1 a 8)

Plano: `docs/plans/novo_fluxo/README.md` (seções 2, 3 e 6b; decisões F1, F2, F5). Mapa do projeto: `CLAUDE.md`.
Base: F00 concluída (`content_day()` = capítulo; sem espera de dia; `SAVE_VERSION` 34).
Esta etapa **não** faz a lição do painel de crescimento nem a aula da comida (F02), nem o Sítio/fogão/vovó (F03).

## Objetivo

A primeira sessão acontece só em casa, com o Tiro, uma coisa nova por vez, e termina com o primeiro crescimento
(Filhotinho) e a carta da chegada aberta no Álbum. Diretriz do Vitor: **simples, dinâmico, ajudar ao máximo**:
sempre há um próximo toque óbvio (mão/balão/brilho), falas de uma linha, comemorar cada passo.

## Os 8 passos (capítulo 1, `kind: "main"`)

| Ordem | id | Fala da Laís (uma linha, pode ajustar) | Objetivo | Prêmio / efeito |
|---|---|---|---|---|
| 10 | `welcome` | (cena da caixinha) | `stat arrival_box` 1 (já existe) | 1 `puppy_mash` (a "papinha pronta"); **sem moedas** |
| 20 | `lais_feed` | "Ele está com fome. Trouxe uma papinha pronta." | `feed` 1, `fresh` | — |
| 30 | `lais_bath` | "A caixinha sujou ele todo! Um banho?" | `bathe` 1, `fresh` | — |
| 40 | `lais_play` | "Agora ele quer brincar!" | `play` 1, `fresh` (jogar a bolinha) | 1 `bed_gift` (sem Mochila: vai direto para o inventário) |
| 50 | `lais_bed` | "Trouxe uma caminha. Escolha o cantinho dele." | `owned dog_bed` | — |
| 60 | `lais_growth` | "Viu como ele está mudando? Olha aqui." | abrir o painel de crescimento (contador `open:growth`; crie a contagem em `GrowthUi.panel/open` se não existir) | — |
| 70 | `growth_1_puppy` | "Ele está pronto para crescer!" | `growth puppy` (já existe; mover do cap. 2) | cerimônia (já existe) |
| 80 | `lais_photo` | "Tirei uma foto de vocês! Vamos abrir?" | concluir o tutorial da carta (contador novo `album_tutorial`, contado em `GameState.finish_album_tutorial`) | — |

- Reaproveite os ids `welcome`, `lais_play`, `lais_bed`, `growth_1_puppy` (outros sistemas apontam para eles:
  `dog_bed.requirements`, `week_story.json → growth_steps`, fotos). `lais_play` deixa de pedir `yard:ball`/`name_call`
  (o quintal volta no Ato 3). A linha `lais_album` (`kind: line`, `lais_memories`) **sai**: o passo 8 a substitui.
  Ajuste quem a referencia (código, `album.json`, testes).
- Depois do passo 8, mantenha os passos de Sítio atuais do capítulo 1 (`lais_first_crops`, `first_kitchen`,
  `week_market`, `week_plots`, `week_invent`) como estão, só renumerados depois do 80. A F03 refaz isso.
  O passo seguinte ao 80 (`lais_first_crops`) ganha a fala-gancho: "Filhotinho come comida de verdade, na hora do
  almoço e do jantar. Quem planta tudo isso é a vovó Bloblo."
- Capítulo 2 perde `lais_bed` e `growth_1_puppy` (foram para o 1). Confira que o capítulo 2 continua fechando.
- `progression.json` capítulo 1: sem "A vovó volta amanhã" (F00 já tirou); prêmios do capítulo sem moedas não são
  obrigatórios, mas **nenhuma moeda antes do Sítio** no Ato 1.

## Caixinha (passo 1)

`week_story.json → arrival.lines`: sai a 4ª fala (vovó). A última fala vira da Laís, algo como
"Pronto, ele saiu! Esse é o Tiro." com o botão "Oi, Tiro!". Mantenha o nó `ArrivalGo` (o tutorial `arrival` usa).
Ao fechar, a pessoa cai na tela do Tiro e o passo 2 já está guiado.

## O que aparece e quando (uma coisa por vez)

Use `progression.json → features` (`ProgressionState.feature_unlocked`) para tudo abaixo, sem número fixo no código.

| Coisa | Aparece quando |
|---|---|
| Botão Cuidar com **só Comida** | depois da caixinha (`welcome`) |
| Banho na roleta | `lais_feed` pego (o passo 3 está ativo) |
| Brincar na roleta | `lais_bath` pego |
| Dormir na roleta | `lais_bed` pego (caminha = soninho) |
| Aba Mapa (só a Casa) | `lais_play` pego (passo 5 precisa da Casa) |
| Pílula do mundo / seletor de mundos | só quando houver **mais de um** mundo aberto (o Sítio abre depois do passo 8) |
| Botão do Álbum + varal | `lais_photo` ativo (hoje é `photo_count() > 0`); as fotos continuam sendo tiradas em silêncio antes |
| Aba Missões e Mochila | depois do Ato 1 (`lais_photo` pego) — a F03 ajusta para o fim do Ato 2 |
| Pílula do próximo passo | continua visível desde o passo 2 (é a ajuda de sempre) |

- Roleta: hoje `PetCareTray._refresh_wheel` sempre põe os 4 discos em ângulos fixos. Esconda os que ainda não
  apareceram e distribua os visíveis no leque (um disco só = logo acima do botão). Quando um disco novo aparece,
  dê um destaque curto (pop/brilho) — é o "Novo!" dele, sem cartão modal.
- Aba Mapa: `main.gd` já esconde a Mochila por feature (`%BagTab.visible`); faça igual para `%MapTab` e `%TasksTab`.
  As abas que sobrarem devem ficar bem distribuídas no rodapé (confira `_layout_tab_bar`).
- `features.wishes`: tire "Desejos" do `unlocks_text` do `puppy` (desejo é capítulo 3, F04). `features.growth_tab`
  e qualquer outro "Novo!" que hoje dispara ao virar Filhotinho: só o que o passo apresenta. Nada de cartão
  "Novo!" para Mapa/Missões/Mochila durante o Ato 1 que interrompa a cerimônia ou a carta.

## Guia de cada passo (ajudar ao máximo)

Use o motor que já existe: `week_tutorials.json` + `WeekTutorial`/`TutorialGuide` (mão + balão sobre o alvo).
Prenda cada lição ao passo (`quest`), não ao dia:

- passo 2: mão no Cuidar → Comida → arrastar a papinha até a boca (lição `feed` adaptada ao cantinho, sem
  "Dar ao Tiro" da cozinha);
- passo 3: mão no Banho, depois esfregar com a esponja (lição `bath`);
- passo 4: mão no Brincar, jogar a bolinha para cima;
- passo 5: mão na aba Mapa e depois no "+" da caminha na Casa; a compra é grátis (`dog_bed` custa 0 e consome o
  `bed_gift`). Confira que a folha de compra mostra "Colocar" (não "Comprar") e nada de moeda;
- passo 6: mão no anel do avatar no HUD (abre o painel de crescimento);
- passo 7: mão no botão Crescer! do painel;
- passo 8: o `AlbumTutorial` já existente conduz a carta. Hoje ele começa dentro do caderninho (`CodexSections._album`)
  e depende da missão `lais_album`: faça-o começar pelo passo 8 (Ir do passo abre o Álbum e o tutorial segue).

Regras: cada mão aparece uma vez e some ao agir; se a pessoa fechar, a pílula do próximo passo leva ao mesmo
lugar (o `go` de cada missão deve apontar o destino certo — `Places.goal_target`/`quest_target`). Nenhum aviso de
erro sem caminho. Comemoração curta a cada passo (a `QuestReward` já faz; confira que não empilha com a cerimônia).

## Crescimento

`growth.json`:
- `puppy`: lista curta do Ato 1 — `feed` 1, `bathe` 1, `play` 1 (contadores `stat`), `bed` (`owned dog_bed`).
  Rótulos curtos ("Comer", "Banho", "Brincar", "Caminha"). Prêmios do Filhotinho: tire as moedas (sem moeda no
  Ato 1); mantenha `dog_food` 3. `chapter` do puppy = 1.
- `teething` recebe o que saiu do puppy e ainda não está nele (`star_dish`, `invented`, `name`), e `days`
  (`well_fed_day`) passa a **6** com contagem total (`"total": true`), para o dia da chegada contar (decisão F2:
  a papinha do passo 2 já dá a patinha do dia 1). Não duplique requisitos.
- Confira `GameState.week_growth_error` e o `growth_week_test`/`growth_story_test` com a lista nova.

## Saves, textos, docs

- `SAVE_VERSION` +1 (as missões mudaram), saves zerados, sem migração.
- Falas novas curtas, em português, no tom da Laís; sem "Toque em" longo dentro da fala (isso é do balão da mão).
- `docs/ROADMAP.md` "Estado atual": uma linha da F01. `CLAUDE.md` = `AGENTS.md`: uma linha curta no bloco
  "Primeira semana"/novo fluxo. `docs/plans/novo_fluxo/README.md → Andamento`: uma linha.

## Testes e capturas

- Teste novo `game/tests/ato1_test.gd` (suite + áreas `story` e `care` em `tools/test_areas.json`): save novo →
  caixinha → passos 2 a 8 pelas ações reais (`feed`, `bathe`, `play`, compra da caminha, abrir crescimento,
  `grow`, tutorial da carta) e confere: (1) roleta mostra só Comida no passo 2 e ganha um disco por passo;
  (2) Mapa invisível até o passo 5, Missões/Mochila invisíveis até o fim; (3) nenhuma moeda ganha no Ato 1;
  (4) Filhotinho ao fim do passo 7; (5) botão do Álbum só no passo 8 e tutorial termina; (6) patinha do dia 1 contada.
- Rodar `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests ato1_test,<afetados> -KeepGoing`.
  Antes de editar, rode a mesma lista para a linha de base (há falhas antigas: `cart_test`, `tasks_test`,
  `quest_reward_test`, `tray_test`). Afetados prováveis: `week_story_test`, `growth_story_test`, `growth_week_test`,
  `quest_reward_test`, `tasks_test`, `tasks_groups_test`, `album_test`, `album_tutorial_test`, `album_screen_test`,
  `pet_care_test`, `care_wheel_test`, `care_ui_test`, `journey_test`, `content_test`, `texts_test`, `no_day_gates_test`,
  `intro`/`arrival` (procure), e o helper `tests/helpers/week_story_route.gd`. Ajuste para a regra nova, não apague.
  `progression_test` (campanha) não roda aqui.
- Capturas: `tests/ato1_shots.gd` (sem `--headless`, `--resolution 360x780`) → `build/screenshots/ato1/`, um PNG por
  passo (caixinha final, cada roleta, o "+" da caminha, painel de crescimento, cerimônia, carta). Abra os PNGs e
  confira: nada cortado, mão sobre o alvo, rodapé com as abas certas.

## Pronto quando

- Save novo joga os 8 passos só em casa, um sistema por vez, sem moeda, chegando a Filhotinho e à carta aberta.
- Teste novo PASS, afetados PASS ou falha antiga documentada, capturas conferidas.
- Docs atualizados. Sem commit, push ou publicação.
