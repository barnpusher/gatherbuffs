local _, GB = ...

GB.RegisterProfession({
    id = "skinning",
    label = "Skinning",
    find = "Skinning",
    optionCategories = { "weaponstone" },
    mainCard = true,
    showSettingsTab = true,
    trackProfitWithoutAvailability = true,
    weaponstone = true,
    midnightGear = {
        tools = {
            "Thalassian Skinning Knife",
            "Sunforged Skinning Knife",
        },
        accessories = {
            "Eversong Hunter's Headcover",
            "Thalassian Skinner's Stridercap",
            "Sunforged Skinner's Stridercap",
            "Sin'dorei Hunter's Pack",
            "Thalassian Wildseeker's Workbag",
            "Sunforged Wildseeker's Workbag",
        },
    },
    gatherItems = {
        { name = "Void-Tempered Leather", ids = { 238511, 238512 } },
        { name = "Void-Tempered Scales",  ids = { 238513, 238514 } },
        { name = "Void-Tempered Hide",    ids = { 238519 } },
        { name = "Void-Tempered Plating", ids = { 238520, 238521 } },
        { name = "Scalewoven Hide",       ids = { 244631, 244633 } },
        { name = "Fantastic Fur",         ids = { 238525 } },
        { name = "Carving Canine",        ids = { 238523 } },
        { name = "Peerless Plumage",      ids = { 238522 } },
        { name = "Majestic Claw",         ids = { 238528 } },
        { name = "Majestic Fin",          ids = { 238530 } },
        { name = "Majestic Hide",         ids = { 238529 } },
    },
})
