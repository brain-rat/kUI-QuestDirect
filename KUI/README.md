# kUI

A flat, dark look for the game's own windows, matching QuestDirect. It's built as the base for a bigger UI overhaul: every part uses the same shared style (`Style.lua`), so more windows can be added and they'll all match.

So far it covers your bags and bank, the loot window, tooltips, a rare and treasure scanner, junk selling and the minimap.

## Bags

**Untick Baganator and Baganator Sleek** in the AddOns list first. kUI bags stay off while Baganator is on, so the two never fight.

Press **B** as usual. One window holds all your bags:

- **Categories**: Quest, Equipment, Consumables, Trade Goods, Reagents, Recipes, Bags, Ammo, Keys, Miscellaneous, Junk.
  - New items you've just looted go in **New** at the top until you close your bags.
  - Small categories sit side by side when they fit, so the window stays compact.
  - Within a category, items are sorted best rarity first, then by type and name.
- **Every empty slot is shown at the bottom**, as real slots you can drop items into.
- **Rarity outline and inner glow** on every item: green, blue, purple, orange. Junk gets a softer grey. Common items get none, unless you turn that on.
- Stack counts in your chosen font, a gold **!** on items that start a quest, and an optional item level on gear.
- **Search** box: matches item names and types, such as "cloth" or "metal". Everything else dims.
- **Sort** button (if the game has bag sorting), money and slots used.
- Drag the title bar to move it.

Items are the game's own bag slots, so everything works as normal: click, drag, right-click to use or sell, Shift-click to link or split, tooltips.

### Bank

Talk to a banker and the bank opens in the same style next to your bags. It has its bank slots and bank bags, a **Buy bag slot** button while you have bank bag slots left to buy, and the same search. Closing either window closes the banker.

### Settings

Click **Settings** on the bag window, or type `/kui bags`. Press **-** / **+** (or **<** / **>**) and the change shows straight away:

| Setting | Default |
|---|---|
| Columns | 10 |
| Slot size | 36 |
| Horizontal gap (between slots side by side) | 4 |
| Vertical gap (between rows) | 4 |
| Gap between categories | 10 |
| Font | Barlow |
| Count size, heading size | 12, 12 |
| Text outline | Outline |
| Glow strength | 0.6 |
| Opacity, scale | 0.85, 1 |
| Categories, item level on gear, glow on common items | on, off, off |

### Fonts

The font is used everywhere in kUI: bags, loot window and minimap strip.

- **Bundled:** Barlow, Barlow Condensed, Rajdhani, Chakra Petch. All are free under the SIL Open Font Licence; the licences are in `Fonts/`.
- **The game's own:** Friz Quadrata, Arial Narrow, Skurri, Morpheus.
- **Other add-ons' fonts:** any font they share through LibSharedMedia shows up in the list too.

## Rare scanner

It does RareScanner's job in the kUI style. **Untick RareScanner** so you don't get two alerts.

### How it spots rares

- **The game's map markers for rares**, when the game shows them. These carry the rare's exact position.
- **Nameplates** as they come into view. Turn enemy nameplates on (**V** by default) and you'll spot rares at nameplate range.
- **Your target**, and anything you **mouse over**.
- Any NPC that's rare or rare elite counts, plus every rare in the Classic data even if Forever has changed how it's flagged.

### The alert

When it spots one, an alert drops in at the top of the screen and plays the raid-warning sound. If the game is in the background, its icon flashes.

The alert shows:

- the rare's **3D model** and **name**: silver-blue for rares, gold for rare elites;
- its **level** and **where it is**: zone, coordinates and distance;
- **Target**: targets it once it's in range. During combat this waits until combat ends, because the game only lets add-ons set that up out of combat.
- **Waypoint**: puts a waypoint on it, in TomTom if you have it, otherwise the game's own map pin.
- **Ignore**: never alert for this rare again.

When you target the rare it gets a **skull** (if you're solo, or the group leader or an assistant). When it dies the alert says so. The same rare won't alert again for 5 minutes. Drag the alert to move it.

### Map and list

- The **world map** shows where each Classic rare can spawn (331 rares, from the open-source CMaNGOS Classic database). Gold dots are rare elites, silver-blue are rares, and faded dots were killed in the last hour. Hover for level and when you last saw or killed it; click for a waypoint.
- **`/kui rares`** lists the rares in your zone, nearest first, with level, when you last saw each one and when you killed it. Click for a waypoint; right-click to ignore or un-ignore.
- Rares you've seen that aren't in the Classic data are added to the list too.

## Tooltips

Every tooltip (items, people, spells, the map) uses the flat dark panel, the kUI font and a thin flat health bar.

- **Item tooltips get a border in the item's rarity colour**: green, blue, purple, orange or grey. Common items keep the plain border.
- On items it adds:
  - **Item level** on gear, when the game doesn't show it.
  - **Vendor** price, when the game isn't already showing a sell price.
  - **Drops from (your loot record)**: the top three mobs, chests or nodes you've looted it from, with how often and out of how many loots, best chance first. This comes from GoldForever's recording of your play, so it needs GoldForever installed and fills in as you play.
- If GoldForever is installed, its auction lines still show underneath.

## Sell junk

Open a vendor and your grey items are sold automatically, then chat says what you made: "Sold 7 junk items for 1s 23c". It never repairs.

- Hold **Shift** while opening the vendor to skip it.
- It sells one item every 0.2 seconds and checks each slot again just before selling, so only greys are ever sold, never anything you've moved into that slot.
- Items with no sell value and items you're moving are left alone.

## Chests and world lootables

The rare scanner also covers things lying around to loot.

### On the map

- **Chests** (gold-brown dots): where Classic treasure chests can spawn. That covers Battered and Solid Chests, Footlockers, Strongboxes and named chests, 1,885 spots in all.
- **Finds** (green dots): Classic lootables such as Giant Clams, Un'Goro Power Crystals and Dirt Piles, Bloodpetal Sprouts and Half-Buried Bottles.
- **Everything you loot from the world is remembered** with where it was, shown as a slightly bigger dot. This is how Forever's new lootables, like the dinosaur hatchlings, get onto the map: loot one once and its spot is saved. Herbs, ore, fishing and skinning are left out.
- Dots fade for 15 minutes after you loot a spot, while it's probably still empty.

### Alerts

- **Walk within 40 yards of a spot where you've looted something before** (once it's had time to respawn) and you get an alert in the same style: green for finds, gold-brown for chests, with a **Waypoint** button.
  - These are on by default for finds; chests are off, since chests move between spawn points (`/kui rares chestnearby`).
- **The game's own treasure markers** alert too, if Forever shows them, and their spots are saved.
- A treasure alert never covers up a rare alert. If a rare is showing, the treasure goes to chat instead.

### The list

`/kui rares` has a **Treasures** tab. It lists what you've looted in this zone (how often, when last, how many spots) and then the Classic chest types found here. Click for a waypoint to the nearest one; right-click to ignore it.

## Loot window

The loot window is replaced with a QuestDirect-style one:

- a flat dark panel with a thin border, the corpse's name in the blue title strip, and **All** and **x** buttons;
- one row per item, with its icon, a **1px outline and inner glow in its rarity colour** (the same as the bags), and its name in that colour;
- a stack count on the icon, a **Quest** tag on quest items and **Starts a quest** on items that start one;
- locked items (someone else's roll, for example) greyed out.

| Do this | And |
|---|---|
| Click a row | Loot it |
| Shift-click | Link it in chat (Ctrl-click previews it) |
| **All** | Take everything |
| **x** or Esc | Close |
| Drag the title | Move it. The spot is saved. |

- If **Loot under mouse** is on in the game's options, the window opens at your cursor. Otherwise it opens where you last left it.
- With **auto loot**, the window only appears if something is left behind, so it doesn't flash on every kill.
- Bind-on-pickup warnings and group loot rolls still use the game's own popups.
- `/kui test` shows a sample window, so you can see the look without looting.

## Square minimap

- The minimap is **square**, with a 1px border.
- Removed: Blizzard's round frame, compass, zoom buttons, world-map button, zone banner and clock.
- A thin strip underneath shows the **zone** (green friendly, red hostile, orange contested, blue sanctuary) and your **coordinates**.
- Kept and moved to the corners: the mail, tracking, battleground and dungeon-queue icons.
- Other add-ons' minimap buttons are told the map is square, so they sit around its edge.

| On the minimap | Does |
|---|---|
| Mouse wheel | Zoom in and out |
| Right-click | Tracking menu (herbs, minerals and so on) |
| Middle-click | Calendar, if the game has one |
| Click the strip | World map |

## Commands

| Command | Does |
|---|---|
| `/kui` | Show settings |
| `/kui loot on` / `off` | Use the kUI loot window or the game's (needs `/reload`) |
| `/kui map on` / `off` | Square minimap or the game's (needs `/reload`) |
| `/kui bags on` / `off` | kUI bags or the game's (needs `/reload`) |
| `/kui bank on` / `off` | kUI bank window or the game's (needs `/reload`) |
| `/kui bags` | Open the bag settings |
| `/kui bags gapx 6` / `gapy 6` / `gap 6` | Horizontal, vertical or both gaps |
| `/kui bags cols 12` / `size 40` / `scale 1.1` | Columns, slot size, scale |
| `/kui bags categories` / `ilvl` | Turn categories or item level on gear on or off |
| `/kui bags reset` | Bag settings back to defaults |
| `/kui tooltips ilvl` / `vendor` / `drops` | Turn those tooltip lines on or off |
| `/kui tooltips on` / `off` | kUI tooltips or the game's (needs `/reload`) |
| `/kui junk on` / `off` | Sell junk at vendors on or off (needs `/reload`) |
| `/kui rares` | List the rares in your zone |
| `/kui rares test` | Show a sample alert |
| `/kui rares sound` / `flash` / `mark` / `pins` | Turn the sound, icon flash, skull or map dots on or off |
| `/kui rares treasures` | Alerts for the game's treasure markers on or off |
| `/kui rares chests` / `finds` | Chest dots or find dots on the map on or off |
| `/kui rares nearby` | Alerts near spots you've looted before on or off |
| `/kui rares chestnearby` | Include chests in those alerts (off by default) |
| `/kui rares range 40` | How close (yards) before a treasure alert |
| `/kui rares unignore` | Alert for every rare again |
| `/kui rares on` / `off` | Rare scanner on or off (needs `/reload`) |
| `/kui font rajdhani` | Pick the font (`/kui font` lists them) |
| `/kui alpha 0.85` | Panel opacity (0 to 1) |
| `/kui glow 0.6` | Rarity glow strength (0 to 1). `0` leaves just the outline. |
| `/kui common` | Turn a white glow on common items on or off |
| `/kui test` | Sample loot window |
| `/kui reset` | Put the loot window back in its default spot |

## Good to know

- **Tested outside the game only**, against a stubbed WoW API (152 checks).
  - Rares: Classic spawn points placed and pinned, nameplate, mouseover and map-marker alerts, normal mobs ignored, level and position, model, sound, flash, no repeats, skull on target, kills, waypoint, the target button waiting for combat to end, ignore, the zone list.
  - Tooltips: panel, hidden Blizzard frame, old-style backdrops, health bar, font, rarity border and its reset, item level, vendor price (and not when the game shows one), drop lines best-first with chests by name, turning lines off.
  - Junk: greys sold, no-value and locked items left alone, nothing else sold, the summary, Shift to skip, a slot that changed isn't sold.
  - Fonts: settings text redrawn after a font change, and back.
  - Treasures: Classic chests placed, world loots remembered by name and spot, gathering left out, chests told apart, repeat loots merged, map dots and tooltips, alerts near known spots (not while still empty, no repeats, never over a rare), the Treasures list.
  - Bags: a slot button for every bag slot, category order, empties at the bottom, horizontal and vertical gaps, categories side by side, rarity glow, quest marks, fonts, money, search by name and type, live settings, categories off, items moving, opening and closing from the game's bag keys, Blizzard's bag windows kept shut, the bank opening and closing with the banker.
  - Loot: rows, colours, glow, coins, quest tags, locked items, looting, linking, All, closing by **x** / Esc / the game, under-mouse placement, auto loot, the sample.
  - Minimap: square mask, hidden parts staying hidden, kept icons, zone colour, coordinates, zoom, tracking menu, world map.
  - Settings.
- The minimap part works with both Classic and modern minimap layouts. If a Blizzard piece is still showing on the minimap, send me a screenshot.
- If anything errors in game, the Lua error text is what I need.
- If using an item from your bags in combat ever shows "Interface action failed because of an AddOn", tell me. Bag add-ons occasionally hit that and it has a known fix.
- Not in yet: the bank's own row for equipping bank bags (`/kui bank off` and `/reload` gives you Blizzard's bank for that), the keyring, and custom categories.

## Files

| File | Contents |
|---|---|
| `KUI.toc` | Manifest |
| `Style.lua` | The shared look: panels, borders, buttons, rarity glow, fonts |
| `Core.lua` | Settings and `/kui` |
| `Loot.lua` | Loot window |
| `Minimap.lua` | Square minimap and info strip |
| `Bags.lua` | Bag and bank windows, categories, settings panel |
| `RareData.lua` | Classic rares, chests and finds with their spawn points (generated from CMaNGOS classic-db, GPL-2.0) |
| `Rares.lua` | Rare scanner: spotting, alert, map dots, list |
| `Treasures.lua` | Chests and world lootables: map dots, what you've looted, nearby alerts |
| `Tooltips.lua` | Tooltip style, rarity border, extra item lines |
| `Junk.lua` | Sells grey items at vendors |
| `Fonts/` | Bundled fonts and their licences |
