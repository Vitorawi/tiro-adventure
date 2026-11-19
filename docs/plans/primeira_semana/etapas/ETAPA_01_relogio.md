# E01. Relógio do Tiro (tamanho G, dividida em três partes)

**Entrega:** a rotina diária funciona de ponta a ponta. Regras em `REGRAS.md` (D2, D3, ajuste 9).

## Divisão
| Parte | Conteúdo | Situação |
|---|---|---|
| **E01a** | Estado do dia (`WeekState`), janelas de almoço/jantar, opções Mais cedo/Normal/Mais tarde, refeição na hora, dia bem alimentado, patinha, regra do dia da chegada, o dia só avança, `SAVE_VERSION` 21, gancho DEV `dev_week_meal` | Concluída (18/11/2026) |
| **E01b** | Fechamento do dia: dia fraco (não conta, Tiro fraquinho até a próxima refeição na hora), ração sozinho quando a janela fecha, marmita da vovó após 2 dias fracos seguidos, **Deixar pronto** (refeição guardada, o Tiro come ao abrir a janela, inclusive com o jogo fechado) | Concluída (18/11/2026) |
| **E01c** | Telas: reloginho, balão, Hoje, Deixar pronto, escolha de horário | Concluída (18/11/2026) |

## E01a: arquivos
- `game/scripts/state/week_state.gd`: `high_day`, `option`, `days` (`{"<dia>": {lunch, dinner, paw}}`).
- `game/data/config.json → meals` (`periods` com `from`/`to`, `options` com `shift` em horas, `arrival_day`, `on_time_needed` 2, `arrival_on_time_needed` 1); `Database.meals`.
- `game/autoload/game_state.gd`: `week_day()` com `high_day`, `_week_touch`, `meal_window`, `meal_period_at/now`, `is_meal_item` (provisório: item com `growth` e sem `treat`; a E02 troca pelo motor de pratos), `set_meal_option`, `meals_needed/meals_on_time/day_well_fed/well_fed_days`, `meal_info`, `meal_error`, `_register_meal` (chamado no `feed`), `dev_week_meal`.
- `game/autoload/events.gd`: `meal_given(period, on_time)` e `paw_earned(day)`.
- `game/autoload/save_manager.gd`: `SAVE_VERSION` 21 (saves zerados).
- `game/tests/day_clock_test.gd`; `tools/test_areas.json` (área `week`).

## Regras implementadas
- Janelas: almoço 11h–15h, jantar 18h–22h (início inclusivo, fim exclusivo); a opção desloca as duas em −1/0/+1 h (valor assumido; ajustável em `config.json`).
- Refeição conta só se for refeição (não lanche), dentro da janela e uma por período. Fora da janela o `feed` alimenta, mas não conta (E01b decide o resto).
- Dia da chegada (dia 1): a primeira refeição vale a qualquer horário (manhã = almoço, a partir das 16h = jantar) e uma basta para o dia bem alimentado.
- Dia bem alimentado (2 refeições na hora; 1 no dia 1) concede a patinha uma vez (`well_fed_day` no contador, `Events.paw_earned`).
- O dia do jogo só avança: vale o maior dia local já visto. As ferramentas DEV podem voltar.

## Pronto quando (E01 inteira)
`day_clock_test` cobrir dia cheio, dia fraco, jogo fechado, virada de dia e relógio atrasado. E01a cobre dia cheio, chegada, relógio atrasado, persistência; faltam dia fraco, jogo fechado e virada (E01b).

## E01b: arquivos e regras (18/11/2026)
- `week_state.gd`: `settled` (último espaço de refeição conferido: dia local × 2 + 0/1), `weak_streak`, `weak`, `lunchboxes`, `stored` (`{item, day, period}`). `SAVE_VERSION` 22 (saves zerados).
- `config.json → meals`: `ration` (fome +25), `lunchbox` (fome +40, felicidade +10), `lunchbox_after_weak_days` 2, `on_time_bonus` (felicidade +5 a quem dá na hora).
- `GameState`: `update_week()` (roda no tick de 1 s, no carregar do save e no botão DEV "Conferir janelas agora"; confere todas as janelas fechadas, também com o jogo fechado), `_settle_slot` (ração sozinho se a janela fechou sem refeição, registrada com `on_time: false`), `_close_day` (dia sem patinha = fraco; o dia da chegada nunca é), `tiro_weak()` (fraquinho até a próxima refeição na hora), marmita da vovó automática ao 2º dia fraco seguido (zera a sequência), `meal_next_target/store_meal_error/store_meal/cancel_stored_meal/stored_meal/_eat_stored` (Deixar pronto: uma refeição por vez, o Tiro come ao abrir a janela e conta como na hora; se o jogo estava fechado, conta no dia e período guardados; `_forced_meal/_forced_day` fazem o `feed` valer para a janela certa, mesmo em passeio).
- `Events`: `meal_missed`, `weak_day`, `lunchbox_given`, `meal_stored`, `stored_meal_eaten`. Contadores: `weak_day`, `lunchbox`, `meal_stored`, `meal_stored_eaten`.
- A abertura do save marca como conferido tudo que já fechou (não pune o passado). O relógio que volta não reabre janelas.
- Telas (reloginho, balão, Hoje, tampinha da tigela, escolha de horário, aviso do fraquinho/marmita) ficam na E01c.
- Teste: `day_clock_test` ampliado (dia fraco, marmita, jogo fechado, dia da chegada, guardar/cancelar/comer ao abrir, persistência).

## E01c: telas (18/11/2026)
- `scripts/ui/meal_ui.gd` (`MealUi`): `period_state` (done/ration/stored/open/soon/closed), `asking_period`, `clock_button`/`sync_clock`, `open_today`/`today_panel` (folha madeira "Hoje": Dia N, chip da patinha ou "n/m na hora", aviso `WeakNote`, `Period_<período>` com horas e estado, `StoredCard` + `CancelStored`, `OptionCard` com `NotebookTab_early/normal/late`; sem escolha no dia da chegada), `store_choice(item, dar_agora)` (`StoreMeal` verde / `GiveNow`), `connect_notices` (avisos do fraquinho e da marmita).
- `Hud`: `MealClock` no canto do avatar (verde quando pede refeição, pontinho `WeakDot` no fraquinho), sincronizado em `refresh`.
- `PetScreen`: `MealBubble` "Hora do almoço/jantar!" sobre a cabeça, toca e abre a guia de comida.
- `PetCareTray._act`: refeição fora da hora, que dá para guardar, abre `Deixar pronto?`; `StoredLid` (relógio) no botão de comida enquanto há refeição guardada.
- Teste `meal_ui_test` (suite + área `week`); capturas `tests/meal_shots.gd` → `build/screenshots/meal/` (5 telas × 3 resoluções, abertas e conferidas).
- Provisório: reloginho é o ícone vetorial `clock` num disco; balão usa `ChipButton`; sem arte nova (E16).
