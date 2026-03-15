# GatherBuffs

`GatherBuffs` is a World of Warcraft Retail addon for tracking gathering buffs, profession state, and gathering-related weekly progress for Midnight.

Track Midnight gathering buffs, profession stats, Dundun shards, and session profit for fishing, mining, herbalism, skinning, tailoring, and enchanting.

## Features

- Tracks configured gathering consumables and profession buffs
- Shows profession summary bars for Mining and Herbalism
- Tracks `Shard of Dundun` currency progress
- Tracks gathering session profit and looted items
- Supports profit price lookup from `TSM`, `Zygor`, and `Auctionator`
- Provides configurable per-category settings

## Distribution

`GatherBuffs` is released from GitHub tags. Each tagged release includes a packaged zip with the `GatherBuffs/` addon folder at the archive root, which works for direct installation, CurseForge uploads, and WowUp Hub indexing.

WowUp Hub also uses repository metadata:

- GitHub topics for category discovery
- the repository social preview image as the default addon image
- optional screenshots from the `.previews/` folder on the tagged branch snapshot

GitHub repository:

- https://github.com/barnpusher/gatherbuffs

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
- `/gb reset` resets the current session
- `/gb debug` prints addon state for troubleshooting
- `/gb lootdebug` toggles loot debug mode
- `/gb lootlog` prints the recent loot debug log

## Bug Reports

If you hit a bug, please run `/gb debug`, copy the output, and open an issue on GitHub with that information included:

- https://github.com/barnpusher/gatherbuffs/issues

## Compatibility

- World of Warcraft Retail
- Interface `120001`
