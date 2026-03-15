local _, GB = ...

function GB:HasFishingProfession()
    local _, _, _, fishing = GetProfessions()
    return fishing ~= nil
end

function GB:IsProfessionAvailable(profID)
    if profID == "fishing" then
        return self:HasFishingProfession() or self.hasFishing == true or (self.profMap and self.profMap[profID] ~= nil)
    end
    if self.profMap and self.profMap[profID] ~= nil then
        return true
    end
    local profDef = GB.GetProfDef and GB.GetProfDef(profID)
    if profDef and profDef.find then
        return GB.HasProfessionByName(profDef.find)
    end
    return false
end

function GB:GetProfessionDisplayInfo(profID)
    if self.profMap and self.profMap[profID] then
        return self.profMap[profID]
    end
    if profID ~= "fishing" then
        return nil
    end

    local _, _, _, fishing = GetProfessions()
    if not fishing then
        return nil
    end

    local name, icon, skill, maxSkill, _, _, skillLineID, bonus, _, _, currentSkillLineName = GetProfessionInfo(fishing)
    if not name then
        return nil
    end

    return {
        id = "fishing",
        label = "Fishing",
        icon = icon,
        skill = skill or 0,
        maxSkill = maxSkill or 0,
        bonus = bonus or 0,
        total = (skill or 0) + (bonus or 0),
        skillLineID = skillLineID,
        currentSkillLineName = currentSkillLineName,
        professionIndex = fishing,
        professionSlotIndex = "fishing",
    }
end

function GB:IsProfessionModuleEnabled(profID)
    local db = self.db.modules.professions[profID]
    return db and db.enabled ~= false
end

function GB:IsProfessionExpanded(profID)
    local db = self.db.modules.professions[profID]
    return db and db.expanded ~= false
end

function GB:SetProfessionExpanded(profID, expanded)
    self.db.modules.professions[profID].expanded = expanded and true or false
end

function GB:GetDesiredStat(profID)
    local db = self.db.modules.professions[profID]
    return (db and db.desiredStat) or "perception"
end

function GB:IsProfitProfessionTracked(profID)
    local tracking = self.db.modules and self.db.modules.profitTracking
    if not tracking then
        return false
    end
    return tracking[profID] ~= false
end

function GB:IsMidnightEnchantingProfitTracked()
    return self:IsProfitProfessionTracked("midnight_enchanting")
end

function GB:GetTrackedProfitProfessionMap()
    local tracked = {}
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        local available = self:IsProfessionAvailable(prof.id)
        if prof.id == "skinning" and self:IsProfitProfessionTracked(prof.id) then
            tracked[prof.id] = true
        elseif available and self:IsProfitProfessionTracked(prof.id) then
            tracked[prof.id] = true
        end
    end
    if self:IsMidnightEnchantingProfitTracked() and GB.HasProfessionByName("Enchanting") then
        tracked.midnight_enchanting = true
    end
    return tracked
end
