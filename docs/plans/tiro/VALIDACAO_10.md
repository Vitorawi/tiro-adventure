# Etapa 10 — validação (19/10/2026, Claude Code)

Etapa 09 confirmada concluída em VALIDACAO_09.md; portão 08 com ressalvas históricas, suíte não repetida. Sem commit, push, publicação ou reset.

## O jogador encontra

- Vovó Bloblo pede 3 cenouras + 1 batata (missão `bloblo_chew_ring`, após `first_kitchen` e o ensopado) e entrega a **Argolinha de morder** + 10 moedas.
- Bancada: **Mordedor de graveto** (graveto 3 + madeira 1) e **Escova macia** (tábua 1 + fibra 2, depois de `main_8_fiber`). Festa da turma (`community_12_memory`): **Medalhinha de coragem**. Costura (Mocinho): **Lacinho do topete** vermelho (tecido 1 + fita 2), que veste na cabeça do jovem e do adulto.
- Cada crescimento (Dentinhos, Aventureiro, Mocinho, Azul e Dourado) pede o item-chave; o adulto pede também o lacinho e 3 refeições (a favorita chega na 12). "Dar" no cartão do requisito ou no detalhe da Mochila: o ícone voa até o Tiro, o item some e vira lembrança em `growth.delivered`. Mochila ganhou o filtro "Para o Tiro" e o botão Ir.

## Arquivo mudado → teste rodado → resultado

| Área | Teste | Resultado |
|---|---|---|
| items/recipes/collections/quests/growth.json, ícones, overlays | `keys_test` (novo, 6 s) | PASS: categoria/depósito/venda, receitas, missão da vovó uma vez, Dar parcial/definitivo/erro, crescer exige o item, medalhinha uma vez, lacinho costurado→roupa, overlay adulto/jovem, alcançabilidade dos insumos, filtro e Ir |
| mesmas áreas | `content_test`, `products_test`, `station_tray_test`, `growth_foods_test`, `journey_test`, `tasks_test`, `pillars_test`, `ceremony_test`, `growth_visual_test` | PASS |
| `growth_ui.gd`, `sheet_builder.gd`, `inventory_list.gd` | `growth_ui_test`, `lists_test`, `sheet_test`, `manual_test`, `texts_test` | PASS |
| prêmio da lembrança, requisito do adulto | `festival_test`, `growth_test` | PASS depois do ajuste de fixture (DECISOES) |
| — | `npc_lines_test` | FALHA HISTÓRICA reproduzida uma vez (`Recebe etapa da venda`, `Recolher conclui passo do Guia`, `Feirante persiste`), não investigada |
| — | `petshop_test` | histórico: `SCRIPT ERROR ... 'rare'` na linha 130 (passeio no teste), imprime PASS e o runner reprova; reproduzido, fora da área |

Tempo dos testes ≈ 6 min. Nenhuma simulação de economia, `progression_test` ou suíte inteira (não é portão). Logs em `build/test_logs/tiro10_last_run.csv`.

## Capturas e toque

360×780 em `build/screenshots/tiro10_depois/`, todas abertas: `mochila_para_o_tiro`, `detalhe_argolinha` (Dar + Ir), `painel_antes` (cartão com Dar), `painel_voando`, `painel_depois` (✓ e Crescer!). Prancha do lacinho `build/art/tiro10/lacinho.png` (adulto e jovem, cinco poses): lacinho no alto da cabeça em todas. `tests/keys_shots.gd` entrega pelo toque (eventos de mouse reais no viewport do Godot) e confere consumo, ícone voando e Crescer. Sem navegador móvel (`touch_test.ps1`) nem aparelho físico.

## Limites

Ritmo/economia dos itens novos não medidos (por regra). Robô do simulador ainda não entrega itens-chave (etapa 11). Saves v13 em andamento: quem está no meio do Dentinhos precisa da argolinha (a missão da vovó a fornece); fases já alcançadas não mudam. Nenhum PNG do Tiro, canvas ou apoio alterado.

**Encadeamento da 10 (19/10/2026):** `create_session` (claude-code-remote) criou "Tiro — Etapa 11" (`session_019LuSJdPgh5DjXc4qXEu2gy`, ambiente herdado, status pendente; o registro da ferramenta marca "no-git-repo"/"disconnected"). Confirmar que ela abriu na pasta do projeto ClaudeGame; se não, abrir à mão com o bloco "Como passar" e `ETAPA_11_HISTORIA.md`. Etapa 11 não iniciada aqui.
