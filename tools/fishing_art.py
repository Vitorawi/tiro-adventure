"""Monta as pecas de madeira do minigame da pesca a partir das que ja existem (nao e arte nova):
  ui/home/fishing_track.png, fishing_meter.png (molduras NinePatch, miolo transparente), fishing_bar.png (barra do jogador),
  fishing_meter_fill.png (enchimento branco liso, o codigo tinge) e ui/home/map_status_fishing.png (disco do seletor com a vara).
Uso: py -X utf8 tools/fishing_art.py   (depois: godot --headless --path game --import e mipmaps/generate=true nos .import das de madeira)"""
from PIL import Image, ImageDraw
H = "game/assets/sprites/ui/home/"; I = "game/assets/sprites/ui/icons/"
board = Image.open(H + "station_board.png").convert("RGBA")
# faixa de madeira lisa do miolo da tabua, reduzida (3x) para ficar do tamanho de uso
wood = board.crop((120, 60, 480, 130)).resize((120, 23), Image.LANCZOS)
def frame(w, h, b=12):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tile = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    for x in range(0, w, wood.width):
        for y in range(0, h, wood.height): tile.paste(wood, (x, y))
    mask = Image.new("L", (w, h), 0); d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, w - 1, h - 1), 7, fill=255); d.rounded_rectangle((b, b, w - 1 - b, h - 1 - b), 3, fill=0)
    img.paste(tile, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), 7, outline=(70, 42, 22, 255), width=2)
    d.rounded_rectangle((b - 1, b - 1, w - b, h - b), 3, outline=(70, 42, 22, 255), width=2)
    return img
frame(96, 192).save(H + "fishing_track.png")
frame(48, 192).save(H + "fishing_meter.png")
bar = Image.new("RGBA", (24, 24), (0, 0, 0, 0)); d = ImageDraw.Draw(bar)
d.rounded_rectangle((0, 0, 23, 23), 5, fill=(88, 190, 98, 120), outline=(255, 255, 255, 225), width=2)
bar.save(H + "fishing_bar.png")
Image.new("RGBA", (8, 8), (255, 255, 255, 255)).save(H + "fishing_meter_fill.png")
# disco do seletor: disco vazio de madeira + vara de bambu (ja redimensionada para caber)
disc = Image.open(H + "map_status_busy.png").convert("RGBA")
base = Image.open(H + "map_disc.png").convert("RGBA")
rod = Image.open(I + "station_fishing.png").convert("RGBA").resize((64, 64), Image.NEAREST)
out = base.copy(); out.alpha_composite(rod, ((out.width - 64) // 2, (out.height - 64) // 2 + 2))
out.save(H + "map_status_fishing.png")
print("ok", disc.size, base.size)
