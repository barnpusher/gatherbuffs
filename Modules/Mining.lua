local _, GB = ...

GB.RegisterProfession({
    id = "mining",
    label = "Mining",
    find = "Mining",
    optionCategories = { "weaponstone", "overload_mining" },
    mainCard = true,
    showSettingsTab = true,
    toolDetails = true,
    weaponstone = true,
    gatherItems = {
        { name = "Refulgent Copper Ore",  ids = { 237359, 237361 } },
        { name = "Umbral Tin Ore",        ids = { 237362, 237363 } },
        { name = "Brilliant Silver Ore",  ids = { 237364, 237365 } },
        { name = "Dazzling Thorium",      ids = { 237366 } },
        { name = "Mote of Light",         ids = { 236949 } },
        { name = "Mote of Primal Energy", ids = { 236950 } },
        { name = "Mote of Wild Magic",    ids = { 236951 } },
        { name = "Mote of Pure Void",     ids = { 236952 } },
    },
})
