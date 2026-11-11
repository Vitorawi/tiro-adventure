# 02 — História, pratos e tutorial

## 1. Missões novas

Padrão do projeto: a principal (Laís, `kind: main`) **orienta** com `shared_with`; a entrega e o prêmio
ficam na linha do personagem (`kind: line`). Ids estáveis; ordens encaixadas entre as existentes.

### Capítulo 2 — Filhotinho (logo depois de "Mãos na terra")

| Id | Linha | Ordem | Título | Objetivo | Prêmio |
|---|---|---|---|---|---|
| `lais_fishing` | main | c2 o30 | **Um peixinho para o Tiro** | `quest: bloblo_first_fish` (shared) | — |
| `bloblo_rod` | bloblo | 32 | A vara da vovó | falar com a vovó na lagoa | **vara de bambu** + 5 minhocas |
| `bloblo_first_fish` | bloblo | 34 | Primeira fisgada | `fish` 1 (fresh) — **o tutorial** | 10 moedas |
| `bloblo_three_fish` | bloblo | 36 | Peixes da lagoa | pegar lambari, cará e tilápia (`fish:<id>` 1 cada) | 15 moedas + 5 minhocas |
| `bloblo_worms` | bloblo | 38 | Minhocas acabam | comprar minhocas na **aba Comprar da banca** (`bought:bait_worm` 1) — apresenta a compra na banca | 5 moedas |

Fala da Laís no `lais_fishing`: *"Filhote cresce comendo de tudo um pouquinho. Peixe faz bem para os
dentinhos que estão nascendo! A vovó tem uma lagoa cheia deles."*

### Capítulo 3 — Dentinhos (depois de "Cheirinho de comida", com o fogão)

| Id | Linha | Ordem | Título | Objetivo | Prêmio |
|---|---|---|---|---|---|
| `lais_fish_mash` | main | c3 o22 | **Papinha de peixe** | cozinhar `fish_mash` 1 + dar ao Tiro 1 (`feed:fish_mash`) | 15 moedas |
| `bloblo_big_tilapia` | bloblo | 64 | Uma tilápia das grandes | pegar uma tilápia **Grande ou maior** (contador `fish_size:large:fish_tilapia`, que o motor soma também para Gigante) | 20 moedas + 1 parafuso |

Requisito de fase: `teething.requirements` ganha
`{"id": "fish_meal", "type": "feed", "item": "fish_mash", "qty": 2, "label": "Papinha de peixe"}`
(sem `body_level`: o Corpo continua vindo da Cenoura gelada). O passo final `growth_3_teething` não muda.

### Capítulo 5–6 — Aventureiro (Vila e Bosque abertos)

| Id | Linha | Ordem | Título | Objetivo | Prêmio |
|---|---|---|---|---|---|
| `merchant_fishing` | merchant | após `merchant_orders` | **Vara nova** | ter nível de pesca 3 + comprar `reel_rod` no Feirante | 20 moedas + 4 massas |
| `bloblo_carp` | bloblo | 115 | O peixe do fundo | pegar 1 carpa | 25 moedas |
| `lais_fish_stew` | main | c6 o25 | **Ensopado de peixe** | cozinhar `fish_stew` 1 e dar ao Tiro | 30 moedas |
| encomenda `lais_fish_lunch` | Laís | — | Peixe para o almoço | 2 `fish_pacu` + 1 `fish_stew` (`customer: lais`) | 90 moedas |

Requisito de fase: `explorer` ganha `{"id": "fish_meal", "type": "feed", "item": "fish_stew", "qty": 2}`.

### Capítulo 8 — Mocinho (pelo começa a mudar)

| Id | Linha | Ordem | Título | Objetivo | Prêmio |
|---|---|---|---|---|---|
| `guide_angler` | guide | 60 | **O pescador da trilha** | conversar com o Guia sobre a lagoa | receita da vara na bancada |
| `guide_angler_rod` | guide | 62 | Vara do pescador | fazer `angler_rod` na bancada: 3 madeira dura + 4 fibra + 2 cobre | 4 iscas artificiais |
| `guide_pintado` | guide | 64 | O gigante do fundo | pegar 1 pintado | 40 moedas + coleção `fisher_hat` (chapéu, etapa 08, se houver arte) |
| `lais_shiny_coat` | main | c9 o15 | **Pelo brilhante** | cozinhar `herb_fish` 1 e dar ao Tiro | 30 moedas |

Requisito de fase: `young` ganha `{"id": "fish_meal", "type": "feed", "item": "herb_fish", "qty": 2}`.
`herb_fish` também é **fonte de momento de Pelagem** (`growth.json → moments.sources`), porque peixe com
ômega-3 deixa o pelo brilhante — fato real que entra em `phases.young.facts`.

Total: 15 missões novas (5 principais). Atualizar `docs/PROGRESSION.md` e a contagem no `journey_test`.

## 2. Pratos de peixe (receitas novas)

Comida de cachorro **de verdade**: peixe cozido, sem espinha, sem sal, com legumes.

| Prato `id` | Estação | Entrada | Saída | Tempo | Fases | Efeito ao dar |
|---|---|---|---|---|---|---|
| **Papinha de peixe** `fish_mash` | fogão | 1 tilápia + 1 batata | 1 | 3 min | puppy, teething | fome 40, felicidade 10 |
| **Ensopado de peixe** `fish_stew` | fogão | 1 pacu *ou* 1 carpa + 1 cenoura + 1 batata | 2 | 8 min | explorer, young | fome 45, energia 15 |
| **Peixe com ervas** `herb_fish` | fogão | 1 pintado *ou* 1 tucunaré + 2 ervas | 2 | 12 min | young, adult | fome 35, higiene 10, **momento de Pelagem** |
| **Petisco de lambari** `lambari_crunch` | fogão | 3 lambaris | 2 (petisco, `treat`) | 4 min | teething → adult | fome 15, felicidade 15 |
| **Massa de milho** `bait_dough` | fogão | 2 milhos | 4 iscas | 5 min | — | — |

"Ou" = receitas separadas com o mesmo resultado (`fish_stew_carp`, `fish_stew_pacu`), porque o formato de
receita não tem alternativa. Ícones ilustrados `food_<id>.png` (padrão da bandeja de estação).
Venda: papinha 18, ensopado 35, peixe com ervas 60, petisco 14 (ajustar na 09).

## 3. Tutorial — "A vovó ensina a pescar" (etapa 04)

Molde do `AlbumTutorial`: véu com um buraco só no que se pode tocar, balão de madeira com o retrato
animado da vovó, mão que mostra o gesto, nada de pular passo. Passo salvo no save (`fishing.tutorial`),
retoma onde parou. O minigame fica **pausado** enquanto o balão está aberto.

| # | Onde | A vovó diz | O jogador faz | Regra especial |
|---|---|---|---|---|
| 1 | Sítio, conversa da missão `bloblo_rod` | "Essa vara de bambu era do meu velho. Agora é sua! Vem, a lagoa é logo ali." | Ir (alfinete na lagoa) | dá vara + 5 minhocas |
| 2 | Lagoa | "O Tiro já foi sentar na beirinha. Toque na água!" | tocar na lagoa | câmera centra; Tiro anda e senta |
| 3 | Painel de arremesso | "Minhoca é a isca dos peixinhos pequenos. Já está no anzol." | — (isca já escolhida) | só o botão Arremessar ativo |
| 4 | Força | "Segure o botão… e solte quando o ponteiro estiver no verde, bem longe!" | segurar e soltar | zona sempre ≥ Meio |
| 5 | Espera | "Agora é paciência. Olha a boia…" | esperar | espera fixa 3 s |
| 6 | Mordida | "**Afundou! Toque já!**" (o Tiro late) | tocar | janela sem limite |
| 7 | Minigame pausado | "Esse peixinho é o lambari. A barrinha verde é a sua rede." | Continuar | seta na barra e no peixe |
| 8 | Minigame pausado | "**Segure o dedo** em qualquer lugar: a barra **sobe**." | segurar 1 s | mão animada |
| 9 | Minigame pausado | "**Solte**: ela **desce** sozinha." | soltar | |
| 10 | Minigame ao vivo | "Deixe o peixe **dentro** da barra para encher a rede!" | jogar | lambari D 8, dreno 0 até 50% — **não dá para perder** |
| 11 | Rede em 60% | "Se ele fugir da barra, a rede esvazia. Quase lá!" | jogar | dreno normal a partir daqui, mas a rede não desce abaixo de 0,2 |
| 12 | Resultado | "Olha o tamanho! Cada peixe tem o seu, e eu anoto o maior no caderninho." | Oba! | mostra cm, classe, recorde |
| 13 | Volta à lagoa | "Peixe bom para o Tiro é a **tilápia**, para a papinha. Pega mais uns!" | — | fim; missão `bloblo_first_fish` pronta |

Depois do tutorial, dicas curtas de primeira vez (uma vez cada, em `progress.seen`):
- primeira **bolha** na lagoa: "Bolhinhas! Ali os peixes mordem rapidinho.";
- primeiro peixe **escapado**: "Ele escapou e levou a minhoca. Na próxima, solte o dedo um pouco antes.";
- primeira vez **sem minhoca**: "Acabaram as minhocas. Tem na minha banca, e às vezes aparece uma ao colher.";
- primeiro **baú** (vara 2): pausa curta "Um baú! Cubra ele com a barra… mas não perca o peixe!".

## 4. Diárias, semanais e encomendas (etapa 08)

`routines.json` (fazenda): diária "Pescar 3 peixes" (`fish` 3), semanal "Um peixe Grande" (`fish_size:large`
1) e "Pescar 15 peixes". Encomendas `customer`: Bloblo "Lambaris para a vovó" (4 lambaris), Nina "Petisco
de lambari" (2), Laís "Peixe para o almoço" (§1). Feirante compra todos os peixes (venda normal).

## 5. Ritmo esperado (medido na 10)

Hoje (aprovado em 23/10): Filhotinho 1,5 min, Dentinhos 0,34 d, Aventureiro 2,08 d, Mocinho 8,84 d,
adulto 19,84 d. Meta: **+1–2 h** de jogo nos Dentinhos (tutorial + achar 2 tilápias + cozinhar) e
**+3–5 h** em Aventureiro e Mocinho, sem passar de +10% na campanha inteira. Se passar, primeiro baixar a
quantidade dos pratos (2 → 1), depois o preço das iscas.
