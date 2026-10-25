# Etapa 09 — Como fazer, Lugares, conversa e compra

> Tamanho: grande. Depende de: 08. Próxima: 10.
> Itens da revisão: **10** (Como fazer com cartões antigos), **13** ("O que tem aqui?" no visual antigo),
> **14** (conversa com repetições e linhas desalinhadas), **34** (compra bloqueada toda esmaecida).
> Resultado que o Vitor vê: o Como fazer vira uma cadeia de linhas com ícone, ✓ no que já tem e um verde só
> no primeiro passo que falta; a lista de Lugares vira linhas com ícone e ›; a conversa não repete nome nem
> retrato; a compra bloqueada mostra a figura e o ganho nítidos, com o cadeado só no rodapé.

## 1. Objetivo
Migrar de verdade (estrutura, não só cor e fonte) os quatro painéis do mundo que ficaram "meio migrados".
Usar aqui já os nomes certos de texto (`StrongLabel` para nome de coisa, `Label` para frase): a etapa 10
não precisa voltar nestes arquivos.

## 2. Ler antes
`REVISAO_OPUS.md` itens 10, 13, 14, 34 (e o item 6, para já aplicar a hierarquia nestes painéis);
`02_JORNADA.md` §8 (conversa, lugares) e §11 (bloqueios); `03_TELAS.md` "Como fazer", "Conversa", "Compra";
`01_BIBLIA_VISUAL.md` §F (`list_card`, `list_row`, `chip`, `lock_hint`, `small_go`).

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scripts/ui/task_help.gd` (`TaskHelp.panel`, ~513–610: `UiKit.card(..., &"ReadyCardPanel")`, `SectionLabel`, `PrimaryButton`) | 10 |
| `game/scripts/ui/places.gd` (~263 e ~273: lista de Lugares, prefixo `"! "`) | 13 |
| `game/scripts/ui/progression_ui.gd` (`npc_header`, `npc_quest_card`, `character_quest_detail`, `NpcServices`, `upgrade_card`) | 14, 34 |
| `game/scripts/ui/speech_bubble.gd` (rótulo de nome opcional) | 14 |

## 4. Como está hoje (estado esperado ao começar)
- `TaskHelp.panel`: cabeçalho e cartões `ReadyCardPanel` antigos; nome em `SectionLabel` (12 cinza); botão
  "Missões" **verde** no caso "Você já tem"; passos de crescimento (`care`) e guia de preparo em cartões;
  `UiKit.GOOD/BAD` para cor (`i2_09_taskhelp`).
- Lugares (`b22b_places_list`): botões grandes, um deles verde ("Canteiros"), prefixo de texto `"! "`.
- Conversa (`i2_06_npc`, `b17_npc_lais`): nome no título da folha **e** no rótulo do balão; retrato repetido
  em cada cartão de missão; linhas de serviço ("Canteiros", "Vender") com o texto preso no topo.
- Compra bloqueada (`a05_fridge_sheet`): cartão inteiro com opacidade 0,55.

## 5. Passo a passo

### 5.1 Como fazer (10)
1. Cabeçalho: ícone 64 em disco `SUNKEN` + nome em `StrongLabel` + estoque em chip `have`/`missing`
   (`UiKit.chip(..., kind)`).
2. Guia de preparo e passos de crescimento (`care`): `UiKit.list_card` com `UiKit.list_row` por passo —
   disco com anel de progresso, chips, `small_go("Ir")` calmo — e **um** `primary` só no primeiro passo que
   falta. "Onde conseguir" vira linhas com `ctl chev`.
3. Cores: `UiKit.GOOD/BAD` → `Palette.GO_INK`/`Palette.ALERT_INK` neste arquivo.
4. "Você já tem": chip `have` + `small_go("Ir")` para onde se usa; sem "Missões" em verde.

### 5.2 Lugares (13)
`list_card` com `list_row` (ícone em disco, nome em `StrongLabel`, selo "!" ou ✓ do personagem com
`UiKit.badge`, `ctl chev`). Sem verde por linha: o pronto ganha fundo `GO_SOFT`. Sem prefixo `"! "`.

### 5.3 Conversa (14)
1. `SpeechBubble`: rótulo de nome opcional; na folha do personagem (título = nome), sem rótulo.
2. Sem retrato em cada cartão de missão quando a folha é do próprio personagem (`npc_quest_card(..., show_face
   := false)` chamado pela conversa; Pessoas continua com retrato).
3. Linhas de serviço centralizadas na vertical (`alignment`/`size_flags_vertical` no `list_row`).

### 5.4 Compra bloqueada (34)
Figura e ganho com opacidade total; só o rodapé com `UiKit.lock_hint` (cadeado + "Depois de: …").
`UpgradeHero`, `BuildUpgrade`, `SpaceChip` mantêm os nomes.

### 5.5 Armadilhas
- `recipe_help_test` e `item_sources_test` procuram textos e nós do Como fazer (`GrowthSource_*`,
  caminhos): mude a forma de achar, não o conteúdo conferido.
- `ui_style_test`: ≤ 1 `PrimaryButton` por painel — o Como fazer precisa continuar com no máximo um.
- `npc_lines_test` confere a ordem de missões/serviços da conversa.
- `IntroductionNext` (balão da apresentação) e `NpcPortrait` fora do corpo reconstruído: não mexer.

## 6. Testes
- Lista: `recipe_help_test,item_sources_test,growth_ui_test,ui_style_test,npc_lines_test,worlds_test,navigation_test,sheet_test,storage_test`
  (~2 min 10).

## 7. Capturas
Bloco `--aj-09-only`: `i2_09_taskhelp`, Como fazer de um requisito de crescimento (crie `aj_09_taskhelp_growth`),
Como fazer "Você já tem" (crie `aj_09_taskhelp_have`), `b22b_places_list`, `i2_06_npc`, `b17_npc_lais`,
`i2_06_buy`, `a05_fridge_sheet`. Antes e depois nas 3 resoluções.

## 8. Pronto quando
- [x] Como fazer em linhas com um verde só (no primeiro passo que falta); sem `ReadyCardPanel`/`GOOD`/`BAD`.
- [x] Lugares em `list_card` sem verde por linha.
- [x] Conversa sem nome/retrato repetidos; serviços centralizados.
- [x] Compra bloqueada nítida, com `lock_hint` só no rodapé.
- [x] Nenhum nome de coisa em `SectionLabel` nestes quatro painéis.
- [x] Testes verdes.

## 9. Handoff
Pontos naturais: após 5.1, 5.2, 5.3, 5.4. O Como fazer é o maior: se parar no meio, diga quais casos de
`TaskHelp.describe` já estão no visual novo.

## 10. Registro

Concluída por Codex em 25/10/2026. Registro completo, provas por item, checklist, testes,
capturas e decisões no README do plano, entrada **Etapa 09**. Próxima: 10, não iniciada.

```
**Etapa 09 (data, executor[es]):** Como fazer em list_card com um verde no primeiro passo que falta; Lugares em
linhas; conversa sem repetições e serviços centralizados; compra bloqueada nítida com lock_hint. Testes … PASS
em … s. Pendências: … Sem push.
```
