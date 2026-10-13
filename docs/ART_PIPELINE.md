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
