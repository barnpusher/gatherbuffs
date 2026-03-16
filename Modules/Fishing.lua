local _, GB = ...

local Fishing = GB.RegisterProfession({
    id = "fishing",
    label = "Fishing",
    find = "Fishing",
    optionCategories = { "fishing", "fishing_chum" },
    mainCard = true,
    showSettingsTab = true,
    gatherItems = {
        { name = "Arcane Wyrmfish",   ids = { 238371 } },
        { name = "Gore Guppy",        ids = { 238382 } },
        { name = "Lynxfish",          ids = { 238366 } },
        { name = "Root Crab",         ids = { 238367 } },
        { name = "Sin'dorei Swarmer", ids = { 238365 } },
        { name = "Blood Hunter",      ids = { 238377 } },
        { name = "Bloomtail Minnow",  ids = { 238369 } },
        { name = "Fungalskin Pike",   ids = { 238375 } },
        { name = "Restored Songfish", ids = { 238372 } },
        { name = "Shimmer Spinefish", ids = { 238370 } },
        { name = "Shimmersiren",      ids = { 238378 } },
        { name = "Sunwell Fish",      ids = { 238384 } },
        { name = "Tender Lumifin",    ids = { 238374 } },
        { name = "Eversong Trout",    ids = { 238383 } },
        { name = "Hollow Grouper",    ids = { 238381 } },
        { name = "Lucky Loa",         ids = { 238376 } },
        { name = "Null Voidfish",     ids = { 238380 } },
        { name = "Ominous Octopus",   ids = { 238373 } },
        { name = "Warping Wise",      ids = { 238379 } },
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
