# Tiro bebê Brilhante — lote 01, três animações

**Fonte histórica:** estes são os desenhos brutos do teste anterior. O registro
somente por contorno foi substituído por `../tiro_puppy_landmarks_v4/` antes de
instalar os três clipes no jogo. A conclusão "só experimento local" abaixo
descreve esta primeira versão, não os PNGs corrigidos instalados posteriormente.
GIFs, quadros e prévias são derivados locais: executar `prepare.py` para recriá-los.

Pedido do Vitor em 07/11/2026: fazer só três primeiro, usando o visual do teste
`tiro_idle_shiny_v1`. Geradas com image_gen a partir dos sprites originais e da
folha Brilhante já mostrada/aprovada como referência visual.

| Animação | Quadros | FPS original | Ciclo | Comparação | Prompt |
|---|---:|---:|---:|---|---|
| Inclinar a cabeça | 9 | 7 | 1,286 s | [GIF](head_tilt/comparison.gif) | [Prompt](head_tilt/prompt.txt) |
| Coçar | 9 | 8 | 1,125 s | [GIF](scratch/comparison.gif) | [Prompt](scratch/prompt.txt) |
| Bocejar | 9 | 6 | 1,500 s | [GIF](yawn/comparison.gif) | [Prompt](yawn/prompt.txt) |

[Abrir as três prévias](index.html). Cada sequência tem seu `preview.html`
autocontido, com comparação sincronizada, pausa, seleção de quadro e meia velocidade.
O GIF arredonda os tempos para centésimos; a prévia HTML usa o FPS original.

Cada pasta guarda `source_manifest.json` (hashes e limites dos originais),
`source_sheet.png` (referência original 3×3), `generated_sheet.png` (geração bruta),
`registered_sheet.png` e `frames_3x/` (extração/alinhamento no canvas original a 3×),
`validation.json`, GIF e captura. `prepare.py` reproduz o preparo com Pillow.

## Conferência

- 27/27 hashes originais intactos; nove quadros não vazios por clipe.
- Contagem, ordem, FPS e posições dos limites de cada quadro preservados no registro.
- Transparência e registro conferidos; não há corte individual do enquadramento na reprodução.
- Prévia Chrome: imagens, quadros 0/4/8, play/pausa, reprodução e seleção das três animações PASS; sem erro JavaScript.
- Folhas e comparações estáticas conferidas: inclinação da cabeça, patinha junto ao rosto e cauda na coçada; progressão da boca aberta/fechada e olhos fechados no fim do bocejo.

É um redesenho generativo: detalhes internos de rosto/pelo e anatomia podem variar.
O registro mantém enquadramento/apoio/ritmo, mas não garante deformação interna
idêntica ao sprite original. A continuidade visual precisa da avaliação do Vitor.

**Só experimento local.** Não grava em `game/`, não altera regras/save, não instala
as animações e não faz export/publicação. As demais animações não foram iniciadas.
