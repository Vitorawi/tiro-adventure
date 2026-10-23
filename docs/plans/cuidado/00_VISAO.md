# 00 — Visão: cuidar é crescer

## Diagnóstico (dados de 23/10/2026)

| Sistema | Como está | Problema |
|---|---|---|
| **Coragem** | carinho = 1 ponto, no máximo um a cada 120 s (`care_affection_cooldown`); adulto pede Coragem nível 8 = **220 pontos** (`growth.json → levels`) | o maior esforço do jogo é esfregar a cabeça do Tiro com espera entre um e outro |
| **Esperteza / Pelagem** | brincar 3 pontos (recarga 300 s), banho 3 (2 h), escova 5 (4 h); níveis 6–8 = 135–220 pontos | mesma moeda de pontos; repetir a ação é o caminho |
| **Necessidades** (Barriga, Felicidade, Energia, Higiene) | única consequência: "Radiante" (todas ≥ 60 → ×1,5 nos pilares) e a energia do passeio | ninguém percebe o efeito; cuidar ou não cuidar dá quase no mesmo |
| **Desejos** | até 3 espaços, novo a cada 600 s, sorteio por peso; prêmio 2–8 moedas + afeto; vínculo em corações (8 níveis) | pedido constante e aleatório, sem relação com a fase nem com o que falta para crescer |
| **Diárias/semanais** | `care`, `care_week`, `tiro_walk` pedem cuidado útil e passeio | terceiro sistema pedindo a mesma coisa que necessidade e desejo |
| **Vínculo** | afeto → corações; trava espaços de desejo, truques (`bond` 2–5) e passeios longos (`bond` 3–5) | segunda barra de progresso do Tiro, paralela ao crescimento |

Resumo: **três sistemas pedem a mesma coisa e duas barras medem o mesmo cachorro.** O crescimento já é o
objetivo do jogo (plano "Tiro no centro"); o resto tem que alimentar o crescimento, não competir com ele.

## O modelo novo

```
 necessidade baixa ──┐
                     ├──► cuidado útil ──► MOMENTO do pilar ──► requisitos da fase ──► cresce
 desejo do período ──┤                                ▲
 novidade (passeio,  ┘                                │
 lugar, amigo, truque) ───────────────────────────────┘

 tudo em dia ──► "Tiro animado" ──► ajuda na horta, no passeio e no faro
```

1. **Necessidade = quando dá para cuidar.** Cada necessidade abre a porta de um pilar. Cuidar só vale
   quando ele precisa; cuidar de novo, com ele satisfeito, só dá a animação fofa.
2. **Momento = a unidade do crescimento.** Os pilares deixam de ter pontos (10/25/45/… até 330) e passam a
   contar **momentos**: cada momento é uma coisa de verdade que aconteceu (ele estava carente e ganhou
   carinho, conheceu a Vila, aprendeu um truque). Uma fase pede de 2 a 8 momentos por pilar.
3. **Desejo = a voz do crescimento.** Um pedido por período do dia (manhã, tarde, noite), escolhido pelo
   que **falta para a fase** e pelo que ele está precisando. Atender = um momento garantido. Pedidos de
   comida puxam a fazenda (cozinhar *para o Tiro*).
4. **Tiro animado = utilidade.** Quando nada está pedindo, ele fica animado e isso aparece no jogo: ajuda na
   colheita, traz mais coisa do passeio, acha mais montinhos. Nunca castiga quem ficou fora.
5. **Gesto em vez de repetição.** Carinho é segurar (e descobrir o lugar favorito), não esfregar dez
   vezes; Esperteza ganha um esconde-esconde curto além da bola.

## Princípios

- **Simplificar antes de acrescentar.** Cada etapa remove pelo menos tanto quanto cria. O que sai está
  listado abaixo e é removido de verdade (código, dados, testes, textos), não só escondido.
- **Uma barra de progresso do Tiro**: o crescimento. Sem vínculo paralelo.
- **Um pedido por vez.** No máximo um desejo ativo; a tela do Tiro mostra o que ele precisa agora.
- **Sem punição.** Necessidade baixa não tira nada; só deixa de dar o bônus de "animado".
- **Visual e simples** (regra do projeto): ícone + número; "Coragem ●●●○○" em vez de "Coragem 45/70".
- **Saves sempre zerados** (pedido do Vitor): sem migração, sem teste de save antigo, sem piso legado novo.

## O que sai

| Sai | Substituído por |
|---|---|
| pontos de pilar, `levels`, `cap`, `reserve`, Radiante (`radiant`) | momentos por fase ([02 B](02_DESENHO.md#b-momentos)) |
| recargas de ganho (`care_affection_cooldown`, `cooldown` em `growth.json → sources`) | necessidade baixa + teto por período |
| `nap` como fonte de Corpo | Corpo vem só das refeições da fase |
| afeto, vínculo, `bond_levels`, `BondChip`, requisito `bond` | requisito `growth`/momentos |
| até 3 espaços de desejo, `refill_seconds`, trocar desejo | um desejo por período |
| aba **Desejos** | balão do desejo na tela do Tiro e no avatar do HUD |
| diárias/semanais `care`, `care_week`, `tiro_walk` | desejos (o Tiro) × rotinas (só fazenda) |

## O que fica

Fases, refeições da fase (`feed.body_level`), itens-chave, cerimônia, álbum, Casa, paladar, jeito, seda,
passeios, truques (com requisito trocado), história e capítulos. A ordem do ritmo-alvo do plano anterior
continua (Filhotinho na primeira sessão, Dentinhos dia 1–3, Aventureiro 5–8, Mocinho 10–14, adulto 18–24).
