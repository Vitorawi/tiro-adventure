# Monta a sala do Sítio (ilha) a partir da arte gerada no Scenario.
# Uso: py -X utf8 -I tools/build_farm_island.py
# Entradas (tools/art/sitio_vovo/isometrico/scenario/): sitio_cena_ambiente.png, pecas/*.png + posicoes.json,
#   camadas/ilha_sem_penhasco.png (alfa da ilha) e, do Codex, ../../quadrante_horta/canteiro_bloqueado.png.
# Saídas: game/assets/sprites/areas/farm/ilha_*.{webp,png} e game/data/rooms/farm.json.
# Coordenadas da sala = pixels da cena em METADE da resolução (a ilha fica em (400,1500) na cena cheia).
import json
import math
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SC = os.path.join(ROOT, "tools", "art", "sitio_vovo", "isometrico", "scenario")
ART = os.path.join(ROOT, "game", "assets", "sprites", "areas", "farm")
ROOM = os.path.join(ROOT, "game", "data", "rooms", "farm.json")
OLD = os.path.join(SC, "farm_antigo.json")
OX, OY, K = 400, 1500, 0.5
RES = "res://assets/sprites/areas/farm/"


def S(x: float, y: float) -> list[int]:
    """Coordenada da ilha (2400x1712) -> sala (cena em metade)."""
    return [round((x + OX) * K), round((y + OY) * K)]


def inside(poly: list, p: tuple) -> bool:
    x, y = p
    ok = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
            ok = not ok
        j = i
    return ok


def hull(points: list) -> list:
    pts = sorted(set(map(tuple, points)))
    if len(pts) <= 2:
        return [list(p) for p in pts]

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    return [list(p) for p in lo[:-1] + up[:-1]]


def grow(poly: list, f: float) -> list:
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    return [[round(cx + (p[0] - cx) * f), round(cy + (p[1] - cy) * f)] for p in poly]


def diamond(cx: float, bottom: float, hw: float, ratio: float = 1.5) -> list:
    hh = hw / ratio
    return [[round(cx), round(bottom - 2 * hh)], [round(cx + hw), round(bottom - hh)], [round(cx), round(bottom)], [round(cx - hw), round(bottom - hh)]]


def dumps(v, ind=0) -> str:
    pad = "  " * ind
    if isinstance(v, dict):
        if not v:
            return "{}"
        rows = [f'{pad}  {json.dumps(k, ensure_ascii=False)}: {dumps(x, ind + 1)}' for k, x in v.items()]
        return "{\n" + ",\n".join(rows) + f"\n{pad}}}"
    if isinstance(v, list):
        if all(isinstance(x, (int, float)) for x in v) or (v and all(isinstance(x, list) and all(isinstance(y, (int, float)) for y in x) for x in v)):
            return json.dumps(v, ensure_ascii=False)
        if not v:
            return "[]"
        rows = [f"{pad}  {dumps(x, ind + 1)}" for x in v]
        return "[\n" + ",\n".join(rows) + f"\n{pad}]"
    return json.dumps(v, ensure_ascii=False)


def main() -> None:
    if not os.path.exists(OLD):
        import shutil
        shutil.copy(ROOM, OLD)  # guarda o farm.json antigo uma vez
    old = json.load(open(OLD, encoding="utf-8"))
    old_obj = {o["id"]: o for o in old["objects"]}
    old_zone = {z["id"]: z for z in old["zones"]}
    pos = json.load(open(os.path.join(SC, "pecas", "posicoes.json"), encoding="utf-8"))

    # --- arte em metade da resolução ---
    cena = Image.open(os.path.join(SC, "sitio_cena_ambiente.png")).convert("RGB")
    cena = cena.resize((cena.width // 2, cena.height // 2), Image.LANCZOS)
    cena.save(os.path.join(ART, "ilha_cena.webp"), quality=88, method=6)
    info: dict[str, dict] = {}
    for nm in ("silo", "armazem", "bancada", "moinho", "queijaria", "galinheiro", "curral", "estufa", "pomar"):
        im = Image.open(os.path.join(SC, "pecas", nm + ".png")).convert("RGBA")
        half = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
        half.save(os.path.join(ART, f"ilha_{nm}.png"), optimize=True)
        v = pos[nm]
        info[nm] = dict(w=half.width, h=half.height, pos=S(v["x"] + v["w"] / 2, v["y"] + v["h"]), tl=S(v["x"], v["y"]))
    bed = Image.open(os.path.join(SC, "pecas", "canteiro_livre.png")).convert("RGBA")
    bh = bed.resize((bed.width // 2, bed.height // 2), Image.LANCZOS)  # 111x73
    cw, ch = bh.size  # 110x73: livre e bloqueado têm exatamente o mesmo quadro e a mesma base
    bh.save(os.path.join(ART, "ilha_canteiro.png"), optimize=True)
    # Bloqueado = o MESMO canteiro com mato e uma pedra por cima (alinhado por construção). O desenho do Codex tem outra
    # perspectiva e não casava com o livre.
    blocked_bed = bh.copy()
    fg = os.path.join(SC, "camadas", "primeiro_plano")

    def stamp(nome: str, altura: int, cx: float, cy: float) -> None:
        im = Image.open(os.path.join(fg, nome + ".png")).convert("RGBA")
        w = max(1, round(im.width * altura / im.height))
        im = im.resize((w, altura), Image.LANCZOS)
        blocked_bed.alpha_composite(im, (round(cx - w / 2), round(cy - altura)))

    stamp("pedras_com_musgo", 20, 56, 34)
    stamp("arbusto_redondo", 16, 70, 40)
    stamp("margaridas", 22, 40, 45)
    stamp("margaridas", 18, 72, 51)
    blocked_bed.save(os.path.join(ART, "ilha_canteiro_bloqueado.png"), optimize=True)
    crop_off = 0
    print("canteiro", cw, ch)

    # --- chão: losango da ilha a partir do alfa ---
    al = Image.open(os.path.join(SC, "camadas", "ilha_sem_penhasco.png")).split()[3].point(lambda v: 255 if v > 128 else 0)
    W, H = al.size
    px = al.load()
    xs = [x for x in range(0, W, 4) if any(px[x, y] for y in range(0, H, 4))]
    xmin, xmax = xs[0], xs[-1]
    ymin_col = lambda x: min(y for y in range(0, H) if px[x, y])
    ymax_col = lambda x: max(y for y in range(0, H) if px[x, y])
    L = (xmin, ymax_col(xmin))
    R = (xmax, ymax_col(xmax))
    bx = max(range(xmin, xmax, 4), key=lambda x: ymax_col(x))
    B = (bx, ymax_col(bx))
    T = (L[0] + R[0] - B[0], L[1] + R[1] - B[1])
    print("L R B T", L, R, B, T)
    floor_i = grow([list(T), list(R), list(B), list(L)], 0.88)
    floor = [S(*p) for p in floor_i]

    # --- obstáculos fixos (coordenadas da ilha) ---
    rgb = Image.open(os.path.join(SC, "camadas", "ilha_sem_penhasco.png")).convert("RGB")
    small = rgb.resize((W // 4, H // 4))
    sp = small.load()
    # só a região do lago (canto da frente à esquerda): as janelas azuis da casa não contam
    water = [[x * 4, y * 4] for y in range(small.height) for x in range(small.width) if 0 <= x * 4 <= 900 and 620 <= y * 4 <= 1250 and sp[x, y][2] > 170 and sp[x, y][0] < 150 and sp[x, y][1] > 120]
    water += [[580, 960], [830, 960], [830, 1110], [580, 1110]]  # píer
    lake_i = grow(hull(water), 1.0)
    house_i = [[1040, 360], [1210, 275], [1415, 345], [1240, 445]]
    stall_i = [[1215, 1290], [1385, 1205], [1565, 1290], [1395, 1385]]
    # Tudo que está PINTADO no fundo (casa, banca, portão, rochas, cerca do lago) bloqueia a silhueta inteira, inclusive o chão
    # "atrás" dele: o fundo fica abaixo de todos os objetos, então o Tiro atrás desses desenhos apareceria por cima. (coords da sala)
    obstacles = [
        {"id": "bloblo_house", "polygon": [[700, 855], [855, 788], [930, 875], [930, 965], [820, 995], [740, 985], [695, 920]]},
        {"id": "lake", "polygon": [S(*p) for p in lake_i]},
        {"id": "lake_rocks", "polygon": [[220, 1115], [260, 1080], [365, 1042], [405, 1110], [365, 1152], [275, 1185], [235, 1170]]},
        {"id": "lake_fence", "polygon": [[268, 1198], [288, 1192], [506, 1352], [506, 1380], [488, 1382], [268, 1218]]},
        {"id": "stall", "polygon": [[805, 1325], [850, 1270], [950, 1315], [1010, 1365], [1010, 1430], [950, 1452], [885, 1452], [835, 1410]]},
        {"id": "gate", "polygon": [[700, 1420], [762, 1405], [840, 1395], [850, 1502], [780, 1515], [700, 1490]]},
    ]

    # --- canteiros comuns: grade 3x3 achada na arte ---
    O, U, V = (1072, 598), (137, 83), (-150, 78)
    order = [(0, 0), (1, 0), (0, 1), (1, 1), (2, 0), (0, 2), (2, 1), (1, 2), (2, 2)]  # 0-3 iniciais (bloco superior); 4-8 comprados
    objects: list[dict] = []
    bed_fp = []
    for idx, (i, j) in enumerate(order):
        x, y = O[0] + i * U[0] + j * V[0], O[1] + i * U[1] + j * V[1]
        p = S(x + 111, y + 146)  # meio da base do canteiro (peça 222x146)
        fp = diamond(p[0], p[1] - 4, 0.50 * cw)
        bed_fp.append(fp)
        objects.append({"id": f"plot_{idx}", "action": "plot", "plot": idx, "sprite": RES + "ilha_canteiro.png", "locked_sprite": RES + "ilha_canteiro_bloqueado.png", "crop_offset": crop_off, "always_behind": True, "pos": p, "footprint": fp, "approach": [p[0], p[1] + 22]})

    # --- estufa: os 4 espaços de plantio (canteiros 9-12) não aparecem no mapa; tocar na estufa abre a bandeja ---
    gh = info["estufa"]

    # --- construções compráveis (somem até a compra; o jogo põe o "+") ---
    fpw = {"silo": 0.32, "armazem": 0.44, "bancada": 0.40, "moinho": 0.30, "queijaria": 0.42, "galinheiro": 0.46, "curral": 0.46, "estufa": 0.42, "pomar": 0.46}
    ids = {"silo": "silo", "armazem": "warehouse", "bancada": "workbench", "moinho": "mill", "queijaria": "dairy", "galinheiro": "chicken_coop", "curral": "cow_barn", "estufa": "greenhouse", "pomar": "orchard"}
    bases: dict[str, list] = {}
    for nm in ("bancada", "silo", "armazem", "estufa", "pomar", "galinheiro", "curral", "moinho", "queijaria"):
        t = info[nm]
        oid = ids[nm]
        o = dict(old_obj[oid])
        for k in ("pos", "approach", "footprint", "label_pos", "sprite", "z_index"):
            o.pop(k, None)
        hw = fpw[nm] * t["w"]
        fp = diamond(t["pos"][0], t["pos"][1] - 4, hw)
        bases[nm] = fp
        o["sprite"] = RES + f"ilha_{nm}.png"
        o["pos"] = t["pos"]
        o["approach"] = [t["pos"][0] + round(0.5 * hw), t["pos"][1] + 18]
        o["footprint"] = fp
        o["label_pos"] = [t["pos"][0], t["tl"][1] + round(t["h"] * 0.25)]
        o = {k: o[k] for k in ["id", "action", "upgrade", "region", "station", "sprite", "pos", "approach", "footprint", "label", "label_pos", "detail_label"] if k in o}
        objects.append(o)

    # --- animais: lugares dentro dos pátios (os desenhos atuais são provisórios) ---
    def spot(nm: str, fx: float, fy: float) -> list:
        v = pos[nm]
        return S(v["x"] + fx * v["w"], v["y"] + fy * v["h"])

    animals = [
        ("hen_1", "chicken_coop", 0, spot("galinheiro", 0.36, 0.80)), ("hen_2", "chicken_coop", 1, spot("galinheiro", 0.58, 0.72)), ("hen_3", "chicken_coop", 2, spot("galinheiro", 0.50, 0.90)),
        ("cow_1", "cow_barn", 0, spot("curral", 0.28, 0.76)), ("cow_2", "cow_barn", 1, spot("curral", 0.44, 0.88)), ("cow_3", "cow_barn", 2, spot("curral", 0.18, 0.62)),
    ]
    for aid, st, slot, p in animals:
        o = dict(old_obj[aid])
        o.update({"pos": p, "footprint": diamond(p[0], p[1], 10), "approach": [p[0] + 18, p[1] + 10]})
        o.pop("scale", None)
        objects.append(o)

    # --- regiões fechadas (sombra + cerca + preço) ---
    def region(rid: str, nms: list[str], f: float) -> dict:
        pts = [q for nm in nms for q in grow(bases[nm], f)]
        poly = hull(pts)
        cx = sum(p[0] for p in poly) / len(poly)
        cy = sum(p[1] for p in poly) / len(poly)
        # divisa com cerca = aresta da frente à direita (a que olha para o caminho)
        edges = sorted(((poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly))), key=lambda e: -(((e[0][1] + e[1][1]) / 2) - cy) * 1.0 - (((e[0][0] + e[1][0]) / 2) - cx) * 0.0)
        gate = [edges[0][0], edges[0][1]]
        r = dict(old["regions"][[g["id"] for g in old["regions"]].index(rid)])
        r["polygon"] = poly
        r["gate"] = gate
        r["label_pos"] = [round(cx), round(cy)]
        return r

    regions = [region("greenhouse_area", ["estufa"], 1.45), region("orchard_area", ["pomar"], 1.05), region("animals_area", ["galinheiro", "curral", "moinho", "queijaria"], 1.05)]

    # --- zonas de toque e pontos ---
    zones = []
    for z in old["zones"]:
        z = dict(z)
        if z["id"] == "early_market":
            z["polygon"] = [S(*p) for p in [[1215, 1180], [1390, 1050], [1585, 1150], [1585, 1290], [1400, 1390], [1230, 1300]]]
            z["label_pos"] = S(1395, 1230)
        elif z["id"] == "bloblo_house":
            z["polygon"] = [S(*p) for p in [[1040, 360], [1210, 150], [1415, 330], [1240, 450]]]
            z["label_pos"] = S(1225, 110)
        elif z["id"] == "animal_yard":
            z["polygon"] = regions[2]["polygon"]
            z["label_pos"] = regions[2]["label_pos"]
        zones.append(z)

    blocked = [o["polygon"] for o in obstacles] + [r["polygon"] for r in regions] + bed_fp + [bases[k] for k in ("armazem", "silo", "bancada")]

    # Chão andável como o motor calcula (células de 8 px, margem de 8 nas pontas da célula); fica só a maior região
    # conectada (4 vizinhos), para o Tiro, as aproximações e os pontos de escavar nunca caírem num bolsão fechado.
    NAV, MARGIN = 8, 8
    fx = [p[0] for p in floor]
    fy = [p[1] for p in floor]
    offs = [(0, 0), (-MARGIN, -MARGIN), (MARGIN, -MARGIN), (-MARGIN, MARGIN), (MARGIN, MARGIN)]
    free = set()
    for cy in range(min(fy) // NAV, max(fy) // NAV + 1):
        for cx in range(min(fx) // NAV, max(fx) // NAV + 1):
            c = (cx * NAV + NAV / 2, cy * NAV + NAV / 2)
            if all(inside(floor, (c[0] + dx, c[1] + dy)) and not any(inside(b, (c[0] + dx, c[1] + dy)) for b in blocked) for dx, dy in offs):
                free.add((cx, cy))
    seen: set = set()
    best: set = set()
    for cell in free:
        if cell in seen:
            continue
        comp = {cell}
        stack = [cell]
        seen.add(cell)
        while stack:
            x, y = stack.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in free and n not in seen:
                    seen.add(n)
                    comp.add(n)
                    stack.append(n)
        if len(comp) > len(best):
            best = comp
    cands = [(round(cx * NAV + NAV / 2), round(cy * NAV + NAV / 2)) for cx, cy in best]
    print("chão andável:", len(free), "células; maior região:", len(best))

    def near(target):
        return min(cands, key=lambda c: (c[0] - target[0]) ** 2 + (c[1] - target[1]) ** 2)

    # aproximações: o ponto andável conectado mais próximo (canteiros da estufa ficam como estão: a área só abre na compra)
    for o in objects:
        if "approach" in o and not o["id"].startswith(("plot_9", "plot_10", "plot_11", "plot_12", "hen_", "cow_")):
            want = o["approach"] if not o["id"].startswith("plot_") else [o["pos"][0], o["pos"][1] + 22]
            o["approach"] = list(near(want))

    points = {"dog_start": list(near(S(1100, 1330))), "npc_bloblo": list(near(S(1140, 560)))}
    spots: list = []
    for tgt in [S(900, 520), S(1500, 560), S(1180, 1160), S(1520, 1000), S(700, 700), S(1000, 900), S(1330, 880)]:
        c = near(tgt)
        if all(math.dist(c, s) > 90 for s in spots):
            spots.append(c)
    dig = [list(s) for s in spots]

    room = {
        "background": RES + "ilha_cena.webp",
        "backdrop": {"sky": ["#bddff4", "#fbebd3"], "ground": "#7f9150", "clouds": False},
        "floor": floor,
        "dig_spots": dig,
        "navigation_margin": 8,
        "dog_scale": 0.7, "region_shade": False, "region_fence": False,
        "animal_scale": 1.6,
        "initial_zoom": 0.79,
        "min_zoom": 0.46, "background_bleed": [0, 0, 0, 0],
        "view_center": [785, 1107],
        "obstacles": obstacles,
        "objects": objects,
        "zones": zones,
        "points": points,
        "regions": regions,
    }
    with open(ROOM, "w", encoding="utf-8", newline="\n") as f:
        f.write(dumps(room) + "\n")
    print("ok", ROOM, "objetos:", len(objects), "dig:", len(dig), points)


if __name__ == "__main__":
    sys.exit(main())
