# Etapa 23 — Ajustar o conjunto com evidência de sessões

**Estado: concluída com ressalvas por decisão do Vitor (19/10/2026): rodada mínima; as verificações restantes foram movidas para a etapa 24 (ver [RESULTADOS.md](RESULTADOS.md)). Critério da Festa "+2–4 h" segue FALHO e registrado.** Executar somente esta etapa. Pré-requisito: Etapas 00–22 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

04 integral;02tabelas;BASELINE;DECISOES;relatóriosdas08/13/18/22;simulador01.

## Entrega e implementação

1. Executar todos os perfis, seeds e cenários da seção 04 na R1 completa. Separar tempo ativo/calendário, atenção, moedas únicas/recorrentes, reservas, bloqueios, progresso por visita, filas e atividades com o Tiro. Comparar baseline e R1 com horizonte e política iguais.
2. Examinar primeiros 20 minutos, cozinha, depósitos, bancada, animais, banca 2, ateliê e Festa. Reproduzir cada falha em log curto. Distinguir erro do planejador, requisito incorreto e número inadequado antes de mudar dados. Recuperação com zero moeda é invariante, não resultado médio.
3. Aplicar o protocolo: uma família por rodada, até 25% por valor, no máximo três rodadas. Avaliar fontes, custos e quantidades antes de aumentar esperas; evitar visitas inteiras sem progresso. Se a falha for estrutural, registrar causa e proposta concreta. Não criar produtos para ocultá-la nem marcar concluído antes de resolver.
4. Atualizar tabelas 02/07 quando algum número mudar, e matriz/textos se afetados. DECISOES registra antes, depois, motivo e log. Reexecutar cenários afetados e amostra fixa dos demais. Após o último ajuste de regra, conferir novamente o estado final com a suíte pertinente.
5. Criar `RESULTADOS.md` nesta pasta: tabelas por perfil, seeds, horizontes, limitações e gráficos de fontes/consumos/marcos. Incluir sessão humana se efetivamente feita; simulação não mede diversão sozinha. Preparar perguntas concretas para o Vitor testar no celular.
6. Separar duração das obras, financiamento, pré-requisitos e contratos para a banca 3. Jardim e Piquenique permitem escolher a ordem, mas ambos são necessários à Festa. Medir quando a primeira mudança visual do Banco ocorre após `atelier_open`; não chamar espera comercial de interação com o Tiro.

## Verificação obrigatória

Exigir as invariantes da seção 04, relatório de progresso por visita, margens com intermediários e ausência de bloqueio permanente por estoque, retorno ou sorte. Testar perfil leve com retorno de 24 h e perfil ativo sem tratá-lo como padrão. Repetir seeds de controle depois dos ajustes. A política do simulador não pode ser alterada só para produzir PASS.

## Critérios de conclusão

RESULTADOS distingue o que passou, falhou e continua hipótese. Dados e documentos têm os mesmos valores finais. Se o critério não foi atingido, manter etapa em andamento com causa e próximo teste. Não garantir engajamento sem experiência real.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_23/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
