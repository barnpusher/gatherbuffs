-- Data_updated.lua
-- Buff definitions, researched stat values, and profession metadata.

-- Known Midnight mining tools (item IDs).  Mark as true to show a green
-- "verified" indicator.  Only confirmed mining tools should be placed here.
GATHERBUFFS_MINING_TOOLS = {
    [238010] = true, -- Thalassian Pickaxe (Midnight mining tool)
    -- Additional Midnight mining tools can be added here once verified.
}

-- Items to silently ignore in loot debug popup (non‑gathering drops from herb/ore nodes).
GATHERBUFFS_LOOT_IGNORE = {
    [238467] = true,  -- Thalassian Phoenix Ember (misc node drop)
    [237497] = true,  -- Resilient Seed (all quality tiers)
    [237498] = true,
    [237499] = true,
    [237500] = true,
    [258943] = true,  -- Tarnished Dawnlit Commander's Armplates (armor drop)
    [260620] = true,  -- Stone Droppings (misc node drop)
}

-- Ordering for displayed stats.  Entries map an identifier to a short label.
GATHERBUFFS_STAT_ORDER = {
    { id = "finesse",    label = "Finesse"   },
    { id = "perception", label = "Percept." },
    { id = "deftness",   label = "Deftness"  },
    { id = "speedPct",   label = "Speed%"    },
}

-- Category definitions.  Each category contains one or more buffs.  The
-- "scope" field controls whether a buff is shown for all professions (common)
-- or restricted to specific professions.  The "notes" field gives
-- additional context or restrictions.
GATHERBUFFS_CATEGORIES = {
    {
        id = "food",
        label = "Food",
        scope = "common",
        buffs = {
            {
                name = "Argentleaf Tea",
                spellID = 1269152,  -- shared "Relaxed" aura
                altSpellIDs = { 1269170 },
                maxDuration = 3600,
                itemIDs = { 242298 },
                stats = { finesse = 50, speedPct = 3 },
                notes = "Relaxed tea (Finesse & Speed); shares the tea slot.",
            },
            {
                name = "Sanguithorn Tea",
                spellID = 1269152,  -- shared "Relaxed" aura
                altSpellIDs = { 1269170 },
                maxDuration = 3600,
                itemIDs = { 242299 },
                stats = { perception = 50, speedPct = 3 },
                notes = "Relaxed tea (Perception & Speed); shares the tea slot.",
            },
            {
                name = "Azeroot Tea",
                spellID = 1269152,  -- shared "Relaxed" aura
                altSpellIDs = { 1269170 },
                maxDuration = 3600,
                itemIDs = { 242301 },
                stats = { deftness = 50, speedPct = 3 },
                notes = "Relaxed tea (Deftness & Speed); shares the tea slot.",
            },
        },
    },
    {
        id = "phial",
        label = "Phial",
        scope = "common",
        buffs = {
            {
                name = "Haranir Phial of Perception (Q2)",
                spellID = 1236763,
                maxDuration = 1800,
                itemIDs = { 241316 },
                stats = { perception = 45, deftness = 14 },
            },
            {
                name = "Haranir Phial of Perception (Q1)",
                spellID = 1236763,
                maxDuration = 1800,
                itemIDs = { 241317 },
                stats = { perception = 38, deftness = 12 },
            },
            {
                name = "Haranir Phial of Finesse (Q2)",
                spellID = 1236767,
                maxDuration = 1800,
                itemIDs = { 241310 },
                stats = { finesse = 45, deftness = 14 },
            },
            {
                name = "Haranir Phial of Finesse (Q1)",
                spellID = 1236767,
                maxDuration = 1800,
                itemIDs = { 241311 },
                stats = { finesse = 38, deftness = 12 },
            },
            {
                name = "Haranir Phial of Ingenuity (Q2)",
                spellID = 1239755,
                maxDuration = 1800,
                itemIDs = { 241312 },
                statsUnknown = true,  -- crafting stats only, no gathering benefit
            },
            {
                name = "Haranir Phial of Ingenuity (Q1)",
                spellID = 1239755,
                maxDuration = 1800,
                itemIDs = { 241313 },
                statsUnknown = true,  -- crafting stats only, no gathering benefit
            },
            {
                name = "Phial of Truesight (TWW)",
                spellID = nil,
                maxDuration = 1800,
                itemIDs = { 212309 },
                statsUnknown = true,
                notes = "Increases Perception and reveals camouflaged nodes; stacks only with Dragonflight phials.",
            },
        },
    },
    {
        id = "steamphial",
        label = "Phial (DF)",
        scope = "common",
        buffs = {
            {
                name = "Crystalline Phial of Perception",
                quality = 3,
                spellID = 393714,
                maxDuration = 1800,
                itemIDs = { 191356 },
                stats = { perception = 50 },
                notes = "Legacy Dragonflight phial; stacks with TWW/Midnight phials.",
            },
            {
                name = "Crystalline Phial of Perception",
                quality = 2,
                spellID = 393714,
                maxDuration = 1800,
                itemIDs = { 191355 },
                stats = { perception = 40 },
            },
            {
                name = "Crystalline Phial of Perception",
                quality = 1,
                spellID = 393714,
                maxDuration = 1800,
                itemIDs = { 191354 },
                stats = { perception = 30 },
            },
            {
                name = "Aerated Phial of Deftness",
                quality = 3,
                spellID = 393700,
                maxDuration = 1800,
                itemIDs = { 191344 },
                stats = { deftness = 50 },
            },
            {
                name = "Aerated Phial of Deftness",
                quality = 2,
                spellID = 393700,
                maxDuration = 1800,
                itemIDs = { 191343 },
                stats = { deftness = 40 },
            },
            {
                name = "Aerated Phial of Deftness",
                quality = 1,
                spellID = 393700,
                maxDuration = 1800,
                itemIDs = { 191342 },
                stats = { deftness = 30 },
            },
            {
                name = "Steaming Phial of Finesse",
                quality = 3,
                spellID = 393717,  -- shared buff aura for all quality tiers
                maxDuration = 1800,
                itemIDs = { 191347 },
                stats = { finesse = 50 },
                notes = "Legacy Dragonflight phial; stacks with TWW/Midnight phials.",
            },
            {
                name = "Steaming Phial of Finesse",
                quality = 2,
                spellID = 393717,  -- shared buff aura for all quality tiers
                maxDuration = 1800,
                itemIDs = { 191346 },
                stats = { finesse = 40 },
            },
            {
                name = "Steaming Phial of Finesse",
                quality = 1,
                spellID = 393717,  -- shared buff aura for all quality tiers
                maxDuration = 1800,
                itemIDs = { 191345 },
                stats = { finesse = 30 },
            },
        },
    },
    {
        id = "potion",
        label = "Potion",
        scope = "common",
        buffs = {
            {
                name = "Darkmoon Firewater",
                spellID = 185562,
                maxDuration = 3600,
                itemIDs = { 124671 },
                stats = { speedPct = 15 },
            },
        },
    },
    {
        id = "fishing",
        label = "Lure",
        scope = "common",
        profIcon = "fishing",
        professions = { "fishing" },
        buffs = {
            { name = "Blood Hunter Lure",    spellID = 1237974, maxDuration = 1800, itemIDs = { 238377 }, statsUnknown = true },
            { name = "Lucky Loa Lure",       spellID = 1237964, maxDuration = 1800, itemIDs = { 241145, 238376 }, statsUnknown = true },
            { name = "Ominous Octopus Lure", spellID = 1237965, maxDuration = 1800, itemIDs = { 238373 }, statsUnknown = true },
            { name = "Goldengill Blessing",  spellID = 456596,  maxDuration = 900,  itemIDs = { 222533 }, statsUnknown = true },
        },
    },
    {
        id = "fishing_chum",
        label = "Bonus",
        scope = "common",
        profIcon = "fishing",
        professions = { "fishing" },
        buffs = {
            {
                name = "Chum",
                spellID = 1237942,
                maxDuration = 30,
                itemIDs = { 238365 },
                statsUnknown = true,
                notes = "Fishing chum buff from throwing specific fish back into the water.",
            },
            {
                name = "Midnight Perception",
                spellID = 1235216,
                maxDuration = 15,
                itemIDs = { 238366 },
                stats = { perception = 150 },
                notes = "Short fishing perception buff triggered by throwing specific fish back into the water.",
            },
        },
    },
    {
        id = "enchanting",
        label = "Buff",
        scope = "common",
        profIcon = "enchanting",
        professions = { "enchanting" },
        buffs = {
            {
                name = "Shattered Essence",
                spellID = 1235733,
                itemIDs = {},
                statsUnknown = true,
                notes = "Enchanting-only buff tracked by player aura.",
            },
        },
    },
    {
        id = "overload_mining",
        label = "Overload",
        scope = "common",
        profIcon = "mining",
        showAvailable = true,
        professions = { "mining" },
        buffs = {
            {
                name = "Wild Perception (Mine)",
                spellID = 1225704,
                maxDuration = 300,
                itemIDs = {},
                professions = { "mining" },
                stats = { perception = 150 },
            },
        },
    },
    {
        id = "overload_herbalism",
        label = "Overload",
        scope = "common",
        profIcon = "herbalism",
        showAvailable = true,
        professions = { "herbalism" },
        buffs = {
            {
                name = "Wild Perception (Herb)",
                spellID = 1223879,
                maxDuration = 300,
                itemIDs = {},
                professions = { "herbalism" },
                stats = { perception = 150 },
            },
            {
                name = "Green Thumb",
                spellID = 1221172,
                maxDuration = 300,
                itemIDs = {},
                professions = { "herbalism" },
                statsUnknown = true,
                notes = "Doubles the herbs you receive on your next gather.",
            },
        },
    },
    {
        id = "weaponstone",
        label = "W.Stone",
        scope = "common",
        profIcon = "mining",
        professions = { "mining" },
        equippedGear = true,  -- detected via C_Item.IsEquippedItem, not player aura
        buffs = {
            -- Refulgent Razorstone (Midnight) - quality tiers with separate spells
            {
                name = "Refulgent Razorstone",
                quality = 2,
                spellID = 1224335,
                maxDuration = 7200,
                itemIDs = { 237373 },
                stats = { finesse = 57 },
            },
            {
                name = "Refulgent Razorstone",
                quality = 1,
                spellID = 1224334,
                maxDuration = 7200,
                itemIDs = { 237372 },
                stats = { finesse = 43 },
            },
            -- Ironclaw Razorstone (TWW) - 3 quality tiers
            {
                name = "Ironclaw Razorstone",
                quality = 3,
                spellID = 458931,
                maxDuration = 7200,
                itemIDs = { 222507 },
                stats = { finesse = 72 },
            },
            {
                name = "Ironclaw Razorstone",
                quality = 2,
                spellID = 458930,
                maxDuration = 7200,
                itemIDs = { 222506 },
                stats = { finesse = 57 },
            },
            {
                name = "Ironclaw Razorstone",
                quality = 1,
                spellID = 458929,
                maxDuration = 7200,
                itemIDs = { 222505 },
                stats = { finesse = 43 },
            },
            -- Primal Razorstone (DF) - 3 quality tiers
            {
                name = "Primal Razorstone",
                quality = 3,
                spellID = 371681,
                maxDuration = 7200,
                itemIDs = { 191950 },
                stats = { finesse = 24 },
            },
            {
                name = "Primal Razorstone",
                quality = 2,
                spellID = 371680,
                maxDuration = 7200,
                itemIDs = { 191949 },
                stats = { finesse = 19 },
            },
            {
                name = "Primal Razorstone",
                quality = 1,
                spellID = 371641,
                maxDuration = 7200,
                itemIDs = { 191948 },
                stats = { finesse = 14 },
            },
        },
    },
}
