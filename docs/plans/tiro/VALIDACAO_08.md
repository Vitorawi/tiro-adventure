# Etapa 08 — validação do portão

19/10/2026. Etapa 07 confirmada concluída; aprovação da arte 04 já autorizada pelo Vitor.
Somente cerimônia da 08 implementada, local, sem commit/push/publicação e sem reset de saves.

## Implementação e provas focadas

| Arquivos mudados | Verificação | Resultado |
|---|---|---|
| GrowthState / GameState (recibos, pending_reveal, ready_seen) | ceremony_test: round-trip do save, retomar durante cena, não repetir visto, dormir/acordar/reabrir | PASS |
| main / GrowthCeremony / ModalCard existente | ceremony_test: uma entrada por fase, BeforeAfter/HeightMark, Que lindo!, Novo depois | PASS |
| GrowthCeremony / Motion / Haptics existentes | constante ≤3/s, soma 2,5 s, reduzido sem alternância/confete, 5 cartões | PASS |
| feature wishes / fixtures | wishes_test, pet_care_test, products_test, lists_test | PASS nas rodadas focadas; também incluídos na suíte |
| bond_test (fixture XP/relógio) | prêmios atuais, sorteio com pré-condições explícitas, ganho exato 3 | PASS (3,4 s) |
| growth_ui_test | Crescer agora deve enfileirar cerimônia que assume a tela | PASS (11,8 s) |
| PNGs do Tiro | SHA-256 contra espelho da 07: 1.965 comparados | 0 diferenças, 0 PNGs novos |
| Projeto original | Godot --editor --import --quit | PASS |

`ceremony_test` final: PASS, 19,7 s na suíte (limite interno 170 s e execução com timeout de 3 min).
Log: `build/test_logs/tiro08/ceremony_acceptance.log` (stderr vazio).
As primeiras tentativas acharam carga antecipada de classe em teste -s, um argumento Array não tipado
na fila Novo! e interferência de cartões Novo! entre fixtures; todos corrigidos antes da aceitação.
Nenhum timeout foi contado como PASS. A primeira execução inválida foi interrompida.

## Capturas e toque

- `ui_tour` completo 360×780: **114 PNGs**, sem erros no log, `build/screenshots/tiro08_depois/`.
- Painel e `t04_ceremony_before_after` em 360×780, 390×844 e 412×915, pastas `tiro08_<resolução>`.
- Abertos os PNGs das três resoluções, as cinco fases, tela Tiro, HUD/popover e caderninho.
  Comparados com `tiro00_antes/a01_pet`, `c06_hud_popover` e `f05_notebook_manual`.
  Botão legível, fatos quebram em linhas, nomes/poses sem sobreposição; adulto usa arte preservada.
- `touch_test.ps1`: Chrome headless em celular 390×844, perfil descartável, export só da fixture em build.
  Toques em Crescer e Que lindo! produziram uma mudança para puppy e `CLOSED seen=true`.
  Console sem erro e capturas abertas em `build/test_logs/tiro08/touch/`. Sem aparelho físico.
- A primeira sondagem foi feita antes de o export terminar; a segunda apontou a conversão entre
  coordenadas lógicas e CSS. Roteiro final usa CSS (180,780) e (195,696), com log de confirmação.

## Suíte do portão

Uma única passagem: `test_all.ps1 -KeepGoing -Skip economy_sim_test`, **73 entradas, 1.941,9 s
(32,4 min)** no espelho `build/tiro08_workspace/`, com dados próprios `TiroEtapa08Tests`.
Resultado bruto: **65 PASS / 8 FAIL**; `suite.log`/`suite.csv` preservados sem reescrever os resultados.
Inclui progression_test (1.218,5 s); excluído apenas economy_sim_test pelo pedido explícito do Vitor.
Nenhuma execução de economy_simulate, perfil, semente ou baseline de economia nesta etapa.

Duas fixtures antigas foram corrigidas e repetidas, **sem repetir a suíte**:

| Teste | Falha na suíte | Correção da fixture | Repetição |
|---|---|---|---|
| tricks_test | 11 asserts de roupa oculta no filhote | seleciona adulto antes de conferir roupa/retorno dos 5 clipes; regra da 05 preservada | PASS 10,5 s |
| market_test | treat_box exige Aventureiro; contrato final sem produto | seleciona explorer depois do reset/DEV no cenário de produção; regra da 07 preservada | PASS 6,2 s |

`market_test` teve uma primeira repetição com a fase posta antes do reset (falhou; registro preservado),
corrigida antes da aceitação. Nenhuma regra nem assert foi removido/afrouxado. Só esses dois testes foram
repetidos após a passagem total. **Aceitação consolidada: 67 PASS / 6 falhas de testes históricos**,
em `acceptance_summary.csv`; novo `ceremony_test` PASS **19,7 s**.

| Teste histórico ainda vermelho | Evidência nesta única passagem |
|---|---|
| progression_test | 14 asserts (base tinha 9): capítulos/comunitárias, chest_5/silo_5/warehouse_5, merchant_festival, nina_blueberry. Robô não cresce e ainda espera a economia anterior ao fim dos níveis; não foi alterado nesta etapa. |
| npc_lines_test | Recebe etapa da venda; Recolher conclui passo do Guia; Feirante persiste (mesmos três). |
| onboarding_test | 5 asserts: capítulo 4 em 60 min, primeiro desejo em 7 min, capítulo 4 ao fim, primeiro passeio e primeiro raro. Saída difere da base: esse robô também não cresce; não foi alterado nesta etapa. |
| finds_test | Faro: missão pronta (mesmo erro). |
| park_test | PARK TEST: PASS, runner acusa 14 recursos em uso ao sair (histórico). |
| ui_style_test | UI_STYLE TEST: PASS, runner acusa 12 recursos em uso ao sair (histórico). |

O histórico petshop_test passou (5,1 s). Não se afirma que todos os asserts de progression/onboarding
sejam idênticos à base: as diferenças estão acima. Crescimento/roupas/fila/saves/cuidados e os gates reais
passaram nos testes focados. Portão encerrado com essas ressalvas, sem teste fora da lista histórica
permanecendo vermelho. A adaptação dos robôs ao crescimento pertence à 11; não foi antecipada.
Nenhuma investigação de histórico ultrapassou 10 min, nem houve repetição de histórico na suíte.
