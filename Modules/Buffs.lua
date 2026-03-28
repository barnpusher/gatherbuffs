local _, GB = ...

local function CheckEquipped(cat, buff, profID)
    if not cat.equippedGear then
        return nil
    end
    if cat.id == "weaponstone" then
        local info = GB.GetProfessionDisplayInfo and GB:GetProfessionDisplayInfo(profID)
        if info then
            local profDef = GB.GetProfDef and GB.GetProfDef(profID) or nil
            local static = profDef and profDef.GetStaticVitals and profDef:GetStaticVitals(GB, info) or nil
            local enchantInfo = static and static.toolEnchant or GB.GetProfessionToolEnchantInfo(info)
            if enchantInfo and enchantInfo.hasEnchant then
                local enchantName = enchantInfo.enchantName
                local mappedSpellID = enchantInfo.spellID or (enchantInfo.enchantID and GB.GetToolEnchantSpellID and GB.GetToolEnchantSpellID(enchantInfo.enchantID))
                if mappedSpellID and buff and GB.BuffHasSpellID(buff, mappedSpellID) then
                    return { equipped = true, enchantID = enchantInfo.enchantID, enchantName = enchantName }
                end
                if enchantInfo.enchantID and buff and GB.BuffHasSpellID(buff, enchantInfo.enchantID) then
                    return { equipped = true, enchantID = enchantInfo.enchantID, enchantName = enchantName }
                end
                local slots = static and static.slots or GB.GetProfessionEquipmentSlots(info)
                local enchantStats = static and static.enchantStats or (slots and slots.tool and GB.GetInventorySlotEnchantStats(slots.tool) or nil)
                local selectedBuff = GB.GetSelectedBuff and GB:GetSelectedBuff(cat.id, profID) or nil
                if selectedBuff
                    and buff
                    and GB.GetBuffKey(cat.id, selectedBuff) == GB.GetBuffKey(cat.id, buff)
                    and GB.BuffStatsContainedInTotals
                    and GB.BuffStatsContainedInTotals(buff, enchantStats) then
                    return { equipped = true, enchantID = enchantInfo.enchantID, enchantName = enchantName }
                end
            end
        end
        return nil
    end
    if not (buff.itemIDs and C_Item and C_Item.IsEquippedItem) then
        return nil
    end
    for _, iid in ipairs(buff.itemIDs) do
        if C_Item.IsEquippedItem(iid) then
            return { equipped = true }
        end
    end
    return nil
end

function GB:ToggleMainCollapsed()
    self.db.modules.mainCollapsed = not self.db.modules.mainCollapsed
end

function GB:MigrateDB()
    if self.db and self.db.modules then
        local tracking = self.db.modules.profitTracking
        if tracking and tracking.enchanting == nil and tracking.midnight_enchanting ~= nil then
            tracking.enchanting = tracking.midnight_enchanting and true or false
        end
        if tracking then
            tracking.midnight_enchanting = nil
        end
        if self.db.modules.dundunExpanded == nil then
            if self.db.modules.currenciesExpanded ~= nil then
                self.db.modules.dundunExpanded = self.db.modules.currenciesExpanded and true or false
            else
                self.db.modules.dundunExpanded = true
            end
        end
    end
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        local db = self.db.categories[cat.id]
        if db and db.spellID ~= nil then
            db.spellID = GB.NormalizeSpellID(db.spellID) or db.spellID
        end
        if db and not db.selectedKey then
            local buff = GB.GetBuffDefBySpellID(cat.id, db.spellID) or cat.buffs[1]
            if buff then
                db.selectedKey = GB.GetBuffKey(cat.id, buff)
            end
        end
    end
    local tracker = self.db.shardTracker or {}
    tracker.spent = math.max(0, tonumber(tracker.spent) or 0)
    tracker.lastQuantity = tonumber(tracker.lastQuantity)
    tracker.nextWeeklyResetAt = tonumber(tracker.nextWeeklyResetAt) or 0
    self.db.shardTracker = tracker
end

function GB:RefreshShardTracker()
    local tracker = self.db.shardTracker
    if not tracker then
        return
    end

    local now = GB.GetServerNow()
    if tracker.nextWeeklyResetAt == 0 then
        tracker.nextWeeklyResetAt = GB.GetNextWeeklyResetAt(now)
    elseif tracker.nextWeeklyResetAt > 0 and now >= tracker.nextWeeklyResetAt then
        tracker.spent = 0
        tracker.lastQuantity = nil
        tracker.nextWeeklyResetAt = GB.GetNextWeeklyResetAt(now)
    end

    if tracker.lastQuantity == nil then
        local info = GB.GetShardOfDundunInfo()
        if info then
            tracker.lastQuantity = info.quantity or 0
        end
    end
end

function GB:GetShardSpentThisWeek(info)
    self:RefreshShardTracker()
    info = info or GB.GetShardOfDundunInfo()
    local trackedSpent = (self.db.shardTracker and self.db.shardTracker.spent) or 0
    local derivedSpent = 0
    if info then
        local held = math.max(0, info.quantity or 0)
        local farmed = math.max(0, info.quantityEarnedThisWeek or 0)
        derivedSpent = math.max(0, farmed - held)
        local weeklyMax = math.max(0, info.maxWeeklyQuantity or 0)
        if weeklyMax > 0 then
            derivedSpent = math.min(derivedSpent, weeklyMax)
        end
    end
    return math.max(trackedSpent, derivedSpent)
end

function GB:HandleShardCurrencyUpdate(currencyType, quantity, quantityChange)
    if currencyType and currencyType ~= GB.SHARD_OF_DUNDUN_CURRENCY_ID then
        return
    end

    self:RefreshShardTracker()
    local tracker = self.db.shardTracker
    if not tracker then
        return
    end

    local currentQuantity = quantity
    if currentQuantity == nil then
        local info = GB.GetShardOfDundunInfo()
        currentQuantity = info and info.quantity or nil
    end

    if quantityChange and quantityChange < 0 then
        tracker.spent = tracker.spent + math.abs(quantityChange)
    elseif currentQuantity ~= nil and tracker.lastQuantity ~= nil and currentQuantity < tracker.lastQuantity then
        tracker.spent = tracker.spent + (tracker.lastQuantity - currentQuantity)
    end

    if currentQuantity ~= nil then
        tracker.lastQuantity = currentQuantity
    end
end

function GB:GetCategorySelectionKey(catID, profID)
    local db = self.db.categories[catID]
    if not db then
        return nil
    end
    if profID and db.selectedKeys and db.selectedKeys[profID] then
        return db.selectedKeys[profID]
    end
    return db.selectedKey
end

function GB:GetCategoryEnabled(catID, profID)
    local db = self.db.categories[catID]
    if not db then
        return false
    end
    if profID and db.enabledByProf and db.enabledByProf[profID] ~= nil then
        return db.enabledByProf[profID] ~= false
    end
    return db.enabled ~= false
end

function GB:SetCategoryEnabled(catID, enabled, profID)
    local db = self.db.categories[catID]
    if not db then
        return
    end
    if profID then
        db.enabledByProf = db.enabledByProf or {}
        db.enabledByProf[profID] = enabled and true or false
    else
        db.enabled = enabled and true or false
    end
    GB.vitalsNeedsRefresh = true
end

function GB:SetCategorySelectionKey(catID, selectedKey, profID)
    local db = self.db.categories[catID]
    if not db then
        return
    end
    if profID then
        db.selectedKeys = db.selectedKeys or {}
        db.selectedKeys[profID] = selectedKey
    else
        db.selectedKey = selectedKey
    end
    GB.vitalsNeedsRefresh = true
end

function GB:GetSelectedBuff(catID, profID)
    local db = self.db.categories[catID]
    if not db then
        return nil
    end
    local selectedKey = self:GetCategorySelectionKey(catID, profID)
    local buff = GB.GetBuffDef(catID, selectedKey)
    if buff then
        return buff
    end
    if type(selectedKey) == "string" then
        local legacyID = tonumber(selectedKey:match(":(%d+)$"))
        if legacyID then
            buff = GB.GetBuffDefBySpellID(catID, legacyID)
            if not buff then
                local cat = GB.GetCatDef(catID)
                for _, candidate in ipairs((cat and cat.buffs) or {}) do
                    for _, itemID in ipairs(candidate.itemIDs or {}) do
                        if itemID == legacyID then
                            buff = candidate
                            break
                        end
                    end
                    if buff then
                        break
                    end
                end
            end
            if buff then
                self:SetCategorySelectionKey(catID, GB.GetBuffKey(catID, buff), profID)
                return buff
            end
        end
    end
    buff = GB.GetBuffDefBySpellID(catID, db.spellID)
    if buff then
        self:SetCategorySelectionKey(catID, GB.GetBuffKey(catID, buff), profID)
        return buff
    end
    local cat = GB.GetCatDef(catID)
    return cat and cat.buffs[1] or nil
end

function GB:GetRowBuff(catID, profID)
    local cat = GB.GetCatDef(catID)
    if not cat then
        return nil, nil
    end
    if not profID then
        local buff = self:GetSelectedBuff(catID)
        if not buff then
            return nil, nil
        end
        local aura = GB.GetPlayerAuraForBuff(buff) or CheckEquipped(cat, buff, profID)
        if aura and not aura.equipped then
            buff = GB.ResolveAuraBuff(catID, aura, profID, buff) or buff
        end
        return buff, aura
    end
    local selected, fallback = self:GetSelectedBuff(catID, profID), nil
    for _, buff in ipairs(cat.buffs) do
        if GB.BuffMatchesProfession(buff, profID) then
            if not fallback or (selected and GB.GetBuffKey(catID, buff) == GB.GetBuffKey(catID, selected)) then
                fallback = buff
            end
            local aura = GB.GetPlayerAuraForBuff(buff) or CheckEquipped(cat, buff, profID)
            if aura then
                if not aura.equipped then
                    buff = GB.ResolveAuraBuff(catID, aura, profID, buff) or buff
                end
                return buff, aura
            end
        end
    end
    return fallback, nil
end

function GB:GetCommonTotals(activeOnly)
    local totals = GB.MakeTotals()
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        local db = self.db.categories[cat.id]
        if cat.scope == "common" and db and db.enabled then
            local buff, aura = self:GetRowBuff(cat.id)
            if buff and (not activeOnly or aura) then
                GB.AddStats(totals, buff)
            end
        end
    end
    return totals
end

function GB:UpdateSummary()
    local inCombat = InCombatLockdown()
    if self.combatText then
        self.combatText:Hide()
    end
    self.commonPanel.title:Show()
    if inCombat then
        self.commonPanel.summary:SetText("|cffdd3333⚔ In Combat|r")
        return
    end
    local active, maxTracked = 0, 0
    for _, row in ipairs(self.activeCommonRows or {}) do
        local buff, aura = self:GetRowBuff(row.catID, row.profID)
        if buff and buff.spellID then
            maxTracked = maxTracked + 1
            if aura then
                active = active + 1
            end
        end
    end
    local summaryText = ""
    if not self.db.modules.globalExpanded then
        summaryText = string.format("Buffs: |cff44ff44%d|r / |cffcfd6e6%d|r", active, maxTracked)
    end
    self.commonPanel.summary:SetText(summaryText)
end
