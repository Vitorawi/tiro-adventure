# Etapa 11 — Separar aprender uma rota de ganhar mais vagas

**Estado: concluída (18/10/2026, Claude Code; local, sem commit nem publicação).** Evidência em `build/economy/etapa_11/`; números e cenários em `DECISOES.md`; sistemas em `docs/PROGRESSION.md` ("Economia R1 — etapa 11"). Executar somente esta etapa. Pré-requisito: Etapas 00–10 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção E; 05 snapshots; NatureUi/StationTray; progression nature_sites/nature_resources/activities; tokens de nível.

## Entrega e implementação

1. Aplicar tempos/saídas/XP local por rota da 02. XP local deixa de ser 10 para qualquer busca e passa a depender da atividade escolhida; não confundir XP local do Bosque com atributo Aventura/global. Manter XP de atributo existente salvo ajuste medido posterior.
2. Quatro patamares locais 0/24/120/360, slots 1/2/2/3. Patamar 2 mostra recurso intermediário quando existir; madeira dura/cristal no 3; vaga 3 só no 4. Atualizar tokens `*_slot_3` para nível 4 e introduzir token de nível 4 apenas se a sincronização exigir, sem remover os tokens de recursos do nível 3.
3. Quem já tinha vaga 3/recurso mantém acesso via piso legado de desbloqueio; não reduzir nível exibido abruptamente nem voltar a cobrar tokens gratuitos. Mostrar progresso novo até o próximo patamar sem inventar XP retroativo. Mapa/labels e cadeados devem ler a mesma fonte.
4. Pomar usa produção longa1 h/8 maçãs, sem receber XP de um site inexistente. Coleta de Natureza permanece lote inteiro, pronta no mundo se depósito cheio, sem moedas de produção desde 09.
5. Ajustar descrições dos patamares e rotas. Não criar pedágio por busca, mineração rara obrigatória, recurso novo ou área nova.
6. Antecipar woodcutting para forest_open sem nível 2 e oferecer escolha explícita de rota/duração por material na StationTray/NatureUi. start_gathering pode receber route_id opcional validado contra o material/site/requisitos; chamadas antigas continuam com fallback. Mostrar entrada, saída e tempo da rota selecionada, guardar escolha apenas na sessão. Duas buscas longas de madeira somam24 XP local e alcançam nível 2; não exigir 12 reentradas curtas.

## Verificação obrigatória

Cada rota concede XP certo uma vez; rota cancelada/erro não concede; cobre/desbloqueio 2, madeira dura/cristal 3, vaga3 nível4. Fixture antiga com vaga 3+XP 90 preserva acesso. Bosque/Caverna/Prado medidos com políticas curta e retorno; coletar3 rotas simultâneas não explode capacidade intermediária. Snapshot velho mantém lote antigo.
Comparar duas woodcutting com doze lane: mesmo patamar 2, tempos/saídas próprios, nenhuma seleção silenciosa que troque a preferência. Rota de outro material/site ou bloqueada deve ser rejeitada sem consumir vaga.

## Critérios de conclusão

Nível não sobe igualmente rápido repetindo a menor rota, três vagas não chegam junto de todos os recursos novos. Recursos de história continuam determinísticos; não há dependência da própria vaga para liberar recurso.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_11/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
