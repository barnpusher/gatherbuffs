local _, GB = ...

local W = GB.W
local PAD = GB.PAD
local HDR_H = GB.HDR_H

local openDropList
local blocker = CreateFrame("Frame", nil, UIParent)
blocker:SetAllPoints(UIParent)
blocker:SetFrameStrata("DIALOG")
blocker:EnableMouse(true)
blocker:Hide()
blocker:SetScript("OnMouseDown", function()
    if openDropList then
        openDropList:Hide()
    end
    openDropList = nil
    blocker:Hide()
end)

local function CloseDropdown()
    if openDropList then
        openDropList:Hide()
    end
    openDropList = nil
    blocker:Hide()
end

local function MakeDropList(items, onPick)
    local h = 18
    local list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    list:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    list:SetBackdropColor(0.07, 0.07, 0.10, 0.97)
    list:SetBackdropBorderColor(0.50, 0.44, 0.18)
    list:SetFrameStrata("TOOLTIP")
    list:SetWidth(214)
    list:SetHeight(#items * h + 6)
    for i, item in ipairs(items) do
        local btn = CreateFrame("Button", nil, list)
        btn:SetPoint("TOPLEFT", 4, -3 - (i - 1) * h)
        btn:SetSize(206, h)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        fs:SetText(item.label)
        fs:SetTextColor(0.88, 0.88, 0.88)
        btn:SetScript("OnEnter", function() fs:SetTextColor(1, 0.88, 0.2) end)
        btn:SetScript("OnLeave", function() fs:SetTextColor(0.88, 0.88, 0.88) end)
        btn:SetScript("OnClick", function()
            onPick(item.value)
            CloseDropdown()
        end)
    end
    list:Hide()
    return list
end

local function MakeOptRow(parent, cat, yTop)
    local row, db = CreateFrame("Frame", nil, parent), GB.db.categories[cat.id]
    row:SetPoint("TOPLEFT", PAD, yTop)
    row:SetSize(W + 20, 24)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 0, 0)
    cb:SetChecked(db.enabled)
    cb:SetScript("OnClick", function(self)
        GB.db.categories[cat.id].enabled = self:GetChecked()
        GB:Rebuild()
    end)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 36, 0)
    lbl:SetWidth(72)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(cat.label .. ":")
    local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
    btn:SetPoint("LEFT", 114, 0)
    btn:SetSize(214, 18)
    btn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.10, 0.10, 0.14, 0.92)
    btn:SetBackdropBorderColor(0.38, 0.38, 0.40)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 4, 0)
    txt:SetPoint("RIGHT", -12, 0)
    txt:SetJustifyH("LEFT")
    local arr = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arr:SetPoint("RIGHT", -3, 0)
    arr:SetText("v")
    local STAT_FULL = { finesse = "Finesse", perception = "Perception", deftness = "Deftness" }
    local function BuffLabel(buff)
        if not buff then
            return "-"
        end
        local label = buff.name or "-"
        if buff.quality then
            label = label .. " " .. GB.FormatQualityText(buff.quality)
        end
        if buff.stats then
            local bestStat, bestVal = nil, 0
            for statID, val in pairs(buff.stats) do
                if statID ~= "speedPct" and val > bestVal then
                    bestStat, bestVal = statID, val
                end
            end
            local hint = STAT_FULL[bestStat] or bestStat
            if bestStat and not label:lower():find(hint:lower(), 1, true) then
                label = label .. " (" .. hint .. ")"
            end
        end
        return label
    end
    local function refresh()
        txt:SetText(GB.Trunc(BuffLabel(GB:GetSelectedBuff(cat.id)), 34))
    end
    refresh()
    local items = {}
    for _, buff in ipairs(cat.buffs) do
        table.insert(items, { label = BuffLabel(buff), value = GB.GetBuffKey(cat.id, buff) })
    end
    local list = MakeDropList(items, function(value)
        GB.db.categories[cat.id].selectedKey = value
        refresh()
        GB:UpdateBars()
    end)
    btn:SetScript("OnClick", function(self)
        if openDropList == list and list:IsShown() then
            CloseDropdown()
        else
            CloseDropdown()
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
            list:SetFrameLevel(self:GetFrameLevel() + 10)
            blocker:SetFrameLevel(self:GetFrameLevel() + 9)
            list:Show()
            blocker:Show()
            openDropList = list
        end
    end)
end

local function MakeProfOptRow(parent, prof, yTop)
    GB.db.modules.professions[prof.id] = GB.db.modules.professions[prof.id] or {}
    local db = GB.db.modules.professions[prof.id]
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", PAD, yTop)
    row:SetSize(W + 20, 24)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 0, 0)
    cb:SetChecked(db.enabled ~= false)
    cb:SetScript("OnClick", function(self)
        GB.db.modules.professions[prof.id].enabled = self:GetChecked()
        GB:Rebuild()
    end)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 36, 0)
    lbl:SetWidth(72)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(prof.label .. ":")

    if prof.id == "fishing" or prof.profitOnly then
        return row
    end

    local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
    btn:SetPoint("LEFT", 114, 0)
    btn:SetSize(214, 18)
    btn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.10, 0.10, 0.14, 0.92)
    btn:SetBackdropBorderColor(0.38, 0.38, 0.40)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 4, 0)
    txt:SetPoint("RIGHT", -12, 0)
    txt:SetJustifyH("LEFT")
    local arr = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arr:SetPoint("RIGHT", -3, 0)
    arr:SetText("v")
    local function refresh()
        txt:SetText(GB.GetDesiredStatLabel(GB:GetDesiredStat(prof.id)))
    end
    refresh()
    local items = {}
    for _, stat in ipairs(GATHERBUFFS_STAT_ORDER) do
        if stat.id ~= "speedPct" then
            table.insert(items, { label = stat.label, value = stat.id })
        end
    end
    local list = MakeDropList(items, function(value)
        GB.db.modules.professions[prof.id].desiredStat = value
        refresh()
        GB:UpdateBars()
    end)
    btn:SetScript("OnClick", function(self)
        if openDropList == list and list:IsShown() then
            CloseDropdown()
        else
            CloseDropdown()
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
            list:SetFrameLevel(self:GetFrameLevel() + 10)
            blocker:SetFrameLevel(self:GetFrameLevel() + 9)
            list:Show()
            blocker:Show()
            openDropList = list
        end
    end)
end

local function MakeBoolOptRow(parent, label, yTop, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", PAD, yTop)
    row:SetSize(W + 20, 24)

    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", 0, 0)
    cb:SetChecked(getter())
    cb:SetScript("OnClick", function(self) setter(self:GetChecked()) end)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(label)
    lbl:SetTextColor(0.65, 0.65, 0.68)
    return row
end

local function MakeChoiceOptRow(parent, label, yTop, items, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", PAD, yTop)
    row:SetSize(W + 20, 24)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 36, 0)
    lbl:SetWidth(98)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(label .. ":")
    lbl:SetTextColor(0.65, 0.65, 0.68)

    local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
    btn:SetPoint("LEFT", 136, 0)
    btn:SetSize(192, 18)
    btn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.10, 0.10, 0.14, 0.92)
    btn:SetBackdropBorderColor(0.38, 0.38, 0.40)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 4, 0)
    txt:SetPoint("RIGHT", -12, 0)
    txt:SetJustifyH("LEFT")

    local arr = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arr:SetPoint("RIGHT", -3, 0)
    arr:SetText("v")

    local function getLabel(value)
        for _, item in ipairs(items) do
            if item.value == value then
                return item.label
            end
        end
        return "-"
    end

    local function refresh()
        txt:SetText(getLabel(getter()))
    end

    local list = MakeDropList(items, function(value)
        setter(value)
        refresh()
    end)

    btn:SetScript("OnClick", function(self)
        if openDropList == list and list:IsShown() then
            CloseDropdown()
        else
            CloseDropdown()
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
            list:SetFrameLevel(self:GetFrameLevel() + 10)
            blocker:SetFrameLevel(self:GetFrameLevel() + 9)
            list:Show()
            blocker:Show()
            openDropList = list
        end
    end)

    refresh()
    return row
end

local sliderCounter = 0

local function MakeSliderOptRow(parent, label, yTop, minValue, maxValue, step, getter, setter)
    sliderCounter = sliderCounter + 1
    local sliderName = "GBOptionsSlider" .. sliderCounter

    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", PAD, yTop)
    row:SetSize(W + 20, 42)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", 0, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.65, 0.65, 0.68)

    local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("TOPRIGHT", -8, 0)
    val:SetJustifyH("RIGHT")
    val:SetTextColor(0.88, 0.88, 0.90)

    local slider = CreateFrame("Slider", sliderName, row, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -14)
    slider:SetWidth(220)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    _G[sliderName .. "Low"]:SetText("")
    _G[sliderName .. "High"]:SetText("")
    _G[sliderName .. "Text"]:SetText("")

    local updating = false
    local function refresh()
        updating = true
        local current = getter()
        slider:SetValue(current)
        val:SetText(string.format("%.2f", current))
        updating = false
    end

    slider:SetScript("OnValueChanged", function(_, value)
        if updating then
            return
        end
        local snapped = math.floor((value / step) + 0.5) * step
        snapped = math.max(minValue, math.min(maxValue, snapped))
        setter(snapped)
        val:SetText(string.format("%.2f", snapped))
    end)

    refresh()
    return row
end

function GB:BuildOptions()
    local PANEL_W = W + 34
    local TAB_H, TAB_GAP = 22, 4
    local hasGatheringProfession = self:IsProfessionAvailable("mining")
        or self:IsProfessionAvailable("herbalism")
        or self:IsProfessionAvailable("skinning")
        or self:IsProfessionAvailable("fishing")

    local f = GB.MakePanel(UIParent, "GatherBuffs - Settings")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    local function stopMoving(self)
        self:StopMovingOrSizing()
        GB.db.optX = self:GetLeft()
        GB.db.optY = self:GetTop()
    end
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", stopMoving)
    f.header:EnableMouse(true)
    f.header:RegisterForDrag("LeftButton")
    f.header:SetScript("OnDragStart", function() f:StartMoving() end)
    f.header:SetScript("OnDragStop", function() stopMoving(f) end)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide(); CloseDropdown() end)

    local tabDefs = {
        { id = "global", label = "Global" },
        { id = "consumables", label = "Consum.", visible = hasGatheringProfession },
        { id = "currencies", label = "Currencies" },
        { id = "profit", label = "Profit" },
    }
    for _, prof in ipairs(GB.GetProfessionDefs()) do
        if prof.showSettingsTab then
            table.insert(tabDefs, { id = "prof_" .. prof.id, label = prof.label, prof = prof })
        end
    end
    local visibleTabDefs = {}
    for _, td in ipairs(tabDefs) do
        local tabVisible = td.visible ~= false
        if tabVisible and (not td.prof or self:IsProfessionAvailable(td.prof.id)) then
            visibleTabDefs[#visibleTabDefs + 1] = td
        end
    end
    local nTabs = #visibleTabDefs
    local TAB_W = math.floor((PANEL_W - PAD * 2 - TAB_GAP * (nTabs - 1)) / nTabs)

    local TABS_Y = -(HDR_H + 8)
    local CONTENT_Y = TABS_Y - TAB_H - 6

    local contentFrames = {}
    for _, td in ipairs(visibleTabDefs) do
        local cf = CreateFrame("Frame", nil, f)
        cf:SetPoint("TOPLEFT", f, "TOPLEFT", 0, CONTENT_Y)
        cf:SetSize(PANEL_W, 400)
        cf:Hide()
        contentFrames[td.id] = cf
    end

    do
        local gc = contentFrames.global
        MakeBoolOptRow(gc, "Lock window", 0,
            function() return GB.db.locked end,
            function(value) GB.db.locked = value end)

        MakeBoolOptRow(gc, "Hide in combat", -24,
            function() return GB.db.hideInCombat or false end,
            function(value)
                GB.db.hideInCombat = value
                GB:RefreshMainFrameVisibility()
            end)

        MakeBoolOptRow(gc, "Minimap icon", -48,
            function() return GB.db.ui.showMinimapIcon ~= false end,
            function(value)
                GB.db.ui.showMinimapIcon = value
                GB:ApplyUiSettings()
            end)

        MakeBoolOptRow(gc, "Loot debug (shows unknown items)", -72,
            function() return GB.lootDebug or false end,
            function(value) GB.lootDebug = value end)

        MakeSliderOptRow(gc, "Background Opacity", -106, 0.00, 1.00, 0.01,
            function() return GB.db.ui.backgroundOpacity or GB.DEFAULTS.ui.backgroundOpacity end,
            function(value)
                GB.db.ui.backgroundOpacity = value
                GB:ApplyUiSettings()
            end)

        MakeSliderOptRow(gc, "Bars Opacity", -150, 0.00, 1.00, 0.01,
            function() return GB.db.ui.barOpacity or GB.db.ui.rowOpacity or GB.DEFAULTS.ui.barOpacity or GB.DEFAULTS.ui.rowOpacity end,
            function(value)
                GB.db.ui.barOpacity = value
                GB.db.ui.rowOpacity = value
                GB:ApplyUiSettings()
                GB:UpdateBars()
            end)

        MakeSliderOptRow(gc, "Text Opacity", -194, 0.00, 1.00, 0.01,
            function() return GB.db.ui.textOpacity or GB.DEFAULTS.ui.textOpacity end,
            function(value)
                GB.db.ui.textOpacity = value
                GB:ApplyUiSettings()
                GB:UpdateBars()
            end)

        MakeSliderOptRow(gc, "UI Scale", -238, 0.50, 1.50, 0.05,
            function() return GB.db.ui.scale or GB.DEFAULTS.ui.scale end,
            function(value)
                GB.db.ui.scale = value
                GB:ApplyUiSettings()
            end)
    end

    do
        local cc = contentFrames.consumables
        local globalCatIDs = { "food", "phial", "steamphial", "potion" }
        for i, catID in ipairs(globalCatIDs) do
            local cat = GB.GetCatDef(catID)
            if cat then
                MakeOptRow(cc, cat, -(28 * (i - 1)))
            end
        end
    end

    do
        local cc = contentFrames.currencies
        MakeBoolOptRow(cc, "Enable Dundun module", 0,
            function()
                return GB.db.currencies and GB.db.currencies.shard_of_dundun and GB.db.currencies.shard_of_dundun.enabled ~= false
            end,
            function(value)
                GB.db.currencies = GB.db.currencies or {}
                GB.db.currencies.shard_of_dundun = GB.db.currencies.shard_of_dundun or {}
                GB.db.currencies.shard_of_dundun.enabled = value and true or false
                GB:Rebuild()
            end)
    end

    do
        local pc = contentFrames.profit
        local y = 0
        for _, prof in ipairs(GB.GetProfessionDefs()) do
            if not prof.profitOnly and self:IsProfessionAvailable(prof.id) then
                MakeBoolOptRow(pc, "Track " .. prof.label, y,
                    function()
                        return GB:IsProfitProfessionTracked(prof.id)
                    end,
                    function(value)
                        GB.db.modules.profitTracking[prof.id] = value and true or false
                        GB:CheckProfession()
                        GB:UpdateProfit()
                    end)
                y = y - 24
            end
        end

        for _, prof in ipairs(GB.GetProfessionDefs()) do
            if prof.profitOnly and self:IsProfessionAvailable(prof.id) then
                MakeBoolOptRow(pc, prof.profitToggleLabel or ("Track " .. prof.label), y,
                    function()
                        return GB:IsProfitProfessionTracked(prof.id)
                    end,
                    function(value)
                        GB.db.modules.profitTracking[prof.id] = value and true or false
                        GB:CheckProfession()
                        GB:UpdateProfit()
                    end)
                y = y - 24
            end
        end

        MakeBoolOptRow(pc, "Include vendor loot value", y,
            function()
                return GB.db.modules.profitVendorLoot == true
            end,
            function(value)
                GB.db.modules.profitVendorLoot = value and true or false
                GB:UpdateProfit()
            end)
        y = y - 24

        MakeBoolOptRow(pc, "Auto-start on first loot", y,
            function()
                return GB.db.modules.profitAutoStartOnLoot == true
            end,
            function(value)
                GB.db.modules.profitAutoStartOnLoot = value and true or false
            end)
        y = y - 24

        MakeBoolOptRow(pc, "Exclude gear from vendor loot", y,
            function()
                return GB.db.modules.profitVendorLootExcludeGear == true
            end,
            function(value)
                GB.db.modules.profitVendorLootExcludeGear = value and true or false
                GB:UpdateProfit()
            end)
        y = y - 24

        local modeItems = {}
        for _, entry in ipairs(GB.PROFIT_PRICE_SOURCE_MODES) do
            modeItems[#modeItems + 1] = { label = entry.label, value = entry.id }
        end
        MakeChoiceOptRow(pc, "Price mode", y - 8, modeItems,
            function()
                return GB.GetProfitPriceSourceMode()
            end,
            function(value)
                GB.db.modules.profitPriceSourceMode = value
                GB:UpdateProfit()
            end)

        local sourceItems = {}
        for _, entry in ipairs(GB.PROFIT_PRICE_SOURCES) do
            sourceItems[#sourceItems + 1] = { label = entry.label, value = entry.id }
        end
        MakeChoiceOptRow(pc, "Manual source", y - 36, sourceItems,
            function()
                return GB.GetProfitPriceSource()
            end,
            function(value)
                GB.db.modules.profitPriceSource = value
                GB:UpdateProfit()
            end)
    end

    for _, td in ipairs(visibleTabDefs) do
        if td.prof then
            local pc = contentFrames[td.id]
            MakeProfOptRow(pc, td.prof, 0)
            local catList = td.prof:GetBuffCategoryIDs()
            for i, catID in ipairs(catList) do
                local cat = GB.GetCatDef(catID)
                if cat then
                    MakeOptRow(pc, cat, -(28 * i))
                end
            end
        end
    end

    local tabBtns = {}
    local function SetActiveTab(tabID)
        for _, td in ipairs(visibleTabDefs) do
            local btn = tabBtns[td.id]
            local cf = contentFrames[td.id]
            if td.id == tabID then
                btn:SetBackdropColor(0.16, 0.18, 0.26, 0.95)
                btn:SetBackdropBorderColor(0.50, 0.46, 0.22)
                btn.txt:SetTextColor(1, 0.90, 0.50)
                cf:Show()
            else
                btn:SetBackdropColor(0.08, 0.08, 0.12, 0.92)
                btn:SetBackdropBorderColor(0.26, 0.26, 0.30)
                btn.txt:SetTextColor(0.56, 0.56, 0.60)
                cf:Hide()
            end
        end
    end

    local tabX = PAD
    for _, td in ipairs(visibleTabDefs) do
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", tabX, TABS_Y)
        btn:SetSize(TAB_W, TAB_H)
        btn:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 6,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        local btnTxt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnTxt:SetAllPoints()
        btnTxt:SetJustifyH("CENTER")
        btnTxt:SetText(td.label)
        btn.txt = btnTxt
        tabBtns[td.id] = btn
        local capturedID = td.id
        btn:SetScript("OnClick", function() SetActiveTab(capturedID) end)
        tabX = tabX + TAB_W + TAB_GAP
    end

    SetActiveTab("global")

    local contentH = math.max(288, 28) + PAD
    f:SetSize(PANEL_W, HDR_H + 8 + TAB_H + 6 + contentH + PAD * 2)
    f:ClearAllPoints()
    if self.db.optX and self.db.optY then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.optX, self.db.optY)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
    end
    self.optFrame = f
    self:ApplyUiSettings()
    f:Hide()
    return f
end

function GB:ToggleOptions()
    if self.optFrame and self.optFrame:IsShown() then
        self.optFrame:Hide()
        CloseDropdown()
    else
        if self.optFrame then
            self.optFrame:Hide()
            self.optFrame = nil
        end
        self.optFrame = self:BuildOptions()
        self.optFrame:Show()
    end
end
