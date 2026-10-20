# Etapa 02 — Motor do crescimento (estado, dados e saves zerados)

**Estado: concluída em 19/10/2026 (Codex; local, sem commit/push).** Executar somente esta etapa. Pré-requisito: etapa 01 concluída **e aprovada pelo Vitor**.

## Objetivo

O jogo passa a saber em que fase o Tiro está, o que falta para crescer e consegue fazê-lo crescer. Ainda sem
tela nem arte nova: só o motor, testável e salvo. Saves antigos são zerados (`SAVE_VERSION` 13), como o Vitor pediu.

## Leitura obrigatória

[02](02_FASES_E_PILARES.md) (A, C, F, H), [07](07_SAVES_E_ESTADO.md) A, D, E, F, G;
`game_state.gd` (`requirement_error`, `_grant_automatic`, `_count`, `from_dict/to_dict`),
`save_manager.gd` (`SAVE_VERSION`, `_migrate`, ramo de reset `< 12`), `database.gd`.

## Entrega e implementação

1. `game/data/growth.json` com `schema`, `pillars`, `levels`, `radiant`, `phases` (6 entradas) e os requisitos
   **provisórios** da seção 02 C (só coisas que já existem), `rewards` da 02 F e `facts`/`teaser` por fase.
   Incluir no `include_filter` do preset Web se preciso (já inclui `data/*.json`).
2. `Database.growth` + validação (`growth_problems()`): ids únicos, níveis crescentes, itens/missões/
   construções/projetos referenciados existem, tipos de requisito conhecidos. Falha aparece no `content_test`.
3. `scripts/state/growth_state.gd` (campos da 07 A que esta etapa usa: `schema`, `phase`, `phase_since`,
   `points`, `reserve`, `done`, `delivered`, `phase_stats`, `ceremonies`, `cooldowns`, `firsts`) com
   `reset/to_dict/from_dict` e consultas puras (`phase_index`, `cap`, `level(pilar)`).
4. `GameState.growth` salvo na chave `growth`. Ações (07 F): `growth_info()` (consulta pura: fase, próxima,
   requisitos com `have/need/done`, pilares com nível/teto/reserva, pronto?), `grow_error/grow`,
   `deliver_growth_error/deliver_growth` (entrega parcial, consome, definitivo). Avaliação dos tipos de requisito
   da 02 C; contadores da fase pela diferença com `phase_stats` (gravados ao começar a fase).
   Requisito cumprido vai para `done` na hora em que é visto cumprido (nunca volta).
5. `grow()`: valida, grava `ceremonies[fase] = {at, seen: false}`, muda `phase`/`phase_since`,
   regrava `phase_stats`, aplica a reserva até o novo teto, paga `rewards` por `_grant_automatic("growth:<fase>")`,
   emite `Events.grew`. Idempotente.
6. Requisito `growth` no `GameState.requirement_error` ("Quando ele for Dentinhos"). Ainda **não** usado nos dados.
7. Eventos `grew`, `growth_ready`, `growth_requirement_done`, `pillar_gained` em `events.gd`
   (`pillar_gained` só é emitido a partir da 03).
8. **Reset (07 D):** `SAVE_VERSION` 13; save < 13 em qualquer slot recomeça do zero; `settings.json` fica;
   aviso carinhoso uma vez. Atualizar a regra do `CLAUDE.md`/`AGENTS.md` que dizia que o ramo de reset não se amplia.
9. DEV (aba "Crescimento" no `DevPanel`): `dev_set_phase`, `dev_add_pillar`, `dev_complete_growth_reqs`.
   Até a etapa 06 o crescimento só é visível pelo DEV (sem interface para o jogador).

## Teste da etapa — `growth_test.gd` (novo, ≤ 3 min)

Save novo começa `newborn`; requisito `given` já vem cumprido; "dar comida ×3" só conta comidas dadas **nesta
fase**; `done` não volta atrás mesmo se a condição deixar de valer; `grow_error` com motivo e depois `grow`
funciona; presente pago uma vez (inclusive recarregando); reserva entra no teto novo; `deliver_growth` parcial e
erro sem o item; recarregar no meio da fase mantém tudo; save de exemplo com versão 12 (em dois slots) recomeça
do zero no Recém-chegado e `settings.json` continua igual; requisito `growth` devolve o texto certo; `growth.json` quebrado de propósito é detectado.

Rodar também: `content_test`, `saves_test`, `economy_transactions_test`, `dev_tools_test` e `dev_tools_test -- --prod`.

## Para passar para a próxima

- [x] `growth_test` PASS e afetados PASS (tabela no registro).
- [x] Cópia do save atual do Vitor abre zerada no Recém-chegado, sem erro no console (o original não é tocado pelo teste).
- [x] Nada novo aparece para o jogador fora do DEV.

## Fora desta etapa

Ganhos de pilar (03), arte e telas, itens novos, missões.

## Evidência e passagem de bastão

Logs em `build/test_logs/tiro02/`. README, ROADMAP, `docs/PROGRESSION.md` (seção nova "Crescimento do Tiro"),
`CLAUDE.md`/`AGENTS.md` (linha "Crescimento do Tiro" no "Onde trabalhar" e `growth.json` na Estrutura). Sem push.

Registro e tabela de testes no README do plano (Etapa 02). O aviso de reset é a única novidade fora do DEV.
