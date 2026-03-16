local _, GB = ...

local source = GB.AHSourceBase:New({
    id = "tsm",
    label = "TSM",
    sortOrder = 10,
    autoOrder = 10,
})

function source:IsAvailable()
    return TSM_API ~= nil
end

function source:GetPrice(itemID)
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

function source:GetStatusText()
    if TSM_API then
        return "TSM: active" .. (TSM_API.FOUR and " (v4)" or " (v3)")
    end
    return "TSM: not found"
end

GB.RegisterAhSource(source)
