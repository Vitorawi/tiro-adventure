# Etapa 11 — Nada de botão cinza; menos vermelho nas obras e encomendas

> Tamanho: grande. Depende de: 10. Próxima: 12.
> Itens da revisão: **12** (bloqueio vira `lock_hint`, nunca botão cinza) e **20** (obras e encomendas:
> vermelho demais e progresso repetido).
> Resultado que o Vitor vê: nenhum botão cinza com texto; onde algo não dá, aparece o cadeado com o motivo
> (tocável, leva ao Como fazer); nas obras e encomendas, um chip "0/4" no lugar de "faltam 4" + "tem 0", a
> linha "onde achar?" calma e um só indicador de fase.

## 1. Objetivo
Cumprir a regra da bíblia "desabilitado = vira `lock_hint`" (01 §F, 02 §11) em todo lugar, e dar ao vermelho
só o papel de "pede atenção/falta" (00 §3.4).

## 2. Ler antes
`REVISAO_OPUS.md` itens 12 e 20; `01_BIBLIA_VISUAL.md` §F (`lock_hint`, chips `have`/`missing`, `steps`);
`02_JORNADA.md` §11.

## 3. Arquivos
Saída de `grep -rn "\.disabled = " game/scripts game/scenes` (30 linhas hoje):
`progression_ui.gd` 5, `sheet_builder.gd` 4 (incl. compra ~551/~700), `trick_training.gd` 3, `market_ui.gd` 2
(`Entregar`, `Entregar contrato`), `settings_panel.gd` 2 (`Jogando`, `É o padrão`), `friend_ui.gd` 2,
`game_manual.gd` 2, `trick_ui.gd` 2, e 1 em `find_ui.gd`, `nature_ui.gd` (~222), `pet_care_tray.gd`,
`station_tray.gd`, `walk_result.gd`, `intro.gd`, `dev_panel.gd`, `ui_kit.gd`.
Para 20: `project_ui.gd`, `market_ui.gd`. Teste: `game/tests/ui_style_test.gd`.

## 4. Como está hoje (estado esperado ao começar)
- ~20 botões com `button.disabled = erro != ""` mostram texto cinza (`b14b_neighbor_orders`, `b14c_own_stall`,
  `i2_09_settings`).
- Obras/encomendas (`b16c`–`b16f`, `b16h_picnic_panel`, `b14b`): "faltam 4" + "tem 0" (dois sinais vermelhos),
  faixa vermelha "onde achar?", e barra azul **e** tracinhos de fase (`ProjectSteps`) para o mesmo progresso.

## 5. Passo a passo
1. **Classificar** cada `.disabled =` numa tabela em `docs/plans/interface2_ajustes/VALIDACAO_11.md`:
   - **vira `lock_hint`** (tocável → `TaskHelp`/Como fazer com o motivo): Encomendas `Entregar`, Minha banca
     `Entregar contrato`, truques, passeios, amigos, achados (`find_ui`), Manual, compra (`sheet_builder`),
     `nature_ui`;
   - **vira chip** de estado: saves `Jogando` → chip "Jogando ✓"; `É o padrão` → chip;
   - **some** quando o motivo já aparece ao lado;
   - **lista branca** (fica `disabled`, sem texto cinza à vista ou com papel de controle): `stepper`, paginação,
     roleta dormindo, minijogo de truque, `dev_panel`, o próprio `ui_kit` (peça genérica).
2. Aplicar. O motivo do `lock_hint` é o mesmo texto do `*_error()` do `GameState` (não invente texto).
   Quando o erro é "falta item", `lock_hint` com o ícone do item.
3. **Obras e encomendas (20):** "faltam N" + "tem M" → **um** chip `have`/`missing` com `M/N`; "onde achar?"
   → `list_row` calma com `ctl chev` (não faixa vermelha); fase: fica `ProjectSteps` (`UiKit.steps`) **ou** a
   barra — escolha os tracinhos (já são o padrão das obras) e tire a barra azul. `DeliverProject` continua o
   único verde.
4. **Regra no teste:** `ui_style_test`: "nenhum `Button` desabilitado com texto visível dentro de
   `Sheet`/bandeja/`ModalCard`/`RewardSheet`, salvo a lista branca" (a lista branca fica no teste, por nome
   de nó, com comentário de uma linha por entrada).

### 5.1 Armadilhas
- Testes que conferem `button.disabled` (ex.: `market_test`, `saves_test`, `tricks_test`, `walks_test`,
  `friends_test`) passam a conferir o `lock_hint` (nó e texto do motivo): **mesma garantia** (não dá para
  agir), forma nova. Não apague o caso.
- `ui_style_test` conta ≤ 1 `PrimaryButton` por painel: o `lock_hint` não é botão primário.
- Chip "0/4" com `0` em `missing`; quando completo, `have` com ✓.

## 6. Testes
- Lista: `ui_style_test,market_test,customers_test,saves_test,tricks_test,walks_test,friends_test,finds_test,manual_test,bench_test,garden_picnic_test,festival_test,petshop_test,nature_test`
  (~6 min). Exceção de tempo registrada (obras + Natureza são lentos).

## 7. Capturas
Bloco `--aj-11-only`: `b14b_neighbor_orders`, `b14c_own_stall`, `i2_09_orders`, `i2_09_stall`, `i2_09_settings`,
`b23_settings`, `i2_09_tricks`, `i2_09_walks`, `i2_09_friends`, `b16c_bench_start`…`b16f_bench_last_phase`,
`b16h_picnic_panel`, `b16k_garden_panel`, `b16m_festival_panel`, `i2_09_project`, `a05_fridge_sheet`. Antes e
depois nas 3 resoluções.

## 8. Pronto quando
- [x] Tabela em `VALIDACAO_11.md`; nenhum botão cinza com texto fora da lista branca.
- [x] Obras/encomendas: um chip por item, "onde achar?" calma, um indicador de fase.
- [x] Regra nova do `ui_style_test` verde.
- [x] Testes verdes.

## 9. Handoff
Pontos naturais: após a tabela (passo 1); a cada arquivo convertido (diga quais linhas da tabela já estão
feitas); após 3; após 4.

## 10. Registro
```
**Etapa 11 (data, executor[es]):** N botões desabilitados → lock_hint/chip/sumir (tabela em VALIDACAO_11.md;
lista branca: …); obras e encomendas com chip M/N, "onde achar?" calma e só tracinhos de fase; regra nova no
ui_style_test. Testes … PASS em … s. Pendências: … Sem push.
```
