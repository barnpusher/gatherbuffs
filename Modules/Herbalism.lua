local _, GB = ...

GB.RegisterProfession({
    id = "herbalism",
    label = "Herbalism",
    find = "Herbalism",
    optionCategories = { "weaponstone", "overload_herbalism" },
    categories = {
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
    },
    mainCard = true,
    showSettingsTab = true,
    weaponstone = true,
    midnightGear = {
        tools = {
            thalassian_sickle = { ids = { 238009 } },
            sun_blessed_sickle = { ids = { 238014 } },
            sunforged_sickle = { ids = { 246533 } },
        },
        accessories = {
            bright_linen_herbalism_hat = { ids = { 239645 } },
            elegant_artisans_herbalism_hat = { ids = { 239639 } },
            thalassian_herbalists_cowl = { ids = { 267060 } },
            thalassian_herbtenders_cradle = { ids = { 244807 } },
        },
    },
    gatherItems = {
        tranquility_bloom = { ids = { 236761, 236767 } },
        argentleaf = { ids = { 236776, 236777 } },
        azeroot = { ids = { 236774, 236775 } },
        sanguithorn = { ids = { 236770, 236771 } },
        mana_lily = { ids = { 236778, 236779 } },
        nocturnal_lotus = { ids = { 236780 } },
        mote_of_light = { ids = { 236949 } },
        mote_of_primal_energy = { ids = { 236950 } },
        mote_of_wild_magic = { ids = { 236951 } },
        mote_of_pure_void = { ids = { 236952 } },
    },
})
