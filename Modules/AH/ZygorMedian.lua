local _, GB = ...

local source = GB.AHZygorBase:New({
    id = "zygor_median",
    label = "Zygor Median",
    sortOrder = 30,
    autoOrder = 30,
})

function source:IsAvailable()
    return self:HasTrendData()
end

function source:GetPrice(itemID)
    local trendItem = self:GetTrendItem(itemID)
    if trendItem and trendItem.p_md and trendItem.p_md > 0 then
        return trendItem.p_md
    end
    return nil
end

function source:GetStatusText()
    if not (ZGV and ZGV.Gold) then
        return "Zygor Median: not found"
    end
    return "Zygor Median: " .. (self:IsAvailable() and "available" or "not available")
end

GB.RegisterAhSource(source)
