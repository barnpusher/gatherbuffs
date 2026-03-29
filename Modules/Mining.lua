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
    midnightGear = {
        tools = {
            thalassian_pickaxe = { ids = { 238010 } },
            sun_blessed_pickaxe = { ids = { 238015 } },
            sunforged_pickaxe = { ids = { 246534 } },
        },
        accessories = {
            farstrider_rock_satchel = { ids = { 244719 } },
            junkers_big_ol_bag = { ids = { 244720 } },
            heavy_duty_rock_assister = { ids = { 259175 } },
            farstrider_hardhat = { ids = { 244715 } },
            sindorei_gilded_hardhat = { ids = { 244716 } },
            rock_bonkin_hardhat = { ids = { 259173 } },
        },
    },
    gatherItems = {
        refulgent_copper_ore = { ids = { 237359, 237361 } },
        umbral_tin_ore = { ids = { 237362, 237363 } },
        brilliant_silver_ore = { ids = { 237364, 237365 } },
        dazzling_thorium = { ids = { 237366 } },
        mote_of_light = { ids = { 236949 } },
        mote_of_primal_energy = { ids = { 236950 } },
        mote_of_wild_magic = { ids = { 236951 } },
        mote_of_pure_void = { ids = { 236952 } },
    },
})
