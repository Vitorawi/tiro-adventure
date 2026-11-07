# Prompt pronto — etapa 05

```text
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 05 do plano "Fotos do Tiro — cartas colecionáveis".

Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md,
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md e etapas/ETAPA_05_ABRIR.md.
Leia também VALIDACAO_04.md e os arquivos atuais antes de editar.
Siga o passo a passo, os "não fazer", os testes numerados e o critério de pronto.

Contexto da etapa 04:
- CardViewer.open(id, {host}), close(), is_open(), flip_to(level) e surface_material().
- A carta atual (quadrada, como as molduras da 03) é um PhotoCard num SubViewport
  CardStage, mostrado em CardSurface com card_tilt.gdshader. Só o visualizador tem
  SubViewport; ele é destruído ao fechar. O foil recebe o mesmo tilt do dedo.
- Níveis 1/2 e Menos animação usam UPDATE_ONCE; 3/4 animados precisam UPDATE_ALWAYS
  porque o foil usa TIME. Menos animação: máximo 8 graus, sem mola, efeito parado.
- As quatro versões, Tentar a sorte, Melhorar, custos com ajuda, varal e escolha de
  substituição já funcionam. Repetida só avisa e mantém a carta; nova faz flip simples.
  Substitua esse resultado simples por CardReveal.play_result como pede a etapa 05.
- AlbumView.open_photo ainda consome as cartas fechadas automaticamente antes de
  abrir CardViewer (ponte antiga da 01). A etapa 05 precisa encaminhá-las à revelação,
  sem consumir antecipadamente nem sortear duas vezes. detail permanece como reserva.
- Main._flush_modals espera CardViewer.is_open(); ao integrar CardReveal, cuide da
  entrega para o MESMO visualizador sem bloquear a própria sequência na fila.
- A ajuda de materiais fica sobre a carta (z 9, Sheet 10); ao fechar a ajuda, a carta
  volta a z 11; Ir fecha a carta. Avisos ficam em z 12.
- Preservar a arte da 03: Rara limpa, holográfico só DENTRO DA FOTO, sem símbolo sobre
  a foto holográfica. Não alterar molduras/foil sem pedido do Vitor.
- 144 variantes revisadas (36 fotos) estão instaladas com mipmaps; o catálogo pode
  avançar em paralelo. Nível sem arte usa a ilustração da própria foto.
- photo_art_test agora testa duas instalações em build/photo_art_fixture, usando
  --catalog e --target do instalador; não instala lotes no jogo durante o teste.

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem nos
testes de rolagem. Nunca use tools/art/album_rarity_tests/. Sem regras novas de sorteio,
save, custos ou eventos de obtenção. Sem roleta. Madeira ilustrada, um botão verde,
bloqueios com StepCardUi.locked_button, alvos >= 44 px e ilustrações suaves.
Classe nova exige --headless --path game --import. PNG novo com .import e mipmaps.

Validação: registre card_reveal_test em suite e na área album de tools/test_areas.json.
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests card_reveal_test,card_viewer_test,photo_rarity_test,festa_test,notice_test,welcome_test -KeepGoing
Sem portão, campanha ou simulador. Capturas fotos_05_shots.gd SEM --headless nas
resoluções 360x780, 390x844, 412x915; abrir e conferir os PNGs. Use save descartável.

Ao terminar: preencher Registro do README; atualizar AGENTS.md e CLAUDE.md (iguais)
e Estado atual do docs/ROADMAP.md. Entregar resumo curto, testes, capturas, pendências
e prompt pronto da etapa 06. Não fazer commit, push nem publicação.
```
