local _, GB = ...

local Fishing = GB.RegisterProfession({
    id = "fishing",
    label = "Fishing",
    find = "Fishing",
    simpleSkillSummary = true,
    supportsDesiredStatSelection = false,
    optionCategories = { "fishing", "fishing_chum" },
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
