local _, GB = ...

GB.ProfessionBase = GB.ProfessionBase or {}
local Base = GB.ProfessionBase
local BASE_MT = { __index = Base }

function GB.ApplyProfessionBase(def)
    if getmetatable(def) ~= BASE_MT then
        setmetatable(def, BASE_MT)
    end
    return def
end

for _, def in ipairs(GB.GetProfessionDefs()) do
    GB.ApplyProfessionBase(def)
end

function Base:MatchesName(name)
    return type(name) == "string" and type(self.find) == "string" and name:find(self.find, 1, true) ~= nil
end

function Base:BuildSnapshotInfo(raw)
    local info = {
        id = self.id,
        label = self.label,
        icon = raw.icon,
        skill = raw.skill or 0,
        maxSkill = raw.maxSkill or 0,
        bonus = raw.bonus or 0,
        skillLineID = raw.skillLineID,
        currentSkillLineName = raw.currentSkillLineName,
        professionIndex = raw.professionIndex,
        professionSlotIndex = raw.professionSlotIndex,
    }
    info.total = info.skill + info.bonus
    return info
end

function Base:IsAvailable(addon)
    return (addon.profMap and addon.profMap[self.id] ~= nil) or (self.find and GB.HasProfessionByName(self.find)) or false
end

function Base:GetDisplayInfo(addon)
    return addon.profMap and addon.profMap[self.id] or nil
end

function Base:GetBuffCategoryIDs()
    return self.buffCategories or self.optionCategories or {}
end

function Base:CanTrackProfitWithoutAvailability()
    return self.trackProfitWithoutAvailability == true
end

function Base:GetEquipmentSlots(addon, info)
    return GB.GetProfessionEquipmentSlotsFromInfo(info)
end

function Base:GetToolEnchantInfo(addon, info)
    return GB.GetProfessionToolEnchantInfoFromInfo(info)
end

function Base:GetEquipmentTotals(addon, info)
    return GB.GetProfessionEquipmentTotalsFromInfo(info)
end

function Base:GetApiTotals(addon, info)
    return GB.GetProfessionApiTotalsFromInfo(info, addon and addon.profMap or nil)
end

function Base:GetBuffTotals(addon, activeOnly)
    return GB.GetProfessionBuffTotalsByID(addon, self.id, activeOnly)
end

function Base:GetBuffStates(addon)
    local states = {}
    for _, catID in ipairs(self:GetBuffCategoryIDs()) do
        local buff, aura = addon:GetRowBuff(catID, self.id)
        states[#states + 1] = {
            catID = catID,
            buff = buff,
            aura = aura,
        }
    end
    return states
end

function Base:GetStatSnapshot(addon)
    local info = self:GetDisplayInfo(addon)
    if not info then
        return nil
    end
    return GB.BuildProfessionStatSnapshot(addon, self.id, info)
end

function Base:GetVitals(addon)
    local info = self:GetDisplayInfo(addon)
    if not info then
        return nil
    end

    local slots = self:GetEquipmentSlots(addon, info) or { accessories = {} }
    local tool = slots.tool and {
        slotID = slots.tool,
        itemID = GetInventoryItemID("player", slots.tool),
        itemLink = GetInventoryItemLink("player", slots.tool),
        stats = GB.GetInventorySlotStats(slots.tool),
    } or nil

    local accessories = {}
    for _, slotID in ipairs(slots.accessories or {}) do
        accessories[#accessories + 1] = {
            slotID = slotID,
            itemID = GetInventoryItemID("player", slotID),
            itemLink = GetInventoryItemLink("player", slotID),
            stats = GB.GetInventorySlotStats(slotID),
        }
    end

    return {
        info = info,
        slots = slots,
        tool = tool,
        accessories = accessories,
        toolEnchant = self:GetToolEnchantInfo(addon, info),
        equipmentTotals = self:GetEquipmentTotals(addon, info),
        apiTotals = self:GetApiTotals(addon, info),
        statSnapshot = self:GetStatSnapshot(addon),
        buffStates = self:GetBuffStates(addon),
    }
end
