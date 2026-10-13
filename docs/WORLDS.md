# Mundos (mini mundinhos) e navegação

> Reorganização de 12/10/2026 (Claude Code): o jogador não precisa adivinhar onde fica cada coisa.
> Regra de ouro: **cada coisa fica no lugar onde estaria no mundo, e a aba Missões leva até lá.**

## Abas
| Aba | O que tem |
|---|---|
| **Tiro** | Tela do Pet (necessidades, carinho, comer, brincar, banho, dormir). |
| **Mapa** | O mundo em que você está (sala tocável) com cabeçalho: botão **Mapa**, nome do mundo, botão **Lugares** ("O que tem aqui?") e os **personagens** dali (verdes com "!" quando há missão pronta). Tocar em "Mapa" (ou na aba de novo) mostra a lista de mundos com miniatura, personagens e avisos ("Canteiros: 2 prontos para colher!"). |
| **Missões** | "O que eu faço agora?": **História** (um passo por vez: rosto de quem pede, ícone + `0/6`, ícone do lugar, ingredientes que faltam em chips tocáveis, recompensa em chips, **Ir** + **?**), **Diárias** (3, renovam à meia-noite) e **Semanais** (2, renovam na segunda). A bolinha vermelha conta o que está pronto. Atributos e Coleção ficam na aba Tiro. |
| **Mochila** | Itens por categoria. Tocar num item: o que ele faz, **como conseguir**, **onde é usado**, quanto vale na feira, "Dar ao Tiro" e "Ir vender". |

## Onde fica cada coisa hoje
| Mundo | Personagens | Lugares (tocar na cena ou em "Lugares") |
|---|---|---|
| **Casa** | — | Tigela, **Cozinha** (fogão + forno + fila extra), Geladeira, porta → Sítio. Sofá = enfeite com soneca (`hidden`). |
| **Sítio da Bloblo** | Bloblo (casinha) | Canteiros (+ estufa), Bancada, Pomar, volta para casa |
| **Vila** | Feirante, Laís, Guia da trilha | **Feira** (barraca; abas Vender/Encomendas; caixas abrem Encomendas; + banca), **Ateliê** (casa da Laís), **Portão da trilha** (passeios + mina; + picareta; abre no capítulo 3) |

Regra (simplificação de 12/10/2026): **3 mundos, no máximo 4 lugares visíveis cada** (`content_test`).
Não existe menu "Construir": cada construção é comprada **no próprio lugar** — `"upgrade"` do lugar
(sem ela, tocar abre a compra; móveis mostram "+") ou `"upgrades"` (cartões de compra dentro do painel).
`Database.place_of_upgrade` acha esse lugar; o "Ir" das missões leva até lá.
A antiga Trilha virou o portão da Vila (a arte `areas/trail/` ficou guardada para um mundo futuro).
Rotas aparecem no lugar do tipo delas (`"place"` em `activities`: `walk`, `mine`, `orchard`).

## Como criar um mundo novo (receita)
1. **Arte:** gere a cena no PixelLab no mesmo estilo (ex.: `create_image_pro` 632x395, sem fundo
   transparente, com `farm.png` como referência de estilo: "ilha isométrica flutuante, fundo escuro").
   Salve em `game/assets/sprites/areas/<mundo>/background.png`. Registre em `docs/ART_PIPELINE.md`.
2. **Sala:** `game/data/rooms/<mundo>.json`:
   ```json
   { "background": "res://assets/sprites/areas/<mundo>/background.png",
     "objects": [],
     "zones": [
       { "id": "barraca", "action": "place:sell", "label": "Vender", "label_pos": [228, 72],
         "polygon": [[165, 120], [245, 85], [290, 140], [215, 222]] },
       { "id": "casa", "action": "npc:artisan", "label": "Artesã", "label_pos": [425, 32], "polygon": [...] }
     ],
     "points": {} }
   ```
   - `zones` = áreas tocáveis do desenho (polígono em pixels da imagem); `label` + `label_pos` =
     etiqueta que mostra ao jogador que dá para tocar ali (fica com o mesmo tamanho em qualquer zoom).
   - Sem `floor` = ninguém anda (só toques). Com `floor` + `points.dog_start` o Tiro passeia lá
     (ver casa). Móveis separados vão em `objects` (ver `CLAUDE.md`, "Ambientes").
   - Para achar coordenadas: abra a imagem, ou gere uma prévia com `tools/pixel_tools.ps1`.
3. **Mundo:** entrada em `game/data/worlds.json`:
   ```json
   "praia": { "name": "Praia", "icon": "tab_beach", "description": "...", "room": "praia",
              "requirements": { "owned": ["boat"] },
              "npcs": ["fisher"],
              "places": { "fish": { "name": "Pescar", "icon": "...", "description": "...", "panel": "routes:fish" } } }
   ```
   - `requirements` usa o formato comum (`owned`/`quests`/`skills`/`chapter`); mundo fechado aparece no
     mapa com o motivo.
   - `panel` dos lugares: `station:<id>`, `stations:<id>+<id>`, `inventory`, `feed`, `sleep`, `farm`,
     `market:<sell|orders>`, `routes:<tipo>+<tipo>`, `travel:<mundo>` (lista em `scripts/ui/places.gd`).
     `upgrade` opcional: sem essa construção, tocar abre a compra. `upgrades`: compras dentro do painel.
     `requirements`: lugar fechado até cumprir. `hidden`: fora da lista "Lugares".
     **No máximo 4 lugares visíveis por mundo.**
   - Sem `room`, o mundo ainda funciona: vira uma tela com a imagem `banner` + cartões dos
     personagens e lugares (bom para prototipar antes da arte).
4. **Personagens:** em `game/data/npcs.json` (`name`, `role`, `greeting`, `portrait`, `icon`,
   `services` = lugares do mundo que ele oferece como atalho). Missões em `quests.json` com `"npc"`.
5. **Conteúdo:** rotas (`activities` com `"place"`), construções (`upgrades` com `"world"`),
   receitas/estações etc.
6. **Teste:** `progression_test.gd -- --screenshots` gera `ui_world_<mundo>.png` para os mundos
   da lista do teste (acrescente o novo), e a campanha simulada valida o progresso.

Nenhum código precisa mudar para um mundo novo, a não ser que ele traga um **tipo de painel novo**
(aí: um caso em `Places._panel` + a função que monta o painel).

## Código
| Arquivo | Papel |
|---|---|
| `scenes/ui/worlds_screen/` | Aba Mapa: lista de mundos + mundo atual (instancia `levels/room/room.tscn` por mundo e mantém em memória). `enter(mundo, lugar)`. |
| `scripts/ui/places.gd` (`Places`) | Abre lugares/personagens (`open`, `open_npc`, `run`), lista "O que tem aqui?" (`world_list`) e calcula avisos (`world_alerts`, `npc_alert`, `place_alert`). |
| `scripts/ui/progression_ui.gd` | Painéis: personagem, construir (por mundo), vender, encomendas, rotas, atributos, coleção. |
| `scenes/ui/tasks_screen/` | Aba Missões. |
| `scenes/ui/bag_screen/` + `SheetBuilder.inventory_view/item_detail` | Aba Mochila (e geladeira). |
| `Events.world_requested(mundo, lugar)` | "Ir até lá": `main.gd` troca para o Mapa e entra no mundo; `lugar` = `"<lugar>"`, `"npc:<id>"` ou `"buy:<construção>"`. |
| `Database.npc_world`, `place_with_panel`, `sources_of`, `uses_of` | Consultas de conteúdo usadas pela navegação e pela Mochila. |


## Acesso gradual (Tarefas v2)

Casa e Sítio são abertos. Vila exige `quests: ["first_harvest"]`; o Portão da trilha (lugar da Vila)
exige `chapter: 3`. Pedidos da Vila e rotas de passeio/mina repetem esses requisitos.
O capítulo é derivado das principais recebidas (comprar a geladeira não basta).
A comemoração anuncia mundos recém-abertos; o mapa mostra o motivo dos bloqueios.
Toda missão deve ter um destino válido e acessível quando liberada: valide com
`content_test.gd` e a campanha simulada. `Places.goal_target` produz
`{world, place, hint}` ou `{screen, hint}` para cuidados na aba Tiro.
