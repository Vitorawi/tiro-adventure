from pathlib import Path
from PIL import Image
import numpy as np
from math import cos, tau

folder = Path(__file__).parent
rest = Image.open(folder / "repouso.png").convert("RGBA")
inhale = Image.open(folder / "inspiracao.png").convert("RGBA").resize(rest.size, Image.Resampling.LANCZOS)
# Register once against both planted forepaws. Only translate the whole generated cel.
a = np.asarray(rest, dtype=float)
b = np.asarray(inhale, dtype=float)
def paw_error(dx, dy):
    target = a[505:557, 288:453]
    sample = b[505-dy:557-dy, 288-dx:453-dx]
    def premultiply(pixels):
        return pixels[:, :, :3] * (pixels[:, :, 3:] / 255.)
    return np.mean(abs(premultiply(target)-premultiply(sample)))
dx, dy = min(((x,y) for x in range(-5,6) for y in range(-5,6)), key=lambda d:paw_error(*d))
registered = Image.new("RGBA", rest.size)
registered.paste(inhale, (dx,dy))
# Render review on a fixed matte so playback handles all alpha edges consistently.
def plate(sprite):
    background = Image.new("RGBA", rest.size, "#f3e9da")
    background.alpha_composite(sprite)
    return background.crop((165,105,575,600)).convert("RGB")
low, high = map(plate,(rest, registered))
frames = [Image.blend(low,high,(1-cos(tau*i/60))/2) for i in range(60)]
frames[0].save(folder/"respiracao.webp", save_all=True, append_images=frames[1:],duration=40,loop=0,lossless=True,method=2)
print("Registration:", dx,dy,"preview frames:", Image.open(folder/"respiracao.webp").n_frames)
