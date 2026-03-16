local _, GB = ...

local W = GB.W
local PAD = GB.PAD
local QUAL_ICON = GB.QUAL_ICON
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
    self.sessionBaselineInitialized = session.inventoryBaselineInitialized == true
    self.sessionBaseline = {}
    self.sessionLoot = {}
    self.sessionOrder = {}
    self.sessionVendorLoot = {}
    self.sessionVendorOrder = {}

    for itemID, count in pairs(session.inventoryBaseline or {}) do
        local normalizedID = tonumber(itemID)
        if normalizedID and count and count > 0 then
            self.sessionBaseline[normalizedID] = count
        end
    end

    for _, itemID in ipairs(session.order or {}) do
        local key = tostring(itemID)
        local item = session.loot and session.loot[key]
        if item and item.itemID then
            self.sessionLoot[item.itemID] = {
                itemID = item.itemID,
                link = item.link,
                name = item.name,
                count = item.count or 0,
                activeCount = item.activeCount or item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
                price = item.price,
                quality = item.quality,
            }
            table.insert(self.sessionOrder, item.itemID)
        end
    end

    for _, itemID in ipairs(session.vendorOrder or {}) do
        local key = tostring(itemID)
        local item = session.vendorLoot and session.vendorLoot[key]
        if item and item.itemID then
            self.sessionVendorLoot[item.itemID] = {
                itemID = item.itemID,
                link = item.link,
                name = item.name,
                count = item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
            }
            table.insert(self.sessionVendorOrder, item.itemID)
        end
    end
    self.profitUiDirty = true
end

function GB:SaveSessionState()
    local session = {
        startedAt = self.sessionStart or time(),
        paused = self.sessionPaused or false,
        pausedAt = self.sessionPausedAt or 0,
        pausedTotal = self.sessionPausedTotal or 0,
        inventoryBaselineInitialized = self.sessionBaselineInitialized == true,
        inventoryBaseline = {},
        loot = {},
        order = {},
        vendorLoot = {},
        vendorOrder = {},
    }

    for itemID, count in pairs(self.sessionBaseline or {}) do
        if count and count > 0 then
            session.inventoryBaseline[tostring(itemID)] = count
        end
    end

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
                activeCount = item.activeCount or item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
                price = item.price,
                quality = item.quality,
            }
        end
    end

    for _, itemID in ipairs(self.sessionVendorOrder or {}) do
        local item = self.sessionVendorLoot and self.sessionVendorLoot[itemID]
        if item then
            local key = tostring(itemID)
            session.vendorOrder[#session.vendorOrder + 1] = itemID
            session.vendorLoot[key] = {
                itemID = item.itemID,
                link = item.link,
                name = item.name,
                count = item.count or 0,
                firstSeen = item.firstSeen or self.sessionStart,
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
        self.lastLootAt = time()
    else
        self.sessionPausedAt = time()
        self.sessionPaused = true
    end
    self.profitUiDirty = true
    self:SaveSessionState()
    self:UpdateProfit()
end

function GB:MarkProfitUiDirty()
    self.profitUiDirty = true
end

function GB:MaybeAutoStartSession()
    if not (self.db and self.db.modules and self.db.modules.profitAutoStartOnLoot) then
        return false
    end
    if not self.sessionPaused then
        return true
    end
    local pausedAt = self.sessionPausedAt or self.sessionStart or time()
    self.sessionPausedTotal = (self.sessionPausedTotal or 0) + (time() - pausedAt)
    self.sessionPaused = false
    self.sessionPausedAt = 0
    self.lastLootAt = time()
    self:SaveSessionState()
    return true
end

function GB:CheckAutoInactivePause()
    if not (self.db and self.db.modules and self.db.modules.profitAutoInactivePause) then
        return
    end
    if self.sessionPaused then
        return
    end
    if self.merchantIsOpen then
        return
    end
    if not self.lastLootAt then
        return
    end
    local threshold = (self.db.modules.profitAutoInactivePauseMinutes or 5) * 60
    if time() - self.lastLootAt >= threshold then
        self.sessionPausedAt = time()
        self.sessionPaused = true
        self:SaveSessionState()
        self:UpdateProfit()
    end
end

function GB:ResetSession()
    self.sessionStart = time()
    self.sessionPaused = true
    self.sessionPausedAt = time()
    self.sessionPausedTotal = 0
    self.sessionBaselineInitialized = false
    self.sessionBaseline = {}
    self.sessionLoot = {}
    self.sessionOrder = {}
    self.sessionVendorLoot = {}
    self.sessionVendorOrder = {}
    self.lastGphValue = 0
    self.lastGphUpdateTime = nil
    self.gphDirty = true
    self.profitRowCache = nil
    self.profitTotalValue = 0
    self.profitUiDirty = true
    if self.gatherLookup then
        self:CaptureInventoryBaseline()
    end
    self:SaveSessionState()
    if self.profitPanel then
        self:UpdateProfit()
    end
end

function GB:TrackLoot(itemID, amount, link, activeForProfit)
    if not itemID or not amount or amount <= 0 then
        return
    end
    local item = self.sessionLoot[itemID]
    if not item then
        item = { itemID = itemID, name = link or ("item:" .. itemID), count = 0, activeCount = 0, firstSeen = time() }
        self.sessionLoot[itemID] = item
        table.insert(self.sessionOrder, itemID)
    end
    item.count = item.count + amount
    if activeForProfit ~= false then
        item.activeCount = (item.activeCount or 0) + amount
    end
    item.link = link or item.link
    item.price = self:GetPrice(itemID)
    self.gphDirty = true
    self:MarkProfitUiDirty()
    if not item.quality then
        local _, _, q = GetItemInfo(itemID)
        item.quality = q
    end
    self:SaveSessionState()
end

function GB:TrackVendorLoot(itemID, amount, link)
    if not itemID or not amount or amount <= 0 then
        return
    end
    local item = self.sessionVendorLoot[itemID]
    if not item then
        item = { itemID = itemID, name = link or ("item:" .. itemID), count = 0, firstSeen = time() }
        self.sessionVendorLoot[itemID] = item
        table.insert(self.sessionVendorOrder, itemID)
    end
    item.count = item.count + amount
    item.link = link or item.link
    item.name = GetItemInfo(itemID) or item.name
    self.gphDirty = true
    self:MarkProfitUiDirty()
    self:SaveSessionState()
end

function GB:GetBagItemCount(itemID)
    local count = GetItemCount(itemID, false, false, false, false)
    return math.max(0, tonumber(count) or 0)
end

function GB:GetSessionBagDelta(itemID)
    local current = self:GetBagItemCount(itemID)
    local baseline = (self.sessionBaseline and self.sessionBaseline[itemID]) or 0
    return math.max(0, current - baseline)
end

function GB:CaptureInventoryBaseline()
    local baseline = {}
    for itemID in pairs(self.gatherLookup or {}) do
        local count = self:GetBagItemCount(itemID)
        if count > 0 then
            baseline[itemID] = count
        end
    end
    self.sessionBaseline = baseline
    self.sessionBaselineInitialized = true
    self.gphDirty = true
end

function GB:EnsureInventoryBaseline()
    if self.sessionBaselineInitialized then
        return
    end
    self:CaptureInventoryBaseline()
    self:SaveSessionState()
end

local function GetSummaryChatChannel()
    if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end
    if IsInRaid and IsInRaid() then
        return "RAID"
    end
    if IsInGroup and IsInGroup() then
        return "PARTY"
    end
    return nil
end

local function EscapeChatMessage(message)
    return tostring(message or ""):gsub("|", "||")
end

local function GetVendorSellPrice(itemID)
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemID)
    return math.max(0, tonumber(sellPrice) or 0)
end

local function IsGearItem(itemID)
    local _, _, _, _, _, _, _, _, equipLoc, _, _, classID = GetItemInfo(itemID)
    if classID == LE_ITEM_CLASS_ARMOR or classID == LE_ITEM_CLASS_WEAPON then
        return true
    end
    return equipLoc ~= nil and equipLoc ~= ""
end

function GB:ShouldIncludeVendorLootItem(itemID)
    if not (self.db and self.db.modules and self.db.modules.profitVendorLoot) then
        return false
    end
    if self.gatherLookup and self.gatherLookup[itemID] then
        return false
    end
    if GetVendorSellPrice(itemID) <= 0 then
        return false
    end
    if self.db.modules.profitVendorLootExcludeGear == true and GB.HasProfessionByName("Enchanting") and IsGearItem(itemID) then
        return false
    end
    return true
end

function GB:BuildVendorLootSummary()
    if not (self.db and self.db.modules and self.db.modules.profitVendorLoot) then
        return 0, 0
    end

    local totalValue, totalCount = 0, 0

    for _, itemID in ipairs(self.sessionVendorOrder or {}) do
        local item = self.sessionVendorLoot and self.sessionVendorLoot[itemID]
        if item and item.count and item.count > 0 then
            if self:ShouldIncludeVendorLootItem(itemID) then
                local vendorPrice = GetVendorSellPrice(itemID)
                if vendorPrice > 0 then
                    totalValue = totalValue + (vendorPrice * item.count)
                    totalCount = totalCount + item.count
                end
            end
        end
    end

    return totalValue, totalCount
end

function GB:BuildCurrentProfitGroups(includeBagFallback)
    local totalValue = 0
    local grouped = {}
    local groupOrder = {}
    local groupDisplay = {}
    local trackedProfMap = self:GetTrackedProfitProfessionMap()

    for itemID, lookupInfo in pairs(self.gatherLookup or {}) do
        if GB.IsGatheringMat(itemID, trackedProfMap, self.gatherLookup) then
            local trackedItem = self.sessionLoot and self.sessionLoot[itemID]
            local sessionCount = (trackedItem and trackedItem.activeCount) or 0
            local visibleCount = (trackedItem and trackedItem.count) or 0
            if includeBagFallback and visibleCount <= 0 then
                visibleCount = self:GetSessionBagDelta(itemID)
            end
            if visibleCount > 0 then
                local item = {
                    itemID = itemID,
                    count = visibleCount,
                    sessionCount = sessionCount,
                    price = self:GetPrice(itemID),
                }
                local groupKey = lookupInfo and lookupInfo.name or ("__id_" .. itemID)
                if not grouped[groupKey] then
                    grouped[groupKey] = {}
                    groupOrder[#groupOrder + 1] = groupKey
                    groupDisplay[groupKey] = lookupInfo and lookupInfo.name
                        or GetItemInfo(itemID)
                        or ("item:" .. itemID)
                end
                grouped[groupKey][#grouped[groupKey] + 1] = item
                totalValue = totalValue + ((item.price or 0) * sessionCount)
            end
        end
    end

    table.sort(groupOrder, function(a, b)
        return (groupDisplay[a] or a) < (groupDisplay[b] or b)
    end)

    return grouped, groupOrder, groupDisplay, totalValue
end

function GB:BuildProfitReportLines()
    local lines = {}
    local elapsed = self:GetActiveElapsed()
    local grouped, groupOrder, groupDisplay, totalValue = self:BuildCurrentProfitGroups(false)
    local vendorValue, vendorCount = self:BuildVendorLootSummary()
    totalValue = totalValue + vendorValue

    local gphValue = 0
    if totalValue > 0 and elapsed > 0 then
        gphValue = math.floor((totalValue * 3600) / math.max(elapsed, MIN_GPH_ELAPSED))
    end
    lines[#lines + 1] = string.format("Session total: %s", GB.FormatGoldPlain(totalValue))
    lines[#lines + 1] = string.format("Per hour: %s", GB.FormatGoldPlain(gphValue))
    if vendorValue > 0 then
        lines[#lines + 1] = string.format("Vendor loot: %s (%d items)", GB.FormatGoldPlain(vendorValue), vendorCount)
    end

    for _, groupKey in ipairs(groupOrder) do
        local variants = grouped[groupKey]
        table.sort(variants, function(a, b)
            local la = self.gatherLookup and self.gatherLookup[a.itemID]
            local lb = self.gatherLookup and self.gatherLookup[b.itemID]
            return (la and la.tier or 0) < (lb and lb.tier or 0)
        end)

        local label = groupDisplay[groupKey] or groupKey
        for _, item in ipairs(variants) do
            local lookup = self.gatherLookup and self.gatherLookup[item.itemID]
            local multiQ = lookup and (lookup.totalTiers or 1) > 1
            local suffix = multiQ and (" Q" .. (lookup.tier or 1)) or ""
            local unitPrice = item and item.price and GB.FormatGoldPlain(item.price) or "?"
            local count = item and item.count or 0
            local lineValue = (item and item.price or 0) * count
            lines[#lines + 1] = string.format(
                "%s%s: %d @ %s - %s",
                label,
                suffix,
                count,
                unitPrice,
                GB.FormatGoldPlain(lineValue)
            )
        end
    end

    if #groupOrder == 0 and vendorValue <= 0 then
        lines[#lines + 1] = "No tracked session items"
    end

    return lines
end

function GB:SendProfitReportToChat()
    local channel = GetSummaryChatChannel()
    if not channel then
        print("|cffaaffaaGatherBuffs:|r join a party/raid to export the report.")
        return
    end

    local lines = self:BuildProfitReportLines()
    for _, line in ipairs(lines) do
        SendChatMessage(EscapeChatMessage(line), channel)
    end
end

function GB:PrintProfitReportToConsole()
    local lines = self:BuildProfitReportLines()
    print("|cffaaffaaGatherBuffs report:|r")
    for _, line in ipairs(lines) do
        print(line)
    end
end

function GB:ToggleReportPopup()
    if not self.reportPopup then
        local FW, FH = 500, 360
        local f = CreateFrame("Frame", "GBReportPopup", UIParent, "BackdropTemplate")
        f:SetSize(FW, FH)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            GB.db.reportX = self:GetLeft()
            GB.db.reportY = self:GetTop()
        end)
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
        title:SetText("GatherBuffs - Report")
        title:SetTextColor(0.55, 0.75, 0.95)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local function CreateActionButton(point, relativeTo, relativePoint, x, y, text, width, onClick, r, g, b, br, bg, bb)
            local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
            btn:SetPoint(point, relativeTo, relativePoint, x, y)
            btn:SetSize(width, 18)
            btn:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 6,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            btn:SetBackdropColor(r, g, b, 0.92)
            btn:SetBackdropBorderColor(br, bg, bb)
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetAllPoints()
            fs:SetText(text)
            fs:SetTextColor(0.88, 0.90, 0.96)
            btn:SetScript("OnClick", onClick)
            return btn
        end

        local consoleBtn = CreateActionButton(
            "TOPRIGHT", f, "TOPRIGHT", -28, -8,
            "Console",
            56,
            function()
                GB:PrintProfitReportToConsole()
            end,
            0.16, 0.12, 0.22,
            0.42, 0.30, 0.62
        )
        local partyBtn = CreateActionButton(
            "TOPRIGHT", consoleBtn, "TOPLEFT", -4, 0,
            "Party",
            48,
            function()
                GB:SendProfitReportToChat()
            end,
            0.10, 0.14, 0.22,
            0.24, 0.38, 0.62
        )

        local scroll = CreateFrame("ScrollFrame", "GBReportScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)

        local eb = CreateFrame("EditBox", "GBReportEB", f)
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontNormalSmall")
        eb:SetTextColor(0.88, 0.90, 0.88)
        eb:SetWidth(FW - 36)
        eb:SetHeight(1)
        eb:SetMaxLetters(0)
        eb:EnableMouse(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        scroll:SetScrollChild(eb)

        f.eb = eb
        f.scroll = scroll
        f.partyBtn = partyBtn
        f.consoleBtn = consoleBtn
        f:Hide()
        self.reportPopup = f
    end

    if self.reportPopup:IsShown() then
        self.reportPopup:Hide()
        return
    end

    local lines = self:BuildProfitReportLines()
    self.reportPopup.eb:SetText(table.concat(lines, "\n"))
    self.reportPopup:ClearAllPoints()
    if self.db.reportX and self.db.reportY then
        self.reportPopup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.reportX, self.db.reportY)
    else
        self.reportPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    self.reportPopup:Show()
    self.reportPopup.eb:SetFocus()
    self.reportPopup.eb:HighlightText()
    C_Timer.After(0.05, function()
        if self.reportPopup and self.reportPopup.scroll then
            self.reportPopup.scroll:SetVerticalScroll(0)
        end
    end)
end

function GB:RefreshSessionPrices()
    for _, itemID in ipairs(self.sessionOrder) do
        local item = self.sessionLoot[itemID]
        if item then
            local newPrice = self:GetPrice(itemID)
            if newPrice ~= item.price then
                item.price = newPrice
                self.gphDirty = true
                self:MarkProfitUiDirty()
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
    local totalValue = self.profitTotalValue or 0
    local rows = self.profitRowCache or {}

    if self.profitUiDirty or not self.profitRowCache then
        totalValue, rows = 0, {}
        local byGroup, groupOrder, groupDisplay, groupedTotalValue = self:BuildCurrentProfitGroups(true)
        local vendorValue, vendorCount = self:BuildVendorLootSummary()
        totalValue = (groupedTotalValue or 0) + vendorValue

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

        if vendorValue > 0 then
            table.insert(rows, { left = string.format("Vendor loot  x%d", vendorCount), right = GB.FormatGoldSilver(vendorValue) })
        end

        self.profitRowCache = rows
        self.profitTotalValue = totalValue
        self.profitVisibleRowCount = #rows
        self:EnsureProfitRows(#rows)
        self.profitUiDirty = false
    end

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
    self.profitPanel.summary:SetText(string.format(
        "|cffffd700%dg|r/Session  |cffffd700%dg|r/Hr  %s",
        sessionGold,
        gphGold,
        timerStr
    ))

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

local function AppendPriceSourceInfoLines(addLine)
    addLine("=== Price Sources ===")
    for _, source in ipairs(GB.GetAhSources()) do
        addLine(source:GetStatusText())
        if source.AppendDebugLines then
            source:AppendDebugLines(addLine)
        end
    end

    local mode = GB.GetProfitPriceSourceMode()
    if mode == "manual" then
        local sourceID = GB.GetProfitPriceSource()
        local sourceLabel = GB.GetProfitPriceSourceLabel(sourceID)
        local sourceState = GB.IsAhSourceAvailable(sourceID) and "available" or "not found"
        addLine("Mode: Manual")
        addLine("Selected source: " .. sourceLabel .. " (" .. sourceState .. ")")
    else
        local labels = {}
        for _, sourceID in ipairs(GB.GetAutoPriceSourceOrder()) do
            labels[#labels + 1] = GB.GetProfitPriceSourceLabel(sourceID)
        end
        addLine("Mode: Auto")
        addLine("Lookup order: " .. table.concat(labels, " -> "))
    end
    if not GB.HasAnyPriceSourceAvailable() then
        addLine("No price data - profit values unavailable")
    end
end

function GB:GetPriceSourceInfo()
    local lines = {}
    local function L(s)
        table.insert(lines, s or "")
    end

    AppendPriceSourceInfoLines(L)

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
        local FW, FH = 420, 280
        local f = CreateFrame("Frame", "GBInfoPopup", UIParent, "BackdropTemplate")
        f:SetSize(FW, FH)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            GB.db.infoX = self:GetLeft()
            GB.db.infoY = self:GetTop()
        end)
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
        title:SetText("GatherBuffs - Character Info")
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
        f:Hide()
        self.infoPopup = f
    end
    if self.infoPopup:IsShown() then
        self.infoPopup:Hide()
    else
        self.infoPopup.eb:SetText(self:GetCharacterProfessionInfo())
        self.infoPopup:ClearAllPoints()
        if self.db.infoX and self.db.infoY then
            self.infoPopup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.infoX, self.db.infoY)
        else
            self.infoPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        self.infoPopup:Show()
        C_Timer.After(0.05, function()
            if self.infoPopup and self.infoPopup.scroll then
                self.infoPopup.scroll:SetVerticalScroll(0)
            end
        end)
    end
end

local function FormatTotalsCompact(totals)
    if not totals then
        return "Fin 0  Per 0  Def 0  Spd 0%"
    end
    return string.format(
        "Fin %s  Per %s  Def %s  Spd %s",
        GB.FormatStat("finesse", totals.finesse or 0),
        GB.FormatStat("perception", totals.perception or 0),
        GB.FormatStat("deftness", totals.deftness or 0),
        GB.FormatStat("speedPct", totals.speedPct or 0)
    )
end

local function HasVisibleStats(totals)
    if not totals then
        return false
    end
    return (totals.finesse or 0) ~= 0
        or (totals.perception or 0) ~= 0
        or (totals.deftness or 0) ~= 0
        or (totals.speedPct or 0) ~= 0
end

local function FormatKnownGearLabel(prof, slotKind, itemID)
    local name, itemQuality = GetItemInfo(itemID)
    name = name or ("item:" .. tostring(itemID))
    if prof:IsKnownMidnightGearName(name, slotKind) then
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality or 0]
        local coloredName = color and (color.hex .. name .. "|r") or name
        local craftedTier = itemQuality and (itemQuality - 1) or nil
        if craftedTier and craftedTier >= 1 and craftedTier <= 3 then
            return string.format("%s (%d/3)", coloredName, craftedTier)
        end
        return coloredName
    end
    return string.format("|cffff4444%s|r", name)
end

function GB:GetCharacterProfessionInfo()
    local lines = {}
    local function L(text)
        lines[#lines + 1] = text or ""
    end

    L("Current professions")
    L("")

    local found = false
    for _, prof in ipairs(GB.GetProfessionDefs()) do
        local vitals = prof:GetVitals(self)
        local info = vitals and vitals.info or nil
        if info then
            found = true
            L(string.format("%s - %d/%d", prof:GetLabel(), info.skill or 0, info.maxSkill or 0))
            if vitals.statSnapshot then
                L(string.format("  Current: %s", FormatTotalsCompact(vitals.statSnapshot.current)))
                L(string.format("  Max:     %s", FormatTotalsCompact(vitals.statSnapshot.max)))
            end

            local tool = vitals.tool
            if tool and tool.itemID then
                L(string.format("  Tool: %s", FormatKnownGearLabel(prof, "tool", tool.itemID)))
                if HasVisibleStats(tool.stats) then
                    L(string.format("    Stats: %s", FormatTotalsCompact(tool.stats)))
                end
            else
                L("  Tool: none")
            end

            local enchantInfo = vitals.toolEnchant
            if enchantInfo and enchantInfo.hasEnchant then
                L(string.format("  Enchant: %s", enchantInfo.enchantName or ("Enchant ID " .. tostring(enchantInfo.enchantID))))
                if tool and tool.slotID then
                    local enchantStats = GB.GetInventorySlotEnchantStats(tool.slotID)
                    if HasVisibleStats(enchantStats) then
                        L(string.format("    Stats: %s", FormatTotalsCompact(enchantStats)))
                    end
                end
            else
                L("  Enchant: none")
            end

            if vitals.accessories and #vitals.accessories > 0 then
                for index, accessory in ipairs(vitals.accessories) do
                    if accessory.itemID then
                        L(string.format("  Accessory %d: %s", index, FormatKnownGearLabel(prof, "accessory", accessory.itemID)))
                        if HasVisibleStats(accessory.stats) then
                            L(string.format("    Stats: %s", FormatTotalsCompact(accessory.stats)))
                        end
                    else
                        L(string.format("  Accessory %d: none", index))
                    end
                end
            else
                L("  Accessories: none")
            end

            L("")
        end
    end

    if not found then
        L("No professions detected.")
    end

    L("")
    L("AH pricing")
    local currentSource = GB.GetCurrentPriceSource()
    L(string.format("  Mode: %s", GB.GetProfitPriceSourceMode() == "manual" and "Manual" or "Auto"))
    L(string.format("  Current source: %s", currentSource and currentSource:GetLabel() or "none available"))
    local labels = {}
    for _, sourceID in ipairs(GB.GetAutoPriceSourceOrder()) do
        labels[#labels + 1] = GB.GetProfitPriceSourceLabel(sourceID)
    end
    if #labels > 0 then
        L(string.format("  Lookup order: %s", table.concat(labels, " -> ")))
    end
    L("")
    AppendPriceSourceInfoLines(function(text)
        if text and text ~= "" then
            L("  " .. text)
        else
            L("")
        end
    end)

    return table.concat(lines, "\n")
end

function GB.BuildGatherLookup()
    local lookup = {}
    for _, prof in ipairs(GB.GetProfessionDefs()) do
        for _, entry in ipairs(prof:GetGatherItems()) do
            local totalTiers = #entry.ids
            for tier, itemID in ipairs(entry.ids) do
                if not lookup[itemID] then
                    lookup[itemID] = { name = entry.name, profs = {}, entry = entry, tier = tier, totalTiers = totalTiers }
                end
                lookup[itemID].profs[prof.id] = true
            end
        end
    end
    return lookup
end

function GB.IsGatheringMat(itemID, profMap, gatherLookup)
    local info = gatherLookup and gatherLookup[itemID]
    if info then
        for prof in pairs(info.profs) do
            if profMap and profMap[prof] then
                return true
            end
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
            self.lastLootAt = time()
            local ignored = GATHERBUFFS_LOOT_IGNORE and GATHERBUFFS_LOOT_IGNORE[itemID]
            local isGatherMat = not GB.merchantIsOpen and GB.IsGatheringMat(itemID, trackedProfMap, self.gatherLookup)
            local isVendorItem = not ignored and not GB.merchantIsOpen and self:ShouldIncludeVendorLootItem(itemID)
            local countsForProfit = not ignored and (isGatherMat or isVendorItem)
            if countsForProfit then
                self:MaybeAutoStartSession()
            end
            if countsForProfit and self.sessionPaused then
                if self.lootDebug then
                    print("|cffaaffaaGB paused:|r ignoring profit tracking while session is paused")
                end
                countsForProfit = false
            end
            if countsForProfit and isVendorItem then
                self:TrackVendorLoot(itemID, amount, itemLink)
            end
            if isGatherMat then
                self:TrackLoot(itemID, amount, itemLink, countsForProfit)
            end
            if isGatherMat and countsForProfit then
                self:TrackVendorLoot(itemID, amount, itemLink)
                local name = GetItemInfo(itemID) or "?"
                self:AppendLootLog(string.format("%s  tracked  id=%-8d  x%-3d  %s", date("%H:%M:%S"), itemID, amount, name))
                if self.lootDebug then
                    print("|cffaaffaaGB tracked:|r id=" .. itemID .. " x" .. amount)
                end
            elseif isGatherMat then
                local name = GetItemInfo(itemID) or "?"
                self:AppendLootLog(string.format("%s  skipped  id=%-8d  x%-3d  %s  (session paused)", date("%H:%M:%S"), itemID, amount, name))
                if self.lootDebug then
                    print("|cffaaffaaGB skipped:|r id=" .. itemID .. " x" .. amount .. " (session paused)")
                end
            elseif not ignored and not GB.merchantIsOpen then
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
                local activeForProfit = not self.sessionPaused
                self:TrackLoot(entry.itemID, entry.amount, entry.link, activeForProfit)
                if activeForProfit then
                    self.lastLootAt = time()
                    tracked = true
                end
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
