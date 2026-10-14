# 01 — Regras do executor, guia de arte (PixelLab) e catálogo de nomes

> Vale para **todas** as etapas. Leia inteiro antes da primeira etapa e volte aqui sempre que for
> gerar arte ou criar um id novo.

---

## A. Regras do executor

1. **Uma etapa por vez.** Não adiante conteúdo de etapas futuras. Se uma etapa citar algo de uma
   etapa futura (ex.: um desejo que depende da Praça), **não crie** esse pedaço agora.
2. Siga o `CLAUDE.md`:
   - estado persistente só no `GameState` (e nas classes de `game/scripts/state/` que ele guarda);
   - toda ação nova = método no `GameState` que devolve `""` (deu certo) ou o motivo (texto pronto
     para toast), **mais** um `*_error()` igual, que a UI usa para desabilitar botões;
   - cada ação chama `_changed()` (salva e emite `state_changed`);
   - conteúdo em `game/data/*.json` (números, nomes, falas), nunca fixo no código;
   - GDScript **sempre tipado**; arquivos `snake_case`; `class_name` `PascalCase`; comentários em português;
   - cena + script com o mesmo nome, na mesma pasta;
   - timers com **timestamps Unix** (`GameState.now()`), nunca contadores por frame;
   - toque: `InputEventMouse*` (o toque chega como mouse);
   - ferramenta de teste: `GameState.dev_*()` começando com `if not BuildInfo.is_dev(): return` + botão no `DevPanel`.
3. **Classes de estado novas** (`scripts/state/*.gd`) seguem o modelo de `StationState`/`ProgressionState`:
   só dados + consultas puras + `to_dict()`/`from_dict()`/`reset`. O `GameState` guarda a instância,
   inclui no `to_dict`/`from_dict` dele e no `reset()`.
4. **Arquivos de dados novos** (`wishes.json`, `finds.json`, `walks.json`, `friends.json`):
   carregados pelo `Database` igual aos outros (veja como `routines.json` é carregado e copie o padrão);
   confira se o `include_filter` do preset Web em `game/export_presets.cfg` já cobre `data/*.json`.
5. **Revelar aos poucos:** todo sistema/aba/lugar novo tem requisito e aparece na tela "Novo!"
   (`progression.json → features` para abas/seções; mundos, lugares e NPCs com `requirements` entram sozinhos).
6. **Texto:** português, curto, ícone + número. Falas: uma frase. Rótulos de objetivo (`label`) são
   instruções curtas ("Regar a plantinha"). Nada truncado: pode quebrar linha.
7. **Mobile primeiro:** base 360×780; alvos de toque ≥ 48 px; botões principais embaixo.
8. **Testes:** rode todos (`powershell -ExecutionPolicy Bypass -File tools/test_all.ps1`), mais os
   novos da etapa. Todo teste novo vai para `tools/test_all.ps1` e imprime `<NOME> TEST: PASS`.
   Use o teste existente mais parecido como modelo (ex.: `tasks_test.gd`, `nature_test.gd`).
   Capturas: rode sem `--headless` com `--resolution 360x780` e `-- --screenshots`, e **abra os PNGs**.
9. **Ao terminar a etapa:**
   - `docs/ROADMAP.md → Estado atual`: bloco novo no topo com o que foi feito, o que ficou pela
     metade, decisões tomadas e o próximo passo (a próxima etapa);
   - se criou sistema/arquivo/pasta novo: atualizar `CLAUDE.md` **e** `AGENTS.md` (mesmo conteúdo;
     linha nova na tabela "Onde trabalhar" e, se for o caso, na "Estrutura") e o doc relevante
     (`docs/PROGRESSION.md`, `docs/WORLDS.md`, `docs/GAME_DESIGN.md`);
   - registrar a arte gerada em `docs/ART_PIPELINE.md` (tabela com asset, job/id do PixelLab, arquivo, recorte);
   - marcar a etapa no `docs/plans/comeco/README.md`;
   - commit local: `feat: <resumo em português>` terminando com a linha de coautoria pedida pelo ambiente.
     **Sem push.**
10. **Windows / acentos:** nunca use `Set-Content`/`Out-File` sem `-Encoding utf8`. Prefira as
    ferramentas de edição de arquivo.
11. **Se travar** (teste que não passa por motivo de design, arte que não sai boa depois de 3
    tentativas): entregue o resto com um marcador provisório (ícone existente), anote no ROADMAP
    o que faltou e siga. Não invente regra nova de design sem anotar.

---

## B. Guia de arte (PixelLab)

### B.1 Fluxo de sempre
1. **Referências locais** (PNG do jogo) vão por upload, nunca por base64 longo:
   chame `mcp__pixellab__get_upload_url`, faça o `curl` que ele mandar com o arquivo, e use o
   `upload:<id>` devolvido em qualquer campo de URL (`reference_images[].url`, `style_image.url`,
   `reference_image_url`...). O link vale 15 min; os uploads ficam 3 dias.
2. Os jobs são assíncronos: crie → espere (`get_image`, `get_object`, `get_character`,
   `wait_for_jobs`) → baixe.
3. Baixe os originais para `build/art_sources/<etapa>/` (pasta ignorada pelo git).
4. **Prancha de revisão** antes de escolher: no PowerShell,
   `. .\tools\pixel_tools.ps1; New-ContactSheet build\preview\<nome>.png 4 <arquivos...>` e **abra**
   a prancha. Escolha o melhor candidato (ou gere de novo, até 3 vezes).
5. **Recorte** bordas transparentes: `Invoke-TrimSprite <in> <out>` (devolve "LxA").
   Fundo claro indesejado: `Invoke-ClearOutside <in> <out> 12`.
6. Salve no destino final em `game/assets/sprites/...`, rode o Godot uma vez (headless) para importar
   e **commite o PNG e o `.import`**.
7. Personagens/objetos do PixelLab: tags `tiro-adventure` + o que é (`npc-nina`, `cachorro`,
   `objeto`, `cenario`) + `ativo`. Registre tudo no `docs/ART_PIPELINE.md`.

### B.2 Receitas por tipo de asset (copie os parâmetros)

**Ícone 32×32 (itens, ações, abas)** — `mcp__pixellab__create_image_pixen`
```
width: 32, height: 32, no_background: true,
outline: "single color black outline", detail: "medium detail",
description: "game inventory icon: <COISA>, cute, bold outline, <CORES PRINCIPAIS>, centered, no text"
```
- 1 geração por tentativa; se ficar confuso, tente outra `seed` (no máximo 3).
- Ícones devem se distinguir **pela silhueta** em 32 px (ex.: petisco = biscoito em forma de osso).
- Destino: `game/assets/sprites/ui/icons/<id>.png`. Exibição em 32 ou 64 px (escala inteira).

**Planta madura no canteiro (~56×45)** — `mcp__pixellab__create_image_pro`
```
width: 56, height: 48, no_background: true,
reference_images: [{"url": "upload:<crop_carrot.png>", "usage": "same size, camera angle, pixel density, outline and soil mound as this mature carrot plant"}],
description: "mature <PLANTA> plant growing from a small dark soil mound, <DETALHES>, cute farm game crop, isometric 3/4 view, pixel art"
```
- Devolve 16 candidatos; escolha o que tem a mesma base de terra e altura parecida com a cenoura.
- Destino: `game/assets/sprites/areas/farm/crop_<id>.png` (recortar).

**Móvel/objeto dentro da casa** — `mcp__pixellab__create_object_pro_flash`
```
n_directions: 1, view: "low top-down", width/height: múltiplos de 4 (ex.: 64x48),
style_image: {"url": "upload:<areas/house/room.png>", "usage_description": "match the palette, outline thickness, shading and isometric 3/4 angle of this apartment"},
description: "<OBJETO>, isometric 3/4 view seen from above, front facing south-east, pixel art, no background"
```
- Lição da casa (ART_PIPELINE): objeto que fica **em diagonal** sai melhor com `create_image_pro`
  usando o recorte de um móvel parecido + a sala como referências.

**Objeto de cenário externo (sítio/vila/praça)** — `mcp__pixellab__create_object_pro_flash`
```
n_directions: 1, view: "low top-down",
style_image: {"url": "upload:<areas/farm/farm.png>", "usage_description": "match palette, outline, shading and isometric angle of this farm"},
description: "<OBJETO>, isometric 3/4 view, pixel art, no background"
```

**Fundo de mundo 632×395** — `mcp__pixellab__create_image_pro`
```
width: 632, height: 395, no_background: false,
reference_images: [
  {"url": "upload:<areas/farm/farm.png>", "usage": "art style, palette, outline, lighting and isometric 3/4 angle"},
  {"url": "upload:<areas/village/banner.png>", "usage": "same floating isometric island block with dirt edge on a dark empty background"}
],
description: "<CENA>, on a floating isometric island block with dirt edge, same style as reference, dark empty background, no people, no animals, no text"
```
- 1 candidato por chamada nesse tamanho; gere 2–3 e escolha.
- Não desenhe personagens no fundo; eles vêm por código.

**Cartão-postal do passeio (128×80)** — `mcp__pixellab__create_image_pro`
```
width: 128, height: 80, no_background: false,
reference_images: [{"url": "upload:<areas/farm/farm.png>", "usage": "art style, palette and outline"}],
description: "small cozy landscape postcard: <CENA>, soft daylight, cute pixel art, no people, no text"
```
- 4 candidatos por chamada.

**Personagem humano que anda (NPC)** — igual à Laís v3:
1. `mcp__pixellab__create_character`:
```
mode: "pro", size: 128,
style_character_id: "502435b0-c34e-4164-82ac-4f4699c2894f",   (Laís Mapa v3: mesmo estilo e altura)
description: "<APARÊNCIA>, slim adult proportions, full body, cute pixel art"
```
2. Caminhada: `mcp__pixellab__animate_character` com `template_animation_id: "walking-8-frames"`,
   `mode: "skeleton-v3"`, `directions: ["south", "east", "north", "west"]`.
3. Arquivos: `characters/npc_<id>/rotations/<direção>.png` e `walk/<direção>/frame_00..07.png`
   (mesmo formato da Laís; confira o `NpcWorld`).
4. **Retrato 64×64** — `create_image_pro`, `width: 64, height: 64`, `no_background: true`,
   `reference_images: [{"url": "upload:<characters/npc_lais/portrait.png>", "usage": "portrait framing, size and art style"},
   {"url": "upload:<rotação sul do personagem novo>", "usage": "the character's face, hair and clothes"}]`,
   `description: "head and shoulders portrait of <APARÊNCIA>, friendly smile, cute pixel art"`.
   Devolve 16 candidatos; prancha 4×; escolha o mais parecido com o sprite que anda.

**Cachorro (amigos do Tiro)** — mesmo estilo do Tiro do mapa:
1. `mcp__pixellab__create_character`:
```
mode: "pro", size: 64, body_type: "quadruped", template: "dog",
style_character_id: "8e4e8b4d-142c-4d14-a012-29f16506a0a4",   (Tiro mundo v2)
description: "<RAÇA E CORES>, small cute dog, same size as a yorkshire terrier puppy, pixel art"
```
2. Caminhada: `animate_character` com `template_animation_id: "walk-8-frames"`, `mode: "skeleton-v3"`,
   `directions: ["south", "east", "north"]` (oeste é espelho do leste).
3. Parado: `template_animation_id: "idle"`, `mode: "skeleton-v3"`, `directions: ["south", "east"]`.
4. Retrato 64×64: `create_image_pro` 64×64 com a rotação sul do cachorro como referência
   ("the dog's colors and face") e `characters/tiro_pet/tiro_pet_idle_front.png` ("cute front-facing
   sitting pose and art style"); descrição "cute front-facing sitting <RAÇA>, happy face, pixel art".
5. Arquivos: `characters/dog_<id>/rotations/`, `walk/<dir>/`, `idle/<dir>/`, `portrait.png`.

**Animação nova do Tiro do mapa** (personagem `8e4e8b4d-142c-4d14-a012-29f16506a0a4`):
```
mcp__pixellab__animate_character: character_id: "8e4e8b4d-142c-4d14-a012-29f16506a0a4",
mode: "v3", directions: ["east"], frame_count: 8,
action_description: "<MOVIMENTO>", animation_name: "<nome>"
```
- As animações customizadas do Tiro (sit, eat, sleep) foram feitas só para **leste**; o `DogWorld`
  espelha para oeste e usa a mais próxima nas outras direções. Faça igual.
- Destino: `characters/tiro_world/<nome>/east/frame_00.png ...` (mesmo padrão das pastas existentes;
  confira os nomes dos arquivos em `tiro_world/sit/`).

**Animação nova do Tiro grande (tela do Tiro)** (personagem `1082c03d-9eda-41ee-a5e1-19ba1a6ccf50`):
`animate_character` com `mode: "pixminimax"`, `directions: ["south"]`, `frame_count: 8`,
`action_description: "<MOVIMENTO>"`. Quadros padronizados em 256×216 (pad transparente) como os existentes.

**Roupinha sobre o Tiro grande (sobreposição)** — ver Etapa 08 (pipeline com `edit_image_pro_flash` + diferença de pixels).

### B.3 Paleta e clima
- Tons quentes e suaves (creme, caramelo, verde-folha), contorno preto/marrom escuro, sombras simples.
- Fofo, nunca realista; animais sorrindo; nada assustador.
- Elementos brasileiros quando couber: ipê amarelo, calçada de pedra portuguesa (ondas preto e
  branco), vira-lata caramelo, feirinha com toldo listrado, bandeirinhas.

---

## C. Catálogo de nomes (ids definitivos)

> Use **exatamente** estes ids. O nome entre aspas é o que o jogador lê. A etapa indica quando cria.

### C.1 Itens (`items.json`)
| id | Nome | Categoria | Etapa |
|---|---|---|---|
| `bed_gift` | "Caminha (presente)" | material (`storage: none`) | 02 |
| `strawberry` | "Morango" | crop | 04 |
| `sweet_potato` | "Batata-doce" | crop | 04 |
| `strawberry_pop` | "Picolé de morango" | food | 04 |
| `strawberry_juice` | "Suco de morango" | food (`storage: fridge`) | 04 |
| `mashed_potato` | "Purê de batata" | food | 04 |
| `sweet_potato_chips` | "Chips de batata-doce" | food | 04 |
| `old_horseshoe` | "Ferradura velha" | find | 05 |
| `hen_feather` | "Pena colorida" | find | 05 |
| `grandma_button` | "Botão da vovó" | find | 05 |
| `old_coin` | "Moeda antiga" | find (raro) | 05 |
| `lost_ball` | "Bolinha perdida" | find | 05 |
| `bone_keychain` | "Chaveiro de osso" | find | 05 |
| `shiny_pebble` | "Pedrinha brilhante" | find | 05 |
| `dog_tag` | "Medalhinha" | find (raro) | 05 |
| `marble` | "Bolinha de gude" | find | 05 |
| `old_ticket` | "Bilhete antigo" | find | 05 |
| `silver_spoon` | "Colher de prata" | find | 05 |
| `pocket_watch` | "Relógio de bolso" | find (raro) | 05 |
| `pinecone` | "Pinha" | find | 05 |
| `creek_shell` | "Concha do riacho" | find | 05 |
| `owl_feather` | "Pena de coruja" | find | 05 |
| `fossil` | "Fóssil" | find (raro) | 05 |
| `map_piece_1` … `map_piece_4` | "Pedaço do mapa 1" … "4" | find (não vende) | 05 |
| `stick` | "Graveto" | trail | 07 |
| `ribbon` | "Fita colorida" | trail | 07 |
| `wildflower` | "Flor do campo" | trail | 07 |
| `color_button` | "Botão colorido" | trail | 07 |
| `yarn` | "Novelo de lã" | trail | 07 |
| `smooth_pebble` | "Pedrinha lisa" | trail | 07 |
| `river_shell` | "Conchinha" | trail | 07 |
| `wild_mint` | "Hortelã silvestre" | trail | 07 |
| `bird_feather` | "Pena de passarinho" | trail | 07 |
| `golden_leaf` | "Folha dourada" | trail (rara) | 07 |
| `moon_pebble` | "Pedrinha da lua" | trail (rara) | 07 |
| `mint_snack` | "Petisco de hortelã" | food | 07 |
| `blueberry` | "Mirtilo" | crop | 11 |

Categorias novas: `find` ("Achados") e `trail` ("Do passeio"), ambas `storage: "none"`.

### C.2 Apetrechos / roupinhas (`collections.json`)
| id | Nome | Onde (`slot`) | Como se ganha | Etapa |
|---|---|---|---|---|
| `plaid_bow` | "Laço xadrez" | head | **raro** da Volta na praça | 07 |
| `flower_clip` | "Presilha de flor" | head | **raro** da Rua das flores | 07 |
| `bow_tie` | "Gravata-borboleta" | neck | **raro** da Feirinha da Vila | 07 |
| `sailor_scarf` | "Lenço de marinheiro" | neck | **raro** da Beira do riacho | 07 |
| `explorer_backpack` | "Mochilinha de explorador" | body | **raro** da Clareira dos passarinhos | 07 |
| `star_glasses` | "Óculos de estrelinha" | head | **raro** do Mirante do morro | 07 |
| `glow_collar` | "Coleira que brilha" | neck | **raro** do Passeio ao pôr do sol | 07 |
| `flower_crown` | "Coroa de flores" | head | costura | 08 |
| `shell_collar` | "Coleira de conchas" | neck | costura | 08 |
| `knit_sweater` | "Suéter de tricô" | body | costura | 08 |
| `feather_hat` | "Chapéu de pena" | head | costura | 08 |
| `golden_cape` | "Capa dourada" | body | costura | 08 |
| `red_scarf` | "Lenço vermelho" | neck | pet shop / missão da Nina | 08 |
| `blue_collar` | "Coleira azul" | neck | pet shop | 08 |
| `yellow_bow` | "Lacinho amarelo" | head | pet shop | 08 |
| `rain_coat` | "Capa de chuva" | body | pet shop | 08 |
| `heart_collar` | "Coleira de coração" | neck | semanal de desejos | 03 |
| `digger_bandana` | "Bandana de farejador" | neck | conjunto do sítio / semanal de achados | 05 |
| `park_bow` | "Laço da praça" | head | conjunto da praça | 05 |
| `walker_bandana` | "Bandana de passeador" | neck | semanal de passeios | 07 |
| `caramel_bandana` | "Bandana caramelo" | neck | Pipoca ♥3 | 09 |
| `explorer_hat` | "Chapéu de explorador" | head | tesouro / conjunto da natureza | 11 |

### C.3 Construções e estações
| id | Nome | Mundo | Etapa |
|---|---|---|---|
| `dog_bed` | "Caminha do Tiro" | house | 02 |
| `blender` | "Liquidificador" (estação) | house | 04 |
| `petshop` | "Pet shop Patinhas" | park | 08 |
| `sewing_table` | "Mesa de costura" (estação `sewing`) | park | 08 |
| `walk_bag` | "Bolsinha de passeio" (+1 achado por passeio) | park | 08 |

### C.4 Mundo, NPC, amigos, passeios, truques
- Mundo `park` "Praça" (Etapa 06). NPC `nina` "Nina", adestradora (Etapa 06).
- Amigos (Etapa 09): `pipoca` "Pipoca" (vira-lata caramelo), `mel` "Mel" (poodle), `bolota`
  "Bolota" (pug), `fred` "Fred" (beagle).
- Passeios (`walks.json`, Etapas 06–07): `park_loop` "Volta na praça", `flower_street` "Rua das
  flores", `village_fair` "Feirinha da Vila", `creek_walk` "Beira do riacho", `bird_clearing`
  "Clareira dos passarinhos", `hill_view` "Mirante do morro", `sunset_walk` "Passeio ao pôr do sol".
- Truques (Etapa 10): `paw` "Dá a pata", `talk` "Fala", `roll` "Rola", `jump` "Pula", `spin` "Gira".

### C.5 Contadores (`progress.count`) usados por missões/diárias/semanais
`pet`, `feed:<item>`, `water`, `wish`, `wish:<id>`, `give:<item>`, `find`, `find:<mundo>`,
`find_item:<item>`, `walk`, `walk:<id>`, `walk_item:<item>`, `walk_rare`, `sew`, `equip`,
`friend_gift`, `friend_gift:<id>`, `friend_level`, `trick`, `trick:<id>`.
(Todos são do tipo `stat` nas missões: `{"type": "stat", "key": "<contador>", "target": N}`.)

### C.6 Ícones novos (todos 32×32 em `ui/icons/`)
| Arquivo | O que desenhar (prompt "game inventory icon: …") | Etapa |
|---|---|---|
| `action_water.png` | "blue watering can pouring water drops" | 01 |
| `item_bed_gift.png` | "round plush dog bed, beige cushion with brown rim, tied with a red gift ribbon" | 02 |
| `tab_wishes.png` | "pink heart inside a white thought bubble" | 03 |
| `wish_bubble.png` | "empty white thought bubble with small trailing circles" | 03 |
| `action_pet.png` | "open hand petting gesture with a small pink heart" | 03 |
| `bond_heart.png` | "bright red heart with a tiny paw print in the middle" | 03 |
| `item_strawberry.png` | "two red strawberries with green leaves" | 04 |
| `item_sweet_potato.png` | "purple-skinned sweet potato with orange cut end" | 04 |
| `item_strawberry_pop.png` | "pink strawberry popsicle on a wooden stick" | 04 |
| `item_strawberry_juice.png` | "glass of pink strawberry juice with a straw" | 04 |
| `item_mashed_potato.png` | "small bowl of creamy yellow mashed potato" | 04 |
| `item_sweet_potato_chips.png` | "pile of orange sweet potato chips in a small paper cone" | 04 |
| `find_paw.png` | "paw print with three tiny yellow sparkles" | 05 |
| 16 achados `item_<id>.png` | ver tabela da Etapa 05 | 05 |
| `item_map_piece.png` | "torn piece of old treasure map with a red dotted line" | 05 |
| `tab_park.png` | "green park bench under a yellow flowering tree" | 06 |
| `action_walk.png` | "red dog leash looped with a small paw tag" | 06 |
| 11 materiais `item_<id>.png` | ver tabela da Etapa 07 | 07 |
| `item_mint_snack.png` | "bone-shaped green dog biscuit with mint leaf" | 07 |
| `rare_star.png` | "golden star with shine" (moldura de raro) | 07 |
| 7+ apetrechos `outfit_<id>.png` | ver tabelas das Etapas 07/08 | 07/08 |
| `petshop.png` | "small pet shop kiosk with striped awning and paw sign" | 08 |
| `action_sew.png` | "sewing needle with pink thread and a spool" | 08 |
| `friend_<id>.png` | rosto de cada cachorro | 09 |
| `trick_paw/talk/roll/jump/spin.png` | ver Etapa 10 | 10 |
| `item_blueberry.png` | "handful of dark blue blueberries with a leaf" | 11 |
