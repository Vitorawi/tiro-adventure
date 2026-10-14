# Etapa 02 — A caminha do Tiro (primeiro presente, primeira construção)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_02_caminha.md."
> Pré-requisito: Etapas 00 e 01 feitas.

## Objetivo (o que o jogador sente)
"A Laís me deu um presente de verdade, eu escolhi onde pôr e agora o Tiro dorme na caminha dele."
Ensina o "+" de construir logo no capítulo 1, de graça. Resolve D3 (presente invisível).

## Leia antes
`game/data/quests.json` (`lais_bag`), `progression.json → upgrades`, `worlds.json → house`,
`rooms/house.json`, `scenes/levels/room/room.gd` (`_spawn_dog`, marcador "+" de compra),
`scenes/entities/dog_world/dog_world.gd` (`_brain`, `sleep_point`, `_set_on_sofa`).

## Passo a passo

### 2.1 Item e construção
- [ ] `items.json`:
```json
"bed_gift": {"name": "Caminha (presente)", "category": "material", "storage": "none",
  "icon": "res://assets/sprites/ui/icons/item_bed_gift.png"}
```
  (sem `sell_price`: não aparece para vender.)
- [ ] `progression.json → upgrades`:
```json
"dog_bed": {
  "name": "Caminha do Tiro", "world": "house",
  "description": "Um cantinho só dele para as sonecas.",
  "cost": 0, "materials": {"bed_gift": 1},
  "requirements": {"quests": ["lais_bag"]},
  "icon": "item_bed_gift"
}
```
- [ ] A tela de compra já mostra materiais; confira que "0 moedas" aparece como **"Grátis"**
  (se aparecer "0", ajuste o texto do custo no painel de compra para "Grátis" quando `cost == 0`).

### 2.2 Lugar e objeto na casa
- [ ] `worlds.json → house.places.bed`:
```json
"bed": {"name": "Caminha", "icon": "action_sleep", "description": "Soneca do Tiro.",
  "upgrade": "dog_bed", "panel": "sleep", "hidden": true}
```
  (A casa já tem 4 lugares visíveis: tigela, cozinha, geladeira, porta. Por isso `hidden`.)
- [ ] `rooms/house.json → objects`: novo objeto
```json
{
  "id": "dog_bed", "action": "place:bed", "upgrade": "dog_bed",
  "sprite": "res://assets/sprites/areas/house/dog_bed.png",
  "pos": [372, 336], "approach": [352, 346],
  "footprint": [[350, 330], [372, 318], [394, 330], [372, 342]]
}
```
  Os números são **ponto de partida**: posicione no chão livre entre a ilha e o sofá, perto da
  varanda, sem cobrir o caminho do Tiro até a tigela. Gere uma prévia com `tools/pixel_tools.ps1`
  (ou uma captura) e ajuste `pos`, `approach` e `footprint` até ficar natural.
- [ ] `rooms/house.json → points`: `"bed_sleep": [372, 330]`, `"bed_approach": [352, 346]` (ajuste junto).

### 2.3 Tiro dorme na caminha
- [ ] `room.gd → _spawn_dog`: se `GameState.has_upgrade("dog_bed")` e existirem `bed_sleep`/`bed_approach`,
  usar esses pontos como `sleep_point`/`sleep_approach` e marcar `_dog.sleep_climbs = false`
  (a caminha fica no chão: não precisa do "subir no sofá"). Senão, comportamento atual (sofá).
- [ ] `dog_world.gd`: nova `var sleep_climbs := true`; em `_brain`, só chamar `_set_on_sofa(...)` se
  `sleep_climbs`. A animação `sleep` (leste) toca deitado na caminha.
- [ ] Ao comprar a caminha com o Tiro já dormindo no chão, ele deve ir para a caminha no próximo ciclo
  (o `RoomView` já atualiza objetos após compra; confira que os pontos também são atualizados —
  chame uma função `refresh_sleep_points()` do `RoomView` no `state_changed`).
- [ ] Prioridade quando tiver as duas coisas (caminha e sofá): **caminha**.

### 2.4 Missões da Laís
- [ ] `quests.json → lais_bag.rewards`: `{"coins": 10, "items": {"bed_gift": 1}}`.
  Fala continua: "Deixei um presente na sua mochila. Dá uma olhada!"
- [ ] Nova missão (capítulo 1, depois de `lais_bag`, que agora tem `order` 50):
```json
"lais_bed": {
  "npc": "lais", "name": "Um cantinho para ele",
  "dialogue": "É uma caminha! Escolhe um cantinho da casa pra ela.",
  "goals": [{"type": "owned", "key": "dog_bed", "label": "Pôr a caminha na casa"}],
  "rewards": {"coins": 10, "affection": 5},
  "kind": "main", "chapter": 1, "order": 60,
  "go": {"world": "house", "place": "buy:dog_bed", "hint": "Casa → toque no +"}
}
```
- [ ] O sítio passa a abrir **depois da caminha**: troque `"lais_bag"` por `"lais_bed"` em
  `worlds.json → farm.requirements`, `worlds.json → house.places.door.requirements`,
  `rooms/house.json → zones[door].requirements`, `npcs.json → bloblo.requirements`,
  `quests.json → bloblo_meet.requirements` e em `settings.welcome_requirements` (Etapa 01).
  `features.bag` continua em `lais_play`.
- [ ] O "Ir" de `owned` já leva ao "+" (`buy:dog_bed`). Confira a seta apontando o "+" da caminha.

### 2.5 Arte
- [ ] **Sprite da caminha** — `mcp__pixellab__create_object_pro_flash`:
```
n_directions: 1, view: "low top-down", width: 64, height: 48,
style_image: {"url": "upload:<game/assets/sprites/areas/house/room.png>",
  "usage_description": "match the palette, outline thickness, shading and isometric 3/4 angle of this apartment floor"},
description: "round plush dog bed lying on the floor, soft beige cushion with a thick chocolate-brown rim,
  a small white bone-shaped pillow inside, isometric 3/4 view seen from above, cozy, pixel art, no background"
```
  Recorte (`Invoke-TrimSprite`) → `game/assets/sprites/areas/house/dog_bed.png` (~44×30).
  Compare na prancha com `bowl.png` e `sofa.png`: a caminha deve ser um pouco maior que o Tiro deitado
  e bem menor que o sofá. Se sair de frente (não isométrica), use `create_image_pro` 64×48 com
  referências `[{"url": "upload:<sofa.png>", "usage": "isometric angle and style"}, {"url": "upload:<room.png>", "usage": "palette and floor perspective"}]`.
- [ ] **Ícone** `item_bed_gift.png` — receita "Ícone 32×32": "game inventory icon: round plush dog bed,
  beige cushion with brown rim, tied with a red gift ribbon, cute, bold outline, centered, no text".
- [ ] Registrar os dois no `ART_PIPELINE.md`.

## Testes
- [ ] `intro_test`/`npc_lines_test`/`progression_test`: incluir `lais_bed` no caminho (campanha simulada compra a caminha).
- [ ] Teste novo (pode ficar em `world_life_test`): com `dog_bed` comprado, `sleep_point` = `bed_sleep`;
  sem caminha = sofá/chão; comprar consome o `bed_gift` e não custa moedas.
- [ ] `content_test`: `dog_bed` tem sprite existente; `bed_gift` sem `sell_price`.
- [ ] `onboarding_test` continua passando.

## Capturas
Casa antes (com "+") e depois (caminha), Tiro dormindo na caminha, tela de compra "Grátis".

## Lista de conferência (aceite)
- [ ] A Mochila mostra a caminha como presente; a missão aponta o "+"; comprar é grátis e consome o presente.
- [ ] A caminha aparece no mapa e o Tiro dorme nela.
- [ ] O sítio só abre depois da caminha.
- [ ] ROADMAP, ART_PIPELINE, README marcados; commit `feat: caminha do Tiro como primeiro presente`.
