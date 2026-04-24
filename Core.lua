local addonName, GB = ...

if type(GB) ~= "table" then
    GB = _G.GatherBuffs or {}
end
_G.GatherBuffs = GB

GB.ADDON_NAME = addonName or "GatherBuffs"
GB.professionRegistry = GB.professionRegistry or {}
GB.professionDefs = GB.professionDefs or {}
GB.categoryRegistry = GB.categoryRegistry or {}
GB.categoryRegistryByID = GB.categoryRegistryByID or {}
GB.categoryOwnerIndex = GB.categoryOwnerIndex or {}
GB.itemNameCache = GB.itemNameCache or {}
GB.spellNameCache = GB.spellNameCache or {}
GB.itemCountCache = GB.itemCountCache or {}
GATHERBUFFS_CATEGORIES = GB.categoryRegistry

local function GetDefaultCategorySelectedKey(cat)
    local buff = cat and cat.buffs and cat.buffs[1] or nil
    if not buff then
        return nil
    end
    return (GB.GetBuffKey and GB.GetBuffKey(cat.id, buff)) or cat.id
end

local function EnsureDefaultCategoryState(cat)
    if type(cat) ~= "table" or type(cat.id) ~= "string" or cat.id == "" or type(GB.DEFAULTS) ~= "table" then
        return
    end

    GB.DEFAULTS.categories = GB.DEFAULTS.categories or {}
    local defaults = GB.DEFAULTS.categories[cat.id]
    if type(defaults) ~= "table" then
        defaults = {}
        GB.DEFAULTS.categories[cat.id] = defaults
    end
    if defaults.enabled == nil then
        defaults.enabled = cat.defaultEnabled ~= false
    end
    if defaults.selectedKey == nil then
        defaults.selectedKey = GetDefaultCategorySelectedKey(cat)
    end
end

local function RemoveCategoryByID(catID)
    local existing = GB.categoryRegistryByID[catID]
    if not existing then
        return
    end

    for index, candidate in ipairs(GB.categoryRegistry) do
        if candidate.id == catID then
            table.remove(GB.categoryRegistry, index)
            break
        end
    end
    GB.categoryRegistryByID[catID] = nil
end

function GB.UnregisterOwnedCategories(ownerID)
    if type(ownerID) ~= "string" or ownerID == "" then
        return
    end

    local owned = GB.categoryOwnerIndex[ownerID]
    if not owned then
        return
    end

    for _, catID in ipairs(owned) do
        RemoveCategoryByID(catID)
    end
    GB.categoryOwnerIndex[ownerID] = nil
end

function GB.RegisterCategory(cat, ownerID)
    if type(cat) ~= "table" or type(cat.id) ~= "string" or cat.id == "" then
        error("GB.RegisterCategory requires a category definition with a non-empty id")
    end

    RemoveCategoryByID(cat.id)
    cat.ownerID = ownerID
    GB.categoryRegistry[#GB.categoryRegistry + 1] = cat
    GB.categoryRegistryByID[cat.id] = cat

    if type(ownerID) == "string" and ownerID ~= "" then
        GB.categoryOwnerIndex[ownerID] = GB.categoryOwnerIndex[ownerID] or {}
        table.insert(GB.categoryOwnerIndex[ownerID], cat.id)
    end

    EnsureDefaultCategoryState(cat)
    return cat
end

function GB.RegisterCategories(categories, ownerID)
    for _, cat in ipairs(categories or {}) do
        GB.RegisterCategory(cat, ownerID)
    end
end

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
    GB.UnregisterOwnedCategories(def.id)
    GB.RegisterCategories(def.categories, def.id)
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
    reportX = nil,
    reportY = nil,
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
        enchantingRequireShatteredEssence = false,
        profitTracking = {
            mining = true,
            herbalism = true,
            skinning = true,
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
        phial = { enabled = true, selectedKey = "phial:haranir_perception" },
        steamphial = { enabled = true, selectedKey = "steamphial:steaming_finesse" },
        potion = { enabled = true, selectedKey = "potion:124671" },
        weaponstone = { enabled = true, selectedKey = "weaponstone:refulgent_razorstone" },
    },
}

for _, cat in ipairs(GB.categoryRegistry) do
    EnsureDefaultCategoryState(cat)
end

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
    enchanting = "Interface/Icons/Trade_Engraving",
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
    return GB.categoryRegistryByID[catID]
end

function GB.GetProfDef(profID)
    return GB.professionRegistry[profID]
end

function GB:InvalidateProfessionStaticCache()
    self.professionStaticCacheVersion = (self.professionStaticCacheVersion or 0) + 1
    self.professionStaticCache = {}
    self.vitalsNeedsRefresh = true
end

function GB:GetProfessionStaticCache(profID)
    if type(profID) ~= "string" or profID == "" then
        return nil
    end
    self.professionStaticCache = self.professionStaticCache or {}
    return self.professionStaticCache[profID]
end

function GB:SetProfessionStaticCache(profID, cacheEntry)
    if type(profID) ~= "string" or profID == "" then
        return
    end
    self.professionStaticCache = self.professionStaticCache or {}
    self.professionStaticCache[profID] = cacheEntry
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
    if profID == "fishing" then
        return self:IsProfessionModuleEnabled(profID)
    end
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

function GB:HasTrackedProfitProfession()
    return next(self:GetTrackedProfitProfessionMap()) ~= nil
end

local BUFF_RANK_IGNORED_CATEGORIES = {
    phial = true,
    steamphial = true,
    potion = true,
    weaponstone = true,
}

function GB.CategoryIgnoresBuffRanks(catID)
    return BUFF_RANK_IGNORED_CATEGORIES[catID] == true
end

function GB.GetBuffKey(catID, buff)
    if buff and type(buff.selectionKey) == "string" and buff.selectionKey ~= "" then
        return buff.selectionKey
    end
    if buff.itemIDs and buff.itemIDs[1] then
        return catID .. ":" .. buff.itemIDs[1]
    end
    if buff.spellID then
        return catID .. ":" .. buff.spellID
    end
    for _, altSpellID in ipairs(buff.altSpellIDs or {}) do
        local normalizedAltSpellID = GB.NormalizeSpellID(altSpellID)
        if normalizedAltSpellID then
            return catID .. ":" .. normalizedAltSpellID
        end
    end
    local cat = GB.GetCatDef(catID)
    if cat then
        for index, candidate in ipairs(cat.buffs or {}) do
            if candidate == buff then
                return string.format("%s:index:%d", catID, index)
            end
        end
    end
    return catID
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
    return tonumber(spellID)
end

function GB:InvalidateItemCountCache()
    self.itemCountCache = {}
end

function GB:GetCachedItemCount(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then
        return 0
    end
    local cached = self.itemCountCache[itemID]
    if cached == nil then
        cached = GetItemCount(itemID, false)
        self.itemCountCache[itemID] = cached
    end
    return cached
end

function GB.GetItemNameByID(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then
        return nil
    end
    if GB.itemNameCache[itemID] then
        return GB.itemNameCache[itemID]
    end

    local name
    if C_Item and C_Item.GetItemNameByID then
        local ok, resolved = pcall(C_Item.GetItemNameByID, itemID)
        if ok and type(resolved) == "string" and resolved ~= "" then
            name = resolved
        end
    end
    if not name and C_Item and C_Item.GetItemInfo then
        local ok, resolved = pcall(C_Item.GetItemInfo, itemID)
        if ok and type(resolved) == "string" and resolved ~= "" then
            name = resolved
        end
    end
    if not name and GetItemInfo then
        local resolved = GetItemInfo(itemID)
        if type(resolved) == "string" and resolved ~= "" then
            name = resolved
        end
    end

    if name then
        GB.itemNameCache[itemID] = name
    end
    return name
end

function GB.GetSpellNameByID(spellID)
    spellID = GB.NormalizeSpellID(spellID)
    if not spellID then
        return nil
    end
    if GB.spellNameCache[spellID] then
        return GB.spellNameCache[spellID]
    end

    local name
    if C_Spell and C_Spell.GetSpellName then
        local ok, resolved = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(resolved) == "string" and resolved ~= "" then
            name = resolved
        end
    end
    if not name and GetSpellInfo then
        local resolved = GetSpellInfo(spellID)
        if type(resolved) == "string" and resolved ~= "" then
            name = resolved
        end
    end

    if name then
        GB.spellNameCache[spellID] = name
    end
    return name
end

function GB.GetBuffDisplayName(buff)
    if not buff then
        return nil
    end

    for _, itemID in ipairs(buff.itemIDs or {}) do
        local itemName = GB.GetItemNameByID(itemID)
        if itemName then
            return itemName
        end
    end

    local spellName = GB.GetSpellNameByID(buff.spellID)
    if spellName then
        return spellName
    end

    for _, altSpellID in ipairs(buff.altSpellIDs or {}) do
        local altSpellName = GB.GetSpellNameByID(altSpellID)
        if altSpellName then
            return altSpellName
        end
    end

    return buff.name
end

function GB.GetBuffDisplayLabel(catID, buff, includeQuality)
    local label = GB.GetBuffDisplayName(buff)
    if not label then
        return nil
    end
    if GB.CategoryIgnoresBuffRanks(catID) then
        label = label:gsub("%s*%([Qq]%d+%)$", "")
    elseif includeQuality and buff and buff.quality then
        label = label .. " " .. GB.FormatQualityText(buff.quality)
    end
    return label
end

function GB.GetMaxBuffQuality(catID, buff, profID)
    if not buff then
        return nil
    end
    local cat = GB.GetCatDef(catID)
    if not cat then
        return buff.quality
    end
    local targetKey = GB.GetBuffKey(catID, buff)
    local maxQuality = buff.quality
    for _, candidate in ipairs(cat.buffs or {}) do
        if GB.GetBuffKey(catID, candidate) == targetKey
            and GB.BuffMatchesProfession(candidate, profID)
            and candidate.quality
            and (not maxQuality or candidate.quality > maxQuality) then
            maxQuality = candidate.quality
        end
    end
    return maxQuality
end

function GB.IsMaxQualityBuff(catID, buff, profID)
    if not buff then
        return false
    end
    local maxQuality = GB.GetMaxBuffQuality(catID, buff, profID)
    if not maxQuality or not buff.quality then
        return true
    end
    return buff.quality >= maxQuality
end

function GB:GetRecentConsumableBuff(catID, candidates)
    local recent = self.recentConsumableUses and self.recentConsumableUses[catID]
    if not (recent and recent.expiresAt and recent.expiresAt > GetTime()) then
        return nil
    end

    local pool = candidates
    if not pool then
        local cat = GB.GetCatDef(catID)
        pool = cat and cat.buffs or nil
    end
    if not pool then
        return nil
    end

    if recent.buffKey then
        for _, buff in ipairs(pool) do
            if GB.GetBuffKey(catID, buff) == recent.buffKey then
                return buff
            end
        end
    end

    for _, buff in ipairs(pool) do
        for _, itemID in ipairs(buff.itemIDs or {}) do
            if itemID == recent.itemID then
                return buff
            end
        end
    end

    for _, buff in ipairs(pool) do
        if recent.spellID and GB.BuffHasSpellID(buff, recent.spellID) then
            return buff
        end
    end

    return nil
end

function GB:TrackRecentConsumableUses()
    if not self.BuildInventorySnapshot then
        return
    end

    local previous = self.inventorySnapshot
    if not previous then
        return
    end

    local current = self:BuildInventorySnapshot()
    local recent = self.recentConsumableUses or {}
    local now = GetTime()

    for _, cat in ipairs(GATHERBUFFS_CATEGORIES or {}) do
        for _, buff in ipairs(cat.buffs or {}) do
            for _, itemID in ipairs(buff.itemIDs or {}) do
                local before = previous[itemID] or 0
                local after = current[itemID] or 0
                if after < before then
                    local duration = tonumber(buff.maxDuration) or 30
                    recent[cat.id] = {
                        at = now,
                        expiresAt = now + math.max(30, duration),
                        itemID = itemID,
                        spellID = buff.spellID,
                        buffKey = GB.GetBuffKey(cat.id, buff),
                    }
                end
            end
        end
    end

    self.recentConsumableUses = recent
end

function GB.GetBuffDefBySpellID(catID, spellID)
    local cat = GB.GetCatDef(catID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not cat or not normalizedSpellID then
        return nil
    end
    for _, buff in ipairs(cat.buffs) do
        if GB.BuffHasSpellID(buff, normalizedSpellID) then
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

function GB.GetBuffSpellIDs(buff)
    local spellIDs = {}
    if not buff then
        return spellIDs
    end

    local function addSpellID(spellID)
        local normalizedSpellID = GB.NormalizeSpellID(spellID)
        if normalizedSpellID then
            spellIDs[#spellIDs + 1] = normalizedSpellID
        end
    end

    addSpellID(buff.spellID)
    for _, spellID in ipairs(buff.altSpellIDs or {}) do
        addSpellID(spellID)
    end
    return spellIDs
end

function GB.BuffHasSpellID(buff, spellID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not normalizedSpellID then
        return false
    end
    for _, buffSpellID in ipairs(GB.GetBuffSpellIDs(buff)) do
        if buffSpellID == normalizedSpellID then
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
    if GB.auraSnapshot and GB.auraSnapshot[normalizedSpellID] then
        return GB.auraSnapshot[normalizedSpellID]
    end
    if GB.auraSnapshot and InCombatLockdown() then
        return nil
    end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, normalizedSpellID)
        if ok and aura then
            return aura
        end
    end
    return nil
end

function GB.GetPlayerAuraForBuff(buff)
    if not buff then
        return nil
    end
    for _, spellID in ipairs(GB.GetBuffSpellIDs(buff)) do
        local aura = GB.GetPlayerAura(spellID)
        if aura then
            return aura
        end
    end
    return nil
end

function GB.GetAuraNumericValues(aura)
    if not aura then
        return {}
    end
    local values, seen = {}, {}
    local function addValue(value)
        if type(value) == "number" and value > 0 and not seen[value] then
            seen[value] = true
            values[#values + 1] = value
        end
    end
    addValue(aura.amount)
    addValue(aura.value1)
    addValue(aura.value2)
    addValue(aura.value3)
    if type(aura.points) == "table" then
        for _, value in pairs(aura.points) do
            addValue(value)
        end
    end
    return values
end

local function CollectTooltipTextLine(text, lines)
    if type(text) == "string" and text ~= "" then
        lines[#lines + 1] = text
    end
end

local function ReadAuraTooltipTextDataLine(line, lines)
    if not line then
        return
    end

    if (not line.leftText and not line.rightText) and TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, line)
    end

    CollectTooltipTextLine(line.leftText, lines)
    CollectTooltipTextLine(line.rightText, lines)

    for _, child in ipairs(line.lines or {}) do
        ReadAuraTooltipTextDataLine(child, lines)
    end
end

function GB.GetAuraTooltipText(aura, helpful)
    local lines = {}
    if not (aura and aura.auraInstanceID and C_TooltipInfo) then
        return lines
    end

    local getter = helpful and C_TooltipInfo.GetUnitBuffByAuraInstanceID or C_TooltipInfo.GetUnitDebuffByAuraInstanceID
    if type(getter) ~= "function" then
        return lines
    end

    local ok, data = pcall(getter, "player", aura.auraInstanceID)
    if not (ok and data and data.lines) then
        return lines
    end

    for _, line in ipairs(data.lines) do
        ReadAuraTooltipTextDataLine(line, lines)
    end
    return lines
end

local function GetBuffPrimaryStatID(buff)
    if not (buff and buff.stats) then
        return nil
    end
    local bestStatID, bestValue = nil, nil
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
        if stat.id ~= "speedPct" then
            local value = buff.stats[stat.id]
            if type(value) == "number" and value > 0 and (not bestValue or value > bestValue) then
                bestStatID, bestValue = stat.id, value
            end
        end
    end
    return bestStatID
end

local function ResolveAuraBuffFromTooltip(aura, candidates)
    local tooltipLines = GB.GetAuraTooltipText(aura, true)
    if #tooltipLines == 0 then
        return nil
    end

    local combined = table.concat(tooltipLines, "\n"):lower()
    local bestBuff, bestScore, tied = nil, 0, false
    for _, buff in ipairs(candidates or {}) do
        local score = 0
        local primaryStatID = GetBuffPrimaryStatID(buff)
        local primaryLabel = primaryStatID and GB.GetDesiredStatLabel(primaryStatID)
        if type(primaryLabel) == "string" and primaryLabel ~= "" and combined:find(primaryLabel:lower(), 1, true) then
            score = score + 2
        end
        local buffName = GB.GetBuffDisplayName(buff)
        if type(buffName) == "string" and buffName ~= "" and combined:find(buffName:lower(), 1, true) then
            score = score + 1
        end
        if score > bestScore then
            bestBuff, bestScore, tied = buff, score, false
        elseif score > 0 and score == bestScore then
            tied = true
        end
    end
    if bestBuff and bestScore > 0 and not tied then
        return bestBuff
    end
    return nil
end

function GB.ResolveAuraBuff(catID, aura, profID, preferredBuff)
    local cat = GB.GetCatDef(catID)
    if not (cat and aura and aura.spellId) then
        return preferredBuff
    end

    local normalizedSpellID = GB.NormalizeSpellID(aura.spellId)
    if not normalizedSpellID then
        return preferredBuff
    end

    local candidates = {}
    for _, buff in ipairs(cat.buffs or {}) do
        if GB.BuffHasSpellID(buff, normalizedSpellID) and GB.BuffMatchesProfession(buff, profID) then
            candidates[#candidates + 1] = buff
        end
    end
    if #candidates <= 1 then
        return candidates[1] or preferredBuff
    end

    local tooltipBuff = ResolveAuraBuffFromTooltip(aura, candidates)
    if tooltipBuff then
        return tooltipBuff
    end

    local recentBuff = GB.GetRecentConsumableBuff and GB:GetRecentConsumableBuff(catID, candidates)
    if recentBuff then
        return recentBuff
    end

    local auraValues = GB.GetAuraNumericValues(aura)
    if #auraValues > 0 then
        local valueSet = {}
        for _, value in ipairs(auraValues) do
            valueSet[value] = true
        end

        local bestBuff, bestScore, tied = nil, 0, false
        for _, buff in ipairs(candidates) do
            local score = 0
            for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
                local statValue = buff.stats and buff.stats[stat.id]
                if type(statValue) == "number" and valueSet[statValue] then
                    score = score + 1
                end
            end
            if score > bestScore then
                bestBuff, bestScore, tied = buff, score, false
            elseif score > 0 and score == bestScore then
                tied = true
            end
        end
        if bestBuff and bestScore > 0 and not tied then
            return bestBuff
        end
    end

    return preferredBuff or candidates[1]
end

function GB.GetSpellCooldownInfo(spellID)
    local normalizedSpellID = GB.NormalizeSpellID(spellID)
    if not normalizedSpellID then
        return nil
    end

    local function SafeNumber(value, default)
        if value == nil then
            return default
        end
        local ok, text = pcall(tostring, value)
        if not ok then
            return default
        end
        local numeric = tonumber(text)
        if numeric == nil then
            return default
        end
        return numeric
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

    duration = SafeNumber(duration, 0)
    startTime = SafeNumber(startTime, 0)
    modRate = SafeNumber(modRate, 1)
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

function GB.GetBuffCount(buff, catID)
    if not buff or not buff.itemIDs or #buff.itemIDs == 0 then
        return nil
    end
    if catID and GB.CategoryIgnoresBuffRanks(catID) then
        local cat = GB.GetCatDef(catID)
        local buffKey = GB.GetBuffKey(catID, buff)
        local total, seenItemIDs = 0, {}
        for _, candidate in ipairs((cat and cat.buffs) or {}) do
            if GB.GetBuffKey(catID, candidate) == buffKey then
                for _, itemID in ipairs(candidate.itemIDs or {}) do
                    if not seenItemIDs[itemID] then
                        seenItemIDs[itemID] = true
                        total = total + GB:GetCachedItemCount(itemID)
                    end
                end
            end
        end
        return total
    end
    local total = 0
    for _, itemID in ipairs(buff.itemIDs) do
        total = total + GB:GetCachedItemCount(itemID)
    end
    return total
end

function GB.GetTrackedItemCount(itemIDs)
    local total = 0
    for _, itemID in ipairs(itemIDs or {}) do
        total = total + GB:GetCachedItemCount(itemID)
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
        if GB:GetCachedItemCount(itemID) > 0 then
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

local function ReadTooltipTextDataLine(line, lines)
    if not line then
        return
    end

    if (not line.leftText and not line.rightText) and TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, line)
    end

    CollectTooltipTextLine(line.leftText, lines)
    CollectTooltipTextLine(line.rightText, lines)

    for _, child in ipairs(line.lines or {}) do
        ReadTooltipTextDataLine(child, lines)
    end
end

function GB.GetInventorySlotTooltipText(slotID)
    local lines = {}
    if not slotID or not GetInventoryItemLink("player", slotID) then
        return lines
    end

    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                ReadTooltipTextDataLine(line, lines)
            end
        end
        if #lines > 0 then
            return lines
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
        CollectTooltipTextLine(leftFS and leftFS.GetText and leftFS:GetText(), lines)
        CollectTooltipTextLine(rightFS and rightFS.GetText and rightFS:GetText(), lines)
    end

    tip:Hide()
    return lines
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

local function ExtractItemStringParts(itemLink)
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
    return parts
end

local function StripItemLinkEnchant(itemLink)
    local parts = ExtractItemStringParts(itemLink)
    if not parts then
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
            if self:GetCategoryEnabled(cat.id, profID) then
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

    local fullStats = ScanEquippedItemStats(slotID)
    local baseStats = ScanItemStatsFromLink(strippedLink)
    local totals = GB.MakeTotals()
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        local statID = stat.id
        totals[statID] = (fullStats[statID] or 0) - (baseStats[statID] or 0)
    end
    return totals
end

function GB.BuffStatsContainedInTotals(buff, totals)
    if not (buff and buff.stats and totals) then
        return false
    end
    local matched = false
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
        local expected = buff.stats[stat.id] or 0
        local actual = totals[stat.id] or 0
        if expected ~= 0 then
            if actual ~= expected then
                return false
            end
            matched = true
        end
    end
    return matched
end

function GB.BuffStatsFitWithinTotals(buff, totals)
    if not (buff and buff.stats and totals) then
        return false
    end
    local matched = false
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
        local expected = buff.stats[stat.id] or 0
        local actual = totals[stat.id] or 0
        if expected ~= 0 then
            if actual < expected then
                return false
            end
            matched = true
        end
    end
    return matched
end

function GB.ResolveWeaponstoneSpellIDFromStats(profID, totals, preferredBuff)
    local cat = GB.GetCatDef("weaponstone")
    if not (cat and totals) then
        return nil
    end

    local candidates = {}
    for _, buff in ipairs(cat.buffs or {}) do
        if GB.BuffMatchesProfession(buff, profID) and GB.BuffStatsFitWithinTotals(buff, totals) then
            candidates[#candidates + 1] = buff
        end
    end

    if #candidates == 0 then
        return nil
    end
    if #candidates == 1 then
        return candidates[1].spellID
    end
    if preferredBuff then
        local preferredKey = GB.GetBuffKey("weaponstone", preferredBuff)
        for _, buff in ipairs(candidates) do
            if GB.GetBuffKey("weaponstone", buff) == preferredKey or GB.BuffHasSpellID(buff, preferredBuff.spellID) then
                return preferredBuff.spellID or buff.spellID
            end
        end
    end
    return candidates[1].spellID
end

function GB.ResolveWeaponstoneSpellIDFromTooltip(slotID, profID, totals, preferredBuff)
    local cat = GB.GetCatDef("weaponstone")
    if not (cat and slotID) then
        return nil
    end

    local tooltipLines = GB.GetInventorySlotTooltipText(slotID)
    if #tooltipLines == 0 then
        return nil
    end

    local candidates = {}
    local nameMatches = {}
    for _, buff in ipairs(cat.buffs or {}) do
        if GB.BuffMatchesProfession(buff, profID) then
            local names = {}
            names[#names + 1] = (buff.name or ""):lower()
            local displayName = GB.GetBuffDisplayName(buff)
            if displayName then
                names[#names + 1] = displayName:lower()
            end

            local found = false
            for _, line in ipairs(tooltipLines) do
                local lowerLine = line:lower()
                for _, name in ipairs(names) do
                    if name ~= "" and lowerLine:find(name, 1, true) then
                        found = true
                        break
                    end
                end
                if found then
                    break
                end
            end

            if found then
                nameMatches[#nameMatches + 1] = buff
                if (not totals) or GB.BuffStatsContainedInTotals(buff, totals) then
                    candidates[#candidates + 1] = buff
                end
            end
        end
    end

    if #candidates == 0 then
        if #nameMatches == 0 then
            return nil
        end
        if preferredBuff then
            local preferredKey = GB.GetBuffKey("weaponstone", preferredBuff)
            for _, buff in ipairs(nameMatches) do
                if GB.GetBuffKey("weaponstone", buff) == preferredKey then
                    return preferredBuff.spellID or buff.spellID
                end
            end
        end
        return nameMatches[1].spellID
    end
    if #candidates == 1 then
        return candidates[1].spellID
    end
    if preferredBuff and preferredBuff.name then
        for _, buff in ipairs(candidates) do
            if buff.name == preferredBuff.name or GB.GetBuffKey("weaponstone", buff) == GB.GetBuffKey("weaponstone", preferredBuff) then
                return preferredBuff.spellID or buff.spellID
            end
        end
    end
    return candidates[1].spellID
end

function GB.ResolveWeaponstoneSpellIDFromProfessionTotals(info)
    if not info or not info.id then
        return nil
    end

    local apiTotals = GB.GetProfessionApiTotalsFromInfo(info, GB.profMap)
    if not apiTotals then
        return nil
    end

    local equipmentTotals = GB.GetProfessionEquipmentTotalsFromInfo(info)
    local activeBuffTotals = GB.GetProfessionBuffTotalsByID(GB, info.id, true)
    local inferredTotals = GB.MakeTotals()

    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER or {}) do
        local statID = stat.id
        inferredTotals[statID] = (apiTotals[statID] or 0) - (equipmentTotals[statID] or 0) - (activeBuffTotals[statID] or 0)
    end

    if not HasAnyStatValue(inferredTotals, true) then
        return nil
    end

    return GB.ResolveWeaponstoneSpellIDFromStats(info.id, inferredTotals)
end

function GB.GetProfessionEquipmentTotalsFromInfo(info)
    local totals = GB.MakeTotals()
    local slots = GB.GetProfessionEquipmentSlots(info)
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
    local parts = ExtractItemStringParts(itemLink)
    local enchantID = parts and tonumber(parts[3]) or nil
    if enchantID and enchantID > 0 then
        return enchantID
    end
    return nil
end

local KNOWN_TOOL_ENCHANT_SPELLS = {}

function GB.GetToolEnchantSpellID(enchantID)
    enchantID = tonumber(enchantID)
    if not enchantID or enchantID <= 0 then
        return nil
    end
    return KNOWN_TOOL_ENCHANT_SPELLS[enchantID]
end

function GB.GetProfessionToolEnchantInfoFromInfo(info, slots, enchantStats)
    slots = slots or GB.GetProfessionEquipmentSlots(info)
    if not slots or not slots.tool then
        return nil
    end
    local itemLink = GetInventoryItemLink("player", slots.tool)
    local enchantID = GB.GetItemLinkEnchantID(itemLink)
    if not enchantID then
        return { hasEnchant = false, itemLink = itemLink }
    end

    local spellID = GB.GetToolEnchantSpellID(enchantID)
    local recentWeaponstoneBuff = GB.GetRecentConsumableBuff and GB:GetRecentConsumableBuff("weaponstone")
    local preferredWeaponstoneBuff = recentWeaponstoneBuff
    if not preferredWeaponstoneBuff and GB.GetSelectedBuff then
        preferredWeaponstoneBuff = GB.GetSelectedBuff(GB, "weaponstone", info.id) or nil
    end
    if not spellID and recentWeaponstoneBuff and recentWeaponstoneBuff.spellID then
        spellID = recentWeaponstoneBuff.spellID
    end
    if not spellID then
        enchantStats = enchantStats or GB.GetInventorySlotEnchantStats(slots.tool)
        spellID = GB.ResolveWeaponstoneSpellIDFromTooltip(slots.tool, info.id, enchantStats, preferredWeaponstoneBuff)
        if HasAnyStatValue(enchantStats, true) then
            spellID = spellID or GB.ResolveWeaponstoneSpellIDFromStats(info.id, enchantStats)
        end
    end
    if not spellID then
        spellID = GB.ResolveWeaponstoneSpellIDFromProfessionTotals(info)
    end
    spellID = spellID or enchantID
    local enchantName = GB.GetSpellNameByID(spellID)

    return {
        hasEnchant = true,
        enchantID = enchantID,
        spellID = spellID,
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
