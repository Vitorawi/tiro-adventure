# Prompt pronto — etapa 11

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 11 (Fechamento) do plano “Fotos do Tiro — cartas colecionáveis”.
Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md (registro de todas as etapas),
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md e etapas/ETAPA_11_FECHAMENTO.md. Siga passo a passo,
“não fazer”, e critério de pronto.

Contexto da 10:
- Marcos de coleção: `GameState._check_album_rewards()` (fim de `_apply_photo_roll`), prêmios em `album.json → cards.rewards`
  (só moedas), `Events.album_milestone`, `Celebration.show_album_milestone`, `AlbumView` (`SectionComplete`, `StylesComplete`, `NextMilestone`).
- `photo_rarity_test` zera `cards.rewards` (mede só custos); `photo_line_test` para o timer modal. `album_rewards_test` cobre os marcos.
- Capturas da 10: `tests/fotos_10_shots.gd` (cartão de marco: 4 tipos + álbum).
- Bloco `--fotos-only` do tour deve incluir o cartão de marco.

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem nos testes de rolagem,
nem em HouseUi/HouseDecor. Nunca use tools/art/album_rarity_tests/. Portão uma vez (sem campanha/simulador).
Capturas SEM --headless nas três resoluções, PNGs abertos e auditados; save descartável.
Ao terminar: Registro no README; AGENTS.md e CLAUDE.md iguais; Estado atual do ROADMAP; RESULTADOS.md com o roteiro do celular.
Não fazer commit, push nem publicação.
