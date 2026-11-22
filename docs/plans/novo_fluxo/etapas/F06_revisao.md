# F06 — Revisão completa e roteiro do celular

Plano: `docs/plans/novo_fluxo/README.md` (todas as seções; "Andamento" tem o histórico F00–F05). Mapa: `CLAUDE.md`.
Base: F00–F05 concluídas (Ato 1, Ato 2, aula da comida, capítulos 2–11, missão secreta, ritmo).

## Objetivo

Jogar o começo inteiro como uma pessoa nova, nas três resoluções, e consertar o que atrapalha entender:
"bem legal, dinâmico, simplificado e auxiliar as pessoas o máximo possível" (diretriz do Vitor).
**Sem sistema novo e sem mudar regra/ritmo**: só correções de texto, posição, sobreposição, ordem de avisos,
mão/balão apontando o lugar errado, botões cortados, e bugs.

## Passos

1. **Tour de capturas do começo**: `tests/novo_fluxo_tour.gd` (sem `--headless`) que joga pelo
   `tests/helpers/week_story_route.gd`/`week_session_route.gd` e captura cada passo do Ato 1 (8), Ato 2 (6), a aula
   da comida (5 toques), Boa noite/Bom dia, e o início + fim (carta) de cada capítulo 2–11, o desafio do dia, a
   missão secreta e o Dentinhos → Vila. Rodar em **360×780, 390×844 e 412×915** → `build/screenshots/novo_fluxo/`.
2. **Abrir e revisar cada PNG** com esta lista (anote cada problema com o nome do arquivo):
   - há um próximo toque óbvio (pílula, mão ou brilho)? a mão está em cima do alvo certo?
   - algo cortado, sobreposto, fora da tela, atrás do HUD/abas, texto pequeno ou longo demais (mais de duas linhas)?
   - dois avisos/cartões ao mesmo tempo, ou cartão modal empilhado com lição?
   - aparece algo que ainda não foi apresentado (uma coisa por vez)? sobrou "dia N", "volte amanhã", moeda no Ato 1?
   - texto em português simples, sem bronca, verbos do glossário (Colher, Pegar, Cozinhar, Fazer, Buscar, Ir)?
3. **Corrigir** o que for encontrado (dados/telas). Recapturar só o que mudou e conferir de novo.
4. **Toque real**: exporte (`tools\export_web.ps1`), sirva (`tools\serve_local.ps1`) e rode um roteiro de toque
   (`tools\touch_test.ps1 -Url http://localhost:8000/dev/ -Steps game/tests/touch/novo_fluxo.json`) cobrindo o
   Ato 1 inteiro (caixinha, roleta, banho com esponja, bola, colocar caminha, crescer, carta). Registre fps se der.
5. **Portão** final: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao -KeepGoing`; cada falha
   rodada sozinha e classificada (antiga / regra antiga no teste / bug / carga). Nenhuma falha nova.
6. **Roteiro do celular para o Vitor** em `docs/plans/novo_fluxo/RESULTADOS.md` (seção nova "Roteiro do celular"):
   passo a passo curto do que fazer e o que observar em cada momento (Ato 1, Ato 2, aula, primeira noite, dia 2,
   capítulos), incluindo começar à noite (22h–6h) e jogar uma vez por dia com a tigela. Linguagem simples.
7. Atualize `docs/ROADMAP.md` "Estado atual" (o plano Novo fluxo concluído localmente, o que ficou pendente: arte
   provisória em `PROVISORIOS.md`, teto da missão secreta para o Vitor decidir, testes antigos que já falhavam),
   `CLAUDE.md` = `AGENTS.md` (uma linha "Plano Novo fluxo CONCLUÍDO"), "Andamento" do plano.

## Regras

- Sem commit, push ou publicação. Edite com Edit/Write (UTF-8), preserve CRLF/LF.
- Se uma correção exigir mudar regra ou ritmo, não mude: anote como proposta no RESULTADOS.
- Testes afetados por correções: `-Level etapa -Exact -Jobs 1`.

## Pronto quando

- Começo revisado nas três resoluções sem problema aberto (ou cada um anotado com motivo), toque real do Ato 1 OK,
  portão sem falha nova, roteiro do celular escrito, docs atualizados.
