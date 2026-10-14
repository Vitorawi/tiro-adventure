# Plano — Armazenamento com limite (estilo Hay Day)

Hoje o `Inventory` (`scripts/state/inventory.gd`) é infinito: `item_id -> quantidade`.
Este plano põe **capacidade por tipo de depósito**, melhorável com **missões + materiais**.

## Ideia
| Depósito | Guarda (`category` em items.json) | Onde fica | Começa com |
|----------|-----------------------------------|-----------|-----------|
| Geladeira | `food` perecível (petiscos, ensopados, ovos, leite, queijo) | Casa | 20 |
| Silo | `crop` (cenoura, abóbora, batata, trigo, milho, maçã...) | Sítio | 30 |
| Armazém | `material` (madeira, pedra, tábua, tijolo, fibra, tecido...) | Sítio/Vila | 30 |
| Baú/Prateleira | `product` e acessórios | Casa | 20 |

Capacidade = **total de unidades** por depósito (simples, uma barra "12/30"). Ração do Tiro e itens de missão
podem ficar fora do limite (nunca travar a história).

## Regras
1. **Cheio = para de entrar.** Colheita/coleta/estação pronta ainda fica pronta, mas "Recolher" mostra aviso
   "Silo cheio" e só entrega o que cabe (o resto continua no lote). Nunca perder item.
2. **Ampliar** = compra com moedas + materiais (ex.: Silo nv2: 80 moedas + 6 tábuas + 4 pedras) e **exige missão/capítulo**
   (`requirements`), como as construções. Cada nível soma +N de capacidade (30 → 50 → 80 → 120...).
3. **Depósitos são construções** em `progression.json → upgrades` (Silo, Armazém entram como compras; Geladeira já existe).
   Ampliações = `storage.<id>.levels[]` com `cost`, `materials`, `requirements`, `capacity`.
4. **Revelar aos poucos:** limite só passa a valer quando a missão apresenta o depósito; antes, sem limite (saves antigos
   não perdem nada: se já passa da capacidade, apenas não entra mais até esvaziar).
5. **Visual e simples:** na Mochila, barra por depósito (ícone + "12/30" + botão "+" ampliar); item cheio fica vermelho.
   Toast curto ao encher. Sem texto longo.
6. Vender, cozinhar e usar em missão **liberam espaço** — incentiva o ciclo da cadeia de produção.

## Implementação (ordem)
1. **Dados** (`progression.json`): bloco `storage` (id, nome, ícone, `categories`, `base_capacity`, `levels[]`, `building` que o libera).
   `items.json` ganha opcional `"storage": "<id>"` (padrão = pela categoria).
2. **Estado:** `ProgressionState` guarda `storage_levels: {id: nível}` (+ `to_dict/from_dict`); save v12 com `_migrate` (nível 0).
3. **Regra pura:** `Inventory.capacity_of`/`space_left`/`add_capped` recebem o resolvedor do `Database` (sem dependência de UI).
4. **Ações no `GameState`:** `upgrade_storage(id)` + `upgrade_storage_error(id)`; todos os pontos que dão item
   (colheita, coleta da Natureza, estações, rotas, recompensas) passam por um único `give_items()` que respeita o limite.
5. **UI:** aba Mochila com barras; painel de ampliação no molde de `ProgressionUi` (cartão: ícone, chips de custo, botão);
   lugares "Silo"/"Armazém" no mundo (`worlds.json` + `rooms/*.json`, arte PixelLab).
6. **Missões:** capítulo que apresenta cada depósito ("Laís: a colheita não cabe mais!") + diária "ampliar/esvaziar".
7. **Testes:** `storage_test.gd` (limite, parcial, migração, ampliação) + simulação da campanha em `progression_test.gd`
   com capacidade suficiente; atualizar `tools/test_all.ps1`.
8. **Docs:** PROGRESSION.md, CLAUDE.md/AGENTS.md (tabela "Onde trabalhar"), ROADMAP "Estado atual".

## Decisões (Vitor, 13/10/2026)
- Unidades totais; sem espaço não colhe nem pega (o item continua pronto); ampliação por itens específicos de missões avançadas; ovos e leite na geladeira; Mochila = lugar único com tudo agrupado por depósito. Geladeira e baú em casa; silo e armazém no sítio.

## (antigo) Pontos em aberto
- Limite por **unidades totais** (proposto) ou por **tipos de item** (como "espaços")?
- Geladeira só guarda comida, ou também ovos/leite/queijo? (proposto: sim)
- Quando o lote não cabe: **bloquear a colheita** (proposto, estilo Hay Day) ou **vender automático** o excesso?
- Ampliações só por missão+material, ou aceitar também um caminho "comprar com moedas" mais caro?
