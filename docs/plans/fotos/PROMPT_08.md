# Prompt pronto — etapa 08

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 08 do plano “Fotos do Tiro — cartas colecionáveis”.
Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md,
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md, etapas/ETAPA_08_VARAL.md,
VALIDACAO_07.md e os arquivos atuais antes de editar. Siga passo a passo,
“não fazer”, testes numerados e critério de pronto.

Na 08: varal na parede da HOME do Tiro, com três polaroides (~84 px, mínimo
72 px), cordinha/pregadores e toque que abre a carta certa; espaços vazios levam
ao Álbum. Aparece só após a primeira foto aberta, some no passeio e durante o
sono se cobrir o Zz. Meça contra head_rect(), NeedsPanel, WishBubble, ManualButton
e CareButton nas três resoluções. Use featured_photos/feature_photo e a ordem
do motor; atualize ao mudar versão/featured sem reconstruir o quarto inteiro.
Menos animação para o balanço. Toque consumido, sem disparar carinho/gesto.

Contexto da 07:
- As 54 fotos têm goal_hint nos dados. GameState.photo_hint(id) fornece
  text/icon/have/need/go/revealed; segredo só revela instrução/destino após lupa.
- GameState.near_photos ordena faltantes por fração, com zeros no fim; AlbumNear
  filtra seção/progresso positivo. Sem inferência de destinos na UI.
- AlbumView.photo_hint(id) é a folha PhotoHint de madeira; secret_detail é alias.
  Prévia/grade preservam segredo, ícones/progresso, Ir, lupa e Conversar existentes.
- Álbum: CodexUi/AlbumView.book, duas colunas, rolagem por seção preservada.
- CardReveal/CardViewer continuam sendo a única abertura/revelação;
  consumo/sorteio só ao Abrir. Não abra carta fechada automaticamente no varal.
- Motor featured (até 3), FeatureButton e substituição com varal cheio já existem
  no GameState/CardViewer das 01/04. Confira o estado atual antes de integrar.

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem
nos testes de rolagem. Não mexa na parede/moldura da CASA DO MAPA (HouseUi e
HouseDecor): a 08 é só a HOME. Nunca use tools/art/album_rarity_tests/.
Não instalar lotes. Preserve arte aprovada da 03: carta quadrada, Rara limpa,
holográfico só DENTRO DA FOTO e sem símbolo sobre a foto holográfica.
Não redesenhar molduras/foil. Sem novas regras de sorteio, custos ou obtenção.
Madeira ilustrada, um botão verde, bloqueios StepCardUi.locked_button, alvos >=44,
ilustrações suaves. SubViewport só no visualizador; nenhum _process por carta.
Classe nova exige --headless --path game --import. PNG novo com .import/mipmaps.

Registre photo_line_test em suite e album de tools/test_areas.json, mais as
áreas pertinentes da home/cuidado. Confira os nomes existentes da lista da 08:
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests photo_line_test,card_viewer_test,pet_care_test,care_ui_test,home_test -KeepGoing
Sem portão, campanha ou simulador. Capturas fotos_08_shots.gd SEM --headless em
360x780, 390x844, 412x915: vazio, 1, 3 com Holográfica, dormindo e passeando;
abrir/conferir PNGs e auditar geometria. Use save descartável.

Ao terminar: Registro no README; AGENTS.md e CLAUDE.md iguais; Estado atual do
ROADMAP. Resumo curto, testes, capturas, pendências e prompt pronto da etapa 09.
Não fazer commit, push nem publicação. Não executar a 09 nesta sessão.
