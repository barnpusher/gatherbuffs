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
            thalassian_skinning_knife = { ids = { 238011 } },
            sun_blessed_skinning_knife = { ids = { 238016 } },
            sunforged_skinning_knife = { ids = { 246535 } },
        },
        accessories = {
            eversong_hunters_headcover = { ids = { 244623 } },
            thalassian_wildseekers_stridercap = { ids = { 244809 } },
            sindorei_hunters_pack = { ids = { 244622 } },
            thalassian_wildseekers_workbag = { ids = { 244808 } },
        },
    },
    gatherItems = {
        void_tempered_leather = { ids = { 238511, 238512 } },
        void_tempered_scales = { ids = { 238513, 238514 } },
        void_tempered_hide = { ids = { 238519 } },
        void_tempered_plating = { ids = { 238520, 238521 } },
        scalewoven_hide = { ids = { 244631, 244633 } },
        fantastic_fur = { ids = { 238525 } },
        carving_canine = { ids = { 238523 } },
        peerless_plumage = { ids = { 238522 } },
        majestic_claw = { ids = { 238528 } },
        majestic_fin = { ids = { 238530 } },
        majestic_hide = { ids = { 238529 } },
    },
})
