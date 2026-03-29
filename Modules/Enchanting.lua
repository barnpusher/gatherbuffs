local _, GB = ...

GB.RegisterProfession({
    id = "enchanting",
    label = "Enchanting",
    find = "Enchanting",
    optionCategories = { "enchanting" },
    profitOnly = true,
    showSettingsTab = true,
    profitToggleLabel = "Include Midnight enchanting mats",
    midnightGear = {
        tools = {
            runed_refulgent_copper_rod = { ids = { 244175 } },
            runed_brilliant_silver_rod = { ids = { 244176 } },
            runed_dazzling_thorium_rod = { ids = { 244177 } },
        },
        accessories = {
            bright_linen_enchanting_hat = { ids = { 239643 } },
            elegant_artisans_enchanting_hat = { ids = { 239637 } },
            thalassian_enchanters_bonnet = { ids = { 267056 } },
            silvermoon_focusing_shard = { ids = { 240956 } },
            sindorei_enchanters_crystal = { ids = { 240960 } },
            attuned_thalassian_rune_prism = { ids = { 246527 } },
        },
    },
    gatherItems = {
        dawn_crystal = { ids = { 243605, 243606 } },
        eversinging_dust = { ids = { 243599, 243600 } },
        radiant_shard = { ids = { 243602, 243603 } },
    },
})
