local _, GB = ...

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

function GB:GetTrackedProfitProfessionMap()
    local tracked = {}
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        if self.profMap and self.profMap[prof.id] and self:IsProfessionModuleEnabled(prof.id) and self:IsProfitProfessionTracked(prof.id) then
            tracked[prof.id] = true
        end
    end
    return tracked
end
