# Arquitetura

## Visão geral
```
           Events (signal bus)
          ↑ emite        ↓ escuta
Cenas (scenes/*)  ──métodos──▶  GameState  ◀──to_dict/from_dict──  SaveManager ──▶ user://save.json
                                                                                     (IndexedDB na Web)
```

## Autoloads (ordem de carregamento importa)
| Nome          | Arquivo                       | Responsabilidade |
|---------------|-------------------------------|------------------|
| `Events`      | `game/autoload/events.gd`     | Sinais globais: estado mudou, toast, abrir/fechar sheet, trocar tela. |
| `Database`    | `game/autoload/database.gd`   | Lê `game/data/*.json` (itens, receitas, necessidades, ações, XP, início). |
| `GameState`   | `game/autoload/game_state.gd` | Estado persistente + ações (feed, pet, play, bathe, cook, collect). |
| `SaveManager` | `game/autoload/save_manager.gd` | Lê/escreve o save, migra versões, salva a cada `state_changed`. |

`SaveManager` vem por último porque carrega o save no `_ready` e preenche o `GameState`.
`Database` carrega no `_init`, antes de qualquer `_ready`.

## Estado (`game/scripts/state/`)
| Classe | Guarda |
|---|---|
| `DogState` | Nome, necessidades (valor + `updated_at`, cálculo preguiçoso), sono, afeição, roupa. |
| `Inventory` | `item_id -> quantidade`. |
| `StationState` | Fila de produção com `ready_at` (timestamps Unix). |

## Save local
- Arquivo: `user://save.json` → JSON `{ save_version, saved_at, state }`.
- Na Web, `user://` é sincronizado com o **IndexedDB** do navegador, por site (origem).
  Mesmo jogador, mesmo aparelho, mesmo navegador/app = mesmo save.
- **Quando salva:** chamadas explícitas a `SaveManager.save_game()` e autosave ao perder foco,
  ir para segundo plano ou fechar.
- **Persistência:** na Web pedimos `navigator.storage.persist()` para o navegador não apagar dados.
  No iOS, o Safari pode limpar dados de sites não usados por ~7 dias; o app instalado na tela
  inicial é bem mais estável. Futuro: exportar/importar save como código (backup manual).
- **Migração:** ao mudar o formato, incremente `SAVE_VERSION` e converta em `_migrate()`.
- Atenção: o PWA instalado no iPhone e o Safari normal têm armazenamentos **separados**.

## Cenas
- `scenes/main/main.tscn` — cena inicial (hoje: teste do save com contador).

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
