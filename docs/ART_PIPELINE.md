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
| Tiro mundo v2 | personagem `8e4e8b4d-142c-4d14-a012-29f16506a0a4` | pro, 64px, 8 dir | `characters/tiro_world/` | ativo |
| ↳ animações | walk (S/E/N, skeleton-v3), idle (S/E, skeleton-v3), bark (S), sit (E, v3), sleep (E, v3, deitando), eat (E, v3) | | `tiro_world/<ação>/<direção>/` | ativo |
| Tiro mundo v1 | personagem `cc74ce02-1c93-4dc7-8a72-a359265ad497` | standard, 32px, 4 dir | (substituído) | descartado: pouco detalhe |
| Tiro pet v2 (sentado, frente) | imagem pro, job `ee0ec478-c066-4b6c-ade9-fc8608809abe` (candidato 0 de 4), refs: pose da referência + rotação sul do Tiro mundo v2 | 160px | `characters/tiro_pet/tiro_pet_idle_front.png` | ativo |
| Tiro pet v1 | imagem pixen | 128px | (substituído) | descartado |
| Sala vazia (casa) | imagem pro, job `161a0ff4-3f83-4944-ac04-41875e2e730b` + inpaint `5d257f6d-…` (remover cão) + fundo externo transparente | 624x416 | `areas/house/room.png` | ativo |
| Geladeira | objeto pro flash `c68d8da4-9352-43b5-bc4f-09d1be4151c9` (estilo: recorte da referência) | 47x103 (recortado) | `areas/house/fridge.png` | ativo |
| Fogão | objeto pro flash `6d20f34d-ef1b-42ff-8025-ca1c83db1e9a` | 62x67 | `areas/house/stove.png` | ativo |
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

## Padrões visuais
- Tiro no mundo: 64px (modo pro), exibido 1x (`SPRITE_SCALE` em `dog_world.gd`); o fundo
  provisório é exibido 2x. Um fundo novo do PixelLab deve casar com essa escala.
- Tiro na Tela do Pet: 160px, exibido 2x (320px). Sempre escala inteira (2x, 3x) para pixels nítidos.
- Prévia ampliada de assets: gerar pranchas em `build/preview/` (ignorado no git) antes de aprovar.
- Animações: preferir `skeleton-v3` (mantém a identidade do personagem); `v3` para ações customizadas.
- Ícones do PWA atuais são placeholders.
