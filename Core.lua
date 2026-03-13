local addonName, GB = ...

if type(GB) ~= "table" then
    GB = _G.GatherBuffs or {}
end
_G.GatherBuffs = GB

GB.ADDON_NAME = addonName or "GatherBuffs"

GB.DEFAULTS = {
    locked = false,
    hideInCombat = false,
    manuallyHidden = false,
    mainX = 200,
    mainY = -100,
    optX = nil,
    optY = nil,
    shardTracker = {
        spent = 0,
        lastQuantity = nil,
        nextWeeklyResetAt = 0,
    },
    ui = {
        backgroundOpacity = 0.60,
        rowOpacity = 0.50,
        scale = 1.00,
        showMinimapIcon = true,
        minimapAngle = 220,
    },
    modules = {
        globalExpanded = true,
        currenciesExpanded = true,
        profitExpanded = true,
        profitPriceSourceMode = "auto",
        profitPriceSource = "tsm",
        profitTracking = {
            mining = true,
            herbalism = true,
            skinning = true,
            fishing = true,
        },
        mainCollapsed = false,
        professions = {
            mining = { enabled = true, expanded = true, desiredStat = "perception" },
            herbalism = { enabled = true, expanded = true, desiredStat = "perception" },
            skinning = { enabled = true, expanded = true, desiredStat = "finesse" },
            fishing = { enabled = true, expanded = true },
        },
    },
    session = {
        startedAt = 0,
        loot = {},
        order = {},
        paused = true,
        pausedAt = 0,
        pausedTotal = 0,
    },
    currencies = {
        shard_of_dundun = { enabled = true },
    },
    categories = {
        food = { enabled = true, selectedKey = "food:242299" },
        phial = { enabled = true, selectedKey = "phial:241316" },
        steamphial = { enabled = true, selectedKey = "steamphial:191347" },
        potion = { enabled = true, selectedKey = "potion:124671" },
        fishing = { enabled = false, selectedKey = "fishing:1237974" },
        overload_mining = { enabled = true, selectedKey = "overload_mining:1225704" },
        overload_herbalism = { enabled = true, selectedKey = "overload_herbalism:1223879" },
        weaponstone = { enabled = true, selectedKey = "weaponstone:237373" },
        fishing_chum = { enabled = true, selectedKey = "fishing_chum:1237942" },
    },
}

GB.W = 408
GB.ROW_H = 20
GB.HDR_H = 22
GB.PAD = 6
GB.ICON_W = 18
GB.LBL_W = 44
GB.NM_W = 118
GB.BAR_W = 141
GB.CNT_W = 34

GB.PANEL_BG_COLOR = { 0.02, 0.02, 0.03, 0.45 }
GB.ROW_BG_COLOR = { 0.16, 0.16, 0.19, 0.72 }
GB.HEADER_BG_COLOR = { 0.16, 0.16, 0.19, 0.82 }
GB.FRAME_BG_COLOR = { 0.00, 0.00, 0.00, 0.60 }
GB.TREE_BG_COLOR = { 0.10, 0.10, 0.12, 0.72 }

GB.SHARD_OF_DUNDUN_CURRENCY_ID = 3376
GB.PROFESSION_WEEKLY_ITEMS = {
    herbalism = {
        { itemID = 238465, questIDs = { 81425, 81426, 81427, 81428, 81429 } },
        { itemID = 238466, questIDs = { 81430 } },
        { itemID = 237497, itemIDs = { 237497, 237498, 237499, 237500 }, countOnly = true },
    },
    mining = {
        { itemID = 237496, questIDs = { 88673, 88674, 88675, 88676, 88677 } },
        { itemID = 237506, questIDs = { 88678 } },
    },
    skinning = {
        { itemID = 238625, questIDs = { 88534, 88549, 88536, 88537, 88530 } },
        { itemID = 238626, questIDs = { 88529 } },
    },
}

GB.PROF_ICONS = {
    mining = "Interface/Icons/Trade_Mining",
    herbalism = "Interface/Icons/Trade_Herbalism",
    fishing = "Interface/Icons/Trade_Fishing",
    skinning = "Interface/Icons/INV_Misc_Pelt_Wolf_01",
}

GB.PROFIT_PRICE_SOURCE_MODES = {
    { id = "auto", label = "Auto" },
    { id = "manual", label = "Manual" },
}

GB.PROFIT_PRICE_SOURCES = {
    { id = "tsm", label = "TSM" },
    { id = "zygor_scan", label = "Zygor Scan" },
    { id = "zygor_median", label = "Zygor Median" },
    { id = "zygor_low", label = "Zygor Low" },
    { id = "auctionator", label = "Auctionator" },
}

GB.QUAL_ICON = {
    [1] = "|A:Professions-ChatIcon-Quality-12-Tier1:13:13|a",
    [2] = "|A:Professions-ChatIcon-Quality-12-Tier2:13:13|a",
    [3] = "|A:Professions-ChatIcon-Quality-12-Tier3:13:13|a",
}

function GB.ApplyDefaults(db, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(db[k]) ~= "table" then
                db[k] = {}
            end
            GB.ApplyDefaults(db[k], v)
        elseif db[k] == nil then
            db[k] = v
        end
    end
end

function GB.Trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function GB.GetUiConfig()
    if GB and GB.db and GB.db.ui then
        return GB.db.ui
    end
    return GB.DEFAULTS.ui
end

function GB.GetRowOpacity()
    local ui = GB.GetUiConfig()
    return math.max(0, math.min(1, ui.rowOpacity or GB.DEFAULTS.ui.rowOpacity))
end

function GB.SetRowBackground(row, r, g, b, a)
    if not row or not row.rowBG then
        return
    end
    row.rowBG:SetTexture("Interface/Buttons/WHITE8X8")
    row.rowBG:SetVertexColor(r or 0, g or 0, b or 0, (a or 0) * GB.GetRowOpacity())
end

function GB.Atan2Safe(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x == 0 then
        if y > 0 then
            return math.pi / 2
        end
        if y < 0 then
            return -math.pi / 2
        end
        return 0
    end
    local angle = math.atan(y / x)
    if x < 0 then
        angle = angle + math.pi
    end
    return angle
end

function GB.Trunc(s, maxLen)
    s = s or ""
    if #s <= maxLen then
        return s
    end
    return s:sub(1, maxLen - 3) .. "..."
end

function GB.FormatQualityText(quality)
    if not quality then
        return ""
    end
    return string.format("(Q%d)", quality)
end

function GB.FormatGoldSilver(copper)
    copper = math.max(0, math.floor(copper or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    if gold > 0 then
        return string.format("|cffffd700%dg|r |cffc7c7cf%02ds|r", gold, silver)
    end
    return string.format("|cffc7c7cf%02ds|r", silver)
end

function GB.FormatGoldPlain(copper)
    copper = math.max(0, math.floor(copper or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    if gold > 0 then
        return string.format("%dg %02ds", gold, silver)
    end
    if silver > 0 then
        return string.format("%ds", silver)
    end
    return string.format("%dc", copper % 100)
end

function GB.FormatTime(secs)
    if not secs or secs < 0 then
        return "0:00"
    end
    if secs == math.huge then
        return "inf"
    end
    local s = math.floor(secs)
    if s >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor((s % 3600) / 60), s % 60)
    end
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

function GB.GetProfitPriceSourceMode()
    local modules = GB.db and GB.db.modules
    local mode = modules and modules.profitPriceSourceMode
    if mode == "manual" then
        return "manual"
    end
    return "auto"
end

function GB.GetProfitPriceSource()
    local modules = GB.db and GB.db.modules
    local selected = modules and modules.profitPriceSource
    for _, entry in ipairs(GB.PROFIT_PRICE_SOURCES) do
        if entry.id == selected then
            return selected
        end
    end
    return GB.DEFAULTS.modules.profitPriceSource
end

function GB.GetProfitPriceSourceLabel(sourceID)
    for _, entry in ipairs(GB.PROFIT_PRICE_SOURCES) do
        if entry.id == sourceID then
            return entry.label
        end
    end
    return sourceID or "-"
end

function GB.GetCatDef(catID)
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        if cat.id == catID then
            return cat
        end
    end
end

function GB.GetProfDef(profID)
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        if prof.id == profID then
            return prof
        end
    end
end

function GB.GetBuffKey(catID, buff)
    if buff.itemIDs and buff.itemIDs[1] then
        return catID .. ":" .. buff.itemIDs[1]
    end
    if buff.spellID then
        return catID .. ":" .. buff.spellID
    end
    return catID .. ":" .. buff.name
end

function GB.GetBuffDef(catID, selectedKey)
    local cat = GB.GetCatDef(catID)
    if not cat then
        return nil
    end
    for _, buff in ipairs(cat.buffs) do
        if GB.GetBuffKey(catID, buff) == selectedKey then
            return buff
        end
    end
end

function GB.NormalizeSpellID(spellID)
    if spellID == nil then
        return nil
    end
    if type(spellID) == "number" then
        return spellID
    end
    local ok, normalized = pcall(tonumber, spellID)
    if ok then
        return normalized
    end
    return nil
end

function GB.GetBuffDefBySpellID(catID, spellID)
    local cat = GB.GetCatDef(catID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not cat or not normalizedSpellID then
        return nil
    end
    for _, buff in ipairs(cat.buffs) do
        if GB.NormalizeSpellID(buff.spellID) == normalizedSpellID then
            return buff
        end
    end
end

function GB.BuffMatchesProfession(buff, profID)
    if not profID or not buff.professions then
        return true
    end
    for _, allowed in ipairs(buff.professions) do
        if allowed == profID then
            return true
        end
    end
    return false
end

function GB.GetPlayerAura(spellID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not normalizedSpellID then
        return nil
    end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, normalizedSpellID)
        if ok and aura then
            return aura
        end
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName and C_Spell and C_Spell.GetSpellName then
        local okName, spellName = pcall(C_Spell.GetSpellName, normalizedSpellID)
        if okName and spellName then
            local okAura, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", spellName, "HELPFUL")
            if okAura and aura then
                return aura
            end
        end
    end
    return nil
end

function GB.GetBuffCount(buff)
    if not buff or not buff.itemIDs or #buff.itemIDs == 0 then
        return nil
    end
    local total = 0
    for _, itemID in ipairs(buff.itemIDs) do
        total = total + GetItemCount(itemID, false)
    end
    return total
end

function GB.GetTrackedItemCount(itemIDs)
    local total = 0
    for _, itemID in ipairs(itemIDs or {}) do
        total = total + GetItemCount(itemID, false)
    end
    return total
end

function GB.GetServerNow()
    if C_DateAndTime and C_DateAndTime.GetServerTimeLocal then
        local ok, serverNow = pcall(C_DateAndTime.GetServerTimeLocal)
        if ok and serverNow then
            return serverNow
        end
    end
    return time()
end

function GB.GetNextWeeklyResetAt(now)
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
        if ok and seconds and seconds > 0 then
            return now + seconds
        end
    end
    return 0
end

function GB.GetUseItemID(buff)
    if not buff or not buff.itemIDs or #buff.itemIDs == 0 then
        return nil
    end
    for _, itemID in ipairs(buff.itemIDs) do
        if GetItemCount(itemID, false) > 0 then
            return itemID
        end
    end
    return buff.itemIDs[1]
end

function GB.GetShardOfDundunInfo()
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, GB.SHARD_OF_DUNDUN_CURRENCY_ID)
    if ok and info and info.discovered then
        return info
    end
    return nil
end

function GB.IsQuestCompleted(questID)
    if not questID then
        return false
    end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, completed = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok then
            return completed
        end
    end
    if IsQuestFlaggedCompleted then
        local ok, completed = pcall(IsQuestFlaggedCompleted, questID)
        if ok then
            return completed
        end
    end
    return false
end

function GB.GetWeeklyItemProgress(itemDef)
    local earned = 0
    for _, questID in ipairs(itemDef.questIDs or {}) do
        if GB.IsQuestCompleted(questID) then
            earned = earned + 1
        end
    end
    return earned, #(itemDef.questIDs or {})
end

function GB.GetProfessionWeeklyItemText(profID)
    local defs = GB.PROFESSION_WEEKLY_ITEMS[profID]
    if not defs then
        return nil
    end
    local parts = {}
    for _, itemDef in ipairs(defs) do
        local icon = GetItemIcon(itemDef.itemID)
        local iconMarkup = icon and ("|T" .. icon .. ":14:14:0:0|t") or ""
        if itemDef.countOnly then
            parts[#parts + 1] = string.format("%s %d", iconMarkup, GB.GetTrackedItemCount(itemDef.itemIDs))
        else
            local earned, total = GB.GetWeeklyItemProgress(itemDef)
            parts[#parts + 1] = string.format("%s %d/%d", iconMarkup, earned, total)
        end
    end
    return table.concat(parts, "   ")
end

function GB.FormatShardDisplayText(info, spent, includeIcon)
    if not info then
        return ""
    end
    local parts = {}
    if includeIcon then
        parts[#parts + 1] = string.format("|T%d:14:14:0:0|t", info.iconFileID or 134400)
    end

    local held = math.max(0, info.quantity or 0)
    local heldMax = math.max(0, info.maxQuantity or 0)
    local farmedThisWeek = math.max(0, info.quantityEarnedThisWeek or 0)
    local weeklyMax = math.max(0, info.maxWeeklyQuantity or 0)
    local spentThisWeek = math.max(0, spent or 0)

    if heldMax > 0 then
        parts[#parts + 1] = string.format("%d/%d", held, heldMax)
    else
        parts[#parts + 1] = tostring(held)
    end

    if weeklyMax > 0 then
        parts[#parts + 1] = string.format("F %d/%d", farmedThisWeek, weeklyMax)
    else
        parts[#parts + 1] = string.format("F %d", farmedThisWeek)
    end

    if weeklyMax > 0 then
        parts[#parts + 1] = string.format("S %d/%d", spentThisWeek, weeklyMax)
    else
        parts[#parts + 1] = string.format("S %d", spentThisWeek)
    end

    return table.concat(parts, "  ")
end

function GB.MakeTotals()
    local totals = {}
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        totals[stat.id] = 0
    end
    return totals
end

function GB.AddStats(totals, buff)
    if not buff or not buff.stats then
        return
    end
    for statID, value in pairs(buff.stats) do
        totals[statID] = (totals[statID] or 0) + value
    end
end

function GB.FormatStat(statID, value)
    if statID == "speedPct" then
        return string.format("%d%%", value or 0)
    end
    return tostring(value or 0)
end

function GB.GetDesiredStatLabel(statID)
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        if stat.id == statID then
            return stat.label
        end
    end
    return statID or "-"
end

function GB.FloorToGoldSilver(copper)
    copper = math.max(0, math.floor(copper or 0))
    return copper - (copper % 100)
end

function GB.SnapshotProfessions()
    local map, order = {}, {}
    local primary1, primary2, archaeology, fishing, cooking = GetProfessions()
    for _, idx in ipairs({ primary1, primary2, archaeology, fishing, cooking }) do
        if idx then
            local name, icon, skill, maxSkill, _, _, _, bonus = GetProfessionInfo(idx)
            if name then
                for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
                    if name:find(prof.find, 1, true) and not map[prof.id] then
                        local info = {
                            id = prof.id,
                            label = prof.label,
                            icon = icon,
                            skill = skill or 0,
                            maxSkill = maxSkill or 0,
                            bonus = bonus or 0,
                        }
                        info.total = info.skill + info.bonus
                        if idx == primary1 then
                            info.professionSlotIndex = 1
                        elseif idx == primary2 then
                            info.professionSlotIndex = 2
                        elseif idx == fishing then
                            info.professionSlotIndex = "fishing"
                        elseif idx == cooking then
                            info.professionSlotIndex = "cooking"
                        end
                        map[prof.id] = info
                        table.insert(order, info)
                    end
                end
            end
        end
    end
    return map, order
end

function GB.GetProfessionEquipmentSlots(infoOrProfID, profMap)
    local info = infoOrProfID
    if type(infoOrProfID) == "string" then
        info = profMap and profMap[infoOrProfID]
    end
    if not info then
        return nil
    end
    if info.professionSlotIndex == 1 then
        return { tool = 20, accessories = { 21, 22 } }
    end
    if info.professionSlotIndex == 2 then
        return { tool = 23, accessories = { 24, 25 } }
    end
    if info.professionSlotIndex == "fishing" then
        return { tool = 28, accessories = {} }
    end
    if info.professionSlotIndex == "cooking" then
        return { tool = 26, accessories = { 27 } }
    end
    return nil
end

function GB.GetItemLinkEnchantID(itemLink)
    if not itemLink then
        return nil
    end
    local enchantID = itemLink:match("|Hitem:%d+:(%-?%d+):")
    enchantID = tonumber(enchantID)
    if enchantID and enchantID > 0 then
        return enchantID
    end
    return nil
end

function GB.GetProfessionToolEnchantInfo(infoOrProfID, profMap)
    local slots = GB.GetProfessionEquipmentSlots(infoOrProfID, profMap)
    if not slots or not slots.tool then
        return nil
    end
    local itemLink = GetInventoryItemLink("player", slots.tool)
    local enchantID = GB.GetItemLinkEnchantID(itemLink)
    if not enchantID then
        return { hasEnchant = false, itemLink = itemLink }
    end

    local enchantName
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, enchantID)
        if ok and name then
            enchantName = name
        end
    elseif GetSpellInfo then
        local name = GetSpellInfo(enchantID)
        if name then
            enchantName = name
        end
    end

    return {
        hasEnchant = true,
        enchantID = enchantID,
        enchantName = enchantName,
        itemLink = itemLink,
    }
end

function GB.HasProfessionByName(findText)
    if not findText or findText == "" then
        return false
    end
    for _, idx in ipairs({ GetProfessions() }) do
        if idx then
            local name = GetProfessionInfo(idx)
            if name and name:find(findText, 1, true) then
                return true
            end
        end
    end
    return false
end

function GB.GetNodeSkillSummary(profID)
    return nil
end
