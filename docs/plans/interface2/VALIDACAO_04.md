# Interface 2 — validação da etapa 04

24/10/2026, Codex, continuação do executor anterior. Somente apresentação e fluxo de interface.
Etapa 03 conferida como `[x]`; capturas anteriores preservadas em `build/screenshots/i2_04_antes/`.

## Teste adicional justificado antes de executar

A busca por nomes removidos encontrou `growth_ui_test` procurando `GrowthBadgeHint`.
A etapa 04 retira esse selo solto: a indicação equivalente passa a `ProfileCount` do HUD.
A garantia continua sendo mostrar que falta um requisito (`3/4` visível; o painel agrupa Casa + caminha em um passo).
Executar somente `growth_ui_test` além da lista fechada, conforme 04 §E.1, porque ele depende
exatamente do nó removido nesta etapa. Nenhuma suíte inteira ou campanha.

## Pronto quando

- [x] Rodapé e botão Cuidar embaixo; roleta espaçada, translúcida, rosto visível.
- [x] Cuidados preservados por toque/arrasto, incluindo comida, esponja, bola e escova.
- [x] CareAsk atende às quatro necessidades; sono acorda direto; passeio oculta os cuidados.
- [x] Lista fechada verde, toque Web emulado executado, PNGs abertos e comparados.

## Testes e evidência

`-DryRun` confirmou somente rápido + sete testes da etapa (dez verificações).
Lista final: **10/10 PASS em 142,1 s**, sem erros de script nos logs finais:
`build/test_logs/r20261024_200942_9af303fe/results.csv`.

| Teste | Resultado | Segundos |
|---|---|---|
| scripts_check | PASS | 9,6 |
| content_test | PASS | 6,8 |
| texts_test | PASS | 2,8 |
| care_wheel_test | PASS | 13,8 |
| pet_care_test | PASS | 30,8 |
| care_ui_test | PASS | 15,4 |
| brush_taste_test | PASS | 11,1 |
| gestures_test | PASS | 12,6 |
| wish_guide_test | PASS | 12,7 |
| pet_anchor_test | PASS | 25,0 |

Extra justificado acima: `growth_ui_test` **PASS em 15,3 s** (processo/runner),
`build/i2_04_growth_final.log`, `.err` vazio e `build/i2_04_growth_final_seconds.txt`.
Total da lista + extra: **157,4 s**. Não houve suíte inteira nem campanha.

O teste novo foi registrado em suite, área pet e paths, com `.uid`, e executado sozinho antes da lista.
Além dos onze casos pedidos, verifica toque do botão pelo viewport e liberação/restauração da largura
ocupada pelos anéis ao trocar de aba. Os quatro atalhos são exercitados individualmente.

Correções durante a validação:
- `UiKit.alert_badge()` devolvia um ponto vazio; agora é uma exclamação branca em selo vermelho,
  corrigindo a falha prévia do caderninho sem mudar sua asserção.
- Arco usa coordenadas fracionárias: 64,00002 px compara com 64 por `is_equal_approx`.
  Igualdade de tamanho, limites da tela e distância mínima continuam conferidos.
- `PetCareTray._has_point` deixa o fundo PASS sem interceptar os irmãos Tiro/WishBubble.
  `wish_guide_test` voltou a passar pelo toque no viewport, sem trocar por emissão direta de sinal.
- O teste extra inicialmente esperou 2/3, a contagem agrupada do painel. O HUD mostra 3/4 requisitos
  reais (Casa e caminha separados); a asserção final exige 3/4 visível, portanto ainda falta exatamente um.

Mudanças de contrato visual nos testes afetados: anéis 40 no HUD; discos 64 no arco com distância ≥80
(em lugar de uma linha com discos 56); cinco opções de comida em linhas 56; marcador vermelho nas
necessidades pedindo e estrela de momento no desejo. Todos os contadores, ganhos, recargas, limiares
de gesto, ausência, limpeza de alfinete e condições dos cuidados continuam sendo verificados.
`NeedPillar_<id>` permanece com esse nome, agora o pontinho do anel; não se conserva um ícone invisível
só para satisfazer o teste. `WishSpark` substitui visualmente o antigo ícone de pilar.

## Toque no export Web local

Export prod/dev concluído: `build/i2_04_export.log`. Servidor exclusivamente local; nada publicado.
`tools/touch_test.ps1 -Url http://localhost:8000/dev/ -Steps build/touch_steps_i2_04.json`.
Chrome headless com toque emulado, 390×844 CSS, escala de dispositivo 2, perfil descartável.
Depois das cinco falas iniciais, volta à aba Tiro e realiza a sequência pedida:
Cuidar → roleta; Banho → cuidado e fechamento; Cuidar → Comida; arrasto da primeira ração à cabeça;
toque fora → menu fechado. Seis PNGs abertos em `build/touch_test/i2_04_*.png`, console sem erros.
O roteiro inclui saves antes/depois do perfil descartável:
`i2_04_00_antes.json` e `i2_04_04_depois.json`.
Higiene **70 → 99,997**, barriga **40 → 64,958**, ração **3 → 2** (decaimento real durante o roteiro).
É evidência de toque emulado; não houve aparelho físico.

## Capturas e revisão visual

Antes: `build/screenshots/i2_04_antes/`, preservado do executor anterior.
Depois, sete PNGs por pasta, nas três resoluções solicitadas:
`build/screenshots/i2_04_depois/`, `i2_04_depois_390/`, `i2_04_depois_412/`.
Bloco `--i2-04-only`: fechado sem pedido, fome, cinco/quatro discos, comida, sono e alfinete.
Os PNGs foram abertos e comparados com `prototipo/tiro_cuidar.png` e `tiro_roleta.png`.

| Estado | Conferência |
|---|---|
| Fechado / pedindo | ✓ Fredoka/Nunito; rótulo acima do rodapé; CareAsk visível apenas pedindo; balão dentro da borda |
| Roleta 4/5 | ✓ ordem Comida/Banho/Escovar/Brincar/Dormir; discos espaçados; nomes legíveis; rosto visível; sem humor/caderninho |
| FoodMenu | ✓ cartão branco, ícone em disco, quantidade separada, Provar, acima do botão, cinco linhas antes de rolar |
| Sono / passeio | ✓ Acordar direto; roleta bloqueada dormindo; AwayView e cuidados ocultos na viagem cobertos nos testes |
| Alfinete / HUD | ✓ raiz Polygon2D filha do destino, disco com ícone, limpeza por ação/saída; anéis só na aba Tiro |

Revisão comum: ✓ fontes e paleta da bíblia; controles lisos; pixel nos itens; alvos dos discos 64,
CareButton 72 e CareAsk 44 (desenho 30); nenhuma ação atrás do rodapé; Menos animação no teste novo;
sem novos botões verdes grandes ou arte. Anéis usam os 40 px expressos no passo a passo.

Diferenças deliberadas do protótipo:
- Ordem dos discos segue o jogo e a seção 3.3, com Escovar no centro quando há cinco.
- ZOOM 1,75 multiplica a escala de largura inteira, como exige 3.1; o HTML usa 1,75 direto sobre o
  recorte de 289 px. O enquadramento real fica mais próximo. Âncoras continuam relativas e passaram
  em retrato, paisagem, volta de abas e todos os corpos/clipes; nenhum sprite do Tiro mudou.
- Ícones atuais de esponja e acordar preservados; o protótipo usa banheira/lua ilustrativas.
- Contorno interno dos discos 2 px, pois StyleBoxFlat usa largura inteira (plano descreve 1,5).
- Etiqueta Cuidar sobrepõe 12 px à parte inferior do disco para ficar inteiramente acima do rodapé,
  mantendo o centro exato a 126 px da borda inferior.
- Caderninho fica em 46% da altura, conforme o passo a passo. Hora real no toque Web dá cenário noturno;
  tour força 12 h. Itens, desejos, animações e fase explicam diferenças entre capturas e o desenho estático.

## Arquivos, APIs e passagem

- `pet_care_tray.gd`: Control de tela cheia, `CareButton`, `CareAsk`, `CareWheelOpen`,
  `open_wheel/close_wheel/_toggle_wheel/_asked_care/_refresh_wheel/_draw_wheel/_on_veil_input/_has_point`;
  mesma API de gestos e ações, FoodMenu ancorado no botão, ShampooToggle junto ao Banho,
  CarePointer poligonal com disco branco/mel e ícone.
- `pet_screen.gd`: anéis na segunda linha do HUD (`sync_hud`), `wheel_changed`, humor de 2,5 s,
  desejo branco com bolinhas e `WishSpark`, sem selo solto de crescimento, âncora/escala aproximadas.
- `pet_backdrop.gd`: ZOOM, FOCUS_X, scene_rect e pet_feet; `main.gd`: rodapé unido só no Tiro.
- `ui_kit.gd`: `care_disc(texture, caption, callback, px=64, overlap_caption=false)` e correção de alert_badge.
- `care_wheel_test.gd/.uid`, testes afetados, dependência de growth_ui_test, tour, mapa de testes,
  README/ROADMAP e AGENTS/CLAUDE idênticos.

Sem mudança de GameState, JSON de conteúdo, falas, save, gestos ou PetAnimator. Alterações alheias
em `assets/` e sprites do bebê ficaram intocadas e fora do commit. Sem push/publicação.
Próxima: **05**, não iniciada. Caderninho largo (08), mapas/etiquetas (06), bandejas (07),
contratos (09) e modais (10) continuam nas respectivas etapas. Testes que procuravam os anéis
na PetScreen agora devem buscá-los em main/HUD. `StepCard` sem nome de capítulo e aviso antigo de
lambda ao fechar Popover continuam observações da etapa 03. Não há pendência funcional desta etapa.
