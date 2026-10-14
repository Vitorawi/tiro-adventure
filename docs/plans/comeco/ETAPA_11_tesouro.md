# Etapa 11 — O mapa do tesouro (fecha o mistério)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_11_tesouro.md."
> Pré-requisito: Etapas 00–10 feitas.

## Objetivo (o que o jogador sente)
"Juntei os 4 pedaços do mapa que o Tiro foi achando e descobri a Clareira Escondida com um baú!"
Referências: A Short Hike (tesouro fora do caminho), Zelda (pedaços), Stardew (recompensa grande por coleção).

## Como funciona
1. Os pedaços vêm dos achados garantidos (Etapas 05/06): sítio (3º), praça (2º), vila (2º), natureza (2º).
2. Coleção → Achados mostra a **moldura do mapa** com os pedaços encaixando (`3/4`).
3. Com os 4, o **Guia** (Natureza) ganha um passo: "Esse mapa... é da Clareira Escondida! Vamos lá?"
4. A missão abre uma **região nova** na Natureza com um **baú**. Tocar no baú (uma vez): festa grande,
   150 moedas, **Chapéu de explorador** e as **mudas de mirtilo** (cultura nova).

## Passo a passo
- [ ] `quests.json`:
```json
"guide_treasure": {"npc": "guide", "name": "O mapa completo",
  "dialogue": "Esse mapa... é da Clareira Escondida! Vamos lá?",
  "goals": [
    {"type": "have", "key": "map_piece_1", "target": 1, "label": "Pedaço do sítio"},
    {"type": "have", "key": "map_piece_2", "target": 1, "label": "Pedaço da praça"},
    {"type": "have", "key": "map_piece_3", "target": 1, "label": "Pedaço da vila"},
    {"type": "have", "key": "map_piece_4", "target": 1, "label": "Pedaço da trilha"}
  ],
  "rewards": {"coins": 30, "skill_xp": {"adventure": 40}},
  "kind": "line", "line": "guide", "order": 50,
  "requirements": {"quests": ["guide_fibers"]}}
```
  `have` **não consome** (os pedaços ficam no álbum). Confira que `claim_quest` só consome `deliver`.
- [ ] `rooms/nature.json → regions`: região `clearing` (polígono num canto livre do mapa, `label`
  "Clareira escondida", `locked_label: true`, `requirements: {"quests": ["guide_treasure"]}`), e objeto
  `treasure_chest` (`action: "treasure"`, sprite fechado/aberto) dentro dela.
- [ ] `GameState.open_treasure_error()` (`"Já aberto"`, requisito) / `open_treasure()`: aplica
  `progression.json → treasure.rewards`, grava `progress.seen["treasure_opened"] = true`, contador `treasure`.
```json
"treasure": {"rewards": {"coins": 150, "collections": ["explorer_hat"], "unlocks": ["crop:blueberry"], "items": {"bolt": 2}}}
```
- [ ] `RoomView`: ação `treasure` → `open_treasure()` + comemoração (reuse `celebration` com o ícone do baú)
  e troca o sprite para aberto.
- [ ] Mirtilo: `items.json → blueberry` ("Mirtilo", crop, venda 9, `feed` hunger 4 happiness 8, ícone `item_blueberry`);
  `crops.json → blueberry` (`seconds` 900, `coins` 20, `yield {"blueberry": 3}`, sprite `crop_blueberry.png`,
  `skill_xp` 40, `requirements {"quests": ["guide_treasure"]}`); desejo `blueberry` (feed, especial).
- [ ] Ir: `Places.goal_target` para `have:map_piece_N` → onde se cava naquele mundo.

## Arte
- **Baú** — `create_object_pro_flash` (estilo `areas/nature/nature.png`), `width: 48, height: 40`:
  "small old wooden treasure chest with iron bands and moss, closed, isometric 3/4 view, pixel art, no background"
  → `areas/nature/treasure_closed.png`; depois `mcp__pixellab__create_object_state` (ou `edit_image_pro_flash`
  com o fechado: "the same chest open, golden glow and coins inside") → `treasure_open.png`.
- **Clareira**: se o fundo da Natureza não tiver espaço bonito, gere um recorte com `create_image_pro`
  (estilo `nature.png`, "small hidden forest clearing with soft light rays, flowers and a mossy rock", sem fundo)
  e posicione como objeto decorativo da região.
- Ícones 32×32: `item_blueberry.png` ("handful of dark blue blueberries with a green leaf");
  planta `crop_blueberry.png` (receita "Planta madura": "mature blueberry bush growing from a small dark soil mound,
  dark green leaves with clusters of blue berries, cute farm game crop, isometric 3/4 view, pixel art").

## Testes
- [ ] Missão só aparece após `guide_fibers`; fica pronta com os 4 pedaços; não consome os pedaços.
- [ ] Região abre com a missão; baú abre uma vez; mirtilo planta.

## Lista de conferência (aceite)
- [ ] O mistério que começou no minuto ~15 (pedaço 1) termina com uma descoberta visível no mapa.
- [ ] ROADMAP, `docs/WORLDS.md`, ART_PIPELINE, README; commit.
