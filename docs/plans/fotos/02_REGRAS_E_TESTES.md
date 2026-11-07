# 02 — Regras para quem executa e testes

## 1. Contrato do executor

1. Leia `AGENTS.md` (= `CLAUDE.md`), o `README.md` deste plano, `01_DESENHO.md` e o arquivo da sua etapa.
2. Faça **só a sua etapa**. Se achar que algo de outra etapa é necessário, anote em "Pendências" do registro.
3. **Preserve alterações locais de outros agentes** (`git status` tem muita coisa não commitada; nunca
   reverta, nunca `git checkout --`/`reset`). Leia o arquivo antes de editar.
4. Estado só muda por métodos do `GameState` (ação devolve `""` ou o motivo; `*_error()` igual). Classes de
   `scripts/state/` só dados + `to_dict`/`from_dict`. Sinais globais em `Events`.
5. Conteúdo e números em `game/data/album.json` (nada fixo no código). GDScript tipado, comentários em
   português, arquivos `snake_case`.
6. Classe nova com `class_name` exige `& $env:GODOT_BIN --headless --path game --import` uma vez.
7. PNG novo: commite junto o `.import` (com `mipmaps/generate=true` nas ilustrações).
8. Não altere: ids das fotos, `on`/`when`, falas existentes, outras missões, sorteios de outros sistemas.
9. Não faça commit, push nem publicação. No fim: registro no README do plano, `AGENTS.md`/`CLAUDE.md`
   (mesmo texto) e "Estado atual" do `docs/ROADMAP.md`.

## 2. Padrão visual (obrigatório)

- **Madeira ilustrada**: moldura de madeira + papel creme + placa de título + X de madeira, fonte da madeira
  marrom (`HomeUi.theme`), botões verde (um por tela, meta `wood_primary`) e amarelo de madeira, bloqueio =
  `StepCardUi.locked_button`. Nada de `UiKit.primary/soft/list_card/chip` liso nas telas novas.
- Peças a reutilizar: `StepCardUi` (`wood`, `inner_card`, `go_button`, `lock_note`, `wood_chip`,
  `help_button`, `done_medal`, `portrait_frame`), `WelcomeSheet._button` (verde/amarelo), `SellUi`
  (`nine`, `scrolled`, `style_bar`, `overlay`), `ModalCard` (cartões de festa), `MissionUi.tabs`,
  `CodexUi.tile`, `SpeechBubble(..., wood)`.
- Folhas: meta `sheet_wood` (moldura da `Sheet`) ou `sheet_bare` (a tela traz a própria moldura).
- Ilustrações suaves (`LINEAR_WITH_MIPMAPS`); ícones pixel em escala inteira e `NEAREST`. Nada distorcido.
- Alvos de toque ≥ 44 px; nada sob o HUD (`Hud.SHEET_TOP` 128) nem sob as abas; cabe em 360×780.

## 3. Desempenho (celular, Web, Compatibility)

- Sem threads; shaders `canvas_item` simples (sem laços longos, sem texturas enormes).
- Arte no jogo em 768×768 com mipmaps; nunca carregar os originais de 1254 do `tools/`.
- Grade do álbum: no máximo um shader animado barato por carta, sem `_process` por carta; `SubViewport` só
  na carta grande (visualizador) e destruído ao fechar.
- Texturas carregadas sob demanda (`load` quando a carta aparece), sem pré-carregar as 216.

## 4. Testes

Circuito do projeto (`tools/test.ps1`, mapa em `tools/test_areas.json`):
- Cada etapa: **teste novo da etapa + lista fechada** indicada no arquivo da etapa:
  `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests <lista> -KeepGoing`
  (≤ 5 min). Registre o teste novo em `suite` e na área `album` do JSON.
- **Portão** (`-Level portao`) só na etapa 11. Sem campanha nem simulador de economia.
- Teste que conferia o visual antigo: troque pela forma nova equivalente (ex.: `wood_primary` no lugar de
  `PrimaryButton`) sem enfraquecer o que ele confere de comportamento.
- Em teste `-s`, classes que dependem de autoload (`Hud`, `HomeUi`, `Notice`, `ModalCard`...) não podem ser
  referenciadas por tipo: use `find_child`/`get`/`load(...).call`.

## 5. Capturas

- Cada etapa com tela cria um script de capturas `game/tests/fotos_NN_shots.gd` (modelo:
  `tests/storage_wood_shots.gd` / `tests/welcome_shots.gd`) que salva em `build/screenshots/fotos_NN/` e
  **imprime FAIL** se: algo sai da tela ou fica sob o HUD/abas, alvo < 44, texto cortado, NinePatch com escala
  torta, imagem com razão diferente da fonte > 1%, mais de um botão verde.
- Rodar **sem** `--headless` nas três resoluções: `--resolution 360x780`, `390x844`, `412x915`. Abrir e olhar
  os PNGs antes de dizer que terminou. Efeitos animados: capturar dois instantes diferentes.
- Não grava o save pessoal (modelo: `saver.set("_save_path", ...descartavel.json)`).
