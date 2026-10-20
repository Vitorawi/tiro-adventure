# Etapa 16 — O jeito do Tiro e comportamentos por fase (PORTÃO)

**Estado: implementada; portão em validação (19/10/2026, Codex).** Executar somente esta etapa. Pré-requisito: etapa 15 concluída.

## Objetivo

"O Tiro filhote tropeça e cochila o tempo todo; o Dentinhos morde tudo; o Aventureiro dá corridas loucas; o
adulto senta com ar importante perto da turma. E ele tem um jeito: o meu é Explorador, porque eu passeio muito
com ele." O caderninho mostra um diário curto do que ele fez.

## Leitura obrigatória

[02](02_FASES_E_PILARES.md) A (comportamento); `pet_animator.gd` (`FIDGETS`, `REACTIONS`, `_pick_fidget`),
`dog_world.gd` (IA: destinos, soneca, `react_at`), `progress.stat` (contadores existentes).

## Entrega e implementação

1. **Jeito** (`growth.json → personality`): cinco jeitos com pesos por contador — Explorador (`walk`, `find`,
   mundos visitados), Comilão (comidas de crescimento diferentes, `feed`), Brincalhão (`play`, truques),
   Dengoso (`pet` útil, desejos), Tranquilo (soneca, banho). Jeito atual = maior pontuação relativa; pode mudar
   com o tempo (muda devagar: média dos últimos 14 dias de jogo + histórico). Revelado ao virar Aventureiro
   ("Novo!": "O jeito dele apareceu"). Mostrado no painel e no caderninho como título ("Tiro, o Explorador").
   Nunca bloqueia nada; nenhum jeito é pior.
2. **Comportamentos por fase e jeito** (dados em `growth.json → behaviors`, sem arte nova):
   - Tela do Tiro: pesos de `FIDGETS` por fase (filhote: `yawn`, `sleep` curto; Dentinhos: `scratch`/`lick_paw`
     como "mordiscar"; Aventureiro: `chase_tail`, `look_around`; adulto: `idle_breathe` longo, `head_tilt`) e por
     jeito (Explorador fareja mais, Brincalhão pula mais...).
   - Mundo (`DogWorld`): filhote cochila mais e às vezes para no meio do caminho (tropeço = pausa + pulinho);
     Aventureiro faz "corrida maluca" (sequência rápida de destinos próximos) de vez em quando; Mocinho/adulto
     preferem destinos perto de NPCs e estações em uso; adulto senta (`sit`) perto do jogador/personagens.
3. **Diário** "Hoje o Tiro...": até 20 linhas guardadas em `growth.diary` (fotos, primeiras provas, crescimento,
   passeios, achados raros), uma por evento importante, texto de uma linha montado a partir de modelos no dado.
   Seção no caderninho, aba Crescimento.
4. Nada disso muda necessidades, prêmios ou regras.

## Teste da etapa — `personality_test.gd` (novo, ≤ 3 min)

Contadores de exemplo levam ao jeito esperado; jeito só aparece a partir do Aventureiro; mudança lenta (um dia
diferente não troca o jeito); pesos de fidget por fase/jeito vêm do dado; diário grava eventos, limita a 20 e
não duplica ao recarregar.

Rodar também: `pet_care_test`, `world_life_test`, `manual_test`, `texts_test`, `growth_ui_test`.

## PORTÃO — passagem total

`tools/test_all.ps1` inteiro. Capturas das telas mudadas desde a 11 (bandeja de 5 cuidados, álbum, Casa, painel
com jeito, caderninho) nas **três resoluções**; abrir os PNGs.

## Para passar para a próxima

- [ ] Ver as 6 fases pelo DEV e notar comportamento diferente em cada uma (registrar o que se vê).
- [ ] Suíte inteira sem falha nova.

## Fora desta etapa

Pelagem de seda e simulador (17).

## Evidência e passagem de bastão

`build/test_logs/tiro16/` (suíte com tempos), capturas. README, ROADMAP, GAME_DESIGN (jeito), `CLAUDE.md`/`AGENTS.md`
(linha "Reações do Tiro no mundo"). Sem push.
