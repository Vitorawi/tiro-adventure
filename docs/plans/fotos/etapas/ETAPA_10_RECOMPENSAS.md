# Etapa 10 — Recompensas de coleção

> Tamanho: pequeno. Depende de: 06, 09. Próxima: 11.
> Resultado que o Vitor vê: completar uma seção, juntar as 4 versões de uma foto, chegar a 5/15/30 fotos
> Raras+ e ganhar a primeira Holográfica dão prêmios, com um cartão de festa e o marco visível no álbum.

## 1. Ler antes
`01_DESENHO.md` §7. Código: `GameState._grant_automatic` (recibos em "Presentes para guardar"),
`Celebration` (`scenes/ui/celebration/`, cartões `ModalCard` em madeira), `AlbumSummary` (06), `photo_rolled` (01).

## 2. Como está hoje
Não há prêmio por coleção de fotos.

## 3. Passo a passo
1. Dados: `album.json → cards.rewards` (valores do §7; ajustáveis).
2. `GameState._check_album_rewards()` chamado depois de abrir/rolar/melhorar: paga cada marco uma vez com
   `_grant_automatic("album:section:<seção>" | "album:styles:<foto>" | "album:rare:<n>" | "album:holo:first", ...)`.
3. Sinal `Events.album_milestone(kind, key)` → `Celebration.show_album_milestone` na fila modal (depois da
   revelação, nunca junto): cartão de madeira com a carta/selo e os prêmios.
4. Álbum (06): no `AlbumSummary`, selo de seção completa (medalhão) e, na carta, marca "4/4" quando a coleção
   de versões fecha. Consulta `GameState.album_milestones()` para mostrar o próximo marco ("Mais 2 Raras").

## 4. Não fazer
Itens novos ou mudar a economia fora destes prêmios.

## 5. Armadilhas
O marco pode ser atingido no tutorial: pague normalmente (o tutorial não paga nada sozinho).

## 6. Testes
Novo **`tests/album_rewards_test.gd`** (área `album`):
1. Seção completa paga uma vez (abrir a última carta; repetir não paga de novo).
2. 4 versões de uma foto paga uma vez.
3. Marcos 5/15/30 Raras+ e primeira Holográfica pagam uma vez cada.
4. Itens que não cabem viram recibo ("Presentes para guardar").
5. Cartão de festa entra na fila depois da revelação.
Lista fechada: `album_rewards_test,card_reveal_test,pending_gifts_test,festa_test,album_book_test`.
Capturas `tests/fotos_10_shots.gd`: cartão de seção completa, de 4 versões, de primeira Holográfica.

## 7. Pronto quando
Testes passam, capturas olhadas.
