# Etapa 14 — Ajustar investimentos e ensinar cadeias de ovos, leite e queijo

**Estado: concluída (18/10/2026, Claude Code; local, sem commit nem publicação).** Evidência em `build/economy/etapa_14/`; registro em `DECISOES.md`; sistemas em `docs/PROGRESSION.md` ("Economia R1 — etapa 14"). Executar somente esta etapa. Pré-requisito: Etapas 00–13 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção F (exceto banca 2/3); 03 seção E; 07 farm_breakfast; config animals, upgrades e receitas.

## Entrega e implementação

1. Aplicar custos/materiais de farm, workbench, chicken_coop, cow_barn, mill, dairy, orchard, greenhouse, atelier da 02. Preço da banca500 pode ser aplicado aqui com os demais investimentos, mas níveis2/3 e condições de contratos só15. Atualizar uma fonte de dados, não preços copiados na UI.
2. Manter primeiro animal presente conforme regra atual; preços dos extras galinhas120/150/180, vacas220/280/340 e variedades conforme02. Todas as variedades continuam mesmo rendimento; preço estético não vira produção superior escondida. Índices/IDs de animais existentes permanecem.
3. Revisar linha Bloblo80–140: galinheiro, ovos, curral, leite, moinho/farinha, queijaria/queijos, café. main_9_flour exige owned:mill +produce:flour2 histórico, sem fresh. Criar bloblo_breakfast140 com stat order:farm_breakfast1, prêmio15. Pedido já existe: preservar egg2+flour2+cheese1,95 moedas, recarga600.
4. Preservar milho4/trigo6 oferecidos pelos tutoriais para primeira alimentação, mas não repetíveis. A ração também tem origem renovável desbloqueada ao comprar abrigo. Requisitos da planta e da receita não podem depender de já colher o produto do animal.
5. Comparar gasto com capacidade produtiva e retorno. Reserva de alimento concorre com venda; jogador consegue recompor semente grátis e produzir sem nova taxa por animal. Estações de processamento não desaparecem em Ver tudo ou mapa.

## Verificação obrigatória

Construir os cinco elos por ações reais, comprar animal antes/durante/depois de um lote, alimentar os atuais sem incluir o recém-comprado no snapshot; receber ovos2/leite2 e farinha2 corretamente. Completar café usando pedido existente. Perfil recuperação com compra de conforto anterior precisa financiar próximo elo sem bônus dev.

## Critérios de conclusão

Investimentos criam escolhas graduais e ensino de cadeia, não exigem grind de materiais aleatórios. A compra mais cara não devolve automaticamente seu custo via missão. Nenhum pedido duplicado farm_breakfast.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_14/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
