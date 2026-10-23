# Etapa 06 — Missões e história

Concluída em 23/10/2026 pelo Codex, somente local. Antes da edição: `git status` conferido,
etapa 05 fechada no README, ROADMAP e VALIDACAO_05; alterações anteriores preservadas.

## Entrega

- Rotinas só da fazenda; removidos `care`, `care_week`, `tiro_walk`, catálogos legados e fallback de
  consulta. Catálogos com três modelos cada; sorteio até três diárias e duas semanais, limitado aos
  acessíveis. No início, uma colheita disponível basta, sem exigir tarefas impossíveis.
- Roupas: `clean_bow`/`walker_bandana` em `big_harvest`, `heart_collar` em `orders_week`.
- `lais_first_wish`: primeiro passo do capítulo 2, depois de caminha e Filhotinho; `stat: wish` 1
  histórico, sem fresh nem prêmio adicional. Preserva a feature que exige Filhotinho e evita ciclo no
  primeiro crescimento. `lais_first_crops` apresenta o Tiro animado. Tutoriais feed/bath/play mantidos.
- Como fazer de objetivo `wish`, tipo `moments` e requisitos de momentos explica ação/fontes e Ir.
  Fontes vêm do mesmo catálogo do caderninho, sem conceder progresso pela consulta.
- `texts_test` proíbe vínculo, afeto, corações e referências à aba Desejos/espera de dois minutos.
  Objetivo de amizade muda só de texto; nenhum mecanismo de amigos alterado. `list_texts.ps1` gerou
  2.139 textos; nenhum resultado na busca desses termos. Dados de NPCs e feature já eram compatíveis
  (fala introdutória de cuidados e destino `screen: pet`), preservados após revisão.
- `SAVE_VERSION` 17: IDs de rotinas removidos não são reutilizados por saves anteriores. Reset pelo
  ramo existente, sem migração e sem teste de save antigo.

## Validação

Escopo próprio em `build/cuidado06_scope.txt`, para não selecionar todo o trabalho local anterior.

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests care_story_test -Areas story,navigation -ChangeList build/cuidado06_scope.txt -Jobs 3 -KeepGoing
```

**13/13 PASS em 48,1 s**, `build/test_logs/r20261023_070304_df4ad7c9/results.csv`:
scripts_check, content_test, texts_test, care_story_test, growth_story_test, journey_test, tasks_test,
tasks_groups_test, npc_lines_test, onboarding_test, navigation_test, recipe_help_test, item_sources_test.

`care_story_test` cobre a ordem desde a caminha, pedido real de carinho, atender/Pegar, conclusão e
próximo passo, desejo já atendido, fontes reais no Como fazer, 12 sorteios por tipo de rotina e roupas.
As fixtures de tasks/growth_story e a guarda de conteúdo foram atualizadas para o catálogo e os 111/51
passos atuais. Primeira rodada expôs essas expectativas antigas; corrigidas, rodada seguinte 13/13
PASS em 47,4 s, seguida da final acima após reforço do teste/ícone de momentos.

Revalidação do save atual e áreas relacionadas após subir a versão:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests care_story_test,saves_test -Areas saves -ChangeList build/cuidado06_save_scope.txt -Jobs 3
```

**12/12 PASS em 51,7 s**, `build/test_logs/r20261023_070421_ac8ac8fe/results.csv`:
scripts_check, content_test, texts_test, care_story_test, saves_test, economy_transactions_test,
storage_test, silo_test, fridge_test, warehouse_test, chest_test e pending_gifts_test.
Nenhum portão, campanha, simulação ou suíte inteira. Sem commit, push ou publicação.
Etapa 07 não executada e nenhuma sessão seguinte aberta, conforme pedido do Vitor.
