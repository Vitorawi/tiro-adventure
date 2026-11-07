# Etapa 01 — Regras da carta (motor)

> Tamanho: médio. Depende de: nada (revisa a "etapa 1 antiga"). Próxima: 02.
> Resultado que o Vitor vê: nada novo na tela ainda. O motor passa a ter carta fechada, abrir, tentar a sorte
> (moedas), melhorar (materiais), varal de 3 e o tutorial com resultados forçados. As telas atuais continuam
> funcionando (abrem a foto como antes).

## 1. Ler antes
`01_DESENHO.md` §1–§9 inteiras. `02_REGRAS_E_TESTES.md` §1 e §4. Código: `game/autoload/game_state.gd`
(procure `_album_event`, `_take_photo`, `photo_info`, `reroll_photo`, `photo_can_retake`, `set_photo_variant`,
`dev_take_photo`, `photo_alerts_enabled`, `_grant_automatic`, `transaction_error`), `scripts/state/album_state.gd`,
`game/data/album.json` (bloco `rarity`), `game/autoload/events.gd`, `tests/photo_rarity_test.gd`.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Sorteio | `GameState._take_photo` → sorteia já ao tirar | muda: tirar cria carta **fechada** |
| Dados | `album.json → rarity` (`levels`, `pity`, `section_weights`, `repeat_cooldown_hours`, `reroll` com cristal/madeira dura) | vira `cards` (§3.1) |
| Retomada | `_album_event` chama retomada para foto `repeatable` fora da recarga | passa a somar `sealed` |
| Revelar de novo | `reroll_photo` cobra moedas + cristal + madeira dura | vira só moedas |
| Melhorar | não existe | novo |
| Varal / tutorial | não existem (`album.wall`/`main_photo` são da Casa do mapa e ficam) | novo |
| Save | `SAVE_VERSION` 18 | sobe para 19 |

## 3. Passo a passo

### 3.1 Dados (`album.json`)
1. Renomeie o bloco `rarity` para **`cards`** e deixe-o assim (mantenha os valores já aprovados):
   `levels` (nível, nome, peso, `art`: `common`/`shiny`/`rare`/`holographic`), `pity`, `section_weights`,
   `repeat_cooldown_hours`, `reroll {coins: 40, coins_step: 20, coins_max: 160}`, `upgrade {"2": {coins: 30,
   items: {wood: 4, stone: 3}}, "3": {coins: 80, items: {plank: 3, copper: 2, fiber: 4}}, "4": {coins: 180,
   items: {crystal: 3, hardwood: 3, fabric: 2}}}`, `featured_slots: 3`, `rewards` (§7 do desenho),
   `tutorial {photo: "h_arrival", forced: [1, 2, 3]}`.
2. Atualize `Database` se houver leitura do bloco antigo (procure `rarity` em `database.gd`/`game_state.gd`).
   O conteúdo do JSON mantém 2 espaços; **não** reescreva o arquivo inteiro com outra formatação (edite só o
   bloco), para não sujar o diff.

### 3.2 Estado (`album_state.gd`)
1. Campos por foto: `sealed` (int), `upgrades` (int), `opened_at` (float) — com `from_dict` tolerante.
2. Globais: `featured: Array[String]`, `tutorial: Dictionary` (`{"step": 0, "done": false}`); `to_dict`,
   `from_dict`, `reset`.
3. `SAVE_VERSION` 19 em `save_manager.gd` (sem migração).

### 3.3 Regras (`game_state.gd`)
1. `_take_photo(id)`: cria a entrada com `sealed = 1`, sem nível; emite `photo_taken` como hoje.
2. Retomada natural: em vez de sortear, `sealed += 1` e `Events.photo_sealed(id)` (sinal novo em `events.gd`).
3. Ações novas (cada uma com `*_error` igual, devolvendo texto pronto):
   - `open_photo_card(id)` — consome 1 `sealed`, sorteia (§3 do desenho), define `opened_at` na primeira vez.
   - `reroll_photo(id)` — só moedas, custo por `reroll_cost(id)`; erro se fechada, se tem as 4 ou se faltam
     moedas.
   - `upgrade_photo(id)` — nível `rarity + 1`, custo `upgrade_cost(id)` (moedas + itens do nível de destino);
     erro se fechada, se já é 4, se falta algo (mensagem com o item que falta).
   - `feature_photo(id)` / `unfeature_photo(id)` / `featured_photos()`.
4. Consultas: `photo_sealed(id) -> int`, `sealed_photos() -> Array[String]`, `upgrade_cost(id) -> Dictionary`,
   `reroll_cost(id) -> Dictionary` (formato `{coins, items}`), `photo_rarity(id)` = 0 se nunca aberta.
5. O sinal `photo_rolled` ganha `kind` (`"open"`, `"reroll"`, `"upgrade"`, `"tutorial"`).
6. Tutorial: `album_tutorial_step()`, `advance_album_tutorial(step)`, `finish_album_tutorial()` e um caminho
   interno `_tutorial_override` que, no passo certo, força o nível de `cards.tutorial.forced` e **não cobra**
   nem mexe nas garantias. Ninguém fora do tutorial consegue forçar nível (só `dev_*`).
7. Contadores (`_count`): `photo_opens`, `photo_rerolls`, `photo_upgrades`, `photo_holo` (ao ganhar nível 4).
8. `photo_info(id)` acrescenta `sealed`, `opened`, `variants`, `shown_rarity`.
9. DEV (guarda `BuildInfo.is_dev()`): `dev_take_photo(id, rarity := 0)` passa a criar e abrir; novo
   `dev_seal_photo(id)`; `dev_reset_album_tutorial()`.
10. Tela atual (enquanto as etapas 04–06 não chegam): onde hoje se abre o detalhe da foto
    (`AlbumView.open_photo`), se a foto estiver fechada chame `open_photo_card` antes, para nada quebrar.

## 4. Não fazer
- Interface nova (revelação, carta 3D, álbum): são as etapas 04–06.
- Mudar `on`/`when` das fotos, ids, ou as regras de quando uma foto acontece.
- Dar itens de verdade no tutorial (o desenho pede custo zero, não presente no inventário).

## 5. Armadilhas
- `photo_alerts_enabled()` depende de foto `seen`/`open:album`: carta fechada continua contando como "tem a foto"
  para as regras de requisitos (`album.has_photo`). Confira que missões/condições que usam "tem foto" não mudam.
- Garantias contam só sorteios (abrir/rolar), nunca Melhorar nem tutorial.
- `transaction_error` precisa receber as moedas e os itens juntos para a mensagem certa.

## 6. Testes
Atualize **`tests/photo_rarity_test.gd`** (área `album`):
1. Tirar foto nova → `sealed 1`, `photo_rarity 0`, sem sorteio; `photo_taken` uma vez.
2. `open_photo_card` → `sealed 0`, nível ∈ 1..4, `photo_rolled` com `kind "open"`, `new_photo true`.
3. Pesos (6000 sorteios com semente) dentro de ±6%; tabela da História idem.
4. Garantias 10/30 por abrir e rolar; Melhorar não mexe nelas.
5. Tentar a sorte: só moedas; custo 40, 60, ..., teto 160; erro sem moedas não consome; versão entra.
6. Melhorar: sobe exatamente +1; custo do nível de destino; erro com o item que falta e nada consumido; no 4
   dá erro.
7. Retomada natural de foto repetível: `sealed +1`, recarga de 20 h respeitada, foto da História nunca retoma.
8. Varal: no máximo 3; foto fechada não entra; tirar e trocar.
9. Tutorial: passos forçam 1 → 2 → 3, custo zero, garantias intactas; fora do tutorial nada é forçado.
10. Save ida e volta: `sealed`, `variants`, `shown`, `featured`, `tutorial`, garantias e semente.
Lista fechada: `photo_rarity_test,album_test,album_secrets_test,house_test`.

## 7. Pronto quando
Os 10 itens passam, a lista fechada passa, `album.json` só mudou no bloco `cards`, nenhuma tela quebrou (abrir
uma foto pelo caderninho ainda funciona) e o registro do README/AGENTS/CLAUDE/ROADMAP foi atualizado.
