# Teste do Tiro bebê — idle Brilhante

Teste visual isolado pedido pelo Vitor em 07/11/2026. Fonte: `tiro_pet_puppy/idle_breathe`,
os nove quadros originais em ordem, 6 fps, ciclo de 1,5 s. Sem instalação no jogo.

- `preview.html`: comparação animada sincronizada, pausa, seletor de quadro e meia velocidade; autocontida, abre sem servidor.
- `comparison.gif`: comparação lado a lado animada; duração total de 1,5 s (GIF alterna 170/160/170 ms por limitação do formato).
- `source_sheet.png`: nove quadros originais a 2× para referência do gerador.
- `generated_sheet.png`: resultado bruto do image_gen, RGBA 1366×1152.
- `registered_sheet.png` e `frames_3x/`: nove quadros extraídos em 768×648 (3× o canvas original), cada um alinhado aos limites e linha de apoio do respectivo original. O enquadramento não é cortado individualmente na reprodução.
- `prompt.txt`: instrução completa e referências para a transformação.
- `source_manifest.json` e `validation.json`: hashes das fontes, registro e medições.
- `prepare_preview.py`: extração, escala/registro e montagem das prévias (Pillow); não grava em `game/`.

Referência de acabamento: `h_arrival/shiny.png`, usada para pelagem, volume e luz,
mantendo a pose frontal sentada do original. Há movimento de respiração/subida da
cabeça e fechamento da boca no fim, como no clipe de origem.

Verificado: nove quadros não vazios, transparência, ordem/6 fps, ciclo, linha de apoio
e nove hashes originais intactos. Prévia conferida no Chrome com play/pausa, quadro
0/4/8, imagens carregadas e sem erro de JavaScript.

**Limite do experimento:** a geração redesenha também feições e detalhes internos de
pelagem. O ritmo e a trajetória dos limites externos foram mantidos pelo registro,
mas isso não é garantia de deformação interna idêntica: avaliar o GIF/quadros para
decidir sobre continuidade, identidade e uso futuro. Não substitui ainda o personagem
original, não foi exportado/publicado e não altera scripts/regras/save.
