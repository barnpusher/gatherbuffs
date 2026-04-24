local _, GB = ...

local SHATTERED_ESSENCE_SPELL_ID = 1235733
local DISENCHANT_SPELL_ID = 13262

local Enchanting = GB.RegisterProfession({
    id = "enchanting",
    label = "Enchanting",
    find = "Enchanting",
    simpleSkillSummary = true,
    supportsDesiredStatSelection = false,
    optionCategories = { "enchanting" },
    categories = {
        {
            id = "enchanting",
            label = "Buff",
            scope = "common",
            profIcon = "enchanting",
            professions = { "enchanting" },
            buffs = {
                {
                    name = "Shattered Essence",
                    spellID = 1235733,
                    itemIDs = {},
                    statsUnknown = true,
                    notes = "Enchanting-only buff tracked by player aura.",
                },
            },
        },
    },
    mainCard = true,
    showSettingsTab = true,
    toolDetails = true,
    profitToggleLabel = "Include Midnight enchanting mats",
    midnightGear = {
        tools = {
            runed_refulgent_copper_rod = { ids = { 244175 } },
            runed_brilliant_silver_rod = { ids = { 244176 } },
            runed_dazzling_thorium_rod = { ids = { 244177 } },
        },
        accessories = {
            bright_linen_enchanting_hat = { ids = { 239643 } },
            elegant_artisans_enchanting_hat = { ids = { 239637 } },
            thalassian_enchanters_bonnet = { ids = { 267056 } },
            silvermoon_focusing_shard = { ids = { 240956 } },
            sindorei_enchanters_crystal = { ids = { 240960 } },
            attuned_thalassian_rune_prism = { ids = { 246527 } },
        },
    },
    gatherItems = {
        dawn_crystal = { ids = { 243605, 243606 } },
        eversinging_dust = { ids = { 243599, 243600 } },
        radiant_shard = { ids = { 243602, 243603 } },
    },
})

function Enchanting:GetMainCardBuffRowDefs()
    return {
        { key = "buff", catID = "enchanting", profScoped = true },
    }
end

function GB:HasShatteredEssenceAura()
    local cat = GB.GetCatDef("enchanting")
    local buff = cat and cat.buffs and cat.buffs[1] or nil
    if buff and GB.GetPlayerAuraForBuff(buff) then
        return true
    end
    return GB.GetPlayerAura(SHATTERED_ESSENCE_SPELL_ID) ~= nil
end

function GB:ShouldWarnDisenchantWithoutShatteredEssence()
    return self.db
        and self.db.modules
        and self.db.modules.enchantingRequireShatteredEssence == true
        and self:IsProfessionModuleEnabled("enchanting")
        and self:IsProfessionAvailable("enchanting")
        and not self:HasShatteredEssenceAura()
        or false
end

function GB:IsPendingDisenchantSpell()
    local targetingSpell = SpellIsTargeting and SpellIsTargeting() or false
    local disenchantName = GB.GetSpellNameByID(DISENCHANT_SPELL_ID)

    if targetingSpell and IsCurrentSpell then
        local okByID, isCurrentByID = pcall(IsCurrentSpell, DISENCHANT_SPELL_ID)
        if okByID and isCurrentByID then
            return true
        end
        if disenchantName then
            local okByName, isCurrentByName = pcall(IsCurrentSpell, disenchantName)
            if okByName and isCurrentByName then
                return true
            end
        end
    end

    local cursorType, cursorID
    if GetCursorInfo then
        cursorType, cursorID = GetCursorInfo()
    end

    local currentSpellID = cursorType == "spell" and tonumber(cursorID) or nil
    if currentSpellID and currentSpellID == DISENCHANT_SPELL_ID then
        return true
    end

    if currentSpellID then
        local currentSpellName = GB.GetSpellNameByID(currentSpellID)
        if currentSpellName and disenchantName and currentSpellName == disenchantName then
            return true
        end
    end

    if IsCurrentSpell then
        local okByID, isCurrentByID = pcall(IsCurrentSpell, DISENCHANT_SPELL_ID)
        if okByID and isCurrentByID then
            return true
        end
        if disenchantName then
            local okByName, isCurrentByName = pcall(IsCurrentSpell, disenchantName)
            if okByName and isCurrentByName then
                return true
            end
        end
    end

    return false
end

function GB:MaybeWarnDisenchant()
    if not self:ShouldWarnDisenchantWithoutShatteredEssence() then
        return false
    end

    if not self:IsPendingDisenchantSpell() then
        return false
    end

    local now = (GetTime and GetTime()) or 0
    if not self.lastDisenchantWarnAt or (now - self.lastDisenchantWarnAt) >= 1 then
        self.lastDisenchantWarnAt = now
        print("|cffff6644GatherBuffs:|r Missing |cff00ee44Shattered Essence|r before disenchanting.")
    end

    return true
end
