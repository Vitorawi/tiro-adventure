# Etapa 08 — Crescimento (prancha primeiro) e seda

> Tamanho: grande. Depende de: 07. Próxima: 09.
> Itens da revisão: **35** (tela de Crescimento sem hierarquia — **sugestão do revisor, aprovada pelo
> Vitor**: refazer, com prancha HTML primeiro e implementação em seguida, **sem parar para aprovação**) e
> **11** (painel da seda fora do padrão do Crescimento).
> Resultado que o Vitor vê: a tela que resume o objetivo do jogo ganha um herói (Tiro de agora → próxima fase),
> um só indicador de progresso, passos em tiles com anel e um detalhe claro com um verde só; a seda do adulto
> usa a mesma grade.

## 1. Objetivo
1. Desenhar a tela nova numa **prancha HTML** (antes × proposta) com os sprites reais.
2. Implementar a proposta no `GrowthUi.panel` na mesma etapa, preservando nós e regras.
3. Trazer a seda (`SilkReq_*`) para a mesma grade.

## 2. Ler antes
`REVISAO_OPUS.md` itens 35 e 11; `01_BIBLIA_VISUAL.md` §A (tamanhos; valor maior que o rótulo; um título
por tela) e §F (`tile`, `ring`, `steps`, `ctl_button`); `03_TELAS.md` "Crescimento" ("grade de passos vira
tiles afundados com anel; detalhe em faixa branca"); o bloco "Crescimento do Tiro" da tabela "Onde trabalhar"
do `CLAUDE.md` (todos os nós do `GrowthUi`); protótipos existentes (`prototipo/tiro.html`, `proto.css`,
`proto.js`, `render.sh`, `prancha.html`) como modelo de HTML.

## 3. Arquivos
| Arquivo | O quê |
|---|---|
| `docs/plans/interface2/prototipo/crescimento.html` (novo) | protótipo da tela (360×780), duas variações por âncora: `#filhote` (passos por fazer) e `#pronto` (grade toda ✓) |
| `docs/plans/interface2/prototipo/crescimento*.png` (novos) | render das variações |
| `docs/plans/interface2/prototipo/prancha.html` | entrada nova `crescimento`: antes (`t01_growth_panel`, `t02_growth_almost`, `i2_09_growth`) × proposta |
| `game/scripts/ui/growth_ui.gd` | `panel`, `GrowthHero`, `progress_strip`, `step_view`, `GrowthSteps`, `GrowthDetail`, ramo da seda |
| `game/scripts/ui/pillar_ui.gd` | `dots` (bolinhas de 10 px) |
| `game/scenes/ui/sheet/sheet.gd` (só se precisar de um slot de botões no cabeçalho) | botões ⓘ/≡ no título da folha |

## 4. Como está hoje (estado esperado ao começar)
- `GrowthUi.panel` (compacto, cabe em 360×780 sem rolar): cabeçalho `GrowthHero` com `CurrentDog` →
  `NextSilhouette` ("?" em traço) e botões `GrowthDetails`/`GrowthHistoryButton` na lateral; `GrowthSummary` +
  `progress_strip` ("0 de 3 passos · falta 3" **e** barrinhas); grade `GrowthSteps` de 3 colunas com
  `GrowthReq_<id>` (anel `step_ring`, nome curto, quantidade ou `GrowthDots_<pilar>`, ✓); detalhe único
  `GrowthDetail` (`GrowthNextStep`/`GrowthNextAction`, `GrowthDetail_<id>`, `GrowthAct_<id>`,
  `GiveGrowth_<item>`, `GrowthHint_<id>`, `GrowthSource_<item>`, `GrowthHelp`); pronto = `GrowButton`.
  A folha fica com uma metade vazia embaixo; o rodapé "Ao crescer: …" é texto.
- Seda (adulto): `SilkSilhouette` com "?", `SilkReq_*` em cartões brancos sem ícone e de alturas diferentes,
  `SilkButton`, `SilkCard_n` (`b19_skills`).

## 5. Passo a passo

### 5.1 Prancha (primeiro; não pare depois dela)
1. `crescimento.html` com `proto.css`/`proto.js` e os sprites reais (`../../../../game/assets/...`: retratos
   das fases em `hud_tiro_puppy/young`/`hud_tiro`, ícones de pilares e itens):
   - **Herói:** Tiro atual 96 num disco `SUNKEN`, seta vetorial, próxima fase no mesmo tamanho com silhueta
     **preenchida** (sem "?"); nome de cada fase embaixo (`StrongLabel`), a próxima em `INK_SOFT`.
   - **Botões ⓘ e ≡** na linha do título da folha (discos 32 `SUNKEN`, sem sombra), não na lateral do herói.
   - **Um indicador:** `UiKit.steps` (ou anel mel) com "1/3"; sem a frase e sem barrinhas duplicadas.
   - **Passos:** tiles com ícone 40, anel de 4 px em volta, `n/m` em `NumberLabel`; bolinhas de momentos 10 px.
   - **Detalhe:** nome em 18, caminho como linha "Casa › Liquidificador" com ícones, `?` como `ctl_button` 32
     sem sombra, verde na largura do cartão.
   - **Altura:** folha do tamanho do conteúdo; "Ao crescer: …" vira chips de prêmio (ícone + nome).
2. Render: `sh docs/plans/interface2/prototipo/render.sh crescimento filhote` e `… crescimento pronto`
   (gera `crescimento_filhote.png`, `crescimento_pronto.png`); entrada `crescimento` no `prancha.html` e render
   da prancha (`W=1180 H=900 sh render.sh prancha crescimento`).
3. Abra os PNGs, confira a bíblia (§A/§F, 04 §B) e **siga direto** para a implementação (aprovação já dada).
   Registre no README do plano que a prancha foi feita e onde está.

### 5.2 Implementação (35)
1. Monte o `GrowthUi.panel` como na prancha, **mantendo todos os nomes de nós** listados no §4 (os testes e
   o `GrowthQuick_*` do HUD dependem deles). `NextSilhouette` continua sendo a silhueta (agora preenchida,
   via `silhouette.gdshader`).
2. Botões ⓘ/≡ (`GrowthDetails`, `GrowthHistoryButton`) no cabeçalho da folha: use um slot no `Sheet` (ex.:
   `content.set_meta("sheet_actions", [botões])`) se não existir; não duplique o `CloseButton`.
3. Um só indicador de progresso; `GrowthSummary` pode continuar existindo como contêiner do indicador.
4. `step_view(req)` com ícone 40 + anel 4 px + `n/m`; `PillarUi.dots` com bolinhas de 10 px.
5. Detalhe com nome em 18, caminho com ícones, `?` = `ctl_button` 32, verde (único) na largura.
6. Altura: remova o `sheet_size` fixo (automático); "Ao crescer" em chips (`RewardSheet.prize_chip` ou
   `UiKit.chip(..., "prize")`).
7. Conferir as cinco fases (`t_phase_*`), "quase" (`t02`), "pronto" (`t03`, corrigido na etapa 01).

### 5.3 Seda (11)
1. `SilkReq_*` na **mesma grade** do `GrowthSteps` (ícone do pilar/item, anel, `n/m`, ✓).
2. `SilkSilhouette`: prévia do brilho do pelo (o `sheen` do shader `tiro_coat`, nível seguinte), em vez de "?".
3. Bloqueio da seda com `UiKit.lock_hint` com ícone.

### 5.4 Armadilhas
- `growth_ui_test` confere seleção persistente (`box.set_meta("selected")`), padrão = `recommended`, e que cabe
  em 360×780 sem rolar: mantenha.
- `care_ui_test` toca `GrowthQuick_*` do resumo do HUD: não mude `GrowthUi.compact_steps` além do visual.
- `ceremony_test` usa a silhueta: o shader não muda.
- A prancha não entra no export (está em `docs/`).

## 6. Testes
- Lista: `growth_ui_test,growth_story_test,ceremony_test,care_ui_test,silk_test,hud_growth_test,growth_visual_test`
  (~1 min 55).

## 7. Capturas
Bloco `--aj-08-only`: `t01_growth_panel`, `t02_growth_almost`, `t03_growth_ready`, `t_phase_*` (cinco fases),
`i2_09_growth`, `b19_skills`, `t05_hud_popover`. Antes e depois nas 3 resoluções; compare com
`crescimento_filhote.png`/`crescimento_pronto.png`.

## 8. Pronto quando
- [ ] Prancha `crescimento*.png` + entrada no `prancha.html`, abertas e citadas no registro.
- [ ] Herói com as duas fases e nomes; ⓘ/≡ no título; um só indicador; tiles com anel; detalhe com um verde.
- [ ] Folha do tamanho do conteúdo, sem metade vazia, cabendo sem rolar em 360×780.
- [ ] Seda na mesma grade, prévia do brilho, bloqueio com `lock_hint`.
- [ ] Testes verdes.

## 9. Handoff
Pontos naturais: (1) prancha pronta e renderizada; (2) herói + cabeçalho; (3) indicador + passos; (4) detalhe
+ altura; (5) seda. Se parar entre 1 e 2, quem continua **não** refaz a prancha: implementa a partir dela.

## 10. Registro
```
**Etapa 08 (data, executor[es]):** prancha prototipo/crescimento_filhote.png e _pronto.png (+ prancha.html
#crescimento), feita e seguida sem parada (aprovação prévia do Vitor; item 35 é sugestão do revisor).
GrowthUi.panel: herói Tiro → próxima fase, ⓘ/≡ no título, um indicador, tiles com anel, detalhe com um verde,
altura automática, prêmios em chips. Seda na mesma grade com prévia do brilho. Testes … PASS em … s.
Pendências: … Sem push.
```
