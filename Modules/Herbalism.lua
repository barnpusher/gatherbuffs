local _, GB = ...

GB.RegisterProfession({
    id = "herbalism",
    label = "Herbalism",
    find = "Herbalism",
    optionCategories = { "weaponstone", "overload_herbalism" },
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
