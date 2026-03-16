# Changelog

## 0.99.12

- Expanded the profession-module refactor with a documented `ProfessionBase` contract and moved more UI, settings, and profit behavior behind profession methods
- Reworked the Info popup to show current professions, tools, enchants, accessories, and live stat summaries instead of price-source info
- Added Midnight profession gear catalogs for module-aware tool and accessory highlighting, plus improved profession gear slot inference from item tooltips
- Added Tailoring bolt tracking so crafted Midnight bolts appear in Tailoring profit tracking
- Folded the old `Professions.lua` facade into `Core.lua` and removed the extra module layer
- Fixed main panel collapse toggling and refreshed the README feature/command documentation

## 0.99.11

- Added CurseForge project metadata and workflow secret wiring for automated CurseForge uploads on tagged releases
- Fixed skinning profit tracking so valid skinning drops register again and removed the separate Skinning settings tab
- Refactored profession handling into per-profession modules and moved profession-specific logic out of the shared professions module

## 0.99.10

- Reworked profession, profit, currency, and fishing settings visibility so tabs and toggles only appear when relevant to the current character
- Refined the main UI layout with cleaner section headers, consistent padding, separate background/bar/text opacity controls, and updated Dundun presentation
- Expanded profit tracking with Midnight cloth and enchanting material toggles, vendor-loot support, auto-start on first loot, and improved report output for chat and console
- Fixed profit session handling so paused sessions no longer inflate totals or gold-per-hour and reports stay tied to tracked session loot
- Added Fishing/Tailoring/Enchanting profit and settings fixes, plus improved profession detection fallbacks for Fishing and profession equipment
- Added overload cooldown display, stricter aura matching for shared-name buffs, and updated debug output to show the real category detection path
- Updated the README with GitHub release, issue-reporting, and debug command documentation and added WowUp `.previews` scaffolding

## 0.99.9

- Added a Profit-tab checkbox to include Midnight enchanting disenchant mats in profit tracking
- Added Midnight enchanting material tracking for Eversinging Dust and Radiant Shard
- Restricted profit totals and reports to tracked looted or disenchanted items still remaining in bags, excluding mailbox and AH additions

## 0.99.8

- Moved profession stat summaries into the profession cards and kept the global buff section limited to shared buffs
- Added Tailoring as a profit-only module with dedicated settings and Midnight cloth tracking
- Switched profit display and reporting to current bag inventory minus session-start baseline
- Added readable profit report export buttons for party chat and local console output

## 0.99.7

- Moved profession stat summaries out of the profession cards and into the main buffs panel
- Added `Fin / Per / Def / Speed` summary rows for mining, herbalism, skinning, and fishing
- Added profession stat scanning from equipped tool and accessory tooltips as the basis for current/max stat totals

## 0.99.6

- Fixed GitHub artifact upload so packaged zips in `.release` are included in successful tagged runs

## 0.99.5

- Published packaged addon archives to GitHub Packages via GHCR on tagged releases
- Kept release zip assets attached to GitHub Releases for non-beta tags

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
