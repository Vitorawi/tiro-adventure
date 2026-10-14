# Etapa 10 — Truques (minijogo de um toque com a Nina)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_10_truques.md."
> Pré-requisito: Etapas 00–09 feitas.

## Objetivo (o que o jogador sente)
"Ensinei o Tiro a dar a pata! E agora ele faz truques quando eu peço." Reaproveita animações que já
existem no Tiro grande (`characters/tiro_pet/`): `give_paw`, `bark`, `roll_over`, `happy_jump`, `chase_tail`.
Regras mobile: um dedo, sem precisão fina, **sem falhar de verdade**.

## Como funciona (para o jogador)
1. Na Praça, lugar **Treino** (cantinho dos cones). A Nina ensina um truque por vez.
2. Painel do treino: Tiro grande no meio (mesmo `PetAnimator`), embaixo uma **barra horizontal** com um
   marcador indo e voltando e uma **zona verde**; botão grande **"Agora!"** (ou tocar em qualquer lugar).
3. Acertou → o Tiro faz o truque e acende um ponto (●●○). **3 acertos** = truque aprendido (festa
   "Novo truque!"). Errou → "Quase!" e tenta de novo, sem limite e sem custo.
4. Aprendido: a tela do Tiro ganha o botão **Truques** (ícone `trick_paw`): lista dos truques; tocar faz
   o Tiro executar (+3 felicidade, +1 afeto; recarga de 2 min por truque).

## Passo a passo

### 10.1 Dados (`progression.json → tricks`)
```json
"tricks": {
  "paw":  {"name": "Dá a pata", "icon": "trick_paw",  "animation": "give_paw",   "requirements": {"quests": ["nina_pipoca"]}, "zone": 0.25, "speed": 1.2},
  "talk": {"name": "Fala",      "icon": "trick_talk", "animation": "bark",       "requirements": {"bond": 2, "quests": ["nina_pipoca"]}, "zone": 0.25, "speed": 1.2},
  "roll": {"name": "Rola",      "icon": "trick_roll", "animation": "roll_over",  "requirements": {"bond": 3, "quests": ["nina_pipoca"]}, "zone": 0.22, "speed": 1.1},
  "jump": {"name": "Pula",      "icon": "trick_jump", "animation": "happy_jump", "requirements": {"bond": 4, "quests": ["nina_pipoca"]}, "zone": 0.20, "speed": 1.0},
  "spin": {"name": "Gira",      "icon": "trick_spin", "animation": "chase_tail", "requirements": {"bond": 5, "quests": ["nina_pipoca"]}, "zone": 0.18, "speed": 0.95}
}
```
`zone` = largura da zona verde (fração da barra); `speed` = segundos por ida do marcador.
Settings: `"trick_settings": {"hits": 3, "cooldown": 120, "perform": {"happiness": 3, "affection": 1}}`.

### 10.2 Estado e ações
- [ ] `progress.tricks = {"paw": true}` (salvo); recarga em `progress.cooldowns["trick:<id>"]`.
- [ ] `learn_trick_error(id)` / `learn_trick(id)` (o minijogo chama só no 3º acerto); contador `trick_learned`.
- [ ] `perform_trick_error(id)` / `perform_trick(id)`: aplica `perform`, contadores `trick`, `trick:<id>`.
- [ ] Bloqueado passeando/dormindo (mensagens já existentes).

### 10.3 Cena do minijogo — `scenes/ui/trick_training/trick_training.tscn` + `.gd`
- [ ] Aberta no Sheet pelo lugar Treino (`panel: "tricks"`): lista de truques (aprendidos ✓, próximo
  liberado com "Treinar", bloqueados com requisito em ícone) → "Treinar" abre o minijogo.
- [ ] Marcador animado por `Tween` em ping-pong (`speed` por ida); zona verde centralizada com
  pequena variação a cada tentativa; botão 64 px "Agora!"; contraste forte.
- [ ] Ao tocar: verifica a posição do marcador; mostra "Isso!"/"Quase!"; acerto toca a animação do truque.
- [ ] Testável: função `check_hit(marker: float) -> bool` pura e um modo de teste que força a posição.

### 10.4 Lugar, missões, desejo, diária
- [ ] `worlds.json → park.places.training`: `{"name": "Treino", "icon": "trick_paw", "description": "Truques com a Nina.",
  "panel": "tricks", "requirements": {"quests": ["nina_pipoca"]}}` + zona `training` em `rooms/park.json` (cantinho dos cones, etiqueta "Treino").
- [ ] Missões:
```json
"nina_trick": {"npc": "nina", "name": "Dá a pata!",
  "dialogue": "Vou te ensinar o 'dá a pata'. Toque na hora certa!",
  "goals": [{"type": "stat", "key": "trick_learned", "target": 1, "label": "Ensinar Dá a pata"}],
  "rewards": {"coins": 20, "affection": 5}, "kind": "line", "line": "nina", "order": 90},
"nina_roll": {"npc": "nina", "name": "Rola, Tiro!",
  "dialogue": "Ele confia em você. Agora o 'rola'!",
  "goals": [{"type": "stat", "key": "trick_learned", "target": 3, "label": "Aprender 3 truques"}],
  "rewards": {"coins": 40}, "kind": "line", "line": "nina", "order": 110}
```
- [ ] Desejo `trick`: `{"type": "action", "name": "Quero mostrar um truque", "icon": "trick_paw", "goal": {"key": "trick", "target": 1},
  "go": "screen:pet", "rewards": {"coins": 8, "affection": 6}, "weight": 2, "requirements": {"quests": ["nina_trick"]}}`.
- [ ] Diária `trick`: "Mostre 2 truques" (`trick` × 2, 10 moedas, `nina_trick`).
- [ ] `features.tricks`: `{"name": "Truques", "icon": "trick_paw", "go": {"screen": "pet"}, "requirements": {"quests": ["nina_trick"]}}`.

### 10.5 Arte — ícones 32×32 (receita)
| Arquivo | texto |
|---|---|
| `trick_paw.png` | "small dog paw raised in a high five with a tiny star" |
| `trick_talk.png` | "cartoon speech bubble with WOOF lines and a paw" (sem letras legíveis: "speech bubble with zigzag sound lines") |
| `trick_roll.png` | "curved circular arrow around a small paw print" |
| `trick_jump.png` | "paw print with upward motion lines" |
| `trick_spin.png` | "spiral swirl with a paw print in the center" |

## Testes — `tricks_test.gd` (novo)
- [ ] `check_hit` dentro/fora da zona; 3 acertos chamam `learn_trick` uma vez.
- [ ] Requisitos de vínculo; executar respeita recarga e dá felicidade/afeto; contadores.

## Lista de conferência (aceite)
- [ ] Aprender "Dá a pata" leva menos de 30 s e não frustra.
- [ ] Botão Truques aparece na tela do Tiro; roupas somem só nas animações acrobáticas (Etapa 08).
- [ ] CLAUDE.md/AGENTS.md, `docs/GAME_DESIGN.md` (seção Truques), ROADMAP, ART_PIPELINE, README; commit.
