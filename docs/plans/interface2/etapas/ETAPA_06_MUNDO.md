# Etapa 06 — Mundo: mapa sem texto, balões, alfinete, mundos em cartões-postais e conversa

> Tamanho: grande. Depende de: 05. Próxima: 07.
> Resultado que o Vitor vê: os mapas **sem os nomes escritos**; balões lisos (andando, pronto ✓, comprar);
> brilho ✦ em lugar novo; tocar e segurar mostra o nome; o **alfinete** no lugar da seta amarela; a lista de
> mundos em **cartões-postais**; conversa com personagem no visual novo.

## 1. Ler antes
`02_JORNADA.md` §1.1 (mapas sem texto), §2.1 (alfinete), §8 (conversa), §10 (compra); `03_TELAS.md` "Mundo";
protótipos `prototipo/horta_seta.png` (alfinete), `mundos.png` (cartões), `fogao.png` (barra do mundo).

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Etiquetas | `room.gd:624` `_spawn_labels` (uma `WorldLabel` por `label` em zones/objects/regions, com metas `anchor`, `tap_data`, `detail_label`, `overview_label`, `requirements`, `upgrade`/`locked_upgrade`, `hide_seen`), `room.gd:713` `_place_labels` (importante = compra disponível/alvo de missão/`place_alert`/`npc_badge`; `reveal(eligible and shown)`), `present_labels()` + `GameState.note_label_visit(world)` (2 primeiras visitas) | sempre visíveis |
| Toque em etiqueta | `room.gd:1233` `_tap_label` (chamado em `_handle_tap`, antes de regiões, NPCs, objetos e zonas) | etiqueta é alvo de toque |
| Outros alvos | `_handle_tap` (`room.gd:1125`): montinho, balões (`_tap_balloon`), amigo, etiqueta, `PurchaseMarker` de região, polígono de região fechada, NPC, Tiro, sprites (do mais à frente), zonas (polígono) | — |
| `WorldLabel` | `scripts/ui/world_label.gd` (é `Label`; `restyle`, `reveal`, `set_world_zoom`, desenha o ícone 16) | pílula `PAPER` 90%, borda na cor do mundo se importante |
| Balões | `scripts/ui/world_balloon.gd` (`DIAMETER 44`, estados `progress/ready/queued/buy/alert`, `_draw`, `hit_rect`, `caption`/`show_caption`, `set_zoom`); filhos de tipo: `PlotIndicator`, `StationIndicator`, `RouteIndicator`, `WalkIndicator` | desenho próprio em `_draw` |
| Seta | `room.gd:1044` `point_at(action, seconds = 5.0)`: `Node2D` "Pointer" com `Polygon2D` amarelo + contorno, pula; `clear_pointer()` | testes procuram `find_child("Pointer")` (`intro_test:64`, `tasks_test:174`, `tray_test:642`) |
| Barra do mundo | `worlds_screen.gd` `_build_world_bar` (`WorldBar`, `MapButton`=`WorldPill`, `PlacesButton`, `WorldTitle`, `NpcRow` de `NpcFace`) — a 03 já a pôs na linha 2 | `WorldPill` (44, borda 2 na cor do mundo, seta desenhada), `NpcFace` (48) |
| Seletor | `world_selector.gd` (`chosen`, `closed`, `open/refresh/dismiss`, fundo escurecido) + `world_card.gd` (`WorldCard_<mundo>`, linha 72/64, ícone 40, `Places.world_summary`, `_locked_hint`) | lista "executiva" |
| Conversa | `progression_ui.gd` `npc_view(npc)`, `npc_introduction(npc, i)`, `npc_header` (retrato 96 + `SpeechBubble`), serviços como `UiKit.button` grandes | — |
| Testes | `world_view_test` (etiquetas fixas ao arrastar; etiqueta de área fechada no centro do polígono), `farm_market_label_test` (etiqueta "venda" visível, dentro da tela, sem cobrir outras), `balloon_test`, `world_selector_test`, `intro_test`, `npc_lines_test` | mudam junto (§6) |

## 3. Passo a passo

### 3.1 Mapa sem texto
1. `_place_labels`: as etiquetas ficam **escondidas** por padrão (`reveal(false)`), inclusive nas primeiras
   visitas (some a apresentação de `present_labels`; mantenha `note_label_visit` sem efeito visual ou
   remova a chamada — o `GameState` não muda). `_spawn_labels` continua criando as `WorldLabel` (são o
   balãozinho do "segurar" e guardam `tap_data`).
2. `_tap_label`: deixa de ser chamado em `_handle_tap` (etiqueta escondida não recebe toque). **Antes de
   desligar**, rode a auditoria do teste (§6, caso 1): toda etiqueta com `action` precisa ter outro caminho
   de toque (sprite com a mesma `action`, zona, polígono de região). Se alguma não tiver, **acrescente o
   polígono de toque no JSON da sala** (`zones` com `polygon` e a `action`) em vez de manter a etiqueta.
3. **Tocar e segurar** (500 ms parado, sem passar do `TAP_SLOP`): `_gui_input` arma um `Timer` no
   `pressed`; se disparar, procure o alvo no ponto com uma consulta **sem efeito** (`_target_at(point) ->
   Dictionary` com `{label: WorldLabel, sprite: Sprite2D}`, reaproveitando a ordem do `_handle_tap`) e mostre
   aquela `WorldLabel` por 1,5 s (`reveal(true)` e depois `reveal(false)`), com `Haptics.tap()`; o `released`
   seguinte é engolido (`_swallow_touch = true`), para não agir. Sem alvo: nada.
4. **Brilho ✦ de lugar novo:** para cada etiqueta com `action` `place:<id>` cujo lugar está liberado
   (`Places.place_error(place) == ""`, compra feita quando houver `upgrade`) e que nunca foi tocado
   (`progress.seen["ui:place_tapped:<mundo>:<id>"]` ausente), mostre um `WorldBalloon` novo no estado
   **`spark`** (disco mel 26 com `ctl spark` branco, pulinho a cada 2 s) na âncora da etiqueta. Ao tocar o
   lugar (`_on_object_tapped` com `place:<id>`), grave a marca e some o brilho. Saves novos: os lugares do
   começo já nascem marcados (`seen` preenchido na primeira entrada no mundo, para não acender tudo de uma vez).
5. Áreas fechadas: sem nome; só o cadeado (balão `buy` com preço, já existe) no centro.

### 3.2 Balões (`WorldBalloon._draw` e filhos)
Disco **branco** (alfa 0,95) com sombra suave desenhada (círculo `SHADOW` deslocado 2 px), anel 4 px:
`progress` = trilho `SUNKEN` + arco `SKY`; `ready` = anel `GO` cheio + disquinho verde com `ctl check`
(textura, filtro linear) no canto; `queued` = arco tracejado `SKY`; `buy` = disco `HONEY` com `ctl plus`
branco e o preço (`caption`) num chip `CARD` embaixo; `alert` = `UiKit.dot` vermelho; **`spark`** (novo, §3.1).
Ícone do produto no meio como hoje. `hit_rect`, `set_zoom`, `show_caption` e o pulinho continuam.

### 3.3 Alfinete (`point_at`)
1. Crie `game/scripts/ui/world_pin.gd` (`class_name WorldPin extends Node2D`) que desenha em `_draw`:
   rabinho (triângulo `HONEY` 18×12) apontando para baixo; disco `CARD` 52 com anel `HONEY` 4 px e sombra; o
   ícone do destino (36) no meio — escolha o ícone como o `QuestDestination` da 05 faz (lugar → ícone do
   lugar; `npc:` → retrato; `buy:` → ícone da construção; canteiro → ícone da semente/`action_water`);
   e no chão, centrado na base do objeto, uma elipse `HONEY` 3 px com fundo `HONEY` 18% e uma segunda
   elipse que pulsa (escala 1 → 1,25, alfa 0,5 → 0, 1,2 s, em laço). O disco balança 6 px (1,4 s, seno).
   `Motion.reduced`: parado.
2. `point_at` cria o `WorldPin` com `name = "Pointer"` (os testes procuram esse nome), `z_index` 5 absoluto,
   escala `1/zoom` (como hoje), na mesma âncora de hoje; a base do anel é a posição do sprite/zona.
   `clear_pointer`, `seconds` e as regras de sumir continuam.

### 3.4 Barra do mundo
`WorldPill`: pílula `CARD` 44 com sombra, ícone do mundo 32, nome `StrongLabel`, `ctl down` 18 em `INK_SOFT`
(sem borda colorida grossa). `NpcFace`: disco `CARD` 44 com sombra, retrato 40, selo `!`/✓ como
`UiKit.badge`/disquinho verde. `PlacesButton`: `UiKit.ctl_button("list", …, 40)` na coluna da direita
abaixo dos rostos.

### 3.5 Lista de mundos em cartões-postais
1. **Miniaturas:** `tools/world_thumbs.gd` (roda com janela: `& $env:GODOT_BIN --path game --resolution
   720x480 -s ../tools/world_thumbs.gd`): para cada mundo, monta a sala (`RoomView` com save novo + as
   compras do começo de cada mundo liberadas por `dev_*`), sem HUD/etiquetas/balões, no enquadramento
   inicial, e salva `game/assets/sprites/ui/worlds/<mundo>.png` com 300×200 recortados do meio.
   Commite os PNG + `.import` (filtro nearest). Rode de novo se a arte de um mundo mudar.
2. `WorldSelector`: vira **folha alta** (fundo `PAPER`, canto 28, alça, título "Para onde vamos?" e X), sobre
   véu `SCRIM`; grade de 2 colunas, espaço 12, margem 16; o último ímpar ocupa as duas colunas.
3. `WorldCard` (mantém nome `WorldCard_<mundo>` e `setup/refresh`): cartão branco 20 com 6 px de moldura;
   foto (a miniatura, canto 15, altura 104; largo 92); embaixo ícone do mundo 28 + nome `StrongLabel`;
   sobre a foto, no canto de baixo à esquerda, chips brancos 94%: rosto 20 do personagem com missão + `!`
   (`Places.npc_badge`), `ctl check` verde + número de prontos (`Places.world_summary`). Mundo atual: contorno
   `HONEY` 3 px + chip "Aqui" mel no canto de cima à direita. Fechado: foto em cinza (`modulate` dessaturado
   via shader simples ou textura cinza gerada pela ferramenta: gere também `<mundo>_locked.png`), disco
   branco com `ctl lock` no meio e, embaixo, a linha do `_locked_hint()` + rosto de quem abre, quando houver.
4. Toque único viaja (como hoje); "Aqui" fecha a folha.

### 3.6 Conversa com personagem
`npc_header`: retrato 96 animado (`NpcPortrait`, fora do corpo reconstruído, como hoje) + `SpeechBubble`
solto. `npc_view`: cartão da missão do personagem = o mesmo das linhas de Pessoas (05) já expandido, com
`claim_quest_fx`; serviços do personagem (`services`) como `list_card` de linhas 56 (ícone do lugar, nome,
`ctl chev`) em vez de botões grandes. `npc_introduction`: o balão avança ao tocar nele (`›` pequeno no canto
do balão, `ctl chev`); no fim, `primary("Vamos!")`. Nós `NpcIntroduction`, `NpcPortrait` preservados.

### 3.7 Folha de compra (02 §10)
`ProgressionUi.upgrade_card`: figura grande (ícone da construção 64 em disco `SUNKEN` 96), nome `TitleLabel`,
uma linha de descrição, ganho em `chip(..., "neutral")` (`SpaceChip`, mantido), materiais em chips
`have`/`missing` (tocáveis → Como fazer), e o preço **no botão verde** ("Construir · 40" com a moeda).
Sem moedas/materiais: `lock_hint("Faltam 12", missing = moeda)` tocável. Requisito não cumprido: cartão a
55% + `lock_hint` com o motivo (como hoje).

### 3.8 Tour
`--i2-06-only`: `i2_06_farm` (sem nomes, balões novos), `i2_06_hold` (nome aparecendo ao segurar no
galinheiro), `i2_06_spark` (lugar novo brilhando: Vila com a feira recém-aberta), `i2_06_pin` (alfinete na
bancada: `point_at("place:workbench")`), `i2_06_worlds` (cartões), `i2_06_worlds_locked` (Natureza fechada),
`i2_06_npc` (conversa com a Bloblo com missão), `i2_06_buy` (folha de compra do silo).

## 4. Não fazer
- Mudar câmera, enquadramento, navegação do Tiro, requisitos de lugares ou ordem de compra.
- Apagar as `WorldLabel` (são o balão do "segurar" e guardam `tap_data`).

## 5. Armadilhas
- Etiqueta era o **único** alvo de toque de algum lugar? A auditoria (§6.1) acha; conserte com polígono no
  JSON da sala, nunca reativando a etiqueta.
- O "segurar" não pode atrasar o toque comum: o toque continua agindo no `released` antes dos 500 ms.
- Segurar e arrastar = câmera (cancele o timer ao passar do `TAP_SLOP`).
- `WorldPin` em escala `1/zoom`: confira no zoom mínimo e máximo que o anel do chão fica na base do objeto.
- Miniaturas: gere com o save **novo** + compras básicas, para não mostrar construções que o jogador ainda
  não tem como se fossem dele (a foto é de "como o lugar é").

## 6. Testes

**`game/tests/world_pin_test.gd`** (área `world`):
1. **Auditoria de toque sem etiqueta:** para cada mundo, para cada `WorldLabel` com `tap_data.action` (e
   elegível), ache um ponto de toque **que não seja a etiqueta** (centro do sprite com a mesma `action`, ou
   centroide do polígono da zona/região) e confira que `_handle_tap(ponto)` devolve `true` e leva à mesma
   ação (espie `Places.run`/`_on_object_tapped` por sinal ou por `Events.sheet_requested`/`plot_tray_requested`).
   Liste no `push_error` cada ação sem caminho.
2. Ao entrar no Sítio (save avançado com `dev_unlock_everything`), nenhuma `WorldLabel` visível.
3. Segurar 0,6 s no centro do galinheiro mostra a etiqueta "Galinheiro"; soltar não abre bandeja nem folha;
   depois de 1,6 s a etiqueta some.
4. Toque rápido (pressed + released em < 0,2 s) no galinheiro abre a bandeja como antes.
5. `point_at("place:workbench")` cria um nó `Pointer` que é `WorldPin`; tocar na bancada remove o `Pointer`.
6. Lugar novo: liberar a feira (requisito) → existe um `WorldBalloon` com `state == "spark"` na âncora; tocar
   o lugar grava `ui:place_tapped:<mundo>:<id>` e o brilho some.
7. Seletor: `WorldCard_farm` tem `TextureRect` com a miniatura `ui/worlds/farm.png`; o mundo atual tem o chip
   "Aqui"; `WorldCard_nature` fechado tem o `ctl lock`.

**Atualizar** (mesma garantia, nova forma): `world_view_test._labels` (etiquetas não andam ao arrastar —
continua valendo para a etiqueta mostrada ao segurar; área fechada: o **cadeado/preço** fica no centro do
polígono), `farm_market_label_test` (a venda continua tocável pela zona e o nome aparece ao segurar, dentro
da tela e sem cobrir outras), `world_selector_test` (cartões em vez de linhas; as garantias de toque único,
"Aqui", fechar com X/fundo/Escape continuam), `balloon_test` (estados e `hit_rect` iguais; novo `spark`).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests world_pin_test,world_view_test,world_selector_test,balloon_test,intro_test,farm_market_label_test,npc_lines_test` (~2 min 40).

## 7. Capturas
`--i2-06-only` antes (tour do Mapa como "antes") e depois nas 3 resoluções; compare com `horta_seta.png`,
`mundos.png`, `fogao.png`.

## 8. Pronto quando
- [ ] Nenhum nome escrito nos mapas; tudo continua tocável; segurar mostra o nome.
- [ ] Lugar recém-aberto brilha até o primeiro toque.
- [ ] Alfinete no lugar da seta, igual ao protótipo.
- [ ] Lista de mundos em cartões-postais com fotos; fechado em cinza com cadeado.
- [ ] Conversa e folha de compra no visual novo.
- [ ] Testes verdes; miniaturas e ferramenta registradas em `docs/ART_PIPELINE.md`; `CLAUDE.md`/`AGENTS.md`.

## 9. Registro
```
**Etapa 06 (data, executor):** mapas sem etiquetas (segurar mostra o nome; ✦ em lugar novo; auditoria de
toque: N lugares ganharam polígono), balões lisos, WorldPin no lugar da seta, WorldPill/NpcFace novos,
seletor em cartões-postais com miniaturas (tools/world_thumbs.gd), conversa e compra novas. Testes … PASS
em … s. Pendências: …
```
