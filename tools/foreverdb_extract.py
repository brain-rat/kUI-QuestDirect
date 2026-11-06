"""Turn what ForeverSync downloaded into QuestDirect's ForeverData.lua.

    python foreverdb_extract.py <ForeverSync data folder> <QuestDirect\\QuestData.lua> <out ForeverData.lua>

Write the output into your installed add-on folder, not this repository: ForeverDB's
data is theirs and isn't redistributed here. QuestDirect works without the file.

The file is an overlay on the Classic data:
  - quests also in the Classic data keep its race, class and chain rules, and take
    what players saw in Forever (giver, hand-in, level, title);
  - quests only ForeverDB knows are added when ForeverDB says they're Forever's own
    ("source": "forever"). Dungeon, raid, PvP, profession and holiday quests are added
    without a giver: never suggested, but their hand-ins are still known;
  - every quest keeps its label: seen in WoW Forever, the Forever client, or Classic data.
"""
import json, os, re, sys, time
from collections import Counter, defaultdict

ALLIANCE, HORDE = 77, 178
CLASSES = {"Warrior": 1, "Paladin": 2, "Hunter": 4, "Rogue": 8, "Priest": 16, "Shaman": 64,
           "Mage": 128, "Warlock": 256, "Druid": 1024}
RACES = {"Human": 1, "Orc": 2, "Dwarf": 4, "Night Elf": 8, "Undead": 16, "Tauren": 32, "Gnome": 64, "Troll": 128}
# Quests in these categories aren't suggested, the same rule as the Classic data.
NOT_SUGGESTED = {
    "", "Ragefire Chasm", "Wailing Caverns", "The Deadmines", "Shadowfang Keep", "Blackfathom Deeps", "The Stockade",
    "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon",
    "Sunken Temple", "Blackrock Mountain", "Blackrock Depths", "Blackrock Spire", "Dire Maul", "Stratholme",
    "Scholomance", "Zul'Gurub", "Molten Core", "Blackwing Lair", "Ahn'Qiraj", "Ahn'Qiraj War", "Naxxramas",
    "Ruins of Lordaeron", "City of Dalaran", "Dalaran", "Excavation Site: Wetlands", "The Hall of Thanes",
    "Warsong Gulch", "Arathi Basin", "Alterac Valley", "Darkspear Islands",
    "Lunar Festival", "Seasonal", "Midsummer", "Invasion", "Special", "Legendary", "Epic",
    "Alchemy", "Blacksmithing", "Cooking", "Crafting", "Enchanting", "Engineering", "First Aid", "Fishing",
    "Herbalism", "Leatherworking", "Mining", "Skinning", "Tailoring",
}
# One of these for each profession, so most wouldn't apply to you.
NOT_SUGGESTED_TITLE = re.compile(r"^Camping 101:")
# A "both" quest in one side's home zone is that side's, when its giver doesn't say.
HOME = {
    "Durotar": HORDE, "Orgrimmar": HORDE, "Mulgore": HORDE, "Thunder Bluff": HORDE, "Tirisfal Glades": HORDE,
    "Undercity": HORDE, "Silverpine Forest": HORDE, "The Barrens": HORDE,
    "Elwynn Forest": ALLIANCE, "Stormwind City": ALLIANCE, "Westfall": ALLIANCE, "Redridge Mountains": ALLIANCE,
    "Duskwood": ALLIANCE, "Dun Morogh": ALLIANCE, "Ironforge": ALLIANCE, "Loch Modan": ALLIANCE,
    "Teldrassil": ALLIANCE, "Darnassus": ALLIANCE, "Darkshore": ALLIANCE,
}
MARKER_GIVER, MARKER_ENDER = 900000000, 910000000
MAX_SPOTS = 3


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def label(source):
    """1 seen in WoW Forever, 2 the Forever client, 0 Classic data or unknown."""
    source = source or ""
    if source.startswith("seen in WoW Forever"):
        return 1
    if source.startswith("Forever client"):
        return 2
    return 0


def who(person):
    """QuestDirect's id for an NPC or object; items and map markers have none."""
    if not person or person.get("id") is None:
        return None
    return {"npc": person["id"], "object": -person["id"]}.get(person.get("type"))


def read_classic(path):
    text = open(path, encoding="utf-8").read()
    quests = {}
    for m in re.finditer(r'^q\[(\d+)\]=\{"((?:[^"\\]|\\.)*)",(-?\d+),(-?\d+),\d+,\d+,"([^"]*)",-?\d+,-?\d+,\d+,"([^"]*)","([^"]*)"\}', text, re.M):
        quests[int(m[1])] = dict(title=m[2].replace('\\"', '"').replace("\\\\", "\\"), level=int(m[3]), min=int(m[4]),
                                 pre=m[5], givers=m[6], enders=m[7])
    npcs = {}
    for m in re.finditer(r'^n\[(-?\d+)\]=\{"((?:[^"\\]|\\.)*)"', text, re.M):
        npcs[int(m[1])] = m[2].replace('\\"', '"').replace("\\\\", "\\")
    if not quests or not npcs:
        sys.exit("Couldn't read the quest data in " + path)
    return quests, npcs


def ids(s):
    return [int(x) for x in re.findall(r"-?\d+", s)]


def main(data_dir, classic_path, out_path):
    quests, npcs = read_classic(classic_path)
    listing = json.load(open(os.path.join(data_dir, "quests_list.json"), encoding="utf-8"))
    rows = listing["data"]
    if not rows or "starts" not in rows[0]:
        sys.exit("quests_list.json doesn't look like ForeverDB's quest list.")
    build = (listing.get("meta") or {}).get("build") or "?"

    # Which side each giver is on, from the quests that say.
    votes = defaultdict(set)
    for r in rows:
        if r.get("side") in ("a", "h"):
            g = who(r.get("starts"))
            if g:
                votes[g].add(r["side"])

    def side_mask(r):
        if r.get("side") == "a":
            return ALLIANCE
        if r.get("side") == "h":
            return HORDE
        v = votes.get(who(r.get("starts")))
        if v and len(v) == 1:
            return ALLIANCE if "a" in v else HORDE
        return HOME.get(r.get("category")) or HOME.get((r.get("zone") or {}).get("n")) or 0

    out_q, names, spots = {}, {}, defaultdict(dict)
    used = set()
    report = Counter()

    def note_spot(pid, person, flag, classic_known):
        loc = person.get("location")
        if not loc or person.get("instance") or loc.get("x") is None or loc.get("uiMapId") is None:
            return
        if flag == 0 and classic_known:
            return  # the Classic data has its spawn points already
        best = spots[pid].get(loc["uiMapId"])
        rank = (flag > 0, person.get("players") or 0)
        if not best or rank > best[0]:
            spots[pid][loc["uiMapId"]] = (rank, loc["x"], loc["y"])

    def people(r, side):
        p = r.get(side) or {}
        return [p] + list(p.get("others") or [])

    for r in rows:
        qid = r["id"]
        old = quests.get(qid)
        if not old and r.get("source") != "forever":
            report["left_out_classic_only_in_foreverdb"] += 1
            continue
        starts, ends = r.get("starts") or {}, r.get("ends") or {}
        seen_g, seen_e = label(starts.get("source")), label(ends.get("source"))
        givers, enders = [], []
        for side, dest, base in (("starts", givers, MARKER_GIVER), ("ends", enders, MARKER_ENDER)):
            for p in people(r, side):
                flag = label(p.get("source"))
                pid = who(p)
                if pid:
                    # A known quest only changes to what players actually saw.
                    if not old or flag:
                        dest.append(pid)
                    if p.get("name"):
                        names[pid] = p["name"]
                    note_spot(pid, p, flag, pid in npcs)
                elif p.get("location") and p.get("type") is None and not (old and (old["givers"] if base == MARKER_GIVER else old["enders"])):
                    # No NPC known: the game's own map marker, or where players' maps showed it.
                    pid = base + qid
                    dest.append(pid)
                    names[pid] = "Quest giver" if base == MARKER_GIVER else "Turn-in"
                    note_spot(pid, p, flag, False)

        if old:
            report["known_quests"] += 1
            title = r["name"] if r.get("source") == "forever" and r.get("name") and r["name"] != old["title"] else False
            level = r["level"] if r.get("level") is not None and r["level"] != old["level"] else False
            minl = r["requiredLevel"] if r.get("requiredLevel") is not None and r["requiredLevel"] != old["min"] else False
            g = ",".join(map(str, givers)) if givers and set(givers) != set(ids(old["givers"])) else False
            e = ",".join(map(str, enders)) if enders and set(enders) != set(ids(old["enders"])) else False
            pre = False
            if not old["pre"]:
                # Only where the Classic data has no chain: its own rules are more exact.
                seen_pre = [c["questId"] for c in r["chain"]["previous"] if label(c.get("source")) and c["relation"] in ("Complete first", "Next quest", "Chain link")]
                if seen_pre:
                    pre = ",".join(map(str, sorted(set(seen_pre))))
            out_q[qid] = (title, level, minl, False, False, pre, g, e, seen_g, seen_e)
            for key, v in (("titles_changed", title), ("levels_changed", level), ("givers_changed", g), ("enders_changed", e), ("chains_added", pre)):
                if v is not False:
                    report[key] += 1
            used.update(ids(g or old["givers"]))
            used.update(ids(e or old["enders"]))
        else:
            cat = r.get("category") or ""
            suggest = cat not in NOT_SUGGESTED and r.get("level") is not None and not NOT_SUGGESTED_TITLE.match(r.get("name") or "")
            if not suggest or not givers:
                givers = []
            if not givers and not enders:
                report["left_out_no_giver_or_hand_in"] += 1
                continue
            report["new_suggested" if givers else "new_hand_in_only"] += 1
            pre = set()
            for c in r["chain"]["previous"]:
                if c["relation"] == "Must be active":
                    pre.add(-c["questId"])
                elif c["relation"] in ("Complete first", "Chain link", "Next quest", "Offered after", "Quest line"):
                    pre.add(c["questId"])
            pre.discard(qid)
            title = r.get("name") or ""
            if not title:
                continue
            out_q[qid] = (title, r.get("level") or 0, r.get("requiredLevel") or 0, RACES.get(cat) or side_mask(r), CLASSES.get(cat, 0),
                          ",".join(map(str, sorted(pre))), ",".join(map(str, givers)), ",".join(map(str, enders)), seen_g, seen_e)
            used.update(givers)
            used.update(enders)
    # Classic quests ForeverDB doesn't list still use their NPCs.
    for qid, old in quests.items():
        if qid not in out_q:
            report["classic_quests_not_in_foreverdb"] += 1
            used.update(ids(old["givers"]))
            used.update(ids(old["enders"]))

    def lua_val(v):
        if v is False:
            return "false"
        if isinstance(v, str):
            return lua_str(v)
        return str(v)

    tmp = out_path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- QuestDirect: Forever quest data. Data from ForeverDB.net (https://foreverdb.net).\n")
        f.write("-- Made on your PC by tools/foreverdb_extract.py from what ForeverSync downloaded. Not for redistribution.\n")
        f.write("-- q[id] = { title, level, minLevel, raceMask, classMask, \"prereqs\", \"givers\", \"enders\", giverLabel, enderLabel }\n")
        f.write("--   false = keep the Classic value. Labels: 0 Classic data, 1 seen in WoW Forever, 2 the Forever client.\n")
        f.write("-- n[id] = name   p[id] = \"uiMapId,x%,y%;...\"\n")
        f.write("local _, ns = ...\nlocal q, n, p = {}, {}, {}\n")
        f.write("ns.ForeverData = { q = q, n = n, p = p, build = %s, made = %s, credit = \"Data from ForeverDB.net (https://foreverdb.net)\" }\n" % (
            lua_str(build), lua_str(time.strftime("%Y-%m-%d", time.gmtime(os.path.getmtime(os.path.join(data_dir, "quests_list.json")))))))
        for qid in sorted(out_q):
            f.write("q[%d]={%s}\n" % (qid, ",".join(lua_val(v) for v in out_q[qid])))
        for pid in sorted(names):
            if pid in used and names[pid] != npcs.get(pid):
                f.write("n[%d]=%s\n" % (pid, lua_str(names[pid])))
                report["npc_names"] += 1
        for pid in sorted(spots):
            if pid in used:
                best = sorted(spots[pid].items(), key=lambda kv: kv[1][0], reverse=True)[:MAX_SPOTS]
                f.write("p[%d]=\"%s\"\n" % (pid, ";".join("%d,%.1f,%.1f" % (m, s[1], s[2]) for m, s in best)))
                report["npc_positions"] += 1
    os.replace(tmp, out_path)
    print(json.dumps(dict(sorted(report.items())), indent=1))
    print("Wrote %s (build %s). Data from ForeverDB.net." % (out_path, build))


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:4])
