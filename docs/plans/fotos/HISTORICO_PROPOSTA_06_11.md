# Plano "Fotos do Tiro" (06/11/2026) — aprovado pelo Vitor

Pedido: as fotos viram uma parte principal do jogo, instigante de colecionar. Hoje: o álbum mostra as
polaroides encolhidas em quadradinhos (as ilustrações novas viram borrão), as pistas são vagas, ganhar uma foto
é só um aviso, não há raridade, e a "parede/cantinho" da Casa é uma lista de botões. As 54 ilustrações novas
(`assets/sprites/ui/album/illustrated/`, 1254×1254, `photo.illustration` no `album.json`) já existem e NÃO mudam.

## 1. Raridade (4 níveis)

Cada foto, ao ser tirada, ganha uma raridade sorteada. A ilustração é a mesma; muda o acabamento:

| Nível | Nome | Chance | Acabamento |
|---|---|---|---|
| 1 | Comum | 45% | polaroide creme simples |
| 2 | Brilhante | 30% | moldura dourada + brilho que passa de vez em quando |
| 3 | Rara | 18% | moldura entalhada com folhas/flores + brilho contínuo + selo de estrela |
| 4 | Holográfica | 7% | moldura prateada + reflexo arco-íris que se mexe (shader) ao arrastar o dedo/inclinar |

- **Melhorar depois:** fotos de momentos que se repetem (cochilos, travessuras, passeios, amigos, datas) podem ser
  **tiradas de novo**; cada repetição sorteia outra vez e a foto só **sobe** de nível (nunca cai). Assim colecionar
  "todas holográficas" vira meta longa. Fotos únicas da História sorteiam uma vez, com chance melhor (são marcos).
- **Garantia (pity):** a cada 10 fotos sem Rara+, a próxima é no mínimo Rara; a cada 30 sem Holográfica, a
  próxima é Holográfica. Contadores salvos.
- Sorteio com semente (`Loot`), gravado no estado da foto (`rarity`, `rolls`), sem ressortear ao recarregar.

## 2. A festa de ganhar uma foto (revelação)

Ao tirar uma foto, entra na fila modal (depois do que estiver aberto) a **revelação**:
1. Uma polaroide virada para baixo cai na tela com o título ("Nova foto: Penetra!"). Toque para revelar.
2. A foto "revela" (do branco para a ilustração, como polaroide de verdade).
3. As molduras **giram** como uma roleta (Comum → Brilhante → Rara → Holográfica…) e vão desacelerando até parar
   na raridade sorteada; vibração e confete proporcionais (Holográfica = confete + brilho na tela inteira).
4. Cartão final: foto grande com a moldura, nome, data, selo da raridade, progresso da seção ("Travessuras 5/9")
   e botões **"Guardar no álbum"** (verde) e **"Pôr na home"** (amarelo).
- Se a foto já existia e subiu de nível: "Melhorou! Comum → Rara". Se não subiu: sem roleta, só um aviso curto
  "Foto repetida — ficou com a Brilhante" (sem interromper).
- "Menos animação": pula o giro e mostra o resultado direto.

## 3. Álbum novo (tela própria, em madeira)

- Abre pela aba Álbum do caderninho e pelo toque nas fotos da home. Em vez da grade de 4 quadradinhos:
  **um livro** com páginas de **2 polaroides grandes por linha** (≈150 px de largura, ilustração nítida), abas das
  seções no topo e, por seção, contador `5/9` + mini-contagem por raridade (●●●●).
- **Foto que você tem:** ilustração com a moldura da raridade, título embaixo, o holográfico brilhando na grade.
- **Foto que falta:** a própria ilustração **borrada e escurecida** (dá vontade de descobrir) + cadeado e uma
  **pista clara com ícone** (ver 4). Fotos secretas mostram "???" até a primeira pista.
- **Detalhe:** foto em tela cheia, raridade, data e fase do Tiro, "Pôr na home"/"Tirar da home", contagem de
  vezes tirada e a chance de melhorar ("Pode melhorar: tire de novo!").
- Topo do álbum: total `32/54`, quantas holográficas, e a faixa **"Quase lá"** com 1–3 fotos que estão perto de sair
  (condições quase cumpridas) com botão Ir.

## 4. Pistas mais claras

Cada foto que falta mostra **o que fazer** em uma linha, com o ícone da ação e, quando der, progresso:
- Nível 1 (sempre visível): ação + onde. Ex.: 🛁 "Dê banho no Tiro à noite", 🐾 "Passeie 5 vezes (3/5)".
- Fotos secretas: começam com a pista poética atual ("Tem alguém sempre aparecendo...") e a **lupa** (já existe,
  1 por dia, +1 com a câmera antiga) transforma em pista concreta. Personagens também dão a pista ao conversar
  (já existe `hint_npc`), agora com o botão Ir.
- Dados: campo novo `goal_hint` por foto em `album.json` (texto + ícone + contador opcional).

## 5. Fotos na home (3 em destaque)

- Na tela principal do Tiro, um **varal/prateleira de madeira** com até **3 polaroides** escolhidas, visíveis e
  tocáveis (toque abre a foto grande). Lugar proposto: na parede, acima/ao lado do Tiro, sem cobrir a bandeja das
  necessidades, o caderninho nem o botão Cuidar. Holográfica brilha ali também.
- Escolher: "Pôr na home" no detalhe/revelação; com 3 cheias, pede qual trocar (toque na que sai).
- Vazio: 3 molduras vazias discretas com "+" que abrem o álbum (só depois da primeira foto).
- A parede/moldura da Casa no mapa fica para depois (como pedido).

## 6. Recompensas de coleção (opcional, para instigar)

- Completar uma seção: moedas + um enfeite (ex.: moldura especial para a home).
- Marcos de raridade: 5 / 15 / 30 fotos Rara+; primeira Holográfica = conquista no álbum.

## Etapas sugeridas (uma por sessão)

1. Estado e regras: raridade, repetição que melhora, garantias, `SAVE_VERSION` novo (saves zerados).
2. Molduras e efeitos: 4 molduras de madeira/ouro/folhas/prata + shader holográfico + brilho (arte a partir de `IUREF`/PixelLab).
3. Revelação com roleta (fila modal, festa por raridade, "Menos animação").
4. Álbum novo + detalhe + "Quase lá".
5. Pistas claras (`goal_hint`, progresso, Ir) e lupa ajustada.
6. Fotos na home (3 destaques) e escolha.
7. Recompensas de coleção + fechamento (capturas nas 3 resoluções, testes da área, tour).

## Decisões do Vitor (06/11/2026)
- Raridade **pode melhorar**: momentos que se repetem sorteiam de novo e a foto só sobe de nível.
- Chances **mais generosas**: Comum 45%, Brilhante 30%, Rara 18%, Holográfica 7% (garantias 10/30 mantidas).
- Home: **varal na parede** com 3 polaroides presas por pregadores, acima do Tiro.
- **Com recompensas** de coleção (seções completas, marcos de Rara+, primeira Holográfica).
- As 54 ilustrações (Codex) conferidas: todas com `photo.illustration` e PNG importado com mipmaps.
- **Etapa 1 concluída (06/11/2026)**: ver CLAUDE.md "Fotos do Tiro — etapa 1".
- **Coleção de estilos (pedido do Vitor, 06/11/2026):** cada foto guarda TODAS as variantes de raridade já
  conseguidas (não só a melhor); o jogador escolhe qual variante mostrar. Ação paga **"Revelar de novo"** para
  qualquer foto já tida (inclusive da História): sorteia outra variante com as mesmas chances/garantias, custa
  materiais mais difíceis/raros + moedas (dados em `album.json → reroll`, sobe a cada revelação, com teto).
  Meta: completar os 4 estilos de cada foto (contagem "estilos completos" no álbum e nas recompensas).
