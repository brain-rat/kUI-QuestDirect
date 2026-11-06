"""Extract herb, ore and fishing-school spawn points from the CMaNGOS Classic
database dump and write GoldForever's ClassicNodes.lua data file.

    python3 cmangos_extract.py <ClassicDB_*.sql.gz> <out ClassicNodes.lua> <out report.json>

Spawn points are world coordinates (map 0 = Eastern Kingdoms, 1 = Kalimdor).
GoldForever converts them to zone map positions in game with the client's own
map API, so no map tables need shipping.
"""
import gzip, json, re, sys
from collections import defaultdict

WANT = {
    "gameobject": ["guid", "id", "map", "position_x", "position_y"],
    "gameobject_template": ["entry", "type", "name", "data1"],
    "gameobject_loot_template": ["entry", "item", "ChanceOrQuestChance", "groupid", "mincountOrRef", "maxcount"],
    "item_template": ["entry", "class", "subclass", "name", "Quality"],
    "gameobject_spawn_entry": ["guid", "entry"],
    "reference_loot_template": ["entry", "item", "ChanceOrQuestChance", "groupid", "mincountOrRef", "maxcount"],
}

def parse_values(s, i):
    """Yield tuples from an INSERT ... VALUES (...),(...); string starting at i."""
    n = len(s)
    while i < n:
        while i < n and s[i] != "(":
            if s[i] == ";":
                return
            i += 1
        i += 1
        row, cur, inq = [], [], False
        while i < n:
            c = s[i]
            if inq:
                if c == "\\":
                    cur.append(s[i + 1]); i += 2; continue
                if c == "'":
                    if i + 1 < n and s[i + 1] == "'":
                        cur.append("'"); i += 2; continue
                    inq = False; i += 1; continue
                cur.append(c); i += 1; continue
            if c == "'":
                inq = True; i += 1; continue
            if c == ",":
                row.append("".join(cur)); cur = []; i += 1; continue
            if c == ")":
                row.append("".join(cur)); i += 1; break
            cur.append(c); i += 1
        yield row

def load(path):
    cols, rows = {}, defaultdict(list)
    table, colnames = None, []
    with gzip.open(path, "rt", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.match(r"CREATE TABLE `(\w+)` \(", line)
            if m:
                table, colnames = m.group(1), []
                continue
            if table and line.startswith("  `"):
                colnames.append(line.split("`")[1])
                continue
            if table and line.startswith(")"):
                cols[table] = colnames
                table = None
                continue
            m = re.match(r"INSERT INTO `(\w+)` VALUES ", line)
            if m and m.group(1) in WANT:
                t = m.group(1)
                idx = [cols[t].index(c) for c in WANT[t]]
                for r in parse_values(line, m.end()):
                    rows[t].append([r[k] for k in idx])
    return rows

def main(src, out_lua, out_report):
    rows = load(src)
    items = {int(r[0]): {"class": int(r[1]), "sub": int(r[2]), "name": r[3], "q": int(r[4])} for r in rows["item_template"]}
    templates = {int(r[0]): {"type": int(r[1]), "name": r[2], "loot": int(r[3])} for r in rows["gameobject_template"]}
    refs = defaultdict(list)
    for e, item, chance, group, mn, mx in rows["reference_loot_template"]:
        refs[int(e)].append((int(item), float(chance), int(group), int(mn), int(mx)))
    loot = defaultdict(list)
    for e, item, chance, group, mn, mx in rows["gameobject_loot_template"]:
        mn = int(mn)
        if mn < 0:
            # A reference: the node drops whatever reference table -mn holds (e.g. Sungrass, Dreamfoil).
            for r in refs.get(-mn, []):
                if r[3] > 0:
                    loot[int(e)].append((r[0], r[1] or float(chance), r[2], r[3], r[4]))
            continue
        loot[int(e)].append((int(item), float(chance), int(group), mn, int(mx)))

    # Which node types are herbs, ore or fishing schools, and their main material.
    # In 1.12 ores and stones are plain Trade Goods (class 7, subclass 0); herbs are subclass 9.
    kinds = {}
    for entry, t in templates.items():
        if t["type"] not in (3, 25):
            continue
        drops = [(it, ch, g) for it, ch, g, mn, mx in loot.get(t["loot"], []) if mn > 0 and it in items]
        if not drops:
            continue
        name = t["name"]
        if re.search(r"chest|box|crate|trunk|cache", name, re.I):
            continue
        if t["type"] == 25:
            cat = "Fish"
            cands = [d for d in drops if not (items[d[0]]["class"] == 7 and items[d[0]]["sub"] == 9)]
            if not cands:
                continue
        elif re.search(r"Vein|Deposit", name):
            cat = "Ore"
            cands = [d for d in drops if items[d[0]]["class"] == 7 and (d[1] >= 100 or items[d[0]]["name"].endswith("Ore"))] or drops
        elif t["type"] == 3 and (any(items[it]["class"] == 7 and items[it]["sub"] == 9 for it, _, _ in drops)
                                 or any(items[it]["class"] == 7 and items[it]["name"] == name for it, _, _ in drops)):
            # Herb nodes: 1.12 tags some herbs (Purple Lotus, Sungrass...) as plain trade goods,
            # so a node that drops a trade good with its own name counts too.
            cat = "Herb"
            same = [d for d in drops if items[d[0]]["name"] == name]
            cands = same or [d for d in drops if items[d[0]]["class"] == 7 and d[1] >= 50]
            if not cands:
                continue  # quest objects that only sometimes hold a herb
        else:
            continue
        # Main material: highest stated chance (a guaranteed drop is 100), then lowest item id.
        main = sorted(cands, key=lambda x: (-x[1], x[0]))[0][0]
        kinds[entry] = {"cat": cat, "node": name, "item": main, "itemName": items[main]["name"],
                        "yields": [{"item": it, "name": items[it]["name"], "chance": ch if ch > 0 else None, "min": mn, "max": mx}
                                   for it, ch, g, mn, mx in loot.get(t["loot"], []) if mn > 0 and it in items]}

    # Spawns on the two classic continents only.
    # Spawn points that roll between several node types (e.g. a thorium, mithril or truesilver spot).
    alt = defaultdict(set)
    for guid, entry in rows["gameobject_spawn_entry"]:
        alt[int(guid)].add(int(entry))
    points = defaultdict(list)  # (map, item, cat) -> [(x, y)]
    per_node = defaultdict(int)
    shared = 0
    for guid, gid, mp, x, y in rows["gameobject"]:
        guid, gid, mp = int(guid), int(gid), int(mp)
        if mp not in (0, 1):
            continue
        entries = alt.get(guid) or {gid}
        mats = {}
        for e in entries:
            if e in kinds:
                mats[(kinds[e]["item"], kinds[e]["cat"])] = e
        if len(mats) > 1:
            shared += 1
        for (item, cat), e in mats.items():
            points[(mp, item, cat)].append((round(float(x), 1), round(float(y), 1)))
            per_node[e] += 1

    # Merge exact duplicates (several node types sharing a spot, e.g. pooled herbs).
    out = ["-- GoldForever · Classic node data (generated, do not edit)",
           "-- Herb, ore and fishing-school spawn points from the CMaNGOS Classic database",
           "-- (github.com/cmangos/classic-db, ClassicDB 1.12.1 " + src.split("_")[-1].split(".")[0] + ").",
           "-- These are every point a node CAN spawn at in Classic, not all at once,",
           "-- and Forever may have moved some. World coordinates: map 0 Eastern Kingdoms, 1 Kalimdor.",
           "-- Game data is Blizzard's; CMaNGOS provides it for non-commercial use. Personal use only.",
           "local _, ns = ...", "ns.ClassicNodes = {"]
    total = 0
    by_item = defaultdict(lambda: {"cat": None, "name": None, "points": 0, "maps": set()})
    for (mp, item, cat), pts in sorted(points.items()):
        uniq = sorted(set(pts))
        total += len(uniq)
        enc = ";".join(f"{x:.1f},{y:.1f}" for x, y in uniq)
        out.append(f'  {{ {mp}, {item}, "{cat}", "{enc}" }},')
        b = by_item[(item, cat)]
        b["cat"], b["name"] = cat, items[item]["name"]
        b["points"] += len(uniq)
        b["maps"].add(mp)
    out.append("}")
    with open(out_lua, "w") as f:
        f.write("\n".join(out) + "\n")

    report = {
        "source": src.split("/")[-1],
        "totalPoints": total,
        "materials": sorted(({"item": i[0], **{k: (sorted(v) if isinstance(v, set) else v) for k, v in b.items()}} for i, b in by_item.items()),
                            key=lambda r: (r["cat"], r["name"])),
        "nodeTypes": sorted(({"entry": e, "spawns": per_node[e], **k} for e, k in kinds.items() if per_node[e]),
                            key=lambda r: (r["cat"], r["node"])),
    }
    with open(out_report, "w") as f:
        json.dump(report, f, indent=1)
    print(f"{len(kinds)} node types, {total} spawn points ({shared} shared between materials), {len(by_item)} materials")
    for r in report["materials"]:
        print(f"  {r['cat']:5} {r['name']:28} {r['points']:5} points  maps {r['maps']}")

if __name__ == "__main__":
    main(*sys.argv[1:4])
