# F05 — Ritmo: tempos e moedas pelo simulador

Plano: `docs/plans/novo_fluxo/README.md` seção 7 (metas) e 5c (quem joga uma vez por dia). Mapa: `CLAUDE.md`.
Base: F00–F04b (Ato 1 casa, Ato 2 vovó, capítulos 2–11 por sistema, aula da comida, tigela de dois lugares,
missão secreta do Ensopado Dourado). Referência do método: `docs/plans/primeira_semana/RESULTADOS.md` (E15).
Esta é a etapa do nível de testes **campanha**.

## Objetivo

Medir e acertar o ritmo da semana nova pelos tempos de produção e pelas moedas, **sem trava por dia** e sem
"volte amanhã". Metas (seção 7):

| Perfil | Capítulos 2–10 (conteúdo) | Dentinhos |
|---|---|---|
| `muito` (3+ sessões por dia, joga ao vivo, faz a missão secreta) | 2 a 3 dias reais | dia 6 ou 7 (com o segredo, ~dia 5) |
| `regular` (1–2 sessões, usa a tigela quando sai) | 5 a 7 dias | dia 7 a 9 |
| `perde_dia` (como o regular, mas pula um dia inteiro no meio) | igual, um dia depois | um dia depois, sem perder nada além daquele dia |

Também: a primeira sessão (Ato 1 + Ato 2) cabe em ~30–40 min de jogo ativo; nenhum capítulo do Ato 3 tem espera
longa sem outra coisa para fazer; o caixa nunca trava a história (sempre dá para conseguir as moedas do próximo
passo com o que já está aberto).

## Passos

1. **Robô da semana nova**: reescreva `game/tests/helpers/week_economy_route.gd` (e o que ele usa de
   `tests/helpers/week_story_route.gd`) para seguir a ordem nova (Ato 1 → Ato 2 → capítulos 2–11) por **sessões
   no relógio** (horários reais de entrada/saída por perfil), não por "dia N". Perfis `muito`, `regular`,
   `perde_dia` (mantenha `tranquilo/regular/dedicado` só se ainda forem úteis; o modo `-Until week` do
   `tools/economy_simulate.ps1` aceita os novos). O robô usa só ações reais do `GameState` (sem `dev_*`, sem
   `unlimited_storage`, sem `ready_at` forçado), dá as refeições na janela ao vivo quando está jogando e usa a
   tigela de dois lugares antes de sair. `muito` faz a missão secreta quando aparece.
2. **Medir** com 3 sementes por perfil (`tools\economy_simulate.ps1 -Until week -Profile <p> -Seed 1..3`):
   por capítulo, minutos de sessão / espera / toques; dia real em que cada capítulo fecha; dia do Dentinhos;
   patinhas por dia; caixa mínimo; depósitos cheios. Guarde em `build/economy/f05_antes/`.
3. **Ajustar** só dados (`crops.json`, `recipes.json`, `config.json → farm`/estações, preços/prêmios em
   `progression.json`/`quests.json`), nunca o código das regras, até as metas. Plano diz que os tempos atuais são
   curtos demais para quem joga muito (ovos 30 min, frutas 2 h, abóbora 10 min): alongue onde segura o ritmo, mas
   sem espera morta (sempre há outra coisa a fazer). Decida também `farm.early_through` (primeiros dias mais
   rápidos, hoje no calendário): manter, passar a capítulo, ou remover — o que der o ritmo certo.
4. **Medir de novo** → `build/economy/f05_depois/`, mesmas sementes.
5. **Campanha**: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level campanha -KeepGoing`
   (progression_test + simulador Quick + Python). Ajuste o robô da campanha (`economy_bot.gd`/`economy_sim.gd`/
   `progression_test`) para a ordem nova, se quebrar. Rode em segundo plano (demora).
6. **Resultados** em `docs/plans/novo_fluxo/RESULTADOS.md`: como reproduzir, tabela antes × depois por perfil
   (capítulos, Dentinhos, sessão ativa, esperas), o que foi ajustado e por quê, ressalvas. Linguagem simples
   (o Vitor lê).

## Regras

- Sem commit, push ou publicação. `CLAUDE.md` = `AGENTS.md`, `docs/ROADMAP.md`, "Andamento": uma linha cada.
- Se um ajuste de dado mudar o que um teste confere (tempo, preço), ajuste o teste. Rode os testes de etapa afetados
  (`-Level etapa -Exact -Jobs 1`) depois dos ajustes: `ato1_test`, `ato2_test`, `ato3_chapters_test`, `ato3_help_test`,
  `food_lesson_test`, `meal_rules_test`, `secret_stew_test`, `week_story_test`, `farm_week_test`, `content_test`,
  `texts_test` e os de produção que mudarem.
- Se a meta não for atingível só com dados (ex.: precisa de regra nova), pare, registre a proposta no RESULTADOS e
  não mude a regra.

## Pronto quando

- As três metas atingidas (ou a diferença explicada com números e uma proposta), campanha sem falha nova,
  RESULTADOS escrito.
