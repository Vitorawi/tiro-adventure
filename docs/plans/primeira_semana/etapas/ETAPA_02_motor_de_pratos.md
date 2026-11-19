# E02. Motor de pratos

Plano: [`../README.md`](../README.md) (E02) · regras: [`../REGRAS.md`](../REGRAS.md). Fontes usadas: "Alimentação do Tiro: design completo" (vale), o plano da semana e a planilha "Catálogo de pratos do filhote" (538 combinações).

## Regras do motor (conferidas contra a planilha)

- **13 ingredientes** (categoria, sabor, Força/Brilho/Foco/Ânimo, dia em que abre), na ordem canônica: cenoura, batata, abóbora, abobrinha, batata-doce, aveia, milho, arroz, ovo, peixe, maçã, banana, melancia. A ordem importa para o **nome** ("Papinha de cenoura, ovo e peixe").
- **5 tipos** e suas vagas (o mesmo ingrediente pode repetir; a ordem não muda o prato):

| Tipo | Ingredientes | Abre | Refeição |
|---|---|---|---|
| Papinha | 2 ou 3; pelo menos 1 legume; sem fruta (a 3ª vaga abre no dia 3) | 1 | sim |
| Petisco | 1 ou 2 quaisquer | 1 | não (lanche) |
| Biscoito | 2; pelo menos 1 grão | 2 | não (lanche) |
| Sopinha | 3; pelo menos 2 legumes; sem fruta | 3 | sim |
| Mingau | 2 ou 3; pelo menos 1 grão e 1 fruta; o 3º é grão, fruta, abóbora ou batata-doce | 4 | sim |

- **Gororoba** = combinação que não forma o prato do tipo (fruta na sopinha, peixe no mingau): enche a barriga, não conta como prato diferente, tem um ícone só e **devolve 1 ingrediente** (o que quebrou a regra).
- **Cálculo** (confere linha a linha com a planilha): soma dos ingredientes → bônus fixos do tipo (+1 Ânimo na sopinha e no mingau) → duplas (+1 cada) → **um** multiplicador único (maciça ×1,2 da papinha em Recém-chegado/Filhotinho × preparo 1 / 1,2 / 1,4 por estrela), arredondado uma vez.
- **Totais acumulados por dia**: 23 · 53 · 308 · 497 · 538. Refeições 398, lanches 140.
- **Nome**: tipo + ingredientes diferentes na ordem canônica ("Papinha de abóbora e peixe"); ~25 pratos têm nome e ícone próprios (`dishes.json → named`), as 4 secretas inclusive.

## Identificador de prato dinâmico

O inventário só conhecia itens fixos de `items.json`. Um prato é descrito por **tipo + ingredientes + estrelas** e vira o item `dish_<tipo>_<ing+ing+ing>_<estrelas>` (ex.: `dish_papinha_cenoura+ovo_2`), só com `[a-z0-9_+]` (nomes de nó e chaves de contador continuam válidos).

- `DishRules` (`scripts/state/dish_rules.gd`): funções puras (criar/ler o id, avaliar, nutrientes, nome, sabor, duplas, combinações por dia).
- `Database.ensure_dish(id)` **registra** o item em `Database.items` (nome, categoria `food`, depósito geladeira, ícone, preço, `feed`, `growth`, `treat` se for lanche). Assim venda, depósito, Mochila, alimentação e contadores funcionam sem mudar nada neles.
- Quem deixa um prato entrar chama o registro: `Inventory.add`/`from_dict`, o cozinhar do `GameState` e o carregar (lotes na fila).

## Passo a passo

1. `dishes.json` (ingredientes, tipos, duplas, estrelas, nomeados, gororoba) e `DishRules`.
2. `Database`: carregar, `ensure_dish`, `dish_problems`; itens novos (abobrinha, aveia, arroz, banana, melancia, gororoba) com ícones provisórios tingidos.
3. `Inventory` registra pratos.
4. `GameState`: `dish_info/dish_error/cook_dish/dish_refund`, `is_meal_item` pelo motor, `dev_give_ingredients`.
5. `invent.json` definitivo (tipos de espaço, ingredientes por item, recomendados, os 5 tipos) e a aba Inventar passando o tipo para `cook_invented`.
6. Teste `dish_engine_test`; registrar em `tools/test_areas.json`.
7. Capturas da aba Inventar nas três resoluções; docs.

## Testes

`dish_engine_test` (novo, área `dishes`) + `cook_invent_test`, `growth_meals_test`, `day_clock_test`, `meal_ui_test` e `economy_transactions_test`.

## Pronto quando

`dish_engine_test` reproduz 23/53/308/497/538 e a linha a linha da planilha, e um prato dinâmico é guardado (depósito), vendido e dado ao Tiro, inclusive depois de salvar e carregar.

## Fora desta etapa

Pratos conhecidos/estrelas reais nos cartões e filtros (E03), minigame (E04), requisitos de crescimento por tipo (E05), paladar por sabor e livro (E11).
