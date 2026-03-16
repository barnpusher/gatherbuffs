local _, GB = ...

GB.RegisterProfession({
    id = "enchanting",
    label = "Enchanting",
    find = "Enchanting",
    profitOnly = true,
    profitToggleLabel = "Include Midnight enchanting mats",
    midnightGear = {
        tools = {
            "Runed Refulgent Copper Rod",
            "Runed Brilliant Silver Rod",
            "Runed Dazzling Thorium Rod",
        },
        accessories = {
            "Bright Linen Enchanting Hat",
            "Elegant Artisan's Enchanting Hat",
            "Thalassian Enchanter's Bonnet",
            "Silvermoon Focusing Shard",
            "Sin'dorei Enchanter's Crystal",
            "Attuned Thalassian Rune-Prism",
        },
    },
    gatherItems = {
        { name = "Eversinging Dust", ids = { 243599, 243600 } },
        { name = "Radiant Shard",    ids = { 243602, 243603 } },
    },
})
