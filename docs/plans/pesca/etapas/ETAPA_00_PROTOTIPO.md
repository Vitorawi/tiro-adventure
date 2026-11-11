# Etapa 00 — Protótipo do minigame (só a sensação)

> Tamanho: média. Depende de: nada. Próxima: 01. **Portão do Vitor no fim.**
> Resultado que o Vitor vê: uma tela de teste onde ele segura o dedo e a barra verde sobe, solta e ela cai,
> tentando manter um peixinho dentro dela enquanto a rede enche. Ele joga os cinco jeitos de peixe nadar,
> compara as duas opções de gravidade e diz "está bom" ou o que mudar.
> **Nada entra no jogo de verdade**: sem save, sem missão, sem item, sem mudar a lagoa.

## 1. Ler antes

- `docs/plans/pesca/README.md` (decisões e respostas do Vitor) e `01_DESENHO.md` §1–3, §5, §12.
- `CLAUDE.md` → "Regras de arquitetura", "Convenções", seção "Madeira ilustrada" e o parágrafo
  "Comemorações (ModalCard) em madeira" (só para saber o estilo; esta etapa usa peças provisórias).
- Código que serve de molde:
  - `game/scripts/util/loot.gd` (`Loot.pick_weighted(entries, seed)`, `Loot.amount`, `Loot.roll`): sorteios
    com semente. O movimento do peixe usa um `RandomNumberGenerator` com semente própria, no mesmo espírito.
  - `game/scenes/ui/trick_training/` (minijogo de truques: barra, zona verde, três acertos). É o minijogo
    que já existe; veja como ele recebe toque e como se monta/desmonta.
  - `game/scripts/ui/motion.gd` (`Motion.reduced`) e `game/scripts/ui/haptics.gd` (`Haptics.tap/success`).
  - `game/autoload/database.gd` linhas ~230–262 (`_init`, `_load("res://data/<arquivo>.json")`).

## 2. Como está hoje

Não existe nada de pesca. A lagoa do Sítio é só obstáculo (`rooms/farm.json → obstacles` ids `lake`,
`lake_rocks`, `lake_fence`), gerada por `tools/build_farm_island.py`. Não mexa nela nesta etapa.

## 3. Passo a passo

1. **`game/data/fishing.json`** — crie só com o que o protótipo usa:
   ```json
   {
     "schema": 1,
     "physics": {"bar_base": 0.169, "bar_per_level": 0.014, "bar_max": 0.34, "thrust": 2.11,
                 "gravity": 1.73, "drag": 1.8, "bounce": 0.45, "tick": 0.0166667,
                 "animated_bonus": 0.017, "gravity_on_hold": false},
     "meter": {"start": 0.30, "fill": 0.18, "drain": 0.12, "grace": 1.0, "perfect_xp_mult": 2.4},
     "motion": {"speed": [0.25, 1.2], "pause": [1.2, 0.3], "darter_bursts": 0.8, "biased": 0.75,
                "sinker_fall": 1.5, "floater_rise": 1.5},
     "proto_fish": {
       "mixed":   {"name": "Tilápia (teste)", "motion": "mixed",   "difficulty": 30},
       "smooth":  {"name": "Cará (teste)",    "motion": "smooth",  "difficulty": 22},
       "sinker":  {"name": "Carpa (teste)",   "motion": "sinker",  "difficulty": 40},
       "floater": {"name": "Lambari (teste)", "motion": "floater", "difficulty": 15},
       "darter":  {"name": "Tucunaré (teste)","motion": "darter",  "difficulty": 75}
     }
   }
   ```
   Em `database.gd`: `var fishing: Dictionary = {}` com comentário `## Pesca (data/fishing.json)…` e
   `fishing = _load("res://data/fishing.json")` no `_init`. `data/*.json` já entra no export
   (`export_presets.cfg → include_filter`), não precisa mexer lá.

2. **Motor puro do minigame — `game/scripts/fishing/fishing_sim.gd`** (`class_name FishingSim`,
   `extends RefCounted`). **Sem nó, sem desenho, sem `Time`**: só números. Assim o teste headless e a cena
   usam exatamente o mesmo código.
   - `func _init(config: Dictionary, fish: Dictionary, seed: int, bar_height: float)`.
   - Estado público: `bar_y`, `bar_v`, `bar_h`, `fish_y`, `meter`, `elapsed`, `inside_time`,
     `outside_time` (só depois de `grace`), `finished`, `caught`, `perfect`.
   - `func step(holding: bool, delta: float) -> void`: acumula `delta` e roda passos fixos de `tick`
     (máx. 10 passos por chamada, para não travar se o app engasgar). Em cada passo:
     a) barra: segurando `a = thrust − drag·v` (ou `thrust − gravity − drag·v` se `gravity_on_hold`);
        soltando `a = −gravity − drag·v`; `v += a·tick`; `y += v·tick`;
     b) fronteiras: `y ≤ 0` → `y = 0`, `v = −bounce·v` (e `v = 0` se `|v| < 0,02`, para não tremer);
        `y ≥ 1 − bar_h` → `y = 1 − bar_h`, `v = 0`;
     c) peixe: ver item 3;
     d) rede: `fish_y ∈ [bar_y, bar_y + bar_h]` → `meter += fill·tick`, `inside_time += tick`; senão
        `meter −= drain·(1 − hold)·tick` e, se `elapsed > grace`, `outside_time += tick`;
     e) `meter ≥ 1` → `finished = true, caught = true, perfect = outside_time == 0`;
        `meter ≤ 0` → `finished = true, caught = false`.
   - `func score() -> float`: `inside_time / max(elapsed − grace, tick)`, limitado a 0–1.
   - `hold` (γ da vara) vem de um parâmetro opcional `rod: Dictionary = {}` no `_init` (padrão 0).
3. **Peixe (dentro do `FishingSim`)**: estado `fish_y`, `fish_target`, `fish_speed`, `wait_left`.
   - Começa em `fish_y = 0,5`. Quando `wait_left ≤ 0` e chegou ao alvo (`|fish_y − alvo| < 0,01`), sorteia o
     próximo alvo e a pausa: `pausa = lerp(pause[0], pause[1], D/100) · (0,6 + 0,8·rng)`.
   - `velocidade = lerp(speed[0], speed[1], D/100)` pistas/s.
   - `mixed`: alvo uniforme em [0,05; 0,95]; aproxima com velocidade constante + ruído pequeno (seno de
     2 Hz, amplitude 0,01).
   - `smooth`: alvo a pelo menos 0,35 de distância; posição por curva em S (smoothstep) entre a origem e o
     alvo, duração = distância / velocidade.
   - `sinker`: com chance `biased` o alvo fica abaixo; descendo usa `velocidade·sinker_fall`, subindo
     `velocidade/sinker_fall`.
   - `floater`: espelho do sinker (`floater_rise`).
   - `darter`: como mixed; além disso, a cada passo, chance `darter_bursts·D/100·tick` de **arrancada**:
     novo alvo a 0,25–0,45 de distância e velocidade ×4 até chegar.
   - O peixe fica sempre em [0,02; 0,98].
4. **Cena de teste — `game/scenes/ui/fishing/fishing_game.tscn` + `fishing_game.gd`** (`class_name
   FishingGame`, `extends Control`, tela cheia). Nesta etapa é **provisória** (retângulos e um ícone
   qualquer; a arte vem na 03 e o visual final na 02):
   - pista vertical à direita (72 px de largura, altura = tela − 168 em cima − 100 embaixo, margem 16);
   - barra verde translúcida, peixe (use `UiKit.ui_icon("item_carrot")` ou um círculo, só para ver),
     rede = coluna ao lado da pista que enche de baixo para cima;
   - entrada: `_gui_input` + `_unhandled_input` tratam `InputEventMouseButton` e `InputEventScreenTouch`
     (o projeto emula mouse com toque); guarde quantos dedos estão apertados; segurando = algum dedo;
   - `_process(delta)` chama `sim.step(holding, delta)` e redesenha; ao terminar, mostra "Pegou!"/"Escapou"
     com tempo, pontuação e perfeita, e um botão "De novo".
   - Rótulo pequeno no canto com o perfil e a semente.
5. **Ferramenta de ajuste (só DEV, só nesta etapa)**: no topo da cena, uma fileira de botões
   `Proto_<perfil>` para trocar o peixe, `ProtoGravity` alterna `gravity_on_hold`, e `−`/`+` para `thrust`,
   `gravity`, `drag`, `fill`, `drain`, `bar_base` mostrando o valor. Os valores mudados **não** são salvos
   sozinhos: ao fim, imprimir no console o bloco JSON para colar no `fishing.json`.
6. **Abrir o protótipo**: `game/tests/fishing_proto.gd` (script `-s`, não é teste) que troca a cena principal
   por `fishing_game.tscn` com `-- --fish=<perfil> --seed=N`. E, no `DevPanel`
   (`scripts/ui/dev_panel.gd`), um botão "Pesca (protótipo)" que abre a cena por cima de tudo, para testar no
   celular pela versão dev.
7. **Toque real**: roteiro `game/tests/touch/fishing_proto.json` para `tools/touch_test.ps1`
   (abre pelo DEV, segura 1,2 s, solta 0,8 s, repete por 12 s, `perf_start/perf_stop`, `shot`).

## 4. Não fazer

Item, missão, save, mudança na lagoa, arte final, painel de madeira definitivo. Nenhum número fixo no
`fishing_sim.gd` além de limites de segurança (0,02/0,98, 10 passos).

## 5. Armadilhas

- Física por `delta` variável dá resultados diferentes em 30 e 120 fps: use **passo fixo acumulado**.
- `Engine.time_scale`/pausa da árvore: o protótipo não usa pausa da árvore.
- Toque e mouse chegam duplicados em alguns navegadores: conte por índice de dedo (`InputEventScreenTouch.index`)
  e ignore o mouse emulado se já houver toque.

## 6. Testes

Novo **`game/tests/fishing_physics_test.gd`** (headless, só `FishingSim`, área nova `fishing` em
`tools/test_areas.json`, também em `suite`):
1. Segurando por 1 s a partir do fundo, `bar_y` sobe; soltando, desce.
2. Velocidade terminal segurando ≈ `thrust/drag` (±5%) e soltando ≈ `gravity/drag` (±5%).
3. Na base, com velocidade de queda v, a velocidade logo após é `−bounce·v` (±2%); com `bounce 0`, para.
4. No topo a barra para (`v = 0`) e não passa de `1 − bar_h`.
5. Peixe parado dentro da barra (perfil de teste com `difficulty 0` e pausa infinita) enche a rede de 0,30 a
   1,0 em `0,70/fill` s (±1 tick) e termina `caught` e `perfect`.
6. Barra longe do peixe esvazia a rede em `0,30/drain` s e termina `caught = false`.
7. `hold = 0,30` faz a rede esvaziar 30% mais devagar.
8. Mesma semente + mesma sequência de toques → mesmo resultado, com `step` chamado em 1/30, 1/60 e 1/120.
9. Cada perfil: em 60 s simulados o peixe nunca sai de [0,02; 0,98]; `sinker` passa > 60% do tempo abaixo de
   0,5 e `floater` > 60% acima; `darter` faz ≥ 1 arrancada com D 75.
10. `gravity_on_hold = true` sobe mais devagar que `false` com os mesmos números.

Registre em `tools/test_areas.json`: `"fishing": {"paths": ["game/scripts/fishing/", "game/scenes/ui/fishing/",
"game/data/fishing.json", "game/tests/fishing_physics_test.gd"], "tests": ["fishing_physics_test"]}` e o nome
em `suite`. Rode: `tools/test.ps1 -Level etapa -Exact -Tests fishing_physics_test,content_test`.

## 7. Capturas

Sem `--headless`, `--resolution 360x780`, `390x844`, `412x915`: o protótipo no começo, no meio (rede ~60%),
"Pegou!" e "Escapou". Em `build/screenshots/fishing_proto/`. Abrir e conferir que a pista não fica sob o HUD
nem sob as abas.

## 8. Pronto quando

Testes PASS; o Vitor jogou os cinco perfis (no Godot ou na dev pelo DEV → "Pesca (protótipo)") e aprovou;
os números aprovados estão no `fishing.json`; escolhida a opção de gravidade **mais fácil de controlar**
(decisão do Vitor) e anotada no README do plano ("Registro da 00"). Atualizar "Estado atual" do ROADMAP.

## 9. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

Execute SOMENTE a ETAPA 00 do plano "Pesca na lagoa da vovó".
Leia CLAUDE.md (ou AGENTS.md), docs/plans/pesca/README.md, 01_DESENHO.md e
docs/plans/pesca/etapas/ETAPA_00_PROTOTIPO.md antes de editar. Siga o passo a passo,
o "não fazer", os testes numerados e o critério de pronto.
Classe nova exige `godot --headless --path game --import`. Registre o teste novo em
suite e na área fishing de tools/test_areas.json. Capturas SEM --headless nas três
resoluções, PNGs abertos e conferidos. Não mexa na lagoa nem em save/missões.
Preserve alterações locais de outros agentes.
Ao terminar: "Registro da 00" no README do plano, Estado atual do ROADMAP,
CLAUDE.md e AGENTS.md iguais. Resumo curto, testes, capturas e o que o Vitor precisa
jogar para aprovar. Sem commit, push ou publicação. Não executar a 01.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
