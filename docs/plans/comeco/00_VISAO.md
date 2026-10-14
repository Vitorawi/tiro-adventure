# 00 — Visão: por que e para onde

> Leia antes de qualquer etapa. Aqui ficam o diagnóstico, a pesquisa, os princípios, a linha do
> tempo que queremos e as regras de "o que não fazer". O **como** está em cada `ETAPA_XX`.

## 1. Pedido do Vitor
"Melhorar ainda mais a experiência no **início do jogo**: mais missões, mais itens, mais receitas,
outras estruturas, **um mapa novo**. Engajar mais e facilitar mais. Inspirar-se em jogos de colheita
e de aventura." Depois: "caminha do Tiro; uma **aba de desejos** (ele pede um tipo de comida);
**vários passeios** que vão sendo liberados com o tempo; no passeio ele acha **coisas raras**
(roupinhas, apetrechos) e **materiais que só dá para achar ali**; a praça abre **depois** da Vila;
pode zerar os saves."

## 2. Diagnóstico da primeira hora atual
| Min. | O que acontece | O que o jogador sente |
|---|---|---|
| 0–4 | Chegada da Laís; comer, banho, brincar, abrir a Mochila | Bom, mas o "presente" é só +10 moedas |
| 4–10 | Sítio; vovó empresta **1 canteiro**; colher **3 vezes** | **Tempo morto** (~3 min só esperando) |
| 10–20 | Entregar cenouras; batata de 5 min | Pouco a fazer em paralelo |
| 20–35 | Geladeira, fogão, ensopado | Bom marco; mas abóbora/papinha presas a **atributos escondidos** |
| 35–50 | Vila: vender e encomendar | Vila com pouca coisa no começo |
| 50–70 | Natureza: 6 madeiras (1 por minuto), bancada | Primeira "aventura" é um painel de timers |

Problemas (as etapas citam estes códigos):
- **D1** Tempo morto no sítio (1 canteiro emprestado).
- **D2** O Tiro quase não pede nada; o bichinho não puxa a produção.
- **D3** Recompensas invisíveis: presente = moedas; roupas da coleção sem desenho; subir de nível só dá um toast.
- **D4** Abóbora (Horta 3) e papinha (Cozinha 2) presas a atributos que só aparecem no cap. 6.
- **D5** 3 culturas e 3 receitas até o cap. 5; nada pensado para o Tiro.
- **D6** Nenhuma surpresa, item raro ou segredo.
- **D7** Sem motivo para voltar amanhã até o cap. 4; nenhum resumo ao voltar.
- **D8** Nada do mundo canino: passeio, outros cães, truques, pet shop (estavam no `GAME_DESIGN.md`, nunca saíram).
- **D9** Canteiros fechados repetem a etiqueta "Sítio" (poluição visual).
- **D10** `pet()` não conta estatística; `feed()` não conta qual comida.

## 3. Pesquisa: o que os jogos de referência fazem e o que levamos
| Jogo | O que fazem | O que levamos |
|---|---|---|
| **Hay Day** | Poucos campos no início; cada nível traz algo novo; primeiras construções baratas/grátis; quadro de pedidos; pets que não produzem, mas querem casinha e petisco. | Presente ao subir de nível; **caminha grátis** como 1ª construção; pedidos para cada produto novo; Tiro como pet que **pede petiscos** (aba Desejos, parecida com o quadro de pedidos). |
| **Stardew Valley** | Primeira missão concreta (plantar e colher); **regar** é o toque diário; **pacotes do Centro Comunitário** (coleções por tema, recompensa por pacote e por sala, restauração visível). | **Regar** para acelerar; **álbum de achados em conjuntos** (sítio, praça, vila, natureza); diário de passeios com metas de coleção. |
| **Animal Crossing: New Horizons** | Metas pequenas diárias (Nook Miles); check-in diário; tarefas renovam todo dia; aviso quando pronta. Itens raros por estação e horário. | **Presente do dia** sem punição; diárias mais cedo; **passeio do pôr do sol** só em certo horário; raros que fazem voltar. |
| **Pocket Camp** | Visitantes por janela de tempo com 1–3 pedidos; amizade; coleta de um toque. Crítica: pedido que se cumpre sozinho perde a graça. | **Amigos do Tiro** por janela de 3 h; entrega sempre com um toque e animação. |
| **Neko Atsume** | Bichos visitam com o app fechado e deixam presentes; álbum com silhuetas; minimalismo. | Melhores amigos visitam a casa; **silhuetas** de achados, materiais e apetrechos ainda não encontrados. |
| **A Short Hike / Fae Farm / Ooblets** | Tesouro fora do caminho; recompensa pequena quase a cada ação; coleção puxa exploração. | **Faro do Tiro** (cavar achados) e **mapa do tesouro** em 4 pedaços. |
| **Pokémon GO / Pikmin Bloom (passeios)** | Sair para caminhar rende itens; raridade com "garantia" depois de várias tentativas. | **Passeios com tabela de achados**, **raro garantido** depois de N passeios sem raro (sem frustração). |
| **Cats & Soup** | Estações simples que melhoram; zero pressão; roupinhas opcionais. | Liquidificador pequeno e barato; roupinhas como prêmio, nunca obrigação. |
| **Onboarding mobile (Unity, Roblox, PocketGamer)** | Dia 1 é onde mais se perde jogador; chegar à diversão rápido; ensinar jogando; poucos pop-ups; medir onde param. | 1ª colheita < 4 min, 1º achado < 9 min; **dica parada**; "Ritmo" no DevPanel para o Vitor medir. |

## 4. Princípios (valem para todas as etapas)
| # | Princípio | Como verificar |
|---|---|---|
| P1 | **5 minutos mágicos**: Tiro reage, a primeira construção (grátis) muda a casa | Captura do cap. 1 com a caminha |
| P2 | **Nunca só esperar**: sempre ≥ 2 coisas úteis para fazer | `onboarding_test.gd` (Etapa 01 cria; cada etapa amplia) |
| P3 | **Tiro no centro**: o que se produz serve ao Tiro e aos amigos dele | Toda comida nova tem `feed` ou é pedida em desejo/amigo/pedido |
| P4 | **O mapa e o Tiro mudam à vista** a cada marco | Capturas de cada etapa |
| P5 | **Voltar é gostoso, faltar não dói** | Presente do dia, resumo ao voltar, visitas; nada estraga, morre ou zera |
| P6 | **Aventura pequena e frequente + meta longa** | Achados, raros dos passeios, álbum, mapa do tesouro |
| P7 | **Revelar aos poucos** (regra do `CLAUDE.md`) | Todo sistema novo tem `features.<id>` com `requirements` e tela "Novo!" |
| P8 | **Máximo 4 lugares visíveis por mundo** | Lugares extras com `"hidden": true` ou painel agrupado |
| P9 | **Visual e simples**: ícone + número; falas de uma frase | Revisão das capturas |

## 5. A nova primeira hora (alvo, depois de todas as etapas)
| Min. | Quem | O quê | Conceito novo |
|---|---|---|---|
| 0–1 | Laís | Chegada (igual) | — |
| 1–3 | Laís | Falar, comer, banho, brincar | Cuidar |
| 3–5 | Laís | Abrir a Mochila → **Caminha** → pôr a caminha na casa (grátis) | Construir |
| 5 | Tiro | **1º desejo**: "Quero carinho" → aba Desejos aparece | Desejos |
| 6 | Bloblo | Conhecer a vovó → **2 canteiros** | — |
| 7 | Bloblo | Plantar e **regar** | Regar |
| 8 | Tiro | **Fareja e cava**: mudas de morango | Faro / achados |
| 9–15 | Bloblo | Colher 3× (→ 4 canteiros), colher morango | — |
| 12–20 | Tiro | Mais achados no sítio; **pedaço do mapa 1** | Álbum + mistério |
| 20–35 | Laís | Geladeira, fogão, **liquidificador**, ensopado | Estação nova |
| 25+ | Tiro | Desejos de comida: petisco, picolé, purê | Cozinhar para o Tiro |
| 35 | — | Diárias abrem | Diárias |
| 35–50 | Laís | Vila: vender, encomendas (pedidos novos de morango/picolé) | — |
| ~50 | **Nina** | **Praça abre** → Nina e Pipoca → **Volta na praça** (2 min) | Mapa novo, passeio |
| 50–70 | Nina | Mais passeios: Rua das flores (3 passeios), Feirinha (6) | Passeios em degraus |
| 55–90 | Tiro | **Primeiro apetrecho raro** do passeio (garantido em até 6 voltas) | Raros |
| 50+ | Laís/Guia | Natureza (igual), em paralelo | — |
| depois | Nina | Pet shop, vestir o Tiro, costura, amigos, truques, tesouro | — |

## 6. Economia da primeira hora (conferir jogando)
Até o fim do cap. 3 (~35 min): início 10 + missões do cap. 1–3 (~250) + colheitas (~60) + desejos
(~40) + níveis 2–3 (35) ≈ **395**; gastos: geladeira 40, fogão 60, liquidificador 30 → **~265**
antes da escritura (180). Se ficar fácil demais, o ajuste recomendado é **subir a escritura para 220**,
sem mexer nas recompensas dos capítulos 1–2. Passeios dão poucas moedas: o valor deles são os
materiais e os raros.

## 7. O que NÃO fazer
- Nada de punição: desejo trocado, amigo que vai embora e Tiro cansado **não tiram nada**.
- Nada de sequência que zera (presente do dia conta **dias jogados**).
- Nada de moeda premium, anúncio ou "acelerar pagando".
- Não aumentar a queda das necessidades para forçar desejos.
- Não passar de 4 lugares visíveis por mundo; não abrir dois sistemas novos no mesmo passo.
- Não escrever textos longos; nada de parágrafo em tela.
- Não mexer em Natureza/armazenamento além do pedido (acabaram de ser refeitos).
- Não usar threads nem recursos fora do renderer Compatibility (Web single-thread).

## 8. Fontes da pesquisa
- Hay Day: [GameSkinny, níveis](https://www.gameskinny.com/zs7xi/hay-day-guide-the-levelling-system) ·
  [Hay Day Wiki, Feed Mill](https://hayday.fandom.com/wiki/Feed_Mill) ·
  [GameSkinny, produção](https://www.gameskinny.com/tips/hay-day-guides-the-production-buildings-on-the-farm/) ·
  [SuperCheats, pets](https://www.supercheats.com/hay-day/walkthrough/pets-in-hay-day)
- Stardew: [StrategyWiki, primeiro calendário](https://strategywiki.org/wiki/Stardew_Valley/First_time_calendar) ·
  [Stardew Wiki, Bundles](https://stardewvalleywiki.com/bundles) ·
  [StrategyWiki, Community Centre](https://strategywiki.org/wiki/Stardew_Valley/Community_Centre) ·
  [Steam, discussão sobre o começo](https://steamcommunity.com/app/413150/discussions/0/2653116897581674000)
- Animal Crossing: [TheGamer, Nook Miles](https://www.thegamer.com/animal-crossing-new-horizons-complete-guide-nook-miles/) ·
  [Pixelpoppers, Nook Miles+](https://pixelpoppers.com/2020/03/nook-miles-and-binge-playing/) ·
  [Animal Crossing Wiki](https://animalcrossing.fandom.com/wiki/Nook_Miles)
- Pocket Camp: [Destructoid](https://www.destructoid.com/review-animal-crossing-pocket-camp/) ·
  [Pocket Gamer](https://www.pocketgamer.com/animal-crossing-pocket-camp/animal-crossing-pocket-camp-tips-and-tricks-fish-bugs-shells-and-more/) ·
  [Game Developer, mecânicas de compromisso](https://www.gamedeveloper.com/business/animal-crossing-pocket-camp-can-an-old-dog-learn-new-tricks-)
- Neko Atsume: [TV Tropes](https://www.tvtropes.org/pmwiki/pmwiki.php/VideoGame/NekoAtsume) ·
  [Siliconera](https://www.siliconera.com/here-are-the-best-toys-in-neko-atsume-2/)
- Aventura aconchegante: [Filibuster, cozy de exploração](https://thefilibusterblog.com/top-10-cozy-games-for-rewarding-exploration-experiences/) ·
  [RPG Site, Fae Farm](https://rpgsite.net/review/14765-fae-farm-review) ·
  [Use a Potion, Ooblets](https://useapotion.com/2022/09/ooblets-nintendo-switch-review)
- Cats & Soup: [3DJuegos](https://www.3djuegos.com/android/noticias/amantes-gatos-tienen-android-netflix-este-relajante-juego-gestion-donde-cocinar-sopa-placer)
- Onboarding: [Unity, FTUE](https://unity.com/how-to/10-first-time-user-experience-tips-games) ·
  [Unity, retenção](https://unity.com/how-to/improve-retention-every-stage-player-lifecycle) ·
  [Roblox, onboarding](https://create.roblox.com/docs/production/game-design/onboarding) ·
  [PocketGamer.biz, FTUE](https://www.pocketgamer.biz/first-impressions-count-creating-the-ultimate-first-time-user-experience)
