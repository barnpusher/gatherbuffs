# Changelog

## 0.99.4

- Replaced the custom GitHub packaging workflow with the BigWigs WoW packager
- Kept packaging GitHub-only, with zip artifacts uploaded from the packager output

## 0.99.3

- Fixed manual hide state so the addon stays hidden until explicitly shown again, even across combat and profession refresh events

## 0.99.2

- Fixed GitHub packaging on Linux by normalizing TOC path separators in the workflow
- Added Midnight Skinning weekly drop tracking to the profession bar

## 0.99.1

- Split the addon into module files (`Core`, `UI`, `Options`, `Init`, `Buffs`, `Professions`, `Profit`)
- Reworked the layout to a Myu-style stacked panel UI
- Moved settings and info into a context menu and independent settings window
- Added minimap button, UI opacity controls, row opacity, UI scale, lock window, and hide in combat options
- Added `Currencies` module with `Shard of Dundun` tracking
- Added `Fishing` as a profession module and moved fishing timers into the common buff section
- Added profession weekly item progress for Herbalism and Mining in the main profession bars
- Added profit session tracking with configurable profession filters and multiple price sources
- Added profit price source selection with `Auto` and `Manual` modes
- Added support for `TSM`, `Zygor`, and `Auctionator` pricing
- Added Dragonflight profession phials for Perception, Deftness, and Finesse with `Q1/Q2/Q3` labels
- Removed non-functional `Use` buttons
- Fixed aura lookup taint issues caused by imported spell IDs
- Fixed profession equipment detection to read profession tool and accessory slots
- Froze buff timer reads during combat to avoid combat-time aura access
- Clamped G/hour after session reset to avoid unrealistic early spikes
