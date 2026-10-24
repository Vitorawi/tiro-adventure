# Etapa 09 — Painéis grandes

> Tamanho: grande (muitos arquivos, pouca lógica). Depende de: 08. Próxima: 10.
> Resultado que o Vitor vê: Crescimento, feira/encomendas/banca, lojas, obras, passeios, amigos, truques,
> esconde-esconde, níveis da Natureza, "Como fazer" e Configurações no mesmo visual das outras telas.

## 1. Ler antes
`03_TELAS.md` "Painéis grandes" e "Outras"; `01_BIBLIA_VISUAL.md` §F; checklist `04 §B`. Referência de
loja: cartões com preço em pílula verde (Ms Farm, `00_VISAO.md` §2).

## 2. O que existe (todos já montam com `UiKit`/`SheetBuilder`, então o tema e as peças da 01–02 já
mudaram boa parte; aqui se trocam as montagens à mão e se aplica o checklist)

| Painel | Arquivo / função | Nós que os testes usam (preservar) |
|---|---|---|
| Crescimento | `scripts/ui/growth_ui.gd` (`panel`, `_hero`, `_steps`, `_step_tile`, `_style_tile`, `_step_detail`, `history`, `step_ring`, `progress_strip`) e `pillar_ui.gd` | `GrowthHero`, `CurrentDog`, `NextSilhouette`, `GrowthDetails`, `GrowthHistoryButton`, `GrowthSummary`, `GrowthSteps`, `GrowthReq_<id>`, `GrowthDots_<pilar>`, `GrowthDetail`, `GrowthNextStep`, `GrowthNextAction`, `GrowthDetail_<id>`, `GrowthAct_<id>`, `GiveGrowth_<item>`, `GrowthHint_<id>`, `GrowthSource_<item>`, `GrowthHelp`, `GrowButton`, `GrowthCard_<fase>`, `SilkSilhouette`, `SilkReq_*`, `SilkButton`, `SilkCard_n` |
| Feira / Encomendas / Banca | `scripts/ui/market_ui.gd` | os de `market_test`/`customers_test` (confira com `Select-String`) |
| Construir / lojas | `ProgressionUi.upgrade_card` (a 06 já fez a folha de compra), `SheetBuilder.animal_shop`, `ProgressionUi.petshop_panel` | `SpaceChip`, `LockedSlot_*` |
| Obras | `scripts/ui/project_ui.gd` (`panel`, `community`, `_gathering_card`) | os de `bench_test`/`garden_picnic_test`/`festival_test` |
| Passeios | `ProgressionUi.walks_panel`, `walk_diary` | `StartWalk_*`, `WalkSlot`, `CancelWalk` |
| Amigos / truques / esconde-esconde | `friend_ui.gd`, `trick_ui.gd`, `scenes/ui/trick_training/`, `hide_seek_ui.gd` | `TrickTraining`, `HideSeek*`, os de `friends_test`/`tricks_test`/`gestures_test` |
| Natureza (níveis, rotas) | `nature_ui.gd` (`panel`, `levels_panel`, `slot`, `route_choice`) | `NatureLevel_*`, `NatureSkill_*`, `NextTool_*`, `Material_*`, `GatherItem_*`, `RouteChoice_*` |
| Como fazer | `scripts/ui/task_help.gd` (`panel`, `open`, `_go`) | — |
| Configurações | `scripts/ui/settings_panel.gd` (`panel`, `_toggle_row`, `_slot_card`, `_version_label`) | `VibrateToggle`, `ReducedMotionToggle`, `Save_<n>`, `NewSave`, `VersionLabel`, `NotebookTab_on/off` (se ainda existirem) |
| DEV | `scripts/ui/dev_panel.gd` | só troca de peças |

## 3. Passo a passo (por painel, sempre: trocar montagem à mão por peça do `UiKit`, um verde, checklist)
1. **Crescimento:** quadradinhos dos passos viram `UiKit.tile` (anel `HONEY` em volta do ícone para o
   progresso, ✓ em disquinho verde nos feitos, escolhido com contorno de tinta); faixa de detalhe em cartão
   branco; `GrowButton` = `primary`; `GrowthDetails`/`GrowthHistoryButton` = `ctl_button("info")` e
   `ctl_button("list")`; resumo do avatar (`GrowthQuick_<id>`) em `Popover` branco. O painel continua
   cabendo em 360×780 sem rolar (regra antiga do Crescimento).
2. **Feira/Encomendas/Banca:** encomendas em cartões de 2 colunas (ícones do pedido com `n/m`, prêmio em
   `chip prize`, quem pede em retrato 28 no canto); venda com `UiKit.stepper`; selos de cliente em disquinhos
   bronze/prata/ouro (`Palette.SEAL_*`) com `ctl check`; paginação vira rolagem vertical se couber, senão
   `ctl back`/`chev` em discos.
3. **Lojas (animais, pet shop):** cartões de 2 colunas: figura 64 em disco, nome, botão verde pequeno com o
   preço (moeda + número); indisponível = cartão a 55% + `ctl lock` + uma linha do motivo.
4. **Obras:** fases com `UiKit.steps` (grande, 8 px de altura); entrega por item com `chip have/missing` +
   `stepper` + `small_go("Entregar")`; encontro da turma como cartão mel.
5. **Passeios:** caminhos em `list_card` com o postal como miniatura 56, tempo em `chip time`, energia em chip;
   começar = `small_go`; passeio em andamento com `UiKit.ring` grande.
6. **Amigos/truques/esconde-esconde:** linhas e tiles do `UiKit`; minijogo do truque: barra com trilho
   `SUNKEN` e zona `GO_SOFT`, marcador `INK` (as cores `TRACK_*` da `Palette` passam a apontar para esses).
7. **Natureza:** níveis com `UiKit.steps`/barra `SKY`, materiais em tiles, rotas em `segmented`.
8. **Como fazer:** cadeia em `list_card`; cada passo com ícone, uma linha, `ctl check` em verde se já tem;
   `soft("Ir")` em cada passo e **um** `primary("Ir")` no primeiro que falta.
9. **Configurações:** linhas com `UiKit.toggle` ("Vibrar", "Menos animação"; nós mantidos), saves em
   `list_card` com `ctl chev`, versão em `SmallLabel`.
10. Tour `--i2-09-only`: uma captura de cada painel acima (nomes `i2_09_<painel>`).

## 4. Não fazer
Mudar preços, prêmios, requisitos, tempos, quantidades ou regras de qualquer painel.

## 5. Armadilhas
- `growth_ui_test` confere estrutura e seleção dos passos (o `selected` persiste nas reconstruções): troque
  só o desenho do quadradinho.
- `bench_test` é o mais demorado da lista (38 s): rode-o por último.
- `ui_style_test` (≤ 1 `PrimaryButton` por painel) pega painéis com dois verdes: use `small_go` nas linhas.

## 6. Testes
Sem teste novo. **Comando:** `tools\test.ps1 -Level etapa -Exact -Tests growth_ui_test,market_test,bench_test,walks_test,tricks_test,ui_style_test` (~2 min).
Se mexer em `friend_ui.gd` ou `hide_seek_ui.gd`, acrescente `friends_test` (8 s) ou `gestures_test` (15 s) e
registre.

## 7. Capturas
`--i2-09-only` antes (tour completo como referência: `b14*`, `b16*`, `b19`, `b24*`, `t0*`) e depois nas 3
resoluções.

## 8. Pronto quando
- [ ] Todos os painéis da tabela passam no checklist 04 §B (anotar ✓/✗ por painel no registro).
- [ ] Testes verdes.

## 9. Registro
```
**Etapa 09 (data, executor):** painéis grandes no visual novo (Crescimento, feira, lojas, obras, passeios,
amigos/truques/esconde, Natureza, Como fazer, Configurações). Checklist: … Testes … PASS em … s.
```
