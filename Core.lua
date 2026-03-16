local addonName, GB = ...

if type(GB) ~= "table" then
    GB = _G.GatherBuffs or {}
end
_G.GatherBuffs = GB

GB.ADDON_NAME = addonName or "GatherBuffs"
GB.professionRegistry = GB.professionRegistry or {}
GB.professionDefs = GB.professionDefs or {}

function GB.RegisterProfession(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or def.id == "" then
        error("GB.RegisterProfession requires a profession definition with a non-empty id")
    end

    if GB.ApplyProfessionBase then
        GB.ApplyProfessionBase(def)
    end

    local existingIndex
    for i, existing in ipairs(GB.professionDefs) do
        if existing.id == def.id then
            existingIndex = i
            break
        end
    end

    if existingIndex then
        GB.professionDefs[existingIndex] = def
    else
        GB.professionDefs[#GB.professionDefs + 1] = def
    end
    GB.professionRegistry[def.id] = def
    return def
end

function GB.GetProfessionDefs()
    return GB.professionDefs
end

local function ResolveProfessionInfoAndDef(infoOrProfID, profMap)
    local info = infoOrProfID
    local profDef

    if type(infoOrProfID) == "string" then
        profDef = GB.GetProfDef(infoOrProfID)
        info = (profMap and profMap[infoOrProfID]) or (GB.GetProfessionDisplayInfo and GB:GetProfessionDisplayInfo(infoOrProfID)) or nil
    elseif type(infoOrProfID) == "table" and infoOrProfID.id then
        profDef = GB.GetProfDef(infoOrProfID.id)
    end

    return info, profDef
end

GB.DEFAULTS = {
    locked = false,
    hideInCombat = false,
    manuallyHidden = false,
    mainX = 200,
    mainY = -100,
    optX = nil,
    optY = nil,
    infoX = nil,
    infoY = nil,
    shardTracker = {
        spent = 0,
        lastQuantity = nil,
        nextWeeklyResetAt = 0,
    },
    ui = {
        backgroundOpacity = 0.60,
        barOpacity = 0.50,
        rowOpacity = 0.50,
        textOpacity = 1.00,
        scale = 1.00,
        showMinimapIcon = true,
        minimapAngle = 220,
    },
    modules = {
        globalExpanded = true,
        dundunExpanded = true,
        profitExpanded = true,
        profitPriceSourceMode = "auto",
        profitPriceSource = "tsm",
        profitAutoStartOnLoot = false,
        profitAutoInactivePause = false,
        profitAutoInactivePauseMinutes = 5,
        alertOnBuffExpiry = false,
        alertOnLowStock = false,
        profitVendorLoot = false,
        profitVendorLootExcludeGear = false,
        profitTracking = {
            mining = true,
            herbalism = true,
            skinning = true,
            fishing = true,
            tailoring = true,
            enchanting = false,
        },
        mainCollapsed = false,
        professions = {
            mining = { enabled = true, expanded = true, desiredStat = "perception" },
            herbalism = { enabled = true, expanded = true, desiredStat = "perception" },
            skinning = { enabled = true, expanded = true, desiredStat = "finesse" },
            fishing = { enabled = true, expanded = true },
            tailoring = { enabled = true, expanded = true },
            enchanting = { enabled = true, expanded = true },
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

GB.ahSourceRegistry = {}
GB.ahSourceOrder = {}
GB.PROFIT_PRICE_SOURCES = {}

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

function GB.GetBarOpacity()
    local ui = GB.GetUiConfig()
    local value = ui.barOpacity
    if value == nil then
        value = ui.rowOpacity
    end
    if value == nil then
        value = GB.DEFAULTS.ui.barOpacity or GB.DEFAULTS.ui.rowOpacity
    end
    return math.max(0, math.min(1, value))
end

function GB.GetTextOpacity()
    local ui = GB.GetUiConfig()
    return math.max(0, math.min(1, ui.textOpacity or GB.DEFAULTS.ui.textOpacity))
end

function GB.SetRowBackground(row, r, g, b, a)
    if not row or not row.rowBG then
        return
    end
    row.rowBG:SetTexture("Interface/Buttons/WHITE8X8")
    row.rowBG:SetVertexColor(r or 0, g or 0, b or 0, (a or 0) * GB.GetBarOpacity())
end

function GB.SetStatusBarColor(bar, r, g, b, a)
    if not bar then
        return
    end
    bar:SetStatusBarColor(r or 0, g or 0, b or 0, (a or 1) * GB.GetBarOpacity())
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

local function SortAhSources(a, b)
    local left = GB.ahSourceRegistry[a]
    local right = GB.ahSourceRegistry[b]
    local leftOrder = left and left.GetSortOrder and left:GetSortOrder() or math.huge
    local rightOrder = right and right.GetSortOrder and right:GetSortOrder() or math.huge
    if leftOrder ~= rightOrder then
        return leftOrder < rightOrder
    end
    local leftLabel = left and left.GetLabel and left:GetLabel() or a
    local rightLabel = right and right.GetLabel and right:GetLabel() or b
    return leftLabel < rightLabel
end

local function RebuildPriceSourceList()
    for i = #GB.PROFIT_PRICE_SOURCES, 1, -1 do
        GB.PROFIT_PRICE_SOURCES[i] = nil
    end
    for _, sourceID in ipairs(GB.ahSourceOrder) do
        local source = GB.ahSourceRegistry[sourceID]
        if source then
            GB.PROFIT_PRICE_SOURCES[#GB.PROFIT_PRICE_SOURCES + 1] = {
                id = sourceID,
                label = source:GetLabel(),
            }
        end
    end
end

function GB.RegisterAhSource(source)
    if not source or type(source.GetID) ~= "function" then
        return
    end
    local sourceID = source:GetID()
    if not sourceID or sourceID == "" then
        return
    end
    local exists = GB.ahSourceRegistry[sourceID] ~= nil
    GB.ahSourceRegistry[sourceID] = source
    if not exists then
        GB.ahSourceOrder[#GB.ahSourceOrder + 1] = sourceID
    end
    table.sort(GB.ahSourceOrder, SortAhSources)
    RebuildPriceSourceList()
end

function GB.GetAhSource(sourceID)
    return GB.ahSourceRegistry[sourceID]
end

function GB.GetAhSources()
    local sources = {}
    for _, sourceID in ipairs(GB.ahSourceOrder) do
        local source = GB.ahSourceRegistry[sourceID]
        if source then
            sources[#sources + 1] = source
        end
    end
    return sources
end

function GB.GetAutoPriceSourceOrder()
    local sourceIDs = {}
    for _, source in ipairs(GB.GetAhSources()) do
        if source.IsInAutoOrder and source:IsInAutoOrder() then
            sourceIDs[#sourceIDs + 1] = source:GetID()
        end
    end
    return sourceIDs
end

function GB.IsAhSourceAvailable(sourceID)
    local source = GB.GetAhSource(sourceID)
    return source and source.IsAvailable and source:IsAvailable() or false
end

function GB.HasAnyPriceSourceAvailable()
    for _, source in ipairs(GB.GetAhSources()) do
        if source.IsAvailable and source:IsAvailable() then
            return true
        end
    end
    return false
end

function GB.GetCurrentPriceSource()
    local mode = GB.GetProfitPriceSourceMode()
    if mode == "manual" then
        return GB.GetAhSource(GB.GetProfitPriceSource())
    end
    for _, sourceID in ipairs(GB.GetAutoPriceSourceOrder()) do
        local source = GB.GetAhSource(sourceID)
        if source and source.IsAvailable and source:IsAvailable() then
            return source
        end
    end
    return nil
end

function GB.GetProfitPriceSource()
    local modules = GB.db and GB.db.modules
    local selected = modules and modules.profitPriceSource
    if GB.GetAhSource(selected) then
        return selected
    end
    return GB.DEFAULTS.modules.profitPriceSource
end

function GB.GetProfitPriceSourceLabel(sourceID)
    local source = GB.GetAhSource(sourceID)
    if source then
        return source:GetLabel()
    end
    return sourceID or "-"
end

function GB:GetPrice(itemID)
    if not itemID then
        return nil
    end

    local mode = GB.GetProfitPriceSourceMode()
    if mode == "manual" then
        local source = GB.GetAhSource(GB.GetProfitPriceSource())
        if source and source.GetPrice then
            return source:GetPrice(itemID)
        end
        return nil
    end

    for _, sourceID in ipairs(GB.GetAutoPriceSourceOrder()) do
        local source = GB.GetAhSource(sourceID)
        local value = source and source.GetPrice and source:GetPrice(itemID)
        if value then
            return value
        end
    end

    return nil
end

function GB.GetCatDef(catID)
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        if cat.id == catID then
            return cat
        end
    end
end

function GB.GetProfDef(profID)
    return GB.professionRegistry[profID]
end

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
            if okAura and aura and GB.NormalizeSpellID(aura.spellId) == normalizedSpellID then
                return aura
            end
        end
    end
    return nil
end

function GB.GetSpellCooldownInfo(spellID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not normalizedSpellID then
        return nil
    end

    local startTime, duration, isEnabled, modRate
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, normalizedSpellID)
        if ok and info then
            startTime = info.startTime
            duration = info.duration
            isEnabled = info.isEnabled
            modRate = info.modRate
        end
    end
    if startTime == nil and GetSpellCooldown then
        local ok, s, d, e, m = pcall(GetSpellCooldown, normalizedSpellID)
        if ok then
            startTime, duration, isEnabled, modRate = s, d, e, m
        end
    end

    duration = tonumber(duration) or 0
    startTime = tonumber(startTime) or 0
    modRate = tonumber(modRate) or 1
    if modRate <= 0 then
        modRate = 1
    end
    if isEnabled == 0 or duration <= 1.5 or startTime <= 0 then
        return nil
    end

    local remaining = ((startTime + duration) - GetTime()) / modRate
    if remaining <= 0 then
        return nil
    end

    return {
        startTime = startTime,
        duration = duration / modRate,
        remaining = remaining,
    }
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
        parts[#parts + 1] = string.format("Inv.: %d/%d", held, heldMax)
    else
        parts[#parts + 1] = string.format("Inv.: %d", held)
    end

    if weeklyMax > 0 then
        parts[#parts + 1] = string.format("Farm: %d/%d", farmedThisWeek, weeklyMax)
    else
        parts[#parts + 1] = string.format("Farm: %d", farmedThisWeek)
    end

    if weeklyMax > 0 then
        parts[#parts + 1] = string.format("Spent: %d/%d", spentThisWeek, weeklyMax)
    else
        parts[#parts + 1] = string.format("Spent: %d", spentThisWeek)
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

local PROF_STAT_SCAN_PATTERNS = {
    finesse = {
        "([%+%-]?%d+)%s+Finesse",
        "Finesse%s+([%+%-]?%d+)",
    },
    perception = {
        "([%+%-]?%d+)%s+Perception",
        "Perception%s+([%+%-]?%d+)",
    },
    deftness = {
        "([%+%-]?%d+)%s+Deftness",
        "Deftness%s+([%+%-]?%d+)",
    },
    speedPct = {
        "([%+%-]?%d+)%%%s+Speed",
        "Speed%s+([%+%-]?%d+)%%",
    },
}

local PROF_INFO_STAT_KEYS = {
    finesse = { "gatheringFinesse", "professionFinesse", "currentFinesse", "finesse" },
    perception = { "gatheringPerception", "professionPerception", "currentPerception", "perception" },
    deftness = { "gatheringDeftness", "professionDeftness", "currentDeftness", "deftness" },
}

local TOOLTIP_SCAN_NAME = "GatherBuffsScanTooltip"

local function AddTotalsInto(target, source)
    if not source then
        return target
    end
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        local statID = stat.id
        target[statID] = (target[statID] or 0) + (source[statID] or 0)
    end
    return target
end

local function SubtractTotals(left, right)
    local totals = GB.MakeTotals()
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        local statID = stat.id
        totals[statID] = (left and left[statID] or 0) - (right and right[statID] or 0)
    end
    return totals
end

local function HasAnyStatValue(totals, includeSpeed)
    if not totals then
        return false
    end
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        if includeSpeed or stat.id ~= "speedPct" then
            if (totals[stat.id] or 0) ~= 0 then
                return true
            end
        end
    end
    return false
end

local function EnsureScanTooltip()
    if GB.scanTooltip then
        return GB.scanTooltip
    end
    local tip = CreateFrame("GameTooltip", TOOLTIP_SCAN_NAME, UIParent, "GameTooltipTemplate")
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    GB.scanTooltip = tip
    return tip
end

local function AccumulateTooltipStats(text, totals)
    if type(text) ~= "string" or text == "" then
        return
    end
    for statID, patterns in pairs(PROF_STAT_SCAN_PATTERNS) do
        for _, pattern in ipairs(patterns) do
            local value = tonumber(text:match(pattern))
            if value then
                totals[statID] = (totals[statID] or 0) + value
                break
            end
        end
    end
end

local function ReadTooltipLine(leftFS, rightFS, totals)
    if leftFS and leftFS.GetText then
        AccumulateTooltipStats(leftFS:GetText(), totals)
    end
    if rightFS and rightFS.GetText then
        AccumulateTooltipStats(rightFS:GetText(), totals)
    end
end

local function ReadTooltipDataLine(line, totals)
    if not line then
        return
    end

    if (not line.leftText and not line.rightText) and TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, line)
    end

    AccumulateTooltipStats(line.leftText, totals)
    AccumulateTooltipStats(line.rightText, totals)

    for _, child in ipairs(line.lines or {}) do
        ReadTooltipDataLine(child, totals)
    end
end

local function ReadTooltipProfessionLine(line, tags)
    if not line then
        return
    end

    if (not line.leftText and not line.rightText) and TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, line)
    end

    local leftText = type(line.leftText) == "string" and line.leftText:lower() or nil
    local rightText = type(line.rightText) == "string" and line.rightText:lower() or nil
    for _, prof in ipairs(GB.GetProfessionDefs()) do
        local label = prof:GetLabel():lower()
        local find = type(prof.find) == "string" and prof.find:lower() or label
        if (leftText and (leftText:find(label, 1, true) or leftText:find(find, 1, true)))
            or (rightText and (rightText:find(label, 1, true) or rightText:find(find, 1, true))) then
            tags[prof.id] = true
        end
    end

    for _, child in ipairs(line.lines or {}) do
        ReadTooltipProfessionLine(child, tags)
    end
end

local function ScanEquippedItemStats(slotID)
    local totals = GB.MakeTotals()
    if not slotID or not GetInventoryItemLink("player", slotID) then
        return totals
    end

    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                ReadTooltipDataLine(line, totals)
            end
        end
        if HasAnyStatValue(totals, true) then
            return totals
        end
    end

    local tip = EnsureScanTooltip()
    tip:ClearLines()
    tip:SetInventoryItem("player", slotID)

    for i = 1, 40 do
        local leftFS = _G[TOOLTIP_SCAN_NAME .. "TextLeft" .. i]
        local rightFS = _G[TOOLTIP_SCAN_NAME .. "TextRight" .. i]
        if not leftFS and not rightFS then
            break
        end
        ReadTooltipLine(leftFS, rightFS, totals)
    end

    tip:Hide()
    return totals
end

local function ScanItemStatsFromLink(itemLink)
    local totals = GB.MakeTotals()
    if not itemLink or itemLink == "" then
        return totals
    end

    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, itemLink)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                ReadTooltipDataLine(line, totals)
            end
        end
        if HasAnyStatValue(totals, true) then
            return totals
        end
    end

    local tip = EnsureScanTooltip()
    tip:ClearLines()
    tip:SetHyperlink(itemLink)

    for i = 1, 40 do
        local leftFS = _G[TOOLTIP_SCAN_NAME .. "TextLeft" .. i]
        local rightFS = _G[TOOLTIP_SCAN_NAME .. "TextRight" .. i]
        if not leftFS and not rightFS then
            break
        end
        ReadTooltipLine(leftFS, rightFS, totals)
    end

    tip:Hide()
    return totals
end

local function StripItemLinkEnchant(itemLink)
    if type(itemLink) ~= "string" then
        return nil
    end
    local itemString = itemLink:match("|H(item:[^|]+)|h")
    itemString = itemString or itemLink:match("^(item:[^|]+)$")
    if not itemString then
        return nil
    end

    local parts = {}
    for part in string.gmatch(itemString, "([^:]+)") do
        parts[#parts + 1] = part
    end
    if parts[1] ~= "item" or not parts[2] then
        return nil
    end
    parts[3] = "0"
    return table.concat(parts, ":")
end

local function ExtractInfoStatValue(info, statID)
    if type(info) ~= "table" then
        return nil
    end
    for _, key in ipairs(PROF_INFO_STAT_KEYS[statID] or {}) do
        local value = info[key]
        if type(value) == "number" then
            return value
        end
    end
    for _, value in pairs(info) do
        if type(value) == "table" then
            local nested = ExtractInfoStatValue(value, statID)
            if nested ~= nil then
                return nested
            end
        end
    end
    return nil
end

function GB.GetActiveProfessionVariantID(infoOrProfID, profMap)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines and C_TradeSkillUI.GetTradeSkillDisplayName) then
        return nil
    end

    local info = infoOrProfID
    if type(infoOrProfID) == "string" then
        info = profMap and profMap[infoOrProfID]
    end
    if not info or not info.currentSkillLineName then
        return nil
    end

    if not GB.skillLineByDisplayName then
        GB.skillLineByDisplayName = {}
        for _, skillLineID in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines() or {}) do
            local displayName = C_TradeSkillUI.GetTradeSkillDisplayName(skillLineID)
            if displayName and displayName ~= "" then
                GB.skillLineByDisplayName[displayName] = skillLineID
            end
        end
    end

    return GB.skillLineByDisplayName[info.currentSkillLineName]
end

function GB.GetProfessionBuffTotalsByID(self, profID, activeOnly)
    local totals = GB.MakeTotals()
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        if cat.scope == "common" then
            local db = self.db.categories[cat.id]
            if db and db.enabled then
                local buff, aura = self:GetRowBuff(cat.id, profID)
                if buff and (not activeOnly or aura) then
                    GB.AddStats(totals, buff)
                end
            end
        end
    end
    return totals
end

function GB.GetProfessionEquipmentSlotsFromInfo(info)
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

function GB.GetInventorySlotStats(slotID)
    return ScanEquippedItemStats(slotID)
end

function GB.GetItemStatsFromLink(itemLink)
    return ScanItemStatsFromLink(itemLink)
end

function GB.GetItemProfessionTagsFromLink(itemLink)
    local tags = {}
    if not itemLink or itemLink == "" then
        return tags
    end

    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, itemLink)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                ReadTooltipProfessionLine(line, tags)
            end
        end
        if next(tags) then
            return tags
        end
    end

    local tip = EnsureScanTooltip()
    tip:ClearLines()
    tip:SetHyperlink(itemLink)

    for i = 1, 40 do
        local leftFS = _G[TOOLTIP_SCAN_NAME .. "TextLeft" .. i]
        local rightFS = _G[TOOLTIP_SCAN_NAME .. "TextRight" .. i]
        if not leftFS and not rightFS then
            break
        end
        local leftText = leftFS and leftFS.GetText and leftFS:GetText()
        local rightText = rightFS and rightFS.GetText and rightFS:GetText()
        for _, prof in ipairs(GB.GetProfessionDefs()) do
            local label = prof:GetLabel():lower()
            local find = type(prof.find) == "string" and prof.find:lower() or label
            local leftLower = type(leftText) == "string" and leftText:lower() or nil
            local rightLower = type(rightText) == "string" and rightText:lower() or nil
            if (leftLower and (leftLower:find(label, 1, true) or leftLower:find(find, 1, true)))
                or (rightLower and (rightLower:find(label, 1, true) or rightLower:find(find, 1, true))) then
                tags[prof.id] = true
            end
        end
    end

    tip:Hide()
    return tags
end

function GB.GetInventorySlotProfessionTags(slotID)
    local itemLink = slotID and GetInventoryItemLink("player", slotID) or nil
    return GB.GetItemProfessionTagsFromLink(itemLink)
end

function GB.GetInventorySlotEnchantStats(slotID)
    local link = slotID and GetInventoryItemLink("player", slotID) or nil
    if not link then
        return GB.MakeTotals()
    end

    local strippedLink = StripItemLinkEnchant(link)
    if not strippedLink or strippedLink == link then
        return GB.MakeTotals()
    end

    local fullStats = ScanItemStatsFromLink(link)
    local baseStats = ScanItemStatsFromLink(strippedLink)
    local totals = GB.MakeTotals()
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        local statID = stat.id
        totals[statID] = (fullStats[statID] or 0) - (baseStats[statID] or 0)
    end
    return totals
end

function GB.GetProfessionEquipmentTotalsFromInfo(info)
    local totals = GB.MakeTotals()
    local slots = GB.GetProfessionEquipmentSlotsFromInfo(info)
    if not slots then
        return totals
    end

    if slots.tool then
        AddTotalsInto(totals, ScanEquippedItemStats(slots.tool))
    end
    for _, slotID in ipairs(slots.accessories or {}) do
        AddTotalsInto(totals, ScanEquippedItemStats(slotID))
    end
    return totals
end

function GB.GetProfessionApiTotalsFromInfo(info, profMap)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID) then
        return nil
    end

    if not info then
        return nil
    end

    local variantID = GB.GetActiveProfessionVariantID(info, profMap)
    if not variantID then
        return nil
    end

    local profInfo = C_TradeSkillUI.GetProfessionInfoBySkillLineID(variantID)
    if not profInfo then
        return nil
    end

    local totals = GB.MakeTotals()
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        if stat.id ~= "speedPct" then
            local value = ExtractInfoStatValue(profInfo, stat.id)
            if type(value) == "number" then
                totals[stat.id] = value
            end
        end
    end

    if HasAnyStatValue(totals, false) then
        return totals
    end
    return nil
end

function GB.BuildProfessionStatSnapshot(self, profID, info)
    if not info then
        return nil
    end

    local activeBuffs = GB.GetProfessionBuffTotalsByID(self, profID, true)
    local maxBuffs = GB.GetProfessionBuffTotalsByID(self, profID, false)
    local liveTotals = GB.GetProfessionApiTotalsFromInfo(info, self.profMap)
    local current = GB.MakeTotals()
    local max = GB.MakeTotals()

    if liveTotals then
        AddTotalsInto(current, liveTotals)
        AddTotalsInto(max, liveTotals)
        AddTotalsInto(max, SubtractTotals(maxBuffs, activeBuffs))
    else
        local baseline = GB.GetProfessionEquipmentTotalsFromInfo(info)
        AddTotalsInto(current, baseline)
        AddTotalsInto(max, baseline)
        AddTotalsInto(current, activeBuffs)
        AddTotalsInto(max, maxBuffs)
    end

    current.speedPct = activeBuffs.speedPct or 0
    max.speedPct = maxBuffs.speedPct or 0

    return {
        current = current,
        max = max,
        hasLiveTotals = liveTotals ~= nil,
    }
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
            local name, icon, skill, maxSkill, _, _, skillLineID, bonus, _, _, currentSkillLineName = GetProfessionInfo(idx)
            if name then
                for _, prof in ipairs(GB.GetProfessionDefs()) do
                    if prof:MatchesName(name) and not map[prof.id] then
                        local professionSlotIndex
                        if idx == primary1 then
                            professionSlotIndex = 1
                        elseif idx == primary2 then
                            professionSlotIndex = 2
                        elseif idx == fishing then
                            professionSlotIndex = "fishing"
                        elseif idx == cooking then
                            professionSlotIndex = "cooking"
                        end
                        local info = prof:BuildSnapshotInfo({
                            name = name,
                            icon = icon,
                            skill = skill,
                            maxSkill = maxSkill,
                            skillLineID = skillLineID,
                            bonus = bonus,
                            currentSkillLineName = currentSkillLineName,
                            professionIndex = idx,
                            professionSlotIndex = professionSlotIndex,
                        })
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
    local info, profDef = ResolveProfessionInfoAndDef(infoOrProfID, profMap)
    if not (profDef and info) then
        return nil
    end
    return profDef:GetEquipmentSlots(GB, info)
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

function GB.GetProfessionToolEnchantInfoFromInfo(info)
    local slots = GB.GetProfessionEquipmentSlotsFromInfo(info)
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

function GB.GetProfessionToolEnchantInfo(infoOrProfID, profMap)
    local info, profDef = ResolveProfessionInfoAndDef(infoOrProfID, profMap)
    if not (profDef and info) then
        return nil
    end
    return profDef:GetToolEnchantInfo(GB, info)
end

function GB.GetProfessionEquipmentTotals(infoOrProfID, profMap)
    local info, profDef = ResolveProfessionInfoAndDef(infoOrProfID, profMap)
    if not (profDef and info) then
        return GB.MakeTotals()
    end
    return profDef:GetEquipmentTotals(GB, info)
end

function GB.GetProfessionApiTotals(infoOrProfID, profMap)
    local info, profDef = ResolveProfessionInfoAndDef(infoOrProfID, profMap)
    if not (profDef and info) then
        return nil
    end
    return profDef:GetApiTotals(GB, info)
end

function GB:GetProfessionStatSnapshot(profID)
    local profDef = GB.GetProfDef(profID)
    if not profDef then
        return nil
    end
    return profDef:GetStatSnapshot(self)
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
