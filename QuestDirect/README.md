# QuestDirect

A quest tracker for **World of Warcraft: Forever** that you can drag, resize and scale. Click a quest to focus it, and QuestDirect points TomTom's arrow at where you need to go next.

It also suggests **quests to pick up nearby**, and **Plan** lays out the whole zone: which quest givers to visit in which order, what to hand in and pick up at each, which objectives to do, and where to head once the zone is done.

## The tracker

| Do this | And |
|---|---|
| Drag the title bar | Move the tracker |
| Drag the bottom-right corner | Resize it |
| **Ctrl** + mouse wheel on the title bar | Scale it (0.5 to 2) |
| Mouse wheel on the list | Scroll |
| Click a zone heading | Collapse or expand that zone |
| **Lock** | Stop moving and resizing |
| **–** / **+** | Collapse the whole list to the title bar |
| **Zone** | Show only quests in the zone you're in |
| **Plan** | Plan this zone (below) |

Quests are grouped by zone, with **your current zone first**. Inside a zone, quests right for your level come first (see *How quests are ranked*), then nearest. Each quest shows its level in the game's difficulty colours (grey, green, yellow, orange, red), its distance, and its objectives; finished objectives are greyed out. Quests ready to hand in say **Ready to turn in**.

Position, size, scale and lock are saved for all your characters. Hidden quests, collapsed zones, the focused quest, dismissed suggestions and whether a plan is on are saved per character.

## Clicking a quest

| Click | Does |
|---|---|
| **Click** | Focus the quest and navigate to it. Click again to stop. |
| **Shift-click** | Link the quest in chat |
| **Right-click** | Menu: navigate or stop, open in the quest log, share with your party, hide from the tracker |
| Hover | Tooltip with every objective |

Focusing a quest does three things:

1. It becomes Blizzard's **focused (super-tracked) quest**, so the game's own map pin and on-screen distance follow it too. Focusing a quest on Blizzard's map or quest log works the other way and moves QuestDirect to it.
2. A **TomTom waypoint** is placed with the arrow pointing at it, plus pins on the world map and minimap.
3. It **picks the right spot**:
   - **In your zone:** the quest's objective area.
   - **Objectives done:** the turn-in. The arrow moves there by itself the moment the last objective completes.
   - **Another zone:** Blizzard's own next travel step (a flight master, a zone exit, a boat), so the arrow follows real paths rather than a straight line over mountains. When you reach a step, it moves on to the next one, then to the quest itself.

When you **turn in** the focused quest, QuestDirect focuses the next one: the next stop of your plan if you have one, otherwise the best next quest: one in this zone, right for your level, then nearest.

QuestDirect tells TomTom to switch off its own quest-objective waypoint while QuestDirect is loaded, so the two don't fight over the arrow. That's a per-session switch, so your TomTom settings don't change.

Without TomTom, QuestDirect uses Blizzard's own map pin instead (no arrow).

## Pick up nearby

At the top of the tracker, **Pick up nearby** lists the closest quests you can take right now (up to 5), with the quest giver's name and distance. A quest only shows if:

- you meet its level (nothing grey, nothing more than 3 levels above you);
- it's for your race and class;
- you've done the quest before it in the chain;
- it isn't in your log and you haven't done it.

**Click** a suggestion and the arrow points at its quest giver. **Right-click** to stop it being suggested. Hover for the level and where the suggestion came from.

When there's little left nearby, a **Then head to…** line suggests the next area: the zone with the most quests for your level, weighted by distance, and the quest giver to go to.

## Plan

**Plan** (or `/qd plan`) plans the zone you're in as a numbered list of stops:

- **Quest giver stops** show what to **Hand in** and what to **Pick up** there. If a hand-in unlocks a follow-up from the same giver, both are listed at that stop, hand-in first.
- **Do** stops show the next objectives of a quest.
- **Hand in elsewhere** lists finished quests that go back to another zone.
- **Then head to…** is the next area once the zone is done.

### How quests are ranked

Quests are put into four groups by level, and plans, **Pick up nearby**, the quest list and the next-quest key all use them in this order:

| Order | Which quests | Level, compared to yours |
|---|---|---|
| 1 | Right for your level, and anything ready to hand in | Up to 2 above, down to the grey line |
| 2 | Harder (orange) | 3 or 4 above |
| 3 | Too easy (grey) | Below the grey line |
| 4 | Far too hard (red) | 5 or more above |

So at level 12 a plan finishes your level 12 quests before a level 15, however close the level 15 is. It re-sorts when you level up. A quest the data says needs a group counts as harder unless you're in a group.

### The order of a plan

Inside each group, the order is the **shortest walk** that still makes sense:

- each objective comes before its hand-in;
- each hand-in comes before the follow-up it unlocks;
- **pick-ups and hand-ins lean early**: a quest giver that's only a little out of the way comes before an objective, so you leave town carrying everything you can do on the way. A big detour doesn't win, though.
- quests closest to your level (2 below to 1 above) get a small pull forward too;
- **pick-ups come from the whole zone**: the best for your level first, then nearest, up to the room left in your quest log. `/qd plan radius 900` limits them to quest givers within that many yards, and `/qd plan radius zone` goes back to the whole zone;
- a quest giver you can pick up from now and hand in to later is **two stops**, so a pick-up doesn't wait until you've finished something else;
- objectives within 40 yards of each other are one **Do** stop.

**The plan stays put.** The same situation always gives the same plan. When it re-plans (after a stop, or when you press Plan again) it keeps the order you had and slots anything new in where it fits best. It only reorders when that saves at least 60 yards or 4% of the walk. To start over from where you're standing, right-click a stop and choose **Re-plan from scratch**, or type `/qd plan fresh`. A new zone always plans from scratch.

The arrow points at the current stop (highlighted). When you finish a stop by handing in, picking up or completing the objective, QuestDirect plans again from where you're standing. That adds the objectives of the quests you just took. The quest list below numbers your quests in plan order.

**Click** a stop to go there now. **Right-click** to skip it, re-plan from scratch, or stop the plan. Entering a new zone plans that zone. Press **Plan** again to stop.

## Where the quest data comes from

1. **The game.** The game's own data on available quests is used when the client has it.
2. **You.** Quest givers you talk to are remembered: what they offered, where they stand, and where quests are handed in. These are saved for all your characters and win over the Classic data.
3. **Forever data from [ForeverDB.net](https://foreverdb.net)**, if you've made the file (below). What players saw in Forever: who gives and takes each quest and where they stand, Forever's new quests and zones, and corrected levels and titles.
4. **Classic quest data.** This covers 2,493 quests and 1,339 quest givers from the open-source CMaNGOS Classic database. It has levels, chains, races, classes, and giver and hand-in NPCs, placed on your maps by the game itself when you log in. Dungeon, raid, PvP, profession, holiday and repeatable quests are left out.

Forever may have changed some quests, so a Classic suggestion can be wrong. Right-click it to dismiss it.

### Adding the Forever data

Public copies of QuestDirect don't include ForeverDB's data, and QuestDirect works without it. To add it on your own PC, you need a ForeverDB API key and Python:

1. Run [ForeverSync](../ForeverSync/README.md) with your key. It takes about a minute.
2. From this repository's folder, make the file in your installed add-on (change the paths to match your PC):

```bash
python tools/foreverdb_extract.py "C:/path/to/ForeverSync/data" QuestDirect/QuestData.lua "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/QuestDirect/ForeverData.lua"
```

3. `/reload` in game. `/qd data` shows how many quests it added, the game build and the date. Repeat these steps now and then to pick up what players have seen since.

What changes with the file:

- **Quest givers and hand-ins** stand where players saw them, including NPCs and zones Classic doesn't have.
- **New quests** are suggested if ForeverDB says they're Forever's own. Dungeon, raid, PvP, profession and holiday quests aren't suggested, but QuestDirect can still find their hand-ins.
- **Your rules stay.** A quest the Classic data knows keeps its race, class and chain rules. New quests only say which side they're for, so QuestDirect works out the rest from the quest's category, its giver and the zone. A new quest can occasionally be wrong; right-click to dismiss it.
- **Follow-up quests can stay hidden.** For a new quest, "players were offered this after that one" counts as needing that one first, so a quest that doesn't really need it won't be suggested until you've done it. The game's own map data can still show it.
- **Every suggestion says where it's from:** *Seen in WoW Forever*, *From the Forever client* or Classic data. `/qd classic off` keeps what players saw and drops only the Classic suggestions.
- **Credit.** ForeverDB's terms ask for a visible credit, so **Data from ForeverDB.net (https://foreverdb.net)** shows at the bottom of the tracker and in tooltips. Keep it there, and don't share the file: the data is theirs.

**Forever's quest IDs differ from Classic's**, so QuestDirect matches quests by name:

- At login it reads the names of every quest this character has finished, so finished quests aren't suggested.
- If Forever's IDs turn out to be Classic's plus a fixed number, QuestDirect spots that and translates them.

`/qd data` shows what QuestDirect knows: how IDs are matched, how many finished quests it read, and your first few log quests next to the Classic quest each was matched to.

## Quest item buttons

Quests with an item to use (a bottle to fill, a totem to place, something to throw) get a button on a small bar next to the tracker. The focused quest's item comes first, then nearest first, up to 8. Hover a button for the item and which quest it's for. Cooldowns and charges show on the button. A finished quest's item goes away, unless the game says it's still needed.

- **Keybind**: "Use the first quest item (nearest quest)" in the keybindings below. Its key shows on the first button.
- **Moving it**: unlock the tracker, then drag the thin handle on the bar's left. `/qd items reset` puts it back next to the tracker.
- The game only lets add-ons use items through special buttons, and those can't be rearranged during combat. If a quest's items change mid-fight, the bar updates the moment combat ends; buttons already there keep working.

## Keybinds

In **Options → Keybindings → AddOns → QuestDirect**:

- Show or hide the tracker
- Focus the best next quest
- Stop navigating
- Plan this zone, or stop the plan
- Use the first quest item (nearest quest)

## Commands

| Command | Does |
|---|---|
| `/qd` | Show or hide the tracker |
| `/qd lock` / `unlock` | Stop or allow moving and resizing |
| `/qd scale 1.2` | Scale (0.5 to 2) |
| `/qd alpha 0.6` | Background opacity (0 to 1) |
| `/qd plan` | Plan this zone, or stop the plan (`/qd route` works too) |
| `/qd plan fresh` | Plan from scratch, ignoring the previous order |
| `/qd plan radius 900` | Only pick up quests within this many yards (`zone` for the whole zone, the default) |
| `/qd items` | Show or hide the quest item buttons (`/qd items reset` puts them back next to the tracker) |
| `/qd nearby` | Show or hide **Pick up nearby** |
| `/qd pickups` | Include pick-ups in plans or leave them out |
| `/qd grey` | Suggest grey quests too |
| `/qd above 3` | Suggest quests up to this many levels above you |
| `/qd classic off` | Don't use the Classic data, only what the game, you and players in Forever have seen (`on` to undo) |
| `/qd unignore` | Suggest quests you dismissed again |
| `/qd data` | What QuestDirect knows: quest data, Forever data and how old it is, quest givers placed, what it has learned |
| `/qd next` | Focus the best next quest for your level |
| `/qd clear` | Stop navigating |
| `/qd zone` | This zone's quests only (toggle) |
| `/qd blizzard on` / `off` | Show or hide Blizzard's own quest tracker |
| `/qd unhide` | Show quests you hid |
| `/qd reset` | Put the tracker back in its default spot and size |

## Good to know

- **Blizzard's quest tracker is hidden** while QuestDirect runs (`/qd blizzard on` brings it back). Its buttons for usable quest items are replaced by QuestDirect's own (below).
- Changes to Blizzard's tracker wait until you **leave combat**, because the game blocks them during combat.
- **Locations come from the game**: QuestDirect uses Blizzard's own quest pins and travel steps. A quest the game gives no map location shows **No map location for this quest** when focused.
- Quests under a heading you collapsed in Blizzard's quest log may not show until you expand it there.
- **Tested outside the game only**, against a stubbed WoW API with a mock TomTom and the real quest data placed on a mock Durotar (241 checks), plus 42 checks of the tool that makes the Forever data.
  - Tracker: order, focus, TomTom waypoints and arrow, travel steps, turn-ins, auto-next, scaling, resizing, locking, menus, links, filters, Blizzard focus sync, the no-TomTom fallback and combat safety.
  - Suggestions: race, class, level and chain rules, learning quest givers, dismissing, finished quests read by name, ID offset detection.
  - Forever data: laying it over the Classic data, the labels and credit in each place they show, new zones, sides and classes, `/qd classic off`, working without the file. Real ForeverDB data has been run through the tests too, but its map positions haven't been checked against the game.
  - Quest items: a button per quest with an item, item and charges from the quest log, focused quest first, keybind label, nothing rearranged or created in combat, update after combat, tooltip, cooldowns, finished quests' items removed, hiding the bar.
  - Plan: hand-in order, follow-up order, log room, one stop per giver, identical plans from the same spot, keeping the order when you move a little or toggle Plan, pick-ups leaning early but not past a big detour, the pick-up range, re-planning after pick-ups, skipping, and the next area.
  - Level ranking: the four groups and their edges, plans, pick-ups across the zone and with little log room, re-sorting on level-up, group quests, Pick up nearby, the quest list, the next-quest key, and the next zone.

  If anything errors in game, the Lua error text is what I need.

## Files

| File | Contents |
|---|---|
| `QuestDirect.toc` | Manifest (works with or without TomTom) |
| `Core.lua` | Settings, events, slash commands |
| `QuestData.lua` | Classic quest data (generated from CMaNGOS classic-db, GPL-2.0) |
| `Quests.lua` | Reads the quest log, distances, where each quest's next stop is |
| `Offers.lua` | Quests you can pick up: givers on the map, eligibility, learning, next area |
| `Nav.lua` | Focus, TomTom waypoints and arrow, travel steps |
| `Plan.lua` | The zone plan: stops, order, progress |
| `Tracker.lua` | The window, rows, menus, Blizzard tracker hiding |
| `Items.lua` | Quest item buttons |
| `Bindings.xml` | Keybinds |
