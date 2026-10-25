# Etapa 04 — Bandejas e horta: fogão visível, "Tudo" de volta, barra documentada

> Tamanho: grande. Depende de: 03 (mesmo `room.gd`). Próxima: 05.
> Itens da revisão: **7** (bandeja esconde o fogão — **reverter, aprovado pelo Vitor**), **8** ("Tudo ×N" —
> **reverter, aprovado pelo Vitor**), **9** (câmera não fecha a barra da horta — **manter e documentar,
> aprovado pelo Vitor**), **26** (tile Regar e botão Lugares na barra da horta).
> Resultado que o Vitor vê: ao tocar no fogão, ele sobe para o terço de cima e a bandeja abre embaixo dele,
> com o fogão e o anel do lote visíveis; um "Tudo" pequeno ao lado do seletor de quantidade nas estações, na
> Feira e nas obras; na horta, o tile Regar diz "Regar".

## 1. Objetivo
Devolver às bandejas o princípio "a bandeja aponta para o objeto, e o mundo fica visível" (00 §3 princípio
8, 02 §6), padronizar o atalho de quantidade máxima e registrar a regra da barra da horta.

## 2. Ler antes
`REVISAO_OPUS.md` itens 7, 8, 9, 26; `02_JORNADA.md` §6 e §6.1 (item 7); `docs/plans/interface2/VALIDACAO_07.md`
(os três desvios da 07); protótipos `prototipo/fogao.png`, `prancha_fogao.png`, `horta_plantar.png`,
`horta_colher.png`.

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scenes/levels/room/room.gd` (`open_station_tray` ~1536, `open_nature_tray` ~1553, `_bring_into_view` ~1469) | 7 |
| `game/scripts/ui/action_tray.gd` (`_place`, altura da grade em modo `pick`) | 7 |
| `game/scripts/ui/station_tray.gd` (`recipe_detail`, `_stepper`) | 7, 8 |
| `game/scripts/ui/ui_kit.gd` (`stepper` ~715) | 8 |
| `game/scripts/ui/market_ui.gd` (~331 "Tudo"), `game/scripts/ui/project_ui.gd` (~185 "Tudo") | 8 |
| `game/scripts/ui/farm_dock.gd`, `game/scripts/ui/plot_tray.gd` (`water_entry`) | 9, 26 |
| `docs/plans/interface2/02_JORNADA.md` §6.1 | 9 (documentação) |

## 4. Como está hoje (estado esperado ao começar)
- Bandeja `pick` das estações abre e pode cobrir o próprio fogão (`i2_07_stove`); a grade mostra 2,5 linhas,
  deixando a bandeja alta. `_bring_into_view(center, force, bottom_extra)` já existe.
- `UiKit.stepper(value, min, max, on_change)` não tem "Tudo". Feira (`market_ui.gd:331`) e obras
  (`project_ui.gd:185`) têm botões `UiKit.soft("Tudo")` próprios; as estações não têm nenhum.
  `queue_test` confere `QuantityValue` ("×1") e `FinishAt`; não há `QuantityMax` hoje.
- `FarmDock` não fecha ao mexer a câmera (decisão: **manter**). O tile Regar mostra só "×3" e falta o
  separador de 1 px antes dele (`horta_plantar.png` mostra os dois). Com a barra aberta, o botão Lugares (≡)
  pode ficar meio atrás do rosto da Bloblo (`i2_07_dock_plant`).

## 5. Passo a passo

### 5.1 Fogão visível (item 7, reverter)
1. Antes de abrir uma bandeja `pick` (estação, criação, Natureza), leve o objeto ao **terço de cima** da sala
   (centro do objeto em y ≈ 140–220, abaixo da linha 2) com `_bring_into_view(..., bottom_extra = altura
   prevista da bandeja)`. Calcule a altura prevista **antes** de abrir (cabeçalho + fila + 2 linhas de grade +
   detalhe).
2. Grade com no máximo **duas linhas** visíveis; da terceira em diante, rolagem vertical dentro da grade
   (como no protótipo).
3. "Entra → sai" numa linha só no `recipe_detail`; sem chip `×1` na saída quando a quantidade é 1.
4. Altura máxima da bandeja: até 8 px acima do rodapé e **nunca** acima do topo do sprite do objeto. Se o
   objeto estiver tão embaixo que a câmera não consegue subi-lo (borda da sala), a bandeja abre em cima dele
   com a setinha para baixo (regra que o `ActionTray` já tem).
5. `station_tray_test`, caso novo: em 360×780, o retângulo da bandeja não cruza o retângulo do sprite do
   fogão, do liquidificador e da bancada.

### 5.2 "Tudo" no `stepper` (item 8, reverter no padrão novo)
1. `UiKit.stepper(value, min, max, on_change, max_label := "")`: com `max_label` não vazio, acrescenta uma
   pílula `soft` pequena (nó `QuantityMax`) que leva ao máximo e fica apagada (não clicável, sem cinza
   chamativo: `modulate.a` baixo) quando já está no máximo. Sem `max_label`, igual a hoje.
2. Use `max_label = "Tudo"` nas estações (`StationTray._stepper`), na Feira e nas obras; **apague** os botões
   "Tudo" próprios de `market_ui.gd` e `project_ui.gd` (o comportamento é o mesmo: ir ao máximo permitido).
3. `queue_test`: `QuantityMax` existe na estação com ≥ 2 vagas livres e leva a `×<máx>`. `market_test` e
   `bench_test` acham o "Tudo" pelo nó novo (mesma garantia). `ui2_kit_test`: caso do `stepper` com
   `max_label`.

### 5.3 Barra da horta: manter e documentar (item 9)
1. Em `02_JORNADA.md` §6.1, item 7, acrescente: "Mexer na câmera **não** fecha a barra da horta (aprovado pelo
   Vitor em 25/10/2026): ela é presa ao rodapé, não ao objeto, e plantar em canteiros fora da tela pede
   arrastar a câmera sem perder a semente escolhida. A regra 'arrastar a câmera fecha' (§6 item 4) vale para
   as bandejas presas ao objeto."
2. Comentário de uma linha no `FarmDock` com a mesma regra.
3. Confira que a pinça (`_is_pinching`) cancela o gesto **sem** fechar a barra; se o `farm_dock_test` não
   cobre, acrescente o caso.

### 5.4 Tile Regar e Lugares (item 26)
1. Tile Regar com legenda "Regar" e o `×N` num selo (como a quantidade da Mochila); separador de 1 px
   (`LINE`) antes dele.
2. Com a barra aberta, o botão Lugares (≡) não fica atrás do rosto da Bloblo: ajuste a ordem/posição na
   `WorldBar` (sem mudar o rosto de lugar fora da barra).

### 5.5 Armadilhas
- `station_tray_test` leva ~170 s: rode-o sozinho primeiro com `tools\run_godot_test.ps1 station_tray_test`
  enquanto ajusta.
- `tray_test` confere `drag_through`/`item_center`: a grade com rolagem não pode mudar o centro dos itens da
  primeira linha.
- A câmera subir o objeto não pode fechar a bandeja que acabou de abrir (`_camera_changed` fecha bandejas):
  mova a câmera **antes** de abrir, ou marque a abertura como em curso.

## 6. Testes
- Lista: `station_tray_test,queue_test,tray_test,farm_dock_test,market_test,bench_test,ui2_kit_test,garden_test`
  (~6 min). Exceção de tempo registrada (o `station_tray_test` sozinho leva ~170 s).

## 7. Capturas
Bloco `--aj-04-only`: `i2_07_stove`, `i2_07_coop`, `i2_07_trees`, `i2_07_dock_plant`, `i2_07_dock_harvest`,
`i2_07_station_full`, `i2_09_market` (venda com "Tudo"), `i2_09_project` (obra com entrega). Antes e depois nas 3 resoluções; compare `i2_07_stove` com `prototipo/fogao.png`.

## 8. Pronto quando
- [ ] Fogão, liquidificador e bancada visíveis acima da bandeja nas 3 resoluções; grade com ≤ 2 linhas.
- [ ] `QuantityMax` igual nas estações, Feira e obras; os "Tudo" antigos saíram.
- [ ] §6.1 do `02_JORNADA.md` atualizado; pinça não fecha a barra.
- [ ] Tile "Regar" com selo e separador; Lugares visível com a barra aberta.
- [ ] Testes verdes.

## 9. Handoff
Pontos naturais: após 5.1 (diga como a altura prevista é calculada), 5.2 (diga quais testes já acham
`QuantityMax`), 5.3, 5.4.

## 10. Registro
```
**Etapa 04 (data, executor[es]):** bandejas pick sobem o objeto ao terço de cima e não o cobrem (fogão,
liquidificador, bancada), grade em 2 linhas; UiKit.stepper(max_label) com QuantityMax em estações/Feira/obras;
barra da horta: câmera não fecha (documentado no 02 §6.1, aprovado pelo Vitor); tile Regar. Testes … PASS
em … s. Pendências: … Sem push.
```
