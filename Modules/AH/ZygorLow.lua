local _, GB = ...

local source = GB.AHZygorBase:New({
    id = "zygor_low",
    label = "Zygor Low",
    sortOrder = 40,
    autoOrder = 40,
})

function source:IsAvailable()
    return self:HasTrendData()
end

function source:GetPrice(itemID)
    local trendItem = self:GetTrendItem(itemID)
    if trendItem and trendItem.p_lo and trendItem.p_lo > 0 then
        return trendItem.p_lo
    end
    return nil
end

function source:GetStatusText()
    if not (ZGV and ZGV.Gold) then
        return "Zygor Low: not found"
    end
    return "Zygor Low: " .. (self:IsAvailable() and "available" or "not available")
end

GB.RegisterAhSource(source)
