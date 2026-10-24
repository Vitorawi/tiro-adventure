# 04 — Regras do executor, checklist, capturas e testes

> Vale para todas as etapas. Quem executa é outro modelo (Sonnet ou Codex): leia inteiro antes da primeira
> etapa e volte aqui sempre que for criar teste, captura ou peça.

## A. Contrato do executor

1. **Uma etapa por sessão**, na ordem do README. Confirme que a anterior está marcada como feita. Não
   adiante telas de etapas futuras: elas ganham o visual novo "de graça" pelo tema (01) e pelas peças (02)
   e são refeitas na etapa delas.
2. **Só interface e fluxo de interface.** Não mude tempos, preços, prêmios, requisitos, ids de conteúdo,
   missões, falas da história nem o formato do save. Exceções previstas (e só elas):
   - etapa 05: a interface emite `Events.items_gained` depois de um `claim_quest` bem-sucedido, como as
     diárias já fazem (`ProgressionUi.claim_routine_rows`); o `GameState` não muda;
   - preferências de interface em `GameState.progress.seen["ui:<chave>"]` (por save) ou `settings.json`
     via `SaveManager` (do aparelho, como "Vibrar"/"Menos animação").
   Se surgir necessidade de campo salvo novo: pare e pergunte ao Vitor; se aprovado, suba `SAVE_VERSION`
   sem migração (regra "saves sempre zerados").
3. **Arquitetura do `CLAUDE.md`:** ações só por métodos do `GameState` (devolvem `""` ou o motivo);
   estado só no `GameState`; sinais globais só em `Events`; GDScript **sempre tipado**; cena + script com o
   mesmo nome na mesma pasta; comentários em português; toque chega como `InputEventMouse*`
   (`emulate_mouse_from_touch`).
4. **Tokens só da bíblia** (`01_BIBLIA_VISUAL.md`). Cores de `Palette`, tamanhos das variações do tema,
   tempos de `Motion`, peças do `UiKit`. Proibido em código novo: `Color("...")`/`Color(r, g, b)` soltos,
   `add_theme_font_size_override` fora do `UiKit`, ícone de controle em PNG pixel, `StyleBoxFlat` montado à
   mão dentro de uma tela (vai para o `UiKit` ou para o tema).
5. **Nomes de nós usados em testes continuam existindo** (listas em `03_TELAS.md` e em cada etapa). Antes de
   renomear ou remover um nó: `Select-String -Path game\tests\*.gd -Pattern '<Nome>'`. Se o teste precisa
   mudar porque o fluxo mudou de propósito, ele muda **na mesma etapa**, sem enfraquecer a garantia (troque a
   forma de achar o nó, não o que é verificado) e o motivo vai para o registro.
6. **Celular primeiro:** alvo de toque ≥ 44×44 (a parte visível pode ser menor, com folga invisível); ação
   principal no terço de baixo; nada atrás do rodapé (84 px) nem da barra de gestos; conferir 360×780,
   390×844 e 412×915.
7. **Delegação:** o Claude Code escreve o pedido a partir do arquivo da etapa, entrega a um subagente Sonnet
   (ou ao Codex), confere diff, capturas e testes e pede correções. Quem executa **não** abre a etapa seguinte.
8. **Ao terminar:** registro no README do plano (modelo no fim de cada etapa); bloco no topo do "Estado
   atual" do `docs/ROADMAP.md`; `CLAUDE.md` **e** `AGENTS.md` (conteúdo idêntico, conferir com
   `cmp`/`fc`) quando criar peça, arquivo, comando ou mudar o "Onde trabalhar"; commit local
   `feat(ui2): etapa NN — <resumo>` com a linha de coautoria do ambiente. **Sem push, sem publicar.**
9. **Windows/acentos:** nunca `Set-Content`/`Out-File` sem `-Encoding utf8`; prefira as ferramentas de
   edição. Cuidado com `\t`, `\n` e crases dentro de comandos de shell: grave scripts em arquivo.
10. **Se travar** (3 tentativas sem ficar bom): entregue o resto, deixe o comportamento antigo naquele
    ponto, anote no registro e siga.
11. **Classe nova (`class_name`)**: rode `& $env:GODOT_BIN --headless --path game --import` uma vez antes
    dos testes (o `test.ps1` já faz isso sozinho quando detecta classe fora do cache).

## B. Checklist de revisão (cada tela tocada na etapa)

Copie para o registro da etapa com ✓/✗ por tela.

**Visual**
- [ ] Só Fredoka/Nunito, nos 4 tamanhos da bíblia; nenhuma Jersey 10 sobrando.
- [ ] Nenhum ícone de controle pixel (X, ?, cadeado, check, engrenagem, relógio, setas, +, −).
- [ ] Todo ícone pixel está dentro de algo liso (disco, tile, chip, pílula); nada solto no papel.
- [ ] Uma cor = um significado (verde fazer/pronto; mel prêmio/crescer; azul tempo/progresso; vermelho pede).
      Seleção = contorno de tinta, nunca verde.
- [ ] No máximo um botão verde grande visível (fora `Pegar` pequeno, um por linha).
- [ ] Espaços da grade (4/8/12/16/24/32); margem lateral 16; cartão 20; sombras quentes.
- [ ] Valor maior que o rótulo.

**Jogo**
- [ ] Cada elemento precisa estar aqui **agora**? (nada de "sopa de interface")
- [ ] Texto dentro do orçamento (§C); no máximo uma linha por cartão/linha.
- [ ] Toda ação responde em < 200 ms (aperto, voo, contagem, vibração).
- [ ] O estado importante aparece sem abrir nada (progresso, tempo, o que falta).
- [ ] Ensina fazendo: nenhuma instrução em texto que o gesto já ensina.
- [ ] Bloqueio mostra o que falta (ícone) e é tocável; nunca botão cinza mudo.
- [ ] No máximo um elemento pulando por tela.

**Celular**
- [ ] Alvos ≥ 44; ação principal no terço de baixo.
- [ ] Nada cortado ou sobreposto em 360/390/412; nada atrás do rodapé.
- [ ] Contraste da bíblia respeitado; a cor nunca é o único sinal (sempre ícone ou forma junto).
- [ ] Menos animação: tudo aparece parado e funcionando.
- [ ] Estados desenhados: vazio (com orientação e `Ir`), andando, erro, sucesso.

## C. Orçamento de texto por tela (palavras visíveis sem rolar, fora nomes de coisas e números)

| Tela | Máximo |
|---|---|
| Tiro | rótulos da roleta (só aberta) + humor (só quando muda) |
| Mapa (mundo) | **nenhum** texto fixo (02 §1.1); nome só ao tocar e segurar |
| Bandeja | nome da estação/receita + 1 verbo no botão |
| Missões | falas dos personagens + nomes das missões; nenhuma instrução extra |
| Folha de prêmio | 1 fala (até 14 palavras) + 2 botões |
| Mochila / detalhe do item | 1 linha de uso |
| Painéis grandes | 1 linha por cartão |

## D. Capturas (só das telas da etapa)

O tour `game/tests/ui_tour.gd` é uma sequência longa (~114 PNGs). Ele já tem blocos que rodam só um
pedaço (`--pet-only`, `--lists-only`, `--festa-only`...). **Cada etapa deste plano cria o seu bloco
`--i2-NN-only`** no mesmo padrão (ver `ui_tour.gd:78-140`): `state.call("reset")`, `seen["intro"] = true`,
`dev_unlock_everything` + `_mark_all_seen` quando precisar de tudo aberto, `await _start_main(1.5)`, as
capturas da etapa com nomes `i2_NN_<tela>` e `quit(0)`.

```powershell
$env:GODOT_BIN = "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# antes de mexer (o bloco novo ainda não existe na primeira vez: use o bloco equivalente antigo ou o tour completo)
& $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --i2-NN-only --out=i2_NN_antes
# no fim
& $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --i2-NN-only --out=i2_NN_depois
& $env:GODOT_BIN --path game --resolution 390x844 -s res://tests/ui_tour.gd -- --i2-NN-only --out=i2_NN_depois_390
& $env:GODOT_BIN --path game --resolution 412x915 -s res://tests/ui_tour.gd -- --i2-NN-only --out=i2_NN_depois_412
```

- Captura precisa de janela: **não** use `--headless`.
- **Abra** os PNGs (`build/screenshots/<pasta>/`) e compare com o protótipo da tela em
  `docs/plans/interface2/prototipo/` e com o "antes". Escreva no registro o que ficou diferente do protótipo
  e por quê.
- Tour **completo** só nas etapas 01 (o tema muda tudo) e 12. Linha de base: `build/screenshots/interface2_antes`.

## E. Testes: o que testar e quanto

**Filosofia (pedido do Vitor, 24/10/2026): testes enxutos e direcionados.**
- Teste **comportamento e contrato**, não pixel: "tocar no disco Comida abre o `FoodMenu`", "a pílula some
  com a história concluída", "pegar duas vezes não paga duas vezes". Medidas só onde são regra da bíblia
  (alvo ≥ 44, altura do rodapé 84, um `PrimaryButton` por painel).
- O visual é conferido nas **capturas**, com os olhos, contra o protótipo — não em teste.
- Cada etapa roda **só** o teste novo dela + uma **lista fechada** de testes afetados, com orçamento de
  **≤ 3 min somados** (tempos medidos em `build/test_logs/times.csv`).
- A suíte inteira roda **uma vez**, na etapa 12. Campanha (`progression_test` + simulador) **nunca** roda
  neste plano: nenhuma regra do jogo muda.
- "Verde é verde": um teste da lista que falhar é consertado na etapa; não existe "falha histórica".
- Precisa de mais um teste além da lista? Justifique no registro antes de rodar. Teste com mais de 60 s
  (`station_tray_test` 135 s, `tray_test` 65 s, `animals_test` 45 s, `nature_test` 44 s) só se a etapa mexer
  diretamente no que ele cobre.

**Comando** (o `-Exact` é criado na etapa 01; antes dele, use `tools\test_all.ps1 -Only <lista>`):

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests ui2_tokens_test,ui_style_test -DryRun   # confere a lista e a estimativa
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests ui2_tokens_test,ui_style_test
```

O nível "etapa" sempre inclui o `rapido` (importação se preciso, checagem de scripts, `content_test`,
`texts_test`: ~15 s). Logs em `build/test_logs/<execução>/`; tempos atualizados em `times.csv`.

### E.1 Listas por etapa

| Etapa | Teste novo | Lista fechada (segundos medidos) | Total |
|---|---|---|---|
| 01 base | `ui2_tokens_test` | `ui_style_test` 8, `ui_base_test` 3, `hud_test` 12, `sheet_test` 17 | ~1 min |
| 02 peças | `ui2_kit_test` | `ui_style_test` 8, `ui_base_test` 3, `sheet_test` 17, `lists_test` 18 | ~1 min 10 |
| 03 casca | `next_step_test`, `notice_test` | `hud_test` 12, `hud_growth_test` 16, `festa_test` 10, `welcome_test` 10, `ready_badges_test` 19, `effects_layer_test` 16, `world_selector_test` 24 | ~2 min 30 |
| 04 Tiro | `care_wheel_test` | `pet_care_test` 41, `care_ui_test` 14, `brush_taste_test` 10, `gestures_test` 15, `wish_guide_test` 12, `pet_anchor_test` 23 | ~2 min 30 |
| 05 missões | `quest_reward_test` | `tasks_test` 26, `tasks_groups_test` 18, `lists_test` 18, `navigation_test` 13, `journey_test` 11 | ~2 min |
| 06 mundo | `world_pin_test` | `world_view_test` 31, `world_selector_test` 24, `balloon_test` 26, `intro_test` 17, `farm_market_label_test` 16, `npc_lines_test` 18 | ~2 min 40 |
| 07 horta e bandejas | `farm_dock_test` | `tray_test` 65, `garden_test` 8, `queue_test` 9, `recipe_help_test` 11 — **+ `station_tray_test` 135** se a `StationTray` mudar (muda nesta etapa: entra) | ~4 min (exceção registrada) |
| 08 mochila | — | `lists_test` 18, `pending_gifts_test` 27, `album_test` 13, `petshop_test` 7, `item_sources_test` 8 | ~1 min 20 |
| 09 painéis | — | `growth_ui_test` 16, `market_test` 26, `bench_test` 38, `walks_test` 11, `tricks_test` 12, `ui_style_test` 8 | ~2 min |
| 10 festa | — | `festa_test` 10, `welcome_test` 10, `ceremony_test` 21, `walk_return_ui_test` 20 | ~1 min 10 |
| 11 texto | `text_budget_test` | `texts_test` 3, `content_test` 7, `ui_style_test` 8 | ~30 s |
| 12 fechamento | — | **suíte inteira, uma vez** (`-Level portao`, 3 processos) | ~10 min |

### E.2 Modelo de teste (padrão do projeto — ver `game/tests/hud_test.gd`)

```gdscript
extends SceneTree
## Interface 2, etapa NN: <o que este teste garante, em uma frase>.

var failures: int = 0
var state: Node
var main: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("NOME: " + message)


func _run() -> void:
	# Sem disco: tira o SaveManager (nada é gravado).
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true   # pula a chegada da Laís
	Motion.reduced = true                         # animações terminam na hora
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	await _caso_um()
	await _caso_dois()
	Motion.reduced = false
	print("NOME TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
```

Regras do modelo:
- Um `func _caso_*()` por comportamento, cada um começando de um estado conhecido (`state.call("reset")`
  quando precisar) e com mensagens de `check` que digam **o que** deveria acontecer, em português.
- Ache nós com `main.find_child("Nome", true, false)`; nunca por índice de filho.
- Toque: simule com `InputEventMouseButton` (pressed/released) e `InputEventMouseMotion` enviados por
  `root.push_input(evento)` ou chamando o método público da peça (ex.: `press_item`/`move_item`/
  `release_item` do `PetCareTray`). Prefira o método público quando ele existir.
- Tempo de jogo: use `state.call("now")`/campos `ready_at` só por métodos do `GameState` ou `dev_*`
  (a versão dev é a do executável; `BuildInfo.is_dev()` é verdadeiro nos testes).
- Nada de `await create_timer` maior que 0,5 s; com `Motion.reduced = true` não é preciso esperar animação.
- Cenários de missão prontos para usar: `welcome` (objetivo `talk:lais`; `state.call("talk_to", "lais")` deixa
  pronta), `lais_feed` (objetivo `feed`; precisa de `dog_food`, que o prêmio de `welcome` dá),
  `lais_meet_bloblo` (capítulo 2, `shared_with: bloblo_meet` — o caso da história que aponta para personagem);
  `state.call("dev_complete_quest", id)` conclui uma missão direto.

### E.3 Registrar um teste novo

1. Arquivo em `game/tests/<nome>.gd` + o `.uid` que o Godot gerar (commitar os dois).
2. `tools/test_areas.json`: o nome em `suite` **e** em `tests` da área certa (`ui_kit`, `shell`, `pet`,
   `story`, `world`, `farm`, `checks`...), e o caminho do arquivo em `paths` da mesma área. Sem isso o
   `test.ps1` recusa ("Teste órfão" / "Teste desconhecido").
3. Rodar sozinho primeiro: `powershell -ExecutionPolicy Bypass -File tools\run_godot_test.ps1 <nome>`.

## F. Teste de toque real (só onde há gesto novo)

Etapas 04 (roleta), 07 (barra da horta) e 12 (roteiro completo):

```powershell
powershell -ExecutionPolicy Bypass -File tools\export_web.ps1
powershell -ExecutionPolicy Bypass -File tools\serve_local.ps1      # em outro terminal / segundo plano
powershell -ExecutionPolicy Bypass -File tools\touch_test.ps1 -Url http://localhost:8000/dev/ -Steps build\touch_steps_i2_NN.json
```

O roteiro (`tap`, `drag`, `shot`) fica em `build/touch_steps_i2_NN.json` (não versionado); cada etapa diz
quais passos. Abra os `shot` gerados.
