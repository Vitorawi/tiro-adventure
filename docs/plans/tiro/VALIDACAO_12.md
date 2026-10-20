# Etapa 12 — validação (19/10/2026, Claude Code)

Etapa 11 confirmada em VALIDACAO_11.md. Sem commit, push, publicação ou reset.

## O jogador encontra

Ao virar Dentinhos o Tiro ganha a escovinha; aparece o quinto cuidado **Escovar** entre Banho e Brincar. Arrasta-se a escova nas costas (~600 px): nós somem a cada ~200 px, Pelagem 5 (8 com a escova macia), recarga de 4 h ("Ele já está penteadinho"). Cada comida nova tem reação na primeira prova (amou/gostou/estranhou/careta); uma favorita por save dá +50% e dancinha. A guia de comida mostra ♥ na favorita e "Nova!" nas não provadas; a aba Crescimento ganhou o Guia de sabores (provadas com carinha, não provadas em silhueta). O Azul e Dourado pede a favorita ×3 ("Descubra a favorita" até ela ser provada).

## Arquivo mudado → teste → resultado

| Área | Teste | Resultado |
|---|---|---|
| estado, `growth.json`, cuidados, guia | `brush_taste_test` (novo) | PASS |
| mesmas áreas | `pet_care_test`, `manual_test`, `texts_test`, `wishes_test`, `growth_test`, `growth_foods_test`, `pillars_test`, `content_test`, `growth_story_test`, `growth_ui_test`, `keys_test`, `ceremony_test`, `hud_growth_test`, `dev_tools_test`, `saves_test`, `growth_visual_test`, `tasks_test`, `journey_test` | PASS (fixtures de `growth_foods_test`/`pillars_test` evitam a favorita; Manual ganhou a fonte "Presente do Tiro") |
| robôs com `favorite` | `economy_sim_test` (fixture do Azul e Dourado agora dá a favorita), `progression_test` (970 s, 109/109), `lists_test`, `hud_test`, `petshop_test`, `festa_test`, `welcome_test` | PASS |
| históricos reproduzidos | `ui_style_test` (resources in use ao sair), `onboarding_test` (primeiro raro e ocioso 670 s > 240 s, como na linha de base: 730 s) | FALHA HISTÓRICA, não investigada |

Logs em `build/test_logs/tiro12/`. Capturas 360×780, 390×844 e 412×915 em `build/screenshots/tiro12_*` (`t07_care_tray`, `t07_brush`, `t07_food_guide`, `t08_tastes`; as de 360 abertas). Cinco círculos 56×56 na mesma linha nas três resoluções (asserts do teste novo). Toque real: gesto emulado por `gui_input` no Godot (mesmo caminho do celular); sem aparelho físico.

## Limites

Os nós do pelo são marcadores simples (sem arte). Reações usam clipes existentes do Tiro; nenhum PNG do Tiro foi alterado. Ritmo e calibração ficam para a 17.
