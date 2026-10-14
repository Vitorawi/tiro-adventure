# Etapa 00 — Fundação (save zerado e peças do motor)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_00_fundacao.md."

## Objetivo
Deixar o motor pronto para as etapas seguintes **sem mudar nada que o jogador veja**: save novo
zerado, contadores que faltam, tipos de requisito e de recompensa novos, ordens das missões com folga
para inserir passos, consulta "o que dá para fazer agora" e a ferramenta "Ritmo" para o Vitor medir
a primeira hora.

## Leia antes
- `game/autoload/save_manager.gd` (`SAVE_VERSION`, `_migrate`)
- `game/autoload/game_state.gd` (`feed`, `pet`, `play`, `bathe`, `_apply_rewards`, `requirement_error`)
- `game/scripts/state/progression_state.gd` (`count`, `stat`, `requirement_error`, `to_dict/from_dict`)
- `game/scripts/ui/dev_panel.gd`
- `game/data/quests.json`

## Passo a passo

### 0.1 Save v12 zerado
- [ ] `save_manager.gd`: `SAVE_VERSION := 12`.
- [ ] Em `_migrate`, trocar a regra do v11 por:
```gdscript
	if version < 12:
		# v12: começo refeito (plano docs/plans/comeco). Combinado com o Vitor em 13/10/2026:
		# o progresso anterior é descartado e o jogo recomeça do zero.
		return {"save_version": SAVE_VERSION, "state": {}}
```
- [ ] Vale para todos os slots (o `_migrate` roda em cada arquivo carregado). Confira no `saves_test`.

### 0.2 Ordens das missões com folga (×10)
- [ ] Em `game/data/quests.json`, multiplique **todo** campo `"order"` por 10 (main e linhas).
  Ex.: `welcome` 1 → 10, `lais_feed` 2 → 20, `bloblo_meet` 1 → 10, `main_9_coop` 8 → 80.
- [ ] Nada mais muda: o código só **ordena** por `order` (`progression_state.gd`, linhas ~206 e ~242).
  Procure nos testes (`game/tests/*.gd`) qualquer uso de número de `order` e ajuste.
- Motivo: as próximas etapas inserem passos no meio (ex.: `order` 25) sem renumerar tudo.

### 0.3 Contadores que faltam
- [ ] `GameState.pet()`: adicionar `progress.count("pet")`.
- [ ] `GameState.feed(item_id)`: adicionar `progress.count("feed:" + item_id)` logo depois do `count("feed")`.

### 0.4 Requisitos novos (`ProgressionState.requirement_error`)
- [ ] `"stats": {"walk": 5}` → se `stat(key) < alvo`: devolve `"Faça mais %d %s" % [faltam, rótulo]`.
  Rótulos em `progression.json → settings.stat_labels` (novo):
```json
"stat_labels": {
  "walk": "passeios", "find": "achados", "wish": "desejos", "harvest": "colheitas",
  "water": "regas", "friend_gift": "petiscos a amigos", "trick": "truques"
}
```
  Chave sem rótulo usa a própria chave.
- [ ] `"bond": 3` → se o nível de vínculo for menor: `"Vínculo %d"`. **O vínculo só existe na Etapa 03**;
  agora crie a função `ProgressionState.bond_level(affection: int) -> int` lendo
  `progression.json → bond_levels` (crie a lista já agora, com os valores da Etapa 03, seção 3.4),
  e o `requirement_error` recebe o afeto pelo `GameState` (passe `GameState.dog.affection` ou mova a
  checagem do `bond` para `GameState.requirement_error`, que já embrulha a do `progress`). Escolha o
  jeito mais limpo e explique no comentário.
- [ ] `"hours": [17, 21]` → disponível só se a hora local estiver em `[início, fim)`. Mensagem:
  `"Só das %dh às %dh"`. Use a mesma hora local das diárias (`GameState._local_time`).
- [ ] `content_test.gd`: aceitar essas chaves como válidas.

### 0.5 Recompensas novas (`GameState._apply_rewards`)
- [ ] `"affection": N` → `dog.affection += N`.
- [ ] `"needs": {"happiness": 20, "energy": -8}` → `dog.apply(rewards.needs, now())`.
- [ ] `"collections"` e `"unlocks"` já existem: não mexer.
- [ ] `ProgressionUi.reward_chips` mostra `affection` com o ícone `need_happiness` provisório (a Etapa
  03 troca por `bond_heart`).

### 0.6 Quantidades com faixa (sorteio)
Várias tabelas futuras usam `[min, max]` em vez de número. Crie **agora** um ajudante puro:
- [ ] `game/scripts/util/loot.gd` (`class_name Loot`):
  - `static func pick_weighted(entries: Array, seed: int) -> Dictionary` (campo `weight`, padrão 1);
  - `static func amount(value: Variant, seed: int) -> int` (número → ele mesmo; `[a, b]` → sorteio entre a e b);
  - `static func roll(entries: Array, rolls: int, seed: int) -> Dictionary` → `{"coins": int, "items": {id: qtd}}`
    somando os sorteios (cada entrada pode ter `coins` e/ou `items`).
  - Determinístico: use `RandomNumberGenerator` com `seed` (mesma semente = mesmo resultado).
- [ ] Teste rápido dentro de `content_test` ou um `loot_test.gd` novo: mesma semente = mesmo resultado;
  pesos respeitados em 1000 sorteios (tolerância larga).

### 0.7 "O que dá para fazer agora"
- [ ] `GameState.available_actions() -> Array[Dictionary]` (consulta pura, sem alterar estado).
  Cada item: `{"kind": String, "world": String, "target": String}` (`target` = alvo do Ir, igual ao
  usado por `Places.goal_target`/`RoomView.point_at`). Tipos desta etapa:
  - `plant` (canteiro vazio acessível + alguma cultura liberada), `harvest` (canteiro pronto),
  - `cook` (estação comprada com espaço livre e alguma receita possível com o estoque),
  - `collect` (estação/criação com lote pronto), `gather` / `gather_ready` (natureza),
  - `quest_ready` (missão pronta para receber), `routine_ready` (diária/semanal pronta),
  - `care` (alguma necessidade do Tiro < 60).
  Cada etapa futura acrescenta o seu tipo (regar, desejo, achado, passeio, amigo).
- [ ] Uso: teste "nunca só esperar" (Etapa 01), cartão "enquanto você estava fora" (Etapa 01) e dica parada.

### 0.8 "Ritmo" (linha do tempo das primeiras vezes) — só na versão dev
- [ ] `ProgressionState`: `started_at: float` (gravado no novo jogo) e `firsts: Dictionary` (chave → timestamp).
  Salvar em `to_dict`/`from_dict`.
- [ ] Quando um contador passa de 0 para 1, gravar `firsts[chave] = agora`. Como `count()` não conhece
  o tempo, faça no `GameState` um embrulho `_count(key, amount := 1)` que chama `progress.count` e grava
  o primeiro horário; troque as chamadas `progress.count(...)` do `GameState` por `_count(...)`.
- [ ] `DevPanel`: seção **"Ritmo"** com a lista ordenada `mm:ss  chave` (minutos desde `started_at`),
  e um botão "Copiar" que põe o texto na área de transferência (`DisplayServer.clipboard_set`).

## Testes
- [ ] Suíte inteira verde (`tools/test_all.ps1`), incluindo `dev_tools_test` com `-- --prod`.
- [ ] `saves_test`: arquivo v11 carregado vira jogo novo (v12) sem erro.
- [ ] Teste dos requisitos `stats`, `hours` e da recompensa `affection` (pode ficar em `progression_test`).

## Lista de conferência (aceite)
- [ ] Jogo abre do zero (chegada da Laís) mesmo com save antigo.
- [ ] Nada mudou visualmente.
- [ ] DevPanel mostra "Ritmo" com `talk:lais`, `feed`, `bathe`, `play` depois do capítulo 1.
- [ ] ROADMAP atualizado; README da pasta marcado; commit `feat: fundação do novo começo (save v12)`.

## Armadilhas
- Não esqueça de trocar **todas** as chamadas `progress.count` do `GameState` pelo `_count`
  (inclusive `talk_to`, `note_screen_opened`, `claim_quest`, `claim_routine`).
- `_migrate` também é usado pelo resumo dos slots (`SaveManager.list_slots`): confira que um slot v11
  aparece como "novo" e não quebra a lista.
