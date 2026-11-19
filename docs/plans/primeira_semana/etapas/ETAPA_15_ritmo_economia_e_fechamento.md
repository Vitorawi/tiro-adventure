# E15. Ritmo, economia e fechamento

| Bloco | Arquivos | Verificação e critério de pronto |
|---|---|---|
| Referências | README, REGRAS, PROVISORIOS, E14, plano e revisão em cache | Usar as metas 1–7 e preservar o roteiro M3. |
| Simulação | simulador e percurso da História em game/tests | Começar da chegada, executar compras, produção, refeições e crescimento pelo motor. Registrar sete dias por perfil, esperas, compras e depósitos. |
| Calibração | dados do jogo e RESULTADOS.md | Investigar cada trava e repetir a medição após ajustes. |
| Fechamento | tools/test.ps1, exportação Web local e capturas | Executar portão completo e campanha, comparar falhas com E14, abrir as três resoluções e validar toque. |
| Registro | RESULTADOS.md, README e ROADMAP | Dar evidência e ressalva para cada critério, manter M3 e adiar E16. |

## Arquivos executados

- `tools/economy_simulate.ps1` aceita `-Until week`. O runner `game/tests/economy_simulation.gd` cria o relatório por semente. O percurso `game/tests/helpers/week_economy_route.gd` estende `week_story_route.gd` com agenda, medidas, observação de estoque e fechamento do caixa.
- `game/tests/helpers/economy_clock.gd` injeta a mesma hora nos gestos do quintal. `economy_sim.gd` usa a abertura da semana nas campanhas, conta as missões ativas e confere custos de sementes, preços locais, tempo de fila e maestria. `economy_sim_test.gd` verifica a sequência de transações e os objetivos novos. `progression_test.gd` inclui a rota de madeira e atende objetivos de alimentação da campanha posterior.
- `tools/economy_audit.py` reconhece receitas do caderninho, colheitas do pomar e missões aposentadas. `economy_audit_selftest.py` quebra uma missão ativa para verificar que o auditor detecta o erro. `tools/test.ps1` preserva o resultado de timeout ao encerrar uma árvore de processos, e `test_circuit_selftest.py` verifica a seleção a partir do mapa vigente.
- `game/tests/week_story_shots.gd` percorre a caixinha, almoço e Vila. `week_tutorial_test.gd` aciona Crescer! e Que lindo!, confere o recibo persistido e captura a cerimônia. O alfinete em `game/scenes/levels/room/room.gd` cancela a expiração quando a própria indicação sai da cena. `drag_scroll_test.gd` exercita o Livro de História na camada em que ele abre.
- Registro completo dos critérios, tabelas e limites em [RESULTADOS.md](../RESULTADOS.md). O [roteiro M3](ETAPA_14_tutoriais.md#roteiro-para-o-portão-m3-no-celular) continua pendente no aparelho. Os provisórios continuam para a E16.
