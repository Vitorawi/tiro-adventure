# Prompt pronto — etapa 10

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 10 do plano “Fotos do Tiro — cartas colecionáveis”.
Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md (§7),
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md, etapas/ETAPA_10_RECOMPENSAS.md,
o registro da 08 no README e os arquivos atuais antes de editar. Siga passo a
passo, “não fazer”, testes numerados e critério de pronto.

Contexto da 09:
- Tutorial: `AlbumTutorial` (scripts/ui/album_tutorial.gd), passos salvos em `AlbumState.tutorial`; níveis forçados só em `GameState._tutorial_level`.
- O marco pode ser atingido durante o tutorial: pague normalmente; o tutorial não paga nada sozinho.
- Abrir/rolar/melhorar emitem `Events.photo_rolled`; prêmios automáticos usam `GameState._grant_automatic` (recibos em "Presentes para guardar").

Preserve alterações locais dos outros agentes. Dados em album.json → cards.rewards, teste novo tests/album_rewards_test.gd e capturas tests/fotos_10_shots.gd. Não mexa em drag_scroll.gd nem nos
testes de rolagem, nem em HouseUi/HouseDecor. Nunca use tools/art/album_rarity_tests/.
Não instalar lotes. Preserve a arte aprovada da 03. Sem novas regras de sorteio,
custos ou obtenção. Madeira ilustrada, um botão verde, bloqueios
StepCardUi.locked_button, alvos >= 44. Classe nova exige --headless --path game --import.
Registre testes novos em suite e na área certa de tools/test_areas.json.
Sem portão, campanha ou simulador. Capturas SEM --headless nas três resoluções,
PNGs abertos e auditados; save descartável.
Ao terminar: Registro no README; AGENTS.md e CLAUDE.md iguais; Estado atual do
ROADMAP. Resumo curto, testes, capturas, pendências e prompt pronto da etapa 10.
Não fazer commit, push nem publicação. Não executar a 11 nesta sessão.
