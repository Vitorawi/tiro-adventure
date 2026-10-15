# Etapa 09 — Amigos do Tiro (cachorros da vizinhança)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_09_amigos.md."
> Pré-requisito: Etapas 00–08 feitas.

## Objetivo (o que o jogador sente)
"O Tiro tem amigos! Cada um gosta de um petisco; quando viram melhores amigos, vêm visitar a casa e
deixam presentes." Referências: Neko Atsume (visitas e presentes com o app fechado, silhuetas),
Pocket Camp (amizade por pedidos), Stardew (presentes favoritos).

## Como funciona (para o jogador)
1. Na Praça há sempre a **Pipoca** e **1 amigo visitante** que troca a cada **3 horas** (janela de horário local).
2. Cada amigo tem um **petisco preferido**. Tocar no amigo → cartão: retrato, nome, raça, **corações**
   (0–3), petisco preferido com `tem/precisa` e **Dar** (ou Ir/? se não tem). **Um petisco por amigo por janela.**
3. Corações: 1º petisco = ♥1, 3 petiscos = ♥2, 6 petiscos = ♥3 (**melhor amigo**). Cada coração dá um prêmio.
4. **Pipoca ♥2**: ela vai junto nos passeios → **+1 achado por passeio** (chip "Pipoca vai junto" no painel).
5. **Melhor amigo visita a casa**: a cada 8 h, se o jogador estiver fora do jogo, o amigo ♥3 "passou
   por lá" e deixou um presente. Aparece no cartão "Que bom que você voltou!" e, na Casa, o amigo fica
   brincando com o Tiro até o jogador tocar nele (toque = presente + aceno, ele vai embora).
6. Coleção → nova aba **Amigos**: silhuetas dos que ainda não conheceu; corações dos conhecidos.

## Passo a passo

### 9.1 Dados — `game/data/friends.json` (novo)
```json
{
  "settings": {"window_hours": 3, "hearts": [1, 3, 6], "visit_hours": 8, "visitors_per_window": 1},
  "friends": {
    "pipoca": {
      "name": "Pipoca", "breed": "Vira-lata caramelo", "always": true, "npc": "dog_pipoca",
      "sprite_dir": "res://assets/sprites/characters/dog_pipoca/",
      "portrait": "res://assets/sprites/characters/dog_pipoca/portrait.png", "icon": "friend_pipoca",
      "likes": "carrot_snack", "requirements": {"quests": ["nina_sewing"]},
      "heart_rewards": [{"coins": 10}, {"coins": 20, "items": {"dog_food": 3}}, {"coins": 30, "collections": ["caramel_bandana"]}],
      "visit_gift": {"coins": [8, 15], "loot": [{"weight": 1, "items": {"stick": 2}}, {"weight": 1, "items": {"ribbon": 1}}]},
      "walk_bonus": {"hearts": 2, "rolls": 1}
    },
    "mel": {
      "name": "Mel", "breed": "Poodle", "sprite_dir": "res://assets/sprites/characters/dog_mel/",
      "portrait": "res://assets/sprites/characters/dog_mel/portrait.png", "icon": "friend_mel",
      "likes": "strawberry_pop", "requirements": {"quests": ["nina_pipoca"], "owned": ["blender"]},
      "heart_rewards": [{"coins": 12}, {"coins": 25, "items": {"wildflower": 3}}, {"coins": 40, "items": {"ribbon": 3}}],
      "visit_gift": {"coins": [10, 18], "loot": [{"weight": 1, "items": {"wildflower": 2}}, {"weight": 1, "items": {"strawberry": 3}}]}
    },
    "bolota": {
      "name": "Bolota", "breed": "Pug", "sprite_dir": "res://assets/sprites/characters/dog_bolota/",
      "portrait": "res://assets/sprites/characters/dog_bolota/portrait.png", "icon": "friend_bolota",
      "likes": "mashed_potato", "requirements": {"quests": ["nina_pipoca"]},
      "heart_rewards": [{"coins": 12}, {"coins": 25, "items": {"color_button": 3}}, {"coins": 40, "items": {"yarn": 3}}],
      "visit_gift": {"coins": [10, 18], "loot": [{"weight": 1, "items": {"potato": 3}}, {"weight": 1, "items": {"color_button": 2}}]}
    },
    "fred": {
      "name": "Fred", "breed": "Beagle", "sprite_dir": "res://assets/sprites/characters/dog_fred/",
      "portrait": "res://assets/sprites/characters/dog_fred/portrait.png", "icon": "friend_fred",
      "likes": "sweet_potato_chips", "requirements": {"quests": ["bloblo_sweet_potato", "nina_pipoca"]},
      "heart_rewards": [{"coins": 15}, {"coins": 30, "items": {"bird_feather": 2}}, {"coins": 50, "items": {"bolt": 1}}],
      "visit_gift": {"coins": [12, 20], "loot": [{"weight": 1, "items": {"smooth_pebble": 2}}, {"weight": 1, "items": {"sweet_potato": 2}}]}
    }
  }
}
```
- [x] `collections.json → caramel_bandana` "Bandana caramelo" (neck, ícone `friend_pipoca`, com `overlay` se a arte da Etapa 08 permitir).

### 9.2 Estado — `game/scripts/state/friend_state.gd` (novo, `class_name FriendState`)
```
friends: Dictionary  # "<id>": {"gifts": int, "last_window": "", "claimed_hearts": int, "last_visit": 0.0, "visit_pending": false}
```
### 9.3 Ações no `GameState`
- [x] `friend_window() -> String` (`"2026-10-13-5"` = dia + bloco de 3 h, hora local).
- [x] `friends_present() -> Array[String]`: Pipoca (se liberada) + visitante sorteado de forma
  determinística por `hash(janela)` entre os liberados não-`always`.
- [x] `friend_hearts(id)` a partir de `gifts` e `settings.hearts`.
- [x] `give_friend_error(id)` (`"<Nome> não está na praça agora"`, `"Já ganhou petisco hoje"` (nesta janela),
  `"Falta <item>"`) e `give_friend(id)`: consome 1 item, `gifts += 1`, aplica `heart_rewards` novos,
  contadores `friend_gift`, `friend_gift:<id>`, e recalcula `friend_level` (soma dos corações de
  todos → grava no contador com `progress.stats["friend_level"] = soma`).
- [x] `update_friend_visits()` (ao carregar): para cada amigo ♥3 com `now - last_visit >= visit_hours*3600`
  e o app estava fechado → `visit_pending = true`, `last_visit = now`.
- [x] `collect_friend_visit(id)`: aplica `visit_gift` (`Loot`), `visit_pending = false`.
- [x] `walk_bonus`: em `collect_walk`, se Pipoca tem `hearts >= 2` → `rolls + 1`.
- [x] `available_actions()`: `friend` (amigo presente que aceita petisco e o jogador tem) e `friend_visit`.

### 9.4 Mapa e telas
- [x] A Pipoca deixa de ser `decor` quando `nina_pipoca` está ativa/concluída: tocar nela abre o cartão de amigo.
- [x] Visitante: `NpcWorld` com o `sprite_dir` do amigo no ponto `friend_1` (novo em `rooms/park.json → points`);
  aparece/sai quando a janela muda (o `RoomView` confere a cada minuto).
- [x] Balão sobre o amigo: ícone do petisco preferido se ele ainda aceita nesta janela.
- [x] Casa: `rooms/house.json → points.friend_visit`; amigo com visita pendente aparece lá brincando
  (anda perto do Tiro); toque → presente (CollectFx) e ele sai.
- [x] Lugar `friends` na Praça (`worlds.json → park.places.friends`, `panel: "friends"`,
  `requirements: {"quests": ["nina_pipoca"]}`): lista os amigos presentes (máx. 2 cartões).
- [x] Coleção → aba **Amigos**: todos os amigos (silhueta preta se nunca ganhou petisco), corações,
  petisco preferido, "Visita a casa" quando ♥3.
- [x] Cartão "Que bom que você voltou!": "Mel passou aqui e deixou um presente! [Ver]".

### 9.5 Missões, desejos, diárias, semanais
```json
"nina_pipoca": {"npc": "nina", "name": "Amiga da Pipoca",
  "dialogue": "A Pipoca é doida por petisco de cenoura. Dá um pra ela?",
  "goals": [{"type": "stat", "key": "friend_gift:pipoca", "target": 1, "label": "Dar petisco à Pipoca"}],
  "rewards": {"coins": 20}, "kind": "line", "line": "nina", "order": 80},
"nina_friends": {"npc": "nina", "name": "Turma da praça",
  "dialogue": "O Tiro já tem fama! Faça amizade com mais cachorros.",
  "goals": [{"type": "stat", "key": "friend_level", "target": 4, "label": "Somar 4 corações de amizade"}],
  "rewards": {"coins": 50, "affection": 10}, "kind": "line", "line": "nina", "order": 100}
```
- [x] `features.friends`: `{"name": "Amigos do Tiro", "icon": "friend_pipoca", "go": {"world": "park", "place": "friends"},
  "requirements": {"quests": ["nina_pipoca"]}}`.
- [x] Desejo `friend`: `{"type": "action", "name": "Saudade da Pipoca", "icon": "friend_pipoca", "goal": {"key": "friend_gift", "target": 1},
  "go": "place:park:friends", "rewards": {"coins": 10, "affection": 8}, "weight": 2, "requirements": {"quests": ["nina_pipoca"]}}`.
- [x] Diária `friend`: "Dê um petisco a um amigo" (`friend_gift` × 1, 12 moedas, `nina_pipoca`).
- [x] Semanal `pack_week`: "Turma da praça" (`friend_gift` × 7, 100 moedas, 2 fitas, `nina_pipoca`).

### 9.6 Arte (receita "Cachorro" do `01_REGRAS_E_ARTE.md`)
| Pasta | description do `create_character` |
|---|---|
| `characters/dog_mel/` | "white fluffy toy poodle with a pink bow, round puffy ears and pom-pom tail, small cute dog, same size as a yorkshire terrier puppy, pixel art" |
| `characters/dog_bolota/` | "chubby fawn pug with a black wrinkled face, curly tail and big round eyes, small cute dog, same size as a yorkshire terrier puppy, pixel art" |
| `characters/dog_fred/` | "tricolor beagle with long floppy brown ears, white muzzle and white-tipped tail, small cute dog, same size as a yorkshire terrier puppy, pixel art" |
Retratos 64×64 (receita) e ícones `friend_<id>.png` 32×32 ("game inventory icon: cute face of a <raça e cor>, bold outline, centered, no text")
para `pipoca`, `mel`, `bolota`, `fred`.

## Testes — `friends_test.gd` (novo)
- [x] Pipoca vira amiga quando `nina_sewing` foi recebida (o passo `nina_pipoca` fica ativo e dá para cumpri-lo); visitante estável na janela e muda na próxima.
- [x] Um petisco por amigo por janela; corações em 1/3/6 com prêmio uma vez; `friend_level` somado.
- [x] Visita ♥3 só após 8 h e uma vez; presente uma vez.
- [x] Pipoca ♥2 → passeio com +1 sorteio.
- [x] Save/carregar preserva tudo.

## Lista de conferência (aceite)
- [x] Dar petisco à Pipoca abre "Novo! Amigos do Tiro".
- [x] Visitantes trocam ao longo do dia; amigos ♥3 deixam presentes ao voltar.
- [x] CLAUDE.md/AGENTS.md (`friends.json`, `FriendState`, visitas), `docs/GAME_DESIGN.md`, ROADMAP, ART_PIPELINE, README; commit.

## Execução — 14/10/2026, Codex

Concluída e validada; detalhes e decisões no Estado atual do ROADMAP. Pipoca abre após
`nina_sewing`, sem ciclo com `nina_pipoca`. Bolota também exige `bloblo_potato`, requisito
real do purê. Sorteio/validação do bônus em `walk_loot`; visitas por ausência contínua e
atividade global entre slots, presente persistido. Bandana caramelo sem overlay (opcional
na 9.1), permanece na Coleção com Vestir desabilitado. Nenhum sistema da Etapa 10.
