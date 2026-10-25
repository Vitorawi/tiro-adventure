# Etapa 10 — Hierarquia de texto (`SectionLabel`), passeios e Feira

> Tamanho: grande. Depende de: 09. Próxima: 11. **Etapa com portão.**
> Itens da revisão: **6** (restaurar a hierarquia de texto), **27** (passeios: `?` solto, espaço vazio),
> **28** (Feira: cartão de venda e contorno do selecionado).
> Resultado que o Vitor vê: nomes de coisas (produto, receita, passeio, material, fase) em 18 escuro, frases
> em 15, rótulos de seção pequenos em maiúsculas — acaba a "parede de texto de 12 px cinza". Passeios e Feira
> mais compactos e claros.

## 1. Objetivo
Revisar todos os usos restantes de `SectionLabel` e dar a cada texto o papel certo; travar a regra num teste.
É a mudança mais sistêmica do plano (toca quase todos os painéis): por isso vem depois dos painéis refeitos
(08, 09) e roda o **portão** no fim.

## 2. Ler antes
`REVISAO_OPUS.md` itens 6, 27, 28; `01_BIBLIA_VISUAL.md` §A (quatro tamanhos, um nome em 18);
`04_REGRAS_E_TESTES.md` §B e §C; o tema `game/assets/theme/main_theme.tres` (variações `SectionLabel`,
`SmallLabel`, `OverLabel`, `StrongLabel`, `NumberLabel`).

## 3. Arquivos
Os que ainda usam `SectionLabel` depois da etapa 09. Contagem de hoje (antes das etapas 06–09), por
`grep -rc '"SectionLabel"' game/scripts game/scenes`:
`game_manual.gd` 15, `progression_ui.gd` 9, `celebration.gd` 7, `pillar_ui.gd` 5, `task_help.gd` 5,
`growth_ui.gd` 4, `market_ui.gd` 4, `sheet_builder.gd` 4, `project_ui.gd` 3, `station_tray.gd` 3,
`walk_result.gd` 3, `album_view.gd`, `find_ui.gd`, `friend_ui.gd`, `nature_ui.gd`, `intro.gd` 2 cada,
`dev_panel.gd`, `hide_seek_ui.gd`, `house_ui.gd`, `hud.gd`, `pet_care_tray.gd`, `wish_ui.gd`,
`growth_ceremony.gd`, `pet_screen.gd`, `trick_training.gd`, `welcome_back.gd` 1 cada (≈ 82 no total).
Mais: `game/scripts/ui/ui_kit.gd` (`section`), `main_theme.tres`, `game/tests/ui_style_test.gd`.
Para 27: `progression_ui.gd` (`walks_panel`). Para 28: `market_ui.gd` (cartão de venda).

## 4. Como está hoje (estado esperado ao começar)
- Na etapa 01 do Interface 2, `SectionLabel` (antes título de seção, 22 px) virou igual a `SmallLabel`
  (Nunito 12, `INK_SOFT`), e é usada para nomes e títulos.
- `OverLabel` (maiúsculas espaçadas) existe no tema e não é usada; `UiKit.section` usa `font_caption_spaced`.
- Passeios (`b16_walks`, `i2_09_walks`): `?` solto no canto da lista; cartões com espaço vazio.
- Feira (`b14_market`, `i2_09_market`): nomes em 12; o primeiro item selecionado não mostra contorno.

## 5. Passo a passo
1. **Inventário:** gere a lista de usos (`grep -rn '"SectionLabel"' game/scripts game/scenes`) e classifique
   cada um numa tabela no registro de validação (`docs/plans/interface2_ajustes/VALIDACAO_10.md`, novo):
   **nome de coisa** → `StrongLabel` 18; **frase** → `Label` 15 (sem variação); **rótulo de seção** →
   `UiKit.section` (que passa a usar `OverLabel`); **legenda de verdade** (tempo sob ícone, "1 de 3") →
   `SmallLabel` 12. `dev_panel.gd` pode ficar em `SmallLabel` (DEV).
2. **Aplicar** arquivo por arquivo, do maior para o menor (`game_manual.gd` primeiro). Cuidado com largura:
   nomes em 18 quebram mais; use `autowrap`/reticências, nunca fonte menor.
3. **Tema:** `UiKit.section` usa `OverLabel`; `SectionLabel` vira apelido de `OverLabel` no tema (ou sai, se
   não sobrar uso). Não deixe variação órfã.
4. **Passeios (27):** o `?` entra no cabeçalho do painel (`ctl_button("info")`); achados e `StartWalk_<id>` na
   mesma linha do cartão, sem o vão.
5. **Feira (28):** cartão de venda com ícone 40 em disco, nome `StrongLabel`, contorno de tinta no
   selecionado — inclusive o **primeiro**, selecionado por padrão ao abrir.
6. **Regra no teste:** `ui_style_test` ganha: "nenhum `Label` com variação `SectionLabel` como **primeiro
   texto** de um cartão (`CardPanel`/`list_row`/tile) dentro de `Sheet`/bandeja/`ModalCard`/`RewardSheet`".
   Monte telas reais (Feira, Manual, passeios, Como fazer) e confira.
7. **Portão** (§6).

### 5.1 Armadilhas
- Muitos testes acham nós por texto/variação: se um teste procura `SectionLabel`, mude para o nome do nó ou
  a nova variação, mantendo o que é conferido.
- `text_budget_test` mede palavras por tela: não acrescente texto.
- `celebration.gd`/`walk_result.gd` já foram mexidos na 07: só troque a variação.

## 6. Testes
- Lista da etapa: `ui_style_test,text_budget_test,market_test,customers_test,walks_test,manual_test,lists_test,item_sources_test,growth_ui_test,festa_test,friends_test,tricks_test`
  (~3 min 30).
- **Portão** no fim: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao -KeepGoing`
  (~11 min). Verde é verde: falha é consertada aqui (mesmo que pareça "de outra etapa"; registre a causa).

## 7. Capturas
Bloco `--aj-10-only`: `b14_market`, `i2_09_market`, `b14b_neighbor_orders`, `b14c_own_stall`, `b15_nature_trees`,
`b16_walks`, `i2_09_walks`, `b24_manual`, `b24b_manual_stations`, `b16c_bench_start`…`b16f_bench_last_phase`,
`i2_09_taskhelp`, `c04_walk_result`, `i2_10_unlock`. Antes e depois nas 3 resoluções. Mais o **tour completo**
em 360×780 (`--out=aj_10_tour`) para varrer telas não listadas.

## 8. Pronto quando
- [x] Tabela de classificação em `VALIDACAO_10.md`; nenhum nome de coisa em 12.
- [x] `UiKit.section` em `OverLabel`; nenhuma variação órfã.
- [x] Passeios com `?` no cabeçalho e cartões compactos; Feira com contorno no selecionado (inclusive o 1º).
- [x] Regra nova do `ui_style_test` verde.
- [x] Lista da etapa e **portão** verdes (logs citados).

## 9. Handoff
Pontos naturais: após o inventário (passo 1: a tabela é o mapa para quem continuar); depois de cada arquivo
grande (`game_manual`, `progression_ui`, `celebration`, `pillar_ui`, `task_help`) — diga quais arquivos da
tabela já estão feitos; após 4/5; após o teste novo; durante o portão (diga o log e as falhas abertas).

## 10. Registro
```
**Etapa 10 (data, executor[es]):** hierarquia restaurada (N usos de SectionLabel → StrongLabel/Label/section/
SmallLabel; tabela em VALIDACAO_10.md); UiKit.section em OverLabel; passeios e Feira compactos; regra nova no
ui_style_test. Lista … PASS em … s; portão N/N PASS em … min (log …). Pendências: … Sem push.
```
