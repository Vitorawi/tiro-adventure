# Etapa 03 — Desempenho do mundo e orçamento de atenção

> Tamanho: grande. Depende de: 02. Próxima: 04.
> Itens da revisão: **4** (engasgos no Sítio: 28,3 ms de média, picos de 150 ms) e **23** (só um balão
> pulando por tela).
> Resultado que o Vitor vê: arrastar o Sítio e plantar ficam lisos, sem o tranco a cada ~125 ms; só o
> balão mais importante pula, os outros prontos ficam verdes e parados.

## 1. Objetivo
Tirar do tique de 8 Hz tudo o que não anima, parar o redesenho de balões e do alfinete parados, guardar o
brilho do álbum em cache e aquecer os glifos das fontes. **Medir antes e depois** com o mesmo roteiro.
Sem mudar nenhuma regra: o que aparece na tela tem de ser o mesmo, só calculado menos vezes.

## 2. Ler antes
`REVISAO_OPUS.md` item 4 (diagnóstico completo) e 23; `docs/plans/interface2/RESULTADOS.md` (medição da 12);
o registro da etapa 01 deste plano (números da linha de base).

## 3. Arquivos
| Arquivo | O quê |
|---|---|
| `game/scenes/levels/room/room.gd` | `_animate_objects` (linha ~464), `_place_labels` (~720), `_layout_balloons` (~850), `_update_plot` |
| `game/autoload/game_state.gd` | `album_hint_glow(object)` (~4304) |
| `game/scripts/ui/world_balloon.gd` | `_process` + `queue_redraw` (linhas ~34/52), legenda com `UiKit.surface` |
| `game/scripts/ui/world_pin.gd` | `_process` + `queue_redraw` (~17), balanço |
| `game/scripts/ui/plot_indicator.gd`, `station_indicator.gd` | `refresh` |
| `game/scenes/main/main.gd` | aquecimento de glifos na carga |

## 4. Como está hoje (estado esperado ao começar)
- `_animate_objects` roda a **8 Hz** e, para **todos** os ~28 objetos do Sítio: `GameState.album_hint_glow(id)`
  (percorre 54 fotos, monta dicionário, chama `AlbumRules.holds`: ~1.500 iterações por tique); por canteiro
  `plot_status`, `plot_progress`, `water_error`, `PlotIndicator.refresh`; por estação `ready_count`,
  `StationIndicator.refresh`.
- `_place_labels()` recalcula `requirement_error` de etiquetas e regiões e os brilhos.
- `_layout_balloons()` faz `get_nodes_in_group` na árvore só para zerar `draw_offset` (que já é sempre zero)
  e chama `queue_redraw` em cada balão.
- Todo `WorldBalloon` e o `WorldPin` chamam `queue_redraw()` em **todo quadro**, mesmo parados (arcos de
  48 segmentos); a legenda cria um `StyleBox` novo a cada desenho.
- Picos de ~150 ms também na roleta e na folha: provável primeira rasterização de glifos da Fredoka/Nunito
  variáveis em tamanhos novos, ou compilação de shader (renderer Compatibility).
- Linha de base: os números anotados na etapa 01.

## 5. Passo a passo
1. **Medir antes no desktop:** profiler do Godot (Monitors + Profiler) na cena do Sítio com balões; anote
   as 5 funções mais caras por quadro. Junte ao número Web da etapa 01.
2. **Brilho do álbum em cache:** no `GameState`, `album_hint_glow_map(world) -> Dictionary` calculado uma vez
   por `state_changed` (ou no máximo 1×/s) e guardado; `album_hint_glow(object)` passa a consultar o
   dicionário. O resultado tem de ser idêntico: `album_secrets_test` confere.
3. **Dividir `_animate_objects`:** a 8 Hz fica só o que anima (`busy_frames`, `idle_offset`, piscar, pulinho);
   indicadores de canteiro/estação, etiquetas e regiões passam a 1 Hz **e** a `state_changed` (o que vier
   primeiro). O anel de progresso pode seguir a 8 Hz **só** para balões em `progress` visíveis na tela.
4. **Apagar `_layout_balloons()`** (sem efeito) e as `requirement_error` das regiões no tique (passam a
   `state_changed`).
5. **Balões e alfinete sem redesenho parado:** `WorldBalloon` redesenha só quando `state`, `progress`
   (arredondado a 1/48), zoom ou legenda mudam, ou durante o pulinho; `WorldPin` idem, e o balanço vira
   tween de posição num nó filho. `StyleBox` da legenda em cache (estático por cor/canto).
6. **Um balão pulando por tela (item 23):** a sala escolhe **um** balão `ready` para pular (o da missão
   ativa; senão o mais antigo pronto); os demais `ready` ficam verdes e parados. Se ficar sem graça,
   rodízio de 4 s entre os prontos visíveis. Com `Motion.reduced`, nenhum pula (como hoje).
7. **Aquecer glifos:** na carga (`main.gd`), um `Label` fora da tela com o alfabeto + acentos + dígitos em
   cada variação do tema (12/15/18/24/26 e Texto maior se ligado), por 2–3 quadros, depois removido. Meça se
   os picos da roleta/folha somem; se não somem, investigue shader (anote, não insista além de 1 h).
8. **Medir depois:** mesmo roteiro, mesmo export. Meta: média ≤ 20 ms e **sem padrão periódico** acima de
   33 ms. Se a meta não for atingida, registre os números e o que ainda pesa (profiler), sem esconder.

### 5.1 Armadilhas
- Não troque timestamps por contadores de quadro: timers do jogo são Unix (regra de arquitetura).
- `balloon_test` confere estados e pulinho: o balão escolhido tem de pular; os outros, não.
- `world_view_test`/`world_life_test` dependem de etiquetas/brilhos aparecerem após `state_changed`: emita
  o recálculo nessa hora, não espere o próximo segundo.
- Não mude `Motion.WORLD_BOUNCE` nem o visual dos balões.

## 6. Testes
- Lista: `balloon_test,world_view_test,world_life_test,album_secrets_test,tray_test,farm_dock_test,effects_layer_test,garden_test`
  (~4 min 05). `tools\test.ps1 -Level etapa -Exact -Tests <lista>` (`-DryRun` antes).

## 7. Capturas
Bloco `--aj-03-only`: `i2_07_dock_plant`, Sítio com vários prontos (crie `aj_03_farm_ready`, ≥ 3 canteiros e
1 estação prontos), `i2_06_pin` (alfinete) e a Natureza com rotas prontas. Antes e depois nas 3 resoluções.
As imagens devem ser **iguais** às de antes, exceto pelos balões que deixaram de pular (posição do pulo).

## 8. Pronto quando
- [ ] Números antes × depois no registro (Web: média, p95, > 33 ms, pico; profiler desktop: top 5).
- [ ] Média ≤ 20 ms e sem padrão de 8 Hz — ou, se não atingido, causa restante medida e anotada.
- [ ] Só um balão pulando por sala; `Motion.reduced` sem pulo.
- [ ] Capturas iguais às de antes (salvo o pulo).
- [ ] Testes verdes.

## 9. Handoff
Pontos naturais: após cada passo 2–7. Sempre diga o último número medido e com qual export (hash do commit
ou "árvore suja"). Se parar após o passo 3, diga quais chamadas saíram do tique e para onde foram.

## 10. Registro
```
**Etapa 03 (data, executor[es]):** Sítio Web antes … ms (p95 …, … > 33 ms) → depois … ms (p95 …, …);
profiler: … ; brilho do álbum em cache por state_changed; tique de 8 Hz só anima; _layout_balloons removida;
balões/alfinete redesenham só quando mudam; um balão pulando por sala; glifos aquecidos (picos … → …).
Testes … PASS em … s. Pendências: … Sem push.
```
