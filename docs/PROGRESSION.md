# Progressão (Jornada)

> Sistema implementado em 12/10/2026 (Codex) e revisado/organizado no mesmo dia (Claude Code).
> Conteúdo e números ficam nos JSON de `game/data/`; este doc explica **como funciona e como estender**.

## Ideia
Você começa cuidando do Tiro numa **casa quase vazia**: sem geladeira, sem fogão, sem sítio próprio,
só a tigela, 3 rações e 10 moedas. A Bloblo empresta **um canteiro**. A partir daí:

```
cuidar do Tiro ─┐
plantar/colher ─┼─▶ moedas + itens + XP de atributo ─▶ comprar construções ─▶ novas receitas,
passear/minerar ┤                                      e terrenos              rotas e pedidos
vender/pedidos ─┘                         missões dos NPCs ─▶ roupas/apetrechos (Coleção)
```

A complexidade cresce aos poucos: no começo duas ou três decisões (cuidar, plantar cenoura, juntar
para o fogão); no fim, cadeias com várias estações (madeira → tábua → cozinha organizada; maçã +
petisco → biscoito → caixa de petiscos → encomenda especial).

## Peças do sistema
| Peça | Onde está | O que é |
|---|---|---|
| **Atributos (7)** | `progression.json` → `skills` | Agricultura, Culinária, Construção, Comércio, Passeio, Mineração, Vínculo. Sobem com a atividade correspondente. |
| **Construções** | `progression.json` → `upgrades` | Compras permanentes (moedas + materiais + requisitos): fogão, geladeira, escritura do sítio, sofá, bancada, picareta, cozinha organizada, forno, pomar, estufa, banca, ateliê. |
| **Estações** | `config.json` → `stations` + `recipes.json` | Fogão, bancada, forno e ateliê; filas com tempo real. `slot_upgrades` = construção que aumenta a fila. |
| **Rotas** | `progression.json` → `activities` | Passeios/mineração com tempo (uma por vez): bairro, trilha, pedreira, cobre, gruta, pomar, prado. |
| **Feira** | `progression.json` → `orders` + `sell_price` em `items.json` | Encomendas com recarga + venda direta. |
| **Capítulos** | `progression.json` → `chapters` (+ `final_chapter`) | A "história": cada capítulo termina ao comprar seu `target`. Aparece em Jornada → Hoje. |
| **Missões** | `quests.json` | Por NPC, em sequência (`requires`). Objetivos + recompensas. |
| **NPCs** | `npcs.json` | Bloblo, Guia da trilha, Feirante, Artesã. `portrait` = foto/retrato (vazio = usa `icon`). |
| **Coleção** | `collections.json` | Roupas/apetrechos ganhos em missões (`slot`: head/neck/body; `sprite` para vestir no futuro). |
| **Sítio** | `config.json` → `farm` | 1 canteiro emprestado antes da escritura; depois 3 iniciais e expansão até 9 (`unlock_costs`). |

## Como os atributos sobem
- XP total por atributo fica salvo em `GameState.progress.skills`; o nível é calculado
  (`ProgressionState.skill_info`): ir do nível N ao N+1 custa `skill_base_xp + (N-1) * skill_xp_step`
  (30, 50, 70...). Máximo `max_skill_level` (20).
- **Descoberta:** a primeira colheita de cada cultura e a primeira receita de cada tipo valem
  XP × `first_discovery_multiplier` (2).
- **Vínculo:** cuidar (comer, brincar, banho) só dá XP quando o Tiro **precisa** (necessidade abaixo
  de `care_need_threshold`) e fora da recarga `care_reward_cooldown` — não dá para "farmar" tocando.
- Fontes: colheita → Agricultura; receita → atributo do campo `skill` da receita (padrão Culinária);
  venda → Comércio (`trade_xp` do item); recompensas de rotas, pedidos, missões e construções → `skill_xp`.
- **Nível do jogador** (estrela da barra superior) é separado: XP de ações (`config.json` → `xp`),
  missões (`player_xp`), construções e rotas.

## Requisitos (um formato para tudo)
Construções, culturas, receitas, rotas e pedidos aceitam:
```json
"requirements": { "owned": ["farm"], "quests": ["first_sale"], "skills": { "agriculture": 4 } }
```
Validados por `ProgressionState.requirement_error()` (a mensagem vira o motivo na UI).
`progress.unlocks` ("crop:potato", "recipe:pumpkin_mash") libera conteúdo **sem** cumprir requisitos
(usado para saves antigos e pode ser recompensa: `"rewards": { "unlocks": [...] }`).

## Objetivos de missão
| `type` | `key` | Conta |
|---|---|---|
| `stat` | contador | `progress.stats[key]` (ver tabela abaixo) |
| `owned` | construção | 1 se comprada |
| `skill` | atributo | nível atual |
| `deliver` | item | itens na mochila; **são consumidos** ao concluir |

Contadores (`progress.stats`), incrementados pelas ações do `GameState`:
`feed`, `play`, `bathe`, `harvest`, `harvest:<crop>`, `produce`, `produce:<item>`, `trade`, `sold`,
`orders`, `order:<id>`, `activity:<id>`, `explore`, `build`, `quests`.

## Recompensas (missões, pedidos, rotas)
```json
"rewards": { "coins": 20, "items": { "dog_food": 2 }, "skill_xp": { "bond": 10 },
             "collections": ["farm_ribbon"], "unlocks": ["crop:potato"] }
```

## Caminho atual (resumo do balanceamento)
| Capítulo | Alvo | O que destrava |
|---|---|---|
| 1. Um novo começo | Fogão (40) | petisco de cenoura, pedido "Petiscos para a feira" |
| 2. Nossa primeira cozinha | Geladeira (75) | caldo de legumes, pedido "Almoço da comunidade" |
| 3. Um pedacinho de terra | Escritura do sítio (180, missão "Seu primeiro cliente") | 3 terrenos + expansão até 9, bancada |
| 4. Construindo o futuro | Bancada (120 + 6 madeira + 4 pedra) | tábuas e tijolos |
| 5. Uma produção de verdade | Forno (240 + 4 tijolo + 3 cobre; Culinária 3) | biscoito de maçã, caixa de petiscos |
| 6. Nosso lugar na vila | Banca (350 + materiais; Comércio 4) | pedidos grandes |
| 7. Um mundo de possibilidades | Estufa (480 + cristais; Agricultura 5, Mineração 3) | ervas |
| 8. Feito por nós | Ateliê (600 + materiais; Construção 5, Comércio 4) | tecido, conjunto de acessórios |

O `progression_test.gd` joga uma **campanha simulada** do zero (só ações reais, tempo acelerado) e
falha se alguma construção ou missão ficar inalcançável. Rode-o depois de mexer em números.

## Interface
- Aba **Jornada** (`scenes/ui/progression_screen/`): Hoje (capítulo, rota em andamento, missões
  prontas, ajuda de comida), Atributos (próximos marcos de cada um), Missões (por NPC), Construir,
  Rotas, Feira (encomendas + venda direta), Produção (estações), Coleção.
- Páginas montadas por `scripts/ui/progression_ui.gd` (caixas `LiveBox` que se refazem a cada
  mudança de estado e a cada segundo).
- Casa: móveis com `"upgrade"` em `rooms/house.json` só aparecem depois de comprados; antes há um
  marcador "+" que abre a compra. Sítio: canteiros bloqueados mostram "Sítio" (antes da escritura)
  ou o preço do próximo terreno.
- Bloblo (casinha no sítio) abre as missões dela.
- **Ajuda de comida:** sem nenhuma comida na mochila, a Bloblo dá ração grátis (recarga de 5 min)
  — o cuidado com o Tiro nunca trava por falta de moedas.

## Versão dev (testar as partes avançadas)
Para chegar nas partes avançadas sem jogar horas, existe a **versão dev** (detalhes de build em
`docs/DEPLOY.md`):
- Endereço: https://vitorawi.github.io/tiro-adventure/dev/ (local: `http://localhost:8000/dev/`;
  rodando pelo Godot é sempre dev). Pode ser instalada na tela inicial como **"Tiro DEV"**.
- **Save separado** (`user://save_dev.json`): nada do que se faz lá afeta o jogo de verdade.
- Selo vermelho **DEV** na barra superior abre as **Ferramentas DEV** (`scripts/ui/dev_panel.gd`):
  - **Recursos:** +100/+1000/+10000 moedas; +10 de cada item (todos, materiais, colheitas, comidas); necessidades 100%.
  - **Progresso:** atributos para nível 3/5/10/máx.; **pular para o capítulo N** (libera de graça tudo
    o que vem antes, inclusive missões e atributos exigidos); liberar uma construção específica;
    concluir uma missão; **liberar tudo**.
  - **Tempo:** terminar todos os timers agora; avançar 10 min / 1 h / 4 h / 12 h (como se o app
    ficasse fechado: necessidades caem, plantas crescem, filas andam).
  - **Save:** copiar o save da versão publicada (mesmo aparelho) para testar em cima do progresso
    real; salvar; recomeçar do zero (toque duplo).
- Ferramentas são métodos `GameState.dev_*` com a guarda `BuildInfo.is_dev()` — na versão publicada
  não fazem nada (testado em `dev_tools_test.gd -- --prod`).

## Saves antigos
Save v4 (`SaveManager._migrate`): quem jogou antes da progressão ganha `legacy_owned` (fogão,
geladeira, sofá, sítio, fila do fogão) e `legacy_unlocks` (batata, abóbora, papinha), mantendo
moedas, terrenos e plantações.

## Como estender
- **Nova construção:** entrada em `upgrades` (name, description, cost, materials, requirements,
  skill_xp, icon). Se for estação: `"station": "<id>"` + entrada em `config.json → stations` +
  receitas com `"station"`. Se tiver móvel: objeto em `rooms/<sala>.json` com `"upgrade": "<id>"`.
- **Novo capítulo:** item em `chapters` com o `target` (uma construção).
- **Nova missão:** entrada em `quests.json` com `npc`, `requires`, `goals`, `rewards`.
- **Novo NPC com foto:** entrada em `npcs.json`; coloque o retrato (pixel art do PixelLab feita a
  partir da foto) em `assets/sprites/characters/npc_<id>/portrait.png` e preencha `"portrait"`.
- **Nova roupa:** entrada em `collections.json` (+ `sprite` quando existir a camada para vestir).
- Depois de mudar números: rode `progression_test.gd` (campanha simulada).

## Pendências conhecidas / próximos passos
Ver `docs/ROADMAP.md` → "Estado atual". Principais: vestir as roupas da Coleção no Tiro, retratos
dos NPCs (fotos do Vitor), NPCs no mundo, móveis da bancada/forno/ateliê na casa ou no sítio,
sprite próprio da planta de ervas, e balancear o ritmo real (hoje medido só pela campanha simulada).
