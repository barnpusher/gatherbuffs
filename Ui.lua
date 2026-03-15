local _, GB = ...

local W = GB.W
local ROW_H = GB.ROW_H
local HDR_H = GB.HDR_H
local PAD = GB.PAD
local ICON_W = GB.ICON_W
local LBL_W = GB.LBL_W
local NM_W = GB.NM_W
local BAR_W = GB.BAR_W
local CNT_W = GB.CNT_W
local PANEL_BG_COLOR = GB.PANEL_BG_COLOR
local ROW_BG_COLOR = GB.ROW_BG_COLOR
local HEADER_BG_COLOR = GB.HEADER_BG_COLOR
local FRAME_BG_COLOR = GB.FRAME_BG_COLOR
local TREE_BG_COLOR = GB.TREE_BG_COLOR
local PROF_ICONS = GB.PROF_ICONS

local function SetTextAlpha(region)
    if region and region.SetAlpha then
        region:SetAlpha(GB.GetTextOpacity())
    end
end

local function SetBarTextureAlpha(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r or 0, g or 0, b or 0, (a or 1) * GB.GetBarOpacity())
    end
end

local function ApplyRowTextAlpha(row)
    if not row then
        return
    end
    SetTextAlpha(row.lbl)
    SetTextAlpha(row.nm)
    SetTextAlpha(row.tm)
    SetTextAlpha(row.cnt)
    SetTextAlpha(row.left)
    SetTextAlpha(row.right)
    SetTextAlpha(row.val)
    SetTextAlpha(row.txt)
    if row.icon and row.icon.SetAlpha then
        row.icon:SetAlpha(GB.GetTextOpacity())
    end
end

local function ApplyPanelChrome(panel)
    if not panel then
        return
    end
    SetBarTextureAlpha(panel.headerBG, HEADER_BG_COLOR[1], HEADER_BG_COLOR[2], HEADER_BG_COLOR[3], HEADER_BG_COLOR[4])
    SetTextAlpha(panel.title)
    SetTextAlpha(panel.summary)
    SetTextAlpha(panel.arrow)
end

local function MakePanel(parent, titleText)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    f:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], PANEL_BG_COLOR[4])
    local header = CreateFrame("Button", nil, f)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(HDR_H)
    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetAllPoints()
    headerBG:SetTexture("Interface/Buttons/WHITE8X8")
    headerBG:SetVertexColor(HEADER_BG_COLOR[1], HEADER_BG_COLOR[2], HEADER_BG_COLOR[3], HEADER_BG_COLOR[4])
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", PAD, 0)
    title:SetJustifyH("LEFT")
    title:SetJustifyV("MIDDLE")
    title:SetText(titleText)
    title:SetTextColor(1, 1, 1)
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(2, -2)
    local summary = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("LEFT", title, "RIGHT", 10, 0)
    summary:SetPoint("RIGHT", -6, 0)
    summary:SetJustifyH("RIGHT")
    summary:SetJustifyV("MIDDLE")
    summary:SetTextColor(1, 1, 1)
    summary:SetShadowColor(0, 0, 0, 1)
    summary:SetShadowOffset(2, -2)
    local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetJustifyV("MIDDLE")
    arrow:SetText("")
    arrow:SetTextColor(1, 1, 1)
    arrow:SetShadowColor(0, 0, 0, 1)
    arrow:SetShadowOffset(2, -2)
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -HDR_H)
    content:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -HDR_H)
    content:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.title = title
    f.header = header
    f.headerBG = headerBG
    f.summary = summary
    f.arrow = arrow
    f.content = content
    return f
end

GB.MakePanel = MakePanel

local function MakeRow(parent, catDef, profID)
    local row = CreateFrame("Frame", nil, parent)
    row.catID = catDef.id
    row.profID = profID

    local bg = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetAllPoints()
    row.rowBG = bg
    GB.SetRowBackground(row, ROW_BG_COLOR[1], ROW_BG_COLOR[2], ROW_BG_COLOR[3], ROW_BG_COLOR[4])

    local icon = row:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("LEFT", 0, 0)
    icon:SetSize(16, 16)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", ICON_W, 0)
    lbl:SetWidth(LBL_W)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(catDef.label)
    lbl:SetTextColor(0.90, 0.82, 0.48)
    lbl:SetShadowColor(0, 0, 0, 1)
    lbl:SetShadowOffset(2, -2)

    local nm = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nm:SetPoint("LEFT", ICON_W + LBL_W + 2, 0)
    nm:SetWidth(NM_W)
    nm:SetJustifyH("LEFT")
    nm:SetShadowColor(0, 0, 0, 1)
    nm:SetShadowOffset(2, -2)

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("LEFT", ICON_W + LBL_W + NM_W + 4, 0)
    bar:SetSize(BAR_W, ROW_H - 4)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
    local barBG = bar:CreateTexture(nil, "BACKGROUND")
    barBG:SetAllPoints()
    barBG:SetTexture("Interface/Buttons/WHITE8X8")
    barBG:SetVertexColor(0.08, 0.08, 0.10, 0.88)

    local tm = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tm:SetAllPoints()
    tm:SetJustifyH("CENTER")
    tm:SetShadowColor(0, 0, 0, 1)
    tm:SetShadowOffset(2, -2)

    local cnt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cnt:SetPoint("LEFT", bar, "RIGHT", 3, 0)
    cnt:SetWidth(CNT_W)
    cnt:SetJustifyH("RIGHT")
    cnt:SetShadowColor(0, 0, 0, 1)
    cnt:SetShadowOffset(2, -2)

    row.nm, row.bar, row.tm, row.cnt = nm, bar, tm, cnt
    row.lbl = lbl
    row.barBG = barBG
    return row
end

GB.MakeRow = MakeRow

local function MakeInfoRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", ICON_W, 0)
    lbl:SetWidth(LBL_W)
    lbl:SetJustifyH("LEFT")
    lbl:SetTextColor(0.90, 0.82, 0.48)
    lbl:SetShadowColor(0, 0, 0, 1)
    lbl:SetShadowOffset(2, -2)
    local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    val:SetPoint("LEFT", ICON_W + LBL_W + 2, 0)
    val:SetWidth(W - PAD * 4 - ICON_W - LBL_W - 4)
    val:SetJustifyH("LEFT")
    val:SetShadowColor(0, 0, 0, 1)
    val:SetShadowOffset(2, -2)
    row.lbl, row.val = lbl, val
    return row
end

GB.MakeInfoRow = MakeInfoRow

local function MakeCurrencyTextRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)

    local icon = row:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("LEFT", 0, 0)
    icon:SetSize(16, 16)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    txt:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    txt:SetJustifyH("LEFT")
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(2, -2)
    row.txt = txt

    return row
end

local function MakeMainFrame()
    local f = CreateFrame("Frame", "GatherBuffsFrame", UIParent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    f:SetBackdropColor(FRAME_BG_COLOR[1], FRAME_BG_COLOR[2], FRAME_BG_COLOR[3], FRAME_BG_COLOR[4])
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetSize(W, 1)
    return f
end

function GB:SaveMainPosition()
    if not self.mainFrame then
        return
    end
    self.db.mainX = self.mainFrame:GetLeft()
    self.db.mainY = self.mainFrame:GetTop()
end

function GB:ApplyUiSettings()
    local ui = GB.GetUiConfig()
    local bgAlpha = math.max(0, math.min(1, ui.backgroundOpacity or GB.DEFAULTS.ui.backgroundOpacity))
    local scale = math.max(0.5, math.min(1.5, ui.scale or GB.DEFAULTS.ui.scale))

    if self.mainFrame and self.mainFrame.SetBackdropColor then
        self.mainFrame:SetBackdropColor(FRAME_BG_COLOR[1], FRAME_BG_COLOR[2], FRAME_BG_COLOR[3], bgAlpha)
        self.mainFrame:SetScale(scale)
    end
    if self.mainTree and self.mainTree.SetBackdropColor then
        self.mainTree:SetBackdropColor(TREE_BG_COLOR[1], TREE_BG_COLOR[2], TREE_BG_COLOR[3], bgAlpha)
    end
    if self.optFrame and self.optFrame.SetBackdropColor then
        self.optFrame:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], bgAlpha)
        self.optFrame:SetScale(scale)
    end

    if self.commonPanel and self.commonPanel.SetBackdropColor then
        self.commonPanel:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], bgAlpha)
    end
    if self.currencyPanel and self.currencyPanel.SetBackdropColor then
        self.currencyPanel:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], bgAlpha)
    end
    if self.profitPanel and self.profitPanel.SetBackdropColor then
        self.profitPanel:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], bgAlpha)
    end
    for _, panel in pairs(self.profCards or {}) do
        if panel and panel.SetBackdropColor then
            panel:SetBackdropColor(PANEL_BG_COLOR[1], PANEL_BG_COLOR[2], PANEL_BG_COLOR[3], bgAlpha)
        end
    end

    ApplyPanelChrome(self.commonPanel)
    ApplyPanelChrome(self.currencyPanel)
    ApplyPanelChrome(self.profitPanel)
    for _, panel in pairs(self.profCards or {}) do
        ApplyPanelChrome(panel)
        SetTextAlpha(panel.skill)
        SetTextAlpha(panel.total)
        SetTextAlpha(panel.buffs)
        SetTextAlpha(panel.nodes)
    end

    SetTextAlpha(self.combatText)
    SetTextAlpha(self.profitMeta)
    SetTextAlpha(self.profitPauseTxt)
    SetTextAlpha(self.profitResetTxt)
    SetTextAlpha(self.profitPartyTxt)
    SetTextAlpha(self.profitConsoleTxt)

    for _, row in pairs(self.commonRows or {}) do
        ApplyRowTextAlpha(row)
        SetBarTextureAlpha(row.barBG, 0.08, 0.08, 0.10, 0.88)
    end
    ApplyRowTextAlpha(self.shardRow)
    if self.shardRow then
        SetBarTextureAlpha(self.shardRow.barBG, 0.08, 0.08, 0.10, 0.88)
    end
    ApplyRowTextAlpha(self.currencyShardRow)
    for _, panel in pairs(self.profCards or {}) do
        ApplyRowTextAlpha(panel.overload)
        ApplyRowTextAlpha(panel.weaponstone)
        ApplyRowTextAlpha(panel.tool)
        ApplyRowTextAlpha(panel.enchant)
        if panel.overload then
            SetBarTextureAlpha(panel.overload.barBG, 0.08, 0.08, 0.10, 0.88)
        end
        if panel.weaponstone then
            SetBarTextureAlpha(panel.weaponstone.barBG, 0.08, 0.08, 0.10, 0.88)
        end
    end
    for _, row in ipairs(self.profitRows or {}) do
        ApplyRowTextAlpha(row)
    end

    if self.minimapButton then
        self.minimapButton:SetShown(ui.showMinimapIcon ~= false)
        self:UpdateMinimapButtonPosition()
    end
end

function GB:UpdateMinimapButtonPosition()
    if not (self.minimapButton and Minimap) then
        return
    end
    local ui = GB.GetUiConfig()
    local angle = math.rad(ui.minimapAngle or GB.DEFAULTS.ui.minimapAngle)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function GB:BuildMinimapButton()
    if self.minimapButton or not Minimap then
        return
    end

    local b = CreateFrame("Button", "GatherBuffsMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetMovable(true)
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local border = b:CreateTexture(nil, "BACKGROUND")
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(PROF_ICONS.herbalism)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon = icon

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("GatherBuffs")
        GameTooltip:AddLine("Left-click: Toggle window", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: Menu", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: Move around minimap", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(_, button)
        if b.__gbDragging then
            return
        end
        if button == "RightButton" then
            GB:ToggleContextMenu()
        else
            if GB.db and GB.db.manuallyHidden then
                GB:SetManualHidden(false)
            elseif GB.mainFrame and GB.mainFrame:IsShown() then
                GB:SetManualHidden(true)
            else
                GB:SetManualHidden(false)
            end
        end
    end)
    b:SetScript("OnDragStart", function(self)
        self.__gbDragging = true
        self:SetScript("OnUpdate", function(btn)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(GB.Atan2Safe(cy - my, cx - mx))
            GB.db.ui.minimapAngle = angle
            GB:UpdateMinimapButtonPosition()
        end)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        C_Timer.After(0, function() self.__gbDragging = false end)
    end)

    self.minimapButton = b
    self:ApplyUiSettings()
end

function GB:StartFrameDrag(owner)
    if not self.mainFrame or self.db.locked then
        return
    end
    owner.__gbDragging = true
    self.mainFrame:StartMoving()
end

function GB:StopFrameDrag(owner)
    if not self.mainFrame then
        return
    end
    self.mainFrame:StopMovingOrSizing()
    self:SaveMainPosition()
    C_Timer.After(0, function()
        if owner then
            owner.__gbDragging = false
        end
    end)
end

function GB:ResetMainPosition()
    self.db.mainX = UIParent:GetWidth() / 2 - W / 2
    self.db.mainY = UIParent:GetHeight() / 2 + 100
    if self.mainFrame then
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.mainX, self.db.mainY)
    end
end

function GB:InitializeContextMenu(_, level)
    if level ~= 1 then
        return
    end
    local function addSeparator()
        if UIDropDownMenu_AddSeparator then
            UIDropDownMenu_AddSeparator(level)
            return
        end
        local info = UIDropDownMenu_CreateInfo()
        info.text = " "
        info.disabled = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    end
    local function addButton(text, func, checked, isNotRadio, keepShownOnClick)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.func = func
        info.notCheckable = checked == nil
        info.checked = checked
        info.isNotRadio = isNotRadio
        info.keepShownOnClick = keepShownOnClick
        UIDropDownMenu_AddButton(info, level)
    end

    local title = UIDropDownMenu_CreateInfo()
    title.text = "GatherBuffs"
    title.isTitle = true
    title.notCheckable = true
    UIDropDownMenu_AddButton(title, level)

    addSeparator()
    addButton(self.db.locked and "Unlock Position" or "Lock Position", function()
        GB.db.locked = not GB.db.locked
    end)
    addButton("Settings", function() GB:ToggleOptions() end)
    addButton("Info", function() GB:ToggleInfoPopup() end)
    addButton("Reset Position", function() GB:ResetMainPosition() end)
    addButton("Hide", function() GB:SetManualHidden(true) end)
end

function GB:ToggleContextMenu()
    if not UIDropDownMenu_Initialize or not ToggleDropDownMenu then
        return
    end
    if not self.contextMenu then
        self.contextMenu = CreateFrame("Frame", "GatherBuffsContextMenu", UIParent, "UIDropDownMenuTemplate")
        self.contextMenu.displayMode = "MENU"
    end
    UIDropDownMenu_Initialize(self.contextMenu, function(...) GB:InitializeContextMenu(...) end, "MENU")
    ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 0, 0)
end

function GB:SetPanelExpanded(panel, expanded)
    panel.expanded = expanded and true or false
    panel.content:SetShown(panel.expanded)
    panel.arrow:SetText("")
end

function GB:ConfigurePanel(panel, expanded, onClick)
    self:SetPanelExpanded(panel, expanded)
    panel.header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if panel.header.SetPropagateMouseClicks then
        panel.header:SetPropagateMouseClicks(true)
    end
    panel.header:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            GB:ToggleContextMenu()
        elseif button == "LeftButton" then
            onClick()
        end
    end)
end

function GB:BuildStaticUI()
    self.mainFrame = MakeMainFrame()
    self.mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.mainX, self.db.mainY)
    self.mainTree = CreateFrame("Frame", nil, self.mainFrame, "BackdropTemplate")
    self.mainTree:SetPoint("TOPLEFT", 1, -1)
    self.mainTree:SetPoint("TOPRIGHT", -1, -1)
    self.mainTree:SetWidth(W - 2)
    self.mainTree:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    self.mainTree:SetBackdropColor(TREE_BG_COLOR[1], TREE_BG_COLOR[2], TREE_BG_COLOR[3], TREE_BG_COLOR[4])
    self.mainTree:EnableMouse(true)
    self.mainTree:RegisterForDrag("LeftButton")
    self.mainTree:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            GB:ToggleContextMenu()
        end
    end)
    self.mainTree:SetScript("OnDragStart", function() GB:StartFrameDrag(self.mainTree) end)
    self.mainTree:SetScript("OnDragStop", function() GB:StopFrameDrag(self.mainTree) end)

    self.commonPanel = MakePanel(self.mainTree, "Buffs")
    self:ConfigurePanel(self.commonPanel, self.db.modules.globalExpanded, function()
        GB.db.modules.globalExpanded = not GB.db.modules.globalExpanded
        GB:Rebuild()
    end)
    self.combatText = self.commonPanel.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.combatText:SetAllPoints()
    self.combatText:SetJustifyH("CENTER")
    self.combatText:SetJustifyV("MIDDLE")
    self.combatText:SetText("⚔")
    self.combatText:SetTextColor(0.85, 0.15, 0.15)
    self.combatText:Hide()
    self.commonRows = {}
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        if cat.scope == "common" then
            self.commonRows[cat.id] = MakeRow(self.commonPanel.content, cat)
            self.commonRows[cat.id]:Hide()
        end
    end
    self.shardRow = MakeRow(self.commonPanel.content, { id = "shard_of_dundun", label = "Shard" })
    self.shardRow.cnt:Hide()
    self.shardRow:Hide()
    self.currencyPanel = MakePanel(self.mainTree, "Dundun")
    self:ConfigurePanel(self.currencyPanel, self.db.modules.dundunExpanded, function()
        GB.db.modules.dundunExpanded = not GB.db.modules.dundunExpanded
        GB:Rebuild()
    end)
    self.currencyShardRow = MakeCurrencyTextRow(self.currencyPanel.content)
    self.currencyShardRow:Hide()

    self.profCards = {}
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        if not prof.profitOnly then
            local card = MakePanel(self.mainTree, prof.label)
            card.profID = prof.id
            self:ConfigurePanel(card, self:IsProfessionExpanded(prof.id), function()
                GB:SetProfessionExpanded(prof.id, not GB:IsProfessionExpanded(prof.id))
                GB:Rebuild()
            end)
            card.skill = card.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            card.skill:SetPoint("TOPLEFT", PAD, -4)
            card.skill:SetWidth(W - PAD * 4)
            card.skill:SetJustifyH("LEFT")
            card.total = card.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            card.total:SetPoint("TOPLEFT", PAD, -21)
            card.total:SetWidth(W - PAD * 4)
            card.total:SetJustifyH("LEFT")
            card.buffs = card.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            card.buffs:SetPoint("TOPLEFT", PAD, -38)
            card.buffs:SetWidth(W - PAD * 4)
            card.buffs:SetJustifyH("LEFT")
            card.nodes = card.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            card.nodes:SetPoint("TOPLEFT", PAD, -55)
            card.nodes:SetWidth(W - PAD * 4)
            card.nodes:SetJustifyH("LEFT")
            card.nodes:SetTextColor(0.62, 0.68, 0.74)
            local overloadCatDef = GB.GetCatDef("overload_" .. prof.id)
            card.overload = overloadCatDef and MakeRow(card.content, overloadCatDef) or nil
            if prof.id == "mining" then
                card.weaponstone = MakeRow(card.content, GB.GetCatDef("weaponstone"), prof.id)
                card.tool = MakeInfoRow(card.content)
                card.tool.lbl:SetText("Tool")
                card.enchant = MakeInfoRow(card.content)
                card.enchant.lbl:SetText("Enchant")
            end
            card:Hide()
            self.profCards[prof.id] = card
        end
    end

    self.profitPanel = MakePanel(self.mainTree, "Profit")
    self:ConfigurePanel(self.profitPanel, self.db.modules.profitExpanded, function()
        GB.db.modules.profitExpanded = not GB.db.modules.profitExpanded
        GB:Rebuild()
    end)
    self.profitMeta = self.profitPanel.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.profitMeta:SetPoint("TOPLEFT", PAD, -9)
    self.profitMeta:SetWidth(W - PAD * 2 - 250)
    self.profitMeta:SetJustifyH("LEFT")
    self.profitMeta:SetTextColor(0.68, 0.70, 0.74)
    self.profitResetBtn = CreateFrame("Button", nil, self.profitPanel.content, "BackdropTemplate")
    self.profitResetBtn:SetPoint("TOPRIGHT", -PAD, -7)
    self.profitResetBtn:SetSize(52, 18)
    self.profitResetBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    self.profitResetBtn:SetBackdropColor(0.18, 0.10, 0.10, 0.92)
    self.profitResetBtn:SetBackdropBorderColor(0.46, 0.20, 0.20)
    local resetText = self.profitResetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetAllPoints()
    resetText:SetText("Reset")
    resetText:SetTextColor(0.92, 0.78, 0.78)
    self.profitResetTxt = resetText
    self.profitResetBtn:SetScript("OnClick", function() GB:ResetSession() end)

    self.profitPauseBtn = CreateFrame("Button", nil, self.profitPanel.content, "BackdropTemplate")
    self.profitPauseBtn:SetPoint("TOPRIGHT", self.profitResetBtn, "TOPLEFT", -4, 0)
    self.profitPauseBtn:SetSize(58, 18)
    self.profitPauseBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    self.profitPauseBtn:SetBackdropColor(0.10, 0.20, 0.10, 0.92)
    self.profitPauseBtn:SetBackdropBorderColor(0.20, 0.52, 0.20)
    self.profitPauseTxt = self.profitPauseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.profitPauseTxt:SetAllPoints()
    self.profitPauseTxt:SetText("Pause")
    self.profitPauseTxt:SetTextColor(0.70, 0.92, 0.70)
    self.profitPauseBtn:SetScript("OnClick", function() GB:TogglePause() end)

    self.profitPartyBtn = CreateFrame("Button", nil, self.profitPanel.content, "BackdropTemplate")
    self.profitPartyBtn:SetPoint("TOPRIGHT", self.profitPauseBtn, "TOPLEFT", -4, 0)
    self.profitPartyBtn:SetSize(52, 18)
    self.profitPartyBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    self.profitPartyBtn:SetBackdropColor(0.10, 0.14, 0.22, 0.92)
    self.profitPartyBtn:SetBackdropBorderColor(0.24, 0.38, 0.62)
    local partyText = self.profitPartyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    partyText:SetAllPoints()
    partyText:SetText("Report")
    partyText:SetTextColor(0.72, 0.82, 0.96)
    self.profitPartyTxt = partyText
    self.profitPartyBtn:SetScript("OnClick", function() GB:SendProfitReportToChat() end)

    self.profitConsoleBtn = CreateFrame("Button", nil, self.profitPanel.content, "BackdropTemplate")
    self.profitConsoleBtn:SetPoint("TOPRIGHT", self.profitPartyBtn, "TOPLEFT", -4, 0)
    self.profitConsoleBtn:SetSize(56, 18)
    self.profitConsoleBtn:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    self.profitConsoleBtn:SetBackdropColor(0.16, 0.12, 0.22, 0.92)
    self.profitConsoleBtn:SetBackdropBorderColor(0.42, 0.30, 0.62)
    local consoleText = self.profitConsoleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    consoleText:SetAllPoints()
    consoleText:SetText("Console")
    consoleText:SetTextColor(0.84, 0.78, 0.96)
    self.profitConsoleTxt = consoleText
    self.profitConsoleBtn:SetScript("OnClick", function() GB:PrintProfitReportToConsole() end)
    self.profitRows = {}
    self.profitVisibleRowCount = 0
    self:EnsureProfitRows(0)
end

local function FormatProfessionStatSummary(snapshot)
    if not snapshot then
        return "-"
    end
    local cur = snapshot.current or GB.MakeTotals()
    local max = snapshot.max or GB.MakeTotals()
    return string.format(
        "Fin: %d/%d   Per: %d/%d   Def: %d/%d   Speed: %s/%s",
        cur.finesse or 0,
        max.finesse or 0,
        cur.perception or 0,
        max.perception or 0,
        cur.deftness or 0,
        max.deftness or 0,
        GB.FormatStat("speedPct", cur.speedPct or 0),
        GB.FormatStat("speedPct", max.speedPct or 0)
    )
end

local function ApplyRow(row, buff, aura)
    local catDef = GB.GetCatDef(row.catID)
    local count = GB.GetBuffCount(buff)
    if count ~= nil then
        row.cnt:SetText("(" .. count .. ")")
        row.cnt:SetTextColor(count == 0 and 0.80 or 0.55, count == 0 and 0.30 or 0.55, count == 0 and 0.30 or 0.55)
    else
        row.cnt:SetText("")
    end

    if row.icon then
        local tex
        if buff and buff.itemIDs and buff.itemIDs[1] then
            tex = GetItemIcon(buff.itemIDs[1])
        end
        if not tex and buff and buff.spellID then
            tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(buff.spellID)
        end
        if not tex and catDef and catDef.profIcon then
            tex = PROF_ICONS[catDef.profIcon]
        end
        if tex then
            row.icon:SetTexture(tex)
            row.icon:Show()
        else
            row.icon:Hide()
        end
    end

    if not buff then
        row.nm:SetText("- None -")
        row.nm:SetTextColor(0.38, 0.38, 0.38)
        row.bar:SetValue(0)
        GB.SetStatusBarColor(row.bar, 0.18, 0.18, 0.18)
        row.tm:SetText("-")
        GB.SetRowBackground(row, 0, 0, 0, 0)
        return
    end

    local nameStr = GB.Trunc(buff.name, 16)
    if buff.quality then
        nameStr = nameStr .. " " .. GB.FormatQualityText(buff.quality)
    end
    row.nm:SetText(nameStr)
    if not buff.spellID then
        row.nm:SetTextColor(0.75, 0.68, 0.35)
        row.bar:SetValue(0)
        GB.SetStatusBarColor(row.bar, 0.28, 0.24, 0.10)
        row.tm:SetText("ID?")
        GB.SetRowBackground(row, 0.28, 0.22, 0.02, 0.25)
        return
    end

    if aura then
        local pct, left = 1, math.huge
        if not aura.equipped and aura.expirationTime and aura.expirationTime > 0 then
            left = aura.expirationTime - GetTime()
            local dur = (aura.duration and aura.duration > 0) and aura.duration or buff.maxDuration or 60
            pct = math.max(0, math.min(1, left / dur))
        end
        row.bar:SetValue(pct)
        row.tm:SetText(aura.equipped and "Worn" or GB.FormatTime(left))
        row.nm:SetTextColor(1, 1, 1)
        GB.SetRowBackground(row, 0, 0, 0, 0)
        if pct > 0.30 then
            GB.SetStatusBarColor(row.bar, 0.18, 0.72, 0.22)
        elseif pct > 0.10 then
            GB.SetStatusBarColor(row.bar, 0.90, 0.55, 0.08)
        else
            GB.SetStatusBarColor(row.bar, 0.88, 0.18, 0.18)
        end
    elseif catDef and catDef.showAvailable then
        local cooldown = GB.GetSpellCooldownInfo(buff.spellID)
        if cooldown then
            local pct = 0
            if cooldown.duration and cooldown.duration > 0 then
                pct = math.max(0, math.min(1, cooldown.remaining / cooldown.duration))
            end
            row.bar:SetValue(pct)
            GB.SetStatusBarColor(row.bar, 0.62, 0.32, 0.10)
            row.tm:SetText(GB.FormatTime(cooldown.remaining))
            row.nm:SetTextColor(0.90, 0.74, 0.42)
        else
            row.bar:SetValue(0.15)
            GB.SetStatusBarColor(row.bar, 0.18, 0.45, 0.18)
            row.tm:SetText("Avail")
            row.nm:SetTextColor(0.65, 0.82, 0.65)
        end
        GB.SetRowBackground(row, 0, 0, 0, 0)
    else
        row.bar:SetValue(0)
        GB.SetStatusBarColor(row.bar, 0.40, 0.10, 0.10)
        row.tm:SetText("MISS")
        row.nm:SetTextColor(0.52, 0.52, 0.52)
        GB.SetRowBackground(row, 0.55, 0.05, 0.05, 0.32)
    end
end

local function ApplyCurrencyRow(row, info)
    if not row then
        return
    end
    if not info then
        row:Hide()
        return
    end

    row:Show()

    if row.icon then
        if info.iconFileID then
            row.icon:SetTexture(info.iconFileID)
            row.icon:Show()
        else
            row.icon:Hide()
        end
    end

    if row.txt then
        row.txt:SetText(string.format("Shards of Dundun   %s", GB.FormatShardDisplayText(info, GB:GetShardSpentThisWeek(info), false)))
        row.txt:SetTextColor(1, 1, 1)
    end
end

function GB:Rebuild()
    self.profMap, self.profOrder = GB.SnapshotProfessions()
    self.hasProfitProfession = false
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        if self:IsProfessionAvailable(prof.id) and self:IsProfessionModuleEnabled(prof.id) and self:IsProfitProfessionTracked(prof.id) then
            self.hasProfitProfession = true
            break
        end
    end
    self.commonPanel:Show()
    local activeCommon, y = {}, PAD
    self.commonPanel:SetPoint("TOPLEFT", self.mainTree, "TOPLEFT", PAD, -y)
    local commonStart = 4
    local n = 0
    for _, cat in ipairs(GATHERBUFFS_CATEGORIES) do
        if cat.scope == "common" then
            local row, db = self.commonRows[cat.id], self.db.categories[cat.id]
            local profOK = true
            if cat.professions then
                profOK = false
                for _, pid in ipairs(cat.professions) do
                    if self.profMap[pid] then
                        profOK = true
                        break
                    end
                end
            end
            if db and db.enabled and profOK then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.commonPanel.content, "TOPLEFT", PAD, -(commonStart + n * (ROW_H + 3)))
                row:SetWidth(W - PAD * 4)
                row:SetHeight(ROW_H)
                row:SetShown(self.db.modules.globalExpanded)
                table.insert(activeCommon, row)
                n = n + 1
            else
                row:Hide()
            end
        end
    end
    if self.shardRow then
        self.shardRow:Hide()
    end
    self.activeCommonRows = activeCommon
    self:SetPanelExpanded(self.commonPanel, self.db.modules.globalExpanded)
    local commonHeight = self.db.modules.globalExpanded and (commonStart + math.max(1, n) * (ROW_H + 3) + PAD + 21) or HDR_H
    self.commonPanel:SetSize(W - PAD * 2, commonHeight)
    y = y + commonHeight + PAD

    local shardInfo = GB.GetShardOfDundunInfo()
    local shardEnabled = self.db.currencies and self.db.currencies.shard_of_dundun and self.db.currencies.shard_of_dundun.enabled ~= false
    if shardInfo and shardEnabled then
        self.currencyPanel:Show()
        self.currencyPanel:SetPoint("TOPLEFT", self.mainTree, "TOPLEFT", PAD, -y)
        self:SetPanelExpanded(self.currencyPanel, self.db.modules.dundunExpanded)
        if self.db.modules.dundunExpanded then
            self.currencyShardRow:ClearAllPoints()
            self.currencyShardRow:SetPoint("TOPLEFT", self.currencyPanel.content, "TOPLEFT", PAD, -4)
            self.currencyShardRow:SetWidth(W - PAD * 3)
            self.currencyShardRow:SetHeight(ROW_H)
            self.currencyShardRow:SetShown(true)
            self.currencyPanel:SetSize(W - PAD * 2, 4 + ROW_H + PAD + 21)
        else
            self.currencyShardRow:Hide()
            self.currencyPanel:SetSize(W - PAD * 2, HDR_H)
        end
        y = y + self.currencyPanel:GetHeight() + PAD
    else
        self.currencyPanel:Hide()
        self.currencyShardRow:Hide()
    end

    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        local card, info = self.profCards[prof.id], self:GetProfessionDisplayInfo(prof.id)
        if card and info and self:IsProfessionModuleEnabled(prof.id) then
            local nodeText = GB.GetNodeSkillSummary(prof.id)
            local showNodes = nodeText and nodeText ~= ""
            local expanded = self:IsProfessionExpanded(prof.id)
            local isFishing = prof.id == "fishing"
            card:SetPoint("TOPLEFT", self.mainTree, "TOPLEFT", PAD, -y)
            self:SetPanelExpanded(card, expanded)

            local rowY = isFishing and 56 or (showNodes and 72 or 56)
            local overloadCatID = "overload_" .. prof.id
            local overloadEnabled = card.overload and self.db.categories[overloadCatID] and self.db.categories[overloadCatID].enabled
            local wsEnabled = card.weaponstone and self.db.categories.weaponstone and self.db.categories.weaponstone.enabled

            if card.overload then
                card.overload:ClearAllPoints()
                card.overload:SetPoint("TOPLEFT", card.content, "TOPLEFT", PAD, -rowY)
                card.overload:SetWidth(W - PAD * 4)
                card.overload:SetHeight(ROW_H)
                card.overload:SetShown(expanded and overloadEnabled)
            end
            if overloadEnabled then
                rowY = rowY + ROW_H + 4
            end

            if card.weaponstone then
                card.weaponstone:ClearAllPoints()
                card.weaponstone:SetPoint("TOPLEFT", card.content, "TOPLEFT", PAD, -rowY)
                card.weaponstone:SetWidth(W - PAD * 4)
                card.weaponstone:SetHeight(ROW_H)
                card.weaponstone:SetShown(expanded and wsEnabled)
                if wsEnabled then
                    rowY = rowY + ROW_H + 4
                end
            end

            if card.tool then
                card.tool:ClearAllPoints()
                card.tool:SetPoint("TOPLEFT", card.content, "TOPLEFT", PAD, -rowY)
                card.tool:SetWidth(W - PAD * 4)
                card.tool:SetShown(expanded)
                rowY = rowY + ROW_H + 4
            end

            if card.enchant then
                card.enchant:ClearAllPoints()
                card.enchant:SetPoint("TOPLEFT", card.content, "TOPLEFT", PAD, -rowY)
                card.enchant:SetWidth(W - PAD * 4)
                card.enchant:SetShown(expanded)
                rowY = rowY + ROW_H + 4
            end

            local detailHeight = rowY + PAD + 20
            card:SetSize(W - PAD * 2, expanded and detailHeight or HDR_H)

            if showNodes then
                card.nodes:SetText(nodeText)
                card.nodes:SetShown(expanded)
            else
                card.nodes:Hide()
            end
            card.skill:SetShown(expanded)
            card.total:SetShown(expanded)
            card.buffs:SetShown(expanded)
            card:Show()
            y = y + card:GetHeight() + PAD
        else
            if card then
                card:Hide()
            end
        end
    end

    if self.hasProfitProfession then
        self.profitPanel:Show()
        self.profitPanel:SetPoint("TOPLEFT", self.mainTree, "TOPLEFT", PAD, -y)
        local profitRowCount = self.profitVisibleRowCount or 0
        self:EnsureProfitRows(profitRowCount)
        self:SetPanelExpanded(self.profitPanel, self.db.modules.profitExpanded)
        self.profitPanel:SetSize(W - PAD * 2, self.db.modules.profitExpanded and (HDR_H + 36 + (profitRowCount * 15) + PAD + 21) or HDR_H)
        y = y + self.profitPanel:GetHeight() + PAD
    else
        self.profitPanel:Hide()
    end
    if self.mainTree then
        self.mainTree:SetHeight(y)
    end
    self.mainFrame:SetSize(W, y + 2)
    self:UpdateBars()
end

function GB:UpdateBars()
    self:UpdateSummary()
    local inCombat = InCombatLockdown()
    for _, row in ipairs(self.activeCommonRows or {}) do
        if not inCombat then
            ApplyRow(row, self:GetRowBuff(row.catID))
        end
    end
    local shardInfo = GB.GetShardOfDundunInfo()
    local shardEnabled = self.db.currencies and self.db.currencies.shard_of_dundun and self.db.currencies.shard_of_dundun.enabled ~= false
    if self.currencyPanel then
        if shardInfo and shardEnabled and not self.db.modules.dundunExpanded then
            self.currencyPanel.summary:SetText(GB.FormatShardDisplayText(shardInfo, self:GetShardSpentThisWeek(shardInfo), false))
        else
            self.currencyPanel.summary:SetText("")
        end
    end
    if not inCombat and self.currencyShardRow and self.db.modules.dundunExpanded and shardEnabled then
        ApplyCurrencyRow(self.currencyShardRow, shardInfo)
    end
    for _, prof in ipairs(GATHERBUFFS_PROFESSIONS) do
        local card, info = self.profCards and self.profCards[prof.id], self:GetProfessionDisplayInfo(prof.id)
        if card and info then
            local isFishing = prof.id == "fishing"
            card.title:SetText(info.label)
            local weeklyItemsText = GB.GetProfessionWeeklyItemText(prof.id)
            if isFishing then
                card.summary:SetText(string.format("%d/%d", info.skill, info.maxSkill))
            elseif weeklyItemsText and weeklyItemsText ~= "" then
                card.summary:SetText(string.format("%s   %d/%d", weeklyItemsText, info.skill, info.maxSkill))
            else
                card.summary:SetText(string.format("%d/%d", info.skill, info.maxSkill))
            end
            card.skill:SetText(string.format("Raw skill: %d / %d", info.skill, info.maxSkill))
            card.total:SetText(string.format("Current total: %d (%+d equipped bonus)", info.total, info.bonus))
            card.buffs:SetText(FormatProfessionStatSummary(inCombat and nil or self:GetProfessionStatSnapshot(prof.id)))
            local nodeText = GB.GetNodeSkillSummary(prof.id)
            if nodeText and nodeText ~= "" then
                card.nodes:SetText(nodeText)
                card.nodes:Show()
            else
                card.nodes:Hide()
            end
            if card.overload and not inCombat then
                ApplyRow(card.overload, self:GetRowBuff("overload_" .. prof.id))
            end
            if card.weaponstone and not inCombat then
                ApplyRow(card.weaponstone, self:GetRowBuff("weaponstone", prof.id))
            end
            if card.tool then
                local slots = GB.GetProfessionEquipmentSlots(info)
                local toolID = slots and slots.tool and GetInventoryItemID("player", slots.tool)
                if toolID then
                    local itemName = GetItemInfo(toolID)
                    local isMidnightTool = GATHERBUFFS_MINING_TOOLS and GATHERBUFFS_MINING_TOOLS[toolID]
                    if isMidnightTool then
                        card.tool.val:SetText("|cff00ee44" .. (itemName or "Unknown") .. "|r")
                    else
                        card.tool.val:SetText("|cffffff55" .. (itemName or "Unknown") .. " (unverified)|r")
                    end
                else
                    card.tool.val:SetText("|cffff4444None|r")
                end
            end
            if card.enchant then
                local enchantInfo = GB.GetProfessionToolEnchantInfo(info)
                if enchantInfo and enchantInfo.hasEnchant then
                    local label = enchantInfo.enchantName or ("Enchant ID " .. enchantInfo.enchantID)
                    card.enchant.val:SetText("|cff00ee44" .. label .. "|r")
                else
                    card.enchant.val:SetText("|cffff4444None|r")
                end
            end
        end
    end
    self:UpdateProfit()
end
