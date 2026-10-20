# 03 — Comidas, itens e economia a serviço do Tiro (autoritativo)

## A. Dois tipos de comida

- **Comida do dia:** mata fome/felicidade como hoje (`feed` em `items.json`). Cru e ração.
- **Comida de crescimento:** tem o campo novo `growth` em `items.json`, além do `feed`:

```json
"puppy_mash": {"name": "Papinha da vovó", "category": "food", "storage": "fridge",
  "feed": {"hunger": 35, "happiness": 10},
  "growth": {"pillars": {"body": 6}, "phases": ["newborn", "puppy", "teething"]}}
```

`phases` = fases em que é **adequada** (ganho ×1). Fora delas o ganho é ×0,5 e a bandeja mostra
"Ele prefere outra coisa agora" (sem bloquear). Na guia de comida do Tiro, comida adequada à fase ganha um
selo de pilar (ícone do pilar principal).

## B. Comidas que já existem (valores de crescimento)

| Item | Pilares | Adequada em |
|---|---|---|
| `dog_food` Ração | Corpo 2 | newborn, puppy (fora delas: 0, não ×0,5) |
| `carrot_snack` Petisco de cenoura | Corpo 2 | newborn → teething |
| `pumpkin_mash` Papinha de abóbora | Corpo 5 | puppy, teething |
| `mashed_potato` Purê de batata | Corpo 4 | puppy, teething |
| `vegetable_soup` Ensopado | Corpo 4, Coragem 1 | teething, explorer |
| `sweet_potato_chips` Chips de batata-doce | Corpo 3, Esperteza 1 | teething, explorer |
| `strawberry_pop` Picolé de morango | Coragem 2 | teething |
| `apple_biscuit` Biscoito de maçã | Corpo 3, Esperteza 2 | explorer → adult |
| `mint_snack` Petisco de hortelã | Pelagem 4 | young, adult |
| `blueberry_treat` Petisco de mirtilo | Esperteza 4, Pelagem 3 | young, adult |
| crus (cenoura, maçã, morango, mirtilo) | 0 | — (contam só "primeira vez" e paladar) |

`cheese` e `strawberry_juice` continuam sem poder ir para o Tiro.

## C. Itens e receitas novos

Ícones 32 px novos no PixelLab (prompts na etapa que cria). Tempos e quantidades são alvos iniciais.

| id | Nome | Onde | Entrada → saída | Tempo | Pilares | Adequada | Libera em |
|---|---|---|---|---|---|---|---|
| `frozen_carrot` | Cenoura gelada | liquidificador | cenoura 2 → 1 | 120 s | Corpo 4 | teething | `lais_blender` (cap. 3) |
| `puppy_mash` | Papinha da vovó | fogão | cenoura 1 + batata 1 → 1 | 120 s | Corpo 6 | newborn → teething | `first_kitchen` (cap. 3) |
| `corn_crunch` | Crocante de milho | fogão | milho 2 → 2 | 300 s | Corpo 4, Esperteza 1 | teething, explorer | capítulo 5 |
| `growth_kibble` | Ração de crescimento | fogão | milho 1 + cenoura 1 + ovo 1 → 2 | 600 s | Corpo 10 | explorer, young | `owned: chicken_coop` |
| `egg_scramble` | Ovinho mexido | fogão | ovo 2 → 1 | 120 s | Corpo 6, Pelagem 2 | explorer → adult | `owned: chicken_coop` |
| `cheese_bites` | Petisco de queijo | fogão | queijo 1 + farinha 1 → 3 | 300 s | Esperteza 4 | explorer → adult | `owned: dairy` |
| `milk_porridge` | Mingau de leite | fogão | leite 1 + farinha 1 → 2 | 300 s | Corpo 6, Pelagem 6 | young, adult | `owned: cow_barn` + `mill` |
| `herb_shampoo` | Xampu de ervas | liquidificador | ervas 2 + leite 1 → 2 | 300 s | — (usado no banho: Pelagem 12) | — | `owned: greenhouse` |
| `stick_chew` | Mordedor de graveto | bancada | graveto 3 + madeira 1 → 1 | 300 s | — (item-chave) | — | `owned: workbench` |
| `soft_brush` | Escova macia | bancada | tábua 1 + fibra 2 → 1 | 600 s | — (item-chave; melhora o escovar) | — | `quest: main_8_fiber` |
| `topknot_bow` | Lacinho do topete | costura | tecido 1 + fita 2 → coleção | 600 s | — (roupa de cabeça) | — | fase `young` |
| `birthday_cake` | Bolo do Tiro | fogão | farinha 1 + maçã 1 + ovo 1 → 1 | 600 s | Coragem 5 | todas | Dia do Tiro (etapa 15) |

Itens sem receita (vêm da história):

| id | Nome | Origem | Vira |
|---|---|---|---|
| `chew_ring` | Argolinha de morder | missão nova da vovó Bloblo `bloblo_chew_ring` (cap. 3) | lembrança na prateleira |
| `basic_brush` | Escovinha | presente ao virar Dentinhos (etapa 12) | ferramenta do "Escovar" |
| `courage_medal` | Medalhinha de coragem | missão `community_12_memory` (cap. 12) | lembrança + foto especial |

**Categorias novas:** `keepsake` (item-chave/lembrança: `storage: none`, não vende, não some da Mochila
até ser entregue) e `care` (xampu: `storage: fridge`). Vendas na feira, quando houver: frozen_carrot 8,
puppy_mash 12, corn_crunch 7 (cada), growth_kibble 14 (cada), egg_scramble 20, cheese_bites 8 (cada),
milk_porridge 15 (cada), herb_shampoo 18 (cada). Itens-chave não vendem.

**Por que esses:** cada estação ganha um uso para o Tiro — galinheiro (ovo) → ração/ovinho; curral + moinho →
mingau; queijaria → petisco de treino; estufa → xampu; bancada → mordedor e escova; costura → lacinho;
liquidificador → cenoura gelada e xampu. Ponto de atenção: a ração de crescimento pede o **galinheiro antes do
fim do capítulo 6** e o mingau pede **curral + moinho antes do fim do 9**. A história (04) passa a guiar essas
compras. Se o Vitor achar pesado ao simular, trocar por receitas sem animais (registrar em DECISOES).

## D. Banho, brinquedos e escova

- **Banho com xampu:** se houver `herb_shampoo` na Mochila, o banho mostra a opção "Com xampu" (ícone no
  banho da bandeja do Tiro). Consome 1, Pelagem 12, conta `shampoo_bath`.
- **Brinquedos de verdade (etapa 14):** `braided_toy` e `lost_ball` ganham `toy: true`. "Dar ao Tiro" coloca
  o brinquedo no **cesto de brinquedos** da Casa (sai da Mochila, fica para sempre). Cada brinquedo diferente
  no cesto dá +1 Esperteza ao brincar (máximo +3).
- **Escova (etapa 12):** `basic_brush` libera "Escovar"; `soft_brush` (entregue ao crescer para Mocinho)
  continua valendo depois: escovar dá Pelagem 8.

## E. Paladar (etapa 12)

- **Primeira prova:** a primeira vez que o Tiro come cada item, ele reage e o item entra no **Guia de
  sabores** (caderninho). Reação fixa por save (semente): favorita = "amou" (`happy_jump` + coraçõezinhos);
  das demais, 60% "gostou" (`wag_excited`), 30% "estranhou" (`head_tilt` + `lick_paw`), 10% "careta"
  (`shake_off`). Mirtilo cru é sempre careta (foto do álbum). Reação nunca reduz ganho.
- **Comida favorita:** sorteada uma vez por save entre `favorite_pool` (comidas de crescimento alcançáveis
  sem linha opcional até o capítulo 10: pumpkin_mash, mashed_potato, vegetable_soup, apple_biscuit,
  puppy_mash, corn_crunch, egg_scramble, cheese_bites, milk_porridge; a etapa confere a alcançabilidade).
  Fica "?" até ele provar. Dar a favorita: +50% nos pilares e a dancinha. O requisito 🍲 do Azul e Dourado é
  "a favorita ×3"; se ainda não foi descoberta, o chip diz "Descubra a favorita" e o "Como fazer" lista as
  comidas que ele ainda não provou.

## F. Fim do nível do jogador (etapa 07)

| Hoje | Depois |
|---|---|
| `GameState.level/xp`, anel de XP e número no HUD | nada disso aparece; `level` não sobe mais (pode ser removido, ver nota abaixo) |
| `Events.level_up` + `Celebration.show_level` + Popover do nível | não emitidos/mostrados mais |
| `level_rewards` (moedas a cada nível) | sem uso; substituídos pelos presentes de crescimento (02 F) |
| Atributos do jogador (`skills`: Horta, Cozinha, Comércio, Aventura) | sem interface; `skill_xp` ignorado nos prêmios; a aba do caderninho vira **Crescimento** |
| `treat_box` exige `skills.cooking 5` | exige `growth: explorer` |
| Chips de XP em missões, receitas, encomendas, obras, rotinas | somem (`reward_chips` ignora `xp`, `player_xp`, `skill_xp`) |
| Prêmio `xp` de rotinas/missões/obras | trocado por `pillars` onde faz sentido (rotinas de cuidado: Coragem 4 ou Pelagem 4; obras: Coragem 5); demais ficam sem efeito visível |
| Feature `skills` (aba Atributos, cap. 6) | feature `growth_tab` (aba Crescimento) liberada com o primeiro crescimento |

Novo tipo de prêmio aceito por `_apply_rewards` e `_grant_automatic`: `"pillars": {"brave": 4}` → passa por
`_gain_pillar`. Como os saves recomeçam, `level`/`xp`/`skills` podem sair do save e do código se isso simplificar
(conferir antes o simulador e os testes que leem esses campos); se ficar mais seguro, só esconder.

## G. Moedas

Os presentes de nível (≈ 410 moedas até o nível 10, depois 20+3n) saem. Entram os presentes de crescimento
(30 + 60 + 100 + 150 + 250 = 590) e as vendas dos produtos novos. Capítulos, encomendas, contratos e obras não
mudam. Risco: o meio do jogo (níveis 5–10 pagavam 30–100 cada) fica um pouco mais curto de moedas; a etapa 17
olha isso **uma vez** no simulador rápido e registra. Não ajustar preços de construções neste plano sem pedido.

## H. O que NÃO muda

Preços e tempos existentes, capacidades, filas, maestria, clientes, contratos, obras, recibos, snapshots.
Trabalhos já iniciados mantêm o que valiam (regra `WorkJobs`).
