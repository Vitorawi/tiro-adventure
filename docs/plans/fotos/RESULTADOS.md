# Fotos do Tiro — fechamento (etapa 11, 07/11/2026, local)

Nada publicado, sem commit/push. Sem campanha nem simulador.

## O que foi conferido
| Item | Resultado |
|---|---|
| Arte por raridade (etapa 02 repetida) | instalador rodado duas vezes (+`--import`): **216/216 versões, 54/54 fotos completas**, 72 novas desde a última vez; `album_rarity_pipeline.py check` PASS |
| Portão (`test.ps1 -Level portao -KeepGoing`, 122 testes, 876 s) | 120 PASS, 2 falhas: `photo_art_test` (do plano; corrigido: com 54/54 completas não sobra foto "pendente", o teste agora trata a lista vazia e o limite subiu para 240 s → PASS isolado) e `drag_scroll_test` (de outro agente, rolagem; falhou no portão com 154,8 s e **passou isolado**, não alterado) |
| Tour `ui_tour.gd -- --fotos-only` | 15 PNGs em cada resolução (`build/screenshots/fotos_11_360x780`, `_390x844`, `_412x915`): álbum, carta 1/3/4 parada e inclinada, revelação (verso/virando/final), varal com 3, cartão de marco, tutorial (abrir/sorte/melhorar). Todos abertos e conferidos, nenhum corte/sobreposição |
| Toque real (Chrome 390×844 touch, build Web dev, `game/tests/touch/fotos.json`) | intro → DEV (moedas + materiais + carta fechada) → Tiro → caderninho → Álbum → **tutorial inteiro por toque** (Abrir, Tentar a sorte grátis, Melhorar, inclinar arrastando, escolher versão, Pôr no varal) → varal na home → tocar no varal abre a carta → arrastar inclina → Melhorar até a Holográfica ("Coleção completa!") → fechar. Capturas em `build/touch_test/t01…t11` |
| Desempenho no navegador (requestAnimationFrame, Chrome headless, limitado a ~60 Hz) | carta Rara inclinando: média 18,7 ms (~54 fps), p95 18,2 ms, 4 quadros > 33 ms de 192; carta **Holográfica**: média 19,3 ms (~52 fps), p95 18,2 ms, 6 > 33 ms de 263 (os picos de 90–210 ms são a troca/criação do `SubViewport` ao abrir e melhorar). Alvo ≥ 50 fps atingido na média. **Não substitui o celular físico.** |

Ajustes no `ui_tour.gd` desta etapa: bloco `--fotos-only` (`_fotos_shots`). Nenhuma regra, custo, sorteio, arte, save ou fala foi alterada.

## Pendências / limites
- Celular físico não medido (só Chrome emulado). Use o roteiro abaixo.
- Prêmios de coleção só em moedas (valores em `album.json → cards.rewards`, ajustáveis).
- Valores de chance/custo ainda podem ser calibrados depois de o Vitor jogar.
- Um servidor local (`tools/serve_local.ps1`, porta 8000) ficou aberto nesta sessão.

## Roteiro do celular (10 passos, versão `/dev/`, save novo)
1. Abra o jogo, passe a introdução e use **DEV → Recursos** (+1000 moedas, +10 materiais) e **DEV → Crescimento → Carta fechada**. *Observe:* nada trava.
2. Na tela do Tiro, abra o caderninho → **Álbum**. *Observe:* a Laís fala, o botão Abrir brilha, só ele recebe toque.
3. Toque **Abrir**. *Observe:* o verso de madeira com a pata vira, a carta aparece Comum, sem lentidão.
4. Toque **Tentar a sorte** (grátis, selo "Grátis"). *Observe:* sai Brilhante; sem cobrar moedas.
5. Toque **Melhorar → Rara** (presente). *Observe:* moldura entalhada e brilho passando.
6. **Arraste** a carta para os lados. *Observe:* ela inclina com o dedo, o brilho acompanha, volta suave ao soltar.
7. Escolha uma versão e **Pôr no varal**. *Observe:* a polaroide aparece presa na parede da home, sem cobrir o Tiro.
8. Toque na polaroide do varal. *Observe:* abre a carta grande; fechar volta à home.
9. Melhore até a **Holográfica** (materiais DEV) e incline. *Observe:* reflexo arco-íris; fluidez parecida com as outras telas, sem esquentar o aparelho.
10. Volte ao Álbum: *Observe:* "Coleção completa!"/"4/4", "Quase lá", pistas com ícone e Ir, cartão de marco "Primeira Holográfica" (+100 moedas). Ligue **Menos animação** e repita 6 e 9: o brilho deve ficar parado.
