"""Extract quests, quest givers and turn-in NPCs from the CMaNGOS Classic database
dump and write QuestDirect's QuestData.lua.

    python3 quest_extract.py <ClassicDB_*.sql.gz> <out QuestData.lua> <out report.json>

Positions are world coordinates (map 0 = Eastern Kingdoms, 1 = Kalimdor);
QuestDirect places them on zone maps in game with the client's own map API.
"""
import json, sys
from collections import defaultdict, Counter
import cmangos_extract as cx

ALLIANCE = 1 | 4 | 8 | 64      # Human, Dwarf, Night Elf, Gnome
HORDE = 2 | 16 | 32 | 128      # Orc, Undead, Tauren, Troll
CLASS_SORTS = {-61, -81, -82, -141, -161, -162, -261, -262, -263}
SKIP_TYPES = {41, 62, 81}      # PvP, raid, dungeon
MAX_SPAWNS = 3

cx.WANT = {
    "quest_template": ["entry", "ZoneOrSort", "MinLevel", "QuestLevel", "Type", "RequiredClasses",
                       "RequiredRaces", "RequiredSkill", "SpecialFlags", "PrevQuestId", "NextQuestId",
                       "ExclusiveGroup", "BreadcrumbForQuestId", "NextQuestInChain", "Title"],
    "creature_questrelation": ["id", "quest"],
    "creature_involvedrelation": ["id", "quest"],
    "gameobject_questrelation": ["id", "quest"],
    "gameobject_involvedrelation": ["id", "quest"],
    "creature": ["guid", "id", "map", "position_x", "position_y"],
    "creature_template": ["Entry", "Name", "Faction"],
    "gameobject": ["guid", "id", "map", "position_x", "position_y"],
    "gameobject_template": ["entry", "type", "name", "data1"],
}


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def main(src, out_lua, out_report):
    rows = cx.load(src)
    report = Counter()

    # Spawns on the two continents only (instances can't be walked to on the map).
    spawns = defaultdict(list)  # key: +creature id / -gameobject id
    for _, cid, mp, x, y in rows["creature"]:
        if mp in ("0", "1"):
            spawns[int(cid)].append((int(mp), float(x), float(y)))
    for _, gid, mp, x, y in rows["gameobject"]:
        if mp in ("0", "1"):
            spawns[-int(gid)].append((int(mp), float(x), float(y)))
    names = {int(r[0]): r[1] for r in rows["creature_template"]}
    ctemplate = {int(r[0]): int(r[2]) for r in rows["creature_template"]}
    names.update({-int(r[0]): r[2] for r in rows["gameobject_template"]})

    givers, enders = defaultdict(set), defaultdict(set)
    for t, sign, dest in (("creature_questrelation", 1, givers), ("gameobject_questrelation", -1, givers),
                          ("creature_involvedrelation", 1, enders), ("gameobject_involvedrelation", -1, enders)):
        for i, q in rows[t]:
            dest[int(q)].add(sign * int(i))

    quests = {}
    for r in rows["quest_template"]:
        (entry, sort, minl, lvl, typ, classes, races, skill, special, prev, nxt, excl, bread, chain, title) = r
        quests[int(entry)] = dict(id=int(entry), sort=int(sort), min=int(minl), lvl=int(lvl), type=int(typ),
                                  classes=int(classes), races=int(races), skill=int(skill), special=int(special),
                                  prev=int(prev), next=int(nxt), excl=int(excl), bread=int(bread),
                                  chain=int(chain), title=title.strip())

    # Prerequisites: PrevQuestId plus every quest whose NextQuestId points here (sign kept).
    pre = defaultdict(set)
    for q in quests.values():
        if q["prev"]:
            pre[q["id"]].add(q["prev"])
        if q["next"]:
            target = abs(q["next"])
            pre[target].add(q["id"] if q["next"] > 0 else -q["id"])

    # Which side an NPC belongs to, from the race masks of the quests it gives;
    # then the same for every NPC sharing its faction template.
    side_votes = defaultdict(Counter)
    npc_side = {}
    for qid, gs in givers.items():
        q = quests.get(qid)
        if not q or not q["races"]:
            continue
        s = "A" if q["races"] & ALLIANCE and not q["races"] & HORDE else "H" if q["races"] & HORDE and not q["races"] & ALLIANCE else None
        for g in gs:
            side_votes[g][s] += 1
    for g, votes in side_votes.items():
        if len(votes) == 1 and None not in votes:
            npc_side[g] = next(iter(votes))
    tmpl_votes = defaultdict(Counter)
    for g, s in npc_side.items():
        if g > 0 and g in ctemplate:
            tmpl_votes[ctemplate[g]][s] += 1
    tmpl_side = {t: v.most_common(1)[0][0] for t, v in tmpl_votes.items() if len(v) == 1 and sum(v.values()) >= 2}

    def side_mask(npcs):
        sides = set()
        for g in npcs:
            s = npc_side.get(g) or (tmpl_side.get(ctemplate.get(g)) if g > 0 else None)
            sides.add(s)
        if sides == {"A"}:
            return ALLIANCE
        if sides == {"H"}:
            return HORDE
        return 0

    kept, used_npcs = [], set()
    for qid in sorted(quests):
        q = quests[qid]
        gs = [g for g in givers.get(qid, ()) if spawns.get(g)]
        if not q["title"]:
            report["skip_no_title"] += 1; continue
        if not gs:
            report["skip_no_giver_on_map"] += 1; continue
        if q["special"] & 1:
            report["skip_repeatable"] += 1; continue
        if q["skill"]:
            report["skip_profession"] += 1; continue
        if q["type"] in SKIP_TYPES:
            report["skip_dungeon_raid_pvp"] += 1; continue
        if q["sort"] < 0 and q["sort"] not in CLASS_SORTS:
            report["skip_seasonal_or_profession"] += 1; continue
        races = q["races"] or side_mask(gs)
        es = [e for e in enders.get(qid, ()) if spawns.get(e)]
        q["eff_races"] = races
        q["givers"], q["enders"] = gs, es
        q["pre"] = sorted(pre.get(qid, ()))
        kept.append(q)
        used_npcs.update(gs)
        used_npcs.update(es)
        report["kept"] += 1
        report["kept_alliance" if races == ALLIANCE else "kept_horde" if races == HORDE else "kept_other"] += 1

    with open(out_lua, "w", encoding="utf-8") as f:
        f.write("-- QuestDirect · quest data, generated by quest_extract.py from the CMaNGOS\n")
        f.write("-- Classic database (GPL-2.0, github.com/cmangos/classic-db). Do not edit by hand.\n")
        f.write("-- q[id] = { title, level, minLevel, raceMask, classMask, \"prereqs\", exclusiveGroup,\n")
        f.write("--           breadcrumbFor, type, \"givers\", \"enders\" }  (NPC ids; negative = object)\n")
        f.write("-- n[id] = { name, continent (0 EK, 1 Kalimdor), \"x,y;x,y\" world positions }\n")
        f.write("local _, ns = ...\nlocal q, n = {}, {}\nns.QuestData = { q = q, n = n, source = \"cmangos classic-db z2815\" }\n")
        for qd in kept:
            f.write("q[%d]={%s,%d,%d,%d,%d,\"%s\",%d,%d,%d,\"%s\",\"%s\"}\n" % (
                qd["id"], lua_str(qd["title"]), qd["lvl"], qd["min"], qd["eff_races"], qd["classes"],
                ",".join(map(str, qd["pre"])), qd["excl"], qd["bread"], qd["type"],
                ",".join(map(str, sorted(qd["givers"]))), ",".join(map(str, sorted(qd["enders"])))))
        for g in sorted(used_npcs):
            pts = spawns[g][:MAX_SPAWNS]
            mp = pts[0][0]
            coords = ";".join("%.1f,%.1f" % (x, y) for m, x, y in pts if m == mp)
            f.write("n[%d]={%s,%d,\"%s\"}\n" % (g, lua_str(names.get(g, "?")), mp, coords))
    report["npcs"] = len(used_npcs)
    report["templates_with_side"] = len(tmpl_side)
    with open(out_report, "w") as f:
        json.dump(report, f, indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main(*sys.argv[1:4])
