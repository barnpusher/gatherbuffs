# GatherBuffs

`GatherBuffs` is a World of Warcraft Retail addon for tracking gathering buffs, profession state, and gathering-related weekly progress for Midnight.

Track Midnight gathering buffs, profession stats, Dundun shards, and session profit for fishing, mining, herbalism, skinning, tailoring, and enchanting.

## Features

- Tracks active gathering buffs — food, phials, potions, overload buffs, and weapon enchants — with a colour-coded timer bar for each
- Shows a profession card for **Mining**, **Herbalism**, and **Fishing** with equipped tool, accessories, weapon enchant, and live stat totals (Finesse, Perception, Deftness, Speed%)
- Tracks **Shard of Dundun** currency and weekly spend
- Tracks gathering session profit and looted items for Mining, Herbalism, Skinning, Fishing, Tailoring, and Enchanting
- Supports price lookup from **TSM**, **Zygor**, and **Auctionator** with automatic fallback chaining
- Session tracking supports pause/resume and persists across reloads
- Minimap button with right-click context menu
- Per-category settings with a dedicated tab for each active gathering profession
- Collapses automatically in combat when **Hide in Combat** is enabled

## Profit Pricing

The `Profit` settings tab supports two price source modes:

- `Auto`: uses `TSM -> Zygor Scan -> Zygor Median -> Zygor Low -> Auctionator`
- `Manual`: forces a single selected source

`Zygor` pricing follows the current character realm/faction automatically.

## Installation

1. Download the latest release zip.
2. Extract the `GatherBuffs` folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

3. Restart WoW or run `/reload`.

## Commands

- `/gb`
- `/gatherbuffs`
- `/gb toggle` toggles the main window
- `/gb config` opens settings
- `/gb reset` resets the window position
- `/gb newsession` starts a fresh session
- `/gb copy` opens the copyable report window for the current session
- `/gb debug` prints addon state for troubleshooting
- `/gb lootdebug` toggles loot debug mode
- `/gb lootlog` prints the recent loot debug log

## Bug Reports

If you hit a bug, please run `/gb debug`, copy the output, and open an issue on GitHub with that information included:

- https://github.com/barnpusher/gatherbuffs/issues

## Compatibility

- World of Warcraft Retail
- Interface `120001`
