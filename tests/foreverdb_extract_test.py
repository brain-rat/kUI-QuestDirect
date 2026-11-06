"""Checks tools/foreverdb_extract.py against a small made-up quest list.

    python tests/foreverdb_extract_test.py
"""
import json, os, re, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import foreverdb_extract as fx

SEEN, CLASSIC, CLIENT = "seen in WoW Forever", "Classic data (CMaNGOS)", "Forever client (quest map marker)"
failed = passed = 0


def check(ok, label):
    global failed, passed
    if ok:
        passed += 1
    else:
        failed += 1
        print("  FAIL: " + label)


def person(pid, name, source, map_id=1411, x=10.0, y=20.0, kind="npc", players=1, others=(), instance=None):
    loc = {"uiMapId": map_id, "zone": "Z", "x": x, "y": y, "source": source} if map_id else None
    return {"type": kind, "id": pid, "name": name, "location": loc, "instance": instance, "source": source, "players": players, "others": list(others)}


def quest(qid, name, source="forever", side="h", category="Durotar", level=5, req=2, starts=None, ends=None, prev=()):
    return {"id": qid, "name": name, "level": level, "requiredLevel": req, "side": side, "category": category,
            "zone": {"n": category, "m": 1411}, "knownInForever": True, "source": source, "starts": starts, "ends": ends,
            "chain": {"previous": list(prev), "next": [], "questLine": None}}


def link(qid, relation, source=SEEN):
    return {"questId": qid, "relation": relation, "source": source, "name": "x"}


CLASSIC_FILE = """q[10]={"Old Title",5,2,178,0,"",0,0,0,"100","100"}
q[11]={"Same",5,2,178,0,"",0,0,0,"100","100"}
q[12]={"Chained \\"One\\"",5,2,178,0,"7",0,0,0,"100","100"}
q[13]={"No Chain",5,2,178,0,"",0,0,0,"100","100"}
q[14]={"Not Listed",5,2,178,0,"",0,0,0,"101","101"}
q[15]={"Marker Stays",5,2,178,0,"",0,0,0,"100","100"}
q[16]={"Classic Disagrees",5,2,178,0,"",0,0,0,"100","100"}
q[18]={"Classic Spot Used",5,2,178,0,"",0,0,0,"102","100"}
n[100]={"Gornek",1,"1,2"}
n[102]={"Classic Spot Only",1,"5,6"}
n[101]={"Stays Used",1,"3,4"}
"""

ROWS = [
    # Known quest: players saw a new giver, level and title.
    quest(10, "New Title", level=6, starts=person(200, "Seen Giver", SEEN, x=30.0, y=40.0, players=5), ends=person(100, "Gornek", CLASSIC)),
    # Known quest, nothing new: only the labels.
    quest(11, "Same", source="classic", starts=person(100, "Gornek", CLASSIC), ends=person(100, "Gornek", SEEN, x=11.0, y=22.0, players=2)),
    # Keeps its Classic chain; a seen one is only added where there's none.
    quest(12, 'Chained "One"', prev=[link(8, "Complete first")], starts=person(100, "Gornek", CLASSIC), ends=person(100, "Gornek", CLASSIC)),
    quest(13, "No Chain", prev=[link(9, "Complete first"), link(6, "Offered after")], starts=person(100, "Gornek", CLASSIC), ends=person(100, "Gornek", CLASSIC)),
    quest(15, "Marker Stays", starts=person(None, None, CLIENT, kind=None), ends=person(100, "Gornek", CLASSIC)),
    # A different giver that nobody saw in Forever changes nothing, and adds no spot.
    quest(16, "Classic Disagrees", source="classic", starts=person(102, "Classic Spot Only", CLASSIC), ends=person(100, "Gornek", CLASSIC)),
    quest(18, "Classic Spot Used", source="classic", starts=person(102, "Classic Spot Only", CLASSIC), ends=person(100, "Gornek", CLASSIC)),
    # Only ForeverDB knows these.
    quest(50, "Horde New", starts=person(201, "New Horde", SEEN, players=3, others=[person(202, "Other Seen", SEEN), person(203, "Other Classic", CLASSIC)]), ends=person(201, "New Horde", SEEN),
          prev=[link(40, "Complete first"), link(41, "Offered after"), link(42, "Must be active", CLASSIC), link(50, "Next quest")]),
    quest(51, "Alliance New", side="a", starts=person(204, "New Alliance", SEEN), ends=person(204, "New Alliance", SEEN)),
    quest(52, "Giver Says Horde", side="both", category="Stranglethorn Vale", starts=person(201, "New Horde", SEEN), ends=person(201, "New Horde", SEEN)),
    quest(53, "Home Zone", side="both", category="Elwynn Forest", starts=person(205, "Unknown", SEEN), ends=person(205, "Unknown", SEEN)),
    quest(54, "Contested", side="both", category="Stranglethorn Vale", starts=person(206, "Neutral", SEEN), ends=person(206, "Neutral", SEEN)),
    quest(55, "Class Quest", side="both", category="Paladin", starts=person(207, "Trainer", SEEN), ends=person(207, "Trainer", SEEN)),
    quest(56, "Race Quest", side="both", category="Night Elf", starts=person(208, "Elder", SEEN), ends=person(208, "Elder", SEEN)),
    quest(57, "Dungeon Quest", category="Gnomeregan", starts=person(209, "Skipped Giver", SEEN), ends=person(210, "Dungeon Hand-in", SEEN)),
    quest(58, "Holiday", category="Lunar Festival", starts=person(211, "Elder", SEEN), ends=None),
    quest(59, "From An Item", starts=person(16305, "Claw", CLASSIC, map_id=None, kind="item"), ends=person(212, "Item Hand-in", SEEN)),
    quest(60, "Marker Giver", starts=person(None, None, CLIENT, kind=None, x=52.5, y=53.0), ends=person(None, None, "seen in WoW Forever (players' game map)", kind=None, x=1.5, y=2.5)),
    quest(61, "Object Giver", starts=person(630696, "Catapult", SEEN, kind="object"), ends=person(213, "In Instance", SEEN, instance={"name": "Somewhere"})),
    quest(62, "No Level", level=None, starts=person(214, "Levelless", SEEN), ends=person(214, "Levelless", SEEN)),
    quest(63, "Camping 101: Blacksmithing", category="Camping", starts=person(216, "Camper", SEEN), ends=person(217, "Camp Hand-in", SEEN)),
    quest(64, "The Great Outdoors", category="Camping", starts=person(216, "Camper", SEEN), ends=person(216, "Camper", SEEN)),
    # One giver with quests for both sides: each quest's own side counts, "both" stays open.
    quest(65, "Mixed Alliance", side="a", category="Stranglethorn Vale", starts=person(218, "Neutral Giver", SEEN), ends=person(218, "Neutral Giver", SEEN)),
    quest(66, "Mixed Horde", side="h", category="Stranglethorn Vale", starts=person(218, "Neutral Giver", SEEN), ends=person(218, "Neutral Giver", SEEN)),
    quest(67, "Mixed Both", side="both", category="Stranglethorn Vale", starts=person(218, "Neutral Giver", SEEN), ends=person(218, "Neutral Giver", SEEN)),
    # Classic-labelled and only in ForeverDB: left out, as the Classic extract chose.
    quest(70, "Classic Only", source="classic", starts=person(215, "Left Out", CLASSIC), ends=person(215, "Left Out", CLASSIC)),
]

with tempfile.TemporaryDirectory() as tmp:
    with open(os.path.join(tmp, "quests_list.json"), "w", encoding="utf-8") as f:
        json.dump({"meta": {"build": "1.2.3", "total": len(ROWS)}, "data": ROWS}, f)
    classic = os.path.join(tmp, "QuestData.lua")
    with open(classic, "w", encoding="utf-8") as f:
        f.write(CLASSIC_FILE)
    out = os.path.join(tmp, "ForeverData.lua")
    fx.main(tmp, classic, out)
    text = open(out, encoding="utf-8").read()
    check(not os.path.exists(out + ".tmp"), "no temp file left behind")
    # Refuses what isn't the quest list.
    with open(os.path.join(tmp, "quests_list.json"), "w", encoding="utf-8") as f:
        json.dump({"meta": {}, "data": [{"id": 1}]}, f)
    try:
        fx.main(tmp, classic, out)
        check(False, "a list of the wrong shape stops it")
    except SystemExit:
        check(True, "a list of the wrong shape stops it")
    check(open(out, encoding="utf-8").read() == text, "and the file already there is left alone")
    # Failing halfway through writing leaves the old file whole.
    with open(os.path.join(tmp, "quests_list.json"), "w", encoding="utf-8") as f:
        json.dump({"meta": {"build": "1.2.3", "total": len(ROWS)}, "data": ROWS}, f)
    real_strftime = fx.time.strftime
    def broken(*a):
        raise OSError("disk full")
    fx.time.strftime = broken
    try:
        fx.main(tmp, classic, out)
        check(False, "a failure while writing is reported")
    except OSError:
        check(True, "a failure while writing is reported")
    fx.time.strftime = real_strftime
    check(open(out, encoding="utf-8").read() == text, "and the old file is still whole")

Q = {int(m[1]): m[2] for m in re.finditer(r"^q\[(\d+)\]=\{(.*)\}$", text, re.M)}
P = {int(m[1]): m[2] for m in re.finditer(r'^p\[(-?\d+)\]="(.*)"$', text, re.M)}
N = {int(m[1]): m[2] for m in re.finditer(r'^n\[(-?\d+)\]="(.*)"$', text, re.M)}

check("Data from ForeverDB.net (https://foreverdb.net)" in text.split("\n")[0], "the file's first line credits ForeverDB")
check('credit = "Data from ForeverDB.net (https://foreverdb.net)"' in text, "the credit the add-on shows is in the data")
check('build = "1.2.3"' in text, "build noted")
check(Q[10] == '"New Title",6,false,false,false,false,"200",false,1,0', "known quest takes what players saw, keeps the rest: " + Q[10])
check(Q[11] == "false,false,false,false,false,false,false,false,0,1", "nothing new: labels only: " + Q[11])
check(Q[12].split(",")[5] == "false", "a Classic chain stays")
check(Q[16].split(",")[6] == "false", "a Classic-labelled giver doesn't replace the known one: " + Q[16])
check(102 not in P, "and a known NPC isn't moved to a Classic-labelled spot")
check(Q[65].split(",")[3] == "77" and Q[66].split(",")[3] == "178", "a quest's own side wins over its giver's")
check(Q[67].split(",")[3] == "0", "a giver with both sides doesn't decide 'both'")
check(Q[13].split(",")[5] == '"9"', "a seen chain is added where there's none, and 'offered after' isn't enough for a known quest: " + Q[13])
check(Q[15].split(",")[6] == "false" and 900000015 not in P, "a map marker doesn't replace a known NPC")
check(14 not in Q and "Not Listed" not in text, "a Classic quest ForeverDB doesn't list isn't touched")
check(Q[50] == '"Horde New",5,2,178,0,"-42,40,41","201,202,203","201",1,1', "new quest: side, chain (not itself), every giver: " + Q[50])
check(Q[51].split(",")[3] == "77", "Alliance mask")
check(Q[52].split(",")[3] == "178", "'both' follows its giver's other quests")
check(Q[53].split(",")[3] == "77", "'both' in a home zone is that side's")
check(Q[54].split(",")[3] == "0", "'both' elsewhere stays open")
check(Q[55].split(",")[4] == "2", "class quest gets its class")
check(Q[56].split(",")[3] == "8", "race quest gets its race")
check(Q[57].split(",")[6] == '""' and Q[57].split(",")[7] == '"210"', "dungeon quest: no giver, hand-in kept")
check(209 not in P and 210 in P, "and its giver isn't placed")
check(58 not in Q, "nothing to offer or hand in: left out")
check(Q[59].split(",")[6] == '""' and Q[59].split(",")[7] == '"212"', "started by an item: no giver")
check(Q[60].split(",")[6] == '"900000060"' and Q[60].split(",")[7] == '"910000060"', "map markers stand in for unknown NPCs")
check(Q[60].endswith(",2,1"), "the client's marker and players' maps keep their own labels")
check(P[900000060] == "1411,52.5,53.0" and N[900000060] == "Quest giver" and N[910000060] == "Turn-in", "markers placed and named")
check(Q[61].split(",")[6] == '"-630696"', "object giver is negative")
check(213 not in P, "nothing inside an instance is placed")
check(Q[62].split(",")[6] == '""', "no level: not suggested")
check(Q[63].split(",")[6] == '""' and Q[63].split(",")[7] == '"217"', "a quest for one profession isn't suggested, its hand-in is kept")
check(Q[64].split(",")[6] == '"216"', "the rest of its category is")
check(70 not in Q and 215 not in P, "Classic-labelled quests only in ForeverDB stay out")
check(P[200] == "1411,30.0,40.0" and N[200] == "Seen Giver", "new NPC placed and named")
check(P[100] == "1411,11.0,22.0", "a Classic NPC moves only to where players saw it: " + P.get(100, ""))
check(P[203] == "1411,10.0,20.0", "a new NPC can use a Classic-labelled spot, there being no other")
check(100 not in N, "a name that's the same isn't repeated")

print("\n%d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
