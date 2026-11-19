# E05. Para crescer e cerimônia

Plano: [`../README.md`](../README.md) (E05) · regras: [`../REGRAS.md`](../REGRAS.md) (D9, D10, seção 5) · lista de requisitos: documento "Tiro filhote: plano da primeira semana", seção "O que precisa para crescer" (lida em 18/11/2026).

## Lista fechada

| Requisito | Recém-chegado → Filhotinho | Filhotinho → Dentinhos |
|---|---|---|
| Dias bem alimentados (`stat well_fed_day`) | 2 | 5 |
| Pratos diferentes comidos na fase (`dishes`) | 4 | 8, de pelo menos 3 tipos (papinha, sopinha, mingau) |
| Prato de 2 estrelas (`dish_stars`) | 1 | — |
| Prato inventado (`invented_dish`) | 1 | — |
| Prato-chave (`dish_key`): ovo, fruta, peixe | — | 1 de cada, só refeição |
| Brincar (`stat play`) | 4 (bolinha) | 8 |
| Cordinha (`stat play_rope`, gancho E09) | — | 1 |
| Atender pelo nome (`stat name_call`, gancho E09) | 1 | — |
| Truques: Senta (`trick_level`, gancho E07) | Aprendeu (nível 1) | Sabe bem (nível 2) + 3 truques aprendidos (`trick_learned`, gancho E07) |
| Item-chave | Caminha (`owned dog_bed`) | Mordedor (`deliver chew_ring`) |

Os momentos de pilar (`moments`) e as refeições `feed` das fases antigas saíram dessas duas listas; as fases seguintes continuam como estavam.

## Arquivos envolvidos

- `game/data/growth.json`: listas das fases `puppy` e `teething`, `hooks`, `key_groups`, `trick_levels`, `week_summary`.
- `game/scripts/state/growth_state.gd`: `phase_dishes` (pratos comidos na fase); `SAVE_VERSION` 24.
- `game/autoload/game_state.gd`: `growth_hook_live`, `trick_level`, `dish_of_item`, `_note_fed_dish`, `_link_key_quests`, `growth_summary`; `growth_info` (esconde gancho desligado, `types_have/types_need`), `_growth_have` com os tipos novos, `feed` e `collect` (ligação com a missão), `grow` (resumo congelado, limpa `phase_dishes`).
- `game/scripts/ui/growth_ui.gd` (`week_icon`, `_week_view`, `_week_hint`) e `task_help.gd` (Como fazer dos requisitos novos; um botão Ir por linha).
- `game/scenes/ui/growth_ceremony/growth_ceremony.gd`: `CeremonySummary` e `CeremonyOpened`.
- Teste novo: `growth_week_test` (áreas `growth`, `dishes`, `suite`). Capturas: `tests/growth_week_shots.gd`.

## Regras

- **Ganchos**: requisito com `hook` só existe enquanto `hooks.<nome>.live` for `true`. Hoje estão desligados `name_call` e `play_rope` (E09) e `trick_sit` e `tricks_three` (E07): o jogo não trava esperando sistema que não existe. A etapa dona liga o gancho e passa a contar o mesmo contador (`name_call`, `play_rope`, `trick:sit`, `trick_learned`). O nível do truque sai de `trick:<id>` (limiares 3, 8 e 15).
- **Prato**: o prato do motor e a receita fixa de mesmos ingredientes têm a mesma chave (`DishRules.key_of`). Conta uma vez por fase, pelo que o Tiro comeu; Gororoba e ração não são prato. Estrela não cria prato novo.
- **8 pratos de 3 tipos**: com 8 pratos mas menos de 3 tipos, o painel mostra 7/8 e a dica "Tipos 2/3".
- **Prato-chave**: só refeição conta (lanche não). Peixe também marca a missão `lais_fish_mash`: comer ou recolher um prato com peixe soma `feed:fish_mash`/`produce:fish_mash` (e a papinha de peixe fixa já é um prato com peixe).
- **Crescer! do dia 2 só no jantar**: sai da conta, sem regra extra: o segundo dia bem alimentado exige as duas refeições na hora; quem fecha a lista antes só vê o botão acender no jantar do dia 2.
- **Cerimônia**: `ceremonies[fase].summary` congela dias, pratos, brincadeiras e truques da fase; a folha mostra "A fase em resumo" e "Abriu: ..." (`unlocks_text` da fase).

## Testes

`growth_week_test`: listas e números; ganchos; dias/pratos/2 estrelas/inventado/brincar; almoço do dia 2 não acende e o jantar acende; 8 pratos de 2 tipos não fecha; prato-chave (lanche não conta); mordedor e Dentinhos; resumo; gancho ligado; recarga do save; ligação com a missão do peixe. Também a área `growth` e `dishes` do `test.ps1 -Level etapa` e o portão M1 (`-Level portao`).

## Pronto quando

Recém-chegado → Filhotinho → Dentinhos funciona com as listas acima e `growth_week_test` passa (Portão M1).
