# Plano de execução — Linhas de missões por NPC (Laís + vovó Bloblo)

> Escrito em 13/10/2026 (Claude Code), para Claude Code **e Codex** continuarem.
> Design (o quê e por quê): `docs/plans/QUESTLINES.md`. Este arquivo é o **como**: fases,
> arquivos, formato dos dados e critérios de pronto. Marque `[x]` ao concluir cada item e
> registre o andamento em `docs/ROADMAP.md → Estado atual`.

## Decisões já tomadas com o Vitor (não reabrir)
- **Save zerado:** sobe `SAVE_VERSION` e o save antigo é descartado (sem migração).
- **NPC = pessoa que mora numa região**, dona de uma linha de missões. Não é mais "serviço".
- **Laís** trouxe o Tiro, conduz a **história principal** (capítulos) e **fica só na Casa**.
- **Bloblo é a vovó do sítio**, fica **só no Sítio**, tem a linha dela (horta → animais).
- **Paralelismo:** um passo ativo **por linha**, ao mesmo tempo. Cruzamentos travam só o passo.
  Lugares já abertos evoluem livremente (canteiros, vagas, níveis, animais).
- **Ordem:** cuidar do Tiro → Mochila → conhecer a Bloblo (abre Sítio e canteiros) →
  Geladeira → Fogão → **ensopado** entregue à vovó → Vila (vender) → Natureza (madeira) →
  Bancada (tábuas) → abrigos de animais (**moedas + tábuas**).
- A casa **começa sem fogão e sem geladeira**.
- **Ensopado simplificado:** 2 cenouras + 1 batata (receita `vegetable_soup`, renomeada "Ensopado").
- **Arte:** Bloblo andando = personagem PixelLab **"Senhora de Verde"** (por enquanto, mínimo de
  animação). Laís andando = personagem novo criado no PixelLab a partir do **"Laís Avatar"**
  (só rosto). Retrato da Laís = rotação `south` do "Laís Avatar".
- **Feirante, Guia e a antiga Artesã ficam como estão por enquanto.** A antiga Artesã (`artisan`)
  se chamava "Laís": passa a se chamar **"Artesã"** para não haver duas Laís.

## Modelo de dados

### `quests.json`
```jsonc
"lais_feed": {
  "kind": "main",            // linha da Laís = história (usa "chapter" + "order")
  "npc": "lais",
  "chapter": 1, "order": 2,
  "name": "Hora de comer",
  "dialogue": "Ele está com fome. Enche a tigela?",  // fala curta (1 linha)
  "goals": [{"type": "stat", "key": "feed", "target": 1, "fresh": true, "label": "Alimentar o Tiro"}],
  "rewards": {"coins": 10}
},
"bloblo_meet": {
  "kind": "line",            // linha secundária: um passo ativo por vez, em "order"
  "line": "bloblo",
  "npc": "bloblo",
  "order": 1,
  "requirements": {"quests": ["lais_bag"]},   // quando a linha (ou o passo) pode começar
  "dialogue": "Oi! Amigo da Laís é meu amigo. Vem ver as plantações!",
  "goals": [{"type": "stat", "key": "talk:bloblo", "target": 1, "label": "Falar com a vovó Bloblo"}],
  "rewards": {"coins": 10}
}
```
- Passo ativo de uma linha `line` = primeira missão não recebida em `order`, desde que os
  `requirements` estejam cumpridos (senão a linha fica "esperando", sem cartão).
- `fresh` passa a usar a base **por linha**: `progress.steps[line] = {quest, base}`
  (substitui `progress.step`).

### Objetivos novos
| type | valor | uso |
|---|---|---|
| `stat` `talk:<npc>` | conversas abertas com o NPC | "Falar com a Laís/Bloblo" |
| `stat` `open:bag` | vezes que a Mochila foi aberta | "Abrir a Mochila" |
| `quest` (key = id) | 1 se a missão já foi recebida | cruzamento entre linhas |

### `npcs.json`
```jsonc
"lais": {
  "name": "Laís", "role": "Trouxe o Tiro para você",   // o mundo vem de worlds.json → npcs
  "portrait": "res://assets/sprites/characters/npc_lais/portrait.png",
  "sprite_dir": "res://assets/sprites/characters/npc_lais/",   // rotations/ + walk/<dir>/
  "greeting": "Oi! Vamos cuidar do Tiro juntos?"
}
```
`requirements` continua controlando quando o NPC aparece. O NPC só anda na sala que tiver
o ponto `"npc_<id>"` em `rooms/<room>.json → points` (ex.: `"npc_lais": [x, y]`).

### `config.json → farm`
`"lent_plots": [{"count": 1, "requirements": {"quests": ["bloblo_meet"]}}, {"count": 3, "requirements": {...}}]`
= canteiros emprestados pela vovó antes da Escritura. `accessible_plots()` usa o maior `count`
liberado (0 antes de conhecer a Bloblo). Depois da Escritura (`farm`) vale `unlocked_plots`.

## Fase 1 — Estrutura + Laís cap. 1–5 + vovó B1–B7  ✅ feita (13/10/2026, Claude Code)
- [x] **Estado:** `ProgressionState.lines()`, `line_quests(line)`, `current_line_quest(line)`,
      `active_steps()` (`{"main": id, "bloblo": id}`), `quest_line(id)`, `steps` por linha;
      `quest_unlocked` aceita `kind: "line"`.
- [x] **GameState:** `talk_to(npc_id)` (conta `talk:<id>` e marca os passos do NPC como vistos),
      `note_screen_opened(tela|mundo)` (`open:bag`, `open:village`, conta só a 1ª vez), goal `quest`,
      `_step_base`/`_sync_step` por linha, `accessible_plots` com `lent_plots`,
      `_dev_complete_quest` conclui passos anteriores da linha e os cruzamentos.
- [x] **Conteúdo:** `quests.json` reescrito (tabela abaixo); capítulos antigos 5–9 viraram 6–10
      (conteúdo igual, `npc: "lais"`); `progression.json → chapters` 1–5 novos; `features`: Mochila
      após `lais_play`, diárias cap. 4, semanais cap. 5, atributos cap. 6; `worlds.json`: Sítio e porta
      da casa exigem `lais_bag`, Vila cap. 4, Natureza/portão cap. 5. Requisitos `{chapter: N}`
      antigos remapeados 2→4, 3→5, 4→6. Geladeira 40 (pede `lais_first_crops`), Fogão 60 (pede
      geladeira), Escritura pede `bloblo_stew`, Bancada = 120 + 6 madeiras (pede `main_4_materials`).
- [x] **Receitas:** `vegetable_soup` = "Ensopado", 2 cenouras + 1 batata, só exige geladeira.
      Batata libera por `requirements.quests: ["bloblo_carrots"]`.
- [x] **NPC no mapa:** `scenes/entities/npc_world/npc_world.gd` (`NpcWorld`): passeia até 140 px de
      casa, balão `!`/`✓` (`Places.npc_badge`), toque → `Places.open_npc`. `RoomView._spawn_npcs`,
      `point_at("npc:<id>")`. Pontos: `house.json → npc_lais`, `farm.json → npc_bloblo`.
- [x] **Conversa:** `ProgressionUi.npc_view` = retrato 96 px + `dialogue` do passo atual + cartão.
- [x] **Aba Missões:** cartão da história + um `LineCard_<linha>` por linha ativa.
- [x] **Revelar aos poucos no mapa:** "+" de compra só aparece quando os requisitos valem.
- [x] **Arte:** Laís = PixelLab "Laís Mapa" (4 direções + walk), retrato = do antigo `npc_artisan`;
      Bloblo = "Senhora de Verde" (4 direções + walk). A antiga Artesã virou "Artesã" sem retrato.
- [x] **Save v11:** qualquer save anterior recomeça do zero; migrações v2–v10 removidas.
- [x] **Testes:** suíte inteira verde (campanha simulada: 139 ciclos, 30 aquisições, 42 missões).
- [x] Docs: `CLAUDE.md`/`AGENTS.md`, `docs/PROGRESSION.md`, ROADMAP.

### Conteúdo da Fase 1 (ids reais; alguns ids antigos foram reaproveitados)
| id | linha · passo | objetivo | recompensa |
|---|---|---|---|
| `welcome` | Laís 1.1 | `talk:lais` | 5 moedas + 2 rações |
| `lais_feed` / `lais_bath` / `lais_play` | Laís 1.2–1.4 | `feed` / `bathe` / `play` (fresh) | 10 moedas cada |
| `lais_bag` | Laís 1.5 | `open:bag` | 10 moedas |
| `lais_meet_bloblo` | Laís 2.1 | `quest` `bloblo_meet` | 10 |
| `lais_first_crops` | Laís 2.2 | `quest` `bloblo_more_crops` | 15 |
| `main_2_fridge` / `first_kitchen` | Laís 3.1–3.2 | geladeira / fogão | 10 / 10 |
| `lais_stew` | Laís 3.3 | `quest` `bloblo_stew` | 20 |
| `lais_village` / `first_sale` / `main_2_order` | Laís 4.1–4.3 | `open:village` / 1 venda / 1 encomenda | 10 / 20 / 25 |
| `lais_forest` / `main_4_materials` / `main_4_bench` | Laís 5.1–5.3 | Bosque / 6 madeiras / bancada | 15 / 30 / 30 |
| `bloblo_meet` | vovó B1 (pede `lais_bag`) | `talk:bloblo` | 5 + 1 canteiro emprestado |
| `first_harvest` | B2 | colher 1 | 10 |
| `bloblo_more_crops` | B3 | colher 3 (fresh) | 10 + 3 canteiros |
| `bloblo_carrots` | B4 | entregar 4 cenouras | 20 + libera batata |
| `bloblo_potato` | B5 | colher batata | 15 |
| `bloblo_stew` | B6 (pede `first_kitchen`) | entregar 1 ensopado | 30 |
| `farm_deed` | B7 | escritura do sítio (180) | 30 |

### Pontos para olhar na próxima rodada
- [x] Canteiros fechados mostram "Vovó" antes da escritura e levam à conversa enquanto
  os requisitos da escritura ainda não valem.
- [x] Atalhos de `services` respeitam requisitos do lugar e compra da construção.
- O sprite andando da vovó não tem o chapéu do retrato (aceito pelo Vitor por enquanto).
- Testar no celular: tamanho do toque na Laís/vovó (escala 0,5 no sítio) e o balão "!".

## Fase 2 — Animais na linha da vovó ✅ feita (13/10/2026, Codex)
- [x] Laís cap. 4 e cap. 5 (feitos já na Fase 1).
- [x] Escritura do sítio na linha da vovó (B7). A Bancada não exige mais `farm`.
- [x] Galinheiro e curral custam **moedas + tábuas** (campo `materials` que já existe nas upgrades, ex.: `{"plank": 4}`); a compra dá o
      **primeiro animal de presente**; produzir pela 1ª vez libera nova variedade
      (`config.animals[*].requirements`).
- [x] Mover as missões antigas de animais (cap. 10) para a linha da Bloblo.

Implementação: galinheiro = 180 moedas + 4 tábuas; curral = 300 + 6 tábuas.
`gift_animal` entrega branca/pintadinha uma vez. Variedades ruiva/caramelo abrem com
2 ovos/leites recolhidos; preta/malhada com 6. B8–B13 usam os ids antigos `main_9_*`
e o novo `bloblo_milk`. B8 espera `main_4_bench`; Laís termina no capítulo 9.

## Fase 3 — Polimento ✅ feita (13/10/2026, Codex)
- [x] Introdução inicial pedida depois da Fase 1: cinco falas da Laís, avatar correto
      acenando, apresentação do Tiro, chegada pela porta e primeira conversa. Implementada
      pelo Claude e revisada pelo Codex em 13/10/2026; `intro_test` cobre fluxo e persistência.
- [x] Balão `✓` verde vs `!` amarelo (feito na Fase 1); badge no botão Mapa (Codex).
- [x] Apresentação da Bloblo em 3 falas na primeira conversa (`introduction` em `npcs.json`),
      persistida em `seen`; Laís mantém a introdução inicial de chegada.
- [x] Animações da Laís ("Acenando sorrindo" ao entregar, "Pedindo algo" ao dar missão).
- [x] Feirante e Guia com linhas próprias (4 passos cada, capítulos 4 e 5).

### Fechamento da Fase 3
- Feirante: `merchant_meet` → `merchant_surplus` (5 produtos vendidos) →
  `merchant_orders` (1 encomenda) → `merchant_regular` (mais 2 encomendas).
- Guia: `guide_meet` → `guide_wood` (lane) → `guide_stone` (quarry) →
  `guide_fibers` (meadow). Coletas contam ao recolher, depois do início de cada passo.
- Nenhuma das linhas novas é requisito da Laís/Bloblo; uma missão ativa por linha.
- Retratos animados em `npcs.json → portrait_animations` (`request`, `complete`).
  `NpcPortrait` permanece vivo enquanto o corpo da conversa atualiza. Aceno usa
  a arte da introdução; pedido usa os 9 quadros existentes de "Laís Avatar".
- Próximo fora deste plano: validar ritmo e toque no celular; avaliar as novas falas.
