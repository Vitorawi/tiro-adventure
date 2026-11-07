# Prompt pronto — etapa 09

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 09 do plano “Fotos do Tiro — cartas colecionáveis”.
Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md (§8),
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md, etapas/ETAPA_09_TUTORIAL.md,
o registro da 08 no README e os arquivos atuais antes de editar. Siga passo a
passo, “não fazer”, testes numerados e critério de pronto.

Contexto da 08:
- Varal na HOME: `PhotoLine` (scripts/ui/photo_line.gd) filho da PetScreen, nós
  `PhotoLine_<id>`/`PhotoSlot_<i>`; usa `GameState.featured_photos()`, aparece só com
  carta aberta, some no passeio. Toque abre `CardViewer.open(id)`; "+" abre o Álbum.
- Tutorial: `AlbumState.tutorial`, `album_tutorial_step/advance_album_tutorial/
  finish_album_tutorial` e `_tutorial_level` (níveis forçados, grátis) já existem (01).
  O último passo (pôr no varal) usa `feature_photo`/`FeatureButton` do CardViewer.
- CardReveal/CardViewer são a única abertura/revelação; consumo/sorteio só ao Abrir.

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem nos
testes de rolagem, nem em HouseUi/HouseDecor. Nunca use tools/art/album_rarity_tests/.
Não instalar lotes. Preserve a arte aprovada da 03. Sem novas regras de sorteio,
custos ou obtenção. Madeira ilustrada, um botão verde, bloqueios
StepCardUi.locked_button, alvos >= 44. Classe nova exige --headless --path game --import.
Registre testes novos em suite e na área certa de tools/test_areas.json.
Sem portão, campanha ou simulador. Capturas SEM --headless nas três resoluções,
PNGs abertos e auditados; save descartável.
Ao terminar: Registro no README; AGENTS.md e CLAUDE.md iguais; Estado atual do
ROADMAP. Resumo curto, testes, capturas, pendências e prompt pronto da etapa 10.
Não fazer commit, push nem publicação. Não executar a 10 nesta sessão.
