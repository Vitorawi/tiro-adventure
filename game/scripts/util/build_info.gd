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
	return "user://save_dev.json" if is_dev() else "user://save.json"
