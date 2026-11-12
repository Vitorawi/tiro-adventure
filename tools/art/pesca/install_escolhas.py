"""Instala as opcoes escolhidas (11/11/2026, o Vitor deixou a escolha comigo: 'depois a gente repensa').
Copia PNGs para game/assets; sem reduzir/esticar. Uso: py -X utf8 tools/art/pesca/install_escolhas.py"""
import shutil, os
O = "tools/art/pesca/opcoes/"; I = "game/assets/sprites/ui/icons/"; F = "game/assets/sprites/ui/fishing/"; X = "game/assets/sprites/fx/"
os.makedirs(F, exist_ok=True); os.makedirs(X, exist_ok=True)
peixes = {"lambari": "a", "cara": "a", "tilapia": "a", "carp": ("carpa", "b"), "pacu": "b", "tambaqui": "a", "traira": "a", "tucunare": "a", "pintado": "a"}
for pid, esc in peixes.items():
    nome, op = (esc if isinstance(esc, tuple) else (pid, esc))
    shutil.copy(f"{O}icons_peixe/{nome}_{op}.png", f"{I}item_fish_{pid}.png")
    shutil.copy(f"{O}peixe_jogo/{nome}_a.png", f"{F}fish_{pid}.png")
for k, v in {"worm": "item_bait_worm", "dough": "item_bait_dough", "lure": "item_bait_lure"}.items():
    shutil.copy(f"{O}iscas/{k}_a.png", f"{I}{v}.png")
for k, v in {"bamboo": "rod_bamboo", "reel": "rod_reel", "angler": "rod_angler"}.items():
    shutil.copy(f"{O}varas/{k}_a.png", f"{I}{v}.png")
for k, v in {"mash": "item_fish_mash", "stew": "item_fish_stew", "herbfish": "item_herb_fish", "crunch": "item_lambari_crunch"}.items():
    shutil.copy(f"{O}pratos/{k}_a.png", f"{I}{v}.png")
shutil.copy(f"{O}fx/station_a.png", f"{I}station_fishing.png")
shutil.copy(f"{O}fx/bobber_a.png", f"{X}fishing_bobber.png")
shutil.copy(f"{O}fx/bubble_a.png", f"{X}fishing_bubble.png")
shutil.copy(f"{O}fx/splash_a.png", f"{X}fishing_splash.png")
shutil.copy(f"{O}fx/bau_a.png", f"{F}chest.png")
print("ok")
