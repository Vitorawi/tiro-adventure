# CLAUDE.md — Mapa do projeto

Leia este arquivo primeiro. Ele diz **o que é o projeto, como está organizado e onde trabalhar**.
Detalhes ficam em `docs/`.

## O que é
**Tiro Adventure** — repo `github.com/Vitorawi/tiro-adventure`, jogo em
https://vitorawi.github.io/tiro-adventure/

**Bichinho virtual (cachorrinho) + produção em cadeia estilo Hay Day.** Celular **em pé**,
tela inteira, **100% toque**: o jogador não controla o movimento do cachorro (ele anda sozinho),
só toca nos objetos (geladeira, horta, fogão...) e arrasta para mover a câmera.

Jogo 2D em **Godot 4.7.2** (GDScript), exportado para **Web** e instalado no celular como **PWA**
("Adicionar à tela inicial" no iPhone/Android). Publicado automaticamente no **GitHub Pages**
a cada push na `main`. Progresso salvo **localmente no aparelho** (IndexedDB via `user://`).
Arte em pixel art gerada com o **MCP PixelLab**.

- Ideia/regras do jogo: `docs/GAME_DESIGN.md`
- Fases e próximas tarefas: `docs/ROADMAP.md`

## Estrutura
```
CLAUDE.md            este mapa
README.md            descrição pública + link do jogo
docs/                documentação (design, arquitetura, arte, deploy, roadmap)
tools/               scripts PowerShell (export e servidor local)
.github/workflows/   deploy.yml: build Web + GitHub Pages
build/               saída do export (gerada, ignorada no git)
game/                PROJETO GODOT (abra game/project.godot no editor)
  autoload/          singletons globais: Events, GameState, SaveManager
  scenes/            cenas, uma pasta por cena (.tscn + .gd juntos)
    main/            cena inicial
    ui/              menus, HUD, popups
    levels/          fases/mapas
    entities/        jogador, inimigos, itens, NPCs
  scripts/           código sem cena (utils, Resources customizados)
  data/              dados de jogo (.tres/.json): balanceamento, itens, fases
  assets/            sprites/(characters,tiles,ui,fx), audio/(music,sfx), fonts/, icons/ (PWA)
  tests/             testes (excluídos do export)
```

## Onde trabalhar (guia rápido)
| Quero...                              | Vá para |
|---------------------------------------|---------|
| Adicionar dado que deve ser salvo     | `game/autoload/game_state.gd` (campo + `to_dict`/`from_dict`/`reset`) |
| Mudar formato do save                 | `game/autoload/save_manager.gd` (`SAVE_VERSION` + `_migrate`) |
| Comunicar sistemas desacoplados       | sinal novo em `game/autoload/events.gd` |
| Criar tela/menu                       | `game/scenes/ui/<nome>/` |
| Criar personagem/inimigo/item         | `game/scenes/entities/<nome>/` |
| Criar fase                            | `game/scenes/levels/<nome>/` |
| Adicionar sprite do PixelLab          | `game/assets/sprites/<categoria>/` (ver `docs/ART_PIPELINE.md`) |
| Mudar resolução/orientação            | `game/project.godot` `[display]` + `progressive_web_app/orientation` em `game/export_presets.cfg` |
| Mudar build/deploy                    | `tools/export_web.ps1`, `.github/workflows/deploy.yml`, `docs/DEPLOY.md` |

## Regras de arquitetura
- **Disco só via `SaveManager`.** Nenhum outro script usa `FileAccess` para save.
- **Estado persistente só em `GameState`.** Cenas leem/alteram o estado por métodos dele.
- **Sinais globais só em `Events`.** Sinais locais ficam na cena.
- Export **Web single-thread** e renderer **Compatibility**: não ligar threads (GitHub Pages
  não envia headers COOP/COEP) nem usar recursos exclusivos de Forward+/Mobile.
- Pensar **mobile primeiro**: celular em pé (base 360×780, `stretch=expand`), só toque,
  alvos grandes, ações perto do polegar, pouca memória. **Nada de botões direcionais/joystick.**
- **Tempo real:** timers (plantação, fogão) e necessidades guardam timestamps Unix, nunca
  contadores por frame, para continuarem com o app fechado.
- **Conteúdo orientado a dados:** itens, receitas, plantas, missões e ambientes ficam em
  `game/data/` como Resources; o código dos sistemas não tem conteúdo fixo.

## Convenções
- Arquivos e pastas em `snake_case`; `class_name` em `PascalCase`; GDScript **sempre tipado**.
- Cena e script com o mesmo nome, na mesma pasta (`player/player.tscn` + `player/player.gd`).
- Nós acessados por código usam nome único (`%Nome`).
- Comentários e docs em português.
- Commitar os arquivos `.uid` e `.import` gerados pelo Godot; nunca commitar `.godot/` ou `build/`.
- Ao mudar estrutura ou arquitetura, **atualize este arquivo e o doc relevante em `docs/`**.

## Comandos
```powershell
# Godot (caminho atual; pode ser sobrescrito com $env:GODOT_BIN)
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

powershell -ExecutionPolicy Bypass -File tools\export_web.ps1   # build Web em build/web
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1  # http://localhost:8000
& $env:GODOT_BIN --headless --path game --quit-after 60         # checar erros de script
```
Deploy: `git push` na `main` → GitHub Actions → GitHub Pages.
