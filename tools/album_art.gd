extends SceneTree
## Gera a arte pequena do álbum (etapa 13): moldura polaroide, adereços de foto e ícones.
## Uso: godot --headless --path game -s ../tools/album_art.gd   (depois: godot --headless --path game --import)
## Os desenhos são grades de caracteres 16×16 ampliadas 2× (32 px), pixel art sem suavização.

const COLORS := {
	"k": Color("4a3a2a"), "b": Color("b98a54"), "B": Color("8a6238"), "l": Color("e0b97a"), "w": Color("fff8e8"),
	"y": Color("f2c94c"), "Y": Color("c9962b"), "r": Color("d9534f"), "R": Color("ef8a85"), "g": Color("79ac4b"),
	"G": Color("4f7f34"), "u": Color("5a8fd0"), "U": Color("3d6aa5"), "p": Color("e89aa5"), "s": Color("9aa0a6"),
	"n": Color("dfe9f2"), "d": Color("6b5a44"),
}

const ART := {
	"ui/album/prop_box": [
		"................", "................", "................", "..kkkkkkkkkkkk..", ".kllllllllllllk.", ".kBBBBBBBBBBBBk.",
		".kbbbbbbbbbbbbk.", ".kbbbbbbbbbbbbk.", ".kbbbkkkkkkbbbk.", ".kbbbkwwwwkbbbk.", ".kbbbkkkkkkbbbk.",
		".kbbbbbbbbbbbbk.", ".kBBBBBBBBBBBBk.", "..kkkkkkkkkkkk..",
	],
	"ui/album/prop_bowl": [
		"................", "................", "................", "................", "...kkbBbBbBkk...", "..kRRRRRRRRRRk..",
		".krrrrrrrrrrrrk.", ".krrrrrrrrrrrrk.", "..krrrrrrrrrrk..", "...kkrrrrrrkk...", ".....kkkkkk.....",
	],
	"ui/album/prop_stall_sign": [
		"................", ".kkkkkkkkkkkkkk.", ".kyyyyyyyyyyyyk.", ".kywywywywywyyk.", ".kyyyyyyyyyyyyk.",
		".kywywyywywyyyk.", ".kyyyyyyyyyyyyk.", ".kkkkkkkkkkkkkk.", ".......kBk......", ".......kBk......",
		".......kBk......", ".......kBk......", "......kkBkk.....",
	],
	"ui/album/prop_medal": [
		".....kk..kk.....", ".....kuk.kuk....", ".....kuk.ukk....", "......kuukk.....", ".......kk.......",
		".....kkkkkk.....", "....kyyyyyyk....", "...kyyYYYYyyk...", "...kyYyyyyYyk...", "...kyYyyyyYyk...",
		"...kyyYYYYyyk...", "....kyyyyyyk....", ".....kkkkkk.....",
	],
	"ui/icons/item_milk_tooth": [
		"................", "....kkk..kkk....", "...kwwwkkwwwk...", "..kwwwwwwwwwwk..", "..kwwwwwwwwwwk..",
		"..kwwnwwwwwwwk..", "...kwwwwwwwwk...", "...kwwwwwwwwk...", "...kwwkkkkwwk...", "...kwwk..kwwk...",
		"...kwk....kwk...", "....kk....kk....",
	],
	"ui/icons/album_story": [
		"................", "..kkkkkkkkkkkk..", ".kuuuuukuuuuuuk.", ".kuwwwwkwwwwwuk.", ".kuwkkwkwkkkwuk.",
		".kuwwwwkwwwwwuk.", ".kuwkkwkwkkkwuk.", ".kuwwwwkwwwwwuk.", ".kuuuuukuuuuuuk.", "..kkkkkkkkkkkk..",
	],
	"ui/icons/album_firsts": [
		"................", ".......kk.......", "......kyyk......", "......kyyk......", "..kkkkkyykkkkk..",
		".kyyyyyyyyyyyyk.", "..kyyyyyyyyyyk..", "...kyyyyyyyyk...", "...kyyyyyyyyk...", "..kyyyykkyyyyk..",
		"..kyyyk..kyyyk..", "...kkk....kkk...",
	],
	"ui/icons/album_tricks": [
		"................", "....kkkkkkkk....", "...kppppppppk...", "..kppkkkkkkppk..", "..kppkpppkkppk..",
		"..kpppppkkpppk..", "...kkpppkkppk...", ".....kppkkkk....", ".....kkkk.......", ".....kppk.......",
		".....kkkk.......",
	],
	"ui/icons/album_sleep": [
		"................", "....kkkkkk......", "..kkyyyyyk......", ".kyyyyyyk.......", ".kyyyyyk..kkkk..",
		".kyyyyyk....kk..", ".kyyyyyyk..kk...", "..kkyyyyykkkkk..", "....kkkkkk......",
	],
	"ui/icons/album_friends": [
		"................", "..kkkk....kkkk..", ".krrrrk..krrrrk.", "krRrrrrkkrrrrrrk", "krrrrrrrrrrrrrrk",
		".krrrrrrrrrrrrk.", "..krrrrrrrrrrk..", "...krrrrrrrrk...", "....krrrrrrk....", ".....krrrrk.....",
		"......krrk......", ".......kk.......",
	],
	"ui/icons/album_dates": [
		"................", "..kkkkkkkkkkkk..", ".kuuuuuuuuuuuuk.", ".kkkkkkkkkkkkkk.", ".kwwwwwwwwwwwwk.",
		".kwrrwwkkwwwwwk.", ".kwrrwwkkwwwwwk.", ".kwwwwwwwwkkwwk.", ".kwwwwwwwwkkwwk.", ".kwwwwwwwwwwwwk.",
		"..kkkkkkkkkkkk..",
	],
}


func _initialize() -> void:
	var root := ProjectSettings.globalize_path("res://assets/sprites/")
	for key: String in ART:
		var rows: Array = ART[key]
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var top := int((16 - rows.size()) / 2)
		for y in rows.size():
			var row: String = rows[y]
			for x in mini(row.length(), 16):
				var ch := row[x]
				if COLORS.has(ch):
					image.set_pixel(x, y + top, COLORS[ch])
		image.resize(32, 32, Image.INTERPOLATE_NEAREST)
		var path := root + key + ".png"
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		image.save_png(path)
		print("ok ", key)
	# Moldura polaroide (9-patch 24×24, margem 8): papel claro, contorno escuro, sombra suave.
	var frame := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	for y in 24:
		for x in 24:
			var edge := mini(mini(x, 23 - x), mini(y, 23 - y))
			var corner := (x == 0 or x == 23) and (y == 0 or y == 23)
			if corner:
				continue
			if edge == 0:
				frame.set_pixel(x, y, COLORS.d)
			elif edge == 1:
				frame.set_pixel(x, y, Color("e8dcc4"))
			else:
				frame.set_pixel(x, y, COLORS.w)
	DirAccess.make_dir_recursive_absolute(root + "ui/album")
	frame.save_png(root + "ui/album/polaroid.png")
	print("ok polaroid")
	quit()
