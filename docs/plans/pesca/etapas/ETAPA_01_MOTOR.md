# Etapa 01 — Motor da pesca (regras, save, sorteios)

> Tamanho: grande. Depende de: 00 (aprovada). Próxima: 02.
> Resultado que o Vitor vê: nada novo na tela ainda (só o DEV). Por baixo, o jogo já sabe ter vara, ter isca,
> arremessar, sortear o peixe, gastar a isca na fisgada, medir o tamanho, guardar o peixe e o recorde.

## 1. Ler antes

- `README.md` do plano, `01_DESENHO.md` inteiro (principalmente §1, §6–§12).
- `CLAUDE.md` → "Regras de arquitetura" (estado só no GameState, ação devolve `""` ou o motivo, `*_error()`
  igual), parágrafo "Saves sempre zerados".
- Código de molde:
  - `game/scripts/state/find_state.gd` e `walk_state.gd` (classe de estado com `to_dict/from_dict/reset`).
  - `game/autoload/game_state.gd`: `_count(key, amount)` (l. ~74), `requirement_error` (l. ~2107),
    `storage_error(items, outgoing)` (l. ~1954), `_grant_automatic(id, rewards)` (l. ~1977),
    `tiro_animated()` (l. ~1016), `walking()` (l. ~324), `dog.sleeping`, `_gain_moment(pillar, source, capped)`
    (l. ~5097), `to_dict/from_dict` (l. ~5263), `_changed()` (l. ~5377), `harvest(index)` (semente fixa com
    `hash(...)`, l. ~1579).
  - `game/autoload/save_manager.gd` (`SAVE_VERSION` = 19 hoje).
  - `game/autoload/events.gd` (todos os sinais globais).
  - `game/scripts/fishing/fishing_sim.gd` (da etapa 00).

## 2. Como está hoje

Só o protótipo da 00 (`FishingSim`, `FishingGame` provisório, `fishing.json` com `physics/meter/motion/
proto_fish`). Nenhum item, nenhum save.

## 3. Passo a passo

1. **`fishing.json` completo** — acrescente as seções do `01_DESENHO.md` §12: `cast`, `bubbles`, `chest`,
   `classes`, `pity_large`, `levels`, `rods`, `baits`, `fish`, mais:
   - `rods`: `bamboo_rod {tier 1, bar_bonus 0, hold 0, bounce 0.45, baits [bait_worm]}`,
     `reel_rod {tier 2, 0.025, 0.15, 0.30, [bait_worm, bait_dough]}`,
     `angler_rod {tier 3, 0.05, 0.30, 0, [bait_worm, bait_dough, bait_lure]}`; cada uma com `name` e `icon`.
   - `baits`: `bait_worm {tier 1}`, `bait_dough {tier 2}`, `bait_lure {tier 3, keep_chance 0.7}`.
   - `fish`: as 9 espécies da tabela do §8 (campos `bait`, `cm [min,max]`, `motion`, `difficulty`,
     `weights [perto, meio, longe]`, `xp`, `fill_mult`, `drain_mult` opcionais). O `proto_fish` sai.
   - `story_guarantee`: `{"fish_tilapia": 3}` (no máximo na 3ª pesca com minhoca vem uma tilápia, enquanto
     nunca pegou nenhuma).
   - `moment_first`: `{"pillar": "brave", "source": "fish_first"}`.
2. **Itens em `items.json`** (ícones provisórios até a 03 — use um ícone existente e marque
   `"icon_todo": true`, que o `content_test` só aceita nesta etapa e a 03 remove):
   - 9 peixes `fish_<id>`: `category "product"`, `storage "fridge"`, `sell_price` da tabela, sem `feed`
     (peixe cru não se dá ao Tiro), `note` curta ("Peixe da lagoa. Vira papinha no fogão.").
   - 3 iscas `bait_worm/bait_dough/bait_lure`: `category "material"`, `storage "none"`, `sell_price 0`
     (não aparecem na venda), `note`.
   - As **varas não são item** (são posse, como ferramenta): vivem no `FishingState`.
3. **`game/scripts/state/fishing_state.gd`** (`class_name FishingState`, `extends RefCounted`):
   ```gdscript
   var rods: Array[String] = []          # varas possuídas, em ordem de chegada
   var rod: String = ""                  # vara escolhida ("" = a melhor)
   var bait: String = ""                 # última isca escolhida
   var xp: int = 0
   var records: Dictionary = {}          # fish_id -> {best_cm, best_class, count, gigantes, perfects, first_at}
   var cast: Dictionary = {}             # partida em andamento (ver item 5); {} = nenhuma
   var since_large: int = 0              # capturas seguidas sem Grande+ (garantia)
   var bait_casts: Dictionary = {}       # bait_id -> pescas com essa isca (garantia da história)
   var bubble: Dictionary = {}           # {"at": unix, "until": unix, "spot": i} ou {}
   var next_bubble_at: float = 0.0
   var tutorial: Dictionary = {"step": 0, "done": false}
   var seq: int = 0                      # contador de partidas (entra na semente)
   ```
   `to_dict/from_dict/reset`, consultas puras: `has_rod(id)`, `level(levels)`, `record(id)`.
   No `GameState`: `var fishing := FishingState.new()`, chave `"fishing"` em `to_dict/from_dict`, `reset`.
4. **`SAVE_VERSION` 19 → 20** em `save_manager.gd` (saves zerados, sem migração — regra do Vitor).
5. **Ações no `GameState`** (seção nova `# --- Pesca ---`). Todas devolvem `""` ou o motivo pronto para aviso,
   e têm o `*_error` igual:
   | Função | Valida | Faz |
   |---|---|---|
   | `fishing_info() -> Dictionary` | — | `{rod, rods, bait, baits: {id: qtd}, level, xp, next_xp, bar, cast_state, bubble}` (consulta pura) |
   | `fishing_error() -> String` | tem vara; Tiro não dormindo (`"Ele está dormindo"`); não passeando (`away_text`) | — |
   | `choose_rod(id)` / `choose_bait(id)` | posse / a vara aceita a isca | grava a escolha |
   | `cast_error(bait, zone, on_bubble)` / `cast(...)` | `fishing_error`; tem a isca (`"Sem minhoca"` usando `Database.item_name`); a vara aceita; nenhuma partida em andamento | cria `fishing.cast = {seed, bait, rod, zone, bubble, at: now(), wait, state: "waiting", fish: ""}`; `seed = hash("fish:%s:%s:%s" % [growth.taste_seed, fishing.seq, int(now()*1000)])`; `seq += 1`; espera sorteada de `cast.wait` (×`wait_mult` na bolha; tutorial: fixa 3 s). **Não gasta a isca.** Emite `Events.fishing_changed`. |
   | `bite_due() -> bool` | — | `cast.state == "waiting"` e `now() ≥ at + wait` |
   | `hook_error()` / `hook()` | partida esperando e mordeu; dentro da janela `bite_window` (sem limite no tutorial) | **gasta 1 isca** (isca artificial: só se `rng > keep_chance`; o sorteio usa a semente da partida); sorteia o peixe (item 6); `state = "fighting"`; `bait_casts[bait] += 1`; devolve `""` |
   | `miss_bite()` | — | mordida perdida/toque antes da hora: limpa `cast` sem gastar nada; conta `fish_miss` |
   | `finish_fishing_error(result)` / `finish_fishing(result)` | `state == "fighting"`; `result = {caught: bool, score: 0..1, perfect: bool, chest: bool}` com tipos e faixas válidos | ver item 7 |
   | `cancel_fishing()` | — | partida em qualquer estado: some **e devolve a isca se já tinha sido gasta** (fechar o app/trocar de aba no meio do minigame); não conta captura |
   | `fishing_bar_height() -> float` | — | `bar_base + bar_per_level·(nível−1) + vara.bar_bonus + (tiro_animated() ? animated_bonus : 0)`, limitado a `bar_max` |
6. **Sorteio do peixe (no `hook`)**: candidatos = `fish` cujo `bait` é a isca usada. Peso = `weights[zone−1]`
   (zona +1 na bolha, máx. 3). Ajustes, nesta ordem:
   a) **garantia da história**: se uma missão ativa pede `fish:<id>` desse grupo, o peixe pedido vale no mínimo
      50% do peso total (`ProgressionState.active_steps` + goals do tipo `stat` com chave `fish:<id>`);
   b) **`story_guarantee`**: nunca pegou tilápia e `bait_casts[bait_worm] ≥ 3 − 1` → tilápia certa;
   c) tutorial (`tutorial.done == false`): sempre `fish_lambari`.
   Sorteio com `Loot.pick_weighted(entries, seed)`. Grava `cast.fish`. O mesmo `seed` decide tudo; reabrir o
   app no meio não troca o peixe (e `cancel_fishing` devolve a isca).
7. **`finish_fishing(result)`**:
   - Escapou (`caught false`): conta `fish_escape`, `fish_escape:<id>`; limpa `cast`; emite
     `Events.fish_escaped(fish_id)`. A isca já foi.
   - Pegou: calcula o tamanho (01_DESENHO §9) com `sorte` = `rng` da semente; aplica perfeita (+1 classe) e a
     garantia `pity_large` (`since_large ≥ 8` → `f ≥ 0,70`); classe → `qtd` (Gigante 2).
     **Antes de mudar qualquer coisa**: `storage_error({fish_id: qtd})`. Se não couber, **não termina**: devolve
     `"Geladeira cheia"` (texto do `storage_error`), mantém a partida em `fighting` com o resultado guardado em
     `cast.pending_result`; a UI mostra "Liberar espaço" e `finish_fishing` pode ser chamado de novo depois. Se
     o jogador desistir, `release_fish()` solta o peixe (sem prêmio, isca gasta, conta `fish_release`).
   - Couber: `inventory.add`, XP de pesca (`fish.xp × classe.xp × (perfeita ? perfect_xp_mult : 1)`,
     arredondado), recorde (só sobe), contadores: `fish`, `fish:<id>`, `fish_size:<classe>`,
     `fish_size:<classe>:<id>` (**Grande soma também em `large` quando for Gigante**, para "Grande ou maior"),
     `fish_perfect`, `fish_gigante`; primeira vez da espécie: `_gain_moment("brave", "fish_first", false)`
     (registrar a fonte em `growth.json → moments.sources.fish_first {label "Pescar um peixe novo", pillar
     brave, qty 1, capped false, first true, go "place:farm:fishing"}`); baú (só vara 2+ e `result.chest`):
     sorteio de `chest.loot` por `_grant_automatic("fish_chest:%d" % seq, {...})`.
   - Emite `Events.fish_caught(fish_id, cm, classe, recorde_anterior_cm)` e, se subiu de nível,
     `Events.fishing_level_up(nível)`. Limpa `cast`. `_changed()`.
8. **Bolhas** (estado e tempo, sem tela ainda): `update_fishing_bubbles()` chamado no tick de 1 s que já existe
   no `GameState` (procure onde `return_due_walk` roda no tick): se não há bolha e `now() ≥ next_bubble_at`,
   cria `{at, until = at + lasts_min·60, spot = rng % pontos}` e marca o próximo em `every_min` sorteado; bolha
   vencida some. Só existe com vara. Funciona com o app fechado (ao carregar, aplica uma vez).
9. **Requisito `rod`**: em `GameState.requirement_error`, antes de `progress.requirement_error`:
   `if requirements.has("rod") and not fishing.has_rod(str(requirements.rod)): return "Ganhe a " + nome_da_vara`.
   E `give_rod(id)` interno (usado por recompensa de missão/loja/receita), que conta `rod:<id>`.
   Recompensa de missão: `_apply_rewards` aceita `"rods": ["bamboo_rod"]` (dá a vara uma vez).
10. **Sinais novos em `events.gd`**: `fishing_changed()`, `fish_caught(fish_id: String, cm: float,
    size_class: String, previous_cm: float)`, `fish_escaped(fish_id: String)`, `fishing_level_up(level: int)`,
    `fish_bite()` (emitido pelo tick quando `bite_due()` vira verdade, uma vez por partida).
11. **`Database.fishing_problems()`** (molde: `album_problems/growth_problems`): todo peixe tem item, isca
    existente e 3 pesos; toda isca é item; `cm[0] < cm[1]`; classes em ordem crescente; níveis crescentes;
    toda vara lista iscas existentes. Chamar no `content_test`.
12. **DEV** (`dev_panel.gd`, aba nova "Pesca", tudo com a guarda `if not BuildInfo.is_dev(): return` nas funções
    `dev_*` do GameState): `dev_give_rod(id)`, `dev_give_baits()` (+10 de cada), `dev_bubble_now()`,
    `dev_fish_xp(n)`, `dev_reset_fishing()`.

## 4. Não fazer

Tela de lagoa, tutorial, missões, receitas, loja (etapas 02–06). Não guardar o tamanho no item do inventário
(o peixe empilha normal; o tamanho fica só no recorde).

## 5. Armadilhas

- O minigame é ao vivo e roda na UI: o `GameState` **não** confia cegamente no resultado. Validar tipos e
  faixas (`score` 0–1, `perfect` só se `caught`), e só aceitar `finish_fishing` com `state == "fighting"`.
- Ordem de validação: espaço no depósito **antes** de gastar/entregar qualquer coisa (regra de toda a economia).
- `_count` é o único caminho dos contadores (o painel Ritmo e as missões dependem disso).
- A isca artificial "não gasta 70%": o sorteio precisa ser da semente, senão reabrir muda o resultado.

## 6. Testes

Novo **`game/tests/fishing_test.gd`** (área `fishing`, suite):
1. Sem vara: `fishing_error` e `cast_error` explicam; `requirement_error({"rod": "bamboo_rod"})` explica.
2. Com vara e sem isca: `cast_error` = "Sem minhoca"; com isca, `cast` cria a partida sem gastar.
3. `miss_bite` não gasta; `hook` gasta 1; `cancel_fishing` depois do hook devolve a isca.
4. Mesma semente → mesmo peixe e mesmo tamanho; reabrir (to_dict/from_dict no meio) mantém o peixe.
5. Isca de grupo errado para a vara → erro; vara 3 aceita as três.
6. Tamanho: `score 1 + perfeita` dá Gigante e 2 peixes; `score 0` dá Pequeno ou Médio; cm dentro da faixa e
   múltiplo de 0,5.
7. Garantia: 8 capturas Pequenas seguidas → a 9ª é Grande+.
8. Geladeira cheia: `finish_fishing` devolve o erro, nada muda, a partida continua; liberar espaço e chamar de
   novo entrega uma vez só; `release_fish` encerra sem prêmio.
9. Recorde só sobe; `records[id].count` soma por captura (Gigante conta 1 captura, 2 itens).
10. Contadores `fish`, `fish:<id>`, `fish_size:large` (também para Gigante), `fish_perfect`.
11. Primeira espécie dá 1 momento de Coragem; a segunda captura da mesma espécie não dá.
12. Tilápia garantida até a 3ª pesca com minhoca; tutorial sempre lambari.
13. Tiro dormindo/passeando: `fishing_error` explica.
14. Bolha nasce e some pelo relógio (com `GameState.now` injetado como nos testes de economia) e dá espera menor.
15. XP sobe e o nível muda a altura da barra; Tiro animado aumenta a barra.
16. `fishing_problems()` vazio no catálogo real.
Afetados: `content_test`, `saves_test`, `storage_test`, `dev_tools_test`, `fishing_physics_test`.
Rode: `tools/test.ps1 -Level etapa -Tests fishing_test -Areas fishing,storage`.

## 7. Pronto quando

Testes PASS, `content_test` sem `icon_todo` fora dos itens de pesca, `SAVE_VERSION` 20, registro no README do
plano, "Estado atual" do ROADMAP, linha da pesca no `CLAUDE.md`/`AGENTS.md` atualizada com os nomes novos
(`FishingState`, `GameState.cast/hook/finish_fishing/cancel_fishing`, sinais, requisito `rod`).

## 8. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 01 do plano "Pesca na lagoa da vovó".
Leia CLAUDE.md, docs/plans/pesca/README.md (incluindo o Registro da 00), 01_DESENHO.md e
docs/plans/pesca/etapas/ETAPA_01_MOTOR.md antes de editar. Siga o passo a passo, o "não fazer",
as armadilhas, os testes numerados e o critério de pronto. SAVE_VERSION sobe para 20 (saves
zerados, sem migração). Classe nova exige --import. Registre fishing_test em suite e na área fishing.
Ao terminar: Registro da 01 no README do plano, Estado atual do ROADMAP, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 02.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
