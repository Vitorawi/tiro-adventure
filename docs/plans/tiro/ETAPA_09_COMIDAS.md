# Etapa 09 — Comidas de crescimento e banho com xampu

**Estado: concluída em 19/10/2026 (Codex, local).** Executar somente esta etapa. Pré-requisito: etapa 08 concluída (portão aprovado).

## Objetivo

"Cada estação da fazenda faz alguma coisa para o Tiro crescer: cenoura gelada para os dentinhos, ração de
crescimento com ovo, mingau com leite e farinha, xampu de ervas para o pelo." Na guia de comida, as comidas
boas para a fase dele têm um selinho.

## Leitura obrigatória

[03](03_COMIDAS_E_ECONOMIA.md) A, B, C, D (xampu); [02](02_FASES_E_PILARES.md) C; `items.json`, `recipes.json`,
`config.json → stations`, `pet_care_tray.gd` (guia de comida e banho), `sheet_builder.gd` (`give_food`),
`game_manual.gd`, `database.gd` (`item_sources`).

## Entrega e implementação

1. Itens e receitas de **comida** da 03 C: `frozen_carrot`, `puppy_mash`, `corn_crunch`, `growth_kibble`,
   `egg_scramble`, `cheese_bites`, `milk_porridge` e o `herb_shampoo` (categoria `care`). Com `feed`, `growth`,
   `storage`, preço de venda, requisitos e `player_xp` 0. (`birthday_cake` fica para a 15.)
2. Ícones 32 px (PixelLab, estilo dos ícones de comida existentes; prompts no ART_PIPELINE).
3. `bathe(use_shampoo := false)`: com xampu consome 1, Pelagem 12 em vez de 3, conta `shampoo_bath`.
   Bandeja do Tiro: quando houver xampu, chip `ShampooToggle` "Com xampu" sobre o banho (lembra a escolha na sessão).
4. Guia de comida: selo do pilar principal nas comidas **adequadas** à fase; nas outras, dica curta ao segurar
   ("Ele prefere outra coisa agora"). Nada bloqueia.
5. `growth.json`: trocar a 🍲 provisória pela final — Dentinhos `frozen_carrot ×3`, Aventureiro
   `growth_kibble ×3`, Mocinho `milk_porridge ×3` e o 🌿 do Mocinho "2 banhos com xampu" (`stat shampoo_bath`).
   Os itens-chave continuam provisórios (10). Saves no meio de uma fase: requisito novo começa a contar da troca
   (registrar em DECISOES).
6. Manual e "Como fazer" mostram as receitas novas (automático pelo `Database`; conferir).

## Teste da etapa — `growth_foods_test.gd` (novo, ≤ 3 min)

Cada receita nova cozinha, rende e vai para a geladeira; ganho de pilar ×1 na fase certa e ×0,5 fora; dar a
refeição da fase conta no requisito só durante a fase; banho com xampu consome, dá 12 e respeita a recarga;
sem xampu o banho continua igual ao de antes; requisitos de receita (galinheiro, curral + moinho, estufa) travam
com o motivo certo; venda com o preço da 03 C.

Rodar também: `content_test`, `products_test`, `station_tray_test`, `fridge_test`, `pet_care_test`,
`texts_test`, `manual_test`, `growth_test`.

Capturas 360×780: guia de comida com selos; bandeja com "Com xampu".

## Para passar para a próxima

- [x] Toda estação produtora (fogão, liquidificador, galinheiro, curral, moinho, queijaria, estufa) tem pelo
      menos um produto que o Tiro usa (tabela no registro).
- [x] Afetados PASS; capturas abertas.

## Fora desta etapa

Itens-chave (10), missões (11), paladar e favorita (12), bolo (15).

## Evidência e passagem de bastão

`build/test_logs/tiro09/`. README, ROADMAP, PROGRESSION, ART_PIPELINE. Sem push.

Validação, tabela por estação e ressalvas: [VALIDACAO_09](VALIDACAO_09.md).
