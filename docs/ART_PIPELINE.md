# Pipeline de arte (PixelLab)

Os assets são gerados pelo **MCP PixelLab** (personagens, animações, tilesets, objetos, UI).

## Fluxo
1. Definir o asset (tamanho em px, direções, animações, paleta) — registrar decisões aqui.
2. Gerar no PixelLab (jobs são assíncronos: criar → aguardar → baixar).
3. Salvar o PNG/spritesheet na pasta certa de `game/assets/sprites/`.
4. Abrir o Godot para importar (o filtro `Nearest` já é padrão do projeto, pixels ficam nítidos).
5. Commitar o PNG e o `.import` gerado.

## Onde salvar
| Tipo                      | Pasta |
|---------------------------|-------|
| Personagens / NPCs / inimigos | `game/assets/sprites/characters/<nome>/` |
| Tilesets e terreno        | `game/assets/sprites/tiles/` |
| Interface (botões, ícones)| `game/assets/sprites/ui/` |
| Efeitos visuais           | `game/assets/sprites/fx/` |
| Ícones do app (PWA)       | `game/assets/icons/` (`icon_144.png`, `icon_180.png`, `icon_512.png`) |

## Nomes
`snake_case`, descritivo: `slime_green_idle.png`, `grass_tileset_16px.png`, `player_walk_south.png`.

## Organização no PixelLab
Não há projetos via MCP para este jogo; a organização é por **tags** (personagens e objetos)
e por este registro. Toda geração nova entra na tabela abaixo.

| Tag | Uso |
|---|---|
| `tiro-adventure` | Tudo que pertence ao jogo |
| `tiro`, `tutor`, `npc-<nome>`, `objeto`, `cenario` | O que é |
| `mundo` / `pet` | Sprite pequeno do mundo / versão detalhada |
| `ativo` / `descartado` | Em uso no jogo / substituído (não apagar sem confirmar) |

Imagens avulsas (create_image_*) não aceitam tags: registrar só aqui.

## Registro de assets

### Primeiros sabores — Etapa 04, 14/10/2026 (Codex)

PixelLab: ícones Pixen 32×32 transparentes, contorno preto, detalhe médio; plantas Pro
56×48, 16 candidatos, referência `crop_carrot.png` por upload. Pranchas abertas em
`build/art_sources/etapa04/`; o helper PowerShell falhou nesta sessão (System.Drawing/Bitmap),
então a revisão em grade e os recortes foram feitos com Pillow, sem alterar a arte gerada.
Originais permanecem nessa pasta ignorada. Ícones mantêm canvas 32×32 para alinhamento.

| Asset | Job/id PixelLab | Arquivo final em `game/assets/sprites/` | Escolha/recorte |
|---|---|---|---|
| Morango | `395466c6-8403-4818-88b9-110891de46b8` | `ui/icons/item_strawberry.png` | canvas 32×32 |
| Batata-doce | `ce8d1410-5cbc-4110-9520-b99086b08789` | `ui/icons/item_sweet_potato.png` | tentativa 2, canvas 32×32 |
| Picolé | `fe67f545-28a8-47ff-a913-2e51c67c7322` | `ui/icons/item_strawberry_pop.png` | canvas 32×32 |
| Suco | `5b403447-2a90-41a4-8a46-fa56028d4724` | `ui/icons/item_strawberry_juice.png` | canvas 32×32 |
| Purê | `745c921a-e225-4661-94e6-e5b594ac7347` | `ui/icons/item_mashed_potato.png` | canvas 32×32 |
| Chips | `b7e74248-5983-41cb-aeca-65f4179e9d0f` | `ui/icons/item_sweet_potato_chips.png` | canvas 32×32 |
| Morangueiro | `5eb550fd-6891-47a1-a0f2-82c3d8d394c3` | `areas/farm/crop_strawberry.png` | candidato 9, bbox `[10,8,45,41]`, 35×33 |
| Batata-doce madura | `1579ffea-3929-49fa-bc3c-568af457b706` | `areas/farm/crop_sweet_potato.png` | candidato 15, bbox `[5,6,47,45]`, 42×39 |
| Liquidificador | objeto `e599be77-804a-4b29-8bb7-7d7ded9673ec`, job `baa5791b-ca83-41f4-9dc0-f4daf629feea` | `areas/house/blender.png` | bbox `[6,6,27,43]`, 21×37 |

Liquidificador Flash Pro, uma direção, low top-down, canvas 32×48; referência do fogão
reduzida com nearest para 29×48 (a referência deve caber no canvas). Tags `tiro-adventure`,
`objeto`, `ativo`. Sem animação opcional: indicador de produção informa trabalho/pronto.
Tentativas descartadas: batata-doce `0fc95615-b6ff-4c5d-a97c-d3a9a799b33e` saiu com rosto;
objeto `bac5a9b4-c6e4-4403-8584-0d3be7b41322`, job `cb617035-7d0f-4d16-bdc7-e605effdb523`,
foi criado sem referência antes da redução do fogão e tem tag `descartado`.

### Laís no mapa v3 — 13/10/2026 (Claude Code)

Personagem **Laís Mapa v3** `502435b0-c34e-4164-82ac-4f4699c2894f`: modo pro, 128 px, 8 direções,
concept = rotação sul do Laís Avatar; descrição pede corpo esguio e proporção adulta (a v2,
96 px, saiu "gordinha"/chibi; pro ignora `proportions`). Altura ~87 px a 1x (geladeira 113),
mesma densidade de pixel do Tiro: não ampliar (`world_scale` removido). Caminhada `walking-8-frames`
em skeleton-v3 (S/E/N/W, grupo `fda0e3fa-ed4e-4861-a9d5-7ab79f26736a`), quadros 144 px
(norte 128 px; todos centrados, pés em +46 do centro). Arquivos: `characters/npc_lais/rotations/` e
`walk/<direção>/frame_00..07.png`. Descartados: `9b151c04…` (Laís Mapa, standard 68 px) e
`d1c95140…` (v2, 96 px); podem ser apagados no PixelLab.

### Retrato animado da Laís — 13/10/2026 (Codex)

Personagem existente **Laís Avatar**, `650a88c3-6c61-40ba-a7f4-e533d891e478`, 64×64.
Sem novas gerações. "Pedindo algo": animação `36e46520-30c5-42b2-81bf-01350b2bdf86`,
9 quadros south em `characters/npc_lais/quest_request/frame_0.png` até `frame_8.png`.
"Acenando sorrindo": `60d41505-05f9-4a28-b67d-75bc7e300364`, 9 quadros já baixados
em `intro_wave/`, também usados na entrega das missões. Reprodução a 8 FPS.

### Natureza contínua e ferramentas — 13/10/2026 (Codex)

Fundo PixelLab Pro em `areas/nature/nature.png`, job `331ff1e1-510a-41e7-8c60-f31f3ffdbc0f`,
512×384, estilo do sítio. Substitui o protótipo composto; árvores, riacho/ponte e gruta
formam uma paisagem. Polígonos de obstáculos acompanham os elementos desenhados.
Madeira dura: Pixen 32 px, `item_hardwood.png`, job `7d5bc0d6-9365-4526-9395-f1a4c8b6ba95`.

Ícones de ferramentas em `ui/icons/`, Pixen 32 px:

| Arquivo | Job |
|---|---|
| tool_axe.png | `4f4f4869-29f1-4224-b2f8-18cf10543111` |
| tool_axe_reinforced.png | `25f7b5aa-0e11-4812-ba33-462bdc7954d0` |
| tool_pickaxe.png | `10351a4d-fe78-4faa-bf50-61365abcea99` |
| tool_pickaxe_reinforced.png | `ca100609-6682-41e7-8817-7ad471ccf9a1` |
| tool_pickaxe_crystal.png | `f46a880a-f529-4ee1-b613-bbcea4ff4ac1` |
| tool_sickle.png | `422a6d00-76f6-46d3-8a1b-2eacb2f09291` |

### Natureza — 13/10/2026 (Codex)

PixelLab Pro, referência de estilo `farm.png`, candidato 0, PNGs transparentes recortados.
Originais e `prepare_nature_art.ps1` ficam em build (ignorados). Fundo 1208×683 composto
com o topo do terreno já gerado e trilhas; sem barrancos internos que pareçam obstáculos.

| Arquivo em areas/nature | Job PixelLab | Recorte |
|---|---|---|
| forest_trees.png | `ccb94578-d03b-4b12-8ca7-939e30e3df28` | 112×116 |
| creek_bridge.png | `69b43832-a68c-4bba-90f9-e0130f2f2aa5` | 124×97 |
| stone_cave.png | `45f45456-47cb-42ad-9cf9-41285a056fe8` | 116×106 |
| crystal_cave.png | `b71f2e86-0ed8-4bab-975d-f4dce5d0ea9c` | 109×95 |
| fiber_meadow.png | `6fbada88-122b-4b44-a988-6b2afb184443` | 113×110 |
| nature.png | Composição do terreno existente | 1208×683 |

### Variedades de animais — 13/10/2026 (Codex)

PixelLab Pixen, transparência, recorte com `tools/pixel_tools.ps1`. Galinhas escala 0,6;
vacas novas escala 1,3 para se aproximar do tamanho da vaca original. Originais em build.

| Arquivo em areas/farm | Job PixelLab | Recorte |
|---|---|---|
| cow_brown.png | `46dd338a-e68a-4216-807c-8785b17a5802` | 42×40 |
| cow_spotted.png | `6f2526a9-069f-4102-ae62-333240ea8392` | 43×37 |
| chicken_brown.png | `d390f672-09b1-4ac0-bf56-aaa877edbd22` | 25×29 |
| chicken_black.png | `d04fbe2a-c1eb-43e1-b6c2-22acd44176be` | 24×28 |

### Expansões e construções — 13/10/2026 (Codex)

Referência de estilo: `areas/farm/farm.png`. Geração PixelLab Pro, candidato 0; recortes
transparentes preparados com `tools/pixel_tools.ps1` no Windows PowerShell.

| Asset | Job PixelLab | Arquivo | Preparação |
|---|---|---|---|
| Terreno vazio | `3232557c-9d20-452a-8923-e0932ec64291` | `areas/farm/land_tile.png` | 632×395; preencher o chão sob os pixels transparentes com a cor da grama original |
| Sítio ampliado | composição local | `areas/farm/farm_expanded.png` | 1208×539; terrenos em (0,144)/(576,144), sítio original em (288,0), remover fundo externo e barranco interno do original |
| Bancada | `d3c814eb-d535-41fc-a2ad-8b0c066201a9` | `areas/farm/workbench.png` | 95×78 recortado |
| Estufa | `c03c97dc-3d3d-49cd-b659-e0ddae709479` | `areas/farm/greenhouse.png` | 125×135 recortado |
| Pomar | `3141936f-cc0b-4b20-aed7-5b82d9fe5dd1` | `areas/farm/orchard.png` | 145×125 recortado |
| Forno | `48982a2f-3fd8-4522-988d-67c9e9782a36` | `areas/house/oven.png` | 69×83 recortado |
| Banca extra | `aa86a1bc-f344-4a9b-9b9d-d691e45f1406` | `areas/village/stall.png` | 83×113 recortado |
| Costura no ateliê | `95e68a14-e62f-403c-89d3-371cb3a314a5` | `areas/village/atelier.png` | 101×94 recortado |

Todos ativos. Originais baixados e script de composição em `build/art_sources/` e
`build/prepare_world_art.ps1` (ignorados); arte anterior preservada para referência.

### Animais e processamento — 13/10/2026 (Codex)

Prédios/animais: PixelLab Pro com `farm.png` como estilo, candidato 0, recorte transparente.
Ícones e culturas: Pixen; ícones com canvas 32 px. Todos ativos.

| Asset | Job PixelLab | Arquivo |
|---|---|---|
| Galinheiro | `b11d1adb-4d09-493b-812a-6959c10478f2` | `areas/farm/chicken_coop.png` (135×132) |
| Curral | `51178d3b-c5c3-49aa-9572-9b216cac6cd3` | `areas/farm/cow_barn.png` (145×133) |
| Moinho | `6ce6e173-2249-40b6-a193-aecd9db66b68` | `areas/farm/mill.png` (115×129) |
| Queijaria | `32bb5c2d-5082-45ae-ae07-b127e0f0024c` | `areas/farm/dairy.png` (102×113) |
| Galinha | `7ec73480-aebd-44ca-b04e-5b32ddc9e624` | `areas/farm/chicken.png` (24×27; escala 0,6) |
| Vaca | `7a1e89a5-ee3e-4747-ac14-8018a87739b6` | `areas/farm/cow.png` (64×52) |
| Trigo (ícone) | `c6ff271e-f3a3-47ff-9ab6-a293a1b5b4e0` | `ui/icons/item_wheat.png` |
| Milho (ícone) | `9b82ce5b-af23-4cc7-b91b-05fe14f5a0ee` | `ui/icons/item_corn.png` |
| Ovos (ícone) | `748b7657-6065-47f4-b7ae-a121912e4bd5`; corrigido por `b5ceb5ba-aa96-4bf7-94e3-87f8e175f2c5` | `ui/icons/item_egg.png` (cascas lisas) |
| Leite (ícone) | `db2a922c-9589-4a19-8aa0-7381128b1d6e` | `ui/icons/item_milk.png` |
| Farinha (ícone) | `7178e820-5c5f-4ee9-8877-c7fc8ba1feb9` | `ui/icons/item_flour.png` |
| Queijo (ícone) | `c6db50ea-4a6a-4f19-9337-c04611c4e3c7` | `ui/icons/item_cheese.png` |
| Trigo (planta) | `6efe3fd5-a3a1-41bc-b63b-b41e289f3b6d` | `areas/farm/crop_wheat.png` |
| Milho (planta) | `a3b06bb4-b5e2-4c2f-9ed1-c3ac2c6f0747` | `areas/farm/crop_corn.png` |
| Sítio com animais | composição dos terrenos anteriores | `areas/farm/farm_animals.png` (1208×683) |

A quarta área usa `land_tile.png` em (288,288), removendo os barrancos internos do mapa
anterior. Composição em `build/prepare_animal_art.ps1`; originais em `build/art_sources/animals/`.

### Registro anterior completo


| Asset | Tipo / ID PixelLab | Modo | Arquivos no jogo | Status |
|---|---|---|---|---|
| Sítio da Bloblo (fundo) | imagem pro, job `cbbd43cb-2fc8-44fd-83f6-bdd00d45c57a`, ref de estilo: sala v2 | 632x395 | `areas/farm/farm.png` | ativo |
| Canteiro (solo vazio) | imagem pro, job `7e96a88e-5554-4a93-995d-6c284f3f991f` (cand. 9, pixels soltos limpos) | 73x52 | `areas/farm/plot.png` | ativo |
| Broto / cenoura / batata / abóbora maduras | imagem pro, jobs `844eeb67-…` (cand. 5), `54b684d8-…` (0), `17b4bc79-…` (0), `8e1777c9-…` (0) | ~56x45 | `areas/farm/crop_*.png` | ativo |
| Ícone aba Sítio | pixen `7aefa112-…` | 32x32 | `ui/icons/tab_farm.png` | ativo |
| Tiro mundo v2 | personagem `8e4e8b4d-142c-4d14-a012-29f16506a0a4` | pro, 64px, 8 dir | `characters/tiro_world/` | ativo |
| ↳ animações | walk (S/E/N, skeleton-v3), idle (S/E, skeleton-v3), bark (S), sit (E, v3), sleep (E, v3, deitando), eat (E, v3) | | `tiro_world/<ação>/<direção>/` | ativo |
| Tiro mundo v1 | personagem `cc74ce02-1c93-4dc7-8a72-a359265ad497` | standard, 32px, 4 dir | (substituído) | descartado: pouco detalhe |
| Tiro pet v2 (sentado, frente) | imagem pro, job `ee0ec478-c066-4b6c-ade9-fc8608809abe` (candidato 0 de 4), refs: pose da referência + rotação sul do Tiro mundo v2 | 160px | `characters/tiro_pet/tiro_pet_idle_front.png` | ativo |
| Tiro pet v3 (animado) | personagem v3 `1082c03d-9eda-41ee-a5e1-19ba1a6ccf50` (ref: `tiro_pet_idle_front.png`, quadrúpede/dog, 8 dir, tags tiro-adventure,tiro,pet,ativo) | v3, 160px (quadros 216px) | `characters/tiro_pet/<animação>/frame_XX.png` | ativo |
| ↳ animações (só south, `animate_character` mode pixminimax, 1 geração cada) | idle_breathe, head_tilt, scratch, yawn, sniff, stretch, bark, eat, happy_jump, shake_off (8 quadros +1), sleep (16 +1, deitando), look_around, chase_tail, lick_paw, give_paw, wag_excited, sad, pet_head (com mão), pet_paw, roll_over (16 +1, rola de barriga; ao reverso = levanta), belly_rub e belly_kick (barriga p/ cima, partem do último quadro de roll_over) | | tocadas por `scripts/ui/pet_animator.gd` | ativo |
| Tiro pet v1 | imagem pixen | 128px | (substituído) | descartado |
| Sala v2 (apê sala+cozinha em L, ilha, porta de vidro, varanda) | imagem pro, job `ee8724e1-1418-4118-9542-c4f50c46d362` (asset `ae1087d7-…`), ref: `docs/references/apartamento_sala_cozinha_v2.jpg` sem o título | 632x395 | `areas/house/room.png` | ativo |
| Ilha (recorte da sala v2) | polígono recortado do próprio fundo, fatiado em colunas para ordenação | 140x151 | `areas/house/island.png` | ativo |
| Sala v1 | imagem pro, job `161a0ff4-…` + inpaint | 624x416 | (substituída) | descartado |
| Building Kits isométricos (tiles) | tiles pro `e2cb8281-…` (interior), `d0b32603-…` (varanda) | 64px | — | descartado: piso quadriculado e paredes em blocos, muito pior que imagem única |
| Geladeira diagonal (frente p/ sudeste, encosta na parede esquerda) | imagem pro, job `1d5c0942-d832-4fa0-99b1-ee0ac24024d2` (candidato 0), refs: geladeira da referência v2 + sala + geladeira antiga | 52x113 (recortado) | `areas/house/fridge.png` | ativo |
| Fogão diagonal com panela | imagem pro, job `0fe5d776-347d-4ca2-912b-3c9d4ecd15dc` (candidato 1; base: job `9e246eff-…` cand. 3) | 96x96 recortado em (30,5,45,75) | `areas/house/stove.png` (sem vapor) | ativo |
| ↳ cozinhando | `animate_image` job `45a0060b-9719-4507-8548-30191ab363ef`: só a faixa do vapor (linhas 0–19) foi usada, corpo fixo (a animação acendia o forno) | mesmo recorte | `areas/house/stove_cooking/frame_XX.png` (8) | ativo |
| Geladeira/fogão de frente | objetos `c68d8da4-…`, `6d20f34d-…` (+ estado cozinhando `8e72756c-…` do usuário) | | — | descartado: de frente não encostam na parede diagonal |
| Tigela | objeto pro flash `63a97314-eaeb-43f7-b957-f0c131aaa463` | 26x20 | `areas/house/bowl.png` | ativo |
| Sofá | imagem pro, job `96402901-fe28-4f4a-80a9-0a45f34d7f2d` (candidato 3) | 132x102 | `areas/house/sofa.png` | ativo |
| Sofá (de frente) | objetos `e97f7943-…`, `85c6e34e-…` | | — | descartado: não isométrico |
| Fundo antigo (referência) | imagem do usuário + inpaint | 512x352 | (removido) | descartado |

### Lições sobre o estilo isométrico da casa
- Sala: `create_image_pro` com a referência do usuário + "EMPTY room, NO furniture". Não mandar o
  sprite do Tiro como referência de escala: ele foi desenhado na sala (precisou de inpaint).
- Móveis encostados na parede da esquerda (frente para sudeste): `create_object_pro_flash` com
  recorte do móvel equivalente da referência como `style_image` funciona.
- Móveis em diagonal (ex.: sofá virado para sudoeste): pro flash desenha de frente; usar
  `create_image_pro` com o recorte da referência + a sala como referências (4 candidatos).
- Sempre recortar bordas transparentes (`Invoke-TrimSprite`) antes de posicionar.
- **Imagem única > tiles** para ambientes bonitos: os kits de tiles do PixelLab ficaram com
  piso quadriculado e paredes em blocos. Peças arquitetônicas que o Tiro contorna (ilha) podem
  vir no fundo e ser **recortadas** como sobreposição com `"slice": true` no JSON da sala.
- Móveis encostados na parede esquerda da sala v2 precisam ser **diagonais** (frente para
  sudeste); de frente sempre sobra fresta. Posicionar pela quina de trás-esquerda na linha do
  rodapé (`y = 283 - 0.5 * (x - 22)` na sala v2).
- `animate_image` pode mudar o objeto inteiro (acendeu o forno). Para efeitos localizados
  (vapor), usar a imagem fixa e copiar só a faixa do efeito de cada quadro.
- `create_image_pro` aceita no máximo 632x424; gerar sem fundo transparente (`no_background=false`)
  e casar a cor do `Void` de `house.tscn` com o fundo escuro da imagem.
- Serrilhado: a sala aparece em escala quebrada no celular; `room.gd` troca para filtro suave
  com mipmaps nessas escalas (`_update_filter`). Texturas da casa importadas com mipmaps.

## Padrões visuais
- Tiro no mundo: 64px (modo pro), exibido 1x (`SPRITE_SCALE` em `dog_world.gd`); o fundo
  provisório é exibido 2x. Um fundo novo do PixelLab deve casar com essa escala.
- Tiro na Tela do Pet: quadros padronizados em 256x216 (as de barriga eram mais largas; pad transparente), exibidos em ~336x284. **Carinho:** arrastar o dedo no Tiro = zonas por altura (cabeça <50%, barriga 50–76%, patas >76%); barriga/cabeça prolongadas fazem ele rolar de barriga. Sempre escala inteira (2x, 3x) para pixels nítidos.
- Prévia ampliada de assets: gerar pranchas em `build/preview/` (ignorado no git) antes de aprovar.
- Animações: preferir `skeleton-v3` (mantém a identidade do personagem); `v3` para ações customizadas.
- Ícones do PWA atuais são placeholders.

## Interface (UI)
- **Fonte:** Jersey 10 (Google Fonts, licença OFL em `assets/fonts/Jersey10_OFL.txt`), importada sem
  antialiasing. Números claros e acentos. Tamanho base 22 (é estreita). Descartadas: Pixelify Sans
  (o "5" parece "S") e Fredoka.
- **Tema:** `assets/theme/main_theme.tres` — creme `#fff4dc`, contorno marrom `#4a2e21` grosso,
  botões laranja/verde com "degrau" embaixo que afunda ao tocar.
- **Ícones 32x32** (`create_image_pixen`, 1 geração cada, contorno preto, estilo fofinho) em
  `sprites/ui/icons/`: `item_<id>`, `need_<id>`, `action_play/bathe/sleep/wake`, `coin`, `xp`, `timer`,
  `tab_pet`, `tab_house`. Exibir em 32 ou 64 px (escala inteira). Prompt base:
  "game inventory icon: <coisa>, cute, bold outline", outline "single color black outline".
  Cenoura e petisco refeitos para não se confundirem (petisco = biscoito em forma de osso).
- Navegação (12/10/2026): `tab_map` (era `tab_journey`), `tab_tasks` (job 8dfc6c5b), `tab_bag` (job f1e1e2df).
- Cenas da Vila e da Trilha: `create_image_pro` 632x395 com `farm.png` como referência de estilo
  (jobs 36b8c28a e 8331aed1), em `areas/village/banner.png` e `areas/trail/banner.png`; usadas como
  fundo das salas `rooms/village.json` e `rooms/trail.json`. Prompt: "...on a floating isometric island
  block with dirt edge, same style as reference ..., dark empty background, no people".
- Retratos PROVISÓRIOS dos NPCs (pixen 64x64): `characters/npc_<id>/portrait.png` (bloblo 297c5b5f,
  guide 38b1560a, merchant 6a56128f). Serão trocados pelas fotos do Vitor.
- **Laís** (NPC `artisan`, a artesã da Vila): retrato feito A PARTIR DE FOTOS (frente + perfil) com
  `create_image_pro` 64x64, refs: foto de frente (rosto/sardas), foto de perfil (cabelo) e o retrato
  provisório (estilo). Job f7aa7f29, candidato 0 de 16. Receita para os próximos NPCs com foto: mesma
  chamada, trocando a descrição; escolher numa prancha 4x (as 16 opções lado a lado).
- Ícones da Jornada (12/10/2026, pixen 32x32, 1 geração cada, mesmo prompt base): `item_wood`,
  `item_stone`, `item_copper`, `item_crystal`, `item_plank`, `item_brick`, `item_fiber`, `item_fabric`,
  `item_apple`, `item_herbs`, `item_vegetable_soup`, `item_apple_biscuit`, `item_treat_box`,
  `item_accessory_set` e `tab_journey` (mapa de aventura). Jobs: 6dbd4739, 9abb5bb5, 7b3afe34, e14f0df2,
  cc88fb7f, 3fd98acc, ed23acc2, 4943e753, 8d92c724, 15cf82fd, 7052ef53, f6de034e, b1fe6d24, 1fd7af62, 63c622bb.

### Armazenamento — 13/10/2026 (Claude Code)

PixelLab Pro Flash, `create_object_pro_flash`, 1 direção, low top-down, recortados ao pixel opaco
(`areas/house/chest.png` 18×22, usado com `scale` 2; `areas/farm/silo.png` 47×89; `areas/farm/warehouse.png` 87×83).
Objetos: baú `004a6731-a055-4049-8b5a-4039a2e772a2`, silo `f2071b90-2b20-4069-a1a7-13e768517eb9`,
armazém `4c3a037e-e51b-4b50-b259-9810ef727510`. Ícones Pixen 32 px em `ui/icons/`:
`item_bolt.png` (`81d53d1e-8a39-4c52-af5e-7f2cfdff382a`) e `item_iron_band.png` (`aaefb859-3329-46ba-a854-fe277e2a565f`).

### Etapa 01 do começo — 14/10/2026 (Claude Code)

Ícone Pixen 32×32 (`create_image_pixen`, `no_background`, contorno preto, médio detalhe), 1 geração, sem repetir:
`ui/icons/action_water.png` — regador azul derramando gotas (job `fb2b5e89-c20b-46aa-9ed5-d05c21c0740c`,
asset `a81f579c-9bdb-5d9d-aaa0-79fad89d6110`). Usado no canteiro (24 px, balançando), na animação de regar e
nos ícones de missão do contador `water`. Original em `build/art_sources/etapa01/`.

### Etapa 03 do começo (desejos) — 14/10/2026 (Claude Code + Codex)

Os quatro ícones foram gerados pelo Claude com `create_image_pixen`, 32×32, transparência,
contorno preto, médio detalhe e os prompts do plano (uma tentativa por ícone). Codex retomou
os originais, conferiu a prancha `build/preview/wishes_icons.png` e as capturas 360×780.
Originais em `build/art_sources/etapa03/`; destinos abaixo, com `.import` do Godot.
Canvas 32×32 preservado para alinhar o fundo do balão ao ícone sobreposto; sem recorte.
O balão usa ~40 px no mundo antes do zoom (~25 px no sítio) e 64 px na tela Tiro, com ícone por cima.

| Asset | Job PixelLab | Arquivo em `game/assets/sprites/` | Recorte |
|---|---|---|---|
| Aba Desejos | `8944e95f-2116-47dc-a75e-bb78b4545952` | `ui/icons/tab_wishes.png` | 32×32, inteiro |
| Balão | `c33e308a-25f8-4a8d-88c3-fe0aa25320de` | `ui/icons/wish_bubble.png` | 32×32, inteiro |
| Carinho | `617c858c-3e8c-4385-a8cf-b15c27fde4e0` | `ui/icons/action_pet.png` | 32×32, inteiro |
| Vínculo | `c3f82abc-1702-4abc-81e2-904ea7946a7c` | `ui/icons/bond_heart.png` | 32×32, inteiro |

`New-ContactSheet` ainda falha nesta máquina; a prancha foi montada com `System.Drawing`
e escala inteira 4× (nearest-neighbor). Cadeado dos espaços fechados desenhado por `WishUi`;
especial usa a estrela de XP existente, conforme fallback do plano.

### Etapa 02 do começo (caminha) — 14/10/2026 (Claude Code)

- `areas/house/dog_bed.png` (39×31 recortado): `create_object_pro_flash`, 1 direção, low top-down, 64×48; objeto
  `0646e11a-dcb8-49ed-b2fe-d24ec3899d22` (job `136b91f6-5674-4ebc-9a50-bdaeeb2f8fda`). A `style_image` precisa caber no canvas
  (o `room.png` de 632×395 foi recusado): usei um recorte 64×48 do piso da sala. 1 tentativa, ficou isométrica.
- `ui/icons/item_bed_gift.png` 32×32: `create_image_pixen` (job `55030dd5-b6d1-48e1-80e0-a79b97e04b7f`,
  asset `3b73d3e5-3a80-5b80-be62-142d5c7a40c2`), 1 geração. Originais em `build/art_sources/02/`.

### Etapa 05 do começo (faro) — 14/10/2026 (Codex gerou, Claude instalou)

Os job ids não foram anotados na hora; as imagens estão na galeria do PixelLab (Creator, 14/10/2026) e os
originais em `build/art_sources/etapa05/` (ignorada pelo git). Ícones 32×32 `create_image_pixen`
(`no_background`, contorno preto, médio detalhe, 1 geração cada), na pasta `ui/icons/`:

| Arquivo | Galeria (`gallery:`) |
|---|---|
| `item_old_horseshoe` | `f46871f9-e41e-5d44-879f-e272affc5cd6` |
| `item_hen_feather` | `5cee647c-35f8-586f-8a13-18e0431c6832` |
| `item_grandma_button` | `884be7a9-0251-5568-8b0c-98e463fade61` |
| `item_old_coin` | `917b2fb1-fb87-54b3-8529-a4b90cdf10f6` |
| `item_lost_ball` | `da02d1e1-f6c3-5e87-a0cd-d35fb5096745` |
| `item_bone_keychain` | `96db6db8-1222-56a2-abce-89dedb043dcf` |
| `item_dog_tag` | `02e0d0a0-5734-542f-9c9d-28f6af409292` |
| `item_marble` | `36738c49-f113-56d9-972c-2b808b8f1def` |
| `item_old_ticket` | `5ba328d9-3abb-5b9f-8407-aab4ee9edf11` |
| `item_silver_spoon` | `5b8fefd4-3d78-55e9-912d-5c97431e76a2` |
| `item_pocket_watch` | `d522da0b-394b-5a0f-9892-febe8f61fc41` |
| `item_pinecone` | `fd073190-5bc1-524a-a273-44472edb17b3` |
| `item_map_piece` | `f9c09935-65b2-52e0-bcf3-545a8fe160a8` |
| `find_paw` | `b588be73-0ef2-5f54-a865-004a3344607c` |

`item_shiny_pebble`, `item_creek_shell`, `item_owl_feather` e `item_fossil` também estão na galeria do mesmo dia
(busque por "pebble", "shell", "feather" e "fossil" em `list_images`). Montinho `areas/fx/dig_spot.png`
(galeria `8bc492ba-9909-5da1-a086-67d587cf6da3`, 32×24) e brilho `areas/fx/fx_sparkle.png` (16×16,
`bdb51a19-cd15-554b-80eb-a95719a40066`). Animações do Tiro do mapa `tiro_world/sniff/east` e `dig/east`
(9 quadros, personagem `8e4e8b4d-142c-4d14-a012-29f16506a0a4`, `animate_character` v3, 1 direção).

### Etapa 06 do começo (Praça) — 14/10/2026 (Claude Code)

Originais em `build/art_sources/etapa06/` (ignorada pelo git).

| Asset | Ferramenta / job ou id | Arquivo em `game/assets/sprites/` | Recorte |
|---|---|---|---|
| Fundo da Praça 632×395 | `create_image_pro`, refs `farm.png` + `village/banner.png`; job `786e8151-a3c3-41c3-a3f7-33acec99ff4f` (asset `f0fcec32-7fe5-52dd-8198-f4fe9c5c3fdc`). 2ª tentativa (seed 7, `2f325580-ce6f-495a-bafc-90587f0171c2`) gerada e não usada | `areas/park/park.png` | inteiro; escolhido pela calçada larga e pelo arco do portão visível. O quiosque veio com balcão (não vazio), serve para a Etapa 08 |
| Postal "Volta na praça" 128×80 | `create_image_pro`, ref `farm.png`; job `56400ba6-72d5-4a85-a5c7-a1223a6e89f1` (4 candidatos; usado o 0) | `areas/walks/park_loop.png` | inteiro |
| Nina (personagem) | `create_character` pro 128, `style_character_id` Laís v3; `008f327a-6e03-4bf8-a1ca-223ddbe2fa79`; caminhada `animate_character` `walking-8-frames` skeleton-v3 (S/E/N `ba30ef8b…`, `c9bb3b2c…`, `28d76fdf…`; O `221bdb32-6703-416e-b4f4-7b00647338a3`) | `characters/npc_nina/rotations/` (4) e `walk/<dir>/frame_00..07.png` | 128×128 e 144×144, como a Laís |
| Retrato da Nina 64×64 | `create_image_pro`, refs retrato da Laís + rotação sul; job `dd1b076e-d1ca-4ddc-9540-a32ab8c20186` (16 candidatos, prancha; usado o 0) | `characters/npc_nina/portrait.png` | inteiro |
| Pipoca (cachorro) | `create_character` pro 64 quadruped `dog`, `style_character_id` Tiro mundo v2; `c2f7d371-f843-4455-8cb9-894c04959074`; `walk-8-frames` S/E/N (grupo `fba31f42…`) e `idle` S/E (grupo `13c22293…`), skeleton-v3 | `characters/dog_pipoca/rotations/` (4), `walk/<dir>/`, `idle/<dir>/` | rotações 64×64, animações 80×80; oeste = espelho do leste |
| Retrato da Pipoca 64×64 | `create_image_pro`, refs rotação sul + `tiro_pet_idle_front.png`; job `0763eca0-b903-4e6d-a36f-b42dffbec391` (16 candidatos; usado o 2) | `characters/dog_pipoca/portrait.png` | inteiro |
| Ícone `action_walk` | `create_image_pixen` 32×32, job `4a83dd30-f471-4ec7-ac55-7755a058ea9b` | `ui/icons/action_walk.png` | inteiro; 1ª tentativa |
| Ícone `tab_park` | `create_image_pixen` 32×32; 1ª (`7c10279c-1e21-4b38-90eb-4c925813d7f4`, canteiro de flores, não leu como banco) trocada pela 2ª (seed 21, `b9305522-7477-4878-9414-bba846a84360`: banco sob árvore amarela) | `ui/icons/tab_park.png` | inteiro |
