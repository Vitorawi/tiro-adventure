# Etapa 13 — validação (19/10/2026, Claude Code)

Etapa 12 confirmada em VALIDACAO_12.md. Sem commit, push, publicação ou reset.

## O jogador encontra

No caderninho aparece a aba **Álbum** assim que existe a primeira foto (a da chegada, ao fim da apresentação da Laís). As fotos saem sozinhas, pelas ações do jogo: chegada, primeira noite, cada crescimento, a papinha, o primeiro passeio, a primeira pata, a banca, o banco, a medalhinha, o Guardião; e as primeiras vezes (banho, papinha, achado, dentinho de leite, amigo, roupa, achado raro de passeio, escovada). Cada uma mostra o aviso "Nova foto!" (tocar abre a foto), o selo Novo no caderninho e uma linha nas boas-vindas. A grade tem 3 colunas, contador (hoje X/22) e abas História / Primeiras vezes; foto que falta é silhueta cinza com o título. O detalhe é a polaroide grande (moldura, cenário, o Tiro **no corpo e no pelo do dia**, adereço), título, data, fase e, no adulto, a foto da chegada ao lado. A caderneta do painel de crescimento mostra a foto da cerimônia. O primeiro montinho a partir de Dentinhos garante o **Dentinho de leite**.

## Arquivo mudado → teste → resultado

| Área | Teste | Resultado |
|---|---|---|
| `album.json`, `AlbumState`/`AlbumRules`, `_album_event`, `PhotoCard`, `AlbumView`, dentinho, DEV | `album_test` (novo, ~12 s) | PASS |
| dado e catálogo | `content_test` (agora também `album_problems`) | PASS |
| `finds`/Manual | `manual_test` (fonte do dentinho), `finds_test` | `manual_test` PASS; `finds_test` FALHA HISTÓRICA ("Faro: missão pronta", 1º check, não investigada) |
| `pet_notebook.gd` (aba nova) | `pet_care_test` (esperava 4 abas, agora 5), `lists_test`, `growth_ui_test` | PASS |
| `main.gd`, boas-vindas | `welcome_test`, `festa_test`, `hud_test`, `ceremony_test` (fila própria de fotos: continua uma cerimônia por evento) | PASS |
| estado/ações/save | `growth_test`, `growth_visual_test`, `growth_story_test`, `keys_test`, `brush_taste_test`, `saves_test`, `hud_growth_test`, `tasks_test`, `journey_test`, `wishes_test`, `dev_tools_test` e `dev_tools_test_prod` | PASS |
| textos | `texts_test` | PASS |

Logs em `build/test_logs/tiro13/` (`run1.log` = primeira rodada, `run2.log` = reexecução dos que quebraram por mudança esperada). Capturas 360×780 em `build/screenshots/tiro13_360x780/`: `t09_album_grid`, `t09_album_firsts`, `t09_notebook_tabs` (5 abas cabem), `t10_photo_detail`, `t10_photo_detail_kitchen` e a folha de contato `t09_album_contact_1/2` com as 20 polaroides; todas abertas e conferidas. Sem suíte inteira, sem simulação de economia, sem `progression_test` (a etapa não mexe na ordem da história), sem toque real no aparelho (só toque, sem gesto novo; o aviso tocável e as tiles foram exercitados por código).

## Limites

- Só as seções História e Primeiras vezes estão ativas; as 32 fotos das outras quatro existem no `album.json` (validadas), mas sem gatilho ligado. Dicas, lupa, "Pendurar", datas e recompensas por quantidade ficam para a 14/15.
- `f_rare` e `h_guardian` são testados pelo evento (o raro de passeio e o fim do último capítulo exigem fixtures longas); os demais, pela ação real.
- Os recortes de cenário são dos mapas atuais; o Tiro em tamanho grande por cima do mapa isométrico é uma escolha visual simples, sem arte exclusiva.
- Arte pequena gerada por código (grades 16×16 ampliadas), não pelo PixelLab; nenhum PNG do Tiro foi criado ou alterado.
- 390×844 e 412×915 não foram capturadas (só nos portões e na 06).
