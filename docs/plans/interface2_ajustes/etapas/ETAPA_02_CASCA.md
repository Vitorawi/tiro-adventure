# Etapa 02 — Casca: aviso, folha, Texto maior, vãos e seletor

> Tamanho: médio. Depende de: 01. Próxima: 03.
> Itens da revisão: **1** (aviso cobre o título da folha), **2** (folha da conversa cortada), **3** (Texto
> maior quebra HUD e Configurações), **5** (dica de bloqueio com gramática errada), **18** (título "Mochila"
> e vão da linha 2), **21** (`WorldBar` aparece atrás do seletor).
> Resultado que o Vitor vê: o aviso nunca encosta no título de uma folha; a conversa mostra tudo até o
> último botão; com "Texto maior" o perfil e as moedas não se sobrepõem; o seletor de mundos diz "Depois de:
> …" numa linha certa; Mochila e Missões sem título solto nem vão vazio.

## 1. Objetivo
Consertar a casca (HUD, `Notice`, `Sheet`, seletor), da qual as bandejas e todos os painéis das próximas
etapas dependem. Por isso vem antes do resto.

## 2. Ler antes
`REVISAO_OPUS.md` itens 1, 2, 3, 5, 18, 21; `02_JORNADA.md` §3 (rodapé/abas sem título) e §5 (aviso:
"posição única, logo abaixo da segunda linha do HUD"); `03_TELAS.md` "HUD" e "Mochila"; protótipo
`prototipo/mundos.png`.

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scenes/main/main.gd` (`notice_top`, `_check_row2`, `NOTICE_Y = 136`) | 1, 18 |
| `game/scenes/ui/sheet/sheet.gd` (`_target_height`, `_queue_fit`, `TALL = 0.88`) | 1, 2 |
| `game/scenes/ui/worlds_screen/worlds_screen.gd` (`toast_top`, `WorldBar`) | 1, 21 |
| `game/scripts/ui/hud.gd` (`HudProfile`, `CoinsPill`, `set_row2_shown`, `HEIGHT = 128`) | 3, 18 |
| `game/scripts/ui/settings_panel.gd`, `game/scripts/ui/large_text.gd` | 3 |
| `game/scripts/ui/world_card.gd` (`_locked_hint`), `game/data/worlds.json` (`map_locked_hint`) | 5 |
| `game/scenes/ui/bag_screen/`, `game/scenes/ui/tasks_screen/tasks_screen.gd` | 18 |
| testes: `notice_test`, `sheet_test`, `text_budget_test`, `hud_test` (casos novos) | 1, 2, 3, 18 |

`worlds.json → map_locked_hint` é a **única** mudança de dado permitida (texto de interface, não fala).

## 4. Como está hoje (estado esperado ao começar)
- `main.gd:226 notice_top()` usa `NOTICE_Y` (136) ou a posição abaixo do banner de atualização; no Mapa,
  `maxf(y, WorldsScreen.toast_top())`. `toast_top()` (`worlds_screen.gd:87`) mede `MapButton` e `NpcRow`,
  que ficam **atrás** do seletor quando ele está aberto (evidência `b05_map_list` em 360 e 412).
- `_check_row2()` (`main.gd:243`) já esconde a linha 2 com folha, seletor, `ActionTray`, `FarmDock` ou
  viagem: a faixa que ela ocupava fica livre — é ali que o aviso deve nascer com folha aberta.
- `sheet.gd`: `TALL = 0.88` da tela; `_target_height()` mede `chrome + conteúdo`; `_queue_fit()` já está
  ligado a `_content_holder.minimum_size_changed` (linha 55) e a `resized`, **mas** tem guardas
  (`_fitted`, `RESIZE_MIN`, `overflowing`) que podem ignorar o crescimento. A revisão supôs que a ligação
  faltava; ela existe. **Reproduza antes de corrigir** (§5.2).
- Com "Texto maior" (`LargeText.apply(true)`, ×1,15), `HudProfile` e `CoinsPill` se sobrepõem
  (`i2_11_pet`, `i2_11_tasks`, `i2_11_stove_tray`) e as Configurações perdem a margem (título a x = 8).
- `world_card.gd _locked_hint`: `"Após " + nome da missão` ("Após Uma encomenda da vizinhança").
  A compra bloqueada já usa "Depois de: Mãos na terra". A Natureza já tem `map_locked_hint`.
- Mochila tem um título "Mochila" solto depois de um vão (`b04_bag`); Missões com a história concluída
  deixa a linha 2 vazia (vão de ~50 px, `i2_11_tasks`).

## 5. Passo a passo

### 5.1 Aviso abaixo do HUD, nunca sobre a folha (item 1)
1. `notice_top()`: se folha, seletor ou bandeja estiverem abertos (reaproveite a condição de `_check_row2`
   numa função `_row2_hidden() -> bool`), o aviso nasce em `Hud.HEIGHT - <altura da linha 2> + margem`,
   isto é, na faixa da linha 2 recolhida. Sem nada aberto, fica como hoje.
2. `toast_top()` devolve `0.0` com o seletor aberto (os controles medidos estão atrás dele).
3. `Sheet._target_height()`: o topo da folha nunca sobe acima de `Hud.HEIGHT`: troque o `usable * TALL`
   fixo por `size.y - Hud.HEIGHT` (perde ~34 px em 360×780). Mantenha `TALL` para o arrasto, recalculado
   do mesmo jeito (`offset_top` mínimo = `-(size.y - Hud.HEIGHT)`).
4. `notice_test`, caso novo: seletor aberto + aviso de momento → o retângulo do aviso não cruza o título
   da folha; folha alta + aviso de erro → idem.

### 5.2 Folha que acompanha o conteúdo (item 2)
1. Reproduza num caso do `sheet_test`: abrir uma folha pequena; dois quadros depois, acrescentar filhos ao
   conteúdo (como o `SheetBuilder._schedule_rebuild` faz na conversa em `state_changed`). Meça `_height`.
2. Ache qual guarda descarta o crescimento (`_fitted` ainda falso, `RESIZE_MIN`, `overflowing` medido
   contra a rolagem antiga, ou o sinal vindo do holder e não do conteúdo reconstruído) e conserte **essa**
   guarda. Ligar também o `minimum_size_changed` do conteúdo novo, se for ele que muda.
3. Folga inferior fixa de 16 px no fim da rolagem (a última linha nunca encosta na borda).
4. O caso do `sheet_test` confere: a altura acompanha até o limite do §5.1 e nunca encolhe por oscilação.

### 5.3 Texto maior sem sobreposição (item 3)
1. `HudProfile`: nome com reticências (`text_overrun_behavior`) e largura mínima; `CoinsPill` cresce para a
   esquerda até encostar no perfil, nunca por cima. Uma linha de cálculo, sem números mágicos por fonte.
2. `SettingsPanel` e linhas de saves: textos com `autowrap_mode` e `size_flags` que não alargam a folha;
   nada com largura mínima maior que a folha menos 2 × 16.
3. `text_budget_test` ganha checagem geométrica com Texto maior em 360×780: retângulo de `HudProfile` ∩
   `CoinsPill` vazio; conteúdo da folha de Configurações sem rolagem horizontal e com margem ≥ 16.

### 5.4 "Depois de:" no seletor (item 5)
1. `_locked_hint` → `"Depois de: " + nome` (mesmo formato da compra). Uma linha; se passar de duas linhas
   em 360, use o `map_locked_hint`.
2. `worlds.json`: `map_locked_hint` escrito à mão para Praça, Vila e Sítio, no tom do protótipo ("Depois do
   baú da Nina"): curto, com quem abre. Rosto de quem abre ao lado, se o cartão já tiver espaço para ele.
3. `texts_test` continua verde (textos novos passam pelo glossário).

### 5.5 Sem título de tela e sem vão (item 18)
1. Regra: **sem título de tela** (a aba ativa do rodapé já diz). Tire o título "Mochila".
2. Quando a pílula do próximo passo não existe (história concluída), a linha 2 recolhe
   (`Hud.set_row2_shown(false)` via `_check_row2`) e o conteúdo da tela sobe. Vale para Mochila e Missões.
3. `hud_test`/`next_step_test`: caso "história concluída → linha 2 recolhida e conteúdo começa em ≤ 136".

### 5.6 `WorldBar` atrás do seletor (item 21)
Com o seletor aberto, `WorldBar` (pílula e rostos) fica invisível; volta ao fechar. Nenhum pedaço de "Sítio"
no topo (`i2_06_worlds`).

### 5.7 Armadilhas
- `Hud.HEIGHT` é constante de classe; não referencie `Hud` por tipo em teste `-s` se ele depender de autoload.
- A folha alta menor muda capturas de quase todo painel: é esperado; confira só que nada ficou cortado.
- `world_selector_test` confere a dica em ≤ 2 linhas na linha de 64: não aumente fonte.

## 6. Testes
- Lista: `notice_test,sheet_test,hud_test,text_budget_test,next_step_test,world_selector_test,worlds_test,lists_test,texts_test,tasks_test`
  (~3 min 10).
- `tools\test.ps1 -Level etapa -Exact -Tests <lista> -DryRun`, depois sem `-DryRun`.

## 7. Capturas
Bloco `--aj-02-only`: `b05_map_list`, `i2_06_worlds`, `i2_06_worlds_locked`, `b17_npc_lais`, `i2_06_npc`,
`b04_bag`, `b03_tasks`, e as telas do `--i2-11-only` com Texto maior (`i2_11_pet`, `i2_11_tasks`,
`i2_11_stove_tray`, `i2_11_settings`). Antes (`aj_02_antes`) e depois nas 3 resoluções.

## 8. Pronto quando
- [x] Nenhuma captura com aviso cruzando título de folha; folha alta começa em ≥ 128.
- [x] `b17_npc_lais` mostra a conversa inteira até o último botão, com folga embaixo, nas 3 resoluções.
- [x] Texto maior: perfil e moedas sem interseção; Configurações com margem 16 e sem rolagem lateral.
- [x] Seletor: "Depois de: …" ou dica própria, em ≤ 2 linhas.
- [x] Mochila sem título; Missões/Mochila sem vão com a história concluída.
- [x] `WorldBar` invisível com o seletor aberto.
- [x] Testes verdes; `git diff --stat` em `game/data/` só toca `worlds.json` (`map_locked_hint`).

## 9. Handoff (pontos naturais de parada)
Um ponto por subseção (5.1 … 5.6). Os §5.1 e §5.2 mexem no mesmo `sheet.gd`: se parar entre eles, diga
qual guarda do `_queue_fit` foi mexida e o resultado do caso novo do `sheet_test`.

## 10. Registro
```
**Etapa 02 (data, executor[es]):** aviso na faixa da linha 2 com folha/seletor/bandeja; folha alta até o HUD
(…); causa da folha cortada: … ; Texto maior sem sobreposição; "Depois de:" e dicas próprias (Praça, Vila,
Sítio); sem título na Mochila e linha 2 recolhida sem pílula; WorldBar oculta com seletor. Testes … PASS em
… s (log …). Capturas aj_02_*. Pendências: … Sem push.
```
