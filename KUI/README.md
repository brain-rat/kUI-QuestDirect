# kUI

A flat, dark look for the game's own windows, matching QuestDirect. It's built as the base for a bigger UI overhaul: every part uses the same shared style (`Style.lua`), so more windows can be added and they'll all match.

So far it covers the player and target frames, the castbar, action bars, your bags and bank, the loot window, tooltips, a rare and treasure scanner, junk selling and the minimap.

## Player and target frames

Flat frames in the shared style replace Blizzard's player, target, target-of-target and pet frames.

- **Header strip:** name, level and status. Your name is in the accent colour. A target's name and health bar use its reaction colour: red hostile, yellow neutral, green friendly, grey if someone else has tagged it.
- **Status tags:** Combat, Rested, Lead and PvP on you. Elite, Rare, Rare Elite, Boss and PvP on your target. A raid marker shows next to the name.
- **Health bar:** percent on the left, `current / max` on the right, or Dead, Ghost or Offline. Players use their class colour (`/kui frames class` for plain green).
- **Power bar:** in that power's colour, with `current / max`.
- **Clicks:** left-click targets, right-click opens the game's unit menu. Click-cast add-ons can see the frames.
- **Target's buffs and debuffs** sit above its frame, debuffs first, up to 16. Debuff borders show the dispel type, and your own are in the accent colour.
- **Combo points** are five pips under the player frame. Rogues always have them, and Druids see them while they have points.
- **Totems:** Blizzard's totem frame is kept and sits above the player frame. It keeps Blizzard's look for now.
- **Elites, rares and bosses** get a coloured border and soft glow on the target frame: gold for elites, silver-blue for rares, red for bosses.
- Portraits are off by default. Turn them on in the edit mode.

## Castbar

- **Your bar:** spell icon, name, time left and a thin spark.
- **Target's bar:** sits above the target frame, and the target's buffs and debuffs move up to make room while it shows.
- **Colours:** sky blue for casts, green for channels, grey for spells you can't interrupt. A failed or interrupted cast flashes red with the reason.
- `/kui castbar test` runs a sample cast, so you can check the look without casting.

## Action bars

Flat, square bars replace the game's: up to eight action bars (as many as the client has), plus the stance, pet and Shaman totem bars, the menu and bag buttons, and XP and reputation bars. Your spells and keys stay where they are, because the bars use the game's own action slots and key bindings.

- **The look:** cropped square icons on a dark slot with a thin border. No end caps or other artwork.
- **Which bars start on:** Bar 1, any bar the game was showing, and any bar with something on it. After that it's your choice.
- **What still works:** paging with Shift and a number, stance and form pages, drag and drop, cast on key down, cooldowns, charges, procs and the game's vehicle bar.
- **Out of range** icons turn red. An equipped item gets a green border.
- **Empty slots** can be hidden. They come back while you hold a spell, even in combat, so you can see where it can go.

**Quick keybinds:** type `/kui keys`, or use the minimap menu or the **Quick keybinds** button in the edit mode. This is the game's own quick keybind mode, and it works on every kUI bar, including the menu and bag buttons. Hover a button, press a key, mouse button or wheel, then click **Okay** to save or **Cancel** to undo. Esc clears a button's key. Every bar and empty slot shows while it's open, so you can bind what's normally hidden. Entering combat closes it and drops keys you hadn't saved. It also works if you open it from the game's settings.

`/kui bars` opens the edit mode on the **Action bars** tab. Pick a bar at the top of the tab, or click its overlay. Everything else on the tab changes that bar. Every slider has a box for typing an exact value: Enter or Tab or clicking away keeps it, and Esc puts it back. Typed values stay between the slider's limits but don't have to land on one of its steps, so a scale of 1.23 is fine:

| Setting | What it does |
|---|---|
| Show this bar | Turns the bar on or off. An off bar gives its keys back to the game |
| Buttons, buttons per row | How many buttons, and how they wrap |
| Button size, gap across, gap between rows, scale | Size and spacing |
| Fill rows to the, add rows going | Which way the buttons run |
| Show | Always, on hover, only in combat, or only out of combat |
| Opacity, opacity when faded | How solid it is, and how far it fades on hover |
| Empty slots | Show or hide slots with nothing in them |
| Key bindings, macro names, stack counts | Each can be off, and each has its own size |
| Cooldown numbers, number size | The countdown on the icon |
| Border | The thin border around each button |

The **All bars** card has red icons out of range and the proc glow. **Copy look to all bars** gives every other bar on this tab this bar's size, gaps, scale, text and visibility, but not its position or number of buttons. **Reset this frame** puts the picked bar back to its default look and spot.

**The totem bar** has the same flat buttons, with a border in each totem's colour: fire, earth, water and air. It sets its size, gaps, rows, text and visibility the same way. A spell or totem you don't have yet doesn't leave a gap. Totem keys stay the game's own, and the flyout that picks a totem still opens above each button.

**Menu and bag buttons, and the XP and reputation bars,** have their own **Menu, bags, XP** tab. Pick a bar at the top, or click its overlay:

| Setting | What it does |
|---|---|
| Show this bar | Turns the buttons on or off. The keys that open your windows and bags work either way |
| Buttons per row, button size, gaps, scale, fill and rows | The same layout as any bar |
| Show, opacity, opacity when faded | The same visibility as any bar |
| Border | The thin border around each button |
| Grey menu icons | Menu icons in grey, or the game's colours |
| Menu buttons | Take any menu button off the bar. The others close up |
| Bag slots, reagent bag, key ring | Take these off the bag bar. The backpack always stays |
| Free bag slots, free slots size | The count on the backpack |
| Width, height | The size of the XP or reputation bar |
| Numbers, number size | Your XP or standing on the bar: always, on hover, or off |
| Rested XP | The lighter part past the end of your XP |

A menu button lights up while its window is open, and the game's alerts still flash on it. The menu goes back to the game for its vehicle bar and pet battles, and comes back afterwards.

The XP bar steps aside at top level or with XP turned off. The reputation bar shows the faction you're watching, in its standing's colour, and steps aside when you aren't watching one. It starts at the top of the screen, out of the way of your action bars. Clicks pass through either bar unless its numbers are set to show on hover.

`/kui bars off` and `/reload` give you the game's bars back.

## Edit mode

Click the **minimap icon** and choose **Edit mode**, or type **`/kui edit`**. Every frame gets a blue overlay, and a settings window opens with a tab for each frame: Player, Target, Target of target, Pet, Castbar and Action bars. Settings are grouped into cards, with sliders (the mouse wheel works on them too), switches and side-by-side choices. A setting that has no effect right now, like Height with the power bar off, dims.

- **Drag** a frame to move it.
- **Click** a frame to jump to its settings.
- Changes show straight away and are saved as you make them. There's nothing to apply.
- **Reset this frame** puts the chosen frame back to its default settings and spot.
- **Done**, **x**, **Esc** or typing `/kui edit` again closes it. Entering combat also closes it, and it can't open in combat, because the game doesn't let frames like these change size in combat.
- While it's open, the target, target-of-target and pet frames stay up showing you, so you can set them up with nothing targeted.

Each frame has its own settings:

| Setting | Options |
|---|---|
| Width, health bar height, power bar height | Sizes in pixels |
| Power bar | On or off |
| Name | Full, first name only, or hidden |
| Name font size | The level and tags scale with it, and the header grows to fit |
| Level | On or off |
| Status tags and raid marker | On or off |
| Health numbers, health percent, power numbers | On or off, each on its own |
| Health font size, power font size | Sizes |
| Class colours | On, or plain green for players |
| Portrait | Off, flat or 3D |
| Portrait side | Left or right |
| Scale | 0.5 to 2 |

If the name, level and tags are all off, the header strip goes too.

The **Target** tab also has:

| Setting | Options |
|---|---|
| Elite and rare style | Off, border, or border and glow. Also on the ToT tab. |
| Preview as | See the frame as Normal, Elite, Rare, Rare Elite or Boss without finding one |
| Buffs and debuffs | On or off |
| Buff and debuff size | Icons wrap to fit the frame's width |
| Cast bar, cast bar height | The bar on the target frame |

The **Castbar** tab has width, height, font size, spell icon, time left, spark and scale for your bar. The icon, time and spark settings apply to the target's bar too.

Every tab also has the **font** and **panel opacity**, which apply to all of kUI. The settings windows themselves always stay in Barlow and stay readable, so they don't change under you while you try things.

## Minimap icon

A small **k** on the edge of the minimap, bottom right to start with. Drag it to move it around the edge.

Click it for the kUI menu:

- **Customise:** Edit mode and Bag settings.
- **Windows:** the rares and treasures list.
- **Try it out:** a sample cast, loot window or rare alert, to see the look without waiting for the real thing.
- **Parts of kUI:** a switch for each part. The menu stays open so you can flip several, then **Reload to apply** appears.
- **Hide this icon:** `/kui icon on` and `/reload` bring it back.

Click the icon again, press Esc or click anywhere else to close the menu.

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

Talk to a banker and the bank opens in the same style, with your bags beside it, and both close when you leave unless your bags were already open. All your tabs show together in categories, with the same search. Right-click an item to move it across, or drag it. A button at the bottom buys your next tab and shows what it costs, or claims your free first one. The game asks you to confirm either way. Warband tabs show too if you can see them, but a right-click from your bags goes to your own tabs, so drag items to a warband tab.

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

The font is used across kUI: unit frames, cast bars, bags, loot window and minimap strip. The settings windows, the minimap menu and the drag overlays stay in Barlow, whatever you pick.

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
- **Target**: targets it once it's in range. In combat the button says "After combat" and comes back when combat ends, because the game only lets add-ons set that up out of combat. **x**, Waypoint and Ignore work in combat.
- **Waypoint**: puts a waypoint on it, in TomTom if you have it, otherwise the game's own map pin.
- **Ignore**: never alert for this rare again.

When you target the rare out of combat it gets a **skull** (if you're solo, or the group leader or an assistant). When it dies the alert says so. The same rare won't alert again for 5 minutes. Drag the alert to move it.

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
| `/kui edit` | Open or close the edit mode (`/kui unlock` and `/kui lock` also work) |
| `/kui icon on` / `off` | Minimap icon on or off (needs `/reload`) |
| `/kui frames` | Unit frame commands |
| `/kui frames scale 1.1` | Size of all the unit frames at once (0.5 to 2) |
| `/kui frames class` | Class colours on player health, on or off for all of them |
| `/kui frames reset` | All the unit frames back to their default settings and spots |
| `/kui frames on` / `off` | kUI unit frames or the game's (needs `/reload`) |
| `/kui castbar` | Castbar commands |
| `/kui castbar test` | Run a sample cast |
| `/kui castbar scale 1.1` | Size of your cast bar (0.5 to 2) |
| `/kui castbar target` | Cast bar on the target frame on or off |
| `/kui castbar reset` | Your cast bar back to its default settings and spot |
| `/kui castbar on` / `off` | kUI's cast bar or the game's for yourself (needs `/reload`) |
| `/kui bars` | Open the edit mode on the action bars |
| `/kui keys` | Quick keybinds: hover a button and press a key |
| `/kui bars reset` | All the action bars back to their default settings and spots |
| `/kui bars debug` | List each bar's state in chat, for reporting a problem |
| `/kui bars on` / `off` | kUI's action bars or the game's (needs `/reload`) |
| `/kui loot on` / `off` | Use the kUI loot window or the game's (needs `/reload`) |
| `/kui map on` / `off` | Square minimap or the game's (needs `/reload`) |
| `/kui bags on` / `off` | kUI bags or the game's (needs `/reload`) |
| `/kui bank on` / `off` | kUI's bank window or the game's (needs `/reload`) |
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

- **Tested mostly outside the game**, against a stubbed WoW API, plus play in game for the unit frames, settings windows and minimap icon.
  - Settings controls: sliders, typed values, the mouse wheel, limits, switches, choices, steppers, dimmed rows, cards in two columns, the same controls in the bag settings.
  - Minimap icon: placement on square and round maps, dragging, every menu item, part switches and the reload offer, closing by clicking elsewhere, hiding it.
  - Unit frames: Blizzard's frames hidden and silent, totems moved out, secure click setup, health, power, level, tags, colours, two-part player names, raid marker, Dead, Ghost and Offline, target-of-target and pet, buffs and debuffs, combo pips, moving, scale, closing on combat, waiting for combat to end after a `/reload`.
  - Edit mode: every setting through the panel's own buttons, one frame's change not touching another, limits, flat and 3D portraits, elite and rare preview, frame reset, older settings carrying over, nothing changing in combat, Done, Esc and combat closing it.
  - Castbar: casts, channels, pushback, finishing, failed and interrupted, another spell's failure not ending a cast, can't-interrupt colour, a new target, the sample.
  - Action bars, mostly outside the game, with the layout, keys, menu and bag buttons seen working in game: which bars start on, the game's bars retired, slots, keys and shortened key names, layout in every direction, paging, vehicle and form pages, the secure snippets, visibility, hover fading, empty slots, range, procs, stance, pet and totem bars, the menu and bag buttons (the game redrawing them, laying them out, or borrowing the menu for its vehicle bar), quick keybinds opened from kUI or the game, XP, rested XP and reputation, every setting through the panel, typed values, copy and reset, nothing secure changing in combat.
  - Secret values: health, power, names, levels, auras and casts as secret values, with any maths or text work on them in Lua failing the test.
  - Rares: Classic spawn points placed and pinned, nameplate, mouseover and map-marker alerts, normal mobs ignored, level and position, model, sound, flash, no repeats, skull on target, kills, waypoint, the target button waiting for combat to end, ignore, the zone list.
  - Tooltips: panel, hidden Blizzard frame, old-style backdrops, health bar, font, rarity border and its reset, item level, vendor price (and not when the game shows one), drop lines best-first with chests by name, turning lines off.
  - Junk: greys sold, no-value and locked items left alone, nothing else sold, the summary, Shift to skip, a slot that changed isn't sold.
  - Fonts: text redrawn after a font change and back, frames following the font, every piece of text in the settings windows and menu staying in Barlow.
  - Treasures: Classic chests placed, world loots remembered by name and spot, gathering left out, chests told apart, repeat loots merged, map dots and tooltips, alerts near known spots (not while still empty, no repeats, never over a rare), the Treasures list.
  - Bags: a slot button for every bag slot, category order, empties at the bottom, horizontal and vertical gaps, categories side by side, rarity glow, quest marks, fonts, money, search by name and type, live settings, categories off, items moving, opening and closing from the game's bag keys, Blizzard's bag windows kept shut, the bank opening and closing with the banker.
  - Loot: rows, colours, glow, coins, quest tags, locked items, looting, linking, All, closing by **x** / Esc / the game, under-mouse placement, auto loot, the sample.
  - Minimap: square mask, hidden parts staying hidden, kept icons, zone colour, coordinates, zoom, tracking menu, world map.
  - Settings.
- The minimap part works with both Classic and modern minimap layouts. If a Blizzard piece is still showing on the minimap, send me a screenshot.
- If anything errors in game, the Lua error text is what I need.
- If the game blocks kUI ("Interface action failed because of an AddOn"), kUI prints what was blocked in chat. That line is what I need.
- The unit frames replace Blizzard's completely, so anything of Blizzard's that lived inside them only comes back if kUI rebuilds it. Not in yet: a Druid's mana bar while shapeshifted, and heal and absorb bars on health. `/kui frames off` and `/reload` gives you Blizzard's frames back.
- The action bars follow the approach Dominos uses on this client, checked against the game's own interface code. Add-ons that skin or replace the game's action bars, like Dominos or Bartender, will clash: use one or the other.
- If the menu, bag, XP or reputation bar can't be set up, kUI says so in chat and leaves that part as the game has it. Your action bars carry on. That chat line is what I need.
- kUI's XP and reputation bars replace the frame the game keeps all its progress bars in, so the game's honor and house favor bars don't show while kUI's action bars are on. `/kui bars off` and `/reload` give them back.
- The game can refuse add-ons a target's auras during a fight. When it does, the target's aura icons disappear until the auras next change or combat ends.
- If using an item from your bags in combat ever shows "Interface action failed because of an AddOn", tell me. Bag add-ons occasionally hit that and it has a known fix.
- Not in yet: choosing which warband tab a deposit goes to, the keyring, and custom categories.

## Files

| File | Contents |
|---|---|
| `KUI.toc` | Manifest |
| `Style.lua` | The shared look: panels, borders, buttons, bars, drag overlays, rarity glow, fonts |
| `Core.lua` | Settings and `/kui` |
| `UnitFrames.lua` | Player, target, target-of-target and pet frames, target auras, combo pips |
| `Castbar.lua` | Cast bars for you and your target |
| `ActionBars.lua` | Action, stance, pet and totem bars, the menu and bag buttons, and the XP and reputation bars |
| `Controls.lua` | The settings controls: sliders, switches, choices, cards, buttons |
| `EditMode.lua` | The edit mode's settings window |
| `MinimapIcon.lua` | The minimap icon and its menu |
| `Loot.lua` | Loot window |
| `Minimap.lua` | Square minimap and info strip |
| `Bags.lua` | Bag and bank windows, categories, settings panel |
| `RareData.lua` | Classic rares, chests and finds with their spawn points (generated from CMaNGOS classic-db, GPL-2.0) |
| `Rares.lua` | Rare scanner: spotting, alert, map dots, list |
| `Treasures.lua` | Chests and world lootables: map dots, what you've looted, nearby alerts |
| `Tooltips.lua` | Tooltip style, rarity border, extra item lines |
| `Junk.lua` | Sells grey items at vendors |
| `Fonts/` | Bundled fonts and their licences |
