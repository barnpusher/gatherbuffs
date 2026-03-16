local _, GB = ...

GB.RegisterProfession({
    id = "enchanting",
    label = "Enchanting",
    find = "Enchanting",
    profitOnly = true,
    profitToggleLabel = "Include Midnight enchanting mats",
    gatherItems = {
        { name = "Eversinging Dust", ids = { 243599, 243600 } },
        { name = "Radiant Shard",    ids = { 243602, 243603 } },
    },
})
