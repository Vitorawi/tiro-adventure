class_name Palette
extends RefCounted
## Cores da interface. Use sempre estas constantes (nada de Color("...") solto no código novo).
## Guia completo em docs/plans/interface2/01_BIBLIA_VISUAL.md (seção B).

const PAPER := Color("fff8ee")
const CARD := Color("ffffff")
const SUNKEN := Color("f6ede0")
const LINE := Color("eee2d1")
const BASE := Color("fbf1e2")
const BASE_LINE := Color("efe0cb")
const INK := Color("3a2a1f")
const INK_SOFT := Color("745e4d")
const INK_FAINT := Color("bca894")
const GO := Color("2b9946")
const GO_EDGE := Color("1f7a37")
const GO_INK := Color("23783a")
const GO_SOFT := Color("e7f6ea")
const HONEY := Color("ffb730")
const HONEY_EDGE := Color("e2961a")
const HONEY_SOFT := Color("fff1d3")
const HONEY_INK := Color("8c5800")
const TAB_ON := Color("ffe2a6")
const SKY := Color("3e9fe4")
const SKY_SOFT := Color("e2f1fc")
const SKY_INK := Color("22679a")
const ALERT := Color("e5483c")
const ALERT_SOFT := Color("fde6e3")
const ALERT_INK := Color("b0322a")
const SHADOW := Color(0.43, 0.27, 0.12, 0.13)
const SCRIM := Color(0.23, 0.16, 0.12, 0.38)
const BASE_GLASS := Color(0.984, 0.945, 0.886, 0.92)

# Selos de clientes (cores próprias preservadas).
const SEAL_BRONZE := Color("c98a4b")  # selo de cliente: patamar 1
const SEAL_SILVER := Color("b9c3cc")  # patamar 2
const SEAL_GOLD := Color("f2c230")    # patamar 3
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
const PET_BUTTON := Color(0.9, 0.83, 0.69, 0.55)

# Desenho do mundo e do treino (cores que não são de painel, mas também não ficam soltas no código).
const OUTLINE := Color("4a2e21")      # contorno de seta/selo sobre o mundo
const FENCE_RAIL := Color("a67843")   # cerca das áreas fechadas
const FENCE_POST := Color("654529")
const INTRO_SHADE := Color("2a1a12")  # véu da chegada da Laís
const TRACK_DARK := SUNKEN            # barra do treino de truques: trilho afundado
const TRACK_ZONE := GO                # zona certa (GO_SOFT some sobre o trilho; verde = acertar)
const TRACK_MARKER := INK             # marcador
const WARN_TINT := Color(1.0, 0.6, 0.55)  # botão armado ("Certeza?")

# Visual "madeira ilustrada" da tela inicial (HUD, cartão da missão, bandeja, abas). Ver `HomeUi`.
const WOOD_INK := Color("5a3418")       # texto escuro sobre creme/madeira
const WOOD_CREAM := Color("fff3dc")     # texto claro com contorno escuro
const WOOD_PATCH := Color("c17b40")     # remendo de madeira atrás do "n/m" da placa (reamostrado no gerador)
const WOOD_ASK := Color(0.9, 0.12, 0.1, 0.5)  # espaço de necessidade que está pedindo
const WOOD_GLOW := Color(1.0, 0.82, 0.35, 0.9)  # brilho dourado da aba ativa
const WOOD_SHADOW := Color(0.35, 0.2, 0.08, 0.22)  # sombra do Tiro no chão do quarto
