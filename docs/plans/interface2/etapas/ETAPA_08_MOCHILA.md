# Etapa 08 — Mochila, detalhe do item, caderninho, Coleção e Álbum

> Tamanho: médio. Depende de: 07. Próxima: 09.
> Resultado que o Vitor vê: Mochila com os depósitos em quatro mini-cartões, filtros com ícones e grade
> limpa; detalhe do item numa folha curta com uma linha e uma ação verde; caderninho, Coleção e Álbum no
> visual novo.

## 1. Ler antes
`03_TELAS.md` "Mochila e itens" e "Caderninho"; `01_BIBLIA_VISUAL.md` §F (tile, segmented, chip, list_card);
protótipo `prototipo/estilo.png` (peças). Não há protótipo de tela inteira: siga as peças e o checklist.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Mochila | `scripts/ui/inventory_list.gd` (248), montada por `SheetBuilder.inventory_view` | depósitos em linhas com barra (`Storage_<depósito>`, nome + `n/cap`), filtros `UiKit.segmented` horizontais, grade 4 (`Item_<id>`, `UiKit.grid_tile`), selo `NewBadge` "Novo" para item nunca visto (`progress.seen["ui:bag:<id>"]`, marcado ao abrir), cartões `PendingGifts` (`GiftsToggle`, `StoreGifts`, `GiftsBlocked`, `Gift_<item>`) e bagagem do passeio |
| Detalhe | `SheetBuilder.item_detail(id)` (`sheet_builder.gd:98`) | para que serve, onde usar, vender; comida usa `give_food` ("Ele quer!"); "Você não tem" quando zerado |
| Caderninho | `scripts/ui/pet_notebook.gd` (`tabs()`, `open(section)`, `panel(section)`), abas `NotebookTab_<id>` (Manual/Crescimento/Coleção/Truques/Álbum) | `UiKit.segmented` |
| Coleção | `ProgressionUi` (coleção) — `ClothesGrid` (3 colunas), `Equip_<roupa>` com `EquippedCheck` | toque veste/tira |
| Álbum | `scripts/ui/album_view.gd`, `photo_card.gd` (polaroides) | — |
| Testes | `lists_test` (sem ×0; Novo some na próxima abertura; `Storage_fridge` com nome; filtros; detalhe "Você não tem"; Coleção 3 colunas, check na vestida, sem botões repetidos), `pending_gifts_test`, `album_test`, `petshop_test`, `item_sources_test` | — |

## 3. Passo a passo
1. **Depósitos:** grade 2×2 de mini-cartões (`CardPanel` canto 16, altura 64): ícone do depósito 32, nome
   `SmallLabel`, `n/cap` em `NumberLabel` 18, barrinha 6 px (`SKY`; ≥ 90% = `ALERT`). Tocar filtra (como
   hoje); filtrado = contorno de tinta 2,5. Nomes `Storage_<depósito>` mantidos.
2. **Filtros:** `UiKit.segmented` com ícone em cada opção e o texto só na selecionada (as outras mostram só o
   ícone, para caber em 360). Nomes dos botões mantidos.
3. **Grade:** 4 colunas de tiles 76 (`UiKit.tile` com ícone 40 e a quantidade num chip `×9` no canto de baixo
   à direita); "Novo" vira um **pontinho mel** (`UiKit.spark` pequeno ou disco `HONEY` 10) no canto de cima,
   com o mesmo nó `NewBadge` e a mesma regra (some na próxima abertura).
4. **Presentes para guardar:** cartão `HONEY_SOFT` canto 20 no topo, com os chips `Gift_<item>` e
   `small_go("Guardar")` (`StoreGifts`); bloqueado = `lock_hint` (`GiftsBlocked`).
5. **Detalhe do item** (`item_detail`): folha meia, sem `sheet_size` (altura automática, o teste confere):
   ícone 64 num disco `SUNKEN` 88, nome `TitleLabel`, uma linha de uso (`Label` 15), chips (`Vende por 12`
   em `prize`, `Na geladeira 4/24` em `neutral`), seção "De onde vem" com `list_card` de linhas com `ctl chev`
   (cada uma leva ao lugar), e **uma** ação verde contextual (Dar ao Tiro / Vender / Ir). Zerado: "Você não
   tem" em `INK_SOFT` (sem ×0).
6. **Caderninho:** folha alta com `segmented` novo; Manual em `list_card` agrupado com `UiKit.section`;
   Truques em linhas; Coleção em grade de 3 colunas de tiles (vestida = contorno de tinta + `EquippedCheck`
   como disquinho verde com `ctl check`; bloqueada = silhueta + `ctl lock`).
7. **Álbum:** fundo da tela `PAPER`, seções em `segmented`; as polaroides (`PhotoCard`) não mudam (são
   "coisa do mundo"); o aviso "Nova foto!" já passa pelo `Notice` (03).
8. Tour: bloco `--i2-08-only`: `i2_08_bag`, `i2_08_bag_filter`, `i2_08_bag_gifts`, `i2_08_item`,
   `i2_08_item_empty`, `i2_08_notebook_manual`, `i2_08_collection`, `i2_08_album`.

## 4. Não fazer
Mudar categorias, capacidades, venda, presentes, regras de vestir ou do álbum.

## 5. Armadilhas
- O "Novo em tudo" das capturas antigas é do save de teste com tudo liberado: a regra (marcar ao abrir) já
  está certa; não invente outra.
- `lists_test` conta um único `PrimaryButton` por painel no detalhe e no cartão do desejo.

## 6. Testes
Sem teste novo (a etapa é visual sobre regras já testadas). **Atualizar** só se um nó mudar de tipo
(`NewBadge` deixa de ser `Label` com texto "Novo": o teste confere existência, então continua).
**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests lists_test,pending_gifts_test,album_test,petshop_test,item_sources_test` (~1 min 20).

## 7. Capturas
`--i2-08-only` antes (use `--lists-only`) e depois nas 3 resoluções.

## 8. Pronto quando
- [ ] Checklist 04 §B em todas as telas da etapa; nada de ×0; uma ação verde por folha.
- [ ] Testes verdes.

## 9. Registro
```
**Etapa 08 (data, executor):** Mochila (depósitos 2×2, filtros com ícone, grade, Novo em ponto mel,
presentes), detalhe do item, caderninho/Coleção/Álbum no visual novo. Testes … PASS em … s. Pendências: …
```
