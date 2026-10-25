# Interface 2 — validação da etapa 06

24/10/2026, Codex, local. Etapa 05 conferida como [x] antes de mexer.
Somente a etapa 06; próxima 07 não iniciada. Sem export, push ou publicação.

## Pronto quando

- [x] Nenhum nome fixo nos mapas; todos os caminhos físicos preservados; segurar mostra o nome.
- [x] Lugar recém-aberto brilha até o primeiro toque, sem acender tudo na primeira entrada.
- [x] WorldPin no lugar da seta, ícone do destino e anel na base do objeto em qualquer zoom.
- [x] Cartões-postais com fotos; bloqueados em cinza com cadeado; Aqui, toque único, X/fundo/Escape.
- [x] Conversa com detalhe expandido de Pessoas e serviços em linhas; compra com figura/capacidade/preço.
- [x] Lista fechada verde; miniaturas/ferramenta em ART_PIPELINE e arquitetura em AGENTS/CLAUDE idênticos.

## Implementação e auditoria

Auditoria **antes de desligar `_tap_label`**: `build/i2_06_audit_before.log`, 34 etiquetas elegíveis nos
cinco mundos. O espião substitui `_on_object_tapped` e procura pixels opacos dos sprites com a mesma ação
ou centroide da zona. Exige despacho para a ação original e `_handle_tap == true`; zero sem caminho,
zero zonas/polígonos novos. O código permanente está em `world_pin_test` + `helpers/world_tap_spy.gd`.
A primeira auditoria gerou aviso de tamanho antes de `_ready` na ferramenta descartável; corrigido no
helper permanente, sem mudar a verificação de ação. Não foi preciso alterar JSON de sala/conteúdo.

RoomView mantém as WorldLabel, mas só a etiqueta consultada aparece por 1,5 s. Timer de 500 ms no press;
soltar cedo age no mesmo released de antes, soltar após segurar é consumido, TAP_SLOP cancela o timer.
Trocar de tela cancela a consulta. `_target_at` consulta sem agir os balões, regiões, NPCs, sprites e zonas;
`_named_target` resolve a WorldLabel correspondente. Atualizar compras não torna nomes temporariamente
visíveis, mesmo com Menos animação desligado. O balão da horta antes da escritura também perdeu o texto
fixo Vovó; seu toque continua abrindo a conversa, e custos numéricos continuam aparecendo após a escritura.

Brilho: `WorldBalloon.state = spark`, disco mel 26 e controle spark branco; chave
`ui:place_tapped:<mundo>:<lugar>` via GameState.mark_seen. `ui:places_entered:<mundo>` marca os lugares
já elegíveis na primeira entrada. Sem campo novo, migração, SAVE_VERSION ou mudança de requisitos.
Balões progress/ready/queued/buy/alert mantêm hit_rect, escala e APIs; discos brancos, anéis SKY/GO,
check/plus/lock vetoriais, preço em chip claro. Regiões têm cadeado/preço no centro, sem nome.

`WorldPin` (`world_pin.gd`): nó Pointer, rabinho, disco 52/ícone 36, anel 4 e elipses 3 no chão.
`destination_icon` lê lugar/NPC/construção/canteiro. `ground_base` + ground_offset recalculado no zoom
mantêm o anel na base real; tamanho constante na tela. Menos animação deixa as elipses e o disco parados.
Timeout, clear_pointer, revelação pela câmera e toque que remove o alvo continuam.

WorldPill CARD/44/down vetorial; NpcFace CARD/44/retrato 40 e selos; PlacesButton ctl list.
WorldSelector é folha PAPER com alça/título/X; WorldCard em duas colunas e último largo. WorldPhoto,
WorldName, WorldHint, WorldOpener, CurrentWorld, WorldLock e WorldStatusRows. Fotos com filtro nearest,
contorno mel 3 e chip Aqui; bloqueados usam imagem cinza. Altura das fotos se adapta às dicas completas,
inclusive 360×640, sem cortar nomes de missões. A linha 2 da casca recolhe com o seletor aberto.

Conversa: `character_quest_detail` compartilhado com Pessoas; `npc_quest_card` expandido, ações pela
claim_quest_fx existente, retrato fora do LiveBox. NpcServices em list_card/linhas 56, ícone e chev.
NpcIntroduction avança pelo toque no SpeechBubble ou IntroductionNext vetorial; Vamos! no fim.
Compra: UpgradeHero (disco 96/ícone 64), título e descrição reais, SpaceChip, materiais have/missing
com Como fazer, BuildUpgrade com preço/ícone de moeda; erro mostra LockHint com o item que falta.
Sucesso fecha a folha. Requisitos continuam apagando o cartão a 55%.

## Testes

DryRun conferiu somente scripts_check/content_test/texts_test e os sete testes fechados.
Teste novo registrado em suite + world/tests + world/paths, com helper e UID, executado sozinho antes.
Sem suíte inteira, campanha nem teste fora da lista.

Execução consolidada: **10/10 PASS, 125,0 s de relógio, Jobs=2**.
`build/test_logs/r20261024_211438_54824706/results.csv`.

| Teste | Resultado | Segundos por processo |
|---|---|---|
| scripts_check | PASS | 10,8 |
| content_test | PASS | 7,3 |
| texts_test | PASS | 3,3 |
| world_pin_test | PASS | 27,1 |
| world_view_test | PASS | 57,2 |
| world_selector_test | PASS | 49,2 |
| balloon_test | PASS | 36,3 |
| intro_test | PASS | 17,0 |
| farm_market_label_test | PASS | 19,8 |
| npc_lines_test | PASS | 19,8 |

Somados os tempos por processo: 247,8 s (há concorrência e capturas gráficas simultâneas); o orçamento
estrito de 3 min somados do plano foi ultrapassado. A lista não foi ampliada nem as garantias reduzidas.
A execução sequencial anterior levou 191,6 s com uma falha de parse no teste da venda, depois corrigida.
O total final de relógio fica em 2 min 05 com dois processos, como conferido no DryRun (estimativa 95 s).

Após a revisão, reexecução focada de world_pin_test para ausência de piscada nos nomes e texto da horta:
**PASS**, `build/i2_06_pin_verified.log`, `.err` vazio. Esse runner focado não mede tempo próprio.
Não foi repetida a suíte nem a campanha. Logs das tentativas/correções preservados em build/i2_06_*.

Correções de validação: procura de Lugares pelo filho Disc (controle novo, mesmo alvo ≥44); medida real
da dica completa no cartão; limpeza de QuestReward na fixture do seletor (para não interceptar toques);
nome de variável hold_point sem conflito com o iterador de polígono. O teste de retrato desconecta só
a fila modal da casca: o prêmio de história fecha o Sheet desde a 05, enquanto este teste mede a
sobrevivência do retrato à reconstrução do LiveBox e seu aceno real ao receber quest_completed.
As asserções de identidade do retrato, animação de pedido/aceno, contadores, fresh e linhas independentes
continuam. Pointer conserva o nome, então intro_test/tasks_test/tray_test não precisam trocar o alvo.

## Capturas e comparação

Antes de editar o jogo: nove PNGs em `build/screenshots/i2_06_antes/` (cinco mundos, alfinete antigo,
seletor, conversa e compra), por roteiro descartável derivado do ui_tour, sem headless.
Depois: bloco `--i2-06-only`, oito PNGs em cada pasta:

- `build/screenshots/i2_06_depois/` — 360×780.
- `build/screenshots/i2_06_depois_390/` — 390×844.
- `build/screenshots/i2_06_depois_412/` — 412×915.

Estados farm, hold, spark, pin, worlds, worlds_locked, npc, buy. PNGs abertos/revisados individualmente
nos pontos críticos e em três pranchas de oito telas (prancha.png em cada pasta), comparados aos
protótipos horta_seta/mundos/fogao e às capturas anteriores. Nenhuma captura final usa headless.
A preparação de Natureza fechada espera e limpa as comemorações para não cobrir o seletor.
A captura do silo usa seu custo real zero e o ganho 16 → 32, sem inventar preço ilustrativo.

Diferenças e decisões:

- Mapas/câmera/enquadramentos reais preservados; o protótipo aproxima mais os objetos. O alfinete mantém
  sua âncora antiga e o anel vai à base verdadeira; não mudou a câmera para imitar a prancha.
- Fotos mostram o começo de cada mundo com as compras básicas, em vez dos recortes próximos ilustrativos.
  São dez imagens 300×200/cantos com alfa, incluindo cinzas; não refletem progresso atual do jogador.
- Fotos têm até 104 px (último 92), diminuindo quando dicas reais/altura pedem. Dicas completas podem
  ocupar duas/três linhas; preservam nomes e requisitos, sem inventar marco mais curto. Retrato de quem
  abre só quando a missão requerida informa um NPC; requisito apenas de capítulo não inventa um rosto.
- Aqui usa tinta mel sobre HONEY para respeitar contraste; missões usam ! vermelho, pronto tem check verde.
- Falas completas e nomes reais foram preservados. O painel da Bloblo pode ter duas missões e rolagem;
  a borda inferior da folha continua a do Sheet, sem adiantar bandejas ou modais das próximas etapas.
- Sem toque Web/aparelho: esta etapa não pede export/Web; roteiro obrigatório de gesto fica na 07.
  Segurar/soltar/arrastar e toque real nos cartões são exercitados por InputEventMouse no Godot.

## Checklist de revisão por tela

| Tela | Visual | Jogo/estados | Celular |
|---|---|---|---|
| Mundo/hold | ✓ Fredoka/Nunito, sem nomes fixos, balões lisos | ✓ toque curto/segurar/arrasto, progress/ready/buy/spark | ✓ três resoluções, consulta ancorada |
| Alfinete | ✓ disco/ícone/rabinho/anel mel | ✓ some no toque, zoom e Menos animação | ✓ base real e tamanho constante |
| Seletor | ✓ cartões/fotos/cinzas, Aqui mel, lock vetorial | ✓ fechado/atual/avisos, viagem/X/fundo/Escape | ✓ cinco destinos, sem corte/rolagem e sem pílula sobre o título |
| Conversa | ✓ retrato/fala, detalhe de Pessoas, serviços calmos | ✓ fala completa, missão/Ir/Pegar, retrato preservado | ✓ alvos 44, linhas 56, rolagem quando necessário |
| Compra | ✓ figura, capacidade, chips e botão único | ✓ requisito/material/moeda, ajuda, fechar no sucesso | ✓ conteúdo cabe, sem ação atrás da borda |

## Passagem

Nenhum autoload ou dado de conteúdo alterado. GameState, SAVE_VERSION, regras, missões, falas e prêmios
preservados. AGENTS/CLAUDE idênticos. Assets/pixellab_character/tiro_bebe e qualquer trabalho alheio não
foram tocados nem incluídos. Sem pendência funcional da etapa 06. Próxima 07 (FarmDock/bandejas),
sem adiantamento. Avisos antigos de lambda ao fechar Popover continuam fora desta etapa; as execuções
finais consultadas não registraram erro de script. Sem push/publicação.

Revalidação final (24/10/2026, após a correção do balão da horta sem texto "Vovó"): balloon_test,
world_pin_test e farm_market_label_test + rápido (scripts_check, content_test, texts_test) 6/6 PASS em
53,7 s (`build/test_logs/r20261024_223357_929e35ac/`). Capturas `--i2-06-only` refeitas nas três
resoluções (i2_06_depois, _390, _412); horta aberta e horta fechada conferidas em 360×780.
