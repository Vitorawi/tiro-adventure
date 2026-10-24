# Troca local do Filhotinho — 24/10/2026

Resultados dos testes, capturas, export e preservação: [VALIDACAO.md](VALIDACAO.md).

21 clipes + sleep_belly; 206 PNGs em 256×216, escala 1:1. Backup completo preservado (207 PNGs contando a imagem idle_front separada).

| Clipe | Versão final | animation_id | Frames no jogo |
|---|---|---|---|
| idle_breathe | idle_breathe | `08d84fb2-f5e8-4a65-8684-273e43b44588` | 9 |
| eat | eat | `f7cb275d-892c-40a6-8944-e776cd32abba` | 9 |
| happy_jump | happy_jump | `7e02456f-cb7e-456e-a862-dd973601441a` | 9 |
| roll_over | roll_over | `7d279cc5-42dc-4ee5-ac44-234ecb647768` | 17 |
| belly_rub | belly_rub | `7c4eee3d-842e-4fcd-a665-0f3c35cc1663` | 9 |
| belly_kick | belly_kick_v2 | `263d781d-a68c-44aa-8cb0-60bc71bed6b0` | 9 |
| sad | sad | `65b86047-11fd-4df8-b913-7e804ed10889` | 9 |
| sleep | sleep_v2 | `8e191cdd-b059-4fcd-94be-f437d3990567` | 17 |
| shake_off | shake_off_v2 | `d584ad8b-4773-4bce-911d-289fa1f8f393` | 9 |
| wag_excited | wag_excited | `c1441192-95da-41e8-9163-85dc2331a6dd` | 9 |
| pet_head | pet_head_v2 | `132d9f25-99f2-4d7c-ab32-6e8690c073db` | 9 |
| pet_paw | pet_paw | `79f0170d-0596-4bcc-b5c5-9cee199f7894` | 9 |
| bark | bark | `cb6bad7b-a41e-44f7-8bbd-6f3c378b24f9` | 9 |
| chase_tail | chase_tail_v4 | `3446aef4-56e9-4563-b26f-12717be3720e` | 9 |
| head_tilt | head_tilt_v3 | `27d4bb07-4fef-47d5-a65e-5c9d75b05b4f` | 9 |
| scratch | scratch_v4 | `07a445ed-f499-495d-9b72-6c532575bc66` | 9 |
| yawn | yawn | `7c997bf0-427d-4c42-8931-26a9c0064cb8` | 9 |
| sniff | sniff_v3 | `c90e77ed-d890-4192-b43d-b91b7b04796a` | 9 |
| stretch | stretch | `d1c6060b-a3b0-4028-a328-30b8ce928c54` | 9 |
| look_around | look_around_v2 | `0caf9603-8857-43c2-8adf-0a64c3e2835f` | 9 |
| lick_paw | lick_paw | `f9f39422-4bb3-431a-aab9-ddc6a35f6674` | 9 |
| sleep_belly | sleep_belly | `0fe9d67e-7488-4adc-9c61-9cd9d2aa13fb` | 1 |

## Versões rejeitadas e preservadas

- **belly_kick:** Riscos claros; versão anterior preservada, final obrigatória v2.
- **sleep:** Risco branco e resíduos coloridos; deitava em três quartos.
- **scratch:** Risco branco junto à pata e rabo listrado.
- **scratch_v2:** Pata dianteira levada à bochecha, movimento de coçar pouco claro.
- **scratch_v3:** Levanta e mexe o corpo sem coçar a orelha.
- **pet_head:** Mão humana indesejada, apesar de prompt sem mão.
- **shake_off:** Orelhas excessivamente longas/eretas no movimento.
- **head_tilt:** Inclinação lateral insuficiente.
- **head_tilt_v2:** Vira a cabeça para o lado em vez de inclinar lateralmente.
- **chase_tail:** Giro incompleto e rabo com marcações alteradas.
- **chase_tail_v2:** Anda de frente em vez de girar.
- **chase_tail_v3:** Giro melhor, mas risco curvo e claro ao lado do rabo no frame 08.
- **sniff:** Brilhos amarelos/claros ao redor do focinho.
- **sniff_v2:** Nuvem branca de sopro nos frames 03–07.
- **look_around:** Quase só pisca, pouco movimento de olhar.

## Normalização

Escala única 1:1: bebê sentado = 137 px de altura, anterior = 139 px. Só translação por frame para alinhar centro horizontal e linha inferior aos quadros originais. Os saltos seguem as linhas de apoio antigas; poses deitadas usam o apoio antigo correspondente. Nenhum pixel opaco cortado. `.import` e `tiro_pet_puppy_idle_front.png` preservados.

Eat: tigela do frame 01 composta no frame 00, com máscara que acompanha seu contorno. Fontes brutas intactas. Sleep_belly: somente a pose 04 instalada como frame_00; os nove quadros da geração permanecem na fonte.

## Ressalva visual

scratch_v4 coça a lateral da bochecha com a pata levantada; após quatro tentativas, não reproduz exatamente a pata traseira atrás da orelha. A pose inicial customizada estabilizou o gesto e removeu riscos; diferença registrada, sem mascarar como reprodução idêntica.
