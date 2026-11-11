# 01 — Desenho da pesca (regras e números)

Todos os números ficam em `game/data/fishing.json` e podem mudar sem código. Os valores abaixo são o
**ponto de partida** da etapa 00 (vêm da especificação do Vitor, convertidos para frações da pista).

## 1. O ciclo de uma pesca

```
PARADO ──toque na lagoa──► MIRAR (vara + isca)
  ──segurar "Arremessar"──► FORÇA (o ponteiro vai e volta) ──soltar──► a boia cai numa ZONA
  ──► ESPERA (boia balança; 4–10 s, menos na bolha)
  ──► MORDIDA (boia afunda + "!" + Tiro late) ──tocar em até 1 s──► MINIGAME
        (tocar antes da mordida = recolher sem gastar; não tocar a tempo = o peixe vai embora, a isca fica)
  ──► MINIGAME: segurar sobe a barra, soltar desce; peixe dentro enche a rede, fora esvazia
        rede cheia (1,0) ──► PEGOU (tamanho, recorde, prêmios)
        rede vazia (0,0) ──► ESCAPOU (a isca foi junto)
  ──► "Pescar de novo" (mesma vara e isca, sem voltar ao menu) ou "Sair"
```

A isca é gasta **no toque da mordida**. Se o app fechar no meio do minigame, a partida é cancelada e a isca
volta (o peixe não é sorteado de novo: a semente fica no save até a próxima pesca).

## 2. Física da barra (`fishing.json → physics`)

A pista vai de `y = 0` (fundo) a `y = 1` (topo). Tudo é fração da altura da pista na tela.

| Campo | Valor inicial | Equivale na pista de 568 px do Vitor |
|---|---|---|
| `bar_base` | 0,169 | 96 px |
| `bar_per_level` | 0,014 | 8 px por nível de pesca |
| `thrust` | 2,11 /s² | 1200 px/s² |
| `gravity` | 1,73 /s² | 980 px/s² |
| `drag` | 1,8 /s | — |
| `bounce` | 0,45 | — (no topo a barra só para, `v = 0`) |
| `tick` | 1/60 s | passo fixo acumulado |

Segurando: `a = thrust − drag·v`. Soltando: `a = −gravity − drag·v`. O campo `gravity_on_hold`
(padrão `false`) liga a outra opção (`a = thrust − gravity − drag·v`, subida mais pesada) só para comparar
na etapa 00; fica a que for **mais fácil de controlar** (decisão do Vitor).
Velocidade máxima ≈ 1,17 pista/s subindo e 0,96 descendo: atravessa a pista em ~1 s.

Altura final da barra:
`bar = bar_base + bar_per_level·nível_de_pesca + vara.bar_bonus + (Tiro animado ? animated_bonus : 0)`,
limitada a `bar_max` 0,34. `animated_bonus` = 10% de `bar_base` (≈ 0,017).

O dedo vale em **qualquer lugar da tela** durante o minigame (inclusive em cima da pista), menos no botão
de pausar. Vários dedos = segurando enquanto algum estiver na tela.

## 3. Rede (medidor de captura) (`fishing.json → meter`)

| Campo | Valor | Notas |
|---|---|---|
| `start` | 0,30 | |
| `fill` | 0,18 /s | peixe com o **centro** dentro da barra |
| `drain` | 0,12 /s | fora da barra |
| `fill_mult/drain_mult` por espécie | 0,8–1,2 | peixe grande enche mais devagar |
| `vara.hold` (γ) | 0 / 0,15 / 0,30 | reduz o dreno: `drain·(1−γ)` |

Partida mais rápida ≈ 3,9 s; partida típica 8–15 s. **Captura perfeita** = o peixe nunca saiu da barra
depois do primeiro segundo (1 s de folga para o jogador achar o peixe): sobe uma classe de tamanho (máx.
Gigante) e multiplica o XP de pesca por `perfect_xp_mult` 2,4.

## 4. Baú da lagoa (a partir da vara 2)

- Chance `chest.chance` 15% por partida (nunca no tutorial nem na primeira partida de uma espécie).
- Aparece depois de 2 s numa altura sorteada longe do peixe e fica parado (balança só visualmente).
- Rede própria: enche a `chest.fill` 0,5 /s enquanto a barra cobre o baú (2 s), **não esvazia**.
- Só entrega se o baú encheu **e** o peixe foi pego. Peixe escapou = baú perdido.
- Conteúdo em `chest.loot` (sorteio com semente): moedas 10–30, parafuso, sementes, 1 isca artificial
  (raro), pedaço de mapa nunca. Item que não cabe vira recibo (`_grant_automatic("fish_chest:<n>")`).

## 5. Comportamento dos peixes (`motion`)

O peixe escolhe um ponto `alvo ∈ [0,1]` e vai até ele; ao chegar espera um pouco e escolhe outro.
A dificuldade `D` (1–100) da espécie controla:
`velocidade = lerp(0,25, 1,2, D/100)` pistas/s; `pausa = lerp(1,2, 0,3, D/100)` s.

| `motion` | Como escolhe o próximo alvo | Peixes |
|---|---|---|
| `mixed` | sobe/desce por igual, movimento suave com um pouco de ruído | tilápia |
| `smooth` | alvos longe, curva de aceleração em S, previsível | cará, tambaqui |
| `sinker` | 75% para baixo, desce rápido (×1,5) e sobe devagar | carpa, pintado |
| `floater` | 75% para cima, arrancada para cima e flutua devagar para baixo | lambari, pacu |
| `darter` | como `mixed`, mais arrancadas instantâneas (média `D/100·0,8` por segundo) | traíra, tucunaré |

"Menos animação" **não** muda a física (só tira respingos e brilhos). O movimento usa a semente do `cast`.

## 6. Arremesso, zonas e bolhas

- **Força:** segurar o botão "Arremessar" faz um ponteiro ir e voltar numa barrinha (1,2 s por volta);
  soltar define a distância. Três zonas iguais: **Perto (1) · Meio (2) · Longe (3)**.
- **Bolha** (ponto quente): no máximo uma por vez na lagoa; aparece de 20 a 40 min de relógio real e some
  10 min depois (timestamps: vale com o app fechado). Arremessar perto dela (o jogo "puxa" a boia se o
  ponto escolhido cair a menos de um raio) = espera ×0,25 e +1 zona (máx. 3).
- Zona maior = mais chance do peixe **maior do grupo** e +0,05 no tamanho por zona acima de 1.
- Espera: `4–10 s` sorteado (`wait`), ×0,25 na bolha; o Tiro animado não muda a espera.

## 7. Varas e iscas

| Vara | Como consegue | `bar_bonus` | `hold` γ | Rebote | Iscas que aceita |
|---|---|---|---|---|---|
| **Vara de bambu** `bamboo_rod` | Vovó Bloblo, cap. 2 (missão) | 0 | 0 | 0,45 | Minhoca |
| **Vara de molinete** `reel_rod` | Feirante da Vila, cap. 5: 180 moedas + 4 fibras + nível de pesca 3 | +0,025 | 0,15 | 0,30 | Minhoca, Massa |
| **Vara do pescador** `angler_rod` | Missão do Guia, cap. 7–8 (feita na bancada) | +0,05 | 0,30 | **0** (sem repique) | as três |

A vara escolhida é a melhor que você tem (pode trocar no painel de arremesso). A **isca escolhe o grupo**:

| Isca | Grupo | Comprar | Fazer / achar |
|---|---|---|---|
| **Minhoca** `bait_worm` | peixes da vara 1 | banca da vovó (aba Comprar): 5 por 10 moedas | 15% de chance de 1 ao colher na horta |
| **Massa de milho** `bait_dough` | peixes da vara 2 | Feirante (aba Comprar): 4 por 20 moedas | fogão: 2 milhos → 4 (5 min; o milho abre no cap. 5, junto da vara 2) |
| **Isca artificial** `bait_lure` | peixes da vara 3 | Feirante (aba Comprar): 1 por 25 moedas | bancada (após a vara 3): 1 cobre + 1 graveto → 1. **Não gasta em 70% das pescas** (é reutilizável) |

As iscas ficam na **Mochila sem depósito** (`storage: none`, como a Ração), para não disputar o espaço
pequeno da Despensa e do Cesto no começo. Os peixes vão para a **geladeira/Despensa** (`storage: fridge`).

## 8. Os 9 peixes (realistas, de lagoa/açude brasileiro)

| Isca/vara | Peixe `id` | Tamanho real (cm) | `motion` | D | Peso no sorteio Perto/Meio/Longe | Venda | Notas |
|---|---|---|---|---|---|---|---|
| Minhoca | **Lambari** `fish_lambari` | 6–15 | floater | 15 | 50/35/20 | 4 | o primeiro do tutorial; nada na superfície |
| Minhoca | **Cará** `fish_cara` | 8–22 | smooth | 22 | 30/35/35 | 6 | |
| Minhoca | **Tilápia** `fish_tilapia` | 15–40 | mixed | 30 | 20/30/45 | 9 | **o ingrediente da papinha** |
| Massa | **Carpa** `fish_carp` | 30–75 | sinker | 40 | 45/35/25 | 14 | fuça o fundo |
| Massa | **Pacu** `fish_pacu` | 25–60 | floater | 48 | 35/35/30 | 16 | sobe para comer na superfície |
| Massa | **Tambaqui** `fish_tambaqui` | 40–90 | smooth | 55 | 20/30/45 | 20 | pesado, `fill_mult` 0,85 |
| Artificial | **Traíra** `fish_traira` | 20–55 | darter | 60 | 45/35/25 | 18 | ataca a isca de surpresa |
| Artificial | **Tucunaré** `fish_tucunare` | 30–70 | darter | 75 | 35/35/35 | 26 | o mais rápido |
| Artificial | **Pintado** `fish_pintado` | 50–110 | sinker | 85 | 20/30/40 | 34 | de fundo; `fill_mult` 0,8 |

Garantia da história: enquanto uma missão pedir uma espécie (`fish:<id>`), ela vale no mínimo 50% do grupo.
A primeira tilápia vem no máximo na 3ª pesca com minhoca (para o capítulo 3 não travar).

## 9. Tamanho, classe e recorde

Pontuação da partida: `q = tempo_dentro / tempo_total` (0–1), contada depois do primeiro segundo.

```
f = 0,55·q + 0,45·sorte + 0,05·(zona − 1)            # sorte ∈ [0,1) pela semente
f = limita(f, 0, 1); perfeita → sobe uma classe
cm = min + f·(max − min), arredondado a 0,5 cm
```

| Classe | `f` | Rende | Selo |
|---|---|---|---|
| Pequeno | < 0,35 | 1 peixe | — |
| Médio | 0,35–0,70 | 1 peixe | — |
| Grande | 0,70–0,90 | 1 peixe + 50% XP | estrela |
| **Gigante** | ≥ 0,90 | **2 peixes** + XP ×2 | coroa + confete |

Garantia: 8 capturas seguidas sem Grande+ → a próxima tem `f ≥ 0,70`.
Recorde por espécie no save: `best_cm`, `best_class`, `count`, `gigantes`, `perfects`, `first_at`.
Bater o recorde mostra "Novo recorde! 32,5 cm (antes 28 cm)".

## 10. Nível de pesca (XP próprio, como os locais da Natureza)

`xp` por captura = `fish.xp` (lambari 3 … pintado 20) × classe (×1, ×1, ×1,5, ×2) × perfeita (×2,4).
Níveis em `fishing.json → levels`: 1 (0) · 2 (30) · 3 (90) · 4 (200) · 5 (400). Cada nível = barra +0,014.
Subir de nível mostra um aviso de madeira ("Pesca nível 3: a barra cresceu!"), sem cerimônia grande.

## 11. O que a pesca dá ao Tiro

- **Momento de Coragem** na primeira vez que o Tiro vê cada espécie (`growth.json → moments.sources`,
  fonte `fish_first`), com teto normal da fase.
- Os **pratos** de peixe (02_HISTORIA §2) são comida de crescimento e entram em requisitos de fase.
- Tiro animado = barra maior (§2). O Tiro **não** pode pescar dormindo nem passeando (a lagoa diz "Ele está
  no passeio" e a pesca fica para depois), igual aos outros cuidados.

## 12. Esboço do `fishing.json`

```json
{
  "schema": 1,
  "physics": {"bar_base": 0.169, "bar_per_level": 0.014, "bar_max": 0.34, "thrust": 2.11,
              "gravity": 1.73, "drag": 1.8, "bounce": 0.45, "tick": 0.0166667, "animated_bonus": 0.017},
  "meter": {"start": 0.30, "fill": 0.18, "drain": 0.12, "grace": 1.0, "perfect_xp_mult": 2.4},
  "cast": {"power_period": 1.2, "zones": 3, "wait": [4, 10], "bite_window": 1.0},
  "bubbles": {"every_min": [20, 40], "lasts_min": 10, "wait_mult": 0.25, "zone_bonus": 1},
  "chest": {"chance": 0.15, "appear_after": 2.0, "fill": 0.5, "from_rod": "reel_rod", "loot": []},
  "classes": [{"id": "small", "min": 0}, {"id": "medium", "min": 0.35},
              {"id": "large", "min": 0.70, "xp": 1.5}, {"id": "giant", "min": 0.90, "xp": 2, "qty": 2}],
  "pity_large": 8,
  "levels": [0, 30, 90, 200, 400],
  "rods": {"bamboo_rod": {"tier": 1, "bar_bonus": 0, "hold": 0, "bounce": 0.45}},
  "baits": {"bait_worm": {"tier": 1}},
  "fish": {"fish_lambari": {"bait": "bait_worm", "cm": [6, 15], "motion": "floater", "difficulty": 15,
                            "weights": [50, 35, 20], "xp": 3}}
}
```

`Database.fishing()` lê; `Database.fishing_problems()` valida (toda isca tem grupo, todo peixe tem item e
ícone, pesos com 3 zonas, faixas min < max) e entra no `content_test`.
