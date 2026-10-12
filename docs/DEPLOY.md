# Build e deploy

## Build local
```powershell
powershell -ExecutionPolicy Bypass -File tools\export_web.ps1
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1   # http://localhost:8000
```
O export usa o preset **"Web"** de `game/export_presets.cfg` e gera `build/web/`:
`index.html`, `index.js`, `index.wasm`, `index.pck`, `index.manifest.json`,
`index.service.worker.js` e ícones.

## Preset Web (resumo)
- `variant/thread_support=false` — single-thread, sem necessidade de headers COOP/COEP.
- `progressive_web_app/enabled=true` — gera manifest + service worker (instalável e offline).
- `progressive_web_app/display=1` (standalone), `orientation=2` (retrato).
- Ícones: `res://assets/icons/icon_{144,180,512}.png`.

## Deploy automático (GitHub Pages)
`.github/workflows/deploy.yml` roda a cada push na `main` (ou manualmente em Actions):
1. Baixa Godot 4.7.2 Linux + export templates (com cache).
2. `--import` e `--export-release "Web"` para `build/web/`.
3. Publica com `actions/deploy-pages`.

Configuração única no GitHub: **Settings → Pages → Source: GitHub Actions**.

URL: `https://<usuario>.github.io/<repositorio>/`

## Atualizar a versão do Godot
1. Instalar a nova versão localmente + export templates.
2. Mudar `GODOT_VERSION` no workflow e o caminho padrão em `tools/export_web.ps1`.
3. Abrir o projeto no editor, testar, commitar.

## Atualizações no celular
O service worker guarda o jogo em cache. Após um deploy, o PWA pode mostrar a versão antiga
na primeira abertura e atualizar na seguinte. O save não é afetado.
