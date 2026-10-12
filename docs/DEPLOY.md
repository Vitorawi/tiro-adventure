# Build e deploy

## Build local
```powershell
powershell -ExecutionPolicy Bypass -File tools\export_web.ps1
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1   # http://localhost:8000  (dev: /dev/)
```
`export_web.ps1 -Channel both|prod|dev` (padrão `both`: prod em `build/web/`, dev em `build/web/dev/`).
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
2. `--import` e dois `--export-release "Web"`: **prod** em `build/web/` e **dev** em `build/web/dev/`
   (cada um com seu `data/version.json` → `channel`).
3. Ajusta os service workers (ver abaixo e "Versão dev") e publica com `actions/deploy-pages`.

Configuração única no GitHub: **Settings → Pages → Source: GitHub Actions**.

URL: `https://<usuario>.github.io/<repositorio>/`

## Atualizar a versão do Godot
1. Instalar a nova versão localmente + export templates.
2. Mudar `GODOT_VERSION` no workflow e o caminho padrão em `tools/export_web.ps1`.
3. Abrir o projeto no editor, testar, commitar.

## Atualizações no celular
O service worker do Godot serve o jogo **do cache primeiro**. Uma versão nova é baixada em
segundo plano mas fica esperando o app fechar de vez — o que quase nunca acontece num PWA
no iPhone. Por isso existe o autoload `PwaUpdater` (`game/autoload/pwa_updater.gd`):
- procura atualização ao abrir, ao voltar para o app e a cada 5 min;
- quando há versão nova, emite `Events.update_available` e a tela principal mostra a faixa
  **"Nova versão! Toque para atualizar"**;
- o toque salva o jogo e chama `JavaScriptBridge.pwa_update()` (ativa a versão nova e recarrega).

Dois ajustes no build (no workflow e em `tools/export_web.ps1`):
- **Service worker sem cache HTTP:** o SW do Godot instala a versão nova com
  `cache.addAll(CACHED_FILES)`, que pode pegar arquivos antigos do cache HTTP do navegador
  (o Pages manda guardar por 10 min) — a "atualização" vinha com o jogo velho. O build troca
  por `new Request(f, { cache: 'reload' })`.
- **Versão visível:** o deploy grava `game/data/version.json` (commit + data/hora de Brasília),
  mostrado em cinza na barra superior. Local: `vdev`. Use para confirmar o que está rodando.

O save (IndexedDB) não é afetado. **Nunca** orientar o jogador a remover o app da tela inicial
para atualizar: no iPhone isso apaga o save junto.

### Aplicar a atualização
`JavaScriptBridge.pwa_update()` **não funciona no iPhone**: o service worker do Godot ignora a mensagem quando `event.origin` vem vazio (Safari). `PwaUpdater.apply_update()` faz o próprio processo: salva, espera 1 s (sincronizar IndexedDB), remove o service worker e os caches, baixa os arquivos com `cache: 'reload'` e recarrega. Atalho de emergência: **tocar no número da versão** na barra superior.

## Versão dev
Mesmo commit, duas builds no mesmo site:

| | Publicada (prod) | Dev |
|---|---|---|
| Endereço | `https://vitorawi.github.io/tiro-adventure/` | `https://vitorawi.github.io/tiro-adventure/dev/` |
| `data/version.json` → `channel` | `prod` | `dev` |
| Save | `user://save.json` | `user://save_dev.json` (o real nunca é tocado) |
| Barra superior | normal | selo vermelho **DEV** → Ferramentas DEV (`docs/PROGRESSION.md`) |
| Nome na tela inicial | Tiro Adventure | Tiro DEV |
| Prefixo do cache do SW | `Tiro Adventure-sw-cache-` | `Tiro Adventure DEV-sw-cache-` |

- O canal é lido por `BuildInfo.channel()` (`game/scripts/util/build_info.gd`). Rodando pelo
  executável do Godot (editor, testes, screenshots) é sempre **dev**; `-- --prod` força prod.
- O `version.json` versionado é `{ "version": "local", "channel": "dev" }`; o deploy e o
  `export_web.ps1` gravam o deles na hora do export (o script local restaura o arquivo depois).
- **Por que separar save e cache:** as duas builds ficam na mesma origem (`vitorawi.github.io`),
  então dividem o mesmo IndexedDB e o mesmo Cache Storage. Sem nomes diferentes, a dev
  sobrescreveria o save real, e ao ativar um service worker ele apagaria o cache do outro
  (o SW do Godot remove caches com o mesmo prefixo). O deploy troca o prefixo na build dev, e
  `PwaUpdater.apply_update()` só remove o service worker da própria página e os caches do próprio canal.
- O service worker da prod (escopo `/tiro-adventure/`) também cobre `/dev/` até a dev registrar o
  seu próprio. Isso só afeta o cache, não o jogo.
- Para testar com o progresso real: Ferramentas DEV → Save → "Copiar o save da versão publicada"
  (mesmo aparelho e navegador/app; no iPhone o app da tela inicial e o Safari têm armazenamentos separados).
