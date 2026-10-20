# Etapa 05 — O Tiro muda com a fase (visual no jogo)

**Estado: concluída em 19/10/2026.** Executar somente esta etapa. Pré-requisito: etapa 04 concluída e aprovada.

## Objetivo

O jogador vê o Tiro na idade certa em todo lugar: tela do Tiro, mundo, HUD, retratos, intro e boas-vindas.
Um save novo começa com o filhote de orelhas caídas; um save no capítulo 12 continua com o Tiro de sempre.

## Leitura obrigatória

[06](06_INTERFACE_E_ARTE.md) E; [02](02_FASES_E_PILARES.md) A; `pet_animator.gd` (`DIR`, `_load_clip`, cache,
roupas), `dog_world.gd` (`SPRITE_DIR`), `pet_screen.gd` (caminhada da `AwayView` usa `tiro_world/walk/east`),
`hud.gd` (`hud_tiro`), `intro.gd`, `welcome_back.gd`, `overlay_anchors.json`, `petshop_test.gd` (âncoras).

## Entrega e implementação

1. Uma fonte só para "qual corpo/coat agora": `GameState.dog_look()` → `{body, dir_pet, dir_world, portrait,
   idle_front, coat}` a partir de `growth.json → phases/bodies`. Nada de caminho de sprite escrito em cena.
2. `PetAnimator`: pasta pelo corpo; `clip_fallback`; troca de corpo ao receber `Events.grew` (limpa o cache de
   clipes e de roupas). `PetAnimator.portrait` usa o corpo atual.
3. `DogWorld`, `AwayView` (caminhada), intro, boas-vindas e HUD: mesma fonte.
4. Shader `tiro_coat.gdshader` aplicado em todos esses lugares, com `coat` da fase; no Mocinho, `coat` =
   0,3 + 0,4 × (média dos níveis dos pilares ÷ teto). Azul e Dourado = 1,0 (idêntico ao atual).
5. **Roupas:** `overlay_anchors.json → bodies.young` (deslocamento/escala por clipe; variantes por quadro só onde
   ficar torto). No corpo `puppy`, roupas não são desenhadas (equipar continua funcionando; o caderninho mostra
   "Vai aparecer quando ele crescer"). Conferir as 19 roupas vestíveis no corpo jovem em `idle_breathe`, `eat`,
   `sleep`, `head_tilt` e `sad` (prancha).
6. Sem cerimônia ainda: crescer (pelo DEV) troca o visual na hora com um `Motion.pop_in` simples.

## Teste da etapa — `growth_visual_test.gd` (novo, ≤ 3 min)

Para cada uma das 6 fases (via `dev_set_phase`): corpo e pastas certos no `PetAnimator`, `DogWorld`, retrato
do HUD e `idle_front`; todo clipe usado pelo jogo resolve para quadros existentes no corpo (com fallback);
`coat` certo (Mocinho varia com os pilares; adulto = 1); corpo `puppy` não desenha roupa; corpo `young` tem
âncora para todas as roupas vestíveis; trocar de fase troca o visual sem recarregar a cena.

Rodar também: `pet_care_test`, `petshop_test`, `world_life_test`, `intro_test`, `welcome_test`, `festa_test`,
`hud_test`, `growth_test`.

Capturas 360×780: `t12_pet_puppy`, `t13_pet_young`, `t14_pet_young_outfit`, Sítio com o filhote e com o
adulto. Abrir os PNGs e comparar com `tiro00_antes`.

## Para passar para a próxima

- [x] Nenhum lugar do jogo mostra o adulto quando a fase é jovem (e vice-versa).
- [x] Adulto idêntico ao antes do plano (captura lado a lado).
- [x] Roupas no corpo jovem sem cortes visíveis nas poses conferidas (prancha aberta).
- [x] Afetados PASS.

## Fora desta etapa

Cerimônia, painel de crescimento, HUD com anel de crescimento (só o retrato muda aqui).

## Evidência e passagem de bastão

`build/test_logs/tiro05/`, `build/screenshots/tiro05_*`, prancha de roupas em `build/art/tiro_fases/`.
README, ROADMAP, ART_PIPELINE, `CLAUDE.md`/`AGENTS.md` (linha "Vestir o Tiro / camadas" e "Tela do Tiro"). Sem push.

Concluída com 18 testes PASS + reforço final de `growth_visual_test`, importação e evidências visuais
abertas. Registro completo/tabela no README; zero pixels diferentes na comparação GPU do adulto.
Sem pendência da 05. Próxima: 06 em sessão própria, sem publicação.

**Encadeamento da 05 (19/10/2026):** a tentativa de abrir `Tiro — Etapa 06` no projeto local ClaudeGame
com `create_thread` foi recusada pela ferramenta: `MCP tool call requires approval, but approval policy
is never`. Nenhuma sessão foi criada, e a etapa 06 não começou. A etapa 05 permanece concluída; abrir a
06 manualmente com o bloco "Como passar", usando `ETAPA_06_TELA_CRESCIMENTO.md`. Não contornar a
restrição com outra ferramenta/host. O bloqueio é de criação da sessão, sem pendência de implementação.
