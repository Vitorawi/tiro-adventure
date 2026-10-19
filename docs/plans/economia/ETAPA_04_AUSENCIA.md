# Etapa 04 — Tornar a volta acolhedora sem apagar cuidados

**Estado: concluída em 17/10/2026 (Claude Code).** Executar somente esta etapa. Pré-requisito: Etapas 00–03 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção G; 05 seção E; 04 experimento de ausência; DogState, SaveManager, eventos de foco e visitantes.

## Entrega e implementação

1. Aplicar perda offline a 50% das taxas normais, no máximo 8 h por ausência contínua, com pisos 25 fome/35 alegria/25 energia/30 higiene. Piso protege contra queda adicional, não cura barra que já estava abaixo dele; usar fórmula exata da 02. Online preserva taxas atuais.
2. Sono offline recupera energia 40/h até 100; não também subtrair energia acordado no mesmo intervalo. Processar retorno do passeio e seus efeitos no timestamp do fim da viagem e continuar a ausência restante. Evitar resetar proteção a cada heartbeat/autosave.
3. Centralizar fronteiras online/offline, background/foreground e reload. Guardar timestamps/intervalo necessário para idempotência; relógio regressivo não gera ganho de tempo e mudança de slot não fabrica visita/presente. Não usar períodos de simulação como ausência nova a cada ação.
4. Preservar cuidados disponíveis, efeitos dos alimentos e taxas online. Mensagens de retorno neutras e acolhedoras; um cartão agrupado, sem multas ou modal de quatro necessidades. Registrar proteção em manual com texto curto, sem expor fórmula no fluxo normal.

## Verificação obrigatória

Partindo de 100 acordado:8 h e 24 h devem resultar 68/80/76/88. Fome 30→25; fome 10→10. Repetir reload não reduz nem aumenta novamente; sono24 h termina com energia 100 e demais barras protegidas. Testar1 h/8 h/24 h/72 h, passeio finalizando após 30 min, relógio negativo, foco repetido, duas abas quando arquitetura suportar e troca de slot.

## Critérios de conclusão

Matriz de ausência passa no relógio real/injetado; brincar/comer/banho/sono continuam úteis online; proteção não vira mecanismo de cura grátis por recarregar. Não alegar teste em aparelho físico se só rodou viewport.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_04/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
