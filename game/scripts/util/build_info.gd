class_name BuildInfo
extends RefCounted
## Canal da build: "prod" (jogo publicado) ou "dev" (versão de testes).
##
## O canal vem de data/version.json, gravado pelo deploy (prod em /, dev em /dev/).
## Rodando pelo executável do Godot (editor, testes, screenshots) é dev; "-- --prod"
## força prod e "-- --dev" força dev. A versão dev:
##   - usa outro save (user://save_dev.json), sem tocar no progresso real;
##   - mostra o selo DEV na barra superior, que abre as ferramentas de teste
##     (moedas, materiais, atributos, pular capítulos, avançar o tempo...).
## Ver docs/DEPLOY.md ("Versão dev").


static func channel() -> String:
	var args := OS.get_cmdline_user_args()
	if "--prod" in args:
		return "prod"
	if OS.has_feature("editor") or "--dev" in args:
		return "dev"
	return str(Database.version.get("channel", "prod"))


static func is_dev() -> bool:
	return channel() == "dev"


static func save_path() -> String:
	return data_dir() + ("save_dev.json" if is_dev() else "save.json")


static func settings_path() -> String:
	return data_dir() + ("settings_dev.json" if is_dev() else "settings.json")


## Pasta descartável por processo de teste. Produção ignora a variável.
static func data_dir() -> String:
	var tag := OS.get_environment("TIRO_TEST_TAG")
	if tag.is_empty() or not is_dev():
		return "user://"
	# Uma tag é um nome, nunca um caminho fornecido pelo ambiente.
	var safe := ""
	for character: String in tag:
		safe += character if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-" else "_"
	var path := "user://test_%s/" % safe
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	return path
