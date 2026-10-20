# 04 — A história conduzida pelo Tiro (autoritativo)

## A. Princípio

Cada arco termina com **o Tiro crescendo**, e o arco seguinte começa porque ele cresceu. A missão de crescer é
o **último passo** dos capítulos 1, 3, 6, 9 e 12; como o capítulo seguinte só abre com o anterior completo,
**crescer abre o próximo capítulo**. Missões antigas mantêm IDs, objetivos e prêmios; mudam as **falas**
(o porquê passa a ser o Tiro), salvo onde está escrito o contrário. IDs são mantidos por organização (testes,
ferramentas), não por compatibilidade de save.

| Arco | Capítulos | Fase durante o arco | Cresce para | Pergunta do arco |
|---|---|---|---|---|
| 1 | 1 | Recém-chegado | Filhotinho | "Ele chegou assustado. Como faço ele se sentir em casa?" |
| 2 | 2–3 | Filhotinho | Dentinhos | "Filhote precisa de comida de verdade e de alívio para os dentinhos." |
| 3 | 4–6 | Dentinhos | Aventureiro | "Ele precisa conhecer gente, gastar energia e comer para crescer forte." |
| 4 | 7–9 | Aventureiro | Mocinho | "O pelo dele está mudando: cuidar do pelo e da comida de mocinho." |
| 5 | 10–12 | Mocinho | Azul e Dourado | "Ele já é parte da turma. Hora da coragem." |

## B. Novo objetivo e novo requisito

- Objetivo `{"type": "growth", "key": "<fase>"}`: cumprido quando o Tiro **já está** nessa fase ou além.
  Botão "Ir" abre o painel de crescimento (`Places.goal_target` → `growth`). `TaskHelp.describe("growth", fase)`
  mostra os requisitos que faltam, cada um tocável.
- Requisito `{"growth": "<fase>"}` no avaliador único (`GameState.requirement_error`): "Quando ele for
  Aventureiro". Usado em truques, passeios, receitas e features (seção D).

## C. Capítulo a capítulo

IDs novos em **negrito**. `order` encaixa entre os existentes (ver `quests.json`).

### Capítulo 1 — Um novo lar (Recém-chegado)
- Falas: a Laís apresenta um filhote assustado ("ele tremia na caixinha"); banho/brincar/caminha viram
  "deixar ele à vontade".
- **`growth_1_puppy`** (ordem 70) "Ele está crescendo!": objetivo `growth: puppy`. Diálogo: a Laís percebe
  que ele já corre pela casa. Prêmio: nenhum extra (o presente vem da fase).

### Capítulo 2 — O sítio da vovó (Filhotinho)
- Falas: "filhote precisa de comida de verdade" → horta da vovó. Sem missões novas.

### Capítulo 3 — A cozinha (Filhotinho → Dentinhos)
- `main_2_fridge`: "a comida dele precisa ficar fresquinha". `first_kitchen`: "papinha caseira" (libera
  `puppy_mash`). `lais_blender` "Picolé pro calor" → fala nova: "algo geladinho para os dentinhos" (libera
  `frozen_carrot`).
- Linha da vovó: **`bloblo_chew_ring`** (ordem 62, requisito `first_kitchen`) "Argolinha da vovó": entregar
  cenoura 3 + batata 1 → prêmio `chew_ring` + 10 moedas. Fala: "costurei uma argolinha de pano; molha, gela e
  ele morde à vontade".
- **`teeth_3_ring`** (ordem 35) "Dentinhos coçando": objetivo `quest: bloblo_chew_ring`, `shared_with:
  bloblo_chew_ring` (principal orienta, a linha entrega).
- **`growth_3_teething`** (ordem 40) "As orelhinhas subiram!": objetivo `growth: teething`.

### Capítulo 4 — Conhecendo a Vila (Dentinhos)
- Falas: "ele precisa conhecer gente nova" (socialização). Feira/encomenda continuam; a Nina aparece
  porque "a Praça é ótima para filhote aprender".

### Capítulo 5 — Além do portão (Dentinhos)
- Falas: "ele tem energia demais" → Bosque; bancada "para fazer coisas para ele roer" (libera `stick_chew`).

### Capítulo 6 — Uma produção de verdade (Dentinhos → Aventureiro)
- `main_5_cooking`: fala "comida caseira para quem cresce".
- **`explorer_6_eggs`** (ordem 45) "Comida de quem cresce": objetivo `quest: main_9_eggs`, `shared_with:
  main_9_eggs` (a vovó guia galinheiro + ovos; libera `growth_kibble`).
- **`growth_6_explorer`** (ordem 50) "Um pequeno aventureiro": objetivo `growth: explorer`.

### Capítulo 7 — Nosso lugar na vila (Aventureiro)
- Falas: o Tiro vira o mascote da banca ("os clientes perguntam por ele"). Sem missões novas.

### Capítulo 8 — Um mundo de possibilidades (Aventureiro)
- `main_7_greenhouse`: "ervas para um banho cheiroso" (libera `herb_shampoo`).
- **`young_8_shampoo`** (ordem 40) "Banho de ervas": objetivo `stat: shampoo_bath` 1.

### Capítulo 9 — Feito por nós (Aventureiro → Mocinho)
- `main_8_fiber`: "fibras para uma escova macia" (libera `soft_brush`).
- **`young_9_milk`** (ordem 35) "Mingau de mocinho": objetivo `quest: main_9_flour`, `shared_with:
  main_9_flour` (curral, leite e moinho pela linha da vovó; libera `milk_porridge`).
- **`growth_9_young`** (ordem 40) "Pelo de mocinho": objetivo `growth: young`.

### Capítulos 10–11 — Obras (Mocinho)
- Falas: o Tiro participa das obras como membro da turma (banco, jardim, piquenique). Sem missões novas.

### Capítulo 12 — A festa da nossa turma (Mocinho → Azul e Dourado)
- `community_12_memory`: fala nova com a homenagem à **Smoky** (Yorkie de 1,8 kg que, em 1944, passou um cabo
  por um cano de 20 m): durante a Festa, o Tiro leva o fio das bandeirolas pelo cano do coreto. Prêmio passa a
  incluir `courage_medal`.
- **`growth_12_adult`** (ordem 40) "Azul e dourado": objetivo `growth: adult`. Depois vem o `final_chapter`
  com fala nova ("o filhotinho da caixinha virou o Guardião do Vale").

**Total:** 9 principais novas (40 → 49) e 1 na linha da vovó: o jogo passa de 99 para 109 missões.

## D. Liberações ligadas à fase (requisito `growth` somado ao que já existe)

| Conteúdo | Requisito novo |
|---|---|
| feature `wishes` (aba Desejos) | `growth: puppy` (além de `lais_bed`) |
| truques `paw`, `talk` | `growth: teething` |
| truques `roll`, `jump` | `growth: explorer` |
| truque `spin` | `growth: young` |
| passeios `creek_walk`, `bird_clearing`, `hill_view` | `growth: explorer` |
| receita `treat_box` | `growth: explorer` (no lugar de `skills.cooking 5`) |
| receita `topknot_bow` | `growth: young` |
| Pelagem de seda, caminha de luxo | `growth: adult` |

## E. Saves antigos

Não há. A etapa 02 zera saves com `SAVE_VERSION` < 13 (decisão do Vitor): todo mundo recomeça com o Tiro
recém-chegado e vive a história nova do começo. Nenhuma missão nova precisa ser "reconhecida" para saves antigos.

## F. Regras para as falas

Uma ideia por fala, curta (o celular quebra a linha). O Tiro é sempre o motivo ("para ele", "os dentinhos
dele"). A Laís fala de casa e cuidado; a vovó Bloblo, de comida; a Nina, de passeio, truques e coragem; o
Feirante, de clientes que gostam do Tiro; o Guia, de natureza e energia.
