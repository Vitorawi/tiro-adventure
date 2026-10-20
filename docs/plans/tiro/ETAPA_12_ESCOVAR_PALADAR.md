# Etapa 12 — Escovar e paladar

**Estado: concluída (19/10/2026).** Executar somente esta etapa. Pré-requisito: etapa 11 concluída (portão aprovado).

## Objetivo

"Quando ele vira Dentinhos, a Laís me dá uma escovinha: passo o dedo pelas costas dele, os nós somem e o pelo
brilha. E cada comida nova ele prova de um jeito — tem uma que ele ama de paixão, e eu descubro qual é."

## Leitura obrigatória

[02](02_FASES_E_PILARES.md) D (escovar); [03](03_COMIDAS_E_ECONOMIA.md) D, E; [06](06_INTERFACE_E_ARTE.md) A, H;
`pet_care_tray.gd`, `drag_ghost.gd`, `pet_screen.gd` (carinho por passadas, esponja), `pet_animator.gd`
(reações), `pet_notebook.gd`.

## Entrega e implementação

1. **Escova:** `basic_brush` (keepsake/ferramenta) no presente de Dentinhos. `brush_error/brush`: Pelagem 5 (8 se `soft_brush` foi entregue), recarga 4 h, grava o dia
   em `brush_days`, conta `brush`.
2. Bandeja de cuidados com **5** cuidados iguais (`UiKit.action_tile`): Comida, Banho, **Escovar**
   (`BrushTile`, ícone `action_brush`), Brincar, Dormir. Escovar só aparece com a escova. Gesto: arrastar a
   escova sobre as costas do Tiro; nós (partículas) somem a cada ~200 px; ~600 px = uma escovação. Em recarga:
   escovar continua animando, sem ganho, com "Ele já está penteadinho".
3. **Paladar:** `growth.tastes` e `growth.favorite` (03 E). Primeira prova de cada item: reação no
   `PetAnimator` (amou/gostou/estranhou/careta) + `Events.taste_discovered`. Favorita: +50% nos pilares e a
   dancinha sempre. Mirtilo cru = careta.
4. Guia de comida: ♥ na favorita (depois de descoberta), "Nova!" nas não provadas.
5. Caderninho, aba Crescimento: seção **Guia de sabores** (grade de ícones: provadas com a carinha da reação;
   não provadas em silhueta; ♥ na favorita).
6. `growth.json`: 🍲 do Azul e Dourado = `feed favorite ×3`; sem favorita descoberta, o chip diz "Descubra a
   favorita" e o "Como fazer" lista comidas ainda não provadas que ele pode comer.
7. Favorita sorteada quando o save nasce (semente do save).

## Teste da etapa — `brush_taste_test.gd` (novo, ≤ 3 min)

Escovar por arrasto simulado chama `brush` uma vez a cada ~600 px; recarga; escova macia dá 8; dias distintos;
sem escova não há `BrushTile`; reações fixas pela semente; favorita só entre as do `favorite_pool` alcançáveis;
favorita dá +50%; requisito da favorita mostra "Descubra a favorita" e depois conta; recarregar não repete reação.

Rodar também: `pet_care_test`, `manual_test`, `texts_test` (verbo **Escovar**), `wishes_test`, `growth_test`,
`growth_foods_test`.

Toque real: escovar. Capturas 360×780: `t07_brush`, `t08_tastes`.

## Para passar para a próxima

- [x] Cinco cuidados alinhados e do mesmo tamanho nas três resoluções (captura de conferência só desta bandeja).
- [x] Afetados PASS.

## Fora desta etapa

Fotos (13–15), Pelagem de seda (17).

## Evidência e passagem de bastão

`build/test_logs/tiro12/`, capturas. README, ROADMAP, PROGRESSION, ART_PIPELINE (`action_brush`), `CLAUDE.md`/
`AGENTS.md` (linha "Tela do Tiro / cuidados"). Sem push.
