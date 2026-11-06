# ForeverSync

Downloads WoW Forever data from the **ForeverDB API** onto your PC, so it can be turned into data files for QuestDirect and KUI. Add-ons can't make web requests themselves, so this is how the data reaches the game. Data from [ForeverDB.net](https://foreverdb.net).

## Before you start: get a ForeverDB API key

1. Go to <https://foreverdb.net/developers> and log in with Battle.net.
2. Request access. Say what you're building, something like *"personal WoW Forever addons: quest tracker, gold-making and rare scanner"*, give your email, and agree to credit ForeverDB.net.
3. Once ForeverDB approves you, create a key. It starts with `fdb_`.

## Running it

Double-click **ForeverSync.exe**. The first time, it asks for your key and saves it in `key.txt` next to the program. Then it downloads what QuestDirect and kUI use:

| What | Saved as |
|---|---|
| Game build and totals | `data\meta.json` |
| Zones | `data\zones.json` |
| Changes players have seen in Forever | `data\changes\` |
| Every quest: givers, turn-ins and their map positions, chains, levels, side | `data\quests_list.json`, `data\quests\<id>.json` |

Gathering spawns and vendors are only downloaded when you ask for them: `-only gathering,vendors`.

When it's done, the data is ready to be turned into add-on data files.

## How long it takes

ForeverDB allows 60 requests a minute and 10,000 a day. ForeverSync stays just under the per-minute limit, so each quest and vendor takes about a second. **The first run takes roughly an hour or more**, depending on how many quests there are. Leave the window open.

- **Stopping is fine.** Close it any time and run it again: it skips everything it already has and carries on.
- If it hits the daily limit, it says so; run it again the next day.
- Later runs only fetch the lists again plus anything new, so they take a few minutes. `-refresh` downloads everything again.

## Options

Run these from a command prompt in the folder:

| Option | Does |
|---|---|
| `-only quests` | Download just these parts: any of `meta,zones,changes,quests,gathering,vendors` |
| `-zone Durotar` | Quests and gathering for one zone (name or map ID) |
| `-refresh` | Download details again even if already saved |
| `-key fdb_...` | Use this key instead of `key.txt` |

## Good to know

- **Your key stays on your PC.** It's in `key.txt` and is only sent to foreverdb.net. Delete the file to enter a different key.
- **The data is ForeverDB's.** Each record is labelled *Seen in WoW Forever* or *Classic data*, and the add-ons will show that label. ForeverDB asks for a visible credit wherever its data is shown, so the add-ons say "Data from ForeverDB.net" where they use it. Don't resell the data or present it as your own.
- **Tested** against a mock of the API (paging, resuming, the per-minute and daily limits, a refused key), not the real one yet, because ForeverDB doesn't document exact field names. If anything comes back in a shape it doesn't expect, it stops with a message saying what it got.
