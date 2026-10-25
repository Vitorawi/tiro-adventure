# Etapa 12 — Limpeza e fechamento

> Tamanho: médio. Depende de: 11. Última etapa. **Etapa com portão.**
> Itens da revisão: **32** (limpeza de código: apelidos, variações mortas, `reveal` duplicado).
> Resultado que o Vitor vê: o plano pronto para ele conferir no celular quando pedir publicação, com pranchas
> antes × depois de todas as telas mexidas.

## 1. Objetivo
Apagar o que sobrou do visual antigo no código, rodar a verificação final (portão, tour nas 3 resoluções,
toque real, desempenho) e fechar a documentação.

## 2. Ler antes
`REVISAO_OPUS.md` item 32 e §4 (notas finais); `docs/plans/interface2/etapas/ETAPA_12_FECHAMENTO.md` (como
foi o fechamento anterior); `docs/plans/interface2/RESULTADOS.md` e `FUTURO.md`; todos os registros deste
plano (README).

## 3. Arquivos
| Arquivo | O quê |
|---|---|
| `game/scripts/ui/ui_kit.gd` | apagar `GOOD`/`BAD` (35 usos hoje, menos os já trocados nas 09–11) e `secondary` (32 chamadas hoje) |
| todos os chamadores | `UiKit.GOOD` → `Palette.GO_INK`; `UiKit.BAD` → `Palette.ALERT_INK`; `UiKit.secondary` → `UiKit.soft` |
| `game/assets/theme/main_theme.tres` | apagar variações mortas `TopBarPanel`, `BarLabel`, `ToastLabel`, `SoftButton` (confirme com grep que ninguém usa) |
| `game/scripts/ui/modal_card.gd`, `game/scripts/ui/reward_sheet.gd` | juntar `ModalCard.reveal` e `RewardSheet.reveal_in` numa função só (em `Motion` ou numa das duas) |
| `docs/plans/interface2/prototipo/prancha.html` | entradas `aj_*` antes × depois |
| `docs/plans/interface2/RESULTADOS.md`, `FUTURO.md`, `docs/ROADMAP.md`, `CLAUDE.md` = `AGENTS.md` | fechamento |

`world_selector.gd` **não** é órfão (a `.tscn` o referencia): não apagar.

## 4. Como está hoje (estado esperado ao começar)
Etapas 01–11 concluídas e commitadas; `aj_base*` (linha de base da 01) e `aj_NN_*` existem em
`build/screenshots/`. Números de desempenho da 01 e da 03 no README do plano.

## 5. Passo a passo
1. **Limpeza (32):** troque os usos e apague `UiKit.GOOD/BAD/secondary`; apague as variações mortas do tema
   (grep por cada nome em `game/` antes; se algum teste as cita, troque pelo nome atual com a mesma garantia);
   junte `reveal`/`reveal_in` mantendo o comportamento (inclusive `Motion.reduced` e `count_up`).
2. Rode a lista da etapa (§6) antes do portão, para achar quebra cedo.
3. **Portão:** `tools\test.ps1 -Level portao -KeepGoing`. Verde é verde.
4. **Tour completo** nas 3 resoluções: `--out=aj_12_tour`, `aj_12_tour_390`, `aj_12_tour_412` (114 PNGs cada).
5. **Pranchas antes × depois:** no `prancha.html`, entradas `aj_<tela>` comparando `aj_base*` com `aj_12_tour*`
   para as telas da revisão (aviso + folha, conversa, Texto maior, seletor, Sítio com balões, fogão, horta,
   Tiro + cardápio, cerimônia, Missões nas 3 abas, caderninho, capítulo, Novo!, passeio, Crescimento, seda,
   Como fazer, Lugares, compra, Feira, encomendas, obras, passeios, Configurações). Render e **abra** todas.
   Checklist 04 §B por tela no `docs/plans/interface2_ajustes/RESULTADOS.md` (novo).
6. **Toque real** (04 §F): export, `serve_local.ps1`, `touch_test.ps1` com `build/touch_steps_i2_12.json` —
   tem de passar inteiro, inclusive o fogão (agora visível) e a horta.
7. **Desempenho:** mesma medição da 01 e da 03 (Sítio, roleta, folha). Números finais no `RESULTADOS.md`.
8. **Roteiro do celular** no `RESULTADOS.md`: o que olhar no `/dev/` quando o Vitor pedir publicação (aviso
   nunca sobre o título; Texto maior; fogão visível; "Tudo"; Crescimento novo; humor legível; sem botão cinza).
9. **Docs:** registro + `[x]` no README do plano, "PLANO CONCLUÍDO LOCALMENTE"; `docs/plans/interface2/FUTURO.md`
   (o que sobrar); "Estado atual" do `ROADMAP.md`; `CLAUDE.md` = `AGENTS.md` (peças novas: `stepper(max_label)`,
   `QuantityMax`, `--aj-NN-only`, variações de tema novas da 06, slot de ações da folha da 08, regras novas do
   `ui_style_test`).
10. **Não publicar.** Commit local.

## 6. Testes
- Lista (antes do portão): `ui2_kit_test,ui_style_test,festa_test,quest_reward_test,walk_return_ui_test,texts_test,text_budget_test,lists_test`
  (~2 min 30).
- **Portão** (~11 min). Toque real (§5.6).

## 7. Capturas
Tour completo nas 3 resoluções (§5.4) + pranchas (§5.5). Sem bloco `--aj-12-only`.

## 8. Pronto quando
- [ ] `UiKit.GOOD/BAD/secondary` e variações mortas apagados; `reveal` único.
- [ ] Portão verde; toque real verde; desempenho medido (comparado com a 01).
- [ ] Pranchas `aj_*` abertas e checklist por tela no `RESULTADOS.md` deste plano.
- [ ] Roteiro do celular escrito; docs atualizados; `CLAUDE.md` = `AGENTS.md`.
- [ ] Commit local; nada publicado.

## 9. Handoff
Pontos naturais: após a limpeza (diga o que ainda referencia os nomes apagados, se algo); após o portão (log);
após o tour; após as pranchas; após o toque/desempenho; após os docs.

## 10. Registro
```
**Etapa 12 (data, executor[es]): PLANO DE AJUSTES CONCLUÍDO LOCALMENTE.** Limpeza (GOOD/BAD/secondary, variações
mortas, reveal único). Portão N/N PASS em … min; toque real …; Sítio … ms (base … ms); tour aj_12_tour(_390,_412);
pranchas e checklist em RESULTADOS.md; roteiro do celular. Sem push, sem publicação.
```
