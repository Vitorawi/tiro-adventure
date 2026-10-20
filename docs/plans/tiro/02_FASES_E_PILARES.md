# 02 — Fases, pilares e requisitos (autoritativo)

Tudo aqui vira dado em `game/data/growth.json` (etapa 02 cria; etapas seguintes completam). Os números são
alvos iniciais; ajustes vão para [DECISOES](DECISOES.md).

## A. As fases

O Tiro começa como **Recém-chegado** (só os primeiros minutos) e cresce **5 vezes**.

| # | id | Nome | Idade | Peso | Corpo de arte | Cresce no fim do | Teto dos pilares |
|---|---|---|---|---|---|---|---|
| 0 | `newborn` | Recém-chegado | 2 meses | 0,4 kg | filhote | — (início) | 1 |
| 1 | `puppy` | Filhotinho | 3 meses | 0,9 kg | filhote | capítulo 1 | 2 |
| 2 | `teething` | Dentinhos | 5 meses | 1,6 kg | jovem | capítulo 3 | 4 |
| 3 | `explorer` | Aventureiro | 8 meses | 2,3 kg | jovem | capítulo 6 | 6 |
| 4 | `young` | Mocinho | 1 ano e meio | 2,8 kg | adulto + pelo escuro | capítulo 9 | 8 |
| 5 | `adult` | Azul e Dourado | 2 anos e meio | 3,0 kg | **adulto = Tiro atual** | capítulo 12 | 10 |
| ✦ | `silk_1..3` | Pelagem de seda I–III | — | — | adulto + brilho | pós-jogo (etapa 17) | — |

Pesos dentro do padrão da raça (até 3,2 kg). Corpos de arte e cor: [06](06_INTERFACE_E_ARTE.md), seção E.

### Aparência e jeito por fase

| Fase | Aparência (segredo até crescer) | Comportamento novo | Fato real (caderneta, 1 linha) |
|---|---|---|---|
| Recém-chegado | bolinha preta com manchas castanhas, orelhas caídas, cabeção | tímido, dorme muito, fica perto da caminha | "Yorkies nascem quase todos pretos, com manchinhas castanhas." |
| Filhotinho | ainda pequeno, olhar curioso, orelhas caídas | tropeça ao correr, cochilos curtos | "Filhotes pequenos fazem várias refeições pequenas por dia." |
| Dentinhos | **orelhas em pé**, corpo alongando | morde tudo, rouba meia, primeiros truques | "Os dentes de leite caem entre 4 e 7 meses; morder alivia a coceira." |
| Aventureiro | pernas compridas, pelo bagunçado | corridas loucas, fareja tudo, quer sair | "Yorkies eram caçadores de ratinhos nas fábricas de Yorkshire." |
| Mocinho | forma adulta, pelo comprido ainda escuro, raiz azulando | mais calmo, acompanha você no Sítio | "O pelo do Yorkie é parecido com cabelo e cresce sem parar." |
| Azul e Dourado | **revelação da cor**: azul-aço e dourado, "ar importante" | anfitrião da Praça, senta no banco com a turma | "Entre 1 e 3 anos o preto vira azul-aço e o castanho vira dourado." |

Fatos extras para a caderneta (um por cartão, sorteio fixo por fase): orelhas em pé entre 3 e 6 meses;
lacinho no topete para tirar a franja dos olhos; Smoky, Yorkie de 1,8 kg, heroína em 1944; o padrão da raça
pede um "ar importante"; tamanho adulto por volta de 1 ano.

## B. Os quatro pilares (atributos do Tiro)

| id | Nome | Ícone (novo, 32 px) | O que representa |
|---|---|---|---|
| `body` | Corpo | `pillar_body` (ossinho) | ossos, dentes, força |
| `coat` | Pelagem | `pillar_coat` (pente com brilho) | brilho e saúde do pelo |
| `smart` | Esperteza | `pillar_smart` (lâmpada) | faro, truques, curiosidade |
| `brave` | Coragem | `pillar_brave` (estrelinha) | confiança e socialização |

Coragem **não** usa coração (coração é vínculo/afeto).

**Níveis (pontos acumulados):** 1 = 10 · 2 = 25 · 3 = 45 · 4 = 70 · 5 = 100 · 6 = 135 · 7 = 175 · 8 = 220 ·
9 = 270 · 10 = 330.

**Teto por fase (padrão ascensão):** o nível de cada pilar não passa do teto da fase atual (tabela A).
Pontos ganhos acima do teto ficam numa **reserva** por pilar (mostrada como "+N guardado"), limitada ao teto
da fase seguinte, e entram sozinhos quando ele cresce. Nada se perde.

**Radiante (bem-estar):** se as 4 necessidades estão em 60 ou mais no momento do ganho, todo ganho de pilar
vale ×1,5 (arredondado para cima) e aparece um brilho. Necessidade baixa **nunca** tira pontos.

## C. O que cada fase pede para crescer

Estrutura fixa: 📊 pilares · 🔑 item-chave do capítulo (entregue no painel; vira lembrança na Casa) ·
🍲 refeição da fase (dar de comer durante a fase) · 🌿 algo do mundo ou do cuidado. Entre 3 e 4 requisitos.
O **último** requisito típico é o mais rápido (efeito "quase lá"). Cada fase **começa com algo já cumprido**
quando faz sentido.

| Crescer para | 📊 Pilares | 🔑 Item-chave | 🍲 Refeição | 🌿 Extra |
|---|---|---|---|---|
| Filhotinho | Corpo 1, Coragem 1 | Caminha (`owned: dog_bed`, missão `lais_bed`) | dar comida ×3 (qualquer) | "Chegou em casa" ✓ (já vem cumprido) |
| Dentinhos | Corpo 2, Coragem 2 | Argolinha de morder `chew_ring` (vovó Bloblo) | Cenoura gelada `frozen_carrot` ×3 | — |
| Aventureiro | Corpo 4, Esperteza 3, Coragem 4 | Mordedor de graveto `stick_chew` (bancada) | Ração de crescimento `growth_kibble` ×3 | 3 passeios nesta fase |
| Mocinho | todos 6 | Escova macia `soft_brush` (bancada) | Mingau de leite `milk_porridge` ×3 | 2 banhos com xampu de ervas |
| Azul e Dourado | todos 8 | Medalhinha de coragem `courage_medal` (história, cap. 12) | a comida favorita dele ×3 | Lacinho do topete `topknot_bow` costurado (coleção) |

**Versão provisória (etapa 02):** enquanto os itens novos não existem, o `growth.json` usa só pilares e
coisas existentes — Filhotinho: igual; Dentinhos: `carrot_snack` ×3 + `owned: blender`; Aventureiro:
`vegetable_soup` ×3 + `owned: workbench` + 3 passeios; Mocinho: `pumpkin_mash` ×3 + `owned: atelier`;
Azul e Dourado: `owned: atelier` + projeto `village_festival`. As etapas 09 e 10 trocam para a tabela final.

**Tipos de requisito** (`growth.json → phases[].requirements[]`, cada um com `id` estável):

| type | Campos | Conta como cumprido quando |
|---|---|---|
| `pillars` | `levels: {body: 2, …}` | nível de cada pilar ≥ alvo |
| `deliver` | `item`, `qty` | o jogador entregou no painel (consome; definitivo) |
| `feed` | `item` (id, `"any"` ou `"favorite"`), `qty` | o Tiro comeu isso durante a fase (contador da fase) |
| `stat` | `counter`, `qty` | contador cresceu `qty` desde o começo da fase |
| `owned` | `upgrade` | a construção é do jogador |
| `quest` | `quest` | a missão foi recebida |
| `project` | `project` | a obra foi concluída |
| `collection` | `collection` | a roupa/apetrecho é do jogador |
| `given` | `label` | sempre cumprido (progresso concedido) |

Requisito cumprido **nunca volta atrás** (fica gravado em `growth.done[fase][id]`).

## D. De onde vêm os pontos

| Ação (sempre pelo `GameState`) | Pilar e pontos | Condição / recarga |
|---|---|---|
| Dar comida com campo `growth` | conforme [03](03_COMIDAS_E_ECONOMIA.md) | ×1 se adequada à fase, ×0,5 se não |
| Dar ração (`dog_food`) | Corpo 2 | só Recém-chegado e Filhotinho |
| Dar comida crua (cenoura, maçã…) | 0 (só mata a fome e conta "primeira vez") | — |
| Banho útil (`care_useful`) | Pelagem 3 | recarga de pilar 2 h |
| Banho com xampu de ervas | Pelagem 12 (no lugar dos 3) | consome 1 xampu; mesma recarga |
| Escovar (etapa 12) | Pelagem 5; com escova macia 8 | recarga 4 h |
| Brincar útil | Coragem 2 + Esperteza 1 (+1 Esperteza com cesto de brinquedos) | recarga de pilar 30 min |
| Carinho útil (quando dá afeto) | Coragem 1 | recarga existente de 120 s |
| Desejo atendido | Coragem 3 (especial 6) | — |
| Volta de passeio | Coragem: park_loop 3, flower_street 4, village_fair 5, sunset_walk 6, creek_walk 7, bird_clearing 8, hill_view 10 | uma vez por passeio |
| Cavar um achado do faro | Esperteza 3 | — |
| Aprender truque | Esperteza 12 | uma vez por truque |
| Mostrar truque | Esperteza 1 | recarga existente do truque |
| Petisco para amigo / visita de amigo recebida | Coragem 2 / 4 | regras existentes dos amigos |
| Primeira conversa com um personagem | Coragem 3 | uma vez por personagem |
| Primeira vez num mundo com o Tiro presente | Coragem 2 + Esperteza 2 | uma vez por mundo |
| Uso de obra contado (banco, piquenique, festa) | Coragem 3 | regras existentes de uso |
| Acordar de soneca ≥ 1 h com energia 100 | Corpo 2 | uma vez a cada 12 h |

Todos os ganhos passam por **uma** função (`GameState._gain_pillar(id, pontos, origem)`) que aplica teto,
reserva, Radiante e emite o evento. Nada de ganho paralelo na interface.

## E. Ritmo alvo (perfil de referência, dias de jogo)

| Crescimento | Alvo | Por quê |
|---|---|---|
| Filhotinho | primeira sessão (≤ 30 min) | apego começa cedo |
| Dentinhos | dia 1–3 | antes do dia 7, quando a maioria desiste |
| Aventureiro | dia 5–8 | — |
| Mocinho | dia 10–14 | — |
| Azul e Dourado | dia 18–24 | campanha atual ≈ 21 dias |

Ritmo **não** é medido a cada etapa (sem simulação). A etapa 17 mede uma vez; o Vitor simula quando quiser.

## F. Presentes e liberações de cada fase

| Fase | Presente | O que libera (requisito `growth` no dado existente) |
|---|---|---|
| Filhotinho | 30 moedas + ração ×3 | aba Desejos (além de `lais_bed`) |
| Dentinhos | 60 moedas + cesto de roupa (Casa) | truques Dá a pata e Fala; escova básica (etapa 12) |
| Aventureiro | 100 moedas + cesto de brinquedos (Casa) | truques Rola e Pula; passeios creek_walk, bird_clearing, hill_view; jeito revelado |
| Mocinho | 150 moedas + receita do lacinho do topete | truque Gira; caminha macia (etapa 14) |
| Azul e Dourado | 250 moedas + título "Guardião do Vale" | Pelagem de seda; caminha de luxo |

Requisitos `growth` se somam aos existentes (vínculo, missões). Como os saves recomeçam (etapa 02), não há caso de
save antigo preso.

## G. Pelagem de seda (pós-jogo, etapa 17)

Três níveis, só cosméticos (brilho que desliza no pelo; ver 06): I = Pelagem 10 + 5 escovações em dias
diferentes + 3 banhos com xampu; II = 10 dias + 6 banhos; III = 20 dias + 10 banhos. Cada nível: cartão na
caderneta e um presente pequeno (50 / 80 / 120 moedas). Nunca exige comprar nada novo.

## H. Formato do `growth.json`

```json
{
  "schema": 1,
  "pillars": {
    "body":  {"name": "Corpo",     "icon": "pillar_body"},
    "coat":  {"name": "Pelagem",   "icon": "pillar_coat"},
    "smart": {"name": "Esperteza", "icon": "pillar_smart"},
    "brave": {"name": "Coragem",   "icon": "pillar_brave"}
  },
  "levels": [10, 25, 45, 70, 100, 135, 175, 220, 270, 330],
  "radiant": {"min_need": 60, "multiplier": 1.5},
  "phases": [
    {"id": "newborn", "name": "Recém-chegado", "age": "2 meses", "weight": "0,4 kg", "body": "puppy",
     "coat": 0.0, "cap": 1, "facts": ["Yorkies nascem quase todos pretos, com manchinhas castanhas."]},
    {"id": "puppy", "name": "Filhotinho", "age": "3 meses", "weight": "0,9 kg", "body": "puppy",
     "coat": 0.0, "cap": 2, "chapter": 1,
     "requirements": [
       {"id": "home", "type": "given", "label": "Chegou em casa"},
       {"id": "bed", "type": "owned", "upgrade": "dog_bed"},
       {"id": "meals", "type": "feed", "item": "any", "qty": 3},
       {"id": "pillars", "type": "pillars", "levels": {"body": 1, "brave": 1}}
     ],
     "rewards": {"coins": 30, "items": {"dog_food": 3}},
     "unlocks_text": ["Desejos"]}
  ],
  "sources": {"bath": {"coat": 3, "cooldown": 7200}, "walk": {"park_loop": {"brave": 3}}}
}
```

O `Database` valida o arquivo (referências a itens/missões/construções existentes, ids únicos, níveis
crescentes) e expõe `Database.growth`; erro de validação aparece no `content_test`.
