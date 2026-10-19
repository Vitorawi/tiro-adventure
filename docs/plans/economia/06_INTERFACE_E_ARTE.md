# Interface, arte e leitura da progressão

## Aproveitar a interface existente

Preservar abas, câmera, bandejas, tipografia, Palette/Motion e um botão verde por painel. Seguir `docs/plans/interface/01_REGRAS_E_ESTILO.md`. Não refazer o layout neste plano. Informação aparece onde decide uma ação; o jogo não expõe termos como migração, recibo, ledger, simulação ou capacidade projetada.

## Depósitos (02,05–08,18)

Cada filtro mostra nome, ícone e `usado / total`. Antes da construção, nomes Cesto da horta (silo), Despensa (geladeira), Cantinho dos materiais (armazém) e Sacola de passeio (baú). Depois, nomes dos edifícios. São o mesmo depósito, não inventários adicionais. Categoria sem item nem desbloqueio permanece oculta, embora o limite exista na regra. Recompensa antecipada revela sua categoria, sem liberar o prédio.

No detalhe, apresentar capacidade atual → futura e materiais/custo. Mostrar falta concreta e origem tocável. Aviso leve a 80% ao abrir o depósito, nunca modal em cada coleta. Cheio: “O silo está cheio. Guarde espaço para 4 cenouras.” O número é a falta real de espaço, não sempre o tamanho do lote. Ações úteis: abrir depósito, vender excedentes já vendáveis ou ampliar quando possível. Não descartar, vender nem selecionar ingredientes de missão automaticamente. Preservar quantidade e filtros ao voltar.

Presentes automáticos pendentes: uma seção recolhida “Presentes para guardar”, com quantidade pendente e itens; mostrar apenas quando houver. “Guardar” recolhe a quantidade que cabe de cada item e mantém o restante no recibo, sem perda. A operação registra entrada e redução do saldo pendente atomicamente. Nunca pague moedas/XP novamente. Recebimento parcial é próprio de presentes e bagagem; colheita/lote continuam indivisíveis. A etapa 02 entrega a seção junto do estado, antes dos depósitos finitos.

## Volta e ausência (03–04)

Ao terminar o tempo, Tiro reaparece e pode receber cuidados mesmo com baú cheio. Um resultado de passeio por saída, imediatamente se visível e seguro ou na fila de modais ao voltar. Mostrar o que já entrou e “Falta guardar” para os itens restantes; CTA “Guardar” ou “Ver baú”. Novo passeio explica “Guarde os achados da última volta”. Abrir novamente resultado não refaz sorteio, prêmios, postal ou contadores. A tela do Tiro só mostra AwayView durante viagem real.

Ao voltar depois de longa ausência, o cartão existente resume produção e presentes. Não criar tela de culpa, “você abandonou o Tiro” ou sequência de quatro telas de reparo. Usar o mesmo gerenciador de modais; retorno de passeio não se sobrepõe ao presente diário. Preferências Menos animação e vibração continuam respeitadas.

## Produção e clientes (12,15,18)

`Preparar N`: seletor de quantidade junto da receita, máximo calculado por ingredientes e vagas. Mostrar `N lotes · total de ingredientes · último pronto em...`. Se uma vaga já estiver ocupada, o tempo inclui essa fila. Confirmar é uma única ação; N bolinhas representam N trabalhos. Não usar o seletor para alimentar animais, que têm regra própria. Menu compacto deve permitir receita e quantidade sem rolagem horizontal escondida.

Encomendas continuam 2 × 2 e contratos 2 por página. Acrescentar rosto/nome do cliente e selo simples de confiança no detalhe; não adicionar aba global. Vínculo do cachorro continua com corações; confiança comercial usa selo/estrela, nunca o mesmo coração. Contrato mostra pagamento e insumos tocáveis. Sem contador de urgência fictício ou obrigação de aceitar pedido para depois perder recompensa.

Maestria: medidor discreto no painel da estação, não mais uma barra permanente no HUD. Explicar que reconhece experiência; não prometer produção mais rápida. Novas vagas continuam em `SlotDot`, com motivo do cadeado. Totais de estoque e filas nunca podem parecer infinitos.

## Projetos (19–22)

Usar lugares existentes nos mundos: Banco e Piquenique na Praça; Jardim e Festa na Vila. Preferir um acesso “Nossa praça” e um “Nossa vila” com lista de projetos, para manter máximo de quatro lugares visíveis por mundo. Esses acessos podem agrupar serviços existentes compatíveis; não retirar acesso à Costura, treino, passeio, venda, encomendas ou banca. `go` leva ao projeto específico, não à lista sem foco.

Cada projeto mostra: cena/ilustração, motivo em fala curta do personagem, etapa atual, itens entregues/necessários e próximo resultado. Seleção de um material abre quantidade, `Entregar` é o único primário. Botão “Entregar o que tenho” só no detalhe selecionado, com quantidade explícita; não consumir materiais de outros projetos. Contribuições não expiram e não se desfazem; dizer isso antes da primeira entrega. A entrada em moedas aparece como “Começar por N moedas” antes de cobrá-la. Fases seguintes não têm taxa escondida.

Resultado permanente e tocável: banco para sentar/brincar perto, jardim para cheirar, toalha/cesta do encontro, enfeites da festa. O cachorro continua autônomo; tocar convida uma reação usando `DogWorld.react_at`, sem controle direto de caminhada. Se estiver dormindo/passeando, obra conclui e celebra sem chamar o cachorro; interação fica disponível na volta. Não exigir presença de amigo por janela para concluir ou usar.

## Arte e composição

Etapas 17/20/21/22 geram respectivamente ícones dos três produtos, banco, jardim/piquenique e enfeites/lembrança da festa. Pixel art coerente com os assets existentes; usar pipeline PixelLab se disponível, respeitar escala, perspectiva e transparência. É permitido combinar assets já licenciados do repositório quando o resultado for legível. Sem depender de arte externa para testes do estado, mas não marcar entrega visual concluída com quadrado/placeholder.

Não inventar coordenadas neste plano: o agente deve medir a cena atual, escolher espaço livre dentro de cada `room.json`, registrar posição/footprint/ponto de uso em sua entrega e verificar caminho/toque. Não reordenar móveis existentes nem cobrir canteiros/portões para encaixar. Isso é uma decisão de composição local, não autorização para novo mapa. Adicionar obstáculos somente se o sprite exigir; manter acesso pelo caminho existente.

## Régua visual e toque

Usar 360 × 780, 390 × 844 e 430 × 932. Abrir os PNGs produzidos; gerar captura não é inspeção. Acrescentar telas novas ao `ui_tour.gd`. Conferir: maior quantidade/nome, depósito no limite e acima do limite legado, cesta pendente, maior fila, cadeado, material faltante, projeto parcial/concluído, lote de modais, Menos animação, teclado quando aplicável e painel arrastado. Alvos ≥44 px; ícones não cobrem quantidades; nenhuma ação exige hover. Registrar que testes de toque no viewport não equivalem a teste em iPhone físico.
