local _, GB = ...

local Fishing = GB.RegisterProfession({
    id = "fishing",
    label = "Fishing",
    find = "Fishing",
    simpleSkillSummary = true,
    supportsDesiredStatSelection = false,
    optionCategories = { "fishing", "fishing_chum" },
    categories = {
        {
            id = "fishing",
            label = "Lure",
            scope = "common",
            profIcon = "fishing",
            professions = { "fishing" },
            defaultEnabled = false,
            buffs = {
                { name = "Blood Hunter Lure",    spellID = 1237974, maxDuration = 1800, itemIDs = { 238377 }, statsUnknown = true },
                { name = "Lucky Loa Lure",       spellID = 1237964, maxDuration = 1800, itemIDs = { 241145, 238376 }, statsUnknown = true },
                { name = "Ominous Octopus Lure", spellID = 1237965, maxDuration = 1800, itemIDs = { 238373 }, statsUnknown = true },
                { name = "Goldengill Blessing",  spellID = 456596,  maxDuration = 900,  itemIDs = { 222533 }, statsUnknown = true },
            },
        },
        {
            id = "fishing_chum",
            label = "Bonus",
            scope = "common",
            profIcon = "fishing",
            professions = { "fishing" },
            defaultEnabled = false,
            buffs = {
                {
                    name = "Chum",
                    spellID = 1237942,
                    maxDuration = 30,
                    itemIDs = { 238365 },
                    statsUnknown = true,
                    notes = "Fishing chum buff from throwing specific fish back into the water.",
                },
                {
                    name = "Midnight Perception",
                    spellID = 1235216,
                    maxDuration = 15,
                    itemIDs = { 238366 },
                    stats = { perception = 150 },
                    notes = "Short fishing perception buff triggered by throwing specific fish back into the water.",
                },
            },
        },
    },
    mainCard = true,
    showSettingsTab = true,
    midnightGear = {
        tools = {
            farstrider_hobbyist_rod = { ids = { 244711 } },
            sindorei_anglers_rod = { ids = { 244712 } },
            sindorei_reelers_rod = { ids = { 259179 } },
        },
        accessories = {
            bright_linen_fishing_hat = { ids = { 239644 } },
            elegant_artisans_fishing_hat = { ids = { 239638 } },
        },
    },
    gatherItems = {
        arcane_wyrmfish = { ids = { 238371 } },
        gore_guppy = { ids = { 238382 } },
        lynxfish = { ids = { 238366 } },
        root_crab = { ids = { 238367 } },
        sindorei_swarmer = { ids = { 238365 } },
        blood_hunter = { ids = { 238377 } },
        bloomtail_minnow = { ids = { 238369 } },
        fungalskin_pike = { ids = { 238375 } },
        restored_songfish = { ids = { 238372 } },
        shimmer_spinefish = { ids = { 238370 } },
        shimmersiren = { ids = { 238378 } },
        sunwell_fish = { ids = { 238384 } },
        tender_lumifin = { ids = { 238374 } },
        eversong_trout = { ids = { 238383 } },
        hollow_grouper = { ids = { 238381 } },
        lucky_loa = { ids = { 238376 } },
        null_voidfish = { ids = { 238380 } },
        ominous_octopus = { ids = { 238373 } },
        warping_wise = { ids = { 238379 } },
    },
})

function Fishing:IsAvailable(addon)
    return self:GetDisplayInfo(addon) ~= nil or GB.HasProfessionByName(self.find)
end

function Fishing:GetDisplayInfo(addon)
    if addon.profMap and addon.profMap[self.id] then
        return addon.profMap[self.id]
    end

    local _, _, _, fishing = GetProfessions()
    if not fishing then
        return nil
    end

    local name, icon, skill, maxSkill, _, _, skillLineID, bonus, _, _, currentSkillLineName = GetProfessionInfo(fishing)
    if not name then
        return nil
    end

    return self:BuildSnapshotInfo({
        name = name,
        icon = icon,
        skill = skill,
        maxSkill = maxSkill,
        skillLineID = skillLineID,
        bonus = bonus,
        currentSkillLineName = currentSkillLineName,
        professionIndex = fishing,
        professionSlotIndex = "fishing",
    })
end
