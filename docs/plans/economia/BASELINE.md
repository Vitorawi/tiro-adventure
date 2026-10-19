# Linha de base real — etapa 00 do plano de economia

Produzido em **17/10/2026** pela etapa 00. É uma **medição estática dos dados e do código atuais**: nada foi simulado, nenhum JSON de balanceamento foi alterado e nenhuma taxa de uso do jogador é afirmada. Números “teto” são limites aritméticos. As saídas volumosas ficam em `build/economy/baseline/` (ignorado pelo git).

## 1. Estado auditado

| Item | Valor |
|---|---|
| Branch / HEAD | `main` / `6d22eb7b051213e5c4df5de759ae97b779481705` (“docs: registrar publicação 6c01198”) |
| Versão do save | `SAVE_VERSION = 12` (`game/autoload/save_manager.gd`) |
| Hash do conteúdo (`game/data/**/*.json`, sem `version.json`, terminações de linha normalizadas) | `9e8856729c110dc3cd86cc6c15d0ff7825e1a6b8bce1a327eaf296f2607347e4` |
| Conteúdo | 69 itens · 24 receitas · 9 culturas · 48 melhorias · 13 encomendas · 13 rotas da Natureza · 9 estações · 6 animais · 9 capítulos · 7 passeios · 19 desejos · 4 amigos · 19 diárias + 11 semanais |
| Missões | **81** (31 principais, 50 de linhas: Bloblo 23, Feirante 11, Nina 11, Guia 5), 7 com `shared_with` |
| Matriz `08_MATRIZ_QUESTS.md` × `quests.json` | os 81 IDs coincidem; nenhuma diferença desde a redação da R1 |

**Alterações locais já presentes** (anteriores a esta etapa; preservadas, nada foi limpo, commitado ou incorporado): 10 arquivos modificados — `docs/ROADMAP.md`, `game/autoload/game_state.gd`, `game/scenes/main/main.gd`, `game/scenes/ui/tasks_screen/tasks_screen.gd`, `game/scenes/ui/worlds_screen/worlds_screen.gd`, `game/scripts/ui/progression_ui.gd`, `game/scripts/ui/ui_kit.gd`, `game/scripts/ui/world_card.gd`, `game/tests/intro_test.gd`, `tools/test_all.ps1` (+82/−42) — e não rastreados `docs/plans/economia/`, `game/tests/ready_badges_test.gd`, `reports/`, `research_notes/`. Correspondem aos “avisos só do que está pronto” registrados no ROADMAP (contadores de missões prontas/`world_ready_counts`). Nenhum arquivo de dados de balanceamento (`game/data/*.json`) estava modificado: o diff dos JSON é vazio. Cópia do diff e do `git status` de antes desta etapa: `build/economy/baseline/pre_existing_local_changes.patch` e `pre_existing_status.txt`.

Arquivos que esta etapa **criou**: `tools/economy_audit.py`, `tools/economy_audit_selftest.py`, este `BASELINE.md`; editou `tools/test_all.ps1` (uma linha, autoteste), README/DECISOES do plano e ROADMAP.

## 2. Método e comandos

```powershell
# Auditor (somente biblioteca padrão; -X utf8 por causa do console cp1252 do Windows)
py -X utf8 -I tools\economy_audit.py                     # escreve build\economy\baseline\
py -X utf8 -I tools\economy_audit.py --data <pasta> --out <pasta>   # dados alternativos (fixtures)
py -X utf8 -I tools\economy_audit_selftest.py            # dados reais passam; cópia quebrada falha
```

Saídas: `baseline.json` / `baseline.md` (conteúdo completo, determinístico), `references.md` (referências quebradas, ciclos, alcançabilidade), `manifest.json` (SHA-256 de cada JSON/ sala lida e dos `.gd` consultados), `run_meta.json` (git, data, argumentos — **único arquivo que muda entre execuções**). Códigos de saída: 0 sem erros, 1 erros de referência/ciclo, 2 dados ilegíveis.

O que o auditor calcula: todas as ocorrências do campo `coins`, preços/custos, ingredientes, saída por lote, tempos, requisitos, filas/capacidades, depósitos e itens isentos, recompensas (missões/capítulos/nível/vínculo/rotinas/passeios/amigos/encontros), margem **imediata** (venda da saída − venda dos ingredientes) e margem contra a **matéria-prima expandida** (perda de oportunidade de vender o que seria transformado), grafo de missões (`shared_with`, ordem de linha, capítulo, requisitos de compra/receita), resolução de toda referência por ID, ciclos (componentes fortemente conexos), alcançabilidade estática e verificações textuais de código com arquivo:linha.

Limites assumidos: itens sem `sell_price` aparecem como “—”, nunca como zero; o auditor não replica o `GameState`; a alcançabilidade ignora tempo, estoque, depósitos e contadores (`stat`), tratados como satisfazíveis; fontes de moedas por sorteio (passeios, achados) aparecem como faixa mín–máx sem probabilidade.

## 3. Resultados verificados

### 3.1 Referências, ciclos e alcançabilidade
Execução sobre os dados reais: **0 erros de referência, 0 avisos, 0 ciclos** (405 arestas no grafo E de requisitos, ordem de linhas, objetivos `owned`/`quest` e ordem das ampliações). Alcançabilidade estática (aproximação): **81/81 missões, 48/48 melhorias, 9/9 culturas, 24/24 receitas, nenhum item sem fonte**. Detalhes em `references.md`. O primeiro rascunho do auditor acusou `go.place = "order:festival_contract"` em `merchant_festival` como lugar inexistente; era falso positivo (forma `order:<id>` é aceita por `Places.run`, junto de `recipe:`, `route:`, `crop:`, `station:`, `npc:`, `buy:`, `market:`) e o validador foi corrigido — o dado não foi mexido.

### 3.2 Fluxos de moedas (campo `coins`; soma bruta das entradas, **não** é renda por hora)

| Origem | Entradas | Soma |
|---|---:|---:|
| Início do save | 1 | 10 |
| Missões (31 principais = 575; 50 de linhas = 2.085) | 74 com moedas | **2.660** |
| Capítulos 1–9 (10/20/30/40/80/100/120/140/160) | 9 | **700** |
| Níveis 2–10 (`default` = 10 × nível acima) | 9 | 410 |
| Vínculo níveis 2–8 | 7 | 470 |
| Presente do dia (ciclo de 7: 15, 25, 30, 40 em moedas) | 4 | 110 por ciclo |
| Diárias (19 modelos) / semanais (11 modelos) | 30 | 273 / 1.040 se todas fossem sorteadas e feitas |
| Desejos (19 modelos) | 19 | 219 |
| Passeios: fixo / primeira-raro / sorteio | 21 | 153 / 240 / 39–95 |
| Amigos (corações + visitas) | 16 | 349–380 |
| Achados (tabelas e conjuntos) | 8 | 375–398 |
| Baú da Clareira | 1 | 150 |
| Rotas com moeda: `lane` 8, `trail` 15 | 2 | 23 |
| **Colheita** (`crops.*.coins`: 3/9/16/24/4/5/5/20/12) | 9 | 98 por rodada de uma colheita de cada |
| Encomendas (13) | 13 | 1.702 se todas entregues uma vez (repetíveis por recarga) |
| Venda de itens (`sell_price`) | 61 itens | taxa de uso **desconhecida** |

Sumidouros em moedas: melhorias **8.210**, terrenos 580 (`40/70/100/150/220`), animais 750 (60/80/90, 140/180/200), loja 15 (pacote de ração). Não há custo de semente, imposto, aluguel nem deterioração. Estoque cheio **impede** colher (`harvest` recusa e emite aviso); não destrói produção.

### 3.3 Cenoura (conferida à mão)
`seconds = 60`; uma rega reduz o tempo restante em 30% → **42 s**; colheita = **3 moedas + 2 cenouras × 3** = **9** por colheita; teto = 9 ÷ 42 × 60 = **12,857 moedas/canteiro/min**; **51,43** nos quatro canteiros iniciais (coincide com o ROADMAP). Sem as 3 moedas de colheita: 8,57/min por canteiro. Teto sem navegação, toques, falta de espaço ou outras demandas.

Teto por cultura (moedas+venda por canteiro/min): cenoura 12,86 · trigo 9,29 · milho 8,10 · morango 7,14 · batata 6,57 · batata-doce 5,71 · ervas 5,33 · mirtilo 4,48 · abóbora 4,00. As culturas de maior espera (mirtilo e ervas 900 s, abóbora 600 s) rendem menos por minuto de canteiro que a cenoura; hoje não há razão econômica para esperar.

### 3.4 Receitas e transformação (por lote; criações por animal)
Margem imediata = venda da saída − venda dos ingredientes; “vs matéria-prima” expande intermediários até culturas/materiais.

| Receita | Entra → sai | s | Margem imediata | Margem vs matéria-prima |
|---|---|---:|---:|---:|
| carrot_snack | cenoura×2 → 1 | 60 | +6 | +6 |
| vegetable_soup | cenoura×2+batata → 1 | 120 | +15 | +15 |
| mashed_potato / pumpkin_mash | batata×2 / batata+abóbora → 1 | 90 / 180 | +4 / +6 | +4 / +6 |
| **apple_biscuit** | maçã×2 + carrot_snack → **2** | 300 | **+54** (80−26) | +60 (80−20) |
| **treat_box** | biscoito×2 + abóbora_mash + ervas → 1 | 420 | **−61** (60−121) | **+5** (60−55) |
| plank / brick | madeira×3 / pedra×3 → 1 | 90 / 120 | +4 / +6 | +4 / +6 |
| eggs / milk (por animal) | milho×2 / trigo×2 → ovo×2 / leite×2 | 180 / 300 | +10 / +18 | +10 / +18 |
| flour / cheese | trigo×3 → farinha×2 / leite×2 → queijo | 120 / 240 | +19 / +8 | +19 / +26 |
| fabric / accessory_set | fibra×3 / tecido×2+cristal → 1 | 180 / 360 | +12 / +22 | +12 / +46 |

Conferências manuais (planilha em `baseline.md → Conferência aritmética`): biscoito 2 maçãs (14) + petisco (12) = 26 → 2×40 = 80 → **+54**; com matéria-prima (2 maçãs 14 + 2 cenouras 6 = 20) → **+60**. Caixa de petiscos: 2 biscoitos (80) + purê de abóbora (25) + ervas (16) = 121 contra 60 de venda → **−61 de perda imediata**; pela matéria-prima (maçã×2 14 + cenoura×2 6 + batata 7 + abóbora 12 + ervas 16 = 55) a margem fica **+5**, ou seja, transformar quase não paga o tempo de 420 s do fogão. A encomenda `special_order` (3 caixas → 220) devolve 220 contra 363 dos ingredientes imediatos e 180 de venda das caixas; `festival_contract` (450) usa 4 caixas.

`farm_breakfast` (já existe; plano reaproveita): ovo×2 (18) + farinha×2 (28) + queijo×1 (32) = **78**, paga **95** (+17); matéria-prima = milho×2 (8) + trigo×5 (15) = **23** (+72). Recarga 600 s; exige `first_harvest` e queijaria. O item é `egg`; a receita é `eggs` (`output: "egg"`); não existe item `eggs`.

Encomendas (margem sobre a venda dos ingredientes): `vegetables` +6, `snacks` +9, `soup_order` +19, `puree_order` +14, `pop_order` +13, `juice_order` +8, `fruit_basket` +6, `farm_breakfast` +17, `building_order` +62, `fabric_order` +84, `banquet_contract` +92, `special_order` +40, `festival_contract` +74 (os quatro últimos contratos pagam também parafuso/aro).

### 3.5 Estações, filas e capacidades
Fogão 1 vaga (+`stove_queue` +1: 180 moedas + 3 tábuas, exige fogão e bancada; +`stove_queue_2` +1: 320 + 5 tábuas) = 3; liquidificador 1; bancada 2; moinho 2; queijaria 2; ateliê 2; costura 1; galinheiro e curral 1 vaga com `animal_capacity` 3. Vaga = comprimento da fila sequencial (cada trabalho começa quando o anterior termina; `StationState.enqueue`), não máquinas paralelas. Receita de criação multiplica insumo e saída pelo número de animais.

Depósitos (a capacidade **só passa a valer depois de comprar o edifício**; antes, entrada sem limite):

| Depósito | Categorias → itens | Base | Compra | Ampliações |
|---|---|---:|---|---|
| Silo | `crop`: maçã, mirtilo, cenoura, milho, ervas, batata, abóbora, morango, batata-doce, trigo | 40 | 120 + madeira×6; exige `main_9_cheese` | `_2` +40 (150, parafuso, 4 tábuas), `_3` +60 (400, 8 tábuas, 4 tijolos, parafuso, aro) |
| Geladeira | `food` + ovo/leite/farinha/queijo forçados | 30 | 40; exige `lais_first_crops` | +20 / +30 (mesmos custos) |
| Armazém | `material`: tábua, tijolo, cobre, cristal, tecido, fibra, madeira dura, pedra, madeira | 40 | 150 + madeira×8 + pedra×4; exige `bloblo_silo` | +40 / +60 |
| Baú | `product`: **apenas** treat_box e accessory_set | 20 | 80 + madeira×4; exige `bloblo_warehouse` | +20 / +30 |

Isentos de limite (35, todos `storage: none`): ração, parafuso, aro, `bed_gift`, os 20 itens de achado (incluem os 4 pedaços do mapa) e os 11 materiais `trail` (incluem `stick` e `wild_mint`). Todas as ampliações exigem a missão `bloblo_chest`/`bloblo_bigger` além do estágio anterior.

### 3.6 Compra → recompensa de missão (moedas que voltam ao jogador)
Destaques (custo em moedas → recompensa da missão que pede a compra): silo 120 → 40+parafuso (33%); baú 80 → 50+parafuso (62,5%); armazém 150 → 50 (33%); `fridge_2` 150 → 100 (66,7%, dividido com `silo_2` na mesma missão); `silo_3` 400 → 200 (50%); banca 350 → **150** (43%) e capítulo 7 → 120; `stall_2` 450 → 80; `stall_3` 800 → 120; ateliê 600 → **200** (33%) e capítulo 9 → 160; fogão 60 → 10 + capítulo 3 → 30. Tabela completa em `baseline.md`. Sem missão `owned` própria (compra livre, sem devolução): `mill`, `sewing_table`, `walk_bag`, `sofa`, `meadow_open`, `stove_queue`, `stove_queue_2`, `chest_2/3`, `fridge_3`, `warehouse_2/3`.

### 3.7 Parafusos e aros de ferro
Fontes encontradas por ocorrência: **parafuso** — missões 10, nível 4, vínculo 2, baú 2 (únicos); presente do dia 1 por ciclo, rotinas 9, encomendas 4 (repetíveis); achados 4 (sorteio/conjuntos); amigos 1. Demanda: **8** (uma por ampliação de depósito). **Aro** — missões 6 (bloblo_bigger 3 + bloblo_biggest 2 + merchant 1), nível 1 (nível 8), encomendas 2 (contratos), achados 1; demanda **4** (uma por `_3`). Hoje os aros dependem de missões da linha da Bloblo e de contratos da banca; ao retirá-los de `bloblo_bigger/biggest` (etapa 07) a oferta determinística única de aros cai de 7 para 2 (nível 8 e uma missão do Feirante). Hoje as quatro `_3` pedem 1 aro cada; na R1 as `_3` pedem só parafuso e o aro passa a ser exigido nas `_4/_5` (etapa 18), com fontes novas em `banquet_contract` (15) e `workshop_first_set` (17). Entre as etapas 05–08 cada depósito troca para o custo R1 na sua vez, então `chest_3` (etapa 08) ainda pede 1 aro depois de a 07 retirar a fonte das missões: continua alcançável pelo nível 8, mas o executor da 07 deve conferir (ver DECISOES).

### 3.8 Natureza
Rotas (segundos → saída; todas exigem capítulo 5): `lane` 60 → madeira×1 (+8 moedas); `trail` 180 → madeira×3+pedra×2 (+15); `woodcutting` 150 → madeira×4 (exige `forest_level_2`); `timber` 240 → madeira×5+madeira dura×2 (nível 3); `pebbles` 75 → pedra×1; `quarry` 180 → pedra×5; `copper_vein` 360; `deep_quarry` 300; `crystal_cave` 600; `crystal_deep` 480; `meadow` 420 → fibra×5+madeira×3; `reeds` 300 (nível 2); `orchard_harvest` 300 → maçã×4. Níveis de local: Bosque 0/30/90 XP, Caverna 0/40/120, Prado 0/30/90, 10 XP por coleta, 1/2/3 vagas.

### 3.9 Missões
Ordem de cada linha e prêmios por missão em `baseline.md` e `baseline.json → quest_graph`. Quadro: capítulos 1–9 = 31 missões principais (6/2/4/3/3/4/3/3/3); `shared_with` ativo em `lais_meet_bloblo→bloblo_meet`, `lais_first_crops→bloblo_more_crops`, `lais_stew→bloblo_stew`, `first_sale→merchant_first_sale`, `main_2_order→merchant_orders`, `market_day→merchant_regular`, `own_business→merchant_stall`. Estado real versus premissas da R1: `bloblo_silo` order 140 (40 moedas + parafuso), `bloblo_warehouse`, `bloblo_chest` order 160, `bloblo_bigger` (100 + 3 parafusos + 3 aros), `bloblo_biggest` 200 + parafuso×3 + aro×2, `merchant_stall` 150, `atelier_open` 200, `main_5_cooking` = `produce` 5 *fresh*, `main_6_commerce` = `sold` 15 *fresh*, `main_7_greenhouse` = `owned:greenhouse` — todos como a 03/08 descrevem.

## 4. Suposições críticas — confirmadas

| # | Suposição | Evidência |
|---|---|---|
| 1 | Capacidade só ativa após a compra | `game_state.gd:1213` (`storage_active` → `has_upgrade(building)`); `storage_full` ignora depósito inativo |
| 2 | Receita produz várias unidades | `apple_biscuit.qty = 2`, `eggs/milk/flour qty = 2`; `recipe_quantity` (`game_state.gd:816`) |
| 3 | Vagas são filas sequenciais | `station_state.gd:13`; `game_state.gd:728` (`queue.size() >= station_slots`) |
| 4 | Carinho: guarda só na interface | `GameState.pet()` (`:583`) soma +1 afeto sem recarga; `pet_screen.gd:7/409` (`PET_REWARD_EVERY = 1.2`). Brincar soma +2 afeto (`:598`) |
| 5 | Colheita paga moedas | `game_state.gd:968` (`coins += crop.coins`) em todas as 9 culturas; plantio sem custo |
| 6 | Fontes de parafuso/aro | §3.7 |
| 7 | Venda inicial disponível | `worlds.json → farm.places.early_market`, `requirements.quests = [bloblo_meet]` |
| 8 | `farm_breakfast` existente | §3.4 |
| 9 | `egg` × `eggs` | item `egg` (venda 9); receita `eggs`; não há item `eggs` |
| 10 | Estações | `config.stations`: stove, workbench, atelier, chicken_coop, cow_barn, mill, dairy, blender, sewing. **Não há estação `fridge`.** A estação `sewing` é liberada pela melhoria `sewing_table` (`Database.station_upgrade` pelo campo `station`). `progression_test`, `animals_test`, `flavors_test` e `world_life_test` usam `unlimited_storage = true` |
| 11 | Campos de XP | ver DECISOES 17/10 (item 1) |

## 5. Divergências da R1 e destino

Nenhuma contradição bloqueou o plano. Esclarecimentos factuais (registrados em `DECISOES.md`, 17/10/2026, etapa 00):

1. “XP Horta” da tabela C não é um campo: culturas têm `skill_xp` (atributo Agricultura, pago **a cada colheita**, dobrado na primeira descoberta) e o XP do jogador por colheita vem de `config.xp.harvest = 2`. → etapa 10 aplica o valor da tabela em `skill_xp`.
2. Capacidades legadas (silo 40, geladeira 30, armazém 40, baú 20; `_2` +40/+20/+40/+20; `_3` +60/+30/+60/+30) são **maiores** que as “Construído” da R1 (32/24/32/24) exceto o baú → etapa 02 (`legacy_capacity_floor`) já cobre; etapas 05–08 não podem reduzir quem comprou.
3. A R1 usa “estação `fridge`” só no sentido de depósito/compra: nenhuma estação com esse ID existe.
4. Receitas, tempos, preços e custos da R1 são **alvos**: todos diferem do estado atual (ex.: silo 120 moedas hoje, 0 na R1). Não são divergências.
5. A estimativa do ROADMAP (“2.660 + 700 moedas”, caixa 121→60, contrato 220 vs 363, 51,4 moedas/min) foi reproduzida exatamente.

## 6. Verificações executadas (esta etapa)

| Verificação | Resultado |
|---|---|
| `economy_audit.py` duas vezes (saídas em pastas diferentes) | `baseline.json`, `baseline.md`, `references.md` e `manifest.json` **byte a byte idênticos**; só `run_meta.json` (data/hora) muda |
| Conferência manual de cenoura, `apple_biscuit` (saída 2), `treat_box`, `farm_breakfast`, banco de recompensas | números da §3.3–3.4 e §3.7 refeitos à mão e iguais aos do auditor |
| Fixture temporária (requisito/ item/ insumo inexistente + ciclo silo↔`bloblo_silo`) | auditor sai com código 1 e cita os 3 IDs e o ciclo; dados reais saem com 0 (`tools/economy_audit_selftest.py` → PASS). `game/data` não foi tocado |
| Godot: `content_test`, `tasks_test`, `storage_test` | PASS (logs `build/economy/baseline/godot_*.log`) |
| Godot: `progression_test` | **FAIL prévio (1 verificação)**: “Campanha deve alcançar missão: merchant_festival” (1.500 ciclos, 80/81 missões, 48 aquisições; fica parado em `merchant_festival`, que pede `order:festival_contract` = 4 caixas + 4 picolés + 3 tecidos). Sem SCRIPT ERROR; log `godot_progression_test.log`. Não é causado por esta etapa (nenhum código do jogo foi tocado) e coincide com o ROADMAP de 16/10 (“simulação geral interrompida… não declarar PASS”). Roda com `unlimited_storage = true`; a estática do auditor diz que a missão é alcançável, então a causa é a política do bot (reserva/gasto), a investigar na etapa 01 |

## 7. Incertezas e o que NÃO foi medido

- Taxa real de uso: quanto o jogador colhe, vende, cozinha ou volta por dia — é papel das etapas 01 e 23.
- Preço de venda de roupas/coleções, valor real das moedas dos sorteios (passeios/achados) e probabilidade de cada raro.
- Capacidade de criações com mais de um animal (auditor assume 1 animal por receita; o jogo multiplica por `animal_count`).
- Interface: nada foi capturado nesta etapa (não houve mudança visual).
- A alcançabilidade é aproximação: não prova que um perfil real chega lá no tempo planejado.

## 8. Comandos corretos neste computador (para o agente seguinte)

```powershell
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
& $env:GODOT_BIN --headless --path game -s res://tests/content_test.gd     # cada teste imprime "... TEST: PASS"
powershell -ExecutionPolicy Bypass -File tools\test_all.ps1                 # suíte inteira (longa; progression_test sozinho leva vários minutos)
py -X utf8 -I tools\economy_audit.py ; py -X utf8 -I tools\economy_audit_selftest.py
```
Use `py` (o `python` do Windows é um atalho da Microsoft Store que não executa) com `-X utf8`: o console é cp1252 e o `-I` ignora `PYTHONUTF8`. O Chromium/Playwright é do ambiente remoto; neste computador o teste de toque usa `tools\touch_test.ps1`.
