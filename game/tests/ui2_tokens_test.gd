extends SceneTree
## Interface 2, etapa 01: contrato das fontes, tokens, controles vetoriais e tema.

var failures: int = 0
var theme: Theme
var ui_kit: GDScript


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("UI2_TOKENS: " + message)


func _base(font: Font) -> String:
	return (font as FontVariation).base_font.resource_path if font is FontVariation else font.resource_path


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	theme = load("res://assets/theme/main_theme.tres")
	ui_kit = load("res://scripts/ui/ui_kit.gd")
	_fontes()
	_cores()
	_controles()
	_fontes_antigas()
	var primary := theme.get_stylebox("normal", "PrimaryButton") as StyleBoxFlat
	check(primary.bg_color.is_equal_approx(Palette.GO) and primary.border_width_bottom == 3, "Botão verde com lábio de 3 px")
	print("UI2_TOKENS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _fontes() -> void:
	check(_base(theme.default_font).ends_with("Nunito.ttf"), "Fonte padrão Nunito")
	check(theme.default_font_size == 15, "Corpo 15")
	for type_name: String in ["TitleLabel", "StrongLabel", "NumberLabel"]:
		var font := theme.get_font("font", type_name) as FontVariation
		check(_base(font).ends_with("Fredoka.ttf"), type_name + " usa Fredoka")
		check(int(font.variation_opentype.get(2003265652, 0)) == 600, "Fredoka peso 600")
	for entry: Array in [["TitleLabel", 24], ["StrongLabel", 18], ["SmallLabel", 12]]:
		check(theme.get_font_size("font_size", entry[0]) == entry[1], "Tamanho " + str(entry[0]))
	for type_name: String in theme.get_type_list():
		for item: String in theme.get_font_list(type_name):
			check(not _base(theme.get_font(item, type_name)).ends_with("Jersey10.ttf"), "Sem Jersey em " + type_name)


func _cores() -> void:
	for pair: Array in [[Palette.GO, "2b9946"], [Palette.INK, "3a2a1f"], [Palette.PAPER, "fff8ee"], [Palette.HONEY, "ffb730"], [Palette.SKY, "3e9fe4"], [Palette.ALERT, "e5483c"]]:
		check(pair[0] == Color(pair[1]), "Token " + str(pair[1]))
	check(Palette.PRIMARY == Palette.GO and Palette.GOOD == Palette.GO_INK, "Apelidos preservados")


func _controles() -> void:
	for icon_name: String in ["x", "back", "chev", "down", "check", "lock", "plus", "minus", "clock", "help", "list", "arrow", "spark", "gear", "recenter", "talk", "info"]:
		var texture: Texture2D = ui_kit.call("ctl_icon", icon_name)
		check(texture != null and texture.get_width() >= 96, "Vetor 96 px: " + icon_name)
		check(texture == ui_kit.call("ctl_icon", icon_name), "Cache " + icon_name)
	var rect: TextureRect = ui_kit.call("ctl", "x", 20)
	check(rect.custom_minimum_size == Vector2(20, 20) and rect.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Controle 20×20 linear")
	rect.free()
	var button: Button = ui_kit.call("icon_button", ui_kit.call("ctl_icon", "help"), func() -> void: pass)
	check(button.text != "?" and button.find_children("*", "Label", true, false).is_empty(), "Ajuda sem interrogação em texto")
	button.free()
	for symbol: String in ["?", "‹", "+", "−"]:
		var legacy: Button = ui_kit.call("icon_button", null, func() -> void: pass, 44, symbol)
		check(legacy.text == "" and legacy.icon != null and legacy.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Símbolo legado usa vetor: " + symbol)
		legacy.free()


func _fontes_antigas() -> void:
	var dir := DirAccess.open("res://scripts/ui")
	for file: String in dir.get_files():
		if not file.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string("res://scripts/ui/" + file)
		for forbidden: String in ["ui_icon(\"ui_close\")", "ui_icon(\"settings\")", "square_button(\"?\""]:
			check(not source.contains(forbidden), file + " sem controle pixel: " + forbidden)
