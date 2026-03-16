local _, GB = ...

function GB:HasFishingProfession()
    local prof = GB.GetProfDef("fishing")
    return prof and prof:IsAvailable(self) or false
end

function GB:IsProfessionAvailable(profID)
    local prof = GB.GetProfDef(profID)
    return prof and prof:IsAvailable(self) or false
end

function GB:GetProfessionDisplayInfo(profID)
    local prof = GB.GetProfDef(profID)
    return prof and prof:GetDisplayInfo(self) or nil
end

function GB:IsProfessionModuleEnabled(profID)
    local db = self.db.modules.professions[profID]
    return db == nil or db.enabled ~= false
end

function GB:IsProfessionExpanded(profID)
    local db = self.db.modules.professions[profID]
    return db == nil or db.expanded ~= false
end

function GB:SetProfessionExpanded(profID, expanded)
    self.db.modules.professions[profID] = self.db.modules.professions[profID] or {}
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
    for _, prof in ipairs(GB.GetProfessionDefs()) do
        local available = prof:IsAvailable(self)
        if prof:CanTrackProfitWithoutAvailability() and self:IsProfitProfessionTracked(prof.id) then
            tracked[prof.id] = true
        elseif available and self:IsProfitProfessionTracked(prof.id) then
            tracked[prof.id] = true
        end
    end
    return tracked
end
