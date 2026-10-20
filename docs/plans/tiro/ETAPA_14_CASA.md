# Etapa 14 — A Casa que cresce com ele

**Estado: concluída (19/10/2026): funcionalidade e arte PixelLab validadas.** Evidência em [VALIDACAO_14](VALIDACAO_14.md). Executar somente esta etapa. Pré-requisito: etapa 13 concluída.

## Objetivo

"Na parede da Casa tem uma régua com um risquinho para cada fase do Tiro. Numa prateleira estão a caixinha
da chegada, a argolinha, o mordedor, a escova e a medalhinha. A caminha melhora conforme ele cresce, e eu
penduro minhas fotos preferidas."

## Leitura obrigatória

[05](05_ALBUM_E_CASA.md) F, G; [07](07_SAVES_E_ESTADO.md) C, F; `rooms/house.json`, `room.gd` (objetos com
`requirements`, `upgrade`, toque), `dog_world.gd` (onde dorme: `room.gd:556`), `pet_backdrop.gd`,
`progression.json → upgrades` (`dog_bed`, `sofa`), `config.json → needs` (energia dormindo), `absence` (ausência).

## Entrega e implementação

1. Objetos da 05 G em `rooms/house.json` (e `progression.json` quando forem compras): `arrival_box`,
   `height_chart`, `memory_shelf`, `photo_wall`, `laundry_basket`, `toy_basket`, `named_bowl`, `bed_soft`,
   `bed_luxe` e os prêmios do álbum (`paw_rug`, `old_camera`, `gold_frame`, `star_garland`, `big_portrait`).
   Cada um só aparece quando chega (requisito de objeto de sala).
2. **Régua:** risquinhos desenhados em código (altura proporcional ao peso/fase, nome e data); tocar abre o
   painel de crescimento. Também uma régua pequena no cantinho do Tiro.
3. **Prateleira:** mostra a caixinha + os itens-chave **entregues**; tocar num item abre a foto ligada (se houver).
4. **Caminha:** `arrival_box` até `lais_bed`; depois caminha → macia → luxo (troca de desenho pelo nível, sem novo
   objeto). Bônus de energia dormindo +10%/+20% aplicado no `DogState` (também na ausência protegida, sem passar
   os pisos/tetos já existentes).
5. **Tigela com nome:** +10% nos pilares de comidas de crescimento.
6. **Cesto de brinquedos:** `give_toy_error/give_toy` (03 D) para `braided_toy` e `lost_ball`; +1 Esperteza por
   brinquedo diferente ao brincar (máx +3). Item `toy: true` mostra "Dar ao Tiro" no detalhe da Mochila.
7. **Parede de fotos** (6 fotos): escolher até 3 fotos (`HangButton` no detalhe da foto). Moldura dourada (18):
   escolher a foto principal do cantinho. Câmera antiga (12): +1 lupa por dia (a lupa entra na 15; aqui só o
   objeto e o dado).
8. Cesto de roupa e cesto de brinquedos chegam como presentes de Dentinhos/Aventureiro (02 F).
9. Cantinho do Tiro: no máximo 3 enfeites por cima do cenário (tapete, foto principal, cesto de brinquedos),
   sem cobrir o Tiro nem os anéis.
10. Arte: todos os objetos no estilo dos móveis da Casa (PixelLab com referência `areas/house/`), prompts no
    ART_PIPELINE. Caminhas em 3 desenhos. `big_portrait` = retrato do Tiro adulto em moldura (usar a arte atual).

## Teste da etapa — `house_test.gd` (novo, ≤ 3 min)

Cada objeto aparece só quando chega; régua com um risquinho por cerimônia; prateleira só com itens entregues; bônus da caminha na energia dormindo (online e ausência) sem passar
os limites; tigela +10%; `give_toy` move o item e o bônus para em +3; parede/foto principal salvam a escolha;
prêmios do álbum entregues uma vez ao atingir 6/12/18/30/45; o chão continua navegável (footprints).

Rodar também: `world_life_test`, `world_view_test`, `navigation_test`, `pet_care_test`, `absence_test`,
`texts_test`, `album_test`, `lists_test`.

Capturas 360×780: Casa no começo, no meio e no fim (DEV), `t11_house_shelf`, cantinho com enfeites.

## Para passar para a próxima

- [x] A Casa conta a história dele só com objetos (capturas finais abertas lado a lado).
- [x] Teste novo e afetados funcionais PASS; `ui_style_test` mantém apenas a falha histórica no encerramento.
- [x] Produção/revisão da arte no PixelLab: 13 fontes geradas após o serviço voltar; ver VALIDACAO_14.

## Fora desta etapa

Fotos secretas e dicas (15), jeito (16).

## Evidência e passagem de bastão

`build/test_logs/tiro14/`, capturas. README, ROADMAP, PROGRESSION, ART_PIPELINE, `CLAUDE.md`/`AGENTS.md` (linha
"Novo móvel / mudar layout da casa" e objetos novos). Sem push.
