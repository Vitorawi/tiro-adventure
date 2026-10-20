# 01 — Regras de execução (contrato de cada agente)

## Leia antes

`CLAUDE.md` (Claude Code) ou `AGENTS.md` (Codex); seção **Estado atual** do `docs/ROADMAP.md`; o
[README](README.md) deste plano; [00_VISAO](00_VISAO.md); este contrato; o arquivo da etapa pedida e as seções
dos documentos comuns que ela indica. Rode `git status` e preserve alterações de outras tarefas.

## Uma etapa, uma entrega

- Executar **somente** a etapa pedida, na ordem 00 → 18. Cada uma depende da anterior concluída.
- O jogo continua funcionando ao fim de cada etapa. Infraestrutura ainda sem uso **não aparece na interface**.
- Não criar requisito que dependa de conteúdo de etapa futura (ex.: o `growth.json` da etapa 02 só lista
  itens que já existem; os itens-chave entram nas etapas 09–10).
- **Portões do Vitor** (etapas 01 e 04): a etapa termina em "aguardando aprovação". A seguinte não começa
  sem o Vitor aprovar a arte por escrito na conversa (registrar no README, com data).
- Se uma dependência estiver incompleta: dizer exatamente a lacuna, não marcar a etapa, não seguir.
- **Sem publicar e sem push.** Commit local só quando o Vitor pedir.

## Autoridade dos arquivos

| Tema | Arquivo autoritativo |
|---|---|
| Escopo e direção | [00_VISAO](00_VISAO.md) |
| Fases, pilares, requisitos, ritmo | [02_FASES_E_PILARES](02_FASES_E_PILARES.md) |
| Comidas, itens, receitas, fim do nível, moedas | [03_COMIDAS_E_ECONOMIA](03_COMIDAS_E_ECONOMIA.md) |
| Capítulos, missões novas, falas, desbloqueios | [04_HISTORIA](04_HISTORIA.md) |
| Álbum (catálogo e gatilhos) e Casa | [05_ALBUM_E_CASA](05_ALBUM_E_CASA.md) |
| Telas, nós, cerimônia, **arte e identidade do Tiro** | [06_INTERFACE_E_ARTE](06_INTERFACE_E_ARTE.md) |
| Estado salvo, reset de saves, eventos, DEV | [07_SAVES_E_ESTADO](07_SAVES_E_ESTADO.md) |
| Quais testes rodar por área | [MAPA_DE_TESTES](MAPA_DE_TESTES.md) |
| Ajustes feitos durante a execução | [DECISOES](DECISOES.md) |

Números repetidos dentro de uma etapa são exemplos; em conflito vale o documento autoritativo. Pedido novo do
Vitor vale mais que tudo (registrar em DECISOES). Os números são **alvos iniciais**, não resultado de playtest:
implemente sem pedir confirmação de cada um.

## Regra de ouro da arte

**O Tiro não pode parecer outro cachorro.** Leia a seção E do [06](06_INTERFACE_E_ARTE.md) antes de qualquer
arte do Tiro. Resumo: o adulto é o Tiro atual (não regenerar); as fases jovens partem das imagens atuais como
referência; mesma paleta, olhos, focinho, língua, contorno e tela (256×216 / 64×64 / 48×48); sempre montar
uma prancha lado a lado e abrir o PNG antes de usar.

## Testes: enxutos por padrão (pedido do Vitor)

As etapas anteriores chegaram a ~2 h por causa de testes com vários perfis de jogador e simulações.
**Neste plano:**

1. **Orçamento:** os testes de uma etapa somam no máximo **~15 min**. Nenhum teste novo passa de **3 min**.
   Rodar com `tools/run_godot_test.ps1` (tem tempo máximo) ou `tools/test_all.ps1 -Only ...` (etapa 00).
2. **Cada etapa cria um teste focado** (`game/tests/<tema>_test.gd`) com os casos listados nela, e entra no
   `tools/test_all.ps1`. Fixtures podem montar estado direto (via helpers/`dev_*`), sem percorrer o jogo.
3. **Rodar só os afetados:** use o [MAPA_DE_TESTES](MAPA_DE_TESTES.md) (área → testes). Registre na etapa a
   tabela "Arquivo mudado → teste rodado → resultado". Teste que quebrou por mudança esperada: ajuste o
   teste e explique; nunca afrouxe um assert só para passar.
4. **Sem simulação de economia nas etapas.** Nada de perfis, sementes ou campanhas simuladas. O Vitor simula
   quando quiser. Exceções: a etapa 11 garante que o robô do simulador sabe crescer (senão a campanha
   trava) e roda `economy_sim_test`; a etapa 17 roda **uma** execução rápida para conferir que funciona.
5. **`progression_test` (≥ 20 min) só nos portões** de passagem total ou quando a etapa mexe na história.
6. **Passagem total** (`tools/test_all.ps1` inteiro, uma vez) só nos **portões 08, 11, 16 e 18**. Falhas
   históricas conhecidas (`onboarding_test`, `finds_test`, `npc_lines_test`): reproduzir uma vez, registrar,
   não investigar além de 10 min.
7. **Capturas:** só das telas que a etapa mudou, em 360×780, antes/depois, e **abrir os PNGs**. As três
   resoluções (360×780, 390×844, 412×915) só nos portões e na etapa 06.
8. **Toque real** (`tools/touch_test.ps1`) só quando a etapa cria gesto novo (entregar, escovar, crescer).
9. **Timeout não é PASS.** Se um teste estoura, registrar e investigar só se for da área da etapa.

## Persistência e interface

- Preservar IDs, `.uid` e `.import` existentes. Missões antigas não mudam de ID (só falas e, quando a etapa
  manda, requisitos/objetivos).
- Campo novo salvo = `reset`/`to_dict`/`from_dict` + teste de recarga. **Sem migração de saves antigos:** a etapa 02
  zera saves com versão < 13 (decisão do Vitor, 19/10/2026). Não escrever compatibilidade com saves de antes do plano.
- Reutilizar `UiKit`, `Palette`, `Motion`, `Sheet`, `ModalCard`, `RingProgress`, `PetAnimator`, `PetNotebook`,
  `TaskHelp`, `Places`, `StationTray`. Não redesenhar abas, câmera, gestos nem o painel.
- Um `PrimaryButton` por painel; bloqueio é cadeado com motivo, nunca botão cinza.
- Textos seguem o glossário (Colher, Pegar, Cozinhar, Fazer, Buscar, Ir) mais os verbos novos deste plano:
  **Crescer, Dar, Escovar** (a etapa que os usa primeiro atualiza o `texts_test`).
- Toda ferramenta nova `GameState.dev_*` começa com `if not BuildInfo.is_dev(): return`.

## Encerramento obrigatório de cada etapa

1. Marcar a etapa no [README](README.md) (data + linha no registro de avanço).
2. Atualizar **Estado atual** do `docs/ROADMAP.md` (feito, pendente, próxima etapa).
3. Atualizar `docs/PROGRESSION.md` / `docs/GAME_DESIGN.md` só com o que foi implementado; arte nova no
   `docs/ART_PIPELINE.md`.
4. Mudou arquitetura ou onde trabalhar? Atualizar `CLAUDE.md` **e** `AGENTS.md` (idênticos).
5. Ajuste de número ou desvio do plano: registrar em [DECISOES](DECISOES.md) com o motivo.
6. Etapa concluída: abrir a sessão da próxima conforme "Sessões encadeadas" no [README](README.md) (exceto portões
   do Vitor ainda não aprovados, etapa incompleta ou a 18).

**Entrega ao Vitor:** o que o jogador sente agora, arquivos principais, testes efetivamente rodados (e os que
não foram, com motivo), limitações e próxima etapa. Nunca dizer que "está tudo balanceado".
