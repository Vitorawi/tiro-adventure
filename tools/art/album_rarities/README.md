# Produção das raridades do álbum

Pedido do Vitor: todas as fotos, em lotes de cinco cenas. Atualização de 06/11/2026: continuar a produção sem mandar todas as imagens; informar apenas os lotes e totais concluídos. A revisão visual técnica continua obrigatória. Direção: Comum simples → Brilhante com volume → Rara com traço/luz refinados → Holográfica com pintura e texturas delicadas. São **quatro arquivos por foto: Comum + três variações**, 54 fotos / 216 arquivos. Sem instalação automática no jogo.

## Arquivos de controle

- `catalog.json`: catálogo mestre das 54 fotos, seções, fase artística, cenário, eventos/condições do jogo, bases, quatro arquivos, prompts, hashes, estados e lotes.
- `photos/<section>/<photo_id>/photo.json`: ficha independente da foto.
- `photos/<section>/<photo_id>/{common,shiny,rare,holographic}.png`: resultados canônicos desta direção.
- `photos/<section>/<photo_id>/prompts/<rarity>.txt`: prompt exato persistido antes de gerar.
- `gallery.html`: comparação visual das quatro raridades, por foto, com estado e lote. Abre localmente; fotos pendentes aparecem sem imagem.
- `integration_target` é um **destino proposto** para instalação futura. Arquivo do jogo e recurso real da base continuam em `base_image` / `original_photo_definition.illustration`. Nenhuma associação do jogo foi trocada por este processo.

**Produção concluída em 06/11/2026:** 54/54 fotos, 216/216 imagens com revisão visual técnica; zero pendentes ou em geração. `album_rarity_pipeline.py check` PASS. As seis séries iniciais (24 imagens) foram preservadas e as 48 cenas restantes (192 imagens) concluídas em dez lotes. Os lotes 002–010 foram encerrados com `complete`, sem marcar as imagens como mostradas ao Vitor. Prompts e fontes individuais estão preservados no catálogo e nas fichas. Não gerar novamente séries prontas; correções futuras devem preservar o histórico.

## Retomar em outra sessão

1. Leia este arquivo e execute `status`, `check` e `next` com o script abaixo. **Não reinicialize o catálogo nem gere de novo o que existe.** `init` é idempotente e preserva progresso.
2. `next` retoma primeiro o lote em andamento; só reserva cinco cenas novas se não houver lote ativo. Leia as imagens base e as referências de estilo usando `view_image` antes de gerar. Confira fase, orelhas, pelagem, tamanho, ação e objetos indispensáveis na própria base. O texto de cena é complementar; a base prevalece.
3. Revise os prompts antes de começar, se necessário para preservar uma característica específica. Use uma chamada built-in `image_gen` por raridade, com a base como imagem 1 e `style_reference` como imagem 2. Não usar CLI/API pagos como substituto silencioso.
4. Execute `prepare` **uma única vez antes de enviar o lote**: grava as tentativas como `generating` antes das chamadas. Só envie jobs com `ready_to_submit: true` no retorno dessa execução. Estados já `generating` retornam `ready_to_submit: false` e são de recuperação, não autorização para repetir a geração. Nunca reenviar automaticamente jobs sem essa marca.
5. Assim que CADA imagem retornar, execute `accept --photo ID --tier RARIDADE --source CAMINHO`. Isso copia o PNG para a pasta definitiva e grava fonte, dimensões, hash e conclusão. **Serializar todas as mutações do catálogo**, mesmo quando as gerações forem paralelas; o script não oferece bloqueio para processos escritores concorrentes.
6. Inspecione os resultados com `view_image`: identidade/fase/ação corretas, anatomia, presença do Tiro, evolução de traço, distinção Rara/Holográfica. Execute `review` por arquivo conferido. `reviewed` significa revisão visual técnica; a avaliação do Vitor acontece na conversa.
7. Rode `check`; informe apenas o lote e os totais concluídos, conforme o pedido mais recente do Vitor. Execute `complete --batch batch_NNN` após a revisão técnica, sem marcar imagens como mostradas ao usuário. `shown` fica reservado a uma comparação efetivamente entregue. Atualize `docs/ROADMAP.md` com o lote e o que resta. Siga em lotes de cinco; correções do Vitor prevalecem.

## Recuperação se acabar o limite ou houver interrupção

- `pending`: ainda não enviado; pode gerar no próximo lote.
- `generating`: chamada pode ter sido enviada. **Não repetir automaticamente**. Procure primeiro o retorno da ferramenta na conversa e o arquivo em `.codex/generated_images/<thread>/`; inspecione para associar com segurança, então use `accept`. Se não houver resultado, registre a tentativa/erro na ficha antes de decidir reenviar. Não presumir cobrança nem ausência de cobrança.
- `generated`: arquivo e hash registrados, falta conferir visualmente; não gerar novamente.
- `reviewed`: arquivo já conferido; pode ser mostrado ao usuário.
- Uma interrupção durante a atualização do mestre pode deixar `photo.json` mais recente: recupere a ficha individual e o PNG/hash, preservando as tentativas. Escrita JSON usa arquivo temporário + troca atômica; resultados não dependem de variáveis da conversa.
- Os arquivos originais retornados pelo gerador e todos os testes anteriores permanecem preservados. Correções devem arquivar a tentativa anterior, atualizar a ficha e conservar histórico; nunca substituir silenciosamente.

## Comandos (PowerShell, na raiz do projeto)

O Python disponível nesta máquina é `C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

```powershell
& C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe tools/album_rarity_pipeline.py status
# Troque status por check, next ou prepare.
# Operações individuais:
# ... start --photo h_first_night --tier common
# ... accept --photo h_first_night --tier common --source 'C:/.../exec-....png'
# ... review --photo h_first_night --tier common
# ... shown --batch batch_001
```

O script não gera imagens, não consome créditos, não instala no jogo, não altera save ou dados e não publica. Ele organiza os resultados das chamadas autorizadas pelo Vitor. `check` valida IDs contra o catálogo atual do jogo, quatro raridades, bases/prompts, formato PNG quadrado ≥1024, SHA256 e ausência de arquivos duplicados.
