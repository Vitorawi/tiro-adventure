# Bebê ilustrado — cabeça, coçada e bocejo

Ampliação do teste aprovado da respiração, em 07/11/2026. Usa os 27 desenhos
distintos já gerados pelo **image_gen** em `../tiro_puppy_shiny_batch01/`.
Prompts e folhas brutas estão naquela pasta; não houve nova geração nesta revisão.

| Clipe | Quadros | FPS preservado |
|---|---:|---:|
| `head_tilt` | 9 | 7 |
| `scratch` | 9 | 8 |
| `yawn` | 9 | 6 |

`prepare.py` registra cada desenho num canvas fixo de 768×648 (3×). Olhos e
nariz têm correspondências manuais para não perder a referência quando a cabeça
gira ou os olhos fecham. Peito e patas de apoio usam rastreamento de patches.
A boca do bocejo e a patinha que coça têm controles próprios. A pose de repouso
é calibrada com a respiração publicada, evitando offsets independentes entre clipes.
O registro inverso por malha suave preserva os desenhos distintos de cada quadro.

Reproduzir, na raiz do repositório, com Pillow/OpenCV/numpy disponíveis:

```powershell
py tools/art/tiro_puppy_shiny_batch01/prepare.py
py tools/art/tiro_puppy_landmarks_v4/prepare.py
py tools/art/tiro_puppy_landmarks_v4/audit.py
```

Os scripts criam `frames_3x`, folhas, GIFs e prévias HTML por clipe. Copiar os
27 PNGs finais para `game/assets/sprites/characters/tiro_pet_puppy_illustrated/<clipe>`
e importar no Godot com mipmaps. Respiração já aprovada permanece intacta.
Arte pixel é somente entrada: `audit.json` confirma os 27 hashes originais.

`audit.py` mede patches de patas nos PNGs corrigidos, além do ajuste matemático
da malha. Máximo por eixo = 1 px em 3×; máximo vetorial = 1,414 px em cabeça/coçada
e 1 px em bocejo (até 0,472 px no canvas original). Correlações >0,92.
Esses números cobrem as patas de apoio; não prometem identidade de cada fio de
pelo nem substituem avaliação visual da sequência no celular.

`PetAnimator` escolhe os quatro clipes alternativos apenas na aba Tiro e corpo
`puppy`. Cache por clipe, seleção preguiçosa; conjunto incompleto cai no pixel.
Mantém relógio, ordem, repetição e reversão originais. Retratos/mapa/outros corpos
e demais animações continuam com os recursos existentes.

**Reverter:** engrenagem → **Bebê ilustrado** → desligar. Retorna os quatro clipes
ao pixel imediatamente; preferência persistida sem reset do progresso.

Validação: seis testes focados PASS em 48,2 s (`build/test_logs/r20261107_151444_2048d18c/`),
incluindo quadros/ritmo/retorno/reversão/fallback e toggle real. Teste completo com
render OpenGL e capturas dos quadros 0/4/8 de cada clipe PASS; capturas em
`build/screenshots/puppy_idle_preview/`. Revisão das três poses no cenário realizada.

Build prod+dev PASS. Chrome emulado 390×844: partida real, intro, aba Tiro,
relógio de animação, configurações e pixel restaurado conferidos; zero erros JS.
Capturas `three_web_*.png` na pasta acima.
