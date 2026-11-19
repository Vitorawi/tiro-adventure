# E09. Brincadeiras

## Referências

Os conectores Claude Docs e Artifact estão indisponíveis. Foram consultadas as cópias locais da E07, `10ea2159…/scratchpad/plano.md` (“Tiro filhote: plano da primeira semana”, projeto `b45e1b2e-da97-4e57-af6f-b9e8a342ad66`) e `21190024…/scratchpad/artifact-files/ed7f930e…/project/Minigames.dc.html` (prancha T6 do canvas “Primeira semana do Tiro”).

## Arquivos e execução

1. Definir dias, alvos, pontuação, janelas de gesto e prêmios em `growth.json`. Implementar partidas, limites, recordes e contadores no `GameState` e persistir os recibos em `WeekState`. Subir o save para 28.
2. Ligar o Quintal do Sítio, Brincar e Para crescer ao painel de brincadeiras. Reaproveitar a madeira, o cenário, a infraestrutura do esconde-esconde e as poses do Tiro.
3. Registrar `play_week_test` na suíte e nas áreas afetadas. Testar os dias com o relógio DEV, cinco lançamentos, alvos, Pula!, recorde, limites e renovação do período, toque e progresso.
4. Rodar o circuito de etapa, comparar com a E08 e abrir capturas nas três resoluções. Atualizar Andamento, ROADMAP, documentação do projeto e provisórios.

Pronto quando todas as brincadeiras estiverem acessíveis nos dias previstos, os gestos alimentarem o Para crescer dentro dos limites e `play_week_test` passar.

## Implementação

- Toque no cesto do Sítio ou abra **Brincar** nos cuidados do Tiro. No dia 1, cinco lançamentos da bolinha de pano formam uma partida sem pontos. Toque direto ou puxe para lançar. No dia 2, a mira tracejada prevê o alcance e a direção. O arco vale 3, o balde vale 2 e cada faixa cruzada vale 1, até três faixas. O alvo substitui os pontos das faixas. As trapalhadas da lama, galinha e vaso preservam o placar. Acerte **Pula!** enquanto a janela estiver aberta para dobrar os pontos. No dia 5 a bolinha apita e alcança mais longe. No dia 6 ela quica quando cai na ponte.
- As três primeiras partidas completas da Bolinha em cada período dão Felicidade e contam para crescer. A Esperteza segue o teto compartilhado de dois momentos. O recorde pessoal pode subir em qualquer partida. O primeiro recorde positivo premiável do dia paga 5 moedas provisórias, uma vez. Sair no meio descarta a partida. O save 28 guarda os recibos e os recordes e reinicia os saves anteriores.
- **Tiro!** abre no dia 1 e registra o chamado quando ele chega. **Cabo de guerra** abre no dia 4, com três puxões e uma faixa verde para soltar no ritmo. **Esconde-esconde** abre no dia 6 e usa a folha dos copinhos para o jogador procurar o rabo no vaso, na casinha ou no arbusto. Cada brincadeira tem seu limite próprio de três por período. Cordinha e esconde-esconde também contam para o requisito geral de brincar. O nome e a cordinha têm requisitos próprios no Para crescer e levam ao Quintal com **Ir**.

## Validação

- A rodada de `tools/test.ps1 -Level etapa` e os retestes somaram 81 testes distintos. Depois dos ajustes de conteúdo, painel e seletores de cuidado, o consolidado ficou em 71 PASS, nove falhas e um timeout. Logs em `build/e09_etapa.log`, `build/e09_retest.log` e `build/e09_final_isolated.log`.
- Repetiram a E08 `hud_growth_test`, `tray_test`, `world_selector_test`, `world_view_test`, `tasks_test` e `item_sources_test`. `care_ui_test` voltou a exceder o tempo. O escopo da E09 também rodou `ready_badges_test` e `text_budget_test`, já registrados como falhas na E07. `mood_test` espera o Sítio fechado após reset, enquanto o Sítio abre no dia 1 desde a E06.
- `play_week_test` passou no reteste headless final (65,2 s) e em modo gráfico nas três resoluções. O roteiro complementar verificou o toque no cesto, o destino dos atalhos e o toque no esconderijo nas mesmas três resoluções. Foram abertas as pranchas em `build/screenshots/e09_play/` e `build/screenshots/e09_paths/`, com 48 capturas nativas de 360×780, 390×844 e 412×915. O SHA-256 da idle aprovada continuou `FB010A541283D6FF575032EDF172642B569B0D22EAE062A11F1E4F0D9D4CA0B5`.

## Conferência no celular

1. No DEV Semana, vá ao dia 1. Abra o Quintal pelo cesto no Sítio e por **Tiro → Cuidar → Brincar**. Chame **Tiro!** e confira o requisito. Faça cinco lançamentos com a bolinha de pano.
2. No dia 2, mire no arco e no balde, acerte um **Pula!** e deixe outro passar. Confira o placar, o recorde, as 5 moedas do dia e a partida livre depois da terceira. Mude para o período seguinte e confira a renovação.
3. No dia 4, segure a cordinha e solte no verde três vezes. No dia 5, confira o alcance e o som da bolinha. No dia 6, mire na ponte e procure o rabinho nos três esconderijos. Confira o atalho do Para crescer com o polegar e a legibilidade em tela cheia.
