# Etapa 07 — Pistas claras

> Tamanho: médio. Depende de: 06. Próxima: 08.
> Resultado que o Vitor vê: cada foto que falta diz o que fazer em uma linha, com o ícone da ação, progresso
> quando der ("Passeie 5 vezes · 3/5") e botão Ir. As secretas começam com a pista poética e a lupa revela
> a pista clara. O "Quase lá" do álbum mostra as que estão mais perto.

## 1. Ler antes
`01_DESENHO.md` §2, §4. Dados: `album.json → photos[].on/when/hint/icons/hint_npc/hint_talk`. Código:
`scripts/state/album_rules.gd` (`EVENTS`, `CONDITIONS`, `matches/holds`), `GameState.reveal_photo_hint`,
`album_lupas_left`, `album_talk`, `AlbumView.secret_detail`, `Places.go`, `TaskHelp`.

## 2. Como está hoje
21 das 54 fotos têm `hint` (frases poéticas), só travessuras/soninhos usam lupa (1 por dia, +1 com
`old_camera`); o resto não diz nada. Sem progresso, sem Ir.

## 3. Passo a passo
1. **Dados**: em cada uma das 54 fotos, campo `goal_hint`: `{"text": "...", "icon": "<ícone>", "go":
   {destino como em quests.go}, "progress": {"stat": "<contador>", "target": N}}` (`progress` e `go`
   opcionais). Escreva o texto concreto a partir de `on`/`when` (ex.: `on: bathe` + `when.hours [18,24]` →
   "Dê banho no Tiro à noite"). Frases curtas, verbos do glossário (Colher, Pegar, Cozinhar, Fazer, Buscar, Ir).
   Fotos da História: texto que aponta para o capítulo ("Siga a história com a Laís").
2. **Secretas** (as que hoje usam lupa e as `secret`): continuam com o `hint` poético visível; a lupa passa a
   revelar o `goal_hint`. A regra da lupa (1 por dia, +1 câmera) não muda.
3. **Consulta** `GameState.photo_hint(id) -> Dictionary` (`text`, `icon`, `have`, `need`, `go`, `revealed`):
   o progresso vem de `progress.stat` quando houver `progress`.
4. **`GameState.near_photos(limit := 3)`**: faltantes ordenadas pela fração `have/need` (sem progresso = 0;
   secretas sem pista ficam de fora).
5. **UI**: a carta faltante do álbum (06) mostra `goal_hint` (ícone + texto + `n/m`); tocar abre a pista
   grande em madeira (`PhotoHint`: carta escura grande, texto, barra de progresso, "Ir" verde que usa
   `Places.go`, lupa quando for secreta, e o rosto do personagem que dá dica (`hint_npc`) com "Conversar").
   "Quase lá" usa `near_photos`.

## 4. Não fazer
Mudar `on`/`when` (quando a foto acontece) ou a regra da lupa.

## 5. Armadilhas
- Condições de hora/data: o progresso não é contador; mostre só o texto.
- `goal_hint.go` precisa existir no `Places.go` (teste todos).

## 6. Testes
Novo **`tests/photo_hints_test.gd`** (área `album`):
1. As 54 fotos têm `goal_hint` com texto e ícone válidos.
2. Todo `go` resolve um destino válido (`Places.goal_target`/`Places.go` sem erro).
3. Progresso de uma foto por contador sobe quando o contador sobe.
4. Secreta: pista poética até usar a lupa; depois `revealed` e texto concreto.
5. `near_photos` ordena pela fração e não inclui secretas sem pista.
Lista fechada: `photo_hints_test,album_book_test,album_secrets_test,content_test,texts_test`.
Capturas `tests/fotos_07_shots.gd`: faltante com progresso, secreta antes/depois da lupa, "Quase lá".

## 7. Pronto quando
Todas as faltantes dizem o que fazer, testes passam, capturas olhadas.
