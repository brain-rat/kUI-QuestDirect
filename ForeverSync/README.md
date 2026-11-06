# ForeverSync

Downloads WoW Forever data from the **ForeverDB API** onto your PC, so it can be turned into a data file for QuestDirect. Add-ons can't make web requests themselves, so this is how the data reaches the game. Data from [ForeverDB.net](https://foreverdb.net).

## Before you start: get a ForeverDB API key

1. Go to <https://foreverdb.net/developers> and log in with Battle.net.
2. Request access. Say what you're building, something like *"personal WoW Forever addons: quest tracker, gold-making and rare scanner"*, give your email, and agree to credit ForeverDB.net.
3. Once ForeverDB approves you, create a key. It starts with `fdb_`.

## Running it

Double-click **ForeverSync.exe**. The first time, it asks for your key and saves it in `key.txt` next to the program. Then it downloads:

| What | Saved as |
|---|---|
| Game build and totals | `data\meta.json` |
| Zones | `data\zones.json` |
| Changes players have seen in Forever | `data\changes\` |
| Every quest: givers, turn-ins and their map positions, chains, levels, side | `data\quests_list.json` |

Gathering spawns and vendors are only downloaded when you ask for them: `-only gathering,vendors`.

Next, turn the data into QuestDirect's file: see *Adding the Forever data* in [QuestDirect's read-me](../QuestDirect/README.md).

## How long it takes

ForeverDB allows 60 requests a minute and 10,000 a day. ForeverSync stays just under the per-minute limit, so each request takes about a second. **A normal run takes about a minute.**

ForeverDB's quest list already holds what each quest's own page has, so ForeverSync doesn't download those pages. If the list ever stops including it, ForeverSync goes back to downloading them, which takes roughly an hour. `-details` asks for them anyway.

- **Stopping is fine.** Close it any time and run it again. Lists start over, and single pages it already has (vendors, or quests with `-details`) are skipped.
- If it hits the daily limit, it says so; run it again the next day.
- `-refresh` downloads those single pages again.

## Options

Run these from a command prompt in the folder:

| Option | Does |
|---|---|
| `-only quests` | Download just these parts: any of `meta,zones,changes,quests,gathering,vendors` |
| `-zone Durotar` | Quests and gathering for one zone (name or map ID) |
| `-details` | Also download each quest's own page (about an hour) |
| `-refresh` | Download single pages again even if already saved |
| `-key fdb_...` | Use this key instead of `key.txt` |

## Good to know

- **Your key stays on your PC.** It's in `key.txt` and is only sent to foreverdb.net. Delete the file to enter a different key.
- **The data is ForeverDB's.** Each record is labelled *Seen in WoW Forever* or *Classic data*, and QuestDirect shows that label. ForeverDB asks for a visible credit wherever its data is shown, so QuestDirect says "Data from ForeverDB.net (https://foreverdb.net)" where it uses it. Don't resell the data or present it as your own.
- **Rares aren't in it.** ForeverDB's API has no list of NPCs or rares, so kUI's rare scanner keeps using the Classic data and what you see in game.
- **Tested** against a mock of the API (paging, resuming, the per-minute and daily limits, a refused key), and a full normal run against the real API, with a few quest pages as well. The per-minute and daily limits have only been tested against the mock, and gathering and vendors haven't been run against the real API yet. If anything comes back in a shape it doesn't expect, it stops with a message saying what it got.
