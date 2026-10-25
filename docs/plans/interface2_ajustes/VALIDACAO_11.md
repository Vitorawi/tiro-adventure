# Validação — ajustes, etapa 11

Pré-checagem: etapa 10 [x], HEAD f49d6af. Exclusões preexistentes de python_libs fora do escopo.

## Inventário de `.disabled =` antes da conversão

| Arquivo / ação | Destino |
|---|---|
| progression_ui: rotas, Passear, duas compras pet shop, _action | lock_hint com motivo real e ajuda |
| sheet_builder: Pedir à vovó | some durante recarga; FoodHelpTimer já explica |
| sheet_builder: receita, comprar animal, comprar terreno | lock_hint com motivo real e ajuda |
| market_ui: DeliverOrder | lock_hint; item ausente com ícone |
| settings_panel: Play ativo / Default atual | chip Jogando ✓ / É o padrão |
| friend_ui: GiveTreat / Dar petisco | lock_hint com ícone do petisco |
| game_manual: faro / _location | lock_hint com destino da consulta |
| find_ui: Pegar conjunto | lock_hint com motivo e ajuda |
| nature_ui: Material | lock_hint com motivo e ícone |
| station_tray: Material | lock_hint com motivo e ícone |
| trick_ui: Mostrar / Treinar | lock_hint; ação futura some quando já existe próximo treino |
| walk_result: Vestir | lock_hint com motivo real |
| intro: próximo durante transição | some; não é controle disponível durante transição |
| trick_training: três atribuições | lista branca: controle do minijogo |
| dev_panel: aba atual | lista branca: seleção DEV |
| pet_care_tray: dormir durante passeio | lista branca: controle da roleta |
| market_ui: paginação | lista branca: controle de página sem texto |
| ui_kit: stepper | lista branca: limite de quantidade |

São **30 atribuições** no início: **23 removidas/conversões** e sete mantidas em controles da lista branca.
Linhas abaixo são as do commit f49d6af (o número muda com a conversão).

| Local original | Classificação aplicada |
|---|---|
| progression_ui:264 (rotas) | lock_hint de activity_error; ajuda route |
| progression_ui:446 (Passear) | Locked_StartWalk_<id>; walk_error; ajuda walk |
| progression_ui:641 (roupa) | action_or_hint; equip_error/buy_cosmetic_error |
| progression_ui:658 (produto) | action_or_hint; buy_shop_item_error |
| progression_ui:822 (_action) | lock_hint no lugar do botão + motivo duplicado |
| sheet_builder:66 (ajuda) | botão some; FoodHelpTimer permanece |
| sheet_builder:498 (receita) | lock_hint de cook_error com ingrediente ausente |
| sheet_builder:551 (animal) | Locked_Buy_<id>; buy_animal_error |
| sheet_builder:700 (terreno) | Locked_BuyPlot; mesmas condições/textos de buy_plot |
| market_ui:269 (entregar) | Locked_DeliverOrder; order_error e ícone do primeiro ingrediente ausente |
| settings_panel:99 (Jogando) | Playing_<slot> em chip have, sem ação Play |
| settings_panel:106 (padrão) | DefaultState_<slot> em chip have |
| friend_ui:54 (bandeja) | Locked_GiveTreat; give_friend_error; ícone do petisco |
| friend_ui:120 (cartão) | ação some; lock_hint existente recebe ícone do petisco |
| game_manual:208 (faro) | Locked_FindGo_<mundo>; world_error |
| game_manual:269 (destino) | Locked_ManualGo_<mundo>_<lugar>; world_error/place_error |
| find_ui:55 (conjunto) | Locked_ClaimFind_<id>; find_set_error |
| nature_ui:223 (material) | Locked_Material_<item>; next_gathering_error |
| station_tray:406 (material) | Locked_Material_<item>; next_gathering_error |
| trick_ui:28 (Mostrar) | ação some; Locked_Trick_<id> com perform_trick_error |
| trick_ui:31 (Treinar) | ação some se futura; cadeado com learn_trick_error se bloqueada |
| walk_result:99 (Vestir) | Locked_Equip_<id>; equip_error |
| intro:148 (próximo) | hide no encerramento, imediatamente antes de queue_free |
| trick_training:71 | lista branca TrickAttempt: validação do minijogo |
| trick_training:100 | lista branca TrickAttempt: tentativa em andamento |
| trick_training:113 | lista branca TrickAttempt: libera a tentativa |
| dev_panel:40 | lista branca DevTab_resources/progress/growth/time/pace/save: página atual |
| pet_care_tray:260 | lista branca SleepButton: roleta durante passeio |
| market_ui:170 | lista branca PreviousPage/NextPage: limites da página, sem texto |
| ui_kit:778 | lista branca Minus/Plus: limites do stepper |

## Provas e pronto quando

- ✓ **12:** inventário completo acima; sete atribuições restantes apenas nos controles autorizados.
  `UiKit.action_or_hint` libera o botão bloqueado antes de retornar o cadeado; a ação proibida não fica
  conectada em nó invisível. `Locked_*` conserva o motivo em meta `reason`. Cenas de encomendas,
  banca, truques e Configurações mostram a substituição; compra da geladeira continua nítida.
- ✓ **20:** um `ProjectCount_<item>` M/N por item, missing enquanto falta e have com ✓ ao completar.
  ProjectMissing usa list_row + row_chevron, sem vermelho na frase. ProjectSteps é o único medidor
  de fase; ProjectBar e _title_row removidos. DeliverProject continua o único primário de entrega.
  Encomendas/Encontro usam item_chip semântico; have agora inclui HaveCheck vetorial no tap_chip.
- ✓ Tabela e ausência de ação cinza fora da lista branca.
- ✓ Um chip por item, origem calma e um indicador de fase nas obras.
- ✓ Regra nova em ui_style_test, com lista branca por nome, superfícies reais e controles negativos
  em Sheet/ActionTray/ModalCard/RewardSheet. Mantidas as garantias de hierarquia, opacidade,
  primeiro produto selecionado, informação no cabeçalho e no máximo um primário.
- ✓ Testes verdes: 17/17 PASS em 319 s, lista fechada + rápidos obrigatórios.

## Capturas e comparação visual

23 PNGs por pasta (18 obrigatórios mais cinco estados intermediários reaproveitados do percurso das
obras): `build/screenshots/aj_11_antes`, `_antes_390`, `_antes_412`, `_depois`, `_depois_390`,
`_depois_412`. Antes gerado antes de qualquer alteração no jogo. Todos abertos em 18 pranchas
`aj_11_*_prancha_1|2|3.png`, com banco/encomendas/Configurações/Jardim abertos individualmente.

Comparação com a evidência b14b/b14c, i2_09_settings/tricks, b16c–f/h/k/m e a05: saem Entregar/
Mostrar/Jogando/É o padrão cinza; ficam motivo/consulta ou estado. Sai a barra azul e a linha dupla
faltam/tem. O chip de progresso entra no tile, com altura 104 e sem legenda vazia; a primeira
captura intermediária cortou os chips e foi corrigida, regenerando as três pastas finais.
O texto longo da origem pode quebrar; fonte e conteúdo preservados. Nome da encomenda continua
com reticências na grade e completo no detalhe. As cores missing ficam só na quantidade faltante.
Nenhum protótipo novo foi pedido nesta etapa: referência é a evidência real + Bíblia §F.
Falas/poses e objetos de fundo variam com a animação da fixture. Capturas da geladeira e álbum de
amigos mantêm a composição anterior porque já não mostravam botão cinza nesses estados.

As primeiras tentativas restritas acusaram acesso ao user:// e certificados. Os três antes foram
regenerados com acesso normal antes de mexer no jogo; seis execuções finais com acesso normal.

## Testes alterados e decisões

- market: entrega completa continua pelo botão real e conta/consome uma vez. Bloqueada passa a
  conferir motivo exato de order_error e retângulo inteiro do cadeado; mesma garantia sem rolagem,
  inclusive 360×640. Nomes de 18 e reticências preservados.
- saves: Playing_4 com texto Jogando e ausência da ação Play_4.
- manual: todos os cadeados com motivo e LockIcon; nenhuma ação Bloqueado navegável.
- nature: motivo/LockIcon e ausência da ação Material; consulta do cobre não altera fila/save.
- bench: acrescentadas ausência de ProjectBar, um chip por item e origem em linha com chev.
- ui_style: motivo real para truque/passeio, botão proibido removido, ícone do ingrediente faltante,
  check do ingrediente completo; nenhuma garantia anterior removida.
- pet_care: duas asserções de .disabled ajustadas para botão ausente + timer, porque FoodHelpButton
  agora some na recarga. Teste fora da lista fechada: **não executado nesta etapa**, preservando a
  restrição do roteiro; restante da fixture e teste de liberação automática continuam iguais.
- walk_return_ui: asserção de Passear desabilitado adaptada para ausência da ação + cadeado com
  motivo exato de walk_error enquanto a bagagem está pendente. Também fora da lista e não executado;
  a consulta de bagagem, coleta e liberação posterior permanecem como estavam.

Sem alteração de dados, regras, save, arte ou fala. buy_plot não tem método de consulta de erro;
a apresentação reutiliza as condições que já desabilitavam Comprar e os textos exatos da ação,
sem chamar a compra para consultar. Nenhum dado novo. Nomes explícitos em TrickAttempt/DevTab_*
servem à lista branca. Nenhuma variação de tema nova. AGENTS/CLAUDE atualizados juntos.

## Pendências para 12

Nenhuma de implementação da 11. Continuam as herdadas: corpo rolável da bandeja do Galinheiro,
update_finds/update_wishes no tique de 1 s e Tudo junto da borda direita. O portão da 12 deve usar
os nomes novos dos bloqueios e incluir a fixture adaptada de pet_care. Etapa 12 não executada.


## Resultados finais

DryRun confirmou 17 testes (14 pedidos + scripts_check/content/texts). **17/17 PASS em 319 s**.
Log: `build/test_logs/r20261025_165928_1ccf3f74/results.csv`. Cada log tem seu rótulo PASS;
nenhum SCRIPT ERROR/Parse Error na rodada final. Exceção de duração prevista no §6 da etapa.

| Teste | Resultado | Segundos |
|---|---|---|
| scripts_check | PASS | 11.8 |
| content_test | PASS | 7.5 |
| texts_test | PASS | 2.9 |
| ui_style_test | PASS | 10.3 |
| market_test | PASS | 28.2 |
| customers_test | PASS | 8.3 |
| saves_test | PASS | 11.2 |
| tricks_test | PASS | 12.4 |
| walks_test | PASS | 12.3 |
| friends_test | PASS | 8.3 |
| finds_test | PASS | 8.4 |
| manual_test | PASS | 22 |
| bench_test | PASS | 43.2 |
| garden_picnic_test | PASS | 42.3 |
| festival_test | PASS | 29.5 |
| petshop_test | PASS | 7 |
| nature_test | PASS | 50.9 |

Primeira rodada r20261025_165050_465520cd interrompida após erro de compilação: row_chevron exige
Callable (corrigido). Rodada intermediária r20261025_165305_23dd96f8: 17/17 PASS, 394,7 s.
A rodada final inclui todos os novos casos, o check have e a geometria final dos tiles.
Nenhum portão, campanha, simulador, export ou teste fora da lista foi executado.

Checklist visual das telas tocadas: ✓ Fredoka/Nunito e Palette; ✓ controles vetoriais;
✓ ícones em superfícies; ✓ missing apenas na quantidade e have com check; ✓ um primário;
✓ nomes de 18 preservados; ✓ alvos de consulta 44; ✓ origens longas quebram sem reduzir fonte;
✓ sem novos efeitos/movimentos ou dependência de animação; ✓ chips inteiros nas três resoluções.
Falas e regras preservadas. Sem push/publicação. Commit local da etapa, exclusões de python_libs fora.