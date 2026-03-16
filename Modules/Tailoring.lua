local _, GB = ...

GB.RegisterProfession({
    id = "tailoring",
    label = "Tailoring",
    find = "Tailoring",
    profitOnly = true,
    profitToggleLabel = "Include Midnight cloth",
    gatherItems = {
        { name = "Bright Linen", ids = { 236963, 236965 } },
        { name = "Sunfire Silk", ids = { 237015, 237016 } },
        { name = "Arcanoweave",  ids = { 237018, 237017 } },
    },
})
