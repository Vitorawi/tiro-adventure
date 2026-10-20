# Etapa 10 — Itens-chave e entregas

**Estado: concluída em 19/10/2026** (ver [VALIDACAO_10](VALIDACAO_10.md)). Pré-requisito: etapa 09 concluída.

## Objetivo

"Para o Tiro virar Dentinhos, a vovó costura uma argolinha; para Aventureiro, eu faço um mordedor de graveto
na bancada; para Mocinho, uma escova macia; para adulto, a medalhinha de coragem e o lacinho do topete."
Eu entrego no painel com "Dar" e o item vira lembrança.

## Leitura obrigatória

[03](03_COMIDAS_E_ECONOMIA.md) C (itens sem receita, categorias); [02](02_FASES_E_PILARES.md) C; [04](04_HISTORIA.md)
C (cap. 3 e 12, só a parte de `bloblo_chew_ring` e `community_12_memory`); `quests.json` (linha da vovó),
`collections.json` + `overlay_anchors.json` (roupa nova), `inventory_list.gd`.

## Entrega e implementação

1. Categoria `keepsake` (sem depósito, não vende, não some antes de entregar) e os itens `chew_ring`,
   `stick_chew`, `soft_brush`, `courage_medal`; receitas `stick_chew` e `soft_brush` (bancada) da 03 C.
2. Missão da vovó **`bloblo_chew_ring`** (linha `bloblo`, ordem 62, requisito `first_kitchen`): entregar
   cenoura 3 + batata 1 → `chew_ring` + 10 moedas, com fala da 04 C.
3. `community_12_memory`: prêmio passa a incluir `courage_medal`.
4. Roupa `topknot_bow` "Lacinho do topete" (cabeça) com receita de costura (tecido 1 + fita 2; requisito
   `growth: young`), overlay para os corpos `adult` e `young` (arte derivada do `yellow_bow` em vermelho, no
   alto da cabeça; conferir nas poses com prancha).
5. `growth.json` final dos itens-chave e extras: Dentinhos `deliver chew_ring`; Aventureiro `deliver stick_chew`;
   Mocinho `deliver soft_brush`; Azul e Dourado `deliver courage_medal` + `collection topknot_bow`. A 🍲 do adulto
   fica `feed any (comida com growth) ×3` até a etapa 12 trocar pela favorita.
6. Painel: "Dar" com o ícone voando até o Tiro (`fly_icon`), `Haptics.tap`; entregue = ✓ e o item some da
   Mochila. Entregas gravadas como lembranças (`growth.delivered`) para a prateleira da etapa 14.
7. Mochila: filtro/selo "Para o Tiro" nos `keepsake` (botão Ir abre o painel de crescimento).

## Teste da etapa — `keys_test.gd` (novo, ≤ 3 min)

Receitas dos itens-chave; missão da vovó entrega a argolinha uma vez; "Dar" parcial/definitivo e erro sem o
item; crescer exige o item-chave; `keepsake` não vende e não ocupa depósito; medalhinha pela missão (uma vez); lacinho costurado vira roupa e aparece no corpo jovem e adulto.

Rodar também: `content_test`, `npc_lines_test`*, `festival_test`, `petshop_test`, `lists_test`, `growth_test`,
`growth_ui_test`, `texts_test`.

Toque real: entregar um item-chave pelo painel.

## Para passar para a próxima

- [x] As 5 fases têm requisitos finais (exceto a favorita) e todos são alcançáveis por ações do jogo
      (conferir com um save novo usando DEV só para pular tempo, não para dar item).
- [x] Afetados PASS (históricos: `npc_lines_test`, `petshop_test`).

## Fora desta etapa

Missões principais novas (11), favorita (12), prateleira na Casa (14).

## Evidência e passagem de bastão

`build/test_logs/tiro10/`, prancha do lacinho. README, ROADMAP, PROGRESSION, ART_PIPELINE. Sem push.
