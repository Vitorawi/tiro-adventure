extends SceneTree
## Instala a arte por raridade do álbum (Fotos do Tiro, etapa 02). Idempotente.
## Lê tools/art/album_rarities/catalog.json e, para cada foto e chave (common/shiny/rare/holographic) com
## status "reviewed" e arquivo existente, grava uma cópia 768×768 em
## res://assets/sprites/ui/album/rarities/<id>/<chave>.png e registra a origem em rarities/manifest.json.
## Uso (3 passos, repita tudo quando chegarem lotes novos):
##   godot --headless --path game -s ../tools/album_rarity_install.gd     (copia)
##   godot --headless --path game --import                                (importa)
##   godot --headless --path game -s ../tools/album_rarity_install.gd     (liga mipmaps nos .import novos)
##   godot --headless --path game --import                                (reimporta só se algo mudou)
## Nunca lê tools/art/album_rarity_tests/ (histórico). Não mexe nas imagens de origem.

const CATALOG := "tools/art/album_rarities/catalog.json"
const ROOT := "res://assets/sprites/ui/album/rarities/"
const KEYS := ["common", "shiny", "rare", "holographic"]
const SIZE := 768
var target_root := ROOT


func _initialize() -> void:
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var catalog_path := repo.path_join(CATALOG)
	# Testes usam catálogo congelado e destino próprio; a execução normal mantém os caminhos canônicos.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--catalog="):
			catalog_path = arg.trim_prefix("--catalog=")
		elif arg.begins_with("--target="):
			target_root = arg.trim_prefix("--target=").trim_suffix("/") + "/"
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	if not catalog is Dictionary:
		push_error("catalog.json ilegível")
		quit(1)
		return
	var manifest := {"schema": 1, "items": {}}
	if FileAccess.file_exists(target_root + "manifest.json"):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(target_root + "manifest.json"))
		if old is Dictionary and old.has("items"):
			manifest = old
	var items: Dictionary = manifest.items
	var wanted := {}
	var installed := 0
	var skipped := 0
	var patched := 0
	var needs_import := 0
	var complete := 0
	for photo: Dictionary in catalog.photos:
		var id := str(photo.id)
		var have := 0
		for key: String in KEYS:
			var variant: Dictionary = photo.variants.get(key, {})
			if str(variant.get("status", "")) != "reviewed":
				continue
			var source := repo.path_join(str(variant.get("path", "")))
			if not FileAccess.file_exists(source):
				push_warning("%s/%s revisada mas sem arquivo: %s" % [id, key, source])
				continue
			var tag := id + "/" + key
			var target := "%s%s/%s.png" % [target_root, id, key]
			wanted[tag] = true
			have += 1
			var hash := FileAccess.get_sha256(source)
			if hash != str(variant.get("sha256", hash)):
				push_warning("%s: hash difere do catálogo (rode o check do pipeline)" % tag)
			var entry: Dictionary = items.get(tag, {})
			if str(entry.get("sha256", "")) == hash and FileAccess.file_exists(target):
				skipped += 1
			else:
				var image := Image.load_from_file(source)
				if image == null or image.is_empty():
					push_error("Não abriu " + source)
					continue
				image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
				image.save_png(ProjectSettings.globalize_path(target))
				items[tag] = {"sha256": hash, "size": SIZE, "installed_at": Time.get_datetime_string_from_system(true)}
				installed += 1
				# Origem nova: o .import antigo (se houver) precisa ser reimportado.
				needs_import += 1
			var import_path := ProjectSettings.globalize_path(target + ".import")
			if FileAccess.file_exists(import_path):
				var text := FileAccess.get_file_as_string(import_path)
				# Também WebP com perda 0,9: sem perda o álbum pesava ~140 MB no pacote da Web (tools/web_lossy_imports.py).
				if text.contains("mipmaps/generate=false") or text.contains("compress/mode=0"):
					var file := FileAccess.open(import_path, FileAccess.WRITE)
					text = text.replace("mipmaps/generate=false", "mipmaps/generate=true").replace("compress/mode=0", "compress/mode=1")
					var quality := RegEx.create_from_string("compress/lossy_quality=[0-9.]+")
					file.store_string(quality.sub(text, "compress/lossy_quality=0.9"))
					file.close()
					patched += 1
			else:
				needs_import += 1
		if have == 4:
			complete += 1
	# O que deixou de estar revisado sai do jogo.
	var removed := 0
	for tag: String in items.keys():
		if wanted.has(tag):
			continue
		var target := "%s%s.png" % [target_root, tag]
		for path: String in [target, target + ".import"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		items.erase(tag)
		removed += 1
		print("AVISO: removido %s (não está mais revisado)" % tag)
	var keys := items.keys()
	keys.sort()
	var sorted := {}
	for key: String in keys:
		sorted[key] = items[key]
	manifest["items"] = sorted
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_root))
	var out := FileAccess.open(target_root + "manifest.json", FileAccess.WRITE)
	if out == null:
		push_error("Não abriu o manifesto de destino: " + target_root)
		quit(1)
		return
	out.store_string(JSON.stringify(manifest, "  ", false) + "\n")
	out.close()
	print("RARIDADES: instalados %d, pulados %d, removidos %d, fotos completas %d/%d, mipmaps corrigidos %d%s" % [
		installed, skipped, removed, complete, catalog.photos.size(), patched,
		", rode --import e este script de novo" if needs_import > 0 else ""])
	quit(0)
