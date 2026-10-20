# Etapa 13 — Álbum: motor e fotos garantidas

**Estado: concluída (19/10/2026).** Evidência em [VALIDACAO_13](VALIDACAO_13.md). Pré-requisito: etapa 12 concluída.

## Objetivo

"No caderninho tem um álbum de polaroides da vida do Tiro: a chegada na caixinha, a primeira noite, cada vez que
ele cresceu, o primeiro banho, o dentinho de leite que o faro achou..." As fotos aparecem sozinhas e eu vejo
"📸 Nova foto!".

## Leitura obrigatória

[05](05_ALBUM_E_CASA.md) A, B, C (História e Primeiras vezes), E; [06](06_INTERFACE_E_ARTE.md) G; [07](07_SAVES_E_ESTADO.md) B;
`finds.json` (`quest_find`/garantidos), `pet_notebook.gd`, `welcome_back.gd`, `main.gd` (aviso).

## Entrega e implementação

1. `game/data/album.json` com **as 54 entradas** (05 C) e `Database.album` + validação (eventos e condições
   conhecidos, adereços existentes). Nesta etapa só as seções **História** e **Primeiras vezes** ficam ativas
   (`active_sections` no dado); as outras não aparecem.
2. `AlbumState` (chave `album`) e `GameState._album_event(evento, contexto)` chamado pelas ações que geram os
   eventos dessas duas seções. Foto tirada uma vez; `Events.photo_taken`.
3. Achado `milk_tooth` (Dentinho de leite) garantido no primeiro montinho da fase Dentinhos (`finds.json`).
4. `PhotoCard` (`scripts/ui/photo_card.gd`): moldura polaroide + recorte do cenário + quadro do Tiro no corpo/
   coat gravados na foto + adereços + legenda e data.
5. Caderninho: aba **Álbum** (`AlbumView`, 06 G) com as seções ativas, contador, detalhe `PhotoDetail`.
   A caderneta do painel de crescimento passa a usar a foto oficial da cerimônia.
6. Aviso "📸 Nova foto!" (toque abre a foto), selo Novo no caderninho, linha `Line_photo` nas boas-vindas.
7. Arte: moldura polaroide (9-patch), adereços `box`, `bowl`, `stall_sign`, `medal`, ícone `milk_tooth`, ícones
   das seções. Fotos `h_*` das cerimônias usam o cantinho + pose.
8. Contador de fotos gravado (as recompensas por quantidade entram na 14).

## Teste da etapa — `album_test.gd` (novo, ≤ 3 min)

Cada foto de História e Primeiras vezes sai pela ação real certa e uma vez só (recarregando também); a foto
guarda a fase e mostra o corpo daquela fase mesmo depois de ele crescer; dentinho de leite garantido na fase certa; `album.json` com condição desconhecida é
rejeitado; seções inativas não aparecem.

Rodar também: `finds_test`*, `welcome_test`, `manual_test`, `festa_test`, `lists_test`, `texts_test`,
`ceremony_test`.

Capturas 360×780: `t09_album_grid`, `t10_photo_detail`.

## Para passar para a próxima

- [ ] Um save novo jogado pelo DEV do início ao Aventureiro junta as fotos esperadas.
- [ ] Afetados PASS; capturas abertas.

## Fora desta etapa

Seções secretas/sono/amigos/datas e dicas (15), objetos da Casa (14).

## Evidência e passagem de bastão

`build/test_logs/tiro13/`. README, ROADMAP, PROGRESSION ("Álbum"), ART_PIPELINE, `CLAUDE.md`/`AGENTS.md` (linha
nova "Álbum de recordações"). Sem push.
