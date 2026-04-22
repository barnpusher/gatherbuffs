local _, GB = ...

function GB:ShouldShowMainFrame()
    local hasTrackedContent = (#(self.profOrder or {}) > 0) or self.hasFishing or self.hasProfitProfession
    if not hasTrackedContent then
        return false
    end
    if self.db and self.db.manuallyHidden then
        return false
    end
    if self.db and self.db.hideInCombat and InCombatLockdown() then
        return false
    end
    return true
end

function GB:RefreshMainFrameVisibility()
    if not self.mainFrame then
        return
    end
    self.mainFrame:SetShown(self:ShouldShowMainFrame())
end

function GB:SetManualHidden(hidden)
    if not self.db then
        return
    end
    local wasHidden = self.db.manuallyHidden == true
    self.db.manuallyHidden = hidden and true or false
    self:RefreshMainFrameVisibility()
    if wasHidden and not self.db.manuallyHidden and (#(self.profOrder or {}) > 0 or self.hasFishing or self.hasProfitProfession) then
        self:Rebuild()
        self:UpdateBars()
    end
end

function GB:CheckProfession()
    self.profMap, self.profOrder = GB.SnapshotProfessions()
    self.hasFishing = self:HasFishingProfession()
    self.hasProfitProfession = self:HasTrackedProfitProfession()
    if #self.profOrder > 0 or self.hasFishing or self.hasProfitProfession then
        self:Rebuild()
        self:RefreshMainFrameVisibility()
        return true
    else
        self:RefreshMainFrameVisibility()
        if self.optFrame then
            self.optFrame:Hide()
        end
    end
    return false
end

function GB:Init()
    GatherBuffsCharDB = GatherBuffsCharDB or {}
    GatherBuffsDB = GatherBuffsDB or {}
    if next(GatherBuffsDB) and not GatherBuffsCharDB._migrated then
        for k, v in pairs(GatherBuffsDB) do
            if GatherBuffsCharDB[k] == nil then
                GatherBuffsCharDB[k] = v
            end
        end
        GatherBuffsCharDB._migrated = true
        GatherBuffsDB = {}
    end
    GB.ApplyDefaults(GatherBuffsCharDB, GB.DEFAULTS)
    self.db = GatherBuffsCharDB
    self:MigrateDB()
    self:LoadSessionState()
    if not self.sessionStart or self.sessionStart == 0 then
        self.sessionStart = time()
        self.sessionPaused = true
        self.sessionPausedAt = time()
        self.sessionPausedTotal = 0
        self:SaveSessionState()
    end
    self.gatherLookup = GB.BuildGatherLookup()
    self:InvalidateItemCountCache()
    self:EnsureInventoryBaseline()
    self:CaptureInventorySnapshot()
    self:RefreshShardTracker()
    self:BuildStaticUI()
    self:BuildMinimapButton()
    self:ApplyUiSettings()
    self:CheckProfession()
    self:UpdateBars()

    local evf = CreateFrame("Frame")
    evf:RegisterEvent("UNIT_AURA")
    evf:RegisterEvent("BAG_UPDATE_DELAYED")
    evf:RegisterEvent("CHAT_MSG_LOOT")
    evf:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
    evf:RegisterEvent("LOOT_OPENED")
    evf:RegisterEvent("LOOT_CLOSED")
    evf:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    evf:RegisterEvent("SKILL_LINES_CHANGED")
    evf:RegisterEvent("SKILL_LINE_SPECS_RANKS_CHANGED")
    evf:RegisterEvent("SKILL_LINE_SPECS_UNLOCKED")
    evf:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    evf:RegisterEvent("PLAYER_ENTERING_WORLD")
    evf:RegisterEvent("PLAYER_REGEN_ENABLED")
    evf:RegisterEvent("PLAYER_REGEN_DISABLED")
    evf:RegisterEvent("MERCHANT_SHOW")
    evf:RegisterEvent("MERCHANT_CLOSED")
    evf:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
        if event == "MERCHANT_SHOW" then
            GB.merchantIsOpen = true
            GB.lastLootAt = time()
            return
        elseif event == "MERCHANT_CLOSED" then
            GB.merchantIsOpen = false
            GB.lastLootAt = time()
            return
        elseif event == "UNIT_AURA" and arg1 == "player" then
            GB:MaybeBlockDisenchant()
            if InCombatLockdown() then
                return
            end
            GB.vitalsNeedsRefresh = true
            GB:UpdateBars()
        elseif event == "CURRENT_SPELL_CAST_CHANGED" then
            GB:MaybeBlockDisenchant()
        elseif event == "LOOT_OPENED" then
            GB:HandleLootOpened()
        elseif event == "LOOT_CLOSED" then
            GB:HandleLootClosed()
        elseif event == "CHAT_MSG_LOOT" then
            GB:HandleLoot(arg1)
            GB:UpdateProfit()
        elseif event == "BAG_UPDATE_DELAYED" then
            GB:InvalidateItemCountCache()
            GB:ProcessInventoryLootDelta()
            GB:ProcessPendingLoot()
            GB:UpdateBars()
        elseif event == "CURRENCY_DISPLAY_UPDATE" then
            GB:HandleShardCurrencyUpdate(arg1, arg2, arg3)
            if not GB:CheckProfession() then
                GB:UpdateBars()
            end
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            if event == "PLAYER_REGEN_ENABLED" then
                GB.vitalsNeedsRefresh = true
            end
            if GB.db.hideInCombat and event == "PLAYER_REGEN_ENABLED" then
                GB:Rebuild()
                GB:UpdateBars()
            elseif not GB.db.hideInCombat then
                GB:Rebuild()
                GB:UpdateBars()
            end
            GB:RefreshMainFrameVisibility()
        else
            if event == "SKILL_LINES_CHANGED"
                or event == "SKILL_LINE_SPECS_RANKS_CHANGED"
                or event == "SKILL_LINE_SPECS_UNLOCKED"
                or event == "PLAYER_EQUIPMENT_CHANGED"
                or event == "PLAYER_ENTERING_WORLD" then
                GB:InvalidateProfessionStaticCache()
            end
            GB:CheckProfession()
            GB:UpdateBars()
        end
    end)

    local tick = 0
    self.mainFrame:SetScript("OnUpdate", function(_, dt)
        tick = tick + dt
        if tick >= 1.0 then
            tick = 0
            GB:CheckAutoInactivePause()
            if InCombatLockdown() then
                return
            end
            if not (GB.mainFrame and GB.mainFrame:IsShown()) then
                return
            end
            GB:UpdateBars()
        end
    end)
end

SLASH_GATHERBUFFS1, SLASH_GATHERBUFFS2 = "/gatherbuffs", "/gb"
SlashCmdList.GATHERBUFFS = function(msg)
    msg = GB.Trim(string.lower(msg or ""))
    if msg == "" or msg == "toggle" then
        if GB.db.manuallyHidden then
            GB:SetManualHidden(false)
        elseif GB.mainFrame:IsShown() then
            GB:SetManualHidden(true)
        else
            GB:SetManualHidden(false)
        end
    elseif msg == "config" or msg == "settings" or msg == "opt" then
        GB:ToggleOptions()
    elseif msg == "reset" then
        GB:ResetMainPosition()
        print("|cffaaffaaGatherBuffs|r: Position reset.")
    elseif msg == "newsession" then
        GB:ResetSession()
        GB:UpdateProfit()
        print("|cffaaffaaGatherBuffs|r: New session started.")
    elseif msg == "copy" then
        GB:ToggleReportPopup()
    elseif msg == "lootlog" then
        GB:ToggleLootLog()
    elseif msg == "lootdebug" then
        GB.lootDebug = not GB.lootDebug
        print("|cffaaffaaGatherBuffs|r: Loot debug " .. (GB.lootDebug and "|cff00ff00ON|r" or "|cffff4444OFF|r") .. " - mine/herb something to see output.")
        if GB.lootDebug then
            local profKeys = {}
            for k in pairs(GB.profMap or {}) do
                profKeys[#profKeys + 1] = k
            end
            print("|cffaaffaaGB:|r profMap: " .. (#profKeys > 0 and table.concat(profKeys, ", ") or "(empty - no gathering profs detected)"))
        end
    elseif msg == "debug" then
        local lines = {}
        local function L(s)
            table.insert(lines, s or "")
        end
        local function FormatTotals(totals)
            if not totals then
                return "nil"
            end
            local parts = {}
            for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
                local statID = stat.id
                parts[#parts + 1] = string.format("%s=%s", statID, GB.FormatStat(statID, totals[statID] or 0))
            end
            return table.concat(parts, "  ")
        end

        L("=== Tracked categories ===")
        for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
            local db = GB.db.categories[cat.id]
            if db and db.enabled then
                if cat.id == "weaponstone" then
                    for _, prof in ipairs(GB.GetProfessionDefs()) do
                        if prof:UsesWeaponstone() and GB:IsProfessionAvailable(prof.id) then
                            local buff, aura = GB:GetRowBuff(cat.id, prof.id)
                            if buff then
                                L(string.format("  [%s:%s] spellID=%-8s  %s  %s", cat.id, prof.id, tostring(buff.spellID), GB.GetBuffDisplayName(buff) or "?", aura and "FOUND" or "missing"))
                            end
                        end
                    end
                else
                    local profID = cat.professions and cat.professions[1] or nil
                    local buff, aura = GB:GetRowBuff(cat.id, profID)
                    if buff then
                        L(string.format("  [%s] spellID=%-8s  %s  %s", cat.id, tostring(buff.spellID), GB.GetBuffDisplayName(buff) or "?", aura and "FOUND" or "missing"))
                    end
                end
            end
        end

        L("")
        L("=== All HELPFUL auras on player ===")
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local i = 1
            while true do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                if not aura then
                    break
                end
                local left = ""
                if aura.expirationTime and aura.expirationTime > 0 then
                    left = string.format("  %.0fs left", aura.expirationTime - GetTime())
                end
                L(string.format("  [%d] spellId=%-8s  %s%s", i, tostring(aura.spellId), aura.name or "?", left))
                i = i + 1
            end
        end

        L("")
        L("=== Weapon enchants ===")
        local hasMH, mhExp, mhCharges, mhEnchID, hasOH, ohExp, ohCharges, ohEnchID = GetWeaponEnchantInfo()
        if hasMH then
            L(string.format("  MainHand: enchantID=%-8s  %.0fs left  charges=%s", tostring(mhEnchID), (mhExp or 0) / 1000, tostring(mhCharges)))
        else
            L("  MainHand: none")
        end
        if hasOH then
            L(string.format("  OffHand:  enchantID=%-8s  %.0fs left  charges=%s", tostring(ohEnchID), (ohExp or 0) / 1000, tostring(ohCharges)))
        end

        L("")
        L("=== Equipped profession tools & accessories ===")
        for _, prof in ipairs(GB.GetProfessionDefs()) do
            local vitals = prof:GetVitals(GB)
            local info = vitals and vitals.info or nil
            if info then
                local slots = vitals.slots
                if vitals.tool then
                    local toolID = vitals.tool.itemID
                    if toolID then
                        local name = GB.GetItemNameByID(toolID)
                        L(string.format("  %s Tool: id=%-8d  %s", info.label, toolID, name or "?"))
                        local enchantInfo = vitals.toolEnchant
                        if enchantInfo and enchantInfo.hasEnchant then
                            L(string.format(
                                "  %s Tool Enchant: id=%-8d  spellID=%-8s  %s",
                                info.label,
                                enchantInfo.enchantID,
                                tostring(enchantInfo.spellID),
                                enchantInfo.enchantName or "?"
                            ))
                            if slots and slots.tool then
                                local enchantTotals = GB.GetInventorySlotEnchantStats(slots.tool)
                                local equipmentTotals = GB.GetProfessionEquipmentTotalsFromInfo(info)
                                local apiTotals = GB.GetProfessionApiTotalsFromInfo(info, GB.profMap)
                                local activeBuffTotals = GB.GetProfessionBuffTotalsByID(GB, info.id, true)
                                local inferredTotals = nil
                                if apiTotals then
                                    inferredTotals = GB.MakeTotals()
                                    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
                                        local statID = stat.id
                                        inferredTotals[statID] = (apiTotals[statID] or 0) - (equipmentTotals[statID] or 0) - (activeBuffTotals[statID] or 0)
                                    end
                                end
                                L(string.format("  %s Tool Enchant Stats: %s", info.label, FormatTotals(enchantTotals)))
                                L(string.format("  %s Equip Totals: %s", info.label, FormatTotals(equipmentTotals)))
                                L(string.format("  %s API Totals: %s", info.label, FormatTotals(apiTotals)))
                                L(string.format("  %s Active Buff Totals: %s", info.label, FormatTotals(activeBuffTotals)))
                                L(string.format("  %s Inferred Enchant Totals: %s", info.label, FormatTotals(inferredTotals)))
                            end
                        else
                            L(string.format("  %s Tool Enchant: none", info.label))
                        end
                    else
                        L(string.format("  %s Tool: none", info.label))
                    end
                end
                for index, accessory in ipairs(vitals.accessories or {}) do
                    local itemID = accessory.itemID
                    if itemID then
                        local name = GB.GetItemNameByID(itemID)
                        L(string.format("  %s Accessory %d: id=%-8d  %s", info.label, index, itemID, name or "?"))
                    else
                        L(string.format("  %s Accessory %d: none", info.label, index))
                    end
                end
            end
        end

        GB:ShowDebugWindow(table.concat(lines, "\n"))
        for _, line in ipairs(lines) do
            if line ~= "" then
                print("|cffaaffaaGB:|r " .. line)
            end
        end
    else
        print("|cffaaffaaGatherBuffs|r: /gb [toggle|config|reset|newsession|copy|debug|lootdebug|lootlog]")
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    GB:Init()
end)
