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

Quests are grouped by zone, with **your current zone first** and each zone's quests **nearest first**. Each quest shows its level in the game's difficulty colours (grey, green, yellow, orange, red), its distance, and its objectives; finished objectives are greyed out. Quests ready to hand in say **Ready to turn in**.

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

When you **turn in** the focused quest, QuestDirect focuses the next one: the next stop of your plan if you have one, otherwise the nearest quest.

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

The order is the **shortest walk** that still makes sense:

- each objective comes before its hand-in;
- each hand-in comes before the follow-up it unlocks;
- **pick-ups and hand-ins lean early**: a quest giver that's only a little out of the way comes before an objective, so you leave town carrying everything you can do on the way. A big detour doesn't win, though.
- pick-ups are limited to the room left in your quest log and to quest givers within 900 yards of you (`/qd plan radius 900`);
- objectives within 40 yards of each other are one **Do** stop.

**The plan stays put.** The same situation always gives the same plan. When it re-plans (after a stop, or when you press Plan again) it keeps the order you had and slots anything new in where it fits best. It only reorders when that saves at least 60 yards or 4% of the walk. To start over from where you're standing, right-click a stop and choose **Re-plan from scratch**, or type `/qd plan fresh`. A new zone always plans from scratch.

The arrow points at the current stop (highlighted). When you finish a stop by handing in, picking up or completing the objective, QuestDirect plans again from where you're standing. That adds the objectives of the quests you just took. The quest list below numbers your quests in plan order.

**Click** a stop to go there now. **Right-click** to skip it, re-plan from scratch, or stop the plan. Entering a new zone plans that zone. Press **Plan** again to stop.

## Where the quest data comes from

1. **The game.** The game's own data on available quests is used when the client has it.
2. **You.** Quest givers you talk to are remembered: what they offered, where they stand, and where quests are handed in. These are saved for all your characters and win over the Classic data.
3. **Classic quest data.** This covers 2,493 quests and 1,339 quest givers from the open-source CMaNGOS Classic database. It has levels, chains, races, classes, and giver and hand-in NPCs, placed on your maps by the game itself when you log in. Dungeon, raid, PvP, profession, holiday and repeatable quests are left out.

Forever may have changed some quests, so a Classic suggestion can be wrong. Right-click it to dismiss it.

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
- Focus the nearest quest
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
| `/qd plan radius 900` | Only pick up quests within this many yards |
| `/qd items` | Show or hide the quest item buttons (`/qd items reset` puts them back next to the tracker) |
| `/qd nearby` | Show or hide **Pick up nearby** |
| `/qd pickups` | Include pick-ups in plans or leave them out |
| `/qd grey` | Suggest grey quests too |
| `/qd above 3` | Suggest quests up to this many levels above you |
| `/qd classic off` | Don't use the Classic data, only what the game and you have seen (`on` to undo) |
| `/qd unignore` | Suggest quests you dismissed again |
| `/qd data` | What QuestDirect knows: quest data, quest givers placed, what it has learned |
| `/qd next` | Focus the nearest quest |
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
- **Tested outside the game only**, against a stubbed WoW API with a mock TomTom and the real quest data placed on a mock Durotar (120 checks).
  - Tracker: order, focus, TomTom waypoints and arrow, travel steps, turn-ins, auto-next, scaling, resizing, locking, menus, links, filters, Blizzard focus sync, the no-TomTom fallback and combat safety.
  - Suggestions: race, class, level and chain rules, learning quest givers, dismissing, finished quests read by name, ID offset detection.
  - Quest items: a button per quest with an item, item and charges from the quest log, focused quest first, keybind label, nothing rearranged or created in combat, update after combat, tooltip, cooldowns, finished quests' items removed, hiding the bar.
  - Plan: hand-in order, follow-up order, log room, one stop per giver, identical plans from the same spot, keeping the order when you move a little or toggle Plan, pick-ups leaning early but not past a big detour, the pick-up range, re-planning after pick-ups, skipping, and the next area.

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
