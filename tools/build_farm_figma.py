# Monta a sala do Sítio EXATAMENTE como o arquivo do Figma "Figma-basics" > página "Fazenda 2" (file P7Z4cRwe49bHtmG67CG23z,
# node 3840:2). Uso: py -X utf8 -I tools/build_farm_figma.py [--debug]
# Entradas (tools/art/sitio_vovo/figma2/, imagens originais das camadas do Figma): fundo.png (paisagem), ilha.png (a ilha com
#   casa, banca, os 9 canteiros, o rio com a ponte e a lagoa com o píer), silo, celeiro, cural, galinheiro, lacticios, moinho,
#   estufa e compra (a placa "$" dos canteiros fechados).
# Saídas: game/assets/sprites/areas/farm/figma_*.{webp,png} e game/data/rooms/farm.json.
# Coordenadas da sala = pixels do Figma relativos ao canto da paisagem (-3109, -959) vezes K (0,5): nada é reposicionado à mão,
# toda peça fica no x,y que o Vitor deixou no Figma. Os canteiros são parte do desenho da ilha: o jogo só põe a planta por cima
# e, nos fechados, a placa "compra". Construções ainda não abertas também mostram a placa.
# (A versão anterior, da página "Fazenda", está no histórico do git.)
import json
import math
import os
import sys

from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FIG = os.path.join(ROOT, "tools", "art", "sitio_vovo", "figma2")
ART = os.path.join(ROOT, "game", "assets", "sprites", "areas", "farm")
ROOM = os.path.join(ROOT, "game", "data", "rooms", "farm.json")
RES = "res://assets/sprites/areas/farm/"
FO = (-3109.0, -959.0)  # canto da paisagem no Figma
FUNDO_W, FUNDO_H = 5302.0, 3535.0
K = 0.5  # deixa as construções do mesmo tamanho na tela que na versão anterior
ILHA = (-2461.0, -564.0, 4084.0, 2723.0)  # retângulo da camada da ilha no Figma

# Retângulos exatos das camadas no Figma (x, y, largura, altura).
PIECES = {
    "silo": (449, 14, 373, 530),
    "celeiro": (214, 233, 469, 445),
    "cural": (-373, -247, 676, 507),
    "galinheiro": (-662, -361, 455, 355),
    "lacticios": (-1872, 352, 465, 384),
    "moinho": (-2086, 340, 357, 521),
    "estufa": (-88, 1297, 425, 379),
}
# as sete placas "$" do Figma (224x224), cada uma sobre um canteiro fechado
SIGNS = [(-1053, 1040), (-886, 1126), (-886, 953), (-403, 1036), (-728, 1040), (-570, 1126), (-728, 1238)]
SIGN_SIZE = 224
# parte de baixo da peça (fração da altura) que forma a base no chão
BAND = {"silo": 0.30, "celeiro": 0.42, "cural": 0.52, "galinheiro": 0.52, "lacticios": 0.42, "moinho": 0.26, "estufa": 0.42}
OBJ = {"silo": "silo", "celeiro": "warehouse", "cural": "cow_barn", "galinheiro": "chicken_coop", "lacticios": "dairy", "moinho": "mill", "estufa": "greenhouse"}
# centros dos 9 canteiros desenhados na ilha (px da ilha.png, 1536x1024) e meia-largura/altura do losango do aro
BEDS = {"top": (692, 592), "ul": (632, 626), "ur": (754, 626), "l": (572, 662), "c": (692, 660), "r": (815, 662), "bl": (632, 698), "br": (754, 698), "b": (692, 735)}
BED_HW, BED_HH = 48, 26
# ordem de compra: os 2 primeiros (sem placa no Figma) já vêm abertos
PLOT_ORDER = ["top", "ur", "ul", "c", "l", "r", "bl", "br", "b"]
# Coisas PINTADAS na ilha (px da ilha). O fundo fica atrás de tudo: se o Tiro andasse atrás de uma coisa alta pintada, ele
# seria desenhado por cima dela. Por isso cada uma bloqueia a SILHUETA INTEIRA (base + o chão atrás do telhado/copa).
HOUSE_BASE_PX = [[516, 500], [560, 462], [640, 436], [724, 488], [722, 534], [650, 553], [600, 560], [522, 536]]  # base (bancada); as floreiras da frente ficam fora (o Tiro passa rente)
# contorno colado no desenho da casa (telhado, chaminé, paredes, varanda) e da banca (toldo, caixotes, barris): o
# recorte não pode levar estrada nem grama, senão o Tiro "some" num pedaço de chão ao passar atrás
HOUSE_PX = [[522, 530], [516, 492], [558, 433], [568, 426], [614, 399], [617, 391], [649, 391], [649, 414], [681, 449], [717, 486],
            [719, 500], [717, 546], [690, 552], [645, 556], [606, 558], [580, 553], [540, 546], [524, 540]]
# zona da vovó: a casa + a escadinha e o quintalzinho da frente (fora do desenho da bancada, que cobre a casa quando comprada)
HOUSE_ZONE_PX = [[514, 488], [560, 430], [612, 390], [650, 390], [692, 438], [724, 488], [726, 542], [620, 575], [600, 630], [540, 640], [505, 600], [512, 545]]
STALL_PX = [[707, 500], [737, 487], [796, 512], [794, 532], [788, 545], [776, 551], [818, 554], [817, 578], [776, 582], [760, 576], [710, 551], [706, 530]]
CRATE_PX = [[503, 718], [540, 698], [580, 716], [580, 753], [540, 770], [503, 751]]
JAR_PX = [[578, 748], [606, 734], [636, 748], [636, 776], [606, 790], [578, 773]]
TREES_PX = {  # árvores dentro do chão andável: copa (caixa da oval) + tronco (retângulo)
    "tree_1": {"crown": (812, 363, 900, 428), "trunk": (840, 418, 873, 450)},
    "tree_2": {"crown": (970, 470, 1052, 532), "trunk": (997, 522, 1027, 555)},
    "tree_3": {"crown": (160, 538, 228, 598), "trunk": (177, 590, 200, 617)},
    "tree_4": {"crown": (1390, 385, 1470, 455), "trunk": (1425, 444, 1443, 468)},
    "tree_5": {"crown": (1465, 445, 1530, 510), "trunk": (1485, 499, 1500, 520)},
}
POSTS_PX = {  # os quatro postes de luz da ponte
    "bridge_post_1": [[920, 586], [946, 586], [946, 652], [920, 652]],
    "bridge_post_2": [[974, 558], [1003, 558], [1003, 612], [974, 612]],
    "bridge_post_3": [[1049, 593], [1078, 593], [1078, 650], [1049, 650]],
    "bridge_post_4": [[994, 638], [1021, 638], [1021, 692], [994, 692]],
}
# Base no chão (onde o desenho encosta) de cada coisa pintada que vira recorte: o Tiro pode andar atrás dela pela
# estrada e o recorte, idêntico ao fundo, é desenhado por cima dele. Só a base bloqueia.
STALL_BASE_PX = [[708, 542], [760, 514], [822, 536], [822, 566], [782, 574], [716, 553]]  # chão sob caixotes e barris
TREE_BASES_PX = {"tree_1": (857, 447), "tree_2": (1012, 549), "tree_3": (190, 612), "tree_4": (1432, 464), "tree_5": (1492, 516)}
POST_BASES_PX = {"bridge_post_1": (933, 646), "bridge_post_2": (988, 606), "bridge_post_3": (1063, 644), "bridge_post_4": (1007, 686)}
# píer da lagoa + o poste de luz e a vara (o Tiro pesca da margem, ao lado dele)
PIER_PX = [[604, 800], [622, 770], [645, 772], [664, 800], [692, 838], [692, 886], [640, 902], [552, 872], [552, 838]]
# tabuleiro da ponte: fica livre mesmo com a margem do rio engordada
BRIDGE_PX = [[928, 616], [984, 592], [1072, 636], [1018, 676]]


def R(x: float, y: float) -> list[int]:
    """Coordenada do Figma -> sala."""
    return [round((x - FO[0]) * K), round((y - FO[1]) * K)]


SI = ILHA[2] / 1536.0  # px da ilha.png -> px do Figma


def P(ix: float, iy: float) -> list[int]:
    """Pixel da ilha.png -> sala."""
    return R(ILHA[0] + ix * SI, ILHA[1] + iy * SI)


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
    """Tira vértices quase colineares (o JSON fica curto)."""
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


def trace(cells: set) -> list:
    """Contorno externo (sentido horário) de uma região de células da grade, como lista de cantos."""
    edges = {}
    for x, y in cells:
        if (x, y - 1) not in cells:
            edges[(x, y)] = (x + 1, y)
        if (x + 1, y) not in cells:
            edges[(x + 1, y)] = (x + 1, y + 1)
        if (x, y + 1) not in cells:
            edges[(x + 1, y + 1)] = (x, y + 1)
        if (x - 1, y) not in cells:
            edges[(x, y + 1)] = (x, y)
    # (cantos com duas saídas só acontecem em diagonais; a região é dilatada antes, então é raro)
    start = min(edges)
    out = [start]
    cur = edges[start]
    guard = 0
    while cur != start and guard < 200000:
        out.append(cur)
        cur = edges[cur]
        guard += 1
    return out


def dp(points: list, tol: float) -> list:
    """Douglas-Peucker em polígono fechado."""
    def rec(pts):
        if len(pts) < 3:
            return pts
        a, b = pts[0], pts[-1]
        ab = math.dist(a, b) or 1e-9
        best, idx = 0.0, 0
        for i in range(1, len(pts) - 1):
            p = pts[i]
            d = abs((b[0] - a[0]) * (a[1] - p[1]) - (a[0] - p[0]) * (b[1] - a[1])) / ab
            if d > best:
                best, idx = d, i
        if best > tol:
            return rec(pts[: idx + 1])[:-1] + rec(pts[idx:])
        return [a, b]
    far = max(range(len(points)), key=lambda i: math.dist(points[0], points[i]))
    return rec(points[: far + 1])[:-1] + rec(points[far:] + [points[0]])[:-1]


def water_regions(ilha: Image.Image, carve: list, cell: int = 4, dilate: int = 6) -> list:
    """Água da ilha (azul) virando polígonos em px da ilha: o rio de cima da ponte e o de baixo com a lagoa.
    A água é engordada `dilate` células para cobrir as pedras e as taboas da margem; o polígono `carve` (a ponte) fica livre."""
    p = ilha.load()
    W, H = ilha.size
    m = Image.new("L", (W, H), 0)
    mp = m.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = p[x, y]
            if a > 200 and b > 150 and b > r + 40 and b > g + 5:
                mp[x, y] = 255
    m = m.filter(ImageFilter.MedianFilter(5))
    sm = m.resize((W // cell, H // cell), Image.BOX).point(lambda v: 255 if v > 60 else 0)
    sp = sm.load()
    cells = {(x, y) for y in range(sm.height) for x in range(sm.width) if sp[x, y]}
    for _ in range(dilate):
        cells |= {(x + dx, y + dy) for x, y in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))}
    cells = {c for c in cells if not inside(carve, ((c[0] + 0.5) * cell, (c[1] + 0.5) * cell))}
    seen: set = set()
    comps = []
    for c in sorted(cells):
        if c in seen:
            continue
        comp = {c}
        stack = [c]
        seen.add(c)
        while stack:
            x, y = stack.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in cells and n not in seen:
                    seen.add(n)
                    comp.add(n)
                    stack.append(n)
        if len(comp) > 60:
            comps.append(comp)
    polys = []
    for comp in sorted(comps, key=len, reverse=True):
        # tapa buracos (folhas de vitória-régia, pedrinhas) para o contorno externo ficar único
        xs = [c[0] for c in comp]
        ys = [c[1] for c in comp]
        box = {(x, y) for x in range(min(xs) - 1, max(xs) + 2) for y in range(min(ys) - 1, max(ys) + 2)}
        outside = set()
        st = [(min(xs) - 1, min(ys) - 1)]
        while st:
            q = st.pop()
            if q in outside or q not in box or q in comp:
                continue
            outside.add(q)
            st += [(q[0] + 1, q[1]), (q[0] - 1, q[1]), (q[0], q[1] + 1), (q[0], q[1] - 1)]
        full = box - outside
        ring = trace(full)
        ring = dp([(x * cell, y * cell) for x, y in ring], 2.5)
        polys.append(dict(poly=ring, cells=full, cell=cell))
    return polys


def main() -> None:
    debug = "--debug" in sys.argv
    # --- fundo: paisagem + a ilha por cima, no lugar do Figma ---
    fundo = Image.open(os.path.join(FIG, "fundo.png")).convert("RGBA")
    ilha = Image.open(os.path.join(FIG, "ilha.png")).convert("RGBA")
    cw, ch = round(FUNDO_W * K), round(FUNDO_H * K)
    cena = fundo.resize((cw, ch), Image.LANCZOS)
    iw, ih = round(ILHA[2] * K), round(ILHA[3] * K)
    cena.alpha_composite(ilha.resize((iw, ih), Image.LANCZOS), tuple(R(ILHA[0], ILHA[1])))
    cena = cena.convert("RGB")
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
    sign_img = sign.resize((sg, sg), Image.LANCZOS)
    sign_img.save(os.path.join(ART, "figma_compra.png"), optimize=True)
    # parte visível da placa (para a placa das construções ficar com a base no chão)
    sbx = sign_img.split()[3].getbbox()
    # bancada = a própria casa (decisão do Vitor): sem peça no Figma, o objeto é um recorte da casa idêntico ao fundo (nada novo
    # aparece ao comprar), que serve para o toque, a bandeja, o balão e para o Tiro passar atrás dela.
    hx = [q[0] for q in HOUSE_PX]
    hy = [q[1] for q in HOUSE_PX]
    bx0, by0, bx1, by1 = min(hx), min(hy), max(hx), max(hy)
    room_scale = SI * K
    btl = P(bx0, by0)
    bsw, bsh = round((bx1 - bx0) * room_scale), round((by1 - by0) * room_scale)
    full_ilha = ilha.resize((iw, ih), Image.LANCZOS)
    itl = R(ILHA[0], ILHA[1])
    bench = full_ilha.crop((btl[0] - itl[0], btl[1] - itl[1], btl[0] - itl[0] + bsw, btl[1] - itl[1] + bsh))
    from PIL import ImageDraw
    mask = Image.new("L", bench.size, 0)
    sil = [((q[0] - bx0) * room_scale, (q[1] - by0) * room_scale) for q in HOUSE_PX]
    ImageDraw.Draw(mask).polygon(sil, fill=255)
    bench.putalpha(Image.composite(bench.split()[3], Image.new("L", bench.size, 0), mask))
    bench.save(os.path.join(ART, "figma_bancada.png"), optimize=True)
    info["bancada"] = dict(w=bsw, h=bsh, tl=btl, pos=[btl[0] + bsw // 2, btl[1] + bsh])
    bed_w, bed_h = round((2 * BED_HW + 4) * room_scale), round((2 * BED_HH + 4) * room_scale)
    Image.new("RGBA", (bed_w, bed_h), (0, 0, 0, 0)).save(os.path.join(ART, "figma_canteiro_vazio.png"), optimize=True)

    # --- chão: losango da ilha (alfa), encolhido para não pisar nas árvores da borda ---
    al = ilha.split()[3].point(lambda v: 255 if v > 128 else 0)
    W, H = al.size
    px = al.load()
    cols = [x for x in range(0, W, 2) if any(px[x, y] for y in range(0, H, 2))]
    xmin, xmax = cols[0], cols[-1]

    def ys(x):
        c = [y for y in range(H) if px[x, y]]
        return c[0], c[-1]

    Lp = (xmin, sum(ys(xmin)) / 2)
    Rp = (xmax, sum(ys(xmax)) / 2)
    bot = max(range(xmin, xmax, 2), key=lambda x: ys(x)[1])
    Bp = (bot, ys(bot)[1])
    top = min(range(xmin, xmax, 2), key=lambda x: ys(x)[0])
    Tp = (top, ys(top)[0])
    print("L R B T", Lp, Rp, Bp, Tp)
    # contorno andável escolhido sobre a arte: logo abaixo da fileira de árvores da borda de cima e um pouco para dentro da
    # borda de terra de baixo (os cantos medidos acima servem de conferência)
    floor_px = [(40, 522), (95, 458), (785, 60), (1505, 505), (762, 998)]
    floor = [P(*q) for q in floor_px]

    # --- obstáculos pintados no fundo (casa, banca, caixote, pote, árvores e a água) ---
    waters = water_regions(ilha, BRIDGE_PX)
    obstacles = [
        {"id": "crate", "polygon": [P(*q) for q in CRATE_PX]},
        {"id": "jar", "polygon": [P(*q) for q in JAR_PX]},
        {"id": "pier", "polygon": [P(*q) for q in PIER_PX]},
    ]
    # o componente que tem a lagoa (o mais baixo) é o "lake"; o de cima da ponte é o rio
    waters.sort(key=lambda w: max(p[1] for p in w["poly"]), reverse=True)
    lake_w = waters[0]
    for i, w in enumerate(waters):
        obstacles.append({"id": "lake" if i == 0 else f"river_{i}", "polygon": [P(*q) for q in w["poly"]]})
    print("água:", [len(w["poly"]) for w in waters], "vértices")

    # --- canteiros: ficam no fundo; o objeto só guarda o losango, a planta e o balão ---
    objects: list[dict] = []
    bed_fp = []
    plot_pos = {}
    for idx, key in enumerate(PLOT_ORDER):
        cx, cy = BEDS[key]
        pos = P(cx, cy + BED_HH)  # meio da base do aro
        fp = [P(*q) for q in diamond(cx, cy, BED_HW - 4, BED_HH - 4)]  # o aro (o Tiro passa rente, os canteiros ficam atrás dele)
        bed_fp.append(fp)
        plot_pos[key] = P(cx, cy)
        # aproximação: o chão livre mais perto do próprio canteiro (abaixo de um canteiro do meio fica outro canteiro)
        objects.append({"id": f"plot_{idx}", "action": "plot", "plot": idx, "sprite": RES + "figma_canteiro_vazio.png", "always_behind": True, "pos": pos, "footprint": fp, "approach": P(cx, cy)})

    # --- placas "compra" dos canteiros: as sete do Figma, cada uma no canteiro mais próximo ---
    taken = set()
    for sx, sy in SIGNS:
        center = R(sx + SIGN_SIZE / 2, sy + SIGN_SIZE / 2)
        base = R(sx + SIGN_SIZE / 2, sy + SIGN_SIZE)
        best = min((k for k in PLOT_ORDER[2:] if k not in taken), key=lambda k: math.dist(plot_pos[k], center))
        taken.add(best)
        idx = PLOT_ORDER.index(best)
        objects.append({"id": f"sign_plot_{idx}", "action": "buy_sign", "sign_plot": idx, "sprite": RES + "figma_compra.png",
                        "pos": base, "footprint": [[base[0], base[1] - 12], [base[0] + 12, base[1] - 5], [base[0], base[1] + 2], [base[0] - 12, base[1] - 5]]})
        print("placa", base, "-> canteiro", idx, best)

    def sort_shift_for(obj: dict) -> int:
        """Ordem por Y na altura dos cantos laterais da base, não no pé do desenho: atrás dos lados só se chega com Y
        menor que esses cantos, e na frente (floreiras, degraus) o Tiro tem Y maior; assim a ordem por Y acerta os dois."""
        fp_ = obj["footprint"]
        left = min(fp_, key=lambda q: (q[0], -q[1]))
        right = max(fp_, key=lambda q: (q[0], q[1]))
        sort_y = max(left[1], right[1]) + 2
        return max(0, obj["pos"][1] - sort_y)

    # --- construções: o desenho do Figma no lugar exato; fechadas mostram a placa ---
    bases: dict[str, list] = {}
    old = json.load(open(os.path.join(ROOT, "tools", "art", "sitio_vovo", "isometrico", "scenario", "farm_antigo.json"), encoding="utf-8"))
    old_obj = {o["id"]: o for o in old["objects"]}
    order = ["bancada", "silo", "celeiro", "estufa", "galinheiro", "cural", "moinho", "lacticios"]
    ids = dict(OBJ, bancada="workbench")
    future = []
    sign_bottom = sg - sbx[3] if sbx else 0  # px transparentes embaixo da placa
    for nm in order:
        t = info[nm]
        oid = ids[nm]
        o = {k: v for k, v in old_obj[oid].items() if k in ("id", "action", "upgrade", "station", "label", "detail_label")}
        if nm == "bancada":
            fp = [P(*q) for q in HOUSE_BASE_PX]
        else:
            fp = simplify([[round(p[0]), round(p[1])] for p in base_polygon(t["im"], t["tl"], BAND[nm])])
        bases[nm] = fp
        o["sprite"] = RES + f"figma_{nm}.png"
        if nm == "estufa":
            o["greenhouse_indicator"] = True
        o["buy_sign"] = True
        o["pos"] = t["pos"]
        if nm == "bancada":
            o["footprint"] = fp
            o["sort_shift"] = sort_shift_for(o)
        o["footprint"] = fp
        o["label_pos"] = [t["pos"][0], t["tl"][1] + round(t["h"] * 0.25)]
        cx = sum(p[0] for p in fp) / len(fp)
        maxy = max(p[1] for p in fp)
        o["approach"] = [round(cx), maxy + 14]
        o = {k: o[k] for k in ["id", "action", "upgrade", "station", "route_group", "greenhouse_indicator", "buy_sign", "sprite", "pos", "sort_shift", "approach", "footprint", "label", "label_pos", "detail_label"] if k in o and not (k == "sort_shift" and not o[k])}
        objects.append(o)
        if nm in ("silo", "celeiro", "cural", "moinho"):
            o["silhouette"] = True
            front = sorted(fp, key=lambda point: point[1])[-2:]
            future.append({"id": oid, "polygon": fp, "gate": front,
                           "requirements": {"growth": "teething"}, "action": "week:later"})
        # placa no lugar da construção (centro da base, um pouco à frente)
        miny = min(p[1] for p in fp)
        sp_ = [round(cx), round((miny + maxy) / 2 + 14 + sign_bottom)]
        if nm == "bancada":
            sp_ = P(500, 560)  # a casa é a bancada: a placa fica ao lado, à esquerda da escadinha
            sp_[1] += sign_bottom
        objects.append({"id": f"sign_{oid}", "action": "buy_sign", "sign_upgrade": oid, "sprite": RES + "figma_compra.png", "pos": sp_, "footprint": diamond(sp_[0], sp_[1] - 6 - sign_bottom, 14, 9)})

    # Construções coladas no mesmo lote: no vão entre as duas o Tiro ficaria na frente de uma e atrás da outra ao mesmo
    # tempo (nenhuma ordem de desenho resolve). O vão vira chão bloqueado.
    for na, nb in (("moinho", "lacticios"), ("silo", "celeiro")):
        obstacles.append({"id": f"gap_{na}_{nb}", "polygon": simplify(hull(bases[na] + bases[nb]))})

    # --- recortes das coisas altas pintadas na ilha (casa, banca, árvores, postes) ---
    from PIL import ImageDraw as _Draw

    def cutout(name: str, silhouette, base: list) -> dict:
        shapes = [("poly", silhouette)] if isinstance(silhouette, list) else [("oval", silhouette["crown"]), ("rect", silhouette["trunk"])]
        pts = []
        for kind, sh in shapes:
            pts += sh if kind == "poly" else [[sh[0], sh[1]], [sh[2], sh[3]]]
        xs_ = [q[0] for q in pts]
        ys_ = [q[1] for q in pts]
        tl_ = P(min(xs_), min(ys_))
        br_ = P(max(xs_), max(ys_))
        w_, h_ = br_[0] - tl_[0], br_[1] - tl_[1]
        piece = full_ilha.crop((tl_[0] - itl[0], tl_[1] - itl[1], tl_[0] - itl[0] + w_, tl_[1] - itl[1] + h_))
        mask_ = Image.new("L", piece.size, 0)
        drw = _Draw.Draw(mask_)
        for kind, sh in shapes:
            if kind == "poly":
                drw.polygon([(P(*q)[0] - tl_[0], P(*q)[1] - tl_[1]) for q in sh], fill=255)
            else:
                a_, b_ = P(sh[0], sh[1]), P(sh[2], sh[3])
                box_ = [a_[0] - tl_[0], a_[1] - tl_[1], b_[0] - tl_[0], b_[1] - tl_[1]]
                (drw.ellipse if kind == "oval" else drw.rectangle)(box_, fill=255)
        piece.putalpha(Image.composite(piece.split()[3], Image.new("L", piece.size, 0), mask_))
        piece.save(os.path.join(ART, f"figma_corte_{name}.png"), optimize=True)
        obj = {"id": f"cut_{name}", "pass_tap": True, "sprite": RES + f"figma_corte_{name}.png",
               "pos": [tl_[0] + w_ // 2, tl_[1] + h_], "footprint": [P(*q) for q in base]}
        shift = sort_shift_for(obj)
        if shift > 0:
            obj["sort_shift"] = shift
        return obj


    cuts = [cutout("casa", HOUSE_PX, HOUSE_BASE_PX), cutout("banca", STALL_PX, STALL_BASE_PX)]
    for tid, poly in TREES_PX.items():
        bx_, by_ = TREE_BASES_PX[tid]
        cuts.append(cutout(tid, poly, diamond(bx_, by_, 13, 7)))
    for pid, poly in POSTS_PX.items():
        bx_, by_ = POST_BASES_PX[pid]
        cuts.append(cutout(pid, poly, diamond(bx_, by_, 11, 6)))
    objects.extend(cuts)
    # recortes que deixaram de existir saem (com o .import); os atuais mantêm o .import do Godot
    keep = {c["sprite"][len(RES):] for c in cuts}
    for f in os.listdir(ART):
        if f.startswith("figma_corte_") and f.endswith(".png") and f not in keep:
            for g in (f, f + ".import"):
                if os.path.exists(os.path.join(ART, g)):
                    os.remove(os.path.join(ART, g))

    # Pomar provisório no lote da estufa. A estufa retorna ao lote após Dentinhos.
    gh = info["estufa"]
    gfp = bases["estufa"]
    gx, gy = zip(*gfp)
    orchard_pos = [gh["pos"][0], gh["pos"][1] - 8]
    objects.append({"id": "orchard", "action": "place:orchard", "upgrade": "orchard",
                    "buy_sign": True, "sprite": RES + "orchard.png", "scale": 2.4, "footprint": gfp,
                    "pos": orchard_pos, "approach": [round(sum(gx) / len(gx)), max(gy) + 14]})
    front = sorted(gfp, key=lambda point: point[1])[-2:]
    future.append({"id": "orchard", "polygon": gfp, "gate": front,
                   "requirements": {"story_day": 7}, "action": "week:orchard",
                   "plaque": [orchard_pos[0], orchard_pos[1] - 30], "plaque_from": 6, "text": "Em breve"})
    front = sorted(bases["galinheiro"], key=lambda point: point[1])[-2:]
    future.append({"id": "chicken_coop", "polygon": bases["galinheiro"], "gate": front,
                   "requirements": {"story_day": 4}, "action": "week:coop",
                   "plaque": [info["galinheiro"]["pos"][0], max(p[1] for p in front) - 30], "plaque_from": 3, "text": "Em breve"})

    # carroça do Feirante: na estrada, junto à saída da ilha (depois da ponte)
    cart = P(1160, 690)
    objects.append({"id": "week_cart", "action": "place:week_cart",
                    "sprite": "res://assets/sprites/areas/village/stall.png",
                    "pos": cart, "scale": 0.9, "approach": [cart[0] - 26, cart[1] - 40],
                    "footprint": diamond(cart[0], cart[1] - 10, 34, 16),
                    "requirements": {"story_day": 9}})
    objects.append({"id": "week_cart_merchant", "action": "place:week_cart",
                    "sprite": "res://assets/sprites/characters/npc_merchant/portrait.png",
                    "pos": [cart[0] + 38, cart[1] - 7], "scale": 0.62,
                    "footprint": diamond(cart[0] + 38, cart[1] - 12, 14, 9),
                    "requirements": {"story_day": 9}})
    yard = P(400, 622)  # lote de grama à esquerda dos canteiros
    objects.append({"id": "week_yard", "action": "place:week_yard",
                    "sprite": "res://assets/sprites/areas/house/toy_basket.png",
                    "pos": yard, "approach": [yard[0] + 21, yard[1] + 9], "scale": 1.15,
                    "footprint": diamond(yard[0], yard[1] - 6, 16, 9),
                    "label": "Quintal do Tiro", "label_pos": [yard[0], yard[1] - 39]})
    training = info["lacticios"]["pos"]
    objects.append({"id": "week_training", "action": "place:week_training", "hidden_by": ["dairy"],
                    "requirements": {"story_day": 5}, "sprite": "res://assets/sprites/areas/house/paw_rug.png",
                    "pos": [training[0], training[1] + 11], "scale": 1.35, "sort_shift": 40})
    for npc, dx in (("bloblo", -35), ("lais", 35)):
        objects.append({"id": f"week_audience_{npc}", "action": "place:week_show", "hidden_by": ["dairy"],
                        "requirements": {"story_day": 10}, "scale": 1.25,
                        "sprite": f"res://assets/sprites/characters/npc_{npc}/walk/south/frame_00.png",
                        "pos": [training[0] + dx, training[1] - 18],
                        "footprint": diamond(training[0] + dx, training[1] - 24, 14, 9)})

    # --- animais: dentro dos cercados do Figma ---
    def spot(nm: str, fx: float, fy: float) -> list:
        t = info[nm]
        return [t["tl"][0] + round(fx * t["w"]), t["tl"][1] + round(fy * t["h"])]

    animals = [
        ("hen_1", "chicken_coop", 0, spot("galinheiro", 0.42, 0.66)), ("hen_2", "chicken_coop", 1, spot("galinheiro", 0.58, 0.62)),
        ("hen_3", "chicken_coop", 2, spot("galinheiro", 0.50, 0.75)), ("hen_4", "chicken_coop", 3, spot("galinheiro", 0.66, 0.70)),
        ("cow_1", "cow_barn", 0, spot("cural", 0.27, 0.60)), ("cow_2", "cow_barn", 1, spot("cural", 0.42, 0.54)),
        ("cow_3", "cow_barn", 2, spot("cural", 0.38, 0.68)), ("cow_4", "cow_barn", 3, spot("cural", 0.54, 0.66)),
    ]
    for aid, st, slot, p in animals:
        # hen_3/hen_4 e cow_3/cow_4 copiam o 1 do mesmo abrigo (o JSON antigo só tinha dois de cada)
        o = dict(old_obj.get(aid, old_obj[aid[:-1] + "1"]))
        o.update({"id": aid, "animal_slot": slot, "pos": p, "footprint": diamond(p[0], p[1], 14, 9), "approach": [p[0] + 18, p[1] + 10]})
        o.pop("scale", None)
        objects.append(o)

    # --- zonas de toque ---
    zones = [
        {"id": "early_market", "action": "place:early_market", "polygon": [P(*q) for q in [[706, 545], [740, 488], [790, 482], [826, 520], [826, 582], [772, 596], [710, 572]]], "label": "Vender Colheita", "label_pos": P(790, 548)},
        {"id": "bloblo_house", "action": "npc:bloblo", "polygon": [P(*q) for q in HOUSE_ZONE_PX], "label": "Bloblo", "label_pos": P(615, 370)},
    ]

    def lattice_hits(poly):
        xs_, ys_ = [q[0] for q in poly], [q[1] for q in poly]
        for gx_ in range(int(min(xs_)) // 8, int(max(xs_)) // 8 + 1):
            for gy_ in range(int(min(ys_)) // 8, int(max(ys_)) // 8 + 1):
                if inside(poly, (gx_ * 8 + 4, gy_ * 8 + 4)):
                    return True
        return False
    thin = [o["id"] for o in obstacles if not lattice_hits(o["polygon"])] + [o["id"] for o in objects if "footprint" in o and not lattice_hits(o["footprint"])]
    print("bases que o motor não enxergaria (pequenas demais):", thin or "nenhuma")
    # --- camadas impossíveis: o motor desenha quem anda por cima de tudo (z 1) só quando ele está na frente de todo
    # desenho que cobre o corpo dele; senão vale a ordem por Y. Onde ele estaria na frente de um desenho e atrás de outro
    # e a ordem por Y não acerta os dois, nenhuma ordem fica certa: essas células viram chão bloqueado.
    def front_y(poly, x):
        xs_ = [q[0] for q in poly]
        x = min(max(x, min(xs_)), max(xs_))
        best = -1e9
        for i in range(len(poly)):
            a_, b_ = poly[i], poly[(i + 1) % len(poly)]
            if (a_[0] - x) * (b_[0] - x) > 0:
                continue
            if a_[0] == b_[0]:
                best = max(best, a_[1], b_[1])
            else:
                best = max(best, a_[1] + (b_[1] - a_[1]) * (x - a_[0]) / (b_[0] - a_[0]))
        return best

    layered = []
    for o in objects:
        if "footprint" not in o or o.get("action") == "plot" or "animal_station" in o or not o["sprite"].startswith(RES):
            continue
        img = Image.open(os.path.join(ART, o["sprite"][len(RES):])).convert("RGBA")
        sc = float(o.get("scale", 1.0))
        if sc != 1.0:
            img = img.resize((round(img.width * sc), round(img.height * sc)), Image.NEAREST)
        x0_ = o["pos"][0] - img.width / 2
        y0_ = o["pos"][1] - img.height
        layered.append(dict(id=o["id"], a=img.split()[3].load(), w=img.width, h=img.height, x0=x0_, y0=y0_, y=o["pos"][1] - float(o.get("sort_shift", 0)), fp=o["footprint"]))

    def covers(L, box):
        for fx_ in (0.1, 0.5, 0.9):
            for fy_ in (0.1, 0.5, 0.9):
                lx = int(box[0] + box[2] * fx_ - L["x0"])
                ly = int(box[1] + box[3] * fy_ - L["y0"])
                if 0 <= lx < L["w"] and 0 <= ly < L["h"] and L["a"][lx, ly] > 128:
                    return True
        return False

    def never_together(a_, b_):  # a placa de uma construção some quando ela é comprada
        return a_ == "sign_" + b_ or b_ == "sign_" + a_

    conflict = set()
    fxs = [q[0] for q in floor]
    fys = [q[1] for q in floor]
    for gx in range(min(fxs) // 8, max(fxs) // 8 + 1):
        for gy in range(min(fys) // 8, max(fys) // 8 + 1):
            px_, py_ = gx * 8 + 4, gy * 8 + 4
            for tall in (34.0, 56.0):  # Tiro e personagens
                box = (px_ - 12, py_ - tall, 24, tall)
                cov = [L for L in layered if L["x0"] < box[0] + box[2] and box[0] < L["x0"] + L["w"] and L["y0"] < box[1] + box[3] and box[1] < L["y0"] + L["h"] and covers(L, box)]
                if len(cov) < 2:
                    continue
                rel = [(L, py_ > front_y(L["fp"], px_)) for L in cov]

                bad_ = False
                for i_ in range(len(rel)):
                    for j_ in range(len(rel)):
                        if i_ == j_ or never_together(rel[i_][0]["id"], rel[j_][0]["id"]):
                            continue
                        (A, fa), (B, fb) = rel[i_], rel[j_]
                        if fa and not fb:  # na frente de A, atrás de B: z 0, então precisa de Y maior que A e menor que B
                            if not (py_ > A["y"] and py_ < B["y"]):
                                bad_ = True
                if bad_:
                    conflict.add((gx, gy))

    if conflict:
        seen_c: set = set()
        nconf = 0
        for c0 in sorted(conflict):
            if c0 in seen_c:
                continue
            comp = {c0}
            st = [c0]
            seen_c.add(c0)
            while st:
                x, y = st.pop()
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if n in conflict and n not in seen_c:
                        seen_c.add(n)
                        comp.add(n)
                        st.append(n)
            ring = trace(comp)
            ring = [ring[i] for i in range(len(ring)) if (ring[i - 1][0] - ring[i][0]) * (ring[(i + 1) % len(ring)][1] - ring[i][1]) != (ring[i - 1][1] - ring[i][1]) * (ring[(i + 1) % len(ring)][0] - ring[i][0])]
            nconf += 1
            obstacles.append({"id": f"layer_{nconf}", "polygon": [[x * 8, y * 8] for x, y in ring]})
        print("camadas impossíveis bloqueadas:", nconf, "trechos,", len(conflict), "células")
    else:
        print("camadas impossíveis: nenhuma")

    # pior caso: tudo comprado e todos os enfeites da semana no mapa ao mesmo tempo
    blocked = [o["polygon"] for o in obstacles] + bed_fp + list(bases.values()) + [o["footprint"] for o in objects if "footprint" in o and not "animal_station" in o]

    # --- chão andável como o motor calcula (células de 8 px; só a maior região conectada) ---
    NAV, MARGIN = 8, 8
    fx = [p[0] for p in floor]
    fy = [p[1] for p in floor]
    offs = [(dx, dy) for dx in (-MARGIN, 0, MARGIN) for dy in (-MARGIN, 0, MARGIN)]  # bloco 3x3 (navigation_full_cell)
    boxes = [(min(p[0] for p in b), min(p[1] for p in b), max(p[0] for p in b), max(p[1] for p in b), b) for b in blocked]

    def hit(q):
        for x0, y0, x1, y1, b in boxes:
            if x0 <= q[0] <= x1 and y0 <= q[1] <= y1 and inside(b, q):
                return True
        return False

    free = set()
    for cy in range(min(fy) // NAV, max(fy) // NAV + 1):
        for cx in range(min(fx) // NAV, max(fx) // NAV + 1):
            c = (cx * NAV + NAV / 2, cy * NAV + NAV / 2)
            if all(inside(floor, (c[0] + dx, c[1] + dy)) and not hit((c[0] + dx, c[1] + dy)) for dx, dy in offs):
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
    # Bolsões de chão isolados (frestas entre canteiros, cantos cercados pelo rio): viram obstáculo, senão o Tiro ou um NPC
    # poderiam sortear um destino ali e ficar presos. O contorno passa pelas bordas das células, então não come o chão vizinho.
    pockets = free - best
    pseen: set = set()
    npocket = 0
    for cell0 in sorted(pockets):
        if cell0 in pseen:
            continue
        comp = {cell0}
        stack = [cell0]
        pseen.add(cell0)
        while stack:
            x, y = stack.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in pockets and n not in pseen:
                    pseen.add(n)
                    comp.add(n)
                    stack.append(n)
        ring = trace(comp)
        ring = [ring[i] for i in range(len(ring)) if (ring[i - 1][0] - ring[i][0]) * (ring[(i + 1) % len(ring)][1] - ring[i][1]) != (ring[i - 1][1] - ring[i][1]) * (ring[(i + 1) % len(ring)][0] - ring[i][0])]
        npocket += 1
        obstacles.append({"id": f"pocket_{npocket}", "polygon": [[x * NAV, y * NAV] for x, y in ring]})
    print("bolsões isolados fechados:", npocket, "(", len(pockets), "células )")

    def near(target):
        return min(cands, key=lambda c: (c[0] - target[0]) ** 2 + (c[1] - target[1]) ** 2)

    for o in objects:
        if "approach" in o and not "animal_station" in o:
            o["approach"] = list(near(o["approach"]))
    for o in objects:
        if "animal_station" in o:
            o["approach"] = list(near(o["pos"]))

    # o Tiro chega na estradinha entre a frente da casa e os canteiros (perto da horta, longe da banca)
    points = {"dog_start": list(near(P(632, 584))), "npc_bloblo": list(near(P(560, 585)))}

    # --- lagoa: zona tocável só na água da lagoa, ponto da pesca na margem e as bolhas ---
    cell = lake_w["cell"]
    pond_cells = [(x, y) for x, y in lake_w["cells"] if x * cell < 830 and y * cell > 795]
    pond_px = hull([(x * cell + cell / 2, y * cell + cell / 2) for x, y in pond_cells])
    lake_zone = [P(*q) for q in grow(pond_px, 0.85)]
    lcx = sum(p[0] for p in lake_zone) / len(lake_zone)
    lcy = sum(p[1] for p in lake_zone) / len(lake_zone)
    zones.append({"id": "lake", "action": "place:fishing", "polygon": lake_zone, "label": "Lagoa", "label_pos": [round(lcx), round(lcy)]})
    pier = P(628, 852)  # deck do píer, do lado da água
    future.append({"id": "lake", "polygon": lake_zone, "gate": [P(560, 800), P(760, 800)],
                   "requirements": {"story_day": 6}, "action": "place:fishing",
                   "plaque": [pier[0], pier[1] - 30], "plaque_from": 5, "text": "Em breve"})
    spot_xy = near(P(598, 792))  # margem de onde o Tiro entra no píer
    dx, dy = lcx - spot_xy[0], lcy - spot_xy[1]
    face = ("east" if dx > 0 else "west") if abs(dx) > abs(dy) else ("south" if dy > 0 else "north")
    points["fishing_spot"] = list(spot_xy)
    points["fishing_pier"] = pier
    points["fishing_face"] = face
    core = grow(lake_zone, 0.7)
    xs_, ys_ = [p[0] for p in core], [p[1] for p in core]
    inner = [(x, y) for x in range(min(xs_), max(xs_) + 1, 6) for y in range(min(ys_), max(ys_) + 1, 6)
             if inside(core, (x, y)) and math.dist((x, y), pier) > 70]
    bubbles = [min(inner, key=lambda c: math.dist(c, (lcx, lcy)))]
    while len(bubbles) < 4 and inner:
        bubbles.append(max(inner, key=lambda c: min(math.dist(c, b) for b in bubbles)))
    for i, b in enumerate(bubbles):
        points[f"fishing_bubble_{i + 1}"] = [b[0], b[1]]
    print("lagoa: ponto", spot_xy, face, "bolhas", bubbles)

    spots: list = []
    for tgt in [P(320, 470), P(620, 250), P(900, 300), P(1250, 560), P(1340, 460), P(460, 640), P(1020, 640), P(820, 520)]:
        c = near(tgt)
        if all(math.dist(c, s) > 90 for s in spots):
            spots.append(c)

    room = {
        "background": RES + "figma_cena.webp",
        "backdrop": {"sky": ["#c9b4e6", "#fbd9b0"], "ground": "#8a9a3e", "clouds": False},
        "floor": floor,
        "dig_spots": [list(s) for s in spots],
        "navigation_margin": 8,
        "main_floor_only": True,
        "navigation_full_cell": True,
        "dog_scale": 0.7, "region_shade": False, "region_fence": True,
        "animal_scale": 0.85,
        "depth_sort": True,
        "initial_zoom": 0.79,
        "min_zoom": 0.3, "background_bleed": [0, 0, 0, 0],
        "zoom_cover": True,
        "view_center": P(692, 600),
        "plot_signs": True,
        "obstacles": obstacles,
        "objects": objects,
        "zones": zones,
        "points": points,
        "regions": future,
    }
    with open(ROOM, "w", encoding="utf-8", newline="\n") as f:
        f.write(dumps(room) + "\n")
    print("ok", ROOM, "objetos:", len(objects), "dig:", len(spots))

    # --- verificações de conflito: tudo que o Tiro precisa alcançar tem que estar no chão andável conectado ---
    cs = {(round(c[0]), round(c[1])) for c in cands}
    problems = []
    named = {k: v for k, v in points.items() if isinstance(v, list) and not k.startswith("fishing_bubble_") and k != "fishing_pier"}
    for o in objects:
        if "approach" in o:
            named["approach:" + o["id"]] = o["approach"]
    for i, s in enumerate(spots):
        named[f"dig_{i}"] = list(s)
    for k, p in named.items():
        if tuple(p) not in cs:
            problems.append(k)
    for k, p in named.items():
        if hit(tuple(p)):
            problems.append(k + " (dentro de obstáculo)")
    print("pontos fora do chão andável conectado / dentro de obstáculo:", problems or "nenhum")

    if debug:
        dbg = cena.convert("RGBA")
        from PIL import ImageDraw
        d = ImageDraw.Draw(dbg, "RGBA")
        for b in blocked:
            d.polygon([tuple(p) for p in b], fill=(255, 0, 0, 90), outline=(255, 0, 0, 255))
        for z in zones:
            d.polygon([tuple(p) for p in z["polygon"]], outline=(255, 0, 255, 255))
        d.polygon([tuple(p) for p in floor], outline=(0, 0, 255, 255))
        for c in cands[::3]:
            d.point(c, fill=(0, 255, 0, 255))
        for cx, cy in free - best:  # bolsões isolados
            d.rectangle([cx * NAV, cy * NAV, cx * NAV + NAV - 1, cy * NAV + NAV - 1], fill=(255, 0, 255, 255))
        for k, p in named.items():
            d.ellipse([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=(255, 255, 0, 255), outline=(0, 0, 0, 255))
        for o in objects:
            if o["id"].startswith("sign_"):
                q = o["pos"]
                d.ellipse([q[0] - 4, q[1] - 4, q[0] + 4, q[1] + 4], fill=(0, 200, 255, 255))
        out = os.path.join(ROOT, "build", "farm_figma_debug.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        dbg.save(out)
        print("debug", out)


if __name__ == "__main__":
    sys.exit(main())
