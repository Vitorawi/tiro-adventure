extends SceneTree
## Guarda dos textos: nenhum texto visível usa as palavras fora do glossário (docs/GAME_DESIGN.md → "Voz do jogo").
## Lê os mesmos JSON e scripts que tools/list_texts.ps1; ao mudar a lógica de um, mude a do outro.

const FORBIDDEN: Array[String] = ["Recolher", "Coletar", "Conclua:", " · Conclua", "Nv ", "Máx.", "capítulo %d", "x0", "Produzir"]

## Campos JSON cujo valor aparece para o jogador.
const JSON_KEYS: Array[String] = ["name", "description", "label", "dialogue", "map_name", "map_caption", "instruction", "action_label",
	"queue_label", "recipe_label", "hint", "introduction", "postcard", "note", "unlocks_text", "role", "greeting",
	"text", "how_to", "breed", "announcement", "away_text", "unlock_label", "title", "caption", "detail_label",
	"overview_label", "button", "equip", "friend_gift"]

## Ferramentas de teste (DEV) não são texto do jogo.
const EXCEPT_FILES: Array[String] = ["scripts/ui/dev_panel.gd"]
## Exceções pontuais { arquivo: [trechos de texto] } (nomes de id, formatos internos); explique cada uma.
const EXCEPT_TEXTS := {
	# Pedido do Vitor (15/10/2026): o cartão do mundo fechado diz "Abre no capítulo N" + a história/missão exigida.
	"scripts/ui/places.gd": ["Abre no capítulo %d"],
}

const NOISE_PATTERN := "^\\s*(print|push_error|push_warning|assert|@export|const\\s+\\w+\\s*:?=?\\s*preload)\\b|\\b(preload|load|get_node|has_node|find_child)\\("

var failures := 0
var scanned := 0


func _initialize() -> void:
	_run()
	print("TEXTS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEXTS: " + message)


func _run() -> void:
	# O detector precisa pegar cada palavra proibida (senão o teste não vigia nada).
	for word: String in FORBIDDEN:
		check(_forbidden("Frase com " + word + " no meio") == word, "detector acha '%s'" % word)
	check(_forbidden("Colher, Pegar, Cozinhar, Fazer, Buscar, Ir, Crescer, Dar") == "", "glossário passa")

	for path in _files("res://data", ["json"]):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_scan_json(parsed, "", path.trim_prefix("res://"))
	var noise := RegEx.create_from_string(NOISE_PATTERN)
	var literal := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var sources := _files("res://scripts", ["gd"]) + _files("res://scenes", ["gd", "tscn"]) + ["res://autoload/game_state.gd"]
	for path: String in sources:
		var rel := path.trim_prefix("res://")
		if rel in EXCEPT_FILES:
			continue
		var is_script := path.ends_with(".gd")
		var func_name := ""
		var func_pattern := RegEx.create_from_string("^\\s*(?:static\\s+)?func\\s+(\\w+)")
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n in lines.size():
			var line: String = lines[n].trim_suffix("\r")
			var declared := func_pattern.search(line)
			if declared:
				func_name = declared.get_string(1)
			var code := line
			if is_script:
				var hash_at := _comment_start(line)
				if hash_at >= 0:
					code = line.substr(0, hash_at)
			if noise.search(code):
				continue
			for found in literal.search_all(code):
				var text := found.get_string(1)
				if not _prose(text):
					continue
				scanned += 1
				var word := _forbidden(text)
				if word != "" and not _excepted(rel, text):
					check(false, "%s:%d (%s) tem \"%s\": %s" % [rel, n + 1, func_name, word, text])
	check(scanned > 300, "textos de scripts examinados (%d)" % scanned)


## Procura as palavras proibidas; devolve a primeira ou "".
func _forbidden(text: String) -> String:
	for word: String in FORBIDDEN:
		if word in text:
			return word
	return ""


func _excepted(file: String, text: String) -> bool:
	for part: String in EXCEPT_TEXTS.get(file, []):
		if part in text:
			return true
	return false


## Texto de gente: tem letra e (espaço ou começa com maiúscula); ids e caminhos ficam de fora.
func _prose(text: String) -> bool:
	if text.begins_with("res://") or text.begins_with("user://") or text.begins_with("ui:"):
		return false
	var has_letter := false
	for i in text.length():
		if text.unicode_at(i) > 64 and (text[i].to_lower() != text[i].to_upper()):
			has_letter = true
			break
	if not has_letter:
		return false
	return " " in text or (text[0] >= "A" and text[0] <= "Z")


## Posição do "#" que abre comentário fora de aspas (-1 se não tem).
func _comment_start(line: String) -> int:
	var inside := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if c == "\\" and inside:
			i += 2
			continue
		if c == "\"":
			inside = not inside
		elif c == "#" and not inside:
			return i
		i += 1
	return -1


func _scan_json(node: Variant, key: String, file: String) -> void:
	if node is String:
		if key in JSON_KEYS:
			scanned += 1
			var word := _forbidden(node)
			if word != "" and not _excepted(file, node):
				check(false, "%s (%s) tem \"%s\": %s" % [file, key, word, node])
	elif node is Dictionary:
		for child_key: String in node:
			_scan_json(node[child_key], child_key, file)
	elif node is Array:
		for item: Variant in node:
			_scan_json(item, key, file)


func _files(dir_path: String, extensions: Array[String]) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file_name in dir.get_files():
		if file_name.get_extension() in extensions:
			found.append(dir_path.path_join(file_name))
	for sub in dir.get_directories():
		found.append_array(_files(dir_path.path_join(sub), extensions))
	return found
