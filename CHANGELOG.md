# Changelog

## Unreleased

## 0.99.19

- Updated retail interface compatibility for the Midnight 12.0.5 client
- Improved combat handling so buff rows stay frozen in their last out-of-combat state when visible, and the Buffs section title switches to `Combat`
- Added an Enchanting main card with tool details and a setting to block disenchanting unless `Shattered Essence` is active
- Added loot-window and current-cast event handling to improve disenchant gating and gather-action tracking
- Added per-profession gather-action counts to session state and expanded profit reports with average value and yield per action

## 0.99.18

- Modularize professions
- Fixed category defaults so module-owned buff categories inherit their intended enabled state
- Fixed profession tool verification in the main UI to use each profession's own gear catalog
- Fixed Fishing `Bonus` to stay disabled by default alongside Fishing `Lure`
- Reduced hot-path overhead by removing the unnecessary protected `tonumber` call in spell ID normalization and caching tracked item counts between bag updates
- Stopped rebuilding the options window frame whenever not needed
- Removed the redundant extra `UpdateBars` pass on `CURRENCY_DISPLAY_UPDATE`
- Documented the distinction between profession-owned `categories` and UI-exposed `optionCategories`

## 0.99.17

- Fixed Profit panel visibility so disabling the Fishing module no longer hides Profit (thanks `thatn00b` for the report)
- Fixed Profit AH value lookups so TSM and Auctionator prices resolve more reliably again (thanks `thatn00b` for the report)
- Reworked Midnight profession gear catalogs to use readable keyed entries with strict item ID matching for tools and accessories.
- Added more verified Midnight profession gear entries for Fishing, Herbalism, and Skinning
- Fixed profession-scoped common buff rows so module toggles and per-profession settings are respected consistently, including Fishing lure/bonus rows
- Added Enchanting shared buff tracking for `Shattered Essence`
- Expanded Midnight enchanting profit tracking to include `Dawn Crystal`

## 0.99.16

- Automated CurseForge release changelog generation from the matching `CHANGELOG.md` version section
- Added a Skinning settings tab and Razorstone support for Skinning
- Switched buff and enchant matching to strict ID-based resolution instead of spell-name fallbacks
- Added cached item/spell name lookups from the WoW client for UI, settings, and debug display text
- Improved profession tool Razorstone detection and moved the expensive resolution work into the profession static cache to avoid hot-path CPU spikes

## 0.99.15

- Fixed profit tracking in instances and other secret-chat cases by falling back to bag delta scans instead of parsing protected CHAT_MSG_LOOT payloads
- Improved profession tool enchant detection so known razorstone enchant IDs resolve to their matching spell IDs and names
- Expanded debug output to show weaponstone state per profession and include both enchant IDs and mapped spell IDs for profession tools

## 0.99.14

- Reduced CPU usage, optimized a bunch of stuff
- Fixed Argentleaf Tea aura/timer
- Shared-aura phials are less likely to show the wrong selected quality
- Split Razorstone handling properly between Mining and Herbalism
- Moved Razorstone tracking into the global Buffs section, with separate rows for Mining and Herbalism.
- Profit header shows reliably again
- Main window refreshes properly
- Fixed the report window so it remembers where you moved it instead of reopening in the center every time

## 0.99.13

- Fixed the main panel collapse button so it properly opens and closes the addon sections
- Fixed profit tracking so buying items from a vendor no longer counts as farmed profit
- Added optional auto-pause for profit sessions after a chosen period with no loot activity
- Added optional alerts when a tracked buff expires or when a consumable runs out
- Added `/gb newsession` to start a fresh profit session quickly
- Added `/gb copy` to open a copyable report window for the current session
- Reworked the report flow so the Profit panel opens a proper report window with copy, console, and party-share options
- Expanded the Info window to show your current AH pricing setup, active source, and available price data
- Improved manual AH source selection so unavailable sources stay visible but cannot be selected, while auto mode shows the source currently being used
- Updated the README with the latest commands and feature notes

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
