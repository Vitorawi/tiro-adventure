class_name Palette
extends RefCounted
## Cores da interface. Use sempre estas constantes (nada de Color("...") solto no código novo).
## Guia completo em docs/plans/interface/01_REGRAS_E_ESTILO.md (seção B.1).

# Superfícies
const PAPER := Color("fff6e3")        # fundo dos painéis
const CARD := Color("f8ead0")         # cartão (informação agrupada)
const CARD_LINE := Color("e3cba3")    # borda fina do cartão (2 px)
const SUNKEN := Color("eedcb8")       # chip/pílula dentro de cartão, trilho de barra
const SHADE := Color(0.17, 0.11, 0.07, 0.18)  # sombra suave
const DIM := Color(0.12, 0.08, 0.05, 0.45)    # fundo escurecido atrás de painel/modal
# Texto
const INK := Color("3d2618")          # texto principal
const INK_SOFT := Color("7a5c44")     # texto secundário
const INK_ON_DARK := Color("fff1d6")  # texto sobre HUD escuro
# Ações
const PRIMARY := Color("6cc24a")      # botão principal (verde folha)
const PRIMARY_EDGE := Color("3f8a2b") # degrau do botão principal
const ACCENT := Color("f6b85e")       # mel: botão secundário forte, destaque
const ACCENT_EDGE := Color("c9822f")
const DANGER := Color("e0574b")       # falta / fechar
const GOOD := Color("3f8a2b")         # tem / ganho (texto)
const BAD := Color("c2412f")          # falta (texto)
const INFO := Color("4fa3d9")         # água, tempo, progresso
const GOLD := Color("ffd23f")         # moeda, estrela, XP
const HUD := Color(0.17, 0.11, 0.07, 0.78)  # pílulas do HUD sobre o mundo
# Cor de cada mundo (cabeçalho, pílula do mundo, seletor)
const WORLD := {
	"house": Color("c98b5a"), "farm": Color("7db84a"), "park": Color("e9b93a"),
	"village": Color("d9694a"), "nature": Color("4fa3d9"),
}

# Luz do cantinho do Tiro (hora local; só apresentação).
const PET_DAY := Color.WHITE
const PET_SUNSET := Color(1.0, 0.83, 0.66)
const PET_NIGHT := Color(0.42, 0.52, 0.74)
const PET_SLEEP := Color(0.76, 0.79, 0.88)
const PET_SURFACE := Color(1.0, 0.965, 0.89, 0.96)
const PET_BUTTON := Color(0.9, 0.83, 0.69, 0.55)

# Desenho do mundo e do treino (cores que não são de painel, mas também não ficam soltas no código).
const OUTLINE := Color("4a2e21")      # contorno de seta/selo sobre o mundo
const FENCE_RAIL := Color("a67843")   # cerca das áreas fechadas
const FENCE_POST := Color("654529")
const INTRO_SHADE := Color("2a1a12")  # véu da chegada da Laís
const TRACK_DARK := Color("352c39")   # barra do treino de truques
const TRACK_ZONE := Color("66cc73")
const TRACK_MARKER := Color("fff2b0")
const WARN_TINT := Color(1.0, 0.6, 0.55)  # botão armado ("Certeza?")
