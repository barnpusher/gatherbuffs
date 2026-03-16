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
            "Thalassian Sickle",
            "Sunforged Sickle",
        },
        accessories = {
            "Thalassian Herbalist's Cowl",
            "Thalassian Herbtender's Cradle",
        },
    },
    gatherItems = {
        { name = "Tranquility Bloom",     ids = { 236761, 236767 } },
        { name = "Argentleaf",            ids = { 236776, 236777 } },
        { name = "Azeroot",               ids = { 236774, 236775 } },
        { name = "Sanguithorn",           ids = { 236770, 236771 } },
        { name = "Mana Lily",             ids = { 236778, 236779 } },
        { name = "Nocturnal Lotus",       ids = { 236780 } },
        { name = "Mote of Light",         ids = { 236949 } },
        { name = "Mote of Primal Energy", ids = { 236950 } },
        { name = "Mote of Wild Magic",    ids = { 236951 } },
        { name = "Mote of Pure Void",     ids = { 236952 } },
    },
})
