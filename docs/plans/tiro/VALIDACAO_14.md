# Etapa 14 — retomada e validação (19/10/2026, Codex)

**Concluída: funcionalidade e arte PixelLab validadas.** Etapa 13 confirmada.
Histórico local do Claude recuperado: `ce5df0db-9717-5a66-9a5f-973c2248457d.jsonl`; a sessão terminou
por limite de uso, imediatamente antes da criação do teste da Casa. Todas as mudanças locais anteriores
foram preservadas. Sem reset, commit, push ou publicação.

## O que está pronto

Casa por fase e lembranças entregues, régua com nomes/datas das cerimônias, prateleira com acesso às fotos,
prêmios do álbum em 6/12/18/30/45 fotos, caminhas com bônus de energia online e na ausência, tigela +10%,
cesto de brinquedos com entrega permanente e bônus de Esperteza até +3, até três fotos na parede,
foto principal do cantinho, câmera com o dado de duas lupas por dia. Persistência sem mudar SAVE_VERSION.

Nesta retomada foram completadas lacunas da implementação interrompida: dormir na caixinha antes da caminha;
compra das melhorias acessível nos painéis de caminha/tigela; fotos reais escolhidas na parede e moldura
(reutilizando PhotoCard), no lugar de retângulos genéricos; datas da régua; brinquedos no filtro Para o Tiro;
régua do cantinho tocável e tapete dentro da tela. Criados `house_test.gd` e `house_shots.gd`, com seus UIDs.

## Arquivos → testes → resultado

| Área | Testes | Resultado final |
|---|---|---|
| `house.json`, GameState, ProgressionState, DogState, HouseDecor/HouseUi/CornerDecor, sala e escolhas | `house_test` novo, 11,3 s | PASS |
| Sala da Casa, substituições, footprints, sono e caminhos | `world_life_test`, `world_view_test`, `navigation_test` | PASS |
| Cuidados, caminhas e ausência | `pet_care_test`, `absence_test`, `brush_taste_test`, `wishes_test` | PASS |
| Álbum, fotos e Mochila | `album_test`, `lists_test`, `manual_test`, `keys_test` | PASS |
| Pilares, tigela e comida | `pillars_test`, `growth_test`, `growth_foods_test` | PASS |
| Conteúdo, compras e história afetada | `content_test`, `tasks_test`, `growth_story_test`, `journey_test`, `festival_test` | PASS |
| Save e transações | `saves_test`, `economy_transactions_test` | PASS |
| Painéis, receitas/material e texto | `sheet_test`, `station_tray_test`, `products_test`, `fridge_test`, `texts_test` | PASS |
| Estilo da UI | `ui_style_test` | Imprime PASS; runner FAIL apenas pelos recursos em uso ao encerrar, falha histórica já documentada |

**28 testes distintos: 27 PASS, uma falha histórica de encerramento.** Rodadas via `test_all.ps1 -Only`
em `build/test_logs/tiro14/affected.log`/`.csv` (3,5 min), `recheck.log`/`.csv` (2,9 min),
`final.log`/`.csv` (0,6 min). Importação final sem erros em `import.log`; `git diff --check` passou.
Sem suíte inteira, campanha simulada ou simulação de economia, conforme o contrato da etapa.

As duas falhas da primeira rodada foram corrigidas:

- `pillars_test`: a fixture agora entrega um brinquedo real para obter o bônus do cesto; a fixture de
  alimentação única remove a tigela concedida por `dev_unlock_everything`, isolando o comportamento testado.
- `content_test`: reconhece e valida `house:bed`; `worlds.json` mapeia as duas melhorias ao lugar da caminha,
  mantendo a validação de que toda compra tem um lugar de acesso.

## Capturas

Sete PNGs 360×780 em `build/screenshots/tiro14/`: `t11_house_start`, `t11_house_middle`, `t11_house_end`,
`t11_house_shelf`, `t11_house_photos`, `t11_corner_decor`, `t11_house_bed`. Comparativo lado a lado em
`house_comparison.png`. Capturas da Casa, prateleira e cantinho abertas e inspecionadas; a última versão
do cantinho também foi aberta após o ajuste do tapete/régua. Não foi usado aparelho físico. Nenhum gesto
novo de arrastar foi criado; novos controles usam toque simples já existente.

## Primeira tentativa: pendência de arte (resolvida na retomada abaixo)

O Claude deixou arte procedural em `tools/house_art.gd` e 14 PNGs da Casa. Esses arquivos foram preservados,
mas não satisfazem a exigência explícita de produção PixelLab da etapa. Foram tentadas cinco chamadas
`create_image_pixflux` para caixinha, cesto de roupa, cesto de brinquedos, câmera e tapete; todas retornaram
erro de transporte HTTP para `https://api.pixellab.ai/mcp`, sem imagem/job utilizável. Registro resumido em
`build/test_logs/tiro14/pixellab.txt`, prompts e tamanhos em `docs/ART_PIPELINE.md`.

Na primeira tentativa a etapa permaneceu aberta até resolver a arte. O novo pedido do Vitor e a resolução estão registrados abaixo.

## Retomada PixelLab: conclusão da 14

No pedido "Tenta de novo o pixellab", o serviço respondeu e concluiu **13 gerações**. Fontes originais e manifesto completo (prompts, IDs, tamanhos, hashes) em `tools/art/house_pixellab/`; todos os 14 objetos provisórios foram substituídos/preparados a partir dessas fontes. O retrato grande reutiliza o Tiro adulto atual; `gold_frame_front.png` aplica a moldura PixelLab no cantinho. `tools/house_art.gd` virou o preparo reproduzível por recorte/nearest/inclinação, sem acesso à rede.

- Importador de arte: PASS (`art_pixellab.log`); importação Godot sem erro (`import_pixellab.log`).
- Após a arte e a moldura do cantinho: `house_test` 11,3 s, `pet_care_test` 17,8 s, `album_test` 13,1 s — **todos PASS** (0,7 min), logs/CSV `pixellab_tests` em `build/test_logs/tiro14/`.
- Somente esses afetados reexecutados: demais testes funcionais já haviam passado, sem mudança de regras nesta retomada; sem suíte inteira nem simulação.
- Prancha das 13 fontes aberta e revisada; sete capturas finais em 360×780 refeitas, Casa no meio/fim e cantinho abertos. Comparativo final lado a lado em `house_comparison.png`. Versão provisória preservada em `build/screenshots/tiro14_provisoria/`.
- 2.019 PNGs do Tiro, incluindo retratos do HUD, verificados por SHA-256: **zero alterados** (`tiro_preserved.txt`). Nenhum novo corpo, canvas, ponto dos pés ou footprint.

A pendência externa está resolvida. Etapa 14 concluída; próxima é a 15 em sessão própria, sem publicar/commit/push.
