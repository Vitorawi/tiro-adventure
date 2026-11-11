# Etapa 10 — Ritmo, oferta do dia e fechamento (portão do Vitor)

> Tamanho: grande (medição). Depende de: 09. Última etapa.
> Resultado que o Vitor vê: um relatório dizendo quanto tempo a pesca acrescentou em cada fase do Tiro (meta:
> +1–2 h nos Dentinhos, +3–5 h no Aventureiro e no Mocinho, no máximo +10% na campanha inteira), a **oferta do
> dia** ligada na banca, a suíte inteira passando, capturas nas três resoluções e um roteiro para testar no
> celular.

## 1. Ler antes

- `02_HISTORIA §5` (metas de ritmo); `04_BANCA §3` (oferta do dia).
- `docs/plans/economia/SIMULADOR.md` (como o simulador funciona e suas regras: nunca `unlimited_storage`,
  `dev_*` ou `ready_at` forçado).
- `docs/plans/cuidado/RESULTADOS.md` (ritmo atual aprovado em 23/10: Filhotinho 1,5 min ativos, Dentinhos
  0,34 d, Aventureiro 2,08 d, Mocinho 8,84 d, adulto 19,84 d) — é a **linha de base**.
- Código: `game/tests/helpers/economy_bot.gd` (política do robô; a ação simples de pescar veio na 05),
  `economy_sim.gd` (agenda, tempo de sessão), `tools/economy_simulate.ps1 -Quick`, `tools/economy_compare.py`.

## 2. Passo a passo

1. **Robô pescador de verdade** (`economy_bot.gd`):
   - perfis do simulador ganham `fishing_skill` (taxa de pontuação média: reference 0,65, light 0,5,
     active 0,8) e o robô sorteia `score` em torno dela com a `rng` do robô;
   - tempo de cada pesca entra no relógio da sessão: arremesso 2 s + espera (`cast.wait`) + minigame
     (`0,7/fill ÷ score` aproximado, mínimo 4 s) + resultado 2 s;
   - política: pescar quando uma missão/requisito/encomenda pede peixe ou prato de peixe; comprar a isca na
     loja se faltar; usar a bolha se houver; cozinhar os pratos;
   - nada de atalho: sempre `cast → hook → finish_fishing` pelo `GameState`.
2. **Medir**: `tools/economy_simulate.ps1 -Quick` (uma execução) e, se o Vitor pedir, sementes extras. Relatório
   em `docs/plans/pesca/RESULTADOS.md`: tempo de cada fase antes × depois, minutos de pesca por fase, iscas
   compradas, moedas gastas em iscas, peixes pegos por espécie, taxa de Gigante.
3. **Ajustar** (só se passar das metas), nesta ordem: quantidade dos pratos (2 → 1), preço/pacote das iscas,
   chance da tilápia; nunca a física aprovada na 00 sem o Vitor.
4. **Oferta do dia** (`04_BANCA §3`, aprovada pelo Vitor): pacote `daily_offer` na `farm_stall` com
   `"rotation": [{"items": {"wood": 2}, "price": 12}, {"items": {"stone": 2}, "price": 12}, …]` (só materiais
   que já existem no ponto do jogo: requisitos por entrada), `daily 1`, escolha do dia determinística pelo dia
   local + `growth.taste_seed`. Cartão com selo "Hoje". Medir de novo se a oferta mudar o ritmo.
5. **Portão**: `tools/test.ps1 -Level portao` + `-Level campanha` (progression_test + simulador Quick). Falhas
   históricas do ROADMAP não contam.
6. **Tour de capturas**: `tests/ui_tour.gd` ganha `--pesca-only` (lagoa, painel, força, mordida, minigame,
   resultado, tutorial, banca Comprar, caderno); rodar nas três resoluções.
7. **Toque real**: `game/tests/touch/fishing.json` (tutorial completo + uma pesca normal + compra na banca) com
   `tools/touch_test.ps1` e medida de fps no minigame (meta ≥ 50 no Chrome emulado).
8. **Roteiro do celular** em `RESULTADOS.md` (o que o Vitor deve fazer no aparelho: segurar com o polegar, pescar
   com a tela pequena, sair do app no meio do minigame e voltar, bolha com o app fechado).
9. **Fechamento**: "Plano CONCLUÍDO" no README do plano, ROADMAP, `CLAUDE.md`/`AGENTS.md` (resumo final da
   pesca com todos os nomes), `docs/PROGRESSION.md`, `docs/GAME_DESIGN.md` (seção Pesca),
   `FUTURO.md` do plano (fotos de pesca, chapéu do pescador, mais peixes, torneio…).

## 3. Não fazer

Publicar. Mudar a física sem o Vitor. Fotos/álbum de pesca.

## 4. Pronto quando

Portão + campanha PASS (ou só falhas históricas), ritmo dentro das metas (ou o Vitor aprovou o que deu),
capturas e toque OK, roteiro do celular escrito, Vitor aprovou.

## 5. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 10 do plano "Pesca na lagoa da vovó" (ritmo, oferta do dia, fechamento).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–09), 02_HISTORIA_E_TUTORIAL.md §5,
04_BANCA.md §3, docs/plans/economia/SIMULADOR.md e docs/plans/pesca/etapas/ETAPA_10_FECHAMENTO.md.
O robô pesca sempre pelo GameState, sem atalhos. Uma execução -Quick; mais sementes só se o Vitor pedir.
Rode portão e campanha. Escreva RESULTADOS.md com o ritmo antes × depois e o roteiro do celular.
PARE para o Vitor aprovar o ritmo. Sem commit/push/publicação.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
