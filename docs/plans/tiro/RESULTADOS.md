# Fechamento do plano "Tiro no centro" (etapa 18, 19/10/2026)

## Passagem total

- `tools/test_all.ps1 -KeepGoing` (83 testes, **40,7 min**): 76 PASS, 7 FAIL. Logs: `build/test_logs/tiro18/` (`suite.log`, `suite.csv`).
- Falhas **históricas** (já na linha de base da etapa 00, sem relação com o plano): `npc_lines_test`, `onboarding_test`, `finds_test`, `park_test`, `petshop_test`, `ui_style_test`. Cada um imprime o próprio erro conhecido (`park_test`/`ui_style_test` imprimem PASS e caem no filtro de `ERROR:` ao sair; `petshop_test` quebra em `'rare'`). `progression_test` **passou** (936,6 s), o que não acontecia na linha de base.
- **Falha nova encontrada e corrigida:** `economy_sim_test` imprimia PASS mas emitia ~10 mil `Stack underflow` (recursão infinita do robô do simulador: passeio trancado → fase do Tiro → item de passeio → passeio, porque `_pursue_walk` reiniciava a profundidade em 4). Trava de reentrada `_walk_nesting` em `game/tests/helpers/economy_bot.gd` (só teste, sem efeito no jogo). Reexecutado: PASS em 88,7 s, 0 erros. Os outros 75 PASS e as seis históricas continuam como estavam; só esse teste foi repetido depois da correção.
- `dev_tools_test -- --prod` (`dev_tools_test_prod`) PASS na suíte.
- Tour `ui_tour` nas três resoluções, 114 PNGs cada, 0 erros de script: `build/screenshots/tiro18_depois` (360×780), `tiro18_depois_390`, `tiro18_depois_412`. Abertos e conferidos: Tiro (`a01_pet`), HUD com anel e fase, painel de crescimento (`t01`, 360 e 412), cerimônia antes/depois (`t04`), caderninho com Crescimento e diário (`t06`) e Casa (`a04_house`; a Casa do tour é a inicial, sem lembranças). A aba Álbum só foi vista como aba do caderninho; as fotos foram abertas nas etapas 13 e 15. Comparação lado a lado com `tiro00_antes` não refeita nesta etapa (feita nas etapas 05–08); aqui só se confirmou que as telas abertas estão íntegras. O tour não tem captura própria do álbum e da Casa decorada (ficam nas pastas `tiro13_*`, `tiro14`, `tiro15` das etapas).
- Export Web local (`tools/export_web.ps1 -Channel dev` → `build/web`) + `serve_local.ps1` + `touch_test` curto (Chrome móvel emulado 390×844): o jogo carrega, a introdução avança por toque e o Tiro filhote aparece como o mesmo cachorro; console sem erros (`build/test_logs/tiro18/touch/`). **Não** repeti no navegador "crescer, entregar, escovar, abrir álbum": um save novo começa na introdução e chegar a Dentinhos exige o jogo todo ou fixture. Esses gestos já tinham toque emulado/real nas etapas 06 (entregar e crescer) e 08 (cerimônia) e estão cobertos por `growth_ui_test`, `ceremony_test`, `brush_taste_test` e `album_test`. Sem aparelho físico.

## Conferência da visão (00, "O que muda para o jogador")

| # | Item | Onde está | Verificado por |
|---|---|---|---|
| 1 | Cinco fases a partir do Recém-chegado, silhueta da próxima | `growth.json`, `GrowthUi`, `silhouette.gdshader`, corpos por fase (`dog_look`) | `growth_test`, `growth_visual_test`, `growth_ui_test`, tour `t01`/`t_phase_*` |
| 2 | Quatro pilares com teto por fase | `GrowthState`, `_gain_pillar`, `PillarUi` | `pillars_test`, tour `t06` |
| 3 | Item-chave + refeição da fase para crescer | `growth.json`, comidas e itens-chave (etapas 09/10) | `growth_foods_test`, `keys_test` |
| 4 | Crescer fecha os capítulos 1/3/6/9/12 | objetivo `growth` em `quests.json` | `growth_story_test`, `progression_test` (109/109) |
| 5 | A fazenda serve ao Tiro | receitas/estações com `growth`, xampu, mordedor, escova, lacinho | `growth_foods_test`, `keys_test`, `products_test` |
| 6 | Cerimônia, antes e depois, régua | `GrowthCeremony`, `BeforeAfter`, `HeightMark` | `ceremony_test`, tour `t04`, toque da etapa 08 |
| 7 | Álbum de 54 fotos, dicas e segredos | `album.json`, `AlbumView`, `PhotoCard` | `album_test`, `album_secrets_test` |
| 8 | Casa que cresce | `house.json`, `HouseDecor`/`HouseUi` | `house_test` |
| 9 | Jeito e paladar próprios | `PersonalityRules`, `growth.json → tastes` | `personality_test`, `brush_taste_test` |
| 10 | HUD mostra o Tiro; nível some | `Hud`, `GrowthBadge` | `hud_growth_test`, `hud_test`, tour |

Nenhum item ficou sem entrega. **Pendências explícitas (não são itens não entregues):** (a) ritmo: Dentinhos/Aventureiro saem cedo e Mocinho/adulto tarde no simulador (diagnóstico abaixo, nada ajustado); (b) playtest em aparelho físico; (c) as seis falhas históricas da suíte.

## Roteiro do celular (`/dev/`, ≤ 15 itens)

1. Abra a versão dev em aba anônima ou apague o save (Configurações) e confira a introdução e o Recém-chegado.
2. Toque no selo do HUD: o painel Crescimento mostra Filhotinho em silhueta e o que falta.
3. Cumpra os requisitos do Filhotinho e aperte **Crescer!**; veja a cerimônia.
4. Repita a cerimônia com "Menos animação" ligado (Configurações): sem piscar e sem confete.
5. Confira que o filhote é o mesmo Tiro (rosto, pelagem, cor das patas).
6. Siga até Dentinhos: o presente traz a escova; aparece o quinto cuidado Escovar.
7. Arraste ~600 px nas costas dele para escovar; tente de novo logo depois ("Ele já está penteadinho").
8. Dê uma comida e veja o ♥ de favorita e a reação do paladar.
9. Caderninho → Álbum: fotos tiradas, polaroides, selo Novo e aviso "Nova foto!".
10. Segure a lupa em uma foto secreta e leia a dica.
11. Na Casa, veja a régua na parede, a prateleira de lembranças e a foto principal.
12. Passeie e volte: bagagem, fase gravada na foto.
13. Alcance o Aventureiro e veja o jeito do Tiro e o diário.
14. No adulto, abra "Mais brilho!" (Pelagem de seda).
15. Carregue um save antigo (v12 ou menor): ele é zerado com aviso e recomeça no Recém-chegado.

## Resultados da etapa 17 (mantidos)

### Resultados da etapa 17 — simulador rápido (19/10/2026)

**Uma** execução `tools/economy_simulate.ps1 -Quick` (perfil `reference`, semente 1, campanha, 60 dias, sem ledger), conforme a regra 4 do `01_REGRAS_DE_EXECUCAO.md`. Sem perfis extras nem outras sementes. Medidas **simuladas** (agente idealizado), alvos iniciais do plano, não playtest.

- Evidência: `build/economy/quick/20261019_1928/` (`reference_s1/summary.json`, `relatorio/report.md`, seção "4b. Fases do Tiro × dia").
- **Tempo gasto: 6,1 min de relógio** (367 s) para 38,83 dias simulados. Campanha **completa**: 109/109 missões, 57/64 melhorias, 14.825 ações, 1.181 min ativos, 0 violações de guarda.
- Tentativa anterior (19:08): terminou em "TEMPO ESGOTADO (20 min)" sem medir nada, porque um erro meu de tipo em `economy_sim.gd` (`var reached :=`) impedia o carregamento do simulador e o processo ficou parado. Corrigido; não foi PASS. Só a segunda rodada vale.

## Dia de cada fase × alvo (02 E)

| Crescimento | Alvo | Dia simulado | Minutos ativos | Leitura |
|---|---|---|---|---|
| Filhotinho | primeira sessão | 0,00 | 1,3 | dentro |
| Dentinhos | dia 1–3 | 0,01 | 10,0 | **muito cedo** (> 2× fora do alvo) |
| Aventureiro | dia 5–8 | 1,82 | 67,2 | **cedo** (menos da metade do alvo) |
| Mocinho | dia 10–14 | 19,84 | 605 | tarde (1,4× o limite) |
| Azul e Dourado | dia 18–24 | 37,34 | 1.133 | tarde (1,55× o limite) |

Pilares no fim: Corpo 10, Pelagem 8, Esperteza 10, Coragem 10. Seda no fim: 0 (o robô não persegue a Pelagem de seda; é pós-jogo).

## Moedas ao fechar cada capítulo (risco do meio do jogo, 03 G)

| Cap. | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Moedas | 105 | 203 | 238 | 210 | 147 | 743 | 3.628 | 9.245 | 39.548 | 43.866 | 51.785 | 82.665 |

Capítulos 5–9: o jogador idealizado fica com poucas moedas nos capítulos 5 e 6 (147 e 743) e acumula rápido a partir do 7 (3.628 → 39.548 no 9). Não há deficit de moedas no meio; o risco é o oposto: moedas sobrando de montão nos capítulos 8–9. **Registrado, preços não ajustados** (regra da etapa).

## Diagnóstico para o Vitor decidir

1. **Dentinhos e Aventureiro chegam cedo demais** (minutos 10 e 67 do primeiro dia, e dia 1,8). Os requisitos são só contagens baratas (comidas, pilares até nível baixo, missões iniciais) e não há nada limitado por tempo de calendário; o agente joga sem pausa, então o dia 1–3 / 5–8 do alvo não é alcançável sem um requisito de espera (por exemplo dias diferentes de cuidado, como o da seda). Uma pessoa real joga em sessões curtas e provavelmente se aproxima mais do alvo, mas isso só se mede com toque manual.
2. **Mocinho e Azul e Dourado chegam mais tarde que o alvo** (dia 19,8 e 37,3 contra 10–14 e 18–24); o último crescimento só acontece na fase final da campanha (capítulo 12). A diferença vem da cadeia de requisitos de capítulo (obras da vila, Festa), não dos pilares.
3. Pela regra 4 da etapa só se ajusta **uma família de números e só quando alguma fase cai fora do alvo por mais de 2×**. Dentinhos/Aventureiro caem por mais de 2× (para baixo), mas corrigir isso pede decisão de desenho (requisito com espera de calendário) e não só trocar um número; **não ajustei nada** e deixei o diagnóstico acima. Sem segunda rodada.
