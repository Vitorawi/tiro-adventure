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
| ↳ animações (só south, `animate_character` mode pixminimax, 1 geração cada) | idle_breathe, head_tilt, scratch, yawn, sniff, stretch, bark, eat, happy_jump, shake_off (8 quadros +1), sleep (16 +1, deitando) | | tocadas por `scripts/ui/pet_animator.gd` | ativo |
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
- Tiro na Tela do Pet: quadros de 216px (`PetAnimator`), exibidos em ~320px. Sempre escala inteira (2x, 3x) para pixels nítidos.
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
