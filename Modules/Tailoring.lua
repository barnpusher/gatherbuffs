local _, GB = ...

GB.RegisterProfession({
    id = "tailoring",
    label = "Tailoring",
    find = "Tailoring",
    profitOnly = true,
    profitToggleLabel = "Include Midnight cloth",
    midnightGear = {
        tools = {
            farstrider_fabric_cutters = { ids = { 244707 } },
            sindorei_snippers = { ids = { 244708 } },
            self_sharpening_sindorei_snippers = { ids = { 259177 } },
        },
        accessories = {
            bright_linen_tailoring_robe = { ids = { 239646 } },
            elegant_artisans_tailoring_robe = { ids = { 239640 } },
            thalassian_tailors_threads = { ids = { 267062 } },
            thalassian_needle_set = { ids = { 237946 } },
            sun_blessed_needle_set = { ids = { 237950 } },
            sunforged_needle_set = { ids = { 259234 } },
        },
    },
    gatherItems = {
        bright_linen = { ids = { 236963, 236965 } },
        bright_linen_bolt = { ids = { 239700 } },
        imbued_bright_linen_bolt = { ids = { 239702, 239703 } },
        sunfire_silk = { ids = { 237015, 237016 } },
        sunfire_silk_bolt = { ids = { 239201, 239202 } },
        arcanoweave = { ids = { 237018, 237017 } },
        arcanoweave_bolt = { ids = { 239198, 239200 } },
    },
})
