# Etapa 05 — Tiro animado

Concluída em 23/10/2026 pelo Codex, somente local. A 04 estava fechada no README, ROADMAP e
VALIDACAO_04; suas alterações e os demais trabalhos locais foram preservados.

## Implementação

- Estado calculado: acordado e nenhuma necessidade pedindo. Configuração em `mood.animated`.
- Colheita: 20% de +1, sorteio estável pela semente do Tiro, canteiro e timestamp do plantio normalizado
  em milissegundos. O extra só entra se couber junto do lote; aviso “O Tiro ajudou!” e CollectFx da sala.
- Passeio: condição e quantidade extra congeladas no snapshot antes do custo de energia.
- Faro: um extra global por período local, só em mundo aberto, após escavar; mantém um pendente por mundo
  e não adia o horário do normal. Limite e marca do extra persistidos em `FindState`.
- HUD: selo Animado, toque no avatar mostra ajuda em uma linha. Tela do Tiro: brilho discreto,
  estático com Menos animação. A conferência visual encontrou o selo sem largura (vertical);
  largura e ausência de quebra corrigidas e cobertas pelo teste.
- Save 16: reset pelo ramo existente. Nenhuma migração nem teste de save antigo. Simulador intacto.

## Testes

Escopo explícito `build/cuidado05_scope.txt`: nove arquivos desta etapa. As alterações locais anteriores
não ampliam automaticamente a seleção. Áreas amplas declaradas como pedido na etapa.

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests mood_test,saves_test -Areas farm,walks,finds,shell -ChangeList build/cuidado05_scope.txt -Jobs 3 -KeepGoing
```

**28/28 PASS em 140,9 s**, `build/test_logs/r20261023_064445_1335ef9c/results.csv`.
Lista: scripts_check, content_test, texts_test, mood_test, saves_test, farm_test, garden_test, tray_test,
flavors_test, farm_market_label_test, walks_test, park_test, walk_return_test, walk_return_ui_test,
finds_test, treasure_test, hud_test, festa_test, welcome_test, effects_layer_test, ready_badges_test,
care_ui_test, absence_test, pet_care_test, pet_anchor_test, brush_taste_test, manual_test, gestures_test.

Após corrigir a largura do selo e adicionar asserções de linha única/mundo fechado:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Tests mood_test -ChangeList build/cuidado05_hud_scope.txt -Jobs 3
```

**10/10 PASS em 39,7 s**, `build/test_logs/r20261023_064721_0f44a11b/results.csv`.
Lista: scripts_check, content_test, texts_test, mood_test, hud_test, festa_test, welcome_test,
effects_layer_test, ready_badges_test, care_ui_test.

`mood_test` usa relógio injetável e save atual descartável: quatro limiares de necessidades, sono,
semente vencedora, recarga do mesmo plantio, lote normal sem espaço para o extra, saída do passeio
antes do custo, snapshot recarregado e retorno depois de perder o estado, ficar animado só após sair,
extra do faro persistido/limitado por período, manutenção do prazo normal, mundo fechado e HUD.
Durante o desenvolvimento, o teste encontrou instabilidade da semente ao serializar inteiro como float;
timestamp normalizado corrigiu o produto. As primeiras fixtures também precisaram dos requisitos reais
da Nina e do mundo Sítio. As rodadas finais acima estão verdes.

## Capturas

Execução gráfica de `mood_test.gd` a 360×780 com `-- --screenshots`, SaveManager removido e
`TIRO_TEST_TAG=cuidado05_shots_final`. PASS e stderr vazio em `build/cuidado05_shots_final.log(.err)`.
Arquivos abertos/conferidos em `build/screenshots/cuidado05/`: `avatar_help_360.png`,
`animated_360.png` e `animated_reduced_360.png`. Selo horizontal, ajuda legível e brilho discreto;
Menos animação mantém os pontos de brilho estáticos.

Nenhum portão, campanha ou suíte inteira. Sem commit, push ou publicação. Etapa 06 não executada
e sessão seguinte não aberta, conforme instrução específica do Vitor.
