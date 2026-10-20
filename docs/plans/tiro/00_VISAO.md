# 00 — Visão: o Tiro no centro

> **Você entra no jogo para ver o Tiro crescer. Todo o resto existe porque ele precisa.**

## Pedido do Vitor (19/10/2026)

"O objetivo e o foco do jogo têm que ser o Tiro. As pessoas têm que querer entrar para o Tiro evoluir, para
ver essa evolução nele. Tudo em volta — a fazenda, as construções — é para você ver a evolução do Tiro."
Decisões dele: **5 fases** casadas com os capítulos; **crescer é sempre o principal**; atributos passam a ser
do Tiro; o avatar do HUD mostra o crescimento; **o nível do jogador sai**; liberdade para repensar a economia,
criar comidinhas, itens e fatos reais da raça; etapas pequenas, uma por vez; testes enxutos; e,
acima de tudo, **o Tiro continua sendo o mesmo cachorro** (só muda a fase).

Base: o dossiê [`../TAMAGOTCHI_E_EVOLUCAO.md`](../TAMAGOTCHI_E_EVOLUCAO.md) (ideias, não limite) e as pesquisas
desta sessão (virtual pets, álbuns, interface de evolução, psicologia de retenção, biologia do Yorkshire).

## Diagnóstico (como o jogo está hoje)

- O Tiro **não tem progressão própria**: `DogState` guarda só necessidades, sono e afeto. Nível/XP são do
  jogador (mesmo aparecendo no avatar dele); "Atributos" (Horta/Cozinha/Comércio/Aventura) são do jogador
  e prometem coisas que não entregam.
- Vínculo termina em 520 de afeto; depois o afeto não serve para nada.
- Ovo, leite, farinha, queijo, trigo, milho, tecido e cristal **não viram nada para o Tiro**; o brinquedo
  trançado é só de vender.
- Capítulos 2–9 não falam dele; 10–12 o chamam para uma reação de 2 s.
- A Casa quase não tem coisas dele (caminha e sofá só mudam onde dorme).

## Os quatro relógios do Tiro

| Relógio | Ritmo | O que é | Antes | Depois |
|---|---|---|---|---|
| Agora | minutos | Barriga, felicidade, energia, higiene | existe | igual (e alimenta o "Radiante") |
| Hoje | horas | Desejos, passeio, faro, rotinas | existe | rotinas falam do Tiro |
| **Crescendo** | dias | Fase de vida, pilares, o que ele precisa | — | **novo, o objetivo do jogo** |
| **A vida dele** | semanas | Álbum, casa, Dia do Tiro, jeito | — | **novo** |

## O que muda para o jogador

1. **O Tiro cresce em 5 fases** — Filhotinho, Dentinhos, Aventureiro, Mocinho, Azul e Dourado — partindo do
   Recém-chegado. Cada fase muda corpo, cor e jeito; a próxima fica em **silhueta escura**, com o caminho
   (o que ele precisa) sempre visível.
2. **Quatro pilares do Tiro** — Corpo, Pelagem, Esperteza, Coragem — sobem com o que você faz por ele.
   Cada fase tem um teto; crescer abre o próximo teto (padrão "ascensão").
3. **Para crescer**, além dos pilares, ele precisa de um **item-chave do capítulo** (feito numa estação ou
   ganho na história) e de uma **refeição da fase**. Comida comum só mata a fome.
4. **Crescer é o fim de cada arco da história** (capítulos 1, 3, 6, 9 e 12) e abre o arco seguinte.
5. **A fazenda serve ao Tiro**: galinheiro → ração de crescimento; curral + moinho → mingau; estufa → xampu;
   bancada → mordedor e escova; costura → lacinho do topete.
6. **Cerimônia de crescer**: você aperta "Crescer!" quando quiser; antes e depois lado a lado, foto oficial,
   risquinho novo na régua da parede.
7. **Álbum de recordações**: fotos garantidas da história, primeiras vezes, travessuras secretas com dicas,
   poses de sono, amigos e datas (Dia do Tiro).
8. **A Casa cresce com ele**: régua de altura, caminha que evolui, prateleira de lembranças, parede de fotos.
9. **Ele tem jeito próprio** (Explorador, Comilão, Brincalhão, Dengoso, Tranquilo) e paladar próprio
   (comida favorita sorteada por save).
10. **O HUD mostra o Tiro crescendo**; o nível do jogador deixa de existir para quem joga.

## Princípios (inegociáveis)

- **O Tiro é o mesmo cachorro.** O adulto (Azul e Dourado) é o Tiro de hoje, sem redesenho. As fases jovens são
  versões mais novas **dele** (mesmo rosto, olhos, focinho, língua, contorno e paleta). Ver 06, seção E.
- **Gentileza:** sem morte, sem regressão, sem forma "ruim", sem punição por ausência. Nada estraga:
  o que foi entregue fica entregue; cenas da história esperam por você.
- **Previsível:** crescer nunca depende de sorte. Sorte só em bônus (fotos raras, achados), sempre com garantia.
- **O jogador escolhe a hora:** o botão "Crescer!" espera.
- **Visual e simples:** ícone + número; uma linha de texto; revelar aos poucos (regras do `CLAUDE.md`).
- **Dados em JSON, estado em classes, ações no `GameState`.** Nada de número solto em script.
- **Saves zerados:** o Vitor vai zerar o jogo de todos. A etapa 02 sobe o `SAVE_VERSION` para 13 e saves
  antigos recomeçam do zero (preferências do aparelho em `settings.json` ficam). Nada de migração para saves antigos.

## O que NÃO muda

Mundos, estações, bandejas, painel, abas, câmera, gestos, glossário (só ganha verbos novos), sistema de
depósitos, obras comunitárias, passeios, faro, amigos e truques continuam. Eles ganham um **porquê** no Tiro.
`SAVE_VERSION` sobe para 13 uma única vez (etapa 02), com reset; depois disso, campos novos entram com padrão seguro.

## Lições da pesquisa que guiam o plano

| Referência | Lição aplicada |
|---|---|
| Digimon (Time Stranger) | silhueta escura + requisitos legíveis = curiosidade |
| Genshin (ascensão) | mesmos tipos de material a cada fase; teto de nível sobe ao crescer |
| Pokémon GO | o jogador aperta "Evoluir" quando quer; prévia sem spoiler |
| Finch | fases contadas em dias de uso; pet nunca morre; duração crescente |
| Tamagotchi | o que NÃO copiar: ramificação por erro de cuidado |
| Chao Garden | o que você dá vira corpo e jeito |
| Pokémon Sleep | coleção de poses de sono vista ao voltar; caminha melhor = poses raras |
| Neko Atsume | prepare o cenário e o bichinho "atua"; o resultado é visto depois |
| Unpacking | a casa conta a história pelos objetos |
| Stardew / AC | o que evitar: janelas estreitas, eventos perdíveis, sorteio como única via |
| Endowed progress / goal-gradient | fase começa com algo cumprido; último requisito é o mais rápido |

## Sinais de sucesso (para o teste do Vitor no celular)

- Primeira cerimônia (Filhotinho) na **primeira sessão**; Dentinhos **antes do dia 3–5** de jogo.
- Em qualquer momento, a tela de crescimento responde "o que eu faço agora?" com um toque.
- Ninguém confunde o Tiro filhote com outro cachorro.
- Toda estação da fazenda tem pelo menos um produto que o Tiro usa.
