# Monta a sala do Sítio EXATAMENTE como o arquivo do Figma "Figma-basics" > página "Fazenda" (file P7Z4cRwe49bHtmG67CG23z).
# Uso: py -X utf8 -I tools/build_farm_figma.py [--debug]
# Entradas (tools/art/sitio_vovo/figma/, baixadas do Figma, cada camada em 1x): fundodositio.png, sitio.png (ilha com os 9
#   canteiros desenhados), silo, celeiro, cural, galinheiro, lacticios, moinho, estufa e compra (a placa de venda).
# Saídas: game/assets/sprites/areas/farm/figma_*.{webp,png} e game/data/rooms/farm.json.
# Coordenadas da sala = pixels do Figma relativos ao canto do fundo (-1362, -1060) vezes K (0,6): nada é reposicionado à mão,
# toda peça fica no x,y que o Vitor deixou no Figma. Os canteiros agora são parte do desenho do fundo: o jogo só põe
# a planta por cima e, nos fechados, a placa "compra". Construções ainda não abertas também mostram a placa.
import json
import math
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FIG = os.path.join(ROOT, "tools", "art", "sitio_vovo", "figma")
ART = os.path.join(ROOT, "game", "assets", "sprites", "areas", "farm")
ROOM = os.path.join(ROOT, "game", "data", "rooms", "farm.json")
RES = "res://assets/sprites/areas/farm/"
FO = (-1362.0, -1060.0)  # canto do "fundodositio" no Figma
K = 0.6
SITIO = (-1017.0, 105.0)  # canto da camada "sitio" no Figma

# Retângulos exatos das camadas no Figma (x, y, largura, altura) e o que cada uma é no jogo.
PIECES = {
    "silo": (106, 250, 311, 442),
    "celeiro": (245, 430, 400, 380),
    "cural": (336.0585632324219, 619.3577880859375, 617.8828162569553, 467.57634380832314),
    "galinheiro": (160, 869, 421, 329),
    "lacticios": (-521, 380, 385, 318),
    "moinho": (-704, 319, 313, 458),
    "estufa": (-521, 986, 364, 324),
}
SIGNS = [(-357, 749), (137, 749), (14, 817), (-111, 894), (-232, 828)]  # as cinco "compra" do Figma (135x135)
SIGN_SIZE = 135
# parte de baixo da peça (fração da altura) que forma a base no chão
BAND = {"silo": 0.30, "celeiro": 0.42, "cural": 0.52, "galinheiro": 0.52, "lacticios": 0.42, "moinho": 0.26, "estufa": 0.42}
OBJ = {"silo": "silo", "celeiro": "warehouse", "cural": "cow_barn", "galinheiro": "chicken_coop", "lacticios": "dairy", "moinho": "mill", "estufa": "greenhouse"}
# centros dos 9 canteiros desenhados na camada "sitio" (px da camada) e meia-largura/altura do losango do aro
BEDS = {"top": (970, 590), "ul": (850, 661), "ur": (1095, 664), "l": (730, 736), "c": (973, 737), "r": (1222, 739), "bl": (850, 811), "br": (1096, 811), "b": (973, 888)}
BED_HW, BED_HH = 98, 60
HOUSE_PX = [[795, 310], [950, 225], [1290, 320], [1235, 385], [1090, 420], [1010, 425], [905, 395], [800, 340]]  # base da casa (px do "sitio")
# ordem de compra: os 4 primeiros (sem placa) já vêm abertos; as cinco placas do Figma ficam em l, r, bl, br, b
PLOT_ORDER = ["top", "ul", "ur", "c", "bl", "br", "l", "r", "b"]


def R(x: float, y: float) -> list[int]:
    """Coordenada do Figma -> sala."""
    return [round((x - FO[0]) * K), round((y - FO[1]) * K)]


def P(sx: float, sy: float) -> list[int]:
    """Pixel da camada 'sitio' -> sala."""
    return R(sx + SITIO[0], sy + SITIO[1])


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


def diamond(cx: float, cy: float, hw: float, hh: float) -> list:
    return [[round(cx), round(cy - hh)], [round(cx + hw), round(cy)], [round(cx), round(cy + hh)], [round(cx - hw), round(cy)]]


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


def base_polygon(im: Image.Image, tl: list, band: float) -> list:
    """Base no chão de uma peça: casco do trecho de baixo do desenho (alfa > 128), em coordenadas da sala."""
    w, h = im.size
    a = im.split()[3].load()
    pts = [(x + tl[0], y + tl[1]) for y in range(int(h * (1 - band)), h, 3) for x in range(0, w, 3) if a[x, y] > 128]
    return hull(pts)


def simplify(poly: list, tol: float = 2.5) -> list:
    """Tira vértices quase colineares do casco (o JSON fica curto)."""
    pts = [list(p) for p in poly]
    changed = True
    while changed and len(pts) > 6:
        changed = False
        for i in range(len(pts)):
            a, b, c = pts[i - 1], pts[i], pts[(i + 1) % len(pts)]
            area = abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1]))
            base = math.dist(a, c) or 1.0
            if area / base < tol:
                pts.pop(i)
                changed = True
                break
    return pts


def main() -> None:
    debug = "--debug" in sys.argv
    # --- fundo: "fundodositio" + a ilha "sitio" por cima, no lugar do Figma ---
    fundo = Image.open(os.path.join(FIG, "fundodositio.png")).convert("RGBA")
    sitio = Image.open(os.path.join(FIG, "sitio.png")).convert("RGBA")
    fundo.alpha_composite(sitio, (round(SITIO[0] - FO[0]), round(SITIO[1] - FO[1])))
    cena = fundo.convert("RGB")
    cena = cena.resize((round(cena.width * K), round(cena.height * K)), Image.LANCZOS)
    cena.save(os.path.join(ART, "figma_cena.webp"), quality=90, method=6)
    print("cena", cena.size)

    # --- peças ---
    info: dict[str, dict] = {}
    for nm, (x, y, w, h) in PIECES.items():
        im = Image.open(os.path.join(FIG, nm + ".png")).convert("RGBA")
        sw, sh = round(w * K), round(h * K)
        half = im.resize((sw, sh), Image.LANCZOS)
        half.save(os.path.join(ART, f"figma_{nm}.png"), optimize=True)
        tl = R(x, y)
        info[nm] = dict(im=half, w=sw, h=sh, tl=tl, pos=[tl[0] + sw // 2, tl[1] + sh])
    sign = Image.open(os.path.join(FIG, "compra.png")).convert("RGBA")
    sg = round(SIGN_SIZE * K)
    sign.resize((sg, sg), Image.LANCZOS).save(os.path.join(ART, "figma_compra.png"), optimize=True)
    # bancada = a própria casa (decisão do Vitor): sem peça no Figma, o objeto é um recorte da casa idêntico ao fundo (nada novo
    # aparece ao comprar), que serve para o toque, a bandeja, o balão e para o Tiro passar atrás dela.
    bx0, by0, bx1, by1 = 790, 60, 1300, 440
    bench = sitio.crop((bx0, by0, bx1, by1))
    bsw, bsh = round(bench.width * K), round(bench.height * K)
    bench.resize((bsw, bsh), Image.LANCZOS).save(os.path.join(ART, "figma_bancada.png"), optimize=True)
    btl = P(bx0, by0)
    info["bancada"] = dict(w=bsw, h=bsh, tl=btl, pos=[btl[0] + bsw // 2, btl[1] + bsh])
    bed_w, bed_h = round((2 * BED_HW + 4) * K), round((2 * BED_HH + 4) * K)
    Image.new("RGBA", (bed_w, bed_h), (0, 0, 0, 0)).save(os.path.join(ART, "figma_canteiro_vazio.png"), optimize=True)
    # --- limpa a arte do arranjo anterior ---
    for f in list(os.listdir(ART)):
        if f.startswith("ilha_") and os.path.exists(os.path.join(ART, f)):
            os.remove(os.path.join(ART, f))

    # --- chão: losango da ilha (alfa da camada "sitio") ---
    al = sitio.split()[3].point(lambda v: 255 if v > 128 else 0)
    W, H = al.size
    px = al.load()
    xs = [x for x in range(0, W, 4) if any(px[x, y] for y in range(0, H, 4))]
    xmin, xmax = xs[0], xs[-1]
    ymax_col = lambda x: max(y for y in range(0, H) if px[x, y])
    Lp = (xmin, ymax_col(xmin))
    Rp = (xmax, ymax_col(xmax))
    bxx = max(range(xmin, xmax, 4), key=lambda x: ymax_col(x))
    Bp = (bxx, ymax_col(bxx))
    Tp = (Lp[0] + Rp[0] - Bp[0], Lp[1] + Rp[1] - Bp[1])
    print("L R B T", Lp, Rp, Bp, Tp)
    floor = [P(*q) for q in grow([list(Tp), list(Rp), list(Bp), list(Lp)], 0.88)]

    # --- obstáculos pintados no fundo (casa, banca, portão, lagoa, rochas) ---
    rgb = sitio.convert("RGB")
    small = rgb.resize((W // 4, H // 4))
    sp = small.load()
    water = [[x * 4, y * 4] for y in range(small.height) for x in range(small.width) if 0 <= x * 4 <= 800 and 560 <= y * 4 <= 1050 and sp[x, y][2] > 170 and sp[x, y][0] < 150 and sp[x, y][1] > 120]
    lake_px = hull(water + [[430, 800], [720, 800], [720, 995], [430, 995]])  # + píer
    obstacles = [
        {"id": "bloblo_house", "polygon": [P(*q) for q in HOUSE_PX]},
        {"id": "lake", "polygon": [P(*q) for q in lake_px]},
        {"id": "lake_rocks", "polygon": [P(*q) for q in [[90, 640], [330, 600], [570, 760], [625, 830], [480, 775], [300, 735], [120, 705]]]},
        {"id": "lake_fence", "polygon": [P(*q) for q in [[40, 790], [70, 775], [500, 1070], [500, 1105], [470, 1095], [40, 820]]]},
        {"id": "stall", "polygon": [P(*q) for q in [[975, 1050], [1115, 985], [1230, 1030], [1230, 1110], [1130, 1190], [990, 1105]]]},
        {"id": "gate", "polygon": [P(*q) for q in [[820, 1240], [925, 1175], [1022, 1195], [1022, 1335], [930, 1350], [825, 1295]]]},
        {"id": "rock_lake", "polygon": [P(*q) for q in [[495, 1065], [555, 1060], [560, 1115], [500, 1120]]]},
        {"id": "rock_gate", "polygon": [P(*q) for q in [[1030, 1300], [1090, 1295], [1090, 1350], [1035, 1350]]]},
    ]

    # --- canteiros: ficam no fundo; o objeto só guarda o losango, a planta e o balão ---
    objects: list[dict] = []
    bed_fp = []
    plot_pos = {}
    for idx, key in enumerate(PLOT_ORDER):
        cx, cy = BEDS[key]
        pos = P(cx, cy + BED_HH)  # meio da base do aro
        fp = [P(*q) for q in diamond(cx, cy, BED_HW + 4, BED_HH + 2)]
        bed_fp.append(fp)
        plot_pos[key] = pos
        objects.append({"id": f"plot_{idx}", "action": "plot", "plot": idx, "sprite": RES + "figma_canteiro_vazio.png", "always_behind": True, "pos": pos, "footprint": fp, "approach": [pos[0], pos[1] + 24]})

    # --- placas "compra" dos canteiros: as cinco do Figma, cada uma no canteiro mais próximo ---
    sign_pos = []
    for sx, sy in SIGNS:
        base = R(sx + SIGN_SIZE / 2, sy + SIGN_SIZE)
        sign_pos.append(base)
    taken = set()
    for base in sign_pos:
        best = min((k for k in PLOT_ORDER[4:] if k not in taken), key=lambda k: math.dist(plot_pos[k], base))
        taken.add(best)
        idx = PLOT_ORDER.index(best)
        objects.append({"id": f"sign_plot_{idx}", "action": "buy_sign", "sign_plot": idx, "sprite": RES + "figma_compra.png", "pos": base, "footprint": diamond(base[0], base[1] - 4, 10, 6)})
        print("placa", base, "-> canteiro", idx, best)

    # --- construções: o desenho do Figma no lugar exato; fechadas mostram a placa ---
    bases: dict[str, list] = {}
    old = json.load(open(os.path.join(ROOT, "tools", "art", "sitio_vovo", "isometrico", "scenario", "farm_antigo.json"), encoding="utf-8"))
    old_obj = {o["id"]: o for o in old["objects"]}
    order = ["bancada", "silo", "celeiro", "estufa", "galinheiro", "cural", "moinho", "lacticios"]
    ids = dict(OBJ, bancada="workbench")
    for nm in order:
        t = info[nm]
        oid = ids[nm]
        o = {k: v for k, v in old_obj[oid].items() if k in ("id", "action", "upgrade", "station", "label", "detail_label")}
        if nm == "bancada":
            fp = [P(*q) for q in HOUSE_PX]
        else:
            fp = simplify([[round(p[0]), round(p[1])] for p in base_polygon(t["im"], t["tl"], BAND[nm])])
        bases[nm] = fp
        o["sprite"] = RES + f"figma_{nm}.png"
        if nm == "estufa":
            o["greenhouse_indicator"] = True
        o["buy_sign"] = True
        o["pos"] = t["pos"]
        o["footprint"] = fp
        o["label_pos"] = [t["pos"][0], t["tl"][1] + round(t["h"] * 0.25)]
        cx = sum(p[0] for p in fp) / len(fp)
        maxy = max(p[1] for p in fp)
        o["approach"] = [round(cx), maxy + 14]
        o = {k: o[k] for k in ["id", "action", "upgrade", "station", "route_group", "greenhouse_indicator", "buy_sign", "sprite", "pos", "approach", "footprint", "label", "label_pos", "detail_label"] if k in o}
        objects.append(o)
        # placa no lugar da construção (centro da base, um pouco à frente)
        miny = min(p[1] for p in fp)
        sp_ = [round(cx), round((miny + maxy) / 2 + 14)]
        if nm == "bancada":
            sp_ = P(735, 352)  # a casa é a bancada: a placa fica ao lado, nas pedras à esquerda da casa
        objects.append({"id": f"sign_{oid}", "action": "buy_sign", "sign_upgrade": oid, "sprite": RES + "figma_compra.png", "pos": sp_, "footprint": diamond(sp_[0], sp_[1] - 4, 10, 6)})

    # --- pomar: agora fica DENTRO da estufa (a rota de maçãs sai dela). Sem desenho próprio: um objeto transparente do tamanho
    # da estufa leva o balão da rota, a seta do "Ir" e a compra; a placa "compra" dele fica ao lado da placa da estufa. ---
    gh = info["estufa"]
    Image.new("RGBA", (gh["w"], gh["h"]), (0, 0, 0, 0)).save(os.path.join(ART, "figma_pomar_vazio.png"), optimize=True)
    gfp = bases["estufa"]
    gx = [p[0] for p in gfp]
    gy = [p[1] for p in gfp]
    objects.append({"id": "orchard", "action": "place:orchard", "upgrade": "orchard", "route_group": "orchard", "buy_sign": True, "sprite": RES + "figma_pomar_vazio.png", "pos": gh["pos"], "approach": [round(sum(gx) / len(gx)), max(gy) + 14]})
    objects.append({"id": "sign_orchard", "action": "buy_sign", "sign_upgrade": "orchard", "sprite": RES + "figma_compra.png", "pos": [round(sum(gx) / len(gx) + 0.28 * (max(gx) - min(gx))), max(gy) - 6], "footprint": diamond(sum(gx) / len(gx) + 0.28 * (max(gx) - min(gx)), max(gy) - 10, 10, 6)})

    # --- animais: dentro dos cercados do Figma ---
    def spot(nm: str, fx: float, fy: float) -> list:
        t = info[nm]
        return [t["tl"][0] + round(fx * t["w"]), t["tl"][1] + round(fy * t["h"])]

    animals = [
        ("hen_1", "chicken_coop", 0, spot("galinheiro", 0.40, 0.72)), ("hen_2", "chicken_coop", 1, spot("galinheiro", 0.58, 0.78)),
        ("cow_1", "cow_barn", 0, spot("cural", 0.36, 0.70)), ("cow_2", "cow_barn", 1, spot("cural", 0.52, 0.82)),
    ]
    for aid, st, slot, p in animals:
        o = dict(old_obj[aid])
        o.update({"pos": p, "footprint": diamond(p[0], p[1], 10, 6), "approach": [p[0] + 18, p[1] + 10]})
        o.pop("scale", None)
        objects.append(o)

    # --- zonas de toque ---
    zones = [
        {"id": "early_market", "action": "place:early_market", "polygon": [P(*q) for q in [[975, 950], [1115, 940], [1225, 990], [1230, 1110], [1130, 1190], [990, 1105]]], "label": "Vender Colheita", "label_pos": P(1105, 1040), "requirements": {"quests": ["bloblo_meet"]}},
        {"id": "bloblo_house", "action": "npc:bloblo", "polygon": [P(*q) for q in [[800, 300], [880, 110], [1100, 60], [1290, 310], [1180, 420], [960, 440]]], "label": "Bloblo", "label_pos": P(1040, 60)},
    ]
    for z in old["zones"]:
        if z["id"] == "lake":
            pass

    blocked = [o["polygon"] for o in obstacles] + bed_fp + list(bases.values())

    # --- chão andável como o motor calcula (células de 8 px; só a maior região conectada) ---
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
    print("chão andável:", len(free), "células; maior região:", len(best), "de", len(seen) and len(free))

    def near(target):
        return min(cands, key=lambda c: (c[0] - target[0]) ** 2 + (c[1] - target[1]) ** 2)

    for o in objects:
        if "approach" in o and not o["id"].startswith(("hen_", "cow_")):
            want = o["approach"]
            o["approach"] = list(near(want))
    for o in objects:
        if o["id"].startswith(("hen_", "cow_")):
            o["approach"] = list(near(o["pos"]))

    points = {"dog_start": list(near(P(985, 1110))), "npc_bloblo": list(near(P(900, 520)))}

    # --- lagoa: zona tocável só na água, ponto da pesca na margem e as bolhas ---
    lake_poly = next(o["polygon"] for o in obstacles if o["id"] == "lake")
    lcx = sum(p[0] for p in lake_poly) / len(lake_poly)
    lcy = sum(p[1] for p in lake_poly) / len(lake_poly)
    lr = sum(math.dist(p, (lcx, lcy)) for p in lake_poly) / len(lake_poly)
    water_room = hull([P(*q) for q in water])
    lake_zone = grow(water_room, max(0.5, 1 - 6 / lr))
    zones.append({"id": "lake", "action": "place:fishing", "polygon": lake_zone, "label": "Lagoa", "label_pos": [round(lcx), round(lcy)]})
    pier = P(600, 905)  # deck do píer, do lado da água
    spot_xy = near(P(745, 1005))  # margem de onde o Tiro entra no píer
    dx, dy = lcx - spot_xy[0], lcy - spot_xy[1]
    face = ("east" if dx > 0 else "west") if abs(dx) > abs(dy) else ("south" if dy > 0 else "north")
    points["fishing_spot"] = list(spot_xy)
    points["fishing_pier"] = pier
    points["fishing_face"] = face
    core = grow(water_room, 0.6)
    xs_, ys_ = [p[0] for p in core], [p[1] for p in core]
    water_set = [P(*q) for q in water]
    inner = [(x, y) for x in range(min(xs_), max(xs_) + 1, 6) for y in range(min(ys_), max(ys_) + 1, 6) if inside(core, (x, y)) and math.dist((x, y), pier) > 70 and any(math.dist((x, y), w) < 8 for w in water_set[::7])]
    bubbles = [min(inner, key=lambda c: math.dist(c, (lcx, lcy)))]
    while len(bubbles) < 4 and inner:
        bubbles.append(max(inner, key=lambda c: min(math.dist(c, b) for b in bubbles)))
    for i, b in enumerate(bubbles):
        points[f"fishing_bubble_{i + 1}"] = [b[0], b[1]]
    print("lagoa: ponto", spot_xy, face, "bolhas", bubbles)

    spots: list = []
    for tgt in [P(520, 500), P(1500, 560), P(1500, 960), P(700, 1000), P(1180, 1180), P(1700, 1000), P(1000, 1280)]:
        c = near(tgt)
        if all(math.dist(c, s) > 90 for s in spots):
            spots.append(c)

    room = {
        "background": RES + "figma_cena.webp",
        "backdrop": {"sky": ["#bddff4", "#fbebd3"], "ground": "#7f9150", "clouds": False},
        "floor": floor,
        "dig_spots": [list(s) for s in spots],
        "navigation_margin": 8,
        "dog_scale": 0.7, "region_shade": False, "region_fence": False,
        "animal_scale": 0.85,
        "depth_sort": True,
        "initial_zoom": 0.79,
        "min_zoom": 0.46, "background_bleed": [0, 0, 0, 0],
        "view_center": P(983, 738),
        "plot_signs": True,
        "obstacles": obstacles,
        "objects": objects,
        "zones": zones,
        "points": points,
        "regions": [],
    }
    with open(ROOM, "w", encoding="utf-8", newline="\n") as f:
        f.write(dumps(room) + "\n")
    print("ok", ROOM, "objetos:", len(objects), "dig:", len(spots))

    # --- verificações de conflito: tudo que o Tiro precisa alcançar tem que estar no chão andável conectado ---
    cs = {(round(c[0]), round(c[1])) for c in cands}
    problems = []
    named = {k: v for k, v in points.items() if isinstance(v, list) and k != "fishing_pier"}
    for o in objects:
        if "approach" in o:
            named["approach:" + o["id"]] = o["approach"]
    for i, s in enumerate(spots):
        named[f"dig_{i}"] = list(s)
    for k, p in named.items():
        if (round((p[0] - NAV / 2) / NAV) * NAV + NAV // 2, round((p[1] - NAV / 2) / NAV) * NAV + NAV // 2) not in cs and tuple(p) not in cs:
            problems.append(k)
    for k, p in named.items():
        if any(inside(b, tuple(p)) for b in blocked):
            problems.append(k + " (dentro de obstáculo)")
    print("pontos fora do chão andável conectado / dentro de obstáculo:", problems or "nenhum")

    if debug:
        dbg = cena.convert("RGBA")
        from PIL import ImageDraw
        d = ImageDraw.Draw(dbg, "RGBA")
        for b in blocked:
            d.polygon([tuple(p) for p in b], fill=(255, 0, 0, 90), outline=(255, 0, 0, 255))
        d.polygon([tuple(p) for p in floor], outline=(0, 0, 255, 255))
        for c in cands[::3]:
            d.point(c, fill=(0, 255, 0, 255))
        for k, p in named.items():
            d.ellipse([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=(255, 255, 0, 255), outline=(0, 0, 0, 255))
        out = os.path.join(ROOT, "build", "farm_figma_debug.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        dbg.save(out)
        print("debug", out)


if __name__ == "__main__":
    sys.exit(main())
