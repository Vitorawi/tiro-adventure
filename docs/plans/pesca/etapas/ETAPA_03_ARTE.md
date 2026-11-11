# Etapa 03 — Arte da pesca no PixelLab (portão do Vitor)

> Tamanho: média/grande (geração + preparo). Depende de: 02. Próxima: 04. **Portão do Vitor no fim.**
> Resultado que o Vitor vê: pranchas com os 9 peixes, 3 varas, 3 iscas, 4 pratos, boia, respingo, bolha e baú,
> todos em **pixel art do PixelLab**; depois de aprovar, tudo isso aparece no jogo no lugar dos provisórios.

## 1. Ler antes

- `03_INTERFACE_E_ARTE.md` §6 (lista) e §4 (como cada peça aparece).
- `docs/ART_PIPELINE.md` (PixelLab, `tools/pixel_tools.ps1`, `Invoke-ClearCorner`, regras de ícone 32 px).
- `CLAUDE.md`: "Suavização da interface ilustrada" (as peças pixel desta etapa ficam **nearest**, sem mipmaps),
  "Bandeja de estação madeira ilustrada" e "Mochila madeira ilustrada" (como `tools/station_art.gd` e
  `tools/bag_art.gd` montam peças de madeira — molde do `tools/fishing_art.gd`).
- Exemplos de manifesto de arte PixelLab: `tools/art/house_pixellab/`, `tools/art/album_secrets_pixellab/`.

## 2. Direção de arte: tudo no PixelLab (decisão do Vitor, 11/11/2026)

**Toda arte nova da pesca é pixel art feita no MCP PixelLab** (ferramentas `mcp__pixellab__*`; consulte
`mcp__pixellab__search_help(tool="<nome>")` para opções e preços antes de gerar). **Nada de image_gen, Scenario
ou ilustração por enquanto.** As únicas peças que não são geradas são as de madeira da interface do minigame
(pista, barra, rede), que o `tools/fishing_art.gd` **monta a partir das peças de madeira que já existem**.

Regras para todas as peças:
- fundo transparente, contorno escuro de 1 px, paleta e luz iguais às do Sítio e dos ícones `ui/icons/*`
  (luz de cima à esquerda); use um ícone existente como referência de estilo quando a ferramenta aceitar;
- tamanho final exato da tabela; no jogo, sempre em **escala inteira** com filtro nearest (nunca suavizar,
  nunca esticar, sem mipmaps);
- de cada peça, gerar 2–4 opções e escolher na prancha; registrar tudo (ferramenta, prompt, opções, job id,
  escolhida, data) em `tools/art/pesca/manifest.json`;
- retoque pixel a pixel: `mcp__pixellab__pixelart_workbench` (grátis); cores: `reduce_colors`; fundo:
  `remove_background`; animação curta: `animate_object` ou `vfx_workbench`.

| Peça | Arquivo | Tamanho | Ferramenta PixelLab sugerida | Descrição para o prompt |
|---|---|---|---|---|
| Ícone de cada peixe (9) | `assets/sprites/ui/icons/item_fish_<id>.png` | 32×32 | `create_image_pixflux` (ou `create_image_pro` se precisar de mais detalhe) | peixe de lado olhando para a direita, cor real: lambari prateado com cauda amarela; cará com listras escuras; tilápia cinza-esverdeada com listras finas; carpa dourada; pacu prateado-escuro e redondo; tambaqui escuro em cima e claro embaixo; traíra marrom manchada; tucunaré amarelo-esverdeado com 3 faixas e um "olho" na cauda; pintado cinza com pintas pretas e bigodes |
| Peixe do minigame (9) | `assets/sprites/ui/fishing/fish_<id>.png` | 48×48 (tambaqui e pintado 64×48) | `create_image_pixflux` com o ícone 32 px escolhido como referência | o mesmo peixe, maior e mais detalhado, lateral; cauda livre (o código balança) |
| Iscas (3) | `ui/icons/item_bait_worm.png`, `item_bait_dough.png`, `item_bait_lure.png` | 32×32 | `create_image_pixflux` | minhoca rosada num potinho de terra; bolinha de massa amarela; isca artificial colorida com anzol |
| Varas — ícone (3) | `ui/icons/rod_bamboo.png`, `rod_reel.png`, `rod_angler.png` | 32×32 | `create_image_pixflux` | bambu claro com linha; vara com carretel prateado; vara escura com carretel dourado |
| Varas — painel (3) | `ui/fishing/rod_<id>.png` | 64×64 | idem, a mesma vara em diagonal | |
| Pratos (4) | `ui/icons/item_fish_mash.png`, `item_fish_stew.png`, `item_herb_fish.png`, `item_lambari_crunch.png` | 32×32 | `create_image_pixflux` com `item_puppy_mash.png` como referência | papinha clara numa tigelinha; ensopado com pedaços de peixe e cenoura; filé com folhinhas verdes; petiscos dourados de lambari |
| Boia | `sprites/fx/fishing_bobber.png` + `sprites/fx/fishing_bobber_sink/` (4 quadros) | 16×16 | `create_map_object` ou `create_image_pixflux`, depois `animate_object` | boia redonda vermelha e branca, vista de cima como o mapa do Sítio |
| Respingo | `sprites/fx/fishing_splash/` (5 quadros) | 32×32 | `animate_object` ou `vfx_workbench` | anel de água se abrindo com gotinhas |
| Bolha | `sprites/fx/fishing_bubble.png` | 12×12 | `pixelart_workbench` (desenho simples) | bolinha clara com brilho; o código anima subindo |
| Baú da lagoa | `ui/fishing/chest.png` | 48×48 | `create_image_pixflux` | baú de madeira pequeno, molhado, com uma alga |
| Ícone do lugar | `ui/icons/station_fishing.png` | 32×32 | `create_image_pixflux` com um `station_*.png` como referência | vara de bambu com boia, mesma família dos ícones de estação |
| Disco do seletor | `ui/home/map_status_fishing.png` | como os outros `map_status_*` | — | `tools/world_map_art.gd` põe o `station_fishing.png` dentro do disco de madeira existente |
| Pista, barra, rede | `ui/home/fishing_track.png`, `fishing_bar.png`, `fishing_meter.png`, `fishing_meter_fill.png` | NinePatch 3× | — (não é arte nova) | `tools/fishing_art.gd` monta com `station_board`/`item_frame` e preenchimento azul (água) / verde (barra e rede) chapado |

## 3. Passo a passo

1. Criar `tools/art/pesca/` com `manifest.json` (molde dos manifestos já existentes). Nada de arte sem registro.
2. Gerar primeiro os 9 ícones de peixe (definem o estilo). Depois os peixes do minigame usando o ícone
   escolhido como referência. Depois iscas, varas, pratos, boia, respingo, bolha, baú e ícone do lugar.
3. Baixar as opções para `tools/art/pesca/opcoes/<peça>/`; a escolhida vai para o caminho final em `assets/`.
4. `tools/fishing_art.gd` (script Godot `-s`, idempotente): monta só as peças de madeira (pista, barra, rede) e
   o disco do seletor. Depois `godot --headless --path game --import`. Os PNGs pixel ficam com o filtro padrão
   do projeto (nearest); **não** ligar mipmaps neles. As peças de madeira montadas seguem a regra da madeira
   (mipmaps ligados, como as `station_*`).
5. **Pranchas** em `build/art/pesca/` (a 4×, nearest): (a) os 9 ícones de peixe lado a lado e os 9 do minigame
   embaixo; (b) iscas, varas e pratos; (c) boia e respingo em sequência + GIF; (d) uma montagem do minigame com
   pista, barra, rede, um peixe e o baú; (e) a lagoa do Sítio com a boia e a bolha por cima, para ver se o pixel
   combina com o cenário.
6. **Portão**: mostrar as pranchas ao Vitor; refazer no PixelLab o que ele pedir. Só depois:
7. Trocar os provisórios: `items.json` (remover `icon_todo`), `fishing.json → rods.*.icon`,
   `worlds.json → farm.places.fishing.icon`, `FishingGame` (texturas), `FishingBobber`, `FishingBubbles`,
   disco do seletor. Os pratos das etapas 06–09 usam os ícones gerados aqui (a bandeja do fogão mostra o
   ícone pixel no tamanho original, como já faz com itens sem `food_*.png`).
8. `content_test`: deixar de aceitar `icon_todo`.

## 4. Não fazer

Arte nova do Tiro (ele usa `sit`/`bark`/`happy_jump` que já existem). Fotos/álbum de pesca. Mudar regra.
Arte fora do PixelLab (image_gen, Scenario, ilustração) — decisão do Vitor, por enquanto.

## 5. Testes e capturas

- `content_test` (ícones existem, sem `icon_todo`), `fishing_lake_test`, `ui_base_test` (ícone emprestado).
- Repetir `tests/fishing_shots.gd` nas três resoluções e comparar com a 02 (pasta `fishing_03`).
- Conferir todas as peças pixel em escala inteira e nearest; razão de aspecto igual à fonte (±1%).

## 6. Pronto quando

Vitor aprovou as pranchas; nenhum provisório; capturas abertas; manifesto completo. Registro no README do
plano e ROADMAP.

## 7. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 03 do plano "Pesca na lagoa da vovó" (arte, com portão do Vitor).
Leia CLAUDE.md, docs/ART_PIPELINE.md, docs/plans/pesca/README.md, 03_INTERFACE_E_ARTE.md e
docs/plans/pesca/etapas/ETAPA_03_ARTE.md. TODA arte nova no MCP PixelLab (pixel art, nearest,
escala inteira); nada de image_gen/Scenario/ilustração. Gere 2–4 opções por peça, monte as pranchas
em build/art/pesca/ e PARE para o Vitor escolher antes de instalar. Registre tudo em
tools/art/pesca/manifest.json. Não gere arte nova do Tiro. Sem commit/push/publicação. Não executar a 04.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
