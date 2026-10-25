class_name LargeText
extends RefCounted
## "Texto maior" (Configurações): multiplica por 1,15 os tamanhos de fonte do tema principal.
## Parte sempre dos valores originais (guardados no próprio tema), então ligar de novo não acumula.
## A preferência é do aparelho (settings.json), gravada pelo SaveManager.

const THEME_PATH := "res://assets/theme/main_theme.tres"
const SCALE := 1.15
const META := "large_text_base"

static var _on := false


static func is_on() -> bool:
	return _on


static func apply(on: bool) -> void:
	_on = on
	var theme := load(THEME_PATH) as Theme
	if theme == null:
		return
	if not theme.has_meta(META):
		var base := {"": theme.default_font_size}
		for type_name: String in theme.get_font_size_type_list():
			for item: String in theme.get_font_size_list(type_name):
				base["%s/%s" % [type_name, item]] = theme.get_font_size(item, type_name)
		theme.set_meta(META, base)
	var base: Dictionary = theme.get_meta(META)
	var factor := SCALE if on else 1.0
	for key: String in base:
		var size := roundi(int(base[key]) * factor)
		if key == "":
			theme.default_font_size = size
		else:
			var parts := key.split("/")
			theme.set_font_size(parts[1], parts[0], size)
