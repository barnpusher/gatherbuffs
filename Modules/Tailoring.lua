local _, GB = ...

GB.RegisterProfession({
    id = "tailoring",
    label = "Tailoring",
    find = "Tailoring",
    profitOnly = true,
    profitToggleLabel = "Include Midnight cloth",
    midnightGear = {
        tools = {
            "Farstrider Fabric Cutters",
            "Steelweave Snippers",
            "Sin'dorei Snippers",
        },
        accessories = {
            "Bright Linen Tailoring Robe",
            "Elegant Artisan's Tailoring Robe",
            "Sunforged Tailoring Robe",
            "Thalassian Needle Set",
            "Elegant Artisan's Needle Set",
            "Sunforged Needle Set",
        },
    },
    gatherItems = {
        { name = "Bright Linen", ids = { 236963, 236965 } },
        { name = "Bright Linen Bolt", ids = { 239700 } },
        { name = "Imbued Bright Linen Bolt", ids = { 239702, 239703 } },
        { name = "Sunfire Silk", ids = { 237015, 237016 } },
        { name = "Sunfire Silk Bolt", ids = { 239201, 239202 } },
        { name = "Arcanoweave",  ids = { 237018, 237017 } },
        { name = "Arcanoweave Bolt", ids = { 239198, 239200 } },
    },
})
