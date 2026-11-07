# Etapa 06 — Álbum novo

> Tamanho: grande. Depende de: 04 (e 05 para "Para abrir"). Próxima: 07.
> Resultado que o Vitor vê: a aba Álbum do caderninho vira um livro de cartas grandes (2 por linha, arte
> nítida), com seções, contagem de fotos e de versões, cartas fechadas em "Para abrir", fotos que faltam
> escurecidas com a pista, e a faixa "Quase lá". Tocar numa carta abre a carta 3D.

## 1. Ler antes
`01_DESENHO.md` §2, §4, §10. Código: `scripts/ui/codex_sections.gd` (`_album`, tiles `Photo_<id>`),
`scripts/ui/codex_ui.gd` (quadro do caderninho, abas, filtros, `CodexScroll`), `scripts/ui/album_view.gd`
(`panel`, `_section_counts`, `taken_count`, `secret_detail`), `GameState.note_album_section/open_album_photo`.
Referência do problema: `build/screenshots/album_illustrated_360/t09_album_grid.png` (fotos encolhidas em
quadradinhos de 4 colunas).

## 2. Como está hoje
O Álbum é uma seção do `CodexUi` (abas laterais coloridas; Álbum verde) com filtros por seção e grade de 4
colunas de `CodexUi.tile` com a polaroide reduzida dentro do quadradinho creme; faltantes "?" .

## 3. Passo a passo
1. Dentro do quadro do caderninho (mantém a aba Álbum e os filtros de seção como abinhas), a grade do Álbum
   passa a ser **2 colunas de cartas** (`AlbumCard_<id>`, largura ≈ metade útil, ~140–160 px), feitas com
   `PhotoCard` (moldura e efeito do nível mostrado; efeito só por `TIME`, barato).
2. Topo da seção (`AlbumSummary`): "História 9/14" + mini contagem por nível (4 selinhos com números) +
   "Versões 18/56".
3. **Para abrir** (`AlbumSealed`): se houver cartas fechadas, uma faixa no topo com as cartas viradas
   (verso) e "Abrir (N)" — abre a revelação (05) da primeira.
4. **Faltantes**: a carta com a **ilustração base borrada e escurecida** (shader de desfoque leve ou a
   miniatura em baixa resolução + escurecer; secreta = "???" até ter pista), cadeado e uma linha de pista
   (o texto da etapa 07; nesta etapa use o `hint` atual). Tocar abre a pista grande (`secret_detail` em madeira).
5. **Quase lá** (`AlbumNear`): até 3 fotos que faltam e estão perto (use o progresso que a etapa 07 vai
   expor; nesta etapa, as que têm `hint` e condição de contador: mostre só se for barato calcular) com Ir.
6. Tocar numa carta tida → `CardViewer.open(id)` (04).
7. Selo "Novo" das fotos não vistas continua (`seen`).
8. Desempenho: cartas carregam a textura quando entram na área visível (ou a seção inteira de uma vez, que
   tem no máximo ~14 fotos); efeito animado só nos níveis 3–4.

## 4. Não fazer
Mudar as abas do caderninho fora do Álbum; trocar os filtros de seção por outra navegação.

## 5. Armadilhas
- `CodexUi` refaz o quadro ao trocar de filtro: guarde a rolagem por seção.
- A arte base borrada não pode revelar a foto secreta: para `secret` sem pista use só o verso.

## 6. Testes
Atualize **`album_test`** / **`album_secrets_test`** e crie **`tests/album_book_test.gd`** (área `album`):
1. Seção mostra 2 colunas de `AlbumCard_<id>` com o nível certo.
2. Contagens (fotos, versões, por nível) batem com o `GameState`.
3. Cartas fechadas aparecem em "Para abrir" e o botão abre a revelação.
4. Faltante mostra a base escurecida (não colorida) e a pista; secreta sem pista mostra o verso.
5. Tocar numa carta abre o `CardViewer` daquela foto.
Lista fechada: `album_book_test,album_test,album_secrets_test,manual_test,card_viewer_test`.
Capturas `tests/fotos_06_shots.gd` (3 resoluções): seção cheia, seção com faltantes, "Para abrir", rolagem.

## 7. Pronto quando
As fotos aparecem grandes e nítidas, testes passam, capturas olhadas nas 3 resoluções.
