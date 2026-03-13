# GatherBuffs

`GatherBuffs` is a World of Warcraft Retail addon for tracking gathering buffs, profession state, and gathering-related weekly progress for Midnight.

## Features

- Tracks configured gathering consumables and profession buffs
- Shows profession summary bars for Mining and Herbalism
- Tracks `Shard of Dundun` currency progress
- Tracks gathering session profit and looted items
- Supports profit price lookup from `TSM`, `Zygor`, and `Auctionator`
- Provides configurable per-category settings

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

## Compatibility

- World of Warcraft Retail
- Interface `120001`
