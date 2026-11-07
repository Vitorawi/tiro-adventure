# Prompt pronto — etapa 07

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 07 do plano “Fotos do Tiro — cartas colecionáveis”.
Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md,
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md, etapas/ETAPA_07_PISTAS.md,
VALIDACAO_06.md e os arquivos atuais antes de editar. Siga passo a passo,
“não fazer”, testes numerados e critério de pronto.

Contexto da 06:
- CodexSections._album mantém filtros/visita e devolve album_section + cols: 2.
  CodexUi._grid_area monta AlbumView.book(section, width), sem tiles externos.
- AlbumView.panel encaminha ao CodexUi; AlbumGrid tem AlbumCard_<id>, duas colunas.
  AlbumSummary inclui fotos obtidas (inclusive fechadas), versões e quatro níveis.
- AlbumSealed conta cartas fechadas de todas as seções ativas; AlbumOpenSealed
  chama open_photo da primeira, sem consumo ao montar nem ao tocar na faixa.
- AlbumView.preview usa PhotoCard para abertas e versão mostrada; faltantes usam
  ilustração base reduzida a 24 px, cinza/escura. Segredos (tricks/sleep ou secret)
  sem album.hints usam só CardBack e ???; jamais carregam sua ilustração.
- secret_detail virou folha de madeira (PhotoSecret/CodexDetail), sem herói vazio,
  com pista atual, lupa/HintIcons e Voltar ao álbum. Tem folga acima das abas.
- AlbumView.near_entries(section) é provisório e barato: hint + stat_min único,
  have > 0 e < need e destino conhecido; até três, por fração. Nenhuma foto atual
  combina hint e contador útil; AlbumNear só aparece com fixture nos testes e
  captura 09. Na 07, substitua essa consulta por GameState.near_photos e use
  GameState.photo_hint para prévia e detalhe. Não conservar inferência de destinos
  quando houver goal_hint.go nos dados. Não alterar on/when.
- CodexUi.album_scroll[section] guarda {scroll}; restaura ao trocar filtro/voltar.
  Novo continua por seen, separado de sealed. As outras abas mantêm seu layout.
- album_book_test já cobre os cinco grupos da 06, seleção do nível, rolagem por
  seção, Quase lá com fixture privada e ausência de SubViewport na grade.

Na 07: goal_hint nas 54 fotos, photo_hint/near_photos, progresso/ícone/Ir,
segredo poético até lupa e pista concreta depois, PhotoHint de madeira e Conversar
com hint_npc, conforme ETAPA_07_PISTAS.md. Preserve regras da lupa e obtenção.

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem
nos testes de rolagem. Nunca use tools/art/album_rarity_tests/. Não instalar lotes.
Preserve arte aprovada da 03: carta quadrada, Rara limpa, holográfico só DENTRO
DA FOTO e sem símbolo sobre a foto holográfica. Não redesenhar molduras/foil.
CardReveal/CardViewer das 04/05 continuam sendo a única abertura/revelação;
consumo/sorteio só ao Abrir. Sem novas regras de sorteio, custos ou obtenção.
Madeira ilustrada, um botão verde, bloqueios StepCardUi.locked_button, alvos >=44,
ilustrações suaves. SubViewport só no visualizador; nenhum _process por carta.
Classe nova exige --headless --path game --import. PNG novo com .import/mipmaps.

Registre photo_hints_test em suite e album de tools/test_areas.json.
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests photo_hints_test,album_book_test,album_secrets_test,content_test,texts_test -KeepGoing
Sem portão, campanha ou simulador. Capturas fotos_07_shots.gd SEM --headless em
360x780, 390x844, 412x915; abrir/conferir PNGs. Use save descartável.

Ao terminar: Registro no README; AGENTS.md e CLAUDE.md iguais; Estado atual do
ROADMAP. Resumo curto, testes, capturas, pendências e prompt pronto da etapa 08.
Não fazer commit, push nem publicação. Não executar a 08 nesta sessão.
