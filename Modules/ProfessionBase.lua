local _, GB = ...

GB.ProfessionBase = GB.ProfessionBase or {}
local Base = GB.ProfessionBase
local BASE_MT = { __index = Base }

function GB.ApplyProfessionBase(def)
    if type(def) ~= "table" then
        error("Profession definition must be a table")
    end
    if type(def.id) ~= "string" or def.id == "" then
        error("Profession definition is missing id")
    end
    if type(def.label) ~= "string" or def.label == "" then
        error("Profession definition is missing label for " .. tostring(def.id))
    end
    if getmetatable(def) ~= BASE_MT then
        setmetatable(def, BASE_MT)
    end
    return def
end

for _, def in ipairs(GB.GetProfessionDefs()) do
    GB.ApplyProfessionBase(def)
end

-- Returns whether a live profession name matches this module's lookup token.
function Base:MatchesName(name)
    return type(name) == "string" and type(self.find) == "string" and name:find(self.find, 1, true) ~= nil
end

-- Builds the normalized profession snapshot stored in addon state.
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

-- Returns the display label used in tabs, cards, and toggles.
function Base:GetLabel()
    return self.label
end

-- Returns whether this profession is currently available on the character.
function Base:IsAvailable(addon)
    return (addon.profMap and addon.profMap[self.id] ~= nil) or (self.find and GB.HasProfessionByName(self.find)) or false
end

-- Returns the current live profession snapshot for the character.
function Base:GetDisplayInfo(addon)
    return addon.profMap and addon.profMap[self.id] or nil
end

-- optionCategories are categories this profession exposes in its settings UI.
-- categories are categories this profession owns and registers into the shared registry.
-- Shared categories like weaponstone appear in optionCategories without being owned here.
-- Returns the category IDs this profession should surface in settings and buff state checks.
function Base:GetBuffCategoryIDs()
    return self.buffCategories or self.optionCategories or {}
end

-- Returns the gather/profit item definitions owned by this profession.
function Base:GetGatherItems()
    return self.gatherItems or {}
end

local function GetGearEntryItemIDs(entryValue)
    if type(entryValue) ~= "table" then
        return nil
    end

    if type(entryValue.ids) == "table" then
        return entryValue.ids
    end

    return entryValue
end

-- Returns the catalog of known Midnight gear item ID lists for this profession.
function Base:GetMidnightGearCatalog()
    return self.midnightGear or {}
end

-- Returns true if the given item ID is recognized as Midnight gear for this profession.
function Base:IsKnownMidnightGearItem(itemID, slotKind)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then
        return false
    end

    local catalog = self:GetMidnightGearCatalog()
    local entries = catalog[slotKind == "tool" and "tools" or "accessories"] or {}
    for _, entryValue in pairs(entries) do
        local itemIDs = GetGearEntryItemIDs(entryValue)
        if itemIDs then
            for _, knownItemID in ipairs(itemIDs) do
                if tonumber(knownItemID) == itemID then
                    return true
                end
            end
        end
    end
    return false
end

-- Returns whether this profession should render a main card in the addon frame.
function Base:HasMainCard()
    return not self:IsProfitOnly() and self.mainCard ~= false
end

-- Returns whether this profession should appear as its own settings tab.
function Base:HasSettingsTab()
    return self.showSettingsTab == true
end

-- Returns whether this profession only participates in profit tracking.
function Base:IsProfitOnly()
    return self.profitOnly == true
end

-- Returns whether the settings UI should expose desired-stat selection.
function Base:SupportsDesiredStatSelection()
    return not self:IsProfitOnly() and self.supportsDesiredStatSelection ~= false
end

-- Returns whether the main card should show tool and enchant details.
function Base:ShowsToolDetails()
    return self.toolDetails == true
end

-- Returns whether the profession supports the shared Razorstone category.
function Base:UsesWeaponstone()
    return self.weaponstone == true
end

-- Returns the label shown in the Profit settings page.
function Base:GetProfitToggleLabel()
    return self.profitToggleLabel or ("Track " .. self:GetLabel())
end

-- Returns whether this profession's profit toggle can exist without live availability.
function Base:CanTrackProfitWithoutAvailability()
    return self.trackProfitWithoutAvailability == true
end

-- Returns whether the card header should use a plain skill summary with no weekly item text.
function Base:UsesSimpleSkillSummary()
    return self.simpleSkillSummary == true
end

-- Returns the overload category ID for this profession, if one exists.
function Base:GetOverloadCategoryID()
    local catID = "overload_" .. self.id
    return GB.GetCatDef(catID) and catID or nil
end

-- Returns row definitions for profession-specific buff rows shown on the main card.
function Base:GetMainCardBuffRowDefs()
    local rows = {}
    local overloadCatID = self:GetOverloadCategoryID()
    if overloadCatID then
        rows[#rows + 1] = { key = "overload", catID = overloadCatID }
    end
    return rows
end

-- Returns the compact summary text shown on the profession header.
function Base:GetCardSummaryText(addon, vitals)
    local info = vitals and vitals.info or nil
    if not info then
        return ""
    end

    local weeklyItemsText = GB.GetProfessionWeeklyItemText(self.id)
    if self:UsesSimpleSkillSummary() then
        return string.format("%d/%d", info.skill, info.maxSkill)
    end
    if weeklyItemsText and weeklyItemsText ~= "" then
        return string.format("%s   %d/%d", weeklyItemsText, info.skill, info.maxSkill)
    end
    return string.format("%d/%d", info.skill, info.maxSkill)
end

-- Returns the equipped tool/accessory slot IDs for this profession.
function Base:GetEquipmentSlots(addon, info)
    local slots = GB.GetProfessionEquipmentSlotsFromInfo(info)
    if not slots or not info or (info.professionSlotIndex ~= 1 and info.professionSlotIndex ~= 2) then
        return slots
    end

    local alternateSlots = GB.GetProfessionEquipmentSlotsFromInfo({
        professionSlotIndex = info.professionSlotIndex == 1 and 2 or 1,
    })
    if not alternateSlots then
        return slots
    end

    local function score(slotSet)
        local total = 0
        local toolTags = GB.GetInventorySlotProfessionTags(slotSet.tool)
        if toolTags and toolTags[self.id] then
            total = total + 2
        end
        for _, slotID in ipairs(slotSet.accessories or {}) do
            local tags = GB.GetInventorySlotProfessionTags(slotID)
            if tags and tags[self.id] then
                total = total + 1
            end
        end
        return total
    end

    if score(alternateSlots) > score(slots) then
        return alternateSlots
    end
    return slots
end

-- Returns the active enchant metadata for the profession tool.
function Base:GetToolEnchantInfo(addon, info, slots, enchantStats)
    return GB.GetProfessionToolEnchantInfoFromInfo(info, slots, enchantStats)
end

-- Returns stat totals parsed from equipped profession items.
function Base:GetEquipmentTotals(addon, info)
    return GB.GetProfessionEquipmentTotalsFromInfo(info)
end

-- Returns stat totals exposed directly by Blizzard's profession API, if available.
function Base:GetApiTotals(addon, info)
    return GB.GetProfessionApiTotalsFromInfo(info, addon and addon.profMap or nil)
end

-- Returns total buff contribution for the profession, optionally active-only.
function Base:GetBuffTotals(addon, activeOnly)
    return GB.GetProfessionBuffTotalsByID(addon, self.id, activeOnly)
end

-- Returns resolved buff state information for all profession buff categories.
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

-- Returns the merged profession stat snapshot used by the main UI.
function Base:GetStatSnapshot(addon)
    local info = self:GetDisplayInfo(addon)
    if not info then
        return nil
    end
    return GB.BuildProfessionStatSnapshot(addon, self.id, info)
end

function Base:GetStaticVitals(addon, info)
    if not (addon and info) then
        return nil
    end

    local cache = addon:GetProfessionStaticCache(self.id)
    local cacheVersion = addon.professionStaticCacheVersion or 0
    if cache and cache.version == cacheVersion then
        return cache
    end

    local slots = self:GetEquipmentSlots(addon, info) or { accessories = {} }
    local enchantStats = slots.tool and GB.GetInventorySlotEnchantStats(slots.tool) or GB.MakeTotals()
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

    cache = {
        version = cacheVersion,
        slots = slots,
        tool = tool,
        accessories = accessories,
        enchantStats = enchantStats,
        toolEnchant = self:GetToolEnchantInfo(addon, info, slots, enchantStats),
        equipmentTotals = self:GetEquipmentTotals(addon, info),
    }
    addon:SetProfessionStaticCache(self.id, cache)
    return cache
end

-- Returns the full live profession payload used by debug output and UI rendering.
function Base:GetVitals(addon)
    local info = self:GetDisplayInfo(addon)
    if not info then
        return nil
    end
    local static = self:GetStaticVitals(addon, info) or {}
    local apiTotals = self:GetApiTotals(addon, info)
    local activeBuffs = self:GetBuffTotals(addon, true)
    local maxBuffs = self:GetBuffTotals(addon, false)
    local current = GB.MakeTotals()
    local max = GB.MakeTotals()

    if apiTotals then
        for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
            local statID = stat.id
            current[statID] = apiTotals[statID] or 0
            max[statID] = apiTotals[statID] or 0
        end
        for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
            local statID = stat.id
            max[statID] = (max[statID] or 0) + math.max(0, (maxBuffs[statID] or 0) - (activeBuffs[statID] or 0))
        end
    else
        local baseline = static.equipmentTotals or GB.MakeTotals()
        for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
            local statID = stat.id
            current[statID] = (baseline[statID] or 0) + (activeBuffs[statID] or 0)
            max[statID] = (baseline[statID] or 0) + (maxBuffs[statID] or 0)
        end
    end

    current.speedPct = activeBuffs.speedPct or 0
    max.speedPct = maxBuffs.speedPct or 0

    return {
        info = info,
        slots = static.slots or { accessories = {} },
        tool = static.tool,
        accessories = static.accessories or {},
        toolEnchant = static.toolEnchant,
        equipmentTotals = static.equipmentTotals or GB.MakeTotals(),
        apiTotals = apiTotals,
        statSnapshot = {
            current = current,
            max = max,
            hasLiveTotals = apiTotals ~= nil,
        },
        buffStates = self:GetBuffStates(addon),
    }
end
