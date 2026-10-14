# Etapa 08 — Apetrechos: vestir o Tiro, pet shop e mesa de costura

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_08_apetrechos.md."
> Pré-requisito: Etapas 00–07 feitas.

## Objetivo (o que o jogador sente)
"As coisas raras que eu acho nos passeios aparecem **no Tiro**! Também posso costurar roupinhas com
os materiais dos passeios e comprar umas no pet shop." Resolve D3 (roupas sem desenho) e fecha o
ciclo **passear → materiais/raros → vestir**.

## Como funciona (para o jogador)
1. Coleção → **Roupas**: tocar numa roupa que é sua → **Vestir** / **Tirar**. Um apetrecho por lugar:
   **cabeça**, **pescoço**, **corpo** (três ao mesmo tempo).
2. O Tiro grande (tela do Tiro e aba Desejos) aparece **com as roupas**. No mapa, nada muda (sprite pequeno).
3. Pet shop **Patinhas** na Praça (quiosque): compra (moedas) roupinhas simples, ração e a
   **Bolsinha de passeio** (+1 achado por passeio).
4. **Mesa de costura** dentro do pet shop: transforma materiais de passeio em apetrechos (estação com
   tempo, como o fogão). Ao recolher, a roupa vai direto para a Coleção com festa + "Vestir agora".
5. O cartão de raro do passeio (Etapa 07) ganha o botão **Vestir agora**.

## Parte A — investigação de arte (FAÇA PRIMEIRO, antes de programar)
O Tiro grande tem ~22 animações (`characters/tiro_pet/<animação>/frame_XX.png`, quadros 256×216).
Redesenhar todas com cada roupa é caro. Método escolhido (barato e alinhado):
1. **Base**: `characters/tiro_pet/tiro_pet_idle_front.png` (ou o 1º quadro de `idle_breathe`, que é o
   mais exibido — use o que tiver o mesmo tamanho de quadro das animações).
2. **Gerar o Tiro vestido** com `mcp__pixellab__edit_image_pro_flash`:
```
method: "text", image_url: "upload:<quadro base>", no_background: true, use_color_palette_correction: true,
description: "the exact same yorkshire terrier puppy in the exact same pose and position, now wearing <ROUPA>,
  keep the dog, colors, outline and background identical, only add the accessory"
```
3. **Extrair só a roupa** (pixels que mudaram) com uma função nova em `tools/pixel_tools.ps1`:
   `New-OverlayFromDiff <base.png> <vestido.png> <saida.png> [tolerancia=24]` — para cada pixel, se a cor
   do vestido difere da base (soma das diferenças RGBA > tolerância) copia o pixel do vestido; senão
   transparente. Documente no cabeçalho do arquivo, como as outras funções.
4. Abra a prancha (`New-ContactSheet`) com base + vestido + sobreposição sobre a base. Limpe pixels
   soltos se precisar (pode usar `mcp__pixellab__pixelart_workbench`).
5. **Onde mostrar:** a sobreposição usa o canto do quadro (mesmo tamanho, deslocamento 0). Ela só
   fica certinha nas animações em que o corpo fica no lugar. Monte uma prancha com o 1º, o do meio e o
   último quadro de cada animação **com a sobreposição** e marque em
   `characters/tiro_pet/overlay_anchors.json`:
```json
{
  "show_in": ["idle_breathe", "wag_excited", "head_tilt", "look_around", "yawn", "sad", "pet_head", "pet_paw", "eat", "sniff", "lick_paw", "scratch"],
  "offsets": {"head_tilt": {"head": [0, 0]}, "eat": {"head": [0, 6], "neck": [0, 4]}}
}
```
   Nas animações fora de `show_in` (rolar, girar, pular, barriga para cima) a roupa **some** durante a
   animação e volta no fim. `offsets` (opcional) desloca por lugar (`head`/`neck`/`body`) numa animação inteira.
6. Faça **primeiro só o `red_scarf`** e mostre ao Vitor nas capturas (anote no ROADMAP). Se ficar bom,
   siga com as outras. Se ficar ruim, tente `create_image_pro` com o quadro base como referência
   ("character base") e a mesma descrição, depois a mesma extração.

## Parte B — código

### 8.1 Dados das roupas (`collections.json`)
- [ ] Toda roupa ganha `"overlay": "res://assets/sprites/characters/tiro_pet/overlays/<id>.png"` quando a arte existir.
- [ ] Roupas do pet shop: `"price": <moedas>`, `"shop": "petshop"`.
- [ ] Roupas da costura: `"recipe": "<id da receita>"`.
- [ ] Novas (pet shop): `red_scarf` "Lenço vermelho" (neck, 60), `blue_collar` "Coleira azul" (neck, 80),
  `yellow_bow` "Lacinho amarelo" (head, 50), `rain_coat` "Capa de chuva" (body, 140).
- [ ] Novas (costura): `flower_crown` "Coroa de flores" (head), `shell_collar` "Coleira de conchas" (neck),
  `knit_sweater` "Suéter de tricô" (body), `feather_hat` "Chapéu de pena" (head), `golden_cape` "Capa dourada" (body).

### 8.2 Estado e ações
- [ ] `progress.equipped = {"head": "", "neck": "", "body": ""}` (salvo).
- [ ] `GameState.equip_error(id)`, `equip(id)` (veste no `slot` da roupa, trocando a que estava),
  `unequip(slot)`; contador `equip`.
- [ ] `GameState.buy_cosmetic_error(id)`, `buy_cosmetic(id)` (desconta `price`, dá a coleção, conta `buy_cosmetic`).
- [ ] Coleções com `overlay` vazio: podem ser vestidas? **Não** — mostram "Em breve no Tiro" e
  desabilitam Vestir (evita vestir algo invisível). Prioridade de arte: as 7 raras de passeio, as 5 de
  costura, as 4 do pet shop; depois as antigas (`farm_ribbon`, `trail_bandana`, ...).

### 8.3 Tiro vestido
- [ ] `PetAnimator`: camadas `TextureRect` por cima do Tiro, na ordem corpo → pescoço → cabeça,
  mesmo tamanho/posição do sprite do Tiro; visíveis só nas animações de `show_in` (com `offsets`);
  escondidas dormindo? **Não**: dormindo continua (é fofo de pijama); só some nas acrobáticas.
- [ ] Usado na tela do Tiro, no cabeçalho da aba Desejos e em qualquer retrato do Tiro grande.

### 8.4 Pet shop e costura (Praça)
- [ ] `progression.json → upgrades`:
```json
"petshop": {"name": "Pet shop Patinhas", "world": "park",
  "description": "Roupinhas, ração e coisas de passeio.",
  "cost": 150, "materials": {"stick": 4, "ribbon": 2},
  "requirements": {"quests": ["nina_rare"]}, "icon": "petshop"},
"sewing_table": {"name": "Mesa de costura", "world": "park",
  "description": "Materiais de passeio viram apetrechos.",
  "cost": 100, "materials": {"yarn": 2, "ribbon": 2},
  "requirements": {"owned": ["petshop"]}, "icon": "action_sew", "station": "sewing"},
"walk_bag": {"name": "Bolsinha de passeio", "world": "park",
  "description": "O Tiro traz uma coisa a mais de cada passeio.",
  "cost": 200, "materials": {"yarn": 3, "ribbon": 2},
  "requirements": {"owned": ["petshop"], "stats": {"walk": 10}}, "icon": "action_walk"}
```
- [ ] `config.json → stations.sewing`: `{"name": "Mesa de costura", "slots": 1, "instruction": "Materiais de passeio viram apetrechos."}`.
- [ ] `recipes.json` (campo novo `output_collection`: ao recolher, dá a coleção em vez de item;
  `collect` conta `sew` e `produce:<id>`; se já tem a roupa, devolve os materiais? **Não**: a receita
  fica desabilitada com "Você já tem" — `cook_error` checa):
```json
"sew_flower_crown": {"station": "sewing", "inputs": {"wildflower": 3, "ribbon": 1}, "output_collection": "flower_crown", "seconds": 300, "skill": "adventure", "skill_xp": 20},
"sew_shell_collar": {"station": "sewing", "inputs": {"river_shell": 4, "ribbon": 1}, "output_collection": "shell_collar", "seconds": 480, "skill": "adventure", "skill_xp": 25},
"sew_knit_sweater": {"station": "sewing", "inputs": {"yarn": 4, "color_button": 2}, "output_collection": "knit_sweater", "seconds": 600, "skill": "adventure", "skill_xp": 30},
"sew_feather_hat":  {"station": "sewing", "inputs": {"bird_feather": 2, "yarn": 2, "stick": 1}, "output_collection": "feather_hat", "seconds": 600, "skill": "adventure", "skill_xp": 30},
"sew_golden_cape":  {"station": "sewing", "inputs": {"golden_leaf": 3, "yarn": 2, "moon_pebble": 1}, "output_collection": "golden_cape", "seconds": 1200, "skill": "adventure", "skill_xp": 60}
```
  `output`/`qty` não existem nessas receitas: ajuste `GameState.cook/collect`, `StationIndicator`,
  `SheetBuilder` (ícone = ícone da coleção) e `Database` (usos dos itens: "Costura: Coroa de flores")
  para entender `output_collection`. A `note` dos materiais (Etapa 07) deixa de aparecer quando o
  item passa a ter uso de receita.
- [ ] `walk_bag`: em `collect_walk`, `rolls + 1` se comprado.
- [ ] `worlds.json → park.places.petshop`: `{"name": "Pet shop", "icon": "petshop", "description": "Roupinhas e costura.",
  "upgrade": "petshop", "panel": "petshop", "requirements": {"quests": ["nina_rare"]}}`.
- [ ] Painel `petshop` (novo caso em `Places._panel` → `ProgressionUi.petshop_panel()`), três blocos:
  1. **Costura** (se `sewing_table` comprada; senão cartão de compra): espaço da estação em cima
     (padrão `slot_frame`) + cartões das receitas (ícone 64 da roupa, chips dos materiais tem/precisa,
     tempo, botão Costurar; "Você já tem ✓" quando já é sua);
  2. **Comprar**: cartões das roupas do pet shop (ícone, preço, Comprar/Vestir), **Pacote de ração**
     (5 rações por 15 moedas — item de loja simples: `progression.json → shop_items.dog_food_pack = {"items": {"dog_food": 5}, "price": 15, "shop": "petshop"}`),
     **Bolsinha de passeio** (compra de upgrade);
  3. nada mais (uma tela por vez).
- [ ] `rooms/park.json`: objeto do quiosque com `upgrade: "petshop"`, `action: "place:petshop"`; antes
  da compra o "+" aparece sobre o quiosque vazio do fundo. A mesa de costura aparece dentro/ao lado
  (`upgrade: "sewing_table"`, `station: "sewing"`) com `StationIndicator`.

### 8.5 Missões da Nina
```json
"nina_petshop": {"npc": "nina", "name": "Pet shop novo",
  "dialogue": "Abriu um pet shop no quiosque! Vamos montar com graveto e fita?",
  "goals": [{"type": "owned", "key": "petshop", "label": "Montar o pet shop"}],
  "rewards": {"coins": 40, "collections": ["red_scarf"]},
  "kind": "line", "line": "nina", "order": 50},
"nina_dress": {"npc": "nina", "name": "Desfile na praça",
  "dialogue": "Ganhou um lenço! Veste nele pra gente ver?",
  "goals": [{"type": "stat", "key": "equip", "target": 1, "label": "Vestir um apetrecho no Tiro"}],
  "rewards": {"coins": 20, "affection": 10},
  "kind": "line", "line": "nina", "order": 60, "go": {"screen": "pet", "hint": "Tiro → Coleção → Vestir"}},
"nina_sewing": {"npc": "nina", "name": "Feito à mão",
  "dialogue": "Com flores e fita dá uma coroa linda. Costura uma?",
  "goals": [{"type": "stat", "key": "sew", "target": 1, "label": "Costurar um apetrecho"}],
  "rewards": {"coins": 40, "items": {"ribbon": 2}},
  "kind": "line", "line": "nina", "order": 70}
```
- [ ] `Places.goal_target`: `equip` → tela do Tiro (abre Coleção); `sew` → `park` + `petshop`.
- [ ] Diária `sew`: "Costure 1 apetrecho" só se ainda existir receita disponível (requisito: `owned sewing_table`).
  Se o jogador já tiver todas, a diária não deve ser sorteada (use um requisito que o `routine` checa:
  acrescente `"has_recipe": "sewing"` ou simplesmente não crie essa diária — **recomendado: não criar**).

### 8.6 Arte
**Sobreposições** (Parte A) para cada roupa com arte → `characters/tiro_pet/overlays/<id>.png`.
Descrições para o `edit_image_pro_flash` (`<ROUPA>`):
| id | ROUPA |
|---|---|
| `red_scarf` | "a red bandana scarf tied around its neck" |
| `blue_collar` | "a blue dog collar with a small gold tag" |
| `yellow_bow` | "a small yellow bow on top of its head" |
| `rain_coat` | "a yellow raincoat covering its back" |
| `plaid_bow` | "a small red and green plaid bow on top of its head" |
| `flower_clip` | "a pink flower hair clip on one ear" |
| `bow_tie` | "a navy blue polka dot bow tie under its chin" |
| `sailor_scarf` | "a blue and white sailor neckerchief" |
| `explorer_backpack` | "a tiny brown explorer backpack on its back" |
| `star_glasses` | "yellow star-shaped sunglasses on its face" |
| `glow_collar` | "a collar with small glowing light blue beads" |
| `flower_crown` | "a crown of small white and purple wildflowers on its head" |
| `shell_collar` | "a collar made of small pink seashells" |
| `knit_sweater` | "a cozy pink knitted sweater with colorful buttons" |
| `feather_hat` | "a small brown hat with a sky-blue feather" |
| `golden_cape` | "a shiny golden cape on its back" |
**Ícones 32×32** (receita): `petshop.png` "small pet shop kiosk with striped red and white awning and a paw sign";
`action_sew.png` "sewing needle with pink thread and a wooden spool"; ícones `outfit_<id>.png` das roupas novas
(mesmas descrições da tabela acima, sem o "on its ...").
**Quiosque montado** — `create_object_pro_flash` (receita "Objeto de cenário externo", estilo da praça
`areas/park/park.png`): "small pet shop kiosk with a red and white striped awning, a paw print sign,
shelves with dog toys and a tiny sewing table at its side, isometric 3/4 view, pixel art, no background",
`width: 96, height: 96` → recorte → `areas/park/petshop.png`. Confira encaixe sobre o quiosque vazio do fundo.

## Testes — `petshop_test.gd` (novo)
- [ ] Vestir/tirar salva; uma por lugar; não veste o que não tem; sem `overlay` → erro "Em breve".
- [ ] Comprar desconta uma vez; não compra repetido; pacote de ração dá 5.
- [ ] Costura: consome materiais uma vez, dá a coleção ao recolher, não deixa costurar o que já tem.
- [ ] `walk_bag`: passeio sorteia `rolls + 1`.
- [ ] Teste de dados: toda roupa com `overlay` tem arquivo; `overlay_anchors.json` válido.
- [ ] Cartão de raro mostra "Vestir agora" e veste.

## Capturas
Tiro de lenço (tela do Tiro), Tiro com 3 roupas; animação acrobática sem roupa e voltando; Coleção → Roupas;
pet shop (comprar e costura); cartão de raro com "Vestir agora".

## Lista de conferência (aceite)
- [ ] O Vitor viu e aprovou o lenço antes do resto (anotado no ROADMAP).
- [ ] Raros de passeio aparecem no Tiro.
- [ ] Costura usa só materiais de passeio.
- [ ] CLAUDE.md/AGENTS.md (vestir: `equipped`, overlays, `overlay_anchors.json`, `output_collection`,
  pet shop), `docs/ART_PIPELINE.md` (pipeline das sobreposições), ROADMAP, README; commit.
