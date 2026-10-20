# Etapa 01 — Prova de identidade do Tiro (portão do Vitor)

**Estado: concluída e aprovada pelo Vitor (19/10/2026).** Executar somente esta etapa. Pré-requisito: etapa 00 concluída.

## Objetivo

Antes de qualquer código de crescimento, provar que conseguimos desenhar o **mesmo Tiro** mais novo. O Vitor
vê uma prancha lado a lado e aprova (ou pede ajustes). Nada muda no jogo.

## Leitura obrigatória

[06](06_INTERFACE_E_ARTE.md) seção E inteira (regra de ouro, corpos, checklist, processo); `docs/ART_PIPELINE.md`;
`docs/plans/interface/01_REGRAS_E_ESTILO.md` (parte de arte); imagens atuais:
`characters/tiro_pet/idle_breathe/frame_00.png` (256×216), `tiro_pet/tiro_pet_idle_front.png` (160×160),
`tiro_world/rotations/south.png` (64×64), `ui/icons/hud_tiro.png` (48×48).

## Entrega e implementação

1. **Paleta:** extrair as cores das imagens atuais do Tiro (`pixelart_workbench describe` ou
   `tools/pixel_tools.ps1`) e salvar em `build/art/tiro_fases/paleta.png` + lista hex no ART_PIPELINE.
2. **Quadro base de cada corpo** (`puppy` e `young`, `idle_breathe` quadro 0, 256×216, fundo transparente, mesma
   linha dos pés): testar os 3 métodos da seção E.2 (edição com referência no PixelLab, edição exata com
   `pixelart_workbench` sobre o quadro atual, `inpaint` só nas orelhas/corpo). Até 3 tentativas por método.
   `reduce_colors` para a paleta. Escolher o melhor de cada corpo pelo checklist "o que NÃO pode mudar".
3. Com o método escolhido, fazer também: `south` 64×64 do mundo (cada corpo), retrato 48×48 (cada corpo) e
   `idle_front` 160×160 (cada corpo).
4. **Shader de pelagem (protótipo):** `game/assets/shaders/tiro_coat.gdshader` (parâmetro `coat` 0..1, só nas
   cores da sela/dourado do adulto). Renderizar o adulto em `coat` 0 / 0,5 / 1 (prévia do Mocinho). Em 1 tem que
   ficar idêntico ao original (comparar pixel a pixel no script de captura).
5. **Shader de silhueta (protótipo):** `game/assets/shaders/silhouette.gdshader`; renderizar a silhueta de cada corpo.
6. **Pranchas** com `game/tests/growth_art_shots.gd` (script de captura, não é teste) em `build/art/tiro_fases/`:
   - `prancha_corpos.png`: atual | jovem | filhote, nas três escalas (256, 64, 48) e `idle_front`;
   - `prancha_metodos.png`: os candidatos de cada método, numerados;
   - `prancha_pelagem.png`: adulto coat 0 / 0,5 / 1 e as silhuetas.
   Abrir os PNGs e conferir o checklist antes de mostrar.
7. Mostrar as pranchas ao Vitor (enviar os arquivos) e **esperar aprovação por escrito**. Ajustes pedidos entram
   aqui mesmo (até 3 rodadas; depois registrar o impasse).
8. Arquivos aprovados vão para as pastas definitivas (`characters/tiro_pet_puppy/idle_breathe/frame_00.png`,
   `characters/tiro_pet_young/idle_breathe/frame_00.png`, `tiro_world_puppy/rotations/south.png`, etc.) com
   `.import` gerado (`godot --headless --path game --import`). **Nenhum código usa esses arquivos ainda.**
9. Registrar no `docs/ART_PIPELINE.md`: método escolhido, prompts, sementes, ferramentas e o checklist.

## Teste da etapa

Nenhum teste de jogo (só arte e shaders sem uso). Conferir que o projeto abre sem erro:
`godot --headless --path game --quit-after 60`.

## Para passar para a próxima

- [x] Pranchas gravadas e abertas; checklist da seção E cumprido em cada imagem.
- [x] `coat = 1` idêntico ao Tiro atual (comparação registrada: 0 de 10090 pixels diferentes, `build/art/tiro_fases/comparacao_coat.txt`).
- [x] **Aprovação do Vitor registrada no README com data** (portão). Sem isso, a etapa fica "aguardando aprovação".

## Fora desta etapa

Animar clipes (é a etapa 04), ligar arte ao jogo, mudar o adulto.

## Evidência e passagem de bastão

Pranchas em `build/art/tiro_fases/`. README (registro + aprovação), ROADMAP, ART_PIPELINE. Sem push.
