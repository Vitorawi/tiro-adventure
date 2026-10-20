# Etapa 09 — validação (19/10/2026, Codex)

Etapa 08 confirmada no README/ROADMAP/VALIDACAO_08; portão concluído com ressalvas históricas. Etapa 09 concluída localmente. Sem commit, push, publicação ou outro reset.

## O jogador encontra

Sete comidas de crescimento e Xampu de ervas, com ícones próprios 32×32. Guia com selo do maior pilar nas comidas adequadas; segurar outra comida mostra a dica sem impedir alimentar. Com xampu aparece acima do banho quando existe estoque e lembra a escolha só na sessão. Banho e arrasto usam a ação existente bathe(true), com consumo de 1, Pelagem 12 e recarga compartilhada de 2 h; banho comum continua com 3. O contador de banhos não depende da recarga de pontos.

Refeições finais: Dentinhos frozen_carrot ×3, Aventureiro growth_kibble ×3, Mocinho milk_porridge ×3 e 2 shampoo_bath. Itens-chave continuam provisórios. foods_revision mantém os IDs e troca apenas refeições de fases futuras nos saves v13 anteriores à 09, sem repetir a troca na recarga. Ver DECISOES para os valores de feed não definidos pela tabela.

## Cada estação serve ao Tiro

| Estação | Uso real nesta etapa |
|---|---|
| Fogão | Papinha da vovó, crocante de milho, ração, ovinho, queijo e mingau |
| Liquidificador | Cenoura gelada e xampu |
| Galinheiro | Ovo → ração de crescimento/ovinho mexido |
| Curral | Leite → mingau/xampu |
| Moinho | Farinha → mingau/petisco de queijo |
| Queijaria | Queijo → petisco de queijo |
| Estufa | Ervas → xampu |

Bancada/costura e itens-chave permanecem para a 10, paladar para a 12 e bolo para a 15.

## Arquivo mudado → teste rodado → resultado

| Área / arquivo | Testes | Resultado final |
|---|---|---|
| items.json, recipes.json, oito PNGs | growth_foods_test, content_test, products_test, station_tray_test, fridge_test | PASS |
| growth.json, growth_state.gd, game_state.gd (foods_revision) | growth_test, pillars_test, growth_foods_test, saves_test, economy_transactions_test | PASS |
| pet_care_tray.gd | pet_care_test, wishes_test, manual_test; growth_foods_shots | PASS |
| database.gd, categoria care em sheet_builder.gd | manual_test, content_test, sheet_test, lists_test | PASS |
| places.gd, task_help.gd | navigation_test, tasks_test, growth_ui_test; growth_foods_shots | PASS |
| Textos novos | texts_test | PASS |
| Estilo do catálogo | ui_style_test | Imprime PASS; runner FAIL histórico por recursos em uso ao sair |
| tools/test_all.ps1 | execução seletiva de growth_foods_test | PASS, novo teste incluído na suíte |

Consolidado: **18 testes distintos PASS**, mais **GROWTH FOODS UI PASS**; somente ui_style_test histórico. A primeira rodada achou Manual sem categoria care e growth_test usando a refeição provisória; categoria corrigida e fixture trocada por frozen_carrot sem afrouxar assert. Repetidos somente os afetados. UI_STYLE executado uma vez, mesma falha de 12 recursos em uso da base/08, sem investigação adicional.

growth_foods_test final **5,1 s**, watchdog de 150 s; tabela completa build/test_logs/tiro09/results.csv. Rodadas registradas ~3,5 min. Logs affected.log, catalog_affected.log, final_focused.log, growth_help.log e shots_after.log. Importação original import_original.log sem erros. Importação inicial e primeira captura no sandbox foram bloqueadas por diretórios de usuário/cache; repetidas com acesso autorizado. Primeiras tentativas de captura tiveram caminho inválido e referência precoce de autoload no script de teste, corrigidas antes da evidência final.

Sem suíte completa, progression_test ou economia: etapa 09 não é portão. Nenhuma falha histórica dos robôs foi reexecutada.

## Capturas e toque

360×780 antes: build/screenshots/tiro09_antes/guia.png e banho.png, geradas da cópia preservada da 08. Depois: build/screenshots/tiro09_depois/guia_selos.png e banho_xampu.png. Quatro PNGs abertos; guia cabe na tela, selos junto dos ícones, chip acima do banho sem cobrir os quatro controles. Prancha build/art/tiro09/icons.png também aberta.

growth_foods_shots.gd valida eventos do Godot: root.push_input abre Comida e seleciona o chip; gui_input segura comida e toca Banho. Confirma dica, consumo exato, alimentação sem bloqueio, selo atualizado por fase, chip oculto sem estoque, Manual com xampu e Como fazer levando ao Tiro. Não houve gesto novo; touch_test.ps1 não exigido pela regra 8. Sem navegador móvel ou aparelho físico nesta etapa.

**1.965 PNGs do Tiro comparados à cópia da 08: zero diferenças**, conforme art_preservation.txt. Canvases, roupas e shaders preservados.

## Continuação

Próxima: ETAPA_10_ITENS_CHAVE.md em nova sessão local Tiro — Etapa 10; prompt completo preparado em build/tiro10_prompt.txt. A etapa 10 não foi implementada aqui. Se create_thread recusar, registrar o motivo no ROADMAP e entregar o prompt, sem outra ferramenta ou host.


Tentativa efetiva de create_thread no projeto local ClaudeGame (projectId 23045ad9-f070-4702-900e-ffd4c4d7883c), título Tiro — Etapa 10: recusada com MCP tool call requires approval, but approval policy is never. Nenhuma sessão criada; sem contornar por outra ferramenta/host. Abrir manualmente com build/tiro10_prompt.txt.
