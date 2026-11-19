# E03. Cozinha completa

Plano: [`../README.md`](../README.md) (E03) · regras: [`../REGRAS.md`](../REGRAS.md) · motor: [`ETAPA_02_motor_de_pratos.md`](ETAPA_02_motor_de_pratos.md).

## Arquivos envolvidos

- `game/autoload/game_state.gd`: pratos conhecidos (`dish_known/dish_stars/recipe_stars/known_dishes/dishes_known_count`), prévia (`dish_preview`), `dish_type_open`, `dish_inputs`, `cook_known_dish(_error)`, `dish_recipe_match`, `cook_invented` só pelo motor, `_note_dish/_note_recipe`.
- `game/scripts/state/week_state.gd` (`dishes` no save) e `autoload/save_manager.gd` (`SAVE_VERSION` 23).
- `game/scripts/state/dish_rules.gd`: `key_of/parse_key/counts_as/key_notes/open_types/slot_count`.
- `game/data/dishes.json` (`key_note` em ovo e peixe, `counts_as` na papinha de peixe), `invent.json` (`carrier`, `plural`), `recipes.json` (`dish_type` nas receitas do fogão que são pratos).
- `game/autoload/database.gd`: receita de suporte `dish_batch` (sem item provisório), `entry_output/entry_seconds`.
- UI: `scripts/ui/cook_panel.gd` (lista, categorias, filtros, selo, estrelas), `cook_invent.gd` (prévia, vagas por dia, tipos trancados), `cook_invent_picker.gd` (só ingredientes já abertos).
- Fila: `cook_panel`, `sheet_builder`, `station_wood`, `station_indicator` e as boas-vindas mostram o item e o tempo do lote (`entry_output/entry_seconds`).

## Regras fechadas

- **Pratos conhecidos** (`week.dishes`): `dish:<tipo>:<ingredientes>` (sem estrelas) é gravado ao COMEÇAR a cozinhar um prato do motor (a Gororoba não conta); `recipe:<receita>` ao preparar uma receita fixa do fogão. Guardam `stars` (melhor, 1 por padrão; E04 sobe), `made` e `day`.
- **Receita fixa equivalente**: combinação igual à de uma receita do fogão do mesmo tipo (`dish_type` em `recipes.json`) cozinha ESSA receita (pedidos e crescimento que contam o item continuam valendo) e não vira prato do motor duplicado.
- **Vagas**: `DishRules.slot_count` = menor entre os espaços do tipo e `max_count(dia)`: papinha tem 2 espaços e o 3º abre no dia 3 (REGRAS: "a 3ª vaga abre no dia 3"; o texto "3ª em Filhotinho" da etapa vale como o dia 3). Tipos abrem por `opens` (Biscoito 2, Sopinha 3, Mingau 4): aparecem com cadeado e o toque avisa "Sopinha abre no dia N". Ingredientes só aparecem na janelinha depois do dia em que abrem.
- **Prévia** (`dish_preview`): `empty`, `incomplete` ("Falta pouco"), `blocked`, `gororoba` (nome só "Gororoba", ícone único, diz o que devolve), `new` ("Prato novo!") e `known`; mostra nome automático, estrelas, nutrientes (Força/Brilho/Foco/Ânimo) e "Conta como prato com ovo/peixe" (só refeições; `key_note` do ingrediente).
- **Pratos**: lista = receitas fixas + pratos do motor descobertos; categorias reais = Todos, um por tipo aberto, Outros; filtros Dá para fazer (dá cozinhar agora), Faltam (liberado e falta ingrediente) e Do Tiro (saída pedida pelo próximo crescimento, ou `counts_as`); selo "Para crescer" nesses cartões; estrelas reais (0 = nunca feito).
- **Sem provisório**: o item `invented_dish` saiu. A fila do fogão usa a receita escondida `dish_batch` só como suporte; item, tempo e estrelas vêm do `job`.
- Cozinhar pelo botão usa 1 estrela; o minigame e as estrelas 2 e 3 são da E04. "Cozinhar junto" da aba Pratos continua "Em breve!".

## Testes

- Novo: `cook_dishes_test` (área `dishes`, `suite`): prévia, ovo/peixe, Gororoba, tipos por dia, ciclo descobrir → cozinhar → recolher → dar ao Tiro, receita fixa, salvar/carregar, categorias, filtros, selo, estrelas, 2/3 vagas, tipos trancados.
- Ajustados: `cook_invent_test`, `cook_panel_test`, `dish_engine_test` (sem mudança de lógica).
- Capturas: `tests/cook_invent_shots.gd` e `tests/cook_panel_shots.gd` (`--out=e03_cook_invent` / `e03_cook_panel`) nas três resoluções.

## Pronto quando

Dá para descobrir um prato novo na aba Inventar, cozinhar, recolher e dar ao Tiro sem nada provisório; filtros e selo funcionam; testes novos PASS.
