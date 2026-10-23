# Etapa 04 — fechamento das pendências

23/10/2026, Codex. Continuação da implementação do Claude Code, preservando as alterações locais anteriores.

## Ajustes encontrados com toque Web

O menu Bola/Copinhos abria abaixo de Brincar e cortava a segunda opção atrás das abas. Além disso, a pressão
nos botões (`MOUSE_FILTER_PASS`) subia até o fundo do Popover e o fechava antes da seleção. `Popover` agora
abre acima da âncora quando falta espaço abaixo, limita a posição à área do host e fecha por pressão apenas
fora do cartão. Nenhuma regra do crescimento, arte ou formato de save foi alterado.

`gestures_test` ganhou verificações da área inteira do menu e clique pelo viewport em Copinhos, com abertura
da rodada e consumo de exatamente um petisco. As duas regressões falharam antes das respectivas correções:
`build/test_logs/cuidado04/choice_before.log(.err)` e `click_before.log(.err)`; `click_after.log` PASS.

`tools/touch_test.ps1` ganhou `hold` (duração e captura durante a pressão), duração opcional de `tap` e erro
para passo desconhecido. Roteiro reproduzível: `tools/care_gestures_touch_steps.json`; só usa toque, o painel
DEV e leitura do IndexedDB do perfil descartável criado pela ferramenta.

## Testes da etapa

Escopo explícito em `build/cuidado04_scope.txt`: arquivos da 04, seus testes, Popover e ferramenta de toque.
As muitas alterações locais das etapas anteriores não ampliam a seleção automática desta continuação.

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests gestures_test,hud_test -Areas pet,growth -ChangeList build/cuidado04_scope.txt -Jobs 3
```

**28/28 PASS em 233,5 s**, `build/test_logs/r20261023_061236_6b20ef99/results.csv`.
Lista: scripts_check, content_test, texts_test, gestures_test, hud_test, pet_care_test, pet_anchor_test,
brush_taste_test, manual_test, care_ui_test, growth_test, moments_test, growth_meals_test, growth_ui_test,
hud_growth_test, ceremony_test, personality_test, silk_test, growth_visual_test, growth_foods_test, keys_test,
absence_test, station_tray_test, queue_test, products_test, animals_test, animals_chain_test, expansion_test.

Após o último ajuste (pressão dentro do Popover), revalidados os afetados pelo mapa automático:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests gestures_test,hud_test -ChangeList build/cuidado04_popover_scope.txt -Jobs 3
```

**21/21 PASS em 105,8 s**, `build/test_logs/r20261023_061647_2e8686a8/results.csv`.
Lista: scripts_check, content_test, texts_test, gestures_test, hud_test, growth_test, moments_test,
growth_meals_test, growth_ui_test, hud_growth_test, ceremony_test, personality_test, silk_test,
growth_visual_test, growth_foods_test, keys_test, care_ui_test, pet_care_test, pet_anchor_test,
brush_taste_test, manual_test. Nenhum portão, campanha ou suíte inteira executado.

## Falha da Bancada no seletor

Há evidência anterior à 04 da mesma asserção: `build/test_logs/r20261023_010831_033c9283/world_selector_test.log.err`
(rodada inicial da 01, antes de seu fechamento em `r20261023_032629_63ada2a4`). A asserção é
“Bandeja da Bancada abre após a viagem, a seta e o enquadramento”.

Nesta continuação, o teste passou isolado (`build/cuidado04_selector.log`) e no primeiro nível etapa completo
(`build/test_logs/r20261023_060500_d742ac8d/`, 28 PASS em 243,1 s). Reapareceu na rodada adicional que incluía
o seletor junto dos afetados pela primeira correção do Popover (`r20261023_061131_46fd593b`, 7 PASS + 1 FAIL,
46,7 s; o runner encerrou a seleção restante). Essa rodada não conta como verde.

Classificação: falha preexistente e intermitente, sem evidência de origem nos gestos da 04. O seletor não foi
alterado nesta continuação. Sua causa interna permanece sem correção; a pendência fica registrada, como
autorizado pelo Vitor. A seleção final dos afetados da 04 acima não inclui esse teste de navegação.

## Web local e capturas

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_web.ps1 -Channel dev
powershell -ExecutionPolicy Bypass -File tools/serve_local.ps1 -Port 8004
powershell -ExecutionPolicy Bypass -File tools/touch_test.ps1 -Url http://localhost:8004/ -Steps tools/care_gestures_touch_steps.json
```

Export DEV local: `build/cuidado04_export_closed.log`, saída 0 e “Build pronto”. A porta 8000 já estava
ocupada; o servidor desta validação usa 8004. `version.json` original restaurado pelo export.
Capturas nativas 360×780 (`build/screenshots/cuidado04/cups_start_360.png` e `cups_result_360.png`) abertas
e conferidas. Evidência Web em `build/touch_test/` (390×844 CSS, fator de pixels 2).

Roteiro final concluído com saída 0 (`build/cuidado04_touch_final.log`). Capturas `hold_short_ring`,
`hold_long`, `play_choice`, `cups_pick` e `cups_result` conferidas; menu inteiro acima dos cuidados,
anel visível durante o gesto, três copinhos e resultado legível. A rodada errou o copinho e recebeu
“Era aquele! Momento de Esperteza!”, como previsto pela regra.

Comparação dos saves atuais do perfil descartável: `before_hold`, `after_short`, `after_hold`,
`cups_started`, `after_cups`. **9 verificações PASS** em `build/touch_test/validation.json`:
fase Aventureiro; 0,8 s não conta carinho; 3 s conta exatamente um; um momento de Coragem;
um petisco gasto ao iniciar; início ainda sem conclusão; uma rodada concluída pelo toque no copo;
um momento de Esperteza; nenhum segundo consumo ao concluir. Contador `pet`: 0 → 0 → 1;
`hide`: 0 → 0 → 1; Esperteza: 0 → 0 → 1. Sem save antigo ou migração.

## Próxima sessão

Próxima etapa: `ETAPA_05_ANIMADO.md`, em sessão própria “Cuidado — Etapa 05”, mesmo projeto local,
modelo `gpt-6.1-sol`, usando a mensagem do README. A ferramenta `create_thread` não está disponível
nesta sessão (catálogo de ferramentas consultado); não foi criada outra sessão nem executada a 05.
Sem commit, push ou publicação.
