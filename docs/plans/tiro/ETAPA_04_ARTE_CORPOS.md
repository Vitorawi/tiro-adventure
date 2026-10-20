# Etapa 04 — Arte dos corpos jovens (produção completa)

**Estado: concluída em 19/10/2026; aprovação final e continuação autorizadas pelo Vitor: “Pode aprovar no final e continuar”.** Executar somente esta etapa. Pré-requisito: etapa 03 concluída. Pode levar mais de uma
sessão: marque a lista abaixo conforme avança e registre no README onde parou.

## Objetivo

Todos os desenhos do Tiro filhote e jovem prontos, com o mesmo método aprovado na etapa 01, para que a etapa 05
só precise ligá-los. Nada muda no jogo.

## Leitura obrigatória

[06](06_INTERFACE_E_ARTE.md) E (inteira); registro da etapa 01 no README e no `docs/ART_PIPELINE.md` (método,
prompts, paleta); `scripts/ui/pet_animator.gd` (`FPS`, nomes de clipes, quadros por clipe);
`scenes/entities/dog_world/dog_world.gd` (pastas e animações do mundo); `overlay_anchors.json`.

## Entrega e implementação

Para cada corpo (`young`, depois `puppy`), **derivando quadro a quadro dos clipes do adulto** (mesmo movimento,
mesma quantidade de quadros, mesma linha dos pés):

- [x] Tela do Tiro, `young`: os 22 clipes + `sleep_belly` (1 quadro) em `characters/tiro_pet_young/<clipe>/frame_NN.png`.
- [x] Tela do Tiro, `puppy`: os 22 menos `give_paw` + `sleep_belly` em `characters/tiro_pet_puppy/`.
- [x] Mundo, `young` e `puppy` (canvases reais do adulto: rotações 64×64, clipes 76×76/80×80/96×96): `idle`, `walk` (east/north/south), `sit`, `sleep`, `sniff`, `dig`, `eat`,
      `bark` e as 8 `rotations`, na mesma estrutura de `tiro_world/`.
- [x] `idle_front` 160×160 de cada corpo (já pode existir da 01).
- [x] Retratos `hud_tiro_young.png` e `hud_tiro_puppy.png` (48×48; já podem existir da 01).
- [x] `sleep_belly` também para o adulto (1 quadro; único desenho novo do adulto, só para a foto do álbum,
      sem alterar nenhum clipe existente).
- [x] `growth.json → bodies`: `dir` de cada corpo, `clip_fallback` (`puppy: give_paw → wag_excited`), `parts`
      da silhueta (retângulos de orelhas/rabo/pernas) e `pet_feet` se diferir.

Controle de qualidade, para cada clipe: `reduce_colors` para a paleta; prancha de quadros
`build/art/tiro_fases/clipes/<corpo>_<clipe>.png` comparando com o adulto; abrir e conferir o checklist
"o que NÃO pode mudar". No fim, `prancha_geral.png` (um quadro de cada clipe dos três corpos lado a lado) e,
se der, GIFs curtos de `idle_breathe`, `eat`, `sleep`, `happy_jump` e `walk`.

**Portão rápido do Vitor:** mostrar `prancha_geral.png` (e os GIFs) e esperar aprovação por escrito.

## Teste da etapa

Nenhum teste de jogo. Um script de conferência (pode ser parte do `growth_art_shots.gd`) lista clipes e quadros
de cada corpo e acusa falta ou diferença de quantidade em relação ao adulto; registrar a saída.
`godot --headless --path game --import` e `--quit-after 60` sem erro.

## Para passar para a próxima

- [x] Lista acima completa; conferência sem faltas.
- [x] `prancha_geral`: aprovação final autorizada pelo Vitor em 19/10/2026 após a revisão concluída (registro no README).
- [x] ART_PIPELINE atualizado (receita final, custos/gerações, problemas e soluções).

## Fora desta etapa

Ligar a arte ao jogo, roupas no corpo jovem (âncoras são da 05), arte de objetos e adereços.

## Evidência e passagem de bastão

`build/art/tiro_fases/`. README, ROADMAP, ART_PIPELINE. Sem push.

Registro e verificações: [README, etapa 04](README.md#etapa-04--produção-e-validação-19102026). Portão concluído; abrir a 05 em sessão própria.

Nota de execução: o plano chamava todos os quadros do mundo de 64×64. A conferência dos originais mostrou 8 rotações 64, 45 quadros 76, 38 quadros 80 e 8 quadros 96. Foram preservados os canvases de cada arquivo adulto, sem redimensionamento. Ver DECISOES e ART_PIPELINE.
