# Etapa 10 — Comemorações, boas-vindas e Novo!

> Tamanho: médio. Depende de: 09. Próxima: 11.
> Resultado que o Vitor vê: os quatro tamanhos de prêmio certos em todo o jogo — micro e pequeno só voam;
> médio é a folha (passo da história, boas-vindas, passeio comum, Novo!); grande é o cartão com confete
> (capítulo, crescimento, tesouro, obra, truque, seda, raro).

## 1. Ler antes
`02_JORNADA.md` §4 (tamanhos), §9 (boas-vindas); `03_TELAS.md` "Comemorações e retorno"; protótipo
`prototipo/missoes_premio.png` (a folha média).

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Cartão de comemoração | `scripts/ui/modal_card.gd` (`ModalCard.open(host, opções)`: fita, ícone com raios, chips que entram e contam, confete, `add/add_text/add_chips/add_primary/add_ghost/reveal/fire_confetti`) | um só tamanho |
| Montadores | `scenes/ui/celebration/celebration.gd` (`show_chapter`, `show_unlocks`, `show_trick`, `show_silk`, `show_treasure`, `show_project`, `show_find`), `scenes/ui/walk_result/` (`WalkResult*`), `scenes/ui/welcome_back/` (`WelcomeBack`, `DailyGift`, `Line_*`), `scenes/ui/growth_ceremony/` (`GrowthCeremony`, `BeforeAfter`, `HeightMark`, `CloseCeremony`) | todos usam o `ModalCard` |
| Folha média | `scenes/ui/quest_reward/` (criada na 05) | só passo da história |
| Fila | `main.gd._queue_modal/_flush_modals` | serializa tudo |
| Testes | `festa_test` (não referencie `ModalCard` por tipo em teste `-s`: ache por `find_child`), `welcome_test`, `ceremony_test`, `walk_return_ui_test` | — |

## 3. Passo a passo
1. **`ModalCard` (grande):** cartão `PAPER` canto 28, largura 320; **fita** vira pílula colorida (verde =
   concluído; mel = crescimento/prêmio; azul = descoberta) com `StrongLabel` branco; raios mais suaves (alfa
   0,35); chips grandes (44, ícone 36, `HONEY_SOFT`) que contam; um `primary` + um `ghost`; confete e
   vibração como hoje (só nos grandes momentos). Nós `Celebration`, `CelebrationScroll`, `Confetti` mantidos.
2. **Folha média genérica:** extraia da `QuestReward` (05) uma base `RewardSheet` (`scripts/ui/reward_sheet.gd`)
   com: fita, fala opcional (retrato + balão), chips grandes, um bloco livre (ex.: próximo passo, linhas),
   `soft` + `primary`, arrastar para fechar. `QuestReward` passa a usá-la.
3. **Boas-vindas** (`WelcomeBack`): vira `RewardSheet` com o Tiro acenando no topo (retrato do `PetAnimator`
   como hoje), o presente do dia em chips grandes (`DailyGift`) e as linhas por tipo (`Line_dig`,
   `Line_ready_<mundo>`, `Line_walk`, `Line_friend_visit`, `Line_growth`) como `list_row` com `ctl chev` (Ir);
   botão verde "Pegar" (presente) e fantasma "Depois".
4. **Passeio** (`WalkResult`): comum → `RewardSheet` (postal como figura, achados em chips); raro/lendário →
   `ModalCard` com confete (`RareStar` mantido). Nós `WalkResultScroll`, `CloseResult`, `FirstTime`,
   `Found_<item>`, `Equip_<roupa>` mantidos.
5. **Novo!** (`show_unlocks`): `RewardSheet` pequena: ícone 64 da novidade, nome, uma linha e `primary("Ir")`
   + `ghost("Depois")`; uma por novidade, na fila.
6. **Cerimônia do crescimento:** só a pele (cartão, fita mel, botões); a sequência e os nós não mudam.
7. **Regra "nunca dois":** a fila já serializa; confira os pares capítulo+Novo!, passeio+Novo!,
   crescimento+Novo! nas capturas.
8. Tour `--i2-10-only`: `i2_10_chapter`, `i2_10_unlock`, `i2_10_welcome`, `i2_10_walk`, `i2_10_walk_rare`,
   `i2_10_trick`, `i2_10_treasure`, `i2_10_ceremony`.

## 4. Não fazer
Mudar o que cada comemoração dá, quando aparece ou a ordem da fila.

## 5. Armadilhas
- `ModalCard` não pode ser referenciado por tipo em teste rodado com `-s` (regra do `festa_test`).
- Menos animação: confete desligado, chips já no valor final.

## 6. Testes
Sem teste novo (os de hoje já cobrem quando cada cartão aparece). **Atualizar** só nomes/estrutura que
mudarem de propósito. **Comando:** `tools\test.ps1 -Level etapa -Exact -Tests festa_test,welcome_test,ceremony_test,walk_return_ui_test,quest_reward_test` (~1 min 20).

## 7. Capturas
`--i2-10-only` antes (`--festa-only`, `--ceremony-only`) e depois nas 3 resoluções.

## 8. Pronto quando
- [ ] Os quatro tamanhos aparecem certos; nenhum par de cartões simultâneo.
- [ ] Testes verdes.

## 9. Registro
```
**Etapa 10 (data, executor):** ModalCard novo, RewardSheet (base da folha média), boas-vindas, passeio,
Novo! e cerimônia no visual novo. Testes … PASS em … s.
```
