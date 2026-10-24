# Pipeline de arte (PixelLab)

Os assets são gerados pelo **MCP PixelLab** (personagens, animações, tilesets, objetos, UI).

## Interface 2 — fontes e controles lisos (24/10/2026)

Controles em `game/assets/sprites/ui/ctl/`: 17 SVGs brancos, traço 2,4 com pontas e junções
arredondadas, coloridos pela interface. Miolos fornecidos pelo plano `interface2/etapas/ETAPA_01_BASE.md`
e por `interface2/prototipo/proto.js`, no estilo Lucide (licença ISC). Importação `svg/scale=4.0`
(96×96), filtro linear no desenho; itens e personagens continuam pixel art. Catálogo:
`x/back/chev/down/check/lock/plus/minus/clock/help/list/arrow/spark/gear/recenter/talk/info`.
Não apagar os PNGs legados nesta etapa. `UiKit.ctl_icon` faz cache; `UiKit.ctl` cria o controle tingido.

Fredoka e Nunito variáveis foram copiadas de `docs/plans/interface2/prototipo/fonts/` para
`game/assets/fonts/`, com suas licenças `OFL_Fredoka.txt` e `OFL_Nunito.txt`.
FontVariation: Fredoka 600 (`font_display`), Nunito 700 (`font_body`/`main_font`) e Nunito 800
(`font_caption`), eixo `wght` = 2003265652, números tabulares, fallback `story_symbols.fnt` preservado.
Importação: antialiasing cinza, hinting leve, sem mipmaps nem MSDF. Jersey10 permanece no disco.

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

### Ícone da cenoura — troca aprovada (18/10/2026, Codex)

- Cenoura vertical confirmada pelo Vitor, referida como `cenoura_v2_x5.png`; fonte PixelLab `gallery:e090cc73-1df5-596c-ad06-57399d364552`, PNG transparente 96×96.
- Original aplicado sem redesenho ou ampliação em `ui/icons/item_carrot.png`, preservando o caminho compartilhado dos menus. A UI ajusta o tamanho mantendo a proporção; a planta madura no canteiro permanece a mesma.
- Fonte e ícone anterior em `build/art_sources/cenoura_v2/` (ignorado no git). Alteração local, sem publicação.
- Conferência visual do PNG e reimportação headless no Godot concluídas sem erro (`build/carrot_import.log`); `.import` existente preservado.

### Interface nova — Etapa 09, cantinho e cuidados (15/10/2026, Codex)

| Asset | Job / asset PixelLab | Destino / escolha |
|---|---|---|
| Cantinho original | Pro `f217fed7-cfa9-4891-a2d5-a2e663baed91`; asset `023aa614-82e0-55f0-a235-c53d4b0d6ac5` | `areas/pet/corner.png`, 360×420, mantido a pedido do Vitor. Referência `areas/house/room.png` via upload `b5e3093b-c7bc-4bd2-8149-69e6b517aed3`. |
| Esponja | Pixen `a656ecc4-0d24-48e0-a40e-29ac0680f870`; asset `fbafa795-4221-5250-9436-f369239d1d43` | `ui/icons/action_sponge.png`, fonte 32×32, `Invoke-TrimSprite` → 32×29. |
| Caderninho | Pixen `4f71ac45-ffa2-4000-a440-a7a25b2e226f`; asset `44523362-8e82-55b3-a7fe-c16bcee924ce` | `ui/icons/ui_notebook.png`, fonte 32×32, recorte 29×26. |

Ícones transparentes, contorno preto, detalhe médio; aprovados na primeira tentativa. Imagens avulsas não aceitam tags; registro local `tiro-adventure`, `interface`, `ativo`. Pranchas abertas antes da escolha: `build/preview/etapa09/icones.png`, `cenario.png`, `cenarios.png`. Originais e candidatos em `build/art_sources/interface_etapa09/`; PNGs e `.import` versionados.

O primeiro cenário tinha uma moldura bege vazia dentro do próprio PNG. A pedido do Vitor, a tela foi recomposta e o cenário original mantido fiel: `PetBackdrop` desenha o recorte `36,72,289,277` na proporção original e continua parede/piso pela tela; nenhum objeto novo foi pintado. Patas e sombra seguem o centro do tapete. Um candidato Pro 360×640 (`16f6f287-121d-4fdc-948d-5fc5c582f981`, asset `0387c504-ad45-514e-898b-f5aa1fe0393a`) preencheu as bordas, mas trouxe um astronauta: descartado e **não usado no jogo**. O edit Pro Flash foi recusado pela ferramenta (limite 256×256). Terceira geração `577d1b3f-5325-4ead-a918-d57e569eede4` cancelada quando o Vitor pediu fidelidade à primeira imagem.


### Interface nova — Etapa 05, apartamento (15/10/2026, Codex)

- Ajuste do Vitor antes de encerrar: o lar é um apartamento; substituir o desenho da casinha em todos os lugares.
  Trocado o PNG compartilhado `ui/icons/tab_house.png`, preservando o caminho usado por mapa, carrossel,
  missões, atalhos, retorno à Casa e demais referências. Nenhuma mudança de texto ou comportamento.
- Dois candidatos Pixen 32×32 transparentes, contorno preto e detalhe médio. Escolhido o primeiro,
  prédio claro com janelas azuis e sacadas, seed 61, job `29c08d77-863c-4ff3-bb08-e6643967d8f0`,
  asset `b6ab45da-c72c-5291-a681-85058a5ac5f8`. Recorte `Invoke-TrimSprite` 32×32, sem ampliar.
- Alternativa seed 62: job `a057f31e-8d6e-402a-b916-f11ff06c6bfa`, asset
  `4ddadafb-b4fe-528c-b487-9d7e4f13b3ea`, preservada como candidata sem uso.
- Originais e ícone anterior em `build/art_sources/interface_etapa05/apartamento/`;
  pranchas abertas em `build/preview/etapa05/apartamento/` (`candidato_01`, `candidatos`, `interface_final`).
  Conferidos no jogo a pílula, o carrossel e o destino das missões; capturas em `build/screenshots/etapa05_apartamento/`.
  Import Godot, `ui_base_test`, `worlds_test` e `world_selector_test` PASS; export prod/dev atualizado.

### Interface nova — Etapa 05, ícones dos mundos (15/10/2026, Codex)

- Pixen 32×32 transparente, contorno preto, detalhe médio; dois ícones aprovados na primeira tentativa.
  A ferramenta `create_image_pixen` não aceita referência nem tags em imagens avulsas; registro local
  `tiro-adventure`, `interface`, `ativo`. Nenhum upload de referência foi necessário.
- Vila: casinha com telhas e toldo, seed 51, job `c636389e-4c2a-4d46-8b56-9a1bc43d2ac3`,
  asset `1684de67-7bd5-5c59-aca3-39c1c2865285`; destino `ui/icons/tab_village.png`.
- Natureza: pinheiro, pedra e riacho, seed 52, job `e64d99fa-8da9-474f-93e1-5f2caf163171`,
  asset `8548e7b4-1ae0-5726-b592-b85c1a34f408`; destino `ui/icons/tab_nature.png`.
- Originais em `build/art_sources/interface_etapa05/`; prancha com os três ícones existentes
  aberta antes da escolha: `build/preview/etapa05/icones_candidatos.png`. `Invoke-TrimSprite`
  recortou Vila para 32×30 e Natureza para 22×28; ambos recentralizados em canvas transparente 32×32,
  sem ampliar. Script reproduzível `prepare_art.ps1` nessa pasta, executado no Windows PowerShell 5.1.
- `worlds.json → icon` alimenta a pílula e os cartões. Importados no Godot; PNG e `.import` versionados.
  Para a viagem foi usada a alternativa do plano: duas coberturas `Palette.PAPER` arredondadas,
  evitando esticar a pequena arte das nuvens até perder a definição. Nenhuma arte do mundo foi alterada.

### Interface nova — Etapa 04, revisão do chão (15/10/2026, Codex)

- Pedido do Vitor após o commit `7e84772`: dar mais textura ao chão e corrigir o aspecto das maquetes.
- PixelLab Pixen, 128×128 opaco, sem contorno: 1ª tentativa, detalhe médio/seed 41, job
  `7a7f9959-4337-4c44-a076-b47d7d5f630e` (asset `34a0e550-8cdc-52e9-be48-a6e52de74eb5`), rejeitada no jogo por densidade excessiva.
- Escolhida a 2ª tentativa (detalhe baixo/seed 42, tufos esparsos), job `7d10c4a5-0abc-486c-ab37-dd2624975827`,
  asset `f4749cd6-949e-5f04-808a-0f80448f4f6e`. Originais: `build/art_sources/interface_etapa04/revisao/grass_try1|2.png`;
  prancha aberta antes da escolha: `build/preview/etapa04/grass_candidates.png`. Destino: `areas/common/grass_ground.png`,
  recortado com `Invoke-TrimSprite` (128×128; textura opaca, sem margem).
- `WorldGround` preserva os detalhes e ajusta a luminosidade à cor do chão de cada mundo, sem gerar quatro cópias.
  O mesmo recurso cobre as laterais de terra; UV e repetição acompanham o mapa para evitar emendas durante arrasto/zoom.
- Fundos, nuvens e ícone do commit anterior foram preservados; nuvens/névoa ficam desligadas nos JSON conforme o ajuste
  visual iniciado pelo Claudi. Nenhum cenário, objeto ou sprite do Tiro foi substituído.

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


### Etapa 07 do começo (passeios) — 14/10/2026 (Claude Code + Codex)

Retomados oito jobs da conversa Claude `bda53413-221b-4067-8fff-56762caff35b`; demais ícones gerados
na continuação. Originais e tentativas em `build/art_sources/etapa07/` (ignorada pelo git).
Postais: `create_image_pro`, 128×80, referência do sítio, quatro candidatos por caminho; prancha
`build/preview/etapa07_postais.png`. Ícones: `create_image_pixen`, 32×32 transparente, contorno preto,
detalhe médio (estrela final: baixo); prancha `etapa07_icones.png`. Canvas inteiro preservado para
alinhamento dos ícones em 32/64 px; postais sem recorte. O postal `park_loop` é reutilizado da Etapa 06.

| Asset | Job PixelLab | Destino em `game/assets/sprites/` / escolha |
|---|---|---|
| `flower_street` | `bfe03a08-0398-4657-8c81-5df4841b202b` | areas/walks/flower_street.png; candidato 0 |
| `village_fair` | `85ffb543-015d-4603-b316-e7a4e307f82e` | areas/walks/village_fair.png; candidato 1 |
| `creek_walk` | `03183dcf-7878-4314-9302-428519b4cce7` | areas/walks/creek_walk.png; candidato 1 |
| `bird_clearing` | `9c944460-ecff-4479-aec6-2c8295ecbf72` | areas/walks/bird_clearing.png; candidato 1 |
| `hill_view` | `3e5bf3f3-4d44-446d-9c37-78f5ee4296dd` | areas/walks/hill_view.png; candidato 0 |
| `sunset_walk` | `16bd6978-c514-43c5-8ca8-e2508f72b31d` | areas/walks/sunset_walk.png; candidato 2 |
| `item_stick` | `eb8d5de6-8fd3-449c-9259-f4f0cb8302cd` | ui/icons/item_stick.png; inteiro |
| `item_ribbon` | `49a59445-a315-4d53-9dcb-b97781be80c8` | ui/icons/item_ribbon.png; inteiro |
| `item_wildflower` | `7664b3b0-e2e3-400e-af3f-cdcad7f0840a` | ui/icons/item_wildflower.png; inteiro |
| `item_color_button` | `df3d0993-1582-4519-a7b1-1ac29acd3816` | ui/icons/item_color_button.png; inteiro |
| `item_yarn` | `5c56439c-5e77-44a5-8c2f-7e0e6e84bf36` | ui/icons/item_yarn.png; inteiro |
| `item_smooth_pebble` | `33c95f6e-9490-47b9-afdb-f31d8519bfd7` | ui/icons/item_smooth_pebble.png; inteiro |
| `item_river_shell` | `21635bef-3b7d-41e3-b75e-43f4e8a6c01a` | ui/icons/item_river_shell.png; inteiro |
| `item_wild_mint` | `cf2b1c5a-a448-41c9-8a39-46504a0154ed` | ui/icons/item_wild_mint.png; inteiro |
| `item_bird_feather` | `12c88074-3f00-4cb8-8fd7-5b0c73a8e28b` | ui/icons/item_bird_feather.png; inteiro |
| `item_golden_leaf` | `d0c6d973-0876-479e-9255-841663b5cfc9` | ui/icons/item_golden_leaf.png; inteiro |
| `item_moon_pebble` | `baafcbfa-96e3-439f-83ea-7aeeaf50fa5a` | ui/icons/item_moon_pebble.png; inteiro |
| `item_mint_snack` | `910a5691-ab02-44a0-bb06-b1f94c5e4488` | ui/icons/item_mint_snack.png; inteiro |
| `rare_star` | `b1242dfc-f706-4025-ba6f-12596b799f72` | rejeitado (rosto/personagem); só nos originais |
| `outfit_plaid_bow` | `2b6e3ced-dce8-4072-a030-15b7b73a30b4` | ui/icons/outfit_plaid_bow.png; inteiro |
| `outfit_flower_clip` | `9153523d-2c29-463b-a699-03e378e78406` | ui/icons/outfit_flower_clip.png; inteiro |
| `outfit_bow_tie` | `7ab2e100-8a06-4380-993f-3650c61c117a` | ui/icons/outfit_bow_tie.png; inteiro |
| `outfit_sailor_scarf` | `7f711272-b424-45c8-97c4-6b44a530ff6a` | ui/icons/outfit_sailor_scarf.png; inteiro |
| `outfit_explorer_backpack` | `e5df9a2d-0a21-46d6-89e3-3bcae1d5ff47` | ui/icons/outfit_explorer_backpack.png; inteiro |
| `outfit_star_glasses` | `0c5e8c89-8a88-49ca-9712-2402d4ed1e45` | ui/icons/outfit_star_glasses.png; inteiro |
| `outfit_glow_collar` | `c2e85ccd-2829-434b-97d9-ed4e729c1438` | rejeitado (rosto/personagem); só nos originais |
| `outfit_glow_collar_retry` | `6b02fb17-ccdf-439a-a7b5-35919f40b0c0` | ui/icons/outfit_glow_collar.png; inteiro; 2ª tentativa (colar vazio) |
| `rare_star_retry` | `ad61323a-2b1f-4e21-8d37-c65a90961492` | rejeitado (rosto/personagem); só nos originais |
| `rare_star_retry2` | `ec0a6c18-5424-413a-84ef-30a6b8358196` | ui/icons/rare_star.png; inteiro; 3ª tentativa (estrela geométrica) |

Revisão: postais distinguíveis por cenário; materiais por cor/silhueta; estrela sem rosto e coleira
sem cachorro escolhidas nas novas tentativas. Não há arte de vestir, costura ou quiosque da Etapa 08.

### Etapa 08 — investigação do lenço (Parte A), 14/10/2026 (Codex)

**Lenço e método aprovados pelo Vitor em 14/10/2026**, após as comparações transfer_outfit abaixo.
Somente `red_scarf` gerado; nenhuma outra roupa, ícone ou quiosque novo.
Base: `characters/tiro_pet/idle_breathe/frame_00.png`, 256×216, upload
`a70f0dcc-83ba-4563-94fd-a7ef218306dd`. Originais em `build/art_sources/etapa08/`.

| Asset / candidato | Job PixelLab / galeria | Escolha e extração |
|---|---|---|
| Lenço 01, `edit_image_pro_flash`, text, transparente, correção de paleta ligada | `d429285f-1090-472c-9e98-a14362ee09f7` / `c0da5219-6503-5776-9920-8e6556ec0fbb` | Rejeitado: tecido rosado e sombras marrons; diferença RGBA com tolerância 24 = 5376 pixels visíveis, incluindo alterações indevidas no pelo |
| Lenço 02, mesma ferramenta, correção de paleta desligada, pedido explícito de vermelho escarlate | `92028668-23bb-4ae6-a226-6b25d1b4ad23` / `1e182345-d212-56f1-b1e6-673a4c03a015` | Candidato apresentado ao Vitor; diferença bruta = 6180 pixels. `tools/scarf_extract.ps1` retém tecido vermelho e contorno adjacente, exclui boca e resíduos pequenos do pelo. Sobreposição em `characters/tiro_pet/overlays/red_scarf.png` |

`New-OverlayFromDiff` em `tools/pixel_tools.ps1` soma diferenças RGBA, copia o pixel vestido quando
excede 24 e mantém o restante transparente; rejeita tamanhos diferentes. Canvas 256×216 inteiro,
sem trim e offset inicial 0,0. Verificado com imagens idênticas (0 pixels) e candidatos reais.
`New-ContactSheet` recebeu dimensões inteiras para funcionar em `powershell.exe`/System.Drawing.
Limpeza local reproduzível em `tools/scarf_extract.ps1`; prancha `red_scarf_review.png` contém base,
candidato e sobreposição. Nenhuma mudança do cachorro do candidato é levada ao jogo.

`tools/scarf_preview.gd` gera capturas 360×780 sem headless, com timeout externo de 60 s, e remove
SaveManager antes de preparar a demonstração. Tela Tiro: `build/screenshots/etapa08_lenco/tiro_lenco.png`.
As 22 capturas `alinhamento_<animação>.png` foram abertas: primeiro/meio/último quadro, lenço sempre
visível de propósito para expor falhas. São diagnósticos, não o comportamento final da roupa.

`overlay_anchors.json` é **provisório, sem consumidor no jogo ainda**: offset 0 nas 12 poses que
mantêm o pescoço no lugar (`idle_breathe`, `wag_excited`, `head_tilt`, `look_around`, `yawn`, `pet_head`,
`pet_paw`, `sniff`, `scratch`, `bark`, `give_paw`, `shake_off`). Nas acrobáticas (`happy_jump`,
`roll_over`, `belly_rub`, `belly_kick`, `chase_tail`, `stretch`) deverá desaparecer/voltar conforme plano.
`sad`, `eat`, `lick_paw` e `sleep` mudam o pescoço durante a sequência: offset único não basta.
**Pendente antes do aceite final:** corrigir esses alinhamentos; sono deve manter roupa visível,
não se deve considerar sua ausência no `show_in` provisório como decisão de design aprovada.

#### Teste autorizado de `transfer_outfit` — 14/10/2026

Após perguntar sobre troca de roupa preservando personagem, Vitor autorizou testar somente o lenço
nas poses difíceis. Depois das capturas, aprovou o lenço e o método ("Sim!") e pediu visualizar o
catálogo de acessórios. Documentação do PixelLab distingue `create_character_state` (variante nas rotações)
de `transfer_outfit` (roupa de uma referência aplicada aos quadros existentes, mantendo poses).

| Teste | Job / galeria | Entradas e resultado |
|---|---|---|
| Lenço em três poses, `transfer_outfit`, seed 8, 256×216 transparente, 25 gerações | `6540f6c6-3893-4e9a-82b1-b0b34e1e16ab` / `d243bbce-5cbf-5ba5-ab04-2f38a2577fca` | Referência `red_scarf_candidate_02.png`, upload `823d4afb-1232-483f-8d08-d672284ab693`; quadros na ordem: `eat/frame_04.png` (`76f8f1c8-855d-4084-b69f-9851ccbc429b`), `sleep/frame_16.png` (`1ade4547-84b1-40d8-a72b-01c37280f888`), `lick_paw/frame_04.png` (`9f84ea7b-697c-4568-acd3-14a01785d2d6`); resultados `build/art_sources/etapa08/transfer_eat_04.png`, `transfer_sleep_16.png`, `transfer_lick_paw_04.png` |

Capturas 360×780, sem headless e timeout externo de 60 s, abertas e conferidas:
`build/screenshots/etapa08_lenco/transfer_{eat,sleep,lick_paw}.png`. Cada uma mostra original,
sobreposição fixa e transferência; `tools/scarf_preview.gd -- --transfer` reproduz a comparação.
Hashes dos JSON de save antes/depois idênticos. Nenhum resultado transferido foi instalado no jogo.

Conclusão visual: lenço acompanha o pescoço e deixa de cobrir olhos/testa nas três poses. Dormindo,
só se vê a borda do tecido atrás da cabeça e o nó lateral; tigela e gesto de lamber foram preservados
visualmente. Porém, também há mudanças no pelo, cor da tigela e contornos. Medição de diferença RGBA
>24 fora da região do tecido vermelho (bbox expandida 5 px): comer 4390 pixels, sono 1287, lamber 2665;
mudança de silhueta (alpha >0,1): 1192/517/985 pixels respectivamente. É uma região aproximada,
não uma máscara semântica perfeita, mas confirma que a edição não é restrita à roupa.

Transferência é candidata para gerar **camadas por pose/quadro**, após limpar as mudanças do cachorro;
usar quadros completos dificultaria combinar cabeça/pescoço/corpo e mudaria a base original.
O teste contém três poses isoladas: **não valida continuidade temporal** das animações completas.
Visual aprovado; ainda é necessário testar extração por quadro/continuidade.
Prancha de apresentação `build/art_sources/etapa08/accessories_catalog.png`: sete ícones já existentes
da Etapa 07, ampliados 2× sem nova geração, com nomes. Não representa sobreposições já instaladas.

#### Conjunto lendário Bob Esponja — prévia pedida pelo Vitor, 14/10/2026

Vitor escolheu **uniforme e chapéu**, pedindo detalhes mais reconhecíveis do Bob Esponja.
Adição à Etapa 08 documentada no plano: `sponge_uniform` (body) e `sponge_hat` (head).

| Asset | Job / galeria PixelLab | Originais e revisão |
|---|---|---|
| Tiro com uniforme + chapéu, candidato conjunto 01 | `edit_image_pro_flash`, job `295e9865-483c-4774-972e-04281cd9f5c1`, galeria `a6c13b6d-db0b-54ce-a8b0-15a0b9ae872e`, 9 gerações | `build/art_sources/etapa08/sponge_set_candidate_01.png`, 256×216 transparente, sem correção de paleta. Base `idle_breathe/frame_00.png`, upload `b818f77a-fc35-4486-9394-b28ad0c8b212` |

Prévia aberta e conferida: uniforme amarelo com poros em tons de ocre, gola branca, gravata vermelha,
barra marrom com cinto e fivela, detalhes listrados de meias; chapéu branco com âncora azul,
contorno/detalhe vermelho e marca amarela com poros. Rosto e orelhas do Tiro continuam visíveis.
Visual do conjunto aprovado pelo Vitor: "Perfeito!", após a captura ser reenviada diretamente.
Captura 360×780 sem headless, timeout externo 60 s:
`build/screenshots/etapa08_lenco/tiro_esponjinha_conceito.png`, reproduzida por
`tools/scarf_preview.gd -- --sponge`. Script passou em `--check-only`; saves com hashes idênticos
antes/depois. É **conceito estático**, não roupas já implementadas: separar slots/ícones/camadas,
validar animações e definir obtenção/garantia lendária ainda pendentes. Nenhum PNG da prévia
foi instalado em `game/assets/`; não altera os sete raros ou a Etapa 09.

#### Roupas após aceite — lote 01 (14/10/2026)

Oito jobs enviados após o aceite do conjunto. `edit_image_pro_flash`, referência
`idle_breathe/frame_00.png` (upload `b818f77a-fc35-4486-9394-b28ad0c8b212`), canvas 256×216,
transparente, sem correção de paleta. Vestido completo como candidato; extrair e conferir as camadas
antes de instalar. Originais previstos: `build/art_sources/etapa08/<id>_candidate_01.png`.
Os outros sete envios foram recusados pelo limite de oito jobs ativos, sem job criado;
reenviar somente após liberar vagas. Manifesto local `jobs_outfits.json`.

| Peça | Job | Galeria | Estado |
|---|---|---|---|
| blue_collar | `225c7238-c38e-4abd-8890-dd841b5deae8` | `dbfd7907-12f5-5993-ba74-a489aa04ba50` | candidato 01, em processamento |
| yellow_bow | `a5516e67-bd6e-49c5-9d80-3394fb852969` | `733e6845-8ff0-5aaa-a96d-d5ea5df09ab3` | candidato 01, em processamento |
| rain_coat | `81492d05-eb22-4d14-bef7-5bc5bbff76a4` | `f47b58c8-fdea-500e-a368-9f05621d1a58` | candidato 01, em processamento |
| plaid_bow | `a575cff3-3b59-4ab9-98de-03b30da6d8ed` | `6e99b6bb-841e-5dbc-9cae-fb8e2f34b71f` | candidato 01, em processamento |
| flower_clip | `fad43570-6926-4103-95e9-a71871b21677` | `6036a4dc-c41e-5d1d-8c6f-da24b40aa548` | candidato 01, em processamento |
| bow_tie | `ec2cad34-66c9-4816-bf79-d1b3f228dbf7` | `750c59f9-7536-54c9-a1cf-66a4cc0fc4b5` | candidato 01, em processamento |
| sailor_scarf | `624123c3-f6cc-4b32-a72f-7c701dd0eb19` | `b5b3a12a-b44f-57c1-b3a3-31e205bf3a8e` | candidato 01, em processamento |
| explorer_backpack | `1c7f3829-dd05-4578-a6f0-1779194efcfd` | `22cf3d85-d70b-55ff-98dd-6385aba025f8` | candidato 01, em processamento |

### Etapa 08 concluída — artes instaladas e alinhamento (14/10/2026, Codex)

Lenço e método aprovados pelo Vitor antes dos demais; conjunto Bob Esponja também aprovado após
reenviar a imagem diretamente. Os estados "em processamento" acima são o histórico da investigação.
Todos os candidatos abaixo foram baixados em `build/art_sources/etapa08/` e abertos em pranchas.
Origem das edições: `idle_breathe/frame_00.png`, 256×216 transparente, sem correção de paleta.

| Sobreposição | Job PixelLab | Galeria | Escolha / máscara |
|---|---|---|---|
| `blue_collar` | `225c7238-c38e-4abd-8890-dd841b5deae8` | `dbfd7907-12f5-5993-ba74-a489aa04ba50` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `yellow_bow` | `a5516e67-bd6e-49c5-9d80-3394fb852969` | `733e6845-8ff0-5aaa-a96d-d5ea5df09ab3` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `rain_coat` | `81492d05-eb22-4d14-bef7-5bc5bbff76a4` | `f47b58c8-fdea-500e-a368-9f05621d1a58` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `plaid_bow` | `a575cff3-3b59-4ab9-98de-03b30da6d8ed` | `6e99b6bb-841e-5dbc-9cae-fb8e2f34b71f` | Falhou na fila do serviço; substituído pelo novo job |
| `flower_clip` | `fad43570-6926-4103-95e9-a71871b21677` | `6036a4dc-c41e-5d1d-8c6f-da24b40aa548` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `bow_tie` | `ec2cad34-66c9-4816-bf79-d1b3f228dbf7` | `750c59f9-7536-54c9-a1cf-66a4cc0fc4b5` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `sailor_scarf` | `624123c3-f6cc-4b32-a72f-7c701dd0eb19` | `b5b3a12a-b44f-57c1-b3a3-31e205bf3a8e` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `explorer_backpack` | `1c7f3829-dd05-4578-a6f0-1779194efcfd` | `22cf3d85-d70b-55ff-98dd-6385aba025f8` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `plaid_bow` | `d38fab7e-53f8-4af8-bb26-4214996bead6` | `ddef8071-9eb0-598b-b97a-3f6ec7b65daa` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `star_glasses` | `e688e33f-6049-4c51-b348-abac6ffce0da` | `d05945ab-c42b-5764-b373-c97250e20960` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `glow_collar` | `128f7afb-f5d1-4529-86bd-204f3cb6dbef` | `31208c9e-c580-5b7b-b06b-549ba13e1b03` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `flower_crown` | `ad289c29-cff6-41e2-8ad8-4455b830666e` | `dd4d9d77-7f3b-5454-9ad3-1e674a33c2b4` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `shell_collar` | `9c3358ab-0acf-40d6-b824-0bf9a8a1daa4` | `c2905027-f518-5a92-bbe0-98c8970a5201` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `knit_sweater` | `c0890275-b3e3-4f0f-92ee-ce5085133d82` | `5cbd2476-fbec-57fc-8c2c-65a93513470f` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `feather_hat` | `5a896563-792b-4048-8e50-f8d7104d62f4` | `07a303a7-50a6-553b-8050-08f88b9eb957` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |
| `golden_cape` | `81c1755f-c0b8-4af2-a45d-fa37bf4e05b1` | `8d53afa8-be50-5a97-ba42-d8e0231fd3c8` | Candidato 01; polígonos em `tools/outfit_extract.py`; canvas inteiro |

`flower_clip` agora representa **Óculos escuros**. O id antigo foi conservado para manter
as conquistas e garantias da Rua das flores nos saves da Etapa 07; ícone e roupa foram substituídos.
`sponge_hat` e `sponge_uniform` foram separados do candidato conjunto aprovado (`295e9865-483c-4774-972e-04281cd9f5c1`).

| Ícone 32×32 | Job | Galeria | Escolha |
|---|---|---|---|
| `outfit_red_scarf` | `721441ab-ee5a-445b-9fde-feedd330de6e` | `c79a5c26-5f88-5b3b-bda9-a61843024a60` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_blue_collar` | `a4bbede8-efb8-4d21-b8d8-acdaf1fc7e24` | `cda202d6-09c7-58d6-b2ed-4e1f0249276c` | Instalado; 1ª tentativa |
| `outfit_yellow_bow` | `312eef9e-dce4-4702-83d0-53c2823c5d0b` | `eb873fd3-4a37-5696-8c15-121e37e1a5d8` | Instalado; 1ª tentativa |
| `outfit_rain_coat` | `7de525b2-b9b5-43c9-b613-b8776f34d1b0` | `164c8e3c-c76d-5e57-8a44-e3501ea3762b` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_flower_crown` | `18013c92-d43e-400c-a5ef-855c58223188` | `e972c3e7-dd8c-5966-a1d6-da7c050dc0fc` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_shell_collar` | `0736077a-4f42-4d2f-b735-323e1d634003` | `4f345358-6c29-573b-a5bf-fe6a045e428b` | Instalado; 1ª tentativa |
| `outfit_knit_sweater` | `c4b612d2-27f6-49ee-a055-3aec2d27dff6` | `0960c08b-fc88-56f4-8c6d-7c0646d51afe` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_feather_hat` | `0610bbbf-53db-45bb-8817-2a0da0503c4e` | `330b0524-ecfa-519c-ba60-037fe98d71d6` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_golden_cape` | `ff4980c5-55c0-4667-b199-3487be664b8a` | `25f894c0-9182-5e8c-afff-f7c7a8ef85a4` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_sponge_hat` | `db9772f7-53f2-407e-9736-2898ffa9846e` | `e594464e-bae4-58d1-ab55-16a94c79ca7c` | Instalado; 1ª tentativa |
| `outfit_sponge_uniform` | `58cf292d-bf69-445d-97f4-dcc3bd71264d` | `2ebb5d13-962f-5b0a-87be-9ea258725e9c` | Rejeitado: personagem/rosto dentro do ícone |
| `outfit_flower_clip` | `fe1b0f4f-65e5-4a4c-bffd-d09f79fde1d7` | `b9918c92-7542-5c59-a703-6d854acdf3de` | Instalado; 1ª tentativa |
| `petshop` | `7369eb45-2c29-4e41-a242-3fab77888fe2` | `ce5c1050-c0fe-521d-9545-8f55dbe3981a` | Instalado; 1ª tentativa |
| `action_sew` | `5aab422e-27fd-42c0-ae19-66511d6e476a` | `72c9ca90-0b53-5ac5-a64c-348690d60b94` | Instalado; 1ª tentativa |
| `outfit_feather_hat` | `8bf5898a-b1c3-43bd-89bb-ab241a04d114` | `06fb3aa6-f1b2-5f37-804e-fbcca81e4f04` | Instalado; 2ª tentativa, peça vazia |
| `outfit_flower_crown` | `196f4b2d-3ed7-4962-89c4-f851269cbd96` | `8c9bd141-aa25-5fe3-b85c-183da6068174` | Instalado; 2ª tentativa, peça vazia |
| `outfit_golden_cape` | `a95880f0-b2f5-4f7c-add2-4fad72d77059` | `4a73f39c-38fe-5000-ae29-426274d61397` | Instalado; 2ª tentativa, peça vazia |
| `outfit_knit_sweater` | `f842f52c-5e8f-49ee-b74e-0faf507e6680` | `20793eaa-b17d-5d8d-b432-95be47ebe61e` | Instalado; 2ª tentativa, peça vazia |
| `outfit_rain_coat` | `8a502fba-e285-48b3-9659-d6cf3f2ef939` | `4035d16d-2dd6-5add-a8f1-0fe1ec570802` | Instalado; 2ª tentativa, peça vazia |
| `outfit_red_scarf` | `cfcd697a-d5ef-4745-8aef-0a927e058a91` | `7b2e76ae-ce70-5f34-b21f-814433f08302` | Instalado; 2ª tentativa, peça vazia |
| `outfit_sponge_uniform` | `80227967-fac9-448b-b1e6-f93ac1705d12` | `fb2019c4-5a9a-5026-a4bd-e351920d7209` | Instalado; 2ª tentativa, peça vazia |

Ícones gerados com `create_image_pixen`, contorno preto, detalhe médio, transparente; pranchas
`icons_review.png` e `icons_retry_review.png` abertas. Sete primeiras tentativas tinham personagem;
as sete novas versões mostram só o acessório. Demais ícones dos raros reaproveitados da Etapa 07.

| Objeto | Job / objeto PixelLab | Destino e encaixe |
|---|---|---|
| Quiosque 96×96 | `1a3d078c-96ee-40d1-928b-933dc3a8586a` / `1bd1cc85-f64e-4c9b-8d18-2dcde30b4ad2` | `areas/park/petshop.png`: placa de pata e mercadorias recortadas; o balcão/toldo já desenhados no fundo são preservados |
| Costura 48×48 | `36cabb13-fa92-45c0-b826-9a29069483d4` / `cc894cc4-0ca5-440c-a751-a394b426fc06` | `areas/park/sewing_table.png`: recorte alpha, dentro do balcão; StationIndicator |

Objetos: `create_object_pro_flash`, uma direção, low top-down. Não foi sobreposto um segundo
balcão: extraídas só a placa e as mercadorias; o cenário mantém seus 15 obstáculos originais.
Placa em `[500,209]`, mesa em `[531,191]`, sem footprint adicional, aproximação em `[449,209]`.

**Pipeline final das roupas:** `New-OverlayFromDiff` mantém a diferença bruta RGBA (tolerância 24).
`tools/outfit_extract.py` recorta o tecido por polígonos revisados e preserva o cachorro original
fora das roupas. Canvas 256×216 e origem do quadro conservados. Há 18 bases e 954 variantes
(972 PNGs), para `sad`, `eat`, `lick_paw`, `sleep` e `head_tilt`. As variantes reutilizam as artes
PixelLab com âncoras, nearest-neighbor e máscaras de oclusão da face; não são 954 novas gerações.
O lenço nas poses de comer, dormir e lamber usa também o tecido extraído diretamente dos três
quadros `transfer_outfit` aprovados, sem transportar o pelo redesenhado. As demais poses usam
a base fixa. `overlay_anchors.json` controla visibilidade; seis acrobáticas ocultam as camadas
e o descanso as restaura. Dormir mantém roupa/chapéu: tecido aparece sobre as costas, atrás da cabeça.

PetAnimator usa camadas corpo → pescoço → cabeça e cache limitado a 48 texturas; retratos
de Desejos e boas-vindas usam recorte do canvas para o Tiro continuar legível em 64 px.
`rare_star.png` recebeu limpeza de fundo escuro residual, com original preservado em build.
Godot `--headless --import` concluído; PNGs, imports e UIDs entram no commit.

**QA:** 40 capturas 360×780 sem headless, com timeout externo de 120 s, em
`build/screenshots/etapa08/`; abertas e conferidas (lenço, 3 roupas, lendários juntos/sono, 22
animações, Desejos, Coleção, Praça antes/depois, loja/costura/fila, raro e lendário com Vestir agora,
cartão de roupa costurada e Diário). Pranchas `anim_review_00..02` e `outfits_review_<pose>`
conferem os quadros e as 18 roupas nas cinco poses difíceis. Roteiro: `tests/petshop_shots.gd`.
A introdução foi marcada como vista no estado de captura; nenhum save pessoal foi substituído.
Exportação Web local de produção e desenvolvimento concluída sem erros; `overlay_anchors.json`
conferido dentro dos dois pacotes exportados. Saída em `build/web/` e `build/web/dev/`, sem publicação.

## Etapa 09 — Amigos do Tiro (14/10/2026, Codex)

Originais, ZIPs, 48 candidatos de retratos e pranchas em `build/art_sources/etapa09/`.
Pipoca reutiliza integralmente `dog_pipoca` (rotações, caminhada, retrato e seguir Nina).
Três personagens novos gerados no PixelLab com `create_character`, modo pro, quadrúpede dog,
64×64, oito direções e estilo `8e4e8b4d-142c-4d14-a012-29f16506a0a4` (Tiro mundo v2).
Tags: `tiro-adventure`, `cachorro`, `amigo-<id>`, `ativo`.

| Arte | Personagem/job PixelLab | Destino e escolha |
|---|---|---|
| Mel, poodle branco com laço rosa | `e08c0939-df2d-4492-bc5a-6b0efacd2cea` | `characters/dog_mel/rotations/`, oito PNGs 64×64 |
| Bolota, pug fulvo com focinho preto | `2404fb8f-36bb-4904-9b61-30c257b24d07` | `characters/dog_bolota/rotations/`, oito PNGs 64×64 |
| Fred, beagle tricolor | `c3be7d02-3743-4af4-b357-e88cfa541132` | `characters/dog_fred/rotations/`, oito PNGs 64×64 |
| Mel, caminhada S/E/N | `d967dc18-71a3-4dc6-8ac3-3336e40c6783`, `b51a5f2f-e5da-4155-a9db-bef28448b85f`, `a2d4184e-c188-4c80-a6b6-d0ac4fe091a4` | grupo `94723892-1a88-4511-b759-04df0250102f`; `dog_mel/walk/<direção>/frame_00..07.png` |
| Bolota, caminhada S/E/N | `91542b5e-01fd-411b-a144-c89e4a4dd2ab`, `b69427e1-5918-4b0b-95f7-9d9f507d15ca`, `2d40c5f1-8112-4a00-be7d-2d3bdecc45fb` | grupo `fd21141a-e060-452b-9d87-51095a895539`; `dog_bolota/walk/` |
| Fred, caminhada S/E/N | `af384cc9-6448-4d43-9ad3-392d0ffedd1b`, `0e049a26-573b-46e3-9e81-958882c6bed3`, `37ca8026-2b60-4cc4-9b60-b1af8ef84cff` | grupo `89bda567-321f-4efe-9898-eb29f5a43617`; norte enviado separadamente por limite de slots |
| Retrato Mel | `b0699cb3-268b-4ae6-a275-a05a9505c935` (galeria `5c8d1056-c7b3-5007-827c-d5799f5ffe77`) | 16 candidatos; escolhido **0**, laço no alto como no sprite; `dog_mel/portrait.png` |
| Retrato Bolota | `73a46937-71f7-4fb8-b3fb-57e92ded07bd` (galeria `b2795d2a-46fa-580f-8f0e-b0390cef3b14`) | 16 candidatos; **0**, olhos abertos e sorriso; `dog_bolota/portrait.png` |
| Retrato Fred | `a4e3cebe-7dc7-48eb-82f0-ceacb26116de` (galeria `87c6ab82-f89f-5821-aa56-c6cb2ecb0bc0`) | 16 candidatos; **0**, focinho branco/orelhas castanhas/coleira vermelha; `dog_fred/portrait.png` |
| Ícone Pipoca, tentativa 1 | `3385392f-3831-448a-8c62-e3d87c1aed56` (galeria `c4b0d911-5f19-5e3b-a1e0-dbebdb687670`) | Rejeitado: orelhas caídas, diferentes da Pipoca existente |
| Ícone Pipoca, tentativa 2 | `5531c630-0e45-48ac-9ffb-8b713ab00b3f` (galeria `95b26f1e-e9f9-583d-aa38-6a324886d8fd`) | Rejeitado: corpo inteiro, rosto pequeno em 32 px |
| Ícone Pipoca, tentativa 3 | `408eaba9-f3da-4898-a1fd-49976f6e9f9f` (galeria `559031b4-39b9-5d6b-922a-caabc9e6c0cd`) | Escolhido: somente cabeça e orelhas erguidas, `ui/icons/friend_pipoca.png` |
| Ícone Mel | `ac1f7ca7-3792-43a5-877d-2b087c042b68` (galeria `833988d9-2a32-55b9-abc3-5cb531666cbe`) | Primeiro candidato; `ui/icons/friend_mel.png` |
| Ícone Bolota | `c0465cdc-a6ce-451f-95ea-5419b126c5a2` (galeria `e9dc2c43-f5d1-5351-81ff-b59cd3da00a0`) | Primeiro candidato; `ui/icons/friend_bolota.png` |
| Ícone Fred | `9d378a6f-c359-488f-bced-3a910a00ce5d` (galeria `619336a6-f339-5e1e-ace9-3c1472765b84`) | Primeiro candidato; `ui/icons/friend_fred.png` |

Caminhadas usam o template quadrúpede disponível `walk-8-frames` (não o id humano
`walking-8-frames`), oito quadros por direção. Oeste espelha leste pelo NpcWorld existente.
As poses estáticas são idle: não se inventaram quadros; todos os canvases 64×64 foram preservados
sem recorte, mantendo pivô central. NpcWorld calcula os pés pela última linha opaca da pose sul,
e aplica o mesmo deslocamento às animações. Retratos pro 64×64 usam o retrato existente da
Pipoca como referência de enquadramento/contorno; escolhidos após abrir `review_mel`,
`review_bolota`, `review_fred`. Ícones Pixen 32×32, transparência, contorno preto, detalhe médio.
`review_walks.png` confere os 72 quadros e alinhamentos; `review_dogs_icons.png` confere escala
e diferenciação. O ícone final da Pipoca foi aberto individualmente após a terceira tentativa.

Bandana caramelo usa o ícone `friend_pipoca` previsto no plano. **Sem overlay nesta etapa**:
é recompensa de Coleção, com “Em breve no Tiro” e Vestir desabilitado. Nenhuma camada invisível
ou recoloração improvisada das roupas aprovadas na Etapa 08. Overlay era opcional na 9.1.

Capturas gráficas 360×780, sem headless e com timeout externo de 90 s:
`build/screenshots/etapa09/`, roteiro `game/tests/friends_shots.gd`. Incluem Pipoca decorativa/amiga,
missão Nina, cartão sem/com petisco, janela já atendida, coração 2/bônus, melhor amizade, três
visitantes, Coleção com silhuetas/amigos e rolagem ao fim, bônus somados, Casa, boas-vindas e
presente recolhido. Corações vazios usam ícones apagados (a fonte mapeava ♡ como ♥);
contador tem/precisa sem quebra. PNGs e pranchas abertos e conferidos. Importação Godot final
concluída; PNGs, `.import` e `.uid` versionados. Originais e capturas continuam fora do git.

## Etapa 10 — ícones de truques (PixelLab, 14/10/2026)

Pixen, 32×32 transparente, contorno preto e detalhe médio. Originais preservados em `build/art_sources/etapa10/`; pranchas `candidates.png` (primeira rodada) e `candidates2.png` (pata/fala refeitos), abertas antes da escolha. Destino `game/assets/sprites/ui/icons/`. Canvas inteiro 32×32 preservado para alinhar os cinco ícones em 32/48/64 px, sem recorte que altere o pivô. Importação Godot concluída após cada cópia; PNGs e `.import` versionados. Nenhuma animação ou sobreposição existente substituída.

| Asset/candidato | Job PixelLab | Asset de galeria | Escolha/destino |
|---|---|---|---|
| Pata 1 | `a948dbfd-8dba-4a7d-b4ac-b08ec61c94ce` | `92200ba9-96e9-56af-ab7d-0a499cf746e6` | Rejeitado: cachorro inteiro, não pata; original `trick_paw.png` |
| Pata 2 | `430dd767-c629-47a1-9f4e-0f3458eb6252` | `c080b8fa-400f-583b-b9b9-21c12ed5b6d6` | Escolhido: pata isolada/estrela, original `trick_paw_2.png` → `trick_paw.png` |
| Fala 1 | `487fe857-d7bb-48d4-86ff-e61583fc30f9` | `8015ec37-89a9-518f-93fa-1d228fc22a07` | Rejeitado: parecia quadro com escrita; original `trick_talk.png` |
| Fala 2 | `9acd6057-094d-401d-a6f2-4b44145f6844` | `d74538a9-8a42-5c93-9ebc-53349352a246` | Escolhido: balão branco/ziguezague sonoro sem letras, `trick_talk_2.png` → `trick_talk.png` |
| Rola 1 | `a0bcfb30-b179-4e7f-b157-39f062b2ca96` | `3df45de3-6cc0-5066-8220-36df2f46062a` | Escolhido: seta circular/pata → `trick_roll.png` |
| Pula 1 | `206b36bf-580a-4a20-97ac-8c097d0715f6` | `63d1af06-6d8e-576f-b1bf-f5571caea62e` | Escolhido: pata/linhas ascendentes → `trick_jump.png` |
| Gira 1 | `44a551d5-507e-42bb-af9f-c4b584b47fdf` | `55022655-d6af-587d-97cf-5d8a095fbf33` | Escolhido: espiral/pata → `trick_spin.png` |

Reutilizados integralmente `give_paw`, `bark`, `roll_over`, `happy_jump`, `chase_tail` do Tiro grande, respectivas variantes de roupa e os cones do fundo da Praça. Capturas reais do treino e das cinco animações com head/neck/body em `build/screenshots/etapa10/`; pata/latido vestidos, acrobacias sem roupa, retorno vestido. O treino usa os ícones de estrela existentes para acertos, sem glifos ambíguos.

## Etapa 11 — Tesouro (PixelLab, 14/10/2026)
Originais e candidatos em `build/art_sources/etapa11/` (fora do git). Recortes com `Invoke-TrimSprite`.

| Asset | Job / id PixelLab | Escolha | Destino |
|---|---|---|---|
| Baú fechado (objeto 48×40, sem estilo: `style_image` de 512×384 foi recusada — "deve caber no canvas") | objeto `da22b8fd-a9bd-4065-8047-5ddb1934dd15`, job `fcd032e3-0b69-4f27-b1a5-920a3d79305b` | único candidato; recorte 19×18 | `areas/nature/treasure_closed.png` |
| Baú aberto (`create_object_state`, "lid open, golden glow and gold coins") | objeto `5f84c88f-4125-4b66-bc40-22f49dc4d920`, job `37959260-a555-445a-a76b-0a005815a109` | único candidato; recorte 19×21 | `areas/nature/treasure_open.png` |
| Planta madura do mirtilo (56×48, referência `crop_carrot.png`) | `create_image_pro` job `634919dd-986d-4824-a15a-ada21aa0b27e` (16 candidatos) | candidato **0** (monte de terra, bagas azuis visíveis); recorte 30×35 (morango: 35×33) | `areas/farm/crop_blueberry.png` |
| Ícone do mirtilo 32×32 | `create_image_pixen` job `203a9418-b9e2-41db-92ee-18457bb337da`, 1ª tentativa | aprovado, sem recorte | `ui/icons/item_blueberry.png` |
| Clareira (112×64, referência `nature.png`) | `create_image_pro` job `7ccd5399-2c87-4f7c-a0d7-7a7ba3a453a9` (4 candidatos) | **rejeitados os quatro**: vieram como ilhotas isométricas flutuantes com borda de terra, que ficariam como um bloco colado sobre a Natureza | — |

Decisão: o fundo da Natureza (512×384) não tem espaço livre bonito, e nenhum candidato de clareira cabia como objeto
decorativo. O baú fica na grama livre à esquerda da ponte, `pos [96, 222]`, `scale 1.6` (a arte tem só ~19 px, no
tamanho do Tiro a 0,5). A "Clareira escondida" é revelada pelo próprio baú + etiqueta quando a missão
`guide_treasure` é recebida. Chapéu de explorador continua sem overlay ("Em breve no Tiro"), como a bandana caramelo.

## Interface nova — Etapa 00 (PixelLab, 15/10/2026)
Ícones próprios das estações e do cadeado: `create_image_pixen` 32×32, `no_background`, contorno preto, detalhe médio
(receita "Ícone de estação" de `docs/plans/interface/01_REGRAS_E_ESTILO.md`; o Pixen não aceita imagem de referência).
Originais e candidatos em `build/art_sources/interface_etapa00/` (fora do git); pranchas em `build/preview/etapa00_*.png`.
Recorte com `Invoke-TrimSprite` e recentralização num canvas 32×32 (mesmo tamanho dos ícones antigos). Até 3 tentativas cada.

| Ícone (`ui/icons/`) | Job escolhido | Tentativa | Observação |
|---|---|---|---|
| `station_stove` | `55c14ef9-2494-4aaf-9bf6-7c0ec59afae2` | 3 | fogão de frente com panela e vapor; 1ª (`d83f6d43-…`, panela sobre chama) e 2ª (`172ba563-…`, caixa com panela) rejeitadas |
| `station_fridge` | `6852d69d-36a0-49b8-b618-3d4dbfe61747` | 1 | |
| `station_blender` | `e50c0836-d63c-40e7-9f60-5745c8fa339e` | 2 | 1ª (`fb890785-…`) parecia um troféu com carinha |
| `station_chest` | `a0a41f31-02a1-4c6e-9e51-de3a4eef0167` | 1 | |
| `station_workbench` | `be95bde4-5edd-4a69-a56f-4006a123c8a9` | 1 | |
| `station_silo` | `55b72272-a904-4103-a7ac-46b9edc7c7e2` | 2 | 1ª (`b1ecb7d5-…`) parecia hidrante |
| `station_warehouse` | `4d51f9ec-3690-4016-a274-7d4b3f0e7a51` | 1 | |
| `station_mill` | `be9f32bd-6640-4faa-a90d-ac63e4fb2cdc` | 1 | |
| `station_dairy` | `d4dac5c7-4905-48e4-9bfa-1da622992358` | 2 | 1ª (`344b3874-…`) saiu uma vaca em vez da casinha |
| `station_coop` | `3d9a293f-d226-47bd-a7c6-46b678075838` | 1 | |
| `station_barn` | `d3cd53b4-d69a-4213-91b8-cf40c6530449` | 1 | |
| `station_sewing` | `98950559-6f82-436f-b0e2-c1ff93be9682` | 1 | |
| `station_stall` | `86a636c4-79fc-4936-92c5-65786170f711` | 1 | |
| `ui_lock` | `fd381a7d-ac41-4b88-8379-f4464c7cfbce` | 1 | cadeado dourado (usado a partir da Etapa 01) |

Trocados em `progression.json → upgrades[*].icon` (23 construções) e `worlds.json → places[*].icon` (12 lugares).
Ficaram como estão: pomar (maçã), estufa (ervas), ferramentas, tokens de nível da Natureza e o lugar `farm.animals` (ovo,
agrupa galinheiro + curral). Não há personagem/objeto no PixelLab para estes ícones (imagens soltas, sem tags).

### Interface nova — Etapa 01 (ícones de interface)
`create_image_pixen` 32×32, `no_background`, sem imagem de referência (o Pixen não aceita). Originais em
`build/art_sources/interface_etapa01/` (fora do git). Já saíram em 32×32 certinhos, sem precisar de recorte.

| Ícone (`ui/icons/`) | Job escolhido | Tentativa | Observação |
|---|---|---|---|
| `ui_close` | `33b72b4c-d540-493e-9d39-644630237c51` (seed 11) | 1 | "✕" marrom escuro de pontas redondas, `lineless`; usado no botão de fechar do painel (`Sheet`). Alternativa (`94859070-…`, seed 22) saiu laranja |
| `ui_check` | `c7b645b5-acd7-4f32-9fa8-31b45d104f39` (seed 22) | 1 | visto verde com contorno escuro; ainda sem uso (balões de pronto da Etapa 06 e listas). Alternativa (`2074371a-…`, seed 11) mais verde-escura |

Imagens soltas no PixelLab (sem personagem/objeto, sem tags).

### Interface nova — Etapa 03 (retrato do Tiro para o HUD)
Sem PixelLab (nada de arte nova): `ui/icons/hud_tiro.png` (48×48) é um **recorte da cabeça** do quadro
`characters/tiro_pet/idle_breathe/frame_00.png` (caixa 98×98 em x=74, y=38 do canvas 256×216), reduzida para 44×44 por
vizinho mais próximo (`System.Drawing`, `InterpolationMode = NearestNeighbor`) e colocada em (2, 3) de um canvas 48×48
transparente. Serve de rosto no avatar do HUD (`Hud`, botão `HudAvatar`). Para refazer: repetir o recorte com outro quadro.

### Interface nova — Etapa 04 (fundos dos mundos, nuvens e ícone de centralizar)
Originais, tentativas e prancha em `build/art_sources/interface_etapa04/` (fora do git). Imagens soltas no PixelLab (sem tags).

**Faixa de horizonte** (`areas/<mundo>/backdrop.png`) — `create_image_pro`, 480×192, `no_background: true`, 1 referência de estilo
(o próprio mapa do mundo, enviada por `get_upload_url`). Cada uma saiu **na 1ª tentativa** (cenário de fundo com uma faixa de paisagem
e o céu transparente; o céu vem do degradê do código). Recortada com `Invoke-TrimSprite` e sem as últimas linhas (faixa de terra/contorno
que não combinava com o chão do código).

| Mundo | Job escolhido | Recorte final | Observação |
|---|---|---|---|
| farm | `a541261f-cea4-4801-9698-176a79d25748` | 480×41 | morros verdes, árvores e um celeiro ao longe (menos 3 linhas) |
| park | `d4553f1d-efc7-4951-b44c-92ef207b749b` | 480×33 | prédios azulados e ipês amarelos (menos 2 linhas) |
| village | `22d12f41-1abc-4e1b-8ec4-5728698595df` | 480×82 | telhados, igreja e árvores de outono (menos 14 linhas de terra) |
| nature | `55bd9181-16c0-421a-89c5-ab17b660ba03` | 480×130 | montanhas, névoa e pinheiros (menos 24 linhas escuras de baixo) |

**Nuvens** — `create_image_pixen`, `no_background`, `outline: lineless` (o Pixen desenha contorno azul mesmo assim). O Pixen só aceita lado
curto < 32 se for quadrado, então a nuvem 2 ficou 64×32 (não 64×24).
- `areas/common/cloud_1.png` (86×30 depois do recorte): job `c5dd5c9a-b06f-4da0-a799-df7b5f269bd6`, 1ª tentativa.
- `areas/common/cloud_2.png` (53×32): 3ª tentativa, job `dbcacc3f-8287-4c77-9f8c-d0e3f97cd1cf` (seed 21, `single color outline`).
  Rejeitadas: `aafbc72b-45c1-45b4-80c1-518d93c9ba4d` (pontas azuis soltas dos lados) e `5b7ff834-9a3e-4bd0-a2b4-69d235d3ea10` (nuvem cinza).

**Ícone de centralizar** `ui/icons/ui_recenter.png` (32×32) — `create_image_pixen`, 3 jobs em paralelo (mira laranja): escolhido o do seed 5,
job `a03f5c3c-64d6-4728-8e22-deb7f7d552cc` (mira com um olho no meio). Rejeitados: `37ee4046-fd40-4518-8c7b-5080bfc37f87` (explosão) e
`69a803ca-8146-4e66-a8ba-3b31bd44a5dc` (roda de leme).

**Mapas com fundo transparente** (sem PixelLab): os fundos `farm/farm_animals.png`, `house/room.png`, `park/park.png` e `village/banner.png`
traziam a cor de fundo escura (`#231d2c`/`#25192d`) gravada em volta da maquete; ela virou transparente (preenchimento a partir das bordas,
`Invoke-ClearCorner` em `tools/pixel_tools.ps1`, tolerância 4) para o céu e o chão do mundo aparecerem atrás. Os originais ficaram em
`build/art_sources/interface_etapa04/originais/`. `nature/nature.png` já era transparente.

**Polígono `edge_cover`** (terra da lateral do Sítio coberta com a cor do chão): `tools/edge_cover.ps1 <png>` extrai o contorno da borda da grama e do
fundo do bloco, mas a borda desenhada à mão é irregular; o do Sítio foi ajustado à mão (topo 5 px acima da borda da grama e fundo 12 px abaixo da terra) em `rooms/farm.json`.

**Canteiro da estufa** `areas/farm/plot_greenhouse.png` (76×52, Interface nova Etapa 07; pedido do Vitor: a estufa parecia estranha com os mesmos canteiros de madeira) —
`create_image_pixen` 76×52 sem fundo, 3 candidatos em paralelo (caixa de pedra clara com vidro, seeds 11/22/33). Escolhido o do seed 11, job
`59e9382c-ae24-4040-8b34-2f20c4e7680f` (pedra creme + parede de vidro). Rejeitados: `a5791443-4c60-4663-8e3b-00019449ccc9` (pedra escura, brotos
pintados) e `d67faaf5-774f-4152-b15c-501f6201fb2e` (virou uma mini estufa inteira, não cabe no losango). Os brotinhos verdes pintados na terra do
escolhido foram trocados por terra escura (script no PowerShell, 154 pixels) para o canteiro vazio parecer vazio. Originais e pranchas em
`build/art_sources/interface_etapa07/`. Usado só nos canteiros 9–12 (`rooms/farm.json`); o losango do chão (`footprint`) não mudou.

**Raios das comemorações** `ui/fx/rays.png` (128×128, Interface nova Etapa 12; gira atrás do ícone grande do `ModalCard`, 20°/s, alfa 0,6) —
`create_image_pixen` 128×128 sem fundo, "radial sun rays burst, soft golden, transparent background, pixel art, centered, symmetrical", 3 candidatos em paralelo:
seed 11 `lineless`/medium (`b6fc8c35-dc1e-4d26-a069-3da62542a97e`, **escolhido**: explosão limpa de raios finos), seed 22 `lineless`/low
(`b8213319-5771-4378-a67b-0cedd670c137`, raios tortos e sujos) e seed 33 `selective outline` (`436eb195-1f89-4599-a0e0-e881bc145f9a`, virou rosa dos ventos).
O escolhido veio em marrom-ouro escuro; foi **reentonado sem PixelLab** (PowerShell/System.Drawing: luminância → 4 degraus entre `E8A530` e `FFF1B0`, alfa preservado)
para virar o dourado suave da paleta. Originais, reentonado e prévia em `build/art_sources/interface_etapa12/`. Fica em `game/assets/sprites/ui/fx/` (não em `sprites/fx/`, que
é dos efeitos do mundo). O confete é desenhado por código (retângulos 4×6 em `CPUParticles2D`), sem arte.


### Economia R1 — etapa 17, ícones dos produtos (18/10/2026, Claude Code)

Pixen 32×32 transparente, contorno preto, detalhe médio, aprovados na primeira tentativa: Brinquedo trançado (`78face52-08cf-59e5-87be-fb28665e6806` → `ui/icons/item_braided_toy.png`), Cesta do encontro (`5a35c5a0-f1a7-5718-9b9e-eae7fb644fa6` → `item_picnic_pack.png`) e Petisco de mirtilo (`9f2b1a8b-ea40-564f-a513-ba79437f806a` → `item_blueberry_treat.png`). Originais em `build/art_sources/economia_etapa17/`; PNGs e `.import` versionados.


### Economia R1 — etapa 20, Banco da Praça (18/10/2026, Claude Code)

`create_image_pixen`, transparente, contorno preto, detalhe médio, isométrico sudeste, `low top-down`, aprovados na primeira tentativa. Imagens avulsas não aceitam tags; registro local `tiro-adventure`, `cenario`, `ativo`.

| Asset | Job / asset PixelLab | Destino |
|---|---|---|
| Banco com almofada vermelha e brinquedo (fase "conforto") | `7a05951a-183e-44bc-8b4c-4fa562d80fbd`; asset `88b2c4bc-1ad5-5cfa-97ed-07112fb34345`, seed 201, 48×40 | `areas/park/bench_comfort.png` |
| Banco de madeira sem acabamento sobre base de tijolos (fase "base" e marcação translúcida) | `4810963c-df3b-4e99-a275-c18593a0e2fc`; asset `7f76f21c-deb0-5bd9-868c-ad5b05fe1ee2`, seed 201, 48×40 | `areas/park/bench_base.png` |
| Banco completo com tigela de petiscos e bandeirinha (obra pronta) | `7c3aa638-5c22-40ee-8427-1aeb87b0a948`; asset `05e9619f-c790-51e0-98f8-7be4e2355a3e`, seed 201, 56×44 | `areas/park/bench_welcome.png` |
| Ícone da obra | `45974a5e-bddd-4513-a5c5-8fcc96769795`; asset `2cf57678-6c0d-5cc9-844f-df9208df928d`, seed 202, 32×32 | `ui/icons/project_bench.png` |

PNGs e `.import` versionados; posição, footprint e ponto de uso estão em `rooms/park.json` (`community_bench`).


### Economia R1 — etapa 21, Jardim da Vila e Piquenique da Praça (18/10/2026, Claude Code)

`create_image_pixen`, transparente, contorno preto, detalhe médio, `low top-down`, sudeste, aprovados na primeira tentativa (mesmo método do Banco). A marcação inicial de cada obra reutiliza o desenho da primeira fase a 50% de opacidade (como o banco).

| Asset | Job / asset PixelLab | Destino |
|---|---|---|
| Canteiros de madeira vazios, terra à mostra (fase "beds" e marcação) | `9bfe2994-1080-45fb-98f7-9eeb1550ad27`; asset `6a3ea7e4-d419-5950-8544-be8f6e6fcf35`, seed 301, 64×48 | `areas/village/garden_beds.png` |
| Canteiros com ervas e brotos (fase "planting") | `e64ee097-2bf5-4235-93df-a9452a3c7f08`; asset `1d76ea8f-019e-58ec-9da5-7d67f0d47b78`, seed 301, 64×48 | `areas/village/garden_planting.png` |
| Jardim com flores ornamentais, placa e bandeirinha (obra pronta) | `309cdfc7-5e3b-45fd-ae71-008d6193b9e8`; asset `dd592420-ddc0-5520-a85c-2aeb9db9199b`, seed 301, 64×48 | `areas/village/garden_opening.png` |
| Toalha xadrez vermelha estendida (fase "corner") | `7bd4c822-f2a9-4840-a888-61292fcc5948`; asset `f872eda0-13ad-5d57-ac9d-0b41c414ebdc`, seed 302, 56×40 | `areas/park/picnic_corner.png` |
| Toalha com cesta de vime e queijo (fase "basket") | `1100ce63-d5e6-4432-8ff7-522c14aab78a`; asset `96b3082b-9aa3-57d2-a5ed-9145f43e4c20`, seed 302, 56×40 | `areas/park/picnic_basket.png` |
| Toalha com cesta, tigela de petiscos, copos e bandeirinhas (obra pronta) | `f6a3db87-8ece-4bae-9070-420ad35ffe2e`; asset `b912d85b-dfd1-56ae-a7e2-adce2f596792`, seed 302, 56×40 | `areas/park/picnic_meeting.png` |
| Ícone do jardim | `b4ad2761-a77d-4b72-9ee1-9f6ba31b563e`; asset `ef3897fb-27ad-5fa0-9043-e34af1d79bd1`, seed 303, 32×32 | `ui/icons/project_garden.png` |
| Ícone do piquenique | `5141f41c-a4db-4ba1-b62f-5653e28bded8`; asset `b48979fa-519e-51b1-88a6-d31b7d7e53c9`, seed 304, 32×32 | `ui/icons/project_picnic.png` |

PNGs e `.import` versionados. Posições, footprints e pontos de uso em `rooms/village.json` (`community_garden`) e `rooms/park.json` (`community_picnic`, `scale` 0,8).

### Economia R1 — etapa 22, Festa da Vila e Lenço da nossa turma (18/10/2026, Claude Code)

`create_image_pixen`, transparente, contorno preto, detalhe médio, `low top-down`, sudeste, seed 401 nos três desenhos (mesmo método do Jardim/Piquenique), aprovados na primeira tentativa. A marcação inicial reutiliza o desenho da primeira fase a 50% de opacidade. Originais em `build/art_sources/economia_etapa22/`.

| Asset | Job / asset PixelLab | Destino |
|---|---|---|
| Palco de tábuas com varais de bandeirinhas (fase "decorate") | `25d261da-68b3-4d5e-b953-432a30a5f3e8`; asset `e59a2141-f09b-5103-9498-33663d6527b7`, 72×52 | `areas/village/festival_decorate.png` |
| Mesa comprida com cestas, queijos e copos (fase "table") | `c3f950ad-c8df-4f56-a9ab-81ac3982b093`; asset `d9249640-74e9-591c-8632-7cd755989512`, 72×52 | `areas/village/festival_table.png` |
| Festa pronta: mesa, presentes com fita, lanternas e balões (fase "gifts") | `5f62b50e-0d5f-43c4-bd10-b6eb236f1129`; asset `abf779f7-009b-5d11-911f-0f031d6d7c40`, 72×52 | `areas/village/festival_gifts.png` |
| Ícone da festa (bandeirinhas + presente) | `229f05cc-4ce7-4709-9625-7c16e5412770`; asset `a26d3ceb-2b94-5efc-8723-ca2cadaddc3e`, seed 405, 32×32 | `ui/icons/project_festival.png` |

**Lenço da nossa turma (`community_ribbon`, slot `neck`)**: combinado a partir de recursos do projeto, como a seção 07 E permite. `tools/ribbon_recolor.gd` (Godot headless) copia o lenço vermelho (`overlays/red_scarf.png` + as 52 camadas por quadro em `overlays/red_scarf/<pose>/`, poses `sad/eat/lick_paw/sleep/head_tilt`) trocando só o matiz (vermelho → verde-água, `HUE` 0,46) e o ícone `outfit_red_scarf.png` → `outfit_community_ribbon.png`. A máscara e as âncoras são as do lenço vermelho, então `overlay_anchors.json` não mudou (mesmas poses visíveis/ocultas, mesmos quadros variantes). Conferência: `festival_test` (todos os quadros existem) e capturas `20_tiro_com_lenco`/`21_tiro_dormindo_com_lenco` nas três resoluções em `build/screenshots/etapa22_depois/`. Posições, footprint e ponto de uso em `rooms/village.json` (`community_festival`).


### Tiro no centro — etapa 01, prova de identidade (19/10/2026, Claude Code) — APROVADA PELO VITOR (filhote = opção 1, jovem = opção 10, Mocinho do preto do jovem ao atual)
Regra de ouro (seção E do `docs/plans/tiro/06_INTERFACE_E_ARTE.md`): o adulto é o Tiro atual e não é redesenhado; `puppy` e
`young` são o mesmo cachorro mais novo. Pranchas em `build/art/tiro_fases/` (`prancha_corpos.png`, `prancha_metodos.png`,
`prancha_pelagem.png`), feitas por `game/tests/growth_art_shots.gd` (não é teste): `--step=prep` (headless) monta paleta,
candidatos exatos, alinhamento e finais; `--step=boards` (sem `--headless`) desenha com os shaders; `--step=install` copia os
aprovados de `build/art/tiro_fases/final/` para as pastas definitivas (só depois da aprovação).

**Paleta** (81 cores, todas das quatro imagens atuais: `tiro_pet/idle_breathe/frame_00.png`, `tiro_pet_idle_front.png`,
`tiro_world/rotations/south.png`, `hud_tiro.png`; da mais escura à mais clara; `paleta.png`, `paleta_strip.png` 81×1 para o
`reduce_colors`): #010001 #010005 #000102 #030101 #00010a #02010d #000113 #07010a #060207 #05030f #0a0505 #0e0608 #060a15
#131620 #28150f #191921 #261719 #1e212c #272831 #372627 #392d32 #4c2b16 #34363e #4f302a #633011 #3c373f #5b3329 #403f44
#3e4048 #523e32 #573d32 #613c2c #6c3c1d #474a52 #7b411b #544943 #764531 #505152 #7d4a27 #894a1f #7d4f35 #75553c #85522f
#625c56 #8e542b #5e5f60 #ac4c5d #9a5728 #895c3f #676562 #956039 #7d6652 #a3602b #6b7079 #75716b #a06b41 #b2682b #75787f
#94735a #9d734e #b87133 #ad7647 #e56371 #c37835 #cf7061 #bd7c4a #8f8a81 #b7855d #c2844e #b6895c #cb8642 #9e9183 #c7915d
#d88f43 #d3955b #c2a074 #e39c4c #ebaa58 #d7b386 #f9feff #fdfffc. Os "pretos" do jovem/filhote são as 19 cores com brilho < 0,2
desta mesma lista (nada de cor nova).

**Métodos comparados no quadro base** (`idle_breathe` 0, 256×216; uploads do quadro atual como entrada):
| # | Método | Ferramenta / semente | Prompt (resumo) | Resultado |
|---|---|---|---|---|
| 1 | a, filhote | `edit_image` texto, seed 101 | prompt base da seção E.2 (floppy ears, rounder head, black coat, thicker paws…) | muito filhote, mas olhos/língua redesenhados |
| 2 | b, filhote | exato (script): sela cinza → pretos da paleta + reduzir 0,86 pelos pés | — | reduzir por vizinho mais próximo estraga o traço; orelhas continuam em pé |
| 3 | c, filhote | `inpaint_image` caixa (64,28) 118×40, seed 301 | "soft floppy puppy ears folded down…" | orelhas caídas, rosto intacto |
| 4 | c, filhote | `inpaint_image` sobre o #3, caixa (70,110) 116×78, seed 303 | "small chubby yorkshire terrier puppy body… solid black back… short thick legs" | corpo fofo e preto, rosto intacto |
| 5 | **c + b, filhote (escolhido)** | #4 + sela cinza da cabeça → pretos da paleta (exato) + `reduce_colors` (paleta) | — | olhos, nariz, língua e máscara pixel a pixel iguais ao adulto |
| 6 | a, jovem | `edit_image` texto, seed 201 | "young adolescent dog… ears standing up… saddle black" | quase igual ao adulto |
| 7 | a, jovem | `edit_image` texto, seed 202 | "lanky teenage dog… scruffy messy… solid black" | bom jovem, mas o rosto muda e os pés descem 14 px |
| 8 | b, jovem | exato: sela cinza → pretos da paleta | — | identidade perfeita, mas é só o adulto pintado |
| 9 | c, jovem | `inpaint_image` caixa (70,110) 116×78, seed 302 | "slimmer young… solid black back… messy fur tufts, thinner legs" | corpo magro e bagunçado, rosto intacto |
| 10 | **c + b, jovem (escolhido)** | #9 + sela cinza → pretos (exato) + `reduce_colors` | — | idem #5 |

**Método escolhido: c + b** (inpaint só no corpo/orelhas, sela pela troca exata para os pretos da paleta, `reduce_colors` com
`paleta_strip.png`, pés alinhados ao adulto pelo script). Motivo: é o único que mantém olhos, nariz, língua, máscara e contorno
idênticos ao Tiro atual. **Escolha do Vitor (19/10/2026): filhote = #1** (o mais "bebê"; sai do PixelLab com 9 cores, reduzido localmente à paleta pelo
`_quantize` do script); **jovem = #10** (c + b).

**Outros tamanhos** (com o quadro escolhido como referência): `idle_front` 160 = `edit_image` modo referência sobre
`tiro_pet_idle_front.png` (seeds 411 filhote #1 / 402 jovem); mundo `south` 64 = `edit_image` referência sobre
`tiro_world/rotations/south.png` (seeds 511 / 502; 401/501 foram do filhote #5, descartados); os quatro passaram por `reduce_colors` com a paleta e foram alinhados aos pés
(filhote 160: pés 147 → 156; mundo filhote: 55 → 59). Retrato 48 = mesmo recorte do adulto (caixa 98×98 em x=74, y=38 →
44×44 vizinho mais próximo em (2, 3)); o script confirma que essa receita refaz `hud_tiro.png` idêntico.

**Shaders (protótipos, sem uso no jogo):** `game/assets/shaders/tiro_coat.gdshader` (`coat` 0..1 + textura `darks` =
`tiro_coat_darks.png`, os 19 pretos da paleta; a sela do adulto — saturação ≤ 0,22 e brilho 0,22–0,66 — vira em 0 exatamente o
preto do jovem e azula até o original em 1; o dourado NÃO muda, a pedido do Vitor: escurecer o dourado deixava o Mocinho "torrado")
e `silhouette.gdshader` (`tint`, `alpha_cut`). Comparação em `build/art/tiro_fases/comparacao_coat.txt`:
**coat = 1 × frame_00.png: 0 pixels diferentes de 10090 (idêntico)**; coat = 0 × adulto com a sela do jovem: 0 diferentes.

**Checklist conferido nas pranchas:** olhos, nariz, língua rosa e máscara castanha iguais (tela 256); contorno escuro de 1 px;
mesma luz do adulto; mesmo tamanho de pixel; só cores da paleta; canvas 256×216 / 160×160 / 64×64 / 48×48; pés na mesma
linha do adulto (184 na tela, 156 no `idle_front`, 59 no mundo). Gasto PixelLab: ~100 gerações.
Destinos após aprovação: `characters/tiro_pet_<corpo>/idle_breathe/frame_00.png`, `characters/tiro_pet_<corpo>/tiro_pet_<corpo>_idle_front.png`,
`characters/tiro_world_<corpo>/rotations/south.png`, `ui/icons/hud_tiro_<corpo>.png`.


## Tiro no centro — etapa 03: ícones dos atributos (19/10/2026)

PixelLab `create_image_pixflux`, 32×32, transparência, `single color outline`, `basic shading`,
`low detail`. Quatro gerações. Arquivos em `game/assets/sprites/ui/icons/pillar_<id>.png`.
Prompt comum: `Single <objeto>, cozy virtual pet game UI need icon, readable chunky pixel art,
dark brown outline, pastel colors, centered, no text`.

| id | objeto | seed | job PixelLab |
|---|---|---|---|
| body | ivory dog bone | 303 | b7e9fcd4-b5b5-4dbc-bc72-6022ff361e14 |
| coat | teal grooming comb with a tiny golden sparkle | 304 | fe44c871-cb72-4931-97a6-758ed6deae4e |
| smart | warm yellow light bulb | 305 | 6ba97a1e-20a7-43e3-bff7-487a232334d4 |
| brave | golden five pointed star | 306 | ef508f80-5b26-432f-9c01-dad965c3c594 |

PNG dos quatro ícones conferidos na captura 360×780 do caderninho:
`build/screenshots/tiro03_antes/notebook.png` e `tiro03_depois/notebook.png` (abertas).
Coragem usa estrela; coração continua reservado ao vínculo. Nenhuma arte do Tiro alterada.

Captura adicional conferida: `build/screenshots/tiro03_depois/gain.png`, ganho Radiante +3 Corpo acima da cabeça, sem cobrir a fala; número e ícone usam a mesma curva/tempo.


### Tiro no centro — etapa 04, produção dos corpos (19/10/2026, Codex) — CONCLUÍDA

As bases da etapa 01 foram mantidas pixel a pixel: filhote #1 e jovem #10, incluindo frontais 160×160,
retratos 48×48 e `rotations/south` 64×64. Adulto existente preservado por hash. Entrega: jovem 215 quadros
(22 clipes + `sleep_belly`), filhote 206 (21 + `sleep_belly`, sem `give_paw`), mundo 99 por corpo e
`sleep_belly` adulto 1: **620 quadros, dos quais 616 novos**. Pastas definitivas `tiro_pet_young/puppy`,
`tiro_world_young/puppy`; **ainda não usadas pelo jogo**.

Receita reproduzível em `tools/tiro_body_art.py`: `prepare` extrai recortes dos quadros adultos sem
redimensionar, guarda a posição de volta no canvas e faz folhas até 512 px; `install` extrai as células,
troca a sela do jovem pelos mesmos 19 pretos da 01, reduz por distância RGB à paleta, limpa pequenos
fragmentos e alinha o apoio ao quadro adulto correspondente. `repair_tongues` restaura a língua rosa do
latido do filhote e carinho na pata do jovem por ilha de cor isolada (e um polígono manual no quadro 06). `reprocess` reaplica a receita
aos brutos; executar `repair_tongues` depois dele. `audit`, `boards` e `gifs` conferem/montam as evidências.
Nada foi escalado nos arquivos finais: tela 256×216, mundo com o canvas de cada original (rotações 64, clipes 76/80/96); só as prévias recortam/ampliam para leitura.

**Paleta:** 81 cores da 01 + cores já presentes nos demais clipes adultos, total **241**. A ampliação foi
necessária para manter a tigela azul, a mão e os adereços existentes. Paleta final em
`build/art/tiro_fases/producao04/paleta_clipes.json|png`; nenhuma cor externa aos originais foi acrescentada.

**Geração:** `edit_image` em modo referência, seed **4401 jovem / 4501 filhote**, sem fundo. Entradas em
`producao04/inputs/`; referência é `final/young_pet.png` ou `puppy_pet.png`, e `*_world.png` no mundo.
Template usado (campos substituídos pelo manifesto):

> Sprite sheet: {N} frames in {C} columns, reading order. Change EVERY dog to exactly the {body} reference
> of the SAME Yorkshire terrier: [young: upright ears, scruffy lanky narrow body, thin legs, BLACK saddle;
> puppy: floppy ears, large round head, short chubby puppy body, black coat with tan face/chest/paws].
> Keep EVERY original pose/action ({clip}), orientation, eye expression, nose, pink tongue, 1-pixel dark
> outline, light direction and pixel density. Preserve grid cell positions/count/spacing EXACT. Transparent,
> no clothing, no new frames. Lying/jumping/back-facing poses must remain as input, not turn into sitting.
> Same dog, younger.

As duas primeiras provas `transfer_outfit` de 3 quadros foram guardadas em `samples/` e **não instaladas**
(jovem `852373f5-6ca9-4925-9db2-79df2509da23`, filhote `021fa6cb-759f-464f-a568-afcd32e97b98`, seeds
4101/4201). Folhas de respiração finais: jovem `aa0d0cc5-91a3-4fe0-919a-055faff254e7`, filhote
`f566f533-2bfd-46be-b6e5-e6f4951d208b`. Todos os IDs de clipes, substituições e resultado bruto em
`producao04/jobs.json` e `raw/`; metadados exatos dos recortes/células em `manifest.json`. Seis folhas do
mundo jovem e dois lotes de um quadro foram refeitos para eliminar espaço vazio que gerava recorte/desvio
na última pose. As folhas finais do mundo de nove quadros são 3×3; um único quadro não tem célula vazia.

**Sono de barriga:** adulto veio de `belly_rub/frame_00`, `inpaint_image`, seed **4601**, máscara
`(47,94,69,55)`, descrição "The exact same Yorkshire terrier lying on his back, now sleeping peacefully.
Eyes gently closed, mouth closed relaxed (no open pink tongue), same tan muzzle and nose. Keep the head
orientation and ears, black 1-pixel outline, existing pixel style and palette. Transparent outside the dog.
Do not change the rest of the body." Job `d011ceaa-4063-4c45-bb02-ae214c2e9cb4`. Jovem e filhote por
`edit_image` com esse resultado + base aprovada, seeds **4611/4621**, mantendo pose deitada/olhos e boca
fechados: `3f7cd1e2-c7c9-4218-a1a2-dabf634c201f` / `84dada6b-9a8b-44d4-9b2e-c9604ead27f2`.

**Custo observado:** delta de saldo MCP de 2.100 gerações depois das duas provas iniciais de 25 cada:
aproximadamente **2.150 gerações** (incluindo provas, tentativas e reparos nativos) na produção completa, sem compra de créditos. Saldo final observado
381,30. Consultas/downloads e tratamento local não geram novas imagens pagas.

**QA:** `art_audit.log` PASS, zero faltas/canvas/paleta/apoio, bases aprovadas iguais e adulto existente
igual por SHA-256. Pranchas comparativas de cada clipe em `clipes/`, `prancha_geral.png` (35 grupos) e
GIFs de `idle_breathe` 6 FPS, `eat` 8, `sleep` 5, `happy_jump` 9, `walk/east` 8 em `gifs/`. Pranchas abertas
para revisão técnica. Aprovação final e continuação autorizadas pelo Vitor em 19/10/2026: “Pode aprovar no final e continuar”. `growth.json.bodies` descreve diretórios,
retratos, fallback do filhote e regiões da silhueta, sem trocar o visual em execução. Registros completos
dos testes/importação no README do plano e `build/test_logs/tiro04/`. Sem roupas/âncoras nesta etapa.


**Correção descoberta na revisão ampliada:** não são todos 64 px no mundo. Por corpo, os 99 PNGs são
8 rotações 64×64, 45 quadros 76×76 (`dig/eat/sit/sleep/sniff`), 38 quadros 80×80 (`bark`, `idle` e
`walk/east|south`) e 8 quadros 96×96 (`walk/north`). Finais mantêm cada dimensão original, sem escala.
As duas sequências laterais `idle/east` e `walk/east` tinham células invadidas/cortes; foram substituídas
por quadros completos 80×80 de `transfer_outfit`, referência `*_world.png`, seed 4701 jovem / 4801 filhote,
instruindo preservar todas as poses east, movimento e o cachorro inteiro dentro do canvas, sem roupa/fundo.
Jobs: jovem idle `4e8b51e0-f00e-48f0-b594-1508a14f9ea3`, walk `5f61ae5d-1cab-42c8-9117-a30e5f05f620`;
filhote idle `d55a5724-152c-4af8-bc91-30b0ef557885`, walk `4197ac67-5b58-4bee-a9ef-bfac89e32949`.
`producao04/native_jobs.json` e `native/<corpo>/<clipe>/frame_NN.png` guardam as fontes; `native_install`
quantiza/alinha e instala sem recortar. `reprocess` já os aplica por último. A primeira tentativa com
output 64 foi recusada pelo PixelLab porque a entrada era 80 (sem imagem produzida); não foram encolhidos
quadros para contornar isso. A auditoria ganhou a verificação das bordas para não aceitar novamente
uma folha quantitativamente completa com um cachorro cortado.

## Tiro no centro — etapa 05: corpos integrados (19/10/2026)

Sem geração/alteração de PNG nesta etapa. `growth.json.bodies` agora alimenta `GameState.dog_look()` e
as aparições do Tiro no jogo. Shader da 01 integrado pelo helper `DogLook`, com material independente
por desenho e modulate/alfa preservados; Mocinho 0,3–0,7 conforme média dos pilares/teto, adulto 1.

Roupas: `tiro_pet/overlay_anchors.json → bodies.young` por clipe e slot. Cabeça/pescoço: escala 1 e
(0,0); corpo: 0,94 e (6,8) no canvas 256×216. Reutiliza PNGs/variantes por quadro existentes. As 19
roupas foram compostas e abertas em idle_breathe/eat/sleep/head_tilt/sad, com quadros de meio/fim:
`build/art/tiro_fases/roupas05_poses_1.png`…`4.png`; script `build/tiro05_clothes.py`. Sem cortes visíveis
nas poses conferidas; filhote oculta as roupas, mantendo o equipamento e aviso no caderninho.

Capturas 360×780 abertas em `build/screenshots/tiro05_visual/` (t12/t13/t14, adulto e Sítio nos dois
corpos); `adult_before_after.png` ao lado de `tiro00_antes/a01_pet.png`. Teste GPU com mesma textura,
pose, tamanho e fundo: coat=1 versus sem shader = **0 pixels diferentes**, `adult_comparison.txt` e
os dois recortes. Adulto e bases da 01 intactos; nenhum canvas de mundo foi modificado.
Teste visual + 17 afetados PASS; logs em `build/test_logs/tiro05/`. Próxima: tela de crescimento (06).


## Tiro no centro — etapa 06: silhueta na interface (19/10/2026)

`silhouette.gdshader` usa apenas alfa do idle_breathe/frame_00 do corpo seguinte. Partes vêm dos
retângulos de `growth.json.bodies.<body>.parts`: contorno, orelhas, rabo/pernas, brilho; tudo pronto
intensifica o brilho. Palette.INK e contorno claro, amostragem por fwidth para manter a linha legível
na redução, sem exibir RGB da textura futura. Menos animação mantém o brilho fixo. Futuras da caderneta
usam sempre o mesmo shader. Nenhum PNG novo/editado; canvases originais 256×216 e 64/76/80/96 preservados.
Capturas conferidas nas três resoluções em `build/screenshots/tiro06_*`.

## Tiro no centro — etapa 09 (19/10/2026): oito ícones

PixelLab create_image_pixflux; 32×32, transparente, single color outline, basic shading, low detail.
Prompt exato: "Cute cozy farm game inventory icon, {objeto}, centered single object, warm pastel palette, crisp pixel art, no text, no shadow outside object".
Destino de cada um: game/assets/sprites/ui/icons/item_{id}.png. Sem pós-processamento. Prancha aberta: build/art/tiro09/icons.png; capturas abertas 360×780 em build/screenshots/tiro09_depois/.

| id | objeto do prompt | seed | job | asset |
|---|---|---|---|---|
| frozen_carrot | frosty orange carrot slices with tiny ice crystals | 9090 | 2f44defd-6046-4926-a38b-02901031da0b | a2142fa5-bc55-5c9c-8538-7500c5e27b1f |
| puppy_mash | small terracotta bowl of orange carrot and potato mash | 9091 | a6795a55-cf8c-432a-8f38-857f8f5269d7 | 76c01e9a-9c40-5c9d-a127-fae7dcc99187 |
| corn_crunch | two golden crunchy corn biscuits | 9092 | 33e3d162-ad80-4be2-a6fb-12a1f63579b9 | ab06051b-b24b-59f5-8f3c-f73b11cdd1e5 |
| growth_kibble | small green bowl of brown kibble with egg and carrot pieces | 9093 | 942e0e5b-9bf8-4781-b7a9-69920ec8fdc3 | fb0283ce-9a07-56ff-be50-f5f189c04c04 |
| egg_scramble | small cream plate of yellow scrambled eggs | 9094 | 035d05c9-68a9-445d-a28f-9be0da937b5b | 8d396f41-cd53-5cbb-92a2-c408ebca8716 |
| cheese_bites | three small golden cheese bite biscuits | 9095 | bb52176e-95e9-4d69-a6f0-9728ddf622ea | 5d41fa2f-3651-50c6-be9c-5584f2f2ebb3 |
| milk_porridge | small blue bowl of creamy milk porridge | 9096 | dbdd1a9c-02b1-4a07-9b0b-c2a823766781 | c67cec5a-9c79-51c3-93e7-38a0907882d6 |
| herb_shampoo | small green shampoo bottle with a leaf emblem | 9097 | bac6e4c0-bd08-41a4-b601-a6acd62c8c61 | bafcdd58-e1a6-5f64-beba-4b74f006fd7a |


## Tiro no centro — etapa 10 (19/10/2026): ícones dos itens-chave e Lacinho do topete

**Ícones:** PixelLab create_image_pixflux, 32×32, transparente, single color outline, basic shading, low detail. Prompt: "Cute cozy farm game inventory icon, {objeto}, centered single object, warm pastel palette, crisp pixel art, no text, no shadow outside object". Destino `game/assets/sprites/ui/icons/item_{id}.png`, sem pós-processamento.

| id | objeto do prompt | seed | job |
|---|---|---|---|
| chew_ring | soft knotted blue fabric teething ring for a puppy | 10100 | 44b9063d-d5b9-4a33-bbf5-0bf1127554d2 |
| stick_chew | sanded wooden twig chew stick with a tiny rope bow | 10101 | ef9a70e6-0006-40c5-980b-167df4e48559 |
| soft_brush | soft pet grooming brush with wooden handle and soft pink bristles | 10102 | ea48dfcc-5e83-4e9c-834d-4d0a22f52f36 |
| courage_medal | round golden courage medal with a small star and a red ribbon | 10103 | 53714661-8343-4038-b447-3b3169d4f7d7 |

**Lacinho do topete (`topknot_bow`):** derivado do `yellow_bow` por `tools/bow_recolor.gd` (mesma máscara, mesmo recorte por pose e mesmas âncoras; só gira o matiz de amarelo para vermelho, −0,15). Gera `overlays/topknot_bow.png`, `overlays/topknot_bow/<clip>/frame_NN.png` (cinco poses com variantes por quadro) e o ícone `outfit_topknot_bow.png` (55 imagens). Não houve edição manual nem PixelLab. Slot `head`; o jovem usa as âncoras `bodies.young.<clip>.head` já existentes (o lacinho amarelo ocupa o mesmo lugar, no alto da cabeça, entre as orelhas) e o adulto o deslocamento 0. Prancha 2×2 (adulto/jovem × amarelo/vermelho × idle, eat, sleep, head_tilt, sad), aberta e conferida: `build/art/tiro10/lacinho.png` (`tools/bow_board.gd`). Nenhum PNG do Tiro, canvas ou apoio alterado.

## Tiro no centro — etapa 12 (19/10/2026): ícone `action_brush`

`game/assets/sprites/ui/icons/action_brush.png` (32×32, PixelLab `create_image_pixflux`, seed 77, `no_background`, contorno preto, sombreado básico). Prompt: "pet grooming brush seen from the side, round wooden head full of soft pink bristles and short wooden handle". Usado no `BrushTile`, no gesto e como ícone do item `basic_brush`. Nenhum PNG do Tiro foi alterado.

## Tiro no centro — etapa 13 (19/10/2026): arte do álbum

Gerada por `tools/album_art.gd` (`godot --headless --path game -s ../tools/album_art.gd`, depois `--import`): grades de caracteres 16×16 ampliadas 2× (pixel art, sem suavização; sem PixelLab, nada do Tiro). `ui/album/polaroid.png` (9-patch 24×24, margem 8), adereços `ui/album/prop_box|bowl|stall_sign|medal.png`, `ui/icons/item_milk_tooth.png` e ícones de seção `ui/icons/album_story|firsts|tricks|sleep|friends|dates.png` (32 px). Os demais adereços (`foam`, `carrot_mouth`, `sock`, `drops`, `ball`, `moon`, `fireflies`, `mud`, `party_hat`, `cake`, sombra, linhas de velocidade) ficam para a 15. Nenhum PNG do Tiro foi gerado ou alterado: a foto reutiliza os quadros de `tiro_pet*` pelo corpo/coat gravado. Shader novo `assets/shaders/flat_silhouette.gdshader` (cor única, só o alfa da imagem). Cenários das fotos = recortes de `areas/*` (`album.json → scenes`).

## Tiro no centro — etapa 14 (19/10/2026): primeira tentativa, histórica

A sessão interrompida do Claude deixou `tools/house_art.gd` e 14 PNGs em `areas/house/`: arrival_box (28×20), height_chart (14×66), memory_shelf (60×45), photo_wall (62×57), laundry_basket (20×20), toy_basket (24×20), named_bowl, bed_soft, bed_luxe, paw_rug (30×13), old_camera (12×10), gold_frame (20×26), star_garland (100×51), big_portrait (40×55). São pixel art procedural; caminhas/tigela derivam dos móveis existentes e retrato usa o Tiro adulto existente. Paredes inclinadas por SLOPE=0,37; desenhos dinâmicos em HouseDecor usam a mesma transformação. Nenhum PNG do Tiro foi modificado nesta retomada.

**Situação na primeira tentativa (resolvida abaixo): não atendiam ao requisito de produção PixelLab da etapa 14.** Tentadas cinco gerações `create_image_pixflux` (32×32, transparência, contorno de uma cor, sombra básica, low top-down): caixinha com coberta, cesto de roupa com meia, cesto de brinquedos com bola/corda, câmera antiga e tapete com patinha. Prefixo: "Single [objeto]. Cozy isometric home furniture game sprite, crisp pixel art, warm muted beige and walnut brown palette, dark brown single pixel outlines, basic shading, three quarter view, isolated. No text." Todas falharam no transporte HTTP para api.pixellab.ai/mcp; nenhuma imagem/job utilizável retornou. Manter estes sprites como provisórios e retomar a produção com referências dos móveis existentes quando o serviço voltar. Não marcar etapa concluída por causa desta pendência.

## Tiro no centro — etapa 14: PixelLab concluído após nova tentativa (19/10/2026)

Pedido do Vitor: "Tenta de novo o pixellab". Serviço voltou: 13 gerações `create_image_pixflux` concluídas e baixadas, fontes preservadas em `tools/art/house_pixellab/`. `manifest.json` registra cada prompt completo, tamanho, job_id, asset_id e SHA-256; referência de paleta = `areas/house/dog_bed.png` (forced_palette nas doze gerações após o primeiro cesto).

Fontes: arrival_box/laundry_basket/toy_basket/paw_rug/old_camera/gold_frame/named_bowl 32×32; height_chart 32×64; memory_shelf/photo_wall 64×32; star_garland 96×32; bed_soft/bed_luxe 64×64. Descrições pedem móveis de casa aconchegante em pixel art, contorno marrom, sombras básicas, transparência; objetos de parede em vista frontal e os de chão em três quartos. A caminha original continua sendo a terceira arte (básica), sem alteração.

`tools/house_art.gd` agora **prepara essas fontes** (não redesenha os objetos): recorte de alfa, escala nearest nos canvases já usados, inclinação SLOPE=0,37 para a parede, prateleira posicionada na base para receber as lembranças em código. A régua exclui a faixa de piso isolada nas últimas oito linhas da geração. Caminhas recebem variações rosa/lilás; moldura/estrelas, matiz dourada. `big_portrait` = moldura PixelLab + hud_tiro adulto existente. `gold_frame_front.png` mantém a vista frontal para o NinePatch do cantinho.

Saída: 14 objetos existentes + uma moldura frontal, `.import` gerados. Prancha de fontes `build/art/tiro14/pixellab_sources.png`, capturas finais 360×780 e comparativo em `build/screenshots/tiro14/`, todos revisados. 2.019 PNGs do Tiro verificados por SHA-256: zero alterados. Sem nova geração de cachorro, troca de canvas ou posição dos pés.

## Tiro no centro — etapa 15: adereços do álbum

Fontes PixelLab e manifesto de prompts/jobs/hashes: `tools/art/album_secrets_pixellab/`. Preparo reproduzível: `tools/album_secrets_art.py` (Pillow; recorte alfa, nearest, centralização). Saídas em `game/assets/sprites/ui/album/`: espuma, cenoura, meia, gotas, bola, lua, vaga-lumes, lama, chapéu de festa, bolo e chapéu de explorador; ícone do explorador em UI/icons. A primeira lama trouxe um animal e foi rejeitada, preservada como `mud_rejected.png`. Sombra e linhas de velocidade são formas desenhadas pelo preparo.

O chapéu de explorador usa overlay separado de 256×216 em UI/album, sem alterar os corpos nem overlays anteriores. As fotos reutilizam as âncoras/quadros das roupas existentes e guardam a roupa do momento. Bolo e chapéu de festa aparecem durante a janela anual. Prancha e capturas 360×780: `build/test_logs/tiro15/props_board.png`, `build/screenshots/tiro15/`. Nenhum PNG do Tiro anterior foi redesenhado.

Pose adicional da Pipoca: referência `dog_pipoca/rotations/east.png`, PixelLab img2img com força 60, fonte `pipoca_curled.png`; a tentativa de força 220 manteve a pose em pé e foi rejeitada. Preparo mantém 64×64 e alinha à linha dos pés original, saída `ui/album/pipoca_sleep.png`. Usada na visita e em Encostadinhos. Total desta etapa: 14 gerações, 12 fontes aceitas e duas rejeitadas documentadas. Nenhuma imagem dos corpos do Tiro foi alterada. As fotos de sono reutilizam o último quadro do clipe sleep e a arte existente do sofá/caminha como fundo.

## Tiro no centro — resumo final (etapa 18, 19/10/2026)

Corpos do Tiro por fase: filhote (opção 1) e jovem (opção 10) aprovados pelo Vitor, adulto intocado;
`tiro_coat` (pelagem dinâmica, `sheen` na seda) e `silhouette` em `game/assets/shaders/`; receita em
`tools/tiro_body_art.py`. Casa: `tools/art/house_pixellab/` + `tools/house_art.gd`; álbum:
`tools/album_art.gd` e `tools/album_secrets_art.py`. A etapa 18 não gerou nem alterou PNG.
