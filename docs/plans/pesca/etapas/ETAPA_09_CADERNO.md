# Etapa 09 — Caderno de pesca, rotinas e encomendas

> Tamanho: média. Depende de: 08. Próxima: 10.
> Resultado que o Vitor vê: no Caderninho → Coleção aparece o filtro **Peixes**: os 9 peixes em quadradinhos
> (os que faltam como sombra com "?"), com o recorde de cada um; tocar abre o detalhe com a régua do tamanho,
> quantos pegou, Gigantes e onde pegar. Diárias e semanais de pesca e encomendas com peixe.

## 1. Ler antes

- `02_HISTORIA §4`; `03_INTERFACE §7`.
- `CLAUDE.md`: "Caderninho em madeira ilustrada" (`CodexUi.build`, `CodexSections.view`, `CodexUi.tile`,
  filtros `NotebookTab_<filtro>`, detalhes `sheet_wood`), "Missão diária / semanal" (`routines.json`).
- Código: `game/scripts/ui/codex_sections.gd` `_collection(wanted)` (l. ~393: filtros `clothes`, `finds`,
  `friends`, cada um com `feature_unlocked`) e `_clothes_blocks`/`_finds_blocks`; `game/data/routines.json`
  (`daily.missions.<id> {name, description, goal {key, target, targets {start, middle, community}}, rewards,
  player_xp, requirements}`); `progression.json → features` (revelar aos poucos).

## 2. Passo a passo

1. **Feature** `fish_book` em `progression.json → features` com `requirements {rod: bamboo_rod}` (aparece com
   "Novo!" depois do tutorial; `go` = Caderninho → Coleção → Peixes).
2. **Filtro Peixes** em `_collection`: `{"id": "fish", "text": "Peixes", "icon": item_fish_tilapia}` quando
   `feature_unlocked("fish_book")`; `_fish_blocks()`: um bloco por vara ("Vara de bambu", "Molinete", "Vara do
   pescador"), 3 tiles cada (`CodexUi.tile`), `Fish_<id>`: ícone, legenda = nome; pego → pílula com o recorde
   "32,5 cm" e coroa se teve Gigante; não pego → `dim` + "?" (a sombra); vara ainda não obtida → bloco inteiro
   apagado com cadeado e a dica "Ganhe a vara de molinete".
3. **Detalhe da espécie** (`CodexSections.fish_detail(id)`, folha `sheet_wood` no molde de `crop_detail`):
   ícone grande, nome, régua de madeira com a faixa real (min–max cm) e a marca do recorde, "Pegou N" ·
   "Gigantes N" · "Perfeitas N", isca e vara que pegam, comportamento em uma linha ("Nada para o fundo"), botão
   amarelo "Ir pescar" (lagoa). Não pego: só a faixa, a isca e "Ainda não pegou".
4. **Rotinas** (`routines.json`):
   - diária `fish` "Pesque na lagoa" (`goal {key fish, target 2, targets {start 2, middle 3, community 4}}`,
     rewards coins 6, `player_xp 5`, `requirements {rod: bamboo_rod}`);
   - semanal `big_fish` "Um peixe grande" (`fish_size:large` 1, coins 20) e `many_fish` "Pescaria" (`fish` 15,
     coins 25 + `bait_worm 5`), ambas com a vara de bambu.
   Confirme que o requisito `rod` é aceito pelo sorteio das rotinas (passa pelo `requirement_error`).
5. **Encomendas** (`progression.json → orders`, com `customer`): `bloblo_lambaris` (4 lambaris, 30 moedas,
   customer bloblo), `nina_lambari_treats` (2 `lambari_crunch`, 45, customer nina). Item/receita
   `lambari_crunch` "Petisco de lambari" (`02_HISTORIA §2`: 3 lambaris → 2, fogão, 240 s, `treat true`,
   `growth {phases [teething, explorer, young, adult]}`, venda 14).
6. **Manual** (Caderninho → Recursos): os peixes e iscas aparecem na categoria certa com Origem = "Lagoa do
   Sítio" (`Database.sources_of` → lagoa) e Usado em = pratos.
7. **TaskHelp**: `describe("stat", "fish_size:large")` explica "Jogue bem: o peixe fica maior quanto mais tempo
   dentro da barra" com Ir.

## 3. Não fazer

Fotos/álbum de pesca (o Vitor deixou para depois). Prêmio por completar o caderno (pode ser proposto no
registro, não implementado).

## 4. Testes

Novo **`game/tests/fishing_book_test.gd`** (área `fishing` + `lists`):
1. Filtro Peixes só aparece com a vara; "Novo!" uma vez.
2. 9 tiles; pegos com recorde; não pegos `dim`; bloco de vara não obtida apagado.
3. Detalhe mostra faixa, recorde, contadores e Ir leva à lagoa.
4. Rotinas de pesca sorteáveis só com a vara; concluem com os contadores.
5. Encomendas e o petisco funcionam; o petisco é comida de crescimento nas fases certas.
6. `item_sources("fish_tilapia")` aponta a lagoa.
Afetados: `manual_test`, `routines_test` (ou o teste que cobre as diárias), `customers_test`, `lists_test`,
`item_sources_test`, `codex` (capturas).

## 5. Capturas

`tests/codex_shots.gd` (acrescentar casos) ou `tests/fishing_book_shots.gd`: filtro Peixes vazio, meio, completo
com Gigantes; detalhe de um pego e de um não pego. Três resoluções.

## 6. Pronto quando

Testes PASS, capturas abertas, registros.

## 7. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 09 do plano "Pesca na lagoa da vovó" (caderno de peixes, rotinas, encomendas).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–08), 02_HISTORIA_E_TUTORIAL.md e
docs/plans/pesca/etapas/ETAPA_09_CADERNO.md. Sem fotos/álbum de pesca. Registre fishing_book_test.
Capturas SEM --headless. Ao terminar: Registro da 09, ROADMAP, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 10.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
