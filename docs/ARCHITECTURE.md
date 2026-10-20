# Arquitetura

## Visão geral
```
           Events (signal bus)
          ↑ emite        ↓ escuta
Cenas (scenes/*)  ──métodos──▶  GameState  ◀──to_dict/from_dict──  SaveManager ──▶ user://save.json
                                                                                     (IndexedDB na Web)
```

## Camadas visuais

Camadas de desenho: efeitos do cenário usam `Motion.WORLD_FX_Z = 5` com
`z_as_relative = false`. Isso inclui Zz, textos flutuantes, ícones de atributos,
corações e `CollectFx`. Abas (6), HUD (8), Sheet (10), avisos/popovers e os
CanvasLayers dos modais ficam acima deles. Um efeito do Tiro não deve usar z alto
para atravessar a interface; janelas cobrem o cenário e suas animações.

## Autoloads (ordem de carregamento importa)

| Nome          | Arquivo                       | Responsabilidade |
|---------------|-------------------------------|------------------|
| `Events`      | `game/autoload/events.gd`     | Sinais globais: estado mudou, toast, abrir/fechar sheet, trocar tela. |
| `Database`    | `game/autoload/database.gd`   | Lê `game/data/*.json` (itens, receitas, plantas, config, progressão, missões, NPCs, coleção, versão). |
| `GameState`   | `game/autoload/game_state.gd` | Estado persistente + ações (cuidar, cozinhar, plantar, comprar, vender, rotas, missões) + ferramentas `dev_*`. |
| `SaveManager` | `game/autoload/save_manager.gd` | Lê/escreve o save, migra versões, salva a cada `state_changed`. |
| `PwaUpdater`  | `game/autoload/pwa_updater.gd` | Web: detecta versão nova do PWA e aplica (só o SW/cache do próprio canal). |

`SaveManager` vem por último porque carrega o save no `_ready` e preenche o `GameState`.
`Database` carrega no `_init`, antes de qualquer `_ready`.

## Estado (`game/scripts/state/`)
| Classe | Guarda |
|---|---|
| `DogState` | Nome, necessidades (valor + `updated_at`, cálculo preguiçoso), sono, afeição, roupa. |
| `Inventory` | `item_id -> quantidade`. |
| `StationState` | Fila de produção com `ready_at` (timestamps Unix). |
| `ProgressionState` | Jornada: XP dos atributos, construções (`owned`), contadores (`stats`), missões, descobertas, coleção, `unlocks`, recargas e rota em andamento. Consultas puras (`skill_info`, `requirement_error`, `current_chapter`). Acesso: `GameState.progress`. |
| `GrowthState` | Plano "Tiro no centro" (chave `growth`): fase e instante, pontos/reserva dos pilares, requisitos, entregas, cerimônias, recibos, paladar, jeito/diário e seda. Dados em `data/growth.json`; ações `GameState.grow/deliver_growth/brush/brighten`. |
| `AlbumState` | Chave `album`: fotos tiradas (fase/pelagem/roupa congeladas), lupas, dicas, locais de sono, datas. Dados em `data/album.json`; avaliador único `GameState._album_event` + `AlbumRules`. |
| `ProjectState` | Chave `projects`: obras comunitárias da vila (`data/projects.json`). |
| `EconomyState` | Revisão de economia, piso de capacidade, recibos e recompensas já pagas. |
| `FriendState`, `WalkState`, `FindState`, `WishState` | Amigos, passeios (viagem × bagagem), faro e desejos do Tiro. |

Utilitários (`game/scripts/util/`): `BuildInfo` (canal prod/dev e arquivo de save) e `TimeText`
(texto de duração, usado pelo estado e pela UI).

## Save local
- Save v4: bloco `progression` (ver `ProgressionState`); migração v3→v4 dá aos saves antigos os
  equipamentos e culturas que já tinham (`legacy_owned`/`legacy_unlocks` em `progression.json`).
- Save v3: `unlocked_plots` registra expansão sequencial. Migração v2 preserva os canteiros existentes.
- Plantações novas guardam `planted_at` e `ready_at`; plantações antigas calculam início pelo tempo em `crops.json`.
- `GameState.buy_plot`, `plant` e `harvest` validam ações; colheita entrega itens e XP do snapshot do plantio; desde a etapa 09 `crops.json → coins` é 0 (moeda vem de vender/entregar), e plantios antigos ainda pagam o que valiam.
- `WorldBalloon` (base de `PlotIndicator`, `StationIndicator`, `RouteIndicator`, `WalkIndicator` e do marcador de compra) desenha o balão do mundo sem capturar toque; `RoomView` encaminha toques por `hit_rect` e atualiza o visual.
- Testes: `tests/farm_test.gd`, `progression_test.gd` (campanha simulada), `dev_tools_test.gd`
  (rodam headless e removem o SaveManager antes de alterar o estado; comandos no `CLAUDE.md`).
  Scripts de teste (`extends SceneTree`) compilam antes dos autoloads: não citar `class_name`
  que dependa de autoload (use `load()` + `call()`, como em `dev_tools_test.gd`).
- Arquivo: `user://save.json` (versão dev: `user://save_dev.json`, ver `BuildInfo`) → JSON `{ save_version, saved_at, state }`.
- Na Web, `user://` é sincronizado com o **IndexedDB** do navegador, por site (origem).
  Mesmo jogador, mesmo aparelho, mesmo navegador/app = mesmo save.
- **Quando salva:** chamadas explícitas a `SaveManager.save_game()` e autosave ao perder foco,
  ir para segundo plano ou fechar.
- **Persistência:** na Web pedimos `navigator.storage.persist()` para o navegador não apagar dados.
  No iOS, o Safari pode limpar dados de sites não usados por ~7 dias; o app instalado na tela
  inicial é bem mais estável. Futuro: exportar/importar save como código (backup manual).
- **Migração:** ao mudar o formato, incremente `SAVE_VERSION` e converta em `_migrate()`.
- **Revisão de economia (conteúdo):** mudanças só de balanceamento/ordem NÃO incrementam `SAVE_VERSION`: usam
  `EconomyState.CURRENT_REVISION` + `EconomyMigration` (pura, idempotente, sem reset; usa `data/legacy_r0.json`). Trabalhos em
  andamento guardam o contrato de quando começaram (`WorkJobs`); presentes automáticos que não cabem ficam em `economy.pending`.
  Detalhes em `docs/PROGRESSION.md` (Economia R1 — etapa 02).
- Atenção: o PWA instalado no iPhone e o Safari normal têm armazenamentos **separados**.

## Cenas
- `scenes/main/main.tscn` — casca: barra superior (nível, moedas, selo DEV), abas Tiro/Mapa/Tarefas/Mochila, Sheet, toast.
- `scenes/ui/worlds_screen/` — aba Mapa: mundos de `data/worlds.json`; cada um é um `RoomView` (sala) criado na
  primeira visita. Lugares e personagens abertos por `Places` (`scripts/ui/places.gd`). Ver `docs/WORLDS.md`.
- `scenes/ui/tasks_screen/`, `scenes/ui/bag_screen/` — abas Tarefas e Mochila.
- `Events.world_requested(mundo, lugar)` — botões "Ir até lá" de qualquer tela.

### Planejado (ver `GAME_DESIGN.md`)
```
main
├─ PetScreen        scenes/ui/pet_screen/      cachorro grande, necessidades, interações
├─ World            scenes/levels/<ambiente>/  casa, horta... câmera arrastável
│  ├─ Dog           scenes/entities/dog/       IA autônoma (passear, deitar, reagir)
│  └─ Interactables scenes/entities/...        geladeira, fogão, canteiro: tocou → abre painel
└─ HUD / painéis    scenes/ui/                 inventário, receitas, missões
```
Sistemas previstos (dados em `GameState`, conteúdo em `game/data/`): necessidades, atributos/XP,
inventário, plantação, estações de produção, missões, desbloqueio de ambientes.

### Tempo real
Toda espera é salva como timestamp Unix de término (`ready_at`). Ao abrir o jogo, o estado é
"avançado" pelo tempo passado (necessidades caem, plantas ficam prontas). Não depender de `_process`.

### Interação por toque
Objetos tocáveis compartilham um componente comum (área de toque + sinal `tapped`).
Arrastar move a câmera; um toque curto sem arrasto conta como clique.

## Restrições da plataforma Web
- Renderer **Compatibility** (WebGL 2).
- **Sem threads** (export single-thread), para funcionar no GitHub Pages e no Safari iOS.
- Áudio só começa após o primeiro toque do usuário (regra dos navegadores).
- Tamanho do download importa: `index.wasm` ~40 MB sem compressão (o Pages serve com gzip).
