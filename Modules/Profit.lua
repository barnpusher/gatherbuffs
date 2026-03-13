local _, GB = ...

local W = GB.W
local PAD = GB.PAD
local QUAL_ICON = GB.QUAL_ICON
local AUCTIONATOR_CALLER = "GatherBuffs"
local MIN_GPH_ELAPSED = 60

function GB:GetActiveElapsed()
    local paused = self.sessionPaused
    local total = self.sessionPausedTotal or 0
    local start = self.sessionStart or time()
    if paused then
        local pausedAt = (self.sessionPausedAt and self.sessionPausedAt > 0) and self.sessionPausedAt or start
        return math.max(0, pausedAt - start - total)
    end
    return math.max(0, time() - start - total)
end

function GB:LoadSessionState()
    local session = self.db.session or {}
    self.sessionStart = session.startedAt or time()
    self.sessionPaused = session.paused ~= false
    self.sessionPausedAt = session.pausedAt or 0
    self.sessionPausedTotal = session.pausedTotal or 0
    self.sessionLoot = {}
    self.sessionOrder = {}

    for _, itemID in ipairs(session.order or {}) do
        local key = tostring(itemID)
        local item = session.loot and session.loot[key]
        if item and item.itemID then
            self.sessionLoot[item.itemID] = {
                itemID = item.itemID,
                link = item.link,
                name = item.name,
                count = item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
                price = item.price,
                quality = item.quality,
            }
            table.insert(self.sessionOrder, item.itemID)
        end
    end
end

function GB:SaveSessionState()
    local session = {
        startedAt = self.sessionStart or time(),
        paused = self.sessionPaused or false,
        pausedAt = self.sessionPausedAt or 0,
        pausedTotal = self.sessionPausedTotal or 0,
        loot = {},
        order = {},
    }

    for _, itemID in ipairs(self.sessionOrder or {}) do
        local item = self.sessionLoot and self.sessionLoot[itemID]
        if item then
            local key = tostring(itemID)
            session.order[#session.order + 1] = itemID
            session.loot[key] = {
                itemID = item.itemID,
                link = item.link,
                name = item.name,
                count = item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
                price = item.price,
                quality = item.quality,
            }
        end
    end

    self.db.session = session
end

function GB:TogglePause()
    if self.sessionPaused then
        local pausedAt = self.sessionPausedAt or self.sessionStart or time()
        self.sessionPausedTotal = (self.sessionPausedTotal or 0) + (time() - pausedAt)
        self.sessionPaused = false
    else
        self.sessionPausedAt = time()
        self.sessionPaused = true
    end
    self:SaveSessionState()
    self:UpdateProfit()
end

function GB:ResetSession()
    self.sessionStart = time()
    self.sessionPaused = true
    self.sessionPausedAt = time()
    self.sessionPausedTotal = 0
    self.sessionLoot = {}
    self.sessionOrder = {}
    self.lastGphValue = 0
    self.lastGphUpdateTime = nil
    self.gphDirty = true
    self:SaveSessionState()
    if self.profitPanel then
        self:UpdateProfit()
    end
end

local function GetTSMPrice(itemID)
    if TSM_API and TSM_API.GetCustomPriceValue then
        local ok, value = pcall(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    if TSM_API and TSM_API.FOUR and TSM_API.FOUR.CustomPrice and TSM_API.FOUR.CustomPrice.GetValue then
        local ok, value = pcall(TSM_API.FOUR.CustomPrice.GetValue, "DBMarket", "i:" .. itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    return nil
end

local function GetZygorTrendItem(itemID)
    if not (ZGV and ZGV.Gold) then
        return nil
    end
    local trends = ZGV.Gold.servertrends or ZGV.Gold.ServerTrends or ZGV.Gold.ServerTrend
    if trends and trends.items and trends.items[itemID] then
        return trends.items[itemID]
    end
    local globalTrends = ZGV.Gold.servertrends_global
    if globalTrends and globalTrends.items then
        return globalTrends.items[itemID]
    end
    return nil
end

local function GetZygorLivePrice(itemID)
    if ZGV and ZGV.Gold and ZGV.Gold.Scan and ZGV.Gold.Scan.GetPrice then
        local ok, value = pcall(ZGV.Gold.Scan.GetPrice, ZGV.Gold.Scan, itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    return nil
end

local function HasZygorScanData()
    if not (ZGV and ZGV.Gold and ZGV.Gold.Scan and ZGV.Gold.Scan.data) then
        return false
    end
    local data = ZGV.Gold.Scan.data
    local today = data.today
    return type(today) == "number" and type(data[today]) == "table" and next(data[today]) ~= nil
end

local function HasZygorTrendData()
    if not (ZGV and ZGV.Gold) then
        return false
    end
    local trends = ZGV.Gold.servertrends
    if trends and type(trends.items) == "table" and next(trends.items) ~= nil then
        return true
    end
    local globalTrends = ZGV.Gold.servertrends_global
    return globalTrends and type(globalTrends.items) == "table" and next(globalTrends.items) ~= nil
end

local function GetAuctionatorPrice(itemID)
    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
        local ok, value = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, AUCTIONATOR_CALLER, itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    return nil
end

local PRICE_PROVIDERS = {
    tsm = GetTSMPrice,
    zygor_scan = GetZygorLivePrice,
    zygor_median = function(itemID)
        local trendItem = GetZygorTrendItem(itemID)
        if trendItem and trendItem.p_md and trendItem.p_md > 0 then
            return trendItem.p_md
        end
        return nil
    end,
    zygor_low = function(itemID)
        local trendItem = GetZygorTrendItem(itemID)
        if trendItem and trendItem.p_lo and trendItem.p_lo > 0 then
            return trendItem.p_lo
        end
        return nil
    end,
    auctionator = GetAuctionatorPrice,
}

local AUTO_PRICE_SOURCE_ORDER = {
    "tsm",
    "zygor_scan",
    "zygor_median",
    "zygor_low",
    "auctionator",
}

local function IsPriceSourceAvailable(sourceID)
    if sourceID == "tsm" then
        return TSM_API ~= nil
    end
    if sourceID == "zygor_scan" then
        return HasZygorScanData()
    end
    if sourceID == "zygor_median" or sourceID == "zygor_low" then
        return HasZygorTrendData()
    end
    if sourceID == "auctionator" then
        return Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID
    end
    return false
end

function GB:GetPrice(itemID)
    if not itemID then
        return nil
    end

    local mode = GB.GetProfitPriceSourceMode()
    if mode == "manual" then
        local sourceID = GB.GetProfitPriceSource()
        local provider = PRICE_PROVIDERS[sourceID]
        if provider then
            return provider(itemID)
        end
        return nil
    end

    for _, sourceID in ipairs(AUTO_PRICE_SOURCE_ORDER) do
        local provider = PRICE_PROVIDERS[sourceID]
        local value = provider and provider(itemID)
        if value then
            return value
        end
    end

    return nil
end

function GB:TrackLoot(itemID, amount, link)
    if not itemID or not amount or amount <= 0 then
        return
    end
    local item = self.sessionLoot[itemID]
    if not item then
        item = { itemID = itemID, name = link or ("item:" .. itemID), count = 0, firstSeen = time() }
        self.sessionLoot[itemID] = item
        table.insert(self.sessionOrder, itemID)
    end
    item.count = item.count + amount
    item.link = link or item.link
    item.price = self:GetPrice(itemID)
    self.gphDirty = true
    if not item.quality then
        local _, _, q = GetItemInfo(itemID)
        item.quality = q
    end
    self:SaveSessionState()
end

function GB:RefreshSessionPrices()
    for _, itemID in ipairs(self.sessionOrder) do
        local item = self.sessionLoot[itemID]
        if item then
            local newPrice = self:GetPrice(itemID)
            if newPrice ~= item.price then
                item.price = newPrice
                self.gphDirty = true
            end
            if not item.quality then
                local _, _, q = GetItemInfo(itemID)
                item.quality = q
            end
        end
    end
    self:SaveSessionState()
end

local PROFIT_VAL_W = 84

function GB:EnsureProfitRows(count)
    self.profitRows = self.profitRows or {}
    local current = #self.profitRows
    for i = current + 1, count do
        local f = CreateFrame("Frame", nil, self.profitPanel.content)
        f:SetHeight(15)
        local left = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        left:SetPoint("LEFT", 0, 0)
        left:SetPoint("RIGHT", f, "RIGHT", -PROFIT_VAL_W, 0)
        left:SetJustifyH("LEFT")
        local right = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        right:SetPoint("RIGHT", f, "RIGHT", 0, 0)
        right:SetWidth(PROFIT_VAL_W)
        right:SetJustifyH("RIGHT")
        f.left, f.right = left, right
        self.profitRows[i] = f
    end
    for i, row in ipairs(self.profitRows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PAD, -(29 + (i - 1) * 15))
        row:SetWidth(W - PAD * 4)
        row:SetShown(i <= count)
    end
end

function GB:UpdateProfit()
    self:RefreshSessionPrices()
    local totalValue, rows = 0, {}

    local byGroup, groupOrder, groupDisplay = {}, {}, {}
    for _, itemID in ipairs(self.sessionOrder) do
        local item = self.sessionLoot[itemID]
        if item then
            local itemName = GetItemInfo(itemID)
            local lookupInfo = self.gatherLookup and self.gatherLookup[itemID]
            local groupKey = lookupInfo and lookupInfo.name or ("__id_" .. itemID)
            local displayName = lookupInfo and lookupInfo.name
                or itemName
                or (item.link or ""):match("%[(.-)%]")
                or ("item:" .. itemID)
            if not byGroup[groupKey] then
                byGroup[groupKey] = {}
                table.insert(groupOrder, groupKey)
                groupDisplay[groupKey] = displayName
            end
            table.insert(byGroup[groupKey], item)
        end
    end

    for _, groupKey in ipairs(groupOrder) do
        local variants = byGroup[groupKey]
        table.sort(variants, function(a, b)
            local la = self.gatherLookup and self.gatherLookup[a.itemID]
            local lb = self.gatherLookup and self.gatherLookup[b.itemID]
            return (la and la.tier or 0) < (lb and lb.tier or 0)
        end)

        local firstLookup = self.gatherLookup and variants[1] and self.gatherLookup[variants[1].itemID]
        local multiQ = firstLookup and (firstLookup.totalTiers or 1) > 1

        local lineValue, totalCount, parts = 0, 0, {}
        local variantByID = {}
        for _, item in ipairs(variants) do
            variantByID[item.itemID] = item
        end

        for _, item in ipairs(variants) do
            local value = (item.price or 0) * item.count
            lineValue = lineValue + value
            totalValue = totalValue + value
            totalCount = totalCount + item.count
        end

        if multiQ and firstLookup then
            for _, tierID in ipairs(firstLookup.entry.ids) do
                local tLookup = self.gatherLookup[tierID]
                local tier = tLookup and tLookup.tier or 1
                local dot = QUAL_ICON[tier] or string.format("[%d]", tier)
                local cnt = variantByID[tierID] and variantByID[tierID].count or 0
                table.insert(parts, string.format("%s x%d", dot, cnt))
            end
        end

        local name = groupDisplay[groupKey] or groupKey
        local countStr = multiQ and table.concat(parts, "  ") or ("x" .. totalCount)
        local valueStr = lineValue > 0 and GB.FormatGoldSilver(lineValue) or "(no price)"
        table.insert(rows, { left = string.format("%s  %s", name, countStr), right = valueStr })
    end

    self.profitVisibleRowCount = #rows
    self:EnsureProfitRows(#rows)
    self.profitMeta:SetText(string.format("Started: %s", date("%Y-%m-%d %H:%M", self.sessionStart)))

    local paused = self.sessionPaused
    local elapsed = self:GetActiveElapsed()

    if self.profitPauseBtn then
        if paused then
            self.profitPauseTxt:SetText("Start")
            self.profitPauseTxt:SetTextColor(0.70, 0.92, 0.70)
            self.profitPauseBtn:SetBackdropColor(0.10, 0.20, 0.10, 0.92)
            self.profitPauseBtn:SetBackdropBorderColor(0.20, 0.52, 0.20)
        else
            self.profitPauseTxt:SetText("Pause")
            self.profitPauseTxt:SetTextColor(0.92, 0.70, 0.30)
            self.profitPauseBtn:SetBackdropColor(0.20, 0.14, 0.04, 0.92)
            self.profitPauseBtn:SetBackdropBorderColor(0.52, 0.36, 0.10)
        end
    end

    local now = time()
    if self.gphDirty or not self.lastGphUpdateTime or (now - self.lastGphUpdateTime) >= 60 then
        if totalValue > 0 and elapsed > 0 then
            self.lastGphValue = math.floor((totalValue * 3600) / math.max(elapsed, MIN_GPH_ELAPSED))
        else
            self.lastGphValue = 0
        end
        self.lastGphUpdateTime = now
        self.gphDirty = false
    end
    local gphGold = math.floor((self.lastGphValue or 0) / 10000)
    local sessionGold = math.floor(totalValue / 10000)
    local timerColor = paused and "|cffff4444" or "|cff44ff44"
    local timerStr = string.format("%s%s|r", timerColor, GB.FormatTime(elapsed))
    if totalValue > 0 then
        self.profitPanel.summary:SetText(string.format(
            "|cffffd700%dg|r/Session  |cffffd700%dg|r/Hr  %s",
            sessionGold,
            gphGold,
            timerStr
        ))
    else
        self.profitPanel.summary:SetText(timerStr)
    end

    for i, row in ipairs(self.profitRows) do
        if rows[i] then
            row.left:SetText(rows[i].left)
            row.right:SetText(rows[i].right or "")
            row:Show()
        else
            row.left:SetText("")
            row.right:SetText("")
            row:Hide()
        end
    end
end

function GB:AppendLootLog(line)
    self.lootLogLines = self.lootLogLines or {}
    table.insert(self.lootLogLines, line)
    if self.lootLogFrame and self.lootLogFrame:IsShown() then
        self.lootLogFrame.eb:SetText(table.concat(self.lootLogLines, "\n"))
        C_Timer.After(0.05, function()
            if self.lootLogFrame and self.lootLogFrame.scroll then
                self.lootLogFrame.scroll:SetVerticalScroll(self.lootLogFrame.scroll:GetVerticalScrollRange())
            end
        end)
    end
end

function GB:ToggleLootLog()
    if not self.lootLogFrame then
        local FW, FH = 460, 320
        local f = CreateFrame("Frame", "GBLootLogFrame", UIParent, "BackdropTemplate")
        f:SetSize(FW, FH)
        f:SetPoint("CENTER")
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.06, 0.09, 0.95)
        f:SetBackdropBorderColor(0.80, 0.65, 0.20, 0.90)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", 8, -8)
        title:SetText("GatherBuffs - Loot Log   (Ctrl+A, Ctrl+C to copy all)")
        title:SetTextColor(1, 0.88, 0.30)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local clearBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        clearBtn:SetPoint("TOPRIGHT", -28, -6)
        clearBtn:SetSize(46, 16)
        clearBtn:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 6,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        clearBtn:SetBackdropColor(0.18, 0.10, 0.10, 0.92)
        clearBtn:SetBackdropBorderColor(0.46, 0.20, 0.20)
        local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        clearTxt:SetAllPoints()
        clearTxt:SetText("Clear")
        clearTxt:SetTextColor(0.92, 0.78, 0.78)
        clearBtn:SetScript("OnClick", function()
            GB.lootLogLines = {}
            f.eb:SetText("")
        end)

        local EBW = FW - 36
        local scroll = CreateFrame("ScrollFrame", "GBLootLogScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)

        local eb = CreateFrame("EditBox", "GBLootLogEB", f)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontNormalSmall")
        eb:SetTextColor(0.88, 1, 0.88)
        eb:SetWidth(EBW)
        eb:SetHeight(1)
        eb:SetMaxLetters(0)
        eb:EnableMouse(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)

        f.eb = eb
        f.scroll = scroll
        self.lootLogFrame = f
    end

    if self.lootLogFrame:IsShown() then
        self.lootLogFrame:Hide()
    else
        self.lootLogFrame.eb:SetText(table.concat(self.lootLogLines or {}, "\n"))
        self.lootLogFrame:Show()
        C_Timer.After(0.05, function()
            if self.lootLogFrame and self.lootLogFrame.scroll then
                self.lootLogFrame.scroll:SetVerticalScroll(self.lootLogFrame.scroll:GetVerticalScrollRange())
            end
        end)
    end
end

function GB:ShowDebugWindow(text)
    if not self.debugFrame then
        local FW, FH = 480, 340
        local f = CreateFrame("Frame", "GBDebugFrame", UIParent, "BackdropTemplate")
        f:SetSize(FW, FH)
        f:SetPoint("CENTER")
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.06, 0.09, 0.95)
        f:SetBackdropBorderColor(0.80, 0.65, 0.20, 0.90)
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", 8, -8)
        title:SetText("GatherBuffs - Debug   (Ctrl+A, Ctrl+C to copy all)")
        title:SetTextColor(1, 0.88, 0.30)
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        local EBW = FW - 36
        local scroll = CreateFrame("ScrollFrame", "GBDebugScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)
        local eb = CreateFrame("EditBox", "GBDebugEB", f)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontNormalSmall")
        eb:SetTextColor(0.88, 1, 0.88)
        eb:SetWidth(EBW)
        eb:SetHeight(1)
        eb:SetMaxLetters(0)
        eb:EnableMouse(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)
        f.eb, f.scroll = eb, scroll
        self.debugFrame = f
    end
    self.debugFrame.eb:SetText(text)
    self.debugFrame:Show()
    self.debugFrame.eb:SetFocus()
    self.debugFrame.eb:HighlightText()
    C_Timer.After(0.05, function()
        if self.debugFrame and self.debugFrame.scroll then
            self.debugFrame.scroll:SetVerticalScroll(0)
        end
    end)
end

function GB:ShowUnknownLoot(itemID, itemLink)
    if not self.unknownLootFrame then
        local f = CreateFrame("Frame", "GBUnknownLootFrame", UIParent, "BackdropTemplate")
        f:SetSize(360, 76)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.06, 0.09, 0.95)
        f:SetBackdropBorderColor(0.80, 0.65, 0.20, 0.90)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 8, -8)
        lbl:SetText("GatherBuffs - unknown loot (select all & copy):")
        lbl:SetTextColor(1, 0.88, 0.30)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local eb = CreateFrame("EditBox", "GBUnknownLootEditBox", f, "BackdropTemplate")
        eb:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -24)
        eb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -24)
        eb:SetHeight(22)
        eb:SetFontObject("GameFontNormalSmall")
        eb:SetTextColor(0.88, 1, 0.88)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(0)
        eb:EnableMouse(true)
        eb:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 6,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        eb:SetBackdropColor(0.08, 0.12, 0.08, 0.95)
        eb:SetBackdropBorderColor(0.30, 0.55, 0.30)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed", function() f:Hide() end)

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -3)
        hint:SetText("Ctrl+A to select, Ctrl+C to copy")
        hint:SetTextColor(0.50, 0.50, 0.52)

        f.eb = eb
        self.unknownLootFrame = f
    end

    local name = GetItemInfo(itemID) or "?"
    self.unknownLootFrame.eb:SetText(string.format("id=%d  name=%s  link=%s", itemID, name, tostring(itemLink)))
    self.unknownLootFrame:Show()
    self.unknownLootFrame.eb:SetFocus()
    self.unknownLootFrame.eb:HighlightText()
end

function GB:GetPriceSourceInfo()
    local lines = {}
    local function L(s)
        table.insert(lines, s or "")
    end

    L("=== Price Sources ===")
    if TSM_API then
        L("TSM: active" .. (TSM_API.FOUR and " (v4)" or " (v3)"))
    else
        L("TSM: not found")
    end
    if ZGV and ZGV.Gold then
        local scanTime
        for _, tbl in ipairs({ ZGV.Gold.Scan, ZGV.Gold.servertrends, ZGV.Gold.ServerTrends, ZGV.Gold.db }) do
            if type(tbl) == "table" and not scanTime then
                for _, k in ipairs({ "lastScan", "scanTime", "updated", "lastUpdate", "timestamp", "scantime" }) do
                    if type(tbl[k]) == "number" and tbl[k] > 1000000000 then
                        scanTime = tbl[k]
                        break
                    end
                end
            end
        end
        L("Zygor Gold: active")
        L("  Last scan: " .. (scanTime and date("%Y-%m-%d %H:%M", scanTime) or "unknown"))
        L("  Realm scope: current character realm/faction")
        L("  Local scan data: " .. (HasZygorScanData() and "available" or "not available"))
        L("  Trend data: " .. (HasZygorTrendData() and "available" or "not available"))
    else
        L("Zygor Gold: not found")
    end
    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
        L("Auctionator: active")
    else
        L("Auctionator: not found")
    end
    local mode = GB.GetProfitPriceSourceMode()
    if mode == "manual" then
        local sourceID = GB.GetProfitPriceSource()
        local sourceLabel = GB.GetProfitPriceSourceLabel(sourceID)
        local sourceState = IsPriceSourceAvailable(sourceID) and "available" or "not found"
        L("Mode: Manual")
        L("Selected source: " .. sourceLabel .. " (" .. sourceState .. ")")
    else
        L("Mode: Auto")
        L("Lookup order: TSM -> Zygor scan -> Zygor median -> Zygor low -> Auctionator")
    end
    if not TSM_API and not (ZGV and ZGV.Gold) and not (Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID) then
        L("No price data - profit values unavailable")
    end

    L("")
    L("=== Session Item Prices ===")
    if not self.sessionOrder or #self.sessionOrder == 0 then
        L("  (no items tracked this session)")
    else
        for _, itemID in ipairs(self.sessionOrder) do
            local item = self.sessionLoot and self.sessionLoot[itemID]
            if item then
                local name = GetItemInfo(itemID) or ("item:" .. itemID)
                local p = item.price
                L(string.format("  %-26s  %s", name, (p and p > 0) and (GB.FormatGoldPlain(p) .. " ea") or "(no price)"))
            end
        end
    end
    return table.concat(lines, "\n")
end

function GB:ToggleInfoPopup()
    if not self.infoPopup then
        local FW, FH = 340, 240
        local f = CreateFrame("Frame", "GBInfoPopup", UIParent, "BackdropTemplate")
        f:SetSize(FW, FH)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.06, 0.09, 0.95)
        f:SetBackdropBorderColor(0.55, 0.75, 0.95, 0.90)
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", 8, -8)
        title:SetText("GatherBuffs - Price Info")
        title:SetTextColor(0.55, 0.75, 0.95)
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        local EBW = FW - 36
        local scroll = CreateFrame("ScrollFrame", "GBInfoScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)
        local eb = CreateFrame("EditBox", "GBInfoEB", f)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontNormalSmall")
        eb:SetTextColor(0.88, 0.90, 0.88)
        eb:SetWidth(EBW)
        eb:SetHeight(1)
        eb:SetMaxLetters(0)
        eb:EnableMouse(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)
        f.eb, f.scroll = eb, scroll
        self.infoPopup = f
    end
    if self.infoPopup:IsShown() then
        self.infoPopup:Hide()
    else
        self.infoPopup.eb:SetText(self:GetPriceSourceInfo())
        self.infoPopup:ClearAllPoints()
        self.infoPopup:SetPoint("TOPLEFT", self.mainFrame, "TOPRIGHT", 8, 0)
        self.infoPopup:Show()
        C_Timer.After(0.05, function()
            if self.infoPopup and self.infoPopup.scroll then
                self.infoPopup.scroll:SetVerticalScroll(0)
            end
        end)
    end
end

function GB.BuildGatherLookup()
    local lookup = {}
    for profID, entries in pairs(GATHERBUFFS_GATHER_ITEMS) do
        for _, entry in ipairs(entries) do
            local totalTiers = #entry.ids
            for tier, itemID in ipairs(entry.ids) do
                if not lookup[itemID] then
                    lookup[itemID] = { name = entry.name, profs = {}, entry = entry, tier = tier, totalTiers = totalTiers }
                end
                lookup[itemID].profs[profID] = true
            end
        end
    end
    return lookup
end

function GB.IsGatheringMat(itemID, profMap, gatherLookup)
    local info = gatherLookup and gatherLookup[itemID]
    if not info then
        return false
    end
    for prof in pairs(info.profs) do
        if profMap and profMap[prof] then
            return true
        end
    end
    return false
end

function GB:HandleLoot(msg)
    local trackedProfMap = self:GetTrackedProfitProfessionMap()
    local matched = false
    for itemLink, countText in msg:gmatch("(|Hitem:[^|]+|h.-|h|r)%s*x?(%d*)") do
        matched = true
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        local amount = tonumber(countText) or 1
        if itemID then
            local ignored = GATHERBUFFS_LOOT_IGNORE and GATHERBUFFS_LOOT_IGNORE[itemID]
            if GB.IsGatheringMat(itemID, trackedProfMap, self.gatherLookup) then
                self:TrackLoot(itemID, amount, itemLink)
                local name = GetItemInfo(itemID) or "?"
                self:AppendLootLog(string.format("%s  tracked  id=%-8d  x%-3d  %s", date("%H:%M:%S"), itemID, amount, name))
                if self.lootDebug then
                    print("|cffaaffaaGB tracked:|r id=" .. itemID .. " x" .. amount)
                end
            elseif not ignored then
                if not GetItemInfo(itemID) then
                    self.pendingLoot = self.pendingLoot or {}
                    table.insert(self.pendingLoot, { itemID = itemID, amount = amount, link = itemLink })
                else
                    local name = GetItemInfo(itemID) or "?"
                    self:AppendLootLog(string.format("%s  unknown  id=%-8d  x%-3d  %s", date("%H:%M:%S"), itemID, amount, name))
                    if self.lootDebug then
                        self:ShowUnknownLoot(itemID, itemLink)
                    end
                end
            end
        end
    end
    if self.lootDebug and not matched then
        local clean = tostring(msg):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H[^|]*|h", ""):gsub("|h", "")
        print("|cffaaffaaGB loot (no links):|r " .. clean)
    end
end

function GB:ProcessPendingLoot()
    if not self.pendingLoot or #self.pendingLoot == 0 then
        return
    end
    local trackedProfMap = self:GetTrackedProfitProfessionMap()
    local remaining, tracked = {}, false
    for _, entry in ipairs(self.pendingLoot) do
        if GetItemInfo(entry.itemID) then
            if GB.IsGatheringMat(entry.itemID, trackedProfMap, self.gatherLookup) then
                self:TrackLoot(entry.itemID, entry.amount, entry.link)
                tracked = true
            end
        else
            table.insert(remaining, entry)
        end
    end
    self.pendingLoot = remaining
    if tracked then
        self:UpdateProfit()
    end
end
